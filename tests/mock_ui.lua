-- Offline mock of the WoW widget API; tests construction and render, not pixels.
local frames={}
local snapshot={}
local function clean(v) return (tostring(v or ""):gsub("[\r\n|]"," ")) end
local function exportSnapshot(path)
 local lines={"id|kind|parent|visible|width|height|anchor|x|y|text|texture"}
 for _,f in ipairs(frames) do
  local anchor=f.point and clean(f.point[1]) or ""
  local x,y="",""
  if f.point then
   for _,v in ipairs(f.point) do
    if type(v)=="number" then if x=="" then x=v else y=v end end
   end
  end
  lines[#lines+1]=table.concat({f.id,f.kind,f.parent or "",f.visible and "1" or "0",f.width or "",f.height or "",anchor,x,y,clean(f.text),clean(f.texture)},"|")
 end
 local out=assert(io.open(path,"w"))
 out:write(table.concat(lines,string.char(10)))
 out:close()
end
local function exportNative(path)
 local function quote(value)
  local s=tostring(value or ""):gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t")
  return '"'..s..'"'
 end
 local function encode(v)
  if type(v)=="string" then return quote(v) end
  if type(v)=="number" or type(v)=="boolean" then return tostring(v) end
  if type(v)~="table" then return "null" end
  local result={}
  for i,value in ipairs(v) do result[i]=encode(value) end
  return "["..table.concat(result,",").."]"
 end
 local records={}
 for _,f in ipairs(frames) do
  local values={id=f.id,kind=f.kind,parent=f.parent,name=f.name,visible=f.visible,width=f.width,height=f.height,
   text=f.text,texture=type(f.texture)=="string" and f.texture or nil,textureId=type(f.texture)=="number" and f.texture or nil,color=f.color,textColor=f.textColor,
   layer=f.layer,font=f.font,alpha=f.alpha,crop=f.texCoord,all=f.all,template=f.template,justify=f.justify,backdrop=f.backdropColor,backdropBorder=f.backdropBorder,wordWrap=f.wordWrap}
  local points={}
  for _,p in ipairs(f.points or {}) do
   local point,relative,relativePoint,x,y=p[1],f.parent,p[1],0,0
   if type(p[2])=="table" then relative=p[2].id;relativePoint=p[3];x=p[4] or 0;y=p[5] or 0
   elseif type(p[2])=="number" then x=p[2];y=p[3] or 0 end
   points[#points+1]={point,relative or 1,relativePoint,x,y}
  end
  values.points=points
  local record={}
  for key,value in pairs(values) do record[#record+1]=quote(key)..":"..encode(value) end
  records[#records+1]="{"..table.concat(record,",").."}"
 end
 local out=assert(io.open(path,"w"));out:write("["..table.concat(records,",").."]");out:close()
end
local function widget(kind)
 local w={kind=kind,visible=true,children={},text="",id=#frames+1}
 function w:SetText(v) self.text=tostring(v or "");if self.fontString then self.fontString:SetText(v) end;for _,hook in ipairs(self.hooks and self.hooks.OnTextChanged or {}) do hook(self,false) end end
 function w:GetText() return self.text end
 function w:GetStringHeight()
  local size=self.font and self.font[2] or 12
  local chars=math.max(1,math.floor((self.width or 525)/(size*.56)))
  local lines=0
  for paragraph in (self.text.."\n"):gmatch("(.-)\n") do lines=lines+math.max(1,math.ceil(#paragraph/chars)) end
  return math.max(16,lines*(size+2))
 end
 function w:Show() self.visible=true end
 function w:Hide() self.visible=false end
 function w:IsShown() return self.visible end
 function w:SetShown(value) self.visible=value end
 function w:SetScript(name,fn) self[name]=fn end
 function w:HookScript(name,fn) self.hooks=self.hooks or {};self.hooks[name]=self.hooks[name] or {};table.insert(self.hooks[name],fn) end
 function w:HasFocus() return self.focused==true end
 function w:GetScript(name) return self[name] end
 function w:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
 function w:CreateTexture(_,layer) local child=widget("Texture");child.parent=self.id;child.layer=layer;return child end
 function w:CreateFontString(_,layer,template) local child=widget("FontString");child.parent=self.id;child.layer=layer;child.template=template;return child end
 function w:SetColorTexture(...) self.color={...} end
 function w:SetTexture(v) self.texture=v end
 function w:SetPoint(...) self.point={...};self.points=self.points or {};for i,p in ipairs(self.points) do if p[1]==self.point[1] then self.points[i]=self.point;return end end;self.points[#self.points+1]=self.point end
 function w:SetSize(width,height) self.width=width;self.height=height end
 function w:SetHeight(height) self.height=height end
 function w:SetWidth(width) self.width=width end
 function w:GetWidth() return self.width end
 function w:GetHeight() return self.height end
 function w:SetScale(value) self.scale=value end
 function w:SetFrameStrata(value) self.strata=value end
 function w:GetFrameLevel() return self.frameLevel or (self.parent and frames[self.parent]:GetFrameLevel()+1) or 1 end
 function w:SetFrameLevel(v) self.frameLevel=v end
 function w:SetMinMaxValues(a,b) self.minimum,self.maximum=a,b end
 function w:SetValue(v) self.value=v end
 function w:SetStatusBarColor(...) self.barColor={...} end
 function w:SetStatusBarTexture(v) self.barTexture=v end
 function w:EnableMouseWheel() end
 function w:SetResizeBounds() end
 function w:SetRotation(value) self.rotation=value end
 function w:SetEnabled(value) self.enabled=value end
 function w:LockHighlight() end
 function w:UnlockHighlight() end
 function w:SetScrollChild(child) self.child=child end
 function w:GetVerticalScroll() return self.verticalScroll or 0 end
 function w:SetVerticalScroll(offset) self.verticalScroll=offset end
 function w:StartMoving() end
 function w:StopMovingOrSizing() end
 function w:EnableMouse() end
 function w:RegisterForClicks() end
 function w:SetVertexColor(...) self.vertexColor={...} end
 function w:SetDrawLayer(value) self.layer=value end
 function w:RegisterForDrag() end
 function w:SetMovable() end
 function w:SetClampedToScreen() end
 function w:SetResizable() end
 function w:SetBackdrop(...) end
 function w:SetBackdropColor(...) self.backdropColor={...} end
 function w:SetBackdropBorderColor(...) self.backdropBorder={...} end
 function w:SetAllPoints(target) self.all=target and target.id or self.parent end
 function w:SetJustifyH(value) self.justify=value end
 function w:SetJustifyV() end
 function w:SetWordWrap(v) self.wordWrap=v end
 function w:SetShadowOffset() end
 function w:SetShadowColor() end
 function w:SetSpacing() end
 function w:SetTextColor(...) self.textColor={...} end
 function w:SetFontObject() end
 function w:SetTextInsets(...) self.textInsets={...} end
 function w:SetAutoFocus(v) self.autoFocus=v end
 function w:SetMaxLetters(v) self.maxLetters=v end
 function w:SetDisabledFontObject() end
 function w:SetFont(path,size,flags) self.font={path,size,flags} end
 function w:SetTexCoord(...) self.texCoord={...} end
 function w:SetAlpha(value) self.alpha=value end
 function w:SetNormalTexture() end
 function w:SetFontString(value) self.fontString=value end
 function w:GetFontString() return self.fontString or self end
 function w:SetHighlightTexture() end
 function w:SetPushedTexture() end
 function w:ClearAllPoints() self.point=nil;self.points={} end
 frames[#frames+1]=w
 return w
end
CreateFrame=function(kind,name,parent,template) local child=widget(kind);child.parent=parent and parent.id;child.name=name;child.template=template;return child end
UIParent=widget("UIParent")
UIParent:SetSize(1000,700)
SlashCmdList={}
ForeverCompanionDB={welcomed=false}
UnitClass=function() return "Warrior","WARRIOR" end
UnitLevel=function() return 60 end
local mockXP=1500
UnitXP=function() return mockXP end
UnitXPMax=function() return 3000 end
UnitName=function() return "PreviewCharacter" end
GetProfessions=function() return 1,2 end
GetProfessionInfo=function(index)
 if index==1 then return "Blacksmithing",nil,300,300 end
 return "Mining",nil,275,300
end
C_QuestLog={
 GetNumQuestLogEntries=function() return 3 end,
 GetInfo=function(i)
  local examples={{title="Sample: Gather supplies",questID=101,zoneName="Training Camp"},
   {title="Sample: Speak with trainer",questID=102,zoneName="Training Camp",isComplete=true},
   {title="Sample: Explore the outpost",questID=103,zoneName="Frontier"}}
  return examples[i]
 end,
 IsComplete=function(id) return id==102 end,
 GetQuestObjectives=function(id) return {{text="Illustrative objective for test "..tostring(id),finished=id==102}} end
}
GetBuildInfo=function() return "OfflineMock","0","0",16001 end
print=function() end
local toc=assert(io.open("ForeverCompanion/ForeverCompanion.toc","r"))
local addon="ForeverCompanion"
for line in toc:lines() do
 if line:match("%.lua%s*$") then
  local chunk=assert(loadfile("ForeverCompanion/"..line))
  chunk(addon)
 end
end
toc:close()
local addonFrame
for _,f in ipairs(frames) do
 if f.events and f.events.ADDON_LOADED and f.events.PLAYER_XP_UPDATE and f.events.DISPLAY_SIZE_CHANGED then addonFrame=f;break end
end
assert(addonFrame and addonFrame.OnEvent,"addon loaded handler missing")
ForeverCompanionDB={role={},professions=false,position=true,checks={Dungeons=3,Legacy={true}}}
addonFrame.OnEvent(addonFrame,"ADDON_LOADED",addon)
assert(ForeverCompanionDB.role==nil and ForeverCompanionDB.professions==nil)
assert(ForeverCompanionDB.checks.Dungeons==nil and ForeverCompanionDB.checks.Legacy[1]==true)
local lootUI=ForeverCompanionLootUI
lootUI.dungeon="invalid filter";lootUI.savedOnly=true
local firstLoot=ForeverCompanionLoot.records[1]
SlashCmdList.FOREVERCOMPANION("loot "..firstLoot.item)
assert(ForeverCompanionDB.tab=="Loot" and lootUI.searchBox:GetText()==firstLoot.item)
assert(lootUI.itemTitle:GetText()==firstLoot.item and lootUI.dungeon=="" and not lootUI.savedOnly)
SlashCmdList.FOREVERCOMPANION("loot no such loot")
assert(lootUI.selectedIndex==1 and lootUI.itemTitle:GetText()=="No matching loot")
SlashCmdList.FOREVERCOMPANION("overview")
lootUI.resetButton.OnClick()

assert(#frames>50,"expected substantial UI frame tree")
assert(type(SlashCmdList.FOREVERCOMPANION)=="function","slash command missing")
SlashCmdList.FOREVERCOMPANION("class mage")
SlashCmdList.FOREVERCOMPANION("class auto")
SlashCmdList.FOREVERCOMPANION("role damage")
SlashCmdList.FOREVERCOMPANION("position reset")
SlashCmdList.FOREVERCOMPANION("open quests")
assert(ForeverCompanionDB.tab=="Quests","slash navigation must open quest guide")
local questNav=ForeverCompanionUIState.nextQuestButton
local viewport
for _,widget in ipairs(frames) do
 if widget.kind=="ScrollFrame" then viewport=widget;break end
end
assert(viewport.point[3]>questNav.point[3]+questNav.height,"quest scroll viewport must clear both footer buttons")
do
 local originalHeight=viewport.GetHeight
 local childHeight=viewport.child.height
 viewport.GetHeight=function() return 200 end
 viewport.child:SetHeight(500);viewport:SetVerticalScroll(0)
 ForeverCompanionUIState.updateScrollHint()
 local hint
 for _,f in ipairs(frames) do if f.text=='More below  ·  Scroll to continue' then hint=f end end
 assert(hint and hint.visible,'long pages need a visible continuation cue')
 viewport:SetVerticalScroll(800);ForeverCompanionUIState.updateScrollHint()
 assert(viewport:GetVerticalScroll()==300 and hint.text=='End of page','shortened pages clamp stale scroll offsets')
 viewport.child:SetHeight(100);ForeverCompanionUIState.updateScrollHint()
 assert(not hint.visible and viewport:GetVerticalScroll()==0,'short pages hide continuation cues and return to the top')
 viewport.GetHeight=originalHeight;viewport.child:SetHeight(childHeight)
end
SlashCmdList.FOREVERCOMPANION("overview")
assert(ForeverCompanionDB.tab=="Overview","direct slash navigation must return to dashboard")
assert(pcall(SlashCmdList.FOREVERCOMPANION,"status"),"read-only status command must not crash")
SlashCmdList.FOREVERCOMPANION("open nonexistent")
assert(ForeverCompanionDB.tab=="Overview","invalid navigation must not change selected tab")
assert(ForeverCompanionQuestPlanner.Sync(),"fixture quest API should sync")
assert(ForeverCompanionQuestPlanner.AutoCount()==3,"three test quests expected")
assert(ForeverCompanionCraftingPlanner.Add("Blacksmithing","Sample Ore",10,4),"material fixture should be accepted")
local stats=ForeverCompanionCraftingPlanner.Stats()
assert(stats.materials==1 and stats.missing==6 and stats.complete==0,"material dashboard stats wrong")
ForeverCompanionDashboard.Render()
local readyRecommendation=false
for _,w in ipairs(frames) do
 if w.text=="1. Ready to turn in: Sample: Speak with trainer" then readyRecommendation=true end
end
assert(readyRecommendation,"dashboard should prioritize confirmed ready-to-turn-in quests")
local step1,step3,sourceLabel
for _,w in ipairs(frames) do
 if w.caption and w.caption.text:find("1. Ready to turn in:",1,true) then step1=w end
 if w.caption and w.caption.text:find("3. Gather",1,true) then step3=w end
 if w.kind=="FontString" and w.text:find("Quest data: current snapshot",1,true) then sourceLabel=w end
end
assert(step1 and step1.caption.text=="1. Ready to turn in: Sample: Speak with trainer","recommended quest must use visible caption")
assert(step3 and step3.caption.text=="3. Gather 6 Sample Ore for Blacksmithing (manual).","material recommendation must be visible")
assert(step1.extraDetail and step1.extraDetail:find("Training Camp",1,true),"quest action should expose observed zone")
assert(step1.extraDetail:find("Illustrative objective for test 102",1,true),"quest action should expose observed objective")
assert(step3.extraDetail and step3.extraDetail:find("manual",1,true),"material action should disclose manual data")
local oldTooltip=GameTooltip
local tooltip={lines={}}
function tooltip:SetOwner() end
function tooltip:SetText(value) self.title=value end
function tooltip:AddLine(value) self.lines[#self.lines+1]=value end
function tooltip:Show() self.visible=true end
function tooltip:Hide() self.visible=false end
GameTooltip=tooltip
step1.OnEnter(step1)
assert(tooltip.title:find("Ready to turn in",1,true),"quest tooltip should describe action")
assert(tooltip.lines[1]:find("Training Camp",1,true),"quest tooltip should include zone and objective")
step1.OnLeave(step1)
GameTooltip=oldTooltip
assert(sourceLabel and sourceLabel.text:find("Professions: detected",1,true),"data source disclosure missing")
-- Every dashboard progress metric must navigate to the matching read-only guide.
local metricButtons={}
for _,w in ipairs(frames) do
 if w.dashboardTarget then metricButtons[w.dashboardTarget]=w end
end
for _,target in ipairs({"Leveling","Quests","Professions"}) do
 local metric=metricButtons[target]
 assert(metric and metric.OnClick and metric.OnEnter and metric.OnLeave,"missing navigable dashboard metric: "..target)
 assert(type(metric.detail)=="string" and metric.detail~="","metric needs a readable value")
 assert(pcall(metric.OnEnter,metric) and pcall(metric.OnLeave,metric),"metric hover should be safe without tooltip APIs")
 metric.OnClick(metric)
 assert(ForeverCompanionDB.tab==target,"dashboard metric did not open "..target)
 SlashCmdList.FOREVERCOMPANION("overview")
end
local bannerStatus,focusCount
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text:find("ready of 3 quests",1,true) then bannerStatus=w end
 if w.kind=="FontString" and w.text=="0/4 done" then focusCount=w end
end
assert(bannerStatus and bannerStatus.text:find("6 material units needed",1,true),"live dashboard briefing missing")
assert(focusCount,"dashboard focus completion counter missing")
local originalCount=C_QuestLog.GetNumQuestLogEntries
C_QuestLog.GetNumQuestLogEntries=function() return 0 end
assert(ForeverCompanionQuestPlanner.Sync(),"empty quest log scan should succeed")
ForeverCompanionDashboard.Render()
assert(step1.caption.text=="1. Review your quest log for a new objective.","empty-log recommendation should replace prior caption")
C_QuestLog.GetNumQuestLogEntries=originalCount
assert(ForeverCompanionQuestPlanner.Sync(),"quest log should recover after empty scan")
assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,10),"finish manual material goal")
ForeverCompanionDashboard.Render()
assert(step3.caption.text=="3. Add or review your manual profession goals.","completed goals should replace shortage caption")
assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,4),"restore shortage fixture")
ForeverCompanionDashboard.Render()
local focusButton
for _,w in ipairs(frames) do
 if w.caption and w.caption.text and w.caption.text:find("Review active quests",1,true) then focusButton=w end
end
assert(focusButton and focusButton.OnClick,"focus checklist button missing")
focusButton.OnClick(focusButton)
assert(ForeverCompanionDB.dashboardFocus[1]==true,"focus state did not persist")
assert(focusCount.text=="1/4 done","focus completion meter should update after click")
focusButton.OnClick(focusButton)
assert(ForeverCompanionDB.dashboardFocus[1]==false,"focus toggle did not reverse")
-- Today's Focus persists within the same day, then resets on the next day.
local originalDate=date
date=function() return "2026-11-02" end
focusButton.OnClick(focusButton)
assert(ForeverCompanionDB.dashboardFocus[1]==true,"daily focus should save")
ForeverCompanionDashboard.Render()
assert(ForeverCompanionDB.dashboardFocus[1]==true,"same-day focus must persist")
date=function() return "2026-11-03" end
ForeverCompanionDashboard.Render()
assert(not ForeverCompanionDB.dashboardFocus[1],"new day must reset the focus checklist")
assert(focusCount.text=="0/4 done","daily focus completion counter must reset")
date=function() error("restricted date API") end
assert(pcall(ForeverCompanionDashboard.Render),"restricted date API must not crash")
date=originalDate
local questAction
for _,w in ipairs(frames) do if w.caption and w.caption.text=="Quests" then questAction=w end end
assert(questAction and questAction.OnClick,"quest shortcut missing")
questAction.OnClick(questAction)
assert(ForeverCompanionDB.tab=="Quests","quest shortcut failed")
local questHeading,questFocusHeading,questBriefingRoot
for _,w in ipairs(frames) do
 if w.text=="JOURNAL AT A GLANCE" then questHeading=w end
 if w.text=="FOCUSED OBJECTIVE" then questFocusHeading=w end
end
assert(questHeading and questFocusHeading,"quest briefing panels missing")
questBriefingRoot=frames[questHeading.parent].parent
assert(frames[questBriefingRoot].visible,"quest briefing must be visible on quest page")
local questCountCard=false
for _,w in ipairs(frames) do
 if w.text=="3 active  |  1 ready  |  0 pinned" then questCountCard=true end
end
assert(questCountCard,"live quest briefing count incorrect")
local sortControl
for _,w in ipairs(frames) do if w.OnClick and w.text=="Sort: zone" then sortControl=w end end
assert(sortControl and sortControl.OnClick,"quest sort selector missing")
sortControl.OnClick(sortControl) -- ready
assert(ForeverCompanionQuestPlanner.GetSort()=="ready","quest sort should persist readiness")
assert(ForeverCompanionQuestPlanner.GetVisible()[1].quest.complete,"ready quests must sort first")
sortControl.OnClick(sortControl) -- pinned
assert(ForeverCompanionQuestPlanner.GetSort()=="pinned","pinned sort mode should be available")
sortControl.OnClick(sortControl) -- log
assert(ForeverCompanionQuestPlanner.GetVisible()[1].quest.title=="Sample: Gather supplies","log order must be preserved")
sortControl.OnClick(sortControl) -- zone
assert(ForeverCompanionQuestPlanner.GetVisible()[1].quest.zone=="Frontier","zone sort should group alphabetically")
-- Styled journal rows expose readable title, zone, and status without touching
-- the game's selected quest. Clicking only changes the addon's focused entry.
local readyRow
for _,w in ipairs(frames) do
 if w.title and w.zone and w.status and w.title.text:find("Speak with trainer",1,true) then readyRow=w end
end
assert(readyRow and readyRow.OnClick,"native quest journal row missing")
assert(readyRow.zone.text=="Training Camp","quest row zone label incorrect")
assert(readyRow.status.text=="READY","quest row completion badge incorrect")
readyRow.OnClick(readyRow)
assert(ForeverCompanionQuestPlanner.GetSelected().title=="Sample: Speak with trainer","journal row focus failed")
assert(readyRow.selected,"selected quest row must be highlighted")
local pinControl
for _,w in ipairs(frames) do if w.text=="Pin Focus" and w.OnClick then pinControl=w end end
assert(pinControl and pinControl.visible,"quest pin button must be visible")
pinControl.OnClick(pinControl)
assert(ForeverCompanionQuestPlanner.PinnedCount()==1,"pin button must persist quest priority")
assert(pinControl.text=="Unpin Focus","pin control must reflect focused quest state")
assert(readyRow.title.text:find("[PIN]",1,true),"journal row should show pinned badge")
assert(ForeverCompanionQuestPlanner.Overview().pinned==1,"journal overview must count pinned quests")
local knownObjective=false
for _,w in ipairs(frames) do
 if w.text=="1 / 1 objectives complete" then knownObjective=true end
end
assert(knownObjective,"quest focus card should show verified objective progress")
do
 local priorMap,priorPoint,priorTrack,priorDb,priorAddons=C_Map,UiMapPoint,C_SuperTrack,LibQuestieDB,C_AddOns
 local marker,writes,opens,tracked=nil,0,0,false
 local selected=ForeverCompanionQuestPlanner.GetSelected()
 C_QuestLog.GetNextWaypoint=function(id)
  assert(id==selected.id)
  return 1429,.43,.61
 end
 C_Map={
  CanSetUserWaypointOnMap=function(map) return map==1429 end,
  GetMapInfo=function(map) if map==1429 then return {name="Elwynn Forest",mapType=3} end end,
  SetUserWaypoint=function(p) marker=p;writes=writes+1 end,
  GetUserWaypoint=function() return marker end,
  ClearUserWaypoint=function() marker=nil end,
  OpenWorldMap=function(map) assert(map==1429);opens=opens+1 end,
 }
 UiMapPoint={CreateFromCoordinates=function(map,x,y)
  return {uiMapID=map,position={GetXY=function() return x,y end}}
 end}
 C_SuperTrack={
  SetSuperTrackedUserWaypoint=function(value) tracked=value end,
  IsSuperTrackingUserWaypoint=function() return tracked end,
 }
 local briefing=ForeverCompanionQuestBriefing
 local navigation=ForeverCompanionQuestWaypoints
 briefing.Render()
 assert(briefing.mapButton.enabled and writes==0 and opens==0,"render never changes the user's map")
 briefing.mapButton:OnClick()
 assert(writes==1 and opens==1 and tracked and briefing.clearPin.enabled,"one click sets pin and starts arrow")
 marker=UiMapPoint.CreateFromCoordinates(1429,.18,.37)
 assert(not navigation.Clear() and marker,"must preserve a waypoint the player set afterward")
 briefing.mapButton:OnClick()
 briefing.clearPin:OnClick()
 assert(not marker and not briefing.clearPin.enabled,"clear removes the addon waypoint")
 C_QuestLog.GetNextWaypoint=nil
 C_Map.GetBestMapForUnit=function() return 1429 end
 C_QuestLog.GetQuestsOnMap=function()
  return {{questID=selected.id,mapID=1429,isQuestStart=true,x=.1,y=.3},
          {questID=selected.id,mapID=1429,isQuestStart=false,x=.4,y=.6}}
 end
 assert(navigation.Location(selected).x==.4,"map POIs must ignore quest-start locations")
 C_QuestLog.GetQuestsOnMap=nil
 assert(navigation.Location(selected)==nil,"missing data must not invent a marker")
 LibQuestieDB={
  ModeIndicator={GetStatus=function() return {expansion="Forever"} end},
  RequireContract=function(v) return v==1 end,
  Quest={name=function() return selected.title end,finishedBy=function() return {{42}} end},
  Npc={spawns=function() return {[12]={{47,68}}} end},
  Support={Get=function() return {private={areaIdToUiMapId="return {[12] = 1429,}"}} end},
 }
 local candidate=navigation.Location(selected)
 assert(candidate and candidate.source=="QuestieDB turn-in" and candidate.y==.68,"optional provider uses known turn-in spawn")
 LibQuestieDB.ModeIndicator.GetStatus=function() return {mode="baked"} end
 C_AddOns={GetAddOnMetadata=function(addon,key)
  assert(addon=="QuestieDB" and key=="X-Flavor")
  return "Forever"
 end}
 assert(navigation.Location(selected).source=="QuestieDB turn-in","baked provider reads the TOC flavor")
 C_AddOns.GetAddOnMetadata=function() return "Vanilla" end
 assert(navigation.Location(selected)==nil,"other flavors cannot provide markers")
 C_AddOns.GetAddOnMetadata=function() return "Forever" end
 LibQuestieDB.Npc.spawns=function() return {[12]={{47,68},{49,63}}} end
 assert(navigation.Location(selected)==nil,"ambiguous optional coordinates must be skipped")
 C_Map,UiMapPoint,C_SuperTrack,LibQuestieDB,C_AddOns=priorMap,priorPoint,priorTrack,priorDb,priorAddons
end
do
 local planner=ForeverCompanionQuestPlanner
 local briefing=ForeverCompanionQuestBriefing
 local originalInfo,originalCount=C_QuestLog.GetInfo,C_QuestLog.GetNumQuestLogEntries
 local originalMap,originalUtil,originalCVar=C_Map,MapUtil,GetCVarBool
 local canvas=CreateFrame("Frame")
 canvas:SetSize(800,500)
 function canvas:GetFrameLevel() return 1 end
 local mapID,provider,area=1429
 local create=CreateFrame
 CreateFrame=function(kind,...)
  local frame=create(kind,...)
  function frame:SetFrameLevel(level) self.frameLevel=level end
  if kind=="QuestPOIFrame" then
   area=frame
   function frame:SetMapID(map) self.map=map end
   function frame:DrawNone() self.quest=nil end
   function frame:DrawBlob(id) self.quest=id end
   for _,method in ipairs({"SetFillTexture","SetBorderTexture","SetFillAlpha","SetBorderAlpha","SetBorderScalar"}) do
    frame[method]=function() end
   end
  end
  return frame
 end
 WorldMapFrame={IsShown=function() return true end,GetMapID=function() return mapID end,GetFrameLevel=function() return 1 end,
  GetCanvas=function() return canvas end,AddDataProvider=function(_,value) provider=value end}
 MapCanvasDataProviderMixin={}
 CreateFromMixins=function() return {} end
 MapUtil={ShouldMapTypeShowQuests=function(kind) return kind==3 end}
 GetCVarBool=function() return true end
 C_Map={GetMapInfo=function() return {mapType=3} end}
 C_QuestLog.GetQuestsOnMap=function()
  return {{questID=101,mapID=1429,isQuestStart=false,x=.21,y=.42},
          {questID=102,mapID=1429,isQuestStart=false,x=.28,y=.4},
          {questID=104,mapID=1429,isQuestStart=false,x=.5,y=.6},
          {questID=104,mapID=1429,isQuestStart=false,x=.5,y=.6},
          {questID=104,mapID=1429,isQuestStart=false,x=.7,y=.7},
          {questID=104,mapID=1429,isQuestStart=true,x=.1,y=.1},
          {questID=999,mapID=1429,isQuestStart=false,x=.8,y=.8},
          {questID=101,mapID=1415,isQuestStart=false,x=.2,y=.2}}
 end
 C_QuestLog.GetNumQuestLogEntries=function() return 4 end
 C_QuestLog.GetInfo=function(i)
  return i==4 and {title="New quest",questID=104,zoneName="Elwynn Forest"} or originalInfo(i)
 end
 planner.Select(1)
 assert(not planner.IsAutoFocus() and briefing.autoFocusButton.text=="Auto focus: Off")
 briefing.autoFocusButton:OnClick()
 assert(planner.IsAutoFocus() and planner.Sync() and planner.GetSelected().id==104,"new quest should gain automatic focus")
 for _,frame in ipairs(frames) do
  if frame.events and frame.events.QUEST_POI_UPDATE and frame.events.ADDON_LOADED then
   frame:OnEvent("ADDON_LOADED","Blizzard_WorldMap")
   break
  end
 end
 assert(provider and area.visible and area.map==1429 and area.quest==104,"world map draws the focused quest's native boundary")
 local function visiblePins()
  local count,focused,ready,active=0,0,0,0
  for _,frame in ipairs(frames) do
   if frame.parent==canvas.id and frame.symbol and frame.visible then
    count=count+1
    if frame.symbol.text==">" then focused=focused+1 end
    if frame.symbol.text=="?" then ready=ready+1 end
    if frame.symbol.text=="" then active=active+1 end
   end
  end
  return count,focused,ready,active
 end
 local count,focused,ready,active=visiblePins()
 assert(count==4 and focused==2 and ready==1 and active==1,"All should be the default map view")
 local function mapModeButton(text)
  for _,frame in ipairs(frames) do if frame.OnClick and frame.text==text then return frame end end
 end
 local styleButton=assert(mapModeButton("Style: Atlas"))
 local terrain
 for _,frame in ipairs(frames) do
  if frame.parent==canvas.id and frame[9] then terrain=frame end
 end
 assert(terrain and terrain.visible,"atlas style draws an independent terrain overlay")
 styleButton:OnClick()
 assert(not terrain.visible and visiblePins()==4,"original terrain keeps all quest markers")
 styleButton:OnClick()
 assert(not terrain.visible,"original style keeps native artwork unobstructed")
 styleButton:OnClick()
 assert(terrain.visible,"atlas style can be restored")
 local modeButton=assert(mapModeButton("Map: All"))
 modeButton:OnClick()
 count,focused,ready,active=visiblePins()
 assert(count==2 and focused==2 and ready==0 and active==0,"Focus should hide markers for other quests")
 modeButton:OnClick()
 assert(visiblePins()==0 and not area.visible,"Off hides Companion quest markers and area")
 modeButton:OnClick()
 assert(visiblePins()==4)
 planner.SetAutoFocus(false)
 local normalPOIs,normalInfo,normalCount=C_QuestLog.GetQuestsOnMap,C_QuestLog.GetInfo,C_QuestLog.GetNumQuestLogEntries
 C_QuestLog.GetNumQuestLogEntries=function() return 20 end
 C_QuestLog.GetInfo=function(i)
  if i<=4 then return normalInfo(i) end
  return {title="Extra quest "..i,questID=200+i,zoneName="Elwynn Forest"}
 end
 C_QuestLog.GetQuestsOnMap=function()
  local points=normalPOIs()
  for i=5,20 do
   local x=i<=6 and .10 or .14+(i-7)*.045
   points[#points+1]={questID=200+i,mapID=1429,isQuestStart=false,x=x,y=.12}
  end
  return points
 end
 assert(planner.Sync())
 local represented,shared=0,false
 for _,frame in ipairs(frames) do
  if frame.parent==canvas.id and frame.symbol and frame.visible and not frame.focused then
   represented=represented+1+#frame.nearby
   if frame.symbol.text=="+" and #frame.nearby==1 then shared=true end
  end
 end
 assert(represented==18 and shared,"All must retain quests beyond the former cap, including shared destinations")
 C_QuestLog.GetQuestsOnMap,C_QuestLog.GetInfo,C_QuestLog.GetNumQuestLogEntries=normalPOIs,normalInfo,normalCount
 planner.Select(4)
 assert(planner.Sync())
 local oldProvider,oldFaction,oldTimer=LibQuestieDB,UnitFactionGroup,C_Timer
 UnitFactionGroup=function() return "Alliance" end
 local scheduled
 C_Timer={After=function(_,callback) scheduled=callback end}
 LibQuestieDB={
  Quest={},RequireContract=function() return true end,
  ModeIndicator={GetStatus=function() return {expansion="Forever"} end},
  Support={Get=function() return {private={areaIdToUiMapId="return {[12] = 1429,}"}} end},
  Enum={npcFlags={BANKER=256,VENDOR=4}},
  Npc={GetAllIds=function() return {1,2,3} end,npcFlags=function(id) return id==1 and 256 or 4 end,
   friendlyToFaction=function(id) return id==3 and "H" or "A" end,
   name=function(id) return id==1 and "Test banker" or "Test vendor" end,
   spawns=function(id) return {[12]={{44+id,70}}} end},
 }
 provider:OnMapChanged()
 assert(scheduled,"town services are indexed asynchronously")
 scheduled()
 local function townPins()
  local count=0
  for _,frame in ipairs(frames) do
   if frame.parent==canvas.id and frame.locations and frame.visible then count=count+1 end
  end
  return count
 end
 assert(townPins()==1,"nearby friendly service types should cluster together")
 local townsButton=assert(mapModeButton("Towns: On"))
 townsButton:OnClick()
 assert(townPins()==0 and visiblePins()==4,"town services toggle independently of quests")
 townsButton:OnClick()
 assert(townPins()==1)
 local servicePin
 for _,f in ipairs(frames) do if f.parent==canvas.id and f.locations and f.visible then servicePin=f end end
 assert(servicePin and #servicePin.locations==2 and servicePin.count.text=="2")
 local oldShift,oldNavigate=IsShiftKeyDown,ForeverCompanionQuestWaypoints.Navigate
 IsShiftKeyDown=function() return true end
 servicePin:OnClick()
 assert(servicePin.locationIndex==2,"shift click selects another clustered service")
 local chosen
 IsShiftKeyDown=function() return false end
 ForeverCompanionQuestWaypoints.Navigate=function(target) chosen=target;return "Selected service" end
 servicePin:OnClick()
 assert(chosen==servicePin.locations[2],"navigation retains real selected service coordinates")
 IsShiftKeyDown,ForeverCompanionQuestWaypoints.Navigate=oldShift,oldNavigate
 mapID=1430;provider:OnMapChanged()
 assert(townPins()==0,"old service pins disappear on map change")
 mapID=1429;provider:OnMapChanged()
 LibQuestieDB,UnitFactionGroup,C_Timer=oldProvider,oldFaction,oldTimer
 provider:OnMapChanged()
 local activePin
 for _,frame in ipairs(frames) do
  if frame.parent==canvas.id and frame.symbol and frame.visible and frame.symbol.text=="" then activePin=frame end
 end
 assert(activePin and activePin.OnClick and activePin.ring and not activePin.ring.visible)
 activePin:OnClick()
 for _,frame in ipairs(frames) do
  if frame.parent==canvas.id and frame.symbol and frame.visible and frame.symbol.text==">" then activePin=frame end
 end
 assert(planner.GetSelected().id==101 and activePin.ring.visible,"map click focuses the quest and highlights its destination")
 local originalWaypoint,originalShift=UiMapPoint,IsShiftKeyDown
 local originalVector,originalFacing=CreateVector2D,GetPlayerFacing
 local destination
 UiMapPoint={CreateFromCoordinates=function(map,x,y) return {uiMapID=map,position={x=x,y=y}} end}
 C_Map.SetUserWaypoint=function(value) destination=value end
 C_Map.GetUserWaypoint=function() return destination end
 CreateVector2D=function(x,y) return {GetXY=function() return x,y end} end
 C_Map.GetBestMapForUnit=function() return 1429 end
 C_Map.GetPlayerMapPosition=function() return CreateVector2D(0,0) end
 C_Map.GetWorldPosFromMapPos=function(_,pos)
  local x,y=pos:GetXY()
  return 1,CreateVector2D(-y*100,-x*100)
 end
 GetPlayerFacing=function() return 0 end
 activePin:OnClick()
 assert(ForeverCompanionQuestDirection.IsActive(),"a focused marker starts the companion HUD arrow")
 local arrow,hud
 for _,f in ipairs(frames) do
  if f.texture and type(f.texture)=="string" and f.texture:find("QuestDirectionArrow",1,true) then arrow=f;hud=frames[f.parent] end
 end
 assert(arrow and arrow.visible and arrow.rotation<0,"HUD arrow points southwest from the fixture position")
 GetPlayerFacing=function() return nil end
 hud:OnUpdate(.11)
 assert(not arrow.visible,"HUD hides the bearing if facing is unavailable")
 assert(ForeverCompanionQuestWaypoints.Clear(),"active HUD can be cleared")
 assert(not ForeverCompanionQuestDirection.IsActive() and not hud.visible)
 CreateVector2D,GetPlayerFacing=originalVector,originalFacing
 assert(destination and destination.uiMapID==1429 and destination.position.x==.21,"clicking the focused marker sets the native waypoint")
 UiMapPoint,IsShiftKeyDown=originalWaypoint,originalShift

 planner.Select(1)
 assert(not planner.IsAutoFocus() and area.quest==101,"manual selection updates the area and pauses auto focus")
 C_QuestLog.GetNumQuestLogEntries=function() return 5 end
 local four=C_QuestLog.GetInfo
 C_QuestLog.GetInfo=function(i)
  return i==5 and {title="Other new quest",questID=105} or four(i)
 end
 assert(planner.Sync() and planner.GetSelected().id==101,"new quests must not steal manual focus")
 mapID=1429+1
 provider:OnMapChanged()
 assert(visiblePins()==0 and area.map==mapID,"changing map clears old markers and uses new map for area geometry")
 mapID=1429
 provider:OnMapChanged()
 assert(visiblePins()==3,"returning to a map restores a single marker per other quest")
 C_QuestLog.GetNumQuestLogEntries=function() error("quest log unavailable") end
 assert(not planner.Sync() and visiblePins()==0 and not area.visible,"stale quest data must hide map markers and area")
 C_QuestLog.GetInfo,C_QuestLog.GetNumQuestLogEntries=originalInfo,originalCount
 C_QuestLog.GetQuestsOnMap=nil
 assert(planner.Sync())
 local oldPOIs,oldTitle=C_QuestLog.GetQuestsOnMap,C_QuestLog.GetTitleForQuestID
 C_QuestLog.GetTitleForQuestID=function(id) return "Available quest "..id end
 C_QuestLog.GetQuestsOnMap=function()
  return {{questID=777,mapID=1429,isQuestStart=true,x=.3,y=.3},{questID=888,mapID=1429,isQuestStart=true,x=.3,y=.3}}
 end
 provider:OnMapChanged()
 local pickupPin
 for _,f in ipairs(frames) do if f.parent==canvas.id and f.visible and f.entry and f.entry.pickup then pickupPin=f end end
 assert(pickupPin and #pickupPin.pickups==2 and pickupPin.badge.texture=="Interface\\GossipFrame\\AvailableQuestIcon","unaccepted quests use native exclamation artwork and cluster")
 local oldPickupShift,oldPickupNav=IsShiftKeyDown,ForeverCompanionQuestWaypoints.Navigate
 IsShiftKeyDown=function() return true end
 pickupPin:OnClick()
 assert(pickupPin.entry.quest.id==888,"shift click chooses the second unaccepted quest")
 local chosenPickup
 IsShiftKeyDown=function() return false end
 ForeverCompanionQuestWaypoints.Navigate=function(target) chosenPickup=target;return "Quest pickup selected" end
 pickupPin:OnClick()
 assert(chosenPickup==pickupPin.entry.target,"click navigates to actual quest-giver location")
 IsShiftKeyDown,ForeverCompanionQuestWaypoints.Navigate=oldPickupShift,oldPickupNav
 mapModeButton("Pickups: On"):OnClick()
 assert(not pickupPin.visible,"pickup toggle hides unaccepted quests")
 mapModeButton("Pickups: Off"):OnClick()
 C_QuestLog.GetQuestsOnMap,C_QuestLog.GetTitleForQuestID=oldPOIs,oldTitle
 exportNative('ui_map_toolbar_native.json')
 provider:OnHide()
 assert(visiblePins()==0 and not area.visible)
 WorldMapFrame.IsShown=function() return false end
 WorldMapFrame,MapCanvasDataProviderMixin,CreateFromMixins=nil,nil,nil
 C_Map,MapUtil,GetCVarBool,CreateFrame=originalMap,originalUtil,originalCVar,create
end
do
 local journey=ForeverCompanionJourney
 assert(journey.Route(2,15,"Alliance","Human")[1][2]==1436)
 assert(journey.Route(2,11,"Horde","Skyborne")[1][2]==2521)
 assert(journey.Route(2,15,"Horde","Scourge")[1][2]==1421)
 assert(#journey.Route(2,15,nil,nil)==0)
 local a,b={complete=true},{}
 assert(journey.Recommend({a,b},{{quest=b}},a)==b,"prefer a nearby objective over a remote turn-in")
 assert(journey.Recommend({a,b},{{quest=b},{quest=a}},b)==a,"turn in a nearby ready quest before a nearby objective")
 SlashCmdList.FOREVERCOMPANION("open leveling route")
 assert(ForeverCompanionDB.tab=="Journey","the leveling route is reachable from normal navigation")
 local found
 for _,frame in ipairs(frames) do
  if frame.OnClick and frame.text=="Find on map" and frame.enabled then found=true end
 end
 assert(found,"leveling route shows map action for a live quest")
 exportNative("ui_journey_native.json")
 SlashCmdList.FOREVERCOMPANION("open quests")
end
do
 local originalBank,originalContainer,originalEnum,originalTime,originalDate=C_Bank,C_Container,Enum,GetServerTime,date
 Enum={BankType={Character=0}}
 GetServerTime=function() return 100 end
 date=os.date
 C_Bank={CanViewBank=function(kind) return kind==0 end,FetchPurchasedBankTabData=function()
  return {{ID=6,name="Supplies"},{ID=7,name="Gear"}}
 end}
 local stacks=4
 C_Container={GetContainerNumSlots=function() return 2 end,GetContainerItemInfo=function(id,slot)
  if id==7 and slot==1 then return {itemID=1234,stackCount=stacks,hyperlink="|Hitem:1234|h[Sample ore]|h"} end
 end}
 local bankEvent
 for _,frame in ipairs(frames) do if frame.events and frame.events.BANKFRAME_OPENED then bankEvent=frame;break end end
 assert(bankEvent)
 bankEvent:OnEvent("BANKFRAME_OPENED")
 local snapshot=assert(ForeverCompanionDB.bankSnapshot)
 assert(#snapshot.items==1 and snapshot.slots==4 and snapshot.items[1].count==4 and snapshot.items[1].tab=="Gear")
 stacks=6
 bankEvent:OnEvent("PLAYERBANKSLOTS_CHANGED")
 assert(ForeverCompanionDB.bankSnapshot.items[1].count==6)
 C_Container.GetContainerNumSlots=function() return 0 end
 bankEvent:OnEvent("BAG_UPDATE_DELAYED")
 assert(ForeverCompanionDB.bankSnapshot.items[1].count==6,"incomplete reads preserve the last good snapshot")
 bankEvent:OnEvent("BANKFRAME_CLOSED")
 C_Container.GetContainerNumSlots=function() error("must not read the bank remotely") end
 bankEvent:OnEvent("BAG_UPDATE_DELAYED")
 SlashCmdList.FOREVERCOMPANION("bank")
 local found
 for _,frame in ipairs(frames) do if frame.text=="Sample ore" then found=true end end
 assert(ForeverCompanionDB.tab=="Bank" and found,"bank items remain viewable after leaving the banker")
 assert(ForeverCompanionBankView.GetHeight()<250,'short bank lists should use a compact panel')
 exportNative('ui_bank_native.json')
 SlashCmdList.FOREVERCOMPANION("open quests")
 C_Bank,C_Container,Enum,GetServerTime,date=originalBank,originalContainer,originalEnum,originalTime,originalDate
end
local originalComplete=C_QuestLog.IsComplete
C_QuestLog.IsComplete=function() return false end
assert(ForeverCompanionQuestPlanner.Sync(),"non-ready quest fixture should sync")
ForeverCompanionQuestPlanner.Select(1)
ForeverCompanionDashboard.Render()
assert(step1.detail:find("Pinned priority: Sample: Speak with trainer",1,true),"dashboard must prefer unfinished pinned quest")
step1.OnClick(step1)
assert(ForeverCompanionQuestPlanner.GetSelected().title=="Sample: Speak with trainer","dashboard pin recommendation must focus selected priority")
C_QuestLog.IsComplete=originalComplete
assert(ForeverCompanionQuestPlanner.Sync(),"ready quest fixture should recover")
exportSnapshot("ui_quest_snapshot.txt")
exportNative("ui_quest_native.json")
do
 local originalPickups=ForeverCompanionQuestWaypoints.MapPickups
 local originalNavigate=ForeverCompanionQuestWaypoints.Navigate
 local originalMap=C_Map
 local map=1429
 C_Map={GetBestMapForUnit=function() return map end,GetMapInfo=function() return {name='Sample forest'} end}
 local sample={quest={id=900001,title='Sample: Help the outpost',level=60},target={map=map,x=.23,y=.46,label='Sample quartermaster'},reference=true}
 local client={quest={id=900001,title='Sample: Help the outpost',level=60},target={map=map,x=.21,y=.43,label='Sample scout'}}
 local fixture={sample,client}
 ForeverCompanionQuestWaypoints.MapPickups=function() return fixture end
 local navigated
 ForeverCompanionQuestWaypoints.Navigate=function(target,showMap,title) navigated=target;return 'Test waypoint selected' end
 ForeverCompanionQuestDiscovery.Refresh()
 local row
 for _,frame in ipairs(frames) do if frame.kind=='Button' and frame.item and frame.item.quest.id==900001 then row=frame;break end end
 assert(row and #row.item.targets==2)
 row.OnClick(row)
 row.cycle.OnClick(row.cycle)
 row.go.OnClick(row.go)
 assert(navigated and navigated.x==.23,'selected reference giver must be navigated instead of first giver')
 assert(ForeverCompanionQuestDiscovery.GetHeight()<500,'one quest should not leave four rows of empty list space')
 exportNative('ui_discovery_native.json')
 -- Provider refreshes may reorder locations; selection follows coordinates.
 fixture={client,sample};ForeverCompanionQuestDiscovery.Refresh()
 row.go.OnClick(row.go);assert(navigated.x==.23,'giver identity survives provider reordering')
 fixture={};ForeverCompanionQuestDiscovery.Refresh()
 local detailGo
 for _,frame in ipairs(frames) do if frame.kind=='Button' and frame.text=='Navigate to giver' then detailGo=frame end end
 assert(detailGo and detailGo.enabled==false,'stale quest disappears and disables navigation')
 assert(ForeverCompanionQuestDiscovery.GetHeight()>500,'empty discovery must reserve readable explanation space')
 exportNative('ui_discovery_empty_native.json')
 ForeverCompanionQuestWaypoints.MapPickups=originalPickups
 ForeverCompanionQuestWaypoints.Navigate=originalNavigate
 C_Map=originalMap
 ForeverCompanionQuestDiscovery.Refresh()
end
local originalQuestCount=C_QuestLog.GetNumQuestLogEntries
C_QuestLog.GetNumQuestLogEntries=function() error("temporary quest API failure") end
assert(ForeverCompanionQuestPlanner.Sync()==false,"failed quest scan must not be reported successful")
local staleWarning=false
for _,w in ipairs(frames) do
 if w.text=="Cached. Check your quest log." then staleWarning=true end
end
assert(staleWarning,"quest briefing must warn about cached data")
ForeverCompanionDashboard.Render()
assert(sourceLabel.text:find("CACHED - VERIFY IN GAME",1,true),"dashboard must disclose stale quest data")
assert(bannerStatus.text:find("Quest snapshot stale",1,true),"welcome briefing must not report stale quests as live")
assert(step1.detail:find("Quest API unavailable",1,true),"stale quest snapshot must not generate a live recommendation")
assert(metricButtons.Quests.detail=="N/A","stale quest progress must not display an old readiness ratio")
C_QuestLog.GetNumQuestLogEntries=originalQuestCount
assert(ForeverCompanionQuestPlanner.Sync(),"quest scanner should recover after transient error")
local bannerText
for _,w in ipairs(frames) do if w.text=="WELCOME TO FOREVER COMPANION" then bannerText=w end end
assert(bannerText and frames[frames[bannerText.parent].parent].visible==false,"dashboard should hide outside Overview")
local overviewButton
for _,w in ipairs(frames) do if w.section=="Overview" then overviewButton=w end end
assert(overviewButton and overviewButton.OnClick,"sidebar overview navigation missing")
overviewButton.OnClick(overviewButton)
assert(ForeverCompanionDB.tab=="Overview","overview navigation failed")
assert(not frames[questBriefingRoot].visible,"quest briefing must hide on overview")
local recommendedStep
for _,w in ipairs(frames) do
 if w.caption and w.caption.text:find("Review Warrior leveling",1,true) then recommendedStep=w end
end
assert(recommendedStep and recommendedStep.OnClick,"recommended step should be clickable")
recommendedStep.OnClick(recommendedStep)
assert(ForeverCompanionDB.tab=="Leveling","recommended step did not open Leveling")
overviewButton.OnClick(overviewButton)
local professionButton
for _,w in ipairs(frames) do if w.section=="Professions" then professionButton=w end end
assert(professionButton and professionButton.OnClick,"profession sidebar navigation missing")
professionButton.OnClick(professionButton)
local skillHeading,materialsHeading
for _,w in ipairs(frames) do
 if w.text=="PROFESSION SKILLS" then skillHeading=w end
 if w.text=="MATERIAL GOALS" then materialsHeading=w end
end
assert(skillHeading and materialsHeading,"profession briefing panels missing")
assert(frames[frames[skillHeading.parent].parent].visible,"profession briefing must be visible")
local alchemyTab
for _,w in ipairs(frames) do
 if w.label and w.icon and w.bg and w.trim and w.label.text=="Alchemy" then alchemyTab=w end
end
assert(alchemyTab and alchemyTab.OnClick,"styled profession handbook selector missing")
alchemyTab.OnClick(alchemyTab)
assert(alchemyTab.selected,"selected profession handbook tab should highlight")
local notesToggle=ForeverCompanionUIState.professionNotesButton
assert(notesToggle.visible and notesToggle.text=="Show detailed notes","profession details start collapsed")
notesToggle:OnClick()
assert(notesToggle.text=="Hide detailed notes")
local sourcedCampingVisible=false
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text:find("Mana Well",1,true) and w.text:find("Blizzard Forever Camping preview (2026-10-21)",1,true) then
  sourcedCampingVisible=true
 end
end
assert(sourcedCampingVisible,"expanded notes show the source-attributed camp feature")
notesToggle:OnClick()
local materialStatus=false
for _,w in ipairs(frames) do if w.text=="0/1 material goals done" then materialStatus=true end end
assert(materialStatus,"manual material goal status incorrect")
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local shortageFound=false
for _,w in ipairs(frames) do
 if w.text=="Selected guide shortage: Sample Ore x6" then shortageFound=true end
end
assert(shortageFound,"selected profession should show its largest manual shortage")
ForeverCompanionProfessionBriefing.Render("Alchemy")
exportSnapshot("ui_profession_snapshot.txt")
exportNative("ui_profession_native.json")
-- Full manual-goal workflow stays in the UI and preserves failed edits.
local materialsUI=ForeverCompanionMaterialWorkspace
local planner=ForeverCompanionCraftingPlanner
materialsUI.fields.name:SetText("Review herb")
materialsUI.fields.needed:SetText("12");materialsUI.fields.owned:SetText("3")
materialsUI.save:OnClick()
assert(planner.GetEntries("Alchemy")[1].name=="Review herb")
materialsUI.rows[1].edit:OnClick()
materialsUI.fields.name:SetText("Renamed review herb")
materialsUI.fields.needed:SetText("15");materialsUI.fields.owned:SetText("5")
materialsUI.save:OnClick()
assert(planner.GetEntries("Alchemy")[1].needed==15 and planner.GetEntries("Alchemy")[1].owned==5)
materialsUI.rows[1].edit:OnClick()
materialsUI.fields.needed:SetText("-1")
materialsUI.save:OnClick()
assert(planner.GetEntries("Alchemy")[1].needed==15,"invalid form edits must not overwrite a saved goal")
materialsUI.cancel:OnClick()
materialsUI.rows[1].edit:OnClick()
assert(planner.Update("Alchemy",1,"Changed externally",20,7))
materialsUI.save:OnClick()
assert(planner.GetEntries("Alchemy")[1].name=="Changed externally","stale form edits must not replace a changed goal")
materialsUI.cancel:OnClick()
materialsUI.rows[1].remove:OnClick()
assert(#planner.GetEntries("Alchemy")==0,"remove only changes manual planning data")

assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,10),"material goal should update")
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local completedStatus=false
for _,w in ipairs(frames) do if w.text=="1/1 material goals done" then completedStatus=true end end
assert(completedStatus,"material briefing must refresh after manual update")
assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,4))
local originalGetProfessions=GetProfessions
GetProfessions=nil
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local unavailableStatus=false
for _,w in ipairs(frames) do if w.text=="Profession API unavailable on this client." then unavailableStatus=true end end
assert(unavailableStatus,"profession briefing must show unavailable API")
GetProfessions=originalGetProfessions
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
overviewButton.OnClick(overviewButton)
local compactButton,mainWindow
for _,w in ipairs(frames) do
 if w.OnClick and w.text=="Compact" then compactButton=w end
 if w.width==1080 and w.height==720 then mainWindow=w end
end
assert(mainWindow and mainWindow.scale and mainWindow.scale<1,"responsive scale not applied")
UIParent:SetSize(680,480)
addonFrame.OnEvent(addonFrame,"DISPLAY_SIZE_CHANGED")
assert(mainWindow.scale<0.61,"window should shrink when display becomes smaller")
UIParent:SetSize(1000,700)
addonFrame.OnEvent(addonFrame,"UI_SCALE_CHANGED")
assert(mainWindow.scale>0.8,"window should recover scale after display restores")
local originalWidth=UIParent.GetWidth
UIParent.GetWidth=function() error("restricted parent geometry") end
assert(pcall(addonFrame.OnEvent,addonFrame,"UI_SCALE_CHANGED"),"restricted geometry must not crash resize")
UIParent.GetWidth=originalWidth
assert(compactButton and compactButton.OnClick,"compact toggle missing")
compactButton.OnClick(compactButton)
assert(mainWindow.height==620 and ForeverCompanionDB.compact,"compact layout failed")
for _,nav in ipairs(frames) do
 if nav.section then assert(-nav.point[5]+nav.height<=528,"compact navigation must stay above the footer") end
end
local focusTitle
for _,w in ipairs(frames) do if w.text=="TODAY\'S FOCUS" then focusTitle=w end end
assert(focusTitle and frames[focusTitle.parent].visible==false,"compact mode should hide lower focus panel")
compactButton.OnClick(compactButton)
assert(mainWindow.height==720 and not ForeverCompanionDB.compact,"expand layout failed")
assert(frames[focusTitle.parent].visible==true,"expanded mode should restore lower focus panel")
local savedXP=UnitXP
UnitXP=function() error("simulated restricted XP API") end
assert(pcall(ForeverCompanionDashboard.Render),"dashboard should tolerate restricted XP reads")
local xpUnavailable=false
for _,w in ipairs(frames) do if w.kind=="FontString" and w.text=="N/A" then xpUnavailable=true end end
assert(xpUnavailable,"unavailable XP should be labeled N/A")
UnitXP=savedXP
ForeverCompanionDashboard.Render()
SlashCmdList.FOREVERCOMPANION("")
SlashCmdList.FOREVERCOMPANION("")
local foundTitle=false
for _,f in ipairs(frames) do
 if f.text=="Brady\'s Forever Companion" then foundTitle=true end
end
assert(foundTitle,"main window title not rendered")
local foundBanner=false
for _,f in ipairs(frames) do if f.text=="WELCOME TO FOREVER COMPANION" then foundBanner=true end end
assert(foundBanner,"premium dashboard welcome banner missing")
local heraldicMarks=0
for _,w in ipairs(frames) do
 if w.kind=="Texture" and w.texture=="Interface\\AddOns\\ForeverCompanion\\Media\\Crest.tga" then heraldicMarks=heraldicMarks+1 end
end
assert(heraldicMarks>=2,"header and dashboard must use the same original heraldic crest")
-- Exercise the native class-guide hero and capture its real mock widget tree.
local levelingButton
for _,w in ipairs(frames) do if w.section=="Leveling" then levelingButton=w end end
assert(levelingButton and levelingButton.OnClick,"leveling sidebar navigation missing")
levelingButton.OnClick(levelingButton)
assert(ForeverCompanionDB.tab=="Leveling","leveling navigation failed")
local classHeading,rotationControl
for _,w in ipairs(frames) do
 if w.text=="CLASS GUIDES  /  WARRIOR" then classHeading=w end
 if w.OnClick and w.text=="Rotation: leveling" then rotationControl=w end
end
assert(classHeading,"wide class banner breadcrumb missing")
SlashCmdList.FOREVERCOMPANION("open class guides")
assert(ForeverCompanionDB.tab=="Leveling","visible Class Guides label must work in slash navigation")
local specControl
for _,w in ipairs(frames) do if w.OnClick and w.text=="Spec: Arms" then specControl=w end end
assert(specControl and specControl.parent==mainWindow.id,"header specialization selector must avoid scroll-child clipping")
assert(#ForeverCompanionClassGuide.topicButtons==8,"class guide requires eight functional topic tabs")
local classScroll
for _,w in ipairs(frames) do
 if w.kind=="ScrollFrame" and w.parent==mainWindow.id then classScroll=w end
end
assert(classScroll,"class guide requires a scroll viewport")
for _,button in ipairs(ForeverCompanionClassGuide.topicButtons) do
 classScroll:SetVerticalScroll(350)
 button.OnClick()
 assert(ForeverCompanionClassGuide.GetView()==button.view,"topic selection must persist")
 assert(classScroll:GetVerticalScroll()==0,"switching guide topics returns to the heading")
 assert(ForeverCompanionClassGuide.topicPanel.visible==(button.view~="Rotations"),"topic panel visibility")
 if button.view=="Talents" then
  assert(ForeverCompanionTalentWorkspace.root:IsShown(),"talent planner visibility")
 elseif button.view~="Rotations" then
  assert(ForeverCompanionClassGuide.topicBody.text:find(button.view=="Gear & Stats" and "SOURCE-REVIEWED BETA THEORYCRAFT" or (button.view=="Overview" and "SELECTED SPEC" or "GENERAL REFERENCE"),1,true),"topic evidence notice")
 end
end
ForeverCompanionClassGuide.SelectView("Gear & Stats")
exportNative("ui_gear_native.json")
ForeverCompanionClassGuide.SelectView("Talents")
do
 local model=ForeverCompanionTalentPlanner
 local talents=ForeverCompanionTalentData
 local planner=ForeverCompanionTalentWorkspace
 local count,trees=0,0
 assert(model.Budget(9)==0 and model.Budget(10)==1 and model.Budget(60)==51)
 for class,data in pairs(talents.classes) do
  local positions={}
  for _,node in ipairs(data.nodes) do
   local position=table.concat({node[2],node[3],node[4]},":")
   assert(not positions[position] and node[7]>0 and node[8]>0,node[9])
   positions[position]=true
   count=count+1
  end
  for _,specEntry in ipairs(ForeverCompanionSpecs[class]) do
   local name=specEntry[1]
   local recommendation=assert(model.Recommendation(class,name),class.." / "..name)
   local draft={}
   assert(model.CopyRecommendation(class,name,draft))
   assert(model.Total(class,draft)==51 and not model.CopyRecommendation(class,name,draft))
   local replay={}
   local count=0
   while count<51 do
    local before=count
    for _,node in ipairs(data.nodes) do
     local target=draft[node[1]] or 0
     assert(target<=node[6],node[9])
     while model.Rank(replay,node)<target and model.Change(class,replay,node,1,51) do
      count=count+1
     end
    end
    assert(count>before,class.." / "..name.." has an unreachable recommendation")
   end
   for id,rank in pairs(recommendation[3]) do assert(replay[id]==rank) end
  end
  for tree=1,3 do
   local spec=ForeverCompanionSpecs[class][tree][1]
   local opening=model.Opening(class,tree,spec)
   assert(#opening>=2 and #model.Goals(class,tree,spec)==3,spec)
   local draft={}
   assert(model.LoadOpening(class,tree,spec,draft,11),spec)
   assert(model.Rank(draft,opening[1])==opening[1][6],opening[1][9])
   assert(not model.LoadOpening(class,tree,spec,draft,51),"opening must preserve existing drafts")
   local full={}
   assert(model.LoadOpening(class,tree,spec,full,51),spec)
   for _,node in ipairs(opening) do assert(model.Rank(full,node)==node[6],spec.." / "..node[9]) end
   local first={}
   assert(model.LoadOpening(class,tree,spec,first,1) and model.Total(class,first)==1,spec)
   trees=trees+1
  end
 end
 assert(count==467 and trees==27)
 local bear={}
 assert(model.LoadOpening("DRUID",2,"Guardian / Bear",bear,51))
 for _,node in ipairs(model.Opening("DRUID",2,"Guardian / Bear")) do assert(model.Rank(bear,node)==node[6]) end
 local warrior=talents.classes.WARRIOR.nodes
 local arms={}
 assert(not model.Change("WARRIOR",arms,warrior[4],1,51),"tier gate")
 for _=1,5 do assert(model.Change("WARRIOR",arms,warrior[2],1,51)) end
 assert(not model.Change("WARRIOR",arms,warrior[2],1,51),"rank cap")
 assert(model.Change("WARRIOR",arms,warrior[4],1,51))
 assert(not model.Change("WARRIOR",arms,warrior[2],-1,51),"refund cannot break tier")
 assert(model.Rank(arms,warrior[2])==5)
 local second={}
 for _,index in ipairs({2,3,5}) do
  for _=1,warrior[index][6] do assert(model.Change("WARRIOR",second,warrior[index],1,51)) end
 end
 assert(model.Change("WARRIOR",second,warrior[8],1,51))
 assert(not model.Change("WARRIOR",second,warrior[3],-1,51),"refund cannot break direct prerequisite")
 local allocation=model.Load("WARRIOR","Arms")
 local other=model.Load("WARRIOR","Fury")
 planner.buttons[1]:OnClick("LeftButton")
 assert(model.Rank(allocation,planner.buttons[1].node)==1 and model.Total("WARRIOR",other)==0)
 planner.buttons[1]:OnClick("RightButton")
 assert(model.Total("WARRIOR",allocation)==0)
 planner.buildButton:OnClick()
 assert(model.Total("WARRIOR",allocation)>0 and model.Load("WARRIOR","Arms")==allocation)
 local openingTotal=model.Total("WARRIOR",allocation)
 planner.recommendationButton:OnClick()
 assert(planner.recommendationButton.text=="Back to My Draft")
 assert(planner.buildButton.text=="Copy to empty draft" and not planner.lowerLevel.enabled)
 exportNative("ui_topic_native.json")
 planner.buttons[1]:OnClick("LeftButton")
 planner.buttons[1]:OnClick("RightButton")
 planner.buildButton:OnClick()
 assert(model.Total("WARRIOR",allocation)==openingTotal,"preview and copy guard preserve the draft")
 planner.recommendationButton:OnClick()
 assert(planner.buildButton.text=="Load opening ranks" and planner.lowerLevel.enabled)
 planner.tabs[2]:OnClick()
 assert(planner.buttons[1].node[2]==2)
 planner.tabs[1]:OnClick()
 planner.lowerLevel:OnClick()
 assert(model.Level(allocation)==59 and model.Level(other)==60)
 ForeverCompanionSpecPlanner.Next("WARRIOR")
 ForeverCompanionRefresh()
 planner.lowerLevel:OnClick()
 planner.lowerLevel:OnClick()
 assert(model.Level(other)==58 and model.Level(allocation)==59,"level belongs to the active spec draft")
 ForeverCompanionDB.specSelections.WARRIOR=1
 ForeverCompanionRefresh()
 assert(model.Level(model.Load("WARRIOR","Arms"))==59,"switching specs preserves the saved level")
 planner.resetButton:OnClick()
 assert(model.Total("WARRIOR",allocation)>0,"reset needs confirmation")
 planner.resetButton:OnClick()
 assert(model.Total("WARRIOR",allocation)==0 and model.Level(allocation)==59,"confirmed reset clears ranks and preserves the plan level")
 planner.lowerLevel:OnClick()
 planner.recommendationButton:OnClick()
 planner.buildButton:OnClick()
 assert(model.Total("WARRIOR",allocation)==51 and model.Level(allocation)==60 and planner.recommendationButton.text=="Recommended Build")
 planner.resetButton:OnClick()
 planner.resetButton:OnClick()
end
assert(not ForeverCompanionClassGuide.SelectView("Not a topic"),"invalid topic must be rejected")
ForeverCompanionDB.classGuideView="malformed saved view"
assert(ForeverCompanionClassGuide.GetView()=="Rotations","invalid saved topic must recover to rotation view")
ForeverCompanionClassGuide.SelectView("Rotations")
local currentFocus=false
for _,w in ipairs(frames) do
 if w.text:find("FOCUS: At higher levels",1,true)==1 then currentFocus=true end
end
assert(currentFocus,"leveling hero must display class-specific current stage focus")
local unifiedCards=0
for _,w in ipairs(frames) do
 if w.fcPanelEdges and w.fcPanelBackground then
  unifiedCards=unifiedCards+1
  assert(w.fcPanelBackground.color[1]<.06,"shared cards retain a dark reading surface")
 end
end
assert(unifiedCards>=12,"guide and utility cards share the same surface system")
assert(frames[classHeading.parent].visible,"class-guide header should be visible on Leveling")
assert(rotationControl and rotationControl.point and rotationControl.point[1]=="TOPLEFT","rotation control should be in content area")
local workspace=ForeverCompanionRotationWorkspace
assert(workspace.rows[1].visible and workspace.rows[1].number.text=="1","first priority is visible inside its panel")
-- All nine class-preview buttons must be interactive, and must not mutate the player.
local savedPreviewRole=ForeverCompanionDB.role
local classTokens={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
assert(ForeverCompanionClassStripButtons and #ForeverCompanionClassStripButtons==9,"class strip must offer all nine classes")
for i,token in ipairs(classTokens) do
 local button=ForeverCompanionClassStripButtons[i]
 assert(button.classToken==token and button.OnClick and button.visible,"class strip button missing or hidden")
 button.OnClick(button)
 assert(ForeverCompanionDB.previewClass==token,"class selector did not update addon preview")
 for _,topicButton in ipairs(ForeverCompanionClassGuide.topicButtons) do
  topicButton.OnClick()
  assert(ForeverCompanionClassGuide.GetView()==topicButton.view,"topic navigation must work for every class")
 end
 ForeverCompanionClassGuide.SelectView("Rotations")
 for _,contextButton in ipairs(ForeverCompanionRotationWorkspace.buttons) do
  contextButton.OnClick()
  local reference,_,_,_,primary,summary=ForeverCompanionVisiblePriority(token,contextButton.mode,60,nil,ForeverCompanionRotations[token][contextButton.mode])
  for index,step in ipairs(workspace.Plan(reference,primary,"WARRIOR",token,summary)) do
   local row=workspace.rows[index]
   assert(row and row.visible and row.parent==workspace.panel.id,"all steps must be shown inside the priority panel")
   assert(row.instruction==step.text,"row must show the complete instruction")
  end
  for index=#reference+1,#workspace.rows do assert(not workspace.rows[index].visible,"stale priority row") end
 end
end
ForeverCompanionClassStripButtons[1].OnClick(ForeverCompanionClassStripButtons[1])
ForeverCompanionRotationWorkspace.buttons[1].OnClick()
-- Clear preview before testing unavailable live class APIs.
ForeverCompanionDB.previewClass=nil
ForeverCompanionDB.role=savedPreviewRole
ForeverCompanionRefresh()

local classSnapshot={}
for _,f in ipairs(frames) do
 local anchor=f.point and clean(f.point[1]) or ""
 local x,y="",""
 if f.point then
  for _,v in ipairs(f.point) do if type(v)=="number" then if x=="" then x=v else y=v end end end
 end
 classSnapshot[#classSnapshot+1]=table.concat({f.id,f.kind,f.parent or "",f.visible and "1" or "0",f.width or "",f.height or "",anchor,x,y,clean(f.text),clean(f.texture)},"|")
end
local classOut=assert(io.open("ui_leveling_snapshot.txt","w"))
classOut:write("id|kind|parent|visible|width|height|anchor|x|y|text|texture",string.char(10))
classOut:write(table.concat(classSnapshot,string.char(10)))
classOut:close()
exportNative("ui_class_native.json")
assert(#workspace.buttons==5,"direct context navigation must expose every context")
for i,button in ipairs(workspace.buttons) do
 button.OnClick()
 assert(rotationControl.text=="Rotation: "..({"leveling","dungeon","boss","aoe","pvp"})[i])
 assert(workspace.rows[1].visible,"selected context must show its first priority")
end
workspace.buttons[1].OnClick()
assert(not workspace.ShowReference(),"long notes are collapsed by default")
workspace.reference.OnClick()
assert(workspace.ShowReference(),"guide notes toggle must reveal reference")
workspace.reference.OnClick()
local shortWorkspaceHeight=workspace.GetHeight()
local row=workspace.rows[1]
local originalMeasure=row.caption.GetStringHeight
row.caption.GetStringHeight=function() return 350 end
workspace.buttons[1].OnClick()
assert(row.height>=366 and workspace.GetHeight()>shortWorkspaceHeight,"long steps expand the card and panel")
local edges=workspace.panel.fcPanelEdges
assert(edges.left.height==workspace.panel.height,"resized left border follows panel")
exportNative("ui_long_priority_native.json")
row.caption.GetStringHeight=originalMeasure
workspace.buttons[1].OnClick()
assert(workspace.GetHeight()==shortWorkspaceHeight,"short content shrinks after expansion")
local savedPaladinSpec=ForeverCompanionDB.specSelections.PALADIN
ForeverCompanionDB.specSelections.PALADIN=2
local early,_,_,_,earlyPrimary=ForeverCompanionVisiblePriority("PALADIN","boss",11,"Tank",{})
assert(#early==3 and earlyPrimary[1]=="Seal of Fury" and earlyPrimary[3]=="Holy Strike")
assert(not table.concat(early):find("Consecration",1,true))
ForeverCompanionDB.specSelections.PALADIN=3
local ret=ForeverCompanionVisiblePriority("PALADIN","boss",11,"Damage",{})
assert(table.concat(ret):find("Seal of Righteousness",1,true) and not table.concat(ret):find("Seal of Fury",1,true))
ForeverCompanionDB.specSelections.PALADIN=savedPaladinSpec
local savedSpell=C_Spell
C_Spell={GetSpellInfo=function(name)
 if name=="Holy Strike" then return {name="Holy Strike",spellID=680,iconID=12345} end
end}
assert(ForeverCompanionIcons.SpellDetails(earlyPrimary[3]).spellID==680)
assert(not ForeverCompanionIcons.SpellDetails("Holy Strikeout"),"do not match partial spell names")
local scanSpellbook=ForeverCompanionSpellbook.Scan
local scans=0
ForeverCompanionSpellbook.Scan=function()
 scans=scans+1
 return {supported=true,complete=true,inspected=1,known={["holy strike"]=true}}
end
local plan=workspace.Plan(early,earlyPrimary,"PALADIN","PALADIN")
assert(plan[1].spell.spellID==680 and plan[1].status=="In your spellbook")
assert(plan[2].status:find("not found",1,true))
local preview=workspace.Plan(early,earlyPrimary,"WARRIOR","PALADIN")
assert(scans==1 and preview[1].status=="Class preview","other-class previews do not use the character's spellbook")
ForeverCompanionSpellbook.Scan=function() return {supported=true,complete=false,inspected=1,known={}} end
assert(workspace.Plan(early,earlyPrimary,"PALADIN","PALADIN")[1].status=="Training unconfirmed")
ForeverCompanionSpellbook.Scan=function() return {supported=true,complete=true,inspected=1,known={},englishNames=false} end
local localized,_,missing=workspace.Plan(early,earlyPrimary,"PALADIN","PALADIN")
assert(localized[1].status=="Training unconfirmed" and missing==0,"localized name mismatch is not a missing spell")
local refreshes=0
ForeverCompanionSpellbook.Scan=function()
 refreshes=refreshes+1
 return {supported=true,complete=true,inspected=1,known={}}
end
assert(addonFrame.events.SPELLS_CHANGED,"guide must subscribe to spellbook changes")
mainWindow:Show()
addonFrame.OnEvent(addonFrame,"SPELLS_CHANGED")
assert(refreshes>0,"visible class guide refreshes when the spellbook changes")
mainWindow:Hide()
refreshes=0
addonFrame.OnEvent(addonFrame,"SPELLS_CHANGED")
assert(refreshes==0,"hidden addon does not scan on spellbook changes")
addonFrame.OnEvent(addonFrame,"PLAYER_XP_UPDATE")
addonFrame.OnEvent(addonFrame,"PLAYER_ENTERING_WORLD")
ForeverCompanionQuestPlanner.Sync()
assert(refreshes==0,"hidden addon does not rebuild guidance on XP, zone or quest events")
mainWindow:Show()
ForeverCompanionSpellbook.Scan=scanSpellbook
C_Spell=savedSpell
local guide=ForeverCompanionClassGuide
local priorSelections=ForeverCompanionDB.specSelections
ForeverCompanionDB.specSelections={}
local specCount=0
for class,choices in pairs(ForeverCompanionSpecs) do
 for i,choice in ipairs(choices) do
  ForeverCompanionDB.specSelections[class]=i
  local overview=table.concat(guide.TopicLines(class,"Overview")," ")
  local previousView=ForeverCompanionDB.classGuideView
  ForeverCompanionDB.classGuideView='Gear & Stats'
  guide.Render(class,class,60,choice[2])
  local profile=ForeverCompanionGearStats.Get(class,choice[1])
  if profile then
   local cards=guide.readingCards
   assert(cards[2].body.text:find(profile.order[1],1,true),'priority card must use this specialization profile')
   assert(cards[3].body.text==profile.note,'comparison card must retain the full source note')
   for _,card in ipairs(cards) do
    if card.visible then
     assert(card.body.height>=card.body:GetStringHeight(),'guide card must grow around wrapped text')
     assert(-card.point[5]+card.height<=guide.GetTopicHeight(),'reading cards must stay inside the scroll content')
    end
   end
  end
  ForeverCompanionDB.classGuideView=previousView
  for _,mode in ipairs({"leveling","dungeon","boss","aoe","pvp"}) do
   local steps,title,_,_,_,summary=ForeverCompanionVisiblePriority(class,mode,60,nil,{})
   assert(#steps>=3 and title:find(choice[1],1,true) and summary and summary.opener,choice[1]..": missing "..mode.." instructions")
  end
  assert(overview:find(choice[1],1,true) and overview:find("3 BEGINNER ACTIONS",1,true))
  if choice[1]=="Guardian / Bear" then
   assert(overview:find("No published Forever priority",1,true))
  else
   specCount=specCount+1
   assert(overview:find("PUBLISHED FOREVER GUIDE",1,true))
   local boss,title,_,_,primary=ForeverCompanionVisiblePriority(class,"boss",60,nil,{})
   assert(#boss>=3 and title==choice[1].." / Boss","every standard spec has a boss priority in the rotation window")
   assert(#boss==#primary,"every row has a deliberate spell or non-spell cue")
   for index,name in ipairs(primary) do
    if name then assert(boss[index]:lower():find(name:lower(),1,true) or (name=="Power Word: Shield" and boss[index]:find("Shield",1,true)),title..": cue must match step "..index) end
   end
   if choice[1]=="Combat" then assert(overview:find("Blade Flurry",1,true)) end
   if choice[1]=="Beast Mastery" then assert(overview:find("Bestial Wrath",1,true)) end
   assert(overview:find("Reference: https://",1,true))
  end
 end
end
assert(specCount==27)
ForeverCompanionDB.specSelections=priorSelections
ForeverCompanionClassGuide.SelectView("Leveling")
local readingCard=ForeverCompanionClassGuide.readingCards[2]
local originalTopicMeasure=readingCard.body.GetStringHeight
readingCard.body.GetStringHeight=function() return 480 end
ForeverCompanionClassGuide.SelectView("Leveling")
assert(readingCard.body.height>=484,"long note needs measured reading space")
assert(ForeverCompanionClassGuide.GetTopicHeight()>=602,"reading cards must expand the scroll content")
local following=ForeverCompanionClassGuide.readingCards[3]
assert(following and following.visible,'the next guide note must remain available')
readingCard.body.GetStringHeight=originalTopicMeasure
ForeverCompanionClassGuide.SelectView("Rotations")
workspace.buttons[1].OnClick()
rotationControl.OnClick(rotationControl)
assert(rotationControl.text=="Rotation: dungeon","rotation context selector failed")
overviewButton.OnClick(overviewButton)
assert(not frames[frames[classHeading.parent].parent].visible,"class guide should hide outside Leveling")
mockXP=2000
addonFrame.OnEvent(addonFrame,"PLAYER_XP_UPDATE")
local xpUpdated=false
for _,w in ipairs(frames) do if w.kind=="FontString" and w.text=="67%" then xpUpdated=true end end
assert(xpUpdated,"XP event should refresh live progress")
mockXP=1500
addonFrame.OnEvent(addonFrame,"PLAYER_XP_UPDATE")
local savedClass,savedLevel=UnitClass,UnitLevel
UnitClass=function() error("class API restricted") end
UnitLevel=function() error("level API restricted") end
assert(pcall(ForeverCompanionRefresh),"restricted class and level must not crash the dashboard")
local unknownClass=false
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text:find("Unknown class",1,true) then unknownClass=true end
end
assert(unknownClass,"missing class API must not impersonate Warrior")
UnitClass,UnitLevel=savedClass,savedLevel
ForeverCompanionRefresh()
-- The native Dungeon and PvP cards must be real widgets, reflect only manual
-- checklist state, and provide functional guide navigation without game actions.
local dungeonButton,pvpButton
for _,w in ipairs(frames) do
 if w.section=="Dungeons" then dungeonButton=w end
 if w.section=="PvP" then pvpButton=w end
end
assert(dungeonButton and pvpButton,"Dungeon/PvP sidebar entries missing")
dungeonButton.OnClick(dungeonButton)
assert(ForeverCompanionDB.tab=="Dungeons","Dungeon navigation failed")
local dungeonHeading,progressLabel
for _,w in ipairs(frames) do
 if w.text=="DUNGEON PREPARATION" then dungeonHeading=w end
 if w.text=="0/4 preparation tasks marked complete" then progressLabel=w end
end
assert(dungeonHeading and progressLabel,"native Dungeon briefing missing or miscounted")
local dungeonRoot=frames[dungeonHeading.parent].parent
assert(frames[dungeonRoot].visible,"Dungeon cards must be visible on Dungeon page")
local manualDone
for _,w in ipairs(frames) do
 if w.caption and w.caption.text=="Collect dungeon quests" and w.OnClick then manualDone=w end
end
assert(manualDone and manualDone.visible,"native Dungeon checklist tile missing")
manualDone.OnClick(manualDone)
assert(ForeverCompanionDB.checks.Dungeons[1]==true,"manual Dungeon task was not saved")
assert(manualDone.checked and manualDone.status.text=="DONE","Dungeon tile did not show completion")
assert(progressLabel.text=="1/4 preparation tasks marked complete","Dungeon card did not refresh manual progress")
exportSnapshot("ui_dungeon_snapshot.txt")
manualDone.OnClick(manualDone)
assert(ForeverCompanionDB.checks.Dungeons[1]==false,"Dungeon task undo failed")
local guideLink
for _,w in ipairs(frames) do
 if w.text=="OPEN CLASS GUIDE" and w.parent then guideLink=frames[w.parent] end
end
assert(guideLink and guideLink.OnClick,"native class-guide shortcut missing")
guideLink.OnClick(guideLink)
assert(ForeverCompanionDB.tab=="Leveling","native class-guide shortcut did not navigate")
pvpButton.OnClick(pvpButton)
assert(ForeverCompanionDB.tab=="PvP","PvP navigation failed")
local pvpHeading
for _,w in ipairs(frames) do if w.text=="PVP PREPARATION" then pvpHeading=w end end
assert(pvpHeading,"PvP preparation title did not update")
local pvpRoleAdvice=false
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text:find("Coordinate target focus and avoid overextending",1,true) then pvpRoleAdvice=true end
end
assert(pvpRoleAdvice,"PvP role guidance must not reuse dungeon-only tank-target instructions")
assert(frames[dungeonRoot].visible,"PvP must reuse the same native briefing cards")
assert(progressLabel.text=="0/4 preparation tasks marked complete","PvP must have separate manual checklist progress")
local pvpDone
for _,w in ipairs(frames) do
 if w.caption and w.caption.text=="Check equipment" and w.OnClick then pvpDone=w end
end
assert(pvpDone and pvpDone.visible,"native PvP checklist tile missing")
pvpDone.OnClick(pvpDone)
assert(ForeverCompanionDB.checks.PvP[1]==true,"PvP task state was not saved")
assert(pvpDone.checked and pvpDone.status.text=="DONE","PvP tile did not show completion")
assert(progressLabel.text=="1/4 preparation tasks marked complete","PvP manual progress did not update")
assert(ForeverCompanionDB.checks.Dungeons[1]==false,"PvP state must not change Dungeon tasks")
exportSnapshot("ui_pvp_snapshot.txt")
exportNative("ui_pvp_native.json")
pvpDone.OnClick(pvpDone)
local questLink
for _,w in ipairs(frames) do
 if w.text=="OPEN QUEST JOURNAL" and w.parent then questLink=frames[w.parent] end
end
assert(questLink and questLink.OnClick,"native quest-journal shortcut missing")
questLink.OnClick(questLink)
assert(ForeverCompanionDB.tab=="Quests","native quest-journal shortcut failed")
assert(not frames[dungeonRoot].visible,"Adventure cards must hide on Quest page")
-- Settings is a real native interface, not merely a text-only command list.
local settingsNav
for _,w in ipairs(frames) do if w.section=="Settings" then settingsNav=w end end
assert(settingsNav and settingsNav.OnClick,"Settings navigation missing")
settingsNav.OnClick(settingsNav)
assert(ForeverCompanionDB.tab=="Settings","Settings navigation failed")
local settingsHeading,apiHeading,clientLabel
local autoButton,centerButton,compactSettingsButton
for _,w in ipairs(frames) do
 if w.text=="PREFERENCES & CHARACTER" then settingsHeading=w end
 if w.text=="CLIENT API VISIBILITY" then apiHeading=w end
 if w.text:find("Client: OfflineMock",1,true) then clientLabel=w end
 if w.caption and w.caption.text=="AUTO-DETECT CLASS" then autoButton=w end
 if w.caption and w.caption.text=="CENTER WINDOW" then centerButton=w end
 if w.caption and w.caption.text=="TOGGLE COMPACT" then compactSettingsButton=w end
end
assert(settingsHeading and apiHeading and clientLabel,"native Settings cards or client metadata missing")
local questApiDisclosure=false
local professionApiDisclosure=false
for _,w in ipairs(frames) do
 if w.text=="Quest log: API exposed; compatibility unverified" then questApiDisclosure=true end
 if w.text=="Professions: API exposed; compatibility unverified" then professionApiDisclosure=true end
end
assert(questApiDisclosure and professionApiDisclosure,"Settings must distinguish API exposure from live compatibility")
assert(frames[frames[settingsHeading.parent].parent].visible,"Settings cards should be visible")
assert(autoButton and centerButton and compactSettingsButton,"Settings preference actions missing")
SlashCmdList.FOREVERCOMPANION("class mage")
assert(ForeverCompanionDB.previewClass=="MAGE","fixture preview class selection failed")
autoButton.OnClick(autoButton)
assert(ForeverCompanionDB.previewClass==nil,"Settings auto class must reset only addon preview")
ForeverCompanionDB.position={x=20,y=30}
centerButton.OnClick(centerButton)
assert(ForeverCompanionDB.position==nil,"Settings center button should clear saved position")
local wasCompact=ForeverCompanionDB.compact
compactSettingsButton.OnClick(compactSettingsButton)
assert(ForeverCompanionDB.compact~=wasCompact,"Settings compact toggle did not persist")
local layoutTextFound=false
for _,w in ipairs(frames) do
 if w.text:find("Layout: ",1,true) and w.text:find(ForeverCompanionDB.compact and "Compact" or "Expanded",1,true) then layoutTextFound=true end
end
assert(layoutTextFound,"Settings layout summary did not refresh")
local originalBuildInfo=GetBuildInfo
GetBuildInfo=nil
assert(pcall(ForeverCompanionRefresh),"Settings must survive absent client build API")
local missingBuild=false
for _,w in ipairs(frames) do if w.text=="Client: Unknown  |  Interface: ?" then missingBuild=true end end
assert(missingBuild,"Settings must not invent a missing client Interface number")
GetBuildInfo=originalBuildInfo
ForeverCompanionRefresh()
exportSnapshot("ui_settings_snapshot.txt")
exportNative("ui_settings_native.json")
overviewButton.OnClick(overviewButton)
assert(not frames[frames[settingsHeading.parent].parent].visible,"Settings cards must hide on dashboard")
-- Notebook edits persist only when explicitly saved and are context-isolated.
SlashCmdList.FOREVERCOMPANION("open legacy")
local saveNote,clearNote
for _,w in ipairs(frames) do
 if w.OnClick and w.text=="Save research note" then saveNote=w end
 if w.OnClick and w.text=="Clear research note" then clearNote=w end
end
assert(saveNote and clearNote,"notebook controls missing")
local noteFields={}
for _,w in ipairs(frames) do
 if w.kind=="EditBox" and w.parent==saveNote.parent then noteFields[#noteFields+1]=w end
end
assert(#noteFields==3,"note/source/build inputs required")
noteFields[1]:SetText("Check exact unlock requirement")
noteFields[1].OnTextChanged(noteFields[1],true)
ForeverCompanionRefresh()
assert(noteFields[1]:GetText()=="Check exact unlock requirement","ordinary refresh must preserve unsaved input")
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Legacy").note=="")
noteFields[2]:SetText("https://example.test/observation")
noteFields[3]:SetText("offline test build")
saveNote.OnClick()
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Legacy").note=="Check exact unlock requirement")
SlashCmdList.FOREVERCOMPANION("open alts")
assert(noteFields[1]:GetText()=="","Alt notes must not show Legacy text")
noteFields[1]:SetText("Unsaved alt route")
noteFields[1].OnTextChanged(noteFields[1],true)
overviewButton.OnClick(overviewButton)
SlashCmdList.FOREVERCOMPANION("open alts")
assert(noteFields[1]:GetText()=="Unsaved alt route","session draft survives leaving research pages")
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Alts").note=="","draft must not be saved implicitly")
noteFields[1].OnEscapePressed(noteFields[1])
assert(noteFields[1]:GetText()=="","Escape discards restored draft")
SlashCmdList.FOREVERCOMPANION("open legacy")
assert(noteFields[1]:GetText()=="Check exact unlock requirement")
noteFields[1]:SetText("Unsaved replacement")
noteFields[1].OnEscapePressed(noteFields[1])
assert(noteFields[1]:GetText()=="Check exact unlock requirement","Escape restores saved research")
clearNote.OnClick()
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Legacy").note=="")
overviewButton.OnClick(overviewButton)
-- Exercise newly integrated pages through the actual manifest and native buttons.
local function buttonWithText(value)
 for _,w in ipairs(frames) do if w.OnClick and w.text==value then return w end end
end
SlashCmdList.FOREVERCOMPANION("open legacy")
local legacyState=ForeverCompanionStudyBoard.Get("Legacy","WARRIOR",ForeverCompanionDB)
assert(legacyState.total==5 and legacyState.done==0)
local legacyReference
for _,w in ipairs(frames) do
 if w.text:find("BLIZZARD LAUNCH REFERENCE",1,true) and w.text:find("launch cap of 16",1,true) then legacyReference=true end
end
assert(legacyReference,"Legacy handbook must show the published launch rules")
local studyRow
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text==legacyState.tasks[1] then studyRow=frames[w.parent] end
end
assert(studyRow and studyRow.OnClick,"visible Legacy task must be clickable")
studyRow.OnClick(studyRow)
assert(ForeverCompanionStudyBoard.Get("Legacy","WARRIOR",ForeverCompanionDB).done==1)
exportSnapshot("ui_legacy_snapshot.txt")
exportNative("ui_legacy_native.json")
buttonWithText("ALT PREPARATION").OnClick()
assert(ForeverCompanionDB.tab=="Alts","Legacy shortcut should open alt desk")
assert(ForeverCompanionStudyBoard.Get("Alts","WARRIOR",ForeverCompanionDB).done==0)
exportSnapshot("ui_alts_snapshot.txt")
exportNative("ui_alts_native.json")
SlashCmdList.FOREVERCOMPANION("open dungeons")
assert(ForeverCompanionEncounterBrowser.dungeon~="")
local browser=ForeverCompanionEncounterBrowser
browser.dungeon="The Deadmines";browser.boss="Captain Greenskin";browser.page=1
ForeverCompanionRefresh()
local firstBoss=browser.boss
local itemButton=browser.lootRows[1]
assert(itemButton.visible and itemButton.record.itemID,"dungeon items have a native tooltip ID")
function tooltip:SetHyperlink(link) self.link=link end
GameTooltip=tooltip
itemButton.OnEnter(itemButton)
assert(tooltip.link=="item:"..itemButton.record.itemID)
itemButton.OnLeave()
GameTooltip=oldTooltip
noteFields[1]:SetText("Unsaved boss observation")
noteFields[1].OnTextChanged(noteFields[1],true)
assert(browser.rows[2].boss and browser.rows[2].boss~=firstBoss)
browser.rows[2].OnClick(browser.rows[2])
assert(noteFields[1]:GetText()=="","boss notes must follow actual selected encounter")
browser.rows[1].OnClick(browser.rows[1])
assert(noteFields[1]:GetText()=="Unsaved boss observation","boss draft restored after selection changes")
saveNote.OnClick()
assert(ForeverCompanionResearchNotebook.Read(ForeverCompanionDB,"Boss:"..browser.dungeon..":"..firstBoss).note=="Unsaved boss observation")
browser.nextBossPage.OnClick()
assert(browser.page==2 and browser.rows[1].boss,"catalog pagination")
browser.searchBox:SetText("Dull Sawblade")
browser.searchBox.OnTextChanged(browser.searchBox,true)
assert(browser.page==1 and browser.rows[1].boss=="Sneed","search by item must find its source boss")
assert(browser.boss==firstBoss,"filtering must preserve explicit encounter selection")
browser.rows[1].OnClick(browser.rows[1])
assert(browser.boss=="Sneed" and noteFields[1]:GetText()=="","direct search-result selection changes research context")
browser.searchBox:SetText("no known boss")
browser.searchBox.OnTextChanged(browser.searchBox,true)
assert(not browser.rows[1].visible and browser.boss=="Sneed","empty filter must not lose selection")
buttonWithText("Clear").OnClick()
assert(browser.query=="" and browser.searchBox:GetText()=="")
local function pickDungeon(name)
 for _,row in ipairs(browser.dungeonRows) do
  if row.dungeon==name then row:OnClick();return end
 end
 error("Missing dungeon choice: "..name)
end
pickDungeon("Wailing Caverns")
assert(browser.dungeon=="Wailing Caverns" and browser.boss=="Kresh" and browser.page==1)
pickDungeon("Blackfathom Deeps")
assert(browser.dungeon=="Blackfathom Deeps" and browser.boss=="Aku'mai" and #ForeverCompanionLoot.BossDrops(browser.dungeon,browser.boss)==3)
assert(#browser.dungeonRows==9 and browser.dungeonRows[9]:IsShown(),"all nine dungeons can be selected directly")
exportSnapshot("ui_encounter_snapshot.txt")
exportNative("ui_encounter_native.json")
local secondDrop=browser.lootRows[2].record
browser.lootRows[2]:OnClick()
assert(ForeverCompanionDB.tab=="Loot" and lootUI.itemTitle.text==secondDrop.item,"drop clicks focus that exact item")
SlashCmdList.FOREVERCOMPANION("open dungeon journal")
assert(ForeverCompanionDB.tab=="Dungeons" and browser.boss=="Aku'mai","journal navigation preserves the selected boss")
local openLoot=buttonWithText("Open boss loot")
assert(openLoot and openLoot.OnClick,"boss loot shortcut missing")
openLoot.OnClick()
assert(ForeverCompanionDB.tab=="Loot")
assert(ForeverCompanionLootUI.dungeon==ForeverCompanionEncounterBrowser.dungeon)
assert(ForeverCompanionLootUI.boss==ForeverCompanionEncounterBrowser.boss)
assert(ForeverCompanionLootUI.itemCard.visible,"loot card must render after navigation")
local selected=ForeverCompanionLoot.Filter("",ForeverCompanionLootUI.dungeon,false,ForeverCompanionDB,ForeverCompanionLootUI.boss)[1]
assert(selected and ForeverCompanionLootUI.itemTitle.text==selected.item)
assert(ForeverCompanionLootUI.obtainedButton.visible)
ForeverCompanionLootUI.obtainedButton.OnClick()
assert(ForeverCompanionLoot.Obtained(ForeverCompanionDB,selected.item))
assert(not ForeverCompanionLoot.Wishlist(ForeverCompanionDB)[selected.item],"obtained toggle must not add wishes")
ForeverCompanionLootUI.obtainedButton.OnClick()
assert(not ForeverCompanionLoot.Obtained(ForeverCompanionDB,selected.item))
ForeverCompanionLootUI.wishButton.OnClick()
assert(ForeverCompanionLoot.Wishlist(ForeverCompanionDB)[selected.item]==true)
ForeverCompanionLootUI.savedButton.OnClick()
assert(ForeverCompanionLootUI.savedOnly)
ForeverCompanionLootUI.resetButton.OnClick()
assert(ForeverCompanionLootUI.dungeon=="" and ForeverCompanionLootUI.boss=="" and not ForeverCompanionLootUI.savedOnly)
assert(ForeverCompanionLootUI.selectedIndex==1)
-- Browse directly, including the second page, then combine filters.
local catalog=ForeverCompanionLootWorkspace
assert(catalog.root.visible and #catalog.rows==6)
assert(catalog.rows[2].record)
catalog.rows[2].OnClick(catalog.rows[2])
assert(ForeverCompanionLootUI.selectedIndex==2 and ForeverCompanionLootUI.itemTitle.text==catalog.rows[2].record.item)
catalog.nextPage.OnClick()
assert(ForeverCompanionLootUI.selectedIndex==7 and catalog.rows[1].resultIndex==7)
assert(catalog.nextPage.enabled and catalog.previous.enabled)
catalog.nextPage.OnClick()
assert(ForeverCompanionLootUI.selectedIndex==13 and catalog.nextPage.enabled)
catalog.previous.OnClick()
catalog.previous.OnClick()
assert(ForeverCompanionLootUI.selectedIndex==1)
local desired=catalog.rows[1].record
catalog.statusButton.OnClick()
assert(ForeverCompanionLootUI.acquisition=="outstanding")
ForeverCompanionLootUI.obtainedButton.OnClick()
assert(ForeverCompanionLootUI.itemTitle.text~=desired.item,'marking acquired must update outstanding results')
catalog.statusButton.OnClick()
assert(ForeverCompanionLootUI.acquisition=="obtained" and catalog.rows[1].record.item==desired.item)
assert(not catalog.rows[2].visible,'stale result rows must hide')
catalog.researchButton.OnClick()
assert(ForeverCompanionDB.tab=="Dungeons" and browser.boss==desired.boss and browser.dungeon==desired.dungeon)
assert(ForeverCompanionResearchNotebook.Context("Dungeons")=="Boss:"..desired.dungeon..":"..desired.boss)
openLoot.OnClick()
assert(ForeverCompanionLootUI.acquisition=="" and ForeverCompanionLootUI.slot=="",'boss shortcut clears unrelated filters')
ForeverCompanionLootUI.resetButton.OnClick()
catalog.slotButton.OnClick()
local selectedSlot=ForeverCompanionLootUI.slot
for _,row in ipairs(catalog.rows) do if row.record then assert(row.record.slot==selectedSlot) end end
ForeverCompanionLootUI.query="no such loot";ForeverCompanionRefresh()
assert(not catalog.rows[1].visible and not catalog.researchButton.enabled)
assert(not ForeverCompanionLootUI.wishButton.enabled and not ForeverCompanionLootUI.obtainedButton.enabled)
ForeverCompanionLootUI.resetButton.OnClick()
assert(ForeverCompanionLootUI.slot=="" and ForeverCompanionLootUI.acquisition=="")
local measure=catalog.detail.GetStringHeight
catalog.detail.GetStringHeight=function() return 700 end
ForeverCompanionRefresh()
assert(catalog.detail.height>=707 and catalog.root.height>=1050,'long source descriptions expand beyond fixed row area')
assert(catalog.detailPanel.fcPanelEdges.left.height==catalog.detailPanel.height,'detail panel edges follow expansion')
for _,w in ipairs(frames) do
 if w.parent==catalog.root.id and w.text:find("Hover an item for stats",1,true)==1 then
  assert(-w.point[5]>=149+catalog.detailPanel.height+14,"long item details must not cover the catalog disclosure")
 end
end
catalog.detail.GetStringHeight=measure
ForeverCompanionRefresh()
exportNative("ui_loot_native.json")
local searchField=ForeverCompanionLootUI.searchBox
local priorSearch=searchField:GetText()
searchField:SetText("")
assert(searchField.fcPlaceholder.visible,"empty search shows its placeholder")
searchField:SetText("test")
assert(not searchField.fcPlaceholder.visible,"typing hides the placeholder")
searchField:SetText(priorSearch)

exportSnapshot("ui_loot_snapshot.txt")
SlashCmdList.FOREVERCOMPANION("open leveling")
assert(not catalog.root.visible,"catalog must hide outside Loot")
assert(not ForeverCompanionLootUI.itemCard.visible,"loot widgets hide outside Loot")
assert(not ForeverCompanionLootUI.obtainedButton.visible,"manual acquisition button hides outside Loot")
local practice=ForeverCompanionStudyBoard.Get("Leveling","WARRIOR",ForeverCompanionDB)
assert(practice and practice.total>=3)
exportSnapshot("ui_practice_snapshot.txt")
exportNative("ui_practice_native.json")
for _,w in ipairs(frames) do
 if type(w.texture)=="string" then assert(not w.texture:find("\\\\",1,true),"over-escaped texture path: "..w.texture) end
end
overviewButton.OnClick(overviewButton)
if ForeverCompanionDB.compact then ForeverCompanionUIState.compactButton.OnClick() end
exportNative("ui_dashboard_native.json")
for _,f in ipairs(frames) do
 local anchor=f.point and clean(f.point[1]) or ""
 local x,y="",""
 if f.point then
  for _,v in ipairs(f.point) do if type(v)=="number" then if x=="" then x=v else y=v end end end
 end
 snapshot[#snapshot+1]=table.concat({f.id,f.kind,f.parent or "",f.visible and "1" or "0",f.width or "",f.height or "",anchor,x,y,clean(f.text),clean(f.texture)}, "|")
end
local out=assert(io.open("ui_snapshot.txt","w"))
out:write("id|kind|parent|visible|width|height|anchor|x|y|text|texture",string.char(10))
out:write(table.concat(snapshot,string.char(10)))
out:close()
io.write("PASS: actual addon manifest loaded and core UI rendered in offline mock ("..#frames.." widgets)\n")



C_DamageMeter=nil
ForeverCompanionCombatMeter.Show()
ForeverCompanionCombatMeter.SetLayout("standard")
exportNative("ui_meter_native.json")
ForeverCompanionCombatMeter.SetLayout('compact')
exportNative('ui_meter_compact_native.json')
ForeverCompanionCombatMeter.SetLayout('expanded')
exportNative('ui_meter_expanded_native.json')
ForeverCompanionCombatMeter.SetLayout('standard')
ForeverCompanionCombatMeter.SetSkin('recount')
exportNative('ui_meter_recount_native.json')
ForeverCompanionCombatMeter.SetSkin('details')
local meterFrame
for _,f in ipairs(frames) do if f.name=='ForeverCompanionCombatMeterWindow' then meterFrame=f end end
assert(meterFrame)
ForeverCompanionCombatMeter.OpenOptions(meterFrame.optionsButton)
for _,f in ipairs(frames) do
 if f.kind=='FontString' and f.text=='METER OPTIONS' then
  -- Preview identity only; the control geometry and labels are the real UI.
  frames[f.parent].name='ForeverCompanionMeterOptionsPreview'
 end
end
exportNative('ui_meter_options_native.json')
ForeverCompanionCombatMeter.Hide()
do
 SlashCmdList.FOREVERCOMPANION('open quests')
 local planner=ForeverCompanionQuestPlanner
 local originalSelected,originalTargets,originalNavigate=planner.GetSelected,ForeverCompanionQuestWaypoints.Targets,ForeverCompanionQuestWaypoints.Navigate
 local q={id=900002,title='Sample: Supplies for the camp',complete=false,objectives={'Sample: Gather camp supplies'},objectiveStates={{known=true,done=false,current=2,required=5,kind='item'}}}
 planner.GetSelected=function() return q,1 end
 local locations={{map=1429,x=.2,y=.3,label='Sample supply source',source='QuestieDB drop',objectiveIndex=1,reference=true},{map=1429,x=.6,y=.4,label='Sample alternative source',source='QuestieDB drop',objectiveIndex=1,reference=true}}
 ForeverCompanionQuestWaypoints.Targets=function() return locations end
 local navigated
 ForeverCompanionQuestWaypoints.Navigate=function(target) navigated=target;return 'Test objective selected' end
 ForeverCompanionQuestFieldGuide.Refresh()
 local guide,go,cycle
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestFieldGuidePanel' then guide=f end end
 assert(guide)
 for _,f in ipairs(frames) do
  if f.kind=='Button' and f.parent and frames[f.parent].parent==guide.id then
   if f.text=='Navigate to objective' then go=f elseif f.text=='Location 1 / 2' then cycle=f end
  end
 end
 assert(go and go.enabled and cycle and cycle.enabled)
 cycle.OnClick(cycle);go.OnClick(go);assert(navigated.x==.6)
 locations={locations[2],locations[1]};ForeverCompanionQuestFieldGuide.Refresh();go.OnClick(go)
 assert(navigated.x==.6,'field guide keeps the selected objective location after reordering')
 exportNative('ui_fieldguide_native.json')
 q.objectiveStates[1].done=true;ForeverCompanionQuestFieldGuide.Refresh()
 assert(go.enabled==false,'completed objective cannot retain stale navigation')
 planner.GetSelected=originalSelected;ForeverCompanionQuestWaypoints.Targets=originalTargets;ForeverCompanionQuestWaypoints.Navigate=originalNavigate
 ForeverCompanionQuestFieldGuide.Refresh()
 ForeverCompanionQuestTracker.Show()
 exportNative('ui_tracker_native.json')
 local tracker,first
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestTrackerFrame' then tracker=f end end
 assert(tracker and tracker.visible and ForeverCompanionQuestTracker.IsShown())
 for _,f in ipairs(frames) do if f.parent==tracker.id and f.item then first=f;break end end
 assert(first and first.item.quest)
 first.OnClick(first,'LeftButton')
 assert(planner.GetSelected()==first.item.quest and ForeverCompanionDB.tab=='Quests','tracker opens the actual quest field guide')
 ForeverCompanionDB.questTracker.collapsed=true;ForeverCompanionQuestTracker.Refresh()
 assert(tracker.height==28 and not first.visible)
 ForeverCompanionDB.questTracker.collapsed=false
 local main
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionMainFrame' then main=f end end
 assert(main);main:Hide()
 local supported=planner.IsSupported;planner.IsSupported=function() return false end
 ForeverCompanionRefresh();assert(first.map.enabled==false,'tracker must keep updating and reject cached navigation while the main window is hidden')
 planner.IsSupported=supported
 main:Show();ForeverCompanionRefresh()
 ForeverCompanionQuestTracker.Hide();assert(not tracker.visible and not ForeverCompanionQuestTracker.IsShown())
 assert(ForeverCompanionOpenQuestGuide(-1)==false)
end
do
 local originalCatalog=ForeverCompanionAvailableQuests.Catalog
 local originalHistory=ForeverCompanionDB.questHistory
 local originalMap=C_Map
 local originalDate=date
 date=function(pattern,at) return os.date(pattern,at) end
 C_Map={GetBestMapForUnit=function() return 1429 end,GetMapInfo=function() return {name='Sample forest'} end}
 local q=ForeverCompanionQuestPlanner.GetLive()[1]
 local targets={{map=1429,x=.2,y=.3,label='Sample quest giver',source='Forever QuestieDB quest giver'}}
 local catalog={
  {id=q.id,title=q.title,status='active',ready=q.complete,minimum=1,reason='Currently in the live quest log',dependencies={},targets=targets},
  {id=900101,title='Sample: Camp patrol',status='available',minimum=10,reason='Basic checks passed; confirm special requirements with the giver',dependencies={},targets=targets},
  {id=900102,title='Sample: Supply chain',status='locked',minimum=10,reason='Complete one prerequisite quest',dependencies={'Sample: First supplies'},targets=targets},
  {id=900103,title='Sample: A completed quest',status='completed',minimum=10,reason='Completion flag reported by the client',dependencies={},targets=targets},
  {id=900104,title='Sample: Unknown completion',status='unknown',minimum=10,reason='Completion state is unavailable',dependencies={},targets=targets},
 }
 local calls=0
 ForeverCompanionAvailableQuests.Catalog=function() calls=calls+1;return catalog end
 ForeverCompanionOpenQuestBook('catalog')
 local book,selected,searchBox
 for _,f in ipairs(frames) do if f.name=='ForeverCompanionQuestBookPanel' then book=f end end
 assert(book and book.visible)
 assert(viewport.child.height>=-book.point[5]+book.height,'catalog must retain its full scroll extent after discovery shrinks')
 for _,f in ipairs(frames) do
  if f.parent==book.id and f.entry and f.entry.id==900102 then selected=f end
  if f.parent==book.id and f.kind=='EditBox' then searchBox=f end
 end
 assert(selected and searchBox);selected.OnClick(selected)
 exportNative('ui_catalog_native.json')
 local before=calls
 searchBox:SetText('SUPPLY');searchBox.OnTextChanged(searchBox,true)
 assert(calls==before,'typing a catalog search must not rescan completion APIs')
 searchBox:SetText('');searchBox.OnTextChanged(searchBox,true)
 ForeverCompanionDB.questHistory={entries={}}
 ForeverCompanionQuestHistory.Record(900201,500,12345,{quest={id=900201,title='Sample: Report to camp',zoneKnown=true,zone='Sample forest'},map=1429,at=1400000000})
 ForeverCompanionQuestHistory.Record(900202,750,nil,{quest={id=900202,title='Sample: Deliver supplies',zoneKnown=true,zone='Sample forest'},map=1429,at=1400000100})
 ForeverCompanionOpenQuestBook('history')
 for _,f in ipairs(frames) do if f.parent==book.id and f.entry and f.entry.id==900201 then selected=f end end
 selected.OnClick(selected)
 local key=selected.key
 ForeverCompanionQuestHistory.Record(900203,nil,nil,{quest={id=900203,title='Sample: Another turn-in'},map=1429,at=1400000200})
 local retained=false
 for _,f in ipairs(frames) do if f.parent==book.id and f.key==key and f.entry and f.entry.id==900201 then retained=true end end
 assert(retained,'history selection must retain its event identity when new turn-ins arrive')
 exportNative('ui_history_native.json')
 local giverMap
 for _,f in ipairs(frames) do if f.kind=='Button' and f.text=='Show giver map' then giverMap=f end end
 assert(giverMap and giverMap.enabled==false and not giverMap.visible,'turn-in history cannot invent a historical coordinate')
 ForeverCompanionAvailableQuests.Catalog=originalCatalog;ForeverCompanionDB.questHistory=originalHistory;C_Map=originalMap;date=originalDate
 SlashCmdList.FOREVERCOMPANION('discover')
 assert(not book.visible,'discovery tab must replace the book view')
end
