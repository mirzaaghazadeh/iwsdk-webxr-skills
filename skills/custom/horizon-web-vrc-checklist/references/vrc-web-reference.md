# All active VRCs, mapped to WebXR and 2D PWAs

Columns **S** (Meta Horizon Store: immersive WebXR PWA) and **2D** (Meta Horizon Store (2D):
2D PWA) are copied from Meta's VRC index (updated 2026-08-19): ✓ required, + recommended,
- not applicable (the index shows N/A or a blank cell). The requirement text is shortened from
Meta's; the **web check** and **test** columns are this library's mapping to WebXR, Bubblewrap and
Quest Browser, not Meta's wording. Retired and omitted: Performance.2, Functional.8,
Functional.11, Input.6.

Shared tools: `check-pwa-deploy.mjs` and `verify-twa-apk.sh` (in `horizon-web-store-publish`),
`metavr`, `chrome://inspect`, OVR Metrics Tool.

## Packaging

| VRC | S | 2D | Requirement | Web check | Test |
|---|---|---|---|---|---|
| Packaging.1 | ✓ | ✓ | Manifest meets release rules | `verify-twa-apk.sh`; RISK items come from Bubblewrap's template | Upload to ALPHA; Test Status (checked at upload) |
| Packaging.2 | ✓ | ✓ | APK Signature Scheme v2; same certificate for every version | `bubblewrap build` signs with apksigner; never lose the keystore | `apksigner verify` |
| Packaging.3 | ✓ | ✓ | No unsupported Android features (Bluetooth, GMS, camera hardware...) | Don't add `uses-feature required=true` entries; Bubblewrap's are `required=false` | Test Status |
| Packaging.4 | ✓ | ✓ | Supported SDK/engine version; valid network security config | Use the current `@meta-quest/bubblewrap-cli` | Test Status |
| Packaging.5 | ✓ | ✓ | APK < 1 GB, OBB < 4 GB | A TWA is small; game assets stay on the web host | `ls -l` |
| Packaging.6 | ✓ | ✓ | 64-bit binaries | No native code in a TWA | `verify-twa-apk.sh` |

## Audio, performance

| VRC | S | 2D | Requirement | Web check | Test |
|---|---|---|---|---|---|
| Audio.1 | + | + | 3D audio spatialization | Web Audio `PannerNode` (HRTF) or IWSDK spatial audio | Listen with head turns |
| Performance.1 | ✓ | + | Allowed refresh rate; ≥ 60 fps rendered (30 with AppSW) | `supportedFrameRates` + `updateTargetFrameRate`; budgets in `quest-browser-webxr`. WebXR Space Warp needs a flag, so plan for 60+ | OVR Metrics for content length or 45 min |
| Performance.3 | ✓ | + | Head-tracked graphics within 4 s or a VR loading indicator | Auto-enter with a light scene; loading UI inside XR; 2D: show content or a spinner fast | Cold start: `metavr app launch <pkg> --cold-start --measure-launch-time` plus a stopwatch in the headset |
| Performance.4 | + | - | ≥ 85% render scaling for most of the experience | `framebufferScaleFactor` ≥ 0.85; Meta's 0.8-0.9 "last resort" tip conflicts below 0.85 | Read the value in code; OVR Metrics |

## Functional

| VRC | S | 2D | Requirement | Web check | Test |
|---|---|---|---|---|---|
| Functional.1 | ✓ | ✓ | No crashes, freezes, extended unresponsiveness | `webglcontextlost` / `restored` handlers; async loading; memory (dispose three.js resources) | 45+ min session; DevTools console; `metavr log --level E` |
| Functional.2 | ✓ | + | Single-player apps pause when the OS asks | `visibilitychange` → pause on `visible-blurred`/`hidden`; ambient sound may continue | Universal Menu; passthrough via Quick Settings; Power button |
| Functional.3 | ✓ | ✓ | User never stuck | Every screen has a way back; login flows don't dead-end (out-of-scope links open in Browser for immersive packages) | Walk every menu and flow |
| Functional.4 | ✓ | ✓ | No user data loss | Save on `visibilitychange`/`pagehide`; important progress server-side (clearing Browser data clears site storage; 2D PWAs share storage with Browser) | Force-stop mid-session, relaunch |
| Functional.5 | ✓ | ✓ | Responds to position and orientation | `local-floor`/`local` space; IWSDK default `LocalFloor` | Lean and step |
| Functional.6 | ✓ | ✓ | Only Meta Quest headsets and controllers in app and assets | Input-profile Meta models; no generic controllers | Visual review of app and store media |
| Functional.7 | + | + | Tell users when required internet is missing | `navigator.onLine`, fetch failures, offline page via service worker | Airplane mode, launch |
| Functional.9 | ✓ | - | Local tracking space: user can reset forward | Reference space `reset` event; re-place UI | 180° turn, long-press the Meta button |
| Functional.10 | + | - | Avoid head-locked UI | World-locked or lazy-follow panels | Visual review |
| Functional.12 | ✓ | ✓ | Full function for multiple entitled users | No cross-account caching; per-user saves | Primary and secondary accounts |
| Functional.13 | + | + | Default to system language, else English | `navigator.language` | Change device language |
| Functional.14 | ✓ | + | Passthrough-launching apps: passthrough loading screen, launch in passthrough from MR Home | `immersive-ar` start; Bubblewrap immersive template sets `passthrough-contextual` splash | MR Home with passthrough on, launch |

## Security, tracking, input

| VRC | S | 2D | Requirement | Web check | Test |
|---|---|---|---|---|---|
| Security.1 | + | + | Entitlement check within 10 s | WebXR PWA: `getLoggedInUserId()` + server `verify_entitlement` (see SKILL.md); 2D: no Digital Goods service | Unentitled test user: exit, error or demo |
| Security.2 | ✓ | ✓ | Minimum permissions; none prohibited; review-required ones justified; graceful denial | `verify-twa-apk.sh` permission list; `enableNotifications`/`enableMicrophone`/`enableXRScene` false unless used | Deny every prompt |
| Tracking.1 | ✓ | - | Meets declared sitting/standing/roomscale | Standing/roomscale: 6.5' × 6.5'; sitting: no standing, no floor reach, no turning > 90° | Play each declared mode |
| Tracking.2 | ✓ | ✓ | Each declared input modality works alone from launch | Hands-only declared: `'hand-tracking'` requested, all UI via pinch `select`; 2D: Browser panel input with hands and with controllers | Full playthrough per modality |
| Input.1 | + | + | Menu button opens the in-app menu | Left menu button exits WebXR in Browser (webxr-hands); offer an in-app control | Press menu |
| Input.2 | + | - | Grip picks up objects, not trigger | `squeeze` events / gamepad button 1 | Grab objects |
| Input.3 | + | - | Hands and controllers line up with real ones | Render models at `gripSpace`; rays from `targetRaySpace` | Visual check |
| Input.4 | ✓ | - | Focus-aware: keep rendering, hide hands/controllers, ignore input | `visible-blurred` handling; hands may rest at the sides | Universal Menu open |
| Input.5 | + | - | Hands render in correct position, orientation, animation | `getJointPose`/`fillPoses` every frame; `generic-hand` models | Visual check |
| Input.7 | ✓ | ✓ | Correct switching between controllers and hands | `inputsourceschange`; swap visuals and interactors | Auto-switch on, put down and pick up controllers |
| Input.8 | ✓ | ✓ | System gesture reserved | Nothing bound to palm pinch | Palm pinch, no in-app reaction |

## Assets, ads

Same rules for web and native; details and the image checker in `horizon-store-listing-assets`.

| VRC | S | 2D | Requirement |
|---|---|---|---|
| Asset.1 | ✓ | ✓ | Logo on a transparent background |
| Asset.2 | ✓ | ✓ | Cover art: clear branding, no extra text, taglines or banners |
| Asset.3 | + | + | No text in the top or bottom 20% of cover art |
| Asset.4 | + | + | Hero art: branding or title centred |
| Asset.5 | ✓ | ✓ | Screenshots representative, no added logos, text or icons |
| Asset.6 | ✓ | ✓ | No other VR platforms' headsets, controllers or logos |
| Asset.7 | ✓ | ✓ | Trailer ≤ 2 minutes |
| Asset.8 | + | + | Art text ≥ 24 pt |
| Asset.9 | ✓ | ✓ | Immersive Image Layers (Object Left/Right, Logo) on transparent backgrounds |
| Asset.10 | + | - | Quest Pro-only features captioned "Captured on Meta Quest Pro." |
| Ads.1 | ✓ | ✓ | Meet all advertising policies |
| Ads.2 | ✓ | ✓ | "Contains Ads" label on the product page |
| Ads.3 | ✓ | ✓ | Ads not stereoscopic, head-tracked or immersive |
| Ads.4 | ✓ | ✓ | Interfering ads have a clear dismissal |
| Ads.5 | ✓ | ✓ | No interfering ads after each of consecutive user actions |
| Ads.6 | ✓ | ✓ | Ads don't impair device functionality |
| Ads.7 | ✓ | ✓ | No ads that invite inadvertent clicks (for example mimicking Horizon OS UI) |

Web note for ads: a web ad SDK inside an immersive session must still meet Ads.3 (no
stereoscopic or head-tracked ads); show ads on a flat panel or a non-immersive page.

## Accessibility (all recommended)

| VRC | S | 2D | Requirement |
|---|---|---|---|
| Accessibility.1 | + | + | Playable without audio |
| Accessibility.2 | + | + | Legible text and controls |
| Accessibility.3 | + | + | Clear direction via visual, audio and/or haptic cues |
| Accessibility.4 | + | + | One-handed / one-controller option |
| Accessibility.5 | + | + | Display settings (brightness, contrast) |
| Accessibility.6 | + | + | Colour-blind options or colour plus pattern |
| Accessibility.7 | + | + | Rotate the view without moving the head (snap/smooth turn) |
| Accessibility.8 | + | + | Multiple locomotion styles |
| Accessibility.9 | + | - | Sitting or standing apps: a setting to do every interaction and reach all information from a fixed position |

Web hints: haptics via `gamepad.hapticActuators`; IWSDK locomotion provides teleport, slide and
snap/smooth turn (`hz-iwsdk-webxr` input-handling reference).

## Streaming

| VRC | S | 2D | Requirement |
|---|---|---|---|
| Streaming.1 | + | - | Streaming stereoscopic, head-tracked or immersive content: handle connectivity issues gracefully |
| Streaming.2 | ✓ | - | Such streaming only from a local PC the customer has physical access to, unless Meta expressly approves |
| Streaming.3 | ✓ | - | Streaming from virtual devices or cloud sources: display connectivity notices |
| Streaming.4 | ✓ | - | Streaming from virtual devices or cloud sources: not directed at children under 13 |

Applies only if the WebXR app streams rendered stereo content (for example cloud rendering), not
to a web app that downloads assets and renders locally. Read /resources/vrc-quest-streaming-1/
to -4/ before relying on that distinction.

## Privacy, content, publishing (all ✓ / ✓ except Content.4 + / +)

Privacy.1-4 (own privacy policy covering collection, use, deletion requests), Privacy.5 (team
and app pass data protection checks), Content.1 (content guidelines), Content.2 (metadata matches
the app: web deploys can change the app after review, so keep them consistent), Content.3 (UGC
report form), Content.4 (hide UGC immediately, Rec), Publishing.1-8 (valid website, support and
ToS URLs; name, short and long description and keywords meet guidelines; Meta brand use). See
`horizon-store-listing-assets`.
