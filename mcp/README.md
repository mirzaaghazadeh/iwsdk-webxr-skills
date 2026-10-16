# MCP servers for IWSDK projects

An IWSDK project can expose three MCP servers to Claude Code. **Don't hand-write their config.**
The IWSDK CLI generates it with the right absolute paths for your project:

```bash
npx @iwsdk/cli adapter sync --tools claude    # writes .mcp.json and .claude/settings.json
npx @iwsdk/cli adapter status                  # what's configured, per tool
npx @iwsdk/cli adapter prune                   # remove only IWSDK-managed entries
```

`adapter sync` writes agent config, so ask the user first. The scaffold git-ignores `.mcp.json`
because the paths are absolute. Re-run `adapter sync` after moving the folder or reinstalling.

| Server | What it gives Claude | Runs |
|---|---|---|
| `iwsdk-runtime` | Drives the managed browser running your app in the IWER emulator: screenshots, console, page interaction, XR session and controller poses, ECS pause/step/query/snapshot/diff, scene and UI previews | `node node_modules/@iwsdk/cli/dist/cli.js mcp stdio`, relayed to the dev server over WebSocket (`/__iwer_mcp`) |
| `iwsdk-reference` | Local semantic search over the IWSDK API, source, components, systems and examples | from `@iwsdk/reference` in `node_modules` |
| `metavr` | Meta's headset tools: devices, apps, logs, captures, Perfetto, Meta docs search, store distribution | from `@meta-quest/metavr` in `node_modules` |

`iwsdk-reference` and `metavr` are added only when their packages are installed. The generated
`.claude/settings.json` pre-approves all three servers' tools. If you want to approve headset
actions one by one, remove `mcp__metavr__*` from `permissions.allow`.

## Using it

1. Start the dev server first: `npm run dev` or `npx @iwsdk/cli dev up`. With no runtime, tool
   calls fail with a "no runtime" error.
2. Start a new Claude Code session so `.mcp.json` is read. `/mcp` shows server status.
3. The first useful check is `xr_get_session_status` (CLI twin: `npx @iwsdk/cli xr status`).

Every MCP tool has a CLI twin with JSON output, so the skills also work without MCP.
`npx @iwsdk/cli dev up --allow-browser-automation` exposes the managed browser to any local process
for that session: ask first, and never enable it by default.

## Outside an IWSDK project

`mcp.json.example` shows the shape for `metavr` alone (for example, to debug a headset from a
folder that isn't an IWSDK app). Inside a project, use `adapter sync` instead.

## Older names

`iwsdk`, `iwsdk-dev-mcp`, `iwsdk-rag-local` and `hzdb` are legacy server names that `adapter sync`
treats as managed and replaces. `@iwsdk/reference` replaces the earlier stand-alone
`felixtrz/iwsdk-rag-mcp` server.

## Sources

- https://iwsdk.dev/ai/ and https://iwsdk.dev/ai/mcp-tools.html
- IWSDK 1.0.1 source: `packages/cli/src/mcp-adapters.ts` (https://github.com/facebook/immersive-web-sdk)
- `skills/custom/iwsdk-project-setup/references/claude-code-mcp.md` (full details)
