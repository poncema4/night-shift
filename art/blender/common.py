"""Shared Blender helpers for THE NIGHT MANAGER assets. Run via tools/blender.sh (headless)."""
import bpy, math, sys, os, json

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def mat(name, rgb, rough=0.5, metal=0.0, emit=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = (*emit, 1)
        b.inputs["Emission Strength"].default_value = 4.0
    return m

def smooth(obj, bevel=0.01, subsurf=0, segments=3):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    if bevel:
        m = obj.modifiers.new("bevel", "BEVEL"); m.width = bevel; m.segments = segments; m.limit_method = "ANGLE"
    if subsurf:
        s = obj.modifiers.new("sub", "SUBSURF"); s.levels = subsurf; s.render_levels = subsurf
    bpy.ops.object.shade_smooth()
    return obj

def box(name, size, loc, material, bevel=0.012, subsurf=0):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object; o.name = name; o.scale = (size[0]/2, size[1]/2, size[2]/2)
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(material)
    return smooth(o, bevel, subsurf)

def cyl(name, r, h, loc, material, verts=24, bevel=0.005):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=h, vertices=verts, location=loc)
    o = bpy.context.object; o.name = name; o.data.materials.append(material)
    return smooth(o, bevel)

def studio(target=(0, 0, 0.5), dist=4.0, elev=22, azim=35):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE_NEXT"
    sc.render.resolution_x, sc.render.resolution_y = 900, 700
    w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
    w.node_tree.nodes["Background"].inputs[0].default_value = (0.02, 0.02, 0.03, 1)
    w.node_tree.nodes["Background"].inputs[1].default_value = 0.6
    for n, loc, e, col in (("key", (3, -3, 4), 600, (1.0, 0.8, 0.6)), ("rim", (-3, 3, 2.5), 300, (0.5, 0.6, 1.0))):
        bpy.ops.object.light_add(type="AREA", location=loc)
        l = bpy.context.object; l.data.energy = e; l.data.size = 2.5; l.data.color = col
        d = (l.location.x, l.location.y, l.location.z - target[2])
        l.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), d[2]), 0, math.atan2(d[1], d[0]) - math.pi/2 + math.pi)
    bpy.ops.mesh.primitive_plane_add(size=20); f = bpy.context.object
    f.data.materials.append(mat("floor", (0.05, 0.04, 0.045), 0.35))
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam")); sc.collection.objects.link(cam); sc.camera = cam
    a, e = math.radians(azim), math.radians(elev)
    cam.location = (target[0] + dist*math.cos(e)*math.sin(a), target[1] - dist*math.cos(e)*math.cos(a), target[2] + dist*math.sin(e))
    c = cam.constraints.new("TRACK_TO")
    t = bpy.data.objects.new("t", None); t.location = target; sc.collection.objects.link(t)
    c.target = t; c.track_axis = "TRACK_NEGATIVE_Z"; c.up_axis = "UP_Y"

def render(path):
    bpy.context.scene.render.filepath = path
    bpy.ops.render.render(write_still=True)

def _roblox_material(name, metallic, emission, base):
    """Guess the closest Roblox material from the Blender material's name and numbers."""
    n = name.lower()
    if emission > 0.5:
        return "Neon"
    for key, mat_ in (("velvet", "Fabric"), ("linen", "Fabric"), ("cloth", "Fabric"), ("wood", "Wood"), ("walnut", "Wood"),
                      ("plank", "WoodPlanks"), ("marble", "Marble"), ("glass", "Glass"), ("crystal", "Glass"), ("water", "Glass"),
                      ("brass", "Metal"), ("steel", "Metal"), ("chrome", "Metal"), ("rust", "CorrodedMetal"), ("tire", "SmoothPlastic")):
        if key in n:
            return mat_
    return "Metal" if metallic > 0.5 else "SmoothPlastic"

def write_styles(path):
    """Per-part colour and material (by object name) so the game can paint the imported meshes."""
    import re
    styles = {}
    for o in bpy.data.objects:
        if o.type != "MESH" or o.name in ("Plane",) or not o.data.materials:
            continue
        m = o.data.materials[0]
        if not m or not m.use_nodes:
            continue
        b = m.node_tree.nodes.get("Principled BSDF")
        if not b:
            continue
        base = b.inputs["Base Color"].default_value
        emission = b.inputs["Emission Strength"].default_value if "Emission Strength" in b.inputs else 0
        rgb = [int(round(255 * (max(0.0, c) ** (1 / 2.2)))) for c in base[:3]]
        key = re.sub(r"\.\d+$", "", o.name)
        styles.setdefault(key, {"rgb": rgb, "material": _roblox_material(m.name, b.inputs["Metallic"].default_value, emission, base)})
    with open(path, "w") as f:
        json.dump(styles, f, indent=1, sort_keys=True)

def export_glb(path):
    write_styles(path[:-4] + ".styles.json")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=False)
    # Roblox's importer likes FBX best: Y up, -Z forward, 1 unit = 1 metre (the game auto-fits the size)
    bpy.ops.export_scene.fbx(filepath=path[:-4] + ".fbx", use_selection=False, axis_forward="-Z", axis_up="Y", apply_unit_scale=True, bake_space_transform=True)


def cone(name, r1, r2, h, loc, material, verts=32):
    bpy.ops.mesh.primitive_cone_add(radius1=r1, radius2=r2, depth=h, vertices=verts, location=loc)
    o = bpy.context.object; o.name = name; o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o

def sphere(name, r, loc, material, scale=(1, 1, 1), subsurf=0):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, segments=32, ring_count=16, location=loc)
    o = bpy.context.object; o.name = name; o.scale = scale; o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o

def torus(name, major, minor, loc, material):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=48, minor_segments=12, location=loc)
    o = bpy.context.object; o.name = name; o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o

def out(name):
    base = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
    return os.path.join(base, "renders", name + ".png"), os.path.join(base, "models", name + ".glb")


def beam(name, p1, p2, r, material, verts=10):
    from mathutils import Vector
    a, b = Vector(p1), Vector(p2)
    d = b - a
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=d.length, vertices=verts, location=(a + b) / 2)
    o = bpy.context.object; o.name = name; o.data.materials.append(material)
    o.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    bpy.ops.object.shade_smooth()
    return o

def gem(name, r, loc, material):
    bpy.ops.mesh.primitive_ico_sphere_add(radius=r, subdivisions=1, location=loc)
    o = bpy.context.object; o.name = name; o.scale = (1, 1, 1.7); o.data.materials.append(material)
    return o


def tapered(name, size, loc, material, top=(0.7, 0.8), bevel=0.04, subsurf=1):
    """A box whose top face is narrower than its base (a car cabin, a lampshade): top = (x scale, y scale)."""
    import bmesh
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.object; o.name = name
    o.scale = (size[0] / 2, size[1] / 2, size[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    bm = bmesh.new(); bm.from_mesh(o.data)
    for v in bm.verts:
        if v.co.z > 0:
            v.co.x *= top[0]; v.co.y *= top[1]
    bm.to_mesh(o.data); bm.free()
    o.data.materials.append(material)
    return smooth(o, bevel, subsurf)
