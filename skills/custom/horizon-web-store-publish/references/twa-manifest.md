# twa-manifest.json for Meta Quest: fields, defaults, generated output

Read from the source of `meta-quest/bubblewrap` (`main` at commit 2026-09-16, "Default TWA
manifest fields the Gradle template renders unquoted"; still the latest commit on 2026-10-17).
npm `@meta-quest/bubblewrap-cli` 1.24.1 was published 2026-05-05 (registry entry last modified
2026-08-14; an earlier version of this note said "published 2026-08-14"), so a few defaults may
differ slightly in the release you run. Check with `bubblewrap --version`. The canonical schema
is `bubblewrap/packages/core/src/lib/TwaManifest.ts`.

## Template for an immersive IWSDK game (agent / non-TTY path)

```json
{
  "packageId": "com.studio.orbitgarden",
  "host": "orbitgarden.example.com",
  "name": "Orbit Garden",
  "launcherName": "Orbit",
  "display": "standalone",
  "orientation": "default",
  "themeColor": "#0A0418",
  "themeColorDark": "#000000",
  "backgroundColor": "#06010F",
  "startUrl": "/",
  "iconUrl": "https://orbitgarden.example.com/icons/icon-512.png",
  "maskableIconUrl": "https://orbitgarden.example.com/icons/icon-512-maskable.png",
  "webManifestUrl": "https://orbitgarden.example.com/manifest.webmanifest",
  "fullScopeUrl": "https://orbitgarden.example.com/",
  "signingKey": { "path": "/abs/path/outside/web/android.keystore", "alias": "android" },
  "appVersionCode": 1,
  "appVersion": "1.0.0",
  "applicationId": "0",
  "fallbackType": "customtabs",
  "enableNotifications": false,
  "enableMicrophone": false,
  "enableXRScene": false,
  "isMetaQuest": true,
  "horizonOSAppMode": "immersive",
  "minSdkVersion": 23,
  "features": { "horizonPlatformSDK": { "enabled": false } },
  "fingerprints": [],
  "additionalTrustedOrigins": []
}
```

`init --metaquest` writes `horizonPlatformSDK` enabled. Turn it off unless the app calls a
Platform SDK feature: it bundles native libraries for four ABIs (see the field reference). With
it off and no billing, the APK has no native code (692 KB instead of 6 MB, observed 2026-10-24).

For a 2D app: `"horizonOSAppMode": "2D"`, `display` `standalone` (Meta's recommendation), and
`orientation` `landscape` or `portrait`. For IAP in a WebXR PWA, add the App ID and billing:

```json
  "applicationId": "<16- or 17-digit Horizon App ID>",
  "alphaDependencies": { "enabled": true },
  "features": {
    "horizonPlatformSDK": { "enabled": false },
    "horizonBilling": { "enabled": true, "horizonOSAppMode": "immersive" }
  }
```

Billing alone still bundles the platform library's native code; strip the non-`arm64-v8a` ABIs
after `build` (SKILL.md section 4). An app shipped this way (billing on, platform SDK off) passed
upload validation; its purchase flow on a headset was still untested when this was written
(unverified).

## Field reference (Meta-relevant subset)

| Field | Default in source | Notes |
|---|---|---|
| `packageId` | reversed host + `.twa` (`generatePackageId`) | Permanent. Choose deliberately |
| `host` | manifest URL host | Must be the exact host that serves assetlinks (no redirect) |
| `name` / `launcherName` | manifest `name` / `short_name` (else `name` cut to 12) | `init` validates 1-50 and 1-12 characters |
| `startUrl` | manifest `start_url` path + query | Keep within scope |
| `fullScopeUrl` | manifest `scope` (else the manifest directory) | Written by `init`; Quest template exposes it as a resource |
| `display` | `standalone` | `init` forces `standalone` and orientation `default` for immersive; asks for 2D |
| `iconUrl`, `maskableIconUrl` | largest `any` / `maskable` icon, only if >= 512 px | `iconUrl` empty fails validation |
| `monochromeIconUrl` | largest `monochrome` icon >= 48 px | Optional |
| `appVersionCode` / `appVersion` | 1 / "1" | The JSON key for the name is `appVersion`; the class field is `appVersionName` (`TwaManifest.ts`: `this.appVersionName = data.appVersion`), and a JSON key `appVersionName` is ignored, giving an empty `versionName`. `update` adds 1 to the code and, if the name equalled the old code, sets the name to the new code; otherwise it prompts for a name. `--skipVersionUpgrade` skips this; the CLI flag `--appVersionName` sets the name |
| `applicationId` | `"0"` | Horizon App ID. `"0"` builds and sideloads without IAP. Written to `com.meta.horizon.platform.ovr.OCULUS_APP_ID` when set |
| `isMetaQuest` | `false` | `init --metaquest` sets `true` |
| `horizonOSAppMode` | `immersive` | Values: `immersive`, `2D` |
| `minSdkVersion` | 21 (core); `init --metaquest` sets 23 | See SDK note below |
| `enableNotifications` | `true` when created by `init` from a web manifest; `false` when the field is absent from a hand-written JSON (main) | `true` adds `POST_NOTIFICATIONS` (review-required on Quest) |
| `enableMicrophone` | `false` | `true` adds `RECORD_AUDIO` (review-required) |
| `enableXRScene` | `false` | `true` adds `com.oculus.permission.USE_SCENE` |
| `features.horizonPlatformSDK` | enabled by `init --metaquest` | Adds `horizonpermissions` 1.0.0 and `horizonplatformsdk` 1.1.0 handlers to the delegation service. Also bundles `libovrplatformloader.so`, `libpsdk_jni.so` and `libc++_shared.so` for `arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64` (1.24.1 build, `aapt2 dump badging`, 2026-10-24) |
| `features.horizonBilling` | off | Adds `horizonbilling` 1.0.0-alpha11, `PaymentActivity` for `https://quest.meta.com/billing`, `PaymentService`, and `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`. Ignored unless `alphaDependencies.enabled`. Bundles the same four-ABI native libraries, even with `horizonPlatformSDK` off |
| `fallbackType` | `customtabs` | `webview` adds `INTERNET` |
| `fingerprints` | `[]` | Managed by `bubblewrap fingerprint add/remove/list/generateAssetLinks` |
| `additionalTrustedOrigins` | manifest `additional_trusted_origins` | Multi-origin 2D apps; each origin needs assetlinks |
| `signingKey` | `./android.keystore`, alias `android` (relative to the project dir) | Keep the project dir outside the web tree |

## What the Quest template generates

From `packages/core/template_project/app/build.gradle` and `src/main/AndroidManifest.xml`:

- `compileSdkVersion 32` and `targetSdkVersion 32` when `isMetaQuest` (36 / 35 otherwise);
  `minSdkVersion` from the JSON.
- Always for Quest: `com.oculus.permission.HAND_TRACKING`; `uses-feature
  android.hardware.vr.headtracking required="false" version="1"`; `uses-feature
  oculus.software.handtracking required="false"`.
- Launcher intent: `MAIN` + `LAUNCHER` + `com.oculus.intent.category.VR` (immersive) or
  `com.oculus.intent.category.2D` (2D).
- Meta-data `horizonos.pwa.APP_MODE` = `@string/horizonOSAppMode`. 2D also sets
  `com.oculus.vrshell.uses_secure_layer=secure`. Immersive sets
  `com.oculus.ossplash.background=passthrough-contextual` ("seamless AR to AR transitions").
- No `com.oculus.supportedDevices`, no `com.meta.store.defaultDeviceTargets`, no
  `android:installLocation`, no `excludeFromRecents` on the launch activity; release build type
  has `minifyEnabled true`. No native code of its own: native libraries come only with
  `horizonPlatformSDK` or `horizonBilling`, in four ABIs. Keep only `arm64-v8a` for the 64-bit
  rule (Packaging.6).
- Build toolchain: build-tools 34.0.0 (`BUILD_TOOLS_VERSION`), Gradle 8.11.1, Android Gradle
  Plugin 8.9.1.
- The `oculus.software.handtracking required="false"` + `HAND_TRACKING` pair is what Meta's
  app-compatibility page (2026-10-13) calls "controllers and hands" support. Every Quest TWA
  declares it, in both modes. Device targeting is set at upload (`--channel "alpha:quest3+"`) or
  in the Dashboard (Supported Devices, incl. Future devices); see SKILL.md section 7a.

## SDK-level note (unresolved)

Meta's release-manifest page (2026-10-15) asks for minSdk 29-34 and says apps created since
2026-03-01 must set targetSdk 34; immersive apps need `headtracking required="true"`. Meta's own
Bubblewrap emits 23 / 32 / `required="false"`, and Meta's PWA docs (2026-07-22) are silent on
SDK levels. Nothing on developers.meta.com says whether the upload checks exempt TWAs.
Still unresolved on 2026-10-17 (no Bubblewrap release and no page change since).
**Unverified: confirm at https://developers.meta.com/vr/resources/publish-mobile-manifest/
and with the first ALPHA upload's Test Status.** One data point (2026-10-24): an immersive
1.24.1 APK with minSdk 23 / targetSdk 32 / `required="false"` passed the Dashboard's APK
validation and reached Test Status Complete. Don't edit `app/build.gradle` by hand to work
around it: `bubblewrap update` overwrites it. If the upload is rejected, report the exact message
and check https://github.com/meta-quest/bubblewrap for a newer release.

## Commands (Bubblewrap CLI README)

| Command | Use |
|---|---|
| `bubblewrap init --manifest=<url> --metaquest [--directory=<dir>]` | Interactive project creation |
| `bubblewrap update [--skipVersionUpgrade] [--appVersionName=<v>] [--manifest=<path>]` | Regenerate the Android project from the JSON |
| `bubblewrap build [--skipPwaValidation] [--skipSigning] [--signingKeyPath=] [--signingKeyAlias=] [--manifest=]` | Gradle build, zipalign, apksigner. Passwords from `BUBBLEWRAP_KEYSTORE_PASSWORD` and `BUBBLEWRAP_KEY_PASSWORD` |
| `bubblewrap fingerprint add <sha256> [--name=]`, `list`, `remove`, `generateAssetLinks` | Manage assetlinks fingerprints |
| `bubblewrap install [--apkFile=]` | adb install to a connected device |
| `bubblewrap validate --url=<pwa-url>` | Google's TWA quality criteria (Play-oriented) |
| `bubblewrap doctor`, `bubblewrap updateConfig --jdkPath= --androidSdkPath=` | Toolchain checks and paths. Without a TTY, `updateConfig` crashes; edit `~/.bubblewrap/config.json` instead. `doctor` wants `bin/` or `tools/` under the SDK path (SKILL.md section 4) |
