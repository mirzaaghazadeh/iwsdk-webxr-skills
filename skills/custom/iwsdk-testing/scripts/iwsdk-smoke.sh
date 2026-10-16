#!/usr/bin/env bash
# iwsdk-smoke.sh: headless smoke test of an IWSDK 1.x app in the IWER emulator (no headset).
# Run from the app root after `npm install`. Needs jq and the project's local @iwsdk/cli.
# Usage: iwsdk-smoke.sh [--entity REGEX] [--component NAME] [--out DIR] [--no-xr]
#                       [--allow-console-errors] [--keep-running] [--timeout MS]
# Exit: 0 all checks passed, 1 a check failed, 2 setup or usage error.
set -euo pipefail

OUT="artifacts/smoke"
ENTITY=""
COMPONENT=""
XR=1
ALLOW_ERRORS=0
KEEP=0
TIMEOUT=180000

while [ $# -gt 0 ]; do
  case "$1" in
    --entity) ENTITY="${2:?--entity needs a regex}"; shift 2 ;;
    --component) COMPONENT="${2:?--component needs a name}"; shift 2 ;;
    --out) OUT="${2:?--out needs a directory}"; shift 2 ;;
    --no-xr) XR=0; shift ;;
    --allow-console-errors) ALLOW_ERRORS=1; shift ;;
    --keep-running) KEEP=1; shift ;;
    --timeout) TIMEOUT="${2:?--timeout needs milliseconds}"; shift 2 ;;
    -h | --help) sed -n '2,6p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

# Use the project's own CLI so nothing is fetched from npm.
IWSDK="${IWSDK_CLI:-./node_modules/.bin/iwsdk}"
command -v jq >/dev/null || { echo "jq is required" >&2; exit 2; }
[ -f iwsdk.config.json ] || { echo "run from the IWSDK app root (no iwsdk.config.json here)" >&2; exit 2; }
[ -x "$IWSDK" ] || { echo "no local @iwsdk/cli at $IWSDK; run npm install first" >&2; exit 2; }
mkdir -p "$OUT"

FAILS=0
pass() { echo "PASS $*"; }
fail() { echo "FAIL $*"; FAILS=$((FAILS + 1)); }
# The CLI prints {"ok":true,"data":...} on stdout and exits 0, or {"ok":false,"error":...} on stderr and exits 1.
cli() { "$IWSDK" "$@" 2>>"$OUT/errors.log"; }

# shellcheck disable=SC2329  # invoked by the EXIT trap
cleanup() {
  if [ "$KEEP" = 0 ]; then
    if [ "$XR" = 1 ]; then "$IWSDK" xr exit --input-json '{}' >/dev/null 2>&1 || true; fi
    "$IWSDK" dev down >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

: >"$OUT/errors.log"
echo "Starting a headless managed runtime (agent mode)..."
if ! cli dev up --ai-mode agent --timeout "$TIMEOUT" >"$OUT/dev-up.json"; then
  echo "dev up failed; see $OUT/errors.log and '$IWSDK dev logs --tail 100'" >&2
  exit 2
fi

# A browser screenshot switches the managed workspace to the runtime view and proves a frame rendered.
shot=0
for _ in $(seq 1 45); do
  if cli browser screenshot --output-file "$OUT/01-first-frame.png" >"$OUT/01-first-frame.json"; then
    shot=1
    break
  fi
  sleep 2
done
if [ "$shot" = 1 ]; then pass "first frame rendered ($OUT/01-first-frame.png)"; else fail "no screenshot after 90 s"; fi

ready=0
for _ in $(seq 1 30); do
  if cli dev status >"$OUT/status.json" && jq -e '.data.state.browserCommandReady == true' "$OUT/status.json" >/dev/null; then
    ready=1
    break
  fi
  sleep 2
done
if [ "$ready" = 1 ]; then
  pass "browser command path ready at $(jq -r '.data.runtimeUrls.local // "?"' "$OUT/status.json")"
else
  fail "browserCommandReady never became true (see $OUT/status.json)"
  exit 1
fi

cli browser logs --input-json '{"count":200}' >"$OUT/console.json" || true
errors=$(jq '[.. | objects | select(.level? == "error")] | length' "$OUT/console.json" 2>/dev/null || echo "?")
if [ "$errors" = "0" ]; then
  pass "no console errors"
elif [ "$ALLOW_ERRORS" = 1 ]; then
  echo "WARN $errors console error(s), allowed by --allow-console-errors (see $OUT/console.json)"
else
  fail "$errors console error(s) (see $OUT/console.json)"
fi

if [ -n "$ENTITY" ]; then
  find_input=$(jq -nc --arg p "$ENTITY" '{namePattern: $p, limit: 10}')
  if cli ecs find --input-json "$find_input" >"$OUT/entity.json" &&
    jq -e '(.data.result.entities | length) > 0' "$OUT/entity.json" >/dev/null; then
    pass "entity matching /$ENTITY/ exists (index $(jq -r '.data.result.entities[0].entityIndex' "$OUT/entity.json"))"
    if [ -n "$COMPONENT" ]; then
      if jq -e --arg c "$COMPONENT" '.data.result.entities[0].componentIds | any(.[]; contains($c))' "$OUT/entity.json" >/dev/null; then
        pass "entity has component $COMPONENT"
      else
        fail "entity lacks component $COMPONENT (has: $(jq -c '.data.result.entities[0].componentIds' "$OUT/entity.json"))"
      fi
    fi
  else
    fail "no entity matching /$ENTITY/ (see $OUT/entity.json)"
  fi
fi

# Systems keep running: pause, step 30 frames, and record what changed.
if cli ecs pause --input-json '{}' >/dev/null &&
  cli ecs snapshot --input-json '{"label":"smoke-before"}' >/dev/null &&
  cli ecs step --input-json '{"count":30,"delta":0.016}' >/dev/null &&
  cli ecs snapshot --input-json '{"label":"smoke-after"}' >/dev/null &&
  cli ecs diff --input-json '{"from":"smoke-before","to":"smoke-after"}' >"$OUT/ecs-diff.json"; then
  pass "ECS pause/step/diff works (summary $(jq -c '.data.result.summary' "$OUT/ecs-diff.json"))"
else
  fail "ECS pause/step/diff failed (see $OUT/errors.log)"
fi
cli ecs resume --input-json '{}' >/dev/null || true

if [ "$XR" = 1 ]; then
  if cli xr enter --input-json '{}' >"$OUT/xr-enter.json" &&
    cli xr status >"$OUT/xr-status.json" &&
    jq -e '.data.result.sessionActive == true' "$OUT/xr-status.json" >/dev/null; then
    pass "emulated XR session active ($(jq -r '.data.result.sessionMode // "?"' "$OUT/xr-status.json"))"
    cli browser screenshot --output-file "$OUT/02-in-xr.png" >/dev/null && pass "XR frame captured ($OUT/02-in-xr.png)"
  else
    fail "could not enter XR; world.xr.offer must be \"once\" or \"always\" (see $OUT/errors.log)"
  fi
fi

echo
if [ "$FAILS" = 0 ]; then
  echo "SMOKE PASSED. Artifacts in $OUT"
  exit 0
fi
echo "SMOKE FAILED: $FAILS check(s). Artifacts in $OUT"
exit 1
