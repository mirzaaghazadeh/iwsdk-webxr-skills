# Meta VR Glasses for web and IWSDK developers (reference)

Condensed for agents. Checked 2026-10-17. Every row ends with a source tag; the tags resolve to a
URL and that page's `last_updated` date in [Sources](#sources). Facts are paraphrased, not copied.
"Unverified" means no Meta page or package source confirms it.

**Status:** announced at Connect (2026-09-23/24); hardware ships **spring 2027**; the v207 SDKs
for Unity, Unreal, Android and Web, plus simulators, are out now [B1][B2]. Until then, test on a
Quest 3 / 3S (or Quest Pro for FoV simulation) and in IWER [E1][E3].

## 1. Device facts that change web apps

| Item | Meta VR Glasses | Quest 3 (for contrast) | Src |
|---|---|---|---|
| Form factor | Light glasses tethered to a compute puck (USB-C on the puck) | All-in-one headset | E2 |
| OS | Meta Horizon OS (same OS, Store and SDKs as Quest) | same | E2, B2 |
| Primary input | **Eyes (gaze) + hands**; ships without controllers; Touch Plus sold separately | Touch Plus in box + hands | E2, E4 |
| Eye tracking | Yes (Quest 3/3S have none; Quest Pro has it) | No | E2, E14 |
| Display | micro-OLED, 2412 × 2288 px per eye, 37 PPD, up to 120 Hz | LCD, 2064 × 2208, 25 PPD, 120 Hz | E2 |
| Field of view (nominal) | **70° H × 66° V** (an upper bound; fit and gaze direction shrink it) | 110° × 96° | E2, E3 |
| Per-eye render extent | 74° × 68°; IWER's profile measures it as 37°/37° horizontal, **25° up / 43° down** | n/a | E3, S5 |
| Perceived p90 FoV (test target) | 58° × 54° | n/a | E3 |
| Render scale 1.0 resolution | 1728 × 1760 per eye; no single scale matches the panel; Meta recommends dynamic resolution | 1680 × 1760 | E5 |
| Chipset / RAM | Snapdragon XR2 Gen 3 / 12 GB | XR2 Gen 2 / 8 GB | E2 |
| App memory kill limit (PSS) | 5.75 GiB (same as Quest 3/3S) | 5.75 GiB | E6 |
| Passthrough | Colour stereo, 26 PPD, autofocus, depth sensing | Colour, 18 PPD, depth sensor | E2 |
| Face tracking for apps | None camera-based (Audio To Expressions only) | Audio To Expressions | E2 |
| Android | 14 | 14 | E2 |

## 2. Input model

| Fact | Src |
|---|---|
| Targeting = gaze; selection = hand pinch. Map controller actions: ray → eye or hand ray; trigger/grip → pinch, poke or palm grab; hold → pinch and hold; drag → pinch and drag; thumbstick scroll → swipe or pinch-drag; thumbstick locomotion → teleport | E4 |
| A controller-required **immersive** app installs, but a **Switch to Controllers** dialog blocks entry until controllers are active. Don't assume users own controllers | E4, E7 |
| Microgestures (thumb tap, swipes) are discrete: no magnitude, so use pinch-drag for continuous input | E4 |
| When eye tracking is unavailable or drops, the platform falls back to hand/controller rays, and to head gaze only if neither is tracked | D1 |
| Web content in Browser gets **no gaze hover events**: no `:hover`, no pointer events from looking. The system draws hover. Build controls from `<button>`, `<a href>` or focusable ARIA roles; a click-listener `<div>` may not be a target | W1, D1, B1 |
| Gaze target minimum: **3° of visual angle**. Web in Browser: **56 × 56 CSS px** (eyes best practices, 2026-10-13); the older 2d-web page (2026-09-04) still says 48 × 48 | D1, W1 |
| World-space size for 3°: `2 × d × tan(1.5°)` ≈ 5.2 cm at 1 m | D1 |
| Platform gaze cone half-angle 2.0°; targets resolve by angle before distance; a short consensus window stabilises the target; gaze never activates by dwelling | D2 |
| Hover feedback: subtle colour/opacity/scale of the content, don't move or resize the target, no outline strokes; hover-off slower than hover-on (colour 300/400 ms; motion 475 ms after 150 ms delay / 625 ms); press 80 ms, release 100 ms | D1 |
| Provide an explicit close button; "click empty space to dismiss" is hard with gaze | D1 |

## 3. Browser and WebXR on the device

| Fact | Status | Src |
|---|---|---|
| A browser runs on the device; the Connect web session covers "adapting existing sites for the Meta VR Glasses browser" | Documented (session blurb only) | V1 |
| UA device token for VR Glasses | **Unverified**: browser-specs (2026-07-21) lists Quest tokens only. Use feature detection, never the UA | W2 |
| Supported WebXR features (passthrough, hit test, anchors, planes, meshes, depth, layers) | **Unverified on VR Glasses**: no Meta web page mentions the device. Meta says passthrough and hand tracking exist on all its devices | E2, W3 |
| Eye gaze in WebXR | IWSDK requests the `'gaze-tracking'` session feature (its source says this is the name Quest Browser accepts and the one that yields an `XRInputSource` with `targetRayMode === 'gaze'`) and also offers the W3C draft name `'eye-tracking'` as optional | S3 |
| Refresh rates | Display max 120 Hz [E2]. VRC Performance.1 allows 72/80/90/96/100/120 Hz with ≥ 60 fps rendered [R2]. IWER's glasses profile reports `[72, 90, 96, 100, 120]`: emulator data, not a Browser guarantee | E2, R2, S5 |
| Browser release notes | No VR Glasses entry through 152.1 (2026-10-02) | W4 |
| Eye-tracked foveated rendering | Supported on the device, but Meta lists no public ETFR route for Web | E8, E9 |

## 4. Performance (no WebXR-specific numbers exist)

| Fact | Src |
|---|---|
| Steady state: CPU and GPU level 4. GPU level 5, dual-core mode and CPU/GPU trading are unavailable; CPU Boost can briefly reach level 8 | E10, E11 |
| Passthrough can lower available performance levels | E10 |
| Thermals are managed in separate domains for the glasses and the puck; test sustained runs (content length or 45 min) with the puck vents clear | E12, E9 |
| Battery saver: refresh drops to 72 Hz, FFR level 3, boosts off | E13 |
| Native draw-call/triangle targets cover Quest 2/3 only; none published for VR Glasses | R1 |
| Engine levers (CPU/GPU hints, dynamic resolution, ETFR) are native-API features; how Quest Browser applies them to WebXR is **unverified** | E5, E10 |

## 5. Testing without the device

| Tool | What it does | Src |
|---|---|---|
| IWER `metaVRGlasses` profile (`dev.emulator.device` in `iwsdk.config.json`, IWSDK 1.0.0+) | Quest 3 capabilities plus the glasses' asymmetric view mask; adds a gaze source. Toolbar: **Gaze + Hands** (hands + cursor gaze), gaze mode Off / Cursor / Head, commit hand (right by default), FoV-mask toggle | S1, S5, I2 |
| Cursor-gaze controls | Pointer aims gaze; hold left mouse = pinch with commit hand; drag moves the hand; wheel = hand depth; right-drag rotates the head; Space resets the hand. Pointer-lock play mode is off while cursor gaze is on | I2 |
| CLI / MCP automation | Aim `gaze` with `xr look-at` / `set-transform` / `animate-to` (orientation only; move the headset to move its origin). Pinch through `hand-left`/`hand-right` with `xr select` or `xr set-select-value`; the `gaze` device takes no select or gamepad calls. `xr set-connected` on `gaze` tests the fallback | I2, S1 |
| Headset preview (IWSDK 1.0.1) | `dev.targetDevicePreview.gazeSimulation: "head"` adds a head-directed test gaze source to the native Quest Browser session when the app requests gaze; dev server only, stripped from builds; checks plumbing, not eye accuracy | S1 |
| Device FoV simulation | `metavr device fov-sim enable` (70 × 66), `--perceived` (58 × 54), `disable`. Quest 3 / 3S / Pro, developer mode. Resets on reboot; re-don the headset if it doesn't apply. Before Horizon OS v209 it does not clip compositor layers (WebXR layers). Casts/screenshots show the crop only on v209+ | E3, S6 |
| Immersive Web Emulator extension | Recap says it supports the glasses input model and FoV; the extension source in the IWER repo has a `metaVRGlasses` device. Whether the store-published build has it: **unverified** | B1, S5 |

## 6. Meta's hosted IWSDK docs vs the published packages

Meta's IWSDK pages were generated from IWSDK **0.5.3**; npm `latest` is **1.0.1** (`next`:
1.1.0-rc.1). For VR Glasses config, follow the package, not the hosted page:

| Meta-hosted page says | IWSDK 1.0.1 and 1.1.0-rc.1 actually | Src |
|---|---|---|
| `world.features.fieldOfViewMask: true` turns on a FoV mask, also on a real Quest | No such key in the manifest types, schema or validator; unknown keys fail `iwsdk.config.json` validation. Use the IWER profile on desktop and `metavr device fov-sim` on a Quest | I1, I2, S2 |
| Without a usable gaze pose IWSDK "falls back to head pointing" (amber reticle) | "IWSDK does not silently replace missing production gaze with head pose"; hand/controller far rays resume; head gaze only via explicit dev preview | I1, I3, S1 |
| Gaze tuning key `suppressWhenHandPointerActive` | `suppressWhenDirectPointerActive` (the other name fails validation) | I3, S2 |
| `iwsdk-runtime` exposes 45 tools (also on the AI tools page; the IWSDK product page says 32) | 1.0.1 lists 55: 50 app/editor tools + 5 `runtime_*` control tools | I4, S4 |

## 7. Store pointers (owned by the store skills)

- Build targeting: **All Devices** includes VR Glasses; `quest3+` in
  `com.meta.store.defaultDeviceTargets` covers the Quest 3 family, VR Glasses and future devices;
  "Future devices" marks a build forward-compatible. Targeting controls delivery, not
  compatibility [R3, E7]. Details: `horizon-web-store-publish`, `horizon-web-vrc-checklist`.
- Apps must ship 64-bit native code [E7]. Whether a Bubblewrap TWA APK passes the glasses'
  checks is **unverified**; list its `lib/` folders.
- Input declaration: `oculus.software.handtracking` `required="false"` plus
  `com.oculus.permission.HAND_TRACKING` means "controllers and hands" [E7]. Bubblewrap's Quest
  template (1.24.1) always writes exactly that, so every TWA claims hand support: make sure
  the app really works with hands.

## Sources

`/horizon/…` page URLs 302-redirect to `/vr/…` (checked 2026-10-17); both work. Markdown twins:
`https://developers.meta.com/vr/llmstxt/<path>.md`.

| Tag | URL | Last updated |
|---|---|---|
| B1 | https://developers.meta.com/blog/meta-connect-recap/ | post 2026-09-24 |
| B2 | https://developers.meta.com/blog/meta-connect-recap-start-building-the-future-of-vr/ | post 2026-09-24 |
| V1 | https://developers.meta.com/resources/videos/building-immersive-experiences-with-webxr/ | session 2026-09-24 |
| E1 | https://developers.meta.com/horizon/essentials/get-started-with-glasses/ | 2026-10-13 |
| E2 | https://developers.meta.com/horizon/essentials/compare-devices/ | 2026-09-30 |
| E3 | https://developers.meta.com/horizon/essentials/field-of-view/ | 2026-09-25 |
| E4 | https://developers.meta.com/horizon/essentials/bring-your-app-glasses/ | 2026-10-13 |
| E5 | https://developers.meta.com/horizon/essentials/render-scale/ | 2026-09-01 |
| E6 | https://developers.meta.com/horizon/essentials/memory-ram/ | 2026-08-31 |
| E7 | https://developers.meta.com/horizon/essentials/app-compatibility/ | 2026-10-13 |
| E8 | https://developers.meta.com/horizon/essentials/fixed-foveated-rendering/ | 2026-09-14 |
| E9 | https://developers.meta.com/horizon/essentials/test-your-app/ | 2026-09-25 |
| E10 | https://developers.meta.com/horizon/essentials/cpu-gpu-levels/ | 2026-09-11 |
| E11 | https://developers.meta.com/horizon/essentials/boost-cpu-gpu-levels/ | 2026-09-11 |
| E12 | https://developers.meta.com/horizon/essentials/thermal/ | 2026-09-15 |
| E13 | https://developers.meta.com/horizon/essentials/battery-saver-mode/ | 2026-04-08 |
| E14 | https://developers.meta.com/horizon/essentials/horizon-os-input/ | 2026-09-10 |
| D1 | https://developers.meta.com/horizon/design/eyes-best-practices/ | 2026-10-13 |
| D2 | https://developers.meta.com/horizon/design/gaze_specs/ | 2026-10-13 |
| W1 | https://developers.meta.com/horizon/documentation/web/2d-web/ | 2026-09-04 |
| W2 | https://developers.meta.com/horizon/documentation/web/browser-specs/ | 2026-07-21 |
| W3 | https://developers.meta.com/horizon/documentation/web/webxr-mixed-reality/ | undated |
| W4 | https://developers.meta.com/vr/release-notes/?search_key=browser (the old `/documentation/web/browser-release-notes/` redirects here) | undated (152.1 = 2026-10-02) |
| I1 | https://developers.meta.com/horizon/documentation/iwsdk/guides/get-started-glasses/ | 2026-09-04 |
| I2 | https://developers.meta.com/horizon/documentation/iwsdk/guides/02-testing-experience/ | 2026-09-04 |
| I3 | https://developers.meta.com/horizon/documentation/iwsdk/guides/06-built-in-interactions/ | 2026-09-04 |
| I4 | https://developers.meta.com/horizon/documentation/iwsdk/ai/mcp-tools/, https://developers.meta.com/vr/discover/ai-tools/, https://developers.meta.com/vr/develop/iwsdk/ | 2026-09-04 / undated / undated |
| R1 | https://developers.meta.com/horizon/resources/device-optimization-comparison/ | 2026-05-11 |
| R2 | https://developers.meta.com/horizon/resources/vrc-quest-performance-1/ | 2025-10-22 |
| R3 | https://developers.meta.com/horizon/resources/publish-release-channels-device-targeting/ | 2026-09-04 |
| S1 | IWSDK 1.0.1 `docs/concepts/xr-input/gaze.md`, `docs/guides/02-testing-experience.md` (github.com/facebook/immersive-web-sdk @ `0778f518`) = https://iwsdk.dev/concepts/xr-input/gaze.html | commit 2026-10-01 |
| S2 | npm `@iwsdk/core` 1.0.1 and 1.1.0-rc.1: `dist/project/types.d.ts`, `dist/project/validation.js`, `dist/schemas/iwsdk-project.v1.schema.json` | 2026-10-01 / 2026-10-13 |
| S3 | npm `@iwsdk/core` 1.0.1 `dist/init/xr.js` (`buildSessionInit`) | 2026-10-01 |
| S4 | npm `@iwsdk/cli` 1.0.1 `dist/cli.js` (`RUNTIME_MCP_TOOLS`, the `tools/list` handler) | 2026-10-01 |
| S5 | npm `iwer` 2.6.0 `lib/device/configs/headset/meta.js`; github.com/meta-quest/immersive-web-emulation-runtime `docs/getting-started.md`, `packages/extension/src/agent/prefs.ts` (IWER 2.5.0 added the profile, 2026-09-24) | 2026-10-13 |
| S6 | `docs/metavr-cli-reference.md` in this library (`metavr device fov-sim`) | metavr 1.8.1 |

Package sources were read from the npm tarballs; nothing was installed or executed.
