"""Validate the reference-style class layout before the native renderer runs.

The native renderer owns the final PNG: this preflight does not invent a layout.
"""
import json
from pathlib import Path
nodes=json.loads(Path('ui_class_native.json').read_text())
texts={n.get('text','') for n in nodes}
for title in ['CLASS GUIDES  /  WARRIOR','Rotation Type','What to Press','More guide notes']:
    assert title in texts, 'Missing native class widget: '+title
for view in ['Overview','Talents','Rotations','Leveling','Dungeons','PvP','Gear & Stats','Professions']:
    assert any(n.get('text')==view and n['kind']=='FontString' for n in nodes), 'Missing topic: '+view
assert any(n.get('texture','').endswith('Warrior.tga') for n in nodes), 'Missing illustrated class header'
steps=[n for n in nodes if n.get('width')==550 and n['kind']=='Frame' and n.get('visible')]
assert steps, 'No native priority rows captured'
print('PASS: illustrated banner, eight topic tabs and numbered priorities captured')
