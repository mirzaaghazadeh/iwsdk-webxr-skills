---
name: quest-browser-webxr
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.1.0"
description: >-
  What Meta Quest Browser supports for WebXR and how to use it: a sourced
  feature matrix with a Meta VR Glasses column (immersive-vr, immersive-ar
  passthrough, hand-tracking, gaze-tracking, hit-test, anchors, plane and
  mesh detection, depth sensing, layers, fixed foveation, framebuffer scale,
  frame rate control, multiview, Space Warp, system keyboard, Touch Pro),
  session init options, focus and visibility handling, gaze rules for 2D
  pages, headset testing (adb reverse, chrome://inspect, MQDH, IWER, OVR
  Metrics, ovrgpuprofiler, RenderDoc, metavr fov-sim) and performance budgets
  for Quest 2/3/3S and VR Glasses. Use when the user asks "does Quest Browser
  support X", "does it work on Meta VR Glasses", "how do I request
  passthrough / hand tracking / plane detection / eye gaze", "set 90 Hz in
  WebXR", "enable foveation", "my WebXR app stutters on Quest", "debug WebXR
  on the headset", "Enter VR button missing", or before choosing WebXR
  features for an IWSDK app.
---

# Quest Browser WebXR: features, session setup, testing, performance

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

This is the browser layer under IWSDK, for any WebXR stack (IWSDK, three.js, A-Frame, Babylon,
raw WebGL). Hand-offs in this library: IWSDK APIs and feature flags `hz-iwsdk-webxr` and
`iwsdk-project-setup`; step-by-step headset testing of an IWSDK app `iwsdk-quest-device-testing`;
IWSDK-specific tuning (its renderer defaults, multiview already on) `iwsdk-performance`;
packaging `horizon-web-store-publish`. Per-feature detail and caveats:
[references/feature-matrix.md](references/feature-matrix.md). Profiling recipes:
[references/performance.md](references/performance.md).

Meta's per-feature WebXR pages are mostly **undated and older** than its 2026-07 web-docs
rewrite (the mixed reality page still names only Quest 2 and Quest Pro), and **none mentions
Meta VR Glasses** (checked 2026-10-17). Treat device lists as lower bounds, detect features at
runtime, and confirm anything critical with `metavr docs search "<feature> webxr"` and a
headset test. Building for VR Glasses (gaze + pinch, no controllers, 70° × 66° view): load
**`iwsdk-vr-glasses`**; device facts with sources: `docs/meta-reference/web-vr-glasses.md`.

## Know the browser

- Chromium-based. Since March 2026 Browser versions follow Chromium milestones: 144 (2026-03-02),
  146.0 (2026-04-21, Chromium 146), 149.1, 150.1, **152.1 (2026-10-02)** (Browser release notes).
  Before that: 42.x (Feb 2026).
- User agent tokens: `Quest 2`, `Quest Pro`, `Quest 3`; **Quest 3S reports `Quest 3`**; no
  token is documented for VR Glasses. Meta says use feature detection, not the UA
  (browser-specs, 2026-07-21).
- 2D windows: default 1280 × 670, min 500 × 495, max 2000 × 1070 CSS px; desktop browsing mode
  by default (viewport meta ignored) (browser-specs). Window sizes on VR Glasses: unverified.
- Gaze in 2D pages: looking fires no `:hover` or pointer events (the system draws hover), so no
  flow may depend on hover; use `<button>` / `<a href>` or focusable ARIA roles (a click-only
  `<div>` may not be targetable). Targets **56 × 56 CSS px** or larger (eyes-best-practices,
  2026-10-13; the older 2d-web page, 2026-09-04, still says 48 × 48).
- WebXR needs a secure context: HTTPS, or `localhost` through `adb reverse`.

## Feature matrix (summary)

"Glasses" = Meta VR Glasses. No Meta web page covers the device yet, so that column is device
specs plus IWSDK's guidance; "unverified" there means "detect at runtime and test when the
hardware ships (spring 2027)".

| Feature | Request it with | Status on Quest Browser | Glasses | Meta source |
|---|---|---|---|---|
| VR session | `requestSession('immersive-vr')` | Supported | Meta's IWSDK glasses guide uses VR mode | webxr-overview; IWSDK get-started-glasses |
| Passthrough AR | `'immersive-ar'`; clear to transparent | Supported (page: Quest 2 grey, Pro colour; Quest 3/3S not listed but IWSDK MR targets them) | Device has colour stereo passthrough with depth; WebXR AR unverified | webxr-mixed-reality; compare-devices |
| Hand tracking | optional feature `'hand-tracking'` | Supported; palm pinch reserved for the system | **Primary input**: pinch selects | webxr-hands; bring-your-app-glasses |
| Eye gaze | optional `'gaze-tracking'` (IWSDK also offers the W3C draft `'eye-tracking'`) → an `XRInputSource` with `targetRayMode === 'gaze'` | No eye tracking on Quest 3/3S (Quest Pro has the hardware; Browser support unverified) | **Primary targeting**; IWSDK 1.0+ `gazeTracking` | IWSDK 1.0.1 `init/xr.js`; horizon-os-input |
| Hit test | `'hit-test'` | Supported; no room scan needed | Unverified | IWSDK ch. 14 |
| Anchors, persistent | `'anchors'`; `requestPersistentHandle()` / `restorePersistentAnchor()` | Supported; 8 persistent per site; none in private mode | Unverified | webxr-mixed-reality |
| Plane detection | `'plane-detection'`; `frame.detectedPlanes` | Supported; needs Space Setup; `initiateRoomCapture()` once per session | Unverified | webxr-mixed-reality |
| Mesh detection | `'mesh-detection'` | Used by IWSDK scene understanding; device support **unverified** | Unverified | IWSDK ch. 11 |
| Depth sensing | `'depth-sensing'` + usage/format preferences | Used by IWSDK depth occlusion; Browser 146.0 added experimental depth projection; device list **unverified** | Device has depth sensing; WebXR unverified | IWSDK ch. 15; release notes; compare-devices |
| Layers | `'layers'`; `XRWebGLBinding`, `XRMediaBinding` | Supported (quad, cylinder, equirect, cube, projection, media) | Unverified; `metavr device fov-sim` clips layers only on Horizon OS v209+ | webxr-layers; field-of-view |
| Fixed foveation | `'low'/'medium'/'high-fixed-foveation-level'` or `XRWebGLLayer.fixedFoveation` 0-1 | Supported | Device supports FFR and ETFR natively; no public ETFR route for web | webxr-ffr; fixed-foveated-rendering |
| Frame rate | `session.supportedFrameRates`, `updateTargetFrameRate()` | Browser 16.4+ | Display up to 120 Hz; IWER's profile lists 72/90/96/100/120 (emulator data) | webxr-frames; compare-devices |
| Multiview | WebGL2 `OCULUS_multiview` (`OVR_multiview2` behind a flag) | Supported, "experimental" label | Unverified | web-multiview |
| Space Warp | `'layers'` + `'space-warp'` | Draft spec; Browser 24.2+ and **`chrome://flags` only**: not usable for Store users | Same caveat | webxr-space-warp |
| System keyboard | focus an HTML `<input>`; `session.isSystemKeyboardSupported` | Browser 26.1+ | Unverified | webxr-keyboard |
| Touch Pro controllers | profile `meta-quest-touch-pro` (fallback `oculus-touch-v2`) | 12 gamepad buttons incl. stylus, finger curl | Touch Plus only, sold separately; don't assume controllers | webxr-pro-controller; compare-devices |
| Camera access | MediaDevices (`getUserMedia`) | IWSDK `CameraSource`; which cameras Browser exposes is **unverified** | Unverified | IWSDK ch. 13 |
| DOM overlay, WebGPU XR | n/a | Not documented by Meta for Quest WebXR; release notes list experimental WebGPU layers, foveation and Space Warp layers (149.1-152.1) | Same | release notes |

## Session setup (raw WebXR; IWSDK wraps this)

```js
const mode = 'immersive-vr';                       // or 'immersive-ar' for passthrough
if (!(await navigator.xr?.isSessionSupported(mode))) return showNoXrMessage();
const session = await navigator.xr.requestSession(mode, {
  requiredFeatures: ['local-floor'],
  optionalFeatures: ['hand-tracking', 'layers', 'medium-fixed-foveation-level'],
  // AR extras: 'hit-test', 'anchors', 'plane-detection', 'mesh-detection',
  // 'depth-sensing' with depthSensing: { usagePreference: ['gpu-optimized'], dataFormatPreference: ['float32'] }
  // Eye gaze (VR Glasses): 'gaze-tracking' and 'eye-tracking', always optional
});
```

- Put everything optional in `optionalFeatures`; a missing required feature rejects the session.
- **Gaze without IWSDK:** after the session starts, look in `session.inputSources` (and
  `inputsourceschange`) for a source with `targetRayMode === 'gaze'`, cast from its
  `targetRaySpace`, and take selection from the hands' `select` events. That split (gaze aims,
  pinch commits) is how IWSDK 1.0.1 and IWER model it; whether Browser's gaze source fires
  `select` itself is unverified. Keep hand and controller rays working when no gaze source
  appears (Quest 3/3S). Meta has no web guide that combines gaze and pinch outside IWSDK
  (bring-your-app-glasses), so test on hardware.
- `requestSession` needs a user activation in a tab. In an installed immersive PWA the icon tap
  counts, so call it on load there only (gate on `window.getDigitalGoodsService`; see
  `horizon-web-store-publish`).
- **Frame rate**, after the session starts:
  ```js
  const rates = session.supportedFrameRates;            // e.g. Float32Array; undefined if unsupported
  if (rates?.includes(90)) await session.updateTargetFrameRate(90);
  console.log('nominal rate', session.frameRate);
  ```
  Meta: default is 90 fps on Quest 2 and 72 on "Meta Quest headsets" (an undated page that
  predates Quest 3; read `session.frameRate` rather than assuming). VRC Performance.1 allows
  72, 80, 90, 96, 100 or 120 Hz (96/100/120 not on all devices) with **≥ 60 fps** rendered.
- **Render scale**: `XRWebGLLayer` init `framebufferScaleFactor`, or three.js
  `renderer.xr.setFramebufferScaleFactor(x)` before the session starts (webxr-perf-workflow).
  Stay ≥ 0.85 for most of the experience (VRC Performance.4, Recommended).
- **Foveation at runtime**: `session.renderState.baseLayer.fixedFoveation = 0.0-1.0` (three.js:
  `renderer.xr.setFoveation(x)`). FFR only applies when rendering straight to the eye buffer:
  post-processing into an intermediate target, or switching render targets mid-frame, cancels it
  (and MSAA) (webxr-ffr).

## Lifecycle and input focus (VRC Functional.2, Input.4)

`XRSession.visibilityState` (WebXR spec):

| State | Rendering | Input | What to do |
|---|---|---|---|
| `visible` | normal rate | processed | normal |
| `visible-blurred` | may be throttled | **not processed** | keep rendering, hide or rest hands and controllers, pause single-player gameplay (Universal Menu is open) |
| `hidden` | rAF callbacks stop | not processed | pause; save state |

Listen on `session.addEventListener('visibilitychange', ...)`; in 2D pages use
`document.visibilitychange`. IWSDK exposes `world.visibilityState` (`hz-new-project-creation`
web reference). Also handle `inputsourceschange` (hands ↔ controllers, Input.7) and the
reference space `reset` event (recenter, Functional.9). Hand pinch arrives as `select` events.
Left palm pinch, like the left menu button, "takes the user out of the WebXR session"
(webxr-hands), so don't rely on the left menu button for an in-app menu.

## Test on a headset

```bash
metavr device list                                   # developer mode + USB, see hz-quest-verify-first
metavr adb reverse tcp:8081 tcp:8081                 # headset localhost:8081 -> dev machine
metavr device browser https://localhost:8081         # open it in Browser (IWSDK prints its port)
# DevTools: desktop Chrome -> chrome://inspect/#devices -> inspect the tab
metavr log --level E                                 # device log; hz-vr-debug has filtering recipes
```

- Same-network alternative: open `https://<LAN-IP>:<port>` and accept the local certificate.
  Corporate networks often block it; use `adb reverse` or Chrome's port forwarding in
  `chrome://inspect`. Full IWSDK walkthrough (certificates, reading the live session's frame rate
  and features, what only the headset proves): `iwsdk-quest-device-testing`.
- Installed PWA instead of a tab: `chrome://inspect` lists its tab once it runs (pwa-webxr FAQ).
- No headset: IWER inside the IWSDK dev server, or the **Immersive Web Emulator** extension for
  Chrome/Edge; Spector.js works only on desktop (webxr-workflow). Emulators miss performance,
  comfort and some input; always finish on hardware.
- VR Glasses before the hardware exists: IWER's `metaVRGlasses` profile (gaze + hands, view
  mask; IWER 2.5.0+), and on a Quest 3/3S/Pro `metavr device fov-sim enable` (70° × 66°;
  `--perceived` 58° × 54°; `disable` afterwards; ask first) (field-of-view, 2026-09-25).
  Walkthrough: `iwsdk-vr-glasses` §7.
- MQDH: ADB over Wi-Fi ("preferred" for Browser debugging), casting, screenshots, and Device
  Manager > Browser to send a URL (browser-mqdh).
- Meta's samples: immersive-web.github.io/webxr-samples (bare API, layers, hands, AR); Meta's
  sample pages: Project Flowerbed, Flap Frenzy, Chairs Etc., RealMeasure, Sneaker Builder, WebXR
  First Steps (React). Start new projects with `npm create @iwsdk@latest`.

## Performance: budgets and knobs

Frame budgets: 60 fps = 16.6 ms, 72 = 13.7 ms, 90 = 11.1 ms (webxr-perf-workflow). Meta gives no
WebXR-specific draw-call or triangle budgets. Use the native targets as an upper bound and expect
less: Quest 3 < 200 draw calls and < 1.5M triangles, Quest 2 < 100 and < 750K
(device-optimization-comparison, 2026-05-11). Browser adds "a small amount of additional
overhead" (webxr-perf-bp), and 1,000 single-triangle draw calls "would likely" drop below
72 fps (webxr-perf-workflow).

Work in this order (details in [performance.md](references/performance.md); for IWSDK's own
renderer settings and feature-flag costs use `iwsdk-performance`):

1. **Measure** on device: OVR Metrics Tool HUD; CPU frame time via `chrome://inspect` > trace
   with the `xr.debug` category; GPU via `ovrgpuprofiler`; RenderDoc Meta Fork for draw order.
2. **CPU or GPU bound?** Stop rendering: no change means CPU bound. GPU bound: set render scale to
   0.01; faster means fragment bound, unchanged means vertex bound.
3. CPU: merge meshes, instancing, multiview (Meta: CPU-bound apps often save 25-50% CPU), fewer
   state changes, stagger updates across frames; optimize any app logic that takes over 2 ms.
4. Fragment: front-to-back opaque order (fix sky domes), fewer lights and shadows, cheaper
   materials off hero objects, KTX2/Basis (or ETC/ASTC) textures, FFR, layers for static
   backgrounds, video and text, clear to black or white, render scale 0.8-0.9 only as a last
   resort.
5. Vertex: LODs, simpler meshes, split big meshes for culling, cull instanced meshes.

Space Warp needs a `chrome://flags` switch, so Store users won't have it; don't plan a game's
budget around it.

**Meta VR Glasses:** no WebXR or draw-call budget published. Device facts: up to 120 Hz;
render scale 1.0 = 1728 × 1760 per eye (Quest 3: 1680 × 1760); steady-state CPU/GPU level 4,
no GPU level 5; app memory limit 5.75 GiB PSS like Quest 3/3S; battery saver forces 72 Hz
(render-scale 2026-09-01, cpu-gpu-levels 2026-09-11, memory-ram 2026-08-31,
battery-saver-mode 2026-04-08). How Browser maps these to WebXR is unverified; start from the
Quest 3 numbers and measure.

## Sources

- https://developers.meta.com/horizon/documentation/web/ (2026-07-22), /webxr-overview/ (2026-07-21), /3d-web/ (2026-07-22), /2d-web/ (2026-09-04)
- https://developers.meta.com/horizon/documentation/web/browser-specs/ (2026-07-21), /browser-remote-debugging/ (2026-07-22), /browser-mqdh/; release notes now at https://developers.meta.com/vr/release-notes/?search_key=browser (152.1, 2026-10-02)
- https://developers.meta.com/horizon/documentation/web/webxr-mixed-reality/, /webxr-hands/, /webxr-layers/, /webxr-ffr/, /webxr-frames/, /web-multiview/, /webxr-space-warp/, /webxr-keyboard/, /webxr-pro-controller/, /webxr-workflow/ (undated)
- https://developers.meta.com/horizon/documentation/web/webxr-perf/ (2026-07-21), /webxr-perf-workflow/ (2026-07-21), /webxr-perf-bp/, /webxr-perf-tools/
- https://developers.meta.com/horizon/documentation/iwsdk/guides/02-testing-experience/, /11-scene-understanding/, /13-camera-access/ (2026-09-04), /14-environment-raycast/ (2026-07-22), /15-depth-occlusion/ (2026-09-04)
- https://developers.meta.com/horizon/resources/vrc-quest-performance-1/ (2025-10-22), /vrc-quest-performance-4/, /vrc-quest-input-4/ (2025-09-26), /vrc-quest-functional-2/
- https://developers.meta.com/horizon/resources/device-optimization-comparison/ (2026-05-11)
- https://immersive-web.github.io/webxr/ (XRVisibilityState, frameRate, updateTargetFrameRate)
- https://developers.meta.com/horizon/essentials/compare-devices/ (2026-09-30), /field-of-view/ (2026-09-25), /bring-your-app-glasses/ (2026-10-13), /horizon-os-input/ (2026-09-10), /fixed-foveated-rendering/ (2026-09-14), /render-scale/ (2026-09-01), /cpu-gpu-levels/ (2026-09-11), /memory-ram/ (2026-08-31), /battery-saver-mode/ (2026-04-08)
- https://developers.meta.com/horizon/design/eyes-best-practices/ (2026-10-13)
- https://developers.meta.com/horizon/documentation/iwsdk/guides/get-started-glasses/ (2026-09-04); npm `@iwsdk/core` 1.0.1 `dist/init/xr.js`; npm `iwer` 2.6.0 `lib/device/configs/headset/meta.js`

Last verified: 2026-10-17
