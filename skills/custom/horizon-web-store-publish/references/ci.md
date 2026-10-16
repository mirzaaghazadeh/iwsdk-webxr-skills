# CI for a Quest PWA (GitHub Actions sketch)

Two pipelines, because web changes and APK changes ship differently:

1. **Web deploy** on every push to `main`: build, deploy to a staging origin, run
   `check-pwa-deploy.mjs`, then promote to the production origin by hand or on a tag.
2. **APK build** only when native inputs change (`twa-manifest.json`, icons, app mode, version):
   Bubblewrap build, `verify-twa-apk.sh`, upload to **ALPHA** only. Promotion to BETA/RC/Production
   and Submit for Review stay manual.

Not tested end to end here (no Developer Dashboard app or runner was used). Every command and
flag below comes from the Bubblewrap README/source, Meta's ovr-platform-util page (2026-07-20) or
GitHub's action docs. Pin versions and dry-run before trusting it.

## Secrets

| Secret | Content |
|---|---|
| `ANDROID_KEYSTORE_B64` | `base64 < android.keystore` (the one permanent key; keep the original offline too) |
| `BUBBLEWRAP_KEYSTORE_PASSWORD`, `BUBBLEWRAP_KEY_PASSWORD` | Read by `bubblewrap build` from the environment |
| `META_APP_ID` | Not secret, but convenient here |
| `META_UPLOAD_TOKEN` or `META_APP_SECRET` | User token (`ovr-platform-util get-access-token`) or App Secret (Dashboard > Development > API) |

GitHub masks secrets in logs, but `ovr-platform-util` takes them as arguments; never `set -x`.

## Workflow

```yaml
name: quest-apk
on:
  workflow_dispatch:
  push:
    tags: ['apk-v*']
jobs:
  apk:
    runs-on: ubuntu-latest
    environment: quest-alpha            # add required reviewers to this environment
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '17' }
      - name: Install Bubblewrap (pinned)
        run: npm install --global @meta-quest/bubblewrap-cli@1.24.1
      - name: Restore keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE_B64 }}" | base64 -d > twa/android.keystore
      - name: Check the live deploy first
        run: node scripts/check-pwa-deploy.mjs https://game.example.com/manifest.webmanifest --package com.studio.game
      - name: Build APK
        working-directory: twa
        env:
          BUBBLEWRAP_KEYSTORE_PASSWORD: ${{ secrets.BUBBLEWRAP_KEYSTORE_PASSWORD }}
          BUBBLEWRAP_KEY_PASSWORD: ${{ secrets.BUBBLEWRAP_KEY_PASSWORD }}
        run: |
          bubblewrap update --skipVersionUpgrade     # version code comes from twa-manifest.json in git
          bubblewrap build
      - name: Verify APK
        run: scripts/verify-twa-apk.sh twa/app-release-signed.apk --mode immersive --assetlinks https://game.example.com/.well-known/assetlinks.json
      - name: Upload to ALPHA
        env:
          META_APP_ID: ${{ secrets.META_APP_ID }}
          META_AGE_GROUP: TEENS_AND_ADULTS
          META_UPLOAD_TOKEN: ${{ secrets.META_UPLOAD_TOKEN }}
          OVR_PLATFORM_UTIL: ./ovr-platform-util
          RELEASE_NOTES: ${{ github.ref_name }}
        run: scripts/upload-pwa-build.sh twa/app-release-signed.apk alpha
```

Points to adapt:

- **First run:** Bubblewrap asks to install its JDK and Android SDK when its config is empty. In
  CI either pre-create `~/.bubblewrap/config.json` with `jdkPath` and `androidSdkPath` (or run
  `bubblewrap updateConfig --jdkPath=... --androidSdkPath=...`) or cache `~/.bubblewrap`. Run
  `bubblewrap doctor` to confirm.
- **ovr-platform-util:** download the Linux binary (Meta labels it experimental:
  `https://www.oculus.com/download_app/?id=5159709737372459&access_token=OC%7C5159709737372459%7C`),
  `chmod +x`, and run `./ovr-platform-util version`. Or run the upload step on a macOS runner with
  the macOS build from `/downloads/package/platform-utils-cli-osx/`.
- **Version code:** commit `appVersionCode` changes in `twa-manifest.json` and keep
  `--skipVersionUpgrade`, so the uploaded code is reviewable and never collides with a
  previous upload.
- **No production from CI:** the wrapper refuses `store` without `CONFIRM_STORE_UPLOAD=yes`; don't
  set it in workflows. Promote with `ovr-platform-util set-release-channel-build` from a
  manual job or the Dashboard, after the VRC checklist.
- **`bubblewrap build` also writes `app-release-bundle.aab`.** The Horizon Store takes the APK.
