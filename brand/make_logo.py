"""Draws the Nexus Hollow Studios logo with Pillow (no other tools needed) and writes:
   brand/icon_512.png        square mark (game or group icon)
   brand/banner_1920x1080.png  wordmark on a dark background (thumbnail / TikTok end card base)
Run:  python3 brand/make_logo.py
The vector master is brand/logo.svg (same shapes)."""
import math
import pathlib

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

HERE = pathlib.Path(__file__).parent
CYAN = (56, 232, 255)
MAGENTA = (193, 75, 255)
DEEP = (24, 12, 56)
NIGHT = (7, 4, 15)
LATO_BLACK = "/usr/share/fonts/truetype/lato/Lato-Black.ttf"
LATO_BOLD = "/usr/share/fonts/truetype/lato/Lato-Bold.ttf"


def hexagon(cx, cy, r, rotate=0.0):
    return [(cx + r * math.cos(math.radians(60 * i + rotate)), cy + r * math.sin(math.radians(60 * i + rotate))) for i in range(6)]


def gradient(size, a, b, vertical=False):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (y / max(h - 1, 1)) if vertical else (x / max(w - 1, 1))
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
    return img


def radial(size, inner, outer):
    w, h = size
    img = Image.new("RGB", size)
    px = img.load()
    cx, cy = w / 2, h / 2
    rmax = math.hypot(cx, cy)
    for y in range(h):
        for x in range(w):
            t = min(math.hypot(x - cx, y - cy) / rmax, 1.0)
            px[x, y] = tuple(int(inner[i] + (outer[i] - inner[i]) * t) for i in range(3))
    return img


def draw_mark(size=2048, with_bg=True):
    """The mark: a hollow hexagon (the Hollow) with an N cut through it and glowing nodes (the Nexus)."""
    S = size
    if with_bg:
        canvas = radial((S // 8, S // 8), DEEP, NIGHT).resize((S, S), Image.BICUBIC).convert("RGBA")
    else:
        canvas = Image.new("RGBA", (S, S), (0, 0, 0, 0))  # transparent: sits on any background
    c = S / 2
    # the hollow hexagon ring as a mask: outer minus inner
    ring = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(ring)
    d.polygon(hexagon(c, c, S * 0.40, 30), fill=255)
    d.polygon(hexagon(c, c, S * 0.31, 30), fill=0)
    ring_color = gradient((S, S), CYAN, MAGENTA).convert("RGBA")
    # glow behind the ring
    glow = ring.filter(ImageFilter.GaussianBlur(S * 0.02))
    glow_layer = Image.new("RGBA", (S, S), CYAN + (0,))
    glow_layer.putalpha(glow.point(lambda v: int(v * 0.55)))
    canvas = Image.alpha_composite(canvas, glow_layer)
    ring_layer = ring_color.copy()
    ring_layer.putalpha(ring)
    canvas = Image.alpha_composite(canvas, ring_layer)
    # the N: two bars and a diagonal, inside the hollow
    n = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(n)
    w = S * 0.065
    left, right = c - S * 0.12, c + S * 0.12
    top, bottom = c - S * 0.16, c + S * 0.16
    d.rectangle([left - w / 2, top, left + w / 2, bottom], fill=255)
    d.rectangle([right - w / 2, top, right + w / 2, bottom], fill=255)
    d.polygon([(left - w / 2, top), (left + w / 2 + w * 0.2, top), (right + w / 2, bottom), (right - w / 2 - w * 0.2, bottom)], fill=255)
    n_color = gradient((S, S), MAGENTA, CYAN, vertical=True).convert("RGBA")
    n_glow = n.filter(ImageFilter.GaussianBlur(S * 0.012))
    gl = Image.new("RGBA", (S, S), MAGENTA + (0,))
    gl.putalpha(n_glow.point(lambda v: int(v * 0.6)))
    canvas = Image.alpha_composite(canvas, gl)
    n_layer = n_color.copy()
    n_layer.putalpha(n)
    canvas = Image.alpha_composite(canvas, n_layer)
    # nodes on the six corners of the hexagon, joined to a bright core by faint lines
    pts = hexagon(c, c, S * 0.355, 30)
    lines = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lines)
    for p in pts:
        ld.line([(c, c), p], fill=(255, 255, 255, 38), width=int(S * 0.004))
    canvas = Image.alpha_composite(canvas, lines)
    nodes = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    nd = ImageDraw.Draw(nodes)
    for i, p in enumerate(pts):
        r = S * 0.026
        nd.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=(255, 255, 255, 255))
    node_glow = nodes.filter(ImageFilter.GaussianBlur(S * 0.012))
    canvas = Image.alpha_composite(canvas, node_glow)
    canvas = Image.alpha_composite(canvas, nodes)
    return canvas


def fit_font(path, text, max_width, start):
    size = start
    while size > 10:
        font = ImageFont.truetype(path, size)
        if font.getlength(text) <= max_width:
            return font
        size -= 4
    return ImageFont.truetype(path, 10)


def banner(mark, w=1920, h=1080):
    img = radial((w // 8, h // 8), DEEP, NIGHT).resize((w, h), Image.BICUBIC).convert("RGBA")
    m = mark.resize((int(h * 0.58), int(h * 0.58)), Image.LANCZOS)
    img.alpha_composite(m, ((w - m.width) // 2, int(h * 0.04)))
    d = ImageDraw.Draw(img)
    title = fit_font(LATO_BLACK, "NEXUS HOLLOW", w * 0.78, 220)
    sub = fit_font(LATO_BOLD, "S T U D I O S", w * 0.40, 80)
    ty = int(h * 0.63)
    tw = title.getlength("NEXUS HOLLOW")
    d.text(((w - tw) / 2, ty), "NEXUS HOLLOW", font=title, fill=(255, 255, 255, 255))
    sw = sub.getlength("S T U D I O S")
    sub_y = ty + title.size * 1.18
    assert sub_y + sub.size < h - 30, "the subtitle must fit inside the picture"
    d.text(((w - sw) / 2, sub_y), "S T U D I O S", font=sub, fill=CYAN + (255,))
    return img


if __name__ == "__main__":
    mark = draw_mark(2048)
    mark.resize((512, 512), Image.LANCZOS).convert("RGB").save(HERE / "icon_512.png", optimize=True)
    banner(draw_mark(2048, with_bg=False)).convert("RGB").save(HERE / "banner_1920x1080.png", optimize=True)
    print("wrote icon_512.png and banner_1920x1080.png")
