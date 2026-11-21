-- Dungeon identity is independent of partial loot imports.
-- New dungeon bands: Blizzard article 24301455. Returning dungeon directory:
-- https://www.wowhead.com/forever/guide/dungeons-overview-locations-details
local D={entries={}}
ForeverCompanionDungeonCatalog=D
local function add(name,zone,low,high,source,aliases)
 D.entries[name]={name=name,zone=zone,low=low,high=high,source=source,aliases=aliases}
end
local official='https://news.blizzard.com/en-us/article/24301455/explore-the-new-dungeons-of-world-of-warcraft-forever'
for _,r in ipairs({
 {'Hall of Thanes','Dun Morogh',13,18},{'Ruins of Lordaeron','Tirisfal Glades',15,20},
 {'Excavation Site: Wetlands','Wetlands',24,29},{'City of Dalaran','Alterac Mountains',28,33},
 {'The Drowned City','Stranglethorn Vale',35,40},{'Krol’dok Stronghold','Riverglades',40,45},
 {'Alcaz Prison','Dustwallow Marsh',48,53},{'Blackmaw Hold','Azshara',55,60},{'Shaper’s Terrace','Un’Goro Crater',58,60},
}) do add(r[1],r[2],r[3],r[4],official) end
local directory='https://www.wowhead.com/forever/guide/dungeons-overview-locations-details'
for _,r in ipairs({
 {'Ragefire Chasm','Orgrimmar',13,18},{'The Deadmines','Westfall',18,23},{'Wailing Caverns','The Barrens',15,25},
 {'Shadowfang Keep','Silverpine Forest',22,30},{'Blackfathom Deeps','Ashenvale',24,32},
 {'The Stockade','Stormwind City',22,30},{'Gnomeregan','Dun Morogh',29,38},{'Razorfen Kraul','The Barrens',30,40},
 {'Scarlet Monastery: Graveyard','Tirisfal Glades',28,38},{'Scarlet Monastery: Library','Tirisfal Glades',29,39},
 {'Scarlet Monastery: Armory','Tirisfal Glades',32,42},{'Scarlet Monastery: Cathedral','Tirisfal Glades',35,45},
 {'Razorfen Downs','The Barrens',40,50},{'Uldaman','Badlands',42,52},{"Zul'Farrak",'Tanaris',44,54},
 {'Maraudon','Desolace',45,57},{"Temple of Atal'Hakkar",'Swamp of Sorrows',50,60},
 {'Blackrock Depths','Blackrock Mountain',52,60},{'Lower Blackrock Spire','Blackrock Mountain',55,60},
 {'Upper Blackrock Spire','Blackrock Mountain',58,60},{'Dire Maul: East','Feralas',58,60},
 {'Dire Maul: West','Feralas',58,60},{'Dire Maul: North','Feralas',58,60},{'Scholomance','Western Plaguelands',58,60},
 {'Stratholme','Eastern Plaguelands',58,60},
}) do add(r[1],r[2],r[3],r[4],directory) end
D.entries["Temple of Atal'Hakkar"].aliases='sunken temple'
D.entries['Maraudon'].aliases='wicked grotto foulspore cavern earth song falls'
D.entries['Krol’dok Stronghold'].aliases="krol'dok stronghold kroldok"
D.entries['Shaper’s Terrace'].aliases="shaper's terrace shapers terrace"
D.entries['The Stockade'].aliases='stockades stormwind stockade stockade'
function D.Names(query)
 local term=type(query)=='string' and query:lower():match('^%s*(.-)%s*$') or ''
 local names,seen={},{}
 for name,entry in pairs(D.entries) do
  if term=='' or (name..' '..entry.zone..' '..(entry.aliases or '')):lower():find(term,1,true) then names[#names+1]=name;seen[name]=true end
 end
 -- Also retain future sourced imports that have not yet gained metadata.
 for _,name in ipairs(ForeverCompanionLoot and ForeverCompanionLoot.DungeonNames() or {}) do
  if not seen[name] and (term=='' or name:lower():find(term,1,true)) then names[#names+1]=name end
 end
 table.sort(names);return names
end
-- Both Stratholme approaches lead to the same instance.
function D.JournalName(name)
 return name=='Stratholme: Service Gate' and 'Stratholme' or name
end
function D.LevelRange(name)
 local e=D.entries[D.JournalName(name)]
 if e and e.low and e.high then return ('%d-%d'):format(e.low,e.high) end
end
function D.Summary(name)
 local e=D.entries[name]
 if not e then return 'Dungeon reference · confirm access in game' end
 local range=D.LevelRange(name)
 return e.zone..(range and (' · suggested '..e.low..'–'..e.high) or '')
end

-- Outdoor approach references, not interior portal or boss coordinates.
local approaches={
 ["Zul'Farrak"]={map=1446,x=.387,y=.199,zone='Tanaris',source='https://azeroth.wiki/forever/map/tanaris/zul-farrak'},
 Maraudon={map=1443,x=.291,y=.629,zone='Desolace',source='https://azeroth.wiki/forever/map/desolace/maraudon'},
 ['The Deadmines']={map=1436,x=.382,y=.775,zone='Westfall',source='https://azeroth.wiki/forever/map/westfall/deadmines'},

 Uldaman={map=1418,x=.352,y=.103,zone='Badlands',source='https://azeroth.wiki/forever/map/badlands/uldaman'},
}
local mapGuide='https://mmonster.co/wow-forever/tools/world-map?d=hall-of-thanes'
local entranceGroups={
 {1455,'Ironforge',27.8,47.9,'Hall of Thanes'},
 {1454,'Orgrimmar',53,48.9,'Ragefire Chasm'},
 {1420,'Tirisfal Glades',63.1,67.5,'Ruins of Lordaeron'},
 {1413,'The Barrens',47.7,35,'Wailing Caverns'},
 {1421,'Silverpine Forest',44.7,67.8,'Shadowfang Keep'},
 {1440,'Ashenvale',14.5,14.6,'Blackfathom Deeps'},
 {1437,'Wetlands',47.8,56.3,'Excavation Site: Wetlands'},
 {1453,'Stormwind City',50.4,66.2,'The Stockade'},
 {1416,'Alterac Mountains',8.8,59.6,'City of Dalaran'},
 {1426,'Dun Morogh',24,40,'Gnomeregan'},
 {1413,'The Barrens',42.3,89.9,'Razorfen Kraul'},
 {1420,'Tirisfal Glades',85.1,31.4,'Scarlet Monastery: Graveyard','Scarlet Monastery: Library','Scarlet Monastery: Armory','Scarlet Monastery: Cathedral'},
 {1434,'Stranglethorn Vale',21.4,27.9,'The Drowned City'},
 {1413,'The Barrens',50.9,92.9,'Razorfen Downs'},
 {1445,'Dustwallow Marsh',75.5,13.7,'Alcaz Prison'},
 {1435,'Swamp of Sorrows',70.2,52.3,"Temple of Atal'Hakkar"},
 {1428,'Burning Steppes',22.6,7.5,'Blackrock Depths'},
 {1444,'Feralas',64.9,29.4,'Dire Maul: East'},
 {1447,'Azshara',34.9,23.8,'Blackmaw Hold'},
 {1428,'Burning Steppes',33,25.2,'Lower Blackrock Spire','Upper Blackrock Spire'},
 {1444,'Feralas',62.9,24.9,'Dire Maul: North'},
 {1444,'Feralas',60.3,31.8,'Dire Maul: West'},
 {1422,'Western Plaguelands',69,72.7,'Scholomance'},
 {1449,'Un’Goro Crater',48.1,6.1,'Shaper’s Terrace'},
 {1423,'Eastern Plaguelands',26.5,10.4,'Stratholme'},
}
for _,r in ipairs(entranceGroups) do
 for i=5,#r do approaches[r[i]]={map=r[1],zone=r[2],x=r[3]/100,y=r[4]/100,source=mapGuide} end
end
approaches['Krol’dok Stronghold']={map=2548,zone='Riverglades',x=.44,y=.27,approximate=true,
 source='https://undying.app/zones/riverglades'}
local function mapNumber(n)
 return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge
end
local function project(map,x,y,target)
 if map==target then return x,y end
 local api=C_Map
 if not api or not api.GetMapInfo or not api.GetMapRectOnMap then return end
 local seen={}
 while map~=target do
  if seen[map] then return end
  seen[map]=true
  local ok,info=pcall(api.GetMapInfo,map)
  if not ok or (issecretvalue and issecretvalue(info)) or type(info)~='table' then return end
  local parent=info.parentMapID
  if not mapNumber(parent) or parent<=0 then return end
  local valid,left,right,top,bottom=pcall(api.GetMapRectOnMap,map,parent)
  if not valid or not (mapNumber(left) and mapNumber(right) and mapNumber(top) and mapNumber(bottom))
   or left>=right or top>=bottom then return end
  x=left+(right-left)*x;y=top+(bottom-top)*y;map=parent
 end
 if x>=0 and x<=1 and y>=0 and y<=1 then return x,y end
end
function D.MapLocations(mapID)
 local groups,byPoint={},{}
 local function addPoint(name,point)
  local x,y=project(point.map,point.x,point.y,mapID)
  if not x then return end
  local key=point.map..':'..point.x..':'..point.y
  local group=byPoint[key]
  if not group then
   group=point;group.displayX=x;group.displayY=y;group.names={}
   byPoint[key]=group;groups[#groups+1]=group
  end
  group.names[#group.names+1]=name
 end
 for _,name in ipairs(D.Names()) do
  local point=D.Approach(name)
  if point then addPoint(name,point) end
 end
 addPoint('Stratholme: Service Gate',{map=1423,x=.419,y=.158,zone='Eastern Plaguelands',source=mapGuide})
 return groups
end
function D.Approach(name)
 local p=approaches[name]
 if not p then return nil end
 return {map=p.map,x=p.x,y=p.y,zone=p.zone,source=p.source,approximate=p.approximate,reference=true,kind='dungeon approach'}
end
function D.Navigate(name)
 local target=D.Approach(name)
 if not target then return 'Entrance location is unavailable.' end
 if target.approximate then return 'The map shows the dungeon area. The exact entrance is unconfirmed.' end
 return ForeverCompanionQuestWaypoints.Navigate(target,true,name..' approach')
end
