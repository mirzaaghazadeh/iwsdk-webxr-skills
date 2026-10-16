# Source: iwsdk-grab

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-grab/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

Proves near-hand grabbing (`OneHandGrabbable`, `TwoHandsGrabbable`) with emulated controllers:
find the entity, animate the controller to it, hold squeeze (gamepad button index `1`), check
`Grabbed`, move, release. Short and precise about which button and which component.

## Caveats

- It verifies interactions; implementation patterns are in `iwsdk-dev/references/api-reference.md`
  §12 and the scaffold's `ecs-api` rule.
- Distance grab is `iwsdk-ray` (trigger, index `0`).

## Security review

Read in full. Markdown only. No injection.
