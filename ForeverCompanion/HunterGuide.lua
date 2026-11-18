-- Original Hunter field guide over an attributed, pinned MIT reference snapshot.
local H={};ForeverCompanionHunterGuide=H
local D=ForeverCompanionHunterData
local function secret(v) return issecretvalue and issecretvalue(v) end
local function finite(v) return not secret(v) and type(v)=='number' and v==v and math.abs(v)<math.huge end
local function read(fn,...) if type(fn)~='function' then return end;local ok,a,b,c,d,e=pcall(fn,...);if ok then return not secret(a) and a or nil,not secret(b) and b or nil,not secret(c) and c or nil,not secret(d) and d or nil,not secret(e) and e or nil end end
local function text(s) return not secret(s) and type(s)=='string' and s or '' end
H.Read=read;H.Finite=finite
function H.Settings()
 ForeverCompanionDB=ForeverCompanionDB or {};local cfg=ForeverCompanionDB.hunterJournal
 if type(cfg)~='table' then cfg={} end
 if type(cfg.favorites)~='table' then cfg.favorites={} end
 if type(cfg.sightings)~='table' then cfg.sightings={} end
 if type(cfg.snapshots)~='table' then cfg.snapshots={} end
 local snapshots={}
 for _,pet in ipairs(cfg.snapshots) do
  if #snapshots>=12 then break end
  if type(pet)=='table' and text(pet.name)~='' then
   pet.name=text(pet.name):sub(1,80);pet.family=text(pet.family):sub(1,80);pet.savedAt=text(pet.savedAt):sub(1,40)
   local actions={};for _,name in ipairs(type(pet.actions)=='table' and pet.actions or {}) do if #actions>=10 then break end;if text(name)~='' then actions[#actions+1]=text(name):sub(1,100) end end;pet.actions=actions
   for _,key in ipairs({'level','health','maximum','armor','low','high','speed','dps'}) do if not finite(pet[key]) or pet[key]<0 then pet[key]=nil end end
   snapshots[#snapshots+1]=pet
  end
 end
 cfg.snapshots=snapshots
 ForeverCompanionDB.hunterJournal=cfg;return cfg
end
local digits={};local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
for i=1,#alphabet do digits[alphabet:sub(i,i)]=i-1 end
function H.Decode(packed)
 if type(packed)~='string' or #packed%3~=0 then return {},false end
 local result,seen={},{}
 for i=1,#packed,3 do
  local a,b,c=digits[packed:sub(i,i)],digits[packed:sub(i+1,i+1)],digits[packed:sub(i+2,i+2)]
  if not a or not b or not c then return {},false end
  local n=a*4096+b*64+c;local x,y=math.floor(n/501),n%501
  if x>500 or y>500 then return {},false end
  local key=x..':'..y;if not seen[key] then seen[key]=true;result[#result+1]={x=x/500,y=y/500} end
 end
 return result,true
end
local taught,displays,npcs,abilities,families,trainers
function H.Index()
 if npcs then return end
 taught={};displays={};npcs={};abilities={};families={};trainers={}
 for family,f in pairs(D.TameableFamilies) do families[#families+1]={name=family,record=f} end
 if not D.TameableFamilies['Core Hound'] then families[#families+1]={name='Core Hound',record={foods={'Meat'},referenceOnly=true}} end
 for key,a in pairs(D.TameableAbilities) do
  abilities[#abilities+1]={key=key,name=a.name,record=a}
  for _,rank in ipairs(a.ranks) do for _,id in ipairs(rank.npc_ids or {}) do
   taught[id]=taught[id] or {};taught[id][#taught[id]+1]={key=key,name=a.name,ability=a,rank=rank}
  end end
 end
 -- These are native interval references, not promises of transferable skills.
 local intervals={{1.0,7,1263110},{1.2,6,1263109},{1.3,5,1263107},{1.4,4,1263104},{1.5,3,1263102},{1.6,2,1263100},{1.7,1,1263099},{2.5,2,1263113},{2.7,3,1263114}}
 for _,tier in ipairs(intervals) do
  local key='interval-'..tier[1];local name=(tier[1]<2 and 'Faster Attack' or 'Slower Attack')..' / '..tier[1]..' sec reference'
  local rank={rank=tier[2],spell_id=tier[3],npc_ids={}}
  local a={name=name,passive=true,interval=true,learned_by={},ranks={rank}}
  for id,npc in pairs(D.TameableNPCs) do if npc.speed==tier[1] and not D.TameableHidden[id] then
   rank.npc_ids[#rank.npc_ids+1]=id;taught[id]=taught[id] or {};taught[id][#taught[id]+1]={key=key,name=name,ability=a,rank=rank}
  end end
  abilities[#abilities+1]={key=key,name=name,record=a}
 end
 for _,looks in pairs(D.TameableLooks) do for _,look in ipairs(looks) do for _,id in ipairs(look.npcs) do displays[id]=displays[id] or {};displays[id][#displays[id]+1]={display=look.display,name=look.name} end end end
 for id,npc in pairs(D.TameableNPCs) do if not D.TameableHidden[id] then npcs[#npcs+1]={id=id,name=npc.name,record=npc} end end
 for id,t in pairs(D.TameableTrainers) do trainers[#trainers+1]={id=id,name=t.name,record=t} end
 local function sort(list) table.sort(list,function(a,b) if a.name~=b.name then return a.name<b.name end;return (a.id or 0)<(b.id or 0) end) end
 sort(npcs);sort(abilities);sort(families);sort(trainers)
 for _,list in pairs(taught) do table.sort(list,function(a,b) if a.name~=b.name then return a.name<b.name end;return a.rank.rank<b.rank.rank end) end
end
function H.Abilities(id) H.Index();return taught[id] or {} end
function H.Looks(id) H.Index();return displays[id] or {} end
function H.Level(npc) return finite(npc.min) and (tostring(npc.min)..(npc.max and npc.max~=npc.min and ('–'..npc.max) or '')) or 'Unknown' end
local zoneCache,zoneAPI={},nil
function H.Zones(npc)
 local api=C_Map and C_Map.GetAreaInfo
 if api~=zoneAPI then zoneAPI=api;zoneCache={} end
 if zoneCache[npc] then return zoneCache[npc] end
 local zones={}
 for _,id in ipairs(npc.zones or {}) do local name=C_Map and read(C_Map.GetAreaInfo,id);zones[#zones+1]=type(name)=='string' and name or ('Area #'..id) end
 local result=#zones>0 and table.concat(zones,', ') or 'Zone not documented';zoneCache[npc]=result;return result
end
function H.Speed(npc) return finite(npc.speed) and string.format('%.1f sec',npc.speed) or 'Unknown' end
local roles={
 ['Bear']={'Solo tank','Swipe adds multi-target pressure; plan threat and healing for extra enemies.'},
 ['Boar']={'Solo tank','Charge helps engage and reconnect; a practical leveling option when its utility suits your pulls.'},
 ['Turtle']={'Solo tank','Shell Shield is a defensive cooldown; useful when survival matters more than burst.'},
 ['Cat']={'Damage','A damage-focused option with Prowl. Compare skills, happiness and survival rather than speed alone.'},
 ['Wind Serpent']={'Damage','Lightning Breath provides ranged magic damage; value depends on focus use and enemy defenses.'},
 ['Raptor']={'Damage','Savage Rend provides a bleed option. Confirm ranks and effects against your client tooltip.'},
 ['Wolf']={'Group utility','Furious Howl supports party melee attacks; usefulness depends on party composition and the current spell effect.'},
 ['Spider']={'Control','Web can help control movement. Confirm current family restrictions and cooldowns.'},
 ['Hyena']={'Control','Tendon Rip provides a movement slow for keeping contact or helping control a pull.'},
 ['Crab']={'Control','Pinch provides movement control; choose it for that tool rather than a universal DPS ranking.'},
 ['Bat']={'Control','Sonic Blast offers caster-focused utility; inspect the current rank in the game.'},
 ['Bird of Prey']={'Control','Mine! provides weapon-disarm utility where the target can be disarmed.'},
 ['Carrion Bird']={'Group utility','Demoralizing Screech provides an enemy debuff; coordinate debuffs with your group.'},
 ['Tallstrider']={'Group utility','Dust Cloud adds a debuff option; usefulness depends on the current encounter and effect.'},
 ['Gorilla']={'Solo tank','Thunderstomp offers area pressure. Manage extra enemies and pet survival carefully.'},
 ['Fox']={'Control','Trickster’s Dance offers a short mobility/avoidance window. Check the current tooltip.'},
 ['Scorpid']={'Damage','Scorpid Poison adds a damage-over-time option; value depends on rank, focus use and encounter length.'},
 ['Crocolisk']={'Damage','Dismember adds a family attack option. Confirm the current effect before comparing damage.'},
}
H.roles=roles
-- Tamed Pet Passive modifiers, Forever client 1.60.1.70938.
-- https://wow-forever.gg/pets/ ; values are damage, health, armor.
H.familyModifiers={
 Bat={7,0,0},Bear={-9,8,5},['Bird of Prey']={7,0,0},Boar={-10,4,9},
 ['Carrion Bird']={0,0,5},Cat={10,-2,0},['Core Hound']={1,5,0},Crab={-5,-4,13},
 Crocolisk={0,-5,10},Fox={0,0,5},Gorilla={2,4,0},Hyena={0,0,5},
 Raptor={10,-5,3},Scorpid={-6,0,10},Spider={7,0,0},Tallstrider={0,5,0},
 Turtle={-10,0,13},['Wind Serpent']={7,0,0},Wolf={0,0,5},
}
function H.FamilyStats(family)
 local m=H.familyModifiers[family]
 return m and string.format('Damage %+d%%   Health %+d%%   Armor %+d%%',m[1],m[2],m[3]) or 'Family modifiers unavailable'
end
function H.FamilyPreview(family)
 H.Index()
 local fallback
 for _,beast in ipairs(npcs) do
  if beast.record.family==family then
   fallback=fallback or beast
   if #H.Looks(beast.id)>0 then return beast end
  end
 end
 return fallback
end
function H.Build(view,options)
 H.Index();options=options or {};local result={};local query=text(options.query):lower();local level=read(UnitLevel,'player');local zone=text(read(GetRealZoneText));local faction=text(read(UnitFactionGroup,'player')):lower()
 local cfg=H.Settings()
 local source=view=='families' and families or view=='abilities' and abilities or view=='trainers' and trainers or npcs
 for _,entry in ipairs(source) do
  local r=entry.record;local match=true;local extra=''
  if view~='families' and view~='abilities' and view~='trainers' then
   local role=roles[r.family];extra=(r.family or '')..' '..H.Zones(r)..' '..(role and role[1] or '')
   for _,ability in ipairs(H.Abilities(entry.id)) do extra=extra..' '..ability.name..' '..ability.rank.rank end
   if options.family and options.family~='' and r.family~=options.family then match=false end
   if options.role and options.role~='' and (not role or role[1]~=options.role) then match=false end
   if options.level and (not finite(level) or not finite(r.min) or r.min>level) then match=false end
   if options.zone and (zone=='' or not H.Zones(r):lower():find(zone:lower(),1,true)) then match=false end
   if options.rare and r.class~='Rare' and r.class~='Rare Elite' then match=false end
   if options.favorites and not cfg.favorites[tostring(entry.id)] then match=false end
   if options.seen and type(cfg.sightings[tostring(entry.id)])~='table' then match=false end
   if options.ability then
    local teaches=false
    for _,a in ipairs(H.Abilities(entry.id)) do
     if a.key==options.ability and (not options.rank or a.rank.rank==options.rank) then teaches=true;break end
    end
    match=match and teaches
   end
  elseif view=='trainers' then extra=(r.zone or '')..' '..(r.side or '');if options.faction and r.side~=faction and r.side~='neutral' then match=false end end
  for term in query:gmatch('%S+') do if not (entry.name..' '..tostring(entry.id or '')..' '..extra):lower():find(term,1,true) then match=false end end
  if match then result[#result+1]=entry end
 end
 return result
end
function H.RecordTarget()
 local guid=text(read(UnitGUID,'target'))
 local id=tonumber(guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-'))
 local npc=id and D.TameableNPCs[id]
 if not npc or D.TameableHidden[id] then return false,'Target a beast listed in the Field Guide.' end
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 local position=map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if position then x,y=read(function() return position:GetXY() end) end
 if not finite(map) or map<=0 or not finite(x) or not finite(y) or x<0 or x>1 or y<0 or y>1 then
  return false,'Your map position is unavailable.'
 end
 local sightings=H.Settings().sightings
 local key=tostring(id)
 if not sightings[key] then
  local count=0;for _ in pairs(sightings) do count=count+1 end
  if count>=800 then return false,'Field notes are full.' end
 end
 sightings[key]={map=map,x=x,y=y,level=read(UnitLevel,'target')}
 return true,'Recorded '..npc.name..' at your current position.',id
end
function H.Points(id,trainer)
 local r=trainer and D.TameableTrainers[id] or D.TameableNPCs[id];local result={}
 if not r or not trainer and D.TameableHidden[id] then return result end
 local function add(map,x,y,observed)
  local info=C_Map and read(C_Map.GetMapInfo,map)
  if finite(map) and map>0 and finite(x) and finite(y) and x>=0 and x<=1 and y>=0 and y<=1 and type(info)=='table' and type(info.name)=='string' and (info.mapType==3 or info.mapType==4 or info.mapType==5) then
   result[#result+1]={map=map,x=x,y=y,label=r.name,source=observed and 'Your field sighting' or ('TrueshotLodge MIT reference '..D.revision:sub(1,7)),observed=observed,reference=true,entityID=id,zone=info.name}
  end
 end
 if trainer then for _,p in ipairs(r.coords or {}) do add(r.ui_map_id,p.x/100,p.y/100) end
 else for map,packed in pairs(r.maps or {}) do local points,valid=H.Decode(packed);if valid then for _,p in ipairs(points) do add(map,p.x,p.y) end end end end
 if not trainer then
  local sighting=H.Settings().sightings[tostring(id)]
  if type(sighting)=='table' and finite(sighting.map) then add(sighting.map,sighting.x,sighting.y,true) end
 end
 table.sort(result,function(a,b) if a.observed~=b.observed then return a.observed==true end;if a.map~=b.map then return a.map<b.map end;if a.x~=b.x then return a.x<b.x end;return a.y<b.y end)
 return result
end
function H.Navigate(id,point,trainer)
 if type(point)~='table' then return false,'Choose a recorded location.' end
 for _,fresh in ipairs(H.Points(id,trainer)) do
  if fresh.map==point.map and math.abs(fresh.x-point.x)<.000001 and math.abs(fresh.y-point.y)<.000001 and point.entityID==id then return true,ForeverCompanionQuestWaypoints.Navigate(fresh,true,fresh.label) end
 end
 return false,'Location or identity changed. Reopen the map menu.'
end
function H.LivePet()
 if read(UnitExists,'pet')~=true then return nil end
 local p={name=text(read(UnitName,'pet')),family=text(read(UnitCreatureFamily,'pet')),level=read(UnitLevel,'pet'),health=read(UnitHealth,'pet'),maximum=read(UnitHealthMax,'pet')}
 local armor,effective=read(UnitArmor,'pet');p.armor=finite(effective) and effective or armor
 local low,high=read(UnitDamage,'pet');local speed=read(UnitAttackSpeed,'pet')
 if finite(low) and finite(high) and low>=0 and high>=low then p.low,p.high=low,high end
 if finite(speed) and speed>0 then p.speed=speed;if p.low then p.dps=(p.low+p.high)/2/speed end end
 p.actions={}
 for slot=1,10 do local name=read(GetPetActionInfo,slot);if type(name)=='string' and name~='' then p.actions[#p.actions+1]=name end end
 for _,field in ipairs({'level','health','maximum','armor'}) do if not finite(p[field]) then p[field]=nil end end
 return p
end
function H.SavePet()
 local pet=H.LivePet();if not pet then return false,'No readable active pet. Summon your pet and retry outside restricted states.' end
 local snapshots=H.Settings().snapshots;pet.savedAt=type(date)=='function' and date('%Y-%m-%d %H:%M') or 'This session'
 table.insert(snapshots,1,pet);while #snapshots>12 do table.remove(snapshots) end
 return true,'Saved a pet snapshot. It is not a live stable scan.'
end
