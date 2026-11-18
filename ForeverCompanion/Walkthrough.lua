-- Original zone itinerary. Quest progress and client markers take precedence over reference spawns.
local G={}
ForeverCompanionWalkthrough=G
local chapters={
 {1429,1,11,'A','Elwynn Forest','Start at Northshire Abbey, then use Goldshire as your hub. Finish the mine and farm objectives near each other before crossing to Eastvale.'},
 {1426,1,11,'A','Dun Morogh','Work outward from Coldridge Valley. At Kharanos, collect the nearby hunting and cave quests together before heading east to Loch Modan.'},
 {1438,1,11,'A','Teldrassil','Finish the Shadowglen loop, then bind in Dolanaar. Pick up the next errands before crossing the island toward Darnassus.'},
 {1411,1,12,'H','Durotar','Clear Valley of Trials, then collect the Senjin and Razor Hill quests. Finish coastal objectives together before turning north.'},
 {1412,1,12,'H','Mulgore','Begin on Red Cloud Mesa. Move your hearth to Bloodhoof Village and clear the nearby hunting grounds before the northern camps.'},
 {1420,1,12,'H','Tirisfal Glades','Work out from Deathknell to Brill. Pair the farm and mill objectives, then use the road west toward Silverpine.'},
 {2521,1,14,'B','Zephras Isle','Follow your faction introduction first. Keep delivery chains together and take the offered travel handoff when your starting settlement sends you onward.'},
 {1436,10,20,'A','Westfall','Start with the farm quests on the Elwynn road. Unlock Sentinel Hill, then clear a Defias camp and its nearby harvest fields on the same trip.'},
 {1432,10,20,'A','Loch Modan','Use Thelsamar as the return hub. Work the western road and trogg camps together, then check the eastern lodge before leaving the loch.'},
 {1439,10,21,'A','Darkshore','Bind at Auberdine. Take one coastal loop north and a separate loop south so you return with several completed quests each time.'},
 {1413,10,25,'H','The Barrens','Collect the Crossroads flight path. Work the nearby savannah before visiting Ratchet, then move your base to Camp Taurajo for the southern objectives.'},
 {1421,10,21,'H','Silverpine Forest','Collect the Sepulcher flight path. Finish the nearby farms and woods before moving south. Leave elite or dungeon work for a group.'},
 {1433,16,26,'A','Redridge Mountains','Use Lakeshire for supplies and turn-ins. Work the southern road before tackling the tougher gnoll and Blackrock camps.'},
 {1431,20,32,'A','Duskwood','Begin in Darkshire. Group eastern objectives first, then collect the Raven Hill and cemetery errands for a single western circuit.'},
 {1440,20,30,'B','Ashenvale','Alliance can stage at Astranaar and Horde at Splintertree Post. Keep the eastern and western objectives in separate trips.'},
 {1424,20,32,'B','Hillsbrad Foothills','Use Southshore or Tarren Mill for your faction. Collect nearby objectives before crossing the farms. Check elite labels before entering a keep.'},
 {1441,25,35,'B','Thousand Needles','Horde can begin around Freewind Post. On the Shimmering Flats, collect the raceway quests together before hunting around the outer rim.'},
 {1434,30,45,'B','Stranglethorn Vale','Start with the northern hunting camp and your faction camp. Combine the hunts by terrain. Save Booty Bay and the southern coast for a later pass.'},
 {1443,30,39,'B','Desolace','Use Nijel’s Point or Shadowprey Village for supplies. Check centaur faction requirements before choosing a camp to fight.'},
 {1417,30,40,'B','Arathi Highlands','Visit Refuge Pointe or Hammerfall. Pair nearby farm objectives and keep Stromgarde group work separate. Alliance can move to Farholde Keep at 36.'},
 {2548,36,46,'B','Riverglades','Alliance: reach level 36, then speak with Demar Brant at Farholde Keep. Wheeler’s Grange is your first western stop. Horde: check the available quests at Rog’mar before circling the river.'},
 {1445,35,45,'B','Dustwallow Marsh','Start at Theramore or Brackenwall Village. Pick up the local investigations before entering the marsh. Return by the road when your swamp objectives are ready.'},
 {1446,40,51,'B','Tanaris','Take the Gadgetzan flight path and collect the town quests. Combine the Wastewander objectives, then make a separate coastal trip for the pirate camps.'},
 {1444,40,51,'B','Feralas','Start at your faction hub. Finish one side of the zone at a time. Check the coast and island travel before committing to a long return journey.'},
 {1425,40,51,'B','The Hinterlands','Unlock Aerie Peak or Revantusk Village. Bundle the troll camps by location. Check the group requirement before climbing Jintha’Alor.'},
 {1419,46,56,'B','Blasted Lands','Collect the northern beast-part requests together. Check the required drops before selling animal parts, then turn them in as a batch.'},
 {1449,48,56,'B',"Un'Goro Crater",'Visit Marshal’s Refuge and take the flight path. Collect the overlapping wildlife, crystal and expedition objectives before making a circuit of the crater.'},
 {1448,48,57,'B','Felwood','Collect faction quests in the south, then push north in stages. Check the next handoff before leaving the road for a corrupted camp.'},
 {1422,50,60,'B','Western Plaguelands','Start at Chillwind Camp or the Bulwark. Work through the cauldron farms in chain order and return for the next handoff before riding farther east.'},
 {1428,50,60,'B','Burning Steppes','Start from your faction outpost. Clear open-world Blackrock camps while you travel and separate Blackrock Mountain dungeon objectives from solo work.'},
 {1452,53,60,'B','Winterspring','Use Everlook as the hub. Combine nearby yeti and wildlife objectives. Check escort and elite requirements before heading into the outer valleys.'},
 {1423,54,60,'B','Eastern Plaguelands','Collect the western hunting quests and unlock Light’s Hope Chapel. Work one plaguewood or tower cluster at a time rather than crossing the zone for each kill.'},
 {1451,55,60,'B','Silithus','Unlock Cenarion Hold. Complete the outdoor insect and scouting quests before considering hive elites. At 60, finish any remaining chains you want for rewards.'},
}
G.chapters=chapters
local byMap,records={},{}
for _,c in ipairs(chapters) do byMap[c[1]]=c;records[c[1]]={} end
for _,r in ipairs(ForeverCompanionWalkthroughRecords) do
 local list=records[r[6][2]]
 if list then list[#list+1]=r end
end
local function call(fn,...)
 if type(fn)=='function' then local ok,a,b,c=pcall(fn,...);if ok and not (issecretvalue and issecretvalue(a)) then return a,b,c end end
end
local function cfg()
 ForeverCompanionDB=ForeverCompanionDB or {}
 ForeverCompanionDB.walkthrough=ForeverCompanionDB.walkthrough or {skip={}}
 return ForeverCompanionDB.walkthrough
end
local function allowed(c,side) return c and (c[4]=='B' or c[4]==side:sub(1,1)) end
local starts={Human=1429,Dwarf=1426,Gnome=1426,NightElf=1438,Orc=1411,Troll=1411,Tauren=1412,Scourge=1420}
local riverOrder={
 Alliance={94613,94614,94617,94999,95156,94877,95561,95913,95961,95988,95957,95975},
 Horde={93787},
}
local riverTips={
 Alliance={
  {36,"Farholde > Wheeler's Grange. Start with Demar's horse investigation and batch Benjy's river and coyote objectives. Do the Meadowsbrook delivery if you're heading west."},
  {40,"Farholde > Sunnyglade. Collect the keep's objectives together. When Tessa sends you to Powderfuse Port, do the innkeeper errands on that trip."},
  {43,"Finish open Farholde, Sunnyglade and port chains. Continue in Tanaris if the remaining work stalls or needs a group."},
 },
 Horde={
  {36,"Rog'mar > river camps. Start with Krom'rosh around 59.4, 45.6. Pick up nearby quests before leaving the hub."},
  {40,"Finish the nearby river objectives before heading north to Bolder'ok. Keep Powderfuse Port errands together for one eastbound trip."},
  {43,"Finish open Rog'mar and Bolder'ok chains. Use Powderfuse Port for coastal errands or continue at Gadgetzan if a chain stalls."},
 },
}
local delivery={[94613]=true,[94999]=true,[95059]=true,[95961]=true,[95957]=true}
function G.ChapterTip(chapter,side,level)
 if chapter[1]~=2548 then return chapter[6] end
 local phases=riverTips[side] or riverTips.Alliance
 for i=#phases,1,-1 do if level>=phases[i][1] then return phases[i][2] end end
 return 'Return at level 36. Finish nearby quests before travelling to '..(side=='Horde' and "Rog'mar." or 'Farholde Keep.')
end
function G.Chapter(level,map,side,race,chosen)
 if allowed(byMap[chosen],side) then return byMap[chosen] end
 if map==2548 and level<36 then return byMap[2548] end
 if side=='Alliance' and level==36 and map==1417 then return byMap[2548] end
 local here=byMap[map]
 if allowed(here,side) and level>=here[2] and level<=here[3] then return here end
 if level<11 then return byMap[starts[race] or (race and race:lower():find('skyborne') and 2521) or (side=='Horde' and 1411 or 1429)] end
 local route=side=='Alliance' and {{16,1436},{20,1433},{30,1431},{36,1417},{44,2548},{49,1446},{54,1449},{57,1422},{61,1423}} or {{21,1413},{27,1424},{32,1441},{36,1434},{44,2548},{49,1446},{54,1449},{57,1422},{61,1423}}
 for _,v in ipairs(route) do if level<v[1] then return byMap[v[2]] end end
 return byMap[1423]
end
local function point(p)
 if p then return {label=p[1],map=p[2],x=p[3]/100,y=p[4]/100,source='Walkthrough reference'} end
end
local function place(t)
 if not t then return 'Check the quest log for the destination.' end
 return ('%s  |  %s  %.1f, %.1f'):format(t.label or 'Map marker',byMap[t.map] and byMap[t.map][5] or 'Map',t.x*100,t.y*100)
end
local function raceMatches(mask,bit)
 return mask==0 or (bit and bit>0 and math.floor(mask/bit)%2==1)
end
local function eligible(r,ctx,done)
 if r[4]>ctx.level or r[3]>ctx.level+3 or not raceMatches(r[5],ctx.bit) then return false end
 for _,id in ipairs(r[9]) do if done(id)~=true then return false end end
 if #r[10]>0 then
  for _,id in ipairs(r[10]) do if done(id)==true then return true end end
  return false
 end
 return true
end
function G.Build(chapter,ctx)
 local result,seen,reference,known={},{},{},{}
 if chapter[1]==2548 and ctx.level<36 then return result end
 local order={}
 for i,id in ipairs(chapter[1]==2548 and riverOrder[ctx.side or 'Alliance'] or {}) do order[id]=i end
 local function done(id)
  if known[id]==nil then local v=ctx.completed(id);known[id]=type(v)=='boolean' and (v and 1 or 0) or -1 end
  if known[id]>=0 then return known[id]==1 end
 end
 for _,r in ipairs(records[chapter[1]] or {}) do reference[r[1]]=r end
 local function add(id,title,action,detail,target,rank,level)
  if ctx.skip[id] then return end
  local distance=math.huge
  if ctx.map==chapter[1] and ctx.x and ctx.y and target and target.map==ctx.map then distance=(target.x-ctx.x)^2+(target.y-ctx.y)^2 end
  local index=seen[id]
  if index then
   local previous=result[index]
   -- Preserve live objectives and native offers; among equally reliable pickups choose the nearest.
   if previous.rank<rank or (previous.rank==rank and (action~='Pick up' or previous.distance<=distance)) then return end
  else
   index=#result+1;seen[id]=index
  end
  result[index]={id=id,title=title,action=action,detail=detail,target=target,rank=rank,level=level or ctx.level,distance=distance}
 end
 for _,q in ipairs(ctx.active) do
  local r=reference[q.id]
  if r or q.zone==chapter[5] then
   local target=ctx.location(q)
   local detail=ForeverCompanionLevelingPlan.NextStep(q)
   if q.complete then
    if target and target.kind=='pickup' then target=nil end
    target=target or (r and point(r[7]))
   elseif r and r[11] then detail=detail..'\n'..r[11] end
   if not q.complete and target and target.kind=='pickup' then target=nil end
   if not q.complete and not target and r and delivery[q.id] then target=point(r[7]) end
   if not q.complete and not target and r then
    for _,o in ipairs(r[8]) do
     if detail:lower():find(o[2]:lower(),1,true) then target=point({o[2],o[3],o[4],o[5]});break end
    end
   end
   add(q.id,q.title,q.complete and 'Turn in' or 'Objective',detail,target,q.complete and 1 or 2,r and r[3])
  end
 end
 for _,entry in ipairs(ctx.pickups) do
  local q,t=entry.quest,entry.target
  if t and t.map==chapter[1] and done(q.id)~=true and (not q.level or q.level<=ctx.level+3) then
   local r=reference[q.id]
   add(q.id,q.title,'Pick up',('Speak with '..(t.label or (r and r[6][1]) or 'the marked quest giver')..'.')..(r and r[11] and ('\n'..r[11]) or ''),t,entry.reference and 4 or 3,q.level or (r and r[3]))
  end
 end
 if not ctx.catalogReady then
  for _,r in ipairs(records[chapter[1]] or {}) do
   if done(r[1])==false and eligible(r,ctx,done) then
    local tip=r[11] or ('Look for '..r[6][1]..'. Turn-in contact: '..r[7][1]..'.')
    if not r[11] and r[8][1] then tip=tip..'\nObjective area: '..r[8][1][2]..' near '..r[8][1][4]..', '..r[8][1][5]..'.' end
    add(r[1],r[2],'Check pickup',tip..'\nReference location. Confirm the offer with the giver.',point(r[6]),5,r[3])
   end
  end
 end
 -- Rank confirmed steps on the player's map before a long return trip.
 -- Cells are only a neighborhood lookup; compare the actual coordinates.
 local cells={}
 local function key(x,y) return x..':'..y end
 for _,step in ipairs(result) do
  local t=step.target
  step.speedTier=3
  if step.rank==1 and ctx.rewardXP then
   local xp=ctx.rewardXP(step.id)
   if type(xp)=='number' and xp>0 and xp<math.huge then step.rewardXP=xp end
  end
  if t and t.map==ctx.map and type(ctx.x)=='number' and type(ctx.y)=='number' and step.rank<=4 then
   local dx,dy=t.x-ctx.x,t.y-ctx.y
   step.travel=math.sqrt(dx*dx+dy*dy)
   step.speedTier=step.travel<=.035 and 0 or (step.travel<=.12 and 1 or 2)
   local cell=key(math.floor(t.x/.035),math.floor(t.y/.035))
   cells[cell]=cells[cell] or {};table.insert(cells[cell],step)
  end
 end
 for _,step in ipairs(result) do
  if step.travel then
   local t=step.target;local cx,cy=math.floor(t.x/.035),math.floor(t.y/.035)
   local count=0
   local hubXP=step.rewardXP or 0
   for x=cx-1,cx+1 do for y=cy-1,cy+1 do
    for _,other in ipairs(cells[key(x,y)] or {}) do
     local dx,dy=other.target.x-t.x,other.target.y-t.y
     if other~=step and dx*dx+dy*dy<=.035*.035 then
      count=count+1
      if step.rank==1 and dx*dx+dy*dy<=.01*.01 then hubXP=hubXP+(other.rewardXP or 0) end
     end
    end
   end end
   if step.rank==1 and hubXP>0 then
    step.hubXP=hubXP
    step.ding=ctx.remainingXP and hubXP>=ctx.remainingXP and step.speedTier<=1 or false
   end
   step.neighbors=count
   step.cost=step.travel/(1+.22*math.min(count,4))
  end
 end
 table.sort(result,function(a,b)
  if ctx.focus and (a.id==ctx.focus)~=(b.id==ctx.focus) then return a.id==ctx.focus end
  if (a.ding==true)~=(b.ding==true) then return a.ding==true end
  if a.speedTier~=b.speedTier then return a.speedTier<b.speedTier end
  if a.speedTier==0 and a.rank~=b.rank then return a.rank<b.rank end
  if a.cost and b.cost and a.cost~=b.cost then return a.cost<b.cost end
  if a.rank~=b.rank then return a.rank<b.rank end
  if order[a.id]~=order[b.id] then return (order[a.id] or math.huge)<(order[b.id] or math.huge) end
  local al,bl=math.abs(a.level-ctx.level),math.abs(b.level-ctx.level)
  if (a.distance<.0025)~=(b.distance<.0025) then return a.distance<.0025 end
  if al~=bl then return al<bl end
  if a.distance~=b.distance then return a.distance<b.distance end
  return a.id<b.id
 end)
 return result
end
local frame,chapterText,chapterTip,currentTitle,currentBody,nextText,status
local chapterButton,followButton,locateButton,skipButton,backButton,pageText,compactButton,detailsButton,prevButton,nextButton
local rows,current,page={},nil,1
local following,lastSignature,lastOwner=false,nil,nil
local function currentMap() return C_Map and call(C_Map.GetBestMapForUnit,'player') end
local function context()
 local level=call(UnitLevel,'player') or 1
 local side=call(UnitFactionGroup,'player') or ''
 local _,race,id=call(UnitRace,'player')
 local bit=type(id)=='number' and id>=1 and id<=53 and 2^(id-1)
 if race and race:lower():find('skyborne') then bit=side=='Horde' and 8589934592 or 4294967296 end
 local db=ForeverCompanionQuestLocations.Provider()
 if db and db.Enum and db.Enum.raceMaskById then bit=db.Enum.raceMaskById[id] or bit end
 local map=currentMap()
 local ch=G.Chapter(level,map,side,race,cfg().chapter)
 local planner=ForeverCompanionQuestPlanner
 local live=planner.IsSupported() and planner.GetLive() or {}
 local pos=C_Map and map and call(C_Map.GetPlayerMapPosition,map,'player')
 local x,y;if pos then x,y=call(pos.GetXY,pos) end
 local w=ForeverCompanionQuestWaypoints
 local pickups=w.MapPickups(ch[1],live,true)
 local indexed=ForeverCompanionAvailableQuests.Status(ch[1])
 local ctx={level=level,map=map,side=side,bit=bit,x=x,y=y,active=live,pickups=pickups or {},skip=cfg().skip,focus=cfg().manualFocus,
  catalogReady=indexed.initialized and indexed.quests>0 and indexed.completion,
  completed=function(q) return C_QuestLog and call(C_QuestLog.IsQuestFlaggedCompleted,q) end,location=w.Location}
 local xp,maxXP=call(UnitXP,'player'),call(UnitXPMax,'player')
 if level<60 and type(xp)=='number' and type(maxXP)=='number' and xp>=0 and maxXP>xp then ctx.remainingXP=maxXP-xp end
 ctx.rewardXP=function(id) return call(GetQuestLogRewardXP,id) end
 return ch,ctx
end
local function signature(step)
 if not step then return end
 local target=step.target
 return table.concat({step.id,step.action,target and target.map or '',target and target.x or '',target and target.y or ''},'/')
end
local function directions(step)
 if not step or not step.target then return end
 local questID=(step.action=='Objective' or step.action=='Turn in') and step.id or nil
 return ForeverCompanionQuestWaypoints.Navigate(step.target,false,step.title,questID)
end
local function label(parent,x,y,w,h,size)
 local t=ForeverCompanionInterface.Text(parent,size);t:SetPoint('TOPLEFT',x,-y)
 t:SetWidth(w);t:SetHeight(h);t:SetJustifyH('LEFT');t:SetJustifyV('TOP');t:SetWordWrap(true);return t
end
local function button(x,y,w,name,fn)
 local b=ForeverCompanionInterface.Button(frame);b:SetPoint('TOPLEFT',x,-y);b:SetSize(w,28)
 b:SetText(name);b:SetScript('OnClick',fn);return b
end
local function ownsTarget(active,owner)
 return active and owner and active.label==owner.title and active.map==owner.map
  and active.x==owner.x and active.y==owner.y
end
local function clearFollowTarget()
 if lastOwner then
  local active=ForeverCompanionQuestWaypoints.Active()
  if ownsTarget(active,lastOwner) then ForeverCompanionQuestWaypoints.Clear() end
 end
 lastOwner=nil;lastSignature=nil
end
local function stopFollowing()
 following=false;clearFollowTarget()
end
function G.Refresh()
 if not frame or not frame:IsShown() then return end
 local ch,ctx=context()
 local steps=G.Build(ch,ctx);G.steps=steps
 current=steps[1]
 if cfg().manualFocus and (not current or current.id~=cfg().manualFocus) then cfg().manualFocus=nil end
 chapterText:SetText(ch[5]..'  |  Levels '..ch[2]..'–'..ch[3]..'  |  You: '..ctx.level)
 chapterTip:SetText(G.ChapterTip(ch,ctx.side,ctx.level))
 currentTitle:SetText(current and (current.action..'   '..current.title..(current.level and current.level>0 and ('  (Lv. '..current.level..')') or '')) or (ch[1]==2548 and ctx.level<36 and 'Reach level 36' or 'No available step in this chapter'))
 local detail=current and current.detail
 if current and current.ding then detail=('Turn-ins here offer %d XP. You need %d XP for level %d.'):format(current.hubXP,ctx.remainingXP,ctx.level+1) end
 currentBody:SetText(current and (detail..'\n'..(current.target and place(current.target) or 'Open quest details for the full objective.')) or
  (ch[1]==2548 and ctx.level<36 and G.ChapterTip(ch,ctx.side,ctx.level) or 'Review another zone under Chapters, restore skipped quests, or check a local quest giver.'))
 nextText:SetText(current and current.neighbors and current.neighbors>0 and ('Nearby: '..current.neighbors..' other quest step'..(current.neighbors==1 and '' or 's')..' in this area') or 'Upcoming steps')
 local pages=math.max(1,math.ceil((#steps-1)/3));page=math.max(1,math.min(page,pages))
 for i,b in ipairs(rows) do
  local s=steps[(page-1)*3+i+1];b.step=s;b:SetShown(s~=nil and not cfg().compact)
  if s then b:SetText(s.action..'   '..s.title..(s.target and ('   ·   '..(s.target.label or 'Map marker')) or '')) end
 end
 local tracker=ForeverCompanionSessionProgress
 local session=tracker and tracker.Snapshot and tracker.Snapshot()
 local pace=session and not session.paused and session.rate and ('  |  '..math.floor(session.rate)..' XP/hr') or ''
 pageText:SetText(#steps..' steps available  |  Page '..page..' of '..pages..pace)
 locateButton:SetEnabled(current and current.target~=nil or false);skipButton:SetEnabled(current~=nil)
 backButton:SetEnabled(next(cfg().skip)~=nil)
 followButton:SetText(following and 'Follow: on' or 'Follow: off')
 if following then
  local sig=signature(current)
  local w=ForeverCompanionQuestWaypoints
  local active=w.Active()
  if lastOwner and active and not ownsTarget(active,lastOwner) then
   stopFollowing();followButton:SetText('Follow: off');status:SetText('Following paused because another destination was selected.')
  elseif sig~=lastSignature then
   if current and current.target and not call(InCombatLockdown) then
    local msg=directions(current);status:SetText(msg or '')
    local owner={title=current.title,map=current.target.map,x=current.target.x,y=current.target.y}
    if ownsTarget(w.Active(),owner) then lastOwner=owner else clearFollowTarget() end
    lastSignature=sig
   elseif not current or not current.target then
    clearFollowTarget()
    lastSignature=sig
    status:SetText('Follow is waiting for a reported destination.')
   end
  end
 end
end
local function layout()
 local compact=cfg().compact==true
 local function move(widget,x,y)
  widget:ClearAllPoints();widget:SetPoint('TOPLEFT',x,-y)
 end
 frame:SetHeight(compact and 297 or 520)
 move(currentTitle,18,compact and 77 or 126)
 move(currentBody,18,compact and 115 or 168)
 move(status,18,compact and 239 or 462)
 for i,b in ipairs({locateButton,followButton,skipButton,backButton,detailsButton}) do
  move(b,({18,157,291,393,545})[i],compact and 204 or 253)
 end
 for _,element in ipairs({chapterTip,nextText,prevButton,nextButton,pageText}) do element:SetShown(not compact) end
 compactButton:SetText(compact and 'Expand' or 'Compact')
end
local function choose(map)
 stopFollowing();cfg().chapter=map;cfg().manualFocus=nil;page=1;status:SetText('');G.Refresh()
end
local function menu(anchor)
 local U=ForeverCompanionInterface;local side=UnitFactionGroup('player') or ''
 local entries={{label='Automatic chapter for my character',action=function() choose(nil) end}}
 for _,range in ipairs({{1,9},{10,19},{20,29},{30,39},{40,49},{50,60}}) do
  local lo,hi=range[1],range[2]
  entries[#entries+1]={label='Chapters starting at '..lo..'–'..hi,action=function()
   local options={}
   for _,c in ipairs(chapters) do if allowed(c,side) and c[2]>=lo and c[2]<=hi then
    local map=c[1];options[#options+1]={label=c[5]..'  '..c[2]..'–'..c[3],action=function() choose(map) end}
   end end
   U.Menu(anchor,'Choose a zone',options,nil,270)
  end}
 end
 U.Menu(anchor,'1–60 chapters',entries,nil,260)
end
function G.Open()
 if not frame then
  local U=ForeverCompanionInterface
  frame=CreateFrame('Frame','ForeverCompanionWalkthroughFrame',UIParent,'BackdropTemplate')
  frame:SetSize(746,520);frame:SetPoint('CENTER');frame:SetFrameStrata('DIALOG');U.Surface(frame)
  U.PreparePanel(frame,'ForeverCompanionWalkthroughFrame',746,520);U.CloseButton(frame,function() frame:Hide() end)
  chapterText=label(frame,18,12,555,28,17);chapterButton=button(566,40,160,'Chapters',menu)
  compactButton=button(456,40,102,'Compact',function() cfg().compact=not cfg().compact;layout();G.Refresh() end)
  chapterTip=label(frame,18,48,429,72,13)
  currentTitle=label(frame,18,126,708,38,19);currentBody=label(frame,18,168,708,84,14)
  locateButton=button(18,253,130,'Directions',function() G.Refresh();status:SetText(directions(current) or 'No destination available.') end)
  followButton=button(157,253,124,'Follow: off',function()
   if following then stopFollowing() else following=true;lastSignature=nil end;G.Refresh()
  end)
  skipButton=button(291,253,92,'Skip quest',function()
   if current then cfg().skip[current.id]=true;cfg().manualFocus=nil;page=1;G.Refresh() end
  end)
  backButton=button(393,253,142,'Restore skipped',function() cfg().skip={};page=1;G.Refresh() end)
  detailsButton=button(545,253,181,'Quest details',function()
   if current and (current.action=='Objective' or current.action=='Turn in') and ForeverCompanionOpenQuestGuide then ForeverCompanionOpenQuestGuide(current.id)
   elseif current then status:SetText(current.detail) end
  end)
  nextText=label(frame,18,296,400,22,14)
  for i=1,3 do local b=button(18,319+(i-1)*32,708,'',function(self)
   if self.step then cfg().manualFocus=self.step.id;page=1;G.Refresh() end
  end);rows[i]=b end
  local function wheel(_,delta) if not cfg().compact then page=page+(delta<0 and 1 or -1);G.Refresh() end end
  frame:EnableMouseWheel(true);frame:SetScript('OnMouseWheel',wheel)
  for _,b in ipairs(rows) do b:EnableMouseWheel(true);b:SetScript('OnMouseWheel',wheel) end
  prevButton=button(18,420,92,'Previous',function() page=page-1;G.Refresh() end)
  pageText=label(frame,124,427,480,21,12)
  nextButton=button(634,420,92,'Next',function() page=page+1;G.Refresh() end)
  status=label(frame,18,462,708,48,12);frame:HookScript('OnHide',stopFollowing)
 end
 layout();frame:Show();G.Refresh()
end
SLASH_FCWALKTHROUGH1='/fcguide'
SlashCmdList.FCWALKTHROUGH=G.Open
local watcher=CreateFrame('Frame')
for _,e in ipairs({'PLAYER_XP_UPDATE','QUEST_LOG_UPDATE','QUEST_ACCEPTED','QUEST_TURNED_IN','PLAYER_LEVEL_UP','ZONE_CHANGED_NEW_AREA','PLAYER_REGEN_ENABLED'}) do pcall(watcher.RegisterEvent,watcher,e) end
local queued=false
watcher:SetScript('OnEvent',function()
 if not frame or not frame:IsShown() or queued then return end
 if C_Timer and C_Timer.After then queued=true;C_Timer.After(.25,function() queued=false;G.Refresh() end) else G.Refresh() end
end)

