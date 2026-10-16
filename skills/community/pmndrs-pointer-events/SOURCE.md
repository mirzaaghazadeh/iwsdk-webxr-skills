# Source: pmndrs-pointer-events

- **Repo:** https://github.com/pmndrs/xr
- **Path:** `packages/pointer-events/skills/pmndrs-pointer-events/`
- **Commit:** `0e1acd868ca744032240db819d1e428bd1812901` (2026-10-15). The skill itself last changed in `045c81b` (2026-10-13).
- **License:** MIT, Copyright 2024 Bela Bohlender and Copyright 2023 Coconut Capital (`LICENSE` copied from the repo root; it is identical to `packages/pointer-events/LICENSE`). GitHub reports NOASSERTION because of the two copyright lines; the text is the MIT license.
- **Stars at fetch:** 2616
- **Fetched:** 2026-10-16

## Why it was picked

IWSDK depends on `@pmndrs/pointer-events` (`^6.6.22`). Its ray, grab, touch and gaze pointers and its canvas pointer are built on it, so the events an IWSDK app receives follow this package's rules. The skill, written by the package maintainers, explains the behaviour that causes most "my click doesn't fire" bugs:
- the default `pointerEvents: 'listener'` means an object is hit only if it or an ancestor has a listener, so decoration neither receives nor blocks events;
- `pointerEventsType` filters by pointer type, for example `{ deny: 'grab' }` so a hand passing through a button does not press it;
- `setPointerCapture` for dragging, and the void object for "clicked nothing";
- batched delivery moves handlers out of the browser's user-gesture stack, so playing a video from a `click` handler fails unless batching is off;
- `pointerenter`/`pointerleave` do not bubble, and `click` is synthesized from down/up on the same object.

## Security review

I read the SKILL.md in full. It is Markdown only.

## Caveats

- **IWSDK already creates the pointers and forwards events.** Do not call `forwardHtmlEvents` in an IWSDK app unless the IWSDK docs say to, or events will fire twice. The skill is most useful for understanding hit rules and for custom pointers.
- It refers to `@react-three/xr` for React Three Fiber. Ignore that part for IWSDK.
- Its companion `pmndrs-xr` skill was not collected: `@pmndrs/xr` is a separate session and input stack that competes with IWSDK's own.
