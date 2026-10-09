"""The game icon: a close-up of the Night Manager's face, red eyes in the dark. Output: art/renders/icon_face.png (1024x1024).
Usage: scripts/blender.sh art/blender/icon.py   (then python3 brand/make_store_art.py)"""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *
from figures import build_night_manager

reset()
build_night_manager()
studio(target=(0, 0, 11.6), dist=9, elev=2, azim=0)
sc = bpy.context.scene
sc.render.resolution_x, sc.render.resolution_y = 1024, 1024
# a dim red glow just in front of the face so the eyes and the cap read at thumbnail size
bpy.ops.object.light_add(type="POINT", location=(0, -3.2, 11.8))
glow = bpy.context.object
glow.data.energy = 90
glow.data.color = (1.0, 0.15, 0.12)
png, _ = out("icon_face")
render(png)
