# art/

Blender pipeline for THE NIGHT MANAGER models. Scripts in `art/blender/` build a model,
render a preview to `art/renders/` and export a `.glb`. Look at the render before
anything goes to Studio.

    scripts/blender.sh art/blender/armchair.py

Install (no sudo): download the Linux tarball from a Blender mirror
(e.g. https://mirrors.ocf.berkeley.edu/blender/release/Blender4.5/) and extract to `~/tools`.

Meshes are not synced by Rojo: import the `.glb`/FBX in Studio with Asset Manager > Bulk Import.
