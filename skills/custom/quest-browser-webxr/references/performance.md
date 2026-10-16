# WebXR performance on Quest: measuring and fixing

From Meta's WebXR performance pages (workflow and hub 2026-07-21; best practices and tools
undated) plus the VRCs. Fetched 2026-10-16.

## Targets

| Item | Value | Source |
|---|---|---|
| Rendered fps | ≥ 60 sustained (≥ 30 only with Application SpaceWarp) | VRC Performance.1 (2025-10-22) |
| Refresh rates for interactive apps | 72, 80, 90, 96, 100, 120 Hz (96/100/120 not on all devices) | VRC Performance.1 |
| Frame budget | 60 fps 16.6 ms; 72 fps 13.7 ms; 90 fps 11.1 ms | webxr-perf-workflow |
| Launch | head-tracked graphics within 4 s, or a VR loading indicator | VRC Performance.3 |
| Render scale | ≥ 85% for most of the experience (Recommended) | VRC Performance.4 |
| Native upper bounds | Quest 3: < 200 draw calls, < 1.5M tris, 90 Hz recommended; Quest 2: < 100 draw calls, < 750K tris | device-optimization-comparison (2026-05-11) |
| Test length | content length or 45 minutes, whichever is shorter, with OVR Metrics Tool | VRC Performance.1 |

Quest 3S has no dedicated Meta spec page (unverified budgets; it reports `Quest 3` in the UA).
Numbers in `hz-iwsdk-webxr` ("50-80 draw calls on Quest 2, 100-120 on Quest 3", "keep total
texture memory under 256 MB", "750K triangles per eye") are not on any Meta page: unverified.

## Tools

```bash
# OVR Metrics Tool (HUD + logs)
metavr tools install ovrmetric
# GPU render-stage trace for the Browser
adb shell am force-stop com.oculus.browser
adb shell ovrgpuprofiler -e            # extended mode, then relaunch Browser and enter VR
adb shell ovrgpuprofiler -t            # trace; fewer "stages" with FFR on
adb shell ovrgpuprofiler --realtime="29,30"   # vertex vs fragment share in real time
```

- **CPU frame time**: headset in the WebXR scene, then desktop Chrome `chrome://inspect#devices`
  > "trace" next to `com.oculus.browser` > Record > Edit categories > enable `xr.debug` > Record >
  Stop. The trace shows CPU frame time and the Phase Sync period [webxr-perf-tools].
- **Draw order, per-draw GPU cost**: RenderDoc Meta Fork with Browser [webxr-perf-renderdoc];
  draw-call metrics [ts-webxr-perf-drawcall].
- **System traces**: Perfetto (`hz-perfetto-debug`).
- **Three.js counters**: `renderer.info.render.calls` / `.triangles` (`hz-iwsdk-webxr`).

## Workflow [webxr-perf-workflow]

1. Disable all rendering. No frame-time change: CPU bound. Big improvement: GPU bound.
2. GPU bound: set render scale to 0.01. Faster: fragment bound. Unchanged: vertex bound.
3. Fix the top item, re-measure, repeat; the bottleneck moves.

## Fixes by bottleneck

**CPU bound** (app logic, too many draw calls)
- Merge small meshes; `THREE.InstancedMesh`; multiview (25-50% CPU reduction "often possible",
  CPU-bound apps only) [web-multiview].
- Fewer WebGL state changes per draw; optimize any logic over 2 ms; stagger non-critical updates
  (animate a third of the objects per frame at 90 fps for 30 Hz animation) [webxr-perf-bp].
- Avoid allocations in the frame loop; pool objects (`hz-iwsdk-webxr`).

**Vertex bound**
- Simplify meshes, LODs, split huge meshes for frustum culling, cull instanced meshes, indexed
  triangle strips.

**Fragment bound**
- Opaque objects front to back; force sky domes to draw last.
- Cheaper materials away from hero objects (`MeshPhongMaterial` vs `MeshStandardMaterial`); fewer
  PBR maps or lower resolutions.
- One directional or point light with PBR; light probes or baked lightmaps for static lighting;
  careful with shadows (point-light shadows render 6 maps).
- Compress textures: KTX 2.0 / Basis Universal recommended [webxr-perf-bp]; ETC or ASTC also cut
  bandwidth [webxr-perf-workflow]. Reduce anisotropic filtering; try `mediump`.
- Avoid overdraw from transparency and particles; stop drawing fully faded objects.
- Clear to black or white (Adreno fast clear) [webxr-perf-bp].
- FFR [webxr-ffr]; layers for backgrounds, video and text [webxr-layers].
- Last resort: render scale 0.8-0.9 [webxr-perf-workflow]; below 0.85 for most of the game
  conflicts with VRC Performance.4 (Recommended).

**Loading** (Performance.3, Functional.1)
- Start the session with a light scene and a loading indicator; load the rest asynchronously
  (IWSDK `AssetManager` with priorities; `hz-iwsdk-webxr`).
- Desktop load profiling for canvas-only pages: `hz-iwsdk-webxr` references
  `desktop-load-profiling.md` (Lighthouse cannot compute LCP for a canvas).
