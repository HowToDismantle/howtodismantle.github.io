#!/usr/bin/env python3
"""
update-llms-txt-blog.py

Regenerates the snapshot block in llms-full.txt for
how-to-dismantle-a-peakboard-box.com from the live sitemap.xml.

Replaces only the content between <!-- AUTOGEN:START --> and <!-- AUTOGEN:END -->
markers, leaving the rest of llms-full.txt untouched.

This script is specifically tailored for the blog: it expects all blog posts
to live at the site root with `.html` extension, in reverse-chronological order
by their <lastmod> date in the sitemap.

Usage:
    python update-llms-txt-blog.py                    # uses defaults
    python update-llms-txt-blog.py --dry-run          # prints diff without writing
    python update-llms-txt-blog.py --llms path/to/llms-full.txt --sitemap https://...
"""

import argparse
import re
import sys
import urllib.request
from datetime import date
from pathlib import Path
from xml.etree import ElementTree as ET

DEFAULT_SITEMAP = "https://how-to-dismantle-a-peakboard-box.com/sitemap.xml"
DEFAULT_LLMS_PATH = "llms-full.txt"
SITE_BASE = "https://how-to-dismantle-a-peakboard-box.com"

MARKER_START = "<!-- AUTOGEN:START — content between the AUTOGEN markers is regenerated from sitemap.xml; do not edit by hand -->"
MARKER_END = "<!-- AUTOGEN:END -->"

# URL prefixes that are NOT blog posts and should be skipped
SKIP_PREFIXES = (
    "/category/",
    "/collections/",
    "/learning/",
    "/archive/",
    "/assets/",
    "/about.html",
    "/search.html",
    "/google",  # Google site verification file
)


def fetch_sitemap(url: str) -> str:
    """Download the sitemap and return its raw XML."""
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read().decode("utf-8")


def parse_posts(xml_text: str):
    """Extract blog posts from the sitemap as (slug, date) tuples.

    A blog post is any URL that:
    - lives directly under the site root (no subdirectory)
    - has .html extension
    - is not a meta page (about, search, archive, etc.)
    - has a <lastmod> date

    Returns posts sorted by date, newest first.
    """
    ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    root = ET.fromstring(xml_text)

    posts = []
    for url_elem in root.findall("sm:url", ns):
        loc_elem = url_elem.find("sm:loc", ns)
        lastmod_elem = url_elem.find("sm:lastmod", ns)
        if loc_elem is None or loc_elem.text is None:
            continue
        url = loc_elem.text
        if not url.startswith(SITE_BASE):
            continue
        path = url[len(SITE_BASE):]
        # Filter: must be /<something>.html with no further slashes
        if not path.endswith(".html"):
            continue
        if any(path.startswith(p) for p in SKIP_PREFIXES):
            continue
        # Must be /xxx.html, not /sub/xxx.html
        if path.count("/") != 1:
            continue
        # Need a date
        if lastmod_elem is None or lastmod_elem.text is None:
            continue
        # Extract just YYYY-MM-DD from ISO datetime
        date_str = lastmod_elem.text[:10]
        slug = path.lstrip("/").rsplit(".html", 1)[0]
        posts.append((slug, date_str))

    # Newest first
    posts.sort(key=lambda p: p[1], reverse=True)
    return posts


def display_title(slug: str) -> str:
    """Convert slug to readable title — just replace dashes with spaces.
    Preserves things like 'wheel.me', 'n8n.io', 'seven.io' etc."""
    return slug.replace("-", " ")


def render_block(posts) -> str:
    """Render the snapshot block (everything between the markers)."""
    out = []
    out.append(MARKER_START)
    out.append("")
    out.append(f"### All blog posts ({len(posts)})")
    out.append("")
    for slug, date_str in posts:
        out.append(f"- {date_str} — {display_title(slug)}: {SITE_BASE}/{slug}.html")
    out.append("")
    out.append(MARKER_END)
    return "\n".join(out)


def update_snapshot_date(content: str, today: str) -> str:
    """Update the 'as of YYYY-MM-DD' date in the snapshot heading."""
    return re.sub(
        r"## Full post archive \(as of \d{4}-\d{2}-\d{2}\)",
        f"## Full post archive (as of {today})",
        content,
    )


def replace_block(content: str, new_block: str) -> str:
    """Replace everything between MARKER_START and MARKER_END (inclusive)."""
    pattern = re.compile(
        re.escape(MARKER_START) + r".*?" + re.escape(MARKER_END),
        re.DOTALL,
    )
    if not pattern.search(content):
        sys.exit(
            f"ERROR: AUTOGEN markers not found in {DEFAULT_LLMS_PATH}.\n"
            f"Expected:\n  {MARKER_START}\n  ...\n  {MARKER_END}"
        )
    return pattern.sub(new_block, content)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--llms", default=DEFAULT_LLMS_PATH, help="Path to llms-full.txt")
    parser.add_argument("--sitemap", default=DEFAULT_SITEMAP, help="Sitemap URL")
    parser.add_argument("--dry-run", action="store_true", help="Print without writing")
    args = parser.parse_args()

    llms_path = Path(args.llms)
    if not llms_path.exists():
        sys.exit(f"ERROR: {llms_path} not found")

    print(f"Fetching {args.sitemap} ...")
    xml_text = fetch_sitemap(args.sitemap)

    print("Parsing URLs ...")
    posts = parse_posts(xml_text)
    print(f"  Blog posts: {len(posts)}")
    if posts:
        print(f"  Newest: {posts[0][1]} — {posts[0][0]}")
        print(f"  Oldest: {posts[-1][1]} — {posts[-1][0]}")

    today = date.today().isoformat()
    new_block = render_block(posts)

    original = llms_path.read_text(encoding="utf-8")
    updated = update_snapshot_date(original, today)
    updated = replace_block(updated, new_block)

    if updated == original:
        print("No changes — llms-full.txt already up to date.")
        return

    if args.dry_run:
        print("\n--- DRY RUN: would write the following changes ---\n")
        print(new_block[:500] + "\n... (truncated) ...\n" + new_block[-300:])
        return

    llms_path.write_text(updated, encoding="utf-8")
    print(f"Updated {llms_path} (snapshot date: {today})")


if __name__ == "__main__":
    main()
