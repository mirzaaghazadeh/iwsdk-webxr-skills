# What `@iwsdk/create@1.0.1` generates

Checked on 2026-10-16 by running, in an empty scratch folder:

```bash
npx -y @iwsdk/create@1.0.1 vrapp --yes --target vr --no-install --no-git
```

and against `packages/create/src/project-files.ts` at commit `0778f518`. There is **no
tool-selection step**: files for Claude Code, Codex, Cursor, GitHub Copilot and OpenCode are
always written. Delete the ones you don't use.

## App files

| Path | Purpose |
|---|---|
| `package.json` | Scripts `dev` (`iwsdk dev restart --open --foreground`), `dev:runtime` (`vite`), `dev:down`, `dev:status`, `reference:status`, `reference:warmup`, `typecheck` (`tsc --noEmit`, TS only), `build` (`vite build`), `preview`. Deps: `@iwsdk/core`, `@pmndrs/uikit*`, `three: npm:super-three@0.181.0`. Dev deps: `@iwsdk/cli`, `@iwsdk/reference`, `@iwsdk/vite-plugin-dev`, `@meta-quest/metavr`, `typescript`, `vite@^7`. `overrides` pin `three` and `sharp` |
| `pnpm-workspace.yaml` | Same overrides for pnpm |
| `.nvmrc` | `22.12.0` |
| `iwsdk.config.json` | `version: iwsdk.project.v1`; `scene`, `assets.module`, `components.module`; `world.xr` (`mode`, `offer: always`, `features`), `world.input.canvasPointerEvents`, `world.render` (near/far/camera), `world.features` (`locomotion`, `grabbing`, `physics`, `sceneUnderstanding`, `environmentRaycast`, `spatialUI.kit: horizon`); `dev.emulator.device: metaQuest3` (AR adds `environment: living_room`) |
| `vite.config.ts` | `plugins: [iwsdkDev()]`, `server: { host: '0.0.0.0', port: 8081, open: false }`, `base: './'`, `resolve.dedupe` for three/uikit, `optimizeDeps.exclude: ['@babylonjs/havok']` |
| `index.html` | `#scene-container`, placeholder favicon (`data:,`), no web manifest |
| `src/index.ts` | `World.create(container, projectOptions)` from `virtual:iwsdk-project`, then `registerSystem(...)` |
| `src/assets.ts`, `src/components.ts` | `defineAssets({...})`, `defineComponents([...])` shared with the editor |
| `src/robot*.ts`, `src/panel.ts` | Starter component/system and UI wiring (replace them) |
| `public/scenes/main.iwsdk.scene.json` | Starter scene (`iwsdk.scene.v1`) |
| `public/ui/welcome.uikitml`, `public/audio/chime.mp3`, `public/gltf/…`, `public/textures/…` | Starter content |
| `.gitignore` | Ignores `node_modules/`, `dist/`, `.env*`, `.iwsdk/`, and the generated MCP configs (`.mcp.json`, `.cursor/mcp.json`, `.vscode/mcp.json`, `.codex/config.toml`) |

## Agent guidance

| Path | Purpose |
|---|---|
| `AGENTS.md` | Canonical project rules (from `packages/cli/guidance/AGENTS.md`): what is not standard Vite, silent-failure traps, verification rules, skill routing, layout, conventions |
| `CLAUDE.md` | `# IWSDK project guidance` + `@AGENTS.md` |
| `src/AGENTS.md`, `public/scenes/AGENTS.md`, `public/ui/AGENTS.md` | Scoped copies of the rules for `AGENTS.md` harnesses |
| `.claude/skills/` | `iwsdk-dev`, `iwsdk-build-model`, `iwsdk-compose-scene`, `iwsdk-ui`, `iwsdk-grab`, `iwsdk-ray`, `iwsdk-debug`, `iwsdk-physics`, `iwsdk-depth-occlusion`, `iwsdk-native-xr-test`, `iwsdk-hosting`, `iwsdk-pwa-packaging` |
| `.agents/skills/` | Byte-identical copy for Codex and other harnesses |
| `.claude/rules/` | `ecs-api.md` (`src/**/*.ts`), `assets-and-manifest.md` (`src/assets.ts`, `src/scene-assets/**`), `scene-json.md` (`public/scenes/**`), `uikitml.md` (`public/ui/**`), each with a `paths:` frontmatter |
| `.claude/agents/iwsdk-project-code-reviewer.md` | Review subagent (`model: sonnet`) |
| `.claude/settings.json` | Allows `mcp__iwsdk-runtime__*`, `mcp__iwsdk-reference__*`, `mcp__metavr__*` and `Skill(iwsdk-…)`; `enabledMcpjsonServers: [iwsdk-runtime, iwsdk-reference, metavr]` |
| `.cursor/rules/*.mdc`, `.github/instructions/*.instructions.md` | The four rules for Cursor and Copilot |
| `.codex/config.toml` | Placeholder until `adapter sync --tools codex` |

## Written after install

| Path | By |
|---|---|
| `.mcp.json` (Claude), `.cursor/mcp.json`, `.vscode/mcp.json`, `.codex/config.toml`, `opencode.json` | `npx @iwsdk/cli adapter sync` (create runs it for all tools when it installs dependencies) |
| `.iwsdk/https/` | The dev plugin's cached self-signed certificate |
| `.iwsdk/runtime/session.json` | The running dev session (port, URLs, browser state) |
| `.iwsdk/reference/` | `reference warmup` state (the model and corpus also go to a shared cache) |
| `~/.metavr/`, a completions block in your shell profile | `@meta-quest/metavr` postinstall (see SKILL.md §9) |
