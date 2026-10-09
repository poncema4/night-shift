"""Reusable Blender figures. The Night Manager matches src/shared/NightManagerRig.luau (units = studs)."""
import bpy, math
from common import *


def build_night_manager(ox=0.0, oy=0.0, oz=0.0, yaw=0.0):
    """Builds the Night Manager at (ox, oy, oz) facing `yaw` radians (front = -y at yaw 0). Returns the new objects."""
    before = set(bpy.data.objects)
    coat = mat("coat", (0.012, 0.01, 0.016), 0.9)
    trim = mat("trim", (0.12, 0.012, 0.02), 0.8)
    mask = mat("mask", (0.75, 0.72, 0.62), 0.45)
    brass = mat("brass", (0.8, 0.5, 0.15), 0.25, 1.0)
    eye = mat("eye", (1, 0.1, 0.15), 0.3, emit=(1.0, 0.05, 0.1))
    dark = mat("dark", (0.003, 0.003, 0.004), 0.6)

    def B(name, size, loc, m, bevel=0.06):
        return box(name, size, loc, m, bevel, 0)

    # hips / coat: tapered layers
    B("skirt_low", (3.6, 2.0, 0.9), (0, 0, 3.85), coat, 0.06)
    B("skirt_mid", (3.1, 1.8, 1.1), (0, 0, 4.85), coat, 0.06)
    B("skirt_high", (2.6, 1.7, 1.0), (0, 0, 5.9), coat, 0.06)
    B("tail", (2.8, 0.2, 2.6), (0, 1.15, 3.1), coat, 0.05)
    B("hem", (3.6, 2.0, 0.2), (0, 0, 3.3), trim, 0.02)
    for s_ in (-1, 1):
        B("leg", (0.8, 0.8, 2.8), (s_*0.7, 0, 1.8), coat, 0.05)
        B("shoe", (1.0, 1.5, 0.4), (s_*0.7, -0.25, 0.2), dark, 0.08)
    # chest + shoulders
    B("chest", (2.4, 1.5, 2.5), (0, 0, 7.65), coat, 0.15)
    B("shoulders", (3.2, 1.4, 0.5), (0, 0, 9.15), coat, 0.12)
    B("tie", (0.26, 0.08, 2.0), (0, -0.79, 7.8), trim, 0.01)
    B("badge", (0.5, 0.06, 0.26), (0.7, -0.78, 8.4), brass, 0.01)
    for i in range(3):
        sphere("btn", 0.1, (-0.6, -0.8, 6.9 + i*0.6), brass, (1, 0.5, 1))
    # head
    B("neck", (0.5, 0.5, 0.5), (0, 0, 9.65), coat, 0.02)
    B("skull", (1.6, 1.7, 2.7), (0, 0, 11.25), coat, 0.3)
    B("mask", (1.3, 0.12, 2.4), (0, -0.91, 11.25), mask, 0.04)
    B("mouth", (0.8, 0.04, 0.1), (0, -0.99, 10.4), dark, 0.01)
    for s_ in (-1, 1):
        B("hollow", (0.34, 0.06, 0.6), (s_*0.32, -0.99, 11.55), dark, 0.02)
        sphere("spark", 0.065, (s_*0.32, -1.05, 11.55), eye)
    B("band", (1.64, 1.74, 0.2), (0, 0, 12.7), brass, 0.03)
    B("cap", (1.6, 1.7, 0.7), (0, 0, 13.15), trim, 0.1)
    # arms
    for s in (-1, 1):
        x = s*1.95
        B("upper", (0.38, 0.38, 3.2), (x, 0, 7.4), coat, 0.06)
        B("fore", (0.34, 0.34, 3.0), (x, 0, 4.3), coat, 0.06)
        B("hand", (0.7, 0.7, 0.9), (x, 0, 2.35), mask, 0.08)
        for f in (-1, 0, 1):
            B("finger", (0.12, 0.12, 1.1), (x + f*0.22, 0, 1.35), mask, 0.03)

    made = [o for o in bpy.data.objects if o not in before]
    pivot = bpy.data.objects.new('nm_pivot', None)
    bpy.context.scene.collection.objects.link(pivot)
    pivot.location = (ox, oy, oz)
    pivot.rotation_euler = (0, 0, yaw)
    for o in made:
        o.parent = pivot
    return made
