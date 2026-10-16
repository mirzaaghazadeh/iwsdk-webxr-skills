---
name: iwsdk-project-setup
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.0.0"
description: >-
  Sets up a machine and a project for Meta Immersive Web SDK (IWSDK) WebXR
  development with Claude Code: checks Node, maps the game pitch to
  `npm create @iwsdk@latest` flags (vr/ar/browser, physics, locomotion,
  grabbing, scene understanding), explains what the scaffold writes (AGENTS.md,
  CLAUDE.md, .claude skills/rules/agent), connects Claude Code to the
  iwsdk-runtime, iwsdk-reference and metavr MCP servers with `adapter sync`,
  starts the CLI-managed dev server (HTTPS, port 8081, IWER emulator, agent or
  collaborate mode), and fixes headless/cloud setups (IWSDK_GPU, Playwright
  Chromium). Use when starting a new IWSDK or WebXR project, when the user says
  "set up IWSDK", "npm create @iwsdk", "scaffold a WebXR game", "MCP tools
  missing", "iwsdk-runtime not connected", "Node version unsupported", "port
  8081 in use", "Executable doesn't exist" (Playwright), when cloning a
  teammate's IWSDK repo, or when adding IWSDK to an existing Vite app.
---

# IWSDK project setup

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

Gets a machine and a project to the state the official `iwsdk-*` skills expect: an IWSDK 1.x
manifest-first project, dependencies installed, Claude Code connected to the project's MCP servers,
and `npx @iwsdk/cli dev status` reporting `browserCommandReady: true`.

Hand-offs: building features → **`iwsdk-dev`**; testing on a Quest → **`iwsdk-quest-device-testing`**;
0.4.x projects (GLXF, Meta Spatial Editor) → **`iwsdk-migrate-0-5`** first.

## Ground rules

- **Ask before** installing Node, Playwright browsers, Android platform tools, or anything global.
  Never run `npm i -g` or edit `~/.claude` without a yes.
- `adapter sync` writes project config (`.mcp.json`, `.claude/settings.json`). Say so before
  running it in an existing repo.
- **Don't install duplicate skills.** Every scaffold already contains the 12 official skills in
  `.claude/skills/` (and a copy in `.agents/skills/`). Install only this library's `custom/` and
  extra skills into such a project.
- Always use the scoped name `npx @iwsdk/cli ...` (never an unscoped `iwsdk` package via npx).
  The scope is a security boundary: npx could fetch an unrelated package otherwise.
- Check flags with `--help` before relying on them: `npx @iwsdk/create@latest --help`,
  `npx @iwsdk/cli dev up --help`. This skill was checked against 1.0.1.

## 1. Check the machine

```bash
node --version      # must satisfy >=20.19.0 <21 || >=22.12.0 <23 || >=24.0.0
npm --version
git --version
```

The engine range comes from every `@iwsdk/*` `package.json`; the scaffold's `.nvmrc` is
`22.12.0`. Node 18 and Node 21/23 are rejected by `@iwsdk/cli`. If Node is wrong, ask which
version manager the user has (nvm, fnm, Volta, Homebrew) and use it; don't pick one for them.

Optional now, needed for the headset: Android platform tools (`adb version`) and desktop Chrome
(for `chrome://inspect`). See `iwsdk-quest-device-testing`.

## 2. Turn the pitch into flags

| Pitch says | Flag |
|---|---|
| Fully virtual world | `--target vr` |
| Passthrough, content in the real room | `--target ar` (the session mode is `immersive-ar`) |
| Desktop browser 3D, no headset | `--target browser` |
| Gravity, collisions, throwing | `--physics` (Havok; adds a JS + WASM payload) |
| Walk/teleport through a big space | `--locomotion` (VR and browser only) |
| Pick up and move objects | `--grabbing` |
| Real walls, floors, tables, anchors | `--scene-understanding` (AR only) |
| Place things on real surfaces (hit test) | `--environment-raycast` (AR only) |

Every boolean also has a `--no-…` form. Defaults with `--yes`: TypeScript, git init, install.
Recommended baselines (create README): VR = locomotion on a worker + grabbing, no physics;
mixed reality = grabbing only; desktop = browser camera, input, locomotion, interactions.
If the pitch is ambiguous in a way that changes the target or a feature, ask.

## 3. Scaffold

```bash
# new folder (npm create needs `--` before flags)
npm create @iwsdk@latest my-game -- --yes --target vr --grabbing --physics --no-locomotion

# same thing via npx
npx @iwsdk/create@latest my-game --yes --target vr --grabbing --physics --no-locomotion

# inside an existing, non-empty repo: --force is required and overwrites conflicting generated files
npx @iwsdk/create@latest . --yes --force --target vr
```

Useful extras: `--no-install` (inspect first), `--no-git`, `--language js`,
`--skip-reference-warmup` (skip the reference model download). Confirm before `--force`: it
overwrites generated files, keeps unrelated files and the existing git repo.

What lands in the project (full table: [references/generated-files.md](references/generated-files.md)):

```
iwsdk.config.json       project authority: scene, asset/component modules, world.xr, features, dev.emulator
src/index.ts            World.create(container, projectOptions from 'virtual:iwsdk-project') + registerSystem
src/assets.ts           defineAssets({...}): the asset catalog shared by runtime and editor
src/components.ts       defineComponents([...])
public/scenes/main.iwsdk.scene.json   authored scene (iwsdk.scene.v1)
public/ui/welcome.uikitml             spatial UI panel
AGENTS.md + CLAUDE.md   CLAUDE.md is "@AGENTS.md"
.claude/                skills (12), rules (4), agents/iwsdk-project-code-reviewer.md, settings.json
```

Change features in `iwsdk.config.json` (`world.features`, `world.xr.features`), not by
re-scaffolding. Editing it restarts Vite in place.

## 4. Install and connect Claude Code

```bash
cd my-game
npm install                                   # skip if create already installed
npx @iwsdk/cli adapter sync --tools claude    # create runs `adapter sync` (all tools) after installing
npx @iwsdk/cli adapter status
npx @iwsdk/cli reference warmup               # one-time download of the reference corpus + pinned model
npx @iwsdk/cli reference status
```

`adapter sync --tools claude` writes `.mcp.json` with up to three stdio servers, each run with
`node` and an absolute path into `node_modules`:

| Server | Runs | Gives Claude |
|---|---|---|
| `iwsdk-runtime` | `@iwsdk/cli/dist/cli.js mcp stdio` | `xr_*`, `browser_*`, `scene_*`, `ecs_*`, `ui_*`, `asset_*` tools on the running app |
| `iwsdk-reference` | `@iwsdk/reference` entrypoint | semantic search, API lookup, component/system lists |
| `metavr` | `@meta-quest/metavr/bin.js mcp server` | Quest device control, Meta docs search, 3D asset search |

It also adds `enabledMcpjsonServers` and narrow `mcp__<server>__*` allow rules to
`.claude/settings.json`, and removes an old `enableAllProjectMcpServers: true` if present.
Then **restart the Claude Code session** and check with `/mcp`. Snippet and details:
[references/claude-code-mcp.md](references/claude-code-mcp.md).

If MCP tools are missing or deferred, use the CLI: every tool has a CLI twin
(`xr_get_session_status` = `npx @iwsdk/cli xr status`, `browser_screenshot` =
`npx @iwsdk/cli browser screenshot`). `npx @iwsdk/cli mcp inspect --tool <name>` prints a schema.

**Cloned a teammate's repo?** `.mcp.json`, `.cursor/mcp.json`, `.vscode/mcp.json`,
`.codex/config.toml` and `.iwsdk/` are git-ignored by the scaffold. Run `npm install`, then
`npx @iwsdk/cli adapter sync --tools claude` and `reference warmup` on each machine.

## 5. Start the dev server

```bash
npm run dev                                   # = iwsdk dev restart --open --foreground (headed, attached)
npx @iwsdk/cli dev up --ai-mode agent         # headless, fixed 800x800 viewport, returns to the shell
npx @iwsdk/cli dev up --ai-mode collaborate   # one visible managed Chromium window with Runtime/Editor
npx @iwsdk/cli dev status                     # data.runtimeUrls.local / .network, data.state.browserCommandReady
npx @iwsdk/cli dev logs --tail 100
npx @iwsdk/cli dev down
```

- The developer owns headed vs headless. Announce a change before restarting.
- Wait for `browserCommandReady: true` before browser, XR or ECS commands; `dev up` can return
  earlier.
- Port **8081** (`vite.config.ts` `server.port`) fails if busy instead of moving. Stop the other
  process (`lsof -i :8081`) or change the port.
- HTTPS is on: `iwsdkDev()` generates a self-signed certificate cached in `.iwsdk/https` and
  installs no CA. The managed browser accepts it; a headset shows a one-time warning.
  `iwsdkDev({ https: false })` opts out (WebXR then only works on `localhost`).
- First smoke test: `npx @iwsdk/cli browser screenshot --output-file artifacts/first.png`, then
  `npx @iwsdk/cli xr enter` and `npx @iwsdk/cli xr status`.

## 6. Emulator (IWER) settings

In `iwsdk.config.json` → `dev.emulator` (defaults from `@iwsdk/vite-plugin-dev` types):

| Key | Default | Notes |
|---|---|---|
| `device` | `metaQuest3` | also `metaQuest2`, `metaQuestPro`, `metaVRGlasses` (adds gaze), `oculusQuest1` |
| `activation` | `localhost` | emulate only on localhost; `always` or a RegExp |
| `userAgentException` | `/OculusBrowser/` | never emulate in Quest Browser |
| `environment` | none (AR scaffolds use `living_room`) | `living_room`, `meeting_room`, `music_room`, `office_large`, `office_small` |
| `iwer` | `true` | `false` = never inject (browser-only apps) |
| `injectOnBuild` | `false` | keep `false` for store builds |

## 7. Cloud and headless machines

- The managed browser is Playwright Chromium. It picks GPU or SwiftShader automatically;
  override with `IWSDK_GPU=auto|gpu|swiftshader` (`vite-plugin-dev/src/managed-browser/launch.ts`).
  SwiftShader frame times are meaningless for performance.
- `Executable doesn't exist at …/chromium_headless_shell-…`: install the browser for the
  Playwright version the project resolves: `npm ls playwright`, then
  `npx playwright@<that version> install chromium` (on Linux CI add `--with-deps`).
- Long screenshots cost context: `--screenshot-width 500 --screenshot-height 500` on `dev up`.

## 8. Adding IWSDK to an existing Vite app

Prefer scaffolding a throwaway project with the same target and copying its `iwsdk.config.json`,
`vite.config.ts`, `src/assets.ts`, `src/components.ts`, `.claude/` and `AGENTS.md`. The runtime
needs one shared Three.js instance:

```json
{
  "dependencies": { "@iwsdk/core": "^1.0.1", "three": "npm:super-three@0.181.0" },
  "overrides": { "three": "npm:super-three@0.181.0" }
}
```

(pnpm reads the override from `pnpm-workspace.yaml`.) Import Three.js classes from
`@iwsdk/core`, not `three`. Keep every `@iwsdk/*` package on the same version.

## 9. Side effects and privacy

Scaffolds add `@meta-quest/metavr` (Meta's Quest CLI) as a dev dependency. Tell the user, before
the first `npm install`, what it does:

- **Postinstall writes outside the project** (read in `postinstall.js` / `download.js` of 1.8.1):
  it downloads the `metavr` binary from `securecdn.oculus.com` into `~/.metavr` (or
  `$METAVR_HOME`) and appends a completions block to `~/.zshrc`, or `~/.bash_profile` /
  `~/.bashrc`, or the PowerShell profile. To avoid that, install with
  `METAVR_SKIP_DOWNLOAD=1 npm install` (the binary is then fetched on first `metavr` run), or
  remove the package.
- **Telemetry**: when it is installed, `@iwsdk/cli` and the Vite plugin report each runtime tool
  call (tool name, duration, a fixed failure code, session id) through `metavr`, which also has
  its own telemetry. `npm exec metavr -- telemetry status` / `telemetry disable` (essential only).
- `npm uninstall @meta-quest/metavr` stops both, and removes the `metavr` MCP server and device
  tools (you can still use `adb` directly). Let the user choose.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Unsupported Node` from `@iwsdk/cli` | Node outside the engine range (step 1) |
| `dev up` fails, port in use | another server on 8081; stop it or change `server.port` |
| `browser_not_launched` | started with `--no-open`; `npx @iwsdk/cli dev restart --open` |
| Runtime commands time out | `xr status` → `browser logs` → `browser reload` → `dev restart`, in that order |
| `iwsdk-runtime` tools absent in Claude | `adapter sync --tools claude`, restart session, `/mcp`; use CLI meanwhile |
| Reference tools say warmup required | `npx @iwsdk/cli reference warmup` |
| Cryptic errors from `node_modules/.vite/deps/chunk-*.js` after an update | stop the server, `rm -rf node_modules/.vite/deps`, start again (IWSDK troubleshooting page) |
| "Only pmndrs/uikit components can be added as children" | duplicate Three/UIKit graph; keep the scaffold's `resolve.dedupe` in `vite.config.ts` |

## Sources

- https://github.com/facebook/immersive-web-sdk (commit `0778f518`, 1.0.1): `packages/create/src/cli.ts`, `src/catalog.ts`, `src/project-files.ts`, `packages/cli/src/mcp-adapters.ts`, `agent-adapters.ts`, `help.ts`, `packages/vite-plugin-dev/src/types.ts`, `template/common/vite.config.ts`
- https://iwsdk.dev/guides/01-project-setup.html
- https://iwsdk.dev/guides/02-testing-experience.html
- https://iwsdk.dev/ai/getting-started.html, https://iwsdk.dev/ai/modes.html
- https://iwsdk.dev/skill.md (headless GPU and Playwright notes)
- https://www.npmjs.com/package/@iwsdk/create (1.0.1, 2026-10-16)

Last verified: 2026-10-16
