#!/usr/bin/env python3
"""Converte a fonte bitmap do jogo (assets/ui/fonts/noct_pixel.fnt + .png) em site/fonts/noct_pixel.woff2.

Cada pixel claro do glifo vira um quadrado na fonte vetorial, então o texto do site fica idêntico ao do jogo.
A sombra escura do bitmap não entra: o site desenha a sombra com CSS (text-shadow).

Uso: python3 tools/make_site_font.py   (precisa de: pip install fonttools brotli pillow)
"""
import re
from pathlib import Path

from PIL import Image
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen

ROOT = Path(__file__).resolve().parent.parent
FNT = ROOT / "assets/ui/fonts/noct_pixel.fnt"
PNG = ROOT / "assets/ui/fonts/noct_pixel.png"
OUT = ROOT / "site/fonts/noct_pixel.woff2"

PX = 100            # unidades por pixel
FILL = (225, 167, 180)  # cor do traço; a outra cor do bitmap é a sombra


def main() -> None:
    text = FNT.read_text(encoding="utf-8")
    base = int(re.search(r"base=(\d+)", text).group(1))
    line = int(re.search(r"lineHeight=(\d+)", text).group(1))
    img = Image.open(PNG).convert("RGBA")

    glyphs = {".notdef": TTGlyphPen(None).glyph()}
    metrics = {".notdef": (6 * PX, 0)}
    cmap = {}
    for m in re.finditer(r"char id=(\d+) x=(\d+) y=(\d+) width=(\d+) height=(\d+) xoffset=(-?\d+) yoffset=(-?\d+) xadvance=(\d+)", text):
        cid, x, y, w, h, xo, yo, adv = map(int, m.groups())
        name = "uni%04X" % cid
        pen = TTGlyphPen(None)
        for row in range(h):
            col = 0
            while col < w:
                if img.getpixel((x + col, y + row))[:3] != FILL:
                    col += 1
                    continue
                start = col
                while col < w and img.getpixel((x + col, y + row))[:3] == FILL:
                    col += 1
                x0, x1 = (xo + start) * PX, (xo + col) * PX
                y1 = (base - (yo + row)) * PX
                y0 = y1 - PX
                pen.moveTo((x0, y0)); pen.lineTo((x0, y1)); pen.lineTo((x1, y1)); pen.lineTo((x1, y0)); pen.closePath()
        glyphs[name] = pen.glyph()
        metrics[name] = (adv * PX, 0)
        cmap[cid] = name

    order = list(glyphs)
    fb = FontBuilder(line * PX, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=base * PX, descent=-(line - base) * PX)
    fb.setupNameTable({"familyName": "Noct Pixel", "styleName": "Regular"})
    fb.setupOS2(sTypoAscender=base * PX, sTypoDescender=-(line - base) * PX, usWinAscent=base * PX, usWinDescent=(line - base) * PX)
    fb.setupPost()
    fb.font.flavor = "woff2"
    OUT.parent.mkdir(parents=True, exist_ok=True)
    fb.save(str(OUT))
    print("ok:", OUT, len(cmap), "glifos")


if __name__ == "__main__":
    main()
