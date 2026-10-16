# Source: iwsdk-depth-occlusion

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-depth-occlusion/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

Mixed-reality occlusion: request `depthSensing` in the AR session, register `DepthSensingSystem`
once, tag only the intended entities with `DepthOccludable` (soft, `HardOcclusion` or
`MinMaxSoftOcclusion`), then verify in the emulator's synthetic room.

## Caveats

Depth sensing needs a headset that supports it (Quest 3 / 3S class). The emulator's room data
proves wiring, not final quality; check on the device. Longer background: https://iwsdk.dev guide
15 (depth occlusion).

## Security review

Read in full. Markdown only. No injection.
