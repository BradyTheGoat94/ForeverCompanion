#!/usr/bin/env python3
"""Conservative static Forever API risk audit; no third-party code is vendored.

This catches direct calls to globals reported missing in public 1.60.1 API
captures. Dynamic calls and behavioral correctness require real-client testing.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1] / "ForeverCompanion"
# These older globals are absent from the modern Forever baseline.
MISSING = (
    "GetSpellInfo", "GetItemInfo", "UnitAura", "GetTalentInfo",
    "GetMerchantItemInfo", "CombatLogGetCurrentEventInfo",
    "GetContainerItemInfo", "GetNumTalentTabs", "GetTalentTabInfo",
    "GetSpecialization", "GetSpecializationInfo",
)
# Calls guarded by feature probes may be intentional. Report all direct calls
# rather than incorrectly claiming safety from a regex-level inspection.
def scan():
    hits = []
    for path in sorted(ROOT.rglob("*.lua")):
        source = path.read_text(encoding="utf-8")
        for line, raw in enumerate(source.splitlines(), 1):
            # Exclude full-line Lua comments; ordinary code remains fail-closed.
            if raw.lstrip().startswith("--"):
                continue
            for symbol in MISSING:
                pattern = r"(?<![\w.:'\"])"+re.escape(symbol)+r"\s*\("
                if re.search(pattern, raw):
                    hits.append((str(path.relative_to(ROOT)), line, symbol))
    return hits

if __name__ == "__main__":
    hits = scan()
    if hits:
        for name, line, symbol in hits:
            print(f"REVIEW {name}:{line}: deprecated direct call {symbol}")
        print(f"{len(hits)} compatibility risks found. Inspect and guard or port them.")
        sys.exit(1)
    print("PASS: no direct calls to curated absent legacy globals.")
    print("LIMIT: static checks do not verify runtime behavior, dynamic calls, or API signatures.")
