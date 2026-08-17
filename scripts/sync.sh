#!/usr/bin/env bash
# sync.sh — daily flow: lift → review → conventional commit → push.
# Usage: sync.sh [-y]     (-y: commit without asking; push still runs)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
PY="$(command -v python3 || command -v python || true)"
[ -n "$PY" ] || { echo "ERROR: python3 required" >&2; exit 1; }

YES=0
[ "${1:-}" = "-y" ] && YES=1
HOST="$("$PY" "$SCRIPT_DIR/manifest.py" host)"

"$SCRIPT_DIR/lift.sh"

if git -C "$DOTFILES" diff --quiet -- "hosts/$HOST/" && git -C "$DOTFILES" diff --cached --quiet -- "hosts/$HOST/"; then
  echo
  echo "SYNC: nothing changed for '$HOST' — nothing to commit."
  exit 0
fi

echo
git -C "$DOTFILES" add "hosts/$HOST/"
echo "Staged:"
git -C "$DOTFILES" status --short -- "hosts/$HOST/"

if [ "$YES" -eq 0 ]; then
  read -r -p "Commit and push? (y/N) " ans || true
  [ "$ans" = "y" ] || [ "$ans" = "Y" ] || { echo "Aborted. Changes left staged (git status)."; exit 1; }
fi

git -C "$DOTFILES" commit -q -m "dots: sync $HOST"
echo "Commit: $(git -C "$DOTFILES" log -1 --format='%h %s')"

if git -C "$DOTFILES" remote >/dev/null 2>&1 && git -C "$DOTFILES" rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  git -C "$DOTFILES" push -q
  echo "Pushed."
else
  echo "No remote/upstream configured — not pushing. Set it up, then:"
  echo "  git -C $DOTFILES push -u origin HEAD"
fi