"""Shared Blender helpers for NIGHT SHIFT assets. Run via tools/blender.sh (headless)."""
import bpy, math, sys, os

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

def export_glb(path):
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=False)
