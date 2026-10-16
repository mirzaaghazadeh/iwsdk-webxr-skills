# Source: xr-reference

- **Repo:** https://github.com/the-vibey-project/vibey
- **Path:** `src/vibey_tools/skills/plugins/vr-ar-development/skills/xr-reference/`
- **Commit:** `0b2cfd3dc3e0fd3577d12c822d45cf7840c68d58` (2026-10-11)
- **License:** MIT (`LICENSE` copied from the repo root)
- **Stars at fetch:** 3
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/xr-reference/`.
- **Upstream re-checked 2026-10-16:** the last commit touching the `vr-ar-development` plugin is `bc42417` (2026-09-15), before the pinned commit. Nothing was re-fetched.

## Why it was picked

This is part 5 of the five-skill VR/AR reference. It holds the XR anti-pattern list, a numbers table (frame budgets per refresh rate, IPD range, latency thresholds), the platform landscape (Quest's installed base, Horizon OS, Android XR, visionOS, WebXR), the resource list, and a quick reference. It is a fast lookup during design reviews, and it is engine-neutral, so it applies to an IWSDK app as much as to a Unity one.

## Security review

I read the file. It is Markdown only.

## Caveats

- The platform landscape section is a dated snapshot from August 2026 and will go stale first.
- See `xr-perceptual-constraints-displays-and-tracking/SOURCE.md` for notes on the parent repo.
