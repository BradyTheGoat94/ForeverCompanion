-- A bounded, per-character ledger of observed turn-ins, never inferred dates.
local H={limit=300}
ForeverCompanionQuestHistory=H
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
local function number(n,min)
 if issecretvalue and issecretvalue(n) then return nil end
 if type(n)=='number' and n==n and n<math.huge and n>=min and n==math.floor(n) then return n end
end
local function text(s,limit)
 if issecretvalue and issecretvalue(s) then return nil end
 if type(s)=='string' and s~='' then
  s=s:gsub('[\r\n\t|]',' '):match('^%s*(.-)%s*$')
  if s=='' then return nil end
  local last=math.min(#s,limit or 150)
  while last>0 do local nextByte=s:byte(last+1);if not nextByte or nextByte<128 or nextByte>=192 then break end;last=last-1 end
  return s:sub(1,last)
 end
end
local function now() return number(read(GetServerTime) or read(time),1) end
local function ensure()
 ForeverCompanionDB=ForeverCompanionDB or {}
 local db=ForeverCompanionDB
 if type(db.questHistory)~='table' then db.questHistory={entries={},startedAt=now()} end
 local history=db.questHistory
 if type(history.entries)~='table' then history.entries={} end
 local clean,seen,maxSequence={},{},0
 for _,entry in ipairs(history.entries) do if type(entry)=='table' and number(entry.sequence,1) then maxSequence=math.max(maxSequence,entry.sequence) end end
 for _,entry in ipairs(history.entries) do
  if type(entry)=='table' and number(entry.id,1) and text(entry.title) then
   local sequence=number(entry.sequence,1)
   if not sequence or seen[sequence] then maxSequence=maxSequence+1;sequence=maxSequence end
   seen[sequence]=true
   clean[#clean+1]={id=entry.id,sequence=sequence,title=text(entry.title),xp=number(entry.xp,0),money=number(entry.money,0),at=number(entry.at,1),map=number(entry.map,1),mapName=text(entry.mapName),questZone=text(entry.questZone),level=number(entry.level,1)}
  end
 end
 while #clean>H.limit do table.remove(clean,1) end
 history.entries=clean
 history.nextSequence=math.max(number(history.nextSequence,1) or 1,maxSequence+1)
 return history
end
function H.Record(id,xp,money,context)
 if not number(id,1) then return false end
 context=context or {}
 local q=context.quest
 if q and q.id~=id then q=nil end
 if not q and ForeverCompanionQuestPlanner then
  for _,candidate in ipairs(ForeverCompanionQuestPlanner.GetLive()) do if candidate.id==id then q=candidate;break end end
 end
 local title=text(q and q.title) or text(C_QuestLog and read(C_QuestLog.GetTitleForQuestID,id))
 if not title then
  local provider=ForeverCompanionQuestLocations and ForeverCompanionQuestLocations.Provider()
  title=text(provider and read(provider.Quest.name,id))
 end
 local map=number(context.map or (C_Map and read(C_Map.GetBestMapForUnit,'player')),1)
 local info=map and C_Map and read(C_Map.GetMapInfo,map)
 local history=ensure()
 local entry={id=id,sequence=history.nextSequence,title=title or ('Quest '..id),xp=number(xp,0),money=number(money,0),at=number(context.at,1) or now(),map=map,
  mapName=text(info and info.name),questZone=text(q and q.zoneKnown and q.zone),level=number(read(UnitLevel,'player'),1)}
 history.entries[#history.entries+1]=entry
 history.nextSequence=history.nextSequence+1
 while #history.entries>H.limit do table.remove(history.entries,1) end
 if ForeverCompanionQuestBook then ForeverCompanionQuestBook.Refresh() end
 return true,entry
end
function H.List(query,map)
 local result={}
 query=string.lower(type(query)=='string' and query or '')
 local entries=ensure().entries
 for i=#entries,1,-1 do
  local entry=entries[i]
  local haystack=string.lower(entry.title..' '..(entry.questZone or '')..' '..(entry.mapName or '')..' '..entry.id)
  if (not map or entry.map==map) and haystack:find(query,1,true) then result[#result+1]=entry end
 end
 return result
end
function H.Summary(entries)
 local result={turnins=0,unique=0,xp=0,money=0,xpKnown=0,moneyKnown=0}
 local seen={}
 for _,entry in ipairs(entries or H.List()) do
  result.turnins=result.turnins+1
  if not seen[entry.id] then seen[entry.id]=true;result.unique=result.unique+1 end
  if number(entry.xp,0) then result.xp=result.xp+entry.xp;result.xpKnown=result.xpKnown+1 end
  if number(entry.money,0) then result.money=result.money+entry.money;result.moneyKnown=result.moneyKnown+1 end
 end
 return result
end
function H.Money(value)
 if not number(value,0) then return 'Not reported' end
 return math.floor(value/10000)..'g '..math.floor(value/100)%100 ..'s '..value%100 ..'c'
end
local events=CreateFrame('Frame')
pcall(events.RegisterEvent,events,'QUEST_TURNED_IN')
events:SetScript('OnEvent',function(_,event,id,xp,money) if event=='QUEST_TURNED_IN' then H.Record(id,xp,money) end end)
