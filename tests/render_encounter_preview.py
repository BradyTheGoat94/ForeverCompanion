"""Draw captured encounter widgets at their actual relative coordinates.

This is an offline layout illustration with approximate fonts, not a game screenshot.
"""
import csv
import textwrap
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

rows = list(csv.DictReader(Path('ui_encounter_snapshot.txt').open(), delimiter='|'))
heading = next(r for r in rows if r['kind'] == 'FontString' and r['text'].startswith('REFERENCE / '))
panel = next(r for r in rows if r['id'] == heading['parent'])
children = [r for r in rows if r['parent'] == panel['id']]
assert panel['height'] == '356'
buttons = [r for r in children if r['kind'] == 'Button' and r['height'] == '29']
assert len(buttons) == 4 and all(r['visible'] == '1' for r in buttons)
assert any('[SELECTED]' in r['text'] for r in buttons)
assert any(r['kind'] == 'EditBox' for r in children)
assert any(r['text'] == 'Next bosses' for r in children)

scale = 1.5
im = Image.new('RGB', (1155, 590), (10, 14, 21))
d = ImageDraw.Draw(im)
d.rectangle((0, 0, 1154, 534), outline=(210, 163, 71), width=2)

def font(size):
    return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', size)

for row in children:
    if row['visible'] != '1' or row['kind'] not in ('FontString', 'Button', 'EditBox'):
        continue
    x, y = float(row['x']), -float(row['y'])
    w = float(row['width'])
    size = 19 if row == heading else 14
    value = row['text']
    if row['kind'] in ('Button', 'EditBox'):
        h = float(row['height'])
        assert 0 <= y < y + h <= 356, 'Control exceeds browser panel'
        selected = '[SELECTED]' in value
        d.rectangle((x*scale, y*scale, (x+w)*scale, (y+h)*scale),
                    fill=(64, 49, 29) if selected else (25, 33, 45),
                    outline=(228, 180, 79) if selected else (100, 87, 62))
        x += 8
        y += 5
        w -= 16
    lines = textwrap.wrap(value, width=max(8, int(w*scale/(size*.58))))
    for i, line in enumerate(lines):
        d.text((x*scale, y*scale+i*(size+3)), line, font=font(size),
               fill=(239, 195, 112) if row == heading or '[SELECTED]' in value else (220, 224, 231))

d.text((16, 557), 'OFFLINE ENCOUNTER WIDGET PREVIEW / approximate fonts / live-client testing pending',
       font=font(14), fill=(186, 194, 209))
im.save('ui_encounter_preview.png')
print('PASS: captured boss browser controls and panel bounds')
