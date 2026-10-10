"""Store art for THE NIGHT MANAGER, built from the Blender key-art renders (art/blender/hero.py, thumbnail.py) (the studio logo is deliberately NOT on game art: popular games
use their own title logo, and the studio name lives on the group page). Run:  scripts/blender.sh art/blender/hero.py && python3 brand/make_store_art.py
Outputs: store_icon_512.png (square icon: silhouette + wordmark), store_thumb_hero.png and store_thumb_corridor.png
(1920x1080 thumbnails), store_thumb_key.png (1920x1080 key art for the detail-page carousel)."""
import pathlib
import random

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

HERE = pathlib.Path(__file__).parent
ROOT = HERE.parent
LATO_BLACK = "/usr/share/fonts/truetype/lato/Lato-Black.ttf"
LATO_BOLD = "/usr/share/fonts/truetype/lato/Lato-Bold.ttf"
RED = (222, 38, 50)
BONE = (240, 234, 226)


def grain(img, amount=9):
    rnd = random.Random(5)
    noise = Image.effect_noise(img.size, 38).convert("RGB")
    noise = ImageEnhance.Brightness(noise).enhance(0.5)
    return Image.blend(img, Image.blend(img, noise, 0.5), amount / 100)


def vignette(img, strength=0.7):
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).ellipse((-w * 0.2, -h * 0.2, w * 1.2, h * 1.2), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(w * 0.1))
    dark = Image.new("RGB", (w, h), (0, 0, 0))
    return Image.composite(img, dark, mask.point(lambda v: int(255 * (1 - strength) + v * strength)))


def bottom_fade(img, height_frac=0.42, strength=0.9):
    w, h = img.size
    fade = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(fade)
    start = int(h * (1 - height_frac))
    for y in range(start, h):
        d.line((0, y, w, y), fill=int(255 * strength * ((y - start) / (h - start)) ** 1.4))
    return Image.composite(Image.new("RGB", (w, h), (4, 3, 8)), img, fade)


def shadowed(draw, xy, text, font, fill, spread=5):
    x, y = xy
    for dx in range(-spread, spread + 1, 2):
        for dy in range(-spread, spread + 1, 2):
            draw.text((x + dx, y + dy), text, font=font, fill=(0, 0, 0))
    draw.text((x, y), text, font=font, fill=fill)


def tracked(draw, xy, text, font, fill, tracking, spread=4):
    x, y = xy
    for ch in text:
        shadowed(draw, (x, y), ch, font, fill, spread)
        x += draw.textlength(ch, font=font) + tracking
    return x


def width_of(draw, text, font, tracking):
    return sum(draw.textlength(c, font=font) + tracking for c in text) - tracking


def logo(size):
    return Image.open(ROOT / "art/research/group_icon.png").convert("RGBA").resize((size, size), Image.LANCZOS)


def wordmark(img, anchor_x, baseline_y, scale=1.0, centered=False):
    d = ImageDraw.Draw(img)
    top = ImageFont.truetype(LATO_BOLD, int(46 * scale))
    big = ImageFont.truetype(LATO_BLACK, int(150 * scale))
    tr_top, tr_big = int(14 * scale), int(6 * scale)
    wt, wb = width_of(d, "THE", top, tr_top), width_of(d, "NIGHT MANAGER", big, tr_big)
    x = anchor_x - (wb / 2 if centered else 0)
    tracked(d, (x + (wb - wt) / 2 if centered else x, baseline_y - 150 * scale - 54 * scale), "THE", top, (190, 186, 196), tr_top, 3)
    tracked(d, (x, baseline_y - 150 * scale), "NIGHT MANAGER", big, BONE, tr_big, 5)
    return wb


def finish(img):
    return grain(vignette(ImageEnhance.Contrast(img).enhance(1.06), 0.55))


def icon():
    face = Image.open(ROOT / "art/renders/hero_icon.png").convert("RGB")
    img = face.crop((60, 40, 964, 944)).resize((512, 512), Image.LANCZOS)
    img = bottom_fade(img, 0.34, 0.92)
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(LATO_BLACK, 52)
    for line, y in (("NIGHT", 392), ("MANAGER", 440)):
        w = width_of(d, line, font, 3)
        tracked(d, (256 - w / 2, y), line, font, BONE if line == "NIGHT" else RED, 3, 3)
    return grain(vignette(img, 0.4), 6)


def thumb_hero():
    img = Image.open(ROOT / "art/renders/hero_wide.png").convert("RGB").resize((1920, 1080), Image.LANCZOS)
    img = bottom_fade(finish(img), 0.3, 0.85)
    wordmark(img, 90, 1030, 0.62)
    return img


def thumb_corridor():
    img = Image.open(HERE / "thumbnail_corridor.png").convert("RGB").resize((1920, 1080), Image.LANCZOS)
    img = bottom_fade(finish(img), 0.3, 0.8)
    wordmark(img, 90, 1030, 0.62)
    return img


def thumb_key():
    face = Image.open(ROOT / "art/renders/hero_icon.png").convert("RGB")
    canvas = Image.new("RGB", (1920, 1080), (6, 5, 12))
    big = face.resize((1080, 1080), Image.LANCZOS)
    canvas.paste(big, (420, 0))
    fade = Image.new("L", (1920, 1080), 255)
    fd = ImageDraw.Draw(fade)
    for x in range(420, 760):
        fd.line((x, 0, x, 1080), fill=int(255 * (x - 420) / 340))
    for x in range(1180, 1500):
        fd.line((x, 0, x, 1080), fill=int(255 * (1 - (x - 1180) / 320)))
    fd.rectangle((0, 0, 420, 1080), fill=0)
    fd.rectangle((1500, 0, 1920, 1080), fill=0)
    canvas = Image.composite(canvas, Image.new("RGB", (1920, 1080), (6, 5, 12)), fade)
    img = bottom_fade(finish(canvas), 0.28, 0.9)
    wordmark(img, 960, 1030, 0.62, centered=True)
    return img


if __name__ == "__main__":
    icon().save(HERE / "store_icon_512.png")
    thumb_hero().save(HERE / "store_thumb_hero.png")
    thumb_corridor().save(HERE / "store_thumb_corridor.png")
    thumb_key().save(HERE / "store_thumb_key.png")
    print("wrote store_icon_512.png, store_thumb_hero.png, store_thumb_corridor.png, store_thumb_key.png")
