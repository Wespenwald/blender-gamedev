# Blender 5.2.2 gamedev build

A patch for Blender 5.2.2 that strips out features game development doesn't use, plus a Windows 11 script that builds it.

## Build (Windows 11)

1. Download this repo (Code > Download ZIP) and unzip it.
2. Double-click `build_blender_gamedev.bat`.
   - It installs Git, CMake and Visual Studio 2022 C++ through winget if they're missing. Click "Yes" on the admin prompts.
   - It downloads Blender 5.2.2 and its libraries to `C:\blender-gamedev`. Needs about 40 GB of free disk space.
   - It applies `blender-gamedev.patch` and compiles with `make gamedev`.
3. At the end it prints where `blender.exe` is. If it stops partway, run it again and it continues from where it stopped.

## What changes

**Removed at build time** (`build_files/cmake/config/blender_gamedev.cmake`)
- FFmpeg (no video import or export)
- Freestyle
- Fluid/smoke (Mantaflow) and ocean sim
- OpenVDB / NanoVDB (volumes)

**Hidden in the UI** (the code is still there)
- Video Sequencer and Movie Clip editors
- Compositor and Geometry Nodes editors. The Geometry Nodes engine stays, so geometry-node modifiers keep working.
- The Compositing, Geometry Nodes and Video Editing workspaces
- The 2D Animation, Storyboarding, VFX and Video Editing templates under File > New
- Fluid, ocean and volume entries in the Add, Quick Effects, Modifier and Physics menus

An editor that's already open in a file still shows up in its editor menu, so older files keep working.

**Kept:** Cycles (needed for baking), EEVEE, Workbench, shader/UV/image editors, texture paint, sculpt, rigging and animation, cloth/soft body/rigid body, and the FBX/glTF/OBJ/USD/Alembic exporters.

## License

Blender is GPL-2.0-or-later, and this patch is under the same license.
