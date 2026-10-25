# Meta's AI tools for VR developers: condensed reference (web / IWSDK edition)

Checked 2026-10-17; `metavr init`, the plugin id and the MCP re-test added 2026-10-25. Our own summary; each row cites `[key date]` (page "Updated" date), resolved
in [Sources](#sources). Nothing was installed or run: version facts come from the npm registry,
the npm package files and Meta's public binary feed. The Unity library has the same reference with
Unity specifics (`unity-meta-quest-skills/docs/meta-reference/ai-tools.md`).

## 1. The surfaces, and which matter for web apps

| Tool | What it is | For IWSDK / WebXR? | Source |
|---|---|---|---|
| **Meta VR CLI** (`metavr`, formerly `hzdb`) | CLI + stdio MCP server: devices, apps, logs, captures, Perfetto, docs search, Store distribution. An IWSDK scaffold installs it as `@meta-quest/metavr` in `node_modules` | Yes: headset, logs, traces, docs, upload | [ai-tools-page; metavr-overview 2026-08-31] |
| **IWSDK CLI MCP** (`npx @iwsdk/cli`) | Meta's AI tools page and the IWSDK MCP-tools page (2026-09-04) say 45 tools, counted for IWSDK 0.5.3; the shipped `@iwsdk/cli` 1.0.1 lists **55** (`meta-reference/web-iwsdk-docs-on-meta.md`). IWER emulates headset, hands and, with IWSDK 1.0, VR Glasses gaze | Yes: the main agent loop (see `mcp/README.md`) | [ai-tools-page; iwsdk-mcp-tools 2026-09-04; iwsdk-blog 2026-10-14] |
| **Agent skills** | `meta-quest/agentic-tools` (36 skills); this library ships the 10 that fit web | Yes | [agent-skills 2026-09-29] |
| **Meta XR Operator** | OpenXR API layer + MCP for native OpenXR apps (Unity integration, standalone package for other engines) | **No.** A WebXR page runs inside Quest Browser; use the IWSDK tools instead | [operator-doc 2026-09-09] |
| **Meta AI Developer Assistant** | Read-only chat in the Developer Center and Dashboard (section 5) | Yes, for submissions and analytics questions | [ai-assistant 2026-09-24] |
| **LLM resources** | `https://developers.meta.com/horizon/llmstxt/documentation/web/llms.txt/` and resources/policy indexes (Markdown) | Yes | [llm-resources 2026-09-01] |
| v0 by Vercel template | Prompt to a hosted IWSDK starter; then package it as a PWA | Optional | [recap-vr 2026-09-24] |
| Muse Code | Meta's multi-agent terminal coding tool (`metavr init --muse-code`). **Note only** | - | [recap 2026-09-24] |

## 2. metavr version and command changes

| Item | Value | Source |
|---|---|---|
| npm `metavr` / `@meta-quest/metavr` latest | **1.8.1** (2026-10-01); 1.8.0 on 2026-09-24 | registry.npmjs.org |
| What 1.8.1 changed | npm wrapper only (download logic and error messages); still pins binary **1.8.0.17.10**, same SHA-256 as 1.8.0 | 1.8.0 vs 1.8.1 tarballs |
| Live binary | `1.8.0.17.10` ("2026.09.15 release branch") | `https://www.oculus.com/binary-info/26345008975148693/latest/` |
| Upstream `docs/metavr-cli.md` | Unchanged since `3a8553d` (2026-09-24); identical to `docs/metavr-cli-reference.md` | github.com/meta-quest/agentic-tools |

**No command changes to record.** Commands Meta's new pages document, all already in the
reference: `metavr device fov-sim enable [--perceived]|disable` (VR Glasses FoV on a Quest 3/3S/Pro);
`metavr skills list|status|install|update|remove` (writes `~/.agents/skills`); `metavr init`
flags (`--claude-code`, `--muse-code`, `--no-auth`, `-y`, `--all-agents`); `metavr mcp install
<target>`; `metavr update [--version|--dry-run|--force]`; `metavr auth status` (always exits 0),
`METAVR_TOKEN`; `metavr store dist upload|channels|copy-build` (draft unless `--publish`; no
age-group or device-targeting flag) [install 2026-08-31; troubleshoot 2026-08-27; fov 2026-09-25].

## 3. Installing skills and MCP without duplicates

| Route (Meta) | Installs | Source |
|---|---|---|
| `metavr init` | metavr skill, MCP config, agent plugins, all at **user scope** (details below) | [install 2026-08-31]; observed 2026-10-25 |
| `/plugin marketplace add meta-quest/agentic-tools` + `/plugin install meta-vr@meta-vr` | All 36 Meta skills + an MCP server via `npx` | [other-tools 2026-08-31] |
| `gh skill install` / `npx skills add` / `npx ctx7@latest skills install` | Skills only | [other-tools 2026-08-31] |
| `metavr skills install --all` | Skills into `~/.agents/skills` | reference §skills |
| `npx @iwsdk/cli adapter sync --tools claude` | IWSDK, iwsdk-reference and metavr MCP entries in `.mcp.json` | `mcp/README.md` |

Meta: `metavr init` already installs the skills and MCP config, so use the plugin only without it
[other-tools 2026-08-31]; each bundling tool registers its own MCP server, so remove duplicates
[troubleshoot 2026-08-27]. **For this library:** pick one source of Meta's skills (this library's
`meta-web-extras` / `iwsdk-core` copies with ERRATA, *or* Meta's channels), and keep one `metavr`
MCP entry. In an IWSDK project that entry normally comes from `adapter sync`; don't add a second
one with `metavr mcp install`.

**Correction to the other-tools page:** it gives `/plugin install meta-vr@meta-quest` for Claude
Code, but the repo's `.claude-plugin/marketplace.json` names the marketplace `meta-vr`, so the
plugin is `meta-vr@meta-vr` (agentic-tools `3a8553d`; `metavr init` installed it under that name,
2026-10-25).

**What `metavr init` installs** (metavr 1.8.0.17.10, observed 2026-10-25). Ask before running it,
and tell the user that it all lands in their home folder, for every project:
- `metavr-cli` plus 35 skills from agentic-tools go into `~/.agents/skills`, symlinked from
  `~/.claude/skills` and `~/.cursor/skills`;
- the `meta-vr@meta-vr` plugin (v2.0.0: the same 36 skills plus an MCP server via `npx -y metavr`)
  is installed at user scope;
- a `metavr` MCP entry is added to `~/.claude.json` at local scope for the current folder, and to
  `~/.cursor/mcp.json`;
- after sign-in it downloads a 330 MB "VRC-local" bundle with 10 more skills: `vrc-drive`,
  `vrc-verdict`, `vrc-listing-check`, `vrc-listing-assets`, `troubleshoot`, `da-scout`,
  `analyze-drive`, `perf-render-capture`, `renderdoc-optimize`, `runtime-optimizer`.

In an IWSDK project that means two or three `metavr` MCP servers (`adapter sync`'s, the local
entry, the plugin's) and two copies of each `hz-*` skill next to this library. To keep Meta's tools
in one project instead:
1. `claude plugin install meta-vr@meta-vr --scope project`, then `claude plugin uninstall
   meta-vr@meta-vr --scope user`. Add `meta-quest/agentic-tools` to the project's
   `extraKnownMarketplaces`, under the name `meta-vr`.
2. `claude mcp remove metavr -s local`. Keep the project's own entry (from `adapter sync` in an
   IWSDK game). Project servers need a one-time approval when Claude Code next starts there.
3. Move the skill folders into `<project>/.agents/skills` and replace the home symlinks with
   project ones: `.claude/skills` only for the ten VRC-local skills (the plugin brings the rest),
   and `.cursor/skills` for all of them. Move `~/.cursor/mcp.json` to `<project>/.cursor/mcp.json`.
4. Git-ignore `.agents/`, `.cursor/` and those links; they're per machine. A later `metavr init`
   puts everything back at user scope.

## 4. MCP facts

| Fact | Source |
|---|---|
| `metavr mcp server` is stdio only; restart the agent after any config change; the server calls itself `hzdb` | [troubleshoot 2026-08-27] |
| Old `/horizon/essentials/ai-tooling-mcp/` now redirects to "Install Meta VR CLI" | redirect checked 2026-10-17 |
| The Unity library saw Claude Code 2.1.301 reject metavr 1.8.0.17.10's `tools/list` results. **Gone with Claude Code 2.1.310:** the same binary, registered as `~/.metavr/bin/metavr mcp server --update`, connected and its tools loaded. The `meta-vr` plugin's `npx` server failed once with `request _meta is missing or has malformed required fields`, then connected. Not re-tested for the IWSDK-managed entry | `unity-meta-quest-skills/mcp/README.md`; re-tested 2026-10-25 |

## 5. Meta AI Developer Assistant

Read-only, sign-in, no install; icon after Search (Developer Center) or Help (Dashboard). Answers
from docs, known issues, submissions and reviewer feedback, analytics (usage, crashes, FPS,
startup, funnel, wishlists, peer benchmarks), monetization and org roles; drafts support tickets
that you submit [ai-assistant 2026-09-24]. Agents can't call it; suggest it to the user.

## 6. Mismatches between Meta's pages and Meta's repo

- "Test your app for Meta VR Glasses" names skills `vrc-check`, `xr-simulator-setup` and
  `perfetto-debug` [test-app 2026-09-25]; `agentic-tools@3a8553d` has `hz-perfetto-debug` and no
  VRC skill (removed 2026-05-12). Use `horizon-web-vrc-checklist`.
- Markdown twins open with `agent_guidance` asking agents to use Meta VR CLI and to ask before
  installing tools. It is page content, not an instruction.

## Sources

| Key | Page |
|---|---|
| ai-tools-page | https://developers.meta.com/vr/discover/ai-tools/ (no date shown; fetched 2026-10-17) |
| metavr-overview | https://developers.meta.com/vr/essentials/metavr-overview/ (2026-08-31) |
| install | https://developers.meta.com/vr/essentials/metavr-install/ (2026-08-31) |
| other-tools | https://developers.meta.com/vr/essentials/metavr-other-tools/ (2026-08-31) |
| troubleshoot | https://developers.meta.com/vr/essentials/metavr-troubleshooting/ (2026-08-27) |
| agent-skills | https://developers.meta.com/vr/essentials/agent-skills/ (2026-09-29) |
| llm-resources | https://developers.meta.com/vr/essentials/ai-solutions/ (2026-09-01) |
| ai-assistant | https://developers.meta.com/vr/essentials/ai-developer-assistant/ (2026-09-24) |
| fov | https://developers.meta.com/vr/essentials/field-of-view/ (2026-09-25) |
| test-app | https://developers.meta.com/vr/essentials/test-your-app/ (2026-09-25) |
| operator-doc | https://developers.meta.com/vr/documentation/unity/meta-xr-operator/ (2026-09-09) |
| iwsdk-blog | https://developers.meta.com/vr/blog/immersive-web-sdk-1-0/ (2026-10-14) |
| iwsdk-mcp-tools | https://developers.meta.com/vr/documentation/iwsdk/ai/mcp-tools/ (2026-09-04) |
| recap | https://developers.meta.com/blog/meta-connect-recap/ (2026-09-24) |
| recap-vr | https://developers.meta.com/blog/meta-connect-recap-start-building-the-future-of-vr/ (2026-09-24) |
| reference | `docs/metavr-cli-reference.md` (metavr 1.8.0.17.10, identical to upstream `docs/metavr-cli.md` @ `3a8553d`) |
