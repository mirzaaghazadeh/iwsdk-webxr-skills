# Source: xr-perceptual-constraints-displays-and-tracking

- **Repo:** https://github.com/the-vibey-project/vibey
- **Path:** `src/vibey_tools/skills/plugins/vr-ar-development/skills/xr-perceptual-constraints-displays-and-tracking/`
- **Commit:** `0b2cfd3dc3e0fd3577d12c822d45cf7840c68d58` (2026-10-11)
- **License:** MIT (`LICENSE` copied from the repo root). Plugin author: Adam Matthew Steinberger.
- **Stars at fetch:** 3
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/xr-perceptual-constraints-displays-and-tracking/`.
- **Upstream re-checked 2026-10-16:** the last commit touching the `vr-ar-development` plugin is `bc42417` (2026-09-15), before the pinned commit. Nothing was re-fetched.

## Why it was picked

This is part 1 of a five-skill, engine-neutral VR/AR design reference. All five are collected because they cross-reference each other by section number (§N). This part covers motion-to-photon latency budgets, the causes of cybersickness (vection, vergence-accommodation conflict), presence, displays and optics (PPD, refresh), and tracking. Getting these wrong is what makes a Quest game physically uncomfortable, whether it is built in Unity or in the browser. No other collected skill explains the "why" behind comfort rules this well.

## Security review

I read the file. It is Markdown only, with no scripts and no tool instructions.

## Caveats

- The parent repo is a large general-purpose orchestrator (857 skills) with few stars. Only the `vr-ar-development` plugin was taken.
- It is a reference, not a how-to. Pair it with the IWSDK and Meta skills in this library for the WebXR implementation.
- Its currency snapshot is dated August 2026. Hardware numbers will drift.
