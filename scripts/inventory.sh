#!/usr/bin/env bash
# inventory.sh — "what do I have installed?"
# Reports, for the current OS: each manifest tool, whether present, and version.
# Table: TOOL | STATUS | VERSION.
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

OS="$("$PY" "$SCRIPT_DIR/manifest.py" os)"
HOST="$("$PY" "$SCRIPT_DIR/manifest.py" host)"

echo "dotfiles:  $DOTFILES"
echo "OS:        $OS"
echo "host:      $HOST"
echo "shell:     ${SHELL:-n/a}"
if git -C "$DOTFILES" rev-parse --git-dir >/dev/null 2>&1; then
  echo "last fix:  $(git -C "$DOTFILES" log -1 --format='%h %s' 2>/dev/null || echo 'no commits yet')"
fi
echo
printf "%-30s %-10s %s\n" "TOOL" "STATUS" "VERSION"
printf -- "--------------------------------------------------------------------------\n"

while IFS=$'\t' read -r id name bin vcmd check; do
  present=0
  if [ -n "$bin" ] && [ "$bin" != "-" ]; then
    command -v "$bin" >/dev/null 2>&1 && present=1
  elif [ -n "$check" ] && [ "$check" != "-" ]; then
    bash -c "$check" >/dev/null 2>&1 && present=1 || true
  fi
  if [ "$present" -eq 1 ]; then
    ver="-"
    if [ -n "$vcmd" ] && [ "$vcmd" != "-" ]; then
      ver="$(bash -c "$vcmd" 2>/dev/null | head -n1 || true)"
    fi
    printf "%-30s %-10s %s\n" "$name" "OK" "$ver"
  else
    printf "%-30s %-10s %s\n" "$name" "NO" "-"
  fi
done < <("$PY" "$SCRIPT_DIR/manifest.py" tools | sort -k2)

printf -- "--------------------------------------------------------------------------\n"
echo "To install what's missing: scripts/install.sh --tools (review before running)"