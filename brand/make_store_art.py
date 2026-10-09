"""Store art for THE NIGHT MANAGER from the real renders and the studio logo (used unchanged, only resized):
   brand/store_icon_512.png         game icon (the Night Manager's face)
   brand/store_thumb_corridor.png   1920x1080 thumbnail: the corridor, him at the end
   brand/store_thumb_face.png       1920x1080 thumbnail: the face close-up
Run:  scripts/blender.sh art/blender/icon.py && python3 brand/make_store_art.py"""
import pathlib

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont

HERE = pathlib.Path(__file__).parent
ROOT = HERE.parent
LATO_BLACK = "/usr/share/fonts/truetype/lato/Lato-Black.ttf"
LATO_BOLD = "/usr/share/fonts/truetype/lato/Lato-Bold.ttf"
RED = (214, 40, 52)
AMBER = (255, 190, 90)


def vignette(img, strength=0.75):
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).ellipse((-w * 0.25, -h * 0.25, w * 1.25, h * 1.25), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(w * 0.12))
    dark = Image.new("RGB", (w, h), (0, 0, 0))
    return Image.composite(img, dark, mask.point(lambda v: int(255 * (1 - strength) + v * strength)))


def text_with_shadow(draw, xy, text, font, fill, shadow=(0, 0, 0), spread=4):
    x, y = xy
    for dx in range(-spread, spread + 1, 2):
        for dy in range(-spread, spread + 1, 2):
            draw.text((x + dx, y + dy), text, font=font, fill=shadow)
    draw.text((x, y), text, font=font, fill=fill)


def logo(size):
    return Image.open(ROOT / "art/research/group_icon.png").convert("RGBA").resize((size, size), Image.LANCZOS)


def thumbnail_corridor():
    img = Image.open(HERE / "thumbnail_corridor.png").convert("RGB").resize((1920, 1080), Image.LANCZOS)
    img = vignette(ImageEnhance.Contrast(img).enhance(1.08), 0.6)
    d = ImageDraw.Draw(img)
    big = ImageFont.truetype(LATO_BLACK, 170)
    small = ImageFont.truetype(LATO_BOLD, 54)
    text_with_shadow(d, (90, 670), "THE NIGHT", big, (240, 236, 232))
    text_with_shadow(d, (90, 820), "MANAGER", big, RED)
    text_with_shadow(d, (96, 980), "HE HEARS EVERYTHING.", small, AMBER, spread=2)
    mark = logo(120)
    img.paste(mark, (1920 - 120 - 60, 60), mark)
    return img


def thumbnail_face():
    face = Image.open(ROOT / "art/renders/icon_face.png").convert("RGB")
    canvas = Image.new("RGB", (1920, 1080), (9, 8, 14))
    zoom = face.resize((1080, 1080), Image.LANCZOS)
    canvas.paste(zoom, (840, 0))
    # fade the face image into the dark on its left edge
    fade = Image.new("L", (1920, 1080), 255)
    fd = ImageDraw.Draw(fade)
    for x in range(840, 1240):
        fd.line((x, 0, x, 1080), fill=int(255 * (x - 840) / 400))
    dark = Image.new("RGB", (1920, 1080), (9, 8, 14))
    left = Image.composite(canvas, dark, fade.point(lambda v: v if v < 255 else 255))
    canvas.paste(left.crop((0, 0, 1240, 1080)), (0, 0))
    img = vignette(canvas, 0.55)
    d = ImageDraw.Draw(img)
    big = ImageFont.truetype(LATO_BLACK, 150)
    small = ImageFont.truetype(LATO_BOLD, 52)
    text_with_shadow(d, (80, 330), "THE NIGHT", big, (240, 236, 232))
    text_with_shadow(d, (80, 490), "MANAGER", big, RED)
    text_with_shadow(d, (86, 680), "Run. Hide. Vote.", small, AMBER, spread=2)
    text_with_shadow(d, (86, 750), "Survive the night shift.", small, (200, 196, 210), spread=2)
    mark = logo(120)
    img.paste(mark, (80, 1080 - 120 - 60), mark)
    return img


def icon():
    face = Image.open(ROOT / "art/renders/icon_face.png").convert("RGB")
    crop = face.crop((150, 110, 874, 834)).resize((512, 512), Image.LANCZOS)
    crop = ImageEnhance.Brightness(crop).enhance(0.85)
    return vignette(crop, 0.55)


if __name__ == "__main__":
    icon().save(HERE / "store_icon_512.png")
    thumbnail_corridor().save(HERE / "store_thumb_corridor.png")
    thumbnail_face().save(HERE / "store_thumb_face.png")
    print("wrote store_icon_512.png, store_thumb_corridor.png, store_thumb_face.png")
