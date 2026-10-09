import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from common import *
reset()
velvet = mat("velvet", (0.28, 0.03, 0.06), 0.85)
wood = mat("walnut", (0.09, 0.045, 0.02), 0.4)
brass = mat("brass", (0.8, 0.55, 0.2), 0.25, 1.0)
box("seat", (0.8, 0.75, 0.2), (0, 0, 0.38), velvet, 0.06, 2)
box("back", (0.8, 0.16, 0.7), (0, 0.32, 0.72), velvet, 0.06, 2)
for s in (-1, 1):
    box(f"arm{s}", (0.14, 0.7, 0.34), (s*0.47, 0, 0.55), velvet, 0.05, 2)
    for y in (-1, 1):
        o = cyl(f"leg{s}{y}", 0.035, 0.26, (s*0.38, y*0.3, 0.13), wood, 16)
        o.scale = (1, 1, 1)
        cyl(f"cap{s}{y}", 0.045, 0.02, (s*0.38, y*0.3, 0.02), brass, 16)
for i in (-1, 0, 1):
    cyl(f"button{i}", 0.018, 0.02, (i*0.2, 0.235, 0.78), brass, 12)
studio(target=(0, 0, 0.45), dist=3.2)
render(os.path.join(os.path.dirname(__file__), "..", "renders", "armchair.png"))
export_glb(os.path.join(os.path.dirname(__file__), "..", "armchair.glb"))
