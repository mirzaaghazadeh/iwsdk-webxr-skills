# Source: pmndrs-uikit

- **Repo:** https://github.com/pmndrs/uikit
- **Path:** `packages/uikit/skills/pmndrs-uikit/`
- **Commit:** `099f6f701c5fbec356f9f2d5d7dc86c8a6ff2cbf` (2026-10-15). The skill itself last changed in `1e836d2` (2026-10-13).
- **License:** MIT, Copyright 2024 Bela Bohlender and Copyright 2023 Coconut Capital (`LICENSE` copied from the repo root; it is identical to `packages/uikit/LICENSE`). GitHub reports the license as NOASSERTION because the file has two copyright lines, but the text is the MIT license.
- **Stars at fetch:** 3249
- **Fetched:** 2026-10-16

## Why it was picked

IWSDK's spatial UI is built on `@pmndrs/uikit`: IWSDK's packages depend on `^1.0.74`, and its UIKitML layer creates uikit components. This skill is written by the uikit maintainers and ships inside the uikit package. It covers what an agent gets wrong without it:
- every component is an `Object3D` laid out by Yoga flexbox, rendered as instanced panels and MSDF text;
- `pixelSize` scales a whole UI (100 px = 1 m by default), instead of inflating font sizes;
- breakpoints compare against the root's width in pixels, not the browser window;
- `Content` for 3D objects inside a layout, `flexShrink: 0` in scroll lists, inheritance and conditional precedence;
- signals for cheap per-frame property animation, MSDF font loading, draw-call batching per material class;
- the 0.x to 1.x migration (`setStyle` to `setProperties`, `backgroundOpacity` removed).

It also names the `@pmndrs/uikit-horizon` kit, which gives Meta Horizon OS-style components.

## Security review

I read the SKILL.md in full. It is Markdown only, with no scripts and no tool instructions.

## Caveats

- **IWSDK does part of the setup for you.** Its UIKitML layer already sets the transparent sort, and IWSDK forwards pointer events itself. Use the skill's "Scene setup" section to understand the requirements, not to add a second event forwarder or update loop to an IWSDK app. Check the IWSDK skills for how panels are declared there.
- It refers to a `react-three-uikit` sibling skill for React Three Fiber. That skill was not collected, because IWSDK is not React-based.
- Written for uikit 1.x. Older 0.x examples on the web use different property names.
