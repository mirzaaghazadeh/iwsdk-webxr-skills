# Third-party notices

This repository mixes original work and third-party work. The root [`LICENSE`](LICENSE) (MIT)
covers **only the original work**. Everything listed under "Third-party work" keeps its own license,
which is stored next to it, and those licenses take precedence for those files.

## Original work: MIT, © 2026 Navid Mirzaaghazadeh

- `skills/custom/**`: all 11 original skills with their scripts and references. Each `SKILL.md`
  carries `license: MIT`, `metadata.author` and a "Made by" line.
- `README.md`, `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, `THIRD_PARTY_NOTICES.md`, `install.sh`,
  `.claude-plugin/marketplace.json`, `mcp/**`
- `docs/install.md`, `docs/usage.md`, `docs/research-iwsdk.md`, `docs/research-meta-web.md`,
  `docs/community-candidates.md`. The research notes summarise and briefly quote public IWSDK and
  Meta documentation and source, with a link to each source.
- The `SOURCE.md` / `AGENT-SOURCE.md` provenance files and the `ERRATA.md` files next to
  third-party folders.
- `skills/custom/horizon-store-listing-assets/scripts/check-store-assets.sh` started as a copy of
  the same author's script in [unity-meta-quest-skills](https://github.com/mirzaaghazadeh/unity-meta-quest-skills) (MIT).

## Third-party work

| Path | Author | License | License file |
|---|---|---|---|
| `skills/iwsdk-official/*` (13 skills) and `skills/iwsdk-official/agents/iwsdk-project-code-reviewer.md` | Meta Platforms, Inc. and affiliates, the IWSDK team ([facebook/immersive-web-sdk](https://github.com/facebook/immersive-web-sdk) @ `0778f518`, IWSDK 1.0.1) | MIT | `skills/iwsdk-official/LICENSE` and in each skill folder |
| `skills/meta-official/*` (10 skills) | Meta Platforms, Inc. ([meta-quest/agentic-tools](https://github.com/meta-quest/agentic-tools) @ `3a8553d`) | Apache-2.0 | `skills/meta-official/LICENSE` |
| `docs/metavr-cli-reference.md` | Meta Platforms, Inc. (same repo, `docs/metavr-cli.md`, unchanged) | Apache-2.0 | `skills/meta-official/LICENSE` |
| `skills/community/pmndrs-uikit` | Bela Bohlender and contributors ([pmndrs/uikit](https://github.com/pmndrs/uikit)) | MIT | `LICENSE` |
| `skills/community/pmndrs-pointer-events`, `pmndrs-handle` | Bela Bohlender and contributors ([pmndrs/xr](https://github.com/pmndrs/xr)) | MIT | `LICENSE` in each folder |
| `skills/community/threejs-perf-loading` | Vlad ([vladmdgolam/agent-skills](https://github.com/vladmdgolam/agent-skills)) | MIT | `LICENSE` |
| `skills/community/webapp-testing` | Anthropic ([anthropics/skills](https://github.com/anthropics/skills)) | Apache-2.0 | `LICENSE.txt` |
| `skills/community/pwa-offline` | pwa-skill-suite contributors ([AQaddora/pwa-skill-suite](https://github.com/AQaddora/pwa-skill-suite)) | MIT | `LICENSE` |
| `skills/community/cf-cli`, `wrangler`, `durable-objects`, `workers-best-practices` | Cloudflare, Inc. ([cloudflare/skills](https://github.com/cloudflare/skills)) | Apache-2.0 | `LICENSE` in each folder |
| `skills/community/game-gdd-author`, `game-playtest` | Cem Ipek, AlterLab Creative Technologies Laboratory ([AlterLab-IEU/AlterLab_GameForge](https://github.com/AlterLab-IEU/AlterLab_GameForge)) | MIT | `LICENSE` in each folder |
| `skills/community/prototype-fast` | Abhishek Barali and the awesome-gamedev-agent-skills contributors ([gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills)) | Apache-2.0 | `LICENSE`, `NOTICE` |
| `skills/community/review-game-trailer` | GarrettPetersen ([GarrettPetersen/indie-game-marketing-skills](https://github.com/GarrettPetersen/indie-game-marketing-skills)) | MIT | `LICENSE` |
| `skills/community/scenario-blender-*` (3) | Scenario Inc. ([scenario-labs/skills](https://github.com/scenario-labs/skills)) | MIT | `LICENSE` in each folder |
| `skills/community/xr-*` (5) | Adam Matthew Steinberger ([the-vibey-project/vibey](https://github.com/the-vibey-project/vibey)) | MIT | `LICENSE` in each folder |

Each third-party folder also has a `SOURCE.md` recording the exact upstream repository, path,
commit, fetch date and review notes for that copy. The `game-*`, `prototype-fast`,
`review-game-trailer`, `scenario-blender-*` and `xr-*` copies are shared with
[unity-meta-quest-skills](https://github.com/mirzaaghazadeh/unity-meta-quest-skills).

### Modifications

Third-party files are copied **unchanged**. The only additions are files placed next to them:
`SOURCE.md`, `AGENT-SOURCE.md` and `ERRATA.md`. Each folder is named after the skill's own
`name:`, which can differ from the upstream path recorded in `SOURCE.md`. The IWSDK review agent
moved from upstream's `.claude/agents/` to `skills/iwsdk-official/agents/` so the `iwsdk-official`
plugin can load it; its content is unchanged.

## Trademarks

Meta, Meta Quest, Meta Horizon and Horizon OS are trademarks of Meta Platforms, Inc. Cloudflare is
a trademark of Cloudflare, Inc. Blender is a trademark of the Blender Foundation. These names are
used here only to describe compatibility. **This project is not affiliated with, endorsed by or
sponsored by Meta Platforms, Inc., the IWSDK team, Cloudflare, Anthropic or any other company
named here.**
