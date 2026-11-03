#!/usr/bin/env python3
"""Reproducible, fail-closed CurseForge beta packaging for ForeverCompanion.

Does not claim client compatibility. Run from any working directory:
  python3 tools/build_curseforge_beta.py --output dist
"""
from __future__ import annotations
import argparse
import hashlib
import json
import pathlib
import re
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
ADDON = ROOT / "ForeverCompanion"
TOC = ADDON / "ForeverCompanion.toc"
FORBIDDEN = {".git", "__pycache__", ".pytest_cache", ".github", "tests", "tools", "dist"}
ALLOWED = {".lua", ".toc", ".tga", ".blp", ".png", ".jpg", ".jpeg", ".xml", ".ttf", ".otf"}
MAX_FILE = 20 * 1024 * 1024

def validate() -> tuple[list[pathlib.Path], dict]:
    errors = []
    if not TOC.is_file():
        raise ValueError("Missing ForeverCompanion/ForeverCompanion.toc")
    raw = TOC.read_text(encoding="utf-8-sig")
    meta = {}
    sources = []
    for line in raw.splitlines():
        line = line.strip()
        if not line or line.startswith("#") and not line.startswith("## "):
            continue
        if line.startswith("## "):
            if ":" not in line:
                errors.append("Invalid manifest directive: " + line)
                continue
            k, v = line[3:].split(":", 1)
            meta[k.strip()] = v.strip()
        else:
            if "[" in line or "]" in line:
                errors.append("Dynamic manifest path requires manual audit: " + line)
                continue
            rel = pathlib.PureWindowsPath(line.replace("/", "\\"))
            parts = rel.parts
            if not parts or any(x in ("..", ".") for x in parts) or rel.is_absolute():
                errors.append("Unsafe manifest path: " + line)
                continue
            target = ADDON.joinpath(*parts)
            if not target.is_file():
                errors.append("Missing manifest dependency: " + line)
            else:
                sources.append(target)
    for required in ("Interface", "Title", "Version"):
        if not meta.get(required):
            errors.append("Missing ## " + required)
    if meta.get("Title") != "Brady's Forever Companion":
        errors.append("Public title differs from approved brand")
    if not re.fullmatch(r"[0-9]+", meta.get("Interface", "")):
        errors.append("Interface must be a numeric value; verify it against the target client")
    if not sources:
        errors.append("No Lua/XML entries in manifest")
    if len(sources) != len(set(sources)):
        errors.append("Duplicate manifest file entry")
    if sources and sources[-1].name != "Core.lua":
        errors.append("Core.lua should load last")
    files = []
    for p in sorted(ADDON.rglob("*")):
        if p.is_symlink():
            errors.append("Symlink not allowed: " + str(p.relative_to(ROOT)))
            continue
        if not p.is_file():
            continue
        if any(part.startswith(".") or part in FORBIDDEN for part in p.relative_to(ADDON).parts):
            continue
        if p.suffix.lower() not in ALLOWED:
            errors.append("Unexpected packaged extension: " + str(p.relative_to(ROOT)))
            continue
        if p.stat().st_size > MAX_FILE:
            errors.append("Oversized addon asset: " + str(p.relative_to(ROOT)))
        files.append(p)
    if TOC not in files:
        errors.append("Manifest excluded from archive")
    if errors:
        raise ValueError("\n".join(errors))
    return files, meta

def build(outdir: pathlib.Path) -> pathlib.Path:
    files, meta = validate()
    outdir.mkdir(parents=True, exist_ok=True)
    version = re.sub(r"[^A-Za-z0-9._-]", "-", meta["Version"])
    archive = outdir / ("BradysForeverCompanion-" + version + ".zip")
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for p in files:
            rel = p.relative_to(ROOT).as_posix()
            info = zipfile.ZipInfo(rel, date_time=(2020, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o644 << 16
            z.writestr(info, p.read_bytes(), compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    with zipfile.ZipFile(archive) as z:
        names = z.namelist()
        if len(names) != len(set(names)) or any(not n.startswith("ForeverCompanion/") for n in names):
            raise ValueError("Invalid archive root or duplicate entries")
        if "ForeverCompanion/ForeverCompanion.toc" not in names or z.testzip():
            raise ValueError("Archive integrity check failed")
    report = {"archive": archive.name, "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
              "files": len(files), "title": meta["Title"], "version": meta["Version"],
              "interface": meta["Interface"], "client_verified": False,
              "warning": "Forever client compatibility and interface number are unverified"}
    (outdir / "release-audit.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return archive

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default=str(ROOT / "dist"))
    parser.add_argument("--check-only", action="store_true")
    args = parser.parse_args()
    try:
        if args.check_only:
            files, meta = validate()
            print(f"Manifest and {len(files)} files validated; client compatibility NOT verified")
        else:
            build(pathlib.Path(args.output))
    except (ValueError, OSError) as exc:
        print("RELEASE AUDIT FAILED: " + str(exc), file=sys.stderr)
        sys.exit(1)
