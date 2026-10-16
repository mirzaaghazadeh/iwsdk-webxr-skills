#!/usr/bin/env bash
# install.sh: copy skills (and bundled agents) from this library into a Claude Code project or
# user folder.
# Part of iwsdk-webxr-skills (MIT): https://github.com/mirzaaghazadeh/iwsdk-webxr-skills
#
# Bundles come from .claude-plugin/marketplace.json, so this script and the
# Claude Code plugins always install the same sets.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE="$REPO_DIR/.claude-plugin/marketplace.json"

usage() {
  cat <<'EOF'
Usage: ./install.sh [target] [options] <bundle|skill>...

Targets (pick one):
  --project DIR   install into DIR/.claude/skills (+ DIR/.claude/agents)   (one app; recommended)
  --user          install into ~/.claude/skills (+ ~/.claude/agents)      (every project)
  --dest DIR      install skills into DIR as-is; agents are skipped        (other agents' folders)

Options:
  --link          symlink instead of copy, so `git pull` here updates the skills
  --force         replace skills or agents that already exist in the target
  --dry-run       print what would happen, change nothing
  --uninstall     remove the named bundles/skills from the target
  --list          list bundles, their skills and agents, then exit
  -h, --help      show this help

Bundles: iwsdk-core, iwsdk-official, meta-web-extras, community-web,
         community-design-art, or "all". Any single skill name works too.

Projects made with `npm create @iwsdk` already contain the iwsdk-official skills and agent:
don't install that bundle into them.

Examples:
  ./install.sh --project ~/Games/MyWebXRGame iwsdk-core
  ./install.sh --user iwsdk-core community-design-art
  ./install.sh --project . --link iwsdk-core pmndrs-uikit
  ./install.sh --project ~/Games/MyWebXRGame --uninstall community-web
EOF
}

die() { echo "error: $*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || die "python3 is required to read the bundle list (install Xcode Command Line Tools or Python 3)."
[ -f "$MARKETPLACE" ] || die "can't find $MARKETPLACE. Run this script from a full clone of the repository."

# Prints "<bundle>\t<skill|agent>\t<path relative to repo>" for every bundled skill, plus every
# agent in a bundle's own agents/ folder (how Claude Code loads plugin agents).
bundle_table() {
  python3 -I - "$MARKETPLACE" "$REPO_DIR" <<'PY'
import json, os, sys
marketplace, repo = sys.argv[1], sys.argv[2]
with open(marketplace) as f:
    data = json.load(f)
def rel(p):
    return p[2:] if p.startswith("./") else ("" if p in (".", "./") else p)
for plugin in data["plugins"]:
    base = rel(plugin.get("source", "./")) if isinstance(plugin.get("source"), str) else ""
    for path in plugin.get("skills", []):
        print(plugin["name"] + "\tskill\t" + os.path.normpath(os.path.join(base, rel(path))))
    if base:
        agents = os.path.join(repo, base, "agents")
        if os.path.isdir(agents):
            for name in sorted(os.listdir(agents)):
                if name.endswith(".md"):
                    print(plugin["name"] + "\tagent\t" + os.path.join(base, "agents", name))
PY
}

TARGET="" ; AGENT_TARGET="" ; MODE="copy" ; FORCE=0 ; DRY=0 ; UNINSTALL=0 ; LIST=0
NAMES=()
while [ $# -gt 0 ]; do
  case "$1" in
    --project) [ $# -ge 2 ] || die "--project needs a directory"; TARGET="$2/.claude/skills"; AGENT_TARGET="$2/.claude/agents"; shift 2 ;;
    --user)    TARGET="$HOME/.claude/skills"; AGENT_TARGET="$HOME/.claude/agents"; shift ;;
    --dest)    [ $# -ge 2 ] || die "--dest needs a directory"; TARGET="$2"; AGENT_TARGET=""; shift 2 ;;
    --link)    MODE="link"; shift ;;
    --force)   FORCE=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --list)    LIST=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*)        die "unknown option: $1 (see --help)" ;;
    *)         NAMES+=("$1"); shift ;;
  esac
done

TABLE="$(bundle_table)"

if [ "$LIST" -eq 1 ]; then
  current=""
  while IFS=$'\t' read -r bundle kind path; do
    if [ "$bundle" != "$current" ]; then
      count=$(printf '%s\n' "$TABLE" | awk -F'\t' -v b="$bundle" '$1==b && $2=="skill"' | wc -l | tr -d ' ')
      printf '\n%s (%s skills)\n' "$bundle" "$count"
      current="$bundle"
    fi
    if [ "$kind" = "agent" ]; then
      printf '  %-48s %s\n' "$(basename "$path" .md) (agent)" "$(dirname "$path")"
    else
      printf '  %-48s %s\n' "$(basename "$path")" "$(dirname "$path")"
    fi
  done <<< "$TABLE"
  echo
  exit 0
fi

[ ${#NAMES[@]} -gt 0 ] || { usage; exit 1; }
[ -n "$TARGET" ] || die "choose where to install: --project DIR, --user or --dest DIR (see --help)."

# Resolve bundle and skill names to "kind<TAB>path" rows (deduplicated, order kept).
ROWS=()
add_row() {
  local r="$1" existing
  for existing in ${ROWS[@]+"${ROWS[@]}"}; do [ "$existing" = "$r" ] && return 0; done
  ROWS+=("$r")
}
for name in "${NAMES[@]}"; do
  matched=0
  while IFS=$'\t' read -r bundle kind path; do
    item="$(basename "$path" .md)"
    if [ "$name" = "all" ] || [ "$name" = "$bundle" ] || [ "$name" = "$item" ]; then
      add_row "$kind"$'\t'"$path"; matched=1
    fi
  done <<< "$TABLE"
  [ "$matched" -eq 1 ] || die "no bundle or skill named '$name'. Run ./install.sh --list to see them."
done

[ "$DRY" -eq 1 ] && echo "(dry run: nothing will change)"
[ "$DRY" -eq 1 ] || mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || echo "$TARGET")"

installed=0 ; skipped=0 ; removed=0 ; agents_skipped=0
for row in "${ROWS[@]}"; do
  kind="${row%%$'\t'*}" ; path="${row#*$'\t'}"
  src="$REPO_DIR/$path"
  item="$(basename "$path")"
  case "$item" in ""|.|..|*/*) die "refusing unsafe name '$item'" ;; esac

  if [ "$kind" = "agent" ]; then
    [ -f "$src" ] || die "missing $src"
    if [ -z "$AGENT_TARGET" ]; then
      agents_skipped=$((agents_skipped + 1)); continue
    fi
    dst="$AGENT_TARGET/$item" ; label="$(basename "$item" .md) (agent)"
    [ "$DRY" -eq 1 ] || [ "$UNINSTALL" -eq 1 ] || mkdir -p "$AGENT_TARGET"
  else
    [ -f "$src/SKILL.md" ] || die "missing $src/SKILL.md"
    dst="$TARGET/$item" ; label="$item"
  fi

  if [ "$UNINSTALL" -eq 1 ]; then
    if [ -e "$dst" ] || [ -L "$dst" ]; then
      echo "remove   $label"
      [ "$DRY" -eq 1 ] || rm -rf -- "$dst"
      removed=$((removed + 1))
    fi
    continue
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$FORCE" -ne 1 ]; then
      echo "skip     $label (already there; use --force to replace)"
      skipped=$((skipped + 1))
      continue
    fi
    [ "$DRY" -eq 1 ] || rm -rf -- "$dst"
  fi

  if [ "$MODE" = "link" ]; then
    echo "link     $label -> $path"
    [ "$DRY" -eq 1 ] || ln -s "$src" "$dst"
  else
    echo "copy     $label"
    [ "$DRY" -eq 1 ] || cp -R "$src" "$dst"
  fi
  installed=$((installed + 1))
done

echo
verb_rm="Removed" ; verb_in="Installed"
[ "$DRY" -eq 1 ] && { verb_rm="Would remove" ; verb_in="Would install" ; }
if [ "$UNINSTALL" -eq 1 ]; then
  echo "$verb_rm $removed item(s) from $TARGET"
else
  echo "$verb_in $installed item(s) into $TARGET ($skipped skipped)"
  [ "$agents_skipped" -gt 0 ] && echo "Agents are only installed with --project or --user ($agents_skipped skipped)."
  if [ "$DRY" -ne 1 ] && [ "$installed" -gt 0 ]; then
    cat <<EOF

Next:
  1. Start a new Claude Code session (or run /reload-plugins) so the skills load.
  2. Ask: "Use iwsdk-dev-workflow to plan my WebXR game" and follow the steps it gives.
  3. Don't also install Meta's meta-vr plugin or the same bundles as Claude Code plugins,
     and skip iwsdk-official in projects made with npm create @iwsdk: Claude would see
     duplicate skills.
EOF
  fi
fi
