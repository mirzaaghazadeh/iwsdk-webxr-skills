# Source: game-playtest

- **Repo:** https://github.com/AlterLab-IEU/AlterLab_GameForge
- **Path:** `skills/workflows/game-playtest/SKILL.md`
- **Commit:** `5f5148d61986b32299070e87fcd4a1ab3718eacf` (2026-03-30)
- **License:** MIT (`LICENSE` copied)
- **Stars at fetch:** 45
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/game-playtest/`.
- **Upstream re-checked 2026-10-16:** HEAD is still the pinned commit. The last commits touching the skill and `docs/` are `e32a92f` (2026-03-25) and `ada0161` (2026-03-26). Nothing was re-fetched.

## What is in this folder

- `SKILL.md`: unchanged.
- `docs/game-design-theory.md`: copied unchanged from the repo root `docs/`. The SKILL.md cites it for the Flow and MDA frameworks.

## Why it was picked

It is a structured playtest workflow:
- define observable questions before inviting testers;
- the facilitator stays silent;
- 5 or more testers, never the dev team;
- behavioural data outranks verbal feedback;
- observation is kept separate from interpretation;
- observation sheets and timestamped per-player forms;
- synthesis into prioritized design insights.

It works on its own, which other candidates did not: the Donchitos and gstack-game playtest skills are tied to their frameworks, and OpenAI's `game-studio` playtest skill is tied to that plugin's references.

## Security review

I read the SKILL.md and the doc. They are Markdown only. Allowed tools are Read, Glob, Grep, Write and AskUserQuestion.

## Caveats

- **Not VR-specific.** For Quest playtests, add comfort and safety observation yourself: a simulator sickness questionnaire, session length, guardian and boundary issues, seated versus standing play, and hand versus controller input. The five `xr-*` skills (the-vibey-project) supply the criteria.
- A WebXR build is easy to hand out as a link, which makes remote playtests tempting. The skill assumes an observed session, so keep at least some sessions in person with the headset.
- It is part of a larger collection. Cross-references to `game-prototype`, `game-qa-lead` and `game-balance-check` point to skills that were not collected.
- Last commit 2026-03-30, so it is less fresh than the other picks.
