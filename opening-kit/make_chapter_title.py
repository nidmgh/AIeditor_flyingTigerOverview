#!/usr/bin/env python3
# Chapter-title plate: e.g. "第一章 · 飞虎出征" centered, sitting beneath the
# FLYING TIGERS subtitle. Warm-silver text + thin amber flanking rules + glow.
# Usage: make_chapter_title.py "第一章 · 飞虎出征" out.png [baseline_y]
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

text = sys.argv[1] if len(sys.argv) > 1 else "第一章 · 飞虎出征"
out  = sys.argv[2] if len(sys.argv) > 2 else "plates/chapter_title.png"
ycen = int(sys.argv[3]) if len(sys.argv) > 3 else 880

W, H = 1920, 1080
FONT = "/System/Library/Fonts/STHeiti Medium.ttc"
SIZE = 60
SPACE = 12
AMBER = (228, 196, 120)

font = ImageFont.truetype(FONT, SIZE)
canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))

# measure with letter spacing
tmp = ImageDraw.Draw(canvas)
chs = list(text)
widths = [tmp.textbbox((0, 0), c, font=font)[2] for c in chs]
tw = sum(widths) + SPACE * (len(chs) - 1)
x0 = (W - tw) // 2
asc, desc = font.getmetrics()
y0 = ycen - (asc + desc) // 2

def draw_spaced(drw, x, y, fill, **kw):
    cx = x
    for i, c in enumerate(chs):
        drw.text((cx, y), c, font=font, fill=fill, **kw)
        cx += widths[i] + SPACE

# soft glow
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw_spaced(ImageDraw.Draw(glow), x0, y0, (150, 185, 235, 255))
glow = glow.filter(ImageFilter.GaussianBlur(10))
canvas = Image.alpha_composite(canvas, glow)
# shadow
sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw_spaced(ImageDraw.Draw(sh), x0, y0 + 3, (0, 0, 0, 200))
sh = sh.filter(ImageFilter.GaussianBlur(4))
canvas = Image.alpha_composite(canvas, sh)
# main text (warm off-white)
d = ImageDraw.Draw(canvas)
draw_spaced(d, x0, y0, (242, 238, 228, 255))

# thin amber flanking rules on either side of the text
rule_y = ycen
gap = 46
rlen = 120
d.rectangle([x0 - gap - rlen, rule_y - 1, x0 - gap, rule_y + 1], fill=AMBER + (230,))
d.rectangle([x0 + tw + gap, rule_y - 1, x0 + tw + gap + rlen, rule_y + 1], fill=AMBER + (230,))

canvas.save(out)
print("chapter title plate ->", out, "| text:", text)
