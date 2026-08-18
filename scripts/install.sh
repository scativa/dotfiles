#!/usr/bin/env bash
# install.sh — pulls the versioned config OF A HOST down to this machine.
#   - macos/linux: symlink $HOME/<path> -> hosts/<host>/<repo>
#   - windows:     copy (git-bash symlinks usually need admin)
# Options:
#   --dry-run      show what would happen without touching anything
#   --tools        also offer to install manifest tools that are missing
#   -y             answer yes to everything (non-interactive)
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

DRY=0
TOOLS=0
YES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --tools) TOOLS=1 ;;
    -y) YES=1 ;;
    *) echo "Usage: install.sh [--dry-run] [--tools] [-y]" && exit 1 ;;
  esac
  shift
done

OS="$("$PY" "$SCRIPT_DIR/manifest.py" os)"
HOST="$("$PY" "$SCRIPT_DIR/manifest.py" host)"
HOSTDIR="$DOTFILES/hosts/$HOST"

[ "$DRY" -eq 0 ] && mkdir -p "$HOSTDIR"
echo "# install: $OS / $HOST"
echo "# mode:    $([ "$DRY" -eq 1 ] && echo 'DRY-RUN (only shows what would be done)' || echo 'applying')"
echo

# --- 1) link/copy files -----------------------------------------------------
linked=0
while IFS=$'\t' read -r id repo home; do
  [ -n "$home" ] && [ "$home" != "-" ] || continue
  repo_file="$HOSTDIR/$repo"
  target="$(resolve_home "$home")"
  if [ ! -e "$repo_file" ]; then
    printf "  skip    %-30s (not versioned in %s)\n" "$id" "$HOSTDIR/$repo"
    continue
  fi

  if [ "$DRY" -eq 1 ]; then
    if [ "$OS" = "windows" ]; then
      printf "  COPY    %-30s -> %s\n" "$id" "$target"
    else
      printf "  SYMLINK %-30s -> %s\n" "$id" "$target"
    fi
    linked=$((linked + 1))
    continue
  fi

  mkdir -p "$(dirname "$target")"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    cp -f "$target" "$backup"
    printf "  backup  %-30s -> %s\n" "$id" "$backup"
  fi

  if [ "$OS" = "windows" ]; then
    cp -f "$repo_file" "$target"
  else
    ln -sfn "$repo_file" "$target"
  fi
  printf "  link    %-30s <- %s\n" "$id" "$repo"
  linked=$((linked + 1))
done < <("$PY" "$SCRIPT_DIR/manifest.py" files)

echo
echo "Files processed: $linked"

# --- 2) (optional) install missing tools ------------------------------------
if [ "$TOOLS" -eq 1 ]; then
  echo
  echo "# Missing tools and how to install them:"
  missing=0
  while IFS=$'\t' read -r id cmd; do
    present=0
    while IFS=$'\t' read -r t_id _t_name t_bin _t_vcmd t_check; do
      [ "$t_id" = "$id" ] || continue
      if [ -n "$t_bin" ] && [ "$t_bin" != "-" ]; then
        command -v "$t_bin" >/dev/null 2>&1 && present=1
      elif [ -n "$t_check" ] && [ "$t_check" != "-" ]; then
        bash -c "$t_check" >/dev/null 2>&1 && present=1 || true
      fi
    done < <("$PY" "$SCRIPT_DIR/manifest.py" tools)

    if [ "$present" -eq 1 ]; then
      continue
    fi
    missing=$((missing + 1))
    printf "  [%s]  %s\n" "$id" "$cmd"
    if [ "$DRY" -eq 1 ]; then
      continue
    fi
    if [ "$YES" -eq 0 ]; then
      read -r -p "    Install? (y/N) " ans || true
      [ "$ans" = "y" ] || [ "$ans" = "Y" ] || continue
    fi
    echo "    → running…"
    bash -c "$cmd" || echo "    ✗ failed (fix manually)"
  done < <("$PY" "$SCRIPT_DIR/manifest.py" tool-installs)
  [ "$missing" -eq 0 ] && echo "  (nothing missing — the full stack is present)"
fi

echo
if [ "$DRY" -eq 1 ]; then
  echo "DRY-RUN: nothing was modified. Remove --dry-run to apply."
else
  echo "Done. Future edits go up with scripts/lift.sh + sync.sh."
fi