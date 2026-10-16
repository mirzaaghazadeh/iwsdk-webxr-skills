# Errata: where Meta's official skills disagree with live docs

The skill folders here are kept **unchanged** from upstream (commit `3a8553d`, still the latest on
2026-10-17). Some content in them is older than Meta's developer pages or than IWSDK 1.0.1.
Checked on 2026-10-16 and again on 2026-10-17 after Meta Connect 2026. Where they disagree, trust
the live page, the `iwsdk-*` official skills (`../iwsdk-official/ERRATA.md`) and the custom skills
in `../custom/`, which were written from those sources.

Meta's developer pages moved from `developers.meta.com/horizon/...` to `developers.meta.com/vr/...`
(HTTP 302, `/vr/` is canonical). The `/horizon/` links in these skills still redirect and work; the
link check on 2026-10-17 found no dead links in this folder.

## `hz-iwsdk-webxr`: written for IWSDK 0.4

Treat its API examples as outdated. For current IWSDK code use `iwsdk-dev` and the other
`iwsdk-*` skills. Full table with sources: `../custom/iwsdk-performance/references/older-advice.md`.

| What the skill says | What's true now | Source |
|---|---|---|
| Quest Browser defaults to 72 Hz for WebXR | 90 fps on Quest 2 (72 on the original Quest); Quest 3/3S not stated. Read `session.frameRate` | [webxr-frames](https://developers.meta.com/vr/documentation/web/webxr-frames/) |
| FFR via `session.fixedFoveatedRendering.level = 'high'`, "~15/25/40%" | No such API. Use `XRWebGLLayer.fixedFoveation` (0–1); in IWSDK `world.renderer.xr.setFoveation()` | [webxr-ffr](https://developers.meta.com/vr/documentation/web/webxr-ffr/) |
| `navigator.xr.enableSpaceWarp(true)` | Not an API. WebXR Space Warp is a draft behind a `chrome://flags` switch (Browser 24.2+), with no support in IWSDK 1.0.1 | [webxr-space-warp](https://developers.meta.com/vr/documentation/web/webxr-space-warp/) |
| Turn on multiview with `renderer.xr.useMultiview = true` | IWSDK already creates its renderer with multiview stereo; check `world.renderer.xr.isMultiview` | IWSDK 1.0.1 source |
| Draw calls 50–80 (Quest 2) / 100–120 (Quest 3); textures < 256 MB; pinch threshold 0.7–0.8 | No Meta source. Meta's native upper bounds: Quest 2 < 100 draw calls / < 750K triangles; Quest 3 < 200 / < 1.5M. Measure on the device | [device-optimization-comparison](https://developers.meta.com/vr/resources/device-optimization-comparison/) |
| "13.9 ms at 72 Hz" | 13.7 ms at 72 fps | [webxr-perf-workflow](https://developers.meta.com/vr/documentation/web/webxr-perf-workflow/) |
| `vite-plugin-mkcert`, `@iwsdk/vite-plugin-gltf-optimizer`, `createSystem({ name, queries, execute })` | Removed or changed in IWSDK 0.5–1.0 | `../custom/iwsdk-performance/references/older-advice.md` |
| "Applies to Meta VR Glasses with gaze-pinch input", with no gaze setup | IWSDK 1.0+: `world.xr.features.gazeTracking: true` (optional; `{ required: true }` fails sessions without eye tracking, such as Quest 3/3S); desktop emulation with `dev.emulator.device: "metaVRGlasses"` and IWER's "Gaze + Hands"; Quest preview with `dev.targetDevicePreview.gazeSimulation: "head"`; targets need only `RayInteractable` / `DistanceGrabbable`. Use `../custom/iwsdk-vr-glasses` | [get-started-glasses](https://developers.meta.com/vr/documentation/iwsdk/guides/get-started-glasses/) (2026-09-04); https://iwsdk.dev/concepts/xr-input/gaze.html (IWSDK 1.0.1) |

## `hz-store-pwa`

| What the skill says | What's true now | Source |
|---|---|---|
| Scripted `twa-manifest.json` with `"features": {}` | `bubblewrap init --metaquest` always enables `features.horizonPlatformSDK` | `@meta-quest/bubblewrap-cli` 1.24.1 source |
| IAP needs only `applicationId` | Also needs `alphaDependencies.enabled` and `features.horizonBilling`, or Horizon Billing is skipped | Bubblewrap `FeatureManager.ts` |
| `minSdkVersion: 23`, no SDK-level guidance | Bubblewrap's Quest template (1.24.1, still `latest` on 2026-10-17) hard-codes targetSdk 32 in both modes and marks head tracking `required="false"`. Meta asks minSdk 29–34, **targetSdk 34 for apps created since 2026-03-01**, and `required="true"` for immersive apps. Whether TWAs are exempt isn't documented: read the first ALPHA upload's test status | [publish-mobile-manifest](https://developers.meta.com/vr/resources/publish-mobile-manifest/) (2026-10-15) ✔ re-checked |
| (no device-targeting guidance) | The template declares `oculus.software.handtracking required="false"` + `HAND_TRACKING` ("controllers and hands") and no `supportedDevices`. To reach Meta VR Glasses, include **Future devices** in the build's Supported Devices or upload with `--channel "alpha:quest3+"` | [app-compatibility](https://developers.meta.com/vr/essentials/app-compatibility/) (2026-10-13), [target-builds-by-device](https://developers.meta.com/vr/resources/publish-release-channels-device-targeting/) (2026-09-04) |
| "hzdb / metavr cannot upload to the Store" | `metavr store dist upload`, `channels` and `copy-build` exist (uploads are drafts unless `--publish`; no age-group or device-target option) | `docs/metavr-cli-reference.md` |
| `npx @iwsdk/create@latest <app> --yes --mode vr --no-metaspatial` | `npm create @iwsdk@latest my-app -- --yes --target vr\|ar\|browser`. The Meta Spatial Editor integration was removed in IWSDK 0.5 | `../custom/iwsdk-project-setup` |
| JDK and Android SDK "pre-provisioned in ~/.bubblewrap" | Bubblewrap downloads them on first run | [pwa-packaging](https://developers.meta.com/vr/documentation/web/pwa-packaging/) |

## `hz-new-project-creation` (`references/web-project.md`)

| What the skill says | What's true now | Source |
|---|---|---|
| Optional `@iwsdk/vite-plugin-metaspatial`; `iwsdkDev({ emulator: … })` in `vite.config` | Spatial Editor integration removed in 0.5; keep emulator settings in `iwsdk.config.json` | IWSDK 1.0.1 docs (guide 02, testing) |
| Emulator devices without a VR Glasses option | IWSDK 1.0.1 `dev.emulator.device` accepts `metaQuest2`, `metaQuest3`, `metaQuestPro`, `metaVRGlasses`, `oculusQuest1` | npm `@iwsdk/core` 1.0.1 `dist/project/types.d.ts`; [02-testing-experience](https://developers.meta.com/vr/documentation/iwsdk/guides/02-testing-experience/) (2026-09-04) |

## `hz-immersive-designer`

| What the skill says | What's true now | Source |
|---|---|---|
| Ray targets ≥ 48 mm (~2.8° at 1 m), poke/pinch 64 mm; no gaze rule; "Is haptic feedback used to confirm interactions?" | Gaze targets ≥ **3° of visual angle** (~5.2 cm at 1 m); **web content in Browser ≥ 56 × 56 CSS px** (a convention, not enforced); subtle hover that never moves or resizes the target; explicit close affordances. VR Glasses ship without controllers, so no haptics by default | [eyes-best-practices](https://developers.meta.com/vr/design/eyes-best-practices/) (2026-10-13), [compare-devices](https://developers.meta.com/vr/essentials/compare-devices/) (2026-09-30) |

## `hz-store-submit` (store-wide values)

| What the skill says | What Meta's docs say now | Source |
|---|---|---|
| `targetSdkVersion >= 32` (2D panel apps 34+), `minSdkVersion >= 29` | targetSdk 32–34 for immersive, 32–37 for 2D; **34 for every app created since 2026-03-01**; minSdk 29–34 | [publish-mobile-manifest](https://developers.meta.com/vr/resources/publish-mobile-manifest/) ✔ re-checked |
| Icon 1024×1024; hero 2560×1440; at least 3 screenshots | Icon **512×512**; hero **3000×900**; covers 2560×1440 / 1440×1440 / 1008×1440; Mini Landscape 1080×360; **5** screenshots at 2560×1440. Alpha is ignored except on the Logo | [asset-guidelines](https://developers.meta.com/vr/resources/asset-guidelines/) ✔ re-checked |
| Name 30, short 150, long 4000 characters | **40 / 500 / 1500** | [publish-app-metadata](https://developers.meta.com/vr/resources/publish-app-metadata/) |
| Trailer 30–60 s | **30 s to 2 min**, MP4/H.264/AAC, 1080p–2K | [asset-guidelines](https://developers.meta.com/vr/resources/asset-guidelines/) ✔ re-checked |
| 72 Hz minimum, **90 Hz on Quest 3 and Meta VR Glasses**; load under 15 s | VRC.Quest.Performance.1: render at **≥ 60 fps** on every device (no VR Glasses-specific VRC); Performance.3: graphics within **4 s** or a loading indicator | [publish-quest-req](https://developers.meta.com/vr/resources/publish-quest-req/) (2026-08-19) ✔ re-checked 2026-10-17 |
| (submission-checklist) "App launches successfully on Meta VR Glasses, Quest 3, and Quest 3S" | VR Glasses ship in spring 2027. Test with IWER's VR Glasses profile and `metavr device fov-sim` on a Quest 3/3S; Store delivery is set by **Future devices** | [test-your-app](https://developers.meta.com/vr/essentials/test-your-app/) (2026-09-25), [app-compatibility](https://developers.meta.com/vr/essentials/app-compatibility/) |
| Paid apps must check entitlement and quit, or they're auto-rejected | VRC.Quest.Security.1 is **Recommended**; exiting, an error or a limited demo are all allowed | [vrc-quest-security-1](https://developers.meta.com/vr/resources/vrc-quest-security-1/) |

## Meta's pages vs. Meta's repo (2026-10-17)

- "Test your app for Meta VR Glasses" (2026-09-25) names skills `vrc-check`,
  `xr-simulator-setup` and `perfetto-debug`, which aren't in `agentic-tools@3a8553d` (it has
  `hz-perfetto-debug`; the VRC skill was removed on 2026-05-12). Use
  `../custom/horizon-web-vrc-checklist` for VRCs.
- `com.oculus.supportedDevices`: the release-manifest page (2026-10-15) lists `vrglasses`, the
  compatibility-mode page (2026-09-04) says it is "not currently a supported public value".
  Bubblewrap writes neither; use Store targeting.

Rows marked ✔ were checked again against the live page during review. The rest come from the
research passes (`docs/research-meta-web.md` §6 and later sections, `docs/research-iwsdk.md`,
`docs/meta-reference/web-vr-glasses.md`), which list every source. The VR Glasses rows for
`hz-iwsdk-webxr`, `hz-new-project-creation` and `hz-immersive-designer` come from the 2026-10-17
IWSDK pass, with their page dates spot-checked.
