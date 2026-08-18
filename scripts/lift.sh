#!/usr/bin/env bash
# lift.sh — copies the CURRENT config of this machine into hosts/<host>/ in the repo.
# Use it to push changes you made by hand in $HOME.
# Usage: lift.sh        (copies + shows status; committing is done by sync.sh)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
# Prefer a real, runnable interpreter: on Windows, "python3" may be a
# Microsoft Store alias stub that prints an error and exits non-zero.
PY=""
for _c in python python3; do
  _py="$(command -v "$_c" 2>/dev/null || true)"
  [ -n "$_py" ] && "$_py" -V >/dev/null 2>&1 && PY="$_py" && break
done
[ -n "$PY" ] || { echo "ERROR: python3 required" >&2; exit 1; }

# Resolve a manifest "home" to a local path. Absolute paths (Windows
# redirected folders like E:\...) are used as-is; relative paths join $HOME.
resolve_home() {
  case "$1" in
    /*|[A-Za-z]:*|\\*) printf '%s' "$1" ;;
    *) printf '%s/%s' "$HOME" "$1" ;;
  esac
}

HOST="$("$PY" "$SCRIPT_DIR/manifest.py" host)"
HOSTDIR="$DOTFILES/hosts/$HOST"
mkdir -p "$HOSTDIR"

lifted=0
skipped=0
while IFS=$'\t' read -r id repo home; do
  [ -n "$home" ] && [ "$home" != "-" ] || continue
  src="$(resolve_home "$home")"
  dst="$HOSTDIR/$repo"
  if [ -e "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
    printf "  lifted  %s -> %s\n" "$home" "$repo"
    lifted=$((lifted + 1))
  else
    printf "  skip    %s (missing on this machine)\n" "$home"
    skipped=$((skipped + 1))
  fi
done < <("$PY" "$SCRIPT_DIR/manifest.py" files)

echo
echo "Lifted: $lifted | Skipped: $skipped (host: $HOST)"
if [ "$lifted" -gt 0 ]; then
  echo
  echo "Pending changes:"
  git -C "$DOTFILES" status --short -- "hosts/$HOST/"
  echo
  echo "Next: review and push with scripts/sync.sh"
fi