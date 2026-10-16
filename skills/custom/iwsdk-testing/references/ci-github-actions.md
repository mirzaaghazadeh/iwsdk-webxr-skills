# CI for an IWSDK app (GitHub Actions)

A starting point, not a tested template: the shape follows IWSDK's own workflow
(`.github/workflows/native-scene-editor.yml`: Node 22, install, `playwright install --with-deps
chromium`, then tests) adapted to a single app. Ask the user before adding a workflow file.

```yaml
# .github/workflows/iwsdk-ci.yml
name: IWSDK app checks
on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  check:
    runs-on: ubuntu-latest
    env:
      METAVR_SKIP_DOWNLOAD: '1'   # skip the metavr binary download in @meta-quest/metavr's postinstall
      IWSDK_GPU: swiftshader      # runners have no GPU; make the choice explicit
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: npm

      - run: npm ci                # commit package-lock.json

      - name: Install Playwright Chromium for the version IWSDK resolved
        run: |
          PW=$(node -p "require('playwright/package.json').version")
          npx -y "playwright@${PW}" install --with-deps chromium

      - run: npm run --if-present typecheck
      - run: npm run build

      - name: Asset check
        run: find public \( -name '*.glb' -o -name '*.gltf' \) -exec node scripts/check-gltf.mjs {} +

      - name: Runtime smoke test
        run: scripts/iwsdk-smoke.sh --out artifacts/smoke

      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: smoke-artifacts
          path: artifacts/
```

Copy `check-gltf.mjs` (from `iwsdk-asset-pipeline/scripts/`) and `iwsdk-smoke.sh` (from
`iwsdk-testing/scripts/`) into the project's `scripts/` folder first.

Notes:

- `require('playwright/package.json')` assumes npm hoisted Playwright (a dependency of
  `@iwsdk/vite-plugin-dev`, `^1.58.2` in 1.0.1) to the top of `node_modules`. If it fails, read
  the version from `npm ls playwright` instead. Mismatched browser revisions fail with
  "Executable doesn't exist at …/chromium_headless_shell-…".
- SwiftShader makes frames 10x slower than a GPU. Never gate CI on frame time; gate on state.
- Smoke runs need the dev server's port (8081 by default) free on the runner.
- Store-build steps (Bubblewrap, signing, `ovr-platform-util`) don't belong in this job; they
  need secrets and the user's approval (`iwsdk-pwa-packaging`).
- Unverified: whether `dev up` needs extra Linux flags in a container runner. If the managed
  browser fails to launch, read `npx @iwsdk/cli dev logs --tail 200` and
  `npx @iwsdk/cli runtime status`.
