# Source: xr-ux-design-and-performance-budgeting

- **Repo:** https://github.com/the-vibey-project/vibey
- **Path:** `src/vibey_tools/skills/plugins/vr-ar-development/skills/xr-ux-design-and-performance-budgeting/`
- **Commit:** `0b2cfd3dc3e0fd3577d12c822d45cf7840c68d58` (2026-10-11)
- **License:** MIT (`LICENSE` copied from the repo root)
- **Stars at fetch:** 3
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/xr-ux-design-and-performance-budgeting/`.
- **Upstream re-checked 2026-10-16:** the last commit touching the `vr-ar-development` plugin is `bc42417` (2026-09-15), before the pinned commit. Nothing was re-fetched.

## Why it was picked

This is part 4 of the five-skill VR/AR reference. It covers 3D UX (text legibility, placement zones, diegetic UI, scale and affordance, never moving the camera without input) and XR performance budgeting (11.1 ms at 90 Hz for both eyes, sustained versus burst on mobile SoCs, overdraw and fill rate, profiling on the device with frame-time histograms rather than averages).

## Security review

I read the file. It is Markdown only.

## Caveats

- Some levers it lists, such as "GPU instancing", are generic. In three.js they map to `InstancedMesh` and `BatchedMesh`, and the browser adds its own costs (shader compile hitches, garbage collection). See `threejs-perf-loading` for those, and measure on the headset, not the desktop.
- For in-XR UI, its placement and legibility rules apply to `pmndrs-uikit` panels, where sizes are set with `pixelSize`.
- See `xr-perceptual-constraints-displays-and-tracking/SOURCE.md` for notes on the parent repo.
