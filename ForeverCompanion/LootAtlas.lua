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
  Loot.records[#Loot.records+1]=record
  return true
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
