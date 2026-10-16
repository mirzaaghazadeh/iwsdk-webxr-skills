# Source: threejs-perf-loading

- **Repo:** https://github.com/vladmdgolam/agent-skills
- **Path:** `skills/threejs-perf-loading/SKILL.md`
- **Commit:** `b66d157341c7c08023f6ef61324bd3ba3c1b6f85` (2026-10-14). The skill itself last changed in `3a24734` (2026-08-05).
- **License:** MIT, Copyright 2026 Vlad (`LICENSE` copied from the repo root)
- **Stars at fetch:** 9
- **Fetched:** 2026-10-16

## Why it was picked

It is the only redistributable three.js performance skill found that goes beyond the generic "dispose and instance" checklist. It is distilled from teardowns of shipped sites plus live profiling:
- **Hide shader compile cost:** force every pipeline to compile behind the loader by drawing it once, with frustum culling off, and run `renderer.compileAsync` per camera and layer mask. A first-use compile is a visible hitch in a headset.
- **Adaptive quality that does not flap:** a one-way latch, plus four hardening rules against false degrades from transient stalls.
- **Steady-state cost:** on-demand shadow map updates, GPU-resident particles, proximity gating with hysteresis, fused post passes.
- **Frame attribution tooling:** a marks buffer, a GL resource delta sampler that names each new program, a dispose tracer with call stacks, and a boot tracer that starts before the framework mounts.

## Security review

I read the SKILL.md in full. It is Markdown only. It suggests in-app debug tooling behind a URL flag and asks the user where their own teardown notes live. It does not fetch anything.

## Caveats

- **Written for desktop and mobile websites,** mostly scroll-driven pages, React Three Fiber and drei. Skip the scroll, transmission-glass and DOF sections for a VR game. Most post-processing is too expensive in stereo on Quest.
- The "device pixel ratio" lever maps to the XR framebuffer scale and foveation level in a WebXR session.
- Some examples use WebGPU and TSL post-processing. IWSDK renders with WebGL, so apply the ideas, not those exact APIs.
- It refers to a `three-best-practices` skill for basics. That skill was not collected because its upstream repo has no license.
- A personal repo with few stars, but the skill is recent and specific.
