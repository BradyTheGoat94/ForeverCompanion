-- Independent gear research and transparent, user-adjustable stat budgets.
local G={requested={},loadQueue={},interested={},revision=0,metrics={builds=0,itemReads=0,ownershipReads=0}}
ForeverCompanionGearFinder=G
G.slots={{'Head',1},{'Neck',2},{'Shoulder',3},{'Chest',5},{'Waist',6},{'Legs',7},{'Feet',8},{'Wrist',9},{'Hands',10},{'Finger',11},{'Finger',12},{'Trinket',13},{'Trinket',14},{'Back',15},{'Main Hand',16},{'Off Hand',17},{'Ranged',18}}
G.stats={{'Strength','ITEM_MOD_STRENGTH_SHORT'},{'Agility','ITEM_MOD_AGILITY_SHORT'},{'Intellect','ITEM_MOD_INTELLECT_SHORT'},{'Stamina','ITEM_MOD_STAMINA_SHORT'},{'Spirit','ITEM_MOD_SPIRIT_SHORT'},{'Spell power','ITEM_MOD_SPELL_POWER_SHORT'},{'Attack power','ITEM_MOD_ATTACK_POWER_SHORT'},{'Armor','RESISTANCE0_NAME'},
 {'Healing power','ITEM_MOD_SPELL_HEALING_DONE_SHORT'},{'Mana / 5 sec','ITEM_MOD_MANA_REGENERATION_SHORT'},{'Hit rating','ITEM_MOD_HIT_RATING_SHORT'},{'Crit rating','ITEM_MOD_CRIT_RATING_SHORT'},{'Haste rating','ITEM_MOD_HASTE_RATING_SHORT'},{'Defense rating','ITEM_MOD_DEFENSE_SKILL_RATING_SHORT'},{'Dodge rating','ITEM_MOD_DODGE_RATING_SHORT'},{'Block rating','ITEM_MOD_BLOCK_RATING_SHORT'},
 {'Expertise rating','ITEM_MOD_EXPERTISE_RATING_SHORT'},{'Ranged attack power','ITEM_MOD_RANGED_ATTACK_POWER_SHORT'},
 {'Block value','ITEM_MOD_BLOCK_VALUE_SHORT'},{'Parry rating','ITEM_MOD_PARRY_RATING_SHORT'},
 {'Holy damage','ITEM_MOD_HOLY_DAMAGE_SHORT'},{'Fire damage','ITEM_MOD_FIRE_DAMAGE_SHORT'},{'Frost damage','ITEM_MOD_FROST_DAMAGE_SHORT'},
 {'Arcane damage','ITEM_MOD_ARCANE_DAMAGE_SHORT'},{'Shadow damage','ITEM_MOD_SHADOW_DAMAGE_SHORT'},{'Nature damage','ITEM_MOD_NATURE_DAMAGE_SHORT'},
 {'Spell damage','ITEM_MOD_SPELL_DAMAGE_DONE_SHORT'}}
local originalStatCount=16
G.presets={Balanced={1,1,1,1,1,1,.5,.02},Strength={2,.5,0,1,0,0,1,.02},Agility={.5,2,0,1,0,0,1,.02},Caster={0,0,2,1,1,2,0,0},Survival={.5,.5,0,2,0,0,0,.1},Healer={0,0,1.5,1,1,0,0,0,2,2}}
-- Editable leveling estimates informed by WoW Forever guide priorities.
-- See GearStats.lua for the per-spec source references. These values are
-- authored defaults. Hit caps, weapon DPS and effects require separate review.
local specProfiles={
 WARRIOR={Arms={2,.5,0,.6,0,0,1,.02,0,0,0,1.4},Fury={2,.7,0,.6,0,0,1,.02,0,0,0,1.6},
  Protection={.6,1,0,2,0,0,.25,.09,0,0,0,0,0,1.2,1.4,.8}},
 ROGUE={Combat={.7,2,0,.6,0,0,1,.02,0,0,0,1.4,1},
  Assassination={.65,2,0,.6,0,0,1,.02,0,0,0,1.3,1.3},Subtlety={.8,2,0,.6,0,0,1,.02,0,0,0,1.5,1}},
 HUNTER={Marksmanship={.2,2,.6,.7,0,0,1,.02,0,0,0,1.2},
  ["Beast Mastery"]={.1,2,.55,.8,0,0,1,.03,0,0,0,1.2},Survival={.9,2,.5,.8,0,0,1,.02,0,0,0,1.3}},
 MAGE={Frost={0,0,.9,.5,.45,2,0,0,0,.5,0,1.2},
  Fire={0,0,.85,.5,.4,2,0,0,0,.35,0,1.5,1},Arcane={0,0,1.25,.5,.6,2,0,0,0,.6,0,1.2,1}},
 WARLOCK={Affliction={0,0,.5,.8,.3,2,0,0,0,0,0,1.2,1},
  Demonology={0,0,.55,.8,.3,2,0,0,0,0,0,1.2,1},Destruction={0,0,.6,.7,.3,2,0,0,0,0,0,1.5,1}},
 SHAMAN={Elemental={.3,0,.9,.5,.45,2,0,0,0,0,0,1.3,1.6},
  Enhancement={1.5,.8,1.4,.65,.15,.8,.75,.02,0,0,0,1,1.1},Restoration={0,0,1,.5,.7,0,0,0,2,1,0,1.4,1.2}},
 PALADIN={Holy={0,0,1.4,.5,.8,0,0,0,2,1,0,.5},
  Protection={.55,.5,.7,2,0,1.1,.25,.09,0,0,0,0,0,1.1,1,.9},Retribution={1.1,.65,1,.6,0,1.2,.6,.02,0,0,0,.85,.7}},
 PRIEST={Discipline={0,0,.9,.5,1.2,0,0,0,2,1.5,0,.5},
  Holy={0,0,1.2,.5,1,0,0,0,2,1.3,0,.65},Shadow={0,0,.95,.65,.55,2,0,0,0,0,0,1.5}},
 DRUID={Feral={1.4,2,0,.7,0,0,.7,.02,0,0,0,1.4},
  Balance={0,0,.95,.5,.55,2,0,0,0,0,0,1.2,1},Restoration={0,0,.9,.5,1,0,0,0,2,.75,0,1.3,1.2},
  ["Guardian / Bear"]={.55,1.15,0,2,0,0,.35,.1,0,0,0,0,0,1.3,1.4}}
}
-- Ratings are editable raw-point preferences. No universal encounter cap is assumed.
local extraWeights={
 WARRIOR={Arms={[17]=1},Fury={[17]=1},Protection={[17]=.65,[19]=.8,[20]=1}},
 ROGUE={Assassination={[17]=1},Combat={[17]=1},Subtlety={[17]=1}},
 PALADIN={Protection={[17]=.55,[19]=.8,[20]=1,[21]=1.1,[27]=1.1},Retribution={[17]=.85,[21]=1.2,[27]=1.2}},
 HUNTER={Marksmanship={[18]=1},["Beast Mastery"]={[18]=1},Survival={[18]=.45,[17]=.5}},
 MAGE={Arcane={[24]=2,[27]=2},Fire={[22]=2,[27]=2},Frost={[23]=2,[27]=2}},
 WARLOCK={Affliction={[25]=2,[27]=2},Demonology={[22]=1,[25]=1,[27]=2},Destruction={[22]=2,[27]=2}},
 PRIEST={Shadow={[25]=2,[27]=2}},
 SHAMAN={Elemental={[22]=1.1,[26]=2,[27]=2},Enhancement={[17]=.8,[22]=.4,[26]=.7,[27]=.8}},
 DRUID={Balance={[24]=1.4,[26]=1.4,[27]=2},Feral={[17]=.9},["Guardian / Bear"]={[17]=.55}},
}
for class,profiles in pairs(specProfiles) do
 for spec,weights in pairs(profiles) do
  local extra=extraWeights[class] and extraWeights[class][spec] or {}
  for i,value in pairs(extra) do weights[i]=value end
 end
end
for class,profiles in pairs(specProfiles) do
 for spec,weights in pairs(profiles) do G.presets[spec..' '..class:sub(1,1)..class:sub(2):lower()]=weights end
end
local function secret(v) return issecretvalue and issecretvalue(v) end
local function finite(n) return not secret(n) and type(n)=='number' and n==n and math.abs(n)<1e10 end
local function id(n) return finite(n) and n>0 and n%1==0 end
local function public(v) if secret(v) then return nil end;return v end
local function call(fn,...)
 if type(fn)=='function' then local ok,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p=pcall(fn,...);if ok and not secret(a) and not secret(b) then return a,b,public(c),public(d),public(e),public(f),public(g),public(h),public(i),public(j),public(k),public(l),public(m),public(n),public(o),public(p) end end
end
G.Call=call
function G.Invalidate() G.revision=G.revision+1 end
local function label(s,limit)
 if type(s)~='string' or secret(s) then return '' end
 s=s:gsub('[%c|]',' ');local last=limit or 80
 while #s>last and last>0 do local b=s:byte(last+1);if b<128 or b>=192 then break end;last=last-1 end
 return s:sub(1,last)
end
function G.SuggestPreset()
 local _,class=call(UnitClass,'player')
 local choice=ForeverCompanionSpecPlanner and call(ForeverCompanionSpecPlanner.Get,class)
 local spec=type(choice)=='table' and choice[1] or ''
 local role=type(choice)=='table' and choice[2] or ''
 local preset=role=='Healer' and 'Healer' or role=='Tank' and 'Survival' or
  (class=='MAGE' or class=='WARLOCK' or class=='PRIEST' or (class=='DRUID' and spec=='Balance') or (class=='SHAMAN' and spec=='Elemental')) and 'Caster' or
  (class=='HUNTER' or class=='ROGUE' or class=='DRUID') and 'Agility' or
  (class=='WARRIOR' or class=='PALADIN' or class=='SHAMAN') and 'Strength' or 'Balanced'
 local hasSpecProfile=specProfiles[class] and specProfiles[class][spec]
 if hasSpecProfile then preset=spec..' '..class:sub(1,1)..class:sub(2):lower() end
 return preset,(class or 'Unknown class')..(spec~='' and (' / '..spec) or ''),hasSpecProfile~=nil
end
function G.Settings()
 if type(ForeverCompanionDB)~='table' then ForeverCompanionDB={} end
 local s=ForeverCompanionDB.gearFinder
 if type(s)~='table' then s={};ForeverCompanionDB.gearFinder=s end
 if type(s.weights)~='table' then
  s.weights={};local preset=G.SuggestPreset();for i in ipairs(G.stats) do s.weights[i]=G.presets[preset][i] or 0 end;s.profile=preset
 end
 for i in ipairs(G.stats) do if not finite(s.weights[i]) or s.weights[i]<0 or s.weights[i]>100 then
  local preset=i>originalStatCount and G.presets[s.profile] or G.presets.Balanced
  s.weights[i]=preset and preset[i] or 0
 end end
 for _,key in ipairs({'hunts','completed','profiles','sources'}) do if type(s[key])~='table' then s[key]={} end end
 local count=0
 for key,value in pairs(s.hunts) do
  local n=type(key)=='string' and tonumber(key)
  if not id(n) or tostring(n)~=key or value~=true or count>=300 then s.hunts[key]=nil else count=count+1 end
 end
 for key,value in pairs(s.completed) do
  local n=type(key)=='string' and tonumber(key)
  if not id(n) or tostring(n)~=key or type(value)~='table' or value.observed~=true then s.completed[key]=nil end
 end
 s.profile=label(s.profile,40);if s.profile=='' then s.profile='Balanced' end
 if s.matchArmor==nil then s.matchArmor=true end
 if s.ready==nil then s.ready=true end
 s.largeWindow=s.largeWindow==true
 s.dungeon=label(s.dungeon,100)
 if not id(s.slot) or not G.slots[s.slot] then s.slot=0 end
 if type(s.tracked)~='string' or not s.hunts[s.tracked] or s.completed[s.tracked] then s.tracked=nil end
 return s
end
local function weightsChanged()
 G.Invalidate();local T=ForeverCompanionGearTooltips;if T and T.Refresh then T.Refresh() end
end
function G.Preset(name)
 local p=G.presets[name];if not p then return false end
 local s=G.Settings();for i in ipairs(G.stats) do s.weights[i]=p[i] or 0 end;s.profile=name;weightsChanged();return true
end
function G.SetWeight(index,value)
 if not G.stats[index] or not finite(value) or value<0 or value>100 then return false end
 local s=G.Settings();s.weights[index]=value;s.profile='Custom';weightsChanged();return true
end
function G.SaveProfile(index,name)
 if index~=1 and index~=2 and index~=3 then return false end
 local s=G.Settings();local weights={};for i,v in ipairs(s.weights) do weights[i]=v end
 s.profiles[index]={name=label(name,32),weights=weights};if s.profiles[index].name=='' then s.profiles[index].name='Custom '..index end
 s.profile=s.profiles[index].name;weightsChanged()
 return true
end
function G.LoadProfile(index)
 local s=G.Settings();local p=s.profiles[index]
 if type(p)~='table' or type(p.weights)~='table' then return false end
 local migrated={}
 for i in ipairs(G.stats) do
  local value=p.weights[i]
  if value==nil and i>originalStatCount then value=0 end
  if not finite(value) or value<0 or value>100 then return false end
  migrated[i]=value
 end
 for i,value in ipairs(migrated) do s.weights[i]=value end;s.profile=label(p.name,32);weightsChanged();return true
end
function G.Score(stats,weights)
 if secret(stats) or type(stats)~='table' or not next(stats) then return nil end
 local score,recognized=0,false
 for i,stat in ipairs(G.stats) do
  local n=stats[stat[2]];local weight=weights[i] or 0
  if not finite(weight) or weight<0 then return nil end
  if n~=nil then if not finite(n) or n<0 then return nil end;recognized=true;score=score+n*weight end
 end
 return recognized and score or nil
end
function G.Points(value,signed)
 if type(value)~='number' or secret(value) or value~=value or math.abs(value)==math.huge then return '?' end
 if value==0 then value=0 end
 if math.abs(value)>=1e6 then return string.format(signed and '%+.3g' or '%.3g',value) end
 if value~=0 and math.abs(value)<.005 then return string.format(signed and '%+.3g' or '%.3g',value) end
 local result=string.format(signed and '%+.2f' or '%.2f',value)
 return (result:gsub('0$',''))
end
function G.Request(itemID)
 if id(itemID) and not G.requested[itemID] and #G.loadQueue<300 then G.requested[itemID]='queued';G.loadQueue[#G.loadQueue+1]=itemID
  local W=ForeverCompanionGearFinderWorkspace;if W and W.Wake then W.Wake() end
 end
end
function G.LoadBatch()
 local api=C_Item or {};local n=math.min(6,#G.loadQueue)
 for _=1,n do local itemID=table.remove(G.loadQueue,1);G.requested[itemID]='sent';call(api.RequestLoadItemDataByID,itemID) end
 return #G.loadQueue
end
function G.RetryData() G.requested={};G.loadQueue={};G.interested={};G.Invalidate() end
function G.Read(item,context)
 if not item then return nil end
 local cache=context and context.cache
 if cache and cache[item]~=nil then return cache[item] or nil end
 local api=C_Item or {};G.metrics.itemReads=G.metrics.itemReads+1
 local name,link,quality,level,required,kind,subkind,stack,equip,texture,sell,classID,subclassID,bindType,expansionID,setID=call(api.GetItemInfo,item)
 local itemID=type(item)=='number' and item or (type(item)=='string' and tonumber(item:match('item:(%d+)')))
 if id(itemID) then G.interested[itemID]=true end
 if type(name)~='string' then if id(itemID) then G.Request(itemID) end;if cache then cache[item]=false end;return nil end
 local rawStats=call(api.GetItemStats,type(item)=='string' and item or link)
 local stats,unmodeled,invalid=nil,0,false
 if type(rawStats)=='table' and not secret(rawStats) then
  stats={};local known={}
  for _,stat in ipairs(G.stats) do
   known[stat[2]]=true;local n=rawStats[stat[2]]
   if n~=nil then if finite(n) and n>=0 then stats[stat[2]]=n else invalid=true end end
  end
  for key,n in pairs(rawStats) do if secret(key) or (not known[key] and (not finite(n) or n~=0)) then unmodeled=unmodeled+1 end end
 end
 local info={name=name,link=type(item)=='string' and item or link,required=required,equip=equip,itemLevel=level,quality=quality,kind=kind,subkind=subkind,classID=classID,subclassID=subclassID,setID=setID,stats=stats,unmodeled=unmodeled,score=not invalid and G.Score(stats,context and context.weights or G.Settings().weights) or nil}
 if info.score==nil and type(item)=='number' then G.Request(item) end
 if cache then cache[item]=info end;return info
end
local function numberPattern(template)
 if type(template)~='string' then return nil end
 local start,finish=template:find('%%[%d%$%.]*[fs]')
 if not start then return nil end
 local function literal(value) return (value:gsub('(%W)','%%%1')) end
 return '^%s*'..literal(template:sub(1,start-1))..'(%d+[.,]?%d*)'..literal(template:sub(finish+1))..'%s*$'
end
local function tooltipNumber(value,pattern)
 if type(value)~='string' or not pattern then return nil end
 local number=value:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):match(pattern)
 local numeric=number and tonumber((number:gsub(',','.')))
 return finite(numeric) and numeric>0 and numeric or nil
end
-- Base weapon data stays separate from stat weights and combined loadout DPS.
function G.WeaponDetails(info)
 if not info or info.classID~=2 or type(info.link)~='string' then return end
 if info.weaponDetails then return info.weaponDetails end
 local dpsPattern=numberPattern(DPS_TEMPLATE)
 local speedTemplate=ITEM_SPEED or SPEED_TEMPLATE
 local speedPattern=numberPattern(speedTemplate) or (type(speedTemplate)=='string' and numberPattern(speedTemplate..' %.2f'))
 if not speedPattern then
  local locale=call(GetLocale)
  if locale=='enUS' or locale=='enGB' then speedPattern=numberPattern('Speed %.2f') end
 end
 local tooltip=call((C_TooltipInfo or {}).GetHyperlink,info.link)
 local lines=type(tooltip)=='table' and public(tooltip.lines)
 if type(lines)~='table' then return end
 local weapon={}
 for _,line in ipairs(lines) do
  if not secret(line) and type(line)=='table' then
   local left,right=public(line.leftText),public(line.rightText)
   weapon.dps=weapon.dps or tooltipNumber(left,dpsPattern) or tooltipNumber(right,dpsPattern)
   weapon.speed=weapon.speed or tooltipNumber(right,speedPattern) or tooltipNumber(left,speedPattern)
   if weapon.dps and weapon.speed then break end
  end
 end
 if weapon.dps and weapon.speed then weapon.average=weapon.dps*weapon.speed end
 info.weaponDetails=weapon
 return weapon
end
function G.WeaponDPS(info)
 local weapon=G.WeaponDetails(info)
 return weapon and weapon.dps
end
function G.Catalog()
 local records,byID={},{}
 local combined={}
 for _,r in ipairs(ForeverCompanionLoot and ForeverCompanionLoot.records or {}) do combined[#combined+1]=r end
 for _,r in ipairs(ForeverCompanionLoot and ForeverCompanionLoot.gearSources or {}) do combined[#combined+1]=r end
 if ForeverCompanionQuestRewards then for _,r in ipairs(ForeverCompanionQuestRewards.Catalog()) do combined[#combined+1]=r end end
 for _,record in ipairs(combined) do
  if id(record.itemID) then local r=byID[record.itemID];if not r then r={record=record,sources={}};byID[record.itemID]=r;records[#records+1]=r end;r.sources[#r.sources+1]=record end
 end
 return records,byID
end
function G.RememberSource(itemID,dungeon,boss)
 local _,catalog=G.Catalog();local entry=catalog[itemID]
 if not entry then return false end
 for _,source in ipairs(entry.sources) do
  if source.dungeon==dungeon and source.boss==boss then G.Settings().sources[tostring(itemID)]={dungeon=dungeon,boss=boss};return true end
 end
 return false
end
function G.SavedSource(itemID)
 local _,catalog=G.Catalog();local entry=catalog[itemID];if not entry then return nil end
 local saved=G.Settings().sources[tostring(itemID)]
 if type(saved)=='table' then for _,source in ipairs(entry.sources) do if source.dungeon==saved.dungeon and source.boss==saved.boss then return source end end end
 return entry.record
end
local locations={Head='INVTYPE_HEAD',Neck='INVTYPE_NECK',Shoulder='INVTYPE_SHOULDER',Chest='INVTYPE_CHEST',Waist='INVTYPE_WAIST',Legs='INVTYPE_LEGS',Feet='INVTYPE_FEET',Wrist='INVTYPE_WRIST',Hands='INVTYPE_HAND',Finger='INVTYPE_FINGER',Trinket='INVTYPE_TRINKET',Back='INVTYPE_CLOAK'}
local equipSlots={INVTYPE_ROBE='Chest',INVTYPE_WEAPON='One-Hand',INVTYPE_2HWEAPON='Two-Hand',
 INVTYPE_WEAPONMAINHAND='Main Hand',INVTYPE_WEAPONOFFHAND='Off Hand',INVTYPE_SHIELD='Off Hand',
 INVTYPE_HOLDABLE='Off Hand',INVTYPE_RANGED='Ranged',INVTYPE_RANGEDRIGHT='Ranged',INVTYPE_THROWN='Ranged'}
for slot,location in pairs(locations) do equipSlots[location]=slot end
local armorSlots={Head=true,Shoulder=true,Chest=true,Waist=true,Legs=true,Feet=true,Wrist=true,Hands=true}
function G.Compatible(record,index)
 local slot=G.slots[index];return slot and (record.slot==slot[1] or (slot[2]==16 and (record.slot=='One-Hand' or record.slot=='Two-Hand')) or (slot[2]==17 and record.slot=='One-Hand'))
end
function G.SourceKind(source)
 if source.carried then return 'bags' end
 if source.questID then return 'quest' end
 if source.reference then return 'crafted' end
 return 'dungeon'
end
local bagSnapshot,bagRevision
local function bagLinks()
 local api=C_Container or {}
 if bagRevision==G.revision and bagSnapshot then return bagSnapshot end
 if type(api.GetContainerNumSlots)~='function' or type(api.GetContainerItemInfo)~='function' then return {} end
 local found,seen={},{}
 for bag=0,4 do
  local count=call(api.GetContainerNumSlots,bag)
  if finite(count) and count>=0 and count<=200 then
   for slot=1,math.floor(count) do
    local item=call(api.GetContainerItemInfo,bag,slot)
    local link=type(item)=='table' and public(item.hyperlink)
    if type(link)=='string' and not seen[link] and link:find('item:%d+') then
     found[#found+1]=link;seen[link]=true
    end
   end
  end
 end
 bagSnapshot,bagRevision=found,G.revision
 return found
end
function G.Owned(itemID)
 G.metrics.ownershipReads=G.metrics.ownershipReads+1
 local count=call((C_Item or {}).GetItemCount,itemID,false,false,false,false)
 return finite(count) and count>=0 and count%1==0 and count or nil
end
-- A missing/failed link lookup must never be mistaken for an empty equipment slot.
local function inventory(slot)
 if type(GetInventoryItemLink)~='function' then return nil,false end
 local ok,link=pcall(GetInventoryItemLink,'player',slot)
 if not ok or secret(link) then return nil,false end
 if type(link)=='string' and link~='' then return link,true end
 if link~=nil then return nil,false end
 if type(GetInventoryItemID)=='function' then
  local found,itemID=pcall(GetInventoryItemID,'player',slot)
  if found and not secret(itemID) and itemID==nil then return nil,true end
  if found and id(itemID) then G.Request(itemID) end
 end
 return nil,false
end
function G.Context(settings,matchArmor)
 local cfg=settings or G.Settings();local weights={};for i in ipairs(G.stats) do weights[i]=cfg.weights[i] end
 local c={cache={},uniqueness={},links={},inventoryKnown={},owned={},usable={},weights=weights,settings=cfg,level=call(UnitLevel,'player'),matchArmor=matchArmor==true}
 for i,slot in ipairs(G.slots) do c.links[i],c.inventoryKnown[i]=inventory(slot[2]) end
 return c
end
function G.SnapshotKey(options)
 options=options or {};local cfg=G.Settings();local context=G.Context(cfg,options.matchArmor or options.bestNow and not options.includeReview);context.bestNow=options.bestNow
 local fields={tostring(G.revision),tostring(context.level)}
 if options.includeBags then context.bags=bagLinks();for _,link in ipairs(context.bags) do fields[#fields+1]=link end end
 for _,key in ipairs({'slot','query','dungeon','saved','completed','active','ready','matchArmor','upgrades','hideOwned','bestNow','includeReview','includeBags','sourceKind'}) do fields[#fields+1]=tostring(options[key]) end
 for i in ipairs(G.slots) do fields[#fields+1]=tostring(context.links[i]);fields[#fields+1]=tostring(context.inventoryKnown[i]) end
 for i in ipairs(G.stats) do fields[#fields+1]=tostring(context.weights[i]) end
 local keys={};for key,value in pairs(cfg.sources) do if type(key)=='string' and type(value)=='table' and type(value.dungeon)=='string' and type(value.boss)=='string' then keys[#keys+1]='s'..key..value.dungeon..'/'..value.boss end end
 for key in pairs(cfg.hunts) do keys[#keys+1]='h'..key end;for key in pairs(cfg.completed) do keys[#keys+1]='c'..key end;table.sort(keys)
 for _,key in ipairs(keys) do fields[#fields+1]=key end
 fields[#fields+1]=tostring(cfg.tracked)
 local records=ForeverCompanionLoot and ForeverCompanionLoot.records or {};fields[#fields+1]=tostring(records);fields[#fields+1]=tostring(#records)
 -- API identity changes are mostly useful for test clients / optional API availability changes.
 for _,fn in ipairs({'GetItemInfo','GetItemStats','GetItemCount','GetItemUniquenessByID'}) do fields[#fields+1]=tostring((C_Item or {})[fn]) end
 fields[#fields+1]=tostring((C_PlayerInfo or {}).CanUseItem)
 return table.concat(fields,'\031'),context
end
local function observed(itemID,context)
 if context.owned[itemID]==nil then context.owned[itemID]=G.Owned(itemID) or false end
 local n=context.owned[itemID];if n==false then return nil end;return n
end
local function usable(itemID,context)
 if context.usable[itemID]==nil then local value=call((C_PlayerInfo or {}).CanUseItem,itemID);context.usable[itemID]=type(value)=='boolean' and {value=value} or false end
 local value=context.usable[itemID];if not value then return nil end;return value.value
end
local function uniqueness(itemID,context)
 if context.uniqueness[itemID]~=nil then return context.uniqueness[itemID] or nil end
 local unique,name,limit,category=call((C_Item or {}).GetItemUniquenessByID,itemID)
 local value=type(unique)=='boolean' and {unique=unique,limit=limit,category=category} or nil
 context.uniqueness[itemID]=value or false;return value
end
local function blocked(itemID,index,context)
 local rule=uniqueness(itemID,context);if not rule then return false,false end
 local category=finite(rule.category) and rule.category>0 and rule.category or nil
 local limit=finite(rule.limit) and rule.limit>0 and rule.limit or (rule.unique and 1 or nil)
 if not rule.unique and not category then return false,true end
 local count,same,uncertain=0,0,false
 for i in ipairs(G.slots) do
  if i~=index then
   local link=context.links[i]
   if type(link)=='string' then
    local otherID=tonumber(link:match('item:(%d+)'))
    if otherID then
     if otherID==itemID then same=same+1 end
     if category then
      local other=uniqueness(otherID,context)
      if not other then uncertain=true elseif other.category==category then count=count+1 end
     end
    else uncertain=true end
   elseif not context.inventoryKnown[i] then uncertain=true end
  end
 end
 if (rule.unique and same>=1) or (category and limit and count>=limit) then return true,true end
 if uncertain then return nil,false end
 return false,true
end
local function recommendable(row)
 return row.delta and row.delta>0 and not row.partial and (row.owned==0 or row.carried)
  and not row.isEquipped and row.usable==true and row.uniquenessChecked and row.slot[1]~='Trinket'
end
local function compare(entry,index,context)
 local record,info=entry.record,G.Read(entry.record.bagLink or entry.record.itemID,context)
 local slot=G.slots[index];local equipped=context.links[index];local baseline=G.Read(equipped,context)
 local canUse=usable(record.itemID,context)
 local conflict,uniqueChecked=blocked(record.itemID,index,context)
 local r={record=record,sources=entry.sources,info=info,baseline=baseline,slotIndex=index,slot=slot,owned=observed(record.itemID,context),usable=canUse,uniquenessChecked=uniqueChecked,weights=context.weights}
 r.carried=record.carried
 r.isEquipped=type(equipped)=='string' and not r.carried and tonumber(equipped:match('item:(%d+)'))==record.itemID
 if r.carried then
  r.isEquipped=type(equipped)=='string' and equipped:match('item:[^|]+')==record.bagLink:match('item:[^|]+')
  r.owned=math.max(1,r.owned or 0)
 end
 local reason
 if not info then reason='Loading item data'
 elseif not finite(info.required) or not finite(context.level) then reason='Level requirement unavailable'
 elseif info.required>context.level then reason='Requires level '..info.required;r.future=true
 elseif canUse==false then reason='Client reports this item cannot be used';r.blocked=true;r.unusable=true
 elseif conflict==true then reason='Unique-item limit conflicts with equipped gear';r.blocked=true
 elseif conflict==nil then reason='Unique-item restrictions unavailable';r.restrictionsUnknown=true
 elseif slot[2]>=16 then
  if slot[2]==16 and info.equip=='INVTYPE_2HWEAPON' and context.links[16] then
   reason='Two-handed swap also replaces your off-hand';r.displaced=G.Read(context.links[16],context)
  elseif slot[2]==17 and context.links[15] and (G.Read(context.links[15],context) or {}).equip=='INVTYPE_2HWEAPON' then
   reason='Off-hand swap needs a one-handed main hand'
  else reason='Review weapon speed, DPS and effects' end
 elseif info.equip~=locations[slot[1]] and not (slot[1]=='Chest' and info.equip=='INVTYPE_ROBE') then reason='Client slot differs from source catalog'
 elseif context.matchArmor and armorSlots[slot[1]] and baseline and (not finite(info.subclassID) or not finite(baseline.subclassID)) then reason='Armor type unavailable';r.armorUnknown=true
 elseif context.matchArmor and armorSlots[slot[1]] and baseline and info.subclassID~=baseline.subclassID then reason='Different armor type';r.armorMismatch=true
 elseif info.score==nil or (equipped and (not baseline or baseline.score==nil)) then reason='Comparison stats unavailable'
 elseif not equipped and not context.inventoryKnown[index] then reason='Equipped item link unavailable';r.equipmentUnknown=true
 elseif not equipped then
  r.empty=true;reason='Empty slot — inspect this candidate'
  if context.bestNow then
   r.delta=info.score;r.partial=(info.unmodeled or 0)>0
   reason=G.Points(r.delta,true)..' estimated points vs empty slot'
  end
 else
  r.delta=info.score-baseline.score
  if math.abs(r.delta)<=1e-9*math.max(1,math.abs(info.score),math.abs(baseline.score)) then r.delta=0 end
  r.partial=(info.unmodeled or 0)>0 or (baseline.unmodeled or 0)>0
  if baseline.score>0 then r.percent=100*r.delta/baseline.score end
  reason=G.Points(r.delta,true)..' estimated points'..(r.partial and ' · partial stats' or (r.percent and (' ('..G.Points(r.percent,true)..'% score)') or ''))
 end
 if r.delta~=nil and ((id(info.setID) and (not baseline or info.setID~=baseline.setID))
  or (baseline and id(baseline.setID) and baseline.setID~=info.setID)) then
  r.partial=true;r.setReview=true;reason=G.Points(r.delta,true)..' points / check set bonuses'
 end
 r.reason=reason;r.saved=context.settings.hunts[tostring(record.itemID)]==true;r.completed=context.settings.completed[tostring(record.itemID)];r.tracked=context.settings.tracked==tostring(record.itemID)
 return r
end
-- Compare the actual hovered item link, including its suffix/enchant variant.
function G.CompareLink(link)
 if type(link)~='string' or secret(link) then return nil end
 local itemID=tonumber(link:match('item:(%d+)'));if not id(itemID) then return nil end
 local cfg=G.Settings();local context=G.Context(cfg,cfg.matchArmor)
 local info=G.Read(link,context);if not info then return nil end
 local slotName=equipSlots[info.equip]
 if not slotName then return nil end
 context.cache[itemID]=info
 local record={itemID=itemID,item=info.name,slot=slotName};local entry={record=record,sources={}}
 local best
 for i in ipairs(G.slots) do if G.Compatible(record,i) then local r=compare(entry,i,context);if not best or (r.delta~=nil and (best.delta==nil or r.delta>best.delta)) then best=r end end end
 return best
end
-- An incomplete client check should surface an item for review, never certify it.
local function reviewTier(row,level)
 if not row.info or not finite(level) or not finite(row.info.required) or row.info.required>level
  or row.blocked or row.armorMismatch or row.isEquipped or (row.owned and row.owned>0 and not row.carried) then return end
 if row.delta and row.delta>0 then return 2 end
 if not row.delta and (row.slot[2]>=16 or row.slot[1]=='Trinket' or row.info.score~=nil) then return 1 end
end
local function betterUpgrade(a,b)
 if not b then return true end
 if a.upgradeTier~=b.upgradeTier then return a.upgradeTier>b.upgradeTier end
 if a.upgradeTier>1 and a.delta~=b.delta then return a.delta>b.delta end
 if a.upgradeTier==1 then
  local aLevel=finite(a.info.itemLevel) and a.info.itemLevel or a.info.required
  local bLevel=finite(b.info.itemLevel) and b.info.itemLevel or b.info.required
  if aLevel~=bLevel then return aLevel>bLevel end
 end
 return a.record.itemID<b.record.itemID
end
function G.Build(options,context)
 G.metrics.builds=G.metrics.builds+1
 options=options or {};local s=G.Settings();local result={};context=context or G.Context(s,options.matchArmor or options.bestNow and not options.includeReview);context.bestNow=options.bestNow
 local selected=options.slot==0 and 0 or (G.slots[options.slot or 1] and (options.slot or 1) or 1)
 local catalog,byID=G.Catalog()
 local bagLoading=0
 if options.includeBags and (not options.sourceKind or options.sourceKind=='bags') and (not options.dungeon or options.dungeon=='') then
  for _,link in ipairs(context.bags or bagLinks()) do
   local itemID=tonumber(link:match('item:(%d+)'))
   local info=G.Read(link,context)
   if not info then bagLoading=bagLoading+1 end
   local slot=info and equipSlots[info.equip]
   if slot then
    local record={itemID=itemID,item=info.name,slot=slot,dungeon='Carried gear',boss='In your bags',carried=true,
     reference=true,bagLink=link,status='Exact item in your carried inventory'}
    local entry=byID[itemID]
    if not entry then entry={record=record,sources={}};catalog[#catalog+1]=entry;byID[itemID]=entry end
    entry.sources[#entry.sources+1]=record
   end
  end
 end
 local terms={};for term in label(options.query,100):lower():gmatch('%S+') do terms[#terms+1]=term end
 local stats={total=0,ranked=0,positive=0,loading=bagLoading,hidden=0,confirmed=0,estimated=0,review=0,carried=0,slots={}}
 for _,entry in ipairs(catalog) do
  local record=entry.record;local key=tostring(record.itemID)
  local matches=(not options.saved or s.hunts[key]) and (not options.completed or s.completed[key])
  if options.active and s.completed[key] then matches=false end
  local sourceText=record.item..' '..key..' '..record.slot
  local eligible,preferred,bestHits={},nil,-1
  for _,candidate in ipairs(entry.sources) do
   if (not options.sourceKind or G.SourceKind(candidate)==options.sourceKind) and
      (not options.bestNow or not candidate.sourceMinLevel or (finite(context.level) and candidate.sourceMinLevel<=context.level)) and
      (not options.dungeon or options.dungeon=='' or candidate.dungeon==options.dungeon) then
    eligible[#eligible+1]=candidate;local text=(candidate.dungeon..' '..candidate.boss):lower();local hits=0
    for _,term in ipairs(terms) do if text:find(term,1,true) then hits=hits+1 end end
    local saved=(options.saved or options.completed) and s.sources[key]
    local isSaved=type(saved)=='table' and candidate.dungeon==saved.dungeon and candidate.boss==saved.boss
    if hits>bestHits or (hits==bestHits and isSaved) then bestHits=hits;preferred=candidate end
    sourceText=sourceText..' '..candidate.item..' '..candidate.dungeon..' '..candidate.boss
   end
  end
  for _,term in ipairs(terms) do if not sourceText:lower():find(term,1,true) then matches=false end end
  local sourceMatch=#eligible>0
  local best
  if matches and sourceMatch then
   local candidates={}
   for _,candidate in ipairs(eligible) do
    if candidate.carried then candidates[#candidates+1]=candidate end
   end
   if #candidates==0 then candidates[1]=preferred end
   for _,candidate in ipairs(candidates) do
    local info=G.Read(candidate.bagLink or record.itemID,context)
    local slotInfo={slot=info and equipSlots[info.equip] or candidate.slot}
    local rowEntry={record=candidate,sources=eligible}
    for i in ipairs(G.slots) do if (selected==0 or selected==i) and G.Compatible(slotInfo,i) then
     local r=compare(rowEntry,i,context)
    if options.bestNow then
     r.upgradeTier=recommendable(r) and 3 or options.includeReview and reviewTier(r,context.level) or nil
     if r.upgradeTier and betterUpgrade(r,best) then best=r end
    elseif not best or (r.delta~=nil and (best.delta==nil or r.delta>best.delta)) then best=r end
    if options.bestNow and not r.info then stats.loading=stats.loading+1 end
    if r.delta and r.delta>0 then stats.slots[i]=(stats.slots[i] or 0)+1 end
    end end
   end
  end
  if best then
   if best.carried then
    best.sources={best.record}
    for _,candidate in ipairs(eligible) do if not candidate.carried then best.sources[#best.sources+1]=candidate end end
   end
   stats.total=stats.total+1;if best.delta~=nil then stats.ranked=stats.ranked+1;if best.delta>0 then stats.positive=stats.positive+1 end end
   if not best.info then stats.loading=stats.loading+1 end
   if (not options.upgrades or (best.delta and best.delta>0 and not best.partial and best.owned==0)) and
      (not options.ready or (best.info and finite(best.info.required) and finite(context.level) and best.info.required<=context.level)) and
      (not options.hideOwned or best.owned==0) and (not options.matchArmor or not best.armorMismatch or options.saved or options.completed) then result[#result+1]=best else stats.hidden=stats.hidden+1 end
  end
 end
 -- Keep legacy saved identities reviewable if a later catalog removes their source.
 if selected==0 and (options.saved or options.completed) and (not options.dungeon or options.dungeon=='') then
  local _,known=G.Catalog();local identities=options.completed and s.completed or s.hunts
  for key in pairs(identities) do
   local itemID=tonumber(key)
   if not known[itemID] and not (options.active and s.completed[key]) then
    local title='Saved item #'..key;local matches=true
    for _,term in ipairs(terms) do if not title:lower():find(term,1,true) then matches=false end end
    if matches then
     local record={itemID=itemID,item=title,slot='Unknown',dungeon='Source unavailable',boss='Retained saved identity',status='No current source in the bundled catalog',unavailable=true}
     result[#result+1]={record=record,sources={record},slot={'Unknown',0},slotIndex=0,reason='Source unavailable — saved identity retained',saved=s.hunts[key]==true,completed=s.completed[key],tracked=false,unavailable=true}
    end
   end
  end
 end
 if options.bestNow then
  table.sort(result,betterUpgrade)
  for _,r in ipairs(result) do
   if r.carried then stats.carried=stats.carried+1 end
   if r.upgradeTier==3 then stats.confirmed=stats.confirmed+1
   elseif r.upgradeTier==2 then stats.estimated=stats.estimated+1
   else stats.review=stats.review+1 end
  end
  for i,r in ipairs(result) do
   r.recommended=r.upgradeTier==3
   if r.recommended then r.rank=i;r.rankCount=stats.confirmed;r.rankScore=r.info.score end
   r.listIndex=i
  end
  return result,G.Read(context.links[selected],context),G.slots[selected],stats
 end
 -- Rank candidate stats independently of the equipped baseline. A missing worn
 -- item must not erase a known candidate score. Scope is this filtered slot list.
 local groups={}
 for _,r in ipairs(result) do
  local info=r.info
  r.rankScore=info and info.score
  r.rankable=info~=nil and info.score~=nil and (info.unmodeled or 0)==0 and not r.blocked and not r.future and not r.restrictionsUnknown and not r.armorMismatch and not r.armorUnknown and r.slot[2]<16 and info.equip==locations[r.slot[1]]
  if info and r.slot[1]=='Chest' and info.equip=='INVTYPE_ROBE' and info.score~=nil and (info.unmodeled or 0)==0 and not r.blocked and not r.future and not r.armorMismatch and not r.armorUnknown and not r.restrictionsUnknown then r.rankable=true end
  if r.rankable then local key=r.slot[1];groups[key]=groups[key] or {};groups[key][#groups[key]+1]=r end
 end
 for _,group in pairs(groups) do
  table.sort(group,function(a,b) if a.rankScore~=b.rankScore then return a.rankScore>b.rankScore end;return a.record.itemID<b.record.itemID end)
  local rank,previous=0,nil
  for i,r in ipairs(group) do
   if previous==nil or math.abs(r.rankScore-previous)>1e-9*math.max(1,math.abs(r.rankScore),math.abs(previous)) then rank=i end
   r.rank=rank;r.rankCount=#group;previous=r.rankScore
  end
 end
 -- Every journal view uses ranks first, including saved and acquired items.
 -- Across slots, show each slot's first choice before second choices; raw scores
 -- from unrelated slots are deliberately not treated as comparable upgrades.
 table.sort(result,function(a,b)
  if (a.rank~=nil)~=(b.rank~=nil) then return a.rank~=nil end
  if a.rank and b.rank and a.rank~=b.rank then return a.rank<b.rank end
  if a.slotIndex~=b.slotIndex then return a.slotIndex<b.slotIndex end
  if a.rank and b.rank and a.rankScore~=b.rankScore then return a.rankScore>b.rankScore end
  if (a.delta~=nil)~=(b.delta~=nil) then return a.delta~=nil end
  if a.delta~=b.delta then return (a.delta or -math.huge)>(b.delta or -math.huge) end
  return a.record.itemID<b.record.itemID
 end)
 for i,r in ipairs(result) do r.listIndex=i end
 return result,G.Read(context.links[selected],context),G.slots[selected],stats
end
function G.Breakdown(row)
 if not row or not row.info or type(row.info.stats)~='table' then return {} end
 local baseline=row.baseline and row.baseline.score~=nil and row.baseline.stats or row.empty and {};local weights=row.weights or G.Settings().weights;local result={}
 for i,stat in ipairs(G.stats) do
  local a=row.info.stats[stat[2]] or 0;local b=type(baseline)=='table' and (baseline[stat[2]] or 0) or nil
  if finite(a) and (b==nil or finite(b)) and (a~=0 or (b and b~=0)) then result[#result+1]={name=stat[1],candidate=a,equipped=b,delta=b and a-b,weight=weights[i],points=b and (a-b)*weights[i]} end
 end;return result
end
function G.Toggle(itemID)
 local s=G.Settings();local key=tostring(itemID)
 if s.hunts[key] then s.hunts[key]=nil;if s.tracked==key then s.tracked=nil end;return true,'Removed from hunts.' end
 local _,catalog=G.Catalog();if not catalog[itemID] then return false,'Item is no longer in the catalog.' end
 local count=0;for _ in pairs(s.hunts) do count=count+1 end
 if count>=32 then return false,'Your hunt log is full (32 items). Remove a hunt first.' end
 s.hunts[key]=true;local owned=G.Owned(itemID)
 if owned and owned>0 then s.completed[key]={observed=true};return true,'Saved — already observed in your inventory.' end
 return true,'Added to your hunt log.'
end
function G.Track(itemID)
 local s=G.Settings();local key=tostring(itemID)
 local _,catalog=G.Catalog();if not catalog[itemID] or not s.hunts[key] or s.completed[key] then return false end
 if s.tracked==key then s.tracked=nil else s.tracked=key end;return true
end
function G.ObserveHunts()
 local s=G.Settings();if not next(s.hunts) then return {} end;local _,catalog=G.Catalog();local acquired={}
 for key in pairs(s.hunts) do
  local itemID=tonumber(key);local count=not s.completed[key] and catalog[itemID] and G.Owned(itemID)
  if catalog[itemID] and not s.completed[key] and count and count>0 then s.completed[key]={observed=true};if s.tracked==key then s.tracked=nil end;acquired[#acquired+1]=catalog[itemID].record end
 end
 table.sort(acquired,function(a,b) return a.itemID<b.itemID end);return acquired
end
function G.HuntCounts()
 local s=G.Settings();local active,done=0,0
 for key in pairs(s.hunts) do if not s.completed[key] then active=active+1 end end
 for _ in pairs(s.completed) do done=done+1 end;return active,done
end
