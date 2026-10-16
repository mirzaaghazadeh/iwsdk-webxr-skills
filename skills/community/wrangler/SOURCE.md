# Source: wrangler

- **Repo:** https://github.com/cloudflare/skills
- **Path:** `skills/wrangler/SKILL.md`
- **Commit:** `86505e44f87d801aa1864a3c4109e9a8ae5c409f` (2026-10-15). The skill itself last changed in `cf56dd4` (2026-10-12).
- **License:** Apache-2.0 (`LICENSE` copied from the repo root; the repo has no NOTICE file)
- **Stars at fetch:** 3079
- **Fetched:** 2026-10-16

## Why it was picked

For a project that already has `wrangler.jsonc` (for example, one that serves the Vite build as Workers static assets and runs a multiplayer Durable Object), this is Cloudflare's own guidance. It is retrieval-first and safety-conscious:
- use the project's Wrangler version and installed config schema, not memorized flags;
- keep secrets out of arguments, code and logs, and treat `wrangler secret put` as a deployment;
- Preview URLs are public unless access controls are set, and the user decides;
- validate with `wrangler deploy --dry-run` and regenerate types with `wrangler types`;
- the Cloudflare Vite plugin selects the environment at build time.

It also links the Pages-to-Workers migration guide, which matters if your site started on Cloudflare Pages.

## Security review

I read the SKILL.md in full. It is Markdown only. It will fetch Cloudflare documentation pages.

## Caveats

- It routes new projects without a Wrangler config to the `cf-cli` skill. Install both.
- Workers Previews need project-local Wrangler 4.135.0 or later.
- Remote commands need your Cloudflare login or API token. The skill asks for the narrowest scope and never asks you to paste a token into chat.
