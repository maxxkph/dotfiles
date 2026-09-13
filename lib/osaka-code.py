#!/usr/bin/env python3
"""Retune Apple's Osaka-Mono into `Osaka Code`, a terminal-correct coding font.

Osaka's ASCII needs no work: all 95 printable characters are already an exact
500-unit half-width grid, with CJK at 1000. That is precisely the dual-width
model a terminal wants.

What breaks is 372 *non*-CJK codepoints -- arrows, curly quotes, dashes, Greek,
Cyrillic, box drawing, geometric shapes -- that Osaka draws as 1000-unit
full-width CJK glyphs. A terminal allots them one 500-unit cell, so they bleed
into the next column. That is the smeared commit circle in lazygit: U+25EF is
in the font, at 1000 units, overflowing its cell by 99%.

The fix is to unmap them rather than redraw them. Ghostty already falls back
cleanly for anything Osaka lacks -- that is why the lazygit checkmark (U+2713,
absent from Osaka) renders perfectly while the circle does not -- so dropping
these from cmap hands them to Ghostty's bundled JetBrains Mono -- a true
monospace -- at exactly one cell. Inverted from the intuition: what Osaka is
*missing* looks fine, what it *has* is broken.

Also repairs OS/2, which the .otf conversion left almost entirely zeroed.

You do not normally need to run this: `dot fonts` installs the built .otf from
the private font repo, which also holds the Osaka-Mono this reads. It is here
for changing how the retune works.

Needs fontTools:  pip3 install --user fonttools
"""
import os
import sys

SRC = os.path.expanduser("~/Library/Fonts/Osaka Regular-Mono.otf")
OUT = os.path.expanduser("~/Library/Fonts/OsakaCode-Regular.otf")

FAMILY, SUBFAMILY = "Osaka Code", "Regular"
PS_NAME = "OsakaCode-Regular"
VERSION = "Version 1.000; Osaka-Mono retuned for terminal use"


def mac_roman_codepoint(byte):
    """The legacy Macintosh cmap is keyed by Mac Roman byte, not codepoint, so
    its keys need translating before they can be matched against the strip set
    -- otherwise ¢ £ § ¬ ° ± × ÷ … — “ ” ‘ ’ survive in that subtable."""
    try:
        return ord(bytes([byte]).decode("mac_roman"))
    except Exception:
        return None


def main():
    try:
        from fontTools.ttLib import TTFont
    except ImportError:
        sys.exit("fontTools missing — pip3 install --user fonttools")

    src = sys.argv[1] if len(sys.argv) > 1 else SRC
    out = sys.argv[2] if len(sys.argv) > 2 else OUT
    if not os.path.exists(src):
        sys.exit(f"no Osaka-Mono at {src} — run 'dot fonts' first")

    font = TTFont(src, fontNumber=0)
    hmtx = font["hmtx"]

    # Everything non-ASCII below the CJK blocks that is drawn full-width. The
    # 0x2E80 floor keeps real CJK, kana and the fullwidth forms untouched --
    # those are *correctly* double-width and must stay at 1000.
    strip = {cp for cp, glyph in font.getBestCmap().items()
             if 0x80 <= cp < 0x2E80 and hmtx[glyph][0] == 1000}

    for table in font["cmap"].tables:
        if table.platformID == 1:
            doomed = [k for k in table.cmap if mac_roman_codepoint(k) in strip]
        else:
            doomed = [k for k in table.cmap if k in strip]
        for key in doomed:
            del table.cmap[key]

    # The outlines stay in the CFF. The vertical-writing feature ('vrt2') still
    # references some of them, and 372 orphans out of 7431 is not worth the risk.

    # Only hhea was populated; OS/2 came out of the conversion as zeros. Mirror
    # hhea exactly so line height is unchanged -- `adjust-cell-height` in the
    # ghostty config is already tuned against these numbers.
    os2, hhea, head = font["OS/2"], font["hhea"], font["head"]
    os2.sTypoAscender = hhea.ascent
    os2.sTypoDescender = hhea.descent
    os2.sTypoLineGap = hhea.lineGap
    os2.usWinAscent, os2.usWinDescent = head.yMax, abs(head.yMin)
    os2.fsSelection |= 1 << 6      # REGULAR. Bit 7 (USE_TYPO_METRICS) stays
                                   # clear so hhea remains authoritative.
    os2.panose.bProportion = 9     # monospaced
    os2.xAvgCharWidth = 500        # the Latin cell. The spec average is 988,
                                   # skewed by 7264 full-width CJK glyphs, and
                                   # would imply a double-wide cell.
    os2.recalcUnicodeRanges(font)
    font["post"].isFixedPitch = 1

    # Renamed so it installs beside the original rather than shadowing it.
    names = {1: FAMILY, 2: SUBFAMILY, 3: f"{PS_NAME};1.000",
             4: FAMILY, 5: VERSION, 6: PS_NAME}
    for name_id, value in names.items():
        font["name"].setName(value, name_id, 3, 1, 0x409)   # Windows
        font["name"].setName(value, name_id, 1, 0, 0)       # Macintosh
    if "CFF " in font:
        cff = font["CFF "].cff
        cff.fontNames[0] = PS_NAME
        top_dict = cff[PS_NAME].rawDict
        top_dict["FullName"], top_dict["FamilyName"] = FAMILY, FAMILY

    font.save(out)
    print(f"unmapped {len(strip)} full-width glyphs -> {out}")
    print(f"set ghostty's font-family to '{FAMILY}'")


if __name__ == "__main__":
    main()
