"""Illustrative black-and-gold previews derived from the actual mocked UI widget text.
These are NOT screenshots from a running World of Warcraft client.
"""
import csv
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

GOLD=(232,180,79)
MUTED=(164,176,194)
PALE=(233,229,217)
def font(size,bold=False):
    name="/usr/share/fonts/truetype/dejavu/DejaVuSans"
    try:
        return ImageFont.truetype(name+("-Bold" if bold else "")+".ttf",size)
    except OSError:
        return ImageFont.load_default()
F14,F17,F21,F28,F35=font(14),font(17),font(21,True),font(28,True),font(35,True)
def read_rows(path):
    return list(csv.DictReader(Path(path).open(encoding="utf-8"),delimiter="|"))
def read(path):
    return [r["text"] for r in read_rows(path) if r.get("text")]
def find(strings,prefix,default="Unavailable"):
    return next((s for s in strings if s.startswith(prefix)),default)
def draw_base(section):
    im=Image.new("RGB",(1500,930),(12,15,22))
    d=ImageDraw.Draw(im)
    x,y=72,54
    d.rounded_rectangle((x,y,x+1356,y+807),radius=13,fill=(17,21,30),outline=(143,105,52),width=4)
    d.rectangle((x+13,y+12,x+1342,y+17),fill=(185,131,48))
    d.text((x+42,y+35),"FOREVER COMPANION",font=F35,fill=GOLD)
    d.text((x+44,y+84),"Leveling   /   Quest Journal   /   Professions   /   Builds",font=F17,fill=MUTED)
    d.text((x+1140,y+44),"BETA",font=F17,fill=GOLD)
    d.rounded_rectangle((x+14,y+136,x+256,y+730),radius=6,fill=(22,28,39),outline=(84,69,47))
    d.text((x+35,y+155),"NAVIGATION",font=F21,fill=GOLD)
    for i,name in enumerate(("Overview","Leveling","Quests","Dungeons","Professions","PvP","Settings")):
        yy=y+207+i*67
        active=name==section
        d.rounded_rectangle((x+25,yy,x+243,yy+54),radius=5,fill=(78,56,28) if active else (31,39,50),outline=GOLD if active else (73,76,81),width=2 if active else 1)
        d.text((x+46,yy+16),name,font=F17,fill=GOLD if active else PALE)
    cx=x+276
    d.rounded_rectangle((cx,y+136,cx+1064,y+204),radius=5,fill=(31,39,52),outline=(106,85,52))
    d.text((cx+23,y+153),section.upper()+" GUIDE",font=F28,fill=GOLD)
    d.text((cx+23,y+189),"Live API data when available; no automated gameplay",font=F14,fill=MUTED)
    d.text((x+10,y+833),"OFFLINE MOCK-CLIENT PREVIEW  |  SIMULATED CHARACTER AND QUEST DATA  |  NOT A LIVE WOW SCREENSHOT",font=F17,fill=GOLD)
    return im,d,x,y,cx
def panel(d,x,y,w,h,title):
    d.rounded_rectangle((x,y,x+w,y+h),radius=7,fill=(25,33,45),outline=(109,86,49),width=2)
    d.rectangle((x+3,y+3,x+w-3,y+7),fill=(146,104,47))
    d.text((x+21,y+22),title,font=F21,fill=GOLD)
def line(d,x,y,value,limit=66,color=PALE):
    d.text((x,y),value[:limit],font=F17,fill=color)
def bar(d,x,y,width,fraction,color):
    d.rounded_rectangle((x,y,x+width,y+12),radius=4,fill=(64,70,80))
    if fraction is not None and fraction>0:
        d.rounded_rectangle((x,y,x+max(3,int(width*min(1,fraction))),y+12),radius=4,fill=color)
def quest_preview():
    rows=read_rows("ui_quest_snapshot.txt")
    strings=[r["text"] for r in rows if r.get("text")]
    for heading in ("JOURNAL AT A GLANCE","FOCUSED OBJECTIVE"):
        if heading not in strings:
            raise SystemExit("Quest snapshot missing real UI heading: "+heading)
    im,d,x,y,cx=draw_base("Quests")
    top=y+223
    panel(d,cx,top,517,210,"JOURNAL AT A GLANCE")
    panel(d,cx+529,top,535,210,"FOCUSED OBJECTIVE")
    count=next((s for s in strings if re.match(r"^\d+ active\s+\d+ ready",s) or " cached quests" in s),"Quest scan unavailable")
    if count=="Quest scan unavailable" and any(s.startswith("Live quest-log snapshot") for s in strings):
        raise SystemExit("Active quest summary not found in captured UI strings")
    line(d,cx+23,top+78,count,49)
    line(d,cx+23,top+119,find(strings,"Top zone:","No zone data"),52,MUTED)
    line(d,cx+23,top+177,find(strings,"Live quest-log snapshot","Quest-log status unavailable"),55,GOLD)
    match=re.search(r"(\d+) active\s+(\d+) ready",count)
    frac=int(match.group(2))/int(match.group(1)) if match and int(match.group(1)) else None
    bar(d,cx+23,top+148,466,frac,(224,163,64))
    line(d,cx+552,top+78,find(strings,"Sample:","No focused quest"),53)
    line(d,cx+552,top+118,find(strings,"Ready to turn in",find(strings,"In progress","No quest status")),52,MUTED)
    line(d,cx+552,top+157,find(strings,"Illustrative objective","Objective unavailable"),50,GOLD)
    lower=top+225
    panel(d,cx,lower,1064,263,"ACTIVE QUEST JOURNAL")
    line(d,cx+23,lower+65,"Choose a quest to update the focus card; use filter and paging to explore.",100,MUTED)
    # Use the actual native row widget hierarchy, not a fabricated list of
    # hard-coded sample quests. Each visible row has title/zone/status children.
    children={}
    for widget in rows:
        children.setdefault(widget.get("parent"),[]).append(widget)
    quest_rows=[]
    for widget in rows:
        if widget.get("kind")!="Button" or widget.get("visible")!="1":
            continue
        labels=[item.get("text","") for item in children.get(widget["id"],[])
                if item.get("kind")=="FontString"]
        if len(labels)>=3 and labels[2] in ("READY","ACTIVE"):
            quest_rows.append((labels[0],labels[1],labels[2]))
    if not quest_rows:
        raise SystemExit("Native quest journal rows missing from UI snapshot")
    for i,(title,zone,status) in enumerate(quest_rows[:6]):
        yy=lower+103+i*35
        d.rounded_rectangle((cx+20,yy-4,cx+1042,yy+29),radius=3,fill=(34,43,55))
        line(d,cx+36,yy,title,59)
        line(d,cx+650,yy,zone,22,MUTED)
        line(d,cx+899,yy,status,12,GOLD if status=="READY" else MUTED)
    im.save("ui_quest_preview.png")
    print("Quest preview generated from",len(strings),"widget strings")
def profession_preview():
    strings=read("ui_profession_snapshot.txt")
    for heading in ("PROFESSION SKILLS","MATERIAL GOALS"):
        if heading not in strings:
            raise SystemExit("Profession snapshot missing real UI heading: "+heading)
    im,d,x,y,cx=draw_base("Professions")
    top=y+223
    panel(d,cx,top,517,210,"PROFESSION SKILLS")
    panel(d,cx+529,top,535,210,"MATERIAL GOALS")
    line(d,cx+22,top+73,find(strings,"2 detected","Profession scan unavailable"),51,MUTED)
    skill_strings=[s for s in strings if re.search(r"\d+/\d+$",s) and ("Blacksmithing" in s or "Mining" in s)]
    for i,value in enumerate(skill_strings[:2]):
        yy=top+105+i*48
        line(d,cx+23,yy,value,50)
        m=re.search(r"(\d+)/(\d+)$",value)
        frac=int(m.group(1))/int(m.group(2)) if m and int(m.group(2)) else None
        bar(d,cx+23,yy+24,455,frac,(74,174,119))
    line(d,cx+550,top+77,find(strings,"Guide:","Guide not selected"),52)
    status=find(strings,"0/1 material goals","No manual material goals")
    line(d,cx+550,top+116,status,53,MUTED)
    m=re.search(r"(\d+)/(\d+)",status)
    frac=int(m.group(1))/int(m.group(2)) if m and int(m.group(2)) else None
    bar(d,cx+550,top+143,466,frac,(220,166,70))
    line(d,cx+550,top+175,find(strings,"6 units remaining","Counts entered manually"),50,GOLD)
    lower=top+225
    panel(d,cx,lower,1064,263,"PROFESSION HANDBOOK & MATERIAL CHECKLIST")
    line(d,cx+23,lower+66,"Choose a profession to see general guidance and manage your manual materials.",105,MUTED)
    handbook=[name for name in ("Alchemy","Blacksmithing","Enchanting","Engineering","Herbalism","Leatherworking","Mining","Skinning","Tailoring") if name in strings]
    for i,name in enumerate(handbook):
        bx=cx+22+(i%5)*202
        by=lower+105+(i//5)*60
        d.rounded_rectangle((bx,by,bx+186,by+46),radius=4,fill=(48,50,49),outline=(123,96,54))
        d.text((bx+12,by+14),name,font=F14,fill=PALE)
    line(d,cx+23,lower+225,"Recipe and material quantities are manual planning data, not a verified game database.",100,GOLD)
    im.save("ui_profession_preview.png")
    print("Profession preview generated from",len(strings),"widget strings")
def adventure_preview(section,slug):
    rows=read_rows("ui_"+slug+"_snapshot.txt")
    strings=[r["text"] for r in rows if r.get("text")]
    heading="PVP PREPARATION" if section=="PvP" else "DUNGEON PREPARATION"
    for required in (heading,"CLASS & ROLE GUIDANCE","OPEN CLASS GUIDE","OPEN QUEST JOURNAL"):
        if required not in strings:
            raise SystemExit(slug+" preview missing real native widget: "+required)
    progressText=next((v for v in strings if re.match(r"^\\d+/\\d+ preparation tasks marked complete$",v)),None)
    if not progressText:
        raise SystemExit(slug+" preview missing actual manual progress")
    children={}
    for widget in rows:
        children.setdefault(widget.get("parent"),[]).append(widget)
    taskRows=[]
    for widget in rows:
        if widget.get("kind")!="Button" or widget.get("visible")!="1":
            continue
        labels=[w.get("text","") for w in children.get(widget["id"],[])
                if w.get("kind")=="FontString"]
        if len(labels)>=3 and labels[-1] in ("DONE","TODO"):
            taskRows.append((labels[0],labels[1],labels[-1]))
    if len(taskRows)!=4:
        raise SystemExit(slug+" preview needs four actual clickable checklist tiles; got "+str(len(taskRows)))
    im,d,x,y,cx=draw_base(section)
    top=y+223
    panel(d,cx,top,517,212,heading)
    panel(d,cx+529,top,535,212,"CLASS & ROLE GUIDANCE")
    line(d,cx+23,top+75,progressText,51)
    line(d,cx+23,top+113,find(strings,"Next:","No next task"),54,MUTED)
    m=re.match(r"(\\d+)/(\\d+)",progressText)
    frac=int(m.group(1))/int(m.group(2)) if m and int(m.group(2)) else None
    bar(d,cx+23,top+147,466,frac,(230,174,75))
    line(d,cx+23,top+177,find(strings,"Manual checklist only","Manual planning"),52,GOLD)
    role=next((v for v in strings if re.search(r"\\s\\|\\s",v) and "Warrior" in v),"Class and role unavailable")
    line(d,cx+552,top+76,role,55)
    line(d,cx+552,top+112,"Read-only class guidance; verify game-specific abilities.",57,MUTED)
    for i,name in enumerate(("OPEN CLASS GUIDE","OPEN QUEST JOURNAL")):
        bx=cx+552+i*232
        by=top+157
        d.rounded_rectangle((bx,by,bx+215,by+36),radius=4,fill=(70,54,33),outline=GOLD)
        d.text((bx+11,by+11),name,font=F14,fill=PALE)
    lower=top+227
    panel(d,cx,lower,1064,268,"MANUAL PREPARATION CHECKLIST")
    line(d,cx+23,lower+60,"Click a tile in game to mark a preparation task; progress is saved per character.",100,MUTED)
    for i,(number,title,status) in enumerate(taskRows):
        col=i%2;row=i//2
        bx=cx+20+col*524
        by=lower+95+row*78
        d.rounded_rectangle((bx,by,bx+505,by+66),radius=5,
                            fill=(53,48,35) if status=="DONE" else (34,43,56),
                            outline=GOLD if status=="DONE" else (101,83,52),width=2)
        d.ellipse((bx+14,by+18,bx+42,by+46),outline=GOLD,width=2)
        d.text((bx+23,by+23),number,font=F14,fill=GOLD)
        d.text((bx+57,by+22),title[:39],font=F17,fill=PALE)
        d.text((bx+425,by+24),status,font=F14,fill=GOLD if status=="DONE" else MUTED)
    im.save("ui_"+slug+"_preview.png")
    print(section,"preview generated from",len(strings),"widget strings and",len(taskRows),"real task buttons")

quest_preview()
profession_preview()
adventure_preview("Dungeons","dungeon")
adventure_preview("PvP","pvp")
