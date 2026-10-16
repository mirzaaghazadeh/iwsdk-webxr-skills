# Source: xr-platforms-audio-and-comfort

- **Repo:** https://github.com/the-vibey-project/vibey
- **Path:** `src/vibey_tools/skills/plugins/vr-ar-development/skills/xr-platforms-audio-and-comfort/`
- **Commit:** `0b2cfd3dc3e0fd3577d12c822d45cf7840c68d58` (2026-10-11)
- **License:** MIT (`LICENSE` copied from the repo root)
- **Stars at fetch:** 3
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/xr-platforms-audio-and-comfort/`.
- **Upstream re-checked 2026-10-16:** the last commit touching the `vr-ar-development` plugin is `bc42417` (2026-09-15), before the pinned commit. Nothing was re-fetched.

## Why it was picked

This is part 3 of the five-skill VR/AR reference. It covers OpenXR as the cross-platform baseline, spatial audio (HRTF, room modelling, why audio carries presence), and comfort, safety and accessibility: guardian and boundary, session length, and seated, standing and mobility-limited play. These are the areas that game-dev skills usually skip. No redistributable web-specific spatial audio or XR accessibility skill was found, so this is the library's main source for both.

## Security review

I read the file. It is Markdown only.

## Caveats

- Engine-neutral and platform-generic. Meta's VRCs and store comfort ratings come from the official Meta skills and docs.
- The OpenXR section describes the native runtime layer. A WebXR app reaches it only through the browser's WebXR Device API.
- See `xr-perceptual-constraints-displays-and-tracking/SOURCE.md` for notes on the parent repo.
