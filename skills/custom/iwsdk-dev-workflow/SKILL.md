---
name: iwsdk-dev-workflow
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.0.0"
description: >-
  Start-here map for making a WebXR game or app with Meta's Immersive Web SDK
  (IWSDK) and Claude Code, testing it on Meta Quest, and shipping it on the
  Meta Horizon Store as a PWA. Gives the end-to-end order (plan, set up,
  build, test in the IWER emulator, test on the headset, optimise, host and
  package, VRC audit, store listing, upload, submit), names the skill that
  handles each step, and lists the hard rules (ask before deploys, uploads and
  installs; never publish the keystore; prove behaviour in the runtime and on
  the device). Use when starting or planning an IWSDK or WebXR project, when
  unsure which skill fits, when the user asks "where do I start", "what's
  next", "how do I ship my WebXR game", or at the start of any multi-step
  IWSDK task.
---

# IWSDK WebXR workflow: start here

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

This skill only routes. The detailed steps live in the skills it names. Load the named skill
before acting on a step.

- **Plugin installs prefix skill names** (`<bundle>:iwsdk-dev`). Match on the part after the
  colon.
- **If a named skill isn't installed**, say so and point to the library README. Don't improvise
  its content from memory.
- **Scaffolded projects already contain** IWSDK's 12 official skills in `.claude/skills/`. Don't
  install a second copy.

## 1. Before anything

1. For Quest, Quest Browser or Horizon Store facts, load **`hz-quest-verify-first`** and check
   Meta's live docs (`metavr docs search "<topic>"`), not memory.
2. Check the tools and the project, and ask before installing anything:
   ```bash
   node --version                      # >=20.19 <21, >=22.12 <23, or >=24
   npx @iwsdk/cli dev status           # inside an IWSDK app: runtime URLs, browserCommandReady
   adb devices                         # headset connected and authorised
   ```
   No project, wrong Node, MCP tools missing → **`iwsdk-project-setup`**. An IWSDK 0.4.x project
   (GLXF, Meta Spatial Editor, `vite-plugin-uikitml`) → **`iwsdk-migrate-0-5`** first.
3. For any change to app code, scenes, models or UI, invoke **`iwsdk-dev`** first. It picks the
   greenfield or bounded-change playbook and calls the specialists.

## 2. The path from idea to store

| # | Phase | Skills, in order | Done when |
|---|---|---|---|
| 0 | Plan | `game-gdd-author`, `prototype-fast`, `hz-immersive-designer`, `xr-ux-design-and-performance-budgeting`, `horizon-launch-roadmap` | Core loop proven; VR vs MR vs browser, immersive vs 2D, hosted web vs Store PWA decided |
| 1 | Set up | `iwsdk-project-setup` (`npm create @iwsdk@latest`), `quest-browser-webxr` (does Quest Browser support the features you need?) | `npm run dev` works; Claude Code sees `iwsdk-runtime`; `xr enter` works in the emulator |
| 2 | Build | `iwsdk-dev` → `iwsdk-build-model`, `iwsdk-compose-scene`, `iwsdk-ui`, `iwsdk-physics`, `iwsdk-depth-occlusion`; assets: `iwsdk-asset-pipeline`, `scenario-blender-expert`, `scenario-blender-retopology`, `scenario-blender-uv-baking` | Feature works in the managed runtime with ECS evidence |
| 3 | Test in the emulator | `iwsdk-grab`, `iwsdk-ray`, `iwsdk-debug`, `iwsdk-testing` (smoke test, CI) | Smoke test green; interactions proven with state |
| 4 | Test on the Quest | `iwsdk-quest-device-testing`, `iwsdk-native-xr-test`, `hz-vr-debug`, `metavr-cli`, `game-playtest` | Headset checklist passes; playtest notes logged |
| 5 | Optimise | `iwsdk-performance`, `quest-browser-webxr`, `hz-perfetto-debug`, `threejs-perf-loading`; review with the `iwsdk-project-code-reviewer` agent | ≥ 60 fps rendered at an allowed refresh rate in the heaviest scene |
| 6 | Host and package | `iwsdk-hosting`, then `horizon-web-store-publish` (release pipeline; `iwsdk-pwa-packaging` and `hz-store-pwa` are the upstream guides it builds on) | Signed APK sideloaded; launches without a URL bar; assetlinks live; keystore URL is 404 |
| 7 | Store readiness | `horizon-web-vrc-checklist` | Every applicable VRC passes on the device |
| 8 | Store listing | `horizon-store-listing-assets`, `review-game-trailer` | Art, copy, rating, privacy policy ready |
| 9 | Upload and submit | `horizon-web-store-publish` (ALPHA/BETA first), then the Dashboard (`hz-store-submit` for the walkthrough only) | Build on a test channel, then submitted by the user |

## 3. Hard rules

- **Ask first** before: deploying to a public host, any Store upload or channel promotion,
  scaffolding with `--force`, installing tools (Node, Playwright browsers, KTX-Software,
  `npm i -g @meta-quest/bubblewrap-cli`, OVR Metrics Tool), writing agent config
  (`adapter sync`), enabling `--allow-browser-automation`, or creating a signing key. Store
  submission happens in the Developer Dashboard, done by the user.
- **Secrets:** keystores, key passwords, app secrets and deploy tokens never go in `public/`,
  `dist/`, git or chat output. After every publish, check that `https://<domain>/android.keystore`
  returns 404. Remind the user to back up the keystore: without it the app can't be updated.
- **Prove it in the runtime, then on the device.** Typecheck → `dev up` → ECS/XR evidence
  (`xr status` shows `sessionActive`) → headset. A compile or a flat screenshot isn't proof.
- **Versions:** all `@iwsdk/*` packages on one version (1.0.1 when checked), `three` aliased to
  `npm:super-three@0.181.0` with an `overrides` entry, Three.js classes imported from
  `@iwsdk/core`.
- **One of each:** one scaffold (`npm create @iwsdk@latest`), one entry skill for app code
  (`iwsdk-dev`), one release pipeline (`horizon-web-store-publish`), one verify-first skill
  (`hz-quest-verify-first`).
- **Conflicting guidance:** IWSDK APIs → the `iwsdk-*` official skills plus
  `skills/iwsdk-official/ERRATA.md` (Meta's `hz-iwsdk-webxr` was written for IWSDK 0.4; see
  `iwsdk-performance/references/older-advice.md`). Store values → the `horizon-*` skills over
  `hz-store-submit` and `hz-store-pwa`. When in doubt, check live docs.
- **Built-ins first:** IWSDK already provides grabbing, ray/pointer interaction, UIKitML panels,
  locomotion, physics and audio. `@iwsdk/core` 1.0.1 is built on `@pmndrs/uikit`,
  `@pmndrs/handle` and `@pmndrs/pointer-events`, so use `pmndrs-uikit`, `pmndrs-handle` and
  `pmndrs-pointer-events` only as low-level references **after** `iwsdk-ui`, `iwsdk-grab` and
  `iwsdk-ray`. Don't call pmndrs's `forwardHtmlEvents`, add a second event forwarder, or run
  another uikit update loop: IWSDK wires these already (canvas events come from
  `input.canvasPointerEvents`), so events would fire twice. Skip their `createXRStore` and React
  Three Fiber sections.
- **Side effects to mention once:** `npm install` in a scaffold runs `@meta-quest/metavr`'s
  postinstall (binary into `~/.metavr`, a completions line in your shell profile) and enables
  IWSDK tool-call telemetry through `metavr` (`iwsdk-project-setup` §9).

## 4. Quick router

| The user wants to… | Use |
|---|---|
| start a new WebXR/IWSDK project, fix Node/MCP/dev-server setup | `iwsdk-project-setup` |
| upgrade a 0.4.x project or a Meta Spatial Editor scene | `iwsdk-migrate-0-5` |
| add or change any feature, system, component | `iwsdk-dev` |
| build or fix a 3D model in code | `iwsdk-build-model` |
| import, convert, compress a GLB/FBX, KTX2/Draco, "won't load" | `iwsdk-asset-pipeline` |
| arrange a scene, lights, environment, camera views | `iwsdk-compose-scene` |
| spatial UI panels, HUD, buttons | `iwsdk-ui`, then `pmndrs-uikit` for layout, text and style details |
| custom grab constraints (doors, levers, dials, two-handed scale, gizmos) | `iwsdk-grab`, then `pmndrs-handle` |
| custom pointers, hit or capture rules | `iwsdk-ray`, then `pmndrs-pointer-events` |
| model or fix assets in Blender | `scenario-blender-expert` (+ `scenario-blender-retopology`, `scenario-blender-uv-baking`, kept as sibling folders); always export glTF 2.0 / GLB, then `iwsdk-asset-pipeline` |
| gravity, collisions, throwing | `iwsdk-physics` |
| passthrough occlusion, depth | `iwsdk-depth-occlusion` |
| does Quest Browser support X, WebXR session options | `quest-browser-webxr` |
| check grab or ray interactions in the emulator | `iwsdk-grab`, `iwsdk-ray` |
| a state/physics/interaction bug | `iwsdk-debug` |
| automated tests, CI | `iwsdk-testing` |
| open it on the headset, remote DevTools, device logs | `iwsdk-quest-device-testing`, `hz-vr-debug`, `metavr-cli` |
| script a real Quest session | `iwsdk-native-xr-test` |
| it stutters, low FPS, slow loading | `iwsdk-performance`, `hz-perfetto-debug`, `threejs-perf-loading` (ideas only: IWSDK renders with WebGL, some of its examples are WebGPU/TSL) |
| plan or run a playtest | `game-playtest` with `xr-platforms-audio-and-comfort` for comfort observation |
| comfort, motion sickness, interaction design | `hz-immersive-designer`, `xr-platforms-audio-and-comfort`, `xr-perceptual-constraints-displays-and-tracking` |
| look up an XR number or anti-pattern; stereo rendering and input concepts | `xr-reference`, `xr-rendering-input-and-spatial-understanding` |
| leaderboards, saves, multiplayer backend | IWSDK has none built in (guide 18): your own backend; on Cloudflare `durable-objects` (multiplayer rooms), `workers-best-practices` |
| host the app (any host / Cloudflare) | `iwsdk-hosting`; Cloudflare: `cf-cli` for a new project, `wrangler` once a wrangler config exists |
| service worker, offline, stale-after-deploy | `pwa-offline` (keep `/.well-known/` and the start URL reachable) |
| plan the launch, PWA vs website, Early Access | `horizon-launch-roadmap` |
| package as a PWA/APK, upload, channels | `horizon-web-store-publish` (+ `iwsdk-pwa-packaging` for IWSDK's auto-enter and app-mode notes) |
| check store requirements (VRCs) | `horizon-web-vrc-checklist` |
| store art, description, rating, price, trailer | `horizon-store-listing-assets`, `review-game-trailer` (its wording is Steam-oriented; Horizon trailer and art specs come from `horizon-store-listing-assets`) |
| plain Playwright smoke tests of 2D pages | `webapp-testing`; in-XR checks use IWSDK's managed browser (`iwsdk-testing`) |

## Sources

- https://iwsdk.dev, https://iwsdk.dev/llms.txt, https://iwsdk.dev/ai/
- https://github.com/facebook/immersive-web-sdk (1.0.1, commit `0778f518`): `packages/cli/guidance/AGENTS.md`, `docs/guides/18-platform-services.md`
- https://developers.meta.com/horizon/resources/vrc-quest-performance-1/

Last verified: 2026-10-16
