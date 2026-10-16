# Source: iwsdk-build-model

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-build-model/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

Builds or repairs one reusable model, as a glTF or a deterministic procedural `Object3D`, and
proves it with `npx @iwsdk/cli asset render-preview` contact sheets in `material` and `clay`
modes, with geometry warnings and named-part focus. It hands a stable manifest id to
`iwsdk-compose-scene`. Includes `assets/hardsurface.ts.template`, a construction library (lofts,
bevelled boxes, surface frames, seeded random) and `agents/openai.yaml` (Codex display metadata).

## Caveats

- Needs the managed editor running (`npx @iwsdk/cli dev up`) for previews.
- Tells Claude Code to write long files with Bash heredocs and avoid `Edit` on files over about
  120 lines, to save context. Your own `CLAUDE.md` rules about file tools take precedence.
- For downloaded models, use `../../custom/iwsdk-asset-pipeline` first (no Meshopt in IWSDK).

## Security review

Read in full, including the 599-line TypeScript template: pure geometry, imports only from
`@iwsdk/core`, no network, DOM, file system or timers. The skill copies the template into
`src/scene-assets/lib/` with `find` + `cp`. No injection.
