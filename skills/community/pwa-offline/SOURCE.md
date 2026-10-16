# Source: pwa-offline

- **Repo:** https://github.com/AQaddora/pwa-skill-suite
- **Path:** `skills/pwa-offline/` (`SKILL.md`, `agents/openai.yaml`)
- **Commit:** `6aeb6b330aa2ac0c79bb75f64505295e92696a68` (2026-08-31). The skill itself last changed in `3d99d91` (2026-08-05).
- **License:** MIT, Copyright 2026 pwa-skill-suite contributors (`LICENSE` copied from the repo root)
- **Stars at fetch:** 2
- **Fetched:** 2026-10-16

## Why it was picked

A Horizon Store PWA still loads from your web origin, so a bad service worker can strand every installed user on a dead build. This skill is a catalog of the service-worker and deploy mistakes agents make, each with a fix:
- network-first for navigations and cache-first only for content-hashed assets, so HTML is never pinned;
- the update flow: surface "update available" and call `skipWaiting` only on user confirmation, never unconditionally;
- recovery from lazy-chunk 404s after a deploy, with a reload-once guard;
- `Cache-Control: no-cache` on `sw.js` and the manifest at the CDN, versioned cache names, precache lists generated from the real build output;
- version skew: a build ID, a reset route, and a test that deploys build A, then build B, to an existing client.

It also includes a check that `vite-plugin-pwa` precaches the real build output, which fits IWSDK's Vite build. No Quest-specific PWA skill passed review, and this one is engine-neutral.

## Security review

I read the SKILL.md and `agents/openai.yaml` in full. Both are text only. The YAML is display metadata for Codex.

## Caveats

- **Its "Audit first" step will not run from this folder.** It calls `scripts/run-audit.mjs` from the sibling `pwa-audit` skill, which needs the suite's JavaScript scanner runtime. Neither was collected. Skip that step, or review and install the full suite separately.
- References to the `superpowers` skills (`test-driven-development`, `verification-before-completion`) are optional. The skill works without them.
- Written for mobile PWAs. The Safari items (Range requests, ITP cookie caps) do not apply on Quest Browser.
- Large GLB and KTX2 files count against the browser's storage quota. Precache only what the first scene needs.
- For Horizon Store packaging and `assetlinks.json`, follow Meta's Bubblewrap instructions in the Meta skills, not the Play Store note in this skill.
- A new repo with 2 stars, so the content was judged on its own merit.
