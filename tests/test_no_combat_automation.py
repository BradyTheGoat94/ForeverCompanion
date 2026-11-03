#!/usr/bin/env python3
"""Regression tests for the zero-combat-automation release gate."""
import importlib.util
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("combat_audit", ROOT / "tools" / "audit_no_combat_automation.py")
audit = importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class CombatAutomationAuditTests(unittest.TestCase):
    def scan(self, source):
        with TemporaryDirectory() as directory:
            old = audit.ROOT
            try:
                audit.ROOT = Path(directory)
                (audit.ROOT / "sample.lua").write_text(source, encoding="utf-8")
                return audit.scan()
            finally:
                audit.ROOT = old

    def test_informational_guide_is_allowed(self):
        self.assertEqual([], self.scan("""
-- CastSpellByName('Fireball') is documentation only
local hint = 'Use Fireball after your opening buff'
local icon = C_Spell.GetSpellTexture('Fireball')
"""))

    def test_direct_casting_and_targeting_are_blocked(self):
        for source in (
            "CastSpellByName('Fireball')",
            "C_Spell.CastSpell(133)",
            "TargetNearestEnemy()",
            "RunMacroText('/cast Fireball')",
            "SetBindingSpell('1','Fireball')",
            "StartAttack()",
            "local f=CreateFrame('Button',nil,UIParent,'SecureActionButtonTemplate')",
            "button:SetAttribute('type','spell')",
        ):
            with self.subTest(source=source):
                self.assertTrue(self.scan(source), source)

    def test_nested_files_are_scanned(self):
        with TemporaryDirectory() as directory:
            old = audit.ROOT
            try:
                audit.ROOT = Path(directory)
                (audit.ROOT / "sub").mkdir()
                (audit.ROOT / "sub" / "bad.lua").write_text("RunMacro(1)", encoding="utf-8")
                self.assertEqual(1, len(audit.scan()))
            finally:
                audit.ROOT = old


if __name__ == "__main__":
    unittest.main()
