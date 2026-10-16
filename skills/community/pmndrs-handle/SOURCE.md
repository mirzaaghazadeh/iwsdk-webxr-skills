# Source: pmndrs-handle

- **Repo:** https://github.com/pmndrs/xr
- **Path:** `packages/handle/skills/pmndrs-handle/`
- **Commit:** `0e1acd868ca744032240db819d1e428bd1812901` (2026-10-15). The skill itself last changed in `045c81b` (2026-10-13).
- **License:** MIT, Copyright 2024 Bela Bohlender and Copyright 2023 Coconut Capital (`LICENSE` copied from the repo root; it is identical to `packages/handle/LICENSE`). GitHub reports NOASSERTION because of the two copyright lines; the text is the MIT license.
- **Stars at fetch:** 2616
- **Fetched:** 2026-10-16

## Why it was picked

IWSDK depends on `@pmndrs/handle` (`^6.6.16`), and its grab system creates `HandleStore` instances for grabbable objects. When a game needs more than the default grab (a door, a lever, a dial, a two-handed scale, an editor gizmo), this skill from the package maintainers is the reference:
- `HandleStore(target, options)` with per-axis limits, and `translate: 'as-rotate'` for doors, levers and dials;
- multitouch: two pointers translate, rotate and scale together, while one pointer never scales;
- the `apply` hook to clamp or snap, and `state.first`/`state.last` for the start and end of an interaction;
- `alwaysUpdate: true` when the parent moves every frame, and `stopPropagation: false` for nested handles.

## Security review

I read the SKILL.md in full. It is Markdown only.

## Caveats

- **The wiring example assumes `@pmndrs/xr`'s `createXRStore` or `forwardHtmlEvents`.** In IWSDK, events already arrive through IWSDK's input system. Try IWSDK's own grab components first, and use this skill when you build a custom handle on top of them.
- `OrbitHandles` and `MapHandles` are screen camera controls and ignore XR pointers.
- It refers to `@react-three/handle` for React Three Fiber. Ignore that part for IWSDK.
