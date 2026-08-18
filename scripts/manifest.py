#!/usr/bin/env python3
"""Manifest reader for the dotfiles repo — zero dependencies.

Parses manifest.toml with a minimal embedded TOML parser (works on Python 3.9,
no tomllib) and exposes TSV-views for the bash scripts.

Usage:
    manifest.py os                      -> macos | linux | windows
    manifest.py host                    -> resolved host id (or DOTFILES_HOST)
    manifest.py host-dir                -> hosts/<host id>
    manifest.py files [--os <os>]       -> id<TAB>repo<TAB>home1  (entries for OS)
    manifest.py tools [--os <os>]       -> id<TAB>name<TAB>bin<TAB>version_cmd<TAB>check
    manifest.py tool-installs [--os]    -> id<TAB>cmd       (install commands for OS)
"""
import fnmatch
import os
import platform
import re
import socket
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = os.path.join(os.path.dirname(HERE), "manifest.toml")

SUPPORTED_OS = {"Darwin": "macos", "Linux": "linux", "Windows": "windows"}


def unescape_basic(s):
    """Unescape a TOML basic-string interior (handles \\\", \\\\, \\n, \\t)."""
    out, i = [], 0
    while i < len(s):
        c = s[i]
        if c == "\\" and i + 1 < len(s):
            nxt = s[i + 1]
            if nxt == '"':
                out.append('"')
            elif nxt == "\\":
                out.append("\\")
            elif nxt == "n":
                out.append("\n")
            elif nxt == "t":
                out.append("\t")
            else:
                out.append(c + nxt)
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def parse_value(s):
    s = s.strip()
    if s.startswith("#"):
        s = s.split("#", 1)[0].strip()
    if s.startswith("["):  # array
        return [parse_value(x) for x in split_top(s[1:].rstrip("]"))]
    if s.startswith("{"):  # inline table
        d = {}
        for part in split_top(s[1:].rstrip("}")):
            if "=" not in part:
                continue
            k, v = part.split("=", 1)
            d[k.strip().strip('"').strip("'")] = parse_value(v)
        return d
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        return unescape_basic(s[1:-1])
    if len(s) >= 2 and s[0] == "'" and s[-1] == "'":
        return s[1:-1]
    if re.fullmatch(r"true|false", s):
        return s == "true"
    if re.fullmatch(r"-?\d+", s):
        return int(s)
    return s  # bare word


def split_top(s, sep=","):
    parts, cur, depth, quote = [], "", 0, None
    i = 0
    while i < len(s):
        c = s[i]
        if quote:
            if c == "\\" and i + 1 < len(s):  # escaped char stays inside quote
                cur += c + s[i + 1]
                i += 2
                continue
            cur += c
            if c == quote:
                quote = None
        elif c in ('"', "'"):
            quote, cur = c, cur + c
        elif c in "[{":
            depth, cur = depth + 1, cur + c
        elif c in "]}":
            depth, cur = depth - 1, cur + c
        elif c == sep and depth == 0:
            parts.append(cur)
            cur = ""
        else:
            cur += c
        i += 1
    if cur.strip():
        parts.append(cur)
    return parts


def parse_toml(text):
    root, cur = {}, {}
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[["):
            path = re.match(r"\[\[([^\]]+)\]\]", line).group(1).split(".")
            parent = root
            for p in path[:-1]:
                parent = parent.setdefault(p, {})
            parent.setdefault(path[-1], []).append({})
            cur = parent[path[-1]][-1]
            continue
        if line.startswith("["):
            path = re.match(r"\[([^\]]+)\]", line).group(1).split(".")
            cur = root
            for p in path:
                cur = cur.setdefault(p, {})
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        cur[key.strip().strip('"').strip("'")] = parse_value(value)
    return root


def load():
    with open(MANIFEST, encoding="utf-8") as fh:
        return parse_toml(fh.read())


def current_os():
    return SUPPORTED_OS.get(platform.system(), platform.system())


def resolve_host(data):
    override = os.environ.get("DOTFILES_HOST")
    if override:
        return override
    node = socket.gethostname().rstrip(".")
    candidates = [node]
    short = node.split(".")[0] if "." in node else node
    if short and short != node:
        candidates.append(short)
    for host_name, cfg in data.get("hosts", {}).items():
        for pattern in cfg.get("match", []):
            for cand in candidates:
                if fnmatch.fnmatch(cand, pattern) or fnmatch.fnmatch(cand.lower(), pattern.lower()):
                    return host_name
    return re.sub(r"[^A-Za-z0-9._-]", "-", candidates[-1])


def os_matches(entry, osname):
    return "os" not in entry or osname in entry["os"]


def first_home(entry, osname):
    home = entry.get("home")
    if isinstance(home, dict):
        home = home.get(osname, [])
    if not home:
        return ""
    return home[0]


def main():
    # Windows pipes translate "\n" to "\r\n"; bash "read" would keep the "\r"
    # and break every path. Emit pure "\n" so TSV parsing works on all OSes.
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(newline="\n")
    data = load()
    if not data:
        sys.exit("manifest.toml vacío o inválido")
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    osname = current_os()
    if "--os" in sys.argv:
        i = sys.argv.index("--os")
        if i + 1 < len(sys.argv):
            osname = sys.argv[i + 1]

    if cmd == "os":
        print(osname)
    elif cmd == "host":
        print(resolve_host(data))
    elif cmd == "host-dir":
        print(os.path.join("hosts", resolve_host(data)))
    elif cmd == "files":
        for f in data.get("files", []):
            if os_matches(f, osname):
                print("\t".join([f.get("id", ""), f.get("repo", "") or "-", first_home(f, osname) or "-"]))
    elif cmd == "tools":
        for t in data.get("tools", []):
            if os_matches(t, osname):
                print("\t".join([
                    t.get("id", ""), t.get("name", ""),
                    t.get("bin") or "-", t.get("version_cmd") or "-",
                    t.get("check") or "-",
                ]))
    elif cmd == "tool-installs":
        for t in data.get("tools", []):
            inst = t.get("install") or {}
            if os_matches(t, osname) and osname in inst:
                print("\t".join([t.get("id", ""), inst[osname]]))
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()