dofile('ForeverCompanion/GearFinder.lua')
local G=ForeverCompanionGearFinder
ForeverCompanionDB={gearFinder={weights={1,1,1,1,1,1,.5,.02},hunts={}}}
UnitLevel=function() return 30 end
local links={[1]='item:100',[11]='item:101',[12]='item:102'}
GetInventoryItemLink=function(_,slot) return links[slot] end
GetInventoryItemID=function(_,slot) local link=links[slot];return link and tonumber(link:match('item:(%d+)')) end
local function record(id,name,slot,dungeon,boss) return {itemID=id,item=name,slot=slot or 'Head',dungeon=dungeon or 'Dungeon A',boss=boss or 'Boss AlphaSentinel',status='Fixture',source='https://example.test/'..id} end
ForeverCompanionLoot={records={record(2001,'Candidate'),record(2001,'Candidate','Head','Dungeon B','Boss BetaWarden'),record(2002,'Partial candidate'),record(2003,'Ring','Finger')}}
local stats={ [100]={ITEM_MOD_STRENGTH_SHORT=5},[101]={ITEM_MOD_STRENGTH_SHORT=5},[102]={ITEM_MOD_STRENGTH_SHORT=10},
 [2001]={ITEM_MOD_STRENGTH_SHORT=20},[2002]={ITEM_MOD_STRENGTH_SHORT=30,ITEM_MOD_FIRE_DAMAGE_SHORT=10},[2003]={ITEM_MOD_STRENGTH_SHORT=15}}
local allowed={};local rule={};local counts,uses={},{}
C_PlayerInfo={CanUseItem=function(id) uses[id]=(uses[id] or 0)+1;return allowed[id]~=false end}
C_Item={GetItemInfo=function(value)
 local id=type(value)=='number' and value or tonumber(value:match('item:(%d+)'))
 return 'Item '..id,'item:'..id,3,20,1,'Armor','Cloth',1,(id==101 or id==102 or id==2003) and 'INVTYPE_FINGER' or 'INVTYPE_HEAD',nil,nil,4,1
end,GetItemStats=function(value) local id=type(value)=='number' and value or tonumber(value:match('item:(%d+)'));return stats[id] end,
GetItemCount=function(id) counts[id]=(counts[id] or 0)+1;return 0 end,
GetItemUniquenessByID=function(id) local r=rule[id];if r=='error' then error('unknown') end;return false,nil,r and r.limit,r and r.category end}
local candidates=G.Build({query='Candidate'});local row
for _,r in ipairs(candidates) do if r.record.itemID==2002 then row=r end end
assert(row and row.partial and row.delta==25 and row.rank==nil,'partial comparisons remain reviewable outside the stat-ranked items')
local positive=G.Build({upgrades=true});assert(#positive==1 and positive[1].record.itemID==2001,'partial stats excluded from strict positive filter')
allowed[2001]=false;row=G.Build({query='2001'})[1];assert(row.unusable and row.delta==nil and row.usable==false)
C_PlayerInfo.CanUseItem=function() error('missing eligibility') end;row=G.Build({query='2001'})[1];assert(row.usable==nil and not row.unusable,'unknown eligibility is not false')
C_PlayerInfo.CanUseItem=function(id) uses[id]=(uses[id] or 0)+1;return true end
row=G.Build({dungeon='Dungeon B',query='2001'})[1];assert(row.record.dungeon=='Dungeon B' and row.record.boss=='Boss BetaWarden')
assert(#G.Build({dungeon='Dungeon B',query='AlphaSentinel'})==0,'source terms respect dungeon scope')
row=G.Build({query='BetaWarden 2001'})[1];assert(row.record.boss=='Boss BetaWarden','search shows the matching source')
assert(G.RememberSource(2001,'Dungeon B','Boss BetaWarden'));assert(not G.RememberSource(2001,'Invented','Boss'))
G.Toggle(2001);assert(G.Build({saved=true})[1].record.dungeon=='Dungeon B','hunt view respects the saved source')
assert(G.SavedSource(2001).boss=='Boss BetaWarden')
local snapshot=G.Build({query='2001'})[1];stats[2001].ITEM_MOD_STRENGTH_SHORT=999
assert(snapshot.info.stats.ITEM_MOD_STRENGTH_SHORT==20,'client stat tables are copied')
G.SetWeight(1,2);local breakdown=G.Breakdown(snapshot);assert(breakdown[1].points==15,'breakdown uses the same weight snapshot as the displayed score')
stats[2001].ITEM_MOD_STRENGTH_SHORT=20;G.SetWeight(1,1)
stats[100]={};row=G.Build({query='2001'})[1];assert(row.delta==nil and G.Breakdown(row)[1].equipped==nil and G.Breakdown(row)[1].points==nil,'missing baseline is not zero in the breakdown')
stats[100]={ITEM_MOD_STRENGTH_SHORT=5}
links[1]=nil;GetInventoryItemID=function(_,slot) if slot==1 then return 100 end;return nil end
row=G.Build({query='2001'})[1];assert(row.equipmentUnknown and not row.empty and row.delta==nil,'uncached equipment link is not an empty slot')
GetInventoryItemLink=function() error('equipment scan failure') end;row=G.Build({query='2001'})[1];assert(row.equipmentUnknown and not row.empty)
GetInventoryItemLink=function(_,slot) return links[slot] end;GetInventoryItemID=function() return nil end
row=G.Build({query='2001'})[1];assert(row.empty and not row.equipmentUnknown,'confirmed empty slot identified')
links[1]='item:100';rule[2003]={category=42,limit=1};rule[101]={category=42,limit=1};rule[102]={category=43,limit=1}
local ring=G.Build({slot=0,query='2003'})[1];assert(ring.slotIndex==10 and ring.delta==10,'known category conflict excluded from alternate slot')
rule[102]='error';ring=G.Build({slot=10,query='2003'})[1];assert(ring.restrictionsUnknown and ring.delta==nil,'unknown category data does not imply the item is legal')
rule={};counts={};uses={};G.Build({slot=0,query='2003'});assert(counts[2003]==1 and uses[2003]==1,'ownership and eligibility read once across both ring slots')
local key=G.SnapshotKey({slot=0});G.SetWeight(1,3);assert(key~=G.SnapshotKey({slot=0}));key=G.SnapshotKey({slot=0});G.Invalidate();assert(key~=G.SnapshotKey({slot=0}))
assert(G.Points(.02,true)=='+0.02' and G.Points(.0001,true)=='+0.0001','small gains are not printed as +0.0')
G.SetWeight(1,.1);G.SetWeight(2,.2)
stats[100]={ITEM_MOD_STRENGTH_SHORT=3};stats[2001]={ITEM_MOD_STRENGTH_SHORT=1,ITEM_MOD_AGILITY_SHORT=1}
assert(G.Build({query='2001'})[1].delta==0,'floating-point roundoff is treated as equal')
local secret={};issecretvalue=function(v) return v==secret end
local original=C_Item.GetItemInfo
C_Item.GetItemInfo=function(...) local name,link,quality,level,required,kind,subkind,stack,equip,texture,sell,class,subclass=original(...);return name,link,secret,level,secret,kind,subkind,stack,equip,texture,sell,class,subclass end
row=G.Build({query='2001'})[1];assert(row.info.quality==nil and row.info.required==nil and row.delta==nil,'secret metadata is sanitized before arithmetic or rendering')
print('PASS: gear precision gates, scoped sources, immutable stats/weights, exact equipment states, category uncertainty and per-scan memoization')

C_Item.GetItemInfo=original;issecretvalue=nil;rule={};links[1]=nil;GetInventoryItemID=function() return 100 end
stats[2001]={ITEM_MOD_STRENGTH_SHORT=20};stats[2002]={ITEM_MOD_STRENGTH_SHORT=20}
local ranks=G.Build({query='Candidate'});assert(#ranks==2 and ranks[1].rank==1 and ranks[2].rank==1 and ranks[1].rankCount==2,'equal candidate scores share a slot-scoped rank')
assert(ranks[1].delta==nil and ranks[1].equipmentUnknown,'known candidate ranking must not invent an equipped comparison')
print('PASS: tied candidate stat ranks remain available with unknown equipped baseline')

-- Rank ordering must win over names, slot grouping and tracker pinning.
ForeverCompanionLoot.records={record(2001,'Z strongest'),record(2002,'A weaker'),record(2003,'B ring','Finger'),record(2004,'A review')}
stats[2001]={ITEM_MOD_STRENGTH_SHORT=30};stats[2002]={ITEM_MOD_STRENGTH_SHORT=10}
stats[2003]={ITEM_MOD_STRENGTH_SHORT=15};stats[2004]={UNSUPPORTED_STAT=900}
GetInventoryItemLink=function(_,slot) return links[slot] end
GetInventoryItemID=function() return nil end
local cfg=G.Settings();cfg.hunts={['2001']=true,['2002']=true,['2003']=true,['2004']=true};cfg.tracked='2002'
cfg.completed={['2001']={observed=true},['2002']={observed=true},['2003']={observed=true},['2004']={observed=true}}
for _,opts in ipairs({{slot=0},{slot=0,saved=true},{slot=0,completed=true}}) do
 local list=G.Build(opts)
 assert(list[1].record.itemID==2001 and list[2].record.itemID==2003 and list[3].record.itemID==2002 and list[4].record.itemID==2004,'all views rank #1 choices first, then #2, then manual review, regardless of alphabet or pin')
end
ForeverCompanionLoot.records[1].item='A renamed';ForeverCompanionLoot.records[2].item='Z renamed'
assert(G.Build({slot=0})[1].record.itemID==2001,'renaming cannot alter priority')
print('PASS: discover, saved and acquired lists order by ranks rather than alphabet or pin')

-- Recommendations compare gains across slots, rather than raw item score or per-slot rank.
links[1]='item:100';stats[100]={ITEM_MOD_STRENGTH_SHORT=5}
stats[101]={ITEM_MOD_STRENGTH_SHORT=14};stats[102]={ITEM_MOD_STRENGTH_SHORT=13}
local best=G.Build({slot=0,bestNow=true})
assert(#best==3 and best[1].record.itemID==2001 and best[2].record.itemID==2002 and best[3].record.itemID==2003)
assert(best[1].rank==1 and best[2].rank==2 and best[3].rank==3 and best[1].recommended)
assert(best[3].slotIndex==11 and best[3].record.boss,'alternate slot and acquisition source retained')
links[1]=nil
local emptySlot=G.Build({slot=1,bestNow=true})[1]
assert(emptySlot.empty and emptySlot.delta==emptySlot.info.score,'known empty slot uses a zero baseline for Best Now')
GetInventoryItemID=function(_,slot) return slot==1 and 100 or nil end
assert(#G.Build({slot=1,bestNow=true})==0,'an uncached equipped item is not an empty slot')
GetInventoryItemID=function() return nil end
links[1]='item:100'
rule[2001]='error'
assert(G.Build({slot=0,bestNow=true})[1].record.itemID==2002,'unverified uniqueness cannot claim first place')
C_PlayerInfo.CanUseItem=function() return nil end
assert(#G.Build({slot=0,bestNow=true})==0,'unknown eligibility stays in Browse')
print('PASS: Best Now ranks by cross-slot gain with confirmed eligibility and recorded sources')

local rows,_,_,counts=G.Build({slot=0,bestNow=true,includeReview=true})
assert(#rows>0 and counts.estimated>0 and counts.confirmed==0,'unknown use checks should surface possible gains')
for _,candidate in ipairs(rows) do assert(not candidate.recommended and not candidate.rank,'review items never inherit a confirmed rank') end
C_PlayerInfo.CanUseItem=function(id) return id~=2002 end
rows,_,_,counts=G.Build({slot=0,bestNow=true,includeReview=true})
assert(counts.confirmed>0 and rows[1].recommended,'confirmed gains stay first')
local found={}
for _,candidate in ipairs(rows) do found[candidate.record.itemID]=candidate end
assert(not found[2002] and found[2001] and found[2001].upgradeTier==2,'blocked candidates stay out and incomplete uniqueness is disclosed')
ForeverCompanionLoot.records[4]=record(2004,'Weapon for this level','Two-Hand')
local itemInfo=C_Item.GetItemInfo
C_Item.GetItemInfo=function(item)
 if item==2004 then return 'Weapon for this level','item:2004',3,42,27,'Weapon','Swords',1,'INVTYPE_2HWEAPON',123,nil,2,8 end
 return itemInfo(item)
end
local weapons=G.Build({slot=15,bestNow=true,includeReview=true})
assert(weapons[1] and weapons[1].upgradeTier==1 and not weapons[1].delta,'eligible weapons appear as inspectable without a fabricated score gain')
print('PASS: Best Now can include clearly marked possible and inspectable candidates')

-- Carried gear uses exact variants and can appear even outside the source catalog.
local carried={'item:2010:0','item:2010:17','item:2001:17','item:2011:17'}
local scanCount=0
C_Container={
 GetContainerNumSlots=function(bag) return bag==0 and #carried or 0 end,
 GetContainerItemInfo=function(_,slot) scanCount=scanCount+1;return {hyperlink=carried[slot]} end,
}
C_Item.GetItemInfo=function(item)
 if type(item)=='string' and item:find('item:2010',1,true) then
  return 'Carried upgrade',item,3,23,20,'Armor','Cloth',1,'INVTYPE_HEAD',nil,nil,4,1
 elseif item==2012 then
  return 'Misfiled boots','item:2012',3,20,10,'Armor','Cloth',1,'INVTYPE_FEET',nil,nil,4,1
 end
 return itemInfo(item)
end
local originalStats=C_Item.GetItemStats
C_Item.GetItemStats=function(item)
 if item=='item:2010:17' then return {ITEM_MOD_STRENGTH_SHORT=35}
 elseif item=='item:2010:0' then return {ITEM_MOD_STRENGTH_SHORT=5} end
 return originalStats(item)
end
rule={};C_PlayerInfo.CanUseItem=function() return true end
ForeverCompanionLoot.records={record(2012,'Misfiled boots','Head')}
local options={slot=0,bestNow=true,includeBags=true,sourceKind='bags',includeReview=true}
G.Invalidate()
local key,context=G.SnapshotKey(options)
assert(G.SnapshotKey(options)==key and scanCount==#carried,'scrolling should reuse current backpack snapshot')
local upgrades,_,_,summary=G.Build(options,context)
assert(upgrades[1].record.itemID==2010 and upgrades[1].info.link=='item:2010:17' and upgrades[1].recommended)
assert(upgrades[1].carried and upgrades[1].owned>=1 and #upgrades[1].sources==1 and summary.carried>=1)
local dungeon=G.Build({slot=7,sourceKind='dungeon'})
assert(dungeon[1].record.itemID==2012 and dungeon[1].slot[1]=='Feet')
assert(#G.Build({slot=1,sourceKind='dungeon'})==0,'client equipment slots override catalog labels')
table.remove(carried,2)
G.Invalidate()
local refreshed=G.Build({slot=1,bestNow=true,includeBags=true,sourceKind='bags',includeReview=true})
for _,row in ipairs(refreshed) do assert(row.record.itemID~=2010,'removed bag item variant must not remain an upgrade') end
print('PASS: carried gear outside the catalog, exact variants, scoped sources, bag refresh, and client slot corrections')
DPS_TEMPLATE='(%.1f damage per second)'
C_TooltipInfo={GetHyperlink=function(link)
 assert(link=='item:2004')
 return {lines={{leftText='+5 Fire Damage'},{leftText='|cffcccccc(27.4 damage per second)|r'}}}
end}
assert(G.WeaponDPS(weapons[1].info)==27.4,'read native base weapon DPS without treating it as a gear score')
DPS_TEMPLATE='(%.1f Schaden pro Sekunde)'
C_TooltipInfo.GetHyperlink=function() return {lines={{leftText='(27,4 Schaden pro Sekunde)'}}} end
assert(G.WeaponDPS({classID=2,link='item:2004'})==27.4,'use the localized tooltip format')
assert(G.WeaponDPS({classID=4,link='item:2004'})==nil,'armor never gets weapon DPS')
