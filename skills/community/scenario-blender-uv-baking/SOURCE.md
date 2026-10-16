# Source: scenario-blender-uv-baking

- **Repo:** https://github.com/scenario-labs/skills
- **Path:** `skills/dcc/blender/scenario-blender-uv-baking/`
- **Commit:** `49dd26e47371163ae0020c7f5627d0993626bfc2` (2026-10-15)
- **License:** MIT, Copyright 2026 Scenario Inc. (`LICENSE` copied)
- **Stars at fetch:** 1032
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/scenario-blender-uv-baking/`.
- **Upstream re-checked 2026-10-16:** HEAD on `main` is still the pinned commit. The last commit touching this path is `ca0fec5` (2026-10-04). Nothing was re-fetched.

## Why it was picked

It covers game-ready UVs and high-to-low bakes in Blender 5.2:
- seams follow the texturing method, and every hard edge is a seam;
- the unwrap method is chosen by measurement;
- texel density is set before texture size, with target px/cm per camera type;
- pixel-true padding of res/128;
- projection distance is measured with adaptive extrusion rather than guessed;
- bakes are judged in pixels (inverted or flat texels) and under a raking light;
- unique UVs where baked lighting differs, and the OpenGL normal convention. Its own convention table lists glTF as OpenGL, which is what three.js expects.

The `bx_uvbake.py` toolkit computes every gate. Baked lighting matters even more for a browser game on Quest, where real-time shadows are expensive.

## Security review

- I read the SKILL.md. I grepped the references and `bx_uvbake.py`.
- It uses bpy, bmesh, numpy and the standard library, and writes bake images.
- No subprocess and no network.

## Caveats

- It needs `scenario-blender-expert` installed next to it, in the same parent folder.
- `numpy` must be available in Blender's Python. Recent Blender builds bundle it.
- It stops at baked images. Converting them to KTX2 for the web is not covered.
