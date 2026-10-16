# Source: scenario-blender-expert

- **Repo:** https://github.com/scenario-labs/skills
- **Path:** `skills/dcc/blender/scenario-blender-expert/`
- **Commit:** `49dd26e47371163ae0020c7f5627d0993626bfc2` (2026-10-15)
- **License:** MIT, Copyright 2026 Scenario Inc. (`LICENSE` copied)
- **Stars at fetch:** 1032
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/scenario-blender-expert/`.
- **Upstream re-checked 2026-10-16:** HEAD on `main` is still the pinned commit. The last commit touching this path is `ca0fec5` (2026-10-04). Nothing was re-fetched.

## Why it was picked

This is the lead Blender 5.2 LTS skill: the router plus agent protocol for the 3D asset pipeline.
- **Execution channels:** a live GUI session over a Blender MCP bridge, or headless `blender -b --factory-startup --python-exit-code 1`.
- **The expert loop:** build big to small, and gate each stage on a mesh audit plus a rendered review sheet.
- **Persona chains:** "game asset artist" and "AI-mesh finisher" are the ones relevant here.
- **5.x API traps:** brushes as assets, Auto Smooth removed, slotted actions, and others.
- **Shared toolkit:** `bx_audit.py` (quads %, poles, non-manifold, fidelity to the high poly), `bx_review.py` (contact sheets, turntables) and `bx_gui.py`. The retopology and UV/baking skills import it.

The asset side of a WebXR game is the same as for a native one, so the Blender skills carry over from the Unity library unchanged.

## Security review

- I read the SKILL.md and both references. I read the imports and file I/O of the 3 Python modules.
- They use only bpy, bmesh, mathutils and the standard library.
- They write review images, a legend `.txt` and JSON audits.
- No subprocess and no network.

## Caveats

- **Keep the folder name.** The sibling skills find it as a folder named exactly `scenario-blender-expert` in the same parent folder.
- **It references sibling skills that were not collected** (sculpting, texturing-shading, hard-surface, rigging, and others, plus Scenario's own paid generation skills `scenario-3d`/`scenario-textures`). Install those from the same repo if you need them. The Scenario service skills are optional.
- It targets Blender 5.2. Older Blender versions differ, which the skill itself warns about.
- **No glTF export step.** For three.js and IWSDK, export GLB with Blender's glTF exporter, then compress geometry and textures (meshopt or Draco, KTX2) yourself. No redistributable glTF optimization skill was good enough to collect; see `docs/community-candidates.md`.
