# Claude Code + IWSDK MCP servers

## What `adapter sync` writes

`npx @iwsdk/cli adapter sync --tools claude` merges entries into `.mcp.json` at the project root
(source: `packages/cli/src/mcp-adapters.ts`, 1.0.1). Paths are absolute, which is why the
scaffold git-ignores the file. Shape (your paths will differ):

```json
{
  "mcpServers": {
    "iwsdk-runtime": {
      "command": "node",
      "args": ["/abs/path/my-game/node_modules/@iwsdk/cli/dist/cli.js", "mcp", "stdio"]
    },
    "iwsdk-reference": {
      "command": "node",
      "args": ["/abs/path/my-game/node_modules/@iwsdk/reference/<entrypoint>"]
    },
    "metavr": {
      "command": "node",
      "args": ["/abs/path/my-game/node_modules/@meta-quest/metavr/bin.js", "mcp", "server"]
    }
  }
}
```

`iwsdk-reference` and `metavr` are added only when those packages exist in `node_modules`.
Don't hand-write these paths; rerun `adapter sync` after moving the folder or reinstalling.

It also merges into `.claude/settings.json`:

```json
{
  "permissions": { "allow": ["mcp__iwsdk-runtime__*", "mcp__iwsdk-reference__*", "mcp__metavr__*"] },
  "enabledMcpjsonServers": ["iwsdk-runtime", "iwsdk-reference", "metavr"]
}
```

and deletes `enableAllProjectMcpServers: true` (older starters set it; it would auto-enable every
project server, including ones the user didn't add). Other adapters: `--tools cursor`
(`.cursor/mcp.json` + `.cursor/permissions.json`), `copilot` (`.vscode/mcp.json`, approval stays
manual in VS Code), `codex` (`.codex/config.toml`, `default_tools_approval_mode = "approve"` per
managed server), `opencode` (`opencode.json`). No `--tools` = all of them.

```bash
npx @iwsdk/cli adapter status     # instruction file, MCP config and permissions per tool
npx @iwsdk/cli adapter prune      # remove only IWSDK-managed entries
npx @iwsdk/cli adapter prompt     # self-contained setup prompt for an unrecognised harness
```

## How the runtime server works

`iwsdk mcp stdio` doesn't bind to a port. It reads the active workspace runtime that
`iwsdk dev up` recorded (`.iwsdk/runtime/`), then relays each tool call over a WebSocket
(`/__iwer_mcp` on the Vite server) to the managed Playwright Chromium page, where IWER executes
it. So:

1. Start the dev server first (`npm run dev` or `npx @iwsdk/cli dev up`).
2. Then call tools. With no runtime, calls fail with a "no runtime" error.
3. Your own desktop browser or headset keeps its own XR session; the agent drives the managed
   browser only, unless you pair a headset (`iwsdk-native-xr-test`).

Tool groups (full list: https://iwsdk.dev/ai/mcp-tools.html, schemas: `npx @iwsdk/cli mcp inspect`):

| Group | Tools |
|---|---|
| Browser (6) | `browser_screenshot`, `browser_snapshot`, `browser_interact`, `browser_profile`, `browser_get_console_logs`, `browser_reload_page` |
| WebXR | `xr_get_session_status`, `xr_accept_session`, `xr_end_session`, `xr_get/set_transform`, `xr_look_at`, `xr_animate_to`, `xr_set_input_mode`, `xr_set_connected`, `xr_get/set_select_value`, `xr_select`, `xr_get/set_gamepad_state`, `xr_get/set_device_state` |
| ECS | `ecs_pause`, `ecs_resume`, `ecs_step`, `ecs_query_entity`, `ecs_find_entities`, `ecs_list_systems`, `ecs_list_components`, `ecs_toggle_system`, `ecs_set_component`, `ecs_snapshot`, `ecs_diff` |
| Scene / editor | `scene_open`, `scene_render_file`, `scene_flatten_file`, `scene_get_state`, `scene_get_capabilities`, `scene_screenshot`, `scene_select`, `scene_set_camera`, `scene_set_preview_visibility`, `scene_measure_image_regions` |
| Assets / UI | `asset_render_preview`, `ui_list_assets`, `ui_render_preview`, `ui_inspect` |

`browser_profile` results are labelled `host-browser-diagnostic`, `calibrated: false`: they are
desktop numbers, never headset performance.

## In Claude Code

- After `adapter sync`, start a new session (or restart) so `.mcp.json` is read; `/mcp` lists
  server status.
- If tool schemas are deferred, load them with tool search first, then call
  `xr_get_session_status` as the first check. Until then, use `npx @iwsdk/cli …`.
- The generated settings pre-approve all three servers' tools. If the user wants to approve
  device actions (`metavr`) one by one, remove `mcp__metavr__*` from `permissions.allow`.
- `npx @iwsdk/cli dev up --allow-browser-automation` + `npx @iwsdk/cli browser run <script.mjs>`
  is an opt-in escape hatch that exposes the managed browser over loopback CDP. It gives any local
  process browser-level control for that session. Ask first; never enable it by default.

## Older names you may see

`iwsdk`, `iwsdk-dev-mcp`, `iwsdk-rag-local` and `hzdb` are legacy server names that
`adapter sync` treats as managed and replaces. `felixtrz/iwsdk-rag-mcp`
(`@felixtz/iwsdk-rag-mcp`) was the earlier stand-alone reference server; `@iwsdk/reference`
replaces it (same tool set: search, relationship, api, file, components, systems, dependents,
examples).
