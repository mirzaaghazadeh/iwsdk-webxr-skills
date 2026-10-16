---
name: iwsdk-testing
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.0.0"
description: >-
  Sets up repeatable automated tests for an IWSDK WebXR app: typecheck and
  build gates, asset checks, a headless smoke test that drives the IWER
  emulator through the `iwsdk` CLI (screenshot, console errors, entity and
  component checks, ECS pause/step/diff, entering XR), scripted interaction
  tests with emulated controllers, scene-file validation, the opt-in
  Playwright runner, unit tests for pure game logic, and a GitHub Actions job.
  Use when the user says "add tests", "regression test", "CI for my WebXR
  game", "test without a headset", "automate the emulator", "smoke test",
  "check it still works after my change", or before a release build. For a
  real headset use `iwsdk-native-xr-test`; for one-off debugging use
  `iwsdk-debug`.
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

## 5. Advanced: the Playwright runner

For assertions the CLI can't express (DOM overlays, CDP metrics), IWSDK has an opt-in runner:

```bash
npx @iwsdk/cli dev up --allow-browser-automation
npx @iwsdk/cli browser run scripts/check-hud.mjs     # export default async function ({ page, frame, cdp }) { … }
```

The module must live inside the workspace and return JSON up to 1 MiB. While enabled, any local
process that can reach the loopback CDP endpoint has browser-level control of that session. Ask
the user, review the script, and don't enable it in ordinary sessions.

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

Last verified: 2026-10-16
