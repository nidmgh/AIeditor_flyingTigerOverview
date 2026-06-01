#!/usr/bin/env python3
# Metallic "飞虎队 / FLYING TIGERS" title plate on a 1920x1080 transparent canvas.
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def _font(env, default):
    """Resolve a font path from an env var (macOS default); fail clearly if absent."""
    p = os.environ.get(env, default)
    if not os.path.exists(p):
        raise SystemExit(f"opening-kit: font not found: {p} (override with {env}=/path/to/font)")
    return p

W, H = 1920, 1080
CJK = _font("OPENING_FONT",     "/System/Library/Fonts/STHeiti Medium.ttc")
LAT = _font("OPENING_LAT_FONT", "/System/Library/Fonts/Supplemental/DIN Condensed Bold.ttf")

def vgrad(w, h, stops):
    """Vertical gradient. stops = [(pos0..1, (r,g,b)), ...]."""
    g = Image.new("RGB", (1, h))
    px = g.load()
    stops = sorted(stops)
    for y in range(h):
        t = y / max(1, h - 1)
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]; p1, c1 = stops[i + 1]
            if p0 <= t <= p1:
                f = (t - p0) / max(1e-6, (p1 - p0))
                px[0, y] = tuple(int(c0[k] + (c1[k] - c0[k]) * f) for k in range(3))
                break
        else:
            px[0, y] = stops[-1][1]
    return g.resize((w, h))

# Classic chrome ramp: light -> bright highlight -> dark horizon -> light reflection
STEEL = [(0.0,(216,222,229)),(0.34,(255,255,255)),(0.50,(150,159,170)),
         (0.52,(86,93,103)),(0.72,(170,178,188)),(1.0,(214,220,227))]

def metal_text(text, font, gradient_stops, stroke=6, glow=True, letter_space=0):
    """Render gradient-filled text with dark stroke, drop shadow, outer glow.
    Returns an RGBA image sized to the text plus padding."""
    pad = 60
    # measure (with optional letter spacing for Latin)
    tmp = Image.new("L", (10, 10)); d = ImageDraw.Draw(tmp)
    if letter_space:
        widths = [d.textbbox((0,0), ch, font=font, stroke_width=stroke)[2] for ch in text]
        tw = sum(widths) + letter_space * (len(text)-1)
        bb = d.textbbox((0,0), text, font=font, stroke_width=stroke)
        th = bb[3]-bb[1]; ty0 = bb[1]
    else:
        bb = d.textbbox((0,0), text, font=font, stroke_width=stroke)
        tw = bb[2]-bb[0]; th = bb[3]-bb[1]; ty0 = bb[1]
    iw, ih = tw + pad*2, th + pad*2

    def draw_text(drw, x, y, **kw):
        if letter_space:
            cx = x
            for i, ch in enumerate(text):
                drw.text((cx, y), ch, font=font, **kw)
                cx += widths[i] + letter_space
        else:
            drw.text((x, y), text, font=font, **kw)

    ox, oy = pad, pad - ty0
    # glyph mask
    mask = Image.new("L", (iw, ih), 0); md = ImageDraw.Draw(mask)
    draw_text(md, ox, oy, fill=255, stroke_width=stroke, stroke_fill=255)
    # gradient fill clipped to mask
    grad = vgrad(iw, ih, gradient_stops).convert("RGBA")
    grad.putalpha(mask)
    out = Image.new("RGBA", (iw, ih), (0,0,0,0))
    # outer glow (soft, cool)
    if glow:
        gl = Image.new("RGBA", (iw, ih), (0,0,0,0)); gd = ImageDraw.Draw(gl)
        draw_text(gd, ox, oy, fill=(120,180,255,255), stroke_width=stroke, stroke_fill=(120,180,255,255))
        gl = gl.filter(ImageFilter.GaussianBlur(16))
        out = Image.alpha_composite(out, gl)
    # drop shadow
    sh = Image.new("RGBA", (iw, ih), (0,0,0,0)); sd = ImageDraw.Draw(sh)
    draw_text(sd, ox, oy+6, fill=(0,0,0,200), stroke_width=stroke, stroke_fill=(0,0,0,200))
    sh = sh.filter(ImageFilter.GaussianBlur(7))
    out = Image.alpha_composite(out, sh)
    # dark outline for definition
    ol = Image.new("RGBA", (iw, ih), (0,0,0,0)); od = ImageDraw.Draw(ol)
    draw_text(od, ox, oy, fill=(20,24,30,255), stroke_width=stroke, stroke_fill=(20,24,30,255))
    out = Image.alpha_composite(out, ol)
    # metal fill on top
    out = Image.alpha_composite(out, grad)
    return out

cjk = ImageFont.truetype(CJK, 300)
lat = ImageFont.truetype(LAT, 132)

main = metal_text("飞虎队", cjk, STEEL, stroke=8)
sub  = metal_text("FLYING TIGERS", lat, STEEL, stroke=4, letter_space=24)

canvas = Image.new("RGBA", (W, H), (0,0,0,0))
mx = (W - main.width)//2; my = H//2 - main.height//2 - 40
canvas.alpha_composite(main, (mx, my))
sx = (W - sub.width)//2; sy = my + main.height - 30
canvas.alpha_composite(sub, (sx, sy))
canvas.save("plates/title.png")

# Bright white silhouette for the reveal flash
flash = Image.new("RGBA", (W, H), (0,0,0,0))
for im, (x,y) in ((main,(mx,my)),(sub,(sx,sy))):
    a = im.split()[3]
    white = Image.new("RGBA", im.size, (255,255,255,0)); white.putalpha(a)
    flash.alpha_composite(white, (x,y))
flash.filter(ImageFilter.GaussianBlur(3)).save("plates/title_flash.png")
print("title.png + title_flash.png written:", canvas.size)
