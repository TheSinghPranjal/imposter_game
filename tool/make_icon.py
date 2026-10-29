"""Generates the app icon artwork in assets/icon/.

Run: python3 tool/make_icon.py  (then: dart run flutter_launcher_icons)
"""
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SS = 4  # supersampling factor
N = 1024 * SS
FONT = "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf"

INK = (43, 20, 82)        # AppColors.deepPurple
BODY = (52, 24, 110)
LAVENDER = (190, 150, 255)
YELLOW = (255, 213, 79)   # AppColors.warmYellow
ORANGE = (255, 150, 40)


def background():
    img = Image.new("RGB", (N, N))
    px = img.load()
    cx, cy = N / 2, N * 0.42
    maxd = math.hypot(N / 2, N * 0.6)
    step = SS * 2
    d = ImageDraw.Draw(img)
    for y in range(0, N, step):
        for x in range(0, N, step):
            t = min(math.hypot(x - cx, y - cy) / maxd, 1) ** 1.2
            c = tuple(int(YELLOW[i] + (ORANGE[i] - YELLOW[i]) * t) for i in range(3))
            d.rectangle([x, y, x + step, y + step], fill=c)
    # Sunburst rays.
    rays = Image.new("L", (N, N), 0)
    rd = ImageDraw.Draw(rays)
    for k in range(16):
        a0 = math.radians(k * 22.5)
        a1 = a0 + math.radians(11.25)
        r = N * 1.5
        rd.polygon([(cx, cy),
                    (cx + r * math.cos(a0), cy + r * math.sin(a0)),
                    (cx + r * math.cos(a1), cy + r * math.sin(a1))], fill=38)
    img.paste((255, 255, 255), mask=rays)
    return img


def silhouette(size, scale=1.0, oy=0.0, body=0.9):
    """Bear-shaped mystery character with a '?' — RGBA, transparent bg."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s = size * scale
    cx = size / 2
    top = size / 2 - s * 0.36 + oy * size

    def shape(draw, grow, fill):
        g = grow
        # ears
        for ex in (-0.23, 0.23):
            draw.ellipse([cx + ex * s - s * 0.1 - g, top + s * 0.02 - g,
                          cx + ex * s + s * 0.1 + g, top + s * 0.22 + g], fill=fill)
        # shoulders / body
        draw.ellipse([cx - s * 0.42 - g, top + s * 0.60 - g,
                      cx + s * 0.42 + g, top + s * (0.60 + body) + g], fill=fill)
        # head
        draw.ellipse([cx - s * 0.30 - g, top + s * 0.06 - g,
                      cx + s * 0.30 + g, top + s * 0.64 + g], fill=fill)

    # soft drop shadow
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shape(ImageDraw.Draw(shadow), s * 0.03, (60, 20, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(s * 0.025))
    layer.alpha_composite(shadow, (0, int(s * 0.03)))

    d = ImageDraw.Draw(layer)
    shape(d, s * 0.028, (255, 255, 255, 255))  # white sticker rim
    shape(d, 0, BODY + (255,))
    # inner ear tint
    for ex in (-0.23, 0.23):
        d.ellipse([cx + ex * s - s * 0.05, top + s * 0.07,
                   cx + ex * s + s * 0.05, top + s * 0.17], fill=INK + (255,))

    # "surprise" marks above the head, like the home artwork
    w = int(s * 0.028)
    for ang in (-24, 0, 24):
        a = math.radians(ang - 90)
        r0, r1 = s * 0.45, s * 0.53
        oyh = top + s * 0.36
        d.line([(cx + r0 * math.cos(a), oyh + r0 * math.sin(a)),
                (cx + r1 * math.cos(a), oyh + r1 * math.sin(a))],
               fill=(255, 255, 255, 255), width=w)
        for r in (r0, r1):
            x, y = cx + r * math.cos(a), oyh + r * math.sin(a)
            d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2],
                      fill=(255, 255, 255, 255))

    font = ImageFont.truetype(FONT, int(s * 0.42))
    d.text((cx, top + s * 0.37), "?", font=font, fill=LAVENDER + (255,),
           anchor="mm")
    return layer


def downsample(img):
    return img.resize((1024, 1024), Image.LANCZOS)


full = background().convert("RGBA")
full.alpha_composite(silhouette(N, scale=0.9, oy=0.1))
downsample(full).convert("RGB").save("assets/icon/app_icon.png")

# Android adaptive foreground: artwork must fit the central ~66% safe zone.
fg = silhouette(N, scale=0.64, oy=0.06)
downsample(fg).save("assets/icon/app_icon_foreground.png")
downsample(background()).save("assets/icon/app_icon_background.png")
