---
name: iwsdk-testing
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.4.0"
description: >-
  Sets up repeatable automated tests for an IWSDK WebXR app: typecheck and
  build gates, asset checks, a headless smoke test that drives the IWER
  emulator through the `iwsdk` CLI (screenshot, console errors, entity and
  component checks, ECS pause/step/diff, entering XR), scripted interaction
  tests with emulated controllers, hands and Meta VR Glasses gaze + pinch,
  a test-hook component for arranging scenarios and fast-forwarding time,
  a TypeScript end-to-end suite under Vitest, bot players that finish the
  game with real emulated input, frame-stepped gameplay videos recorded in
  the emulator, scene-file validation, a production-build smoke test, the
  opt-in Playwright runner, unit tests for pure game logic, and a GitHub
  Actions job. Use when the user says "add tests",
  "regression test", "CI for my WebXR game", "test without a headset",
  "automate the emulator", "smoke test", "record a gameplay video", "make a
  trailer clip without a headset", "check it still works after my change", or
  before a release build. For a real headset use `iwsdk-native-xr-test`; for
  one-off debugging use `iwsdk-debug`.
---

# Testing IWSDK apps

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

IWSDK has no test framework of its own for apps. What it has is better for XR: a CLI that drives
the emulated headset and controllers and reads ECS state from the running app. Build tests on
that, in layers, cheapest first.

| Layer | Proves | Tool | Runs in CI |
|---|---|---|---|
| 1. Static gates | It compiles, bundles, assets load | `npm run typecheck`, `npm run build`, `check-gltf.mjs` | yes |
| 2. Pure logic | Rules, scoring, state machines | a unit runner (ask before adding one) | yes |
| 3. Runtime smoke | It boots, renders, no console errors, enters XR | `scripts/iwsdk-smoke.sh` | yes (headless, SwiftShader) |
| 4. Interactions | Grab, ray click, UI buttons, locomotion change state | `npx @iwsdk/cli xr …` + `ecs query` | yes |
| 5. Headset | Feel, comfort, frame rate, real MR features | `iwsdk-native-xr-test`, `iwsdk-quest-device-testing` | no |

## Ground rules

- Prove behaviour with **ECS state**, not pictures. Screenshots are evidence for humans.
- Pose or interaction claims need an **active XR session** (`xr status` → `sessionActive: true`).
- Use the project's own CLI (`./node_modules/.bin/iwsdk` or `npx @iwsdk/cli`), never an unscoped
  package. Tests must leave buttons released, ECS resumed and the dev server stopped.
- Ask before adding dev dependencies (a unit runner, image diff tools) or CI workflows.

## How the CLI reports results

Every command prints JSON. Success: stdout `{"ok": true, "data": {...}}`, exit 0. Failure:
stderr `{"ok": false, "error": {"code", "message"}}`, exit 1 (`packages/cli/src/index.ts`).
Runtime commands put the tool result at `.data.result`; `--raw` prints the bare result. Useful
paths (from the 1.0.1 source):

| Command | jq path |
|---|---|
| `dev status` | `.data.state.browserCommandReady`, `.data.runtimeUrls.local`, `.data.runtimeUrls.network[]` |
| `xr status` | `.data.result.sessionActive`, `.sessionMode`, `.enabledFeatures`, `.visibilityState` |
| `ecs find --input-json '{"namePattern":"^Robot$"}'` | `.data.result.entities[] | {entityIndex, name, componentIds}`, `.total` |
| `ecs query --input-json '{"entityIndex":7}'` | `.data.result.components[] | {componentId, values}` |
| `ecs diff --input-json '{"from":"a","to":"b"}'` | `.data.result.summary.{added,removed,changed}`, `.entities[]` |
| `browser screenshot --output-file p.png` / `scene render-file …` | `.data.screenshotPath`, metadata in `.data.result` |

Check any other shape with `npx @iwsdk/cli <domain> <action> --help` or
`npx @iwsdk/cli mcp inspect --tool <mcp_name>` instead of guessing.

## 1. Static gates

```bash
npm run --if-present typecheck      # type errors can stop systems initialising silently
npm run build
find public \( -name '*.glb' -o -name '*.gltf' \) -exec node <iwsdk-asset-pipeline>/scripts/check-gltf.mjs {} +
```

Validate authored scenes without the runtime app (needs the dev server for the editor renderer):

```bash
npx @iwsdk/cli scene render-file \
  --input-json '{"path":"public/scenes/main.iwsdk.scene.json","viewId":"hero"}' \
  --output-file artifacts/hero.png | jq -e '.data.result.valid == true'
```

## 2. Pure logic

Keep game rules (scoring, rounds, inventories, AI decisions) in plain TypeScript modules that
don't import `@iwsdk/core`, and let systems call them. Then any unit runner works. The scaffold
ships none; IWSDK's own packages use Vitest. Ask before `npm i -D vitest`. Creating a full
`World` in Node is not documented; don't build tests on it.

This scales to physics-like code: a character controller (state machine, jump windows,
wall-run, slide) behind a small collision interface, backed by simple boxes in tests and
three-mesh-bvh in the app, ran under Vitest in an IWSDK 1.0.1 prototype. Only one ECS system
adapts it to the world.

## 3. Runtime smoke test

`scripts/iwsdk-smoke.sh` (in this skill) starts `dev up --ai-mode agent`, waits for a first
frame and `browserCommandReady`, fails on console errors, optionally checks a named entity and
component, runs ECS pause → snapshot → step 30 frames → snapshot → diff, enters emulated XR,
captures screenshots, then exits XR and stops the server.

```bash
cp <this skill>/scripts/iwsdk-smoke.sh scripts/ && chmod +x scripts/iwsdk-smoke.sh
scripts/iwsdk-smoke.sh --entity '^Robot$' --component OneHandGrabbable --out artifacts/smoke
```

Options: `--no-xr` (browser-only apps), `--allow-console-errors`, `--keep-running`,
`--timeout MS`, `IWSDK_CLI=<path>` to point at another CLI. Exit 0 = pass, 1 = a check failed,
2 = setup error. Status: syntax- and shellcheck-clean and exercised against a stub CLI with the
documented JSON envelope; **not yet run against a live 1.0.1 runtime here**. If a jq path fails
on your version, print the JSON file it names and adjust.

## 4. Interaction tests

Write each scenario as one shell block: arrange (reset state), act (emulated input), assert
(ECS state). Device names: `headset`, `controller-right`, `controller-left`, `hand-right`,
`hand-left`, `gaze`. Gamepad button indices for `xr set-gamepad-state`: `0` trigger, `1`
squeeze, `2` thumbstick, `3` A/X, `4` B/Y, `5` thumbrest (iwsdk.dev/skill.md).

```bash
set -euo pipefail
cli() { npx @iwsdk/cli "$@"; }
cli xr enter --input-json '{}' >/dev/null
idx=$(cli ecs find --input-json '{"namePattern":"^StartButton$"}' | jq -r '.data.result.entities[0].entityIndex')

# Ray click on a UIKit or RayInteractable target: aim, then select
cli xr look-at --input-json '{"device":"controller-right","target":{"x":0,"y":1.5,"z":-2}}' >/dev/null
cli xr select --input-json '{"device":"controller-right","duration":0.2}' >/dev/null
cli ecs query --input-json "{\"entityIndex\":$idx}" | jq -e '.data.result.components[] | select(.componentId | contains("GameState"))'

# Proximity grab: move the controller to the object, hold squeeze (1), assert Grabbed, release
cli xr animate-to --input-json '{"device":"controller-right","position":{"x":0,"y":1.2,"z":-0.6},"duration":0.3}' >/dev/null
cli xr set-gamepad-state --input-json '{"device":"controller-right","buttons":[{"index":1,"value":1}]}' >/dev/null
# … query the object for Grabbed …
cli xr set-gamepad-state --input-json '{"device":"controller-right","buttons":[{"index":1,"value":0}]}' >/dev/null
```

Replace names, positions and component checks with your app's. Distance grab (`DistanceGrabbable`)
holds **trigger (0)** instead; proximity grab (`OneHandGrabbable`, `TwoHandsGrabbable`) holds
**squeeze (1)**. The official `iwsdk-grab` and `iwsdk-ray` skills give the exact procedures. For
physics and timing, use the `iwsdk-debug` loop (`ecs pause`, `snapshot`, `step --input-json
'{"count":8,"delta":0.016}'`, `diff`) and assert on `.data.result.entities`.

Direct `ecs set-component` is fine to **arrange** a scenario, but it is not proof that the user's
input path works.

**Gaze + pinch (Meta VR Glasses).** Needs `world.xr.features.gazeTracking` and, for the
emulated gaze source, `dev.emulator.device: "metaVRGlasses"` (setup: `iwsdk-vr-glasses`).
Switch to hands, aim `gaze`, pinch with a hand, assert, then test the fallback:

```bash
cli xr set-input-mode --input-json '{"mode":"hand"}' >/dev/null
cli xr look-at --input-json '{"device":"gaze","target":{"x":0,"y":1.5,"z":-2}}' >/dev/null
cli xr select --input-json '{"device":"hand-right"}' >/dev/null      # the pinch; gaze itself has no select
cli ecs query --input-json "{\"entityIndex\":$idx}" | jq -e '.data.result.components[] | select(.componentId | contains("GameState"))'
cli xr set-connected --input-json '{"device":"gaze","connected":false}' >/dev/null   # hand rays must take over
```

Gaze is pose-only: `look-at`, `set-transform` (orientation only) and `animate-to` aim it; move
its origin by moving `headset`. It isn't accepted by the select or gamepad commands. For a
hold-move-release grab use `xr set-select-value` on the hand (IWSDK gaze docs).

**CLI gotchas** (1.0.1):

- `xr look-at` needs `target` as an object, `{"x":0,"y":1.5,"z":-2}`. An array doesn't move
  the controller and doesn't give a clear error.
- Every `npx @iwsdk/cli` call costs about 0.3 s (process start). Calling the project's binary,
  `./node_modules/.bin/iwsdk`, directly took about 0.1 s per call (measured 2026-10-23), which
  matters in suites that make thousands of calls. Either way a script that holds a stick and
  presses a button "at the right moment" is only accurate to a few hundred ms. Start the player
  close to the edge you test, or pause the ECS and step (§4a) for exact timing.
- A code edit reloads the page and ends the emulated XR session; run `xr enter` again before
  the next XR command.
- **A hang looks like a lost connection.** An endless loop in game code logs nothing: `dev
  status` shows `browserIssue.cause: "connection_lost"`, and neither `browser reload` nor
  `runtime recover` brings it back while the page keeps hanging. Fix the loop, then `dev
  restart`. A typical culprit: `while (count < target) void addAsync()` where `count` only
  grows after an `await`.
- **`scene render-stats` fails during an emulated XR session** with `Cannot read properties of
  undefined (reading 'x')` (1.0.1; it works outside XR). Its bounds pass appears to trip over the
  emulated controller models. For a draw-call budget, copy `world.renderer.info.render.calls`
  and `.triangles` into a test component each frame and read them with `ecs query`.
- **Console noise from reloads.** The emulated controllers fetch their models from jsDelivr;
  reloading or switching input mode mid-fetch logs `net::ERR_ABORTED` errors. Filter those
  before failing a test on console errors.
- **Counts race with things the game spawns on its own.** "Pieces = before + 1" fails when
  the game adds one of its own at the same moment. Wait for the specific entity (index) to
  change state, or assert a relation that holds either way. To decide that state has settled,
  compare two readings taken seconds apart: a poll helper that checks before its first sleep
  compares readings a fraction of a second apart.
- **Freezing game time doesn't stop work already in flight.** A hit-test probe or an async
  spawn started before a `timeScale = 0` hook still completes.
- **Press a button only once the ray is on it.** After aiming, poll for `Hovered` on the
  target entity before pinching. If it never comes, fail with the list of entities that do
  have `Hovered`: that tells "aimed wrong" apart from "the press was lost". A test that alternates
  pass/fail on the same press is worth reading as a game bug. In one 1.0.1 game it was the
  button that removed itself while still pressed (see `iwsdk-official/ERRATA.md`).
- **The other controller's ray counts too.** Both emulated controllers point forward by default.
  On a wide panel the idle hand's ray can rest on a button, and a game that gives the pointed-at
  button to whichever hand is aiming will then ignore the trigger on the other side. Aim both
  controllers explicitly (the idle one away from the panel) before pressing.
- **Input mode is emulator state, not test state.** After `xr set-input-mode` hand (or a manual
  check in hand mode), the managed browser stays in hand mode for the next test and the next run,
  and controller presses do nothing. Set the mode at the start of every suite and in every hand
  test's cleanup.

**A test-hook component** makes scenarios quick to arrange: one dev component with plain fields
(`x`, `y`, `z`, `yawDeg`, `teleport`, `restart`, `setting`, `value`, `apply`) and a system
that acts when a trigger flag turns true, then clears it. `ecs set-component` writes one field
per call, so write the data fields first and the trigger flag last. Register the component in
`src/components.ts` like any other.

Three more fields on the same component paid off in an IWSDK 1.0.1 game:

- **A `command` string** the system reads each frame and clears: `reset`, `stars:20`,
  `derail` and so on. For `reset`, stop saving first, then clear storage and call
  `location.reload()`. A `pagehide` save handler would otherwise write the old state back.
- **A `timeScale` number** multiplied into the game's own `delta`: 8× turns minutes of play
  into seconds. Keep input steering on real frame time so carrying still works at 0×.
- **Mirrored counters** (score, entity counts, "game over", the current hint as a string),
  copied into the component when they change, so assertions are one `ecs query`.

### 4b. A TypeScript end-to-end suite

Past a handful of scenarios, shell blocks get hard to maintain. A small TypeScript harness
under Vitest worked well (measured: 21 scenarios, about 6 minutes against a live 1.0.1
emulator). Use a separate config so `npm test` stays fast:

```ts
// vitest.e2e.config.ts
export default defineConfig({ test: { include: ['e2e/**/*.e2e.ts'], fileParallelism: false, testTimeout: 180_000, hookTimeout: 180_000 } });

// e2e/harness.ts: one CLI call, parsed
const BIN = fileURLToPath(new URL('../node_modules/.bin/iwsdk', import.meta.url));
export function cli(command: string, input?: unknown): any {
  const args = command.split(' ');
  if (input !== undefined) args.push('--input-json', JSON.stringify(input));
  const out = execFileSync(BIN, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }); // throws on exit 1
  const json = JSON.parse(out);
  return json.data?.result ?? json.data;
}
// …plus waitFor(what, check, timeoutMs) that treats a CLI error during a reload as "not yet".
```

Keep scenario helpers (where to stand, how to grab and aim, game-frame ↔ world transforms) in
one module and import the game's pure modules into the tests. Expected positions then come from
the same code the game uses, not from hand-copied numbers.

**A bot player** proves a game can be finished, not just that its parts work. Expose what a
player would act on (the next hinted move, the goal) through the test-hook component, then loop:
read it, perform it with real emulated input (grab, aim, release), and assert the end state.
In one train-set game, the bot played a whole session to "complete" with tracked hands, and on
the way it found a placement that left a goal unreachable, which no single-scenario test had
caught.

### 4a. Record a gameplay video in the emulator

The emulator can't record real-time video, but pausing the ECS and stepping a fixed delta gives
a smooth, repeatable one. Each frame:

1. read state: `ecs query` on the player entity;
2. decide input (a small bot: jump when past an edge, slide at a marker) and send it with
   `xr set-gamepad-state` (a button press = down before the step, up after it);
3. `ecs step --input-json '{"count":1,"delta":0.0333333}'`;
4. `browser screenshot --output-file frames/0001.png`.

Then: `ffmpeg -framerate 30 -i frames/%04d.png -c:v libx264 -pix_fmt yuv420p -crf 18 out.mp4`.

- It only works if systems use the `delta` passed to `update()` (movement, timers, animation),
  not `performance.now()`.
- The run is deterministic: do a dry run without screenshots first (about two CLI calls per
  frame) to check the route, then record.
- Cost on a laptop: about 1.2 s per frame with screenshots, so 10 s of video at 30 fps takes
  about 7 minutes. Agent mode frames are 800 × 800.
- Hide dev overlays first and restore them after. The video is smooth by construction, so it
  shows look and moves, never real-time performance. Say so wherever it's shared.
- Measured in an IWSDK 1.0.1 prototype, 2026-10-17.

## 5. Advanced: the Playwright runner

For assertions the CLI can't express (DOM overlays, CDP metrics), IWSDK has an opt-in runner:

```bash
npx @iwsdk/cli dev up --allow-browser-automation
npx @iwsdk/cli browser run scripts/check-hud.mjs     # export default async function ({ page, frame, cdp }) { … }
```

The module must live inside the workspace and return JSON up to 1 MiB. While enabled, any local
process that can reach the loopback CDP endpoint has browser-level control of that session. Ask
the user, review the script, and don't enable it in ordinary sessions.

**Smoke-test the production build too.** The emulator suites run against the dev server, so
also serve `dist/` with `vite preview` and load it once in headless Chromium through Playwright
(a dependency of `@iwsdk/cli`). Fail on any console error or `pageerror`, and check that the
manifest URL returns 200. Playwright's `chromium_headless_shell` may not be downloaded, but the
IWSDK CLI's managed browser is: on macOS, launch with `executablePath` set to
`~/Library/Caches/ms-playwright/chromium-<n>/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing`
instead of downloading another browser (ask before `npx playwright install`).

## 6. Continuous integration

A GitHub Actions job (Linux, no GPU, so the managed browser uses SwiftShader: fine for
correctness, useless for performance): [references/ci-github-actions.md](references/ci-github-actions.md).

## 7. On the headset

Automated: **`iwsdk-native-xr-test`** (real Quest Browser session over `adb reverse`, same CLI
commands with a `runtimeTarget`). Manual checklist: **`iwsdk-quest-device-testing`** §6.

## Sources

- https://github.com/facebook/immersive-web-sdk (1.0.1): `packages/cli/src/index.ts`, `cli-results.ts`, `commands/runtime.ts`, `commands/status.ts`, `runtime-state.ts`, `help.ts`, `packages/core/src/mcp/ecs-debug-tools.ts`, `scripts/test-servers.mjs`, `.github/workflows/native-scene-editor.yml`
- https://github.com/meta-quest/immersive-web-emulation-runtime `packages/iwer/src/remote/types.ts` (session status fields)
- https://iwsdk.dev/ai/workflows.html (runtime-first workflows, Playwright runner)
- https://iwsdk.dev/ai/mcp-tools.html
- https://iwsdk.dev/skill.md (device names, gamepad indices, verification workflow)
- `npx @iwsdk/cli ecs step --help` (1.0.1: `count` 1-120, fixed `delta`, requires `ecs pause`)
- Test-hook component, CLI timing, `xr look-at` target shape, frame-stepped recording and the Vitest controller: an IWSDK 1.0.1 VR prototype, 2026-10-16/17
- Gaze automation: IWSDK 1.0.1 `docs/concepts/xr-input/gaze.md` ("Drive tests from the CLI"), https://developers.meta.com/horizon/documentation/iwsdk/guides/02-testing-experience/ ("Automate gaze and pinch", 2026-09-04)
- CLI timing with the project binary, the hang, `render-stats` and `ERR_ABORTED` behaviour, count races, the `command`/`timeScale`/mirrored-counter hooks, the Vitest suite, the bot player and the production smoke: an IWSDK 1.0.1 MR train-set game, 2026-10-23 (observed, not from IWSDK docs)
- The idle controller's ray and the sticky input mode: an IWSDK 1.0.1 seated VR game with 16 emulator tests, 2026-10-24 (observed)

Last verified: 2026-10-24
