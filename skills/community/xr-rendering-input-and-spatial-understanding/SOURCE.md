# Source: xr-rendering-input-and-spatial-understanding

- **Repo:** https://github.com/the-vibey-project/vibey
- **Path:** `src/vibey_tools/skills/plugins/vr-ar-development/skills/xr-rendering-input-and-spatial-understanding/`
- **Commit:** `0b2cfd3dc3e0fd3577d12c822d45cf7840c68d58` (2026-10-11)
- **License:** MIT (`LICENSE` copied from the repo root)
- **Stars at fetch:** 3
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/xr-rendering-input-and-spatial-understanding/`.
- **Upstream re-checked 2026-10-16:** the last commit touching the `vr-ar-development` plugin is `bc42417` (2026-09-15), before the pinned commit. Nothing was re-fetched.

## Why it was picked

This is part 2 of the five-skill VR/AR reference. It covers stereo rendering (single-pass/multiview), reprojection (ATW/ASW as a safety net, not a budget), fixed and eye-tracked foveation, MSAA versus TAA in XR, and TBDR rules. It also covers input (controllers, hands, gaze, gorilla arm) and the locomotion comfort table: snap turn as the default, and vignetted smooth movement offered as an option rather than imposed. Anchors and occlusion are included for MR.

## Security review

I read the file. It is Markdown only.

## Caveats

- Engine-neutral. It explains why the levers matter, not how to set them in a browser. In a WebXR app on Quest the equivalents are the XR framebuffer scale, the foveation level and multiview, which IWSDK and three.js's `WebXRManager` expose. Check the IWSDK and Meta skills for what Quest Browser actually supports before relying on a native-app feature such as Application SpaceWarp.
- See `xr-perceptual-constraints-displays-and-tracking/SOURCE.md` for notes on the parent repo.
