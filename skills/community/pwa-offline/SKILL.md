---
name: pwa-offline
description: 'Use for service-worker strategy, the update flow, lazy-chunk-404 recovery after deploy, cache versioning, offline fallback, client storage, version skew across deploys, and the CDN/deploy headers that pin a broken worker. Fixes service-worker P-501..P-519, P-549, P-560..P-561; version-skew P-520..P-531; and build-deploy P-562, P-1101..P-1105. Trigger phrases: "users are stuck on the old version", "white screen after deploy", "service worker won''t update", "add offline support", "chunk 404 after release", "cache-first is serving stale HTML", "sw.js is cached by the CDN".'
---

# pwa-offline

The highest-stakes area: a wrong service worker can pin every user to a dead build with
**the fix itself trapped behind the cache**. Covers service-worker entries
(**P-501..P-519**, **P-549**, **P-560..P-561**), version skew (**P-520..P-531**), and
build/deploy (**P-562**, **P-1101..P-1105**).

**Audit first:**

```bash
node "<pwa-audit-skill-dir>/scripts/run-audit.mjs" "<path-to-app>"
```

Resolve `<pwa-audit-skill-dir>` from the selected `pwa-audit/SKILL.md`, not from the target
repository.

Static detection here classifies fetch-handler *strategy* and greps headers config — a
heuristic, not proof. **The authoritative test is deploy A → deploy B on an existing
client** (P-512): the single most valuable runtime test in the suite. The bundled
`packages/deploy-harness` proves the harness checks against its fixtures; it does not prove
an arbitrary repository. Require an explicit project deploy adapter or manual A→B evidence.

## The one that ends companies: caching strategy

- **P-502** — **Network-first** (or stale-while-revalidate with a fast timeout) for
  `request.mode === 'navigate'`. Cache-first **only** for content-hashed immutable assets.
  Cache-first on HTML pins users to the old app forever and makes the fix un-shippable.
- **P-506** — never cache or serve cached responses for non-GET requests; branch on
  `request.method === 'GET'` before any cache read/write.
- **P-507** — don't blanket-cache cross-origin `no-cors` (opaque) responses — unknown
  status (a 404 caches happily) and padded quota. Scope caching to same-origin.
- **P-515** — preserve the original `credentials` mode when re-issuing requests, or
  installed users get random 401s.
- **P-516** — forward `Range` headers and return `206` for media, or Safari won't seek/play.

## The update flow — and its two opposite mistakes

- **P-503** — new SW sits in `waiting` forever. Detect `updatefound` → `installed` **with
  an existing controller** → surface a non-blocking "Update available — reload", then
  `skipWaiting` + `clients.claim` **on user confirmation**.
- **P-504** — the inverse, and agents love it as a "fix" for P-503: `skipWaiting()` fired
  unconditionally swaps assets under a live tab → the running bundle requests chunks that
  no longer exist → white screen mid-session. Only after user-confirmed reload, or paired
  with a controlled reload on `controllerchange`.
- **P-505** — lazy chunk 404s after deploy (the most common real-world PWA outage). Ship a
  global dynamic-import error handler that force-reloads **once** (guarded against reload
  loops), plus a retention window for old chunks on the origin.
- **P-512** — the update path is never tested. Ship the two-build harness: serve A,
  install, swap origin to B (delete A's hashed chunks), assert convergence.

## Caching hygiene, offline, storage

- **P-501** — a manifest alone is not a PWA; register a SW that actually controls the origin.
- **P-508** — SW scope. `/static/sw.js` can only control `/static/`. Serve from the origin
  root or set `Service-Worker-Allowed`.
- **P-509** — a precached offline document for failed navigations; enable `navigationPreload`.
- **P-510** — versioned cache names + delete non-current caches on `activate`.
- **P-511** — catch `QuotaExceededError` on Cache/IndexedDB writes; evict, surface a diagnostic.
- **P-513** — register the SW **only in production** (`NODE_ENV === 'production'`) and ship an unregister-and-clear escape hatch. A dev-active SW eats hours to stale output.
- **P-514** — **`Cache-Control: no-cache` on `sw.js` and the manifest.** Long immutable TTLs only on hashed assets. A CDN that pins the worker means users can never receive the fix.
- **P-517** — IndexedDB for meaningful offline data, not `localStorage` (~5MB, synchronous). Treat client storage as evictable for infrequently-used installs and browser tabs; request persistence where it matters.
- **P-518** — don't trust `navigator.onLine` (reports "online" on captive portals); confirm with a real request.
- **P-519** — feature-detect Background/Periodic Sync (`'sync' in registration`) with a foreground fallback.
- **P-549** — mobile notifications must use service-worker
  `registration.showNotification()`, not page-context `new Notification()`. Coordinate the
  permission/subscription UX with `pwa-push-permissions`; keep one worker and test click
  focus/open behavior.
- **P-560** — generate precache URLs from the actual build output. One stale URL makes
  atomic `cache.addAll()` reject the entire install; surface that failure to telemetry.
- **P-561** — catch and report every `serviceWorker.register()` rejection, and keep the
  worker path out of SPA catch-all rewrites so HTML is never served as `sw.js`.

## §5b — Version skew & stale client state

This is where "works on my clean profile, wedges every existing user" bugs live. **P-521 is
the keystone** — without a client build stamp, nothing else here has anything to key off.

- **P-521** — embed a build ID at build time, expose it (meta tag/global), send it with API requests.
- **P-520** — version the auth-cookie name on any breaking change and explicitly clear the old one (or read both shapes for one release). A deliberate migration, never implicit — else existing clients wedge in a redirect loop.
- **P-522** — version the API, or advertise a minimum supported client, so an old cached shell against a new API forces an update instead of a silent blank.
- **P-523** — purge all user-scoped caches + IndexedDB + storage on logout **and identity change**. Retaining user A's data for user B on a shared device is a privacy incident, not a glitch.
- **P-524** — cache names derive from the build ID; `activate` deletes every non-current cache (same pattern as P-510).
- **P-525** — version the persisted client schema; migrate or discard on read; wrap hydration in a fallback-to-clean path so build B doesn't white-screen on build A's stored state.
- **P-526** — never cache responses to credentialed requests unless keyed by identity and purged on logout.
- **P-527** — ship a reachable reset route that unregisters SWs, deletes caches, clears storage, reloads. The goal: support can fix a wedged user in one sentence.
- **P-528** — the SW carries its build ID and declines to serve a mismatched shell; converge on one build.
- **P-529** — set auth cookies **server-side via `Set-Cookie`**; Safari ITP caps client-set (`document.cookie`) cookies at 7 days regardless of `max-age`, silently signing users out weekly.
- **P-530** — `Secure` + a deliberate `SameSite`/partitioning on auth cookies, tested through the real install → sign-in → relaunch path (standalone launch differs from the browser tab).
- **P-531** — distinguish optional from **mandatory** updates; a server-signalled minimum version triggers a forced reload. P-503's polite banner is wrong when the old client cannot work.

## §11 — Build, deploy & platform config

- **P-562** — hard-refresh representative deep routes and configure the repository's real
  host to rewrite client-side routes to `index.html` without rewriting `sw.js`, manifests,
  assets, APIs, or `.well-known` endpoints.
- **P-1101** — on subpath deploys, set the build base path, manifest paths, and SW registration scope **consistently** to the real subpath (they break together otherwise).
- **P-1102** — `Cache-Control: no-cache` on `sw.js`/manifest at the **server/CDN** layer (same as P-514, stated separately because it lives in config, not app code, and survives every app-side fix).
- **P-1103** — configure the framework PWA plugin (`next-pwa`/`vite-plugin-pwa`) for the actual mode (App Router / static export / middleware); verify the precache manifest targets the real output dir.
- **P-1104** — run a Lighthouse/PWA installability audit in the release process and require a pass before calling PWA work done.
- **P-1105** — publish a correct `.well-known/assetlinks.json` **only** when shipping to Play via TWA (else the URL bar stays visible).

## Standalone vs superpowers

Works standalone. When `superpowers` is available (detect **by capability** — is
`test-driven-development` invocable now? — never by path-sniffing):

- **`test-driven-development`** — when a project adapter exists, the deploy-A→B harness is
  the failing test: run it against the current SW, watch it wedge/404, apply the strategy
  fix, watch it converge. The bundled fixture run is only harness self-conformance.
- **`verification-before-completion`** / `pwa-verify` — hard done-gate. §5 work is not
  done until the update-path test (P-512, P-1203) passes and the app has been tested
  offline (P-1204). A green build is not runtime evidence (P-1210).

Absent superpowers, run the two-build test by hand: build A, install (DevTools →
Application → Service Workers), deploy B with A's chunks removed, reload, and assert the
client reaches B with no stale HTML, no chunk 404, no reload loop. Then test airplane-mode navigation.
