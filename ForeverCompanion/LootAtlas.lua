-- Offline loot reference. Only explicit source-attributed records may be displayed.
-- The addon does not scrape sites, automate looting or invent drop percentages.
ForeverCompanionLoot = ForeverCompanionLoot or {}
local Loot=ForeverCompanionLoot
Loot.records = Loot.records or {}
Loot.sources = {
  "https://60forever.com/",
  "https://gearinsight.app/wow/en/forever/db",
  "https://endgametools.com/en/wow-forever/dungeons",
}
local function clean(value)
  return type(value)=="string" and value~="" and value or nil
end
function Loot.Add(record)
  if type(record)~="table" then return false,"invalid record" end
  if not clean(record.item) or not clean(record.dungeon) or not clean(record.boss) then
    return false,"item, dungeon and boss required"
  end
  if not clean(record.source) or not clean(record.status) then
    return false,"source and verification status required"
  end
  if record.itemID~=nil and (type(record.itemID)~="number" or record.itemID<=0 or record.itemID%1~=0) then
    return false,"invalid item ID"
  end
  if record.dropRate~=nil and (type(record.dropRate)~="number" or record.dropRate~=record.dropRate or record.dropRate<0 or record.dropRate>100) then
    return false,"invalid drop rate"
  end
  for _,existing in ipairs(Loot.records) do
    if existing.item:lower()==record.item:lower()
      and existing.dungeon:lower()==record.dungeon:lower()
      and existing.boss:lower()==record.boss:lower() then
      return false,"duplicate item, dungeon and boss"
    end
  end
  Loot.records[#Loot.records+1]=record
  return true
end
-- Forever item IDs and boss sources checked against Wowhead, 2026-11-05.
-- Sources disagree on the Dull Sawblade encounter phase. Do not claim a rate.
local deadmines="The Deadmines"
local caverns="Wailing Caverns"
local thanes="Hall of Thanes"
local drops={
  {"Bandsaw Wristbands",deadmines,"Sneed","Wrist",273293},
  {"Dull Sawblade",deadmines,"Sneed","Ranged",285292,"Sources disagree: Sneed or Sneed’s Shredder."},
  {"Ogre Loincloth",deadmines,"Rhahk'Zor","Legs",273289},
  {"First Mate Band",deadmines,"Mr. Smite","Finger",284715},
  {"Rockslicer",deadmines,"Rhahk'Zor","Two-Hand",872},
  {"Goblin Hammer",deadmines,"Gilnid","Main Hand",273297},
  {"Lookie's Spyglass",deadmines,"Cookie","Trinket",273298},
  {"Skum's Bucket",caverns,"Skum","Off Hand",273137},
  {"Rhahk'Zor's Hammer",deadmines,"Rhahk'Zor","Two-Hand",5187},
  {"Smite's Mighty Hammer",deadmines,"Mr. Smite","Two-Hand",7230},
  {"Emberstone Staff",deadmines,"Captain Greenskin","Two-Hand",5201},
  {"Cruel Barb",deadmines,"Edwin VanCleef","One-Hand",5191},
  {"Kresh's Back",caverns,"Kresh","Off Hand",13245},
  {"Robe of the Moccasin",caverns,"Lord Cobrahn","Chest",6465},
  {"Stinging Viper",caverns,"Lord Pythas","One-Hand",6472},
  {"Ephemeral Choker",thanes,"Faldrim Anvilmar","Neck",270227},
  {"Aetherwisp Bracers",thanes,"Faldrim Anvilmar","Wrist",271096},
  {"Spiritwraith Drape",thanes,"Faldrim Anvilmar","Back",271097},
  {"Kindlegem Girdle",thanes,"Magmatus","Waist",270230},
  {"Flamefist Grips",thanes,"Magmatus","Hands",270231},
  {"Fang of Magmatus",thanes,"Magmatus","Main Hand",271095},
  {"Treads of the Protector Golem",thanes,"Plunder","Feet",270229},
  {"Golemheart Stave",thanes,"Plunder","Two-Hand",270228},
  {"Golemguard Chest",thanes,"Plunder","Chest",271098},
  {"Durgen's Crescent Axe",thanes,"Durgen Dirgehammer","Main Hand",270256},
  {"Robes of the Disgraced Thane",thanes,"Durgen Dirgehammer","Chest",270261},
  {"Direhammer Leggings",thanes,"Durgen Dirgehammer","Legs",270260},
}
for _,entry in ipairs(drops) do
  Loot.Add({item=entry[1],dungeon=entry[2],boss=entry[3],slot=entry[4],
    itemID=entry[5],status=entry[6] or "Forever database match",
    source="https://www.wowhead.com/forever/item="..entry[5]})
end

-- Selected equipment from Icy Veins Forever encounter tables. Each ID links to
-- its Forever database entry. Ambiguous shared drops and unclassified slots are omitted.
local extraDrops={
  {"Blackfathom Deeps", "blackfathom-deeps", {
    {"Ghamoo-ra's Bind", "Ghamoo-ra", "Feet", 6908},
    {"Tortoise Armor", "Ghamoo-ra", "Chest", 6907},
    {"Spiked Shell Band", "Ghamoo-ra", "Finger", 273839},
    {"Naga Battle Gloves", "Lady Sarevess", "Hands", 888},
    {"Darkwater Talwar", "Lady Sarevess", "One-Hand", 11121},
    {"Naga Heartpiercer", "Lady Sarevess", "Ranged", 3078},
    {"Algae Fists", "Gelihast", "Hands", 6906},
    {"Reef Axe", "Gelihast", "Two-Hand", 6905},
    {"Cursed Murloc Eye", "Gelihast", "Trinket", 273840},
    {"Treacherous Treads", "Lorgus Jett", "Feet", 273842},
    {"Twilight Maul", "Lorgus Jett", "Two-Hand", 273841},
    {"Fallenroot Longbow", "Lorgus Jett", "Ranged", 273843},
    {"Glowing Thresher Cape", "Old Serra'kis", "Back", 6901},
    {"Bands of Serra'kis", "Old Serra'kis", "Wrist", 6902},
    {"Gaze Dreamer Pants", "Twilight Lord Kelris", "Legs", 6903},
    {"Twilight Lord Girdle", "Twilight Lord Kelris", "Waist", 273846},
    {"Rod of the Sleepwalker", "Twilight Lord Kelris", "Two-Hand", 1155},
    {"Leech Pants", "Aku'mai", "Legs", 6910},
    {"Moss Cinch", "Aku'mai", "Waist", 6911},
    {"Strike of the Hydra", "Aku'mai", "Two-Hand", 6909},
  }},
  {"City of Dalaran", "city-of-dalaran", {
    {"Graveweave Bindings", "Atrexis the Grave Knight", "Wrist", 273036},
    {"Bonebinder's Signet", "Atrexis the Grave Knight", "Finger", 273032},
    {"Gravespike Repeater", "Atrexis the Grave Knight", "Ranged", 273033},
    {"Cartilage Shapers", "Lyn the Ignored", "Hands", 273054},
    {"Bonepile Gaze", "Lyn the Ignored", "Off Hand", 273055},
    {"Ephemeral Grips", "Arcane Anomaly", "Hands", 273034},
    {"Mana-Warped Chain Shirt", "Arcane Anomaly", "Chest", 273035},
    {"Runemender's Seal", "Arcane Anomaly", "Finger", 273031},
    {"Blightleaf Rope", "Fel Ancient", "Waist", 273039},
    {"Garb of Fallen Felbark", "Fel Ancient", "Chest", 273038},
    {"Felbough Arm", "Fel Ancient", "Two-Hand", 273037},
    {"Unstable Crystalline Shoulderpads", "Unstable Sentinel", "Shoulder", 273047},
    {"Refractory Scaleguards", "Unstable Sentinel", "Legs", 273048},
    {"Slitherwrap Girdle", "Mana Devourer", "Waist", 273041},
    {"Manascale Treads", "Mana Devourer", "Feet", 273042},
    {"Spine of the Devourer", "Mana Devourer", "Two-Hand", 273040},
    {"Violet Sorcerer's Robes", "Arcanic Enigma", "Chest", 273044},
    {"Drape of Shifting Energy", "Arcanic Enigma", "Back", 273045},
    {"Wand of Mana Concentration", "Arcanic Enigma", "Ranged", 273043},
    {"Violet Sorcerer's Mantle", "Shade of the Archmage", "Shoulder", 273051},
    {"Archmagister's Faceted Pendant", "Shade of the Archmage", "Neck", 273049},
    {"Ponderous Orb", "Shade of the Archmage", "Off Hand", 273052},
  }},
  {"Excavation Site: Wetlands", "excavation-site-wetlands", {
    {"Glinteye Slippers", "Saltspine", "Feet", 273024},
    {"Supple Bellyskin Leggings", "Saltspine", "Legs", 273022},
    {"Saltscale Girdle", "Saltspine", "Waist", 273023},
    {"Garb of Florid Feathers", "Shadetooth", "Chest", 273026},
    {"Raptorclaw Greaves", "Shadetooth", "Feet", 273025},
    {"Raptor's Gaze", "Shadetooth", "Off Hand", 273027},
    {"Reliquary Mantle", "Relic Guardian", "Shoulder", 273028},
    {"Ring of Power Regulation", "Relic Guardian", "Finger", 273030},
    {"Golemsight Long Gun", "Relic Guardian", "Ranged", 273029},
  }},
  {"Ragefire Chasm", "ragefire-chasm", {
    {"Barbaric Crossbow", "Oggleflint", "Ranged", 272999},
    {"Trogg Scepter", "Oggleflint", "One-Hand", 272996},
    {"Subterranean Cape", "Taragaman the Hungerer", "Back", 14149},
    {"Crystalline Cuffs", "Taragaman the Hungerer", "Wrist", 14148},
    {"Cursed Felblade", "Taragaman the Hungerer", "One-Hand", 14145},
    {"Robe of Evocation", "Jergosh the Invoker", "Chest", 14150},
    {"Cavedweller Bracers", "Jergosh the Invoker", "Wrist", 14147},
    {"Satyrskin Cloak", "Bazzalan", "Back", 273005},
    {"Chasm Walkers", "Bazzalan", "Feet", 273007},
  }},
  {"Ruins of Lordaeron", "ruins-of-lordaeron", {
    {"Witherbite Bracers", "Witherfang", "Wrist", 271202},
    {"Atrophic Girdle", "Witherfang", "Waist", 271201},
    {"Segmented Spider Leg", "Witherfang", "Two-Hand", 271203},
    {"Leftover Abomination Skin", "The Baron", "Chest", 271206},
    {"Abomination Bones", "The Baron", "Chest", 271205},
    {"Bloodied Chestwraps", "Viktor the Vile", "Chest", 271212},
    {"Vilewalkers", "Viktor the Vile", "Feet", 271211},
    {"Vileblood Scimitar", "Viktor the Vile", "One-Hand", 271218},
    {"Rotmender's Leggings", "The Abandoned", "Legs", 271207},
    {"Grip of Fear", "The Abandoned", "Hands", 271208},
    {"Scepter of the Abandoned", "The Abandoned", "One-Hand", 271216},
    {"Tuskwrap Belt", "Bjork", "Waist", 271210},
    {"Bonerust Leggings", "Bjork", "Legs", 271209},
    {"Corpse Chopper", "Bjork", "Two-Hand", 271217},
    {"Rotmender's Treads", "Rath'mael", "Feet", 271214},
    {"Mirror of Rath'mael", "Rath'mael", "Off Hand", 271213},
    {"Coldspire Staff", "Rath'mael", "Two-Hand", 271215},
  }},
  {"Shadowfang Keep", "shadowfang-keep", {
    {"Rugged Spaulders", "Rethilgore", "Shoulder", 5254},
    {"Sorcerer Collar", "Rethilgore", "Neck", 273457},
    {"Eerie Stable Lantern", "Fel Steed", "Off Hand", 6341},
    {"Bloody Apron", "Razorclaw the Butcher", "Chest", 6226},
    {"Butcher's Cleaver", "Razorclaw the Butcher", "One-Hand", 1292},
    {"Butcher's Slicer", "Razorclaw the Butcher", "One-Hand", 6633},
    {"Silverlaine's Family Seal", "Baron Silverlaine", "Finger", 6321},
    {"Baron's Scepter", "Baron Silverlaine", "One-Hand", 6323},
    {"Blade of Silverlaine", "Baron Silverlaine", "One-Hand", 273637},
    {"Commander's Crest", "Commander Springvale", "Off Hand", 6320},
    {"Arced War Axe", "Commander Springvale", "Two-Hand", 3191},
    {"Worgenbane Talisman", "Commander Springvale", "Trinket", 273643},
    {"Blindwatcher's Sight", "Odo the Blindwatcher", "Head", 273645},
    {"Girdle of the Blindwatcher", "Odo the Blindwatcher", "Waist", 6319},
    {"Odo's Ley Staff", "Odo the Blindwatcher", "Two-Hand", 6318},
    {"Fenrus' Hide", "Fenrus the Devourer", "Back", 6340},
    {"Black Wolf Bracers", "Fenrus the Devourer", "Wrist", 3230},
    {"Half-Eaten Boots", "Fenrus the Devourer", "Feet", 273646},
    {"Wolfmaster Cape", "Wolf Master Nandos", "Back", 6314},
    {"Feline Mantle", "Wolf Master Nandos", "Shoulder", 3748},
    {"Worgpelt Leggings", "Wolf Master Nandos", "Legs", 273647},
    {"Robes of Arugal", "Archmage Arugal", "Chest", 6324},
    {"Belt of Arugal", "Archmage Arugal", "Waist", 6392},
  }},
}
for _,group in ipairs(extraDrops) do
  local encounterSource="https://www.icy-veins.com/wow-forever/"..group[2].."-guide"
  for _,entry in ipairs(group[3]) do
    Loot.Add({item=entry[1],dungeon=group[1],boss=entry[2],slot=entry[3],itemID=entry[4],
      status="Forever guide reference",source="https://db.icy-veins.com/wow-forever/items/"..entry[4],
      encounterSource=encounterSource})
  end
end

function Loot.ShowItemTooltip(owner,record)
  if not record or not GameTooltip then return end
  GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
  local ok=record.itemID and type(GameTooltip.SetHyperlink)=="function"
    and pcall(GameTooltip.SetHyperlink,GameTooltip,"item:"..record.itemID)
  if not ok then GameTooltip:SetText(record.item,1,.8,.4) end
  GameTooltip:AddLine(record.boss.." / "..record.dungeon,1,1,1,true)
  GameTooltip:AddLine(record.status,.7,.8,.9,true)
  GameTooltip:Show()
end

function Loot.ItemIcon(record)
  local api=type(C_Item)=="table" and C_Item.GetItemIconByID
  if record and record.itemID and type(api)=="function" then
    local ok,icon=pcall(api,record.itemID)
    if ok and icon then return icon end
  end
  return "Interface\\Icons\\INV_Misc_QuestionMark"
end
function Loot.Find(itemName)
  if type(itemName)~="string" then return nil end
  for _,record in ipairs(Loot.records) do
    if record.item:lower()==itemName:lower() then return record end
  end
  return nil
end
function Loot.Wishlist(db)
  if type(db)~="table" then return {} end
  if type(db.lootWishlist)~="table" then db.lootWishlist={} end
  return db.lootWishlist
end
function Loot.ToggleWish(db,itemName)
  local record=Loot.Find(itemName)
  if not record then return false,"unknown loot item" end
  local wishes=Loot.Wishlist(db)
  local key=record.item
  wishes[key]=not wishes[key] or nil
  return wishes[key]==true
end
-- Manual acquisition notes are separate from wishlist targets and inventory reads.
function Loot.Obtained(db,itemName)
  local record=Loot.Find(itemName)
  return record~=nil and type(db)=="table" and type(db.lootObtained)=="table" and db.lootObtained[record.item]==true
end
function Loot.ToggleObtained(db,itemName)
  local record=Loot.Find(itemName)
  if not record or type(db)~="table" then return false,"unknown item or character" end
  if type(db.lootObtained)~="table" then db.lootObtained={} end
  db.lootObtained[record.item]=not (db.lootObtained[record.item]==true) or nil
  return db.lootObtained[record.item]==true
end
function Loot.CollectionSummary(db,dungeon,boss)
  local total,obtained=0,0
  for _,record in ipairs(Loot.records) do
    if (not dungeon or dungeon=="" or record.dungeon==dungeon) and (not boss or boss=="" or record.boss==boss) then
      total=total+1
      if Loot.Obtained(db,record.item) then obtained=obtained+1 end
    end
  end
  return "MANUAL ACQUISITION NOTES: "..obtained.." / "..total.." catalog entries marked obtained. Not an inventory scan or complete collection."
end
function Loot.WishlistSummary(db)
  local wishes=Loot.Wishlist(db)
  local lines={"LOOT WISHLIST / PER CHARACTER"}
  local count=0
  for _,record in ipairs(Loot.records) do
    if wishes[record.item] then
      count=count+1
      lines[#lines+1]=record.item.." — "..record.boss.." ("..record.dungeon..")"
    end
  end
  if count==0 then lines[#lines+1]="No saved targets. Add a sourced item with /fc wish <item name>." end
  return table.concat(lines,"\n")
end
function Loot.Recommendations(classToken,role)
  -- Never infer class eligibility or best-in-slot from an unverified item name.
  -- Only explicit, sourced recommendation metadata may appear here.
  local results={}
  for _,record in ipairs(Loot.records) do
    if type(record.recommendedFor)=="table" and type(record.recommendationSource)=="string" then
      for _,entry in ipairs(record.recommendedFor) do
        if type(entry)=="table" and entry.class==classToken
          and (entry.role==nil or entry.role==role) then
          results[#results+1]=record
          break
        end
      end
    end
  end
  return results
end
function Loot.RecommendationSummary(classToken,role)
  local matches=Loot.Recommendations(classToken,role)
  local lines={"CLASS / ROLE GEAR SOURCES"}
  if #matches==0 then
    lines[#lines+1]="No source-backed upgrade recommendations for this class and role yet."
    lines[#lines+1]="Item drops below are not automatically best-in-slot or usable by your class."
  else
    for _,record in ipairs(matches) do
      lines[#lines+1]=record.item.." — "..record.boss.." / "..record.dungeon
      lines[#lines+1]="Recommendation source: "..record.recommendationSource
    end
  end
  return table.concat(lines,"\n")
end
function Loot.Search(query)
  local results={}
  local term=type(query)=="string" and query:lower():match("^%s*(.-)%s*$") or ""
  for _,record in ipairs(Loot.records) do
    if term=="" or tostring(record.item):lower():find(term,1,true)
      or tostring(record.boss):lower():find(term,1,true)
      or tostring(record.dungeon):lower():find(term,1,true) then
      results[#results+1]=record
    end
  end
  return results
end
function Loot.Detail(record,db)
  if type(record)~="table" then return "Select a loot result to inspect its source." end
  local saved=Loot.Wishlist(db)[record.item]==true
  local lines={
    "ITEM DETAIL / "..record.item,
    "Dungeon: "..record.dungeon,
    "Boss: "..record.boss,
    "Verification: "..record.status,
    "Reference: "..record.source,
    "Wishlist: "..(saved and "Saved" or "Not saved"),
    "Obtained (manual note): "..(Loot.Obtained(db,record.item) and "Yes" or "Not marked").."; not checked against inventory.",
  }
  if clean(record.encounterSource) then lines[#lines+1]="Encounter reference: "..record.encounterSource end
  if clean(record.slot) then lines[#lines+1]="Equipment slot: "..record.slot end
  if type(record.itemLevel)=="number" then lines[#lines+1]="Item level: "..record.itemLevel end
  if clean(record.rarity) then lines[#lines+1]="Rarity: "..record.rarity end
  if clean(record.requiredLevel) then lines[#lines+1]="Required level: "..record.requiredLevel end
  if type(record.stats)=="table" then
    for _,stat in ipairs(record.stats) do
      if type(stat)=="string" then lines[#lines+1]=stat end
    end
  end
  if type(record.dropRate)=="number" then
    lines[#lines+1]="Reported drop rate: "..record.dropRate.."% (source methodology must be checked)"
  else
    lines[#lines+1]="Drop chance: unknown / not verified"
  end
  lines[#lines+1]="Class/spec suitability: not verified unless explicitly documented."
  return table.concat(lines,"\n")
end
function Loot.CountByDungeon()
  local counts={}
  for _,record in ipairs(Loot.records) do
    counts[record.dungeon]=(counts[record.dungeon] or 0)+1
  end
  return counts
end
function Loot.CatalogSummary()
  local counts=Loot.CountByDungeon()
  local names={}
  for name in pairs(counts) do names[#names+1]=name end
  table.sort(names)
  local lines={"BOSS DROP COVERAGE / FOREVER"}
  for _,name in ipairs(names) do
    lines[#lines+1]=name..": "..counts[name].." sourced records"
  end
  lines[#lines+1]="This is not a complete dungeon loot table."
  return table.concat(lines,"\n")
end
function Loot.Filter(query, dungeon, savedOnly, db, boss, acquisition, slot)
  local matches=Loot.Search(query)
  local results={}
  local wishes=savedOnly and Loot.Wishlist(db) or nil
  for _,record in ipairs(matches) do
    if (not dungeon or dungeon=="" or record.dungeon==dungeon)
      and (not boss or boss=="" or record.boss==boss)
      and (not savedOnly or wishes[record.item])
      and (not slot or slot=="" or record.slot==slot)
      and (acquisition~="outstanding" or not Loot.Obtained(db,record.item))
      and (acquisition~="obtained" or Loot.Obtained(db,record.item)) then
      results[#results+1]=record
    end
  end
  table.sort(results,function(a,b)
    if a.dungeon~=b.dungeon then return a.dungeon<b.dungeon end
    if a.boss~=b.boss then return a.boss<b.boss end
    return a.item<b.item
  end)
  return results
end
function Loot.FilterSummary(query,dungeon,savedOnly,db,boss,acquisition,slot)
  local matches=Loot.Filter(query,dungeon,savedOnly,db,boss,acquisition,slot)
  local wishes=Loot.Wishlist(db)
  local saved=0
  for _,record in ipairs(matches) do
    if wishes[record.item] then saved=saved+1 end
  end
  local lines={
    "ACTIVE FILTERS / "..#matches.." matching drops",
    "Search: "..(type(query)=="string" and query~="" and query or "All items and bosses"),
    "Dungeon: "..(type(dungeon)=="string" and dungeon~="" and dungeon or "All dungeons"),
    "Boss: "..(type(boss)=="string" and boss~="" and boss or "All bosses"),
    "Wishlist only: "..(savedOnly and "On" or "Off"),
    "Saved in results: "..saved,
    "Slot: "..(slot and slot~="" and slot or "All"),
    "Acquisition (manual): "..(acquisition=="obtained" and "Obtained" or (acquisition=="outstanding" and "Not marked" or "All")),
  }
  return table.concat(lines,"\n")
end
function Loot.DungeonNames()
  local counts=Loot.CountByDungeon()
  local names={}
  for name in pairs(counts) do names[#names+1]=name end
  table.sort(names)
  return names
end
function Loot.FormatMatches(matches)
  local lines={"MATCHING BOSS DROPS / "..#matches}
  if #matches==0 then
    lines[#lines+1]="No matching records. Try a different dungeon or turn off wishlist-only."
  end
  for i,record in ipairs(matches) do
    lines[#lines+1]=i..". "..record.item.." | "..record.boss.." / "..record.dungeon
    lines[#lines+1]="Status: "..record.status.." | Source: "..record.source
  end
  return table.concat(lines,"\n")
end
function Loot.Format(query)
  local lines={"LOOT ATLAS / FOREVER", "Source-attributed dungeon and boss drops only.",
    "Beta data may change. A reported drop is not a confirmed drop rate.",
    "Search fields: item, dungeon or boss; records can be added from documented sources."}
  local matches=Loot.Search(query)
  if #matches==0 then
    lines[#lines+1]="No source-reviewed boss drops have been imported into this addon build."
    lines[#lines+1]="Do not mistake historical Classic loot for verified Forever loot."
  end
  for _,item in ipairs(matches) do
    lines[#lines+1]=item.item.." | "..item.dungeon.." / "..item.boss
    lines[#lines+1]="Status: "..item.status.." | Source: "..item.source
    if clean(item.slot) then lines[#lines+1]="Slot: "..item.slot end
    if type(item.itemLevel)=="number" then lines[#lines+1]="Item level: "..item.itemLevel end
    if type(item.dropRate)=="number" then lines[#lines+1]="Reported rate: "..item.dropRate.."% (source methodology required)" end
  end
  return table.concat(lines,"\n")
end

-- Boss-first navigation for players who know the dungeon but not the item name.
-- This is deliberately a read-only index of attributed records, not a complete loot table.
function Loot.BossNames(dungeon)
  local seen, names = {}, {}
  for _, record in ipairs(Loot.records) do
    if (not dungeon or dungeon=="" or record.dungeon==dungeon) and not seen[record.boss] then
      seen[record.boss]=true
      names[#names+1]=record.boss
    end
  end
  table.sort(names)
  return names
end

function Loot.BossDrops(dungeon,boss)
  local matches={}
  if type(dungeon)~="string" or dungeon=="" or type(boss)~="string" or boss=="" then
    return matches
  end
  for _,record in ipairs(Loot.records) do
    if record.dungeon==dungeon and record.boss==boss then
      matches[#matches+1]=record
    end
  end
  table.sort(matches,function(a,b) return a.item<b.item end)
  return matches
end

function Loot.BossSummary(dungeon,boss,db)
  local matches=Loot.BossDrops(dungeon,boss)
  local lines={"BOSS LOOT / "..tostring(boss or "Unknown"),
    "Dungeon: "..tostring(dungeon or "Unknown"),
    "Records: "..#matches.." (not necessarily complete)"}
  if #matches==0 then
    lines[#lines+1]="No source-attributed drops are recorded for this boss."
  end
  local wishes=Loot.Wishlist(db)
  for _,record in ipairs(matches) do
    lines[#lines+1]=(wishes[record.item] and "[WISHLIST] " or "")..record.item
    lines[#lines+1]="Evidence: "..record.status
    lines[#lines+1]="Source: "..record.source
    lines[#lines+1]="Drop chance: "..(type(record.dropRate)=="number" and
      (tostring(record.dropRate).."% reported; methodology unverified") or "unknown")
  end
  return table.concat(lines,"\n")
end

-- A compact, evidence-aware collection tracker. Counts unique recorded items only;
-- it never implies that a dungeon has a complete loot table.
function Loot.Progress(db,dungeon,boss)
  local wishes=Loot.Wishlist(db)
  local total,saved=0,0
  for _,record in ipairs(Loot.records) do
    if (not dungeon or dungeon=="" or record.dungeon==dungeon)
      and (not boss or boss=="" or record.boss==boss) then
      total=total+1
      if wishes[record.item] then saved=saved+1 end
    end
  end
  return {total=total,saved=saved}
end
function Loot.ProgressSummary(db,dungeon,boss)
  local progress=Loot.Progress(db,dungeon,boss)
  local scope=type(boss)=="string" and boss~="" and boss
    or (type(dungeon)=="string" and dungeon~="" and dungeon or "All recorded dungeons")
  return "WISHLIST TARGETS / "..scope..": "..progress.saved.." of "..progress.total
    .." recorded drops saved (catalog may be incomplete; saved does not mean obtained)"
end


-- Options come from the attributed catalog; never infer equipment eligibility.
function Loot.SlotNames()
 local seen,names={},{}
 for _,record in ipairs(Loot.records) do
  if clean(record.slot) and not seen[record.slot] then seen[record.slot]=true;names[#names+1]=record.slot end
 end
 table.sort(names)
 return names
end
