---
name: horizon-web-store-publish
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.1.0"
description: >-
  End-to-end release pipeline for shipping an IWSDK / WebXR game (or a 2D web
  app) on the Meta Horizon Store as a PWA/TWA: production build, HTTPS hosting
  that can serve /.well-known/assetlinks.json, web app manifest and icons,
  @meta-quest/bubblewrap-cli in immersive or 2D mode (scripted, non-TTY),
  version codes, signed-APK verification, sideload test, ovr-platform-util or
  metavr upload to ALPHA, device targeting (Future devices for Meta VR Glasses,
  quest3+ channel suffix), promotion between release channels, web-only updates
  versus APK rebuilds, and CI. Ships a deploy checker, a TWA APK verifier and a
  guarded upload wrapper. Use when the user says "publish my WebXR app to the
  Quest store", "package my IWSDK game as a PWA", "bubblewrap for Quest", "my
  TWA won't launch / shows a URL bar", "assetlinks", "upload my web app APK",
  "ship my PWA to Meta VR Glasses", "promote to beta / production", or "set up
  CI for my Quest PWA". Builds on and corrects Meta's hz-store-pwa skill.
---

# Ship an IWSDK / WebXR app to the Meta Horizon Store

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

Meta's `hz-store-pwa` skill and IWSDK's upstream `iwsdk-hosting` and `iwsdk-pwa-packaging`
skills (in `skills/iwsdk-official/`, with `ERRATA.md`) are the base walkthroughs (Vercel,
manifest, Bubblewrap, upload). Read one first. This skill adds what it lacks: checks before each irreversible step, hosting traps
that break Digital Asset Links, the Bubblewrap fields agents must set by hand, version-code
control, device targeting, channel promotion, and CI. Meta rewrote its PWA docs on 2026-07-22
and verified them with `@meta-quest/bubblewrap-cli` **1.24.1** (still npm `latest` on 2026-10-17;
Bubblewrap `main` unchanged since 2026-09-16).

Detail lives in references: [twa-manifest.md](references/twa-manifest.md) (every field, what the
Quest template emits), [hosting.md](references/hosting.md) (Vercel, GitHub Pages, custom
domains, headers), [ci.md](references/ci.md) (GitHub Actions).

## Rules for the agent

- **Ask before**: generating or choosing a signing key, installing Bubblewrap (it is a global
  npm install and downloads its own JDK and Android SDK into `~/.bubblewrap` on first run), any
  upload, anything touching the production (`store`/`LIVE`) channel, `metavr ... --publish`,
  and Submit for Review (that one is Dashboard-only and stays with the user).
- **Never** print, log or commit keystore passwords, the App Secret or user tokens. Never put
  the keystore or `twa-manifest.json` inside the deployable web folder (`public/`, `dist/`).
- **Don't hand-edit the generated Android project.** `bubblewrap update` regenerates it and
  deletes manual changes (Bubblewrap README). Change `twa-manifest.json` instead.
- Re-check facts older than "Last verified" with `metavr docs search "<topic>"` or
  `metavr docs fetch <url>` (see `hz-quest-verify-first`).

## 0. Decide first (one-way doors)

| Decision | Why it is permanent | Where |
|---|---|---|
| App mode `immersive` vs `2D` | Sets `horizonOSAppMode`, the launch intent category and whether the app auto-enters WebXR. A wrong value hangs on loading (2D app set immersive) or shows a URL bar (immersive app set 2D) | pwa-packaging; `hz-store-pwa` |
| Android package id | "Every update to an existing Store app must use the same package identifier." Bubblewrap's default is the reversed host plus `.twa`; pick your own | pwa-packaging |
| Signing key | "Every future update must use the same signing certificate." Back up keystore, alias and passwords in two places | pwa-packaging |
| Origin (scheme + host) | The TWA trusts exactly this host and checks `/.well-known/assetlinks.json` on it. Apex vs `www` matters | pwa-packaging; configure-assetlinks |
| Age group | Goes into every `ovr-platform-util` upload; Mixed Ages WebXR PWAs must call `getUserAccountAgeCategory()` on every launch | ps-iap; age-groups |
| Hand support | Bubblewrap's Quest template always declares `oculus.software.handtracking required="false"` + `HAND_TRACKING`, which Meta defines as "controllers and hands". Make hands-only play work from launch (Tracking.2). Whether the Store's hands-first ranking for Meta VR Glasses reads this declaration is undocumented (unverified) | app-compatibility (2026-10-13); Bubblewrap `template_project` |

Plan the launch with `horizon-launch-roadmap`. Create the app in the Developer Dashboard first
(Create a New App, platform Meta Horizon Store) to get the App ID; you need it for IAP and upload.

## 1. Production build

```bash
npm run build        # IWSDK starter: Vite -> dist/   (npm run preview serves it locally)
```

- **Vite `base`:** the IWSDK 1.0.1 scaffold already sets `"./"` (relative), which works at the
  root or a subpath (upstream `iwsdk-hosting`); leave it. Meta's hosting page (2026-09-23) shows
  the default `"/"` for a root deploy or an explicit `"/subpath/"`. Either way `start_url`,
  `scope` and assetlinks are what break at a subpath (section 2).
- Vite copies `public/` verbatim; optimize big GLB/KTX2 files before adding them (IWSDK
  "Build and Deploy", 2026-09-23). Budgets: `quest-browser-webxr`.
- **Immersive mode must auto-enter XR.** Meta: WebXR PWAs should launch "directly into immersive
  mode right after launch without a 2D landing page". The icon tap counts as the user
  activation. Gate on the Digital Goods API so a normal Browser tab keeps its Enter XR button:

```ts
// After World.create(...) resolves (IWSDK). world.launchXR() wraps requestSession.
if (window.getDigitalGoodsService !== undefined && navigator.xr?.isSessionSupported) {
  navigator.xr.isSessionSupported('immersive-vr')          // 'immersive-ar' for MR apps
    .then((ok) => { if (ok) world.launchXR(); }).catch(() => {});
}
```

  `getDigitalGoodsService` exists only in the installed PWA, so this path can only be tested on
  a headset. **2D mode must not auto-enter.**
- Show head-tracked graphics or a VR loading indicator within 4 s of launch (VRC Performance.3):
  start the session with a light scene, then stream heavy assets.

## 2. Host it where the origin root is yours

Requirements: public HTTPS origin; `/.well-known/assetlinks.json` at the **origin root**, served
with **200, no 301/302 redirects, `application/json`** (Android's assetlinks hosting rules; the
TWA uses the same file); the manifest and icons reachable without auth.

| Host | Works? | Traps |
|---|---|---|
| Vercel | Yes (Meta's walkthrough) | Use the production alias. Per-deploy URLs return 401 under Deployment Protection |
| GitHub Pages, user/org site or custom domain | Yes | `gh-pages` CLI drops dotfiles unless `--dotfiles`; branch deploys run Jekyll, which skips dot-folders, unless `--nojekyll` / `.nojekyll`. `actions/upload-pages-artifact` **v4 excludes dotfiles**; v5 needs `include-hidden-files: true`; v3 (Meta's sample workflow) includes them |
| GitHub Pages project site (`user.github.io/repo/`) | **No for Store** | The origin root `user.github.io/.well-known/` is not yours. Fine for Browser-only hosting |
| Custom domain | Yes | Pick apex or `www` once; a redirect between them breaks verification |

More hosts and headers (CORS, MIME types for `.wasm`, `.ktx2`, `.glb`): [hosting.md](references/hosting.md).

## 3. Manifest, icons, asset links: check before packaging

Meta's manifest example and the fields Bubblewrap 1.24.1 reads are in `hz-store-pwa` and
pwa-overview-gs. The rules that bite:

- `start_url` must stay inside `scope`; both resolve against the manifest URL.
- Bubblewrap picks the largest `any` icon and the largest `maskable` icon and ignores them below
  **512 px** (source `util.ts`). No 512 px `any` icon means no launcher icon.
- `bubblewrap init` rejects a `name` over 50 or a launcher name (`short_name`) over 12 characters.
- 2D apps only: other origins go in `additional_trusted_origins`, each with its own assetlinks.

Run the checker against the live deploy (Node 18+, no dependencies):

```bash
node scripts/check-pwa-deploy.mjs https://<DOMAIN>/manifest.webmanifest \
  --mode immersive --package com.studio.game --sha256 <AA:BB:...>
```

It checks HTTP status and content types, JSON, names, scope, PNG sizes against `sizes`, the
512 px icons, assetlinks on every trusted origin (no redirects, package, fingerprint), and that
`/android.keystore` and `/twa-manifest.json` are not downloadable. Exit 1 on any FAIL.

## 4. Package with Bubblewrap

**Human at a terminal:** `bubblewrap init --manifest=https://<DOMAIN>/manifest.webmanifest --metaquest`
asks, in order: app mode, host, start URL, name, launcher name, package id, version code,
display mode and orientation (2D only; immersive is forced to `standalone`), background colour,
icon and maskable icon URLs, shortcuts (if the manifest has any), monochrome icon, Horizon
Billing (then the App ID), location delegation, microphone, XR scene (`USE_SCENE`) permission,
signing key path and alias, and offers to create the key. Answer microphone, location and scene
"no" unless the app uses them (each adds a permission reviewers check under Security.2).

**Agent (no TTY):** `init` cannot be answered from a non-interactive shell. Write
`twa-manifest.json` yourself, then:

```bash
cd <twa-dir>                                    # outside the web project's public/ and dist/
export BUBBLEWRAP_KEYSTORE_PASSWORD=... BUBBLEWRAP_KEY_PASSWORD=...   # from the user, never echoed
bubblewrap update --skipVersionUpgrade          # regenerate the Android project from the JSON
bubblewrap build                                # -> app-release-signed.apk (+ app-release-bundle.aab)
```

Fields to set by hand that `hz-store-pwa`'s template misses (from Bubblewrap source; full list in
[twa-manifest.md](references/twa-manifest.md)):

| Field | Value | Why |
|---|---|---|
| `isMetaQuest` | `true` | Quest template: VR/2D intent category, `horizonos.pwa.APP_MODE` |
| `horizonOSAppMode` | `"immersive"` or `"2D"` | Default is `immersive` |
| `features.horizonPlatformSDK.enabled` | `true` | `init --metaquest` always adds it (Horizon permission and platform request handlers) |
| `enableNotifications` | `false` | Manifests built by `init` default to `true`, which adds `POST_NOTIFICATIONS`, a review-required permission |
| `appVersionCode`, `appVersionName` | integers you control | `update` bumps the code by 1 unless `--skipVersionUpgrade`; `build` always bumps it when it regenerates a changed manifest |
| IAP only: `applicationId`, `alphaDependencies.enabled`, `features.horizonBilling` | App ID; `true`; `{ "enabled": true, "horizonOSAppMode": ... }` | Bubblewrap skips Horizon Billing unless `alphaDependencies` is enabled |

`build` prompts when `manifest-checksum.txt` is missing or the JSON changed since the last
update; run `update` first so CI never hits a prompt.

**Asset links:** get the certificate SHA-256 (`keytool -list -v -keystore <ks> -alias <alias>`;
use the `keytool` in `~/.bubblewrap/jdk` if none is on PATH), run `bubblewrap fingerprint add
<sha256>`, copy the generated `assetlinks.json` to `public/.well-known/`, redeploy, re-run the
checker. One file can authorize several packages (pwa-packaging).

## 5. Verify the APK

```bash
scripts/verify-twa-apk.sh app-release-signed.apk --mode immersive \
  --assetlinks https://<DOMAIN>/.well-known/assetlinks.json [--expect-app-id <APP_ID>]
```

It FAILs on: debuggable, no v2 signature, debug certificate, fingerprint not in assetlinks, app
mode or intent category mismatch, missing `OCULUS_APP_ID` when expected, prohibited permissions.
It reports **RISK** for gaps between Meta's generic release-manifest page and Meta's own
Bubblewrap template: minSdk 23 (page: 29-34), targetSdk 32 (page: 34 for apps created since
2026-03-01), headtracking `required=false` for immersive, no `supportedDevices`, no
`installLocation`, no `excludeFromRecents`. Meta's PWA docs don't mention any of these. Treat the
ALPHA upload's **Manage Builds > Test Status** as the authority (Packaging.1/3/4 run at upload).
If it rejects one, report it to the user with the exact message; don't patch the generated
project. It also prints the declared input (Bubblewrap: controllers and hands) as INFO.

## 6. Sideload and test on a headset

```bash
metavr device list
metavr app install --replace app-release-signed.apk      # or: adb install app-release-signed.apk
metavr adb logcat --clear
# open it from Library > Unknown Sources
metavr adb logcat | grep -i "TWA verification was unsuccessful"   # assetlinks failure
```

- `chrome://inspect/#devices` on the computer lists the PWA's tab once it is running; **inspect**
  gives DevTools (pwa-webxr FAQ).
- Immersive: launches straight into XR, no URL bar. 2D: own panel, no tab or URL bar, data and
  cookies shared with Browser (pwa-2d-support). A URL bar means asset links failed.
- IAP: the Digital Goods service exists only for Store installs (ALPHA/BETA count). For a
  sideloaded APK enable `#enable-debug-for-store-billing` in Browser `chrome://flags` (ps-iap).
- Run the device checks in `horizon-web-vrc-checklist` before uploading.

## 7. Upload to ALPHA (ask first)

First-time blockers: org verification (mandatory before publishing) and the Developer
Distribution Agreement, which an org admin signs (`hz-store-pwa` store-upload reference).

```bash
# guarded wrapper (refuses production without CONFIRM_STORE_UPLOAD=yes; --dry-run masks secrets)
META_APP_ID=... META_AGE_GROUP=TEENS_AND_ADULTS META_UPLOAD_TOKEN=... \
RELEASE_NOTES="..." scripts/upload-pwa-build.sh app-release-signed.apk alpha
```

That runs `ovr-platform-util upload-quest-build --app-id --apk --channel --age-group
(--token|--app-secret)`. Without `--age-group` the upload lands as a draft. Add
`QUEST_DEVICE_TARGETS=quest3+` to send `--channel "alpha:quest3+"` (section 7a). Alternative:
`metavr store dist upload --app-id <ID> --channel ALPHA --apk <apk> --notes "..."` (draft unless
`--publish`; channels ALPHA/BETA/RC/LIVE; no age-group or device-target option). If any
`metavr store dist` call errors, use the Dashboard instead of retrying (`hz-store-submit`).

Then: read Test Status; invite testers (Distribution > Release Channels; 200 users by default,
up to 2,500 on request; channels start with no users, not even you). Builds appear in the tester's
Library and **My Preview Apps**.

## 7a. Device targeting and Meta VR Glasses

Meta VR Glasses (spring 2027) run the same Horizon OS, Store and Browser as Quest, so a Store
PWA can reach them without a new package (app-compatibility, 2026-10-13;
target-builds-by-device, 2026-09-04):

- In the Dashboard, the build's **Supported Devices** must include **Future devices** plus each
  Quest you support. That marks it forward-compatible; after VR Glasses ship, an approved
  Production build with Future devices is delivered there with no new APK. A build with no
  targeting ("All Devices") already includes them.
- At upload: `QUEST_DEVICE_TARGETS="quest3+" scripts/upload-pwa-build.sh app.apk alpha` sends
  `--channel "alpha:quest3+"` (`quest3+` = Quest 3 family, VR Glasses, future devices; other
  specifiers: `quest2only`, `questproonly`, `quest3only`, `quest2+`, `questpro+`, `questpro-`).
  Bubblewrap writes no `com.meta.store.defaultDeviceTargets` or `com.oculus.supportedDevices`, so
  this suffix or the Dashboard is the only control. Meta's pages disagree on whether `vrglasses`
  is a valid `supportedDevices` value; don't patch the generated manifest for it.
- Rules: LIVE must always keep a forward-compatible build, every build in a submission must be
  forward-compatible, and removing a device from a live build rolls that device back (ask first).
- Before marking Future devices: hands-only play works, key UI fits 70° × 66° (IWER's VR Glasses
  profile or `metavr device fov-sim enable` on a Quest 3/3S/Pro), nothing depends on hover, and
  the VRC audit passes (there is no VR Glasses-specific VRC). Gaze-and-pinch in IWSDK:
  `iwsdk-vr-glasses`. Details: `docs/meta-reference/store-2026.md`.

## 8. Promote and release

```bash
ovr-platform-util set-release-channel-build --age-group TEENS_AND_ADULTS \
  --app-id <ID> --token <TOKEN> --source-channel alpha --destination-channel beta
metavr store dist channels --app-id <ID>        # channel ids and latest builds
metavr store dist copy-build --binary-id <BUILD_ID> --to-channel <CHANNEL_ID>
```

The first build in Production does nothing until the user fills Submission Info and clicks
**Submit for Review**. Later builds copied to Production update every entitled user
(publish-release-channels). Before that: `horizon-web-vrc-checklist`,
`horizon-store-listing-assets`, and `hz-store-submit` (use the `horizon-*` values where they differ).

## 9. Updates: redeploy or rebuild?

| Change | Action |
|---|---|
| Game code, assets, levels, UI, manifest colours, assetlinks | Redeploy the site; installed PWAs load it on next launch (`hz-store-pwa`) |
| Package id | Impossible: it's a new app |
| App mode, name, launcher name, icons, host/start URL, permissions, Billing, App ID, version | Rebuild with Bubblewrap, raise `appVersionCode`, upload, promote |
| Signing key | Impossible without a new app |

Web deploys skip Store review, but reviewed metadata must still match the app (VRC Content.2).
Keep a staging origin for testing and promote web builds to production the same way you promote APKs.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Immersive app won't launch; 2D app shows URL bar | Asset links failed | Checker + `verify-twa-apk.sh --assetlinks`; logcat `TWA verification was unsuccessful!` |
| 2D app stuck on loading | `horizonOSAppMode` is `immersive` | Set `2D`, `update`, `build`, re-upload |
| Immersive app opens a 2D page | Mode is `2D`, or no auto-enter | Fix mode; add the gated `launchXR()` |
| `.well-known` 404 after deploy | Dotfiles dropped (gh-pages, Jekyll, upload-pages-artifact v4) | See section 2 |
| `bubblewrap` hangs in CI | Interactive prompt (no checksum, changed JSON, version name) | `update --skipVersionUpgrade` first; set both version fields |
| Upload: "must first agree to our Developer Distribution Agreement" | DDA unsigned | Org admin signs it; retry |
| Upload rejected: version code | Not above every earlier upload | Raise `appVersionCode`, rebuild |
| Gradle: incompatible Java | Wrong JDK | Let Bubblewrap install its JDK or fix `jdkPath` (`bubblewrap doctor`, `updateConfig --jdkPath`) |

## Sources

Pages moved from `developers.meta.com/horizon/` to `/vr/` (old links redirect).

- https://developers.meta.com/vr/documentation/web/pwa-overview/ (2026-07-22)
- https://developers.meta.com/vr/documentation/web/pwa-overview-gs/ (2026-09-23)
- https://developers.meta.com/vr/documentation/web/pwa-packaging/ (2026-07-22)
- https://developers.meta.com/vr/documentation/web/pwa-webxr/ (2026-07-22)
- https://developers.meta.com/vr/documentation/web/pwa-2d-support/ (2026-07-22)
- https://developers.meta.com/vr/documentation/web/ps-iap/ (2026-10-14)
- https://developers.meta.com/vr/documentation/web/web-hosting/ (2026-09-23)
- https://developers.meta.com/vr/documentation/iwsdk/guides/08-build-deploy/ (2026-09-23)
- https://developers.meta.com/vr/resources/publish-mobile-manifest/ (2026-10-15)
- https://developers.meta.com/vr/resources/publish-release-channels/ (2026-03-23)
- https://developers.meta.com/vr/resources/publish-release-channels-device-targeting/ (2026-09-04)
- https://developers.meta.com/vr/essentials/app-compatibility/ (2026-10-13), /compatibility-mode/ (2026-09-04)
- https://developers.meta.com/vr/resources/publish-reference-platform-command-line-utility/ (2026-07-20)
- https://developers.meta.com/vr/resources/publish-create-app/ (2026-08-27)
- https://developers.meta.com/vr/resources/vrc-quest-packaging-1/ (and -2/ to -6/), /vrc-quest-security-2/ (2026-03-30)
- https://github.com/meta-quest/bubblewrap (main @ 2026-09-16; `packages/core/src/lib/TwaManifest.ts`, `util.ts`, `features/`, `template_project/`; `packages/cli/src/lib/cmds/{init,build,update,shared}.ts`)
- https://www.npmjs.com/package/@meta-quest/bubblewrap-cli (1.24.1, published 2026-05-05; still `latest` on 2026-10-17)
- https://github.com/facebook/immersive-web-sdk `packages/core/src/ecs/world.ts` (`World.launchXR(xrOptions?)`, main, IWSDK 1.0.1)
- https://developer.android.com/training/app-links/configure-assetlinks
- https://github.com/actions/upload-pages-artifact (v3.0.1, v4.0.0, v5.0.0 action.yml); https://github.com/tschaub/gh-pages (`--dotfiles`, `--nojekyll`)

Last verified: 2026-10-17
