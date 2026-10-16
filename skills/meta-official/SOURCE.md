# Source: Meta VR Agentic Tools (official)

| Field | Value |
|---|---|
| Publisher | Meta Platforms, Inc. |
| Repository | https://github.com/meta-quest/agentic-tools |
| Commit | `3a8553d10a5a1bd1bf9beaaa950243fbbed3b9ea` (2026-09-23, still the latest on 2026-10-16) |
| License | Apache-2.0 (copy in `LICENSE`) |
| Fetched | 2026-10-16 |
| Meta's page | https://developers.meta.com/horizon/discover/ai-tools/ |

The skill folders here are copied unchanged from `skills/` in the repo at the commit above. The same
copy was reviewed for the sister library
[unity-meta-quest-skills](https://github.com/mirzaaghazadeh/unity-meta-quest-skills): every install
command points to Meta or Google hosts, and there are no scripts that run on install.

## What was copied (10 of 36)

The skills that apply to an **IWSDK / WebXR → Quest Browser → Horizon Store (PWA)** pipeline:

| Skill | Why it's here |
|---|---|
| `hz-iwsdk-webxr` | Meta's IWSDK skill: ECS, three.js, input, spatial UI, performance tips, AI-assisted development |
| `hz-store-pwa` | Shipping a web app to the Horizon Store as a PWA/TWA with `@meta-quest/bubblewrap-cli`, manifest, icons, Digital Asset Links, upload |
| `hz-quest-verify-first` | Guardrail: verify Quest claims against Meta's live docs (`metavr docs`) |
| `metavr-cli` | The Meta VR CLI: device, app, logs, capture, perf, docs search, store distribution |
| `hz-new-project-creation` | Scaffolding for every Meta stack, including `references/web-project.md` |
| `hz-immersive-designer` | Comfort, interaction patterns, spatial layout, accessibility (WebXR included) |
| `hz-vr-debug` | Logs, screenshots and video from the headset |
| `hz-perfetto-debug`, `hz-simpleperf-debug` | GPU/CPU frame timing and CPU hotspots on the device |
| `hz-store-submit` | Meta's general submission walkthrough. **Some specs are out of date**: see `ERRATA.md` |

## What was left out (26), and why

Unity, Unreal, Kotlin/Spatial SDK, React Native, Android 2D, Portal and the XR Simulator skills
target other stacks (the XR Simulator works with Unity, Unreal and native OpenXR, not with a
browser). They are in the sister library or in Meta's repo.

`hz-quest-verify-first` and `hz-new-project-creation` route to all of Meta's stacks, so they name
skills that aren't in this library (for example `hz-spatial-sdk` or `hz-unity-meta-core-sdk`).
Those are pointers for other build paths, and nothing for a web app depends on them.

## Updating

```bash
git clone --depth 1 https://github.com/meta-quest/agentic-tools.git /tmp/agentic-tools
diff -rq /tmp/agentic-tools/skills ./   # review what changed before copying over
```
