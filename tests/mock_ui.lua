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
   layer=f.layer,font=f.font,alpha=f.alpha,crop=f.texCoord,all=f.all,template=f.template,justify=f.justify}
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
 function w:SetText(v) self.text=tostring(v or "") end
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
 function w:SetScript(name,fn) self[name]=fn end
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
 function w:SetEnabled(value) self.enabled=value end
 function w:LockHighlight() end
 function w:UnlockHighlight() end
 function w:SetScrollChild(child) self.child=child end
 function w:GetVerticalScroll() return self.verticalScroll or 0 end
 function w:SetVerticalScroll(offset) self.verticalScroll=offset end
 function w:StartMoving() end
 function w:StopMovingOrSizing() end
 function w:EnableMouse() end
 function w:RegisterForDrag() end
 function w:SetMovable() end
 function w:SetClampedToScreen() end
 function w:SetResizable() end
 function w:SetBackdrop(...) end
 function w:SetBackdropColor(...) end
 function w:SetBackdropBorderColor(...) end
 function w:SetAllPoints(target) self.all=target and target.id or self.parent end
 function w:SetJustifyH(value) self.justify=value end
 function w:SetJustifyV() end
 function w:SetSpacing() end
 function w:SetTextColor(...) self.textColor={...} end
 function w:SetFontObject() end
 function w:SetFont(path,size,flags) self.font={path,size,flags} end
 function w:SetTexCoord(...) self.texCoord={...} end
 function w:SetAlpha(value) self.alpha=value end
 function w:SetNormalTexture() end
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
 if f.events and f.events.ADDON_LOADED then addonFrame=f;break end
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
for _,w in ipairs(frames) do if w.text=="Sort: zone" then sortControl=w end end
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
 if w.text=="Known objectives: 1/1 | addon focus only" then knownObjective=true end
end
assert(knownObjective,"quest focus card should show verified objective progress")
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
local originalQuestCount=C_QuestLog.GetNumQuestLogEntries
C_QuestLog.GetNumQuestLogEntries=function() error("temporary quest API failure") end
assert(ForeverCompanionQuestPlanner.Sync()==false,"failed quest scan must not be reported successful")
local staleWarning=false
for _,w in ipairs(frames) do
 if w.text=="STALE DATA - verify in the game quest log" then staleWarning=true end
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
local sourcedCampingVisible=false
for _,w in ipairs(frames) do
 if w.kind=="FontString" and w.text:find("Mana Well",1,true) and w.text:find("Blizzard Forever Camping preview (2026-10-21)",1,true) then
  sourcedCampingVisible=true
 end
end
assert(sourcedCampingVisible,"profession panel must show official source-attributed camp feature")
local materialStatus=false
for _,w in ipairs(frames) do if w.text=="0/1 material goals completed" then materialStatus=true end end
assert(materialStatus,"manual material goal status incorrect")
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local shortageFound=false
for _,w in ipairs(frames) do
 if w.text=="Selected guide shortage: Sample Ore x6" then shortageFound=true end
end
assert(shortageFound,"selected profession should show its largest manual shortage")
ForeverCompanionProfessionBriefing.Render("Alchemy")
exportSnapshot("ui_profession_snapshot.txt")
assert(ForeverCompanionCraftingPlanner.SetOwned("Blacksmithing",1,10),"material goal should update")
ForeverCompanionProfessionBriefing.Render("Blacksmithing")
local completedStatus=false
for _,w in ipairs(frames) do if w.text=="1/1 material goals completed" then completedStatus=true end end
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
 if w.text=="Compact" then compactButton=w end
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
 if w.text=="Rotation: leveling" then rotationControl=w end
end
assert(classHeading,"wide class banner breadcrumb missing")
SlashCmdList.FOREVERCOMPANION("open class guides")
assert(ForeverCompanionDB.tab=="Leveling","visible Class Guides label must work in slash navigation")
local specControl
for _,w in ipairs(frames) do if w.text=="Spec: Arms" then specControl=w end end
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
 planner.raiseLevel:OnClick()
 planner.resetButton:OnClick()
 assert(model.Total("WARRIOR",allocation)>0,"reset needs confirmation")
 planner.resetButton:OnClick()
 assert(model.Total("WARRIOR",allocation)==0,"confirmed reset clears draft")
 planner.lowerLevel:OnClick()
 planner.recommendationButton:OnClick()
 planner.buildButton:OnClick()
 assert(model.Total("WARRIOR",allocation)==51 and planner.recommendationButton.text=="Recommended Build")
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
local inlaySegments=0
for _,w in ipairs(frames) do
 if w.kind=="Texture" and w.width==19 and w.height==2 and w.color then
  inlaySegments=inlaySegments+1
 end
end
assert(inlaySegments>=16,"quest and profession cards must share original gilded corner inlays")
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
  local reference,_,_,_,primary=ForeverCompanionVisiblePriority(token,contextButton.mode,60,nil,ForeverCompanionRotations[token][contextButton.mode])
  for index,step in ipairs(workspace.Plan(reference,primary,"WARRIOR",token)) do
   local row=workspace.rows[index]
   assert(row and row.visible and row.parent==workspace.panel.id,"all steps must be shown inside the priority panel")
   assert(row.caption.text==step.text,"row must show the complete instruction")
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
local early,_,_,_,earlyPrimary=ForeverCompanionVisiblePriority("PALADIN","boss",11,"Tank",{})
assert(#early==4 and early[3]:find("Holy Strike",1,true) and not table.concat(early):find("Consecration",1,true))
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
local originalTopicMeasure=ForeverCompanionClassGuide.topicBody.GetStringHeight
ForeverCompanionClassGuide.topicBody.GetStringHeight=function() return 480 end
ForeverCompanionClassGuide.SelectView("Leveling")
assert(ForeverCompanionClassGuide.topicBody.height>=492,"long topic needs measured body space")
assert(ForeverCompanionClassGuide.GetTopicHeight()>=602,"topic frame must expand with body")
ForeverCompanionClassGuide.topicBody.GetStringHeight=originalTopicMeasure
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
buttonWithText("Next bosses").OnClick()
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
buttonWithText("Clear search").OnClick()
assert(browser.query=="" and browser.searchBox:GetText()=="")
browser.NextDungeon()
ForeverCompanionRefresh()
assert(browser.dungeon=="Wailing Caverns" and browser.boss=="Kresh" and browser.page==1)
browser.NextDungeon()
ForeverCompanionRefresh()
assert(browser.dungeon=="Hall of Thanes" and #ForeverCompanionLoot.BossDrops(browser.dungeon,browser.boss)==3)
browser.NextDungeon()
ForeverCompanionRefresh()
exportSnapshot("ui_encounter_snapshot.txt")
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
assert(catalog.detail.height>=707 and catalog.root.height>=894,'long source descriptions expand beyond fixed row area')
assert(catalog.detailPanel.fcPanelEdges.left.height==catalog.detailPanel.height,'detail panel edges follow expansion')
for _,w in ipairs(frames) do
 if w.parent==catalog.root.id and w.text:find("Partial beta catalog",1,true)==1 then
  assert(-w.point[5]>=111+catalog.detailPanel.height+14,"long item details must not cover the catalog disclosure")
 end
end
catalog.detail.GetStringHeight=measure
ForeverCompanionRefresh()
exportNative("ui_loot_native.json")
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


