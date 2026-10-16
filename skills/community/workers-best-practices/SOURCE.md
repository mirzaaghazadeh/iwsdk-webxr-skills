# Source: workers-best-practices

- **Repo:** https://github.com/cloudflare/skills
- **Path:** `skills/workers-best-practices/` (`SKILL.md`, `references/configuration.md`, `references/platform-apis.md`, `references/runtime-patterns.md`)
- **Commit:** `86505e44f87d801aa1864a3c4109e9a8ae5c409f` (2026-10-15). The skill itself last changed in `cf56dd4` (2026-10-12).
- **License:** Apache-2.0 (`LICENSE` copied from the repo root; the repo has no NOTICE file)
- **Stars at fetch:** 3079
- **Fetched:** 2026-10-16

## Why it was picked

The Worker that serves the game and routes players to their Durable Object room needs review like any server code. This is Cloudflare's own review checklist:
- an anti-pattern table: buffering unbounded bodies, hard-coded secrets, `Math.random()` for room codes or tokens, unawaited async work outside `ctx.waitUntil()`, module-level request state, hand-written `Env` types;
- binding access in platform classes (`this.env.X`), and `extends` rather than `implements`;
- serialization rules that differ between Queues, storage and WebSockets;
- compatibility dates, Workers Logs and traces.

## Security review

I read the SKILL.md and the three references. They are Markdown only. The references contain example code, including secure token generation and timing-safe comparison. It will fetch Cloudflare documentation pages.

## Caveats

- Workers-only. It does not cover the client or the game protocol.
- It points to `durable-objects`, `cf-cli` and `wrangler` by name. Install them together.
