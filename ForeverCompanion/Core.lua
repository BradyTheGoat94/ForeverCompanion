local addonName = ...
local addon = CreateFrame("Frame")
local DATA = ForeverCompanionData
local DB, window, titleText, content, currentTab
local tabs = {"Overview", "Leveling", "Quests", "Dungeons", "Professions", "PvP", "Settings"}
local classNames = {WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue", PRIEST="Priest", SHAMAN="Shaman", MAGE="Mage", WARLOCK="Warlock", DRUID="Druid"}
local classRoles = {WARRIOR={"Tank","Damage"}, PALADIN={"Tank","Damage","Healer"}, HUNTER={"Damage"}, ROGUE={"Damage"}, PRIEST={"Healer","Damage"}, SHAMAN={"Healer","Damage"}, MAGE={"Damage"}, WARLOCK={"Damage"}, DRUID={"Tank","Damage","Healer"}}
local tabButtons = {}
local checkButtons = {}
local scrollFrame, scrollChild, classButton, roleButton, subtitleText, questCountText, compactButton, accentBar, background, nextQuestButton, previousQuestButton, questFocusText, welcomeTip
local questRows = {}
local questPage=1
local pageBack, pageForward, pageLabel, filterButton, resetClassButton
local questSectionLabel
local classOrder = {"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
local function colorTexture(texture,r,g,b,a)
  if texture.SetColorTexture then texture:SetColorTexture(r,g,b,a)
  else texture:SetTexture(r,g,b,a) end
end
local function say(msg) print("|cffffcc66Forever Companion:|r "..msg) end
local function actualClass() local _, token = UnitClass("player"); return token or "WARRIOR" end
local function classToken() return DB and DB.previewClass or actualClass() end
local function classLabel() return classNames[classToken()] or classToken() end
local function level() return UnitLevel("player") or 1 end
local function toggleCheck(section, index)
  if not DATA.checklist[section] then return end
  DB.checks = DB.checks or {}
  DB.checks[section] = DB.checks[section] or {}
  DB.checks[section][index] = not DB.checks[section][index]
end
local function render()
  if not window or not DB then return end
  titleText:SetText("FOREVER COMPANION")
  if subtitleText then subtitleText:SetText(classLabel().."  |  Level "..level().."  |  "..(DB.role or "Choose role")) end
  if questCountText and ForeverCompanionQuestPlanner then questCountText:SetText("Active quests: "..ForeverCompanionQuestPlanner.AutoCount()) end
  for _, b in ipairs(tabButtons) do
    if b.section == currentTab then b:LockHighlight() else b:UnlockHighlight() end
  end
  for _, b in ipairs(checkButtons) do b:Hide() end
  for _, b in ipairs(questRows) do b:Hide() end
  if questSectionLabel then questSectionLabel:Hide() end
  if filterButton then if currentTab=="Quests" then filterButton:Show() else filterButton:Hide() end end
  local lines = {}
  if currentTab == "Overview" then
    lines = {"WELCOME, ADVENTURER", "Start here: open Quests to see your automatically detected quest log.", "Use Next Quest to switch focus. The suggested next step is based on available quest status, not pathfinding.", "Open Leveling for class tips, Dungeons for party preparation, and Professions for your checklist.", "Detected class: "..(classNames[actualClass()] or actualClass()), "Displayed class: "..classLabel(), "Role preference: "..(DB.role or "Not selected"), "Tip: drag the title area to move the window; use Compact to save space.", "All gameplay remains under your control."}
  elseif currentTab == "Leveling" then
    lines = {"CLASS GUIDANCE"}
    for _, tip in ipairs(DATA.classes[classToken()] or {}) do lines[#lines+1] = "- "..tip end
    if DB.role and DATA.roleAdvice and DATA.roleAdvice[DB.role] then
      lines[#lines+1]="YOUR ROLE: "..string.upper(DB.role)
      for _,tip in ipairs(DATA.roleAdvice[DB.role]) do lines[#lines+1]="- "..tip end
    end
    lines[#lines+1] = "LEVELING"
    for _, band in ipairs(DATA.zones) do
      if level() >= band[1] and level() <= band[2] then
        lines[#lines+1] = "Level "..band[1].."-"..band[2]..": "..band[3]
        lines[#lines+1] = band[4]
        break
      end
    end
  elseif currentTab == "Quests" then
    local live=ForeverCompanionQuestPlanner.GetLive()
    local visible=ForeverCompanionQuestPlanner.GetVisible()
    local focused,selectedIndex=ForeverCompanionQuestPlanner.GetSelected()
    lines = {ForeverCompanionQuestPlanner.FormatFocused(), "", "NEXT STEP", ForeverCompanionQuestPlanner.Recommend(), "", "PERSONAL NOTES", ForeverCompanionQuestPlanner.Format()}
    if questSectionLabel then
      questSectionLabel:SetText("QUEST LOG  |  "..#live.." active  |  "..ForeverCompanionQuestPlanner.ReadyCount().." ready")
      questSectionLabel:Show()
    end
    if filterButton then filterButton:SetText("Show: "..ForeverCompanionQuestPlanner.GetFilter()) end
    local pages=math.max(1,math.ceil(#visible/#questRows))
    if questPage>pages then questPage=pages end
    for i=1,math.min(#questRows,math.max(0,#visible-(questPage-1)*#questRows)) do
      local item=visible[(questPage-1)*#questRows+i]
      local absoluteIndex=item.index
      local q=item.quest
      local btn=questRows[i]
      btn:SetText((selectedIndex==absoluteIndex and "> " or "  ")..(q.complete and "[Ready] " or "")..q.title)
      btn:SetScript("OnClick",function() ForeverCompanionQuestPlanner.Select(absoluteIndex) end)
      btn:Show()
    end
    if pageLabel then pageLabel:SetText("Page "..questPage.." / "..pages) end
  elseif currentTab == "Settings" then
    lines = {"Detected class: "..(classNames[actualClass()] or actualClass()), "Preview: "..classLabel(), "Role: "..(DB.role or "Not selected"), "Professions: "..(DB.professions or "Not selected"), "Commands:", "/fc class Warrior  |  /fc class auto", "/fc role Tank  |  /fc professions Mining + Blacksmithing", "/fc check Dungeons 1  |  /fc reset", "/fc position reset", "Class preview does not change your actual character class."}
  else
    lines = {string.upper(currentTab).." CHECKLIST"}
    local entries = DATA.checklist[currentTab] or {}
    for i, item in ipairs(entries) do
      local done = DB.checks and DB.checks[currentTab] and DB.checks[currentTab][i]
      lines[#lines+1] = (done and "[x] " or "[ ] ")..item
      if checkButtons[i] then checkButtons[i]:SetText(done and "Undo "..i or "Done "..i); checkButtons[i]:Show() end
    end
    if currentTab == "Dungeons" then
      if DB.role and DATA.roleAdvice and DATA.roleAdvice[DB.role] then
        lines[#lines+1]="YOUR ROLE PREPARATION"
        for _,tip in ipairs(DATA.roleAdvice[DB.role]) do lines[#lines+1]="- "..tip end
      end
      lines[#lines+1] = "GENERAL CLASSIC DUNGEON NOTES (NOT VERIFIED FOREVER LOOT DATA)"
      for _, entry in ipairs(DATA.dungeons) do lines[#lines+1] = entry[1]..": "..entry[2] end
    elseif currentTab == "Professions" then
      lines[#lines+1] = "Selected professions: "..(DB.professions or "Not selected")
      lines[#lines+1] = "Set with /fc professions <names>"
    elseif currentTab == "PvP" then
      lines[#lines+1] = "Use game-supported tools and coordinate objectives with your group."
    end
  end
  if pageBack then if currentTab=="Quests" then pageBack:Show(); pageForward:Show(); pageLabel:Show() else pageBack:Hide(); pageForward:Hide(); pageLabel:Hide() end end
  content:SetText(table.concat(lines, "\n\n"))
  content:ClearAllPoints()
  content:SetPoint("TOPLEFT",scrollChild,"TOPLEFT",5,currentTab=="Quests" and -455 or -5)
  if scrollChild then scrollChild:SetHeight(math.max(420, content:GetStringHeight() + (currentTab=="Quests" and 480 or 24))) end
  if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
  if classButton then classButton:SetText("Class: "..classLabel()) end
  if roleButton then roleButton:SetText("Role: "..(DB.role or "Choose")) end
  if nextQuestButton then if currentTab=="Quests" then nextQuestButton:Show() else nextQuestButton:Hide() end end
  if previousQuestButton then if currentTab=="Quests" then previousQuestButton:Show() else previousQuestButton:Hide() end end
  if questFocusText then
    local q=ForeverCompanionQuestPlanner and ForeverCompanionQuestPlanner.GetSelected()
    questFocusText:SetText(currentTab=="Quests" and (q and ("Focused: "..q.title) or "No quest selected") or "")
  end
end
local function createUI()
  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  window = CreateFrame("Frame", "ForeverCompanionMainFrame", UIParent, template)
  window:SetSize(720, DB.compact and 470 or 560)
  if DB.position and type(DB.position.x)=="number" and type(DB.position.y)=="number" then
    window:SetPoint("CENTER", UIParent, "CENTER", DB.position.x, DB.position.y)
  else
    window:SetPoint("CENTER")
  end
  window:SetMovable(true)
  window:EnableMouse(true)
  window:RegisterForDrag("LeftButton")
  window:SetScript("OnDragStart", function(self) self:StartMoving() end)
  window:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if x and y and ux and uy then DB.position = {x=x-ux, y=y-uy} end
  end)
  window:SetClampedToScreen(true)
  if window.SetBackdrop then
    window:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=16, insets={left=5,right=5,top=5,bottom=5}})
  end
  background=window:CreateTexture(nil,"BACKGROUND")
  background:SetAllPoints(window)
  colorTexture(background,0.055,0.065,0.085,0.94)
  accentBar=window:CreateTexture(nil,"BORDER")
  accentBar:SetPoint("TOPLEFT",window,"TOPLEFT",12,-8)
  accentBar:SetPoint("TOPRIGHT",window,"TOPRIGHT",-12,-8)
  accentBar:SetHeight(3)
  colorTexture(accentBar,0.94,0.65,0.22,1)
  titleText = window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  titleText:SetPoint("TOPLEFT", 20, -20)
  titleText:SetTextColor(1,0.79,0.36)
  subtitleText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  subtitleText:SetPoint("TOPLEFT",20,-43)
  subtitleText:SetTextColor(0.72,0.78,0.84)
  questCountText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  questCountText:SetPoint("TOPRIGHT",-48,-43)
  questCountText:SetTextColor(0.70,0.85,0.74)
  local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)
  for i, section in ipairs(tabs) do
    local b = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    b:SetSize(94, 28)
    b:SetPoint("TOPLEFT", 20+(i-1)*97, -60)
    b:SetText(section)
    b.section = section
    b:SetScript("OnClick", function() currentTab=section; DB.tab=section; render() end)
    tabButtons[#tabButtons+1] = b
  end
  local panel=CreateFrame("Frame",nil,window)
  panel:SetPoint("TOPLEFT",16,-98)
  panel:SetPoint("BOTTOMRIGHT",-16,88)
  local panelTexture=panel:CreateTexture(nil,"BACKGROUND")
  panelTexture:SetAllPoints(panel)
  colorTexture(panelTexture,0.085,0.105,0.13,0.95)
  local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
  scrollFrame = scroll
  scroll:SetPoint("TOPLEFT", 22, -104)
  scroll:SetPoint("BOTTOMRIGHT", -35, 92)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(640, 800)
  scrollChild = child
  scroll:SetScrollChild(child)
  filterButton=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  filterButton:SetSize(140,23)
  filterButton:SetPoint("TOPRIGHT",child,"TOPRIGHT",-42,-7)
  filterButton:SetText("Show: all")
  filterButton:SetScript("OnClick",function() questPage=1; ForeverCompanionQuestPlanner.CycleFilter() end)
  filterButton:Hide()
  pageBack=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  pageBack:SetSize(90,24)
  pageBack:SetPoint("TOPLEFT",child,"TOPLEFT",8,-415)
  pageBack:SetText("Prev Page")
  pageBack:SetScript("OnClick",function() questPage=math.max(1,questPage-1); render() end)
  pageForward=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  pageForward:SetSize(90,24)
  pageForward:SetPoint("LEFT",pageBack,"RIGHT",110,0)
  pageForward:SetText("Next Page")
  pageForward:SetScript("OnClick",function() questPage=questPage+1; render() end)
  pageLabel=child:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  pageLabel:SetPoint("LEFT",pageBack,"RIGHT",12,0)
  content = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  content:SetPoint("TOPLEFT", 5, -5)
  questSectionLabel=child:CreateFontString(nil,"OVERLAY","GameFontNormal")
  questSectionLabel:SetPoint("TOPLEFT",child,"TOPLEFT",8,-10)
  questSectionLabel:SetTextColor(1,0.79,0.36)
  questSectionLabel:Hide()
  for i=1,15 do
    local row=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
    row:SetSize(590,23)
    row:SetPoint("TOPLEFT",child,"TOPLEFT",8,-34-(i-1)*25)
    row:Hide()
    questRows[i]=row
  end
  content:SetWidth(610)
  if content.SetSpacing then content:SetSpacing(4) end
  content:SetJustifyH("LEFT")
  content:SetJustifyV("TOP")
  questFocusText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  questFocusText:SetPoint("BOTTOMLEFT",20,83)
  questFocusText:SetWidth(420)
  questFocusText:SetJustifyH("LEFT")
  nextQuestButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  nextQuestButton:SetSize(118,25)
  nextQuestButton:SetPoint("BOTTOMRIGHT",-25,81)
  nextQuestButton:SetText("Next Quest")
  nextQuestButton:SetScript("OnClick",function() ForeverCompanionQuestPlanner.Next(); render() end)
  nextQuestButton:Hide()
  previousQuestButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  previousQuestButton:SetSize(118,25)
  previousQuestButton:SetPoint("RIGHT",nextQuestButton,"LEFT",-5,0)
  previousQuestButton:SetText("Previous")
  previousQuestButton:SetScript("OnClick",function() ForeverCompanionQuestPlanner.Previous(); render() end)
  previousQuestButton:Hide()
  for i=1,4 do
    local b=CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    b:SetSize(90, 25)
    b:SetPoint("BOTTOMLEFT", 20+(i-1)*96, 48)
    b:SetScript("OnClick", function() toggleCheck(currentTab,i); render() end)
    b:Hide()
    checkButtons[i]=b
  end
  classButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
  classButton:SetSize(150, 26)
  classButton:SetPoint("BOTTOMRIGHT", -180, 45)
  classButton:SetScript("OnClick", function()
    local token=classToken()
    for i, candidate in ipairs(classOrder) do
      if candidate == token then DB.previewClass=classOrder[(i % #classOrder)+1]; break end
    end
    DB.role=nil
    render()
  end)
  resetClassButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  resetClassButton:SetSize(92,23)
  resetClassButton:SetPoint("BOTTOMRIGHT",-125,16)
  resetClassButton:SetText("Auto Class")
  resetClassButton:SetScript("OnClick",function() DB.previewClass=nil; DB.role=nil; render() end)
  roleButton = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
  roleButton:SetSize(145, 26)
  roleButton:SetPoint("BOTTOMRIGHT", -25, 45)
  roleButton:SetScript("OnClick", function()
    local roles=classRoles[classToken()] or {"Damage"}
    local nextIndex=1
    for i, role in ipairs(roles) do if DB.role==role then nextIndex=(i % #roles)+1 end end
    DB.role=roles[nextIndex]
    render()
  end)
  compactButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  compactButton:SetSize(92,23)
  compactButton:SetPoint("BOTTOMRIGHT",-25,16)
  compactButton:SetText(DB.compact and "Expand" or "Compact")
  compactButton:SetScript("OnClick",function()
    DB.compact=not DB.compact
    window:SetHeight(DB.compact and 470 or 560)
    compactButton:SetText(DB.compact and "Expand" or "Compact")
    render()
  end)
  local footer=window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  footer:SetPoint("BOTTOMLEFT", 20, 19)
  footer:SetText("v0.8.0 beta  |  /fc help  |  Read-only quest tracking")
  currentTab = DB.tab or "Overview"
  local validTab=false
  for _, section in ipairs(tabs) do if section==currentTab then validTab=true end end
  if not validTab then currentTab="Overview" end
  window:Hide()
  render()
end
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LEVEL_UP")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:SetScript("OnEvent", function(_, event, arg)
  if event == "ADDON_LOADED" and arg == addonName then
    ForeverCompanionDB = ForeverCompanionDB or {}
    DB = ForeverCompanionDB
    if type(DB.checks)~="table" then DB.checks={} end
    if type(DB.tab)~="string" then DB.tab="Overview" end
    createUI()
    if not DB.welcomed then DB.welcomed=true; window:Show() end
  elseif DB and (event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD") then
    render()
  end
end)
SLASH_FOREVERCOMPANION1 = "/fc"
SLASH_FOREVERCOMPANION2 = "/forevercompanion"
SlashCmdList.FOREVERCOMPANION = function(msg)
  msg=(msg or ""):match("^%s*(.-)%s*$")
  if not DB then return end
  if msg == "" then if window:IsShown() then window:Hide() else render(); window:Show() end; return end
  if msg == "help" then say("/fc, /fc class <name|auto>, /fc role <role>, /fc professions <names>, /fc check <section> <1-4>, /fc reset, /fc position reset, /fcq sync"); return end
  local class = msg:match("^class%s+(.+)$")
  if class then
    if class:lower()=="auto" then DB.previewClass=nil
    else
      local found
      for token,name in pairs(classNames) do if name:lower()==class:lower() then found=token end end
      if not found then say("Unknown class."); return end
      DB.previewClass=found
    end
    DB.role=nil; render(); return
  end
  local role=msg:match("^role%s+(.+)$")
  if role then
    local valid=false
    for _, r in ipairs(classRoles[classToken()] or {"Damage"}) do
      if r:lower()==role:lower() then DB.role=r; valid=true end
    end
    if not valid then say("Invalid role for displayed class."); return end
    render(); return
  end
  local prof=msg:match("^professions%s+(.+)$")
  if prof then DB.professions=prof:sub(1,100); render(); return end
  local section,index=msg:match("^check%s+(%a+)%s+(%d+)$")
  if section then
    for name,entries in pairs(DATA.checklist) do
      if name:lower()==section:lower() and tonumber(index)>=1 and tonumber(index)<=#entries then
        toggleCheck(name,tonumber(index)); currentTab=name; DB.tab=name; render(); return
      end
    end
    say("Invalid checklist or step."); return
  end
  if msg=="reset" then DB.checks={}; render(); say("Checklist progress reset."); return end
  if msg=="position reset" then DB.position=nil; window:ClearAllPoints(); window:SetPoint("CENTER"); say("Window centered."); return end
  say("Unknown command; type /fc help")
end

ForeverCompanionRefresh = function() if DB and window then render() end end
