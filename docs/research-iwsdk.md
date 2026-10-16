# Research notes: Meta Immersive Web SDK (IWSDK)

Collected 2026-10-16 for the `iwsdk-official` and `custom/iwsdk-*` skills. Everything here was
read from source at a pinned commit, from the npm registry, or from the live docs; anything not
confirmed is in [Unverified](#9-unverified-items).

**Pinned sources**

| Source | Version / commit | License |
|---|---|---|
| https://github.com/facebook/immersive-web-sdk | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, "prepare 1.0.1 packages"), 341 stars | MIT |
| npm `@iwsdk/*` | 1.0.1, published 2026-10-16 | MIT |
| https://iwsdk.dev (`llms.txt`, `skill.md`, `go.md`, `skills/iwsdk-migrate-0-5/SKILL.md`) | identical to `docs/public/` at the commit above (diffed) | MIT |
| https://github.com/meta-quest/immersive-web-emulation-runtime (IWER) | `449d6817` (2026-10-13); npm `iwer` 2.6.0 | MIT |
| https://github.com/meta-quest/iwsdk-v0-template | `5185128c` (2026-10-05) | Apache-2.0 |
| https://github.com/felixtrz/iwsdk-rag-mcp | pushed 2026-03-21; npm `@felixtz/iwsdk-rag-mcp` 0.3.2 | MIT |
| super-three (Three.js fork used by IWSDK) | 0.181.0, repo `supermedium/three.js` | MIT |
| Meta's `hz-iwsdk-webxr` skill | `meta-quest/agentic-tools@3a8553d` (2026-09-23) | Apache-2.0 |

## 1. What IWSDK is

A TypeScript framework for WebXR (VR, mixed reality) and desktop-browser 3D apps, built on
Three.js with an entity-component-system. "Same code, two experiences": immersive in a headset,
mouse-and-keyboard emulation on desktop (README).

**Versions.** 0.3.0 (2026-03-11) to 0.4.2 (2026-05-29) used GLXF levels from the Meta Spatial
Editor, a UIKitML compiler plugin, a glTF optimiser plugin and `vite-plugin-mkcert` (release
commit dates in git log). **0.5.x** (0.5.1 on 2026-08-03) replaced all of that with
native scene JSON (`iwsdk.scene.v1`), a managed in-browser editor, runtime-parsed UIKitML and a
committed `iwsdk.config.json` project manifest. **1.0.0** (2026-09-25) is the first stable
release: all packages share one version, breaking changes need a major bump; it added gaze +
pinch input and a Meta VR Glasses emulator profile, native Quest control sessions over
`adb reverse`, live UIKitML inspection, Havok physics in a Web Worker by default (60 Hz), and a
hardened CLI-managed runtime (strict port). **1.0.1** (2026-10-01 / npm 2026-10-16) ships
`@meta-quest/metavr ^1.8.1` in new projects and reports CLI tool calls through MetaVR
telemetry (`packages/core/CHANGELOG.md`, git log).

**Packages** (`packages/`): `@iwsdk/core` (runtime, ECS, systems, WebXR), `@iwsdk/create`
(scaffolder, bin `create-iwsdk`), `@iwsdk/cli` (bin `iwsdk`: dev server, runtime commands, MCP
stdio server, adapters, reference), `@iwsdk/vite-plugin-dev` (`iwsdkDev()`: IWER injection,
managed Playwright browser and editor, HTTPS cert, MCP WebSocket bridge, production feature
gating), `@iwsdk/reference` (local semantic search CLI/MCP), `@iwsdk/reference-assets`
(producer-only corpus), `@iwsdk/scene-composition` (scene schema, validation, flattening),
`@iwsdk/xr-input`, `@iwsdk/locomotor`, `@iwsdk/example-assets` (immutable stock models, 0.4.2 on
jsDelivr).

**Engine pieces** (`packages/core/package.json`, `src/`): ECS from `elics` 3.4 with reactive
`@preact/signals-core`; Three.js = `three: npm:super-three@0.181.0`, which apps must alias and
override so there is one Three instance (all Three classes are re-exported from `@iwsdk/core`);
`three-mesh-bvh` for pointer raycasts and locomotion; `@pmndrs/handle` (grab handles) and
`@pmndrs/pointer-events` (ray/grab/touch pointers, also used by `@iwsdk/xr-input`) underneath the
interaction systems; spatial UI = `@pmndrs/uikit` with the
Horizon kit and Lucide icons, authored as UIKitML (`@drawcall/uikitml`), centimetre units, MSDF
text, `ScreenSpace` HUDs and `Follower`; input = `world.input.xr` (stateful gamepads, hands,
multi-pointers), `world.input.keyboard`, `world.input.actions` (`locomotion.move`, `turn`,
`jump`, `teleportAim/Commit`, `interaction.select`), `RayInteractable` + `Hovered`/`Pressed`
tags for both canvas pointers and XR rays, gaze; grabbing = `OneHandGrabbable`,
`TwoHandsGrabbable` (squeeze), `DistanceGrabbable` (trigger; modes `MoveTowardsTarget`,
`MoveFromTarget`, `MoveAtSource`, `RotateAtSource`), mutually exclusive per entity; locomotion =
slide, teleport, snap/smooth turn, jump, comfort vignette, BVH capsule in a worker,
`LocomotionEnvironment` on walkable meshes; physics = Havok (`@babylonjs/havok`),
`PhysicsBody`/`PhysicsShape`/`PhysicsManipulation`; audio = `AudioSource` with pooling and
spatialisation; mixed reality = scene understanding (planes, meshes, anchors), environment
raycast (hit test), `DepthSensingSystem` + `DepthOccludable`, `CameraSource` (passthrough camera
access); WebXR layers = `XRQuadLayer`, `XRCylinderLayer`; environment = `DomeGradient`/
`DomeTexture`, `IBLGradient`/`IBLTexture`, light components; browser-first mode (`xr: false`)
and React/Preact 2D UI (guide 17). No platform services: identity, leaderboards, IAP and saves
are app-owned backends (guide 18).

**Rendering defaults** (`src/init/world-initializer.ts`, `src/init/xr.ts`, super-three
`WebXRManager.js`): `WebGLRenderer({ antialias: true, multiviewStereo: true })`; every session
offers `local-floor`, `bounded-floor`, `layers`; on Quest Browser super-three uses an
`XRProjectionLayer` with `OCULUS_multiview` and 4x MSAA; foveation defaults to 1.0 (max) and
framebuffer scale to 1.0 (settable only before a session). IWSDK sets no target frame rate.

**Assets** (`src/asset/`): glTF via `GLTFLoader` + `DRACOLoader` + `KTX2Loader` (decoders from
unpkg.com, not configurable through `World.create` in 1.0.1), **no Meshopt decoder**; textures
via `TextureLoader` (no standalone KTX2); HDR/EXR via `HDRLoader`/`EXRLoader`; priorities
`critical` (default when omitted), `background`, `lazy`; 30 s timeout per load; staged scene
models capped at 64 MiB each / 256 MiB total. Controller models come from
`cdn.jsdelivr.net/npm/@webxr-input-profiles/assets@1.0`.

## 2. Project template (`npm create @iwsdk@latest`)

Flags (1.0.1 `src/cli.ts`): `[name]` (`.` = in place), `--yes`, `--force` (needed for any
non-empty target), `--target vr|ar|browser` (alias `--mode vr|ar`, `--xr`/`--no-xr`),
`--language ts|js`, `--[no-]install`, `--[no-]git`, `--[no-]locomotion` (vr, browser),
`--[no-]grabbing`, `--[no-]physics`, `--[no-]scene-understanding` (ar),
`--[no-]environment-raycast` (ar), `--skip-reference-warmup`, `--canary [url]`. There is **no
`--ai-tools` flag** (iwsdk.dev/skill.md documents one; the code and the create README don't):
every project gets guidance for Claude Code, Codex, Cursor, Copilot and OpenCode.

Scaffold verified on 2026-10-16 (`npx -y @iwsdk/create@1.0.1 vrapp --yes --target vr
--no-install --no-git`, output byte-identical to the repo's `packages/create/guidance` and
`packages/cli/guidance/AGENTS.md`): `iwsdk.config.json`, `vite.config.ts` (`iwsdkDev()`, port
8081, host 0.0.0.0, `base: './'`), `src/index.ts` (`World.create(container, projectOptions)` from
`virtual:iwsdk-project`), `src/assets.ts`, `src/components.ts`, starter systems, a scene and a
UIKitML panel, **`AGENTS.md`**, **`CLAUDE.md`** (`@AGENTS.md` shim), `.claude/skills/` (12),
`.agents/skills/` (copy), `.claude/rules/` (4 path-scoped rules), `.claude/agents/
iwsdk-project-code-reviewer.md`, `.claude/settings.json`, scoped `AGENTS.md` files, Cursor and
Copilot rule files, a Codex placeholder. Starter models load from the jsDelivr example-assets
CDN. Full table: `skills/custom/iwsdk-project-setup/references/generated-files.md`.

**Side effect found in review:** `npm install` runs `@meta-quest/metavr@1.8.1`'s postinstall,
which downloads its native binary from `securecdn.oculus.com` to `~/.metavr` and appends a
completions block to `~/.zshrc`, `~/.bash_profile`/`~/.bashrc` or the PowerShell profile
(read in `postinstall.js`, `download.js`). `METAVR_SKIP_DOWNLOAD=1` skips it at install time.
The create CLI prints a notice that metavr "collects essential usage data" and how to uninstall.

**Other templates.** `meta-quest/iwsdk-v0-template` (Apache-2.0, 1 star) is the same app
pre-configured for Vercel's v0 with IWSDK 1.0.1 packages but **older skill names**
(`.agents/skills/iwsdk-planner`, `iwsdk-scene-composer`) and a `predev` script
`scripts/setup-browser-deps.mjs` (not reviewed; nothing copied). The repo's `examples/` folder
(audio, browser-first, depth-occlusion, environment-raycast, gaze-pinch, grab, layers,
locomotion, physics, poke, scene-understanding) is the best API reference by example.

## 3. AI tooling: CLI, MCP and agent mode

**How it fits together** (`docs/ai/index.md`, `packages/cli/src`). `npx @iwsdk/cli dev up` (or
`npm run dev` = `iwsdk dev restart --open --foreground`) starts Vite, launches one managed
Playwright Chromium window that hosts the runtime and the editor, and records the session in
`.iwsdk/runtime/`. `iwsdk mcp stdio` resolves that session and relays tool calls over a
WebSocket (`/__iwer_mcp`) to the page, where IWER executes them. The user's own browser or
headset keeps an independent XR session. Every MCP tool has a CLI twin (`xr_get_session_status`
= `iwsdk xr status`), and CLI output is JSON (`{"ok":true,"data":…}` / `{"ok":false,"error":…}`,
exit 0/1).

**Modes.** `--ai-mode collaborate` (headed, resizable, DevUI on, the default experience) and
`--ai-mode agent` (headless, fixed 800x800 viewport, DevUI off); plus `--headed/--headless`,
`--open/--no-open`, `--screenshot-width/height`, `--native-xr-control`,
`--allow-browser-automation`, `--timeout`. The docs insist the developer owns headed vs
headless; agents must announce a change.

**Tool surface** (`docs/ai/mcp-tools.md`): 6 browser tools (`browser_screenshot`, `_snapshot`,
`_interact`, `_profile` (uncalibrated host-browser diagnostics), `_get_console_logs`,
`_reload_page`); 16 `xr_*` session/pose/input tools; 11 `ecs_*` (pause, resume, step, query,
find, list systems/components, toggle, set, snapshot, diff); 10 `scene_*` editor tools
(file-first: agents edit scene JSON with normal file tools; `scene_render_file` validates and
renders; `scene_flatten_file` resolves imports); `asset_render_preview`; `ui_list_assets`,
`ui_render_preview`, `ui_inspect`. Opt-in escape hatch: `iwsdk browser run <script.mjs>` with
loopback CDP (grants browser-level control to local processes while on).

**Reference server.** `@iwsdk/reference` (dev dependency) is a local semantic index of IWSDK,
Three.js and WebXR types: `iwsdk reference warmup` downloads a pinned embedding model and the
corpus; tools `search`, `api`, `relationship`, `file`, `components`, `systems`, `dependents`,
`examples`. It replaces `felixtrz/iwsdk-rag-mcp` (same eight tools; legacy server name
`iwsdk-rag-local`).

**Configuring Claude Code** (text only; `iwsdk adapter sync --tools claude` writes it, with
absolute paths, and the scaffold git-ignores it):

```json
// .mcp.json
{
  "mcpServers": {
    "iwsdk-runtime":   { "command": "node", "args": ["<app>/node_modules/@iwsdk/cli/dist/cli.js", "mcp", "stdio"] },
    "iwsdk-reference": { "command": "node", "args": ["<app>/node_modules/@iwsdk/reference/<entrypoint>"] },
    "metavr":          { "command": "node", "args": ["<app>/node_modules/@meta-quest/metavr/bin.js", "mcp", "server"] }
  }
}
// .claude/settings.json (merged)
{
  "permissions": { "allow": ["mcp__iwsdk-runtime__*", "mcp__iwsdk-reference__*", "mcp__metavr__*"] },
  "enabledMcpjsonServers": ["iwsdk-runtime", "iwsdk-reference", "metavr"]
}
```

`adapter sync` also deletes an old `enableAllProjectMcpServers: true` (older starters set it),
keeps unrelated user entries, and treats `iwsdk`, `iwsdk-dev-mcp`, `iwsdk-rag-local`, `hzdb` as
legacy managed names. Other targets: `.cursor/mcp.json` (+ `permissions.json`),
`.vscode/mcp.json` (approval stays manual), `.codex/config.toml` (`default_tools_approval_mode
= "approve"`), `opencode.json`; `adapter status|prune|prompt`. The docs advise cloud harnesses
to prefer the CLI because MCP wiring is often missing.

**Telemetry.** With `@meta-quest/metavr` installed in the project, the CLI and the Vite plugin
spawn `metavr xxiwsdk tool-call …` for each runtime operation: tool name, duration, a fixed
failure-reason code (error messages are deliberately not sent), session id, client version
(`runtime-telemetry.ts`, `metavr-telemetry.ts`). Without metavr it is skipped silently.
`metavr telemetry disable` limits metavr to essential data.

**IWER** (Immersive Web Emulation Runtime, `iwer` 2.6.0): emulates the WebXR Device API in any
browser. IWSDK injects it in dev (`dev.emulator`: `device` default `metaQuest3`, also
`metaQuest2`, `metaQuestPro`, `metaVRGlasses`, `oculusQuest1`; `activation` `localhost`;
`userAgentException` `/OculusBrowser/`; synthetic rooms for AR via `@iwer/sem`; `iwer: false` to
disable; `injectOnBuild` default false). Separately, the **Immersive Web Emulator** Chrome
extension plus `@iwer/extension-bridge` 2.6.0 is an MCP daemon for *any* WebXR page without a dev
server (`claude mcp add --scope user iwer -- npx -y @iwer/extension-bridge serve`; 127.0.0.1
only, per-tab Allow prompt, 20 tools). Not needed for IWSDK apps; noted for non-IWSDK WebXR.

## 4. Official skills inventory and decisions

| Location | Skills | For | Decision |
|---|---|---|---|
| `packages/create/guidance/claude/.claude/skills/` (shipped into every project) | `iwsdk-dev` (+ planner, iterate, api-reference), `iwsdk-build-model`, `iwsdk-compose-scene`, `iwsdk-ui`, `iwsdk-grab`, `iwsdk-ray`, `iwsdk-debug`, `iwsdk-physics`, `iwsdk-depth-occlusion`, `iwsdk-native-xr-test`, `iwsdk-hosting`, `iwsdk-pwa-packaging` | App developers | **All 12 copied** to `skills/iwsdk-official/` |
| `docs/public/skills/iwsdk-migrate-0-5/` (iwsdk.dev) | `iwsdk-migrate-0-5` | App developers on 0.4.x | **Copied** |
| `docs/public/skill.md` (iwsdk.dev/skill.md) | `iwsdk-dev` (cloud-harness variant) | Agents in headless/cloud harnesses | Not copied: name clash with the scaffold's `iwsdk-dev`; partly stale (0.4.x headings, nonexistent `--ai-tools`). Useful bits folded into `iwsdk-project-setup` |
| Repo-root `.claude/skills/` | `test-all`, `test-audio`, `test-ecs-core`, `test-environment`, `test-grab`, `test-interactions`, `test-level`, `test-locomotion`, `test-physics`, `test-ui` | SDK maintainers (test the repo's examples with the monorepo harness) | Rejected |
| Repo-root `.claude/skills/` | `click-target`, `xr-mode-test` | Maintainers; retired `mcp__iwsdk-dev-mcp__*` tool names, legacy `PanelUI` | Rejected |
| Repo-root `.claude/skills/` | `iwsdk-ui-panel`, `iwsdk-dev` | Maintainer variant / identical copy | Rejected |
| `packages/create/guidance/claude/.claude/agents/` | `iwsdk-project-code-reviewer` | App developers | **Copied** to `skills/iwsdk-official/agents/` |
| Repo-root `.claude/agents/` | `iwsdk-code-reviewer` | Reviews SDK `packages/*` (pnpm lint/format) | Rejected |
| Repo-root `.claude/hooks/iwsdk-stop-check.sh` + `.claude/settings.json` | Stop hook nudging runtime verification, `pnpm format/lint/build`, and MCP feedback to `.claude/mcp-feedback.jsonl`; settings allow `Bash(node *)`, `Bash(npx *)`, `Bash(kill *)` and `enableAllProjectMcpServers` | Maintainers | Not copied (broad permissions, monorepo commands, needs `jq`). An app team could write a similar Stop hook that reminds the agent to run `npm run typecheck`, `iwsdk browser screenshot` and `iwsdk browser logs` after code edits |
| `packages/create/guidance/claude/.claude/rules/*.md` | `ecs-api`, `assets-and-manifest`, `scene-json`, `uikitml` (path-scoped) | App developers | Not skills; every scaffold has them, and `iwsdk-dev`'s playbooks read them |

Security review: every copied file read in full (including the 599-line
`hardsurface.ts.template`, pure geometry); no injection or hidden instructions; outward actions
(deploys, uploads, keystore, global bubblewrap install, `ovr-platform-util` download from Meta's
public link) are gated behind asking the user. Upstream inconsistencies are in
`skills/iwsdk-official/ERRATA.md` (stale skill names `iwsdk-planner`/`iwsdk-scene-composer`,
`AssetType` list missing `UIKitML`, grab components combined against the 1.0 exclusivity rule,
`three` imports in physics examples, Windows-only contact sheet, heredoc-over-Edit advice).

## 5. Overlap with Meta's `hz-iwsdk-webxr`

Meta's skill (agentic-tools `3a8553d`) is a good overview (ECS, World, input, spatial UI,
performance, desktop load profiling with Playwright/Lighthouse and hardware ANGLE flags), but
much of it predates IWSDK 0.5: it recommends `vite-plugin-mkcert`, `@iwsdk/vite-plugin-uikitml`
`compileUIKit` and `PanelUI { config: './ui/x.json' }`, the old `createSystem({ name, queries,
execute })` shape, `world.time.frame`, `entity.getObject3D()`, `entity.destroy()`,
`import * as THREE from 'three'`, and two APIs that don't exist
(`session.fixedFoveatedRendering.level`, `navigator.xr.enableSpaceWarp`). Its numbers ("72 Hz
default", "50-80 / 100-120 draw calls", "texture memory under 256 MB", "pinch 0.7-0.8") have no
Meta source I could find. Details: `skills/custom/iwsdk-performance/references/older-advice.md`.
Its `desktop-load-profiling.md` remains useful and is referenced from `iwsdk-performance`.

## 6. Gaps found and custom skills written

| Gap | Covered by |
|---|---|
| No start-here map across planning, IWSDK build skills, device testing, Meta store skills | `iwsdk-dev-workflow` |
| Official skills assume a ready project; nothing on Node range, flag choice, generated files, Claude Code MCP wiring, team clones, cloud/headless Playwright, metavr side effects | `iwsdk-project-setup` |
| `iwsdk-native-xr-test` automates a real session but nobody explains manual on-device testing (Wi-Fi vs `adb reverse`, cert, chrome://inspect, logs, frame-rate probe, OVR Metrics) | `iwsdk-quest-device-testing` |
| No IWSDK-specific performance workflow; Meta's tips are stale | `iwsdk-performance` (+ `references/older-advice.md`) |
| Optimiser plugin removed in 0.5; no guidance on IWSDK-loadable compression (Meshopt trap) | `iwsdk-asset-pipeline` (+ `scripts/check-gltf.mjs`, tested) |
| No app-level automated testing or CI guidance | `iwsdk-testing` (+ `scripts/iwsdk-smoke.sh`, stub-tested; `references/ci-github-actions.md`) |

Store, PWA packaging, VRCs and Quest Browser feature support are covered by the other groups'
skills (`horizon-*`, `quest-browser-webxr`, Meta's `hz-store-pwa`); the router points to them.

## 7. Performance facts used (all sourced)

- Frame budget arithmetic (72 Hz 13.9 ms, 90 Hz 11.1 ms, 120 Hz 8.3 ms).
- VRC Performance.1 (2025-10-22): ≥ 60 fps rendered; refresh 72/80/90/96/100/120 Hz.
  VRC Performance.4 (2024-07-31): ≥ 85% render scaling for most of the experience.
- Device comparison (2026-05-11): Quest 2 < 100 draw calls, < 750K triangles, 72 Hz; Quest 3
  < 200, < 1.5M, 72 Hz (90 recommended).
- WebXR workflow: CPU/GPU test, vertex/fragment test via framebuffer scale, app logic > 2 ms,
  1,000 draw calls likely < 72 FPS, framebuffer 0.8-0.9 as last resort, layers for static
  content. Best practices: lower update rates, overdraw order, PBR/lights/shadows costs, KTX2.
  FFR page: session tokens and `fixedFoveation` 0-1; FFR lost with intermediate targets.
  Frame-rate page: `frameRate`, `supportedFrameRates`, `updateTargetFrameRate`, Browser 16.4+.
  Space Warp page: experimental, Browser 24.2+, `chrome://flags`, `space-warp` + motion vectors.

## 8. Commands and facts verified against source

`npm create @iwsdk@latest <dir> -- --yes --target …`; `npx @iwsdk/cli dev up|restart|down|status|
logs|open`; `runtime status|targets|wait|recover|pair-headset`; `adapter sync|status|prune|
prompt`; `reference status|warmup|…`; `mcp stdio|inspect`; `xr|browser|asset|scene|ui|ecs
<action>`; `--input-json`, `--raw`, `--output-file`, `--timeout`; `dev status` →
`data.runtimeUrls`, `data.state.browserCommandReady`; `xr status` → `sessionActive`,
`sessionMode`, `enabledFeatures`, `visibilityState` (IWER `remote/types.ts`); `ecs find` →
`entities[].{entityIndex,name,componentIds}`; `ecs diff` → `summary`. gltf-transform 4.5.1:
`optimize` defaults `--compress meshopt`, `--texture-compress auto`, `--texture-size 2048`,
join/flatten/instance/palette/simplify on, `join-named` on; KTX2 needs KTX-Software 4.4.0+;
`optimize --texture-compress ktx2` uses UASTC for normal/occlusion/metal-rough, ETC1S otherwise.

## 9. Unverified items

- `iwsdk-smoke.sh` was exercised against a stub CLI only, not a live 1.0.1 runtime (running one
  needs `npm install`, which downloads Playwright Chromium into a user cache and runs metavr's
  postinstall; skipped to avoid machine-wide changes).
- Whether Quest Browser mirrors page `console.*` into logcat; whether `metavr perf capture`
  attributes WebXR frames in Quest Browser usefully.
- Multiview compatibility of hand-written `ShaderMaterial`s in super-three.
- The `com.oculus.vrshell` launch broadcast in `iwsdk-native-xr-test` (an undocumented Horizon
  OS intent).
- The CI workflow sketch (`references/ci-github-actions.md`): Playwright hoisting and container
  flags not tested.
- `@iwsdk/reference warmup` download size and cache location (only "project-local
  `.iwsdk/reference` state and shared cache" documented).
- Quest 3/3S default WebXR refresh rate (no Meta statement; read `session.frameRate`).
- iwsdk-v0-template's `predev` browser-deps script (not read).

## 10. Sources

- https://github.com/facebook/immersive-web-sdk (README, `packages/*`, `docs/`, `.claude/`, `.github/workflows/`, `scripts/test-servers.mjs`)
- https://iwsdk.dev, https://iwsdk.dev/llms.txt, https://iwsdk.dev/skill.md, https://iwsdk.dev/go.md, https://iwsdk.dev/skills/iwsdk-migrate-0-5/SKILL.md
- https://iwsdk.dev/ai/, /ai/getting-started.html, /ai/modes.html, /ai/mcp-tools.html, /ai/workflows.html
- https://iwsdk.dev/guides/01-project-setup.html, 02-testing-experience.html, 04-external-assets.html, 08-build-deploy.html, 18-platform-services.html
- https://www.npmjs.com/package/@iwsdk/create, /@iwsdk/core, /@iwsdk/cli, /@iwsdk/vite-plugin-dev, /iwer, /@iwer/extension-bridge, /@meta-quest/metavr, /@meta-quest/bubblewrap-cli, /@gltf-transform/cli
- https://github.com/meta-quest/immersive-web-emulation-runtime (README, `packages/extension-bridge/README.md`, `packages/iwer/src/remote/types.ts`)
- https://github.com/meta-quest/iwsdk-v0-template
- https://github.com/felixtrz/iwsdk-rag-mcp
- https://unpkg.com/super-three@0.181.0/src/renderers/webxr/WebXRManager.js, /examples/jsm/loaders/GLTFLoader.js
- https://unpkg.com/@meta-quest/metavr@1.8.1/postinstall.js, /download.js
- https://github.com/donmccurdy/glTF-Transform/tree/v4.5.1/packages
- https://developers.meta.com/horizon/documentation/web/webxr-perf-workflow/, /webxr-perf-bp/, /webxr-ffr/, /webxr-frames/, /webxr-space-warp/, /browser-remote-debugging/
- https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/
- https://developers.meta.com/horizon/resources/device-optimization-comparison/, /vrc-quest-performance-1/, /vrc-quest-performance-4/
- https://developers.meta.com/horizon/documentation/unity/unity-perf/
- https://github.com/meta-quest/agentic-tools (`skills/hz-iwsdk-webxr`)
