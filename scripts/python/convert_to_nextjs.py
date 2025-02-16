#!/usr/bin/env python3

import re
import json
import shutil
import subprocess
from pathlib import Path
from typing import Tuple

def parse_html_file(file_path: Path) -> Tuple[str, str]:
    """
    Parse an HTML file to extract the <title> and <body> content.
    Returns a tuple (title, body_content).
    """
    content = file_path.read_text(encoding="utf-8")
    title_match = re.search(r"<title>(.*?)</title>", content, re.IGNORECASE | re.DOTALL)
    title = title_match.group(1).strip() if title_match else "Page"
    body_match = re.search(r"<body[^>]*>(.*?)</body>", content, re.IGNORECASE | re.DOTALL)
    body_content = body_match.group(1).strip() if body_match else content
    return title, body_content

def remove_html_extension_links(html_content: str) -> str:
    """
    Removes .html or .htm extensions from href attributes in HTML content.
    Converts, e.g., href="pricing.html" to href="pricing".
    """
    pattern = r'(?P<prefix>href=["\'])(?P<url>[^"\']+?)(?P<extension>\.html?)(?P<suffix>["\'])'
    return re.sub(pattern, r"\g<prefix>\g<url>\g<suffix>", html_content)

def fix_form_configuration(html_content: str) -> str:
    """
    Fixes form configuration issues by:
      - Replacing any action attribute in <form> tags with action="#"
      - Removing Webflow-specific data attributes.
    """
    html_content = re.sub(r'(<form[^>]*?)\s*action="[^"]*"', r'\1 action="#"', html_content)
    html_content = re.sub(r'\sdata-wf-[^=]+="[^"]*"', "", html_content)
    return html_content

def process_inner_html(html_content: str) -> str:
    """
    Processes inner HTML by removing .html extensions from links
    and fixing form configurations.
    """
    processed = remove_html_extension_links(html_content)
    return fix_form_configuration(processed)

def convert_html_to_nextjs_page(src_path: Path, dest_path: Path) -> None:
    """
    Converts an HTML file into a Next.js page (.js file).
    """
    title, body_content = parse_html_file(src_path)
    body_content = process_inner_html(body_content)
    json_body = json.dumps(body_content)
    
    page_content = f"""import Head from 'next/head';

export default function Page() {{
  return (
    <>
      <Head>
        <title>{title}</title>
      </Head>
      <div dangerouslySetInnerHTML={{{{ __html: {json_body} }}}} />
    </>
  );
}}
"""
    dest_path.write_text(page_content, encoding="utf-8")

def rewrite_css_urls(css_content: str, css_file: Path, project_root: Path) -> str:
    """
    Rewrites all url(...) references in CSS content.
    Computes the absolute asset path relative to the project root and
    rewrites it to use '/public/' as a prefix.
    """
    pattern = re.compile(r'url\(\s*(["\']?)(.*?)\1\s*\)')

    def replacer(match: re.Match) -> str:
        original = match.group(2).strip()
        if original.startswith(("data:", "http:", "https:")):
            return match.group(0)
        if original.startswith("/"):
            new_url = "/public" + original
        else:
            asset_abs = (css_file.parent / original).resolve()
            try:
                asset_rel = asset_abs.relative_to(project_root.resolve())
            except ValueError:
                asset_rel = asset_abs
            new_url = "/public/" + str(asset_rel).replace("\\", "/")
        return f'url("{new_url}")'

    return pattern.sub(replacer, css_content)

def setup_nextjs_project(output_dir: Path) -> None:
    """
    Sets up the Next.js project inside the output directory:
      - Runs `npm init -y`
      - Updates package.json with required scripts.
      - Installs next, react, and react-dom.
    """
    print("Sir, setting up the Next.js project...")
    subprocess.run(["npm", "init", "-y"], cwd=output_dir, check=True)

    package_json_path = output_dir / "package.json"
    package_data = json.loads(package_json_path.read_text(encoding="utf-8"))
    package_data["scripts"] = {
        "dev": "next dev",
        "build": "next build",
        "start": "next start"
    }
    package_json_path.write_text(json.dumps(package_data, indent=2), encoding="utf-8")
    subprocess.run(["npm", "install", "next", "react", "react-dom"], cwd=output_dir, check=True)
    print("Sir, Next.js project setup complete.")

def main() -> None:
    current_dir = Path.cwd()
    output_dir = current_dir / "nextjs"
    pages_dir = output_dir / "pages"
    public_dir = output_dir / "public"
    styles_dir = output_dir / "styles"

    pages_dir.mkdir(parents=True, exist_ok=True)
    public_dir.mkdir(parents=True, exist_ok=True)
    styles_dir.mkdir(parents=True, exist_ok=True)

    # Initialize the global CSS file.
    global_css_path = styles_dir / "global.css"
    global_css_path.write_text("/* Global CSS aggregated from downloaded project */\n\n", encoding="utf-8")

    # Create a custom _app.js file that imports the global CSS.
    app_js_path = pages_dir / "_app.js"
    app_js_path.write_text(
        "import '../styles/global.css';\n\n"
        "export default function MyApp({ Component, pageProps }) {\n"
        "  return <Component {...pageProps} />;\n"
        "}\n",
        encoding="utf-8"
    )

    print("Sir, converting HTML files, CSS, and assets to Next.js structure...")

    # Process all files in the current directory, skipping the output folder.
    for file_path in current_dir.rglob("*"):
        if file_path.is_dir() or output_dir in file_path.parents:
            continue

        rel_path = file_path.relative_to(current_dir)
        suffix = file_path.suffix.lower()

        if suffix in {".html", ".htm"}:
            js_dest = pages_dir / rel_path.with_suffix(".js")
            js_dest.parent.mkdir(parents=True, exist_ok=True)
            print(f"Converting: {rel_path} -> {js_dest.relative_to(current_dir)}")
            convert_html_to_nextjs_page(file_path, js_dest)
        elif suffix == ".css":
            print(f"Appending CSS from: {rel_path} to global.css")
            css_content = file_path.read_text(encoding="utf-8")
            fixed_css = rewrite_css_urls(css_content, file_path, current_dir)
            with global_css_path.open("a", encoding="utf-8") as f:
                f.write(f"\n/* Begin CSS from {rel_path} */\n")
                f.write(fixed_css)
                f.write(f"\n/* End CSS from {rel_path} */\n")
        else:
            dest_asset = public_dir / rel_path
            dest_asset.parent.mkdir(parents=True, exist_ok=True)
            print(f"Copying asset: {rel_path} -> {dest_asset.relative_to(current_dir)}")
            shutil.copy2(str(file_path), str(dest_asset))

    print(f"Sir, conversion complete. Your Next.js app is ready at: {output_dir}")
    setup_nextjs_project(output_dir)

if __name__ == "__main__":
    main()