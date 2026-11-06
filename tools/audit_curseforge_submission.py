#!/usr/bin/env python3
"""Fail closed on missing CurseForge beta handoff metadata; not a license or client audit."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TOC = ROOT / "ForeverCompanion" / "ForeverCompanion.toc"
HANDOFF = ROOT / "docs" / "CURSEFORGE_SUBMISSION.md"
EXPECTED = {"Interface": "16001", "Title": "Brady's Forever Companion", "Version": "3.19.0-beta"}
REQUIRED = (
    "## Project summary", "## Long description", "## Upload selection",
    "## Changelog", "## Release decision log", "No combat automation",
)

def audit():
    errors = []
    if not TOC.is_file() or not HANDOFF.is_file():
        return ["Missing addon TOC or CurseForge submission handoff"]
    metadata = dict(re.findall(r"^##\s+([^:\n]+):\s*(.+?)\s*$", TOC.read_text(encoding="utf-8"), re.M))
    for key, expected in EXPECTED.items():
        if metadata.get(key) != expected:
            errors.append(f"TOC {key} differs from submission expectation: {metadata.get(key)!r}")
    handoff = HANDOFF.read_text(encoding="utf-8")
    for phrase in REQUIRED:
        if phrase.lower() not in handoff.lower():
            errors.append(f"Missing submission disclosure/section: {phrase}")
    if "not yet been certified" not in handoff.lower():
        errors.append("Missing live-client certification disclaimer")
    if "owner explicitly decides" not in handoff.lower():
        errors.append("Missing unresolved owner license decision")
    if "not submitted" not in handoff.lower():
        errors.append("Missing unsubmitted moderation status")
    return errors

if __name__ == "__main__":
    problems = audit()
    for problem in problems:
        print("ERROR:", problem, file=sys.stderr)
    if problems:
        raise SystemExit(1)
    print("CurseForge submission metadata and disclosures: PASS (not live-client or legal verification)")
