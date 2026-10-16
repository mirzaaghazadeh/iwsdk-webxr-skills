#!/usr/bin/env bash
# upload-pwa-build.sh: guarded wrapper around `ovr-platform-util upload-quest-build` for a
# Bubblewrap-built PWA/TWA APK.
# Usage: upload-pwa-build.sh <apk> <channel> [--dry-run] [extra ovr-platform-util flags...]
#   channel: alpha | beta | rc | <custom> | store   (store = production; needs CONFIRM_STORE_UPLOAD=yes)
# Env (required): META_APP_ID, META_AGE_GROUP (TEENS_AND_ADULTS | MIXED_AGES | CHILDREN),
#                 and META_UPLOAD_TOKEN or META_APP_SECRET
# Env (optional): RELEASE_NOTES, OVR_PLATFORM_UTIL (path to the binary), UPLOAD_AS_DRAFT=1,
#                 QUEST_DEVICE_TARGETS (e.g. "quest3+"; sent as --channel "<channel>:<targets>")
# Flags per developers.meta.com/vr/resources/publish-reference-platform-command-line-utility/
# (page 2026-07-20) and /vr/resources/publish-release-channels-device-targeting/ (2026-09-04),
# verified 2026-10-17. Without --age-group the upload goes to draft status.
# The tool takes secrets as arguments; mask them in CI logs. --dry-run prints the command masked.
set -euo pipefail

APK="${1:?usage: $0 <apk> <channel> [--dry-run] [extra flags]}"
CHANNEL="${2:?usage: $0 <apk> <channel> [--dry-run] [extra flags]}"
shift 2
DRY=0
if [ "${1:-}" = "--dry-run" ]; then DRY=1; shift; fi

TOOL="${OVR_PLATFORM_UTIL:-ovr-platform-util}"
[ -f "$APK" ] || { echo "APK not found: $APK" >&2; exit 2; }
: "${META_APP_ID:?set META_APP_ID (Dashboard > app > Development > API)}"
: "${META_AGE_GROUP:?set META_AGE_GROUP (TEENS_AND_ADULTS | MIXED_AGES | CHILDREN)}"
case "$META_AGE_GROUP" in TEENS_AND_ADULTS|MIXED_AGES|CHILDREN) ;; *) echo "bad META_AGE_GROUP" >&2; exit 2;; esac

channel_lc=$(echo "$CHANNEL" | tr '[:upper:]' '[:lower:]')
if [ "$channel_lc" = "store" ] || [ "$channel_lc" = "production" ] || [ "$channel_lc" = "live" ]; then
  if [ "${CONFIRM_STORE_UPLOAD:-}" != "yes" ]; then
    echo "Refusing to upload to the production channel without CONFIRM_STORE_UPLOAD=yes" >&2
    exit 3
  fi
  CHANNEL="store"
fi

if [ -n "${QUEST_DEVICE_TARGETS:-}" ]; then
  case "$QUEST_DEVICE_TARGETS" in
    *[!a-z0-9+\|-]*) echo "bad QUEST_DEVICE_TARGETS (use specifiers like quest3+ or quest2only|questproonly)" >&2; exit 2;;
  esac
  CHANNEL="$CHANNEL:$QUEST_DEVICE_TARGETS"
fi

AUTH=(); MASKED=()
if [ -n "${META_UPLOAD_TOKEN:-}" ]; then AUTH=(--token "$META_UPLOAD_TOKEN"); MASKED=(--token '***')
elif [ -n "${META_APP_SECRET:-}" ]; then AUTH=(--app-secret "$META_APP_SECRET"); MASKED=(--app-secret '***')
else echo "set META_UPLOAD_TOKEN or META_APP_SECRET" >&2; exit 2; fi

ARGS=(upload-quest-build --app-id "$META_APP_ID" --apk "$APK" --channel "$CHANNEL"
      --age-group "$META_AGE_GROUP" --disable-progress-bar)
[ -n "${RELEASE_NOTES:-}" ] && ARGS+=(--notes "$RELEASE_NOTES")
[ "${UPLOAD_AS_DRAFT:-}" = "1" ] && ARGS+=(--draft)

if [ "$DRY" -eq 1 ]; then
  echo "DRY RUN: $TOOL ${ARGS[*]} ${MASKED[*]} $*"
  exit 0
fi
command -v "$TOOL" >/dev/null 2>&1 || { echo "ovr-platform-util not found (download: developers.meta.com/vr/downloads/package/platform-utils-cli-osx/ or metavr tools install platform-utils)" >&2; exit 2; }
echo "Uploading $(basename "$APK") to channel '$CHANNEL' for app $META_APP_ID (age group $META_AGE_GROUP)..."
"$TOOL" "${ARGS[@]}" "${AUTH[@]}" "$@"
