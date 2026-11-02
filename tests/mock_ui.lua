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
local function widget(kind)
 local w={kind=kind,visible=true,children={},text="",id=#frames+1}
 function w:SetText(v) self.text=tostring(v or "") end
 function w:GetText() return self.text end
 function w:GetStringHeight() return math.max(16,math.ceil(#self.text/75)*16) end
 function w:Show() self.visible=true end
 function w:Hide() self.visible=false end
 function w:IsShown() return self.visible end
 function w:SetScript(name,fn) self[name]=fn end
 function w:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
 function w:CreateTexture() local child=widget("Texture");child.parent=self.id;return child end
 function w:CreateFontString() local child=widget("FontString");child.parent=self.id;return child end
 function w:SetColorTexture(...) self.color={...} end
 function w:SetTexture(v) self.texture=v end
 function w:SetPoint(...) self.point={...} end
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
 function w:GetVerticalScroll() return 0 end
 function w:SetVerticalScroll() end
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
 function w:SetAllPoints() end
 function w:SetJustifyH() end
 function w:SetJustifyV() end
 function w:SetSpacing() end
 function w:SetTextColor() end
 function w:SetFontObject() end
 function w:SetNormalTexture() end
 function w:SetHighlightTexture() end
 function w:SetPushedTexture() end
 function w:ClearAllPoints() end
 frames[#frames+1]=w
 return w
end
CreateFrame=function(kind,_,parent) local child=widget(kind);child.parent=parent and parent.id;return child end
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
 GetQuestObjectives=function(id) return {{text="Illustrative objective for test "..tostring(id)}} end
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
addonFrame.OnEvent(addonFrame,"ADDON_LOADED",addon)
assert(#frames>50,"expected substantial UI frame tree")
assert(type(SlashCmdList.FOREVERCOMPANION)=="function","slash command missing")
SlashCmdList.FOREVERCOMPANION("class mage")
SlashCmdList.FOREVERCOMPANION("class auto")
SlashCmdList.FOREVERCOMPANION("role damage")
SlashCmdList.FOREVERCOMPANION("position reset")
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
local focusButton
for _,w in ipairs(frames) do
 if w.caption and w.caption.text and w.caption.text:find("Review active quests",1,true) then focusButton=w end
end
assert(focusButton and focusButton.OnClick,"focus checklist button missing")
focusButton.OnClick(focusButton)
assert(ForeverCompanionDB.dashboardFocus[1]==true,"focus state did not persist")
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
 if w.text=="3 active  |  1 ready to turn in" then questCountCard=true end
end
assert(questCountCard,"live quest briefing count incorrect")
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
exportSnapshot("ui_quest_snapshot.txt")
local originalQuestCount=C_QuestLog.GetNumQuestLogEntries
C_QuestLog.GetNumQuestLogEntries=function() error("temporary quest API failure") end
assert(ForeverCompanionQuestPlanner.Sync()==false,"failed quest scan must not be reported successful")
local staleWarning=false
for _,w in ipairs(frames) do
 if w.text=="STALE DATA - verify in the game quest log" then staleWarning=true end
end
assert(staleWarning,"quest briefing must warn about cached data")
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
 if f.text=="Forever Companion" then foundTitle=true end
end
assert(foundTitle,"main window title not rendered")
local foundBanner=false
for _,f in ipairs(frames) do if f.text=="WELCOME TO FOREVER COMPANION" then foundBanner=true end end
assert(foundBanner,"premium dashboard welcome banner missing")
-- Exercise the native class-guide hero and capture its real mock widget tree.
local levelingButton
for _,w in ipairs(frames) do if w.section=="Leveling" then levelingButton=w end end
assert(levelingButton and levelingButton.OnClick,"leveling sidebar navigation missing")
levelingButton.OnClick(levelingButton)
assert(ForeverCompanionDB.tab=="Leveling","leveling navigation failed")
local classHeading,buildHeading,rotationControl
for _,w in ipairs(frames) do
 if w.text=="CHARACTER & LEVELING" then classHeading=w end
 if w.text=="BUILD & ROTATION REFERENCE" then buildHeading=w end
 if w.text=="Rotation: leveling" then rotationControl=w end
end
assert(classHeading and buildHeading,"native class-guide header cards missing")
assert(frames[classHeading.parent].visible,"class-guide header should be visible on Leveling")
assert(rotationControl and rotationControl.point and rotationControl.point[1]=="TOPLEFT","rotation control should be in content area")
local levelingHeading
for _,w in ipairs(frames) do if w.text=="LEVELING GUIDE" then levelingHeading=w end end
assert(levelingHeading and frames[levelingHeading.parent].visible,"section header should appear on Leveling")
local priorityTile
for _,w in ipairs(frames) do if w.text:find("^1%. ",1) and w.parent then priorityTile=w end end
assert(priorityTile,"priority tile should display ability text")
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
rotationControl.OnClick(rotationControl)
assert(rotationControl.text=="Rotation: dungeon","rotation context selector failed")
overviewButton.OnClick(overviewButton)
assert(not frames[levelingHeading.parent].visible,"section header should hide on dashboard")
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
