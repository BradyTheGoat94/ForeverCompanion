"""Illustrative offline preview using the addon mock's actual widget strings.
This is NOT a WoW screenshot: textures, fonts, and geometry are approximated.
"""
import csv
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

rows=list(csv.DictReader(Path("ui_snapshot.txt").open(encoding="utf-8"),delimiter="|"))
strings=[r["text"] for r in rows if r.get("kind")=="FontString" and r.get("text")]
required=["WELCOME TO FOREVER COMPANION","CHARACTER OVERVIEW","QUICK ACTIONS",
          "PROGRESS & GOALS","RECOMMENDED NEXT STEPS","TODAY'S FOCUS"]
missing=[s for s in required if s not in strings]
if missing:
    raise SystemExit("Dashboard snapshot missing actual widgets: "+", ".join(missing))
# Recommended steps must be actual buttons, not static decoration.
button_ids={r["id"] for r in rows if r.get("kind")=="Button"}
for prefix in ("1. ","2. ","3. "):
    if not any(r.get("kind")=="FontString" and r.get("parent") in button_ids
               and r.get("text","").startswith(prefix) for r in rows):
        raise SystemExit("Recommended dashboard step is not a clickable widget: "+prefix)
def find(prefix,default="Unavailable"):
    exact=next((s for s in strings if s==prefix),None)
    return exact if exact is not None else next((s for s in strings if s.startswith(prefix)),default)
def font(size,bold=False):
    suffix="-Bold" if bold else ""
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans"+suffix+".ttf",size)
    except OSError:
        return ImageFont.load_default()
F13,F16,F18,F21,F27,F37=(font(13),font(16),font(18),font(21,True),font(27,True),font(37,True))
gold=(240,190,90); goldDim=(135,99,46); white=(241,235,220); muted=(172,182,196)
W,H=1500,950
im=Image.new("RGB",(W,H),(12,15,22))
d=ImageDraw.Draw(im)
# A framed fantasy interface, scaled from the addon layout. Visual-only treatment.
x,y=70,62
d.rounded_rectangle((x,y,x+1360,y+804),radius=15,fill=(16,20,28),outline=goldDim,width=4)
d.rounded_rectangle((x+6,y+6,x+1354,y+798),radius=10,outline=(100,78,45),width=1)
d.rectangle((x+12,y+12,x+1348,y+18),fill=(155,109,42))
d.rectangle((x+14,y+22,x+1346,y+125),fill=(24,28,39))
# Original native-UI FC heraldic monogram, approximated from actual widget labels.
d.rounded_rectangle((x+29,y+42,x+103,y+116),radius=5,fill=(26,28,33),outline=gold,width=3)
d.rounded_rectangle((x+35,y+48,x+97,y+110),radius=3,outline=goldDim,width=2)
if strings.count("FC")<2:
    raise SystemExit("Native header/dashboard heraldic marks missing from mock widget tree")
d.text((x+47,y+64),"FC",font=F27,fill=gold)
d.text((x+121,y+37),find("Forever Companion","Forever Companion"),font=F37,fill=gold)
d.text((x+123,y+88),find("Guides  -","Guides  -  Professions  -  Quests  -  Builds  -  More"),font=F16,fill=white)
manifest=Path("ForeverCompanion/ForeverCompanion.toc").read_text(encoding="utf-8")
version=next((line.split(":",1)[1].strip() for line in manifest.splitlines()
              if line.startswith("## Version:")), "unknown")
d.text((x+1080,y+48),"v"+version.upper(),font=F16,fill=gold)
# Left navigation.
sx,sy=x+14,y+139
d.rounded_rectangle((sx,sy,sx+246,sy+589),radius=8,fill=(20,26,34),outline=(75,61,43))
d.text((sx+22,sy+18),"NAVIGATION",font=F21,fill=gold)
tabs=["Overview","Leveling","Quests","Dungeons","Professions","PvP","Settings"]
for i,label in enumerate(tabs):
    yy=sy+62+i*64
    active=i==0
    d.rounded_rectangle((sx+12,yy,sx+234,yy+53),radius=5,
        fill=(80,57,24) if active else (29,36,46),
        outline=gold if active else (66,67,67),width=2 if active else 1)
    d.ellipse((sx+26,yy+18,sx+43,yy+35),fill=gold if active else goldDim)
    d.text((sx+57,yy+15),label,font=F18,fill=gold if active else white)
# Main welcome banner.
cx=x+276
cw=1068
def panel(px,py,pw,ph,title):
    d.rounded_rectangle((px,py,px+pw,py+ph),radius=8,fill=(22,28,37),outline=(110,87,51),width=2)
    d.rectangle((px+2,py+2,px+pw-2,py+6),fill=goldDim)
    # Native addon panels now contain small gold corner inlays.
    for dx in (8,pw-22):
        d.rectangle((px+dx,py+9,px+dx+14,py+11),fill=goldDim)
    d.rectangle((px+8,py+9,px+10,py+24),fill=goldDim)
    d.rectangle((px+pw-10,py+9,px+pw-8,py+24),fill=goldDim)
    if title:
        d.text((px+20,py+17),title,font=F21,fill=gold)
panel(cx,y+139,cw,115,"")
# Gold architectural ornament is illustrative; not an asset embedded in the addon.
for i in range(7):
    bx=cx+780+i*41
    d.polygon([(bx,y+242),(bx,y+193),(bx+13,y+177),(bx+26,y+193),(bx+26,y+242)],fill=(39,43,56))
d.text((cx+23,y+165),"Welcome to Forever Companion",font=F27,fill=white)
d.text((cx+24,y+211),"Your in-game companion for quests, leveling, builds and professions",font=F16,fill=muted)
# Three data panels.
cy=y+269
panel(cx,cy,323,215,"CHARACTER OVERVIEW")
panel(cx+335,cy,376,215,"QUICK ACTIONS")
panel(cx+723,cy,345,215,"PROGRESS & GOALS")
character=[find("PreviewCharacter"),find("Class:"),find("Role preference:")]
for i,value in enumerate(character):
    d.text((cx+20,cy+61+i*35),value[:36],font=F16,fill=white if i==0 else muted)
profession=find("Professions:")
if ") " in profession:
    first,second=profession.split(") ",1)
    d.text((cx+20,cy+166),first+")",font=F16,fill=muted)
    d.text((cx+20,cy+188),second[:34],font=F16,fill=muted)
else:
    d.text((cx+20,cy+166),profession[:36],font=F16,fill=muted)
quick=[("Leveling","LVL"),("Quests","QST"),("Professions","PRO"),("Diagnostics","API")]
for i,(label,abbrev) in enumerate(quick):
    bx=cx+351+(i%2)*177
    by=cy+60+(i//2)*68
    d.rounded_rectangle((bx,by,bx+164,by+55),radius=5,fill=(41,44,49),outline=goldDim)
    d.text((bx+10,by+11),abbrev,font=F13,fill=gold)
    d.text((bx+52,by+16),label,font=F13,fill=white)
def progress(py,label,value,color):
    bx=cx+743
    d.text((bx,py),label,font=F16,fill=white)
    d.text((bx+251,py),value,font=F16,fill=gold)
    d.rounded_rectangle((bx,py+26,bx+301,py+37),radius=4,fill=(57,63,73))
    frac=0.0
    percent=re.search(r"(\d+)%",value)
    count=re.search(r"(\d+)/(\d+)",value)
    if percent: frac=min(1,int(percent.group(1))/100)
    elif count and int(count.group(2)): frac=min(1,int(count.group(1))/int(count.group(2)))
    if frac>0:
        d.rounded_rectangle((bx,py+26,bx+max(3,int(301*frac)),py+37),radius=3,fill=color)
progress(cy+57,"Experience",find("50%","N/A"),(73,185,87))
progress(cy+110,"Quests ready",find("1/3","N/A"),(70,157,227))
progress(cy+163,"Materials ready",find("0/1","N/A"),(224,160,65))
# Recommended steps and manual focus checklist.
ly=y+497
panel(cx,ly,524,214,"RECOMMENDED NEXT STEPS")
panel(cx+536,ly,532,214,"TODAY'S FOCUS")
for i,prefix in enumerate(("1. ","2. ","3. ")):
    val=find(prefix,"No recommendation available")
    by=ly+55+i*46
    d.rounded_rectangle((cx+14,by,cx+510,by+41),radius=4,fill=(36,42,51),outline=goldDim,width=1)
    d.ellipse((cx+24,by+9,cx+48,by+33),outline=gold,width=2)
    d.text((cx+32,by+13),str(i+1),font=F13,fill=gold)
    d.text((cx+61,by+11),val[3:58],font=F16,fill=white)
focus=["Review active quests","Check leveling priorities","Review material goals","Check client diagnostics"]
for i,name in enumerate(focus):
    label=next((v for v in strings if name in v),name)
    yy=ly+62+i*37
    d.rectangle((cx+557,yy,cx+576,yy+19),outline=gold,width=2)
    if label.startswith("[x]"):
        d.line((cx+559,yy+9,cx+565,yy+15,cx+575,yy+3),fill=(82,212,95),width=3)
    d.text((cx+591,yy),name,font=F16,fill=white)
# Safety banner.
source=find("Quest data:","Quest data unavailable | Professions unavailable | Material goals manual")
if not source.startswith("Quest data:"):
    raise SystemExit("Dashboard snapshot missing real data provenance label")
d.rounded_rectangle((cx,y+725,cx+cw,y+790),radius=6,fill=(17,38,30),outline=(71,123,76))
d.text((cx+20,y+735),"READ-ONLY ADVISOR",font=F18,fill=(120,228,142))
d.text((cx+273,y+737),"No gameplay automation   •   Check /fcdiag for API support",font=F16,fill=white)
d.text((cx+20,y+763),source[:118],font=F13,fill=muted)
d.text((x+4,y+830),"OFFLINE MOCK-CLIENT PREVIEW — SIMULATED CHARACTER/QUEST DATA — NOT A LIVE WOW SCREENSHOT",font=F16,fill=gold)
im.save("ui_preview.png")
print("Rendered",len(rows),"mock widgets; required dashboard headings verified")
