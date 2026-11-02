"""Render a visual approximation from actual offline widget snapshot geometry.
Not an in-game screenshot; WoW textures/fonts are approximated.
"""
import csv
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SOURCE=Path("ui_snapshot.txt")
if not SOURCE.exists():
    raise SystemExit("UI snapshot not found")
rows=list(csv.DictReader(SOURCE.open(encoding="utf-8"),delimiter="|"))
W,H=1000,760
im=Image.new("RGB",(W,H),(17,21,30))
d=ImageDraw.Draw(im)
try:
    font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",14)
    heading=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",22)
except OSError:
    font=ImageFont.load_default();heading=font
x0,y0=140,95
d.rounded_rectangle((x0,y0,x0+720,y0+560),radius=10,fill=(25,32,43),outline=(170,133,64),width=2)
d.rectangle((x0+2,y0+2,x0+718,y0+96),fill=(31,38,49))
d.text((x0+20,y0+18),"FOREVER COMPANION",font=heading,fill=(242,198,106))
d.text((x0+20,y0+47),"Offline UI snapshot  |  simulated WoW client",font=font,fill=(174,184,198))
tabs=["Overview","Leveling","Quests","Dungeons","Professions","PvP","Settings"]
for i,name in enumerate(tabs):
    x=x0+20+i*97
    d.rounded_rectangle((x,y0+60,x+94,y0+88),radius=3,fill=(87,67,39) if i==0 else (44,52,65),outline=(122,104,74))
    d.text((x+6,y0+67),name,font=font,fill=(240,226,200))
d.rounded_rectangle((x0+16,y0+100,x0+704,y0+470),radius=4,fill=(20,27,37),outline=(60,70,82))
content=next((r["text"] for r in rows if r["kind"]=="FontString" and "WELCOME, ADVENTURER" in r["text"]),None)
if content:
    text=content.replace("  "," ")
    # Original UI is one large multiline fontstring, exported as a single line.
    phrases=["WELCOME, ADVENTURER","Start here:","Use Next Quest","Open Leveling","Detected class:","Displayed class:","Role preference:","Tip:","All gameplay","CRAFTING GOALS:","Client:","Modern spellbook","Modern talents:","Legacy professions:","Modern quest log:","Quest objective API:","XP read:","These checks"]
    for phrase in phrases[1:]:
        text=text.replace(phrase,"\\n"+phrase)
    lines=text.split("\\n")
    y=y0+120
    for line in lines:
        if y>y0+445: break
        d.text((x0+30,y),line[:94],font=font,fill=(230,197,131) if line.startswith(("WELCOME","CRAFTING","Client:")) else (214,218,225))
        y+=24
d.text((x0+20,y0+517),"v3.9 beta  |  Read-only guidance  |  Mock-client rendering",font=font,fill=(180,190,205))
d.text((x0,y0+583),"NOT A LIVE WOW SCREENSHOT — reconstructed from addon widget output",font=font,fill=(222,172,100))
im.save("ui_preview.png")
print("Saved ui_preview.png")
