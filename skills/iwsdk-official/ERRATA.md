# Errata for the official IWSDK skills

The skills in this folder are copied unchanged from
[facebook/immersive-web-sdk](https://github.com/facebook/immersive-web-sdk) at commit
`0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (IWSDK 1.0.1). These are the places where they, or
the scaffold files they rely on, disagree with the SDK source or docs at that commit. Checked
2026-10-16; traps from an IWSDK 1.0.1 game prototype added 2026-10-17. When a skill and this
file disagree, trust this file and then the installed package
(`node_modules/@iwsdk/*/dist/**/*.d.ts`, `npx @iwsdk/cli <domain> --help`).

## Stale names

| Where | Says | Actually (1.0.1) |
|---|---|---|
| `iwsdk-pwa-packaging/SKILL.md`, last paragraph | "Building the app itself is `iwsdk-planner`" | The entry skill is **`iwsdk-dev`**. `iwsdk-planner` was its old name (still in `meta-quest/iwsdk-v0-template`) |
| Scaffold `.claude/rules/scene-json.md`, last line (not in this folder, but every project has it) | "use the `iwsdk-scene-composer` skill" | Now **`iwsdk-compose-scene`** |
| `iwsdk-pwa-packaging/SKILL.md`, Step 0 | "scaffolded with `--mode vr` or `--mode ar`" | Works: `--mode` is still accepted as an alias, but `--target vr\|ar\|browser` is the documented flag (`packages/create/src/cli.ts`) |

## Incomplete or redundant

| Where | Issue |
|---|---|
| `iwsdk-dev/references/api-reference.md` §14 "AssetType Enum" | Lists four types. `AssetType` also has **`UIKitML`** (`packages/core/src/asset/asset-manager.ts`); the scaffold rule `assets-and-manifest.md` lists all five |
| `iwsdk-dev/references/api-reference.md` "XR Session Optimization" | `renderer.xr.setFoveation(1)` is described as an optimisation, but 1.0 (maximum) is already the default in super-three 0.181.0 `WebXRManager.js` (`let foveation = 1.0`). Use it to *lower* foveation (e.g. `0.5`) when edges look too blurry. `updateTargetFrameRate(72)` only works for a rate listed in `session.supportedFrameRates` |
| `iwsdk-physics/references/workflows.md` "Making an Object Grabbable with Physics" | Adds `OneHandGrabbable` **and** `DistanceGrabbable` to one entity. Since 1.0 the grab components are documented as mutually exclusive: "`GrabSystem` creates only one handle and ignores additional grab components. Do not rely on which component wins" (`packages/core/src/grab/one-hand-grabbable.ts`). Pick one per entity |
| `iwsdk-physics/references/workflows.md` (two examples) | Import `Mesh`, `SphereGeometry`, etc. `from 'three'`. The project rule (`AGENTS.md`, `ecs-api` rule) is to import Three.js classes from `@iwsdk/core` to avoid a second Three.js instance |
| `iwsdk-ui/SKILL.md`, contact sheet | Gives only a Windows PowerShell command. On macOS use `sips`/ImageMagick if already installed; the skill says not to install a tool just for this |
| `iwsdk-build-model`, `iwsdk-compose-scene` | Tell Claude Code to write long files with Bash heredocs and to replace text with a script instead of `Edit`, to save context. If your own `CLAUDE.md` requires the Write/Edit tools, your instruction wins |

## Docs that disagree with the code

| Where | Says | Actually |
|---|---|---|
| https://iwsdk.dev/skill.md (not copied) | `@iwsdk/create` has `--ai-tools <tools>` | 1.0.1 has no such flag. Every project gets Claude, Codex, Cursor, Copilot and OpenCode files; `adapter sync` then writes all MCP configs (`packages/create/README.md`, `src/cli.ts`) |
| https://iwsdk.dev/skill.md | Section headings say "0.4.x" | The content mostly matches 1.0, but check commands against `--help` |
| `packages/create/README.md` "What You Get" | "GLTF Optimization – Automatic asset compression" | Removed in 0.5 (`@iwsdk/vite-plugin-gltf-optimizer` retired, see `iwsdk-migrate-0-5`). Guide 08: "Vite copies files from `public/` without rewriting them. Optimize large models and textures … before adding them." Use `../custom/iwsdk-asset-pipeline` |
| https://iwsdk.dev/ai/getting-started.html | "Create runs this command automatically for tools selected during an installed scaffold" | There is no selection step; it runs `adapter sync` for every tool when dependencies are installed |
| https://iwsdk.dev/ai/modes.html | With `--no-open`, "browser commands can launch it lazily" | The 1.0.1 `AGENTS.md` says a targetless managed-browser command then fails with `browser_not_launched`. Don't rely on lazy launch |

## Traps the skills don't mention

- **No Meshopt decoder.** IWSDK's glTF loader wires `DRACOLoader` and `KTX2Loader` only
  (`packages/core/src/asset/loaders/gltf-loader.ts`). `gltf-transform optimize` defaults to
  `--compress meshopt`, which produces files the manifest can't load. Use `--compress draco`
  (or `quantize`), or load code-placed art with your own `GLTFLoader` +
  `MeshoptDecoder`. Details in `../custom/iwsdk-asset-pipeline`.
- **Decoders come from a CDN.** The Draco decoder and Basis transcoder load from
  `https://unpkg.com/three@0.181.0/examples/jsm/libs/...` at runtime. `World.create()` calls
  `AssetManager.init(renderer, world)` with no options, so there's no project setting for local
  copies in 1.0.1. Offline or strict-CSP builds need network access to unpkg.com, unless they
  load through their own loader with local decoders (`../custom/iwsdk-asset-pipeline` §1a).
- **Telemetry.** `@iwsdk/cli` and `@iwsdk/vite-plugin-dev` report each runtime tool call (tool
  name, duration, a fixed failure-reason code, session id) through `metavr`'s `xxiwsdk` command when
  `@meta-quest/metavr` is installed in the project. Scaffolds include it. `npm uninstall
  @meta-quest/metavr` turns it off (the create CLI prints this notice).
- **Bubblewrap's Quest APK targets SDK 32.** `iwsdk-pwa-packaging` never mentions SDK levels. The
  `meta-quest/bubblewrap` template (main `7133ca6`, 2026-09-16; npm `@meta-quest/bubblewrap-cli`
  1.24.1) hard-codes `compileSdkVersion 32` / `targetSdkVersion 32` when `isMetaQuest` is set, in
  both app modes, and writes `android.hardware.vr.headtracking` with `required="false"`. Meta's
  manifest page (updated 2026-10-15) says "apps created since March 1, 2026, must set their
  targetSdkVersion to 34" (allowed ranges 32-34 immersive, 32-37 2D) and wants
  `required="true"` on headtracking for immersive apps. No Meta page exempts PWAs. Check the built
  APK with `aapt dump badging` and treat the ALPHA upload's test results as the authority; the
  library's `horizon-web-store-publish` flags both as RISK.
- **Built-in locomotion reads last frame's input.** `world-initializer.ts` registers
  `LocomotionSystem` at priority −5 and `InputSystem` at −4, so locomotion runs first, while
  the comment above `world.update` says "InputSystem => LocomotionSystem => GrabSystem". An
  IWSDK 1.0.1 prototype measured 1 frame of input-to-motion delay with `useWorker` on and off.
- **Locomotor rules that aren't in the docs** (`@iwsdk/locomotor` 1.0.1 `dist/core/engine.js`):
  gravity is multiplied by 3 while the player is above y = 10 m; above y = 100 m the player is
  reset to (0, 2, 0); velocity is capped at 20 m/s; the capsule radius is fixed at 0.5 m; jump
  only works when grounded and after a cooldown. Levels taller than 10 m fall three times faster.
  The public API (`slide`, `jump`, `teleport`) has no velocity read/write, so games that need
  momentum, wall contact or custom jumps need their own controller (`three-mesh-bvh` is already
  a dependency).
- **Physics has no queries.** `@iwsdk/core` 1.0.1's physics API (`PhysicsBody`, `PhysicsShape`,
  `PhysicsManipulation`, `PhysicsSystem`) exposes no raycast or shape cast, so it can't back a
  character controller or hit-scan weapons.
- **Controller models are forced visible every frame.** `@iwsdk/xr-input` 1.0.1
  `dist/xr-input-manager.js` line 461 sets `visualAdapter.visual.model.visible =
  inputSourceData.isPrimary` on each update, so hiding a controller model once (or with
  `toggleVisual`) doesn't stick. To show a held object instead, hide the model in a system that
  runs after `InputSystem` (priority > −4), every frame.
- **Controller models can be served locally**, but only with a patch: copy the
  `@webxr-input-profiles/assets` GLBs you need into `public/` and wrap `AssetManager.loadGLTF`
  before `World.create` to rewrite the jsDelivr prefix. 1.0.1 has no option for it.
- **IWER spoofs the user agent.** `iwer` 2.6.0 defines `navigator.userAgent` as an own property
  with a Quest Browser string, so user-agent checks treat emulator runs as a Quest. Tag
  performance logs from `Navigator.prototype`'s getter (`../custom/iwsdk-performance`).
- **Every edit ends the XR session.** A source or config change reloads the page (observed in
  the emulator with 1.0.1), and a reload ends any XR session, a headset's included. Re-enter XR
  after each edit (`xr enter` for agents) and warn whoever is wearing the headset.
- **UIKit's bundled font lacks some glyphs**, for example superscript "²", which don't render.
  Keep panel text to plain ASCII (the `iwsdk-ui` skill only mentions punctuation).
- **`npm install` edits your shell profile.** `@meta-quest/metavr@1.8.1`'s postinstall downloads
  its binary into `~/.metavr` and appends a completions block to `~/.zshrc` (or `~/.bashrc`,
  `~/.bash_profile`, the PowerShell profile). `METAVR_SKIP_DOWNLOAD=1 npm install` avoids it at
  install time. None of the skills mention this.
