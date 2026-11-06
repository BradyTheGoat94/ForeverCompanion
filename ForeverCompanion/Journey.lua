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

local root,kind,title,detail,hint,mapButton,stageText,previous,nextStage,rows
local overrideStage,actionQuest,actionIndex,zoneNote
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
 local widget=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
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
 kind=label(task,15,-12,735,13,{.38,.87,1})
 title=label(task,15,-38,735,21,white)
 detail=label(task,15,-72,735,13,muted)
 hint=label(task,316,-121,437,12,muted)
 mapButton=button(task,15,-117,143,"Find on map",function()
  if not actionQuest or not ForeverCompanionQuestPlanner.IsSupported() then return end
  local quest=actionQuest
  ForeverCompanionQuestPlanner.Select(actionIndex)
  hint:SetText(ForeverCompanionQuestWaypoints.Show(quest))
 end)
 button(task,170,-117,129,"Quest journal",function() navigate("Quests") end)
 local route=card(0,-171,770,217)
 stageText=label(route,15,-12,450,16,gold)
 previous=button(route,514,-8,73,"Previous",function() J.ChangeStage(-1) end)
 button(route,595,-8,77,"My level",function() J.ChangeStage(0) end)
 nextStage=button(route,680,-8,73,"Next",function() J.ChangeStage(1) end)
 rows={}
 for i=1,3 do
  local y=-44-(i-1)*42
  local row=CreateFrame("Frame",nil,route)
  row:SetPoint("TOPLEFT",route,"TOPLEFT",13,y)
  row:SetSize(744,37)
  local bg=row:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(row);bg:SetColorTexture(.075,.11,.16,1)
  row.title=label(row,11,-10,275,14,white)
  row.detail=label(row,294,-11,327,12,muted)
  row.map=button(row,634,-6,96,"Open map",function()
   if row.zone then ForeverCompanionQuestWaypoints.OpenMap(row.zone[2]) end
  end)
  rows[i]=row
 end
 zoneNote=label(route,15,-183,735,11,muted)
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
 currentStage=J.Stage(level)
 local stage=overrideStage or currentStage
 local band=brackets[stage]
 local faction=read(UnitFactionGroup,"player")
 local _,race=read(UnitRace,"player")
 local zones=J.Route(stage,level,faction,race)
 local map=C_Map and read(C_Map.GetBestMapForUnit,"player")
 local planner=ForeverCompanionQuestPlanner
 actionQuest,actionIndex=nil,nil
 if planner.IsSupported() then
  local quests=planner.GetLive()
  local locations=map and ForeverCompanionQuestWaypoints.MapLocations(map,quests) or {}
  actionQuest,actionIndex=J.Recommend(quests,locations,planner.GetSelected())
 end
 local quest=actionQuest
 if quest then
  kind:SetText(quest.complete and "NEXT STEP   ·   TURN IN" or "NEXT STEP   ·   QUEST OBJECTIVE")
  title:SetText(quest.title)
  local step
  for i,line in ipairs(quest.objectives or {}) do
   local state=quest.objectiveStates and quest.objectiveStates[i]
   if not state or not state.done then step=line;break end
  end
  detail:SetText(quest.complete and ("Return to the quest giver  ·  "..quest.zone) or (step or ("Check the quest journal for details  ·  "..quest.zone)))
  hint:SetText("Click a highlighted marker to start the arrow")
 else
  kind:SetText("NEXT STEP   ·   FIND A QUEST")
  title:SetText(planner.IsSupported() and "Visit a nearby quest hub" or "Open your in-game quest log")
  detail:SetText("Look for a yellow ! near the starter camp or town. Accept a quest to see its next step here.")
  hint:SetText("")
 end
 mapButton:SetEnabled(quest~=nil)
 stageText:SetText(("Levels %d–%d  ·  %s"):format(band[1],band[2],band[3]))
 previous:SetEnabled(stage>1);nextStage:SetEnabled(stage<#brackets)
 for i,row in ipairs(rows) do
  local zone=zones[i]
  row.zone=zone
  if zone then
   local info=C_Map and read(C_Map.GetMapInfo,zone[2])
   row.title:SetText(info and info.name or zone[1])
   row.detail:SetText(map==zone[2] and "You are here" or zone[3] or "Suggested questing zone")
   row.map:SetEnabled(info~=nil)
   row:Show()
  else row:Hide() end
 end
 zoneNote:SetText(#zones>0 and "Pick one zone near you. Finish nearby objectives together, then return to town." or
  "Follow the quests near your starting camp. Zone suggestions appear when your race and faction are available.")
end

function J.GetHeight() return 398 end
