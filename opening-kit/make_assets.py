#!/usr/bin/env python3
# Atmosphere layers for the intro: bg glow, lens-flare streak, ember particles.
from PIL import Image, ImageDraw, ImageFilter
import random
random.seed(1941)
W, H = 1920, 1080

# --- background: deep blue-black with a soft radial glow low-center + vignette ---
bg = Image.new("RGB", (W, H), (8, 12, 20))
glow = Image.new("L", (W, H), 0)
gd = ImageDraw.Draw(glow)
cx, cy = W//2, int(H*0.58)
gd.ellipse([cx-680, cy-380, cx+680, cy+380], fill=255)
glow = glow.filter(ImageFilter.GaussianBlur(220))
blue = Image.new("RGB", (W, H), (30, 70, 130))
bg = Image.composite(blue, bg, glow.point(lambda v: int(v*0.5)))
# vignette
vig = Image.new("L", (W, H), 0)
vd = ImageDraw.Draw(vig)
vd.ellipse([-300, -300, W+300, H+300], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(300))
black = Image.new("RGB", (W, H), (3, 5, 9))
bg = Image.composite(bg, black, vig)
bg.save("plates/bg.png")

# --- lens-flare streak: anamorphic horizontal light bar + bright core (additive) ---
fl = Image.new("RGBA", (W, H), (0,0,0,0))
fd = ImageDraw.Draw(fl)
yc = int(H*0.52)
fd.rectangle([0, yc-3, W, yc+3], fill=(150,200,255,255))       # thin streak
fd.ellipse([W//2-60, yc-60, W//2+60, yc+60], fill=(200,225,255,255))  # core bloom
fl = fl.filter(ImageFilter.GaussianBlur(6))
# brighter pinpoint core
fd2 = ImageDraw.Draw(fl)
fd2.ellipse([W//2-10, yc-10, W//2+10, yc+10], fill=(255,255,255,255))
fl.save("plates/flare.png")

# --- embers: scattered warm + few cool soft dots (additive, will drift up) ---
em = Image.new("RGBA", (W, H), (0,0,0,0))
ed = ImageDraw.Draw(em)
for _ in range(70):
    x = random.randint(0, W); y = random.randint(0, H)
    r = random.choice([2,2,3,3,4,5])
    if random.random() < 0.78:
        c = (255, random.randint(120,180), random.randint(20,60), random.randint(90,200))  # ember
    else:
        c = (140, 190, 255, random.randint(70,150))  # cool spark
    ed.ellipse([x-r, y-r, x+r, y+r], fill=c)
em = em.filter(ImageFilter.GaussianBlur(1.2))
em.save("plates/embers.png")
print("bg.png, flare.png, embers.png written")
