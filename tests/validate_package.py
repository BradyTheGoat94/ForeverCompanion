#!/usr/bin/env python3
"""Strict, standard-library-only Forever Companion beta ZIP validation."""
from pathlib import Path
from zipfile import ZipFile
import sys

zip_path = Path(sys.argv[1] if len(sys.argv)>1 else "ForeverCompanion.zip")
assert zip_path.is_file(), f"Missing package: {zip_path}"
with ZipFile(zip_path) as archive:
    bad = archive.testzip()
    assert bad is None, f"Corrupt ZIP member: {bad}"
    members = [x for x in archive.namelist() if not x.endswith("/")]
    assert members, "Empty addon archive"
    assert all(x.startswith("ForeverCompanion/") for x in members), "ZIP has unexpected top-level files"
    assert len(members) == len(set(members)), "Duplicate ZIP entries"
    assert "ForeverCompanion/ForeverCompanion.toc" in members, "Missing root manifest"
    toc = archive.read("ForeverCompanion/ForeverCompanion.toc").decode("utf-8-sig")
    files = [x.strip() for x in toc.splitlines() if x.strip() and not x.lstrip().startswith("#")]
    assert len(files) == len(set(files)), "Duplicate manifest entries"
    for filename in files:
        assert filename.endswith(".lua") and ".." not in filename and not filename.startswith("/"), f"Invalid manifest path: {filename}"
        assert "ForeverCompanion/" + filename in members, f"Missing manifest file: {filename}"
    lua_members = {x for x in members if x.endswith(".lua")}
    unlisted = sorted(lua_members - {"ForeverCompanion/" + x for x in files})
    assert not unlisted, f"Unlisted Lua source files: {unlisted}"
    assert "## Interface:" in toc and "## Version:" in toc, "Missing manifest metadata"
    print(f"PASS: {zip_path} ({len(members)} files, {len(files)} listed Lua modules)")
