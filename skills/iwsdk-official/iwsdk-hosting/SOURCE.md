# Source: iwsdk-hosting

| Field | Value |
|---|---|
| Repository | https://github.com/facebook/immersive-web-sdk |
| Path | `packages/create/guidance/claude/.claude/skills/iwsdk-hosting/` |
| Commit | `0778f518db51e9d1836977f3b6fed9b53f3f0c6f` (2026-10-01, IWSDK 1.0.1) |
| Also shipped in | `@iwsdk/create@1.0.1` (every new project) |
| License | MIT (`LICENSE`) |
| Fetched | 2026-10-16 |

## Why it was picked

Gets an IWSDK app onto a public HTTPS origin before PWA packaging. It asks first whether a host
exists; recommends Vercel otherwise; for an existing host it prepares files and hands off exact
upload steps (Netlify, Cloudflare Pages, GitHub Pages, S3 + CloudFront, Firebase, nginx/Apache).
Its reachability contract checks the manifest MIME type, `/.well-known/assetlinks.json`, and that
`/android.keystore` returns 404.

## Caveats

- Deploys are public and outward-facing. The skill asks first; keep it that way.
- `npx -y vercel@latest` and the other `npx -y` deploy CLIs run unpinned latest versions.
- Store-side steps (listing, review) are covered by the library's store skills.

## Security review

Read in full (SKILL.md, `vercel.md`, `existing-hosts.md`). Markdown only. Tokens are only read
from environment variables (`$VERCEL_TOKEN`). No injection.
