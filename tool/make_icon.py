"""Builds the app icon files in assets/icon/ from the source artwork.

Source: assets/icon/source/imposter_game_icon.png (a rounded-square icon on a
white page). The rounded square is cropped out and its white corners are
filled with the surrounding colors, so each platform can apply its own mask.

Run: python3 tool/make_icon.py  (needs Pillow; then: dart run flutter_launcher_icons)
"""
from PIL import Image, ImageChops, ImageDraw, ImageFilter

SRC = "assets/icon/source/imposter_game_icon.png"
OUT = "assets/icon"
SIZE = 1024
# Android adaptive icons show the middle 72dp of a 108dp layer.
ADAPTIVE_VISIBLE = 72 / 108


def content_box(img):
    """Bounding box of everything that is not the white page."""
    gray = img.convert("L").point(lambda v: 255 if v < 235 else 0)
    return gray.getbbox()


def full_bleed(img):
    box = content_box(img)
    art = img.crop(box).resize((SIZE, SIZE), Image.LANCZOS)
    # Corner fill: the art's inner region stretched and blurred, so the
    # corners pick up the nearby orange (top) and purple (bottom).
    inset = SIZE // 7
    fill = (
        art.crop((inset, inset, SIZE - inset, SIZE - inset))
        .resize((SIZE, SIZE), Image.LANCZOS)
        .filter(ImageFilter.GaussianBlur(40))
    )
    # Keep the art inside a rounded square slightly rounder than the
    # artwork's own corners (so white lettering is never mistaken for page),
    # plus anything else that is not white page.
    inner = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(inner).rounded_rectangle(
        [0, 0, SIZE - 1, SIZE - 1], int(SIZE * 0.3), fill=255
    )
    not_page = art.convert("L").point(lambda v: 255 if v < 235 else 0)
    not_page = not_page.filter(ImageFilter.MinFilter(5)).filter(
        ImageFilter.GaussianBlur(2)
    )
    keep = ImageChops.lighter(inner, not_page)
    return Image.composite(art, fill, keep)


def main():
    src = Image.open(SRC).convert("RGB")
    icon = full_bleed(src)
    icon.save(f"{OUT}/app_icon.png")

    background = icon.filter(ImageFilter.GaussianBlur(60))
    background.save(f"{OUT}/app_icon_background.png")

    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    side = round(SIZE * ADAPTIVE_VISIBLE)
    offset = (SIZE - side) // 2
    fg.paste(icon.resize((side, side), Image.LANCZOS).convert("RGBA"), (offset, offset))
    fg.save(f"{OUT}/app_icon_foreground.png")


if __name__ == "__main__":
    main()
