"""Offline class-guide visualization from the addon's mocked native widget tree.
Illustrative layout only: not a live game screenshot or verified gameplay advice.
"""
import csv
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

source=Path("ui_leveling_snapshot.txt")
if not source.exists():
    raise SystemExit("Missing leveling widget snapshot")
rows=list(csv.DictReader(source.open(encoding="utf-8"),delimiter="|"))
strings=[r["text"] for r in rows if r.get("kind")=="FontString" and r.get("text")]
required=["CHARACTER & LEVELING","BUILD & ROTATION REFERENCE"]
missing=[item for item in required if item not in strings]
if missing:
    raise SystemExit("Class guide snapshot missing real widgets: "+", ".join(missing))
def find(prefix,default="Unavailable"):
    return next((s for s in strings if s.startswith(prefix)),default)
def font(size,bold=False):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans"+("-Bold" if bold else "")+".ttf",size)
    except OSError:
        return ImageFont.load_default()
small=font(14)
body=font(18)
heading=font(22,True)
title=font(38,True)
gold=(236,183,86)
dim=(138,103,50)
cream=(242,235,220)
muted=(174,184,196)
im=Image.new("RGB",(1500,950),(11,15,22))
d=ImageDraw.Draw(im)
x,y=70,58
d.rounded_rectangle((x,y,x+1360,y+810),radius=14,fill=(17,22,31),outline=dim,width=4)
d.rectangle((x+12,y+13,x+1348,y+18),fill=dim)
d.rectangle((x+14,y+24,x+1346,y+126),fill=(26,31,41))
d.ellipse((x+27,y+37,x+105,y+115),fill=(28,29,31),outline=gold,width=3)
d.line((x+49,y+59,x+66,y+72,x+85,y+59),fill=gold,width=3)
d.line((x+49,y+59,x+49,y+94,x+66,y+105,x+66,y+72),fill=gold,width=3)
d.line((x+85,y+59,x+85,y+94,x+66,y+105),fill=gold,width=3)
d.text((x+125,y+38),"FOREVER COMPANION",font=title,fill=gold)
d.text((x+126,y+92),"Class Guide  /  Leveling  /  Rotation Priorities",font=body,fill=muted)
d.text((x+1165,y+46),"BETA",font=heading,fill=gold)
navx,navy=x+15,y+140
d.rounded_rectangle((navx,navy,navx+247,navy+594),radius=6,fill=(20,26,35),outline=(86,68,43))
d.text((navx+20,navy+17),"NAVIGATION",font=heading,fill=gold)
for i,name in enumerate(["Overview","Leveling","Quests","Dungeons","Professions","PvP","Settings"]):
    yy=navy+62+i*64
    active=name=="Leveling"
    d.rounded_rectangle((navx+13,yy,navx+232,yy+51),radius=5,fill=(80,58,27) if active else (29,36,47),outline=gold if active else (63,66,73),width=2 if active else 1)
    d.ellipse((navx+28,yy+18,navx+46,yy+36),fill=gold if active else dim)
    d.text((navx+61,yy+15),name,font=body,fill=gold if active else cream)
cx=x+280
def card(px,py,w,h,label):
    d.rounded_rectangle((px,py,px+w,py+h),radius=7,fill=(25,32,43),outline=(112,87,50),width=2)
    d.rectangle((px+2,py+2,px+w-2,py+6),fill=dim)
    d.text((px+20,py+18),label,font=heading,fill=gold)
cy=y+140
card(cx,cy,520,197,"CHARACTER & LEVELING")
card(cx+534,cy,520,197,"BUILD & ROTATION REFERENCE")
d.text((cx+22,cy+70),find("Warrior  |","Class preview"),font=heading,fill=cream)
d.text((cx+22,cy+111),find("Preferred role:","Role not selected"),font=body,fill=muted)
tip=next((v for v in strings if "leveling" in v.lower() and len(v)>35 and len(v)<180),"Class-specific leveling reference")
d.text((cx+22,cy+153),tip[:51],font=small,fill=cream)
d.text((cx+555,cy+71),find("Spec preview:","Spec preview unavailable"),font=body,fill=cream)
d.text((cx+555,cy+108),find("Priority context:","Leveling"),font=body,fill=muted)
xp=find("Experience progress:","Experience unavailable")
d.text((cx+555,cy+148),xp,font=body,fill=gold)
d.rounded_rectangle((cx+555,cy+175,cx+1018,cy+184),radius=4,fill=(65,70,76))
percent=re.search(r"(\d+)%",xp)
if percent:
    fraction=min(1,int(percent.group(1))/100)
    if fraction>0:
        d.rounded_rectangle((cx+555,cy+175,cx+555+max(3,int(463*fraction)),cy+184),radius=4,fill=gold)
ry=cy+213
card(cx,ry,1054,182,"ROTATION PRIORITY")
mode=find("Rotation:","Rotation: leveling")
d.text((cx+21,ry+60),mode+"   |   General reference, not a verified optimized sequence",font=body,fill=muted)
priority=[v for v in strings if re.match(r"^[1-5]\\. ",v) and len(v)<55]
for i in range(5):
    tx=cx+20+i*207
    yy=ry+101
    d.rounded_rectangle((tx,yy,tx+193,yy+58),radius=5,fill=(68,52,31) if i==0 else (40,47,57),outline=gold if i==0 else dim)
    val=next((v for v in priority if v.startswith(str(i+1)+". ")),"Priority "+str(i+1))
    d.text((tx+13,yy+17),val[:19],font=small,fill=cream)
by=ry+198
card(cx,by,1054,179,"GUIDE DETAILS & SAFETY")
d.text((cx+22,by+66),"Explore specialization context, role notes, cooldowns and leveling guidance below.",font=body,fill=cream)
d.text((cx+22,by+105),"Priorities are illustrative. Check abilities and talents in your live client.",font=body,fill=muted)
d.text((cx+22,by+143),"Navigation and priority tiles are clickable in the actual addon.",font=small,fill=gold)
d.text((x+6,y+834),"OFFLINE MOCK-CLIENT PREVIEW  •  SIMULATED CHARACTER DATA  •  NOT A LIVE WOW SCREENSHOT",font=body,fill=gold)
im.save("ui_class_preview.png")
print("Rendered class preview from",len(rows),"mock widgets")
