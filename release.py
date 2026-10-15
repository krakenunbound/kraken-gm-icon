#!/usr/bin/env python3
"""Build KrakenGMIcon.ext and publish it as a GitHub Release.

Usage:
    python release.py               # tag = "v" + version from extension.xml
    python release.py v1.1          # explicit tag
    python release.py --build-only  # build the .ext, no release

Requires: Python 3 and, to publish, the GitHub CLI (`gh`) authenticated.
"""
import os, sys, subprocess, zipfile
import xml.etree.ElementTree as ET

REPO = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(REPO, "build", "KrakenGMIcon.ext")
DIRS = ["graphics", "scripts", "strings", "utility"]


def version():
    r = ET.parse(os.path.join(REPO, "extension.xml")).getroot()
    return r.findtext("properties/version") or "0.0"


def files():
    out = ["extension.xml"]
    for d in DIRS:
        for root, _, names in os.walk(os.path.join(REPO, d)):
            for n in sorted(names):
                out.append(os.path.relpath(os.path.join(root, n), REPO).replace("\\", "/"))
    return out


def main():
    args = list(sys.argv[1:])
    build_only = "--build-only" in args
    if build_only:
        args.remove("--build-only")
    tag = args[0] if args else "v" + version()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
        for f in files():
            z.write(os.path.join(REPO, f), f)
    print(f"[build] {os.path.basename(OUT)}")
    if build_only:
        return
    title = f"Kraken GM Icon {tag}"
    notes = ("Install: KrakenGMIcon.ext -> Fantasy Grounds \\extensions\\, then tick Kraken GM Icon for your "
             "campaign (any ruleset). As the GM: Options > GM Icon to pick the GM's chat picture. "
             "See CHANGELOG.md for what's new.")
    exists = subprocess.run(["gh", "release", "view", tag], cwd=REPO,
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
    if exists:
        subprocess.run(["gh", "release", "upload", tag, OUT, "--clobber"], cwd=REPO, check=True)
    else:
        subprocess.run(["gh", "release", "create", tag, OUT, "--title", title, "--notes", notes],
                       cwd=REPO, check=True)
    print("[done]", tag)


if __name__ == "__main__":
    main()
