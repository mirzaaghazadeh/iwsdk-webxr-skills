# Source: iwsdk-native-xr-test

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-native-xr-test/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

The only official recipe for automating a **real** Quest Browser WebXR session: `npx @iwsdk/cli
dev up --native-xr-control --no-open`, `adb -s <serial> reverse tcp:<port> tcp:<port>`,
`runtime pair-headset`, a Quest Browser deep link through `adb shell am broadcast`, then the
usual `xr`/`ecs`/`scene` commands with an exact `runtimeTarget`. Strong safety rules (explicit
device serial, loopback only, always clean up). Added in 1.0.0 (CHANGELOG `13a5cbe`).

## Caveats

- Needs Android platform tools (`adb`), developer mode and an authorised USB connection; see
  `../../custom/iwsdk-quest-device-testing`.
- The launch broadcast targets `com.oculus.vrshell/.ShellControlBroadcastReceiver`, a Horizon OS
  intent that Meta doesn't document for web developers. If it stops working, open the pairing
  URL in Quest Browser by hand.
- A first run shows an immersive-WebXR permission prompt in the headset; a person must accept it.
- Native control replaces the physical controllers with synthetic ones for the test.

## Security review

Read in full. Markdown only. It forbids exposing the command bridge on the LAN and requires
removing the `adb reverse` route afterwards. No injection.
