-- An editable quest shortlist, never an automatic quest/route executor.
local P={limit=8}
ForeverCompanionLevelingPlan=P
local modes={nearby=true,turnins=true,pinned=true}
local function number(n)
 return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and n<math.huge and n>=0
end
function P.Identity(q)
 return type(q)=='table' and number(q.id) and q.id>0 and q.id%1==0 and
  type(q.title)=='string' and q.title~='' and #q.title<=300
end
local function same(a,b) return P.Identity(a) and P.Identity(b) and a.id==b.id and a.title==b.title end
function P.Settings()
 ForeverCompanionDB=type(ForeverCompanionDB)=='table' and ForeverCompanionDB or {}
 local saved=ForeverCompanionDB.levelingPlan
 if type(saved)~='table' then saved={} end
 local entries,seen={},{}
 for _,q in ipairs(type(saved.quests)=='table' and saved.quests or {}) do
  if P.Identity(q) and not seen[q.id] and #entries<P.limit then
   entries[#entries+1]={id=q.id,title=q.title};seen[q.id]=true
  end
 end
 saved.quests=entries
 saved.mode=modes[saved.mode] and saved.mode or 'nearby'
 saved.localOnly=saved.localOnly==true
 ForeverCompanionDB.levelingPlan=saved
 return saved
end
function P.Resolve(identity,quests,supported)
 if not supported or not P.Identity(identity) then return end
 local found,index,count=nil,nil,0
 for i,q in ipairs(type(quests)=='table' and quests or {}) do
  if P.Identity(q) and q.id==identity.id then count=count+1;if same(q,identity) then found,index=q,i end end
 end
 if count==1 then return found,index end
end
function P.Live(identity)
 local planner=ForeverCompanionQuestPlanner
 if not planner or not planner.IsSupported() then return end
 return P.Resolve(identity,planner.GetLive(),true)
end
function P.Contains(identity)
 for _,q in ipairs(P.Settings().quests) do if same(q,identity) then return true end end
 return false
end
function P.Add(identity)
 local q=P.Live(identity)
 if not q then return false,'Quest data changed or is unavailable. Refresh before adding.' end
 local entries=P.Settings().quests
 for _,entry in ipairs(entries) do if entry.id==q.id then return false,'This quest ID is already in your plan. Review the saved entry.' end end
 if #entries>=P.limit then return false,'Your plan has 8 quests. Remove one before adding another.' end
 entries[#entries+1]={id=q.id,title=q.title}
 return true,'Added to your leveling plan.'
end
function P.Remove(identity)
 local entries=P.Settings().quests
 for i,q in ipairs(entries) do if same(q,identity) then table.remove(entries,i);return true end end
 return false
end
function P.Move(identity,delta)
 if delta~=1 and delta~=-1 then return false end
 local entries=P.Settings().quests
 for i,q in ipairs(entries) do
  if same(q,identity) then
   local nextIndex=i+delta
   if not entries[nextIndex] then return false end
   entries[i],entries[nextIndex]=entries[nextIndex],entries[i];return true
  end
 end
 return false
end
function P.NextStep(q)
 if q.complete==true then return 'Ready to turn in: review the giver and remaining travel.' end
 for i,line in ipairs(type(q.objectives)=='table' and q.objectives or {}) do
  local state=type(q.objectiveStates)=='table' and q.objectiveStates[i]
  if type(line)=='string' and not (type(state)=='table' and state.known and state.done) then return line end
 end
 return 'Review quest details; no unfinished objective is reported.'
end
function P.Build(quests,locations,options)
 options=options or {};local result,counts,localQuests={},{},{}
 quests=type(quests)=='table' and quests or {}
 for _,q in ipairs(quests) do if P.Identity(q) then counts[q.id]=(counts[q.id] or 0)+1 end end
 local positioned=number(options.x) and options.x<=1 and number(options.y) and options.y<=1
 for _,entry in ipairs(type(locations)=='table' and locations or {}) do
  entry=type(entry)=='table' and entry or {}
  local q,t=entry.quest,entry.target
  if P.Identity(q) and type(t)=='table' and number(options.map) and options.map>0 and t.map==options.map and
   number(t.x) and t.x<=1 and number(t.y) and t.y<=1 then
   local d=positioned and ((t.x-options.x)^2+(t.y-options.y)^2) or nil
   local old=localQuests[q.id]
   if not old or (d and (not old.distance or d<old.distance)) then localQuests[q.id]={title=q.title,distance=d} end
  end
 end
 local query=type(options.query)=='string' and options.query:lower() or ''
 for index,q in ipairs(quests) do
  if P.Identity(q) and counts[q.id]==1 then
   local location=localQuests[q.id];if location and location.title~=q.title then location=nil end
   local zone=type(q.zone)=='string' and q.zone~='' and q.zone or 'Zone not reported'
   local haystack=(q.title..' '..zone..' '..q.id):lower()
   if (not options.localOnly or location) and (query=='' or haystack:find(query,1,true)) then
    local pinned=type(options.pins)=='table' and options.pins[q.id]==true
    local reasons={}
    if q.complete==true then reasons[#reasons+1]='Ready to turn in' end
    if pinned then reasons[#reasons+1]='Pinned by you' end
    reasons[#reasons+1]=location and 'Reported location on this map' or 'No reported location on this map'
    result[#result+1]={id=q.id,title=q.title,quest=q,index=index,zone=zone,ready=q.complete==true,pinned=pinned,
     nearby=location~=nil,distance=location and location.distance,reason=table.concat(reasons,' · '),nextStep=P.NextStep(q)}
   end
  end
 end
 local mode=modes[options.mode] and options.mode or 'nearby'
 local function rank(r)
  if mode=='turnins' then return (r.ready and 4 or 0)+(r.nearby and 2 or 0)+(r.pinned and 1 or 0) end
  if mode=='pinned' then return (r.pinned and 4 or 0)+(r.nearby and 2 or 0)+(r.ready and 1 or 0) end
  return (r.nearby and 4 or 0)+(r.ready and 2 or 0)+(r.pinned and 1 or 0)
 end
 table.sort(result,function(a,b)
  if rank(a)~=rank(b) then return rank(a)>rank(b) end
  if a.distance and b.distance and a.distance~=b.distance then return a.distance<b.distance end
  return a.index<b.index
 end)
 return result
end
function P.Saved(quests,supported)
 local result={}
 for index,saved in ipairs(P.Settings().quests) do
  local q=P.Resolve(saved,quests,supported)
  result[#result+1]={id=saved.id,title=saved.title,quest=q,planIndex=index,ready=q and q.complete==true,
   zone=q and q.zone or 'Unavailable',nextStep=q and P.NextStep(q) or 'Not confirmed in the current quest log. This does not mean completed.',
   reason=q and (q.complete==true and 'Ready to turn in' or 'Your saved order') or (supported and 'Missing or changed quest identity' or 'Quest scan unavailable')}
 end
 return result
end
function P.Zones(records)
 local byZone,result={},{}
 for _,r in ipairs(records) do
  local z=byZone[r.zone]
  if not z then z={name=r.zone,total=0,ready=0,nearby=0};byZone[r.zone]=z;result[#result+1]=z end
  z.total=z.total+1;z.ready=z.ready+(r.ready and 1 or 0);z.nearby=z.nearby+(r.nearby and 1 or 0)
 end
 table.sort(result,function(a,b) if a.ready~=b.ready then return a.ready>b.ready end;return a.name<b.name end)
 return result
end
function P.Act(identity,kind)
 local q,index=P.Live(identity)
 if not q then return false,'Quest data changed or is unavailable. Refresh and choose again.' end
 if kind=='guide' then
  if ForeverCompanionOpenQuestGuide(q.id) then return true,'Opened quest details.' end
  return false,'Quest details are unavailable. Refresh and choose again.'
 elseif kind=='map' then
  ForeverCompanionQuestPlanner.Select(index)
  return true,ForeverCompanionQuestWaypoints.Show(q)
 end
 return false,'Unknown action.'
end
