#!/usr/bin/env node
// check-pwa-deploy.mjs: pre-packaging checks for a hosted web app that will be wrapped with
// @meta-quest/bubblewrap-cli and shipped on the Meta Horizon Store as a PWA/TWA.
//
// Usage: node check-pwa-deploy.mjs <manifest-url> [--package <android.package.id>]
//          [--sha256 <AA:BB:...>] [--mode immersive|2d] [--allow-http]
//
// Checks
//   manifest : HTTP 200, valid JSON, content type, name/short_name, start_url inside scope,
//              display, icons reachable as PNG with matching sizes, an "any" and a "maskable"
//              icon of at least 512 px (what Bubblewrap 1.24.1 selects)
//   assetlinks: /.well-known/assetlinks.json on the manifest origin and on every
//              additional_trusted_origins host: 200 without redirects, application/json,
//              a handle_all_urls statement for --package with the --sha256 fingerprint
//   exposure : android.keystore / twa-manifest.json not served from the web root
//
// Sources (verified 2026-10-16; URLs moved to /vr/ on 2026-10-17, pages unchanged):
//   developers.meta.com/vr/documentation/web/pwa-overview-gs/ (2026-09-23)
//   developers.meta.com/vr/documentation/web/pwa-packaging/ (2026-07-22)
//   developers.meta.com/vr/documentation/web/pwa-2d-support/ (2026-07-22)
//   developer.android.com/training/app-links/configure-assetlinks (hosting rules)
//   github.com/meta-quest/bubblewrap packages/core/src/lib/{TwaManifest,util}.ts (icon selection)
// Needs Node 18+ (global fetch). No dependencies. Exit: 0 = no FAIL, 1 = FAIL, 2 = usage error.

process.stdout.on('error', (e) => { if (e.code === 'EPIPE') process.exit(fails > 0 ? 1 : 0); throw e; });

const argv = process.argv.slice(2);
const opts = { mode: 'immersive', allowHttp: false, pkg: null, sha256: null, url: null };
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--package') opts.pkg = argv[++i];
  else if (a === '--sha256') opts.sha256 = argv[++i];
  else if (a === '--mode') opts.mode = (argv[++i] || '').toLowerCase();
  else if (a === '--allow-http') opts.allowHttp = true;
  else if (a === '-h' || a === '--help') usage(0);
  else if (!opts.url) opts.url = a;
  else usage(2);
}
if (!opts.url || !['immersive', '2d'].includes(opts.mode)) usage(2);

function usage(code) {
  console.error('usage: node check-pwa-deploy.mjs <manifest-url> [--package <id>] [--sha256 <AA:BB:..>] [--mode immersive|2d] [--allow-http]');
  process.exit(code);
}

let fails = 0;
const pass = (m) => console.log(`PASS  ${m}`);
const warn = (m) => console.log(`WARN  ${m}`);
const fail = (m) => { console.log(`FAIL  ${m}`); fails++; };
const info = (m) => console.log(`      ${m}`);

const normFp = (s) => String(s || '').trim().toUpperCase().replace(/[^0-9A-F]/g, '').replace(/(..)(?!$)/g, '$1:');
const FP_RE = /^([0-9A-F]{2}:){31}[0-9A-F]{2}$/;

function secureOk(u) {
  if (u.protocol === 'https:') return true;
  const local = ['localhost', '127.0.0.1', '[::1]'].includes(u.hostname);
  return opts.allowHttp && local;
}

async function get(url, { manual = false } = {}) {
  try {
    const res = await fetch(url, { redirect: manual ? 'manual' : 'follow', headers: { 'user-agent': 'check-pwa-deploy/1.0' } });
    const buf = Buffer.from(await res.arrayBuffer());
    return { res, buf, type: (res.headers.get('content-type') || '').toLowerCase() };
  } catch (e) {
    return { error: e.cause?.code || e.message };
  }
}

// PNG: 8-byte signature, then IHDR: width @16, height @20, colour type @25 (4/6 = has alpha).
function pngInfo(buf) {
  const sig = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
  if (buf.length < 33 || !sig.every((b, i) => buf[i] === b)) return null;
  const ct = buf[25];
  const hasTrns = buf.includes(Buffer.from('tRNS'));
  return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20), alpha: ct === 4 || ct === 6 || hasTrns };
}

async function checkAssetLinks(origin, label) {
  const url = new URL('/.well-known/assetlinks.json', origin).toString();
  const r = await get(url, { manual: true });
  if (r.error) return fail(`${label} assetlinks: request failed (${r.error}) for ${url}`);
  const s = r.res.status;
  if (s >= 300 && s < 400) return fail(`${label} assetlinks: ${s} redirect to ${r.res.headers.get('location')}; it must be served without redirects (check www/apex and trailing-slash rules)`);
  if (s !== 200) return fail(`${label} assetlinks: HTTP ${s} for ${url} (a TWA verifies against this file; dot-folders are often dropped by deploy tools)`);
  if (!r.type.includes('application/json')) warn(`${label} assetlinks content-type '${r.type || 'none'}'; Android's hosting rules say application/json`);
  let doc;
  try { doc = JSON.parse(r.buf.toString('utf8')); } catch {
    return fail(`${label} assetlinks is not JSON${r.type.includes('html') ? ' (HTML returned: probably an SPA fallback rewrite)' : ''}`);
  }
  if (!Array.isArray(doc)) return fail(`${label} assetlinks must be a JSON array of statements`);
  const stmts = doc.filter((st) => Array.isArray(st?.relation)
    && st.relation.includes('delegate_permission/common.handle_all_urls')
    && st?.target?.namespace === 'android_app');
  if (stmts.length === 0) return fail(`${label} assetlinks has no android_app statement with delegate_permission/common.handle_all_urls`);
  for (const st of stmts) {
    for (const fp of st.target.sha256_cert_fingerprints || []) {
      if (!FP_RE.test(String(fp).toUpperCase())) warn(`${label} fingerprint '${fp}' for ${st.target.package_name} is not colon-separated SHA-256 hex`);
    }
  }
  pass(`${label} assetlinks reachable (${stmts.length} android_app statement(s): ${stmts.map((x) => x.target.package_name).join(', ')})`);
  if (opts.pkg) {
    const mine = stmts.filter((st) => st.target.package_name === opts.pkg);
    if (mine.length === 0) return fail(`${label} assetlinks has no statement for package ${opts.pkg}`);
    pass(`${label} assetlinks lists package ${opts.pkg}`);
    if (opts.sha256) {
      const want = normFp(opts.sha256);
      const have = mine.flatMap((st) => (st.target.sha256_cert_fingerprints || []).map(normFp));
      if (have.includes(want)) pass(`${label} fingerprint matches the signing certificate`);
      else fail(`${label} fingerprint mismatch: expected ${want}, file has ${have.join(', ') || 'none'} (TWA "will not launch" / shows URL bar)`);
    }
  } else {
    warn(`${label} pass --package (and --sha256) to confirm the statement matches your APK`);
  }
}

async function checkNotServed(origin, path) {
  const r = await get(new URL(path, origin).toString(), { manual: true });
  if (r.error || r.res.status !== 200) return pass(`${path} not served (HTTP ${r.error || r.res.status})`);
  if (r.type.includes('text/html')) return warn(`${path} returns HTML with 200 (SPA fallback?); confirm the real file is not deployed`);
  fail(`${path} is publicly downloadable from ${origin}; remove it from the deploy and rotate secrets if exposed`);
}

async function main() {
  let mUrl;
  try { mUrl = new URL(opts.url); } catch { usage(2); }
  console.log(`Checking ${mUrl} (mode: ${opts.mode})`);
  if (!secureOk(mUrl)) { fail(`manifest URL must be HTTPS (Meta: "served over HTTPS"); got ${mUrl.protocol}`); }

  // 1. Manifest
  const m = await get(mUrl.toString());
  if (m.error) { fail(`manifest request failed: ${m.error}`); return finish(); }
  if (m.res.redirected) warn(`manifest redirected to ${m.res.url}; use the final URL in twa-manifest.json`);
  if (m.res.status !== 200) { fail(`manifest HTTP ${m.res.status} (deployment protection returns 401 on per-deploy URLs; use the production alias)`); return finish(); }
  pass('manifest HTTP 200');
  if (m.type.includes('application/manifest+json')) pass('manifest content-type application/manifest+json');
  else if (m.type.includes('json')) warn(`manifest content-type '${m.type}' (application/manifest+json is the registered type)`);
  else warn(`manifest content-type '${m.type || 'none'}'; serve it as application/manifest+json`);
  let man;
  try { man = JSON.parse(m.buf.toString('utf8')); } catch { fail('manifest is not valid JSON'); return finish(); }
  pass('manifest parses as JSON');
  const base = new URL(m.res.url || mUrl.toString());

  // Names (Bubblewrap init validates name 1-50 and launcher name 1-12 characters)
  if (!man.name && !man.short_name) fail('manifest has neither name nor short_name');
  else {
    const name = man.name || man.short_name;
    const launcher = man.short_name || String(man.name).slice(0, 12);
    pass(`name '${name}', launcher label '${launcher}'`);
    if (String(name).length > 50) warn('name is over 50 characters; bubblewrap init rejects it');
    if (man.short_name && String(man.short_name).length > 12) warn('short_name is over 12 characters; bubblewrap init rejects it as the launcher name');
    if (String(name).length > 40) info('note: the Store listing Name field is limited to 40 characters (set separately in the Dashboard)');
  }

  // start_url within scope
  const start = new URL(man.start_url || '/', base);
  const scope = new URL(man.scope || '.', base);
  if (start.origin !== base.origin) fail(`start_url origin ${start.origin} differs from the manifest origin ${base.origin} (Bubblewrap uses the manifest host)`);
  else if (!start.href.startsWith(scope.href)) fail(`start_url ${start.href} is outside scope ${scope.href} (Meta: keep start_url within scope)`);
  else pass(`start_url ${start.pathname}${start.search} inside scope ${scope.pathname}`);
  if (!man.scope) warn('no scope; Bubblewrap falls back to the manifest directory');
  const s = await get(start.toString());
  if (s.error || s.res.status !== 200) fail(`start_url not reachable (HTTP ${s.error || s.res.status})`);
  else pass('start_url HTTP 200');

  // display
  const disp = man.display || '(unset)';
  if (opts.mode === '2d' && disp !== 'standalone') warn(`display '${disp}'; Meta recommends standalone for 2D packages`);
  else if (opts.mode === 'immersive') info(`display '${disp}' (Bubblewrap uses standalone for immersive packages)`);
  else pass('display standalone');
  for (const k of ['theme_color', 'background_color']) if (!man[k]) warn(`${k} not set (Bubblewrap falls back to #FFFFFF)`);

  // icons
  const icons = Array.isArray(man.icons) ? man.icons : [];
  if (icons.length === 0) fail('manifest has no icons');
  let bestAny = 0; let bestMask = 0;
  for (const ic of icons) {
    const src = new URL(ic.src, base).toString();
    const purposes = String(ic.purpose || 'any').split(/\s+/);
    const declared = String(ic.sizes || '').split(/\s+/).map((x) => parseInt(x, 10)).filter(Boolean);
    const r = await get(src);
    if (r.error || r.res.status !== 200) { fail(`icon ${ic.src}: HTTP ${r.error || r.res.status}`); continue; }
    const p = pngInfo(r.buf);
    if (!p) { warn(`icon ${ic.src}: not a PNG (content-type '${r.type}')`); continue; }
    const tag = `icon ${ic.src} ${p.w}x${p.h} [${purposes.join(' ')}]`;
    if (p.w !== p.h) warn(`${tag}: not square`);
    if (declared.length && !declared.includes(p.w)) fail(`${tag}: sizes says '${ic.sizes}' but the file is ${p.w}x${p.h}`);
    else pass(tag);
    if (purposes.includes('any')) bestAny = Math.max(bestAny, p.w);
    if (purposes.includes('maskable')) {
      bestMask = Math.max(bestMask, p.w);
      if (p.alpha) warn(`${tag}: has an alpha channel; Meta's hz-store-pwa skill says the maskable icon must be full-bleed and opaque`);
    }
  }
  if (icons.length) {
    if (bestAny >= 512) pass(`'any' icon of ${bestAny}px available (Bubblewrap needs >= 512)`);
    else fail(`no 'any' icon >= 512px; Bubblewrap leaves iconUrl empty and the build cannot be configured`);
    if (bestMask >= 512) pass(`maskable icon of ${bestMask}px available`);
    else warn('no maskable icon >= 512px; Bubblewrap will not set maskableIconUrl');
  }

  // 2. Digital Asset Links on every trusted origin
  await checkAssetLinks(base.origin, 'primary');
  const extra = Array.isArray(man.additional_trusted_origins) ? man.additional_trusted_origins : [];
  for (const o of extra) {
    let u;
    try { u = new URL(o); } catch { fail(`additional_trusted_origins entry '${o}' is not a URL`); continue; }
    if (u.protocol !== 'https:') fail(`additional_trusted_origins entry '${o}' must be HTTPS`);
    await checkAssetLinks(u.origin, u.host);
  }
  if (extra.length && opts.mode === 'immersive') info('additional_trusted_origins is documented for multi-origin 2D apps; out-of-scope links in immersive packages open in Browser');

  // 3. Secrets must not be on the public host
  for (const p of ['/android.keystore', '/twa-manifest.json']) await checkNotServed(base.origin, p);

  finish();
}

function finish() {
  console.log('----');
  console.log('Not checked here: auto-enter of the immersive session, horizonOSAppMode, APK signing.');
  console.log('Next: scripts/verify-twa-apk.sh on the built APK, then a sideload test on a headset.');
  if (fails > 0) { console.log(`RESULT: ${fails} FAIL(s)`); process.exit(1); }
  console.log('RESULT: no FAILs'); process.exit(0);
}

main().catch((e) => { console.error(e); process.exit(2); });
