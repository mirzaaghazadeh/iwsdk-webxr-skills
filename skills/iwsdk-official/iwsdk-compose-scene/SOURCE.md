# Source: iwsdk-compose-scene

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-compose-scene/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

Composes `public/scenes/*.iwsdk.scene.json` (schema `iwsdk.scene.v1`) from manifest assets:
placement, contacts, prefabs, patterns, lights, dome/IBL environment, player spawn and authored
camera views, validated with `scene render-file` and `scene flatten`. Has a fast path with a
complete minimal scene and an extended workflow with six references (scene format, composition,
review, image and text intake).

## Caveats

- Same heredoc-instead-of-Edit advice as `iwsdk-build-model`; your own rules win.
- Scene JSON is the IWSDK 0.5+ format. Meta Spatial Editor / GLXF scenes from 0.4.x must be
  migrated first (`iwsdk-migrate-0-5`).

## Security review

Read in full (SKILL.md and all six references). Markdown only; commands are `npx @iwsdk/cli`
scene/dev calls. No injection.
