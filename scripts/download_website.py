#!/usr/bin/env python3
"""
Reflow - A Webflow site exporter/scraper with offline interaction support

This tool downloads a Webflow site and repackages it into a static site,
preserving animations by fetching Webflow runtime and jQuery locally.
"""

import os
import re
import json
import time
import shutil
import argparse
import requests  # type: ignore
import logging
from bs4 import BeautifulSoup  # type: ignore
from urllib.parse import urljoin, urlparse, unquote
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger('reflow')


class Reflow:
    def __init__(self, url, output_dir, max_workers=5, delay=0.2,
                 process_cms=True, retain_css=False, create_zip=True,
                 log_level=logging.INFO, log_file=None):
        self.base_url = url.rstrip('/')
        self.output_dir = output_dir
        self.max_workers = max_workers
        self.delay = delay
        self.process_cms = process_cms
        self.process_css = retain_css
        self.create_zip = create_zip

        # Webflow CDN detection
        self.cdn_js_domains = [
            'd3e54v103j8qbb.cloudfront.net',
            'uploads-ssl.webflow.com',
            'assets.website-files.com'
        ]
        self.jquery_path_pattern = re.compile(r'jquery[-\.\d]*\.js')
        self.webflow_js_pattern = re.compile(r'webflow\.[\w\d]+\.js')

        # Logging
        logger.setLevel(log_level)
        if log_file:
            fh = logging.FileHandler(log_file)
            fh.setFormatter(logging.Formatter(
                '%(asctime)s - %(levelname)s - %(message)s'))
            logger.addHandler(fh)

        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0'
        })

        self.visited_urls = set()
        self.assets_to_download = set()
        self.cms_pages = {}
        self.cms_collections = {}

        # Domain
        parsed = urlparse(self.base_url)
        self.domain = parsed.netloc

        # Working dir
        if self.create_zip:
            ts = datetime.now().strftime('%Y%m%d_%H%M%S')
            self.working_dir = os.path.join(
                os.path.dirname(output_dir), f"temp_export_{ts}")
        else:
            self.working_dir = output_dir
        os.makedirs(self.working_dir, exist_ok=True)

    def sanitize_filename(self, name):
        decoded = unquote(name)
        cleaned = re.sub(r'[<>:"/\\|?*\x00-\x1F]', '_', decoded)
        cleaned = cleaned.replace(' ', '_')
        if len(cleaned) > 255:
            base, ext = os.path.splitext(cleaned)
            cleaned = base[:255-len(ext)] + ext
        return cleaned

    def download_page(self, url, out_path=None):
        if url in self.visited_urls:
            return None, None
        self.visited_urls.add(url)

        try:
            logger.info(f"Downloading page: {url}")
            res = self.session.get(url)
            if res.status_code == 404 and url.endswith('.html'):
                alt = url[:-5]
                logger.info(f"Retrying without .html: {alt}")
                res = self.session.get(alt)
            res.raise_for_status()
            time.sleep(self.delay)

            if res.encoding in (None, 'ISO-8859-1'):
                res.encoding = res.apparent_encoding

            content = res.text
            soup = BeautifulSoup(content, 'html.parser')

            if out_path:
                os.makedirs(os.path.dirname(out_path), exist_ok=True)
                with open(out_path, 'w', encoding='utf-8') as f:
                    f.write(content)
            return soup, content
        except Exception as e:
            logger.error(f"Error downloading {url}: {e}")
            return None, None

    def process_html(self, soup, base_url, out_path):
        # Preserve Webflow data attributes on <html>
        html_tag = soup.html
        # No removal of data-wf-page or data-wf-site

        rel_root = os.path.relpath(
            '/', os.path.dirname('/' + os.path.relpath(out_path, self.working_dir)))
        if rel_root == '.':
            rel_root = ''
        elif not rel_root.endswith('/'):
            rel_root += '/'

        # Handle <script> tags: fetch remote jQuery and Webflow runtime
        scripts = list(soup.find_all('script', src=True))
        for tag in scripts:
            src = tag['src']
            full = urljoin(base_url, src)
            parsed = urlparse(full)
            name = os.path.basename(parsed.path)
            if (parsed.netloc in self.cdn_js_domains and
                    (self.jquery_path_pattern.search(name) or self.webflow_js_pattern.search(name))):
                clean = self.sanitize_filename(name)
                local = os.path.join('js', clean)
                self.assets_to_download.add((full, local))
                tag['src'] = f"{rel_root}js/{clean}"

        # After processing remote scripts, handle all other assets as before...
        # [Existing logic for links, images, css, inline styles, favicon omitted for brevity]
        # >>> Insert original process_html body here, replacing script handling above <<<

        # Ensure Webflow interactions init on offline page
        if soup.body:
            init = soup.new_tag('script')
            init.string = "if(window.Webflow&&Webflow.require){Webflow.require('ix2').init();}"
            soup.body.append(init)

        return soup

    # ... rest of methods unchanged ...

    def crawl_site(self):
        # Entry point: download homepage, process, then crawl
        homepage = os.path.join(self.working_dir, 'index.html')
        soup, _ = self.download_page(self.base_url, homepage)
        if not soup:
            logger.error("Failed to download homepage.")
            return
        proc = self.process_html(soup, self.base_url, homepage)
        with open(homepage, 'w', encoding='utf-8') as f:
            f.write(str(proc))

        # Crawl other pages, assets, CMS as in original
        # ... original crawl_site logic ...

        # Create ZIP if requested, then clean up
        # ... unchanged ...


def main():
    p = argparse.ArgumentParser()
    p.add_argument('url')
    p.add_argument('--output', '-o', default='output')
    p.add_argument('--workers', '-w', type=int, default=5)
    p.add_argument('--delay', '-d', type=float, default=0.2)
    p.add_argument('--no-cms', action='store_true')
    p.add_argument('--retain-css', action='store_true')
    p.add_argument('--no-zip', action='store_true')
    p.add_argument('--verbose', '-v', action='store_true')
    p.add_argument('--quiet', '-q', action='store_true')
    p.add_argument('--log-file')
    args = p.parse_args()

    lvl = logging.INFO
    if args.verbose:
        lvl = logging.DEBUG
    if args.quiet:
        lvl = logging.ERROR

    exporter = Reflow(
        args.url,
        args.output,
        max_workers=args.workers,
        delay=args.delay,
        process_cms=not args.no_cms,
        retain_css=args.retain_css,
        create_zip=not args.no_zip,
        log_level=lvl,
        log_file=args.log_file
    )
    exporter.crawl_site()


if __name__ == '__main__':
    main()
