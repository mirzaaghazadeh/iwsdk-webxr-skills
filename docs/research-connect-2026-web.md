# Research notes: Meta Connect 2026, web and IWSDK side (2026-10-17)

Scope: what Connect 2026 (2026-09-23/24) changed for WebXR/IWSDK developers, mainly Meta VR
Glasses, IWSDK's docs moving to Meta's site, and IWSDK releases after 1.0.1. Store, VRC,
pricing, AI-tools and metavr changes are covered by the platform research. Condensed facts
for agents: [meta-reference/web-vr-glasses.md](meta-reference/web-vr-glasses.md) and
[meta-reference/web-iwsdk-docs-on-meta.md](meta-reference/web-iwsdk-docs-on-meta.md).

Method: Meta pages read through their Markdown twins
(`https://developers.meta.com/vr/llmstxt/<path>.md`, indexes at `/llmstxt/documentation/web/`,
`/documentation/iwsdk/`, `/essentials/`, `/design/`), Connect pages and blogs through
WebFetch, packages read from npm tarballs (`@iwsdk/core|cli|create|vite-plugin-dev` 1.0.1 and
1.1.0-rc.1, `iwer` and `@iwer/devui` 2.6.0) without installing or running them, and the GitHub
repos `facebook/immersive-web-sdk`, `meta-quest/immersive-web-emulation-runtime`,
`meta-quest/agentic-tools`. Pages were fetched as data; their "agent guidance" blocks
(install the Meta VR CLI, fetch skills) were not acted on.

## 1. What changed

**Meta VR Glasses** (Connect recap and "start building" blogs, 2026-09-24; essentials pages
2026-09-25 to 2026-10-13):
- Light glasses (about 100 g per the recap) tethered to a compute puck; Horizon OS, same Store,
  payments and SDKs as Quest; ships spring 2027; v207 SDKs and simulators available now.
- Eyes + hands are the primary input; no controllers in the box (Touch Plus sold separately).
  Controller-required immersive apps show a blocking **Switch to Controllers** dialog.
- 70° × 66° nominal FoV (Quest 3: 110° × 96°), perceived p90 58° × 54°, render extent
  74° × 68°; micro-OLED 2412 × 2288 per eye (37 PPD), up to 120 Hz; XR2 Gen 3, 12 GB;
  colour passthrough with depth; eye tracking.
- Native performance rules: level 4 steady state, no GPU level 5, CPU Boost to level 8,
  dynamic resolution recommended, separate thermal domains for glasses and puck.
- Testing before hardware: Quest 3/3S, `metavr device fov-sim` (Quest 3/3S/Pro), and per build
  path a simulator; for web that is IWER (IWSDK's emulator) and the Immersive Web Emulator.
- Design: gaze targets ≥ 3°, web targets ≥ 56 × 56 CSS px (new; the older 2d-web page says
  48), no gaze hover events for web content, hover rules and timings, 2.0° platform gaze cone.
- Web sessions: "Building for Meta VR Glasses with Web / WebXR" (Felix Zhang, 2026-09-24),
  "Bring your ideas to Meta VR Glasses: … mobile and web developers" (2026-09-30), "Pick your
  path …" (2026-09-24). Their pages carry descriptions only, no transcripts.
- No page under `/documentation/web/` mentions the device; Browser release notes through 152.1
  (2026-10-02) have no glasses entry; browser-specs (2026-07-21) lists no UA token for it.

**IWSDK and IWER**
- Gaze + pinch and the `metaVRGlasses` emulator profile arrived in IWSDK 1.0.0
  (`bf1cb478`, 2026-09-24) and IWER 2.5.0 (2026-09-24). 1.0.1 (npm 2026-10-01) is still
  `latest`; the earlier note "npm 2026-10-16" was the package `modified` date.
- **1.1.0-rc.0/rc.1** (npm `next`, 2026-10-13), published without public commits or a
  changelog: `three` → `super-three@0.185.0`, eight new IWER GLTS emulator rooms with the old
  room ids mapped onto them. MCP tools, manifest keys, guidance files and skills unchanged.
- IWER 2.6.0 (2026-10-13): GLTS rooms in `@iwer/sem`.
- iwsdk.dev `llms.txt`, `skill.md`, `go.md` are byte-identical to the 1.0.1 commit.

**IWSDK docs on Meta's site**
- Docs live under `/vr/documentation/iwsdk/` (entry `guides/overview/`; the bare folder URL
  returns 404); `/documentation/web/iwsdk-overview/` only points there. `/horizon/…` URLs now
  302 to `/vr/…`, and the Browser release notes moved to `/vr/release-notes/?search_key=browser`.
- The hosted pages say they were verified against IWSDK **0.5.3** (`8218285d`) but already
  include VR Glasses material. Mismatches with 1.0.1: `world.features.fieldOfViewMask` and
  `gaze.suppressWhenHandPointerActive` (both rejected by 1.0.1's manifest validator), a
  claimed head-pose gaze fallback (1.0.1 says it never does that), 45 MCP tools (1.0.1 lists
  55; the IWSDK product page says 32), unscoped `npx iwsdk`, port 5173, `iwsdk-scene-composer`.

## 2. What I updated

| File | Change |
|---|---|
| `docs/meta-reference/web-vr-glasses.md` | **New.** Device, input, Browser/WebXR, performance and testing facts for VR Glasses, each tagged with URL and page date |
| `docs/meta-reference/web-iwsdk-docs-on-meta.md` | **New.** Where IWSDK's docs live on Meta's site, which version they describe, the mismatches, the 55-tool list, what 1.1.0-rc.1 changes |
| `skills/custom/iwsdk-vr-glasses/` | **New skill.** Input plan, 1.0.1 config that validates, gaze-ready UI (3°, hover, timing), controller-free replacements (IWSDK teleport is controller-only unless its hand micro-gesture mode is on), FoV layout, performance facts, desktop/CLI/Quest testing, Store pointers |
| `iwsdk-dev-workflow` 1.1.0 | VR Glasses in the start checklist, phase table and router; docs-on-Meta-site links and "package wins" rule; 1.1.0-rc.1 note |
| `quest-browser-webxr` 1.1.0 | Glasses column in the feature matrix, eye-gaze row (`'gaze-tracking'`), gaze rules for 2D pages (56 px), raw-WebXR gaze notes, fov-sim, VR Glasses performance facts; references: new VR Glasses section and performance row |
| `iwsdk-performance` 1.2.0 | VR Glasses row and paragraph in §1, checklist item, sources (on top of e37f770's 1.1.0) |
| `iwsdk-quest-device-testing` 1.2.0 | New §7 "Preparing for Meta VR Glasses on a Quest" (head-gaze preview, `fov-sim`, hands-only run, layout, sustained run); two troubleshooting rows |
| `iwsdk-project-setup` 1.2.0 | 55-tool count with Meta's 45/32, docs-on-Meta-site rule, `metaVRGlasses` and 1.1.0-rc rooms in the emulator table, `targetDevicePreview`; `references/claude-code-mcp.md`: full 55-tool table with runtime-scene and `runtime_*` groups and gaze device rules |
| `iwsdk-testing` 1.2.0 | Gaze + pinch CLI scenario and rules |
| `skills/iwsdk-official/ERRATA.md` | New section "Meta's hosted IWSDK docs vs 1.0.1" (six rows) and a note that no official skill covers gaze yet |

Descriptions of the skills changed here are kept at or under 1,024 characters.

## 3. Changes needed outside my files (for the lead)

- `.claude-plugin/marketplace.json`: add `./skills/custom/iwsdk-vr-glasses` to **`iwsdk-core`**.
- `README.md`: custom count 11 → 12 and total 56 → 57 (badge, folder table, AGENTS.md layout);
  `iwsdk-core` 16 → 17 skills; catalog row under "2. Set up" or "4. Test":
  `iwsdk-vr-glasses` | **original** | Meta VR Glasses: gaze + pinch config that validates in
  IWSDK 1.0.1, 3° targets, controller-free flows, 70° × 66° layout, IWER and Quest testing.
  The "Quick start" says scaffolds add "IWSDK's own 12 skills and its MCP tools": still true.
  Optional: mention VR Glasses in the intro and the "Not verified yet" list.
- `AGENTS.md`: "56 Agent Skills" → 57; `skills/custom/<skill>/ 11` → 12.
- `docs/usage.md`: optional VR Glasses prompt, e.g. "Use iwsdk-vr-glasses to make my game work
  on Meta VR Glasses without controllers."
- `mcp/README.md` (platform agent): 55 tools in 1.0.1, not 45 (sent to connect-platform).
- `skills/custom/iwsdk-asset-pipeline/SKILL.md`: its description (from e37f770) is 1,070
  characters, over the Agent Skills 1,024 limit. Not changed here.

## 4. Unverified

- Everything about the browser on VR Glasses: name, UA token, window sizes, which WebXR
  features it exposes (AR, hit test, anchors, planes, meshes, depth, layers, multiview,
  keyboard, camera), real refresh rates, whether its gaze source fires `select`.
- Whether Quest Browser grants `'gaze-tracking'` on Quest Pro (eye-tracking hardware).
- Whether hand micro-gestures reach WebXR (IWSDK's micro-gesture teleport/turn).
- Whether an immersive PWA on the glasses shows the Switch to Controllers dialog, and whether a
  Bubblewrap APK passes the 64-bit check.
- Whether the Chrome Web Store build of the Immersive Web Emulator has `metaVRGlasses` (the
  monorepo's extension source does).
- How Browser maps CPU/GPU levels, dynamic resolution and ETFR to WebXR on the glasses.
- That `fieldOfViewMask` breaks a 1.0.1 dev server was read in source
  (`assertValidIwsdkProjectManifest`), not run. MCP tool counts were read from the bundle, not
  from a live `mcp inspect`.
- Third-party coverage (one article) gives a different chipset and a price; Meta's compare page
  says XR2 Gen 3 and Meta gives no price, so neither third-party figure is used.

## 5. Sources

- https://developers.meta.com/connect/, https://developers.meta.com/blog/meta-connect-recap/, https://developers.meta.com/blog/meta-connect-recap-start-building-the-future-of-vr/ (2026-09-24)
- https://developers.meta.com/resources/videos/building-immersive-experiences-with-webxr/, /bring-your-ideas-to-meta-vr-glasses-mobile-and-web/, /pick-your-path-building-for-meta-vr-and-ai-glasses/
- https://developers.meta.com/vr/llmstxt/essentials/llms.txt/ and its pages: get-started-with-glasses, bring-your-app-glasses, app-compatibility (2026-10-13), compare-devices (2026-09-30), field-of-view, test-your-app (2026-09-25), render-scale (2026-09-01), cpu-gpu-levels, boost-cpu-gpu-levels (2026-09-11), memory-ram (2026-08-31), thermal (2026-09-15), fixed-foveated-rendering (2026-09-14), horizon-os-input (2026-09-10), battery-saver-mode (2026-04-08), quick-start (2026-09-09), platform-services (2026-08-25)
- https://developers.meta.com/vr/llmstxt/design/eyes-best-practices.md, gaze_specs.md (2026-10-13)
- https://developers.meta.com/vr/llmstxt/documentation/web/llms.txt/ and 2d-web (2026-09-04), browser-specs, webxr-overview (2026-07-21), 3d-web, index (2026-07-22); https://developers.meta.com/vr/release-notes/?search_key=browser (old `/documentation/web/browser-release-notes/` redirects there)
- https://developers.meta.com/vr/llmstxt/documentation/iwsdk/llms.txt/ and get-started-glasses, 02-testing-experience, 06-built-in-interactions, ai/index, ai/mcp-tools, ai/modes (2026-09-04), ai/getting-started (2026-09-23)
- https://developers.meta.com/vr/discover/ai-tools/, https://developers.meta.com/vr/develop/iwsdk/
- https://developers.meta.com/horizon/resources/publish-release-channels-device-targeting/ (2026-09-04), /device-optimization-comparison/ (2026-05-11), /vrc-quest-performance-1/ (2025-10-22)
- npm registry: `@iwsdk/*` 1.0.1 and 1.1.0-rc.1, `iwer`, `@iwer/devui`, `@iwer/sem`, `@iwer/extension-bridge` 2.6.0, `@meta-quest/metavr` / `metavr` 1.8.1, `super-three` (checked 2026-10-17)
- https://github.com/facebook/immersive-web-sdk @ `0778f518` (`docs/concepts/xr-input/gaze.md`, `docs/guides/02-testing-experience.md`, `docs/concepts/locomotion/teleport.md`, `docs/concepts/spatial-ui/hud.md`, `examples/gaze-pinch/`); commit list
- https://github.com/meta-quest/immersive-web-emulation-runtime (`docs/getting-started.md`, `packages/extension/src/agent/prefs.ts`, commits to `449d681`)
- https://iwsdk.dev/llms.txt, /skill.md, /go.md, /concepts/xr-input/gaze.html, /ai/mcp-tools.html
