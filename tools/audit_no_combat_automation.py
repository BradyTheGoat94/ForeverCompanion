#!/usr/bin/env python3
"""Fail closed on explicit combat automation patterns in packaged addon Lua.

Static defense-in-depth only; manual code and in-client review remain required.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1] / "ForeverCompanion"
BANNED = (
    r"\b(?:CastSpellByName|CastSpellByID|CastSpell|UseAction|UseInventoryItem|UseContainerItem|TargetUnit|TargetNearestEnemy|TargetNearestFriend|RunMacro|RunMacroText|SetBinding|SetBindingSpell|SetBindingMacro|SetBindingClick|AttackTarget|StartAttack|PetAttack|SpellStopCasting)\s*\(",
    r"\b(?:C_Spell\.CastSpell|C_ActionBar\.UseAction|C_Macro\.RunMacro)\s*\(",
    r"\b(?:SecureActionButtonTemplate|SecureHandlerClickTemplate)\b",
    r"\b(?:type\s*=\s*['\"](?:spell|macro|item|target)['\"])",
    r"""\bSetAttribute\s*\(\s*['"]type['"]\s*,\s*['"](?:spell|macro|item|target)['"]""",
)
def scan():
    findings = []
    for path in sorted(ROOT.rglob("*.lua")):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.lstrip().startswith("--"):
                continue
            for expression in BANNED:
                if re.search(expression, line):
                    findings.append((path.relative_to(ROOT), number, line.strip()))
    return findings

if __name__ == "__main__":
    findings = scan()
    for path, number, line in findings:
        print(f"BLOCK {path}:{number}: {line}")
    if findings:
        sys.exit("FAIL: combat automation indicators found; review required")
    print("PASS: no direct combat automation indicators in packaged Lua")
    print("LIMIT: dynamic invocation and runtime behavior still require manual review")
