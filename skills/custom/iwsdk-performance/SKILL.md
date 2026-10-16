---
name: iwsdk-performance
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.2.0"
description: >-
  Finds and fixes frame-rate and load-time problems in IWSDK WebXR apps in
  Meta Quest Browser (Quest 2/3/3S, and what Meta documents for Meta VR
  Glasses) with Meta's WebXR performance workflow: frame budgets, CPU vs GPU
  vs vertex vs fragment tests, frame-time logging comparable with OVR Metrics
  (percentiles, hitches, CPU/GPU work time), draw calls and instancing,
  animated crowds (animation LOD, vertex animation textures), triangles,
  textures, lights, shadows, fixed foveation (default 1.0), framebuffer
  scale, target frame rate (`supportedFrameRates`, `updateTargetFrameRate`),
  multiview (already on), quad/cylinder layers, costly IWSDK feature flags,
  locomotion input latency, and bundle/loading checks, all sourced. Use when
  the user says "it stutters on the
  Quest", "low FPS", "frame drops", "hitches", "optimize for Quest", "too
  many draw calls", "GPU bound", "foveation", "run at 90 Hz", "framebuffer
  scale", "input lag", "crowd of enemies", "benchmark", "slow to load",
  "bundle too big", or before a store build.
---

# IWSDK performance on Meta Quest

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

Meta's rule for WebXR: find the bottleneck, change one thing, measure on the headset, repeat.
Asset-side fixes (Draco, KTX2, simplification) live in **`iwsdk-asset-pipeline`**; measuring
on the device lives in **`iwsdk-quest-device-testing`**.

## Ground rules

- **Only headset numbers count.** `browser_profile` results are labelled
  `host-browser-diagnostic`, `calibrated: false`. A headless SwiftShader browser runs about 10x
  slower than real. Use them for CPU long tasks and load time, never for frame rate.
- **Emulator runs pretend to be a Quest.** IWER redefines `navigator.userAgent` as an own
  property with a Quest Browser string (`iwer` 2.6.0 `lib/device/XRDevice.js`), so a
  user-agent check labels emulator numbers as headset numbers. Read the real one from the
  prototype and tag every logged row:
  ```ts
  const nav = navigator;
  const spoofed = Object.getOwnPropertyDescriptor(nav, 'userAgent') !== undefined;   // IWER
  const realUa = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(nav), 'userAgent')?.get?.call(nav) ?? '';
  const platform = !spoofed && /OculusBrowser/.test(String(realUa)) ? 'quest' : 'emulator';
  ```
- The headless agent browser (`--ai-mode agent`) rendered at about 60 Hz while IWER reported
  a 90 Hz session in an IWSDK 1.0.1 prototype, so "frames over budget" read 100 % there. Label
  emulator rows "not valid for performance" and don't read them.
- Keep a baseline (FPS, CPU and GPU frame time from OVR Metrics Tool, plus draw calls and
  triangles from `world.renderer.info`) in the heaviest scene, and compare after every change.
- Don't trade away required gameplay or legibility for a count. Ask before removing content.

## 1. Budgets

| Target rate | Frame budget (1000 / Hz) |
|---|---|
| 72 Hz | 13.9 ms |
| 80 Hz | 12.5 ms |
| 90 Hz | 11.1 ms |
| 120 Hz | 8.3 ms |

- **Store requirement (VRC Performance.1, updated 2025-10-22):** immersive apps must render at
  **at least 60 fps** and run at an allowed refresh rate: 72, 80, 90, 96, 100 or 120 Hz (96/100/120
  not on all devices). Plan for 72 Hz at full rate; the VRC audit is `horizon-web-vrc-checklist`.
- The budget covers CPU and GPU work. Meta's WebXR workflow flags app logic over **2 ms** as an
  optimisation candidate, and warns that 1,000 individual draw calls would likely drop below
  72 FPS.
- Meta publishes no WebXR-specific draw-call or triangle budget. Its device comparison page
  (updated 2026-05-11) recommends, for native apps; treat these as **upper bounds** in the browser:

| Device | Draw calls / frame | Triangles / frame | Refresh target |
|---|---|---|---|
| Quest 2 | < 100 | < 750K | 72 Hz |
| Quest 3 | < 200 | < 1.5M | 72 Hz (90 Hz recommended) |
| Meta VR Glasses | not published | not published | display up to 120 Hz |

  (No figures there for Quest 3S, Quest Pro or VR Glasses. Meta's Unity performance page gives
  wider ranges by app type; prefer the stricter numbers above for WebXR.)
- **Meta VR Glasses** (ships spring 2027; native-engine facts, how Browser applies them to WebXR
  is unverified): render scale 1.0 = 1728 × 1760 per eye, about 3% more pixels than Quest 3's
  1680 × 1760, so start from the Quest 3 budget; steady state CPU/GPU level 4 with no GPU
  level 5 (CPU Boost briefly to level 8; passthrough can lower the levels); 5.75 GiB app memory
  limit like Quest 3/3S; battery saver forces 72 Hz and FFR; heat is managed separately for the
  glasses and the compute puck, so the 45-minute run matters more than a short demo. IWER's
  `metaVRGlasses` profile lists 72/90/96/100/120 Hz: emulator data. Meta's render-scale page
  recommends dynamic resolution on the glasses; WebXR fixes `framebufferScaleFactor` before the
  session (super-three), so there is no IWSDK equivalent today. Device setup and gaze:
  `iwsdk-vr-glasses`.
- Don't assume a default refresh rate. Meta's frame-rate page gives defaults only for older
  devices. Read `session.frameRate` on the device (probe in `iwsdk-quest-device-testing` §4).
- Generic Quest Browser WebXR features and knobs (not IWSDK-specific): `quest-browser-webxr`.

## 2. Measure

```ts
// dev only: after World.create(...) resolves
const info = world.renderer.info;      // read during XR; resets every frame
console.log(info.render.calls, info.render.triangles, info.memory.geometries, info.memory.textures);
console.log('multiview:', world.renderer.xr.isMultiview, 'foveation:', world.renderer.xr.getFoveation());
```

- In-headset: OVR Metrics Tool overlay (FPS, CPU/GPU frame time).
- CPU detail: chrome://inspect → Performance (adds overhead; compare like with like).
- Authored scenes: `npx @iwsdk/cli scene render-file ...` returns `renderStats`
  (triangles, visible nodes) for the editor render; use it to spot heavy assets early.
- Load: `npm run build` then `find dist/assets -maxdepth 1 -type f -exec du -h {} + | sort -h`.

### Frame-time logging that lines up with OVR Metrics

Averages hide stutter. For pass/fail decisions log percentiles and hitches, one row per second
with a wall-clock ISO timestamp, so the rows line up with an OVR Metrics CSV recorded at the
same time.

- **Frame interval:** from consecutive XR frame timestamps (`world.onXRFrame` delta). This is
  what the compositor got; compare it with OVR Metrics FPS and stale frames. Report avg, p50,
  p95, p99, max, % of frames over the budget, and frames over 33 ms (hitches).
- **CPU work:** time spent in `world.update` plus render submission. One way is to wrap
  `world.renderer.render` and time it together with a system at the lowest and highest
  priority.
- **GPU work:** `EXT_disjoint_timer_query_webgl2` around the frame's render. Check
  `gl.getParameter(ext.GPU_DISJOINT_EXT)` before using a result. Whether Quest Browser exposes
  the extension is **unverified**; fall back to OVR Metrics' GPU time.
- **Judge headroom on work time, not on the interval.** With vsync the interval averages the
  full budget whenever the app keeps up, so "average 13.9 ms at 72 Hz" says nothing about
  spare time. Use max(CPU, GPU) per frame, which is what OVR Metrics' app CPU and GPU times
  show.
- Get the rows off the headset: see `iwsdk-quest-device-testing` §4b.

## 3. Find the bottleneck (Meta's WebXR workflow)

1. **CPU or GPU?** Stop drawing content and compare frame time. In IWSDK a dev toggle such as
   `world.scene.visible = false` skips all draws (the session still runs). Barely faster → CPU
   bound. Much faster → GPU bound.
2. **GPU: vertex or fragment?** Render at a tiny resolution and compare. In Three.js that is
   `world.renderer.xr.setFramebufferScaleFactor(0.1)`, which **must be called before the session
   starts** (super-three warns "Cannot change framebuffer scale while presenting"). Unchanged →
   vertex bound (scene complexity). Faster → fragment bound (pixels, shading).
3. Fix the biggest one (§4), then run the workflow again: removing one bottleneck often exposes
   the next.

## 4. Fixes

### CPU bound

- **Fewer draw calls.** Merge static meshes that share a material in the asset pipeline
  (`gltf-transform` join/flatten; see `iwsdk-asset-pipeline` for name-preservation caveats).
  Repeat placed objects with scene **patterns**: a pattern whose prefab is one component-free
  mesh lowers to a single `InstancedMesh` (`assets-and-manifest` rule). For code-built repeats
  use `InstancedMesh` from `@iwsdk/core`.
- **Share materials** within a module; clone only the instances that must differ.
- **No allocation in `update()`.** Create scratch `Vector3`/`Quaternion` in `init()`; use
  `getVectorView()` for vector fields; `signal.peek()` instead of `.value` in `update()`.
- **React, don't poll**: `queries.x.subscribe('qualify', ...)` instead of per-frame checks.
- **Lower update rates** for non-critical work: animate distant objects every few frames, split a
  large set into three and update one per frame (Meta best practices).
- **Many animated characters.** Two patterns, both built and compared in an IWSDK 1.0.1
  prototype (IWER emulator, so draw calls only; frame times **unverified on Quest**):
  - *Pooled `SkinnedMesh`*: clone with `SkeletonUtils.clone`, share clips and one material,
    update each `AnimationMixer` at a rate that falls with distance (every frame near, 30 Hz
    mid, 15 Hz far) and freeze characters outside the view cone. Simple; one draw call per
    character; mixer CPU grows with the count.
  - *Vertex animation texture (VAT)*: at load, bake every clip's skinned vertex positions
    (plus a normal component) into a half-float `DataTexture`, then draw all characters with
    one `InstancedMesh` whose `ShaderMaterial` reads the texture with `texelFetch` by
    `gl_VertexID` and a per-instance clip/time attribute. One draw call for the whole crowd and
    almost no animation CPU. Costs: bake time and memory (a 3k-triangle character with 7 clips
    at 30 fps took 83 ms and 11 MB), no cross-fade between clips unless the shader samples two,
    and a hand-written shader
    whose multiview behaviour is unverified (§4 Multiview).
  - Measured at 25 characters: 62 draw calls (pooled skinned) vs 38 (VAT) for the whole frame,
    including level, UI and controllers.
- **Turn off unused features** in `iwsdk.config.json`: `physics: false` removes Havok (JS + WASM)
  from the build; `locomotion: false` when stationary; `sceneUnderstanding`/`environmentRaycast`
  off when not used.
- Physics runs in a Web Worker by default (`useWorker: true`, 60 Hz). Keep it, and raise
  `features.physics.updateFrequency` only for a measured need. `updateFrequency` is a
  **physics-only** key: 1.0.1's locomotion accepts `useWorker`, `initialPlayerPosition`,
  `comfortAssistLevel`, `turningMethod`, `enableJumping` and `browserControls`
  (`packages/core/src/project/validation.ts`).
- **Built-in locomotion acts one frame late.** `LocomotionSystem` is registered at priority −5
  and `InputSystem` at −4, so locomotion reads the previous frame's controller state, although
  the source comment says "InputSystem => LocomotionSystem" (`src/init/world-initializer.ts`).
  An IWSDK 1.0.1 prototype measured 1 frame of input-to-motion delay with `useWorker` on and
  off; a custom controller in a system after −4 measured 0. Fine for comfort walking; worth
  measuring for fast action games.

### Vertex bound

- Fewer triangles: simplify meshes (`gltf-transform simplify`), cut sphere/lathe segment counts on
  small repeated parts, and make distance-based variants (two prototypes from one factory).
- Split very large models so frustum culling can skip off-screen parts; cluster instances
  spatially (Meta workflow).
- Locomotion: segment very large levels into several `LocomotionEnvironment`s (IWSDK locomotion
  performance page).

### Fragment bound

- **Foveation.** `world.renderer.xr.setFoveation(value)`, `0` = none, `1` = maximum. super-three
  0.181.0 already defaults to **1.0** and applies it at session start, so this is normally on.
  Lower it (e.g. `0.5`) only if peripheral text or edges look bad. FFR is lost when you render the
  scene to an intermediate target and post-process it, or switch render targets mid-frame (Meta
  FFR page).
- **Framebuffer scale** (set before the session starts): Meta's workflow calls `0.8`-`0.9` a last
  resort, but for a Store build keep it **≥ 0.85** for most of the experience (VRC
  Performance.4: "no less than 85% render scaling", recommended for immersive apps).
- **Cheaper materials** for background objects (Meta: Phong instead of Standard/PBR); drop
  unneeded maps; use KTX2/Basis textures (UASTC for normal maps, ETC1S for colour).
- **Lights:** cost rises directional → point → spot → area. With heavy PBR, one directional or
  one point light (Meta). Prefer the scene's `IBLGradient`/`IBLTexture` for ambient response.
- **Shadows** add draw calls and fill cost; shadow-casting point lights need six shadow maps.
  Keep `castShadow` off by default (IWSDK rule), use a small `shadowMapSize` (`"256"`-`"2048"`).
- **Overdraw:** opaque front-to-back, big backgrounds last, few large transparent surfaces or
  particles; stop drawing objects that have faded out (Meta).

### Frame rate

- Read `session.supportedFrameRates`; only call `updateTargetFrameRate(rate)` with a listed
  value (Quest Browser 16.4+). Raise it only with measured headroom. If frames regularly exceed
  the target frame time (Meta's example: over 11 ms at 90 Hz), lower the rate instead: missed
  frames make the compositor synthesise frames (stutter, black edges).

```ts
const s = world.session as XRSession & {
  supportedFrameRates?: Float32Array; updateTargetFrameRate?: (r: number) => Promise<void>;
};
const rates = s?.supportedFrameRates ? Array.from(s.supportedFrameRates) : [];
if (rates.includes(90)) await s.updateTargetFrameRate?.(90);   // only after measuring headroom
```

### Multiview and layers

- **Multiview is already on.** IWSDK creates the renderer with super-three's
  `multiviewStereo: true` and always offers the `layers` feature, so on Quest Browser it renders
  both eyes in one pass through `OCULUS_multiview` and a projection layer. Check
  `world.renderer.xr.isMultiview` in XR. Don't add other multiview code. Test custom shaders on the
  device (**unverified**: multiview support for hand-written `ShaderMaterial`s).
- **Quad / cylinder layers** (`XRQuadLayer`, `XRCylinderLayer` components, see
  `examples/layers`): the compositor shows them at their own resolution, which keeps text and
  video sharp and lets static content redraw only when it changes. Enable
  `world.xr.features.layers: true`.

## 5. Loading and bundle

- `npm run build` and sort `dist/assets` by size (IWSDK guide 08). Vite copies `public/` as-is,
  so compress models and textures before adding them (`iwsdk-asset-pipeline`).
- Mark only startup-blocking assets `priority: 'critical'`; others `'background'`, which load
  right after the critical ones.
- UIKitML fonts are pruned to the ones static UIKitML uses; `iwsdkDev({ bundle: { fonts: [...] } })`
  keeps families that load dynamically.
- Runtime CDN fetches on first load: Draco/Basis decoders from `unpkg.com`, controller models
  from `cdn.jsdelivr.net` (`@webxr-input-profiles/assets`). Expect that latency; allow both
  hosts in any CSP. To remove them: load art with your own loader and local decoders
  (`iwsdk-asset-pipeline` §1a). For controller models, copy the profile GLBs you support under
  `public/` and wrap `AssetManager.loadGLTF` before `World.create` to rewrite the jsDelivr
  prefix. That monkeypatches a static, because 1.0.1 has no option for it; it worked in the
  emulator in an IWSDK 1.0.1 prototype and is **unverified on a Quest**.
- Size reference: a small IWSDK 1.0.1 game (UIKitML panels, no physics, own controller)
  built to a 6.6 MB main chunk (1.7 MB gzip), plus a 0.46 MB MSDF text worker and a 0.42 MB
  bundled font (prototype build, 2026-10-16). Most of it is the SDK, so expect a similar floor.
- **Measure the production build on the headset, not the dev server.** The dev server serves
  unbundled modules plus HMR and emulator code. `vite build && vite preview` over HTTPS:
  `iwsdk-quest-device-testing` §4a.
- Desktop load profiling (Lighthouse can't compute LCP/TTI for a canvas-only page; launch
  headless Chromium with a hardware ANGLE backend): Meta's `hz-iwsdk-webxr` skill,
  `references/desktop-load-profiling.md`.

## 6. Ignore these older tips

Some guides (including Meta's `hz-iwsdk-webxr` skill, written for IWSDK 0.4) show APIs that
don't exist or don't apply to IWSDK 1.x. Details and sources:
[references/older-advice.md](references/older-advice.md).

## Checklist before a store build

- [ ] Heaviest scene holds the target rate in OVR Metrics Tool for 5+ minutes; never long below 60 fps
- [ ] Measured on the production build (`vite preview`), with p99 and hitch counts, not only averages
- [ ] Refresh rate is one of the allowed values; framebuffer scale ≥ 0.85
- [ ] Draw calls and triangles recorded and within the Meta numbers above for the device class
- [ ] Unused features off in `iwsdk.config.json`; `physics: false` if no rigid bodies
- [ ] Models Draco- or quantize-compressed, textures KTX2, texture size capped (`iwsdk-asset-pipeline`)
- [ ] `castShadow` only on grounded focal objects; one main light with PBR
- [ ] No per-frame allocations in systems (run `iwsdk-project-code-reviewer`)
- [ ] `dev.emulator.injectOnBuild` is not `true`; dev-only probes removed
- [ ] VR Glasses in scope: same run with hands only, and with `world.features.gaze.showDebugReticle` off

## Sources

- https://developers.meta.com/horizon/documentation/web/webxr-perf-workflow/ (CPU/GPU and vertex/fragment tests, 2 ms logic, 1,000 draw calls, framebuffer 0.8-0.9, layers)
- https://developers.meta.com/horizon/documentation/web/webxr-perf-bp/ (update rates, overdraw, PBR, lights, shadows, KTX2, clear colour)
- https://developers.meta.com/horizon/documentation/web/webxr-ffr/ (fixed foveation, FFR caveats)
- https://developers.meta.com/horizon/documentation/web/webxr-frames/ (frameRate APIs, Browser 16.4+, 11 ms at 90 Hz)
- https://developers.meta.com/horizon/resources/device-optimization-comparison/ (draw calls, triangles, refresh targets; 2026-05-11)
- https://developers.meta.com/horizon/resources/vrc-quest-performance-1/ (≥ 60 fps, allowed refresh rates; 2025-10-22), https://developers.meta.com/horizon/resources/vrc-quest-performance-4/ (≥ 85% render scaling; 2024-07-31)
- https://developers.meta.com/horizon/documentation/unity/unity-perf/ (native ranges by app type)
- https://unpkg.com/super-three@0.181.0/src/renderers/webxr/WebXRManager.js (foveation default 1.0, framebuffer scale before session, projection layer + `OCULUS_multiview`)
- https://github.com/facebook/immersive-web-sdk (1.0.1): `packages/core/src/init/world-initializer.ts` (`multiviewStereo: true`; `LocomotionSystem` priority −5, `InputSystem` −4), `src/project/validation.ts` (physics and locomotion keys), `src/init/xr.ts` (default `layers` offer), `src/asset/loaders/gltf-loader.ts`, `packages/xr-input/src/gamepad/input-profiles.ts`, `docs/guides/08-build-deploy.md`, `docs/concepts/locomotion/performance.md`, `examples/layers/`
- npm `iwer@2.6.0`, `lib/device/XRDevice.js` (`Object.defineProperty(navigator, 'userAgent', …)`)
- https://registry.khronos.org/webgl/extensions/EXT_disjoint_timer_query_webgl2/ (GPU timer queries, `GPU_DISJOINT_EXT`)
- Meta VR Glasses: https://developers.meta.com/horizon/essentials/compare-devices/ (2026-09-30), /render-scale/ (2026-09-01), /cpu-gpu-levels/ (2026-09-11), /boost-cpu-gpu-levels/ (2026-09-11), /memory-ram/ (2026-08-31), /thermal/ (2026-09-15), /battery-saver-mode/ (2026-04-08), /test-your-app/ (2026-09-25); npm `iwer` 2.6.0 `lib/device/configs/headset/meta.js` (`metaVRGlasses` frame rates)
- Crowd rendering, input-delay measurements, emulator frame rate and bundle sizes: an IWSDK 1.0.1 VR prototype, IWER emulator and production build, 2026-10-16 (headset numbers pending)

Last verified: 2026-10-17
