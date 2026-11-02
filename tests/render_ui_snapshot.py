"""Illustrative mock-client dashboard preview using actual exported widget text.
Not a live WoW screenshot; native fonts, textures and anchors are approximated.
"""
import csv
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

rows=list(csv.DictReader(Path("ui_snapshot.txt").open(encoding="utf-8"),delimiter="|"))
def actual(phrase, fallback):
    for row in rows:
        if row.get("kind")=="FontString" and phrase in row.get("text",""):
            return row["text"][:100]
    return fallback

im=Image.new("RGB",(1180,800),(12,16,24))
d=ImageDraw.Draw(im)
try:
    font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",16)
    small=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",13)
    title=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",28)
    heading=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",18)
except OSError:
    font=small=title=heading=ImageFont.load_default()
gold=(226,176,83); pale=(222,224,229); muted=(150,163,182)
x,y=140,78
d.rounded_rectangle((x,y,x+900,y+620),radius=12,fill=(23,29,41),outline=(164,124,60),width=3)
d.rectangle((x+8,y+8,x+892,y+88),fill=(30,36,49))
d.rectangle((x+14,y+12,x+886,y+15),fill=gold)
d.text((x+26,y+29),actual("FOREVER COMPANION","FOREVER COMPANION"),font=title,fill=gold)
d.text((x+27,y+64),actual("Level ","Class | Level | Role"),font=small,fill=muted)
d.rounded_rectangle((x+12,y+98,x+178,y+527),radius=5,fill=(30,39,55))
d.text((x+27,y+115),"NAVIGATION",font=heading,fill=gold)
for i,name in enumerate(["Overview","Leveling","Quests","Dungeons","Professions","PvP","Settings"]):
    yy=y+153+i*43
    d.rounded_rectangle((x+23,yy,x+165,yy+35),radius=5,fill=(102,76,42) if i==0 else (44,54,70),outline=(155,120,66) if i==0 else (60,70,86))
    d.text((x+37,yy+9),name,font=small,fill=pale)
def panel(left,top,width,height,label,value):
    d.rounded_rectangle((x+left,y+top,x+left+width,y+top+height),radius=6,fill=(37,47,63),outline=(77,79,83),width=1)
    d.rectangle((x+left,y+top,x+left+width,y+top+3),fill=gold)
    d.text((x+left+17,y+top+14),label,font=heading,fill=gold)
    d.text((x+left+17,y+top+49),value[:55],font=small,fill=pale)
panel(208,116,666,92,"CHARACTER PROFILE",actual(" | Level ","Character data pending"))
panel(208,220,323,102,"QUEST JOURNAL",actual("Active quests:","Quest count pending"))
panel(543,220,331,102,"LEVELING PROGRESS",actual("XP:","XP data pending"))
d.rounded_rectangle((x+558,y+293,x+848,y+302),radius=3,fill=(73,82,93))
panel(208,334,666,118,"QUICK ACCESS","Choose a section to open your guide")
for i,label in enumerate(["QUESTS","BUILDS","CRAFTING","PVP"]):
    bx=x+225+i*157
    d.rounded_rectangle((bx,y+396,bx+143,y+428),radius=4,fill=(87,69,44),outline=gold)
    d.text((bx+14,y+404),label,font=small,fill=pale)
d.text((x+25,y+565),"READ-ONLY ADVISOR   /fc  |  v3.9 beta",font=small,fill=muted)
d.text((140,733),"OFFLINE MOCK-CLIENT PREVIEW — NOT A LIVE WOW SCREENSHOT",font=font,fill=gold)
im.save("ui_preview.png")
print("Rendered illustrative preview from",len(rows),"exported widgets")
