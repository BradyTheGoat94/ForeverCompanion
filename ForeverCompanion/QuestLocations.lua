-- Runtime reader for the separately installed Forever QuestieDB public API.
local R={}
ForeverCompanionQuestLocations=R

local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,value=pcall(fn,...)
 if ok then return value end
end

local function provider()
 local db=LibQuestieDB
 if type(db)~="table" or read(db.RequireContract,1)~=true then return end
 local status=db.ModeIndicator and read(db.ModeIndicator.GetStatus)
 local flavor=type(status)=="table" and status.expansion
 if not flavor then
  local metadata=C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
  flavor=read(metadata,"QuestieDB","X-Flavor")
 end
 if type(flavor)=="string" and flavor:lower()=="forever" and type(db.Quest)=="table" then return db end
end

local mapText,areaMaps
local function maps(db)
 local zones=db.Support and read(db.Support.Get,"ZoneDB")
 local raw=zones and zones.private and zones.private.areaIdToUiMapId
 if type(raw)~="string" then return {} end
 if raw~=mapText then
  mapText,areaMaps=raw,{}
  -- The provider exposes Lua text. Read numeric entries only.
  local clean=raw:gsub("%-%-[^\r\n]*","")
  for area,map in clean:gmatch("%[(%d+)%]%s*=%s*(%d+)%s*[,}]") do
   areaMaps[tonumber(area)]=tonumber(map)
  end
 end
 return areaMaps
end

R.Provider=provider
R.AreaMaps=maps
-- The opening Forever Faire is in Elwynn, Nov 9–15 2026. This rule expires;
-- faction alone cannot locate a neutral event that rotates between continents.
-- https://www.wowhead.com/forever/guide/darkmoon-faire-event-overview-guide
function R.EventArea(quest)
 if not quest or (quest.id~=7905 and quest.id~=7926) then return end
 local now=C_DateAndTime and read(C_DateAndTime.GetCurrentCalendarTime)
 if type(now)=='table' and now.year==2026 and now.month==11 and type(now.monthDay)=='number' and now.monthDay>=9 and now.monthDay<=15 then return 12 end
end
function R.AllowsLocation(quest,target)
 local area=R.EventArea(quest)
 if not area then return true end
 if target.areaID then return target.areaID==area end
 local db=provider();local map=db and maps(db)[area]
 return map~=nil and target.map==map
end

local function append(result,zoneMaps,spawns,kind,name,objective,entityID)
 if type(spawns)~="table" then return end
 for area,coords in pairs(spawns) do
  local map=zoneMaps[area]
  local info=map and map>0 and C_Map and read(C_Map.GetMapInfo,map)
  -- Reject continent/world aliases. Dungeon entries require verified native
  -- coordinates; provider compatibility mappings alone cannot establish them.
  if type(info)=="table" and (info.mapType==3 or info.mapType==5) and type(coords)=="table" then
   for _,xy in ipairs(coords) do
    if type(xy)=="table" then
     local x,y,phase=xy[1],xy[2],xy[3]
     if type(x)=="number" and type(y)=="number" and x>=0 and x<=100 and y>=0 and y<=100 and (not phase or phase==0) then
      result[#result+1]={map=map,x=x/100,y=y/100,source="QuestieDB "..kind,kind=kind,label=name,objective=objective,entityID=entityID,areaID=area}
     end
    end
   end
  end
 end
end

local function entity(result,mapsByArea,db,kind,id,action,objective)
 if not db or type(id)~="number" or id<=0 then return end
 local spawns=read(db.spawns,id)
 local name=read(db.name,id)
 append(result,mapsByArea,spawns,action or kind,name,objective,id)
end

local function normalized(text)
 if type(text)~="string" then return "" end
 return text:lower():gsub("[%p%s]+"," "):match("^%s*(.-)%s*$")
end

local function mentions(text,name)
 local term=normalized(name)
 if #term<3 then return false end
 local haystack=" "..normalized(text).." "
 if haystack:find(" "..term.." ",1,true) then return true end
 if not haystack:find(" "..term.."s ",1,true) and not haystack:find(" "..term.."es ",1,true) then
  local plural=term:gsub("fe$","ves"):gsub("f$","ves"):gsub("y$","ies")
  return plural~=term and haystack:find(" "..plural.." ",1,true)~=nil
 end
 return true
end

local function candidates(db,objectives)
 local result={monster={},object={},item={}}
 local lists={[1]=result.monster,[2]=result.object,[3]=result.item,[5]=result.monster}
 local sources={[1]=db.Npc,[2]=db.Object,[3]=db.Item,[5]=db.Npc}
 for _,kind in ipairs({1,2,3,5}) do
  local source=sources[kind]
  for _,row in ipairs(type(objectives[kind])=="table" and objectives[kind] or {}) do
   if type(row)=="table" then
    local credit=kind==5
    local id,description,count=row[1],row[2],row[3]
    if credit then id,description,count=row[2],row[3],row[4] end
    lists[kind][#lists[kind]+1]={id=id,name=source and read(source.name,id),description=description,count=count,
     alternates=credit and row[1] or nil}
   end
  end
 end
 return result
end

local function objectiveMatch(list,text,required)
 local matched
 for _,row in ipairs(list) do
  local countMatches=not required or type(row.count)~="number" or row.count<=0 or required==row.count
  if countMatches and (mentions(text,row.name) or mentions(text,row.description)) then
   if matched then return end
   matched=row
  end
 end
 return matched
end

-- Item identity requires the same quest ID/name and one unambiguous live
-- objective match. A similar name or a database-only objective is insufficient.
function R.ObjectiveItem(quest,index)
 local db=provider()
 if not db or type(quest)~='table' or type(quest.id)~='number' or quest.id~=quest.id or quest.id<=0 or quest.id>=math.huge or quest.id%1~=0 or type(quest.title)~='string' or quest.title=='' or type(index)~='number' or index<1 or index%1~=0 then return end
 if normalized(read(db.Quest.name,quest.id))~=normalized(quest.title) then return end
 local state=type(quest.objectiveStates)=='table' and quest.objectiveStates[index]
 local text=type(quest.objectives)=='table' and quest.objectives[index]
 if type(state)~='table' or state.known~=true or state.kind~='item' or type(text)~='string' then return end
 local objectives=read(db.Quest.objectives,quest.id)
 local groups=candidates(db,type(objectives)=='table' and objectives or {})
 local row=objectiveMatch(groups.item,text,state.required)
 if not row or type(row.id)~='number' or row.id~=row.id or row.id<=0 or row.id>=math.huge or row.id%1~=0 or type(row.name)~='string' or row.name=='' then return end
 return {id=row.id,name=row.name,objectiveIndex=index,done=state.done==true or quest.complete==true,current=state.current,required=state.required,source='Forever QuestieDB objective reference'}
end
function R.ForQuest(quest)
 local db=provider()
 if not db or not quest or type(quest.id)~="number" or quest.id<=0 then return {} end
 local result={}
 if normalized(read(db.Quest.name,quest.id))~=normalized(quest.title) then return result end
 local zones=maps(db)
 if quest.complete or quest.id==7905 or quest.id==7926 then
  local endings=read(db.Quest.finishedBy,quest.id)
  if type(endings)=="table" then
   for _,id in ipairs(type(endings[1])=="table" and endings[1] or {}) do entity(result,zones,db.Npc,"npc",id,"turn-in") end
   for _,id in ipairs(type(endings[2])=="table" and endings[2] or {}) do entity(result,zones,db.Object,"object",id,"turn-in") end
  end
  if not quest.complete then
   -- These two breadcrumb quests explicitly deliver a voucher to the Faire.
   -- Keep it a general event destination unless an objective is known.
   for _,t in ipairs(result) do
    t.kind='event-destination'
    if #(quest.objectives or {})==1 and quest.objectiveStates and quest.objectiveStates[1] and quest.objectiveStates[1].known and not quest.objectiveStates[1].done then t.objectiveIndex=1 end
   end
  end
 else
  local objectives=read(db.Quest.objectives,quest.id)
  local groups=candidates(db,type(objectives)=="table" and objectives or {})
  local states=quest.objectiveStates or {}
  for i,state in ipairs(states) do
   if state.known and not state.done then
    local first=#result+1
    local kind,text=state.kind,quest.objectives[i]
    local list=kind and groups[kind]
    local row=list and objectiveMatch(list,text,state.required)
    if row and kind=="monster" then
     if type(row.alternates)=="table" and #row.alternates>0 then
      for _,id in ipairs(row.alternates) do entity(result,zones,db.Npc,"npc",id,nil,text) end
     else
      entity(result,zones,db.Npc,"npc",row.id,nil,text)
     end
    elseif row and kind=="object" then
     entity(result,zones,db.Object,"object",row.id,nil,text)
    elseif row and kind=="item" and db.Item then
     local npcs,objects=read(db.Item.npcDrops,row.id),read(db.Item.objectDrops,row.id)
     for _,id in ipairs(type(npcs)=="table" and npcs or {}) do entity(result,zones,db.Npc,"npc",id,"drop",text) end
     for _,id in ipairs(type(objects)=="table" and objects or {}) do entity(result,zones,db.Object,"object",id,"drop",text) end
    elseif kind=="event" then
     local trigger=read(db.Quest.triggerEnd,quest.id)
     if type(trigger)=="table" and mentions(text,trigger[1]) then
      append(result,zones,trigger[2],"event",trigger[1],text)
     end
    end
    for j=first,#result do result[j].objectiveIndex=i end
   end
  end
 end
 return result
end

local function reportKey(quest,target)
 if not quest or type(quest.id)~='number' or type(target)~='table' or type(target.map)~='number' or type(target.x)~='number' or type(target.y)~='number' then return end
 return string.format('%d:%s:%s:%.5f:%.5f',quest.id,tostring(target.objectiveIndex or target.kind or 'quest'),target.map,target.x,target.y)
end
function R.IsReported(quest,target)
 local key=reportKey(quest,target)
 local reports=ForeverCompanionDB and ForeverCompanionDB.questLocationReports
 if key and type(reports)=='table' then for _,entry in ipairs(reports) do if entry.key==key then return true end end end
 return false
end
function R.Report(quest,target)
 local key=reportKey(quest,target);if not key then return 'Choose a reported quest location first.' end
 ForeverCompanionDB=ForeverCompanionDB or {}
 local db=ForeverCompanionDB
 if type(db.questLocationReports)~='table' then db.questLocationReports={} end
 if R.IsReported(quest,target) then return 'This location is already excluded for this character.' end
 local map=C_Map and read(C_Map.GetBestMapForUnit,'player')
 local pos=map and read(C_Map.GetPlayerMapPosition,map,'player')
 local x,y
 if pos and type(pos.GetXY)=='function' then local ok,a,b=pcall(pos.GetXY,pos);if ok then x,y=a,b end end
 db.questLocationReports[#db.questLocationReports+1]={key=key,questID=quest.id,title=quest.title,objectiveIndex=target.objectiveIndex,
  map=target.map,x=target.x,y=target.y,source=target.source,entityID=target.entityID,areaID=target.areaID,label=target.label,
  playerMap=map,playerX=x,playerY=y}
 while #db.questLocationReports>100 do table.remove(db.questLocationReports,1) end
 return 'Saved locally and excluded this destination. Use Location options to copy the report or restore it.'
end
function R.ReportText(quest)
 local lines={'Forever Companion quest location report (player-reported; not a verified correction)'}
 for _,r in ipairs(ForeverCompanionDB and ForeverCompanionDB.questLocationReports or {}) do
  if not quest or r.questID==quest.id then
   lines[#lines+1]=string.format('Quest #%d: %s | objective %s | map %s %.5f, %.5f | %s | entity %s | area %s | player map %s %s, %s',r.questID,r.title or '',tostring(r.objectiveIndex or 'quest'),tostring(r.map),r.x,r.y,r.source or 'unknown',tostring(r.entityID or '?'),tostring(r.areaID or '?'),tostring(r.playerMap or '?'),tostring(r.playerX or '?'),tostring(r.playerY or '?'))
  end
 end
 return table.concat(lines,'\n')
end
function R.Restore(quest)
 local reports=ForeverCompanionDB and ForeverCompanionDB.questLocationReports
 if type(reports)=='table' then for i=#reports,1,-1 do if reports[i].questID==quest.id then table.remove(reports,i) end end end
end
function R.IsAvailable() return provider()~=nil end

-- Public API reads only. These are Forever-flavor references, not live verification.
function R.Details(quest)
 local result={givers={},pickups={},requirements={},followups={},objectives={},prerequisites={},finishers={},turnins={}}
 local db=provider()
 if not db or type(quest)~='table' or type(quest.id)~='number' then return result end
 if normalized(read(db.Quest.name,quest.id))~=normalized(quest.title) then return result end
 result.source='Forever QuestieDB reference; not live-client verified'
 result.minimum=read(db.Quest.requiredLevel,quest.id)
 local starts=read(db.Quest.startedBy,quest.id)
 if type(starts)=='table' then
  local sources={db.Npc,db.Object,db.Item}
  for kind=1,3 do
   local source=sources[kind]
   for _,id in ipairs(type(starts[kind])=='table' and starts[kind] or {}) do
    if source then
     local name=read(source.name,id)
     if type(name)=='string' and name~='' then result.givers[#result.givers+1]=name..(kind==3 and ' (item start)' or '') end
     if kind<3 then entity(result.pickups,maps(db),source,kind==1 and 'npc' or 'object',id,'pickup') end
    end
   end
  end
 end
 local ends=read(db.Quest.finishedBy,quest.id)
 for kind,source in ipairs({db.Npc or {},db.Object or {}}) do
  for _,id in ipairs(type(ends)=='table' and type(ends[kind])=='table' and ends[kind] or {}) do
   if type(id)=='number' and id>0 and id%1==0 then
    local name=read(source.name,id)
    if type(name)=='string' and name~='' then result.finishers[#result.finishers+1]=name end
    entity(result.turnins,maps(db),source,kind==1 and 'npc' or 'object',id,'turn-in')
   end
  end
 end
 local function prerequisiteRecords(field,mode)
  local ids=read(db.Quest[field],quest.id)
  for _,id in ipairs(type(ids)=='table' and ids or {}) do
   if #result.prerequisites>=24 then break end
   if type(id)=='number' and id==id and math.abs(id)<math.huge and id~=0 and id%1==0 then
    local positive=math.abs(id);local name=read(db.Quest.name,positive)
    local complete=C_QuestLog and read(C_QuestLog.IsQuestFlaggedCompleted,positive)
    result.prerequisites[#result.prerequisites+1]={id=positive,title=type(name)=='string' and name or ('Quest #'..positive),mode=mode,special=id<0,completed=type(complete)=='boolean' and complete or nil}
    -- Preserve explicit false; nil means the API could not establish status.
    if complete==false then result.prerequisites[#result.prerequisites].completed=false end
   end
  end
 end
 prerequisiteRecords('preQuestGroup','all');prerequisiteRecords('preQuestSingle','one')
 local function names(ids)
  local list={}
  for _,id in ipairs(type(ids)=='table' and ids or {}) do
   if #list>=12 then list[#list+1]='More prerequisites may apply';break end
   if type(id)=='number' and id==id and math.abs(id)<math.huge then
    local name=read(db.Quest.name,math.abs(id))
    local label=type(name)=='string' and name or ('Quest #'..tostring(math.abs(id)))
    list[#list+1]=label..(id<0 and ' (special condition; inspect giver)' or '')
   end
  end
  return list
 end
 local group=names(read(db.Quest.preQuestGroup,quest.id))
 local single=names(read(db.Quest.preQuestSingle,quest.id))
 if #group>0 then result.requirements[#result.requirements+1]='All: '..table.concat(group,', ') end
 if #single>0 then result.requirements[#result.requirements+1]='One of: '..table.concat(single,', ') end
 result.followups=names(read(db.Quest.childQuests,quest.id))
 -- nextQuestInChain controls availability; it is NOT necessarily a follow-up.
 local objectives=read(db.Quest.objectivesText,quest.id)
 for _,line in ipairs(type(objectives)=='table' and objectives or {}) do if type(line)=='string' then result.objectives[#result.objectives+1]=line end end
 return result
end
function R.GiverTargets(quest)
 local details=R.Details(quest);local targets={}
 for _,list in ipairs({details.pickups,details.turnins}) do
  for _,target in ipairs(list) do if not R.IsReported(quest,target) then targets[#targets+1]=target end end
 end
 return targets
end
function R.ResolveGiver(quest,target)
 if type(target)~='table' then return end
 local W=ForeverCompanionQuestWaypoints
 if not W or type(W.SameTarget)~='function' then return end
 for _,fresh in ipairs(R.GiverTargets(quest)) do if W.SameTarget(fresh,target) then return fresh end end
end
-- Preparation reports evidence without promising the quest can be accepted.
function R.Preparation(quest)
 local d=R.Details(quest)
 if not d.source then return 'Preparation: no matching reference data. Inspect the giver in game.' end
 local lines={'BEFORE YOU GO'}
 local level=read(UnitLevel,'player')
 if not (issecretvalue and issecretvalue(level)) and type(level)=='number' and level==level and level>0 and level<math.huge and type(d.minimum)=='number' and d.minimum==d.minimum and d.minimum>=0 and d.minimum<math.huge then
  lines[#lines+1]=level<d.minimum and ('Level '..level..' / reference minimum '..d.minimum..': level up first.') or ('Reference minimum level '..d.minimum..' reached.')
 else lines[#lines+1]='Minimum-level comparison unavailable.' end
 local allDone,allCount,alternatives,alternativeDone,special,unknown=0,0,0,0,false,false
 for _,p in ipairs(d.prerequisites) do
  special=special or p.special;unknown=unknown or p.completed==nil
  if p.mode=='all' then allCount=allCount+1;if p.completed then allDone=allDone+1 end
  else alternatives=alternatives+1;if p.completed then alternativeDone=alternativeDone+1 end end
 end
 if allCount>0 then lines[#lines+1]='Grouped prerequisites: '..allDone..' / '..allCount..' completed (client flags).' end
 if alternatives>0 then lines[#lines+1]='Alternative prerequisites: '..alternativeDone..' / '..alternatives..' completed; reference asks for one.' end
 if special then lines[#lines+1]='Special prerequisite conditions require checking the giver.' end
 if unknown then lines[#lines+1]='Some completion flags are unavailable; progress is unknown.' end
 if allCount+alternatives==0 then lines[#lines+1]='No prerequisites documented here; additional conditions may apply.' end
 lines[#lines+1]='Acceptance can also depend on race, class, reputation, events or other conditions. Confirm with the giver.'
 return table.concat(lines,'\n')
end
function R.DetailText(quest)
 local d=R.Details(quest)
 if not d.source then return 'Quest giver, prerequisites and follow-ups are not documented here. A compatible Forever QuestieDB may supply references. Your in-game quest log remains the source of truth.\n\nRewards: inspect the quest in game; no reward is guessed.' end
 local lines={d.source,R.Preparation(quest)}
 if type(d.minimum)=='number' and d.minimum>=0 then lines[#lines+1]='Minimum level (reference): '..d.minimum end
 lines[#lines+1]='Pickup: '..(#d.givers>0 and table.concat(d.givers,', ') or 'Giver not documented')
 lines[#lines+1]='Turn-in: '..(#d.finishers>0 and table.concat(d.finishers,', ') or 'Finisher not documented')
 lines[#lines+1]='Prerequisites: '..(#d.requirements>0 and table.concat(d.requirements,'; ') or 'Not documented; this does not prove none are required')
 for _,p in ipairs(d.prerequisites) do
  local status=p.completed==true and 'Completed (client flag)' or (p.completed==false and 'Not completed (client flag)' or 'Completion unknown')
  lines[#lines+1]=(p.mode=='all' and 'Required reference: ' or 'Alternative reference: ')..p.title..' — '..status..(p.special and '; special condition, inspect giver' or '')
 end
 lines[#lines+1]='Reported follow-ups: '..(#d.followups>0 and table.concat(d.followups,', ') or 'Not documented')
 lines[#lines+1]='Rewards: inspect the quest in game; no reward is guessed.'
 return table.concat(lines,'\n\n')
end
