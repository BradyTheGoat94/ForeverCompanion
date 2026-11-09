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
 {'Ragefire Chasm','Orgrimmar'},{'The Deadmines','Westfall'},{'Wailing Caverns','The Barrens'},
 {'Shadowfang Keep','Silverpine Forest'},{'Blackfathom Deeps','Ashenvale'},
 {'The Stockade','Stormwind City'},{'Gnomeregan','Dun Morogh'},{'Razorfen Kraul','The Barrens'},
 {'Scarlet Monastery: Graveyard','Tirisfal Glades'},{'Scarlet Monastery: Library','Tirisfal Glades'},
 {'Scarlet Monastery: Armory','Tirisfal Glades'},{'Scarlet Monastery: Cathedral','Tirisfal Glades'},
 {'Razorfen Downs','The Barrens'},{'Uldaman','Badlands'},{"Zul'Farrak",'Tanaris'},
 {'Maraudon','Desolace'},{"Temple of Atal'Hakkar",'Swamp of Sorrows'},
 {'Blackrock Depths','Blackrock Mountain'},{'Lower Blackrock Spire','Blackrock Mountain'},
 {'Upper Blackrock Spire','Blackrock Mountain'},{'Dire Maul: East','Feralas'},
 {'Dire Maul: West','Feralas'},{'Dire Maul: North','Feralas'},{'Scholomance','Western Plaguelands'},
 {'Stratholme','Eastern Plaguelands'},
}) do add(r[1],r[2],nil,nil,directory) end
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
function D.Summary(name)
 local e=D.entries[name]
 if not e then return 'Dungeon reference · confirm access in game' end
 return e.zone..(e.low and (' · suggested '..e.low..'–'..e.high) or '')
end
