"""Hotel props. Usage: scripts/blender.sh art/blender/props.py -- armchair|desk|chandelier|bed|lamp|shelf|crate|locker|wardrobe|rack|furnace|generator|table|car|tub"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *

VELVET = lambda: mat("velvet", (0.17, 0.012, 0.03), 0.9)
WOOD = lambda: mat("walnut", (0.11, 0.05, 0.022), 0.35)
BRASS = lambda: mat("brass", (0.85, 0.58, 0.22), 0.22, 1.0)
MARBLE = lambda: mat("marble", (0.82, 0.8, 0.78), 0.12)
CREAM = lambda: mat("linen", (0.78, 0.74, 0.66), 0.95)
GLOW = lambda: mat("glow", (1, 0.75, 0.4), 0.3, emit=(1.0, 0.65, 0.3))

def armchair():
    v, w, b = VELVET(), WOOD(), BRASS()
    box("seat", (0.84, 0.78, 0.2), (0, 0, 0.38), v, 0.07, 0)
    box("back", (0.84, 0.18, 0.78), (0, 0.33, 0.75), v, 0.08, 0)
    for s in (-1, 1):
        box("arm", (0.16, 0.74, 0.3), (s*0.49, 0, 0.56), v, 0.06, 0)
        for y in (-1, 1):
            cone("leg", 0.05, 0.03, 0.3, (s*0.37, y*0.31, 0.15), w, 16)
            cyl("cap", 0.032, 0.02, (s*0.37, y*0.31, 0.01), b, 16)
    for ix in (-1, 0, 1):
        for iz in (0, 1):
            sphere("button", 0.02, (ix*0.22, 0.235, 0.62 + iz*0.22), b, (1, 0.6, 1))
    box("trim", (0.86, 0.02, 0.04), (0, -0.4, 0.3), b, 0.005)
    studio((0, 0, 0.45), 3.2)

def desk():
    w, m, b = WOOD(), MARBLE(), BRASS()
    box("body", (3.0, 0.85, 1.05), (0, 0, 0.525), w, 0.03, 0)
    box("top", (3.2, 1.0, 0.07), (0, 0, 1.085), m, 0.012, 0)
    for i in range(5):
        box("panel", (0.46, 0.03, 0.7), (-1.2 + i*0.6, -0.43, 0.55), w, 0.015, 0)
        box("frame", (0.54, 0.02, 0.78), (-1.2 + i*0.6, -0.425, 0.55), b, 0.008, 0)
    cyl("rail", 0.025, 3.0, (0, -0.55, 0.12), b, 20).rotation_euler = (0, 1.5708, 0)
    box("plinth", (3.05, 0.9, 0.08), (0, 0, 0.04), mat("dark", (0.03, 0.02, 0.015), 0.5), 0.01)
    cyl("bellbase", 0.07, 0.02, (-0.9, -0.1, 1.13), b, 24)
    sphere("bell", 0.06, (-0.9, -0.1, 1.16), b, (1, 1, 0.6))
    studio((0, 0, 0.6), 5.0, 20, 30)

def chandelier():
    import math
    b, g = BRASS(), GLOW()
    crystal = mat("crystal", (0.85, 0.92, 1.0), 0.04)
    cyl("canopy", 0.12, 0.05, (0, 0, 2.05), b, 24)
    cyl("stem", 0.025, 0.75, (0, 0, 1.65), b, 16)
    sphere("knob", 0.09, (0, 0, 1.25), b, (1, 1, 1.5))
    torus("ring", 0.55, 0.022, (0, 0, 1.0), b)
    torus("ring2", 0.28, 0.018, (0, 0, 1.2), b)
    sphere("finial", 0.05, (0, 0, 0.9), b, (1, 1, 1.8))
    for i in range(8):
        a = i * math.tau / 8
        c, s_ = math.cos(a), math.sin(a)
        # S-curve arm from the knob out to the ring, built from three beams
        beam("arm1", (c*0.05, s_*0.05, 1.25), (c*0.28, s_*0.28, 1.2), 0.012, b)
        beam("arm2", (c*0.28, s_*0.28, 1.2), (c*0.5, s_*0.5, 1.06), 0.012, b)
        beam("arm3", (c*0.5, s_*0.5, 1.06), (c*0.55, s_*0.55, 1.0), 0.012, b)
        cyl("cup", 0.032, 0.05, (c*0.55, s_*0.55, 1.05), b, 12)
        cyl("candle", 0.016, 0.1, (c*0.55, s_*0.55, 1.13), mat("wax", (0.9, 0.86, 0.75), 0.6), 12)
        cone("flame", 0.016, 0.0, 0.05, (c*0.55, s_*0.55, 1.2), g, 10)
        for k in range(4):
            gem("drop", 0.016, (c*0.55, s_*0.55, 0.93 - k*0.055), crystal)
    for i in range(16):
        a = i * math.tau / 16
        gem("rim", 0.014, (math.cos(a)*0.28, math.sin(a)*0.28, 1.14), crystal)
    studio((0, 0, 1.15), 3.4, 6, 25)

def bed():
    w, c, v = WOOD(), CREAM(), VELVET()
    box("base", (1.6, 2.1, 0.3), (0, 0, 0.25), w, 0.03, 0)
    box("mattress", (1.5, 2.0, 0.22), (0, 0, 0.51), c, 0.08, 0)
    box("blanket", (1.54, 1.25, 0.1), (0, -0.37, 0.64), v, 0.04, 0)
    box("fold", (1.56, 0.25, 0.13), (0, 0.27, 0.66), v, 0.05, 0)
    box("headboard", (1.7, 0.12, 1.2), (0, 1.0, 0.75), w, 0.04, 0)
    for ix in (-1, 0, 1):
        for iz in (0, 1):
            sphere("tuft", 0.03, (ix*0.5, 0.93, 0.7 + iz*0.35), BRASS())
    for x in (-0.38, 0.38):
        sphere("pillow", 0.3, (x, 0.72, 0.72), c, (1.1, 0.8, 0.38))
    studio((0, 0, 0.55), 4.6, 28, 40)

def lamp():
    b, g, w = BRASS(), GLOW(), WOOD()
    cyl("base", 0.12, 0.04, (0, 0, 0.02), b, 32)
    cyl("stem", 0.015, 0.4, (0, 0, 0.24), b, 12)
    sphere("belly", 0.07, (0, 0, 0.14), b, (1, 1, 1.2))
    cone("shade", 0.2, 0.12, 0.26, (0, 0, 0.55), g)
    sphere("bulb", 0.05, (0, 0, 0.45), mat("bulb", (1, 0.9, 0.7), 0.2, emit=(1, 0.8, 0.5)))
    box("table", (0.8, 0.5, 0.04), (0, 0, -0.02), w, 0.01)
    studio((0, 0, 0.3), 1.8, 18, 30)

def shelf():
    w, b = WOOD(), None
    books = [mat("b%d" % i, c, 0.7) for i, c in enumerate([(0.3, 0.05, 0.06), (0.06, 0.15, 0.3), (0.3, 0.25, 0.1), (0.1, 0.25, 0.14), (0.45, 0.38, 0.28)])]
    for x in (-0.58, 0.58):
        box("side", (0.05, 0.35, 1.8), (x, 0, 0.9), w, 0.008, 0)
    box("back", (1.16, 0.03, 1.8), (0, 0.16, 0.9), w, 0.004, 0)
    for r in range(5):
        z = 0.04 + r * 0.43
        box("board", (1.2, 0.33, 0.035), (0, -0.01, z), mat("light", (0.2, 0.11, 0.06), 0.45), 0.006, 0)
        if r < 4:
            x = -0.52
            i = 0
            while x < 0.5:
                bw = 0.045 + (i * 7 % 4) * 0.015
                bh = 0.25 + (i * 5 % 3) * 0.05
                box("book", (bw, 0.22, bh), (x + bw / 2, -0.03, z + 0.018 + bh / 2), books[(i + r) % 5], 0.004, 0)
                x += bw + 0.008
                i += 1
    studio((0, 0, 0.9), 4.2, 12, 25)

def crate():
    w = mat("planks", (0.25, 0.16, 0.09), 0.75)
    strap = WOOD()
    box("box", (0.6, 0.6, 0.6), (0, 0, 0.3), w, 0.012, 0)
    for z in (0.09, 0.51):
        box("strap", (0.62, 0.62, 0.06), (0, 0, z), strap, 0.006, 0)
    for x in (-0.31, 0.31):
        box("post", (0.06, 0.06, 0.6), (x, -0.31, 0.3), strap, 0.006, 0)
        box("post", (0.06, 0.06, 0.6), (x, 0.31, 0.3), strap, 0.006, 0)
    studio((0, 0, 0.3), 2.2, 22, 35)

def locker():
    steel = mat("steel", (0.18, 0.22, 0.22), 0.45, 0.8)
    box("body", (0.5, 0.5, 1.8), (0, 0, 0.9), steel, 0.015, 0)
    box("door", (0.46, 0.02, 1.7), (0, -0.26, 0.9), mat("door", (0.2, 0.25, 0.25), 0.4, 0.8), 0.006, 0)
    for i in range(3):
        box("vent", (0.34, 0.02, 0.03), (0, -0.275, 1.55 + i * 0.07), mat("dk", (0.02, 0.02, 0.03), 0.6), 0.003, 0)
    cyl("handle", 0.012, 0.18, (0.14, -0.29, 0.9), BRASS(), 12)
    studio((0, 0, 0.9), 4.0, 8, -20)

def wardrobe():
    w = WOOD()
    box("body", (1.0, 0.5, 1.9), (0, 0, 0.95), w, 0.02, 0)
    box("crown", (1.08, 0.56, 0.1), (0, 0, 1.95), mat("light", (0.2, 0.11, 0.06), 0.45), 0.012, 0)
    for x in (-0.24, 0.24):
        box("door", (0.45, 0.03, 1.6), (x, -0.265, 0.95), mat("door", (0.17, 0.09, 0.05), 0.5), 0.01, 0)
        box("panel", (0.33, 0.012, 0.6), (x, -0.285, 1.3), w, 0.006, 0)
        box("panel", (0.33, 0.012, 0.6), (x, -0.285, 0.6), w, 0.006, 0)
        cyl("knob", 0.02, 0.03, (x * 0.35, -0.3, 0.95), BRASS(), 12)
    studio((0, 0, 0.95), 4.6, 10, -22)

def rack():
    w = WOOD()
    glass = mat("glass", (0.03, 0.12, 0.05), 0.15)
    for x in (-0.78, 0.78):
        box("post", (0.05, 0.4, 1.3), (x, 0, 0.65), w, 0.006, 0)
    for r in range(4):
        z = 0.1 + r * 0.38
        box("slat", (1.55, 0.36, 0.03), (0, 0, z), mat("light", (0.2, 0.11, 0.06), 0.45), 0.004, 0)
        for i in range(8):
            c = cyl("bottle", 0.04, 0.3, (-0.68 + i * 0.195, 0, z + 0.07), glass, 16)
            c.rotation_euler = (math.pi / 2, 0, 0)
            cyl("neck", 0.015, 0.1, (-0.68 + i * 0.195, -0.19, z + 0.07), glass, 12).rotation_euler = (math.pi / 2, 0, 0)
    studio((0, 0, 0.65), 4.2, 14, 28)

def furnace():
    rust = mat("rust", (0.22, 0.09, 0.04), 0.8, 0.5)
    steel = mat("steel", (0.18, 0.2, 0.2), 0.5, 0.8)
    fire = mat("fire", (1, 0.4, 0.1), 0.3, emit=(1.0, 0.35, 0.08))
    box("base", (1.3, 1.3, 0.2), (0, 0, 0.1), steel, 0.02, 0)
    cyl("drum", 0.55, 1.6, (0, 0, 1.0), rust, 40)
    for z in (0.5, 1.0, 1.5):
        cyl("band", 0.575, 0.05, (0, 0, z), steel, 40)
    cyl("pipe", 0.12, 0.7, (0.2, 0, 2.15), steel, 20)
    box("door", (0.5, 0.06, 0.5), (0, -0.56, 0.7), mat("dk", (0.03, 0.03, 0.03), 0.5, 0.6), 0.02, 0)
    box("fire", (0.36, 0.02, 0.32), (0, -0.6, 0.7), fire, 0.01, 0)
    studio((0, 0, 1.0), 6.0, 10, -25)

def generator():
    green = mat("green", (0.08, 0.16, 0.1), 0.5, 0.6)
    dark = mat("dk", (0.03, 0.03, 0.04), 0.5, 0.7)
    light = mat("light", (0.2, 1, 0.4), 0.3, emit=(0.2, 1.0, 0.4))
    box("frame", (1.5, 0.85, 0.1), (0, 0, 0.05), dark, 0.01, 0)
    box("body", (1.4, 0.75, 0.75), (0, 0, 0.5), green, 0.04, 0)
    cyl("exhaust", 0.07, 0.3, (0.55, 0, 1.0), dark, 16)
    box("panel", (0.5, 0.02, 0.28), (-0.25, -0.385, 0.55), dark, 0.01, 0)
    for i in range(3):
        sphere("led", 0.025, (-0.4 + i * 0.15, -0.4, 0.62), light)
    for x in (-0.55, 0.55):
        cyl("cap", 0.06, 0.05, (x, -0.2, 0.9), dark, 12)
    studio((0, 0, 0.5), 4.4, 14, -30)

def table():
    w = mat("light", (0.2, 0.11, 0.06), 0.45)
    cloth = VELVET()
    box("top", (3.0, 1.3, 0.09), (0, 0, 0.75), w, 0.012, 0)
    for x in (-1.35, 1.35):
        for y in (-0.5, 0.5):
            box("leg", (0.12, 0.12, 0.72), (x, y, 0.36), WOOD(), 0.012, 0)
    box("runner", (2.6, 0.35, 0.012), (0, 0, 0.805), cloth, 0.003, 0)
    for x in (-0.8, 0, 0.8):
        cyl("stick", 0.025, 0.2, (x, 0, 0.91), BRASS(), 16)
        cyl("candle", 0.018, 0.12, (x, 0, 1.07), mat("wax", (0.9, 0.86, 0.75), 0.6), 12)
        sphere("flame", 0.02, (x, 0, 1.16), GLOW(), (1, 1, 1.8))
    studio((0, 0, 0.7), 6.0, 20, 30)

def car():
    paint = mat("paint", (0.12, 0.03, 0.04), 0.25, 0.7)
    glass = mat("glass", (0.02, 0.04, 0.06), 0.08, 0.2)
    tire = mat("tire", (0.02, 0.02, 0.025), 0.9)
    lamp = mat("lamp", (1, 0.95, 0.8), 0.2, emit=(1.0, 0.9, 0.6))
    chrome = mat("chrome", (0.7, 0.7, 0.72), 0.15, 1.0)
    box("body", (1.8, 4.2, 0.5), (0, 0, 0.58), paint, 0.14, 2)
    tapered("hood", (1.7, 1.5, 0.22), (0, 1.3, 0.9), paint, (0.92, 0.7), 0.05, 0)
    tapered("trunk", (1.7, 1.0, 0.22), (0, -1.6, 0.9), paint, (0.92, 0.7), 0.05, 0)
    tapered("cabin", (1.6, 2.3, 0.5), (0, -0.1, 1.1), glass, (0.78, 0.4), 0.05, 0)
    tapered("roof", (1.12, 0.95, 0.05), (0, -0.1, 1.38), paint, (0.98, 0.95), 0.02, 1)
    for x in (-0.88, 0.88):
        for y in (-1.35, 1.35):
            c = cyl("wheel", 0.33, 0.24, (x, y, 0.33), tire, 32)
            c.rotation_euler = (0, math.pi / 2, 0)
            h = cyl("hub", 0.17, 0.26, (x, y, 0.33), chrome, 20)
            h.rotation_euler = (0, math.pi / 2, 0)
    for x in (-0.55, 0.55):
        sphere("headlight", 0.1, (x, 2.08, 0.68), lamp, (1, 0.5, 0.8))
    box("bumper", (1.7, 0.1, 0.12), (0, 2.12, 0.38), chrome, 0.03, 0)
    box("bumper", (1.7, 0.1, 0.12), (0, -2.12, 0.38), chrome, 0.03, 0)
    studio((0, 0, 0.7), 8.0, 16, 38)

def tub():
    marble = MARBLE()
    water = mat("water", (0.1, 0.35, 0.5), 0.05)
    for y in (-0.55, 0.55):
        box("rim", (2.0, 0.12, 0.5), (0, y, 0.25), marble, 0.02, 0)
    for x in (-0.94, 0.94):
        box("rim", (0.12, 1.0, 0.5), (x, 0, 0.25), marble, 0.02, 0)
    box("water", (1.76, 0.98, 0.04), (0, 0, 0.38), water, 0.0, 0)
    for x in (-0.8, 0.8):
        cyl("tap", 0.02, 0.2, (x, 0.58, 0.6), BRASS(), 12)
    studio((0, 0, 0.3), 5.0, 28, 30)

if __name__ == "__main__":
    which = sys.argv[sys.argv.index("--") + 1]
    reset()
    globals()[which]()
    png, glb = out(which)
    os.makedirs(os.path.dirname(glb), exist_ok=True)
    render(png); export_glb(glb)
