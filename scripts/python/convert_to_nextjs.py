#!/usr/bin/env python3
import os
import re
import json
import shutil
import subprocess

def parse_html_file(file_path):
    """
    Parse the HTML file using regex to extract the <title> and <body> content.
    Returns a tuple (title, body_content).
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Extract <title> content.
    title_match = re.search(r'<title>(.*?)</title>', content, re.IGNORECASE | re.DOTALL)
    title = title_match.group(1).strip() if title_match else "Page"
    
    # Extract <body> content; if not found, use the entire content.
    body_match = re.search(r'<body[^>]*>(.*?)</body>', content, re.IGNORECASE | re.DOTALL)
    body_content = body_match.group(1).strip() if body_match else content
    
    return title, body_content

def remove_html_extension_links(html_content):
    """
    Removes .html or .htm extension from href attributes in HTML content.
    Converts e.g. href="pricing.html" to href="pricing".
    """
    pattern = r'(?P<prefix>href=["\'])(?P<url>[^"\']+?)(?P<extension>\.html?)(?P<suffix>["\'])'
    return re.sub(pattern, r'\g<prefix>\g<url>\g<suffix>', html_content)

def fix_form_configuration(html_content):
    """
    Fixes form configuration issues by:
    - Replacing any action attribute in <form> tags with action="#"
    - Removing Webflow-specific data attributes that may cause misconfiguration.
    """
    # Replace any existing action attribute in <form> tags.
    html_content = re.sub(r'(<form[^>]*?)\s*action="[^"]*"', r'\1 action="#"', html_content)
    # Optionally remove data-wf-* attributes.
    html_content = re.sub(r'\sdata-wf-[^=]+="[^"]*"', '', html_content)
    return html_content

def process_inner_html(html_content):
    """
    Processes the inner HTML by removing .html extensions from links
    and fixing form configurations.
    """
    processed = remove_html_extension_links(html_content)
    processed = fix_form_configuration(processed)
    return processed

def convert_html_to_nextjs_page(src_path, dest_path):
    """
    Converts an HTML file into a Next.js page file (.js).
    Global CSS is handled separately via _app.js.
    """
    title, body_content = parse_html_file(src_path)
    # Process inner HTML: remove .html extensions and fix forms.
    body_content = process_inner_html(body_content)
    # Escape the HTML content so it can be safely injected via dangerouslySetInnerHTML.
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
    with open(dest_path, 'w', encoding='utf-8') as f:
        f.write(page_content)

def rewrite_css_urls(css_content, css_file_full_path, project_root):
    """
    Rewrites all url(...) references in the given CSS content.
    Computes the absolute asset path relative to the project root,
    then rewrites it to use '/public/' as a prefix.
    This version uses a more robust regex to correctly capture URLs with
    parentheses or quotes.
    """
    # Pattern: url( optional-quote, url, same-quote, optional whitespace )
    pattern = re.compile(r'url\(\s*(["\']?)(.*?)\1\s*\)')

    def replacer(match):
        original = match.group(2).strip()
        # Skip data URLs or absolute URLs.
        if original.startswith(('data:', 'http:', 'https:')):
            return match.group(0)
        # If the original is an absolute path, prepend '/public'
        if original.startswith('/'):
            new_url = '/public' + original
        else:
            css_dir = os.path.dirname(css_file_full_path)
            asset_abs = os.path.normpath(os.path.join(css_dir, original))
            asset_rel = os.path.relpath(asset_abs, project_root)
            new_url = '/public/' + asset_rel.replace(os.sep, '/')
        return f'url("{new_url}")'
    
    new_css = pattern.sub(replacer, css_content)
    return new_css

def setup_nextjs_project(output_dir):
    """
    Sets up the Next.js project inside the output directory:
    - Runs `npm init -y`
    - Updates package.json with required scripts.
    - Installs next, react, and react-dom.
    """
    print("Sir, setting up the Next.js project...")

    # Run npm init -y
    subprocess.run(["npm", "init", "-y"], cwd=output_dir, check=True)
    
    # Read and update package.json scripts.
    package_json_path = os.path.join(output_dir, "package.json")
    with open(package_json_path, 'r', encoding='utf-8') as f:
        package_data = json.load(f)
    
    # Set Next.js scripts.
    package_data["scripts"] = {
        "dev": "next dev",
        "build": "next build",
        "start": "next start"
    }
    
    with open(package_json_path, 'w', encoding='utf-8') as f:
        json.dump(package_data, f, indent=2)
    
    # Install dependencies.
    subprocess.run(["npm", "install", "next", "react", "react-dom"], cwd=output_dir, check=True)
    
    print("Sir, Next.js project setup complete.")

def main():
    # Assume the script is run from the root of the downloaded project.
    current_dir = os.getcwd()
    output_dir = os.path.join(current_dir, "nextjs_app")
    pages_dir = os.path.join(output_dir, "pages")
    public_dir = os.path.join(output_dir, "public")
    styles_dir = os.path.join(output_dir, "styles")

    # Create Next.js standard directories.
    os.makedirs(pages_dir, exist_ok=True)
    os.makedirs(public_dir, exist_ok=True)
    os.makedirs(styles_dir, exist_ok=True)

    # Create/initialize the global CSS file.
    global_css_path = os.path.join(styles_dir, "global.css")
    with open(global_css_path, "w", encoding='utf-8') as f:
        f.write("/* Global CSS aggregated from downloaded project */\n\n")

    # Create a custom _app.js file that imports the global CSS.
    app_js_path = os.path.join(pages_dir, "_app.js")
    with open(app_js_path, "w", encoding='utf-8') as f:
        f.write("""import '../styles/global.css';

export default function MyApp({ Component, pageProps }) {
  return <Component {...pageProps} />;
}
""")

    print("Sir, converting HTML files, CSS, and assets to Next.js structure...")

    # Walk through all files in the current directory (skip the output folder).
    for root, _, files in os.walk(current_dir):
        # Skip processing files in the output directory.
        if os.path.abspath(root).startswith(os.path.abspath(output_dir)):
            continue
        for file in files:
            src_file = os.path.join(root, file)
            rel_path = os.path.relpath(src_file, current_dir)
            # Process HTML files.
            if file.lower().endswith((".html", ".htm")):
                # Convert the HTML file into a .js Next.js page.
                js_dest = os.path.join(pages_dir, os.path.splitext(rel_path)[0] + ".js")
                os.makedirs(os.path.dirname(js_dest), exist_ok=True)
                print(f"Converting: {rel_path} -> {os.path.relpath(js_dest, current_dir)}")
                convert_html_to_nextjs_page(src_file, js_dest)
            # Process CSS files: append their content (with URL rewriting) to global.css.
            elif file.lower().endswith(".css"):
                print(f"Appending CSS from: {rel_path} to global.css")
                with open(src_file, 'r', encoding='utf-8') as css_file:
                    css_content = css_file.read()
                fixed_css = rewrite_css_urls(css_content, src_file, current_dir)
                with open(global_css_path, 'a', encoding='utf-8') as global_css:
                    global_css.write(f"\n/* Begin CSS from {rel_path} */\n")
                    global_css.write(fixed_css)
                    global_css.write(f"\n/* End CSS from {rel_path} */\n")
            # Copy other assets to the public folder.
            else:
                dest_asset = os.path.join(public_dir, rel_path)
                os.makedirs(os.path.dirname(dest_asset), exist_ok=True)
                print(f"Copying asset: {rel_path} -> {os.path.relpath(dest_asset, current_dir)}")
                shutil.copy2(src_file, dest_asset)

    print(f"Sir, conversion complete. Your Next.js app is ready at: {output_dir}")

    # Set up the Next.js project automatically.
    setup_nextjs_project(output_dir)
    print("Sir, please navigate to the 'nextjs_app' directory and run 'npm run dev' to start the development server.")

if __name__ == '__main__':
    main()