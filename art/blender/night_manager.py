"""Night Manager preview/hero mesh, same proportions as src/shared/NightManagerRig.luau (units = studs)."""
import sys, os, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import *
from figures import build_night_manager

reset()
build_night_manager()
studio(target=(0, 0, 6.8), dist=30, elev=8, azim=-28)
png, glb = out("night_manager")
os.makedirs(os.path.dirname(glb), exist_ok=True)
render(png); export_glb(glb)
