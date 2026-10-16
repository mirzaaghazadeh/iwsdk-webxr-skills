# Quest Browser WebXR feature notes

Each entry: how to request it, what Meta documents, and caveats. "Unverified" means no Meta page
confirms it; check with `metavr docs search "<feature> webxr"` and on a headset. Most per-feature
pages under /documentation/web/ carry no `last_updated` date; the hub pages were rewritten
2026-07-21/22. Fetched 2026-10-16.

## Session modes

- **`immersive-vr`**: the default IWSDK mode (`SessionMode.ImmersiveVR`).
- **`immersive-ar` (passthrough)** [webxr-mixed-reality]: render on a transparent background
  ("do not clear with an opaque color"); you can't read passthrough pixels. The page says
  passthrough is colour on Quest Pro and greyscale on Quest 2; it predates Quest 3/3S. IWSDK's
  "Mixed reality / passthrough" starter and its tutorials are verified on Quest 3 and 3S
  [IWSDK ch. 1, ch. 2].
- Installed immersive PWAs launch with `com.oculus.ossplash.background=passthrough-contextual`
  (Bubblewrap template), so an AR app can stay in passthrough from MR Home (VRC Functional.14).

## Input

- **Controllers**: `XRInputSource.gamepad` with the `xr-standard` mapping. Touch Pro reports
  profile `meta-quest-touch-pro` (fallback `oculus-touch-v2`) and 12 buttons: 0-5 as
  `xr-standard`, 6 thumb rest (with pressure), 7 stylus pressure, 8 trigger curl, 9 trigger
  slide, 10 trigger proximity, 11 thumb proximity [webxr-pro-controller]. Use
  `@webxr-input-profiles` models so only Meta hardware is shown (VRC Functional.6).
- **Hands** [webxr-hands]: request `'hand-tracking'` (WebXR Hand Input spec); 25 joints via
  `getJointPose` or `fillPoses`; the hand's `targetRaySpace` is an emulated ray matching Horizon
  Home; pinch is a gamepad button press and a `select` event. **Palm pinch is reserved** on both
  hands; left palm pinch equals the left menu button and exits the WebXR session. Meta hand models
  are in WebXR Input Profiles as `generic-hand`.
- **Pinch threshold**: `hz-iwsdk-webxr` says the reliable threshold is 0.7-0.8. Not on any Meta
  page (unverified).

## Reference spaces

- Use `local-floor` (or `local`) for 6DoF; never `viewer`-only for an interactive app (VRC
  Functional.5). `bounded-floor` and `unbounded` exist; Browser 146.0 fixed "WebXR bounded floor
  space issues" [release notes]; IWSDK's depth sample requests `unbounded` [IWSDK ch. 15].
- Handle `XRReferenceSpace` `reset` (WebXR spec) so content follows a recenter (Functional.9,
  Local tracking spaces).

## Mixed reality

- **Hit test** (`'hit-test'`): IWSDK's `EnvironmentRaycastSystem` uses it; works immediately,
  no room scan [IWSDK ch. 14].
- **Anchors** (`'anchors'`) [webxr-mixed-reality]: `createAnchor(pose, space)`; persistent with
  `anchor.requestPersistentHandle()` and `session.restorePersistentAnchor(handle)`. Limits: **8
  persistent anchors per site**; not persistent in private mode; clearing site history deletes
  them.
- **Plane detection** (`'plane-detection'`) [webxr-mixed-reality]: planes come from the user's
  Space Setup; Browser asks the user for permission; polygons are horizontal or vertical
  rectangles. `detectedPlanes` fills after a delay: wait 2-3 s; if empty call
  `session.initiateRoomCapture()` (once per session).
- **Mesh detection** (`'mesh-detection'`): IWSDK `SceneUnderstandingSystem` with
  `meshDetection: true`; IWSDK warns not all implementations support all features [IWSDK ch. 11].
  Which Quest devices return meshes in Browser: unverified.
- **Depth sensing** (`'depth-sensing'`): IWSDK requests `usage: 'gpu-optimized' | 'cpu-optimized'`
  and `format: 'float32' | 'luminance-alpha'` (WebXR spec dictionary: `usagePreference`,
  `dataFormatPreference`). `required: true` blocks the session on devices without depth
  [IWSDK ch. 15]. Browser 146.0: "Experimental WebGPU and WebXR depth projection support". Device
  list: unverified (depth sensors are a Quest 3-family feature natively).
- **Camera** (IWSDK `CameraSource` over MediaDevices): a permission prompt appears; streams stop
  when the page or session is hidden [IWSDK ch. 13]. Which physical cameras Browser exposes:
  unverified. Store builds: camera-type Android permissions are review-required.

## Rendering

- **Layers** (`'layers'`) [webxr-layers]: compositor layers sample once, so text, video and
  skyboxes look sharper and cost less. Media layers: `new XRMediaBinding(session)` then
  `createQuadLayer` / `createCylinderLayer` / `createEquirectLayer` with a `<video>`; cross-origin
  and streaming video work. Meta's example: GPU "Bus Busy" fell from 50.2% to 23.9% with layers.
  Polyfill for other browsers: immersive-web/webxr-layers-polyfill.
- **Fixed foveated rendering** [webxr-ffr]: at session start pass one of
  `'low-fixed-foveation-level'`, `'medium-fixed-foveation-level'`, `'high-fixed-foveation-level'`
  in `optionalFeatures`; or set `XRWebGLLayer.fixedFoveation` (0-1) at runtime. Verify with
  `adb shell ovrgpuprofiler -t`: the "stages" count should drop. Breaks with intermediate render
  targets or mid-frame render-target switches.
  - `hz-iwsdk-webxr` shows `session.fixedFoveatedRendering.level = 'high'`: **no Meta page
    documents that API**; use the two above.
- **Framebuffer scale**: `framebufferScaleFactor` in `XRWebGLLayerInit`; three.js
  `renderer.xr.setFramebufferScaleFactor()`; Babylon `canvasOptions` [webxr-perf-workflow].
- **Multiview** [web-multiview]: WebGL 2 only. `gl.getExtension('OCULUS_multiview')` is on by
  default and adds MSAA (`framebufferTextureMultisampleMultiviewOVR`); `OVR_multiview2` needs a
  flag. Use a projection layer with `textureType: 'texture-array'`; shaders become ES 3.00 with
  `#extension GL_OVR_multiview : require`, `layout(num_views=2) in;` and `gl_ViewID_OVR`. Meta:
  helps CPU-bound apps only. IWSDK already turns it on (super-three `multiviewStereo: true`; see
  `iwsdk-performance`), so IWSDK apps need no multiview code. Meta's sample: immersive-web.github.io/webxr-samples/layers-samples/proj-multiview.html.
- **Frame rate** [webxr-frames]: `session.frameRate`, `session.supportedFrameRates`,
  `session.updateTargetFrameRate(rate)` (Browser 16.4+). If frames take longer than the target
  (for example 11 ms at 90 Hz), pick a lower rate.
  - `hz-iwsdk-webxr` says Quest Browser "defaults to 72 Hz"; Meta's page says 90 on Quest 2.
    Read the value at runtime.
- **Space Warp** [webxr-space-warp]: draft Layers addition; Browser 24.2+; requires "WebXR Space
  Warp" enabled in `chrome://flags`; request `'layers'` and `'space-warp'`; projection layer
  `textureType: 'texture-array'`; render motion vectors (`EXT_color_buffer_half_float`, RGBA16F)
  and depth into the provided textures; set delta pose if the player moves. Fails with
  translucent objects; higher input latency. Check with `adb logcat -s VrApi` (FPS halves).
  - `hz-iwsdk-webxr` shows `navigator.xr.enableSpaceWarp(true)`: **not a documented API**.
- **WebGPU**: release notes list experimental WebGPU composition layers (152.1), foveation
  (150.1), Space Warp layers (149.1) and depth projection (146.0). No Meta guide yet: treat as
  experimental.

## UI and text

- **System keyboard** [webxr-keyboard]: Browser 26.1+; check `session.isSystemKeyboardSupported`;
  append an `<input>` to the DOM and call `focus()`; read `value` (no key events); each show
  starts a new editing session and the first key press overwrites the value; remove the element
  after the session.
- **2D pages**: no gaze hover; semantic `<button>` / `<a href>`; 48 × 48 CSS px targets [2d-web].

## Not documented for Quest Browser (as of 2026-10-16)

`dom-overlay`, `light-estimation`, `secondary-views`, raw camera access via `XRView.camera`, and
eye tracking in WebXR: no Meta web page found. Unverified: detect at runtime and test.
