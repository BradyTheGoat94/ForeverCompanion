"""Render captured native widget geometry, colors and project textures.

No invented navigation/cards/metrics: all labels and positions come from the mock.
Fonts and client-only icon textures are approximated; this is NOT a game capture.
"""
import json
import math
from functools import lru_cache
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ANCHORS={'TOPLEFT':(0,0),'TOP':(.5,0),'TOPRIGHT':(1,0),'LEFT':(0,.5),
         'CENTER':(.5,.5),'RIGHT':(1,.5),'BOTTOMLEFT':(0,1),'BOTTOM':(.5,1),'BOTTOMRIGHT':(1,1)}
FONT_ROOT='/usr/share/fonts/truetype/dejavu/'

def font_for(n):
    size=n.get('font',[None,12])[1] if n.get('font') else (16 if 'Large' in n.get('template','') else 12)
    face='DejaVuSerif.ttf' if n.get('font') or 'Normal' in n.get('template','') else 'DejaVuSans.ttf'
    return ImageFont.truetype(FONT_ROOT+face,int(size)),int(size)

def wrapped(value,width,font):
    lines=[]
    for paragraph in value.split('\n'):
        line=''
        for word in paragraph.split():
            candidate=(line+' '+word).strip()
            if line and font.getlength(candidate)>width:
                lines.append(line);line=word
            else:line=candidate
        lines.append(line)
    return lines

def render(source,output,workspace=False):
    records=json.loads(Path(source).read_text())
    nodes={n['id']:n for n in records}
    children={}
    for n in records: children.setdefault(n.get('parent'),[]).append(n)
    window=next(n for n in records if n.get('name')=='ForeverCompanionMainFrame')

    @lru_cache(None)
    def box(ident):
        n=nodes[ident]
        if ident==window['id']: return (24.,24.,1080.,float(n['height']))
        if not n.get('parent'): return (0.,0.,1000.,700.)
        if n.get('all'): return box(n['all'])
        parent=box(n['parent'])
        f,size=font_for(n)
        auto_width=max([f.getlength(s) for s in n.get('text','').split('\n')]+[1])+2
        w=float(n.get('width') or (auto_width if n['kind']=='FontString' else 1))
        auto_height=len(wrapped(n.get('text',''),w,f))*(size+2)+2
        h=float(n.get('height') or (auto_height if n['kind']=='FontString' else 1))
        positions=[]
        for anchor,rel,rpoint,dx,dy in n.get('points',[]):
            rx,ry,rw,rh=box(rel)
            ax,ay=ANCHORS.get(anchor,(0,0));bx,by=ANCHORS.get(rpoint,(0,0))
            positions.append((ax,ay,rx+rw*bx+dx,ry+rh*by-dy))
        if len(positions)>1:
            for a in positions:
                for b in positions:
                    if a[0]!=b[0]: w=abs((a[2]-b[2])/(a[0]-b[0]))
                    if a[1]!=b[1]: h=abs((a[3]-b[3])/(a[1]-b[1]))
        if positions:
            ax,ay,px,py=positions[0];return (px-ax*w,py-ay*h,w,h)
        # Scroll children use the viewport's origin even without explicit anchors.
        return (*parent[:2],w,h)

    @lru_cache(None)
    def visible(ident):
        n=nodes[ident]
        return n.get('visible',True) and (not n.get('parent') or visible(n['parent']))

    def intersect(a,b):
        return (max(a[0],b[0]),max(a[1],b[1]),min(a[2],b[2]),min(a[3],b[3]))

    if workspace in ('legacy','alts','practice'):
        expected={'legacy':'LEGACY RESEARCH DESK','alts':'ALT PREPARATION DESK'}
        label=next(n for n in records if (workspace!='practice' and n.get('text')==expected.get(workspace)) or (workspace=='practice' and n.get('text','').endswith(' / PRACTICE DESK')))
        target=nodes[label['parent']]
        bx,by,bw,bh=box(target['id'])
        offset=(24-bx,24-by);width,height=818,math.ceil(bh)+94
        start=target['id']
    elif workspace=='loot':
        target=next(n for n in records if n.get('name')=='ForeverCompanionLootCatalog')
        bx,by,bw,bh=box(target['id'])
        offset=(24-bx,24-by);width,height=818,math.ceil(bh)+94
        start=target['id']
    elif workspace:
        label=next(n for n in records if n.get('text')=='Rotation Type')
        target=nodes[nodes[label['parent']]['parent']]
        bx,by,bw,bh=box(target['id'])
        offset=(24-bx,24-by);width,height=818,math.ceil(bh)+94
        start=target['id']
    else:
        offset=(0,0);width,height=1128,int(window['height'])+94;start=window['id']
    im=Image.new('RGBA',(width,height),(8,9,12,255))

    def rgba(value,default=(.88,.88,.84,1)):
        value=list(value or default)
        if len(value)==3:value.append(1)
        return tuple(max(0,min(255,round(v*255))) for v in value)

    def draw(n,clip):
        if not visible(n['id']): return
        x,y,w,h=box(n['id']);x+=offset[0];y+=offset[1]
        if w<=0 or h<=0 or not math.isfinite(w+h): return
        clip=intersect(clip,(x,y,x+w,y+h))
        if clip[0]>=clip[2] or clip[1]>=clip[3]: return
        # Avoid enormous content glyph surfaces; the viewport clips long prose.
        iw,ih=max(1,math.ceil(min(w,width))),max(1,math.ceil(min(h,height)))
        layer=Image.new('RGBA',(iw,ih),(0,0,0,0));d=ImageDraw.Draw(layer)
        if n['kind']=='Texture':
            if n.get('color'): d.rectangle((0,0,iw,ih),fill=rgba(n['color']))
            texture=n.get('texture','')
            if '\\Media\\' in texture:
                path=Path('ForeverCompanion/Media')/texture.rsplit('\\',1)[1]
                art=Image.open(path).convert('RGBA')
                crop=n.get('crop')
                if crop and len(crop)==4: art=art.crop((crop[0]*art.width,crop[2]*art.height,crop[1]*art.width,crop[3]*art.height))
                art=art.resize((iw,ih),Image.Resampling.LANCZOS)
                if n.get('alpha') is not None: art.putalpha(art.getchannel('A').point(lambda a:round(a*n['alpha'])))
                layer.alpha_composite(art)
            elif texture and '\\Icons\\' in texture:
                d.rectangle((0,0,iw-1,ih-1),fill=(43,40,32),outline=(146,117,65))
                d.line((3,ih-4,iw-4,3),fill=(202,169,91),width=max(1,iw//12))
        elif n['kind']=='FontString':
            f,size=font_for(n)
            lines=wrapped(n.get('text',''),iw,f)
            for i,line in enumerate(lines):
                px=(iw-d.textlength(line,font=f))/2 if n.get('justify')=='CENTER' else (iw-d.textlength(line,font=f) if n.get('justify')=='RIGHT' else 0)
                d.text((px,i*(size+2)-2),line,font=f,fill=rgba(n.get('textColor')))
        elif n['kind']=='Button' and n.get('template')=='UIPanelButtonTemplate':
            d.rectangle((0,0,iw-1,ih-1),fill=(28,29,32),outline=(134,110,62))
            f=ImageFont.truetype(FONT_ROOT+'DejaVuSerif.ttf',11)
            d.text((6,4),n.get('text',''),font=f,fill=(231,211,164))
        else: return
        if n.get('alpha') is not None and '\\Media\\' not in n.get('texture',''):
            layer.putalpha(layer.getchannel('A').point(lambda a:round(a*n['alpha'])))
        left,top,right,bottom=[round(v) for v in clip]
        layer=layer.crop((max(0,round(left-x)),max(0,round(top-y)),min(iw,round(right-x)),min(ih,round(bottom-y))))
        if layer.width and layer.height: im.alpha_composite(layer,(left,top))

    layer_order={'BACKGROUND':0,'BORDER':1,'ARTWORK':2,'OVERLAY':3,'HIGHLIGHT':4}
    def visit(ident,clip):
        n=nodes[ident]
        if not visible(ident):return
        draw(n,clip)
        if n['kind']=='ScrollFrame':
            x,y,w,h=box(ident);clip=intersect(clip,(x+offset[0],y+offset[1],x+offset[0]+w,y+offset[1]+h))
        kids=children.get(ident,[])
        for child in sorted((c for c in kids if c['kind'] in ('Texture','FontString')),key=lambda c:layer_order.get(c.get('layer'),2)):
            draw(child,clip)
        for child in kids:
            if child['kind'] not in ('Texture','FontString'):visit(child['id'],clip)
    visit(start,(0,0,width,height-45))
    # Rotation tiles are siblings of the workspace so the addon can reuse its
    # existing selected-priority behavior. Include them in the inspection crop.
    if workspace is True:
        for n in records:
            if n['kind']=='Button' and n.get('width')==88 and n.get('height')==96:visit(n['id'],(24,24,width-24,height-45))
    d=ImageDraw.Draw(im)
    f=ImageFont.truetype(FONT_ROOT+'DejaVuSans.ttf',12)
    d.text((24,height-29),'OFFLINE NATIVE WIDGET LAYOUT / fonts & Blizzard icons approximated / not an in-game screenshot',font=f,fill=(221,181,105))
    im.convert('RGB').save(output)
    print('PASS: native widget geometry rendered:',output)

render('ui_dashboard_native.json','ui_dashboard_native.png')
render('ui_class_native.json','ui_class_native.png')
render('ui_class_native.json','ui_rotation_native.png',True)
render('ui_topic_native.json','ui_topic_native.png')
render('ui_gear_native.json','ui_gear_native.png')
render('ui_loot_native.json','ui_loot_native.png','loot')
render('ui_long_priority_native.json','ui_long_priority_native.png',True)
# Existing automation consumes these established preview filenames. Keep them
# aligned with the native-layout outputs rather than older schematic drawings.
from shutil import copyfile
copyfile('ui_dashboard_native.png','ui_preview.png')
copyfile('ui_class_native.png','ui_class_preview.png')


# Planning-board inspection uses captured native colors and geometry, including
# class accents and completion rails, rather than schematic recoloring.
for section in ('legacy','alts','practice'):
    render('ui_'+section+'_native.json','ui_'+section+'_native.png',section)
