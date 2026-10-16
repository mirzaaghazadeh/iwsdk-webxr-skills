---
name: horizon-store-listing-assets
license: MIT
metadata:
  author: Navid Mirzaaghazadeh
  author-url: https://github.com/mirzaaghazadeh
  repository: https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
  version: "1.0.0"
description: >-
  Prepare and validate the Meta Horizon Store listing for a WebXR / IWSDK PWA or
  a 2D PWA: exact art specs (Cover Landscape/Square/Portrait, Hero, Mini
  Landscape, Logo, Icon, Spatialized tile, screenshots, trailer, 360 preview),
  asset VRCs, metadata limits (name, short and long description, keywords),
  specs metadata (play area, input, comfort, internet), age group
  self-certification and IARC rating, privacy policy and Data Use Checkup for
  Digital Goods and user ID, pricing, web IAP limits (WebXR PWAs only, no
  subscriptions), sales, promo codes, keys, Early Access, Coming Soon and
  pre-orders. Includes an image checker. Use when the user asks for "store
  assets for my web app", "cover art size", "screenshots of my WebXR game",
  "trailer requirements", "store description", "age rating / IARC", "privacy
  policy for my Quest PWA", "can my PWA sell items", "set the price", "run a
  sale", "generate keys", or "early access". Replaces the asset table in Meta's
  hz-store-submit, which has wrong dimensions and limits.
---

# Horizon Store listing for web apps: assets, metadata, rating, pricing

> Made by [Navid Mirzaaghazadeh](https://github.com/mirzaaghazadeh) · part of [iwsdk-webxr-skills](https://github.com/mirzaaghazadeh/iwsdk-webxr-skills) · MIT

A PWA's store listing uses the same Developer Dashboard forms, art specs and VRCs as a native
app; the asset VRCs apply to both the Store and Store (2D) columns. What differs for web apps:
how you capture screenshots, the internet requirement, and monetization (Digital Goods API, WebXR
PWAs only). Policy detail: [references/policy-pricing.md](references/policy-pricing.md).

Correction to Meta's `hz-store-submit`: it lists a 1024 px icon, a 2560 × 1440 hero, a
3-screenshot minimum and 30/150/4000-character name/short/long. The live pages give the values
below. If this skill is older than "Last verified", run
`metavr docs fetch https://developers.meta.com/horizon/resources/asset-guidelines/`.

## 1. Art assets (Asset design guidelines, updated 2026-05-11)

| Asset | Size (W × H) | Ratio | Format | Rules |
|---|---|---|---|---|
| Cover Landscape | 2560 × 1440 | 16:9 | 24-bit PNG | Same design family as the other covers and the Hero |
| Cover Square | 1440 × 1440 | 1:1 | 24-bit PNG | Same design family |
| Cover Portrait | 1008 × 1440 | 7:10 | 24-bit PNG | Same design family |
| Hero Cover | 3000 × 900 | 10:3 | 24-bit PNG | Branding or title centred (Asset.4); title text must match the app title |
| Mini Landscape | 1080 × 360 | 3:1 | 24-bit PNG | In the spec table; the page gives no usage notes (check the Dashboard form) |
| Logo | variable, max 9000 × 1440 | - | 32-bit PNG | **Transparent background** (Asset.1) |
| Icon | 512 × 512 | 1:1 | 24-bit PNG | Solid, no transparency |
| Spatialized tile | 180 × 180 background + 180 × 180 foreground | 1:1 | PNG | Foreground transparent, inside the safe area with 18 dp padding, no shadow (Meta adds one). Optional: without layers the existing asset is brought forward |
| Screenshots | 2560 × 1440 | 16:9 | 24-bit PNG | 5, no duplicates, real in-app content, no added text or logos (Asset.5) |
| Trailer | 1080p min, 2K max | 16:9 | MP4 / H.264 / AAC | 30 s to 2 min (Asset.7: ≤ 2 min); follow hardware safety guidelines (wrist straps, play area) |
| Trailer cover | 2560 × 1440 | 16:9 | 24-bit PNG | |
| 360 preview | cubestrip 12288 × 2048 (6:1) or equirect 7680 × 3840 (2:1) | | PNG, JPEG (quality ≥ 80), KTX | ≤ 2.3 MB; Meta suggests rendering 2048 × 2048 faces or an 8192 × 4096 source |
| Immersive Image Layers (Object Left, Object Right, Logo) | not on the guidelines page (unverified) | | | Transparent backgrounds (Asset.9) |

"All assets support 24 and 32-bit PNGs ... the 8-bit alpha layer is ignored unless it's for the
Logo." Keep titles and focal points in the safe area (templates: https://metaque.st/storetemplates;
no pixel values on the page). Branded assets carry the exact app title; only the icon is exempt.
Each extra store language needs localized assets.

Asset VRCs to self-review: Asset.2 (cover art: branding only, no taglines or banners), Asset.3
(Rec: no text in the top or bottom 20% of covers), Asset.5, Asset.6 (no other VR platforms'
hardware or logos anywhere), Asset.8 (Rec: text ≥ 24 pt), Asset.10 (Rec: "Captured on Meta Quest
Pro." on Pro-only footage), Functional.6 (only Meta Quest hardware).

**Validate a folder:** `scripts/check-store-assets.sh <dir>` checks sizes, alpha, screenshot count
and duplicates, and the trailer's codec, size and length (`sips` or ImageMagick, `ffprobe`).
Expected names: `cover_landscape.png`, `cover_square.png`, `cover_portrait.png`, `hero.png`,
`mini_landscape.png`, `logo.png`, `icon.png`, `tile_background.png`, `tile_foreground.png`,
`screenshot_*.png`, `trailer.mp4`, `trailer_cover.png`.

The Store icon is separate from the PWA's manifest icons (192/512 px `any` and `maskable`) that
Bubblewrap turns into the launcher icon; see `horizon-web-store-publish`.

## 2. Capturing screenshots and trailer footage from a web app

- Capture in the **installed TWA on a headset**, not a desktop tab or the IWER / Immersive Web
  Emulator view. Reviewers compare screenshots with the real app (`hz-store-submit`) and
  emulator chrome would break Asset.5.
- `metavr capture screenshot -o shots/s1.png --width 2560 --height 1440` (default output is
  1024 × 1024; check the real size and crop or scale to 16:9 without adding text). MQDH can also
  capture screenshots and video (browser-mqdh).
- Hide debug HUDs, FPS counters, IWSDK dev overlays and Stats panels. In 2D PWAs no URL bar should
  be visible: if it is, asset links are broken (fix that first).
- Show only Meta Quest controllers or hands (Functional.6, Asset.6).

## 3. Metadata (Providing App Metadata, updated 2025-08-20)

| Field | Limit / rule |
|---|---|
| Name | max 40 characters (Publishing.4). Independent of the manifest `name` and Bubblewrap's 12-character launcher name, but keep them consistent |
| Short description | max 500 characters (Publishing.5) |
| Long description | max 1500 characters (Publishing.6) |
| Search keywords | optional, relevant only (Publishing.7) |
| Categorization | Category + Genres |
| Specs | Game Modes, Supported Controllers, Play Area, Supported Player Modes, Comfort Level, Internet Connection, Subscription, Purchase-blocked devices, Social Features, Supported Languages in App, Early Access |
| Details | Publisher Name, Website (Publishing.1, must resolve), Privacy Policy (Privacy.1-4), optional External Support (Publishing.2) and Terms of Service (Publishing.3) |
| Content rating | Developer contact email (shared with IARC) + IARC certificate |

Web-specific: a PWA loads from your server, so declare the internet requirement truthfully and
handle offline (Functional.7, Rec). Declare only input modalities that work alone from launch
(Tracking.2) and a play area that matches (Tracking.1). Web deploys change the app without review;
keep descriptions and media matching what is live (Content.2).

Copywriting: the first sentence says what the player does; every claim is visible in the build;
no other platforms' names; Meta brands only per the Brand Guidelines (Publishing.8); no keyword
stuffing, all-caps titles, or price text in the name or art. Comfort Level (store policy,
unverified on developers.meta.com): Comfortable = little or no camera/player motion; Moderate =
more motion; Intense = first-person camera motion, acceleration or major movement.

## 4. Age group and rating

- **IARC rating** from the Content Rating step; free and instant.
- **Age group self-certification** is separate and mandatory: Teens and Adults (13+), Mixed Ages
  (10-12 plus 13+), Children (10-12); no users under 10. The same value goes in every
  `ovr-platform-util --age-group` upload.
- **Mixed Ages WebXR PWA:** implement `DigitalGoodsService.getUserAccountAgeCategory()` and call it
  "every time your WebXR PWA launches" (ps-iap, 2026-10-14). Implement within 30 days of
  self-certification or risk removal; after 60 days without it, some Platform SDK features stop
  (age-groups, 2026-04-02). 2D PWAs have no Digital Goods service: Mixed Ages may not be workable
  for a 2D PWA (unverified; ask Meta support).
- **Children** apps may not use the Get Age Category API or any Platform SDK feature.

## 5. Privacy policy and Data Use Checkup

Host a privacy policy at a stable URL covering (Privacy.1-4): who you are and a privacy contact;
what you collect (Meta user ID and age category if used, purchases, analytics, crash reporting,
cookies and local storage, voice); how it is used and shared (each third-party SDK, retention);
how users request deletion. 2D PWAs share cookies and site data with Quest Browser
(pwa-2d-support): say so if it matters for your data.

**Data Use Checkup** is required for the WebXR PWA platform features: Digital Goods IAP and
`getLoggedInUserId()` (User ID / User Profile grant) (ps-iap). DUC requests are approved
automatically during development; submitting for review or raising release-channel limits ends
that; recertify **yearly** or the app is removed. Test users can call these features before DUC
approval, except getting the logged-in user.

## 6. Pricing and monetization (summary; details in references)

- App price: free or $0.99-$299.99 MSRP; add-ons $0.99-$99.99; local pricing per country.
- **Web IAP**: Digital Goods API + Payment Request with `https://quest.meta.com/billing`, **WebXR
  PWAs only**, **subscriptions not supported**, available only when installed from the Store
  (ALPHA and BETA count). Manage products under Monetization > Add-ons. 2D PWAs get no Store IAP:
  charge for the app, or run ads within Ads.1-7.
- Sales (Growth > Manage Promotions), promo codes (Growth > Promo Codes, not for free apps), keys
  (up to 250 per request, 2,000 per 6 months), Early Access (new apps only; turning it off is
  irreversible), Coming Soon (up to 360 days) and pre-orders (up to 90 days), both only during the
  initial submission.

## Sources

- https://developers.meta.com/horizon/resources/asset-guidelines/ (2026-05-11)
- https://developers.meta.com/horizon/resources/publish-app-metadata/ (2025-08-20)
- https://developers.meta.com/horizon/resources/publish-quest-req/ (2026-08-19)
- https://developers.meta.com/horizon/resources/age-groups/ (2026-04-02)
- https://developers.meta.com/horizon/resources/publish-data-use/ (2026-10-14)
- https://developers.meta.com/horizon/documentation/web/ps-iap/ (2026-10-14), /ps-monetization-overview/ (2026-07-22), /pwa-2d-support/ (2026-07-22), /browser-mqdh/
- https://developers.meta.com/horizon/resources/monetization/ (2026-05-11), /monetization-pricing/ (2026-03-30)
- https://developers.meta.com/horizon/resources/monetization-sales-promotions/ (2026-04-29), /monetization-custom-promo-codes/ (2026-04-29)
- https://developers.meta.com/horizon/resources/early-access/ (2025-12-17), /pre-launch-listings/ (2026-08-06)
- https://developers.meta.com/vr/policy/distribution-options/ (2026-03-23)
- https://developer.oculus.com/policy/store-policies (comfort ratings, IARC; not re-fetched)

Last verified: 2026-10-16
