-- A leveling reference plus a live quest-log recommendation.
local J={}
ForeverCompanionJourney=J

local starter={
 Human={"Elwynn Forest",1429}, Dwarf={"Dun Morogh",1426}, Gnome={"Dun Morogh",1426},
 NightElf={"Teldrassil",1438}, Orc={"Durotar",1411}, Troll={"Durotar",1411},
 Tauren={"Mulgore",1412}, Scourge={"Tirisfal Glades",1420}, Skyborne={"Zephras Isle",2521,"Skyborne start · levels 1–12"},
}
local follow={
 Human=1436, Dwarf=1432, Gnome=1432, NightElf=1439,
 Orc=1413, Troll=1413, Tauren=1413, Scourge=1421,
}
local brackets={
 {1,9,"Start near home",{},{}},
 {10,19,"Find your first quest hub",
  {{"Westfall",1436},{"Loch Modan",1432},{"Darkshore",1439}},
  {{"The Barrens",1413},{"Silverpine Forest",1421}}},
 {20,29,"Follow a zone story",
  {{"Redridge Mountains",1433,"Earlier in this bracket"},{"Duskwood",1431},{"Wetlands",1437}},
  {{"Stonetalon Mountains",1442,"Earlier in this bracket"},{"Ashenvale",1440},{"Hillsbrad Foothills",1424}}},
 {30,39,"Open the mid-level zones",
  {{"Arathi Highlands",1417},{"Stranglethorn Vale",1434},{"Desolace",1443}},
  {{"Thousand Needles",1441,"Earlier in this bracket"},{"Stranglethorn Vale",1434},{"Desolace",1443}}},
 {40,49,"Explore a new frontier",
  {{"Riverglades",2548,"Forever zone · mid-30s to mid-40s"},{"Tanaris",1446},{"Feralas",1444}}},
 {50,60,"Finish your journey",
  {{"Un'Goro Crater",1449},{"Western Plaguelands",1422},{"Winterspring",1452,"Later in this bracket"}}},
}

function J.Stage(level)
 for i,band in ipairs(brackets) do
  if level and level>=band[1] and level<=band[2] then return i end
 end
 return level and level>60 and #brackets or 1
end

function J.Route(stage,level,faction,race)
 local band=brackets[stage]
 if not band then return {} end
 local home=starter[race]
 if stage==1 or (stage==2 and home==starter.Skyborne and level and level<=12) then
  return home and {home} or {}
 end
 local zones=band[5] and (faction=="Horde" and band[5] or faction=="Alliance" and band[4]) or band[4]
 if band[5] and faction~="Horde" and faction~="Alliance" then return {} end
 if stage~=2 or not follow[race] then return zones end
 local ordered={}
 for _,zone in ipairs(zones) do if zone[2]==follow[race] then ordered[#ordered+1]=zone end end
 for _,zone in ipairs(zones) do if zone[2]~=follow[race] then ordered[#ordered+1]=zone end end
 return ordered
end

function J.Recommend(quests,mapLocations,selected)
 local localQuests={}
 for _,entry in ipairs(mapLocations) do localQuests[entry.quest]=true end
 local best,index,score
 for i,quest in ipairs(quests) do
  local rank=(localQuests[quest] and 4 or 0)+(quest.complete and 2 or 0)+(quest==selected and 1 or 0)
  if not score or rank>score then best,index,score=quest,i,rank end
 end
 return best,index
end

-- A short visit order from actual current-map quest locations. This does
-- not resolve terrain, quest prerequisites, or multiple objectives for a quest.
function J.LocalRoute(quests,locations,x,y,limit)
 local function valid(n) return not (issecretvalue and issecretvalue(n)) and type(n)=="number" and n>=0 and n<=1 end
 if not valid(x) or not valid(y) then return {} end
 local live,used,result={},{},{}
 for i,q in ipairs(quests) do live[q]=i end
 local count=math.min(5,limit or 3)
 for _=1,count do
  local best,distance,priority
  for _,entry in ipairs(locations) do
   local q,p=entry.quest,entry.target
   if live[q] and not used[q] and type(p)=="table" and valid(p.x) and valid(p.y) then
    local pinned=ForeverCompanionQuestPlanner and ForeverCompanionQuestPlanner.IsPinned(q)
    local rank=pinned and 2 or (q.complete and 1 or 0)
    local d=(p.x-x)^2+(p.y-y)^2
    if not best or rank>priority or (rank==priority and (d<distance or (d==distance and live[q]<live[best.quest]))) then
     best,distance,priority=entry,d,rank
    end
   end
  end
  if not best then break end
  result[#result+1]={quest=best.quest,target=best.target,index=live[best.quest]}
  used[best.quest]=true
  x,y=best.target.x,best.target.y
 end
 return result
end

function J.FormatLocalRoute()
 local planner=ForeverCompanionQuestPlanner
 if not planner or not planner.IsSupported() then return "NEARBY STOPS: Open the quest log for current data." end
 local ok,mapID=pcall(function() return C_Map.GetBestMapForUnit("player") end)
 if not ok or not mapID then return "NEARBY STOPS: Player map unavailable." end
 local positionOK,x,y=pcall(function()
  local p=C_Map.GetPlayerMapPosition(mapID,"player")
  if p then return p:GetXY() end
 end)
 if not positionOK then return "NEARBY STOPS: Player position unavailable." end
 local quests=planner.GetLive()
 local locations=ForeverCompanionQuestWaypoints.MapLocations(mapID,quests)
 local stops=J.LocalRoute(quests,locations,x,y,3)
 local lines={"NEARBY QUEST STOPS (current map)","Pinned quests first, then turn-ins; approximate map distance within each group. Terrain and prerequisites are not evaluated."}
 for i,stop in ipairs(stops) do
  lines[#lines+1]=i..". "..(stop.quest.complete and "Turn in: " or "Objective: ")..stop.quest.title
 end
 if #stops==0 then lines[#lines+1]="No reported destinations here. Check another quest zone; no coordinates have been guessed." end
 lines[#lines+1]="One stop per quest. Review every remaining objective before leaving a zone. Select a quest and click its map marker to start navigation."
 return table.concat(lines,"\n")
end

local root,kind,title,detail,hint,mapButton,stageText,previous,nextStage,rows
local overrideStage,actionQuest,actionIndex,zoneNote,actionPickup
local queueRows,queueEmpty,levelBadge,queueStatus
function J.PickupStops(entries,x,y,limit)
 local grouped=ForeverCompanionQuestDiscovery.Filter(entries,'',false,{sort='recommended',x=x,y=y})
 local result={}
 for i=1,math.min(limit or 3,#grouped) do
  local item=grouped[i]
  result[i]={quest=item.quest,target=item.targets[1],pickup=true,reference=item.targets[1].reference}
 end
 return result
end
local function label(parent,x,y,w,size,color)
 local text=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 text:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 text:SetWidth(w)
 text:SetJustifyH("LEFT")
 ForeverCompanionVisualTheme.Font(text,size)
 text:SetTextColor(color[1],color[2],color[3])
 return text
end

local function button(parent,x,y,width,caption,click)
 local widget=ForeverCompanionInterface.Button(parent)
 widget:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 widget:SetSize(width,24)
 widget:SetText(caption)
 widget:SetScript("OnClick",click)
 return widget
end

local function card(x,y,w,h)
 local panel=CreateFrame("Frame",nil,root)
 panel:SetPoint("TOPLEFT",root,"TOPLEFT",x,y)
 panel:SetSize(w,h)
 ForeverCompanionVisualTheme.Panel(panel,w,h)
 return panel
end

function J.Create(parent,navigate)
 root=CreateFrame("Frame",nil,parent)
 root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-6)
 root:SetSize(770,398)
 local gold,white,muted={1,.81,.43},{.93,.96,1},{.69,.79,.86}
 local task=card(0,0,770,158)
 kind=label(task,15,-12,580,13,{.38,.87,1})
 levelBadge=label(task,641,-12,112,12,gold)
 title=label(task,15,-38,735,21,white)
 detail=label(task,15,-72,735,13,muted)
 hint=label(task,316,-121,437,12,muted)
 mapButton=button(task,15,-117,143,"Find on map",function()
  if actionPickup then ForeverCompanionQuestWaypoints.Navigate(actionPickup.target,true,actionPickup.quest.title);return end
  if not actionQuest or not ForeverCompanionQuestPlanner.IsSupported() then return end
  local quest=actionQuest
  ForeverCompanionQuestPlanner.Select(actionIndex)
  hint:SetText(ForeverCompanionQuestWaypoints.Show(quest))
 end)
 button(task,170,-117,129,"Quest journal",function() navigate("Quests") end)
 local route=card(0,-171,470,217)
 local queue=card(482,-171,288,217)
 label(queue,15,-12,175,13,gold):SetText("UP NEXT")
 queueStatus=label(queue,194,-12,78,11,muted)
 queueEmpty=label(queue,15,-63,258,13,muted)
 queueEmpty:SetHeight(80)
 queueRows={}
 for i=1,3 do
  local item=CreateFrame("Frame",nil,queue)
  item:SetPoint("TOPLEFT",queue,"TOPLEFT",12,-43-(i-1)*45);item:SetSize(264,40)
  local bg=item:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(item);bg:SetColorTexture(.045,.052,.065,1)
  local number=label(item,7,-9,20,12,gold);number:SetText(i)
  item.title=label(item,30,-6,170,12,white);item.title:SetWordWrap(false);item.title:SetHeight(17)
  item.status=label(item,30,-23,170,10,muted);item.status:SetWordWrap(false);item.status:SetHeight(14)
  item.view=button(item,205,-7,52,"View",function()
   if item.stop and item.stop.pickup then
    ForeverCompanionQuestWaypoints.Navigate(item.stop.target,true,item.stop.quest.title);return
   end
   local p=ForeverCompanionQuestPlanner
   if item.stop and p.IsSupported() and p.GetLive()[item.stop.index]==item.stop.quest then
    p.Select(item.stop.index);navigate("Quests")
   end
  end)
  queueRows[i]=item
 end
 stageText=label(route,15,-12,440,15,gold)
 previous=button(route,15,-181,83,"Previous",function() J.ChangeStage(-1) end)
 button(route,106,-181,96,"My level",function() J.ChangeStage(0) end)
 nextStage=button(route,210,-181,83,"Next",function() J.ChangeStage(1) end)
 rows={}
 for i=1,3 do
  local y=-44-(i-1)*42
  local row=CreateFrame("Frame",nil,route)
  row:SetPoint("TOPLEFT",route,"TOPLEFT",13,y)
  row:SetSize(444,37)
  local bg=row:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(row);bg:SetColorTexture(.075,.11,.16,1)
  row.title=label(row,11,-10,221,13,white)
  row.title:SetWordWrap(false);row.title:SetHeight(18)
  row.detail=label(row,237,-11,122,10,muted)
  row.detail:SetWordWrap(false);row.detail:SetHeight(15)
  row.map=button(row,370,-6,65,"Open map",function()
   if row.zone then ForeverCompanionQuestWaypoints.OpenMap(row.zone[2]) end
  end)
  rows[i]=row
 end
 zoneNote=label(queue,15,-183,258,10,muted)
 zoneNote:SetHeight(28)
 ForeverCompanionObjectiveRoute.Create(root)
 root:Hide()
end

local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,a,b=pcall(fn,...)
 if ok then return a,b end
end

local currentStage=1
function J.ChangeStage(delta)
 overrideStage=delta~=0 and math.max(1,math.min(#brackets,(overrideStage or currentStage)+delta)) or nil
 if ForeverCompanionRefresh then ForeverCompanionRefresh() end
end

function J.Show(show,level)
 if not root then return end
 if not show then root:Hide();overrideStage=nil;return end
 root:Show()
 ForeverCompanionObjectiveRoute.Refresh()
 currentStage=J.Stage(level)
 local stage=overrideStage or currentStage
 local band=brackets[stage]
 local faction=read(UnitFactionGroup,"player")
 local _,race=read(UnitRace,"player")
 local zones=J.Route(stage,level,faction,race)
 local map=C_Map and read(C_Map.GetBestMapForUnit,"player")
 local planner=ForeverCompanionQuestPlanner
 actionQuest,actionIndex,actionPickup=nil,nil,nil
 local upcoming={}
 local position=map and C_Map and read(C_Map.GetPlayerMapPosition,map,"player")
 local x,y
 if position then x,y=read(position.GetXY,position) end
 levelBadge:SetText("LEVEL "..tostring(level or "?"))
 if planner.IsSupported() then
  local quests=planner.GetLive()
  local locations=map and ForeverCompanionQuestWaypoints.MapLocations(map,quests) or {}
  local stops=J.LocalRoute(quests,locations,x,y,3)
  upcoming=stops
  if stops[1] then actionQuest,actionIndex=stops[1].quest,stops[1].index
  else actionQuest,actionIndex=J.Recommend(quests,locations,planner.GetSelected()) end
 end
 if not actionQuest and map then
  local pickups=ForeverCompanionQuestWaypoints.MapPickups(map,planner.GetLive(),true)
  upcoming=J.PickupStops(pickups,x,y,3)
  actionPickup=upcoming[1]
 end
 queueStatus:SetText(#upcoming>0 and (#upcoming..(actionPickup and " PICKUPS" or " STOPS")) or "NO ROUTE")
 queueEmpty:SetShown(#upcoming==0)
 queueEmpty:SetText("No reported destinations nearby. Open the quest journal to choose a quest or another zone.")
 for i,item in ipairs(queueRows) do
  local stop=upcoming[i]
  item.stop=stop;item:SetShown(stop~=nil)
  if stop then
   item.title:SetText(stop.quest.title)
   item.status:SetText(stop.pickup and (stop.reference and "Pickup · database reference" or "Pickup · client reported") or (planner.IsPinned(stop.quest) and "Pinned priority" or (stop.quest.complete and "Ready to turn in" or "Quest objective")))
  end
 end
 local quest=actionQuest
 if actionPickup then
  kind:SetText("NEXT STEP   ·   PICK UP A QUEST")
  title:SetText(actionPickup.quest.title)
  detail:SetText("Visit "..(actionPickup.target.label or "the quest giver").." and inspect the quest in game.")
  hint:SetText(actionPickup.reference and "Database reference; confirm additional requirements with the giver." or "Quest start reported by your client. Select Find on map to navigate.")
 elseif quest then
  kind:SetText(quest.complete and "NEXT STEP   ·   TURN IN" or "NEXT STEP   ·   QUEST OBJECTIVE")
  title:SetText(quest.title)
  local step
  for i,line in ipairs(quest.objectives or {}) do
   local state=quest.objectiveStates and quest.objectiveStates[i]
   if not state or not state.done then step=line;break end
  end
  detail:SetText(quest.complete and ("Return to the quest giver  ·  "..quest.zone) or (step or ("Check the quest journal for details  ·  "..quest.zone)))
  hint:SetText("Suggested stop; check terrain. Click map marker for arrow.")
 else
  kind:SetText("NEXT STEP   ·   FIND A QUEST")
  title:SetText(planner.IsSupported() and "Visit a nearby quest hub" or "Open your in-game quest log")
  detail:SetText("Look for a yellow ! near the starter camp or town. Accept a quest to see its next step here.")
  hint:SetText("")
 end
 mapButton:SetEnabled(quest~=nil or actionPickup~=nil)
 stageText:SetText(("Levels %d–%d  ·  %s"):format(band[1],band[2],band[3]))
 previous:SetEnabled(stage>1);nextStage:SetEnabled(stage<#brackets)
 for i,row in ipairs(rows) do
  local zone=zones[i]
  row.zone=zone
  if zone then
   local info=C_Map and read(C_Map.GetMapInfo,zone[2])
   row.title:SetText(info and info.name or zone[1])
   row.detail:SetText(map==zone[2] and "You are here" or zone[3] or "Questing zone")
   row.map:SetEnabled(info~=nil)
   row:Show()
  else row:Hide() end
 end
 zoneNote:SetText(#zones>0 and "Approximate map order. Check terrain and remaining objectives." or
  "Follow the quests near your starting camp. Zone suggestions appear when your race and faction are available.")
end

function J.GetHeight() return 416+ForeverCompanionObjectiveRoute.GetHeight() end
