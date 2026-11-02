#!/usr/bin/env python3
"""Static beta preflight: guide inventory, manifest order, and safety labels.

This validates source completeness, not actual client mechanics or sim accuracy.
"""
from pathlib import Path
import re

root = Path("ForeverCompanion")
toc = (root / "ForeverCompanion.toc").read_text(encoding="utf-8")
manifest = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
required = ["SpecPlanner.lua", "SpecPlaybooks.lua", "ForeverLessons.lua", "Core.lua"]
for name in required:
    assert manifest.count(name) == 1, f"Manifest must load {name} exactly once"
assert manifest.index("SpecPlanner.lua") < manifest.index("SpecPlaybooks.lua") < manifest.index("Core.lua")
assert manifest.index("ForeverLessons.lua") < manifest.index("Core.lua")

specs = (root / "SpecPlanner.lua").read_text(encoding="utf-8")
playbooks = (root / "SpecPlaybooks.lua").read_text(encoding="utf-8")
lessons = (root / "ForeverLessons.lua").read_text(encoding="utf-8")
core = (root / "Core.lua").read_text(encoding="utf-8")
classes = ("WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID")
for cls in classes:
    assert re.search(r"\b" + cls + r"\s*=\s*\{", specs), f"Missing planner class {cls}"
    assert re.search(r"\b" + cls + r"\s*=\s*\{", playbooks), f"Missing playbook class {cls}"
    assert re.search(r"\b" + cls + r"\s*=\s*\{", lessons), f"Missing sourced lesson class {cls}"

for function in ("ForeverCompanionSpecPlaybookLines", "ForeverCompanionSpecPriorityNoteLines",
                 "ForeverCompanionForeverLessonLines", "ForeverCompanionNovemberTuningLines"):
    assert f"type({function})" in core, f"UI not rendering {function}"

assert "Skip untrained spells" in playbooks
assert "not an automated rotation" in playbooks
assert "EXPERIMENTAL FOREVER THEORYCRAFT" in lessons
assert "REPORTED, NOT OFFICIALLY CONFIRMED" in lessons
assert "in_game_tested: false" in Path("BETA_RELEASE_GATE.md").read_text(encoding="utf-8")
print("PASS: nine classes, guide UI hooks, manifest ordering, source cautions, and beta safety claims")
