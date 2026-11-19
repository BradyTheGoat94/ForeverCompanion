for _,module in ipairs({'LootAtlas','LootExpansion','DungeonCatalog','BossMechanics','DungeonReference','EncounterBrowser'}) do dofile('ForeverCompanion/'..module..'.lua') end
local D,M,L,R,E=ForeverCompanionDungeonCatalog,ForeverCompanionBossMechanics,ForeverCompanionLoot,ForeverCompanionDungeonReference,ForeverCompanionEncounterBrowser
assert(#D.Names()==34,'no duplicate dungeon identities or extra combined-wing directories')
local seen,total,documented,pending={golden=true},0,0,0
for _,d in ipairs(D.Names()) do
 local c=R.Coverage(d);assert(c.bosses>0 and c.loot>0,d..' must account for encounters and loot')
 assert(c.bosses==c.documented+c.none+c.pending)
 for _,b in ipairs(M.Names(d)) do
  local r=M.Get(d,b);assert(r.source:match('^https://') and r.reviewed)
  local text=M.Format(d,b);local _,quotes=text:gsub('"DONT BE LIKE DRYST"','')
  if #r.mechanics>0 then assert(quotes==1 and text:find(r.mechanics[#r.mechanics],1,true)<text:find(M.quote,1,true))
  else assert(quotes==0,'no Easter egg on undocumented/no-ability/trash entries') end
  if r.state=='pending' then assert(text:find('not yet documented',1,true)) end
 end
 total=total+c.bosses;documented=documented+c.documented;pending=pending+c.pending
end
for _,r in ipairs(L.records) do
 assert(D.entries[r.dungeon],'every loot record uses an existing directory identity')
 assert(M.Get(r.dungeon,r.boss),'every loot source has an encounter or source guide state')
 local identity=r.dungeon..'/'..r.boss..'/'..r.item:lower();assert(not seen[identity],'no duplicate drop identity');seen[identity]=true
 assert(not r.dropRate and r.source and r.status)
 if not r.itemID then assert(r.status:find('item ID not corroborated',1,true)) end
end
assert(#L.records>1900 and documented>230 and pending>0,'known gaps stay honest')
assert(M.Get('The Stockade','Bruegal Ironknuckle (Rare)')==M.Get('The Stockade','Bruegal Ironknuckle'))
assert(#L.BossDrops('The Stockade','Bruegal Ironknuckle (Rare)')==#L.BossDrops('The Stockade','Bruegal Ironknuckle'))
assert(M.Get('Krol’dok Stronghold','Handler Ashka')==M.Get('Krol’dok Stronghold','War Handler Ashka'))
assert(M.Get('Uldaman','Olaf')==M.Get('Uldaman','The Lost Dwarves'))
assert(#E.Results('Blackrock Depths',"Doom'rel")==1,'grouped encounter aliases remain searchable')
assert(not M.Get('Upper Blackrock Spire','Highlord Omokk') and not M.Get('Lower Blackrock Spire','General Drakkisath'),'Spire wings stay distinct')
assert(M.Get('Shaper’s Terrace','Nanaya').mechanics[1]:find('15%-yard'))
assert(M.Get('Upper Blackrock Spire','Solakar Flamewreath').basis:find('Classic',1,true))
print('PASS: 34 dungeon coverage, '..total..' encounter entries, '..documented..' mechanics guides, '..pending..' explicitly unresolved; '..#L.records..' attributed loot records, aliases, wing scope and quote placement')

for name in pairs(ForeverCompanionDungeonCatalog.entries) do
 local point=assert(ForeverCompanionDungeonCatalog.Approach(name),name)
 assert(point.map>0 and point.x>0 and point.x<1 and point.y>0 and point.y<1 and point.source,name)
end
local dungeonMap=ForeverCompanionDungeonCatalog
assert(#dungeonMap.MapLocations(1423)==2,'both Stratholme gates are mapped')
assert(dungeonMap.MapLocations(2548)[1].approximate,'unconfirmed Riverglades entrance is labeled as an area')

local originalMapAPI=C_Map
local parentMaps={[1423]=1415,[1415]=947,[1444]=1414,[1414]=947}
C_Map={
 GetMapInfo=function(map) return {parentMapID=parentMaps[map]} end,
 GetMapRectOnMap=function(map,parent)
  if parentMaps[map]==parent then return .2,.6,.3,.7 end
 end,
}
local eastern=dungeonMap.MapLocations(1415)
assert(#eastern==2 and eastern[1].map==1423 and eastern[2].map==1423,'only child-map dungeons appear on the continent')
assert(math.abs(eastern[1].displayX-(.2+.4*eastern[1].x))<1e-9,'continent pin uses zone bounds')
assert(#dungeonMap.MapLocations(947)==5,'world view includes both continents')
assert(#dungeonMap.MapLocations(1423)==2 and dungeonMap.MapLocations(1423)[1].displayX==dungeonMap.MapLocations(1423)[1].x,'zone pins retain source coordinates')
C_Map=originalMapAPI

for name in pairs(D.entries) do assert(D.LevelRange(name),name..' needs a suggested level range') end
assert(D.LevelRange('The Deadmines')=='18-23')
assert(D.LevelRange('Stratholme: Service Gate')==D.LevelRange('Stratholme'))
