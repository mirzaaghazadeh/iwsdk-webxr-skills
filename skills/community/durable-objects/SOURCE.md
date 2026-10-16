# Source: durable-objects

- **Repo:** https://github.com/cloudflare/skills
- **Path:** `skills/durable-objects/` (`SKILL.md`, `references/rules.md`, `references/testing.md`, `references/workers.md`)
- **Commit:** `86505e44f87d801aa1864a3c4109e9a8ae5c409f` (2026-10-15). The skill itself last changed in `41e0d19` (2026-10-01).
- **License:** Apache-2.0 (`LICENSE` copied from the repo root; the repo has no NOTICE file)
- **Stars at fetch:** 3079
- **Fetched:** 2026-10-16

## Why it was picked

It is the best-maintained redistributable skill found for a small web multiplayer backend. A Durable Object per game room gives one authoritative, strongly consistent instance with WebSockets and SQLite storage, with no server to run. The skill covers:
- modelling around coordination atoms: one object per room, never one global object;
- deterministic routing with `getByName("room-123")`, SQLite storage, and schema setup in `blockConcurrencyWhile`;
- WebSocket hibernation for idle rooms, with state restored afterwards;
- alarms for timeouts, and persist-before-cache rules;
- the anti-patterns, and a testing reference for Cloudflare's Vitest integration.

Durable Objects are also what PartyKit runs on, so the concepts carry over if you choose it.

## Security review

I read the SKILL.md and the three references. They are Markdown only. Example code reads secrets from `env`, set with `wrangler secret put`. It will fetch Cloudflare documentation pages.

## Caveats

- **It covers the server, not netcode.** Interpolation, client prediction, tick rates and interest management for a VR game are up to you.
- Cloudflare-specific. No maintained, redistributable Colyseus or WebRTC skill was found (see `docs/community-candidates.md`).
- Install it with `workers-best-practices` and `wrangler` or `cf-cli`, which it refers to.
