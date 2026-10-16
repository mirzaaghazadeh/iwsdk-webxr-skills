# Source: IWSDK official agents

| Field | Value |
|---|---|
| Publisher | Meta Platforms, Inc. (the IWSDK team) |
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/agents/iwsdk-project-code-reviewer.md` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1`: every new project gets it at `.claude/agents/` |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

`agents/iwsdk-project-code-reviewer.md` is copied unchanged. It sits inside this folder because
`skills/iwsdk-official/` is the root of the `iwsdk-official` Claude Code plugin, and Claude Code
loads plugin agents from the plugin's own `agents/` folder (agents listed in a marketplace entry
didn't load when tested with Claude Code 2.1.301).

## What it is

A Claude Code subagent (`tools: Read, Grep, Glob, Bash`, `model: sonnet`) that reviews **apps built
with IWSDK**, not the SDK itself. It first reads
`.claude/skills/iwsdk-dev/references/api-reference.md`, then checks `iwsdk.config.json` feature
flags against the scene (locomotion without `LocomotionEnvironment`, physics without
`PhysicsBody` + `PhysicsShape`), allocations in `update()`, polling instead of query
subscriptions, missing `cleanupFuncs`, `Types.Object`, direct `three` imports, raw `GLTFLoader`
or `Raycaster`, `scene.add()`, environment components off the level root, `_needsUpdate`, and
`destroy()` vs `dispose()`. It reports Critical / Warning / Suggestion with a confidence rule.

The `iwsdk-dev` playbooks say to launch it only when a live or build failure stays unexplained,
the code crosses an unfamiliar framework boundary, or the user asks for a review.

## How to use it

- Projects made with `npm create @iwsdk@latest` already have it. Ask: "Use the
  iwsdk-project-code-reviewer agent to review src/."
- For other projects, install the `iwsdk-official` bundle (plugin or `./install.sh --project
  <dir> iwsdk-official`, which copies the agent to `<project>/.claude/agents/`), or copy
  `agents/iwsdk-project-code-reviewer.md` there by hand together with the `iwsdk-dev` skill, so
  the path it reads exists. Ask before writing to `~/.claude/agents/` (user level).
- With the plugin it appears as `iwsdk-official:iwsdk-project-code-reviewer`.
- `model: sonnet` is an alias; Claude Code resolves it to the current Sonnet model.

## Left out

| Item | Why |
|---|---|
| Repo-root `.claude/agents/iwsdk-code-reviewer.md` | Reviews the SDK's own `packages/*` and runs the monorepo's `pnpm format:check` / `pnpm lint` |
| Repo-root `.claude/hooks/iwsdk-stop-check.sh` | Maintainer Stop hook (needs `jq`; nudges `pnpm format/lint/build` and asks the agent to append feedback to `.claude/mcp-feedback.jsonl`). Not useful in an app as written. An app team could adapt the idea (a Stop hook that reminds the agent to run `npm run typecheck`, `npx @iwsdk/cli browser screenshot` and `browser logs` after code edits), but it would be new code, not this file |

## Security review

Read in full. Markdown only, no hidden instructions. It can run Bash; the only commands it
implies are read-only inspection. No network calls.
