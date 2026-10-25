# Installing the skills

There are four ways to install. Pick **one** per machine or project. Mixing them installs the same
skills twice, and Claude then sees duplicates.

| Method | Best for | Updates |
|---|---|---|
| [A. Claude Code plugin](#a-claude-code-plugin-recommended) | Most people. Install by bundle with one command; includes the IWSDK review agent | `claude plugin update` |
| [B. `npx skills`](#b-npx-skills) | Picking individual skills; other agents (Cursor, Codex, Copilot…) | `npx skills update` |
| [C. `gh skill`](#c-gh-skill) | GitHub CLI users; pinning to a tag or commit | `gh skill update` |
| [D. `install.sh` from a clone](#d-installsh-from-a-clone) | Offline use, symlinks that track `git pull`, custom folders | `git pull` (with `--link`) |

## Before you start

You need these to **use** the skills, not to install them:

| Tool | Why | Get it |
|---|---|---|
| Claude Code | Runs the skills. v2.1.275+ for the one-step plugin install | https://code.claude.com |
| Node.js `>=20.19 <21`, `>=22.12 <23`, or `>=24` | IWSDK 1.0.1's supported ranges | https://nodejs.org |
| An IWSDK project | The skills work inside it | `npm create @iwsdk@latest my-app` (the `iwsdk-project-setup` skill picks the flags) |
| A Quest in Developer Mode, plus `adb` | Testing on the device | https://developers.meta.com/vr/documentation/native/android/mobile-device-setup/ |
| Meta developer account and organization | Publishing to the Horizon Store | https://developer.meta.com |

The scaffold installs the IWSDK CLI, the IWER emulator runtime and Meta's `metavr` into the
project's `node_modules`. `iwsdk-project-setup` explains what it writes and its side effects.

### Already have a scaffolded project?

Projects made with `npm create @iwsdk` contain IWSDK's 12 official skills in `.claude/skills/`,
the `iwsdk-project-code-reviewer` agent and the MCP config. Install **`iwsdk-core`** (and any
community bundles), but **not `iwsdk-official`**.

---

## A. Claude Code plugin (recommended)

| Bundle | Skills | Always-on context | Contents |
|---|---|---|---|
| `iwsdk-core` | 17 | ~3.7k tokens | **Start here.** Router, guardrail, metavr, setup + MCP, Quest Browser features, Meta VR Glasses readiness, assets, tests, headset testing, performance, Perfetto, comfort, release pipeline, web VRCs, store listing, launch plan |
| `iwsdk-official` | 13 + agent | ~1.0k | IWSDK team's skills and review agent. Not for scaffolded projects |
| `meta-web-extras` | 5 | ~0.4k | Meta's IWSDK skill (0.4 era), PWA store guide, submission walkthrough, scaffolder, simpleperf |
| `community-web` | 10 | ~1.1k | pmndrs libraries under IWSDK, three.js loading, Playwright, service workers, Cloudflare |
| `community-design-art` | 12 | ~1.3k | XR design reference, GDD, prototyping, playtesting, trailer review, Blender pipeline |

The context figures come from `claude plugin details` and are added to every session while the
bundle is enabled. A skill's full text loads only when it's used.

**One step** (Claude Code 2.1.275 or later), in a Claude Code session:

```
/plugin install iwsdk-core --marketplace mirzaaghazadeh/iwsdk-webxr-skills
```

**Two steps** (any version):

```
/plugin marketplace add mirzaaghazadeh/iwsdk-webxr-skills
/plugin install iwsdk-core@iwsdk-webxr-skills
```

**From your shell**, for one project only (writes the project's `.claude/settings.json`, so the
whole team gets it):

```bash
claude plugin install iwsdk-core --marketplace mirzaaghazadeh/iwsdk-webxr-skills --scope project
```

Add more bundles the same way. Plugin skills show up with the bundle as a prefix, such as
`iwsdk-core:iwsdk-dev-workflow`, and the agent as `iwsdk-official:iwsdk-project-code-reviewer`.

| Task | Command |
|---|---|
| See what a bundle contains and costs | `claude plugin details iwsdk-core` |
| Update | `claude plugin marketplace update iwsdk-webxr-skills`, then `claude plugin update iwsdk-core@iwsdk-webxr-skills` |
| Turn a bundle off for a while | `claude plugin disable iwsdk-core@iwsdk-webxr-skills` |
| Remove a bundle | `claude plugin uninstall iwsdk-core@iwsdk-webxr-skills` |
| Remove everything | `claude plugin marketplace remove iwsdk-webxr-skills` |

## B. `npx skills`

[skills.sh](https://skills.sh)'s CLI finds all 57 skills, grouped by bundle. Agents aren't
installed this way.

```bash
npx skills add mirzaaghazadeh/iwsdk-webxr-skills --list
npx skills add mirzaaghazadeh/iwsdk-webxr-skills -a claude-code \
  --skill iwsdk-dev-workflow --skill quest-browser-webxr --skill horizon-web-store-publish
npx skills add mirzaaghazadeh/iwsdk-webxr-skills -a claude-code -g --skill '*'
```

Projects install to `.claude/skills/`, and `-g` installs to `~/.claude/skills/`. Update with
`npx skills update` and remove with `npx skills remove <name>`.

## C. `gh skill`

The GitHub CLI's `gh skill` (in preview) finds the skills as `<group>/<name>`, for example
`custom/iwsdk-dev-workflow` or `iwsdk-official/iwsdk-dev`.

```bash
gh skill install mirzaaghazadeh/iwsdk-webxr-skills                       # pick interactively
gh skill install mirzaaghazadeh/iwsdk-webxr-skills custom/iwsdk-dev-workflow --agent claude-code
gh skill install mirzaaghazadeh/iwsdk-webxr-skills --all --agent claude-code --scope user
```

Update with `gh skill update`.

## D. `install.sh` from a clone

The script installs the same five bundles as the plugin (it reads `.claude-plugin/marketplace.json`),
including the IWSDK agent into `.claude/agents/`. It needs bash and Python 3.

```bash
git clone https://github.com/mirzaaghazadeh/iwsdk-webxr-skills.git
cd iwsdk-webxr-skills

./install.sh --list                                           # bundles, skills and agents
./install.sh --project ~/Games/MyWebXRGame iwsdk-core         # into MyWebXRGame/.claude/skills
./install.sh --user iwsdk-core community-design-art           # into ~/.claude/skills
./install.sh --project ~/Games/MyWebXRGame --link iwsdk-core  # symlinks: `git pull` updates them
./install.sh --dest ~/Games/MyWebXRGame/.agents/skills all    # another agent's folder (skills only)
./install.sh --project ~/Games/MyWebXRGame --dry-run all      # preview, change nothing
./install.sh --project ~/Games/MyWebXRGame --uninstall community-web
```

Existing items are skipped unless you pass `--force`. Any single skill name works in place of a
bundle, for example `./install.sh --user pmndrs-uikit`.

## E. By hand

Copy skill folders into `.claude/skills/` (one project) or `~/.claude/skills/` (every project), and
`skills/iwsdk-official/agents/*.md` into `.claude/agents/`. Keep each folder's name exactly as it
is: it must match the skill's `name:`. Keep `LICENSE`, `LICENSE.txt` and `NOTICE` files with the
folders you copy.

---

## Avoid duplicates

- In a scaffolded IWSDK project, skip `iwsdk-official` (the scaffold already has it).
- Don't combine Meta's `meta-vr` plugin, `metavr init` or `metavr skills` with this library: they
  install the same Meta skills. `metavr init` installs at user scope (every project); what it
  writes, and how to move it into one project, is in
  [meta-reference/ai-tools.md](meta-reference/ai-tools.md) §3.
- The `scenario-blender-*` specialists need `scenario-blender-expert` next to them. The bundles keep
  them together; if you pick single skills, install the lead skill too.

## Troubleshooting

| Problem | Fix |
|---|---|
| Skills don't appear | Start a new session or run `/reload-plugins`. Check `claude plugin list` or `ls .claude/skills` |
| "Plugin not found in marketplace" | Use the bundle name before `@`, for example `iwsdk-core@iwsdk-webxr-skills` |
| IWSDK MCP tools missing | Start the dev server first (`npm run dev` or `npx @iwsdk/cli dev up`), then a new session. See [mcp/README.md](../mcp/README.md) |
| Wrong Node version | Use one of IWSDK's supported ranges (see the table at the top) |
| The headset can't open the dev server | Use `adb reverse` over USB or the LAN URL; accept the self-signed certificate. `iwsdk-quest-device-testing` walks through it |
