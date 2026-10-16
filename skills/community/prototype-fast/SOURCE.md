# Source: prototype-fast

- **Repo:** https://github.com/gamedev-skills/awesome-gamedev-agent-skills
- **Path:** `skills/workflows/prototype-fast/SKILL.md`
- **Commit:** `0a70cfc64672d512c5b5b6006b5dcb5cf90dbdbd` (2026-10-09)
- **License:** Apache-2.0 (`LICENSE` and `NOTICE` copied)
- **Stars at fetch:** 1550, the most-starred dedicated game-dev skill collection found.
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/prototype-fast/`.
- **Upstream re-checked 2026-10-16:** HEAD is still the pinned commit. The last commit touching the skill is `3727d02` (2026-08-08). Nothing was re-fetched.

## Why it was picked

It covers fast prototyping to answer one question: is it fun?
- one question per prototype;
- decide throwaway versus keep before writing code;
- a hard timebox, a greybox of everything else, and instrumentation for the question;
- an immediate, honest playtest;
- explicit keep, kill or refactor criteria, filled in a prototype brief.

It is engine-agnostic and short. For solo VR development, validating a mechanic in the headset before building it out is the highest-leverage habit. A WebXR prototype is cheap to try on a Quest: open the dev server in Quest Browser, over HTTPS or through `adb reverse` to `localhost`, because WebXR needs a secure context.

## Security review

I read the file. It is Markdown only.

## Caveats

- **Engine-agnostic pseudocode.** For VR, "hand it to someone without explaining the controls" means in the headset, not in the desktop emulator. Add comfort checks.
- The repo's engine skills were not collected. Cross-references to `game-jam`, `steam-publish` and `itch-publish` point to skills that were not collected.
