# Workflow: Linux laptop + Blender -> GitHub -> Windows Studio

Code: edited on Linux, pushed to GitHub. On the Windows PC: `git pull`, `rojo serve`, Studio plugin > Connect. Rojo syncs scripts live from disk into Studio.
Rojo does NOT carry meshes made in Blender through code. Models go in this way:
1. Model in Blender, export `.fbx`/`.glb` into `assets/blender/` (the .blend source is kept too, Git LFS if large).
2. On Windows, in Studio: Asset Manager > Bulk Import the file (or 3D Importer), then Publish to Roblox.
3. Place/arrange in Studio, save the place. Keep the Studio-built world as `place/night-shift.rbxl` only if needed; scripts stay in `src/`.
Blender conventions: 1 Blender unit = 1 stud x 0.28 m, apply scale, forward -Y, export selected, low poly (mobile).
