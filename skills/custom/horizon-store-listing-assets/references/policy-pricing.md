# Store policy, pricing and promotion details (web apps)

Values from developers.meta.com, fetched 2026-10-16; page dates in brackets. Items marked
**unverified** were not confirmed on a Meta page: look them up with `metavr docs search "<topic>"`
before quoting them. Sections 1-7 are engine-neutral and match the Unity edition of this skill;
section 8 is web-specific.

## 1. Prerequisites to publish
- **Org verification** [2026-08-24]: admin (government ID, usually minutes) or business
  (incorporation documents). Without it you can't publish, update apps or recertify a DUC.
- **Create the app** [publish-create-app 2026-08-27]: Dashboard > Create a New App > name >
  Platform: Meta Horizon Store > Create. The App ID is in the Dashboard URL. Names must be unique
  on the platform; after publishing, renaming needs a new submission.
- **Payout and tax info** [publish-overview-smooth-payment, date not checked]: keep payout and
  financial-entity data accurate. **unverified**: exact tax form steps.
- **Developer Distribution Agreement**: an org admin signs it under Legal Documents before the
  first upload. **unverified** on the docs site; source is Meta's `hz-store-pwa` skill and forums.

## 2. Review [publish-app-review 2026-07-07, publish-submit 2026-05-08]
- Technical review against the VRCs, then content review (completeness, polish, value).
- A failed technical review comes with a report; fix and resubmit.
- Submit at least two weeks before the target launch. In saturated categories review may stop at
  the first violation.
- After approval, release immediately or schedule; users can wishlist meanwhile. Managed releases
  are scheduled through the account manager.
- Since 2024-07-31 every Quest app ships through the Horizon Store (App Lab merged)
  [distribution-options 2026-03-23].
- Dashboard performance analytics are not available for web apps [publish-performance-analytics].

## 3. Pricing [monetization-pricing 2026-03-30]
| Item | Min | Max |
|---|---|---|
| App MSRP (unless free) | $0.99 | $299.99 |
| Add-on MSRP | $0.99 | $99.99 |
| Subscription monthly / quarterly / bi-annual / annual | $0.99 / $2.99 / $4.99 / $9.99 | $39.99 / $119.99 / $199.99 / $399.99 |
- Subscription price increases: monthly capped at the lower of $5 or 50% (quarterly, bi-annual,
  annual follow the same pattern with $15/$25/$50); one increase per 90 days, effective 7 days
  after publishing. **Not usable by PWAs** (section 8).
- Prices can change after submission, within consumer-protection law.
- **unverified**: revenue share percentage (set by the developer agreement, not on these pages).

## 4. Sales and promo codes [2026-04-29]
- Sales: Dashboard > app > Growth > Manage Promotions > Create; name, product, dates, discount %,
  review currency conversions, Save as Draft, Submit for Review. Processed sales can't change.
  Only org/team admins create them. An MSRP hold before the first discount may apply (shown in the
  form). **unverified**: discount min/max and cooldowns.
- Meta events: enroll via the Promotion Calendar; cancel during enrollment or email
  metaqueststore@meta.com up to 24 h before the event.
- Custom promo codes: Growth > Promo Codes > Create New; set a usage limit; only for published
  apps and IAP, never free apps.

## 5. Keys [distribution-options 2026-03-23; ps-iap-test 2025-03-27]
- Distribution > Keys > Create: up to **250 keys per request**, **2,000 every 6 months**; Meta may
  change the allocation.
- Keys appear only once the app is approved for release or key generation; you can tie a key to
  an add-on SKU; copy keys immediately (they can't be retrieved later) [ps-iap-test].
- Keys are for press and creators; release channels (up to 2,500 users) are for testers.

## 6. Early Access, Coming Soon, pre-orders
- **Early Access** [2025-12-17]: for newly published apps; Distribution > App Submissions > Edit
  app > App Metadata > Specs > Early Access, then submit. Turning it off is **irreversible**.
  Explain the Early Access status in the description.
- **Coming Soon** up to **360 days** before launch [pre-launch-listings 2026-08-06; the older
  monetization overview says 180]. **Pre-orders** up to **90 days**, for paid apps or free apps
  with paid IAP; charged 24 h before launch; price locked. Both only during the initial
  submission; release date ≥ 14 days out; you can't move it to within 2 weeks of today;
  reverting a pre-order to Coming Soon cancels all pre-orders.

## 7. Age groups [2026-04-02] and Data Use Checkup [2026-10-14]
- Teens and Adults (13+); Mixed Ages (10-12 and 13+); Children (10-12); under 10 not allowed.
- Mixed Ages: Get Age Category API within 30 days; after 60 days without it some Platform SDK
  features stop. Children: no Get Age Category API, no Platform SDK features.
- The age-groups table marks "No ads" as required for every age group, while its text only says
  to comply with Meta's app and ads policies, and Ads.1-7 regulate ad-supported apps. Ambiguous:
  confirm at https://developers.meta.com/horizon/policy/app-policies/ before planning ads.
- DUC: required for Platform SDK features (User ID, User Profile, Followers, Invites, Blocked
  Users, Matchmaking, Parties, Deep Linking, Avatars, Challenges, IAP, Subscriptions, User Age
  Group). Auto-approved during development until the first review submission or raised channel
  limits. Recertify yearly or the app is removed. Test users are exempt while a request is pending.

## 8. Web-specific monetization [ps-iap 2026-10-14; ps-monetization-overview 2026-07-22; ps-iap-s2s; ps-iap-test]
- **Which PWAs:** IAP via the Digital Goods API "only in WebXR PWAs"; **subscriptions are not
  supported**. The service exists only when the PWA is installed from the Store (ALPHA and BETA
  included). Sideload testing: enable `#enable-debug-for-store-billing` in Browser `chrome://flags`.
- **Packaging:** enable Horizon Billing in `bubblewrap init` (or `features.horizonBilling` plus
  `alphaDependencies.enabled` and `applicationId` in `twa-manifest.json`; see
  `horizon-web-store-publish`).
- **Client API:**
  ```js
  const service = await window.getDigitalGoodsService('https://quest.meta.com/billing');
  const details = await service.getDetails(['gems_50']);             // SKUs from the Dashboard
  const request = new PaymentRequest(
    [{ supportedMethods: 'https://quest.meta.com/billing', data: { sku: 'gems_50' } }],
    { total: { label: 'Total', amount: { currency: 'USD', value: '0' } } }); // placeholder values
  const response = await request.show();
  const token = response.details.purchaseToken;   // record it server-side first
  await response.complete('success');             // or Chromium can block input until timeout
  const owned = await service.listPurchases();    // durables + unconsumed consumables
  ```
  There is no API to list SKUs; hard-code them or fetch them from your server. `getDetails` may
  return fewer items, in any order. `listPurchaseHistory()` returns the same as `listPurchases()`.
- **Server side** (`https://graph.oculus.com`, token `OC|<APP_ID>|<APP_SECRET>`, server only):
  `POST /<APP_ID>/verify_entitlement` (`user_id`, optional `sku`; without `sku` it checks the base
  app), `POST /<APP_ID>/consume_entitlement`, `GET /<APP_ID>/viewer_purchases`, `GET
  /application/available_purchases`, `POST /<APP_ID>/refund_iap_entitlement`. At least one APK
  must be uploaded before these work [ps-iap-s2s].
- **User identity:** `getLoggedInUserId()` (app-scoped; `0` = none; DUC review required) and
  `getUserAccountAgeCategory()` (Mixed Ages: call on every launch). Both are exclusive to WebXR PWAs.
- **Testing:** create test users (Development > Test Users), add test cards (always succeeds
  4111 1177 1155 2927; fails at sale 4111 1193 1540 5122); grant or revoke add-on entitlements
  in the Dashboard without buying [ps-iap-test]. Never use real card numbers with test users.
- **Cross-platform note:** Meta's Horizon Billing sample is for native Android (Horizon Billing
  Compatibility SDK mirroring Google Play Billing), not for PWAs.
