#!/usr/bin/env bash
# check-store-assets.sh: validate Meta Horizon Store listing art against the Store Art Guidelines
# (developers.meta.com/horizon/resources/asset-guidelines/, updated 2026-05-11; verified 2026-10-16).
# Usage: check-store-assets.sh <assets-dir>
# Expected names: cover_landscape.png cover_square.png cover_portrait.png hero.png logo.png icon.png
#                 mini_landscape.png tile_background.png tile_foreground.png screenshot_*.png
#                 trailer.mp4 trailer_cover.png
# Tools: sips (macOS) or ImageMagick `identify`; ffprobe for the trailer (optional).
# It checks pixel sizes, alpha, counts, and trailer basics only. Content rules (branding, no extra
# text, safe areas, exact title) still need a human or agent visual review.
# Copied from unity-meta-quest-skills (horizon-store-listing-assets) and changed for this library:
# adds Mini Landscape 1080x360 (in the page's spec table) and reports alpha on 24-bit assets as
# WARN, because the page says the alpha layer of a 32-bit upload "is ignored unless it's for the Logo".
set -u
DIR="${1:-}"
[ -d "$DIR" ] || { echo "usage: $0 <assets-dir>" >&2; exit 2; }

FAILS=0
pass() { echo "PASS  $*"; }
warn() { echo "WARN  $*"; }
fail() { echo "FAIL  $*"; FAILS=$((FAILS + 1)); }

# prints "W H ALPHA" where ALPHA is yes|no
img_info() {
  local f="$1"
  if command -v sips >/dev/null 2>&1; then
    local w h a
    w=$(sips -g pixelWidth "$f" 2>/dev/null | awk '/pixelWidth/{print $2}')
    h=$(sips -g pixelHeight "$f" 2>/dev/null | awk '/pixelHeight/{print $2}')
    a=$(sips -g hasAlpha "$f" 2>/dev/null | awk '/hasAlpha/{print $2}')
    echo "$w $h ${a:-no}"
  elif command -v identify >/dev/null 2>&1; then
    identify -format '%w %h %A\n' "$f" 2>/dev/null | head -n 1 | \
      awk '{a=tolower($3); print $1, $2, ((a=="true"||a=="blend")?"yes":"no")}'
  else
    echo "tool-missing"
  fi
}

check_png() { # file expectedW expectedH alphaRule(none|required|any) label
  local f="$DIR/$1" ew="$2" eh="$3" rule="$4" label="$5"
  if [ ! -f "$f" ]; then fail "$label: missing $1"; return; fi
  case "$1" in *.png|*.PNG) ;; *) fail "$label: must be PNG";; esac
  local info w h a
  info=$(img_info "$f")
  [ "$info" = "tool-missing" ] && { echo "need sips or ImageMagick" >&2; exit 2; }
  read -r w h a <<EOF
$info
EOF
  if [ "$ew" = "max" ]; then
    if [ "$w" -le 9000 ] && [ "$h" -le 1440 ]; then pass "$label ${w}x${h} (max 9000x1440)"; else fail "$label ${w}x${h} exceeds 9000x1440"; fi
  elif [ "$w" = "$ew" ] && [ "$h" = "$eh" ]; then
    pass "$label ${w}x${h}"
  else
    fail "$label is ${w}x${h}, expected ${ew}x${eh}"
  fi
  case "$rule" in
    none)     [ "$a" = "yes" ] && warn "$label has an alpha channel; Meta asks for a 24-bit PNG and ignores the alpha layer, so transparent areas won't show as intended" ;;
    required) [ "$a" = "yes" ] && pass "$label has transparency" || fail "$label needs a transparent background (32-bit PNG)" ;;
    *) ;;
  esac
}

echo "Checking $DIR"
check_png cover_landscape.png 2560 1440 none     "Cover Landscape"
check_png cover_square.png    1440 1440 none     "Cover Square"
check_png cover_portrait.png  1008 1440 none     "Cover Portrait"
check_png hero.png            3000 900  none     "Hero Cover"
check_png icon.png            512  512  none     "Icon"
if [ -f "$DIR/mini_landscape.png" ]; then check_png mini_landscape.png 1080 360 none "Mini Landscape"; else warn "Mini Landscape 1080x360 not provided (listed in the spec table; check whether your Dashboard form asks for it)"; fi
if [ -f "$DIR/logo.png" ]; then check_png logo.png max max required "Logo"; else warn "Logo (optional) not provided"; fi
if [ -f "$DIR/tile_background.png" ] || [ -f "$DIR/tile_foreground.png" ]; then
  check_png tile_background.png 180 180 any      "Spatialized tile background"
  check_png tile_foreground.png 180 180 required "Spatialized tile foreground"
else
  warn "Spatialized tile not provided (check whether your Dashboard form requires it)"
fi
if [ -f "$DIR/trailer_cover.png" ]; then check_png trailer_cover.png 2560 1440 none "Trailer cover"; fi

# Screenshots: 5, 2560x1440, no duplicates
count=0
for s in "$DIR"/screenshot_*.png; do
  [ -f "$s" ] || continue
  count=$((count + 1))
  check_png "$(basename "$s")" 2560 1440 none "Screenshot $(basename "$s")"
done
if [ "$count" -eq 5 ]; then pass "5 screenshots"; else fail "$count screenshots found; guidelines specify 5"; fi
if [ "$count" -gt 1 ]; then
  dups=$(for s in "$DIR"/screenshot_*.png; do shasum "$s" | awk '{print $1}'; done | sort | uniq -d | wc -l | tr -d ' ')
  [ "$dups" -eq 0 ] && pass "no duplicate screenshots" || fail "duplicate screenshots detected"
fi

# Trailer: MP4/H.264/AAC, 16:9, >=1080p, <= "2K", 30-120 s (Asset.7: <= 2 min)
if [ -f "$DIR/trailer.mp4" ]; then
  if command -v ffprobe >/dev/null 2>&1; then
    v=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height -of csv=p=0 "$DIR/trailer.mp4")
    a=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$DIR/trailer.mp4")
    d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$DIR/trailer.mp4" | cut -d. -f1)
    vc=$(echo "$v" | cut -d, -f1); vw=$(echo "$v" | cut -d, -f2); vh=$(echo "$v" | cut -d, -f3)
    [ "$vc" = "h264" ] && pass "trailer video codec h264" || fail "trailer video codec '$vc' (need H.264)"
    [ "$a" = "aac" ] && pass "trailer audio aac" || fail "trailer audio codec '${a:-none}' (need AAC)"
    if [ -n "$vh" ] && [ "$vh" -ge 1080 ]; then pass "trailer height ${vh}px (>=1080)"; else fail "trailer ${vw}x${vh} below 1080p"; fi
    [ -n "$vw" ] && [ "$vw" -gt 2560 ] && warn "trailer width ${vw}px is above 2560; guidelines say 2K maximum"
    if [ -n "$vw" ] && [ -n "$vh" ] && [ $((vw * 9)) -ne $((vh * 16)) ]; then fail "trailer ${vw}x${vh} is not 16:9"; fi
    if [ -n "$d" ] && [ "$d" -ge 30 ] && [ "$d" -le 120 ]; then pass "trailer ${d}s (30-120 s)"; else fail "trailer duration ${d:-?}s outside 30-120 s"; fi
  else
    warn "ffprobe not found; trailer not checked"
  fi
else
  warn "trailer.mp4 not provided (optional, but recommended)"
fi

echo "----"
echo "Manual review still required: exact app title on branded art (not the icon), safe-area placement"
echo "(templates: https://metaque.st/storetemplates), no taglines or banners on cover art (Asset.2),"
echo "no text in top/bottom 20% (Asset.3), screenshots without added text or logos (Asset.5),"
echo "no other VR platforms' hardware (Asset.6), art text >= 24 pt (Asset.8)."
[ "$FAILS" -gt 0 ] && { echo "RESULT: $FAILS FAIL(s)"; exit 1; }
echo "RESULT: no FAILs"; exit 0
