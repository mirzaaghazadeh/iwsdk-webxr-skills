#!/usr/bin/env bash
# verify-twa-apk.sh: pre-upload checks of a Bubblewrap-built Meta Quest PWA/TWA APK
# (VRC.Quest.Packaging.1-6, Security.2, Digital Asset Links).
# Usage: verify-twa-apk.sh app-release-signed.apk [--mode immersive|2d]
#          [--assetlinks <https-url-or-file>] [--expect-app-id <horizon-app-id>]
# Needs Android build-tools (aapt2, apksigner). It looks in ANDROID_BUILD_TOOLS, PATH,
# ~/.bubblewrap/android_sdk (where Bubblewrap installs them), ANDROID_HOME and ANDROID_SDK_ROOT.
# Node is used to parse assetlinks JSON (Bubblewrap already needs Node 18+).
# Exit: 0 = no FAIL (read RISK/WARN lines), 1 = at least one FAIL, 2 = usage/tooling error.
# Rules verified 2026-10-17 against developers.meta.com/vr/resources/publish-mobile-manifest/
# (2026-10-15), /vrc-quest-packaging-1..6/, /vrc-quest-security-2/ (2026-03-30), /permissions-*,
# /vr/essentials/app-compatibility/ (2026-10-13), and the meta-quest/bubblewrap template
# (packages/core/template_project, main @ 2026-09-16).
set -u

APK="${1:-}"; shift || true
MODE="immersive"; ASSETLINKS=""; EXPECT_APP_ID=""
while [ $# -gt 0 ]; do
  case "$1" in
    --mode) MODE="$(echo "${2:-}" | tr '[:upper:]' '[:lower:]')"; shift 2;;
    --assetlinks) ASSETLINKS="${2:-}"; shift 2;;
    --expect-app-id) EXPECT_APP_ID="${2:-}"; shift 2;;
    *) echo "unknown argument: $1" >&2; exit 2;;
  esac
done
if [ -z "$APK" ] || [ ! -f "$APK" ] || { [ "$MODE" != "immersive" ] && [ "$MODE" != "2d" ]; }; then
  echo "usage: $0 app.apk [--mode immersive|2d] [--assetlinks <url|file>] [--expect-app-id <id>]" >&2
  exit 2
fi

find_tool() {
  local name="$1" dir hit
  if [ -n "${ANDROID_BUILD_TOOLS:-}" ] && [ -x "$ANDROID_BUILD_TOOLS/$name" ]; then
    echo "$ANDROID_BUILD_TOOLS/$name"; return 0
  fi
  if command -v "$name" >/dev/null 2>&1; then command -v "$name"; return 0; fi
  for dir in "$HOME/.bubblewrap/android_sdk/build-tools" "${ANDROID_HOME:-}/build-tools" \
             "${ANDROID_SDK_ROOT:-}/build-tools" "$HOME/Library/Android/sdk/build-tools"; do
    [ -d "$dir" ] || continue
    hit=$(ls -d "$dir"/*/ 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$hit" ] && [ -x "${hit}${name}" ]; then echo "${hit}${name}"; return 0; fi
  done
  return 1
}

AAPT2=$(find_tool aapt2) || { echo "aapt2 not found; set ANDROID_BUILD_TOOLS (Bubblewrap puts it in ~/.bubblewrap/android_sdk/build-tools/<ver>)" >&2; exit 2; }
APKSIGNER=$(find_tool apksigner) || { echo "apksigner not found; set ANDROID_BUILD_TOOLS" >&2; exit 2; }
# apksigner is a Java wrapper; fall back to the JDK Bubblewrap downloaded if java is missing.
if ! java -version >/dev/null 2>&1; then
  BW_JDK=$(ls -d "$HOME"/.bubblewrap/jdk/*/ 2>/dev/null | head -n 1)
  [ -n "$BW_JDK" ] && [ -x "${BW_JDK}Contents/Home/bin/java" ] && BW_JDK="${BW_JDK}Contents/Home/"
  [ -n "$BW_JDK" ] && [ -x "${BW_JDK}bin/java" ] && export JAVA_HOME="${BW_JDK%/}" PATH="${BW_JDK}bin:$PATH"
fi

FAILS=0; RISKS=0
pass() { echo "PASS  $*"; }
warn() { echo "WARN  $*"; }
risk() { echo "RISK  $*"; RISKS=$((RISKS + 1)); }
fail() { echo "FAIL  $*"; FAILS=$((FAILS + 1)); }

BADGING=$("$AAPT2" dump badging "$APK" 2>/dev/null) || { echo "aapt2 dump badging failed" >&2; exit 2; }
XMLTREE=$("$AAPT2" dump xmltree --file AndroidManifest.xml "$APK" 2>/dev/null) || XMLTREE=""

pkg=$(echo "$BADGING" | sed -n "s/^package: name='\([^']*\)'.*/\1/p")
vcode=$(echo "$BADGING" | sed -n "s/^package: .* versionCode='\([^']*\)'.*/\1/p")
vname=$(echo "$BADGING" | sed -n "s/^package: .* versionName='\([^']*\)'.*/\1/p")
csdk=$(echo "$BADGING" | sed -n "s/^package: .* compileSdkVersion='\([^']*\)'.*/\1/p")
minsdk=$(echo "$BADGING" | sed -n "s/^sdkVersion:'\([0-9]*\)'.*/\1/p")
tsdk=$(echo "$BADGING" | sed -n "s/^targetSdkVersion:'\([0-9]*\)'.*/\1/p")
echo "APK: $APK"
echo "package=$pkg versionCode=$vcode versionName=$vname minSdk=$minsdk targetSdk=$tsdk compileSdk=${csdk:-unset} mode=$MODE"
echo "----"

# Package name: permanent identity of the Store app (pwa-packaging: same id for every update)
case "$pkg" in
  "") fail "could not read package name";;
  *.twa) warn "package '$pkg' is Bubblewrap's generated default (reversed host + .twa); it can never change after the first upload";;
  com.example.*|com.oculus.*|com.meta.*) warn "package '$pkg' looks reserved or placeholder; choose your own before the first upload";;
  *) pass "package name $pkg";;
esac
[ -n "$vcode" ] && echo "INFO  versionCode $vcode must be higher than every build already uploaded to any channel"

# SDK levels. Meta's release-manifest page asks for minSdk 29-34 and targetSdk 34 for apps
# created since 2026-03-01; the Bubblewrap 1.24.1 Quest template emits minSdk 23 / targetSdk 32.
# Whether Store upload checks exempt TWAs is not documented, so this is reported as RISK.
if [ -n "$minsdk" ] && [ "$minsdk" -ge 29 ] && [ "$minsdk" -le 34 ]; then pass "minSdkVersion $minsdk within 29-34"
else risk "minSdkVersion '$minsdk' is outside the 29-34 range on publish-mobile-manifest (Bubblewrap --metaquest sets 23); confirm with the ALPHA upload's Test Status"; fi
if [ -n "$tsdk" ] && [ "$tsdk" -eq 34 ]; then pass "targetSdkVersion 34"
elif [ -n "$tsdk" ] && [ "$tsdk" -ge 32 ]; then risk "targetSdkVersion $tsdk: apps created since 2026-03-01 must target 34 (Bubblewrap's Quest template hard-codes 32); confirm with the ALPHA upload's Test Status"
else fail "targetSdkVersion '$tsdk' below 32"; fi
if [ -n "$csdk" ] && [ -n "$tsdk" ] && [ "$csdk" -lt "$tsdk" ]; then fail "compileSdkVersion $csdk < targetSdkVersion $tsdk"; fi

# Debuggable (publish-mobile-manifest: false or unset)
if echo "$BADGING" | grep -q "^application-debuggable"; then fail "android:debuggable=true"; else pass "not debuggable"; fi

# 64-bit (Packaging.6). A TWA ships no native code unless horizonPlatformSDK or horizonBilling
# bundles Meta's platform library, which comes in four ABIs.
native=$(echo "$BADGING" | sed -n "s/^native-code: //p")
if [ -z "$native" ]; then pass "no native code (64-bit rule satisfied trivially)"
elif echo "$native" | grep -q "armeabi-v7a\|x86"; then fail "native code includes non-ARM64 ABIs: $native (from horizonPlatformSDK/horizonBilling: turn off what you don't use, or strip the other ABIs and sign again; SKILL.md section 4)"
else pass "native code: $native"; fi

# Signing (Packaging.2) and certificate fingerprint for Digital Asset Links
SIGN=$("$APKSIGNER" verify --verbose --print-certs "$APK" 2>&1)
if echo "$SIGN" | grep -q "Verified using v2 scheme (APK Signature Scheme v2): true"; then pass "APK Signature Scheme v2"
else fail "not signed with APK Signature Scheme v2 (run bubblewrap build, not the unsigned gradle output)"; fi
if echo "$SIGN" | grep -qi "CN=Android Debug"; then fail "signed with the Android debug certificate"; fi
raw_fp=$(echo "$SIGN" | sed -n 's/^Signer #1 certificate SHA-256 digest: //p' | head -n 1)
CERT_FP=$(echo "$raw_fp" | tr '[:lower:]' '[:upper:]' | sed 's/../&:/g; s/:$//')
if [ -n "$CERT_FP" ]; then echo "INFO  signing cert SHA-256 $CERT_FP"; else warn "could not read the signing certificate SHA-256"; fi

if [ -n "$ASSETLINKS" ] && [ -n "$CERT_FP" ]; then
  if echo "$ASSETLINKS" | grep -q '^https\?://'; then AL_JSON=$(curl -s --max-time 20 "$ASSETLINKS")
  else AL_JSON=$(cat "$ASSETLINKS" 2>/dev/null); fi
  match=$(printf '%s' "$AL_JSON" | node -e '
    let s = ""; process.stdin.on("data", d => s += d).on("end", () => {
      const [pkg, fp] = process.argv.slice(1);
      const norm = x => String(x).toUpperCase().replace(/[^0-9A-F]/g, "");
      let doc; try { doc = JSON.parse(s); } catch { console.log("badjson"); return; }
      const st = (Array.isArray(doc) ? doc : []).filter(x => x?.target?.package_name === pkg
        && (x.relation || []).includes("delegate_permission/common.handle_all_urls"));
      if (!st.length) { console.log("nopkg"); return; }
      const ok = st.some(x => (x.target.sha256_cert_fingerprints || []).map(norm).includes(norm(fp)));
      console.log(ok ? "ok" : "nofp");
    });' "$pkg" "$CERT_FP" 2>/dev/null)
  case "$match" in
    ok) pass "assetlinks authorizes $pkg with this signing certificate";;
    nopkg) fail "assetlinks has no handle_all_urls statement for $pkg (TWA verification fails)";;
    nofp) fail "assetlinks lists $pkg but not certificate $CERT_FP (re-run bubblewrap fingerprint add)";;
    *) fail "could not read or parse assetlinks from $ASSETLINKS";;
  esac
fi

# Manifest entries written by the Bubblewrap Quest template
if [ -z "$XMLTREE" ]; then
  warn "could not dump AndroidManifest.xml; skipping manifest element checks"
else
  has() { echo "$XMLTREE" | grep -q "\"$1\""; }
  attr_after() { # value of attribute $2 within 4 lines after the element named $1
    echo "$XMLTREE" | grep -A4 "\"$1\"" | grep -m1 ":$2(" | sed -n 's/.*)=\(.*\)$/\1/p' | sed 's/ (Raw.*//; s/"//g'
  }
  if has "horizonos.pwa.APP_MODE"; then
    am=$("$AAPT2" dump resources "$APK" 2>/dev/null | grep -A2 "string/horizonOSAppMode" | sed -n -E 's/.*"(immersive|2D)".*/\1/p' | head -n 1)
    pass "horizonos.pwa.APP_MODE meta-data present (value: ${am:-unparsed})"
    if [ -n "$am" ]; then
      want="immersive"; [ "$MODE" = "2d" ] && want="2D"
      [ "$am" = "$want" ] || fail "horizonOSAppMode is '$am' but --mode is $MODE (2D set to immersive hangs on loading; immersive set to 2D shows a URL bar)"
    fi
  else
    fail "no horizonos.pwa.APP_MODE meta-data: this APK was not built with bubblewrap init --metaquest"
  fi
  if [ "$MODE" = "immersive" ]; then
    has "com.oculus.intent.category.VR" && pass "launch intent has com.oculus.intent.category.VR" || fail "missing com.oculus.intent.category.VR (horizonOSAppMode must be immersive)"
    has "com.oculus.intent.category.2D" && fail "com.oculus.intent.category.2D present in an immersive build"
    has "passthrough-contextual" && pass "com.oculus.ossplash.background=passthrough-contextual (Functional.14 launch splash)"
  else
    has "com.oculus.intent.category.2D" && pass "launch intent has com.oculus.intent.category.2D" || fail "missing com.oculus.intent.category.2D (horizonOSAppMode must be 2D)"
    has "com.oculus.intent.category.VR" && warn "com.oculus.intent.category.VR present in a 2D build (Horizon Billing's PaymentActivity adds it only for immersive)"
  fi
  if has "com.meta.horizon.platform.ovr.OCULUS_APP_ID"; then
    appid=$(attr_after "com.meta.horizon.platform.ovr.OCULUS_APP_ID" value | tr -cd '0-9')
    echo "INFO  OCULUS_APP_ID=${appid:-unparsed} (Horizon App ID; needed for IAP)"
    [ -n "$EXPECT_APP_ID" ] && [ -n "$appid" ] && [ "$appid" != "$EXPECT_APP_ID" ] && fail "OCULUS_APP_ID $appid differs from the expected $EXPECT_APP_ID"
  else
    [ -n "$EXPECT_APP_ID" ] && fail "no OCULUS_APP_ID meta-data; set applicationId in twa-manifest.json (Horizon Billing prompt)" || echo "INFO  no OCULUS_APP_ID meta-data (fine unless the PWA sells add-ons)"
  fi
  if has "android.hardware.vr.headtracking"; then
    req=$(attr_after "android.hardware.vr.headtracking" required)
    case "$req" in
      true|0xffffffff) pass "uses-feature headtracking required=true";;
      *) [ "$MODE" = "immersive" ] && risk "headtracking required=${req:-unset}; publish-mobile-manifest asks immersive apps for required=true (Bubblewrap emits false)" || pass "headtracking required=${req:-unset} (2D apps may use false)";;
    esac
  else
    [ "$MODE" = "immersive" ] && risk "no android.hardware.vr.headtracking uses-feature" || pass "no headtracking feature (2D)"
  fi
  has "com.oculus.supportedDevices" && pass "com.oculus.supportedDevices declared" || risk "no com.oculus.supportedDevices meta-data (not in the Bubblewrap template); set device targeting in the Dashboard and check the build's Test Status"
  # Declared input (essentials/app-compatibility, 2026-10-13): handtracking required=false +
  # HAND_TRACKING = controllers and hands; required=true = hands only; neither = controllers only
  if has "oculus.software.handtracking"; then
    ht=$(attr_after "oculus.software.handtracking" required)
    case "$ht" in
      true|0xffffffff) echo "INFO  declares hands only: every flow must work without controllers";;
      *) echo "INFO  declares controllers and hands (Bubblewrap default): hands-only play must work from launch (Tracking.2; Meta VR Glasses ship without controllers)";;
    esac
  else
    warn "no oculus.software.handtracking declaration: controllers only (Meta VR Glasses ship without controllers)"
  fi
  has "com.meta.store.defaultDeviceTargets" && echo "INFO  com.meta.store.defaultDeviceTargets present (presets Supported Devices; an upload --channel suffix overrides it)"
  echo "INFO  Meta VR Glasses delivery: include Future devices in the build's Supported Devices, or upload with --channel \"alpha:quest3+\""
  echo "$XMLTREE" | grep -q "installLocation" && pass "installLocation declared" || risk "no installLocation (publish-mobile-manifest asks for auto; the Bubblewrap template omits it)"
  launcher_attrs=$(echo "$XMLTREE" | awk '/[".]LauncherActivity"/{f=1; next} f && /E: /{exit} f')
  echo "$launcher_attrs" | grep -q "excludeFromRecents" && pass "launch activity sets excludeFromRecents" || risk "launch activity has no excludeFromRecents=true (publish-mobile-manifest asks for it; the Bubblewrap template omits it)"
fi

# Size (Packaging.5: APK < 1 GB)
bytes=$(wc -c < "$APK" | tr -d ' ')
if [ "$bytes" -lt 1073741824 ]; then pass "APK size $bytes bytes (< 1 GB)"; else fail "APK size $bytes bytes >= 1 GB"; fi

# Permissions (permissions-prohibited 2025-04-30, permissions-review-required 2025-11-26)
PROHIBITED="ACCEPT_HANDOVER ACCESS_BACKGROUND_LOCATION ACCESS_CHECKIN_PROPERTIES ACCESS_LOCATION_EXTRA_COMMANDS
ACCESS_NOTIFICATION_POLICY ACCOUNT_MANAGER ACTIVITY_RECOGNITION ADD_VOICEMAIL ANSWER_PHONE_CALLS
BIND_ACCESSIBILITY_SERVICE BIND_APPWIDGET BIND_AUTOFILL_SERVICE BIND_CALL_REDIRECTION_SERVICE
BIND_CARRIER_MESSAGING_CLIENT_SERVICE BIND_CARRIER_MESSAGING_SERVICE BIND_CARRIER_SERVICES
BIND_CHOOSER_TARGET_SERVICE BIND_CONDITION_PROVIDER_SERVICE BIND_CONTROLS BIND_DEVICE_ADMIN
BIND_DREAM_SERVICE BIND_INCALL_SERVICE BIND_INPUT_METHOD BIND_MIDI_DEVICE_SERVICE BIND_NFC_SERVICE
BIND_NOTIFICATION_LISTENER_SERVICE BIND_PRINT_SERVICE BIND_QUICK_ACCESS_WALLET_SERVICE
BIND_QUICK_SETTINGS_TILE BIND_REMOTEVIEWS BIND_SCREENING_SERVICE BIND_TELECOM_CONNECTION_SERVICE
BIND_TEXT_SERVICE BIND_TV_INPUT BIND_VISUAL_VOICEMAIL_SERVICE BIND_VOICE_INTERACTION
BIND_VR_LISTENER_SERVICE BIND_WALLPAPER BLUETOOTH_PRIVILEGED BODY_SENSORS
BROADCAST_PACKAGE_REMOVED BROADCAST_SMS BROADCAST_WAP_PUSH CALL_PHONE CALL_PRIVILEGED
CAPTURE_AUDIO_OUTPUT CHANGE_COMPONENT_ENABLED_STATE CHANGE_CONFIGURATION CLEAR_APP_CACHE
CONTROL_LOCATION_UPDATES DELETE_CACHE_FILES DELETE_PACKAGES DIAGNOSTIC DUMP FACTORY_TEST
GET_ACCOUNTS GET_ACCOUNTS_PRIVILEGED INSTALL_LOCATION_PROVIDER INSTALL_PACKAGES
INSTANT_APP_FOREGROUND_SERVICE LOADER_USAGE_STATS LOCATION_HARDWARE MANAGE_DOCUMENTS MANAGE_MEDIA
MANAGE_ONGOING_CALLS MASTER_CLEAR MEDIA_CONTENT_CONTROL MODIFY_PHONE_STATE
MOUNT_FORMAT_FILESYSTEMS MOUNT_UNMOUNT_FILESYSTEMS PACKAGE_USAGE_STATS PROCESS_OUTGOING_CALLS
QUERY_ALL_PACKAGES READ_CALENDAR READ_CALL_LOG READ_CONTACTS READ_INPUT_STATE READ_LOGS
READ_PHONE_NUMBERS READ_PHONE_STATE READ_PRECISE_PHONE_STATE READ_SMS READ_VOICEMAIL REBOOT
RECEIVE_MMS RECEIVE_SMS RECEIVE_WAP_PUSH REQUEST_DELETE_PACKAGES REQUEST_INSTALL_PACKAGES
SEND_RESPOND_VIA_MESSAGE SEND_SMS SET_ALWAYS_FINISH SET_ANIMATION_SCALE SET_DEBUG_APP
SET_PROCESS_LIMIT SET_TIME SET_TIME_ZONE SIGNAL_PERSISTENT_PROCESSES SMS_FINANCIAL_TRANSACTIONS
START_FOREGROUND_SERVICES_FROM_BACKGROUND START_VIEW_PERMISSION_USAGE STATUS_BAR
SYSTEM_ALERT_WINDOW UNINSTALL_SHORTCUT UPDATE_DEVICE_STATS USB_CAMERA
USE_ICC_AUTH_WITH_DEVICE_IDENTIFIER USE_SIP UWB_RANGING WRITE_APN_SETTINGS WRITE_CALENDAR
WRITE_CALL_LOG WRITE_CONTACTS WRITE_GSERVICES WRITE_SECURE_SETTINGS WRITE_SETTINGS WRITE_VOICEMAIL"
REVIEW="ACCESS_MEDIA_LOCATION BLUETOOTH_CONNECT BLUETOOTH_SCAN BLUETOOTH_ADVERTISE CAMERA CHANGE_WIFI_STATE
HEADSET_CAMERA MANAGE_EXTERNAL_STORAGE MODIFY_AUDIO_SETTINGS POST_NOTIFICATIONS READ_EXTERNAL_STORAGE
READ_MEDIA_AUDIO READ_MEDIA_IMAGES READ_MEDIA_VIDEO READ_PHONE_STATE RECEIVE_BOOT_COMPLETED RECORD_AUDIO
AVATAR_CAMERA WAKE_LOCK WRITE_EXTERNAL_STORAGE"

perms=$(echo "$BADGING" | sed -n "s/^uses-permission: name='\([^']*\)'.*/\1/p")
echo "permissions declared:"; echo "$perms" | sed 's/^/        /'
bad=0
for p in $perms; do
  short="${p##*.}"
  for x in $PROHIBITED; do
    if [ "$short" = "$x" ] && { [ "$p" = "android.permission.$x" ] || [ "$p" = "$x" ]; }; then
      fail "prohibited permission $p (the upload fails automatically)"; bad=1
    fi
  done
  for x in $REVIEW; do
    if [ "$short" = "$x" ]; then
      case "$x" in
        POST_NOTIFICATIONS) warn "review-required $p: added by enableNotifications in twa-manifest.json; set it to false unless you justify it";;
        RECORD_AUDIO) warn "review-required $p: added by enableMicrophone; justify it (VOIP etc.) or disable it";;
        *) warn "review-required permission $p: needs a justification at submission";;
      esac
    fi
  done
done
[ "$bad" -eq 0 ] && pass "no prohibited permissions"

echo "----"
echo "RISK lines: Meta's generic release-manifest rules that Meta's own Bubblewrap template does not meet."
echo "Whether Store checks exempt PWAs is undocumented: upload to ALPHA and read Manage Builds > Test Status."
if [ "$FAILS" -gt 0 ]; then echo "RESULT: $FAILS FAIL(s), $RISKS RISK(s)"; exit 1; fi
echo "RESULT: no FAILs, $RISKS RISK(s) (review RISK and WARN lines)"; exit 0
