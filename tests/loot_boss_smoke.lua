-- Run from repository root: lua5.1 tests/loot_boss_smoke.lua
dofile("ForeverCompanion/LootAtlas.lua")
local loot=ForeverCompanionLoot
local function eq(a,b,msg) assert(a==b,(msg or "mismatch")..": "..tostring(a).." vs "..tostring(b)) end
local bosses=loot.BossNames("The Deadmines")
assert(#bosses>0,"expected sourced beta boss fixtures")
for i=2,#bosses do assert(bosses[i-1]<bosses[i],"bosses sorted") end
eq(#loot.BossDrops("The Deadmines","Not a boss"),0,"unknown boss")
eq(#loot.BossDrops(nil,"Sneed"),0,"missing dungeon")
local ids={}
for _,record in ipairs(loot.records) do
  assert(type(record.itemID)=="number" and not ids[record.itemID],"unique Forever item ID required")
  assert(record.source:find("item="..record.itemID,1,true) or record.source:find("items/"..record.itemID,1,true),"item source must match ID")
  ids[record.itemID]=true
end
eq(#loot.records,127,"catalog size")
eq(#loot.DungeonNames(),9,"dungeon coverage")
local newRecords={
  ["Strike of the Hydra"]={"Blackfathom Deeps","Aku'mai",6909},
  ["Cartilage Shapers"]={"City of Dalaran","Lyn the Ignored",273054},
  ["Raptor's Gaze"]={"Excavation Site: Wetlands","Shadetooth",273027},
  ["Barbaric Crossbow"]={"Ragefire Chasm","Oggleflint",272999},
  ["Coldspire Staff"]={"Ruins of Lordaeron","Rath'mael",271215},
  ["Commander's Crest"]={"Shadowfang Keep","Commander Springvale",6320},
}
for item,expected in pairs(newRecords) do
  local record=assert(loot.Find(item))
  eq(record.dungeon,expected[1],item)
  eq(record.boss,expected[2],item)
  eq(record.itemID,expected[3],item)
  assert(record.encounterSource and not record.dropRate)
end
eq(loot.Search("  barbaric crossbow  ")[1].itemID,272999,"item search trims whitespace")
for _,boss in ipairs({"Faldrim Anvilmar","Magmatus","Plunder","Durgen Dirgehammer"}) do
  eq(#loot.BossDrops("Hall of Thanes",boss),3,"Hall of Thanes boss drops")
end
eq(loot.Find("Bandsaw Wristbands").boss,"Sneed","Bandsaw boss correction")
assert(loot.Find("Dull Sawblade").status:find("Sources disagree",1,true),"preserve encounter-phase uncertainty")
local drops=loot.BossDrops("The Deadmines","Sneed")
assert(#drops>0,"expected Sneed fixture")
local db={}
local summary=loot.BossSummary("The Deadmines","Sneed",db)
assert(summary:find("Drop chance: unknown",1,true),"unknown rate must be explicit")
assert(summary:find("\n",1,true),"summary needs real line breaks")
assert(not summary:find("\\n",1,true),"summary must not display escaped newline text")
assert(summary:find("Evidence:",1,true),"source confidence label")
assert(summary:find("Source:",1,true),"source attribution")
loot.ToggleWish(db,drops[1].item)
assert(loot.BossSummary("The Deadmines","Sneed",db):find("[WISHLIST]",1,true),"wishlist marker")
assert(loot.BossSummary("The Deadmines","Unknown",db):find("No source-attributed drops",1,true),"empty state")
local filtered=loot.Filter("","The Deadmines",false,db,"Sneed")
eq(#filtered,#drops,"boss filtered result count")
for _,item in ipairs(filtered) do
  eq(item.boss,"Sneed","boss filter isolation")
end
eq(#loot.Filter("","The Deadmines",false,db,"Unknown"),0,"unknown boss filter")
local filterSummary=loot.FilterSummary("","The Deadmines",false,db,"Sneed")
assert(filterSummary:find("Boss: Sneed",1,true),"boss filter must be visible")
local progress=loot.Progress(db,"The Deadmines","Sneed")
eq(progress.total,#drops,"progress counts boss records")
eq(progress.saved,1,"progress counts saved wishlist targets")
local progressText=loot.ProgressSummary(db,"The Deadmines","Sneed")
assert(progressText:find("saved does not mean obtained",1,true),"wishlist must not imply ownership")
eq(loot.Progress(db,"The Deadmines","Unknown").total,0,"unknown boss progress")
print("loot boss smoke: PASS")

local other={}
assert(not loot.Obtained(db,drops[1].item),'wishlist alone must never mark obtained')
assert(loot.ToggleObtained(db,drops[1].item),'manual obtained toggle')
assert(loot.Obtained(db,drops[1].item))
assert(not loot.Obtained(other,drops[1].item),'character storage isolation')
assert(loot.Wishlist(db)[drops[1].item],'obtained must preserve wishlist preference')
assert(loot.Detail(drops[1],db):find('Obtained (manual note): Yes',1,true))
assert(loot.CollectionSummary(db,'The Deadmines','Sneed'):find('1 / ',1,true))
assert(loot.CollectionSummary(db,'Unknown','Unknown'):find('0 / 0',1,true))
assert(not loot.ToggleObtained(db,'Not an item'))
assert(not loot.ToggleObtained(db,drops[1].item))
assert(not loot.Obtained(db,drops[1].item))
assert(not loot.Add({item='NaN rate',dungeon='Test',boss='Test',source='test',status='unverified',dropRate=0/0}),'reject NaN drop rates')
print('PASS: manual loot acquisition remains separate from wishes, inventory and rates')
dofile('ForeverCompanion/EncounterBrowser.lua')
local browser=ForeverCompanionEncounterBrowser
eq(#browser.Results("The Deadmines",""),#bosses,"one row per source boss")
eq(browser.Results("The Deadmines","  sNeEd  ")[1].boss,"Sneed","literal case-insensitive search")
eq(browser.Results("The Deadmines","Dull Sawblade")[1].boss,"Sneed","item search")
eq(#browser.Results("The Deadmines","%"),0,"search metacharacters are literal")
eq(#browser.Results("Unknown",""),0,"unknown dungeon empty state")
eq(#browser.Results("The Deadmines","The Deadmines"),#bosses,"dungeon search")
eq(#browser.Results("The Deadmines","Rhahk"),1,"multiple drops must not duplicate boss rows")
print('PASS: searchable boss catalog deduplication and scope')
local all=loot.Filter('', '',false,db,'')
local target=all[1]
loot.ToggleWish(db,target.item)
loot.ToggleObtained(db,target.item)
local acquired=loot.Filter('','',false,db,'','obtained')
eq(#acquired,1,'acquisition filter')
eq(acquired[1].item,target.item)
eq(#loot.Filter('','',false,db,'','outstanding'),#all-1,'outstanding filter')
eq(#loot.Filter('','',true,db,'','obtained',target.slot),1,'wishlist plus acquisition plus slot')
eq(#loot.Filter('','',true,db,'','outstanding',target.slot),0,'acquired wishlist target is no longer outstanding')
eq(#loot.Filter('','',false,db,'','obtained','Not a slot'),0,'empty combined filters')
eq(#loot.Filter('',target.dungeon,false,db,'Unknown','obtained'),0,'unknown boss remains empty with acquisition filter')
local slots=loot.SlotNames()
for i=2,#slots do assert(slots[i-1]<slots[i],'slots deduplicated and sorted') end
assert(not loot.Obtained({},target.item),'filtering never leaks acquisition across characters')
print('PASS: combined slot, acquisition, wishlist, dungeon and boss filters')

local combinedSummary=loot.FilterSummary('','',true,db,'','obtained',target.slot)
assert(combinedSummary:find('1 matching drops',1,true) and combinedSummary:find('Acquisition (manual): Obtained',1,true),'text summary must match filtered native list')

dofile('ForeverCompanion/LootExpansion.lua')
dofile('ForeverCompanion/DungeonCatalog.lua')
assert(#loot.records==256 and #loot.DungeonNames()==17,'129 new records across eight additional dungeons')
assert(#loot.BossDrops('The Stockade','Bazil Thredd')==4)
assert(loot.Find('Blackrock Harness').itemID==273805)
assert(loot.Find('Library Walkers').itemID==274294)
assert(loot.Find('Band of Crimson Light').itemID==274295)
assert(#ForeverCompanionDungeonCatalog.Names('Stockades')==1 and ForeverCompanionDungeonCatalog.Names('Stockades')[1]=='The Stockade')
assert(#ForeverCompanionDungeonCatalog.Names()>=34,'directory includes dungeons with no imported loot')
assert(#loot.BossNames('Blackmaw Hold')==0,'unknown drops must not be invented to populate the directory')
for _,record in ipairs(loot.records) do assert(not record.dropRate and record.source and record.status) end
print('PASS: expanded Forever loot, Stockades aliases, and independent dungeon directory')

assert(#browser.Results('The Stockade','Stockades')==7,'dungeon aliases also keep the matching boss list visible')
