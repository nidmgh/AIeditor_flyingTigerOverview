#!/usr/bin/env python3
# Chapter ending card plate: centered text on a transparent 1920x1080 canvas.
# Uses the SAME legible treatment as the opening's chapter title
# (make_chapter_title.py): solid warm off-white + cool glow + soft shadow.
# This reads far better at ending sizes than the metallic steel gradient,
# which only holds up at the huge 飞虎队 title size.
# Supports one or two lines split by "|".
# Usage: make_ending.py "本章完|下一章 · AVG 的诞生" out.png
import os
import sys
from PIL import Image, ImageDraw, ImageFont, ImageFilter

text = sys.argv[1] if len(sys.argv) > 1 else "本章完"
out  = sys.argv[2] if len(sys.argv) > 2 else "plates/_ending.png"
lines = [s.strip() for s in text.split("|") if s.strip()]

W, H = 1920, 1080
FONT = os.environ.get("OPENING_FONT", "/System/Library/Fonts/STHeiti Medium.ttc")
if not os.path.exists(FONT):
    raise SystemExit(f"opening-kit: font not found: {FONT} (override with OPENING_FONT=/path/to/font)")
OFFWHITE = (242, 238, 228, 255)   # warm silver — matches the chapter title
GLOW     = (150, 185, 235, 255)   # cool glow
SPACE    = 10                     # letter spacing

# size: big for a single short line, smaller when two lines / long text
main_sz = 180 if (len(lines) == 1 and len(lines[0]) <= 4) else 140
sub_sz  = 72


def render_line(text, size, space):
    """Solid warm-silver text with glow + shadow, sized to its content."""
    font = ImageFont.truetype(FONT, size)
    pad = 60
    tmp = ImageDraw.Draw(Image.new("L", (10, 10)))
    chs = list(text)
    widths = [tmp.textbbox((0, 0), c, font=font)[2] for c in chs]
    tw = sum(widths) + space * (len(chs) - 1)
    asc, desc = font.getmetrics()
    iw, ih = tw + pad * 2, asc + desc + pad * 2
    x0, y0 = pad, pad

    def draw_spaced(drw, x, y, fill):
        cx = x
        for i, c in enumerate(chs):
            drw.text((cx, y), c, font=font, fill=fill)
            cx += widths[i] + space

    img = Image.new("RGBA", (iw, ih), (0, 0, 0, 0))
    # soft cool glow
    glow = Image.new("RGBA", (iw, ih), (0, 0, 0, 0))
    draw_spaced(ImageDraw.Draw(glow), x0, y0, GLOW)
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(12)))
    # drop shadow
    sh = Image.new("RGBA", (iw, ih), (0, 0, 0, 0))
    draw_spaced(ImageDraw.Draw(sh), x0, y0 + 4, (0, 0, 0, 200))
    img = Image.alpha_composite(img, sh.filter(ImageFilter.GaussianBlur(5)))
    # main warm-silver text
    draw_spaced(ImageDraw.Draw(img), x0, y0, OFFWHITE)
    return img


canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
imgs = [render_line(lines[0], main_sz, SPACE)]
if len(lines) > 1:
    imgs.append(render_line(lines[1], sub_sz, SPACE))

gap = 40
total_h = sum(im.height for im in imgs) + gap * (len(imgs) - 1)
y = (H - total_h) // 2
for im in imgs:
    canvas.alpha_composite(im, ((W - im.width) // 2, y))
    y += im.height + gap
canvas.save(out)
print("ending plate ->", out, "| lines:", lines)
