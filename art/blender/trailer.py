"""Teaser footage for THE NIGHT MANAGER: four shots rendered as image sequences (vertical 1080x1920, 24 fps).
   hall   - POV down the hotel hallway, flashlight flickering, him standing far away
   cage   - the holding cell: the lamp pulses, the camera pushes in on him
   chase  - he comes down the hallway at the camera, handheld shake
   flash  - the flashlight hits his face; he recoils
Usage: TRAILER_OUT=/some/dir [TRAILER_SCALE=0.5] [TRAILER_ONLY=hall] [TRAILER_STILL=1] scripts/blender.sh art/blender/trailer.py
(TRAILER_STILL=1 renders only the middle frame of each shot, for a quick look.)"""
import sys, os, math, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *
from figures import build_night_manager
from mathutils import Vector

OUT = os.environ.get("TRAILER_OUT", "/tmp/trailer")
SCALE = float(os.environ.get("TRAILER_SCALE", "1.0"))
ONLY = os.environ.get("TRAILER_ONLY")
STILL = os.environ.get("TRAILER_STILL") == "1"
FPS = 24
W, H = int(1080 * SCALE), int(1920 * SCALE)
random.seed(4)


def setup(frames):
    reset()
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE_NEXT"
    sc.render.resolution_x, sc.render.resolution_y = W, H
    sc.render.fps = FPS
    sc.frame_start, sc.frame_end = 1, frames
    sc.eevee.taa_render_samples = int(os.environ.get("TRAILER_SAMPLES", "40"))
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
    nt = w.node_tree
    nt.nodes["Background"].inputs[0].default_value = (0.0, 0.0, 0.002, 1)
    nt.nodes["Background"].inputs[1].default_value = 0.25
    vol = nt.nodes.new("ShaderNodeVolumePrincipled")
    vol.inputs["Density"].default_value = 0.0035
    vol.inputs["Color"].default_value = (0.55, 0.5, 0.6, 1)
    nt.links.new(vol.outputs["Volume"], nt.nodes["World Output"].inputs["Volume"])
    looks = [l.identifier for l in sc.view_settings.bl_rna.properties["look"].enum_items]
    hc = [l for l in looks if "High Contrast" in l]
    sc.view_settings.look = hc[0] if hc else "None"
    sc.view_settings.exposure = -0.3
    return sc


def light(kind, loc, energy, color, size=1.0, target=None, spot=None):
    bpy.ops.object.light_add(type=kind, location=loc)
    L = bpy.context.object
    L.data.energy, L.data.color = energy, color
    if kind == "AREA":
        L.data.size = size
    if kind == "SPOT":
        L.data.spot_size = math.radians(spot or 40)
        L.data.spot_blend = 0.6
        L.data.use_shadow = True
    if target:
        L.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
    return L


def camera(lens=32):
    sc = bpy.context.scene
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    sc.collection.objects.link(cam); sc.camera = cam
    cam.data.lens = lens
    return cam


def aim(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()


def key(obj, frame, **kw):
    for attr, value in kw.items():
        setattr(obj, attr, value)
        obj.keyframe_insert(data_path=attr, frame=frame)


def dust(center, spread, count, seed):
    random.seed(seed)
    m = mat("dust", (1, 0.9, 0.8), 0.5, emit=(1.0, 0.85, 0.7))
    for _ in range(count):
        p = tuple(center[i] + random.uniform(-spread[i], spread[i]) for i in range(3))
        bpy.ops.mesh.primitive_uv_sphere_add(radius=random.uniform(0.004, 0.011), location=p, segments=8, ring_count=6)
        bpy.context.object.data.materials.append(m)


def hallway(length=70):
    wall = mat("wall", (0.07, 0.025, 0.03), 0.8)
    floor = mat("floor", (0.07, 0.01, 0.014), 0.55)
    gold = mat("gold", (0.7, 0.45, 0.12), 0.3, 1.0)
    dark = mat("door", (0.02, 0.012, 0.012), 0.5)
    box("floor", (14, length, 0.3), (0, -length / 2 + 25, -0.15), floor, 0, 0)
    for s in (-1, 1):
        box("wall", (0.4, length, 16), (s * 6.5, -length / 2 + 25, 8), wall, 0, 0)
        box("rail", (0.3, length, 0.4), (s * 6.2, -length / 2 + 25, 3.2), gold, 0.02, 0)
    for k in range(8):
        for s in (-1, 1):
            box("door", (0.3, 2.4, 7.5), (s * 6.2, 18 - k * 9, 3.75), dark, 0.02, 0)
    box("lid", (14, length, 0.4), (0, -length / 2 + 25, 16), wall, 0, 0)
    box("end", (14, 0.4, 16), (0, -length + 25, 8), wall, 0, 0)


def lamps(flicker_seed, frames):
    random.seed(flicker_seed)
    out = []
    for k, y in enumerate((12, -2, -16, -30)):
        L = light("POINT", (0, y, 12.6), 2400 - k * 300, (1.0, 0.62, 0.3))
        for f in range(1, frames + 1, 2):
            burst = random.random() < 0.06
            L.data.energy = (2400 - k * 300) * (0.05 if burst else 1.0)
            L.data.keyframe_insert(data_path="energy", frame=f)
        out.append(L)
    return out


def render_shot(name, frames):
    if ONLY and ONLY != name:
        return
    sc = bpy.context.scene
    path = os.path.join(OUT, name)
    os.makedirs(path, exist_ok=True)
    sc.render.image_settings.file_format = "PNG"
    if STILL:
        sc.frame_set(frames // 2)
        sc.render.filepath = os.path.join(path, "still.png")
        bpy.ops.render.render(write_still=True)
        return
    sc.render.filepath = os.path.join(path, "f_")
    bpy.ops.render.render(animation=True)


def shot_hall():
    frames = 6 * FPS
    setup(frames)
    hallway()
    lamps(3, frames)
    nm = build_night_manager(ox=0.6, oy=-33, oz=0, yaw=math.pi)
    for o in bpy.data.objects:
        if o.name.startswith("spark"):
            o.scale = (1.5, 1.5, 1.5)
            for s in o.material_slots:
                s.material.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 4
    cam = camera(30)
    beam = light("SPOT", (0, 28, 5), 3200, (1.0, 0.95, 0.85), spot=26)
    dust((0, 12, 6), (3, 18, 3), 90, 5)
    for f in range(1, frames + 1):
        t = (f - 1) / (frames - 1)
        y = 28 - 24 * t
        bob = math.sin(f * 0.55) * 0.07
        cam.location = (math.sin(f * 0.27) * 0.05, y, 5.2 + bob)
        aim(cam, (0.2 + math.sin(f * 0.11) * 0.25, y - 20, 5.0 + math.sin(f * 0.07) * 0.2))
        cam.keyframe_insert(data_path="location", frame=f)
        cam.keyframe_insert(data_path="rotation_euler", frame=f)
        beam.location = cam.location + Vector((0.3, 0, -0.2))
        aim(beam, (cam.location.x + 0.2, y - 20, 4.6))
        beam.keyframe_insert(data_path="location", frame=f)
        beam.keyframe_insert(data_path="rotation_euler", frame=f)
        beam.data.energy = 3200 * (0.15 if (f % 37) in (0, 1, 2) or (f % 53) in (0, 1) else 1.0)
        beam.data.keyframe_insert(data_path="energy", frame=f)
    render_shot("hall", frames)


def shot_cage():
    frames = 6 * FPS
    setup(frames)
    conc = mat("conc", (0.05, 0.05, 0.055), 0.9)
    iron = mat("iron", (0.04, 0.04, 0.05), 0.5, 0.9)
    box("floor", (40, 40, 0.3), (0, 0, -0.15), conc, 0, 0)
    box("back", (40, 0.4, 16), (0, -14, 8), conc, 0, 0)
    box("left", (0.4, 40, 16), (-14, 0, 8), conc, 0, 0)
    box("right", (0.4, 40, 16), (14, 0, 8), conc, 0, 0)
    box("lid", (40, 40, 0.4), (0, 0, 16), conc, 0, 0)
    for s in range(-3, 4):
        for side in (-3.2, 3.2):
            box("bar", (0.3, 0.3, 9), (s * 1.05, side, 4.5), iron, 0.02, 0)
            box("bar", (0.3, 0.3, 9), (side, s * 1.05, 4.5), iron, 0.02, 0)
    for z in (0.4, 4.5, 8.8):
        for side in (-3.2, 3.2):
            box("rail", (6.7, 0.3, 0.3), (0, side, z), iron, 0.02, 0)
            box("rail", (0.3, 6.7, 0.3), (side, 0, z), iron, 0.02, 0)
    nm = build_night_manager(ox=0, oy=0, oz=0, yaw=math.pi)
    for o in bpy.data.objects:
        if o.name.startswith("spark"):
            o.scale = (1.5, 1.5, 1.5)
            for s in o.material_slots:
                s.material.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 5
    red = light("POINT", (0, 0, 10.2), 1200, (1.0, 0.04, 0.03))
    for f in range(1, frames + 1):
        t = (f - 1) / (frames - 1)
        pulse = 0.5 + 0.5 * math.sin(f * (0.25 + t * 0.9))
        red.data.energy = 900 + 12000 * pulse
        red.data.keyframe_insert(data_path="energy", frame=f)
    light("AREA", (0, 12, 6), 520, (0.35, 0.5, 1.0), size=3, target=(0, 0, 8))
    light("POINT", (0, 7, 9), 700, (1.0, 0.1, 0.08))  # red wash on the bars from the camera side
    bpy.context.scene.view_settings.exposure = 0.5
    cam = camera(34)
    for f in range(1, frames + 1):
        t = (f - 1) / (frames - 1)
        d = 22 - 11 * t
        ang = math.radians(-14 + 28 * t)
        cam.location = (math.sin(ang) * d, math.cos(ang) * d, 5.8 + 2.4 * t)
        aim(cam, (0, 0, 10.0 + 1.0 * t))
        cam.keyframe_insert(data_path="location", frame=f)
        cam.keyframe_insert(data_path="rotation_euler", frame=f)
    dust((0, 0, 7), (6, 6, 5), 80, 9)
    # the payoff: in the last second and a half the bars slide up and out of the way
    start, end = frames - 40, frames - 6
    for o in list(bpy.data.objects):
        if o.name.startswith("bar") or o.name.startswith("rail"):
            z0 = o.location.z
            key(o, start, location=(o.location.x, o.location.y, z0))
            key(o, end, location=(o.location.x, o.location.y, z0 + 11))
            for fc in o.animation_data.action.fcurves:
                for kp in fc.keyframe_points:
                    kp.interpolation = "BEZIER"
    render_shot("cage", frames)


def shot_chase():
    frames = 6 * FPS
    setup(frames)
    hallway()
    lamps(8, frames)
    nm = build_night_manager(ox=0, oy=-34, oz=0, yaw=math.pi)
    pivot = bpy.data.objects["nm_pivot"]
    for o in bpy.data.objects:
        if o.name.startswith("spark"):
            o.scale = (1.5, 1.5, 1.5)
            for s in o.material_slots:
                s.material.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 5
    for f in range(1, frames + 1):
        t = min(1.0, (f - 1) / (frames * 0.82))
        ease = t * t * (0.6 + 0.4 * t)
        pivot.location = (math.sin(f * 0.3) * 0.25, -34 + 38 * ease, math.sin(f * 0.9) * 0.18)
        pivot.rotation_euler = (0, math.sin(f * 0.45) * 0.07, math.pi)
        pivot.keyframe_insert(data_path="location", frame=f)
        pivot.keyframe_insert(data_path="rotation_euler", frame=f)
    cam = camera(26)
    beam = light("SPOT", (0.4, 14.5, 3.6), 4200, (1.0, 0.95, 0.85), spot=28)
    random.seed(21)
    for f in range(1, frames + 1):
        shake = 0.02 + 0.16 * (f / frames) ** 2
        cam.location = (random.uniform(-shake, shake), 15 + random.uniform(-shake, shake), 3.6 + random.uniform(-shake, shake))
        aim(cam, (random.uniform(-shake, shake), -20, 6.5 + random.uniform(-shake, shake)))
        cam.keyframe_insert(data_path="location", frame=f)
        cam.keyframe_insert(data_path="rotation_euler", frame=f)
        aim(beam, (0.5, -20, 5.2))
        beam.keyframe_insert(data_path="rotation_euler", frame=f)
        beam.data.energy = 4200 * (0.1 if f % 11 == 0 else 1.0)
        beam.data.keyframe_insert(data_path="energy", frame=f)
    light("AREA", (0, 8, 15), 1400, (0.35, 0.5, 1.0), size=2, target=(0, -10, 8))
    dust((0, -2, 5.5), (3, 14, 3), 60, 13)
    render_shot("chase", frames)


def shot_flash():
    frames = 4 * FPS
    setup(frames)
    box("back", (30, 0.4, 24), (0, -6, 10), mat("wall2", (0.05, 0.02, 0.025), 0.8), 0, 0)
    nm = build_night_manager(ox=0, oy=0, oz=0, yaw=math.pi)
    pivot = bpy.data.objects["nm_pivot"]
    for o in bpy.data.objects:
        if o.name.startswith("spark"):
            o.scale = (1.6, 1.6, 1.6)
            for s in o.material_slots:
                s.material.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 6
    for f in range(1, frames + 1):
        t = (f - 1) / (frames - 1)
        stun = 1.0 if f > 30 else 0.0
        pivot.rotation_euler = (math.radians(-12 * stun) + math.sin(f * 1.7) * 0.03 * stun, 0, math.pi + math.sin(f * 2.3) * 0.05 * stun)
        pivot.location = (0, 1.2 * stun * min(1, (f - 30) / 8), 0)
        pivot.keyframe_insert(data_path="rotation_euler", frame=f)
        pivot.keyframe_insert(data_path="location", frame=f)
    cam = camera(48)
    cam.location = (0.4, 8.5, 10.4)
    aim(cam, (0, 0, 11.0))
    beam = light("SPOT", (1.6, 8.0, 10.0), 9000, (1.0, 0.97, 0.9), spot=20, target=(0, -0.8, 11.0))
    for f in range(1, frames + 1):
        on = f > 30
        flick = 0.25 if (f % 4 == 0 and on) else 1.0
        beam.data.energy = (9000 if on else 90) * flick
        beam.data.keyframe_insert(data_path="energy", frame=f)
    light("AREA", (0, -4, 15), 1500, (0.35, 0.5, 1.0), size=2, target=(0, 0, 10))
    dust((0.6, 4.0, 10.5), (1.6, 3.5, 1.6), 70, 17)
    render_shot("flash", frames)


for fn in (shot_hall, shot_cage, shot_chase, shot_flash):
    fn()
print("trailer done")
