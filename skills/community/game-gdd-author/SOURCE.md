# Source: game-gdd-author

- **Repo:** https://github.com/AlterLab-IEU/AlterLab_GameForge
- **Path:** `skills/workflows/game-gdd-author/SKILL.md`
- **Commit:** `5f5148d61986b32299070e87fcd4a1ab3718eacf` (2026-03-30)
- **License:** MIT (`LICENSE` copied)
- **Stars at fetch:** 45
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/game-gdd-author/`.
- **Upstream re-checked 2026-10-16:** HEAD is still the pinned commit. The last commits touching the skill, `templates/` and `docs/` are `33aa06d` and `ada0161` (both 2026-03-26). Nothing was re-fetched.

## What is in this folder

- `SKILL.md`: unchanged.
- From the repo root, unchanged, because the SKILL.md references them as `@templates/...` and `@docs/...`:
  - `templates/game-design-document.md`
  - `templates/game-pillars.md`
  - `docs/game-design-theory.md`
  - `docs/monetization-ethics.md`

## Why it was picked

It is a Socratic, section-by-section game design document workflow with 10 sections:
- the agent asks before it writes;
- design pillars are law, and every feature must trace to a pillar;
- every feature gets a scope tier (T1 must-ship, T2 launch target, T3 post-launch);
- mandatory MDA aesthetic tagging;
- contradictions are flagged immediately;
- honest scope warnings for solo developers.

It compiles to one GDD with pillar, MDA and tier coverage matrices. It mentions VR among its target platforms, and it is engine-neutral, so it works the same for a WebXR game.

## Security review

I read the SKILL.md and the 4 supporting docs. They are Markdown only. Its `allowed-tools` includes `Bash`, but the workflow never asks for a shell command. It reads, globs and writes the GDD file.

## Caveats

- The `@templates/...` and `@docs/...` references resolve against the project root in the original repo. In this folder they sit next to the SKILL.md. Either copy them into your project or tell the agent where they are.
- Cross-references to `game-brainstorm`, `game-designer`, `game-design-review` and `game-scope-check` point to skills that were not collected.
- `model: opus` and `effort: high` are set in the frontmatter.
- Last commit 2026-03-30.
