# Source: iwsdk-physics

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-physics/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

Havok rigid bodies in IWSDK: `world.features.physics`, `PhysicsBody` (`DYNAMIC`/`STATIC`/
`KINEMATIC`) plus `PhysicsShape`, shape choice (`ConvexHull` for dynamic meshes, `TriMesh` for
static only), `PhysicsManipulation` for forces, `PhysicsSystem.setBodyTransform` for resets,
worker vs main-thread mode, and ECS-stepped verification. Three references hold component
fields, workflows and tuning.

## Caveats

- Since 1.0, `physics: true` runs Havok in a Web Worker at a fixed 60 Hz by default
  (`packages/core/CHANGELOG.md` 1.0.0).
- `physics: false` removes the Havok JS + WASM payload from the build (guide 08), so leave it off
  when nothing needs simulation.

## Security review

Read in full (SKILL.md and three references). Markdown only. No injection.
