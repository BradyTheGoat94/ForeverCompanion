"""Render the real planning-board widget strings for offline layout inspection.
Fonts are approximated; this is not a live-client screenshot.
"""
import csv
import textwrap
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

def font(size):
    return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',size)

def render(name,needle):
    rows=list(csv.DictReader(Path(f'ui_{name}_snapshot.txt').open(),delimiter='|'))
    heading=next(r for r in rows if needle in r['text'] and r['kind']=='FontString')
    parent=heading['parent']
    panel=[r for r in rows if r['parent']==parent]
    im=Image.new('RGB',(1155,610),(10,14,21));d=ImageDraw.Draw(im)
    d.rectangle((0,0,1154,562),fill=(9,12,18),outline=(198,148,63),width=2)
    for row in panel:
        if row['kind']=='FontString' and row['text']:
            x,y=int(float(row['x'])),int(float(row['y']))
            size=20 if row==heading else 14
            value=row['text'];width=max(10,int(float(row['width'])/7.5))
            for j,line in enumerate(textwrap.wrap(value,width=width)):
                d.text((x*1.5,-y*1.5+j*21),line,font=font(size),fill=(237,188,97) if row==heading else (215,219,225))
    # Identify actual checklist buttons by their native widget dimensions.
    # The study desk moved from 43px to 40px rows; hardcoded 43px broke CI.
    board_rows=[r for r in rows if r['kind']=='Button' and r['parent']==parent
                and r['width'] and r['height']
                and float(r['width'])>=700 and 30<=float(r['height'])<=60]
    assert len(board_rows)==5, f'expected five native task tiles, got {len(board_rows)}'
    for row in board_rows:
        x,y=int(float(row['x'])),int(float(row['y']))
        w,h=float(row['width']),float(row['height'])
        d.rectangle((x*1.5,-y*1.5,(x+w)*1.5,(-y+h)*1.5),fill=(22,30,42),outline=(63,62,51))
        for child in rows:
            if child['parent']==row['id'] and child['kind']=='FontString' and child['text']:
                cx,cy=int(float(child['x'])),int(float(child['y']))
                lines=textwrap.wrap(child['text'],width=84 if cx>20 else 6)
                assert len(lines)<=2,'task text exceeds tile height: '+child['text']
                for j,line in enumerate(lines):
                    d.text(((x+cx)*1.5,(-y-cy)*1.5+j*21),line,font=font(15),fill=(237,188,97) if cx<20 else (237,230,216))
    for row in panel:
        if row['kind']=='Button' and row['height']=='24':
            x,y=int(float(row['x'])),int(float(row['y']))
            if row['anchor']=='TOPRIGHT':x=770+x-int(row['width'])
            w=int(row['width']);d.rectangle((x*1.5,-y*1.5,(x+w)*1.5,(-y+24)*1.5),fill=(45,40,30),outline=(154,120,64))
            d.text((x*1.5+9,-y*1.5+9),row['text'],font=font(14),fill=(239,210,154))
    d.text((16,580),'OFFLINE WIDGET PREVIEW / fonts approximated / live-client acceptance pending',font=font(14),fill=(169,180,196))
    im.save(f'ui_{name}_preview.png')
    print('PASS: native planning board layout:',name)
for name,needle in [('legacy','LEGACY RESEARCH DESK'),('alts','ALT PREPARATION DESK'),('practice',' / PRACTICE DESK')]:render(name,needle)
