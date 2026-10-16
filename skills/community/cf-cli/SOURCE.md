# Source: cf-cli

- **Repo:** https://github.com/cloudflare/skills
- **Path:** `skills/cf-cli/SKILL.md`
- **Commit:** `86505e44f87d801aa1864a3c4109e9a8ae5c409f` (2026-10-15). The skill itself last changed in `d7de390` (2026-10-12).
- **License:** Apache-2.0 (`LICENSE` copied from the repo root; the repo has no NOTICE file)
- **Stars at fetch:** 3079
- **Fetched:** 2026-10-16

## Why it was picked

A Quest PWA needs an HTTPS host that also serves `/.well-known/assetlinks.json`. Cloudflare is a common free choice, and these are Cloudflare's own skills. For a new project with no Wrangler config, Cloudflare now tells agents to use its `cf` CLI (beta) rather than Wrangler. This skill covers:
- choosing between `cf` and Wrangler from the files in the project;
- finding commands with `cf cli search` and `cf schema` instead of guessing;
- safe use: `--dry-run` first, aborted deletes that still exit 0, and `--force` that can also be an API parameter;
- `CLOUDFLARE_API_TOKEN` for CI instead of an interactive login.

Install it together with `wrangler`, `durable-objects` and `workers-best-practices`. They refer to each other by name.

## Security review

I read the SKILL.md in full. It is Markdown only. It tells the agent to prefer retrieval, so it will fetch pages from developers.cloudflare.com.

## Caveats

- **It suggests adding a line to your user-level `AGENTS.md` or `CLAUDE.md`** so agents prefer `cf`. That is a suggestion for you. The agent should not edit files under `~/.claude` without asking.
- `cf` is in beta and needs Node.js 22.18 or later. Installing it globally is your decision.
- Cloudflare's CLI landscape is moving. Check the dates in the linked docs.
