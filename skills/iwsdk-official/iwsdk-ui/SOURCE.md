# Source: iwsdk-ui

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-ui/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

UIKitML spatial panels and ScreenSpace HUDs as one verified slice: manifest registration
(`AssetType.UIKitML`), scene placement, `requireElementById` wiring with cleanup, isolated
`ui render-preview`, live `ui inspect`, and a final visual gate. It states the placement rules
(world-space or object-attached panels, thresholded `Follower`, no head-locked menus) and the
Horizon kit's light panel surface.

## Caveats

- The contact-sheet command is Windows PowerShell only; on macOS use an image tool you already
  have. See `../ERRATA.md`.
- UIKit sizes are centimetres (`width: 100` = 1 m).

## Security review

Read in full. Markdown only. The PowerShell one-liner only resizes two local PNGs into one JPEG.
No injection.
