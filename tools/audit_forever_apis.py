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
)
# Calls guarded by feature probes may be intentional. Report all direct calls
# rather than incorrectly claiming safety from a regex-level inspection.
def scan():
    hits = []
    for path in sorted(ROOT.glob("*.lua")):
        source = path.read_text(encoding="utf-8")
        for symbol in MISSING:
            pattern = r"(?<![\w.:'\"])"+re.escape(symbol)+r"\s*\("
            for m in re.finditer(pattern, source):
                line = source.count("\n", 0, m.start()) + 1
                hits.append((path.name, line, symbol))
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
