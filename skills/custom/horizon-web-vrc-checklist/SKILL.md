---
name: horizon-web-vrc-checklist
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.0.0"
description: >-
  Pre-submission audit of a WebXR / IWSDK PWA (immersive) or a 2D PWA against
  Meta's current Virtual Reality Checks (VRCs) for the Horizon Store, by VRC ID,
  using the Store and Store (2D) columns of Meta's VRC table. For each VRC it
  gives the web-specific check (WebXR APIs, Bubblewrap manifest output, web
  permissions) and how to test it in the installed TWA on a Quest with metavr,
  adb, chrome://inspect and OVR Metrics Tool, then produces a PASS/FAIL/RISK
  evidence table. Use when the user asks "will my WebXR app pass review", "VRC
  checklist for a PWA", "which VRCs apply to a 2D web app", "focus awareness in
  WebXR", "pause when the Universal Menu opens", "frame rate requirement for
  WebXR", "entitlement check for a PWA", or "why was my web app rejected
  (VRC...)". Takes precedence over the generic VRC notes in Meta's
  hz-store-submit, which are partly out of date.
---

# Horizon Store VRC audit for WebXR and 2D PWAs

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

Meta's VRC guide (updated 2026-08-19) lists 84 IDs; 80 are active (retired: Performance.2,
Functional.8, Functional.11, Input.6). It has two columns: **Meta Horizon Store** (apply it to an
immersive WebXR PWA) and **Meta Horizon Store (2D)** (apply it to a 2D PWA). The full table, with
a web check and a test for all 80, is in [references/vrc-web-reference.md](references/vrc-web-reference.md).

Meta's VRC pages are written for Unity, Unreal and native apps (`OnApplicationPause`,
`InputFocusLost`); none mentions WebXR. The web mappings below come from the WebXR Device API and
Meta's Browser docs. They are this skill's interpretation: cite them as such, not as Meta's words.
Individual VRC pages win over Meta's "slightly out of date" test plans and over
`hz-store-submit` (which still says 72 Hz minimum, required entitlement checks, 15 s loads).

## Workflow

1. **Classify** and write it at the top of the report:
   - Mode: immersive (`horizonOSAppMode: "immersive"`) or 2D. Pick the matching column.
   - Declared input modalities (controllers, hands), play area (sitting, standing, roomscale),
     single- or multiplayer, Local vs Stage space (`local-floor` usually behaves as Local:
     recenter applies), launches in passthrough (`immersive-ar`), ads, UGC, cloud streaming,
     Digital Goods / user ID use (needs the Data Use Checkup and Privacy.5).
2. **Static audit, no headset:**
   - `horizon-web-store-publish/scripts/check-pwa-deploy.mjs` on the live manifest URL.
   - `horizon-web-store-publish/scripts/verify-twa-apk.sh` on the release APK: Packaging.1-6 and
     Security.2. Report its RISK lines as RISK, not PASS.
   - Grep the source for the APIs in the table below (`visibilitychange`, `inputsourceschange`,
     `reset`, `updateTargetFrameRate`, `getDigitalGoodsService`).
3. **Device tests** on each target headset with the **installed** TWA (not a Browser tab;
   behaviour differs, for example auto-enter and Digital Goods). Use the session below.
4. **Report** one row per applicable VRC: `ID | Req/Rec (column) | PASS/FAIL/RISK/N/A |
   Evidence | Fix`. Required FAILs first. No PASS without evidence (log line, screenshot, OVR
   Metrics capture, DevTools trace, code reference).
5. Before quoting a requirement, re-check the page if this skill is older than "Last verified":
   `metavr docs fetch https://developers.meta.com/horizon/resources/vrc-quest-<area>-<n>/`.

## Required VRCs that web apps most often miss

Column key: **S** = Store (immersive PWA), **2D** = Store (2D). ✓ required, + recommended, - N/A.

| VRC | S / 2D | Web check | Test in the installed TWA |
|---|---|---|---|
| Packaging.1/.4 | ✓/✓ | Manifest rules and SDK levels; Bubblewrap's Quest template emits minSdk 23, targetSdk 32, headtracking `required=false`, no `supportedDevices` / `installLocation` / `excludeFromRecents` (RISK) | Upload to ALPHA; read Manage Builds > Test Status (checked at upload) |
| Packaging.2 | ✓/✓ | v2 signature, same certificate forever | `apksigner verify`; `verify-twa-apk.sh` |
| Packaging.3/.5/.6 | ✓/✓ | No unsupported Android features; APK < 1 GB; 64-bit (a TWA has no native code) | Test Status after upload |
| Performance.1 | ✓/+ | Pick 72 or 90 from `session.supportedFrameRates`, `updateTargetFrameRate()`; ≥ 60 fps rendered; budgets in `quest-browser-webxr` | OVR Metrics HUD for the content length or 45 min; no extended dips below 60 (loading screens and fades exempt) |
| Performance.3 | ✓/+ | Immersive PWAs auto-enter XR; show head-tracked graphics or an in-XR loading indicator within 4 s; stream heavy assets later | `metavr app launch <pkg> --cold-start --measure-launch-time`, then count seconds in the headset |
| Functional.1 | ✓/✓ | No crash, freeze or long hang: handle `webglcontextlost`, async loading, no unhandled promise rejections at startup | Play 45 min+; DevTools console via `chrome://inspect`; `metavr log --level E` |
| Functional.2 | ✓/+ | Single-player: pause interactive elements when `XRSession.visibilityState` becomes `visible-blurred` or `hidden` (2D: `document.visibilitychange`) | Open the Universal Menu; enter passthrough from Quick Settings; press Power: all interaction stops |
| Functional.3/.4 | ✓/✓ | Never stuck; save progress on `visibilitychange`/`pagehide` (IndexedDB or server), not only on a clean exit | Force-stop mid-session (`metavr app stop <pkg>`), relaunch, check progress |
| Functional.5 | ✓/✓ | 6DoF reference space (`local-floor`/`local`), not `viewer` only | Lean and step: the view translates |
| Functional.6 | ✓/✓ | Only Meta Quest hardware: WebXR Input Profiles Meta models, no generic or other-brand controllers, also in store media | Inspect in-app visuals and every screenshot and trailer |
| Functional.9 | ✓/- | Handle the reference space `reset` event; re-anchor UI after recenter | Turn 180°, long-press the Meta button: forward resets |
| Functional.12 | ✓/✓ | No user ID or entitlement cached across accounts; key saves by `getLoggedInUserId()` when used | Two entitled accounts (primary, secondary); play as each |
| Functional.14 | ✓/+ | Apps that can launch in passthrough: Bubblewrap's immersive template sets `ossplash.background=passthrough-contextual`; start `immersive-ar` without a VR flash | Enable passthrough in MR Home, launch, watch the splash |
| Security.2 | ✓/✓ | Minimum permissions: Bubblewrap adds `HAND_TRACKING` always; `POST_NOTIFICATIONS`, `RECORD_AUDIO`, `USE_SCENE` only via flags (set false if unused); deny every web permission prompt gracefully | Deny each prompt (mic, camera, spatial data): app shows a message or keeps working |
| Tracking.1 | ✓/- | Declared play area matches; standing/roomscale content fits 6.5' × 6.5' | Play several levels in each declared mode |
| Tracking.2 | ✓/✓ | Each declared modality works alone from launch (hands-only: request `'hand-tracking'`, every menu works with pinch `select`) | Play through with controllers only, then hands only |
| Input.4 | ✓/- | Focus-aware: in `visible-blurred` keep rendering, hide hands/controllers (or rest them at the sides), ignore input | Open the Universal Menu: scene renders, no in-app hands, no reaction to input |
| Input.7 | ✓/✓ | Handle `inputsourceschange`; swap hand and controller visuals and interactors | Auto-switch on; pick up and put down controllers repeatedly |
| Input.8 | ✓/✓ | Palm pinch is reserved by Browser; bind nothing to it; keep hands visible so users can exit | Palm toward headset, pinch: no in-app reaction |
| Asset.*, Privacy.1-5, Content.1-3, Publishing.1-8, Ads.1-7 | ✓/✓ | Same rules as native apps | `horizon-store-listing-assets` |

Recommended but worth doing: Security.1 entitlement (web pattern below), Performance.4 render
scale ≥ 85% (S only), Functional.7 tell users when the internet is missing (a PWA always loads
from the network unless it caches), Functional.10 no head-locked UI, Functional.13 default to
`navigator.language`, Input.1 in-app menu (Browser takes the left menu button out of WebXR, so
offer another control), Input.2 grip (`squeeze`) to pick up, Audio.1 spatial audio, Accessibility.1-9.

## Entitlement (Security.1, Recommended) for a WebXR PWA

No Meta web page covers it: the web IAP page links to `/documentation/web/ps-entitlement-check/`,
which returns 404 (2026-10-16). Pattern assembled from documented pieces (unverified as a whole):

1. In the installed WebXR PWA, `getDigitalGoodsService('https://quest.meta.com/billing')` then
   `service.getLoggedInUserId()`. `0` means no ID. Needs a Data Use Checkup with the User ID or
   User Profile grant (ps-iap). Security.1's page: Horizon OS supplies the user ID "only if they
   are entitled to your application".
2. Send the ID to your server; call `POST https://graph.oculus.com/<APP_ID>/verify_entitlement`
   with `access_token=OC|<APP_ID>|<APP_SECRET>` and `user_id` (no `sku` = the base app) (web
   ps-iap-s2s). Never ship the App Secret to the client.
3. On failure, within 10 s: exit, show an error, or enter a limited demo (Security.1 expected result).

2D PWAs don't get the Digital Goods service (IAP is WebXR-only per ps-iap), so this pattern is
immersive-only.

## Device test session (copy and adapt)

```bash
metavr device list
metavr app install --replace app-release-signed.apk
metavr adb logcat --clear
metavr app launch <pkg> --cold-start --wait-for-idle --measure-launch-time --verify   # Performance.3, Functional.1
metavr adb logcat | grep -i "TWA verification was unsuccessful"                       # must be empty
# desktop Chrome: chrome://inspect/#devices -> inspect the PWA tab (console, performance trace)
# In headset: Universal Menu open/close (Input.4, Functional.2); passthrough via Quick Settings;
# Power off/on; 180° turn + long-press Meta button (Functional.9); controllers <-> hands (Input.7);
# palm pinch (Input.8); deny each permission prompt (Security.2)
metavr capture screenshot -o evidence/focus-lost.png
metavr log --level W
```

Performance evidence: OVR Metrics Tool (`metavr tools install ovrmetric`) over the content length
or 45 minutes; save the log or a screenshot. Trace-level work: `quest-browser-webxr`
references/performance.md and `hz-perfetto-debug`. Performance analytics in the Dashboard are not
available for web apps (publish-performance-analytics), so local evidence is all you get.

## Sources

- https://developers.meta.com/horizon/resources/publish-quest-req/ (2026-08-19; Store and Store (2D) columns)
- https://developers.meta.com/horizon/resources/vrc-quest-packaging-1/ ... -6/ (2024-07-31 to 2024-09-03)
- https://developers.meta.com/horizon/resources/vrc-quest-performance-1/ (2025-10-22), -performance-3/, -performance-4/
- https://developers.meta.com/horizon/resources/vrc-quest-functional-2/ (rev. 2025-09-05), -functional-5/, -functional-9/, -functional-12/, -functional-14/
- https://developers.meta.com/horizon/resources/vrc-quest-security-1/ (2025-04-08), -security-2/ (2026-03-30)
- https://developers.meta.com/horizon/resources/vrc-quest-input-4/ (2025-09-26), -input-7/, -input-8/, -tracking-1/ (2025-05-15), -tracking-2/ (2025-12-16)
- https://developers.meta.com/horizon/resources/publish-mobile-manifest/ (2026-10-15), /permissions-prohibited/ (2025-04-30), /permissions-review-required/ (2025-11-26)
- https://developers.meta.com/horizon/resources/publish-performance-analytics/
- https://developers.meta.com/horizon/documentation/web/ps-iap/ (2026-10-14), /ps-iap-s2s/, /webxr-hands/, /pwa-webxr/ (2026-07-22)
- https://immersive-web.github.io/webxr/ (XRVisibilityState, inputsourceschange, reference space reset)
- https://github.com/meta-quest/bubblewrap (template_project AndroidManifest.xml and build.gradle)

Last verified: 2026-10-16
