# Older or unverified performance advice

Checked on 2026-10-16 against IWSDK 1.0.1 source (`facebook/immersive-web-sdk@0778f518`),
super-three 0.181.0 (`src/renderers/webxr/WebXRManager.js`) and Meta's WebXR docs. Much of this
comes from guides written for IWSDK 0.4 or for generic WebXR, including Meta's own
`hz-iwsdk-webxr` skill (`meta-quest/agentic-tools@3a8553d`, `references/performance-tips.md`
and `SKILL.md` "Gotchas").

| Advice you may see | Status | Use instead |
|---|---|---|
| `session.fixedFoveatedRendering.level = 'high'` | No such API in Meta's FFR page or the IWSDK/super-three source | `world.renderer.xr.setFoveation(0..1)`; it sets `fixedFoveation` on the projection layer. Default is already `1.0` (maximum) |
| `navigator.xr.enableSpaceWarp(true)` | Not an API. Meta's real **WebXR Space Warp** is experimental: Quest Browser 24.2+, a `chrome://flags` switch, the `"layers"` + `"space-warp"` session features, a `texture-array` projection layer, and app-rendered motion vectors and depth | No support in IWSDK 1.0.1 or super-three 0.181.0 (no `space-warp` feature, no motion-vector pass). Treat as out of scope |
| `renderer.xr.useMultiview = true` / call `gl.getExtension('OCULUS_multiview')` yourself | Unneeded: IWSDK creates the renderer with `multiviewStereo: true` and super-three turns on `OCULUS_multiview` with a projection layer automatically | Check `world.renderer.xr.isMultiview` in XR |
| "Quest Browser defaults to 72 Hz; call `updateTargetFrameRate(90)`" | Meta's frame-rate page says 72 on the original Quest and 90 on Quest 2; nothing for Quest 3/3S. `updateTargetFrameRate` must use a value from `supportedFrameRates` | Read `session.frameRate` / `supportedFrameRates` on the device; raise only with headroom |
| "Under 50-80 draw calls on Quest 2, 100-120 on Quest 3", "under 100 draw calls", "750K triangles per eye" | No Meta WebXR source found | Meta's device comparison page (Quest 2 < 100 draw calls / < 750K triangles, Quest 3 < 200 / < 1.5M; SKILL.md §1) as upper bounds, plus "1,000 individual draw calls likely < 72 FPS" from the WebXR workflow page; measure |
| "Keep total texture memory under 256 MB" | No Meta source found | Compress to KTX2, cap texture size (2048 is `gltf-transform optimize`'s default), check `renderer.info.memory.textures` and device stability |
| "Hand-tracking pinch threshold 0.7-0.8" | No Meta source found | Use IWSDK's input components (`RayInteractable`, grab components, `world.input.actions`); `GrabSystem.useHandPinchForGrab` defaults to `false` |
| "Use `xrSession.requestAnimationFrame` once the session starts" | True for raw WebXR, but IWSDK owns the loop (`World.create` wires it) | Put per-frame work in a system's `update(delta, time)` or `world.onXRFrame` |
| `vite-plugin-mkcert` for HTTPS | Removed in 0.5 | `iwsdkDev()` makes a cached self-signed cert (`.iwsdk/https`) |
| `@iwsdk/vite-plugin-gltf-optimizer` | Removed in 0.5 | Pre-optimise with `gltf-transform` (`iwsdk-asset-pipeline`) |
| `createSystem({ name, queries, execute })`, `world.time.frame`, `entity.getObject3D()` | Pre-1.0 shapes; not in 1.0.1 | `class S extends createSystem({ q: { required: [C] } }) { update(delta, time) {} }`, `entity.object3D` |
| `entity.destroy()` for meshes | Leaks GPU memory (IWSDK `AGENTS.md`) | `entity.dispose()` |
| `import * as THREE from 'three'` | Can create a second Three.js instance | Import from `@iwsdk/core` |
| `requiredFeatures: ['hand-tracking']` in a hand-built session init | Bypasses IWSDK's session setup | `world.xr.features.handTracking: true` (or `{ "required": true }`) in `iwsdk.config.json` |

Sources:
- https://developers.meta.com/horizon/documentation/web/webxr-ffr/
- https://developers.meta.com/horizon/documentation/web/webxr-space-warp/
- https://developers.meta.com/horizon/documentation/web/webxr-frames/
- https://developers.meta.com/horizon/documentation/web/webxr-perf-workflow/
- https://github.com/meta-quest/agentic-tools/tree/main/skills/hz-iwsdk-webxr
- https://github.com/facebook/immersive-web-sdk/blob/main/packages/cli/guidance/AGENTS.md
