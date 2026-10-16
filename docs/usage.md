# Using the skills

You don't call skills by hand. Describe what you want, and Claude picks the matching skill from its
description. Naming a skill ("use horizon-web-vrc-checklist") makes the choice explicit. Plugin
installs also let you type it as a slash command, for example `/iwsdk-core:iwsdk-dev-workflow`.

## First session

Open Claude Code in your IWSDK project (or an empty folder for a new game) and start with:

> Use iwsdk-dev-workflow to plan my WebXR game. It's a [one-line pitch]. Check my setup first.

`iwsdk-dev-workflow` lays out the path below. For app code, Claude goes through IWSDK's own
`iwsdk-dev` skill, which picks a playbook and proves each change in the running emulator.

## The path, as prompts

| # | Phase | Example prompt | Skills that pick it up |
|---|---|---|---|
| 0 | Plan | "Help me write a one-page GDD for a mixed-reality board game, then a 1-hour prototype plan." | `game-gdd-author`, `prototype-fast`, `hz-immersive-designer` |
| 0 | Launch plan | "Should this be a web link or a Store PWA? What can't I change after the first upload?" | `horizon-launch-roadmap` |
| 1 | Set up | "Create a new IWSDK VR project with grabbing, physics and locomotion, and connect the MCP tools to Claude Code." | `iwsdk-project-setup` |
| 1 | Features | "Can Quest Browser do plane detection and hand tracking? How do I request them?" | `quest-browser-webxr` |
| 2 | Build | "Add a table with physics dice the player can pick up and throw." | `iwsdk-dev` → `iwsdk-compose-scene`, `iwsdk-physics`, `iwsdk-grab` |
| 2 | UI | "Add a world-space start menu with a Play button." | `iwsdk-ui` |
| 2 | Assets | "Import ./art/dice.fbx, compress it and check it loads." | `iwsdk-asset-pipeline` |
| 3 | Emulator | "Prove the dice can be grabbed and released in the emulator." | `iwsdk-grab`, `iwsdk-debug` |
| 3 | Tests | "Add a smoke test and a GitHub Actions job." | `iwsdk-testing` |
| 4 | On the Quest | "Open the dev server on my Quest over USB and show me the console." | `iwsdk-quest-device-testing`, `hz-vr-debug` |
| 4 | Automation | "Script a real Quest session that grabs a die and checks it lands." | `iwsdk-native-xr-test` |
| 4 | VR Glasses | "Make my game work on Meta VR Glasses without controllers, and test it in the emulator." | `iwsdk-vr-glasses`, `quest-browser-webxr` |
| 5 | Performance | "It drops frames when 20 dice are on the table. Find out why." | `iwsdk-performance`, `hz-perfetto-debug` |
| 5 | Review | "Use the iwsdk-project-code-reviewer agent to review src/." | IWSDK review agent |
| 6 | Host | "Deploy to Cloudflare Pages and make sure /.well-known/ is served." | `iwsdk-hosting`, `wrangler` |
| 6 | Package | "Package it as an immersive PWA and check the APK." | `horizon-web-store-publish` |
| 7 | Store checks | "Run the VRC audit and list what fails, by VRC ID." | `horizon-web-vrc-checklist` |
| 8 | Listing | "Check my store art in ./store-assets and draft the store description." | `horizon-store-listing-assets` |
| 9 | Upload | "Upload version 1.0.3 to the ALPHA channel with these release notes." | `horizon-web-store-publish` |

## What stays your job

Claude asks before anything that's hard to undo or public. Some steps only you can do:

- **Developer Dashboard**: create the organization and app, fill in the listing, answer the age
  rating (IARC) and Data Use Checkup, and press **Submit for Review**.
- **Signing key**: create it once, back it up, and keep it out of the web root and git. If you lose
  it you can't update the app. After each deploy, check that `https://<domain>/android.keystore`
  returns 404.
- **Domain**: the PWA's domain and its `/.well-known/assetlinks.json` tie the store app to your
  site. Pick a domain you'll keep.
- **Approvals**: deploys, uploads, channel promotion, installing tools and writing agent config all
  need your yes.
- **The headset**: put it on. Comfort, readability and the real frame rate only show in the device.

## Tips

- **Keep the dev server running.** IWSDK's MCP tools (`iwsdk-runtime`) only work while
  `npm run dev` / `npx @iwsdk/cli dev up` is up. Every tool also has a CLI twin with JSON output.
- **Emulator numbers aren't headset numbers.** `browser_profile` results are desktop diagnostics;
  measure performance on the Quest.
- **Keep the context small.** Enable `iwsdk-core` for daily work and add bundles when a phase needs
  them (`claude plugin enable` / `disable`).
- **Built-ins first:** IWSDK already has grabbing, ray interaction, UIKitML panels, locomotion,
  physics and audio. The `pmndrs-*` skills are low-level references.
- **When guidance disagrees**, trust the `iwsdk-*` and `horizon-*` skills and the two `ERRATA.md`
  files over Meta's `hz-iwsdk-webxr` (IWSDK 0.4 era). Ask Claude to check live docs when in doubt.
