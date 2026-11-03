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
  if record.dropRate~=nil and (type(record.dropRate)~="number" or record.dropRate<0 or record.dropRate>100) then
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
-- Community beta observations, not guaranteed live drops or drop chances.
-- Source: 60forever.com (beta records checked 2026-09-24).
local betaDrops={
  {"Bandsaw Wristbands","The Deadmines","Sneed's Shredder","Wrist",21},
  {"Dull Sawblade","The Deadmines","Sneed","Ranged",21},
  {"Ogre Loincloth","The Deadmines","Rhahk'Zor","Legs",22},
  {"First Mate Band","The Deadmines","Mr. Smite","Finger",22},
  {"Rockslicer","The Deadmines","Rhahk'Zor","Two-Hand",23},
  {"Goblin Hammer","The Deadmines","Gilnid","Main Hand",23},
  {"Lookie's Spyglass","The Deadmines","Cookie","Trinket",23},
  {"Skum's Bucket","Wailing Caverns","Skum","Off Hand",22},
}
for _,entry in ipairs(betaDrops) do
  Loot.Add({item=entry[1],dungeon=entry[2],boss=entry[3],slot=entry[4],
    itemLevel=entry[5],status="Community beta report; unverified in live client",
    source="https://60forever.com/"})
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
  local term=type(query)=="string" and query:lower() or ""
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
  }
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
  local lines={"BOSS DROP COVERAGE / COMMUNITY BETA"}
  for _,name in ipairs(names) do
    lines[#lines+1]=name..": "..counts[name].." sourced records"
  end
  lines[#lines+1]="This is not a complete dungeon loot table."
  return table.concat(lines,"\n")
end
function Loot.Filter(query, dungeon, savedOnly, db)
  local matches=Loot.Search(query)
  local results={}
  local wishes=savedOnly and Loot.Wishlist(db) or nil
  for _,record in ipairs(matches) do
    if (not dungeon or dungeon=="" or record.dungeon==dungeon)
      and (not savedOnly or wishes[record.item]) then
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
function Loot.FilterSummary(query,dungeon,savedOnly,db)
  local matches=Loot.Filter(query,dungeon,savedOnly,db)
  local wishes=Loot.Wishlist(db)
  local saved=0
  for _,record in ipairs(matches) do
    if wishes[record.item] then saved=saved+1 end
  end
  local lines={
    "ACTIVE FILTERS / "..#matches.." matching drops",
    "Search: "..(type(query)=="string" and query~="" and query or "All items and bosses"),
    "Dungeon: "..(type(dungeon)=="string" and dungeon~="" and dungeon or "All dungeons"),
    "Wishlist only: "..(savedOnly and "On" or "Off"),
    "Saved in results: "..saved,
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
