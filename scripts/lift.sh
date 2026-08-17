#!/usr/bin/env bash
# lift.sh — copies the CURRENT config of this machine into hosts/<host>/ in the repo.
# Use it to push changes you made by hand in $HOME.
# Usage: lift.sh        (copies + shows status; committing is done by sync.sh)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
PY="$(command -v python3 || command -v python || true)"
[ -n "$PY" ] || { echo "ERROR: python3 required" >&2; exit 1; }

HOST="$("$PY" "$SCRIPT_DIR/manifest.py" host)"
HOSTDIR="$DOTFILES/hosts/$HOST"
mkdir -p "$HOSTDIR"

lifted=0
skipped=0
while IFS=$'\t' read -r id repo home; do
  [ -n "$home" ] && [ "$home" != "-" ] || continue
  src="$HOME/$home"
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