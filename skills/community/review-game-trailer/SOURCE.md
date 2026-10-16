# Source: review-game-trailer

- **Repo:** https://github.com/GarrettPetersen/indie-game-marketing-skills
- **Path:** `skills/review-game-trailer/` (`SKILL.md`, `references/shot-audit.md`, `references/trailer-first-development.md`, `agents/openai.yaml`)
- **Commit:** `e95d5428400ed6d9b8fe96fa5f0a24bd3c3ebdb6` (2026-10-06)
- **License:** MIT (`LICENSE` copied). The repo's `SOURCES.md` source ledger is copied for attribution.
- **Stars at fetch:** 7
- **Fetched:** 2026-10-16
- **Shared with the Unity library:** the same folder, unchanged, is in `unity-meta/skills/community/review-game-trailer/`.
- **Upstream re-checked 2026-10-16:** HEAD is still the pinned commit, which is also the last commit touching the skill. Nothing was re-fetched.

## Why it was picked

It is the only well-built trailer skill found that is not just an AI-video generator:
- plan trailers from beats to authentic gameplay footage, with a "trailer-first vertical slice";
- capture only after assets are fully loaded, so there is no pop-in;
- review the rendered master frame by frame, with a timecoded issue, evidence, impact and edit table;
- check codecs, aspect ratio, audio peaks and delivery size.

Store trailers and short-form clips are a big part of selling a Quest game, and that holds for a PWA on the Horizon Store too.

## Security review

I read all files. They are Markdown and YAML only. It sets an explicit authorization boundary: rendering never authorizes uploading or publishing. It also has a human-authorship rule: the agent never writes public copy or voice-over.

## Caveats

- **Steam-oriented wording.** Meta Horizon Store trailer and asset specs (resolution, length, 2D versus 360 or mixed-reality capture) are not covered. Check Meta's store asset guidelines.
- For VR footage, plan a smoothed spectator or third-person camera, or mixed-reality capture. Raw headset footage is shaky. The skill does not cover this. A WebXR app can add a desktop spectator view in code, which is often easier than in a native app.
- "Capture only after assets are fully loaded" matters more on the web, where textures and models stream in. Wait for shader warm-up as well (see `threejs-perf-loading`).
- Small new repo. Sibling skills (`plan-indie-game-marketing`, `audit-steam-store-page`) are Steam-specific and were not collected.
