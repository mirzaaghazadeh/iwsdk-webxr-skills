# Errata for the official IWSDK skills

The skills in this folder are copied unchanged from
[facebook/immersive-web-sdk](https://github.com/facebook/immersive-web-sdk) at commit
`0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (IWSDK 1.0.1). These are the places where they, or
the scaffold files they rely on, disagree with the SDK source or docs at that commit. Checked
2026-10-16; traps from an IWSDK 1.0.1 game prototype and the Meta-hosted docs section added
2026-10-17. When a skill and this
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

## Meta's hosted IWSDK docs vs 1.0.1 (checked 2026-10-17)

The pages under `developers.meta.com/vr/documentation/iwsdk/` (entry:
https://developers.meta.com/vr/documentation/iwsdk/guides/overview/; the bare folder URL
returns 404; dated 2026-09-04 to 2026-09-23) say they were verified against `8218285d` (**IWSDK 0.5.3**), but they already
describe Meta VR Glasses. Where they disagree with the 1.0.1 package (npm tarballs read, not
run) or with iwsdk.dev (identical to 1.0.1's `docs/public`):

| Hosted page | Says | 1.0.1 actually |
|---|---|---|
| `guides/get-started-glasses/`, `guides/02-testing-experience/` | Set `world.features.fieldOfViewMask: true` for a Meta VR Glasses view mask, including on a real Quest | No such key in `@iwsdk/core` 1.0.1 or 1.1.0-rc.1 (`dist/project/types.d.ts`, schema, `validation.js`). Unknown keys are `unknown-key` issues and `assertValidIwsdkProjectManifest` throws, so the Vite plugin refuses the manifest. Desktop: `dev.emulator.device: "metaVRGlasses"`; headset: `metavr device fov-sim enable` |
| `guides/06-built-in-interactions/` | Gaze tuning key `suppressWhenHandPointerActive` | `suppressWhenDirectPointerActive`; the hosted name fails validation the same way. The hosted table also omits `showDebugReticle` and `trackingLossGraceSeconds` |
| `guides/06-built-in-interactions/`, `guides/get-started-glasses/` | Without a usable gaze pose IWSDK falls back to head pointing; amber reticle = head fallback | `docs/concepts/xr-input/gaze.md`: "IWSDK does not silently replace missing production gaze with head pose"; hand/controller far rays resume; head-directed gaze only through `dev.targetDevicePreview.gazeSimulation: "head"` or the emulator's Head mode; `showDebugReticle` defaults to `false` |
| `ai/index/`, `ai/mcp-tools/` (and https://developers.meta.com/vr/discover/ai-tools/) | `iwsdk-runtime` exposes 45 public tools (browser 3, UI 2); the IWSDK product page says 32 | `@iwsdk/cli` 1.0.1 `tools/list` returns 55: adds `browser_snapshot`, `browser_interact`, `browser_profile`, `ui_inspect`, `asset_render_preview` and five `runtime_*` control tools |
| `ai/*`, `guides/02-testing-experience/`, `guides/01a-project-manifest/` | `npx iwsdk …`; dev URLs on port 5173 | Use the scoped `npx @iwsdk/cli …` (see `../custom/iwsdk-project-setup`); the scaffold's strict port is 8081 |
| `ai/index/` | Generated skill `iwsdk-scene-composer` | `iwsdk-compose-scene` |

No official skill in this folder mentions gaze, the `gaze` emulator device or Meta VR Glasses
yet (1.0.1 copies). Use `../custom/iwsdk-vr-glasses`.

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
- **A distance grab moves with the hand, not to where the ray points.** With
  `DistanceGrabbable` and `MovementMode.MoveAtSource`, the held object follows the hand's own
  movement, so a player who keeps the hand still and points somewhere else sees the object
  barely move. A playtester on a Quest 3S reported exactly this when placing game pieces on a
  table (2026-10-23). For putting things down on a surface, keep `DistanceGrabbable` for the
  pinch but set `translate: false, rotate: false`, then steer the held object yourself each frame
  where `world.player.raySpaces[hand]` meets the surface. `GrabSystem.getHolderHand(entity)`
  (`packages/core/src/grab/grab-system.ts`) still names the holding hand with both switched off
  (observed in the emulator, 1.0.1). To turn the held object by twisting the wrist, measure the
  hand's roll about its ray against the vertical plane through the ray. The "twist" half of a
  swing–twist split also picks up sideways aiming, and the object spins while the player aims.
- **A button that removes itself on press breaks the next press.** `InputSystem`
  (`packages/core/src/input/input-system.ts`) adds `Pressed` on `pointerdown` and removes it on
  `pointerup`. The usual pattern, acting in a `Pressed` qualify subscription, runs on the *down*.
  If that action disposes the pressed entity (closing a menu, swapping one card of buttons for
  another), the next button still lights up under the ray (`Hovered` appears) but the next pinch
  adds no `Pressed` and does nothing. Observed in the emulator with 1.0.1 and emulated hands on
  every menu → level → menu round trip (2026-10-23). The cause wasn't traced; the pointer probably
  keeps its capture on the removed object. Acting on release fixed it (4 of 4 runs, after
  alternating failures). Use a `Pressed` *disqualify* subscription, act only if the entity
  still has `Hovered` (so sliding off cancels), and run the action on the next frame, outside the
  pointer event. Players expect buttons to act on release anyway.
- **UIKit's bundled font lacks some glyphs**, for example superscript "²", which don't render.
  Keep panel text to plain ASCII (the `iwsdk-ui` skill only mentions punctuation).
- **`npm install` edits your shell profile.** `@meta-quest/metavr@1.8.1`'s postinstall downloads
  its binary into `~/.metavr` and appends a completions block to `~/.zshrc` (or `~/.bashrc`,
  `~/.bash_profile`, the PowerShell profile). `METAVR_SKIP_DOWNLOAD=1 npm install` avoids it at
  install time. None of the skills mention this.
