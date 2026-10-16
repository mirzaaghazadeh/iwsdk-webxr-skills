# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Cursor, Copilot and others) working with this
repository. People should start at [README.md](README.md).

This repo is a **skill library**: 57 Agent Skills and one subagent for building WebXR games and
apps with Meta's Immersive Web SDK (IWSDK), testing them on Meta Quest and shipping them on the
Meta Horizon Store as PWAs. It holds no app code.

## Layout

```
skills/custom/<skill>/             12  Original skills by Navid Mirzaaghazadeh (MIT)
skills/iwsdk-official/<skill>/     13  IWSDK team's skills, copied unchanged (MIT) + ERRATA.md
skills/iwsdk-official/agents/       1  iwsdk-project-code-reviewer subagent (plugin loads it here)
skills/meta-official/<skill>/      10  Meta's skills, copied unchanged (Apache-2.0) + ERRATA.md
skills/community/<skill>/          22  Third-party skills, copied unchanged (MIT/Apache)
.claude-plugin/marketplace.json        Five plugin bundles; the single source of truth for bundles
install.sh                             Installs bundles, skills and agents by reading marketplace.json
docs/                                  install.md, usage.md, research notes, metavr CLI reference
mcp/                                   How IWSDK's and Meta's MCP servers connect to Claude Code
```

Every folder name equals its skill's `name:`. Every third-party folder has a `SOURCE.md`.

## If a user asks you to install skills from this repo

1. **Ask where** (one project or every project) and **which bundles**. Default to `iwsdk-core`
   in the project.
2. **Check for a scaffolded project first.** If the project has `.claude/skills/iwsdk-dev/` (made
   by `npm create @iwsdk`), it already has the `iwsdk-official` skills and agent: don't install
   that bundle. Also check for Meta's `meta-vr` plugin and for Meta skills installed by
   `metavr init` / `metavr skills install` (run `metavr skills status`; they live in
   `~/.agents/skills`), which duplicate the Meta skills.
3. **Pick one method.** As Claude Code:
   `claude plugin install iwsdk-core --marketplace mirzaaghazadeh/iwsdk-webxr-skills --scope project`.
   Otherwise `./install.sh --project <dir> <bundle>` from a clone, or `npx skills add` /
   `gh skill install` (see [docs/install.md](docs/install.md)).
4. **Confirm** before changing user-level settings (`--scope user`, `~/.claude/`).
5. Tell the user to start a new session or run `/reload-plugins`, then suggest:
   "Use iwsdk-dev-workflow to plan my WebXR game."

## If you are using these skills in an IWSDK project

- Start with `iwsdk-dev-workflow` (the router). For any change to app code, scenes, models or UI,
  invoke `iwsdk-dev` first. For Quest or store facts, `hz-quest-verify-first`.
- **Prove it in the runtime, then on the device**: typecheck, `npx @iwsdk/cli dev up`, ECS/XR
  evidence (`xr status`), then the headset. A compile or a flat screenshot isn't proof.
- **Ask before:** deploying to a public host, any Store upload or channel promotion, creating a
  signing key, `npm i -g`, Playwright browser downloads, `adapter sync` (writes agent config) and
  `--allow-browser-automation`.
- **Never** put keystores, key passwords, app secrets or deploy tokens in `public/`, `dist/`, git
  or chat output. After every deploy, check that `https://<domain>/android.keystore` returns 404.
- Prefer the `iwsdk-*` and `horizon-*` skills over Meta's `hz-iwsdk-webxr` (IWSDK 0.4 era) and
  `hz-store-submit` / `hz-store-pwa` where they differ. See both `ERRATA.md` files.

## If you are changing this repository

- **Don't edit** files under `skills/iwsdk-official/`, `skills/meta-official/` or third-party
  folders in `skills/community/`. Refresh them from upstream as their `SOURCE.md` describes, and
  record disagreements in that folder's `ERRATA.md`.
- **Custom skills** (`skills/custom/`): keep `name:` equal to the folder name, keep
  `license: MIT`, the `metadata.author` block and the "Made by" line, cite a source for every API,
  number or flag, mark anything unconfirmed as unverified, and update `Last verified:`.
- **New or moved skills:** add the path to exactly one bundle in
  `.claude-plugin/marketplace.json` (`iwsdk-official` paths are relative to
  `./skills/iwsdk-official`), add a row to the README catalog, and for third-party skills add
  `LICENSE`/`NOTICE`, a `SOURCE.md` and a row in `THIRD_PARTY_NOTICES.md`. See
  [CONTRIBUTING.md](CONTRIBUTING.md).
- **Check before committing:**
  ```bash
  claude plugin validate . --strict
  ./install.sh --list
  ./install.sh --project /tmp/skilltest --dry-run all
  ```
- Never commit `.env` files, keystores (`*.keystore`, `*.jks`) or credentials. `.gitignore`
  blocks the common ones.
