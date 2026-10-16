# Community skill candidates: WebXR, three.js, IWSDK, web games and PWA publishing

Evaluated 2026-10-16. Scope: third-party and community Agent Skills (folders with a SKILL.md) for building WebXR games and apps with Meta's Immersive Web SDK (IWSDK: three.js, ECS, Vite, TypeScript), testing them on Meta Quest, and publishing them on the Meta Horizon Store as PWAs. Meta's official `meta-quest/agentic-tools`, skills from `facebook/immersive-web-sdk` and other IWSDK-team repos, and custom-authored skills are handled elsewhere and are out of scope here.

**Method**
- **Reuse:** the engine-neutral community skills already vetted for the Unity library were copied unchanged. Their upstream repos were re-checked on 2026-10-16. No skill path had changed since the pinned commits, so nothing was re-fetched.
- **Search:** GitHub (`gh search repos`, `gh search code` on SKILL.md files for three.js, WebXR, React Three Fiber, `@react-three/xr`, glTF-Transform, KTX2, meshopt, gltfpack, WebGPU, TSL, Babylon.js, A-Frame, service worker, web app manifest, Playwright, Web Audio, spatial audio, ECS, GLSL, Colyseus, PartyKit, WebRTC, Cloudflare Pages, WCAG, Quest Browser) and repo trees of the upstream projects (three.js, glTF-Transform, meshoptimizer, pmndrs, Babylon.js, A-Frame, PlayCanvas, Colyseus, PartyKit, Playwright, Chrome DevTools MCP). Web search of skills.sh, claudskills.com and skill registries, and the awesome-agent-skills and awesome-claude-skills lists.
- **Metadata:** stars, license and last commit were collected through the GitHub GraphQL API on 2026-10-16.
- **Downloads:** each source was shallow- or sparse-cloned into its own scratch folder. Nothing was installed or executed.
- **Review:** every collected SKILL.md was read in full, and every bundled script was read. All files were grepped for network, process, deletion, credential and `~/.claude` access, and for injection-style instructions. Quest-specific claims were checked against Meta's documentation, and dependency claims against IWSDK's own `package.json` files.

**Selection criteria:**
1. The license permits redistribution.
2. It is accurate and useful for current three.js and WebXR on Quest Browser, and it does not fight IWSDK.
3. It was maintained in 2025-2026.
4. It is not a thin wrapper.
5. It is safe.
6. Its name does not collide with anything else in the library.

**What IWSDK uses** (from its `package.json` files): three.js r181 (`super-three@0.181.0`), Vite 7, TypeScript 5, Vitest 4, the `elics` ECS, `@pmndrs/uikit` 1.x, `@pmndrs/pointer-events` 6.x and `@pmndrs/handle` 6.x, Havok physics, and IWER for emulation. Its dev plugin already ships XR emulation, agent tooling over MCP and a managed Playwright browser. Candidates were judged against that stack.

Collected skills live in `skills/community/<skill-name>/`, each with a `SOURCE.md`. The folder name equals the skill's `name:`.

---

## Picked: new for this library (10)

| Folder | Upstream owner | Purpose | License | Stars / last commit |
|---|---|---|---|---|
| `pmndrs-uikit` | pmndrs | `@pmndrs/uikit` 1.x, the layer IWSDK's spatial UI is built on: flexbox panels, `pixelSize`, conditionals, signals, MSDF fonts, batching, 0.x migration | MIT | 3,249 / 2026-10-15 |
| `pmndrs-pointer-events` | pmndrs | `@pmndrs/pointer-events`, the event system under IWSDK's pointers: hit rules, `pointerEventsType`, capture, void object, gesture pitfalls | MIT | 2,616 / 2026-10-15 |
| `pmndrs-handle` | pmndrs | `@pmndrs/handle`, which IWSDK's grab system uses: constrained handles (doors, levers, dials), two-hand scaling, `apply` hooks | MIT | 2,616 / 2026-10-15 |
| `threejs-perf-loading` | vladmdgolam | Hide shader compile cost, adaptive quality without false degrades, steady-state savings, frame attribution tooling | MIT | 9 / 2026-10-14 |
| `webapp-testing` | anthropics | Python Playwright smoke tests with a server-lifecycle helper, for CI checks of the built PWA | Apache-2.0 | 181,582 / 2026-10-09 |
| `pwa-offline` | AQaddora | Service-worker strategy, the update path, chunk-404 recovery, CDN headers for `sw.js`, version skew | MIT | 2 / 2026-08-31 |
| `cf-cli` | cloudflare | Cloudflare's `cf` CLI (beta) for new projects: find commands, dry-run, choose `cf` or Wrangler | Apache-2.0 | 3,079 / 2026-10-15 |
| `wrangler` | cloudflare | Wrangler for projects with a Wrangler config: deploy, secrets, Previews, Vite plugin environments | Apache-2.0 | 3,079 / 2026-10-15 |
| `durable-objects` | cloudflare | One Durable Object per game room: WebSockets with hibernation, SQLite storage, alarms | Apache-2.0 | 3,079 / 2026-10-15 |
| `workers-best-practices` | cloudflare | Review checklist for the Worker that serves the game and routes players to rooms | Apache-2.0 | 3,079 / 2026-10-15 |

## Picked: reused from the Unity library (12)

Copied unchanged from `unity-meta/skills/community/`, including their `LICENSE`, `NOTICE` and `SOURCE.md`. Each `SOURCE.md` now says the skill is shared with the Unity library, records the 2026-10-16 upstream check, and has web-specific caveats in place of the Unity ones.

| Folder | Upstream owner | Purpose | License | Stars / last commit |
|---|---|---|---|---|
| `xr-perceptual-constraints-displays-and-tracking` | the-vibey-project | VR reference part 1: latency, cybersickness, VAC, presence, displays, tracking | MIT | 3 / 2026-10-11 |
| `xr-rendering-input-and-spatial-understanding` | the-vibey-project | VR reference part 2: stereo, reprojection, foveation, input, locomotion comfort, anchors | MIT | 3 / 2026-10-11 |
| `xr-platforms-audio-and-comfort` | the-vibey-project | VR reference part 3: platforms, spatial audio, comfort, safety, accessibility | MIT | 3 / 2026-10-11 |
| `xr-ux-design-and-performance-budgeting` | the-vibey-project | VR reference part 4: 3D UX, frame-budget method | MIT | 3 / 2026-10-11 |
| `xr-reference` | the-vibey-project | VR reference part 5: anti-patterns, numbers, platform landscape | MIT | 3 / 2026-10-11 |
| `game-gdd-author` | AlterLab-IEU | Socratic 10-section GDD with pillars, scope tiers and MDA tags | MIT | 45 / 2026-03-30 |
| `game-playtest` | AlterLab-IEU | Behavioural playtest protocol, observation sheets, synthesis | MIT | 45 / 2026-03-30 |
| `prototype-fast` | gamedev-skills | One-question, timeboxed greybox prototype with keep or kill criteria | Apache-2.0 | 1,550 / 2026-10-09 |
| `review-game-trailer` | GarrettPetersen | Plan and audit trailers from authentic gameplay | MIT | 7 / 2026-10-06 |
| `scenario-blender-expert` | scenario-labs | Blender 5.2 agent protocol plus audit and review toolkit (lead) | MIT | 1,032 / 2026-10-15 |
| `scenario-blender-retopology` | scenario-labs | Dense or AI mesh to game low poly with budgets and topology audits | MIT | 1,032 / 2026-10-15 |
| `scenario-blender-uv-baking` | scenario-labs | Game UVs, texel density, measured high-to-low bakes | MIT | 1,032 / 2026-10-15 |

**Install notes**
- Install the three `pmndrs-*` skills together. In an IWSDK app, IWSDK already sets up uikit's transparent sort and forwards pointer events. Do not add a second event forwarder.
- Install the four Cloudflare skills together. They refer to each other by name (`wrangler` sends new projects to `cf-cli`; `durable-objects` and `workers-best-practices` point to both).
- `cf-cli` suggests adding a line to your user-level `CLAUDE.md`. That is a suggestion for you, not something the agent should do unasked.
- `pwa-offline`'s "audit first" step needs the rest of its suite, which was not collected. Skip it.
- The `scenario-blender-*` specialists find their lead as a sibling folder named exactly `scenario-blender-expert`. Install them into the same parent folder.

---

## Rejected: licensed but not picked

| Candidate | Upstream owner | License | Stars / last | Reason |
|---|---|---|---|---|
| `meta-webxr-skills`: `webxr-session`, `-rendering`, `-input`, `-layers`, `-passthrough`, `-ratk`, `-anchors`, `-pwa-quest` | Entelligentsia (skillforge) | MIT | 3 / 2026-07-30 | **Accuracy, checked against Meta's docs.** `webxr-pwa-quest` installs `@meta-quest/bubblewrap` (Meta documents `@meta-quest/bubblewrap-cli`), omits `--metaquest` and the 2D or immersive app mode, and adds an `xr_compatible` manifest field that Meta does not document. `webxr-session` says even a microtask gap after a click blocks `requestSession`, which overstates the transient-activation rule, and lists colour passthrough as Quest Pro only. RATK is superseded by IWSDK's scene understanding. |
| `pmndrs-xr`, `react-three-xr`, `react-three-handle`, `react-three-uikit` | pmndrs | MIT | 2,616 / 3,249, 2026-10-15 | Same quality as the picks, but `@pmndrs/xr` is a separate session and input stack that competes with IWSDK's, and the others are for React Three Fiber, which IWSDK does not use. |
| `koota`; `r3f-gamedev` (16 skills incl. `koota`, `miniplex`) | pmndrs; verekia | ISC; MIT | 755 / 2026-08-25; 31 / 2026-05-13 | Different ECS libraries from IWSDK's `elics`, and React Three Fiber game patterns. Would confuse an IWSDK agent. |
| `math` | pmndrs | MIT | 1,326 / 2026-10-12 | For the npm `math` package, not three.js. |
| `tsl`, `typegpu` (glyph); `tsl` (three-flatland); `webgpu`, `webgl`; `replit-webgpu-skills` | pmndrs; thejustinwalsh; woliveiras; AndrewBlumson | MIT; MIT; Apache-2.0; MIT | 397; 34; 3; 3 | WebGPU and TSL. IWSDK renders through `WebGLRenderer` today, and TSL node materials need `WebGPURenderer`. Revisit when IWSDK supports WebGPU. |
| `pmndrs-viverse` | pmndrs | NOASSERTION (not checked) | 132 / 2026-10-02 | HTC VIVERSE platform. Out of scope. |
| `xb-*` (8 skills) | google (xrblocks) | Apache-2.0 | 486 / 2026-10-15 | Specific to the XR Blocks SDK, aimed at Android XR. |
| Three.js-Claude-Skill-Package (24 skills incl. `threejs-impl-xr`, `threejs-agents-model-optimizer`) | Impertio-Studio / OpenAEC Foundation | MIT | 22 / 2026-03-30 | **Accuracy.** Says power-of-two textures are required for mipmaps (not in WebGL2), says UASTC costs 8-16 bytes per texel in VRAM (it transcodes to about 1 byte per texel), and uses a `gltf-transform ktx2` command that the CLI does not have (it has `etc1s` and `uastc`). Budgets target 60 FPS. |
| threejs-skills (14 skills incl. `threejs-xr`) | alton47 | MIT | 13 / 2026-03-25 | **Accuracy.** `threejs-xr` adds `renderer.xr.getCamera()` to the camera rig, tells you to stop the loop with `setAnimationLoop(null)` on session end, and says controller 0 is usually the right hand. |
| threejs-skills (22 skills incl. `threejs-webxr`) | full-stack-skills | Apache-2.0 | 9 / 2026-10-03 | **Thin.** About 85-line doc maps plus a 15-line example each. |
| threejs-skills (24 skills) | cesartevisual | MIT | 5 / 2026-09-10 | **Thin.** 22-24 lines each. |
| Threejs-Awesome-Graphics-Agent-Skills (24); threejs-complete-set-of-skill (27) | scottstts; linegel | MIT; ISC | 913 / 2026-10-15; 10 / 2026-09-24 | Very good for desktop showcase graphics (raymarched clouds, FFT ocean, GTAO, bloom, volumetrics), but screen-space and raymarched effects do not fit a stereo frame budget on Quest. |
| threejs-game-skills (9); mint-threejs-skills (9) | majidmanzarpour; mintdotgg | MIT | 2,525 / 2026-09-28; 114 / 2026-08-01 | **Framework-coupled** director suites for flat browser games. Generator skills call paid 3D, image and audio APIs, and the Mint set targets the Mint MCP. |
| `threejs` | secondsky (claude-skills) | MIT | 231 / 2026-09-26 | Adapted from CloudAI-X/threejs-skills, which has no license. The MIT label on the adaptation does not grant rights the original never gave. |
| claude-skills-threejs-ecs-ts | Nice-Wolf-Studio | MIT | 33 / 2026-07-29 | **Not Agent Skills format.** Loose `.md` files with no SKILL.md folders. |
| `game-studio` plugin (`three-webgl-game`, `react-three-fiber-game`, `web-3d-asset-pipeline`, `web-game-foundations`, `game-playtest`, ...) | openai (plugins) | MIT declared in `plugin.json`, no license file | 7,465 / 2026-10-08 | Flat browser-game focus. The skills depend on plugin-level `references/`. No license text to copy, and `game-playtest` would collide with the existing pick. |
| `threejs`, `react-three-fiber`, `webgl`, `vite`, `websocket-builder`; `three-js`, `canvas-webgl`, `pwa`, `webrtc`, `vite`; `three-js`, `pwa-development`, `vite` | TerminalSkills; claude-dev-suite; Mindrally | Apache-2.0; MIT; Apache-2.0 | 168; 42; 277 | Broad general-purpose libraries. Spot checks found generic content that is not Quest-aware. |
| claudedesignskills (`threejs-webgl`, `react-three-fiber`, `aframe-webxr`, `babylonjs-engine`, `playcanvas-engine`, `blender-web-pipeline`) | freshtechbro | MIT | 1,057 / 2025-11-20 | A-Frame, Babylon.js and PlayCanvas are other engines and out of scope. The three.js parts are generic. |
| create-playcanvas (16 skills incl. `inspect-glb`) | playcanvas | MIT | 61 / 2026-10-08 | PlayCanvas-engine-specific. |
| `gltf-transform`, `render-glb` | rawwerks (VibeCAD) | MIT | 121 / 2025-12-18 | **Thin, with the wrong defaults for Quest:** Draco plus WebP textures (WebP decodes to uncompressed RGBA in GPU memory; KTX2 is the right choice), a CAD workflow, and `bunx`. |
| glb-compressor (gltfpack); threewright | kjanat; m4bwav | MIT | 0 / 2026-08-26; 0 / 2026-10-11 | New and unproven. |
| `playwright-game-testing`, `partykit-multiplayer` and 17 more | shipshitgames | MIT | 5 / 2026-07-23 | **Project-specific** (paths into their own game). The `playwright-game-testing` SKILL.md also contains leftover tool-call residue. |
| `playwright-cli`; `playwright`; playwright-skill; playwright-skill; `playwright-skill` | microsoft; openai; lackeyjb; testdino-hq; LambdaTest | Apache-2.0; Apache-2.0; MIT; MIT; MIT | 14,260; 28,106; 3,204; 396; 376 | Overlap with IWSDK's managed Playwright browser and with `webapp-testing`. Microsoft's `playwright-cli` is the best of them (official, current). Add it if you prefer the CLI. lackeyjb's installs Playwright inside the skill folder. |
| `playwright-interactive` | openai | Apache-2.0 | 28,106 / 2026-06-24 | Codex-only (`js_repl`) and needs `--sandbox danger-full-access`. |
| `chrome-devtools`, `memory-leak-debugging`, `a11y-debugging`, `debug-optimize-lcp`, `troubleshooting` and 2 more | ChromeDevTools | Apache-2.0 | 53,679 / 2026-10-16 | **MCP wrappers.** They need `chrome-devtools-mcp`. Revisit if you adopt it; `memory-leak-debugging` is relevant to three.js leaks. |
| `web-perf` | cloudflare | Apache-2.0 | 3,079 / 2026-10-15 | Needs the Chrome DevTools MCP, and targets content-page Core Web Vitals. |
| web-quality-skills (`performance`, `core-web-vitals`, `accessibility`, `best-practices`, `seo`, `web-quality-audit`) | addyosmani | MIT | 2,952 / 2026-08-24 | High quality, but for content pages (LCP, CLS, INP). A VR game's constraint is frame time in the headset, and in-XR uikit UI has no DOM for WCAG checks. A good optional add-on for a 2D landing page. |
| ACCESSIBILITY.md (`accessibility`, `accessibility-testing`) | KreerC | MIT | 34 / 2026-05-20 | Over-reaches: requires WCAG AAA for every component, a public EU legal page "in any case", and drafting emails to regulators. DOM-only. |
| scaledock-skills (`webxr`, `web-app-manifest`, `service-workers`, `web-audio`, `webrtc`, `webgpu`, ...) | ScaleDockHQ | MIT | 2 / 2026-10-16 | Machine-generated spec digests (quoted MUST sentences for browser implementers), not app guidance. |
| pwa-skill-suite: the other 12 skills (`pwa-manifest`, `pwa-audit`, `pwa-verify`, ...) | AQaddora | MIT | 2 / 2026-08-31 | Phone-focused (iOS install flow, safe areas, touch targets), and the audit and verify skills need the suite's JavaScript runtime. Took `pwa-offline`. |
| pwa2play | degordonstech | MIT | 1 / 2026-10-12 | Google Play TWA with upstream Bubblewrap. Quest uses Meta's fork with different flags. |
| web-asset-generator | alonw0 | MIT | 518 / 2026-01-28 | Favicons and Open Graph images. No Horizon Store art, and it tells the agent to `pip install --break-system-packages`. |
| `netlify-deploy` and 14 more Netlify skills | netlify | MIT | 41 / 2026-10-14 | Official and accurate, but duplicates the Cloudflare hosting picks, and its "house rules" tell the agent to refuse a user's rollback request and "correct the premise". Add it if you host on Netlify, knowing that. |
| `cloudflare-deploy`, `netlify-deploy`, `vercel-deploy`, `render-deploy` | openai (skills) | Apache-2.0; MIT (Vercel) | 28,106 / 2026-06-24 | Copies of or alternatives to the vendors' own skills. Not read in depth. |
| `vite`, `vitest` | antfu | MIT | 5,978 / 2026-10-09 | Generated for Vite 8 (Rolldown) and Vitest 5. IWSDK pins Vite 7 and Vitest 4, so the advice would drift. Revisit when IWSDK upgrades. |
| skills (TDD, PRs, codebase design, ...) | mattpocock | MIT | 293,950 / 2026-10-09 | General engineering workflow, not web or XR. |
| `.github/skills` (`code-review`, `create-pr`, ...) | BabylonJS | Apache-2.0 | 26,168 / 2026-10-16 | Repo-maintenance skills for Babylon.js contributors. |

## Link only: no license, or the license does not allow redistribution

Read these for ideas. Do not copy them.

| Candidate | Stars / last | Notes |
|---|---|---|
| CloudAI-X/threejs-skills (10 skills: `threejs-fundamentals`, `-animation`, `-shaders`, ...) | 3,587 / 2026-01-19 | The most-installed three.js skill set (thousands of installs on skills.sh). No license. Many repos copy or adapt it. Ask the author to add a license. |
| emalorenzo/three-agent-skills (`three-best-practices`) | 61 / 2026-01-28 | No license. Widely copied into other repos. |
| dgreenheck/webgpu-claude-skill | 1,252 / 2026-04-10 | WebGPU and TSL. No license (and WebGPU does not apply to IWSDK today). |
| EnzeD/r3f-skills (11 skills) | 128 / 2026-08-31 | React Three Fiber. No license. |
| PlayableIntelligence/game-creator (31 skills incl. `add-3d-assets`, `game-audio`) | 344 / 2026-05-25 | three.js browser games. No license. |
| vibegameengine/web-starter-kit (72 skills incl. `asset-optimization-pipeline`, `blender-web-pipeline`) | 124 / 2026-09-28 | Only 2 of its 72 skills carry a license. |
| mrgoonie/claudekit-skills (`threejs`) | 2,226 / 2026-04-03 | No repo license. |
| vercel-labs/agent-skills (`deploy-to-vercel`, `vercel-optimize`, React skills) | 32,530 / 2026-08-28 | SKILL.md frontmatter says MIT, but the repo has no license file. Ask the maintainers. |
| cazala/webgpu-skill, iulian640/threejs-webgpu-skill | 34; 0 | No license, or NOASSERTION. WebGPU. |
| shi3z/sparkjs-skill | 38 / 2026-04-14 | Gaussian splats with Spark. No license. |
| webmaxru/web-ai-agent-skills | 52 / 2026-09-29 | Browser AI APIs ("Web AI"). No license. |
| devallibus/shaderbase-skills | 4 / 2026-03-09 | GLSL noise, SDF and colour skills. No license. |
| pascalorg/skills (`glb-web-export`) | 97 / 2026-09-11 | No license. |
| prag-matt-ic/threenix-plugin | 1 / 2026-10-13 | No license. |
| `iwsdk-*` and `hz-*` copies in many game repos (prajjwaldangal, lupamo, aryankeluskar, Rodscaloppe and others) | n/a | Copies of IWSDK-team and Meta skills. Out of scope (handled by another collector). |

## Checked, no skills published

mrdoob/three.js, donmccurdy/glTF-Transform, zeux/meshoptimizer, aframevr/aframe, playcanvas/engine, google/model-viewer, colyseus/colyseus, partykit/partykit, cloudflare/partykit, sparkjsdev/spark and protectwise/troika have no SKILL.md files in their repos as of 2026-10-16.

## Gaps (no good redistributable community skill found)

- **glTF and GLB optimization for Quest** (glTF-Transform or gltfpack, KTX2 with ETC1S or UASTC per texture slot, meshopt, texture budgets). Every candidate was thin, wrong, engine-specific, unlicensed or brand new. A good target for a custom skill.
- **A general three.js API skill.** The popular one is unlicensed, and the licensed ones were inaccurate or derived from it. The IWSDK skills and the model's own three.js knowledge have to cover this.
- **Shaders for WebXR** (`ShaderMaterial` and `onBeforeCompile` under multiview, precision on Adreno).
- **Web Audio and spatial audio** (`PannerNode` HRTF, three.js `PositionalAudio`, autoplay unlock in a headset). `xr-platforms-audio-and-comfort` covers the design side.
- **Multiplayer netcode for WebXR** (avatar and hand sync, interpolation, Colyseus or WebRTC). Only project-specific skills exist; `durable-objects` covers the server side.
- **Accessibility for in-XR UI** built with uikit, which has no DOM.
- **Quest PWA packaging** (Meta's Bubblewrap fork, manifest, `assetlinks.json`). The only community skill was inaccurate; covered by Meta's and the custom skills.
