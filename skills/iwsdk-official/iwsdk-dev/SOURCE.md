# Source: iwsdk-dev

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-dev/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1`: written to `.claude/skills/` and `.agents/skills/` of every new project (byte-identical, checked 2026-10-16) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

The IWSDK team's own entry point for app work. `SKILL.md` only routes: fresh builds go to
`references/planner.md`, bounded changes to an existing app go to `references/iterate.md`.
`references/api-reference.md` (about 1,500 lines) is the API ground truth for ECS, input, player
rig, audio, physics, grabbing, environment, assets, locomotion, scene understanding, UI and
anti-patterns. The `iwsdk-project-code-reviewer` agent reads that file by path.

## Caveats

- Assumes an IWSDK 1.0 manifest-first project (`iwsdk.config.json` + `virtual:iwsdk-project`) and
  the scaffold's `.claude/rules/*.md` and scoped `AGENTS.md` files.
- The playbooks contain hard tool-call and screenshot budgets tuned for agent evaluations. They
  are sensible defaults, not limits you must obey when the user wants more.
- See `../ERRATA.md` (AssetType list, foveation default).

## Security review

Read in full (SKILL.md, planner, iterate, api-reference). Markdown only. Shell commands are
bounded reads (`sed -n`, `find`) and `npx @iwsdk/cli` runtime calls. No injection, no network
beyond the IWSDK CLI.
