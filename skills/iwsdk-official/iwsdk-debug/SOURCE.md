# Source: iwsdk-debug

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-debug/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

A bounded runtime debugging loop for physics, animation, collision, interaction and state bugs:
`ecs pause` → `snapshot before` → `step` 1-3 frames → `snapshot after` → `diff`, one hypothesis,
the smallest fix, then the same probe replayed after a production build. Uses ECS evidence instead
of screenshots.

## Caveats

Runs against the emulated runtime (IWER) in the managed browser. For a real headset use
`iwsdk-native-xr-test` (host-only tools like screenshots are unavailable there) and
`../../custom/iwsdk-quest-device-testing`.

## Security review

Read in full. Markdown only. No injection.
