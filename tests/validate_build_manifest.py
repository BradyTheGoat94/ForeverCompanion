#!/usr/bin/env python3
"""Validate generated beta provenance against the actual distributable ZIP."""
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile

archive = Path("ForeverCompanion.zip")
manifest = Path("beta-build-manifest.json")
assert archive.is_file() and manifest.is_file(), "Missing release artifacts"
record = json.loads(manifest.read_text(encoding="utf-8"))
assert record["package"] == archive.name, "Wrong package name"
assert record["sha256"] == hashlib.sha256(archive.read_bytes()).hexdigest(), "ZIP hash mismatch"
assert record["in_game_tested"] is False, "CI must never certify live client testing"
assert record["release_approved"] is False, "CI must never approve public release"
assert len(record["commit"]) >= 7 and record["commit"] != "unknown", "Missing commit provenance"
with ZipFile(archive) as z:
    toc = z.read("ForeverCompanion/ForeverCompanion.toc").decode("utf-8-sig")
    metadata = {}
    for line in toc.splitlines():
        if line.startswith("## ") and ":" in line:
            k,v = line[3:].split(":",1)
            metadata[k.strip()] = v.strip()
assert record["addon_version"] == metadata["Version"], "Version mismatch"
assert record["manifest_interface"] == metadata["Interface"], "Interface mismatch"
print("PASS: beta provenance matches ZIP and remains explicitly unapproved")
