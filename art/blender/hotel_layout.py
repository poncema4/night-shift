"""Draw the real hotel layout (art/layout.json from scripts/export-layout.luau) and render plans and a stairwell.
Usage: scripts/blender.sh art/blender/hotel_layout.py"""
import sys, os, json, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
data = json.load(open(os.path.join(ROOT, "layout.json")))

COLORS = {
    "wall": (0.42, 0.40, 0.44), "header": (0.42, 0.40, 0.44), "tile": (0.2, 0.2, 0.22), "roof": (0.1, 0.1, 0.1),
    "skirting": (0.15, 0.09, 0.06), "wainscot": (0.25, 0.15, 0.1), "rail": (0.6, 0.45, 0.2), "cornice": (0.6, 0.55, 0.4),
    "frame": (0.5, 0.33, 0.18), "tread": (0.9, 0.45, 0.1), "landing": (0.9, 0.55, 0.15), "guardrail": (0.95, 0.85, 0.2),
}
TILE_BY_LEVEL = {0: (0.35, 0.12, 0.16), 1: (0.13, 0.3, 0.25), -1: (0.25, 0.25, 0.27)}
ITEM = {"bed": (0.7, 0.2, 0.2), "car": (0.2, 0.3, 0.8), "chandelier": (1, 0.8, 0.3), "water": (0.1, 0.5, 0.8), "pool": (0.1, 0.5, 0.9)}

def draw(levels, show_roof=False, show_items=True, nodes=False, xrange=None, skip=()):
    reset()
    cache = {}
    def m(rgb):
        if rgb not in cache:
            cache[rgb] = mat("m%d" % len(cache), rgb, 0.8)
        return cache[rgb]
    for s in data["solids"]:
        lvl = s.get("level")
        if s["kind"] == "roof" and not show_roof:
            continue
        if s["kind"] in skip or (xrange and not (xrange[0] <= s["x"] <= xrange[1])):
            continue
        if lvl is not None and lvl not in levels:
            continue
        if s["kind"] in ("tread", "landing") and not any((s["y"] + 0.5) >= (l * 16 - 2) and s["y"] <= l * 16 + 16 for l in levels):
            continue
        if lvl is None and s["kind"] not in ("tread", "landing", "roof"):
            continue
        rgb = TILE_BY_LEVEL.get(lvl, COLORS["tile"]) if s["kind"] == "tile" else COLORS.get(s["kind"], (0.5, 0.5, 0.5))
        b = box("s", (s["w"], s["d"], s["h"]), (s["x"], s["z"], s["y"] + s["h"] / 2), m(rgb), 0, 0)
    if show_items:
        for it in data["items"]:
            if it["level"] not in levels or it["kind"] == "chandelier":
                continue
            box("i", (it["w"], it["d"], max(it["h"], 0.2)), (it["x"], it["z"], it["y"] + max(it["h"], 0.2) / 2), m(ITEM.get(it["kind"], (0.9, 0.7, 0.3))), 0, 0)
    if nodes:
        for nid, n in data["graph"].items():
            sphere("n", 0.6, (n["x"], n["z"], n["y"] + 0.8), m((0.1, 1, 0.2)))

def setup_render(path, loc, target, ortho=None, res=(1600, 800)):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE_NEXT"
    sc.render.resolution_x, sc.render.resolution_y = res
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.03, 0.03, 0.04, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 1.2
    bpy.ops.object.light_add(type="SUN", location=(0, 0, 100)); sun = bpy.context.object
    sun.data.energy = 3.0; sun.rotation_euler = (math.radians(35), 0, math.radians(30))
    cam = bpy.data.objects.new("c", bpy.data.cameras.new("c")); sc.collection.objects.link(cam); sc.camera = cam
    cam.location = loc
    if ortho:
        cam.data.type = "ORTHO"; cam.data.ortho_scale = ortho
    t = bpy.data.objects.new("t", None); t.location = target; sc.collection.objects.link(t)
    c = cam.constraints.new("TRACK_TO"); c.target = t; c.track_axis = "TRACK_NEGATIVE_Z"; c.up_axis = "UP_Y"
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)

out_dir = os.path.join(ROOT, "renders")
# floor plans: top-down, one level at a time (levels above are hidden)
for name, lvl, y0 in (("plan_basement", -1, -16), ("plan_ground", 0, 0), ("plan_upstairs", 1, 16)):
    draw([lvl], nodes=True)
    setup_render(os.path.join(out_dir, name + ".png"), (0, 0, y0 + 120), (0, 0, y0), ortho=175)
# stairwells as cutaways: floors, treads, landings and guard rails only
CUT = ("wall", "header", "frame", "skirting", "wainscot", "rail", "cornice", "roof")
draw([0, 1], show_items=False, nodes=True, xrange=(-85, -55), skip=CUT)
setup_render(os.path.join(out_dir, "stairs_west.png"), (-110, -45, 45), (-70, 0, 8), res=(1600, 900))
draw([0, -1], show_items=False, nodes=True, xrange=(55, 85), skip=CUT)
setup_render(os.path.join(out_dir, "stairs_east.png"), (110, -45, 30), (70, 0, -6), res=(1600, 900))
