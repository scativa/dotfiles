#!/usr/bin/env bash
# status.sh — drift between THIS machine's dotfiles and what's committed in the repo.
# Usage: status.sh
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

if [ ! -d "$HOSTDIR" ]; then
  echo "No versioned config for host '$HOST'. Try scripts/lift.sh first."
  exit 1
fi

echo "Drift for '$HOST' (local \$HOME vs repo):"
printf "  %-30s %s\n" "FILE" "STATE"
printf -- "  ------------------------------------------------------------------\n"

while IFS=$'\t' read -r id repo home; do
  [ -n "$home" ] && [ "$home" != "-" ] || continue
  local_file="$(resolve_home "$home")"
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