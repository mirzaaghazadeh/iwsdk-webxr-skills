# Hosting a Quest PWA: origins, asset links, headers

Meta's requirements ("Host your web experience", 2026-09-23): serve the site over HTTPS from a
publicly accessible origin and serve the static build. For Store packaging the origin also has
to serve `/.well-known/assetlinks.json` (pwa-packaging, 2026-07-22). Android's hosting rules for
that file (developer.android.com/training/app-links/configure-assetlinks): at
`https://<host>/.well-known/assetlinks.json`, `Content-Type: application/json`, over HTTPS,
"without any redirects (no 301 or 302 redirects)", on every host.

Check any host with:

```bash
curl -sI https://<DOMAIN>/.well-known/assetlinks.json      # expect 200, application/json, no Location
node scripts/check-pwa-deploy.mjs https://<DOMAIN>/manifest.webmanifest --package <id> --sha256 <fp>
```

## Vercel (Meta's walkthrough)

- `npx vercel@latest deploy --prod --yes [--scope <team-slug>]`. Vercel detects Vite, runs
  `vite build`, serves `dist/`. Meta's page uses the default `base: "/"` at the root; the IWSDK
  1.0.1 scaffold's relative `"./"` also works, so don't change a scaffolded project.
- Use the production domain or alias Vercel prints. With Deployment Protection, per-deploy URLs
  return 401; the shared URL must return 200 without auth (Meta).
- `public/.well-known/assetlinks.json` is copied into `dist/` by Vite and served as a static file.
- If you add SPA rewrites, exclude `/.well-known/` so a missing file is a 404, not `index.html`
  with 200. The checker flags HTML responses.

## GitHub Pages

- **Project site** `https://<user>.github.io/<repo>/`: the origin root belongs to the user site,
  so the TWA's `/.well-known/assetlinks.json` cannot live in this repo. Use a user/org site
  (`<user>.github.io` repo) or a custom domain for Store builds.
- **Branch deploy** (`npx gh-pages -d dist`, Meta's option A): the `gh-pages` CLI ignores
  dotfiles unless `-t/--dotfiles` is passed, and GitHub's Jekyll build skips dot-folders unless
  a `.nojekyll` file exists (`--nojekyll`). Use `npx gh-pages -d dist --dotfiles --nojekyll`.
- **Actions deploy** (Meta's option B uses `actions/upload-pages-artifact@v3`): v3.0.1 keeps
  dotfiles; **v4.0.0 excludes them** ("Potentially breaking change: hidden files ... will not be
  included"); v5.0.0 (2026-04-10) adds `include-hidden-files: true`. If you upgrade, add:

  ```yaml
  - uses: actions/upload-pages-artifact@v5
    with:
      path: ./dist
      include-hidden-files: true
  ```
- Set Vite `base` to `/<repo>/` only for project sites (Meta); `/` for user sites and custom
  domains.

## Custom domains and other hosts

- Choose the canonical host (apex or `www`) before the first build. `host` in
  `twa-manifest.json` must be the host that serves the files directly; a redirect between apex
  and `www`, or from `http` to `https` on the assetlinks path, fails verification.
- Any static host works if it meets the rules above (Meta: "Any host that meets the requirements
  works"). Netlify, Cloudflare Pages, S3/CloudFront and others are not covered by Meta's docs;
  verify each with `curl -sI` and the checker.

## Headers and MIME types worth setting

| File | Content-Type | Why |
|---|---|---|
| `manifest.webmanifest` | `application/manifest+json` | Registered type; `hz-store-pwa` requires it |
| `.well-known/assetlinks.json` | `application/json` | Android hosting rule |
| `.wasm` (Havok physics, Basis/Draco decoders) | `application/wasm` | Streaming compilation needs it (MDN, `WebAssembly.instantiateStreaming`) |
| `.glb` / `.gltf` | `model/gltf-binary` / `model/gltf+json` | IANA types; most hosts already map them |
| `.ktx2` | `image/ktx2` | IANA type |

- **CORS:** assets loaded from another origin (CDN) need `Access-Control-Allow-Origin`.
  `hz-iwsdk-webxr` notes that Quest Browser enforces CORS strictly and failures are silent without
  DevTools attached.
- **Caching:** installed PWAs fetch the site on launch. Use hashed asset names (Vite default) and
  short cache lifetimes on `index.html` and the manifest so web-only updates reach users.
- **Offline:** an installed PWA still loads from the network. VRC Functional.7 (Recommended) asks
  apps that need the internet to tell users when it is missing; a service worker with an offline
  page is one way. Meta's PWA docs don't require a service worker.

## Keep secrets off the host

The keystore, `twa-manifest.json`, `.env` files and the App Secret never go in `public/` or
`dist/`. `hz-store-pwa` suggests `curl -o /dev/null -w "%{http_code}" https://<DOMAIN>/android.keystore`
(expect 404). If a key was ever public, treat it as compromised: a published app can't change
its key, so tell the user immediately.
