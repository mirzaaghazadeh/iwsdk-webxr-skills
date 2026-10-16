# IWSDK docs on Meta's site vs the published packages (reference)

Checked 2026-10-17. Meta now hosts the IWSDK docs; this file says where they are, which version
they describe, and where they differ from what npm ships. Paraphrased; sources at the end.

## Where the docs live

| What | URL |
|---|---|
| Product page | https://developers.meta.com/vr/develop/iwsdk/ |
| Docs entry (guides, concepts, AI, examples, troubleshooting) | https://developers.meta.com/vr/documentation/iwsdk/guides/overview/; siblings under `/vr/documentation/iwsdk/` such as `ai/`, `ai/mcp-tools/`, `concepts/`. The bare `/documentation/iwsdk/` root returns **404** (2026-10-17) |
| LLM index for those pages | https://developers.meta.com/horizon/llmstxt/documentation/iwsdk/llms.txt/ |
| Markdown twin of any page | `https://developers.meta.com/horizon/llmstxt/documentation/iwsdk/<path>.md` (missing pages return HTTP 200 with a 45-byte "Sorry, this content isn't available right now") |
| VR Glasses guide | `/horizon/documentation/iwsdk/guides/get-started-glasses/` |
| Old web-docs entry | `/horizon/documentation/web/iwsdk-overview/` only says the docs moved |
| Upstream docs and API reference | https://iwsdk.dev (identical to IWSDK 1.0.1 `docs/public` on 2026-10-17), https://iwsdk.dev/api/ |

HTML pages under `/horizon/…` now answer **302 → `/vr/…`** (e.g.
`/vr/documentation/iwsdk/guides/get-started-glasses/`); the URLs in this library still work
through the redirect. The llmstxt `.md` twins answer 200 under both prefixes. `curl` with a
browser-like `User-Agent` got HTTP 400 from the llmstxt endpoints; curl's default agent works.

## Which version they describe

Every Meta-hosted IWSDK page carries a comment "verified against … `8218285d` (IWSDK v0.5.3)";
most are dated 2026-09-04 (getting-started 2026-09-23, 08-build-deploy 2026-09-23). npm
`latest` is **1.0.1** (published 2026-10-01); `next` is **1.1.0-rc.1** (2026-10-13). So when a
hosted page and the installed package disagree, trust the package
(`node_modules/@iwsdk/*/dist/**/*.d.ts`, `npx @iwsdk/cli <domain> --help`,
`npx @iwsdk/cli mcp inspect`).

## Differences that break or mislead

| Hosted page says | 1.0.1 package / iwsdk.dev | Effect |
|---|---|---|
| `world.features.fieldOfViewMask: true` (get-started-glasses, 02-testing) | Not a manifest key in 1.0.1 or 1.1.0-rc.1; the validator reports `unknown-key`, and the Vite plugin calls `assertValidIwsdkProjectManifest`, which throws on any issue (read in source, not run) | The dev server should refuse the manifest. Use `dev.emulator.device: "metaVRGlasses"` and `metavr device fov-sim` |
| Gaze tuning `suppressWhenHandPointerActive` (06) | `suppressWhenDirectPointerActive` | Same failure |
| Missing gaze pose → IWSDK falls back to head pointing, amber reticle (06, get-started-glasses) | No silent head-pose fallback; hand/controller far rays resume; head gaze only through `dev.targetDevicePreview.gazeSimulation: "head"` or the emulator's Head mode; `showDebugReticle` default `false` | Wrong expectations in tests |
| 45 public MCP tools (ai/index, ai/mcp-tools, and the AI tools page); the product page says 32 | `iwsdk mcp stdio` lists **55** (table below) | Tool lists in prompts go stale; read `mcp inspect` |
| Browser group = 3 tools; UI group = 2 | 6 browser (`browser_snapshot`, `browser_interact`, `browser_profile` added); 3 UI (`ui_inspect` added); plus `asset_render_preview` | |
| Commands as `npx iwsdk …` | Works only through the project's bin; this library always uses the scoped `npx @iwsdk/cli …` | Unscoped npx can fetch an unrelated package |
| Dev URL examples on port 5173 | Scaffold `vite.config.ts` uses 8081 (strict) | Use the port `dev status` reports |
| Generated skill `iwsdk-scene-composer` (ai/index) | `iwsdk-compose-scene` | Name mismatch |

Also on the hosted ai/getting-started page: wait for both `state.browserCommandReady` and
`state.session.browser.commandReady` in `dev status` before runtime calls (in 1.0.1 the first is
computed from the second, so they agree), and a no-code starter template exists on v0 by Vercel.

## `iwsdk-runtime` tools in 1.0.1 (55; same list in 1.1.0-rc.1)

| Group | Count | Tools |
|---|---|---|
| WebXR | 16 | `xr_get_session_status`, `xr_accept_session`, `xr_end_session`, `xr_get_transform`, `xr_set_transform`, `xr_look_at`, `xr_animate_to`, `xr_set_input_mode`, `xr_set_connected`, `xr_get_select_value`, `xr_set_select_value`, `xr_select`, `xr_get_gamepad_state`, `xr_set_gamepad_state`, `xr_get_device_state`, `xr_set_device_state` |
| Browser | 6 | `browser_screenshot`, `browser_snapshot`, `browser_interact`, `browser_profile`, `browser_get_console_logs`, `browser_reload_page` |
| Scene file / Editor | 10 | `scene_open`, `scene_render_file`, `scene_flatten_file`, `scene_get_state`, `scene_get_capabilities`, `scene_select`, `scene_set_preview_visibility`, `scene_set_camera`, `scene_screenshot`, `scene_measure_image_regions` |
| Runtime scene | 3 | `scene_get_render_stats`, `scene_get_runtime_hierarchy`, `scene_get_object_transform` |
| Assets / UI | 4 | `asset_render_preview`, `ui_list_assets`, `ui_render_preview`, `ui_inspect` |
| ECS | 11 | `ecs_pause`, `ecs_resume`, `ecs_step`, `ecs_query_entity`, `ecs_find_entities`, `ecs_list_systems`, `ecs_list_components`, `ecs_toggle_system`, `ecs_set_component`, `ecs_snapshot`, `ecs_diff` |
| Runtime control | 5 | `runtime_pair_headset`, `runtime_get_status`, `runtime_list_targets`, `runtime_wait`, `runtime_recover` |

Counted from `RUNTIME_MCP_TOOLS` and the `tools/list` handler in `@iwsdk/cli` 1.0.1
`dist/cli.js` (read, not run). `scene_measure_image_regions` needs a `captureToken` that no public
tool issues. Every app tool also accepts optional `expectedTab` (stale-tab guard) and
`runtimeTarget` (managed browser or a paired physical headset).

## What 1.1.0-rc.1 changes (prerelease, `next` tag)

- `three` becomes `npm:super-three@0.185.0` (scaffold override and release check updated); the
  `System.update` docs now cite three's `Timer` instead of `Clock`.
- Emulator rooms: `dev.emulator.environment` accepts `sunlit_living_room`, `home_office`,
  `conference_room`, `open_office`, `kitchen`, `bedroom`, `music_studio`, `open_studio` (IWER 2.6.0
  GLTS rooms). The old ids still load, mapped to replacements (`living_room` →
  `sunlit_living_room`, `meeting_room` → `conference_room`, `music_room` → `music_studio`,
  `office_large` → `open_office`, `office_small` → `home_office`); AR scaffolds default to
  `sunlit_living_room`.
- No change to the MCP tool list, the `world.features` keys, the guidance files or the skills.
- No public commits or changelog yet (GitHub `main` is still at the 1.0.1 release commit).
  Don't move projects to it unless the user asks.

## Sources

- https://developers.meta.com/horizon/llmstxt/documentation/iwsdk/llms.txt/ and the `.md` twins of `ai/index` (2026-09-04), `ai/getting-started` (2026-09-23), `ai/mcp-tools` (2026-09-04), `ai/modes` (2026-09-04), `guides/02-testing-experience` (2026-09-04), `guides/06-built-in-interactions` (2026-09-04), `guides/get-started-glasses` (2026-09-04), `guides/01a-project-manifest` (2026-09-04)
- https://developers.meta.com/vr/discover/ai-tools/ (undated; "45 MCP tools"), https://developers.meta.com/vr/develop/iwsdk/ (undated; "32 tools")
- npm registry: `@iwsdk/core|cli|create|vite-plugin-dev` 1.0.1 (2026-10-01) and 1.1.0-rc.1 (2026-10-13) tarballs: `dist/project/types.d.ts`, `validation.js`, `environments.js`, `dist/cli.js`, `scripts/verify-release-ready.mjs`
- https://github.com/facebook/immersive-web-sdk @ `0778f518` (`docs/concepts/xr-input/gaze.md`, `docs/ai/mcp-tools.md`); commit list checked 2026-10-17
- https://iwsdk.dev/llms.txt, /skill.md, /go.md (byte-identical to `docs/public/` at `0778f518`)
