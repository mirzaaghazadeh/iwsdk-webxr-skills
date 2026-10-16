# Source: scenario-blender-retopology

- **Repo:** https://github.com/scenario-labs/skills
- **Path:** `skills/dcc/blender/scenario-blender-retopology/`
- **Commit:** `49dd26e47371163ae0020c7f5627d0993626bfc2` (2026-10-15)
- **License:** MIT, Copyright 2026 Scenario Inc. (`LICENSE` copied)
- **Stars at fetch:** 1032
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/scenario-blender-retopology/`.
- **Upstream re-checked 2026-10-16:** HEAD on `main` is still the pinned commit. The last commit touching this path is `ca0fec5` (2026-10-04). Nothing was re-fetched.

## Why it was picked

Quest games need tight triangle budgets, and a browser game on Quest has less headroom than a native one. This skill turns dense sculpts, scans or **AI-generated meshes** into clean low-poly topology:
- a game low poly is the silhouette plus the loops needed for animation;
- auto-remesh (QuadriFlow, voxel) is fine for static assets, while deforming characters need planned loops;
- pole placement rules, a Shrinkwrap cage fitted on the subdivided surface, and topology audits.

The `bx_retopo.py` toolkit is tested on Blender 5.2.1 and every claim is sourced.

## Security review

- I read the SKILL.md. I grepped the references and `bx_retopo.py`.
- It uses bpy, bmesh and the standard library.
- No subprocess and no network.

## Caveats

- It needs `scenario-blender-expert` installed next to it, in the same parent folder.
- The default game budget is "< 10,000 tris per character". Set your own Quest budget per scene.
- Its worked example exports FBX. For three.js and IWSDK, export GLB with Blender's glTF exporter instead.
