"""Validate the reference-style class layout before the native renderer runs.

The native renderer owns the final PNG: this preflight does not invent a layout.
"""
import json
from pathlib import Path
nodes=json.loads(Path('ui_class_native.json').read_text())
texts={n.get('text','') for n in nodes}
for title in ['CLASS GUIDES  /  WARRIOR','Rotation Type','Priority & Explanations','Quick Tips','Class Quick Info','Selected Priority']:
    assert title in texts, 'Missing native class widget: '+title
for view in ['Overview','Talents','Rotations','Leveling','Dungeons','PvP','Gear & Stats','Professions']:
    assert any(n.get('text')==view and n['kind']=='FontString' for n in nodes), 'Missing topic: '+view
assert any(n.get('texture','').endswith('Warrior.tga') for n in nodes), 'Missing illustrated class header'
tiles=[n for n in nodes if n['kind']=='Button' and n.get('width')==88 and n.get('height')==96 and n.get('visible')]
assert tiles, 'No native priority tiles captured'
print('PASS: illustrated class banner, eight topic tabs, priority table and large tiles captured')
