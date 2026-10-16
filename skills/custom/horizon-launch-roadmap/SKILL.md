---
name: horizon-launch-roadmap
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.0.0"
description: >-
  Plan and sequence the launch of an IWSDK / WebXR game or 2D web app on Meta
  Quest: choose between hosted web, the Browser new tab page and a Horizon
  Store PWA; pick 2D vs immersive; list the irreversible decisions (Android
  package id, signing key, origin and Digital Asset Links, Early Access,
  pre-order and Coming Soon windows, Data Use Checkup auto-approval, age group,
  web IAP limits); map each phase to the skill that does the work; and build a
  dated timeline counting back from launch day. Use when the user asks "how do
  I publish my WebXR game", "should I ship as a PWA or just a website", "what's
  the release process for a Quest web app", "plan my launch", "when should I
  submit", "can I do early access / pre-orders", or starts a new IWSDK project
  meant for the store.
---

# Launch roadmap for a Quest web app (IWSDK / WebXR / 2D PWA)

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

A routing and planning skill: each phase points to the skill that does the work. Since
2024-07-31 every Quest app ships through the Meta Horizon Store (App Lab merged). Review has two
stages, technical (the VRCs) then content ("completeness, polish, and value", publish-app-review,
2026-07-07).

## Step 1: pick the distribution path

| Path | What users get | Review | Money | Source |
|---|---|---|---|---|
| Hosted URL in Quest Browser | Open a link; Enter VR button | None | Your own web payments (outside Meta billing) | web index; web-hosting |
| Browser **new tab page** feature | Curated tile in Quest Browser | Multi-step (QA, content, technical); 4 weeks at the top of the shelf, then ranked by monthly traffic; not guaranteed | Same as hosted | browser-new-tab (2026-07-22) |
| **Web Launch** links | `https://www.oculus.com/open_url/?url=<encoded-https-url>` sends a link from a computer or phone to Quest Browser | None | Same as hosted | web-launch (2026-07-22) |
| **Horizon Store PWA** (this library's focus) | Library app, store page, launches like a native app | Full Store review (VRCs) | Paid app; IAP via Digital Goods for **WebXR PWAs only**, no subscriptions | pwa-overview; ps-iap |

The paths combine: the Store PWA is a wrapper around the same hosted site, so you can keep the
site public. Meta: "A web app can remain available through its website without a PWA package."

**Horizon Worlds** is a different product (worlds built in Meta's Horizon desktop editor and
hosted by Meta, no APK, no VRC review). A WebXR or IWSDK project does not port into Worlds; pick
Worlds only for hosted social creations. Background: `docs/research-meta-web.md` in this repo.

## Step 2: decide early (one-way doors)

| Decision | Why it's hard to undo | Source |
|---|---|---|
| **2D vs immersive** | Sets `horizonOSAppMode`, the intent category, auto-enter and which VRC column applies (2D has fewer Required VRCs). Switching later means a rebuilt APK and a different review bar | pwa-packaging; publish-quest-req |
| **Android package id** | "Every update to an existing Store app must use the same package identifier." Don't accept Bubblewrap's `<reversed-host>.twa` default by accident | pwa-packaging |
| **Signing key** | "Every future update must use the same signing certificate." Lost key = new app. Two offline backups plus the passwords | pwa-packaging; Packaging.2 |
| **Origin (host)** | Baked into the APK and checked through `/.well-known/assetlinks.json`. Moving needs a new APK version and assetlinks on both hosts until users update. GitHub Pages project sites can't serve the origin root | pwa-packaging; `horizon-web-store-publish` |
| **Version-code scheme** | Only goes up across every channel. Bubblewrap bumps it on `update` unless told not to | Bubblewrap source; `hz-store-submit` |
| **Monetization model** | Web IAP works only in WebXR PWAs and has no subscriptions. A 2D app or a subscription business needs another plan (paid app, web payments outside the Store, or native) | ps-iap (2026-10-14) |
| **Early Access** | Only for **newly published** apps; turning it off is **irreversible** | early-access (2025-12-17) |
| **Coming Soon / pre-orders** | Only during the **initial submission**; pre-order price can't change; date can't move to within 2 weeks | pre-launch-listings (2026-08-06) |
| **Data Use Checkup** | Needed for Digital Goods IAP and `getLoggedInUserId()`. Auto-approval ends at the first review submission or a raised channel limit; test those features before | ps-iap; publish-data-use (2026-10-14) |
| **Age group** | Mixed Ages WebXR PWAs must call `getUserAccountAgeCategory()` on every launch; Children apps get no Platform SDK features. 2D PWAs have no Digital Goods service (Mixed Ages for 2D: unverified, ask Meta) | ps-iap; age-groups (2026-04-02) |
| **Org verification** | Without it you can't publish, update or recertify | publish-organization-verification |

## Step 3: phases and skills

| Phase | Do | Skills |
|---|---|---|
| 0. Setup | Node and IWSDK project (`npm create @iwsdk@latest`); headset in developer mode; Dashboard org + app; verify the org | `hz-quest-verify-first`, `metavr-cli`, `hz-new-project-creation`, `hz-iwsdk-webxr` (plus IWSDK's own skills) |
| 1. Build | Interaction, UI, comfort, MR features; choose WebXR features per device | `hz-iwsdk-webxr`, `quest-browser-webxr`, `hz-immersive-designer` |
| 2. Host | Production HTTPS origin you control at the root; staging origin for tests | `horizon-web-store-publish` (references/hosting.md), `hz-store-pwa` |
| 3. Package and test | Bubblewrap build, verify, sideload, ALPHA/BETA (200 users default, up to 2,500) | `horizon-web-store-publish`, `hz-vr-debug` |
| 4. Platform features | Digital Goods IAP, user ID, age category, server checks; fill the DUC | `horizon-store-listing-assets` (references/policy-pricing.md) |
| 5. Performance and compliance | OVR Metrics 45-minute runs; VRC audit; fix FAILs and RISKs | `horizon-web-vrc-checklist`, `quest-browser-webxr`, `hz-perfetto-debug` |
| 6. Listing | Art, metadata, IARC, age group, privacy policy, price | `horizon-store-listing-assets` |
| 7. Submit | Production channel + Submission tab > Submit for Review (Dashboard, by the user) | `hz-store-submit`, `horizon-web-vrc-checklist` |
| 8. Live ops | Web redeploys via staging; APK updates for native changes; sales, promo codes, keys; yearly DUC | `horizon-web-store-publish`, `horizon-store-listing-assets` |

## Step 4: timeline, counting back from launch day L

| When | Milestone | Rule |
|---|---|---|
| Before any upload | Package id, key, origin, mode fixed; org verified; DDA signed | See Step 2 |
| ≤ L-360 d | Coming Soon page (optional) | Up to 360 days out, only in the initial submission (older overview page says 180) |
| ≤ L-90 d | Pre-orders (optional) | Paid apps or free apps with paid IAP; charged 24 h before launch |
| L-6 to L-4 weeks | Release candidate in RC; VRC audit clean; listing complete; production origin frozen | Leave room for one rejection cycle |
| ≥ L-2 weeks | **Submit for Review** | Meta: at least two weeks before launch |
| ≥ L-14 d | Release date set (pre-order launches) | Date ≥ 14 days out |
| After approval | Release now or schedule; wishlists open | No release date before approval |
| L | Launch | Copy future APK builds to Production; web changes go live on deploy, so freeze risky changes around launch |
| L + 1 year | DUC recertification | Otherwise the app is removed |

Plan for review taking longer than two weeks (`hz-store-submit`: holidays and resubmissions
stretch it).

## Web-specific risks to track

- **Bubblewrap vs release-manifest rules**: Meta's template emits targetSdk 32 / minSdk 23 while
  the manifest page asks new apps for targetSdk 34 (see `horizon-web-store-publish`). Upload a
  first ALPHA build early, weeks before submission, to learn whether Store checks accept it.
- **Unreviewed changes**: web deploys reach Store users without review. Keep the reviewed
  experience, metadata (Content.2) and age-appropriate content stable; test on staging first.
- **Hosting is now production infrastructure**: uptime, TLS renewal and the assetlinks file
  decide whether the Store app launches at all.

Before quoting any rule or date, re-verify with `metavr docs search "<rule>"` or
`metavr docs fetch <url>` if "Last verified" is more than a few months old, and cite the URL.

## Sources

- https://developers.meta.com/horizon/documentation/web/ (2026-07-22), /pwa-overview/ (2026-07-22), /pwa-packaging/ (2026-07-22), /ps-iap/ (2026-10-14)
- https://developers.meta.com/horizon/documentation/web/browser-new-tab/ (2026-07-22), /web-launch/, /web-hosting/ (2026-09-23)
- https://developers.meta.com/horizon/resources/publish-quest-req/ (2026-08-19)
- https://developers.meta.com/vr/policy/distribution-options/ (2026-03-23)
- https://developers.meta.com/horizon/resources/publish-submit/ (2026-05-08), /publish-app-review/ (2026-07-07)
- https://developers.meta.com/horizon/resources/early-access/ (2025-12-17), /pre-launch-listings/ (2026-08-06), /monetization/ (2026-05-11)
- https://developers.meta.com/horizon/resources/publish-data-use/ (2026-10-14), /age-groups/ (2026-04-02)
- https://developers.meta.com/horizon/resources/publish-organization-verification/ (2026-08-24), /publish-release-channels/ (2026-03-23)
- https://developers.meta.com/horizon-worlds/ (Worlds; summary in docs/research-meta-web.md)

Last verified: 2026-10-16
