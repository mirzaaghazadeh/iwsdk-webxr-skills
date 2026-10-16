# Source: iwsdk-ray

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-ray/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

Proves ray interactions with emulated controllers: `xr look-at` to aim, `xr select` for
`RayInteractable` and UIKit buttons, and a held trigger (button `0`) for `DistanceGrabbable`,
including the `MoveFromTarget` distance trick. Pairs with `iwsdk-grab`.

## Caveats

Verification only; implementation patterns live in `iwsdk-dev/references/api-reference.md`.

## Security review

Read in full. Markdown only. No injection.
