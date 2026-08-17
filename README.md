# dotfiles

My dev-stack dotfiles, versioned per machine, across macOS / Windows / Linux (WSL).

One private repo, a config folder per machine. Everything (what to track, how to
detect each tool, how to install it) lives in `manifest.toml` — the scripts are
thin, generic readers of that file.

## Structure

```
manifest.toml          single source of truth (hosts, tools, tracked files)
hosts/<machine>/       one folder per machine, mirroring $HOME layout
secrets/               git-ignored; lift never touches it
scripts/manifest.py    zero-dependency TOML reader (works on Python 3.9+)
scripts/inventory.*    what is installed on this machine? (per manifest)
scripts/lift.*         copy local config → hosts/<machine>/
scripts/status.*       drift between local dotfiles and the repo
scripts/install.*      link/copy repo config → this machine (+ --tools)
scripts/sync.*         lift → conventional commit → push
```

`.sh` runs everywhere (macOS, Linux/WSL, Windows via Git Bash). `.ps1` shims
delegate to `.sh` through Git Bash so Windows users can call them from
PowerShell 7.

## Setup on a new machine

```bash
git clone git@github.com:scativa/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/install.sh --dry-run   # preview
./scripts/install.sh             # real: symlinks (copy on Windows)
./scripts/install.sh --tools     # also offer to install missing stack tools
```

Backups are created for any real file that a link is about to replace
(`<file>.bak.<timestamp>`).

## Daily flow (push changes made on a machine)

```bash
./scripts/lift.sh   # copy current $HOME config → hosts/<machine>/
./scripts/status.sh # optional: show drift before pushing
./scripts/sync.sh   # lift + commit "dots: sync <host>" + push
```

## What's installed where (inventory)

```bash
./scripts/inventory.sh          # table: TOOL | STATUS | VERSION
./scripts/inventory.ps1         # same, from PowerShell
./scripts/install.sh --tools --dry-run   # what a fresh box is missing
```

## Adding a tool or a file

Edit `manifest.toml` and commit — nothing else changes:

- `[[tools]]`: detection (`bin` or `check`), optional `version_cmd`, optional
  `install.<os>` command (`brew` / `winget` / `apt`).
- `[[files]]`: `repo` (path under `hosts/<machine>/`) + `home` (path relative
  to `$HOME`). Add `os = ["windows"]` for machine-specific files like the
  PowerShell profiles.
- `[hosts.<id>]`: map hostnames (`fnmatch`, `*` allowed) to a machine folder.

## Secrets

`.gitignore` hard-blocks `secrets/`, `.ssh/`, `.aws/`, `.env*`, keys and certs.
`lift` only ever copies files listed in the manifest; never store credentials
in tracked files. Symlinked configs are visible to the source machine — check
before pushing anything on a box you don't trust.

## Windows notes

- Requires Git for Windows (bash) and a Python 3.x on PATH — Miniconda covers
  the latter on your stack.
- Symlinks generally need an elevated prompt: `install` falls back to copying.
- PowerShell profiles (`$PROFILE`) are tracked under
  `hosts/<machine>/PowerShell/...` per manifest.

## Roadmap

- [ ] Host secrets encryption (age/gpg) for keys that must roan between boxes
- [ ] Auto mapping for OneDrive-redirected `Documents` on Windows
- [ ] `wezterm` GUI config + resurrect.wezterm plugin preset