"""Hotel props. Usage: scripts/blender.sh art/blender/props.py -- armchair|desk|chandelier|bed|lamp"""
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

if __name__ == "__main__":
    which = sys.argv[sys.argv.index("--") + 1]
    reset()
    globals()[which]()
    png, glb = out(which)
    os.makedirs(os.path.dirname(glb), exist_ok=True)
    render(png); export_glb(glb)
