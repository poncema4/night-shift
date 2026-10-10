"""Key-art renders of the Night Manager, lit like real horror art (low angle, red under-light, cold rim light, glowing
eyes, volumetric fog with dust in the beam). Outputs in art/renders/: hero_icon.png (1024x1024, face), hero_wide.png
(1920x1080, looming shot with a flashlight cone).
Usage: scripts/blender.sh art/blender/hero.py"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *
from figures import build_night_manager
from mathutils import Vector

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "renders")


def setup(res):
    reset()
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE_NEXT"
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.eevee.taa_render_samples = 96
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
    nt = w.node_tree
    nt.nodes["Background"].inputs[0].default_value = (0.0, 0.0, 0.002, 1)
    nt.nodes["Background"].inputs[1].default_value = 0.2
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Density"].default_value = 0.0016
    vol.inputs["Color"].default_value = (0.55, 0.5, 0.6, 1)
    nt.links.new(vol.outputs["Volume"], nt.nodes["World Output"].inputs["Volume"])
    sc.view_settings.view_transform = "Filmic" if "Filmic" in [v.identifier for v in sc.view_settings.bl_rna.properties["view_transform"].enum_items] else "AgX"
    looks = [l.identifier for l in sc.view_settings.bl_rna.properties["look"].enum_items]
    hc = [l for l in looks if "High Contrast" in l]
    sc.view_settings.look = hc[0] if hc else "None"
    sc.view_settings.exposure = -0.6
    return sc


def light(kind, loc, energy, color, size=1.0, target=None, spot=None):
    bpy.ops.object.light_add(type=kind, location=loc)
    L = bpy.context.object
    L.data.energy = energy
    L.data.color = color
    if kind == "AREA":
        L.data.size = size
    if kind == "SPOT":
        L.data.spot_size = math.radians(spot or 40)
        L.data.spot_blend = 0.5
        L.data.shadow_soft_size = 0.1
        L.data.use_shadow = True
    if target:
        d = Vector(target) - Vector(loc)
        L.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    return L


def camera(loc, target, lens=50, roll=0.0):
    sc = bpy.context.scene
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam); sc.camera = cam
    cam.location = loc
    cam.data.lens = lens
    d = Vector(target) - Vector(loc)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    cam.rotation_euler.rotate_axis("Z", roll)
    return cam


def dust(center, spread, count, seed=3):
    random.seed(seed)
    m = mat("dust", (1, 0.9, 0.8), 0.5, emit=(1.0, 0.85, 0.7))
    for _ in range(count):
        p = (center[0] + random.uniform(-spread[0], spread[0]), center[1] + random.uniform(-spread[1], spread[1]), center[2] + random.uniform(-spread[2], spread[2]))
        bpy.ops.mesh.primitive_uv_sphere_add(radius=random.uniform(0.004, 0.011), location=p, segments=8, ring_count=6)
        bpy.context.object.data.materials.append(m)


def boost_eyes(strength=14):
    for o in bpy.data.objects:
        if o.name.startswith("spark"):
            o.scale = (1.5, 1.5, 1.5)
            for slot in o.material_slots:
                slot.material.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = strength


def shot_icon():
    setup((1024, 1024))
    build_night_manager()
    boost_eyes(3.2)
    # a silhouette: he is almost black, outlined by a cold rim light from behind, with only his eyes (and a hint of the
    # mask) lit. The flat surfaces of the mask stay in shadow, which is what makes it frightening instead of cartoonish.
    camera((0.0, -9.5, 10.2), (0, 0, 11.4), lens=50, roll=math.radians(-2))
    light("AREA", (8.0, 6.0, 18.0), 16000, (0.4, 0.55, 1.0), size=1.0, target=(0, 0, 11.5))
    light("AREA", (-9.0, 6.0, 15.0), 9000, (0.5, 0.35, 0.9), size=1.0, target=(0, 0, 11.5))
    light("POINT", (-0.32, -1.6, 11.55), 14, (1.0, 0.03, 0.03))
    light("POINT", (0.32, -1.6, 11.55), 14, (1.0, 0.03, 0.03))
    dust((0, -4.0, 11.0), (2.4, 2.0, 2.6), 45, seed=11)
    render(os.path.join(ROOT, "hero_icon.png"))


def shot_wide():
    setup((1920, 1080))
    bpy.context.scene.view_settings.exposure = 0.0
    bpy.context.scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.5
    build_night_manager(ox=2.2, oy=0, oz=0, yaw=math.pi)
    boost_eyes(3.2)
    wall = mat("wall", (0.07, 0.025, 0.03), 0.8)
    floor = mat("floor", (0.07, 0.01, 0.014), 0.55)
    gold = mat("gold", (0.7, 0.45, 0.12), 0.3, 1.0)
    box("floor", (14, 70, 0.3), (0, -25, -0.15), floor, 0, 0)
    for s_ in (-1, 1):
        box("wall", (0.4, 70, 16), (s_ * 6.5, -25, 8), wall, 0, 0)
        box("rail", (0.3, 70, 0.4), (s_ * 6.2, -25, 3.2), gold, 0.02, 0)
    for k in range(6):  # door frames receding down the hall
        for s_ in (-1, 1):
            box("door", (0.3, 2.4, 7.5), (s_ * 6.2, -6 - k * 9, 3.75), mat(f"d{k}{s_}", (0.02, 0.012, 0.012), 0.5), 0.02, 0)
    box("end", (14, 0.4, 16), (0, -55, 8), wall, 0, 0)
    for k, y in enumerate((-8, -22, -36)):  # a few dying warm lamps down the hall
        light("POINT", (0, y, 12.5), 2600 + k * 1500, (1.0, 0.62, 0.3))
    light("POINT", (-4.0, 2.0, 8.0), 900, (1.0, 0.55, 0.28))   # warm kick on the left wall
    light("AREA", (0, 9, 4), 90, (1.0, 0.06, 0.05), size=3.0, target=(2.2, 0, 10))
    light("SPOT", (-3.0, 9.0, 4.0), 7000, (1.0, 0.96, 0.85), spot=22, target=(2.2, -0.8, 10.8))  # the player's flashlight on his face
    light("AREA", (2, -4, 15), 2200, (0.35, 0.5, 1.0), size=2.0, target=(2.2, 0, 10))
    dust((0.0, 3.5, 7.0), (2.6, 4.5, 3.2), 70, seed=7)
    camera((-0.4, 11.5, 3.4), (1.2, 0, 10.0), lens=36, roll=math.radians(-3))
    render(os.path.join(ROOT, "hero_wide.png"))


shot_icon()
shot_wide()
print("done")
