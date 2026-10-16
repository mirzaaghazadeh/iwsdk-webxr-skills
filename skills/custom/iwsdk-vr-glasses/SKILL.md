---
name: iwsdk-vr-glasses
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.0.0"
description: >-
  Makes an IWSDK WebXR app ready for Meta VR Glasses (the controller-free,
  eyes-and-hands Horizon OS device from Connect 2026, shipping spring 2027):
  picks the input plan, writes IWSDK 1.0.1 config that validates
  (`gazeTracking`, `dev.emulator.device: metaVRGlasses`,
  `dev.targetDevicePreview`; not the `fieldOfViewMask` key on Meta's hosted
  page), wires gaze targeting with pinch selection via RayInteractable and
  DistanceGrabbable, sizes targets to 3 degrees, replaces controller-only
  locomotion and menus, fits UI into the 70 x 66 degree view, and tests with
  IWER's Gaze + Hands mode, CLI gaze automation, a head-gaze preview on Quest
  3 and `metavr device fov-sim`. Use when the user mentions Meta VR Glasses,
  VR glasses, gaze and pinch, eye tracking in WebXR, look and pinch,
  controller-free or hands-only play, "make it work without controllers", the
  Switch to Controllers dialog, a narrower field of view, `metaVRGlasses`,
  `gazeTracking`, `fov-sim`, or porting a Quest WebXR game to the device.
---

# Getting an IWSDK app ready for Meta VR Glasses

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

Meta VR Glasses run Horizon OS with the same Store and SDKs as Quest, but users aim with their
**eyes**, select with a **hand pinch**, usually have **no controllers**, and see a **70° × 66°**
view (Quest 3: 110° × 96°). Hardware ships in spring 2027; until then you build on a Quest 3/3S
and in the IWER emulator. Facts, numbers and sources: `docs/meta-reference/web-vr-glasses.md`
in this library.

Hand-offs: feature code → **`iwsdk-dev`** first, then `iwsdk-ray` / `iwsdk-grab` / `iwsdk-ui`;
headset routine → **`iwsdk-quest-device-testing`**; frame rate → **`iwsdk-performance`**;
packaging and device targeting → **`horizon-web-store-publish`**; Browser feature support →
**`quest-browser-webxr`**.

## Ground rules

- **Take config keys from the installed package**, not from Meta's hosted IWSDK pages. Those
  pages describe IWSDK 0.5.3 and show two keys (`world.features.fieldOfViewMask`,
  `gaze.suppressWhenHandPointerActive`) that IWSDK 1.0.1 rejects as unknown. Check
  `node_modules/@iwsdk/core/dist/project/types.d.ts` when unsure.
- **Gaze needs IWSDK 1.0.0 or later** (`npm ls @iwsdk/core`). On 0.x, upgrade first
  (`iwsdk-project-setup`; 0.4 projects go through `iwsdk-migrate-0-5`).
- **Ask before** `metavr device fov-sim enable` (it changes a headset setting until disabled or
  rebooted) and before adding controller-free modes that change gameplay.
- Never ship dev-only emulator settings. IWSDK's `examples/gaze-pinch` uses
  `activation: "always"` and `injectOnBuild: true` for its hosted demo; a Store build keeps the
  defaults (`localhost`, `false`).
- Simulators prove plumbing, not comfort or eye accuracy. Say so in reports.

## 1. Choose the input plan

| Plan | What VR Glasses users get | Work |
|---|---|---|
| Controllers required | App installs; immersive launch shows **Switch to Controllers** and blocks entry until controllers are active. Many users have none | None, but you lose most of the audience |
| Controllers optional (recommended for a Quest port) | Every required flow works with eyes + hands; controllers still work | Sections 2-6 |
| Hands and eyes only | Same as above, no controller code paths | Sections 2-6; still handle a controller appearing |

Meta's mapping from controller to eyes and hands: ray → eye or hand ray; trigger/grip → pinch
(or poke, palm grab); hold → pinch and hold; drag → pinch and drag; thumbstick scroll → swipe or
pinch-drag; thumbstick locomotion → teleport.

## 2. Configure (IWSDK 1.0.1)

Merge into `iwsdk.config.json` (Vite restarts on save):

```json
{
  "world": {
    "xr": {
      "mode": "vr",
      "features": {
        "handTracking": { "required": true },
        "gazeTracking": true
      }
    },
    "features": {
      "grabbing": { "useHandPinchForGrab": true },
      "gaze": { "showDebugReticle": false }
    }
  },
  "dev": {
    "emulator": { "device": "metaVRGlasses" },
    "targetDevicePreview": { "gazeSimulation": "head" }
  }
}
```

| Key | Meaning |
|---|---|
| `xr.features.gazeTracking: true` | Requests the `'gaze-tracking'` WebXR feature as optional (IWSDK also offers `'eye-tracking'`) and registers `GazeSystem`. `{ "required": true }` makes the whole session fail on any runtime that doesn't grant gaze (expect that on Quest 3/3S, which have no eye tracking): avoid. `eyeTracking` is a deprecated alias |
| `handTracking: { "required": true }` | What IWSDK's gaze example and Meta's guide use, since pinch comes from hands. If the app also supports controller-only play, use `true` (optional) instead |
| `features.grabbing.useHandPinchForGrab` | Default `false`: near grabs (`OneHandGrabbable`, `TwoHandsGrabbable`) wait for a squeeze button. `true` forwards hand pinch as squeeze (GrabSystem docs) |
| `dev.emulator.device: "metaVRGlasses"` | Desktop IWER profile: Quest 3 capabilities, the glasses' view mask, a gaze source. Desktop only |
| `dev.targetDevicePreview.gazeSimulation: "head"` | On a real Quest, adds a head-directed test gaze source when the app requests gaze. Dev server only; stripped from builds; needs `dev.emulator.iwer` left on. `false` turns it off |
| `features.gaze.*` | Tuning only, never enables gaze: `coneAngle` 5 (half-angle, degrees), `maxRayLength` 30 m, `dwellWindowSeconds` 0.15, `filterMinCutoff` 1.5, `filterBeta` 0.05, `trackingLossGraceSeconds` 5, `suppressWhenDirectPointerActive` true, `pointerTransformFollowsHand` true, `logDiagnostics` true, `showDebugReticle` false |

Meta's platform gaze cone is a 2.0° half-angle; IWSDK's default is 5°. Leave the default unless
on-device tests show wrong targets on a dense panel, and change one value at a time.

Then confirm the manifest loads: `npx @iwsdk/cli dev status` (no restart loop) and
`npx @iwsdk/cli dev logs --tail 50` (no `unknown property` errors).

## 3. Make interactions gaze-ready

Gaze is one session-wide ray pointer. It picks the target; a pinch from either hand selects.
It uses the normal ray-pointer path, so **no gaze-specific components or events**:

- Selectable things: `RayInteractable`, react to the `Hovered` / `Pressed` tags (or Three.js
  pointer events). Gaze reports `pointerType === 'ray'` with pointer state `source: 'gaze'`.
- Pick-up-at-a-distance: `DistanceGrabbable` (look, pinch, move). With `MoveAtSource` the object
  follows the pinching hand's movement without snapping to it. One grab component per entity.
- Near interaction still wins: an active touch or grab suppresses gaze, so poke buttons and
  hand grabs keep working.
- To accept hand rays but refuse gaze on one target, filter on the pointer state
  (`examples/gaze-pinch` and the IWSDK gaze concept page show a `pointerEventsType` predicate).
- Fallback order in IWSDK: valid gaze owns far targeting; a briefly invalid pose keeps ownership
  for `trackingLossGraceSeconds`; a disconnected gaze source hands far targeting back to hand and
  controller rays. IWSDK never silently swaps in head pose.

Design rules from Meta's eyes guidance (`hz-immersive-designer` has general comfort rules):

| Rule | Value |
|---|---|
| Minimum target size | **3°** of visual angle: `2 × d × tan(1.5°)`. 0.75 m → 3.9 cm, 1 m → 5.2 cm, 1.5 m → 7.9 cm, 2 m → 10.5 cm. UIKit units are centimetres, so a button at 1 m needs width and height ≥ 5.2 |
| Layout | Primary actions near the centre of the panel and of the view; buttons in one row or column, not 2D clusters; no small targets at the view edge |
| Hover | Production gaze has **no cursor**: give every target its own subtle hover (colour/opacity, or scale the content, not the container); never move, resize or reflow on hover; no outlines; no hover-to-reveal menus |
| Timing | Hover-on colour 300 ms, off 400 ms; motion on 475 ms after a 150 ms delay, off 625 ms; press 80 ms, release 100 ms |
| Activation | Only on pinch. Dwell must never activate |
| Dismissal | A visible close button; not "pinch empty space to close" |

2D DOM UI (overlays outside XR, React/Preact HUDs, 2D PWA pages): the page gets no gaze hover at
all, so build controls from `<button>` / `<a href>` (or focusable ARIA roles), never rely on
`:hover`, and size them at least **56 × 56 CSS px** (Meta's 2026-10-13 guidance; an older page
says 48).

## 4. Replace controller-only features

| On Quest you used | For VR Glasses | IWSDK 1.0.1 notes |
|---|---|---|
| Thumbstick slide locomotion | Teleport, or a stationary design | IWSDK teleport is controller-only by default. With the right hand as primary input, a swipe up turns on its micro-gesture mode (turn and teleport by gesture), a swipe down turns it off. Whether the glasses' browser reports those gestures: **unverified**; test it, and tell players the gesture |
| Snap turn on the stick | Micro-gesture turn, or physical turning | Same mode as above |
| Menu / B button for the in-app menu | A visible in-app menu target (world-space or `Follower`) | Left palm pinch is the system gesture and leaves the session (Meta WebXR hands page) |
| Trigger to shoot / select | Gaze + pinch on a target; or a hand ray | `RayInteractable` handles both |
| Squeeze to grab | Pinch (`useHandPinchForGrab: true`) or `DistanceGrabbable` | |
| Haptics | Audio and visual feedback | No controller, no haptics |
| Text entry | Focus an HTML `<input>` to open the system keyboard (`quest-browser-webxr`) | Keyboard on VR Glasses: **unverified** |

Build the replacement with **`iwsdk-dev`** (it owns code changes), then prove each flow with
hands only (section 7).

## 5. Fit the view

- Nominal view **70° × 66°**, treated as an upper bound; Meta's perceived (p90) test target is
  **58° × 54°**. The rendered extent is 74° × 68° and **asymmetric: 25° above, 43° below** the
  optical axis (IWER profile, sampled from the device's projection matrices). Content above eye
  level clips first, so seat panels at or slightly below eye height.
- Keep primary actions and status in the centre; give any edge-only action a second route.
- Place UI in the world or with `Follower` (`PivotY`, small `offsetPosition`); avoid parenting
  panels to `world.playerHeadEntity`. `ScreenSpace` is browser-only, not an XR HUD.
- Judge size by angle (`2 × atan(w / (2 × d))`), never by display pixels; let IWSDK use the
  per-eye `XRView` projection (don't hard-code a FoV).
- WebXR layers (`XRQuadLayer`, `XRCylinderLayer`) are composited separately: check them on a
  headset; `fov-sim` only clips them on Horizon OS v209+.
- Check the first view after launch and after a recenter, menus, captions, error messages, and
  targets near each edge (Meta's VR Glasses test list).

## 6. Performance

Meta publishes no WebXR or draw-call budget for VR Glasses. Plan from the Quest 3 numbers in
`iwsdk-performance` and measure. Known device facts: up to 120 Hz display; render scale 1.0 is
1728 × 1760 per eye (about 3% more pixels than Quest 3 at 1.0); steady state CPU/GPU level 4
with no GPU level 5; passthrough can lower available levels; battery saver forces 72 Hz and
FFR; heat is managed separately for glasses and puck. Read `session.frameRate` and
`supportedFrameRates` at runtime instead of assuming a rate (probe in
`iwsdk-quest-device-testing` §4).

## 7. Test

**Desktop (IWER, no headset)**

1. `dev.emulator.device: "metaVRGlasses"`, `npm run dev`, Enter XR.
2. IWER toolbar → **Select input mode** → **Gaze + Hands**. Move the pointer to aim; hold the
   left mouse button to pinch with the commit hand (right by default); drag to move the hand;
   wheel for depth; right-drag to turn the head; Space resets the hand. Pointer-lock play mode
   is off in cursor-gaze mode.
3. **Configure gaze emulation**: Off (check hand rays take over), Cursor, Head (diagnostic only).
4. Toggle the **field-of-view mask** to compare clipped and full views.

**Automated (CLI, same as MCP `xr_*` tools)**

```bash
cli() { npx @iwsdk/cli "$@"; }
cli xr enter
cli xr set-input-mode --input-json '{"mode":"hand"}'
cli xr look-at --input-json '{"device":"gaze","target":{"x":0,"y":1.2,"z":-2}}'
cli xr select --input-json '{"device":"hand-right"}'        # pinch; the gaze device takes no select
# assert with ECS: the target gained Pressed / your state changed (iwsdk-testing §4)
cli xr set-connected --input-json '{"device":"gaze","connected":false}'   # fallback path
```

Gaze is pose-only: aim it with `look-at`, `set-transform` (orientation only) or `animate-to`;
move its origin by moving `headset`. Use `set-select-value` for hold-move-release grabs.

**On a Quest 3 / 3S** (`iwsdk-quest-device-testing` for connection and DevTools)

1. Keep `targetDevicePreview.gazeSimulation: "head"`; the console shows `[iwsdk][gaze]` lines
   telling granted / missing / invalid / head-mapped gaze apart.
2. With the user's OK: `metavr device fov-sim enable` (or `--perceived`), relaunch or re-don
   the headset, test, then `metavr device fov-sim disable`. Quest Pro also supports `fov-sim`
   and has eye-tracking hardware; whether its Browser grants `gaze-tracking` is unverified.
3. Put the controllers down and complete **every** required flow with hands: start, menus,
   dialogs, scrolling, grabbing, locomotion, pause, exit. No controller prompt should appear.
4. Pick the controllers up mid-session and put them down again: focus, held objects and open
   dialogs must stay valid.
5. Heaviest scene for the content length or 45 minutes at a supported refresh rate.

**Only the device will prove** (spring 2027): eye-tracking accuracy, puck heat and placement,
optics and layer composition, Store install on the glasses.

## 8. Ship

Same PWA pipeline (`horizon-web-store-publish`). Device targeting decides delivery, not
compatibility: **All Devices** and the `quest3+` specifier include VR Glasses, and **Future
devices** marks a build forward-compatible. Meta also requires 64-bit native code; list the APK's
`lib/` folders (`unzip -l app-release-signed.apk | grep '/lib/'`) and flag anything only under
`armeabi-v7a`. Bubblewrap's Quest template declares hand tracking as optional with the
`HAND_TRACKING` permission, which Meta reads as "controllers and hands". VRC audit:
`horizon-web-vrc-checklist`.

## Not verified yet

- Which WebXR features, UA token and window sizes the VR Glasses browser has; whether its gaze
  input source also fires `select` itself (IWSDK takes select from hands only).
- Whether hand micro-gestures reach WebXR on the device (IWSDK's micro-gesture locomotion).
- Whether an immersive PWA on the glasses shows the Switch to Controllers dialog, and whether a
  Bubblewrap APK passes the 64-bit check.
- Whether the Chrome Web Store build of the Immersive Web Emulator already has the
  `metaVRGlasses` device (its source does).
- Real refresh rates in Browser on the glasses (IWER's profile lists 72/90/96/100/120; that is
  emulator data).

## Sources

- https://developers.meta.com/horizon/essentials/get-started-with-glasses/ (2026-10-13), /bring-your-app-glasses/ (2026-10-13), /app-compatibility/ (2026-10-13), /compare-devices/ (2026-09-30), /field-of-view/ (2026-09-25), /test-your-app/ (2026-09-25), /render-scale/ (2026-09-01), /cpu-gpu-levels/ (2026-09-11), /thermal/ (2026-09-15), /battery-saver-mode/ (2026-04-08)
- https://developers.meta.com/horizon/design/eyes-best-practices/ (2026-10-13), /gaze_specs/ (2026-10-13)
- https://developers.meta.com/horizon/documentation/web/2d-web/ (2026-09-04), /webxr-hands/ (undated)
- https://developers.meta.com/horizon/documentation/iwsdk/guides/get-started-glasses/, /02-testing-experience/, /06-built-in-interactions/ (2026-09-04; IWSDK 0.5.3 era, see `docs/meta-reference/web-iwsdk-docs-on-meta.md`), /concepts/spatial-ui/uikit/ (UIKit units are centimetres)
- https://developers.meta.com/horizon/resources/publish-release-channels-device-targeting/ (2026-09-04)
- https://developers.meta.com/blog/meta-connect-recap-start-building-the-future-of-vr/ (2026-09-24)
- https://github.com/facebook/immersive-web-sdk @ `0778f518` (1.0.1): `docs/concepts/xr-input/gaze.md`, `docs/guides/02-testing-experience.md`, `docs/concepts/locomotion/teleport.md`, `docs/concepts/spatial-ui/hud.md`, `examples/gaze-pinch/`
- npm `@iwsdk/core` 1.0.1: `dist/project/types.d.ts`, `dist/project/validation.js`, `dist/init/xr.js`, `dist/grab/grab-system.d.ts`, `dist/locomotion/locomotion.js`
- npm `iwer` 2.6.0: `lib/device/configs/headset/meta.js`
- `docs/metavr-cli-reference.md` in this library (`metavr device fov-sim`)

Last verified: 2026-10-17
