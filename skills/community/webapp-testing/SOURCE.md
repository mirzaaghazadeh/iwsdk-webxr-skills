# Source: webapp-testing

- **Repo:** https://github.com/anthropics/skills
- **Path:** `skills/webapp-testing/` (`SKILL.md`, `LICENSE.txt`, `scripts/with_server.py`, `examples/*.py`)
- **Commit:** `dbd4588f9e1033efb41dad4bef2f7947c8993d44` (2026-10-09). The skill itself last changed in `b9e19e6` (2026-04-20).
- **License:** Apache-2.0. The repo has no root license; each skill carries its own. This skill's `LICENSE.txt` is the Apache License 2.0 and is part of the copied folder. (Anthropic's document skills in the same repo are under a different, restrictive license and were not collected.) The repo's `THIRD_PARTY_NOTICES.md` covers other skills' Python dependencies and was not copied.
- **Stars at fetch:** 181582
- **Fetched:** 2026-10-16

## Why it was picked

It is a small, self-contained way for the agent to drive a local web app with Python Playwright:
- `with_server.py` starts one or more dev servers, waits for their ports, runs the test script and stops the servers;
- a reconnaissance-then-action pattern: wait for `networkidle`, screenshot or read the DOM, then act on discovered selectors;
- examples for console log capture, element discovery and `file://` pages.

For an IWSDK game it is useful for scripted smoke tests in CI: the built PWA loads, there are no console errors, the 2D landing page and the "Enter XR" button render, the manifest and service worker are served.

## Security review

- I read the SKILL.md, `with_server.py` and the three examples in full.
- `with_server.py` runs the server commands you pass it with `subprocess.Popen(shell=True)`, polls `localhost` ports and terminates the servers on exit. It makes no other network calls.
- The examples only open `localhost` or `file://` URLs and write screenshots and a log file.

## Caveats

- **IWSDK already has agent browser tooling.** `@iwsdk/vite-plugin-dev` provides XR emulation (IWER), AI-agent tooling over MCP and a managed Playwright browser. Use that for in-XR checks; use this skill for plain scripted tests.
- Headless Chromium has no XR device and renders WebGL in software. A WebGL canvas screenshot can come back black unless the renderer keeps its drawing buffer or the capture happens right after a frame.
- Two examples save to `/mnt/user-data/outputs/`, a claude.ai path. Change it to a project folder.
- It needs Python, the `playwright` package and a Chromium download. Installing them is your decision; nothing here installs them.
- Pass only your own commands to `with_server.py`, since it runs them in a shell.
