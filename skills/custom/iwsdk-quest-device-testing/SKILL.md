---
name: iwsdk-quest-device-testing
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.2.0"
description: >-
  Tests an IWSDK WebXR app on a physical Meta Quest in Quest Browser: developer
  mode and adb checks, the dev server over Wi-Fi or USB (`adb reverse`) and
  its certificate, the production build over HTTPS for benchmarks, getting
  results off the headset, remote DevTools via chrome://inspect, metavr logs
  and screenshots, the real frame rate, OVR Metrics, a headset-only
  checklist, and Meta VR Glasses prep on a Quest 3/3S (head-gaze preview,
  `metavr device fov-sim`, hands-only run).
  Use when the user says "test on my Quest", "open it in the headset", "Enter
  VR button missing", "works in the emulator but not on the Quest", "test the
  production build on the Quest", "save results from the headset", "kicked
  out of VR when I save", "inspect Quest Browser", "remote debug", "adb
  reverse", "headset logs", "what FPS is it running at", "test for Meta VR
  Glasses without the device", "simulate the glasses field of view", or
  before any store build. For scripted control of a real session, hand off
  to `iwsdk-native-xr-test`.
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

## 4a. Test the production build

Frame-rate and load-time numbers should come from the production build: the dev server serves
unbundled modules, the HMR client and emulator code. `vite preview` can serve `dist/` over
HTTPS with the certificate `iwsdkDev()` already made (`.iwsdk/https/_cert.pem` holds both the
key and the certificate):

```ts
// vite.config.ts
import { existsSync, readFileSync } from 'node:fs';

const devCert = '.iwsdk/https/_cert.pem';                 // written by iwsdkDev() on first dev run
const previewHttps = existsSync(devCert)
  ? { key: readFileSync(devCert), cert: readFileSync(devCert) }
  : undefined;

export default defineConfig({
  // ...existing config
  preview: { host: '0.0.0.0', port: 8083, https: previewHttps },
});
```

```bash
npm run build && npx vite preview        # then open https://<LAN-IP>:8083/ in Quest Browser
```

Use a port the dev server doesn't use, and accept the certificate warning once more (new port).
Checked with IWSDK 1.0.1 on 2026-10-16 from the computer (the HTTPS page and the §4b endpoint
both answer); opening it in Quest Browser is **unverified**.

## 4b. Get results off the headset without DevTools

A Quest page can't write files, and copying from the remote console is slow. A small Vite plugin
gives the page a same-origin endpoint that saves JSON (benchmark summaries, per-second perf rows,
tuning exports) into the repo, on both the dev server and `vite preview`:

```ts
// vite-plugins/results-sink.ts
import { mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import type { Connect, Plugin } from 'vite';

export function resultsSink(root: string): Plugin {
  const dir = join(root, 'results');
  const handler: Connect.NextHandleFunction = (req, res) => {
    const kind = (req.url ?? '').replace(/^\/+/, '').split('?')[0];
    if (req.method !== 'POST' || !/^[a-z0-9-]{1,40}$/.test(kind)) {
      res.statusCode = 400;
      return res.end('expected POST /__results/<kind>');
    }
    const chunks: Buffer[] = [];
    let size = 0;
    req.on('data', (c: Buffer) => { size += c.length; if (size <= 5 * 1024 * 1024) chunks.push(c); });
    req.on('end', () => {
      try {
        if (size > 5 * 1024 * 1024) throw new Error('payload too large');
        const body = JSON.parse(Buffer.concat(chunks).toString('utf8'));
        mkdirSync(dir, { recursive: true });
        const file = join(dir, `${kind}-${new Date().toISOString().replace(/[:.]/g, '-')}.json`);
        writeFileSync(file, `${JSON.stringify(body, null, 2)}\n`);
        res.end(JSON.stringify({ saved: file }));
      } catch (err) { res.statusCode = 400; res.end(String(err)); }
    });
  };
  return {
    name: 'results-sink',
    configureServer: (server) => { server.middlewares.use('/__results/', handler); },
    configurePreviewServer: (server) => { server.middlewares.use('/__results/', handler); },
  };
}
// vite.config.ts: plugins: [iwsdkDev(), resultsSink(process.cwd())]
// in the app:     fetch('/__results/bench', { method: 'POST', body: JSON.stringify(summary) })
```

Add `results/` to `.gitignore`. The endpoint exists only on the dev and preview servers (a
static host has none), and it accepts writes from anyone who can reach the port, so keep those
servers on the LAN.

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

## 7. Preparing for Meta VR Glasses on a Quest

The glasses ship in spring 2027; Meta's advice until then is to test on a Quest 3 or 3S. Their
users aim with their eyes, pinch to select, often have no controllers, and see 70° × 66°. App
changes (config, gaze UI, controller-free flows) are in **`iwsdk-vr-glasses`**; this is the
headset routine.

1. **Head-directed gaze preview.** With `world.xr.features.gazeTracking` set, add
   `"dev": { "targetDevicePreview": { "gazeSimulation": "head" } }` to `iwsdk.config.json`
   (IWSDK 1.0.1; dev server only, needs `dev.emulator.iwer` left on). The native Quest Browser
   session keeps its viewer, hands, controllers and frame timing, plus a test gaze source that
   follows the head. The console's `[iwsdk][gaze]` lines show whether gaze was granted, missing,
   invalid or head-mapped. It proves plumbing, not eye-tracking accuracy.
2. **Field-of-view simulation** (ask first: it changes a headset setting until disabled or
   rebooted). Needs a developer-mode Quest 3, 3S or Pro:
   ```bash
   npm exec metavr -- device fov-sim enable              # nominal 70° × 66°
   npm exec metavr -- device fov-sim enable --perceived  # p90 perceived 58° × 54°
   npm exec metavr -- device fov-sim disable             # always restore afterwards
   ```
   If the view doesn't change, take the headset off and on, or sleep/wake it, or relaunch the
   page. Check the boundary through the lenses: casts and screenshots only show the crop on
   Horizon OS v209+, and before v209 the simulation doesn't clip compositor layers (WebXR
   quad/cylinder layers).
3. **Hands only.** Put the controllers down (the session switches to hands) and complete every
   required flow: entering XR, menus, dialogs, scrolling, grabbing, locomotion, pause and exit.
   Then pick the controllers up mid-flow and put them down again: focus, held objects and open
   dialogs must stay valid (Meta's VR Glasses test procedure).
4. **Layout.** In the simulated view, check the first view after launch and after a recenter,
   menus, captions, error messages, and targets near each edge. Note anything clipped or
   reachable only by an unexpected head turn.
5. **Sustained run.** Heaviest scene for the content length or 45 minutes (§5), so the result
   can be compared once VR Glasses hardware (with its separate glasses and puck thermals) is
   available.

Don't follow `world.features.fieldOfViewMask` from Meta's hosted IWSDK guide: IWSDK 1.0.1
rejects the key (`docs/meta-reference/web-iwsdk-docs-on-meta.md`).

## Troubleshooting

| Symptom | Check |
|---|---|
| No Enter XR button / `isSessionSupported` false | Page not on HTTPS or `localhost`; `world.xr` disabled (`--target browser` projects have `xr: false`); a `required` XR feature the device lacks |
| `localhost` refused on the headset | `adb reverse` missing, wrong serial, or wrong port; check `adb -s <serial> reverse --list` |
| Network URL times out | Different Wi-Fi, client isolation, or firewall on 8081 → route B |
| Certificate page every time | Host changed (new IP); accept again, or use route B for a stable `localhost` |
| IWER toolbar shows on the headset | `dev.emulator.activation` set to `always`, a custom `userAgentException`, or `injectOnBuild: true` |
| Works in IWER, black screen in headset | Read the console via chrome://inspect; then a full page reload (HMR can leave a stale session) |
| Dropped out of VR whenever a file is saved | Expected in dev: an edit reloads the page, which ends the XR session (headset and emulator). Batch edits, warn whoever wears the headset, re-enter XR; play-test on `vite preview` (§4a) |
| Assets missing only on device | Network tab: 404 from a hard-coded `/path` (use `import.meta.env.BASE_URL`), or CORS on a CDN |
| `device unauthorized` | Re-plug and accept the USB debugging prompt in the headset |
| Dev server rejects `iwsdk.config.json` after following Meta's VR Glasses page (`unknown property "fieldOfViewMask"`) | That key isn't in IWSDK 1.0.1; remove it and use §7 (also `suppressWhenHandPointerActive` → `suppressWhenDirectPointerActive`) |
| Headset's field of view stays narrow | `metavr device fov-sim disable`, then take the headset off and on (a reboot also clears it) |

## Sources

- https://iwsdk.dev/guides/02-testing-experience.html (Wi-Fi and ADB methods, certificate, IWER activation)
- https://developers.meta.com/horizon/documentation/web/browser-remote-debugging/ (adb devices, adb reverse, chrome://inspect)
- https://developers.meta.com/horizon/documentation/web/webxr-frames/ (frameRate, supportedFrameRates, updateTargetFrameRate, Browser 16.4+)
- https://developers.meta.com/horizon/documentation/web/webxr-perf-workflow/ (OVR Metrics Tool)
- https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/ (developer mode; Meta's device setup page)
- https://github.com/facebook/immersive-web-sdk (1.0.1): `packages/vite-plugin-dev/src/types.ts` (emulator defaults), `packages/core/src/ecs/world.ts` (`session`, `visibilityState`, `onXRFrame`), `packages/cli/src/runtime-state.ts` (`runtimeUrls`)
- `docs/metavr-cli-reference.md` in this library (`metavr device browser`, `log`, `capture screenshot`, `perf capture`)
- npm `@iwsdk/vite-plugin-dev@1.0.1` `dist/index.js` (certificate cached in `.iwsdk/https`, written as `_cert.pem`)
- https://vite.dev/config/preview-options (`preview.https`, `preview.host`, `preview.port`), https://vite.dev/guide/api-plugin (`configureServer`, `configurePreviewServer`)
- Production preview, results endpoint and the reload-ends-XR behaviour: an IWSDK 1.0.1 VR prototype, 2026-10-16
- Meta VR Glasses: https://developers.meta.com/horizon/essentials/field-of-view/ (2026-09-25; `fov-sim`, v209 notes), /test-your-app/ (2026-09-25), /get-started-with-glasses/ (2026-10-13); IWSDK 1.0.1 `docs/concepts/xr-input/gaze.md` (`targetDevicePreview`), npm `@iwsdk/core` 1.0.1 `dist/project/validation.js`, npm `@iwsdk/vite-plugin-dev` 1.0.1 `dist/index.js` (`targetDevicePreview` requires IWER)

Last verified: 2026-10-17
