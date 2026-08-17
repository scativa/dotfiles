#!/usr/bin/env bash
# status.sh — drift between THIS machine's dotfiles and what's committed in the repo.
# Usage: status.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"
PY="$(command -v python3 || command -v python || true)"
[ -n "$PY" ] || { echo "ERROR: python3 required" >&2; exit 1; }

HOST="$("$PY" "$SCRIPT_DIR/manifest.py" host)"
HOSTDIR="$DOTFILES/hosts/$HOST"

if [ ! -d "$HOSTDIR" ]; then
  echo "No versioned config for host '$HOST'. Try scripts/lift.sh first."
  exit 1
fi

echo "Drift for '$HOST' (local \$HOME vs repo):"
printf "  %-30s %s\n" "FILE" "STATE"
printf -- "  ------------------------------------------------------------------\n"

while IFS=$'\t' read -r id repo home; do
  [ -n "$home" ] && [ "$home" != "-" ] || continue
  local_file="$HOME/$home"
  repo_file="$HOSTDIR/$repo"
  if [ ! -e "$repo_file" ]; then
    state="repo missing"
  elif [ ! -e "$local_file" ]; then
    state="repo only"
  elif cmp -s "$local_file" "$repo_file"; then
    state="up to date"
  else
    state="CHANGED"
  fi
  printf "  %-30s %s\n" "$home" "$state"
done < <("$PY" "$SCRIPT_DIR/manifest.py" files | sort -k2)

echo
echo "Repo working tree:"
git -C "$DOTFILES" status --short || true