# Meta Horizon Store after Connect 2026: condensed reference (web / PWA edition)

Checked 2026-10-17. A summary in our own words, not a copy of Meta's pages. Every row names its
source as `[key date]`; `date` is the page's own "Updated" date, and the keys resolve to full URLs
in [Sources](#sources). "Session only" means the fact comes from a Connect session abstract and no
doc page described it yet. The Unity library carries the same reference with Unity specifics
(`unity-meta-quest-skills/docs/meta-reference/store-2026.md`).

Every `developers.meta.com/horizon/...` page now redirects (HTTP 302) to
`developers.meta.com/vr/...`, which the pages name as canonical. Markdown twins work under both
(`https://developers.meta.com/vr/llmstxt/resources/<page>.md`).

## 1. What Connect 2026 announced for the Store, and what is documented

Connect keynote and recaps: 2026-09-24. Store session "Grow your revenue and get found":
posted 2026-09-30.

| Announcement | Documented? | What a web developer can do today |
|---|---|---|
| Meta VR Glasses (spring 2027; same OS, Store, payments, SDKs; v207) | Yes [recap-vr 2026-09-24; glasses-start 2026-10-13] | Store PWAs reach it through **Future devices** targeting (section 2). Gaze-and-pinch for IWSDK: `get-started-glasses` guide (owned by the IWSDK skills) |
| Store favors controller-free titles for VR Glasses owners without controllers | Blog only [recap-vr 2026-09-24; glasses-start 2026-10-13] | Make every flow work with hands (WebXR `hand-tracking`, pinch `select`) |
| Better recommendations, spotlight, search, ranking | Blog only [recap-vr 2026-09-24] | Keep metadata accurate |
| A/B Pricing | Session only; the Price A/B Testing page is unchanged [price-ab 2025-10-01] | Existing tool, US only (section 3). Expansion **unverified** |
| AI-Powered Analytics | Session only; closest doc is the Meta AI Developer Assistant [ai-assistant 2026-09-24] | Ask it in the Dashboard (read-only) |
| Advanced F2P tooling (IAP and retention) | Session only | Web IAP is still WebXR-PWA-only with no subscriptions [web-iap 2026-10-14] |
| VR ads on Instagram, Messenger, Threads | Session only; ads docs list Facebook and Instagram [app-ads 2026-05-11] | **Unverified** |
| Dashboard: Benchmarks, User Demographics, "PREQ alerts" | Blog [recap-vr 2026-09-24] + pages in section 3 | "PREQ alerts" undocumented |

Shipped before Connect (blog [pricing-blog 2026-08-11]): bundles in store-wide sales, editable
live bundles, achievement-based TBYB, Bayesian TBYB analysis, pre-launch funnel analytics, User
Demographics, automatic quality alerts.

## 2. Meta VR Glasses: what a Store PWA needs

| Topic | Rule | Source |
|---|---|---|
| Binary | 64-bit required. A Bubblewrap TWA has no native code, so it passes | [app-compat 2026-10-13]; Bubblewrap template |
| Store delivery | Production build's **Supported Devices** must include **Future devices** plus each current Quest device. LIVE always needs one forward-compatible build; builds in a submission must be forward-compatible. "All Devices" includes VR Glasses | [app-compat 2026-10-13; targeting 2026-09-04] |
| Targeting at upload | `ovr-platform-util upload-quest-build ... --channel "alpha:quest3+"` (`quest3+` = Quest 3 family, VR Glasses, future devices). `metavr store dist upload` has no targeting option | [targeting 2026-09-04]; metavr reference |
| Input declaration | Meta's Bubblewrap Quest template always adds `oculus.software.handtracking required="false"` and `com.oculus.permission.HAND_TRACKING`, which Meta defines as "controllers and hands". Every TWA therefore claims hand support: make sure hands-only play works (Tracking.2) | [app-compat 2026-10-13]; meta-quest/bubblewrap `template_project` (main @ 2026-09-16) |
| `com.oculus.supportedDevices` | Bubblewrap emits none. The manifest page lists `vrglasses`; the compatibility-mode page says it is "not currently a supported public value". Use Dashboard targeting | [manifest 2026-10-15] vs [compat-mode 2026-09-04] |
| Field of view | 70° × 66° nominal (Quest 3: 110° × 96°). Keep UI near the center; hover never fires | [fov 2026-09-25; recap 2026-09-24] |
| Simulate | `metavr device fov-sim enable [--perceived]` on a Quest 3/3S/Pro, or IWER's glasses profile | [fov 2026-09-25] |
| VRCs and art | **No VRC and no store-asset change for VR Glasses** | [vrc 2026-08-19; assets 2026-05-11] |
| Labels | Store labels and visibility rules can differ from tested behavior; don't present controller/hand support as Store categories | [app-compat 2026-10-13] |

## 3. Pricing experiments, trials and analytics

| Tool | Key rules (web notes in bold) | Source |
|---|---|---|
| Price A/B testing | Growth > Price A/B Testing > Create Pricing Experiment; boundary or incrementality test; starts ≥ 3 days after setup; up to 90 days; 11:00 PT; **US only**; no edits after submit; results by email; may cost sale eligibility within 30 days of a sale | [price-ab 2025-10-01] |
| Try Before You Buy | Time-based (15-30 min) or achievement-based (needs a "simple" achievement); audience 25-100%; no IAP during trial. **Not available for 2D apps.** For an immersive PWA, achievements exist only as server-to-server calls (`graph.oculus.com/<USER_ID>/achievements`), so achievement-based TBYB needs a server; **whether TBYB works for PWAs at all is unverified** | [tbyb 2026-06-29; web-achievements 2026-10-14] |
| Benchmarks | > 100 lifetime active users; 7-day windows; funnel, revenue per active user, retention, crash (immersive and 2D) | [benchmarks 2026-05-22] |
| User Demographics | ≥ 100 lifetime active users; DUC compliance | [demographics 2026-05-06] |
| Alerts | > 100 lifetime active users; no crash/performance alerts for 2D apps; the page says alerts "are not enabled on MQDH or web" (ambiguous for PWAs). Thresholds: crash > 5%, Quest 3 FPS < 72, 1-star ratings, startup > 19 s | [alerts 2025-10-01; pricing-blog 2026-08-11] |
| Performance analytics | **Not available for web apps** (unchanged) | [perf-analytics 2025-02-14] |
| Meta AI Developer Assistant | Read-only analytics, monetization, submission and reviewer-feedback answers in the Dashboard | [ai-assistant 2026-09-24] |

## 4. Monetization for PWAs (unchanged)

| Item | Rule | Source |
|---|---|---|
| Web IAP | Digital Goods API + Payment Request (`https://quest.meta.com/billing`), **WebXR PWAs only, no subscriptions**, only for Store installs | [web-iap 2026-10-14] |
| Add-ons | Bulk TSV (USD only); unconsumed consumables are refunded after 3 days; Store-visible add-ons need ≥ 7 days of review | [add-ons-work 2026-10-14; add-ons-setup 2026-09-28] |
| Bundles, sales, promo codes | Bundles in store-wide sales, per-country base price, live edits without review | [bundles 2026-06-30; pricing-blog 2026-08-11] |
| Meta Credits | Ended for Store purchases on 2026-06-09 | [credits 2026-06-09] |

## 5. Unchanged since 2026-10-16

VRC index [vrc 2026-08-19], release manifest [manifest 2026-10-15], asset guidelines
[assets 2026-05-11], metadata [metadata 2025-08-20], ovr-platform-util [opu 2026-07-20], release
channels [channels 2026-03-23], PWA docs (pwa-overview 2026-07-22, pwa-overview-gs and
web-hosting 2026-09-23), `@meta-quest/bubblewrap-cli` **1.24.1** still npm `latest` (published
2026-05-05; registry entry last modified 2026-08-14), Bubblewrap `main` unchanged since 2026-09-16.

## 6. Open questions (unverified)

- Whether Store upload checks accept Bubblewrap's minSdk 23 / targetSdk 32 / headtracking `required="false"` (still open).
- `vrglasses` in `supportedDevices`; TBYB for immersive PWAs; Price A/B outside the US; Messenger/Threads ads; "PREQ alerts".

## Sources

Dates are each page's "Updated" date (blog and video pages: the post date), checked 2026-10-17.

| Key | Page |
|---|---|
| recap | https://developers.meta.com/blog/meta-connect-recap/ (2026-09-24) |
| recap-vr | https://developers.meta.com/blog/meta-connect-recap-start-building-the-future-of-vr/ (2026-09-24) |
| session | https://developers.meta.com/resources/videos/grow-your-revenue-meta-horizon-store/ (2026-09-30) |
| pricing-blog | https://developers.meta.com/vr/blog/smarter-pricing-better-trials-deeper-analytics-for-VR-developers/ (2026-08-11) |
| glasses-start | https://developers.meta.com/vr/essentials/get-started-with-glasses/ (2026-10-13) |
| app-compat | https://developers.meta.com/vr/essentials/app-compatibility/ (2026-10-13) |
| compat-mode | https://developers.meta.com/vr/essentials/compatibility-mode/ (2026-09-04) |
| fov | https://developers.meta.com/vr/essentials/field-of-view/ (2026-09-25) |
| ai-assistant | https://developers.meta.com/vr/essentials/ai-developer-assistant/ (2026-09-24) |
| targeting | https://developers.meta.com/vr/resources/publish-release-channels-device-targeting/ (2026-09-04) |
| manifest | https://developers.meta.com/vr/resources/publish-mobile-manifest/ (2026-10-15) |
| vrc | https://developers.meta.com/vr/resources/publish-quest-req/ (2026-08-19) |
| assets | https://developers.meta.com/vr/resources/asset-guidelines/ (2026-05-11) |
| metadata | https://developers.meta.com/vr/resources/publish-app-metadata/ (2025-08-20) |
| opu | https://developers.meta.com/vr/resources/publish-reference-platform-command-line-utility/ (2026-07-20) |
| channels | https://developers.meta.com/vr/resources/publish-release-channels/ (2026-03-23) |
| price-ab | https://developers.meta.com/vr/resources/monetization-price-ab-testing/ (2025-10-01) |
| tbyb | https://developers.meta.com/vr/resources/try-before-you-buy/ (2026-06-29) |
| benchmarks | https://developers.meta.com/vr/resources/publish-metrics-benchmarks/ (2026-05-22) |
| demographics | https://developers.meta.com/vr/resources/user-demographics/ (2026-05-06) |
| alerts | https://developers.meta.com/vr/resources/publish-analytics-alerts/ (2025-10-01) |
| perf-analytics | https://developers.meta.com/vr/resources/publish-performance-analytics/ (2025-02-14) |
| add-ons-work | https://developers.meta.com/vr/resources/working-with-add-ons/ (2026-10-14) |
| add-ons-setup | https://developers.meta.com/vr/resources/add-ons-setup/ (2026-09-28) |
| bundles | https://developers.meta.com/vr/resources/monetization-bundles/ (2026-06-30) |
| credits | https://developers.meta.com/vr/resources/monetization-meta-credits-open-beta/ (2026-06-09) |
| app-ads | https://developers.meta.com/vr/resources/app-ads/ (2026-05-11) |
| web-iap | https://developers.meta.com/vr/documentation/web/ps-iap/ (2026-10-14) |
| web-achievements | https://developers.meta.com/vr/documentation/web/ps-achievements/ (2026-10-14) |
