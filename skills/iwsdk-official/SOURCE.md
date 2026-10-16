# Source: Immersive Web SDK official skills

| Field | Value |
|---|---|
| Publisher | Meta Platforms, Inc. (the IWSDK team) |
| Repository | https://github.com/facebook/immersive-web-sdk (341 stars at fetch) |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, "release(iwsdk): prepare 1.0.1 packages") |
| npm release | `@iwsdk/create@1.0.1`, `@iwsdk/core@1.0.1`, `@iwsdk/cli@1.0.1` (all published 2026-10-16) |
| License | MIT (copy in `LICENSE` here and in every skill folder) |
| Fetched | 2026-10-16 |
| Docs | https://iwsdk.dev (agent entry points: https://iwsdk.dev/llms.txt, https://iwsdk.dev/skill.md) |

Every skill folder is copied unchanged. Only `LICENSE` and `SOURCE.md` were added to each folder.
Upstream disagreements with the code or docs are listed in [ERRATA.md](ERRATA.md).

## Where these skills come from

`npm create @iwsdk@latest` writes a full set of coding-agent guidance into every new project. The
canonical source is `packages/create/guidance/claude/.claude/` in the repo. A scaffold made on
2026-10-16 with `npx @iwsdk/create@1.0.1 vrapp --yes --target vr --no-install --no-git` produced a
`.claude/` tree that is byte-identical to that folder at the commit above (`diff -rq`, no output).

What a new project gets (no `--ai-tools` step: every integration is always written):

| Path in the new project | What it is |
|---|---|
| `AGENTS.md` | Project rules for all agents (from `packages/cli/guidance/AGENTS.md`) |
| `CLAUDE.md` | Two-line shim: `# IWSDK project guidance` + `@AGENTS.md` |
| `.claude/skills/` (12) | The skills in this folder, except `iwsdk-migrate-0-5` |
| `.agents/skills/` | Identical copy of the same 12 skills for Codex and other `AGENTS.md` harnesses |
| `.claude/rules/*.md` (4) | Path-scoped rules: `ecs-api`, `assets-and-manifest`, `scene-json`, `uikitml` |
| `.claude/agents/iwsdk-project-code-reviewer.md` | Review subagent (copied to `agents/` in this folder; see `AGENT-SOURCE.md`) |
| `.claude/settings.json` | Pre-allows `mcp__iwsdk-runtime__*`, `mcp__iwsdk-reference__*`, `mcp__metavr__*` and the 12 skills; enables those three `.mcp.json` servers |
| `src/AGENTS.md`, `public/scenes/AGENTS.md`, `public/ui/AGENTS.md` | Scoped copies of the rules |
| `.cursor/rules/*.mdc`, `.github/instructions/*.md`, `.codex/config.toml` | Same rules for Cursor, Copilot, Codex |
| `.mcp.json` (after `npm install`) | Written by `npx @iwsdk/cli adapter sync`; git-ignored because it holds absolute paths |

## What was copied (13)

| Skill | Upstream path | Use it for |
|---|---|---|
| `iwsdk-dev` | `packages/create/guidance/claude/.claude/skills/` | **Entry point.** Routes to a greenfield planner or a bounded-change playbook; `references/api-reference.md` is the 1,500-line API ground truth |
| `iwsdk-build-model` | same | One glTF or procedural `Object3D` model, checked with material and clay contact sheets |
| `iwsdk-compose-scene` | same | `iwsdk.scene.v1` scene JSON: placement, lights, environment, cameras |
| `iwsdk-ui` | same | UIKitML spatial panels and ScreenSpace HUDs, with preview and live inspection |
| `iwsdk-grab` | same | Prove proximity grab (`OneHandGrabbable`, `TwoHandsGrabbable`, squeeze = button 1) with emulated controllers |
| `iwsdk-ray` | same | Prove ray clicks, UIKit buttons and `DistanceGrabbable` (trigger = button 0) |
| `iwsdk-debug` | same | ECS pause, snapshot, step, diff loop for state bugs |
| `iwsdk-physics` | same | Havok bodies and shapes, forces, physics grabbing |
| `iwsdk-depth-occlusion` | same | AR depth sensing and `DepthOccludable` |
| `iwsdk-native-xr-test` | same | Drive a real Quest Browser session over `adb reverse` with the same CLI |
| `iwsdk-hosting` | same | Put the app on a public HTTPS origin (Vercel, or a hand-off for an existing host) |
| `iwsdk-pwa-packaging` | same | PWA manifest, Bubblewrap APK, Digital Asset Links, `ovr-platform-util` upload |
| `iwsdk-migrate-0-5` | `docs/public/skills/iwsdk-migrate-0-5/` | Move a 0.4.x app (GLXF, Meta Spatial Editor, UIKitML compiler, mkcert) to the 0.5+ native scene format. Served at https://iwsdk.dev/skills/iwsdk-migrate-0-5/SKILL.md (identical on 2026-10-16) |

The skills call each other by these names, and the code-reviewer agent reads
`.claude/skills/iwsdk-dev/references/api-reference.md`, so keep the folder names.

## What was left out, and why

| Item | Why |
|---|---|
| `docs/public/skill.md` (also named `iwsdk-dev`, served at https://iwsdk.dev/skill.md) | Same `name:` as the scaffold's `iwsdk-dev`, so both can't be installed. It's the cloud/headless-harness variant and is partly stale (headings say 0.4.x; it documents a `--ai-tools` create flag that 1.0.1 doesn't have). Its useful parts (headless GPU, Playwright revision fix, GitHub Pages deploy) are covered in `../custom/iwsdk-project-setup` with citations |
| Repo-root `.claude/skills/test-all`, `test-audio`, `test-ecs-core`, `test-environment`, `test-grab`, `test-interactions`, `test-level`, `test-locomotion`, `test-physics`, `test-ui` | For SDK maintainers: they test the SDK's own `examples/` (poke, grab, physics...) with the monorepo's port map and `pnpm build:tgz` |
| Repo-root `click-target`, `xr-mode-test` | Maintainer helpers that call the retired `mcp__iwsdk-dev-mcp__*` tool names (now `iwsdk-runtime`) and legacy `PanelUI` |
| Repo-root `iwsdk-ui-panel` | Older maintainer variant of `iwsdk-ui` |
| Repo-root `iwsdk-dev` | Identical to the scaffold copy |
| Repo-root `.claude/agents/iwsdk-code-reviewer.md` | Reviews the SDK's own `packages/*` (runs `pnpm format:check`, `pnpm lint`) |
| Repo-root `.claude/hooks/iwsdk-stop-check.sh` | Maintainer Stop hook: needs `jq`, asks for `pnpm format/lint/build` and appends MCP feedback to `.claude/mcp-feedback.jsonl`. Described in `docs/research-iwsdk.md` |
| `.claude/rules/*.md` | Not skills. They come with every scaffold; see "Expectations" below |
| `meta-quest/iwsdk-v0-template` `.agents/skills/` | Older names of the same set (`iwsdk-planner`, `iwsdk-scene-composer`) |

## Expectations (read before using)

- The skills assume an **IWSDK 1.0 manifest-first project**: `iwsdk.config.json`,
  `virtual:iwsdk-project` passed to `World.create()`, `@iwsdk/cli` and `@iwsdk/vite-plugin-dev` in
  `devDependencies`, and a runtime started with `npx @iwsdk/cli dev up` (or `npm run dev`).
- `iwsdk-dev`'s playbooks read the scaffold's `.claude/rules/*.md` and scoped `AGENTS.md`. For a
  project not made with `npm create @iwsdk@latest`, scaffold a throwaway project and copy those
  files, or read the same rules at the commit above.
- **Don't double-install.** A scaffolded project already has these 12 skills in `.claude/skills/`.
  Install this folder only for older projects, for `iwsdk-migrate-0-5`, or to update stale copies.

## Security review (2026-10-16)

All 13 skills were read in full, including every `references/` file, plus the 599-line
`iwsdk-build-model/assets/hardsurface.ts.template`. Results:

- No prompt injection, no hidden instructions, no obfuscated content, no telemetry calls.
- The TypeScript template is pure geometry (imports only from `@iwsdk/core`; no network, DOM,
  file system, timers or unseeded randomness).
- Outward-facing actions are all gated by "ask the developer": deploys (`npx -y vercel@latest`,
  `netlify-cli`, `wrangler`, `firebase-tools`, `gh-pages`), the signing keystore, the
  `ovr-platform-util` download and Store upload, and the global `npm i -g @meta-quest/bubblewrap-cli`.
- `iwsdk-pwa-packaging/references/store-upload.md` downloads `ovr-platform-util` from
  `https://www.oculus.com/download_app/?id=1462426033810370&access_token=OC%7C1462426033810370%7C`.
  That is Meta's public download link format (the `OC|<app id>|` token is a public app token, not a
  secret).
- Things to watch: `npx -y <tool>@latest` runs unpinned packages; the `keytool` example puts
  passwords on the command line (they land in shell history; prefer prompting); the generated
  `.claude/settings.json` pre-approves all `iwsdk-runtime`, `iwsdk-reference` and `metavr` MCP tools.

## Updating

```bash
git clone --depth 1 https://github.com/facebook/immersive-web-sdk.git /tmp/iwsdk
diff -rq /tmp/iwsdk/packages/create/guidance/claude/.claude/skills ./ | grep -v -e LICENSE -e SOURCE.md
diff -rq /tmp/iwsdk/docs/public/skills/iwsdk-migrate-0-5 ./iwsdk-migrate-0-5
```

Review what changed, copy it over, then update the commit in this file and in each skill's
`SOURCE.md`. A freshly scaffolded project is the other way to get the current set.
