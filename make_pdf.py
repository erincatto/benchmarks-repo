#!/usr/bin/env python3
"""Render docs/REPORT.md to a shareable PDF and a standalone HTML.

Images are inlined as base64 so the HTML is a single file that survives being emailed or
dropped in a chat, and so Chrome does not need filesystem access to the images when printing.

Chrome is used for the PDF because it is the only renderer present here that handles tables,
side-by-side image columns and page breaks without a LaTeX toolchain.
"""

import base64
import mimetypes
import pathlib
import re
import subprocess
import sys

import markdown

ROOT = pathlib.Path(__file__).parent
DOCS = ROOT / "docs"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

CSS = """
@page { size: A4 landscape; margin: 11mm 10mm; }
body {
  font: 10pt/1.45 -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
  color: #14181d; margin: 0; -webkit-print-color-adjust: exact;
}
h1 { font-size: 20pt; margin: 0 0 2pt; letter-spacing: -0.4pt; font-weight: 650; }
h1 + p { color: #57606a; font-size: 9.5pt; margin: 0 0 10pt; }
h2 { font-size: 15pt; margin: 0 0 8pt; padding-bottom: 4pt; font-weight: 650;
     border-bottom: 2px solid #14181d; page-break-before: always; }
h2:first-of-type { page-break-before: avoid; }
h3 { font-size: 11.5pt; margin: 0 0 6pt; font-weight: 600; }
/* Each case is one self-contained block: heading, images, table stay together. */
h3 { page-break-before: always; page-break-after: avoid; }
h2 + table, h2 + p + table { page-break-before: avoid; }
p { margin: 4pt 0; }
code { font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 9.5pt;
       background: none; padding: 0; font-weight: 600; }
table { border-collapse: collapse; margin: 6pt 0 10pt; font-size: 9.5pt;
        page-break-inside: avoid; }
th, td { border-bottom: 1px solid #d8dee4; padding: 4pt 10pt 4pt 0; text-align: left; }
th { border-bottom: 1.5px solid #14181d; font-weight: 600; white-space: nowrap; }
td:not(:first-child), th:not(:first-child) { text-align: right; }
img { max-width: 100%; height: auto; display: block; }
/* Screenshot pairs: equal columns, no borders, images as large as the page allows. */
table:has(img) { width: 100%; table-layout: fixed; }
table:has(img) th { text-align: center; border-bottom: none; padding-bottom: 2pt;
                    font-size: 9pt; color: #57606a; }
table:has(img) td { border: none; padding: 0 4pt; text-align: center; }
.warn { background: #fff5f5; border: 1px solid #ffc9c9; border-left: 4px solid #e03131;
        padding: 7pt 11pt; margin: 8pt 0 12pt; border-radius: 3px; font-size: 9pt; }
.warn ul { margin: 0; padding-left: 14pt; }
a { color: inherit; text-decoration: none; }
hr { display: none; }
"""


def inline_images(html: str) -> str:
    """Replace every local <img src> with a data: URI."""

    def repl(match):
        src = match.group(1)
        if src.startswith(("data:", "http:", "https:")):
            return match.group(0)
        path = (DOCS / src).resolve()
        if not path.exists():
            print(f"warning: missing image {src}", file=sys.stderr)
            return match.group(0)
        mime = mimetypes.guess_type(path.name)[0] or "image/png"
        data = base64.b64encode(path.read_bytes()).decode()
        return match.group(0).replace(src, f"data:{mime};base64,{data}")

    return re.sub(r'<img[^>]+src="([^"]+)"', repl, html)


def main() -> int:
    source = DOCS / "REPORT.md"
    if not source.exists():
        print(f"no report at {source} — run ./run_bench.sh first", file=sys.stderr)
        return 1

    body = markdown.markdown(
        source.read_text(),
        extensions=["tables", "fenced_code", "attr_list", "sane_lists"],
    )
    # The generator emits validity warnings as a bullet list under a warning heading; give
    # them a box so a reader skimming the PDF cannot miss that numbers are qualified.
    body = body.replace(
        "<h2>⚠ Validity warnings</h2>", '<h2>⚠ Validity warnings</h2><div class="warn">'
    ).replace("<h2>2D</h2>", "</div><h2>2D</h2>", 1)

    html = (
        "<!doctype html><html><head><meta charset='utf-8'>"
        "<title>Godot physics engine benchmark</title>"
        f"<style>{CSS}</style></head><body>{body}</body></html>"
    )
    html = inline_images(html)

    html_out = DOCS / "REPORT.html"
    html_out.write_text(html)
    print(f"wrote {html_out} ({html_out.stat().st_size / 1e6:.1f} MB, self-contained)")

    if not pathlib.Path(CHROME).exists():
        print("Chrome not found — HTML written, skipping PDF", file=sys.stderr)
        return 0

    pdf_out = DOCS / "REPORT.pdf"
    result = subprocess.run(
        [
            CHROME,
            "--headless",
            "--disable-gpu",
            "--no-sandbox",
            "--no-pdf-header-footer",
            # Images are inline data URIs, but the charts are large; give layout time to
            # settle or the PDF can come out with blank image boxes.
            "--virtual-time-budget=20000",
            f"--print-to-pdf={pdf_out}",
            html_out.as_uri(),
        ],
        capture_output=True,
        text=True,
        timeout=180,
    )
    if pdf_out.exists() and pdf_out.stat().st_size > 0:
        print(f"wrote {pdf_out} ({pdf_out.stat().st_size / 1e6:.1f} MB)")
        return 0
    print(f"PDF failed: {result.stderr[-500:]}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
