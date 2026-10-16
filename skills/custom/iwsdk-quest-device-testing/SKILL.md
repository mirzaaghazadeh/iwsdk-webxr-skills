---
name: iwsdk-quest-device-testing
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.0.0"
description: >-
  Tests an IWSDK WebXR app on a physical Meta Quest in Quest Browser: developer
  mode and adb checks, opening the dev server over Wi-Fi or USB (`adb reverse`),
  the self-signed certificate, remote DevTools through chrome://inspect, device
  logs and screenshots with metavr, reading the real session frame rate and
  enabled features, the OVR Metrics Tool performance HUD, and a checklist of
  what only the headset proves. Use when the user says "test on my Quest",
  "open it in the headset", "Enter VR button missing", "works in the emulator
  but not on the Quest", "inspect Quest Browser", "remote debug", "adb reverse",
  "headset logs", "what FPS is it running at", or before any store build. For
  scripted pose/input control of a real session, hand off to
  `iwsdk-native-xr-test`.
---

# Testing an IWSDK app on a Meta Quest

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

The emulator (IWER) proves the code paths. Only the headset proves input feel, comfort, text
legibility, real frame rate, thermals and mixed-reality features. Do this early and after every
feature, not just before release.

Related: scripted control of a real session → **`iwsdk-native-xr-test`** (official);
frame-time problems → **`iwsdk-performance`**; Quest CLI details → `docs/metavr-cli-reference.md`
in this library and the `metavr-cli` skill if installed.

## Ground rules

- Work with **one explicit device serial**. If `adb devices` lists several, ask which one and pass
  `-s <serial>` to every `adb` command.
- Ask before installing Android platform tools, OVR Metrics Tool, or anything on the headset.
- Keep the dev server on the local network or loopback. Never expose it with a public tunnel
  without asking (it serves your source and, with AI tooling, a command bridge).
- Remove `adb reverse` routes when done. Never automate permission dialogs in the headset; ask the
  person wearing it.

## 0. Headset ready?

1. Developer mode is on: Meta Horizon mobile app → headset icon → your headset → **Headset
   Settings** → **Developer Mode** (Meta's device setup page). Connect a USB-C data cable, put
   the headset on, and choose **Always allow from this computer** at the USB debugging prompt.
2. Check from the computer:
   ```bash
   adb devices                         # want: <serial>  device   (not unauthorized/offline)
   npm exec metavr -- device list      # same via the project's metavr dev dependency
   ```
3. Start the app: `npx @iwsdk/cli dev up` (or `npm run dev`) and read the URLs:
   ```bash
   npx @iwsdk/cli dev status           # data.runtimeUrls.local and data.runtimeUrls.network[]
   ```

## 1. Open the app on the headset

Pick one route. IWER is not injected in Quest Browser (`userAgentException` defaults to
`/OculusBrowser/`), so the headset always uses its native WebXR.

| Route | Steps | When |
|---|---|---|
| **A. Same Wi-Fi** (IWSDK's recommended method) | Open a `data.runtimeUrls.network` URL, e.g. `https://192.168.1.20:8081/`, in Quest Browser | Home networks |
| **B. USB + `adb reverse`** | `adb -s <serial> reverse tcp:8081 tcp:8081`, then open `https://localhost:8081/` | Corporate/guest Wi-Fi, client isolation, firewalls |
| **C. Chrome port forwarding** | `chrome://inspect/#devices` → Port forwarding… → add the port | Same as B, from Chrome's UI |

- Use the port `dev status` reports (scaffold default 8081).
- Open the URL without typing in the headset: `npm exec metavr -- device browser "https://localhost:8081/"`.
- The dev certificate is self-signed: accept the warning once per host. That's expected.
- Choose **Enter XR**. The scaffold sets `world.xr.offer: "always"`: IWSDK calls
  `navigator.xr.offerSession(...)` after start-up and again after each session ends, so Quest
  Browser shows its own enter button; an app may also add its own.
- Clean up route B: `adb -s <serial> reverse --remove tcp:8081`.

## 2. Remote DevTools

USB (ADB) connection required.

1. Open the page in Quest Browser.
2. On the computer, open `chrome://inspect/#devices` in desktop Chrome.
3. Find the headset and the Quest Browser tab → **inspect**.

Use **Console** for errors and your debug logs, **Network** for 404s, CORS failures and asset
sizes, **Performance** for CPU traces (DevTools adds overhead; compare runs under the same
conditions). Check the console first: type errors can stop a system from initialising without any
visible symptom.

## 3. Logs and captures from the device

```bash
npm exec metavr -- log -n 200 -l W                          # recent device log, warnings and up
npm exec metavr -- capture screenshot -o artifacts/quest.png
adb -s <serial> logcat -d | tail -200                       # raw logcat, if metavr isn't installed
```

`metavr log` is a shortcut for `adb logcat` with tag and level filters. Whether Quest Browser
mirrors page `console.*` output into logcat is **unverified**; rely on chrome://inspect for page
logs. `metavr` options: `npm exec metavr -- <command> --help`.

## 4. Read the real session facts

Add a dev-only probe after `World.create(...)` resolves (remove it before release). `frameRate`,
`supportedFrameRates` and `updateTargetFrameRate` are WebXR APIs that Quest Browser 16.4+
supports; they may be missing from TypeScript's types, hence the cast.

```ts
import { VisibilityState } from '@iwsdk/core';

type RateSession = XRSession & {
  frameRate?: number;
  supportedFrameRates?: Float32Array;
  updateTargetFrameRate?: (rate: number) => Promise<void>;
};

if (import.meta.env.DEV) {
  world.visibilityState.subscribe((state) => {
    if (state !== VisibilityState.Visible) return;
    const s = world.session as RateSession | undefined;
    console.log('[xr] mode/features', s?.enabledFeatures,
      'frameRate', s?.frameRate,
      'supported', s?.supportedFrameRates && Array.from(s.supportedFrameRates));
  });

  let sum = 0;
  let frames = 0;
  world.onXRFrame((_frame, delta) => {   // delta is seconds
    sum += delta;
    if (++frames === 300) {
      console.log('[xr] avg frame', ((sum / frames) * 1000).toFixed(2), 'ms',
        'draw calls', world.renderer.info.render.calls,
        'triangles', world.renderer.info.render.triangles);
      sum = 0;
      frames = 0;
    }
  });
}
```

Don't assume a default refresh rate: Meta's frame-rate page only gives older-device defaults.
Read `frameRate`, and see `iwsdk-performance` before calling `updateTargetFrameRate`.

## 5. Performance HUD

**OVR Metrics Tool** shows FPS and CPU/GPU frame times as an in-headset overlay. Install it from
Meta Quest Developer Hub or sideload it (Meta's WebXR performance workflow page), with the user's
permission. Record: target vs. actual FPS, GPU frame time, CPU frame time, in the heaviest scene
of the app, after 5+ minutes (thermals). Deeper tracing (Perfetto via
`npm exec metavr -- perf capture`) is covered by Meta's `hz-perfetto-debug` skill if installed;
whether it attributes Quest Browser WebXR frames usefully is **unverified**.

## 6. What only the headset proves

- [ ] Session starts from the app's button **and** from Quest Browser's own prompt
- [ ] Controllers: trigger/select, squeeze/grab, thumbsticks, A/B/X/Y, menu
- [ ] Hand tracking (requires `world.xr.features.handTracking` in `iwsdk.config.json`)
- [ ] Locomotion comfort: teleport, snap/smooth turn, vignette; no player falling through floors
- [ ] Text and UI readable at the real viewing distance; panels not head-locked
- [ ] Holds the target frame rate in the heaviest scene; no stutter on asset loads
- [ ] Mixed reality: passthrough, room setup present, planes/meshes/anchors/hit-test/depth as requested
- [ ] Audio: spatial direction and volume
- [ ] Exit XR and re-enter: state resets correctly; ScreenSpace UI comes back
- [ ] Headset sleep / wake (proximity sensor) and system menu: app pauses on `VisibleBlurred`

## Troubleshooting

| Symptom | Check |
|---|---|
| No Enter XR button / `isSessionSupported` false | Page not on HTTPS or `localhost`; `world.xr` disabled (`--target browser` projects have `xr: false`); a `required` XR feature the device lacks |
| `localhost` refused on the headset | `adb reverse` missing, wrong serial, or wrong port; check `adb -s <serial> reverse --list` |
| Network URL times out | Different Wi-Fi, client isolation, or firewall on 8081 → route B |
| Certificate page every time | Host changed (new IP); accept again, or use route B for a stable `localhost` |
| IWER toolbar shows on the headset | `dev.emulator.activation` set to `always`, a custom `userAgentException`, or `injectOnBuild: true` |
| Works in IWER, black screen in headset | Read the console via chrome://inspect; then a full page reload (HMR can leave a stale session) |
| Assets missing only on device | Network tab: 404 from a hard-coded `/path` (use `import.meta.env.BASE_URL`), or CORS on a CDN |
| `device unauthorized` | Re-plug and accept the USB debugging prompt in the headset |

## Sources

- https://iwsdk.dev/guides/02-testing-experience.html (Wi-Fi and ADB methods, certificate, IWER activation)
- https://developers.meta.com/horizon/documentation/web/browser-remote-debugging/ (adb devices, adb reverse, chrome://inspect)
- https://developers.meta.com/horizon/documentation/web/webxr-frames/ (frameRate, supportedFrameRates, updateTargetFrameRate, Browser 16.4+)
- https://developers.meta.com/horizon/documentation/web/webxr-perf-workflow/ (OVR Metrics Tool)
- https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/ (developer mode; Meta's device setup page)
- https://github.com/facebook/immersive-web-sdk (1.0.1): `packages/vite-plugin-dev/src/types.ts` (emulator defaults), `packages/core/src/ecs/world.ts` (`session`, `visibilityState`, `onXRFrame`), `packages/cli/src/runtime-state.ts` (`runtimeUrls`)
- `docs/metavr-cli-reference.md` in this library (`metavr device browser`, `log`, `capture screenshot`, `perf capture`)

Last verified: 2026-10-16
