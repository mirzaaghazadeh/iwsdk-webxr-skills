# Source: iwsdk-pwa-packaging

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-pwa-packaging/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

IWSDK's own end-to-end path from a built app to a Horizon Store build: choose immersive vs 2D app
mode, auto-enter XR in the installed PWA (gated on `getDigitalGoodsService`), manifest and icons,
`@meta-quest/bubblewrap-cli` with a hand-written `twa-manifest.json` (`isMetaQuest`,
`horizonOSAppMode`), signing keystore, Digital Asset Links, sideload, and `ovr-platform-util
upload-quest-build`. Five references, including a troubleshooting table (stuck loading, URL bar,
will not launch).

## Caveats

- Uses `npm i -g @meta-quest/bubblewrap-cli` (a global install). Ask the user first.
- `bubblewrap doctor` must be run once by the person in a real terminal (interactive JDK/SDK and
  licence prompts).
- The `keytool` example puts passwords on the command line; they end up in shell history.
- Says "`iwsdk-planner`" for the entry skill; it is now `iwsdk-dev` (`../ERRATA.md`).
- Bubblewrap's Quest template emits `targetSdkVersion 32` and a non-required headtracking
  feature, while Meta now requires target SDK 34 for apps created since 2026-03-01 and
  `required="true"` for immersive apps (`../ERRATA.md`). Prefer the library's
  `horizon-web-store-publish` pipeline, which checks the APK for both.
- Store requirements (age groups, channels, VRCs, listing assets) change; cross-check with the
  library's store and publishing skills and Meta's live docs.

## Security review

Read in full (SKILL.md and five references). Markdown only. The `ovr-platform-util` download
uses Meta's public download link (`access_token=OC|<app id>|` is a public app token). Secrets
are kept out of `public/`, `dist/` and git, and the skill checks that the keystore isn't served.
No injection.
