# IWSDK × WebXR skill library

[![License: MIT](https://img.shields.io/badge/license-MIT%20%2B%20third--party-blue.svg)](THIRD_PARTY_NOTICES.md)
![Skills: 57](https://img.shields.io/badge/skills-57-brightgreen.svg)
![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin%20marketplace-orange.svg)
![IWSDK 1.0.1](https://img.shields.io/badge/IWSDK-1.0.1-purple.svg)

Agent skills for building **WebXR games and apps with Meta's Immersive Web SDK (IWSDK)** in
Claude Code, testing them on **Meta Quest**, getting them ready for **Meta VR Glasses**, and
shipping them on the **Meta Horizon Store** as PWAs. The IWSDK team's and Meta's official skills,
original skills that fill the testing, performance and publishing gaps, and vetted community
skills, all checked against IWSDK 1.0.1 and Meta's live docs (updated after Meta Connect 2026, on
2026-10-17).

Curated and written by **[Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh)**. Sister
library for Unity: [unity-meta-quest-skills](https://github.com/mirzaaghazadeh/unity-meta-quest-skills).

| Folder | Skills | From | License |
|---|---|---|---|
| [`skills/custom/`](skills/custom) | 12 | **Original, by Navid Mirzaaghazadeh**: workflow router, setup, Quest Browser features, Meta VR Glasses readiness, assets, tests, headset testing, performance, store release pipeline, web VRC audit, store listing, launch plan | MIT |
| [`skills/iwsdk-official/`](skills/iwsdk-official) | 13 + 1 agent | The IWSDK team ([facebook/immersive-web-sdk](https://github.com/facebook/immersive-web-sdk)), unchanged, plus [ERRATA](skills/iwsdk-official/ERRATA.md) | MIT |
| [`skills/meta-official/`](skills/meta-official) | 10 | Meta ([meta-quest/agentic-tools](https://github.com/meta-quest/agentic-tools)), unchanged, plus [ERRATA](skills/meta-official/ERRATA.md) | Apache-2.0 |
| [`skills/community/`](skills/community) | 22 | Vetted third-party skills, unchanged, each with a `SOURCE.md` | MIT / Apache |

---

## Quick start

**1. Install the core bundle** (in a Claude Code session, v2.1.275 or later):

```
/plugin install iwsdk-core --marketplace mirzaaghazadeh/iwsdk-webxr-skills
```

On older versions: `/plugin marketplace add mirzaaghazadeh/iwsdk-webxr-skills`, then
`/plugin install iwsdk-core@iwsdk-webxr-skills`.

**2. Open your project folder (or an empty one) in Claude Code and ask:**

> Use iwsdk-dev-workflow to plan my WebXR game. It's a [one-line pitch]. Check my setup first.

**3. Follow the steps it gives.** For a new project it scaffolds with `npm create @iwsdk@latest`,
which also adds IWSDK's own 12 skills and its MCP tools to the project. It asks before installing
anything.

Other ways to install (`npx skills`, `gh skill`, `install.sh`, by hand), updating, and
troubleshooting: **[docs/install.md](docs/install.md)**.

```bash
npx skills add mirzaaghazadeh/iwsdk-webxr-skills --list          # browse, pick with --skill
gh skill install mirzaaghazadeh/iwsdk-webxr-skills               # GitHub CLI
git clone https://github.com/mirzaaghazadeh/iwsdk-webxr-skills && cd iwsdk-webxr-skills
./install.sh --project ~/Games/MyWebXRGame iwsdk-core            # from a clone
```

## Bundles

The five bundles don't overlap. Start with `iwsdk-core`.

| Bundle | Skills | Context per session | What's in it |
|---|---|---|---|
| **`iwsdk-core`** | 17 | ~3.7k tokens | Router, verify-first guardrail, metavr, setup and MCP wiring, Quest Browser WebXR features, Meta VR Glasses readiness, asset pipeline, automated tests, headset testing, performance, Perfetto, comfort design, store release pipeline, web VRC audit, store listing, launch plan |
| `iwsdk-official` | 13 + agent | ~1.0k | The IWSDK team's skills: `iwsdk-dev` entry point, models, scenes, UI, grab, ray, debug, physics, depth occlusion, real-Quest automation, hosting, PWA packaging, 0.4→0.5 migration, plus the project code-review agent. **Skip it in projects made with `npm create @iwsdk`**: they already have these |
| `meta-web-extras` | 5 | ~0.4k | Meta's IWSDK skill (written for 0.4, see ERRATA), Meta's PWA store guide, the general submission walkthrough, Meta's multi-stack scaffolder, simpleperf |
| `community-web` | 10 | ~1.1k | pmndrs uikit / pointer-events / handle (the libraries under IWSDK), three.js loading and shader-stutter fixes, Playwright smoke tests, service-worker updates, Cloudflare hosting and multiplayer |
| `community-design-art` | 12 | ~1.3k | XR design reference, GDD, prototyping, playtesting, trailer review, Blender asset pipeline (export GLB). Shared with the Unity library |

```
/plugin install iwsdk-official@iwsdk-webxr-skills
/plugin install community-web --marketplace mirzaaghazadeh/iwsdk-webxr-skills
/plugin install community-design-art --marketplace mirzaaghazadeh/iwsdk-webxr-skills
/plugin install meta-web-extras --marketplace mirzaaghazadeh/iwsdk-webxr-skills
```

## How to use it

Describe what you want, and Claude picks the skill. The path from idea to store:

| Phase | Say something like | Main skills |
|---|---|---|
| Plan | "Write a one-page GDD and decide: VR or mixed reality, web link or Store PWA?" | `game-gdd-author`, `prototype-fast`, `horizon-launch-roadmap` |
| Set up | "Create a VR project with grabbing, physics and locomotion, and connect the MCP tools" | `iwsdk-project-setup`, `quest-browser-webxr` |
| Build | "Add a throwable ball, a start menu panel and teleport" | `iwsdk-dev` → `iwsdk-physics`, `iwsdk-ui`, `iwsdk-grab` |
| Test | "Prove grabbing works in the emulator, then add a smoke test for CI" | `iwsdk-grab`, `iwsdk-debug`, `iwsdk-testing` |
| On the Quest | "Open it on my Quest over USB and show me the console" | `iwsdk-quest-device-testing`, `iwsdk-native-xr-test` |
| Optimise | "It drops frames in the forest scene. Find out why" | `iwsdk-performance`, `iwsdk-asset-pipeline` |
| Ship | "Host it, package it as a PWA, run the VRC audit and upload to ALPHA" | `horizon-web-store-publish`, `horizon-web-vrc-checklist`, `horizon-store-listing-assets` |

Claude asks before deploying, uploading, submitting, creating a signing key or installing tools.
Some steps stay yours: the Developer Dashboard, the final **Submit for Review**, and backing up the
keystore. Full walkthrough with prompts for every phase: **[docs/usage.md](docs/usage.md)**.

**AI agents**: read **[AGENTS.md](AGENTS.md)** for install rules, safety rules and repo conventions.

### Tools the skills use

| Tool | What it is | Get it |
|---|---|---|
| Node.js | IWSDK needs Node `>=20.19 <21`, `>=22.12 <23`, or `>=24` | https://nodejs.org |
| `npm create @iwsdk@latest` | IWSDK's scaffolder: app, `AGENTS.md`/`CLAUDE.md`, IWSDK skills, MCP config | runs with npx, no install |
| `npx @iwsdk/cli` | Dev server with the IWER emulator in a managed browser, `iwsdk-runtime` MCP server, CLI twins of every tool | in each project's `node_modules` |
| `metavr` (Meta VR CLI) | Headset control, logs, traces, Meta docs search, store upload | comes with the scaffold (`@meta-quest/metavr`), or `curl -fsSL https://developers.meta.com/horizon/install-cli/ \| sh` |
| `@meta-quest/bubblewrap-cli` | Packages the hosted PWA into a Quest APK | `npm i -g @meta-quest/bubblewrap-cli` (when you get to packaging) |

MCP details and config: [mcp/README.md](mcp/README.md).

---

## Full catalog

### 1. Guardrails, routing and tooling

| Skill | Source | Use it for |
|---|---|---|
| `iwsdk-dev-workflow` | **original** | **Start here.** Routes every task to the right skill; end-to-end order and hard rules |
| `hz-quest-verify-first` | Meta | Check Quest claims against Meta's live docs (`metavr docs`) instead of memory |
| `metavr-cli` | Meta | The Meta VR CLI: device, app, logs, capture, perf, docs search, store distribution |
| `iwsdk-dev` | IWSDK | **Entry point for all app code.** Picks the greenfield or bounded-change playbook and calls the specialists |

### 2. Set up

| Skill | Source | Use it for |
|---|---|---|
| `iwsdk-project-setup` | **original** | Node check, `npm create @iwsdk@latest` flags, generated files, Claude Code MCP wiring (`adapter sync`), headless setup, metavr side effects |
| `quest-browser-webxr` | **original** | What Quest Browser supports (immersive-vr/ar, hands, eye gaze, hit-test, anchors, planes, meshes, depth, layers), with a Meta VR Glasses column, and how to request it |
| `iwsdk-vr-glasses` | **original** | Meta VR Glasses: gaze + pinch config that validates in IWSDK 1.0.1, 3° targets, controller-free flows, 70° × 66° layout, IWER and Quest testing |
| `iwsdk-migrate-0-5` | IWSDK | Upgrade a 0.4.x project: Meta Spatial Editor/GLXF removal, retired Vite plugins, UIKitML changes |
| `hz-new-project-creation` | Meta | Meta's multi-stack scaffolder (`references/web-project.md`; see ERRATA) |

### 3. Build

| Skill | Source | Use it for |
|---|---|---|
| `iwsdk-build-model` | IWSDK | Build or repair a 3D model as glTF or code |
| `iwsdk-compose-scene` | IWSDK | Scene JSON: placement, scale, lighting, environment, cameras |
| `iwsdk-ui` | IWSDK | UIKitML spatial panels and HUDs with preview and runtime checks |
| `iwsdk-physics` | IWSDK | Rigid bodies, collisions, forces, physics-aware grabbing |
| `iwsdk-depth-occlusion` | IWSDK | Depth sensing and real-world occlusion in AR |
| `iwsdk-asset-pipeline` | **original** | What IWSDK can load (manifest: Draco and KTX2 yes, Meshopt no; own loader: Meshopt and local decoders), FBX/OBJ → GLB, `gltf-transform` and its scripting traps, KTX2, HDR, audio, asset licences; with a GLB checker script |
| `pmndrs-uikit`, `pmndrs-pointer-events`, `pmndrs-handle` | community (pmndrs) | Low-level references for the libraries under IWSDK's UI, pointers and grabbing. Use IWSDK's skills first |
| `hz-iwsdk-webxr` | Meta | Meta's IWSDK overview. **Written for IWSDK 0.4**: see [ERRATA](skills/meta-official/ERRATA.md) |

### 4. Test and debug

| Skill | Source | Use it for |
|---|---|---|
| `iwsdk-grab`, `iwsdk-ray` | IWSDK | Prove grab, ray, UI clicks and distance grabbing with emulated controllers |
| `iwsdk-debug` | IWSDK | ECS pause/query/snapshot/step/diff loops for state, physics and interaction bugs |
| `iwsdk-testing` | **original** | Typecheck and build gates, asset checks, headless IWER smoke test, test-hook component, frame-stepped gameplay video, CI; with a smoke-test script |
| `iwsdk-quest-device-testing` | **original** | Open the app on a Quest (Wi-Fi or `adb reverse`), certificates, production build over HTTPS, saving results from the headset, remote DevTools, device logs |
| `iwsdk-native-xr-test` | IWSDK | Script a real Quest immersive session through the IWSDK CLI |
| `hz-vr-debug` | Meta | Logs, screenshots and video from the headset |
| `webapp-testing` | community (Anthropic) | Playwright smoke tests for 2D pages |
| `iwsdk-project-code-reviewer` (agent) | IWSDK | Reviews app code for IWSDK usage, ECS patterns and performance pitfalls |

### 5. Performance

| Skill | Source | Use it for |
|---|---|---|
| `iwsdk-performance` | **original** | Meta's WebXR performance workflow for IWSDK: frame budgets, CPU/GPU bound tests, frame-time logging that lines up with OVR Metrics, draw calls, crowds of animated characters, textures, foveation, refresh rate, locomotion input delay; plus a table of outdated advice |
| `hz-perfetto-debug`, `hz-simpleperf-debug` | Meta | GPU/CPU traces and CPU hotspots on the headset |
| `threejs-perf-loading` | community (vladmdgolam) | Shader-compile stutter, adaptive quality, slow-frame hunting (ideas; IWSDK renders with WebGL) |

### 6. Host and ship to the Horizon Store

| Skill | Source | Use it for |
|---|---|---|
| `horizon-launch-roadmap` | **original** | Hosted web vs Store PWA, 2D vs immersive, the decisions you can't undo (package name, signing key, domain), Early Access |
| `iwsdk-hosting` | IWSDK | Publish to a public HTTPS origin that can serve `/.well-known/` |
| `horizon-web-store-publish` | **original** | **The release pipeline**: build → hosting → manifest → Bubblewrap → verify → sideload → ALPHA → promote, device targeting (`quest3+`, "Future devices" for Meta VR Glasses), asking before every upload; with deploy, APK and upload scripts |
| `iwsdk-pwa-packaging`, `hz-store-pwa` | IWSDK, Meta | The upstream PWA/TWA guides the pipeline builds on (see both ERRATA files) |
| `horizon-web-vrc-checklist` | **original** | Every active VRC by ID, mapped to web apps (Store and Store 2D columns), each with a WebXR check and a headset test |
| `horizon-store-listing-assets` | **original** | Store art specs (incl. Mini Landscape), metadata limits, IARC, privacy policy, Data Use Checkup, pricing, price A/B tests, bundles, analytics and web IAP; with an image checker |
| `hz-store-submit` | Meta | Meta's general submission walkthrough. **Some specs are out of date**: see ERRATA |
| `pwa-offline` | community (AQaddora) | Service-worker updates, version skew, cache headers |
| `cf-cli`, `wrangler` | community (Cloudflare) | Host on Cloudflare (new projects / existing Wrangler projects) |
| `durable-objects`, `workers-best-practices` | community (Cloudflare) | Multiplayer rooms over WebSockets and server-code review (IWSDK has no backend) |

### 7. Design, art, marketing

| Skill | Source | Use it for |
|---|---|---|
| `hz-immersive-designer` | Meta | Comfort, interaction patterns, spatial layout, accessibility |
| `xr-reference`, `xr-perceptual-constraints-displays-and-tracking`, `xr-rendering-input-and-spatial-understanding`, `xr-platforms-audio-and-comfort`, `xr-ux-design-and-performance-budgeting` | community (the-vibey-project) | XR design reference: cybersickness, comfort, locomotion, rendering, frame budgets |
| `game-gdd-author`, `game-playtest` | community (AlterLab-IEU) | Game design document; playtest protocol (pair with `xr-platforms-audio-and-comfort`) |
| `prototype-fast` | community (gamedev-skills) | One-hour "is it fun?" prototype |
| `scenario-blender-expert`, `scenario-blender-retopology`, `scenario-blender-uv-baking` | community (scenario-labs) | Blender game-asset pipeline; export GLB |
| `review-game-trailer` | community (GarrettPetersen) | Plan and review the store trailer (Horizon specs come from `horizon-store-listing-assets`) |

---

## Notes and decisions

- **Meta VR Glasses (announced at Connect 2026, shipping spring 2027).** Eyes aim and a hand pinch
  selects; controllers are sold separately; the view is about 70° × 66°. Meta's hosted IWSDK docs
  were generated from IWSDK 0.5.3 and show two config keys that IWSDK 1.0.1 rejects:
  `iwsdk-vr-glasses` uses the keys that validate. Condensed facts with sources:
  [docs/meta-reference/](docs/meta-reference).
- **Projects made with `npm create @iwsdk` already contain IWSDK's 12 skills**, its review agent
  and MCP config. That's why the official skills are a separate bundle and `iwsdk-core` doesn't
  repeat them.
- **Meta's `hz-iwsdk-webxr` was written for IWSDK 0.4.** Several APIs in it don't exist
  (`session.fixedFoveatedRendering`, `navigator.xr.enableSpaceWarp`) and its performance numbers
  have no source. Corrections: [skills/meta-official/ERRATA.md](skills/meta-official/ERRATA.md)
  and `iwsdk-performance/references/older-advice.md`.
- **Bubblewrap's Quest template targets Android API 32** and marks head tracking as not required,
  while Meta asks new apps for API 34 and immersive apps for `required="true"`. Meta doesn't say
  whether PWAs are exempt, so the release pipeline treats the first ALPHA upload's test result as
  the answer.
- **IWSDK's asset manager can't decode Meshopt**, but `gltf-transform optimize` uses Meshopt by
  default. Use the flags in `iwsdk-asset-pipeline`, or load code-placed art with your own
  `GLTFLoader` + `MeshoptDecoder` and local decoders (same skill, §1a).
- **Built-in locomotion is a comfort-walking engine.** It reads input one frame late, has hidden
  rules (gravity ×3 above 10 m, reset above 100 m, 20 m/s cap) and no velocity API, and IWSDK
  physics has no raycasts. Fast action games need their own controller. See
  `skills/iwsdk-official/ERRATA.md`.
- **Side effects of a scaffold:** `npm install` runs `@meta-quest/metavr`'s postinstall (a binary
  in `~/.metavr` and a completions line in your shell profile; `METAVR_SKIP_DOWNLOAD=1` avoids it),
  and the IWSDK CLI sends tool-call telemetry through metavr. `iwsdk-project-setup` explains both.
- **GitHub Pages is a trap for Store PWAs:** common deploy paths drop `/.well-known/`, and project
  sites can't serve the origin-root `assetlinks.json` a TWA needs. See `horizon-web-store-publish`.
- **Horizon Worlds is a different product.** A WebXR app ships as a Horizon Store PWA or a link in
  Quest Browser, not as a World.
- **Not verified yet:** whether the store accepts Bubblewrap's SDK levels, the default WebXR frame
  rate on Quest 3/3S, which headsets support mesh detection, depth and camera access in Quest
  Browser, and the PWA entitlement flow (Meta's page returns 404). The scripts were tested against
  local fixtures and stubs, not a real APK or store upload. The skills mark these and tell Claude
  to confirm them at runtime.

## Keeping it current

IWSDK ships often (1.0.1 on 2026-10-16), and Meta updates its repo and docs often. To refresh the
copies, follow each folder's `SOURCE.md`. Research notes with every source:
[docs/research-iwsdk.md](docs/research-iwsdk.md), [docs/research-meta-web.md](docs/research-meta-web.md),
[docs/community-candidates.md](docs/community-candidates.md).

## License

- **Original work** (`skills/custom/`, docs, README, install script, MCP notes): [MIT](LICENSE),
  © 2026 Navid Mirzaaghazadeh.
- **IWSDK's skills and agent**: MIT. **Meta's skills**: Apache-2.0. **Community skills**: each keeps
  its own MIT or Apache-2.0 file.
- Full breakdown and attribution: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Contributing:
  [CONTRIBUTING.md](CONTRIBUTING.md).

Not affiliated with or endorsed by Meta Platforms, Inc., the IWSDK team or any other company named
here. Meta, Meta Quest, Meta Horizon and Horizon OS are trademarks of Meta Platforms, Inc.
