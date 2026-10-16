# Source: iwsdk-migrate-0-5

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `docs/public/skills/iwsdk-migrate-0-5/SKILL.md` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also served at | https://iwsdk.dev/skills/iwsdk-migrate-0-5/SKILL.md (identical on 2026-10-16) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

The official migration from IWSDK 0.4.x to 0.5.0, the release that replaced GLXF levels and the
Meta Spatial Editor with native scene JSON and the managed editor, retired
`@iwsdk/vite-plugin-uikitml`, `@iwsdk/vite-plugin-gltf-optimizer`,
`@iwsdk/vite-plugin-metaspatial` and `vite-plugin-mkcert`, and moved settings into
`iwsdk.config.json`. Many tutorials and older projects still use the 0.4 setup. It has strict
safety rules (check `git status`, checkpoint, inventory before deleting) and a parity checklist.

## Caveats

- It targets **0.5.0**. There is no separate 0.5 → 1.0 skill. After migrating, move every
  `@iwsdk/*` package to the same 1.x version and read `packages/core/CHANGELOG.md` 1.0.0: physics
  runs in a worker by default, an occupied `server.port` now fails instead of moving, and apps
  must use `"three": "npm:super-three@0.181.0"` plus the matching `overrides` entry.
- Not generated into new projects (they start on 1.x).

## Security review

Read in full. Markdown only; it explicitly forbids resets, cleans and unrequested commits.
No injection.
