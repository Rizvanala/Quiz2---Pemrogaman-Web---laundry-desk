"""Measures the WCAG contrast of the color pairs used in css/app.css, for both themes.

Run from the project folder:   python docs/contrast.py
Text needs at least 4.5 to 1. Borders of form fields (user interface parts) need at least 3 to 1.
"""
import re
import sys
from pathlib import Path

css = Path(__file__).resolve().parent.parent / "src/main/webapp/css/app.css"
text = css.read_text(encoding="utf-8")


def tokens(block):
    return dict(re.findall(r"--([a-z-]+):\s*(#[0-9A-Fa-f]{6})", block))


light = tokens(re.search(r":root\s*\{(.*?)\n\}", text, re.S).group(1))
dark = tokens(re.search(r':root\[data-theme="dark"\]\s*\{(.*?)\n\}', text, re.S).group(1))
dark = {**light, **dark}


def luminance(color):
    r, g, b = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def ratio(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


PAIRS = [
    ("Body text on page background", "ink", "canvas", 4.5),
    ("Body text on cards", "ink", "paper", 4.5),
    ("Muted text on page background", "muted", "canvas", 4.5),
    ("Muted text on cards", "muted", "paper", 4.5),
    ("Button text on brand color", "brand-ink", "brand", 4.5),
    ("Links on cards", "link", "paper", 4.5),
    ("Links on page background", "link", "canvas", 4.5),
    ("Accent text (balance owed) on cards", "accent", "paper", 4.5),
    ("Accent text on page background", "accent", "canvas", 4.5),
    ("Error text on cards", "err-ink", "paper", 4.5),
    ("Error message text on its box", "err-ink", "err-bg", 4.5),
    ("Success message text on its box", "ok-ink", "ok-bg", 4.5),
    ("Received badge", "st-received-ink", "st-received-bg", 4.5),
    ("Finished badge", "st-finished-ink", "st-finished-bg", 4.5),
    ("Collected badge", "st-collected-ink", "st-collected-bg", 4.5),
    ("Cancelled badge", "st-cancelled-ink", "st-cancelled-bg", 4.5),
    ("Field border on cards (3:1)", "line-strong", "paper", 3.0),
    ("Field border on page background (3:1)", "line-strong", "canvas", 3.0),
]

failed = 0
for name, theme in (("LIGHT THEME", light), ("DARK THEME", dark)):
    print(name)
    for label, fg, bg, need in PAIRS:
        value = ratio(theme[fg], theme[bg])
        ok = value >= need
        failed += not ok
        print("  %-42s %s on %s  %5.2f : 1  need %.1f  %s" % (label, theme[fg], theme[bg], value, need, "OK" if ok else "FAIL"))
    print()
print("All pairs pass." if not failed else "%d pair(s) fail." % failed)
sys.exit(1 if failed else 0)
