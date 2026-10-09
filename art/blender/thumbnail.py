"""Marketing render built from the REAL hotel data (art/layout.json from scripts/export-layout.luau): the ground-floor
corridor with the Night Manager at the far end. Output: brand/thumbnail_corridor.png (1920x1080).
Usage: lune run scripts/export-layout && scripts/blender.sh art/blender/thumbnail.py"""
import sys, os, json, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *
from figures import build_night_manager

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
data = json.load(open(os.path.join(ROOT, "layout.json")))
reset()

def srgb(r, g, b):
    return tuple((c / 255) ** 2.2 for c in (r, g, b))

STYLE = {
    "wall": (srgb(70, 52, 62), 0.85, 0.0), "header": (srgb(70, 52, 62), 0.85, 0.0),
    "skirting": (srgb(34, 22, 16), 0.5, 0.0), "wainscot": (srgb(62, 38, 28), 0.45, 0.0),
    "rail": (srgb(150, 108, 58), 0.3, 0.8), "cornice": (srgb(170, 152, 120), 0.7, 0.0),
    "frame": (srgb(120, 82, 46), 0.45, 0.0), "tile": (srgb(104, 22, 36), 0.9, 0.0),
    "roof": (srgb(34, 30, 38), 0.9, 0.0),
}
cache = {}
def material(kind):
    if kind not in cache:
        rgb, rough, metal = STYLE.get(kind, (srgb(90, 90, 90), 0.8, 0.0))
        cache[kind] = mat("m_" + kind, rgb, rough, metal)
    return cache[kind]

# the ground floor around the corridor (x -62..62), plus the ceiling (the upstairs floor slab) as a dark lid
for s in data["solids"]:
    lvl = s.get("level")
    if lvl != 0 or s["kind"] not in STYLE:
        continue
    if s["kind"] == "tile" and s.get("name") != "Corridor" and abs(s["z"]) < 5:
        continue
    if abs(s["x"]) > 66:
        continue
    box("s", (s["w"], s["d"], s["h"]), (s["x"], s["z"], s["y"] + s["h"] / 2), material(s["kind"]), 0, 0)
box("lid", (130, 60, 2), (0, 0, 15), material("roof"), 0, 0)

# the runner on the carpet
box("runner", (118, 4, 0.04), (0, 0, 0.02), mat("runner", srgb(74, 14, 26), 0.95), 0, 0)
for side in (-1, 1):
    box("edge", (118, 0.25, 0.02), (0, side * 1.9, 0.05), mat("gold", srgb(190, 150, 70), 0.4, 0.6), 0, 0)

# ceiling bulbs: warm point lights and glowing lamp plates
# only the near bulbs are on: the far end is dark so he stands out; one far bulb is dying
for x, power in ((-50, 5200), (-30, 4200), (-10, 2400), (30, 220)):
    bpy.ops.object.light_add(type="POINT", location=(x, 0, 13.0))
    L = bpy.context.object
    L.data.energy = power
    L.data.color = (1.0, 0.72, 0.42)
    L.data.shadow_soft_size = 0.8
    box("plate", (3, 3, 0.25), (x, 0, 13.85), mat("plate", (1, 0.75, 0.45), 0.3, emit=(1.0, 0.65, 0.3)) if power > 1000 else mat("plate_off", (0.2, 0.15, 0.1), 0.6), 0, 0)

# the Night Manager at the far end, facing us, with a red rim light behind him
nm = build_night_manager(ox=14, oy=0.3, oz=0, yaw=-math.pi / 2)  # his front (-y) turned to face -x, toward the camera
bpy.ops.object.light_add(type="SPOT", location=(26, 0, 9))
spot = bpy.context.object
spot.data.energy = 90000
spot.data.color = (1.0, 0.1, 0.12)
spot.data.spot_size = math.radians(40)
spot.rotation_euler = (math.radians(75), 0, math.radians(90))

for o in nm:
    for m in o.data.materials if o.type == 'MESH' else []:
        if m and m.name == 'eye':
            m.node_tree.nodes['Principled BSDF'].inputs['Emission Strength'].default_value = 60.0

# a faint cool fill from the camera side so the coat and mask read against the red
bpy.ops.object.light_add(type="AREA", location=(-8, 0, 7))
fill = bpy.context.object
fill.data.energy = 900
fill.data.size = 6
fill.data.color = (0.55, 0.7, 1.0)
fill.rotation_euler = (0, math.radians(90), 0)

# mist
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE_NEXT"
sc.render.resolution_x, sc.render.resolution_y = 1920, 1080
sc.view_settings.view_transform = "AgX"
sc.view_settings.look = "AgX - High Contrast"
sc.view_settings.exposure = -0.6
sc.eevee.taa_render_samples = 96
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
nt = w.node_tree
nt.nodes["Background"].inputs[0].default_value = (0.01, 0.01, 0.014, 1)
vol = nt.nodes.new("ShaderNodeVolumeScatter")
vol.inputs["Density"].default_value = 0.007
vol.inputs["Color"].default_value = (0.8, 0.7, 0.7, 1)
nt.links.new(vol.outputs["Volume"], nt.nodes["World Output"].inputs["Volume"])

# camera at the west end, eye height, looking down the corridor
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
cam.location = (-44, -0.4, 4.6)
cam.data.lens = 34
target = bpy.data.objects.new("t", None); target.location = (14, 0, 6.6); sc.collection.objects.link(target)
c = cam.constraints.new("TRACK_TO"); c.target = target; c.track_axis = "TRACK_NEGATIVE_Z"; c.up_axis = "UP_Y"

sc.render.filepath = os.path.join(ROOT, "..", "brand", "thumbnail_corridor.png")
bpy.ops.render.render(write_still=True)
