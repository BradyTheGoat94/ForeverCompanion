local addonName = ...
local addon = CreateFrame("Frame")
local DATA = ForeverCompanionData
local ADVANCED = ForeverCompanionAdvanced
local ROTATIONS = ForeverCompanionRotations
local rotationModes={"leveling","dungeon","boss","aoe","pvp"}
local rotationMode=1
local rotationButton, rotationIcon, rotationDescription, specButton
local rotationRows={}
local rotationDetail=1
local DB, window, titleText, content, currentTab, headerMeta
local tabs = {"Overview", "Leveling", "Quests", "Dungeons", "Professions", "PvP", "Settings"}
local classNames = {WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue", PRIEST="Priest", SHAMAN="Shaman", MAGE="Mage", WARLOCK="Warlock", DRUID="Druid"}
local classRoles = {WARRIOR={"Tank","Damage"}, PALADIN={"Tank","Damage","Healer"}, HUNTER={"Damage"}, ROGUE={"Damage"}, PRIEST={"Healer","Damage"}, SHAMAN={"Healer","Damage"}, MAGE={"Damage"}, WARLOCK={"Damage"}, DRUID={"Tank","Damage","Healer"}}
local tabButtons = {}
local checkButtons = {}
local scrollFrame, scrollChild, classButton, roleButton, subtitleText, questCountText, compactButton, accentBar, background, nextQuestButton, previousQuestButton, questFocusText, welcomeTip
local handbookIcon, handbookButtons={}, {}
local materialRows={}
local materialPage=1
local materialPageLabel, materialPrevious, materialNext
local professionIndex=1
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
local function experienceText()
  if type(UnitXP)~="function" or type(UnitXPMax)~="function" then return "XP: not available" end
  local value=tonumber(UnitXP("player"))
  local maximum=tonumber(UnitXPMax("player"))
  if not value or not maximum or maximum<=0 then return "XP: not available at this level" end
  return "XP: "..value.." / "..maximum.." ("..math.floor(value*100/maximum+0.5).."%)"
end
local function toggleCheck(section, index)
  if not DATA.checklist[section] then return end
  DB.checks = DB.checks or {}
  DB.checks[section] = DB.checks[section] or {}
  DB.checks[section][index] = not DB.checks[section][index]
end
local function render()
  if not window or not DB then return end
  titleText:SetText("Forever Companion")
  if headerMeta then headerMeta:SetText(classLabel().."  |  Level "..level().."  |  "..(DB.role or "Choose role")) end
  if questCountText and ForeverCompanionQuestPlanner then questCountText:SetText("Active quests: "..ForeverCompanionQuestPlanner.AutoCount()) end
  local isOverview=currentTab=="Overview"
  if scrollFrame then if isOverview then scrollFrame:Hide() else scrollFrame:Show() end end
  if ForeverCompanionDashboard then
    ForeverCompanionDashboard.SetCompact(DB.compact)
    ForeverCompanionDashboard.Show(isOverview)
  end
  for _, b in ipairs(tabButtons) do
    if b.section == currentTab then
      colorTexture(b.navBackground,0.29,0.22,0.11,1)
      colorTexture(b.navAccent,0.98,0.74,0.29,1)
      b.navLabel:SetTextColor(1,0.83,0.43)
    else
      colorTexture(b.navBackground,0.10,0.13,0.17,1)
      colorTexture(b.navAccent,0.29,0.25,0.18,1)
      b.navLabel:SetTextColor(0.88,0.87,0.83)
    end
  end
  for _, b in ipairs(checkButtons) do b:Hide() end
  if handbookIcon then handbookIcon:Hide() end
  if rotationIcon then rotationIcon:Hide() end
  for _,row in ipairs(rotationRows) do row:Hide() end
  if rotationButton then if currentTab=="Leveling" then rotationButton:Show(); rotationButton:SetText("Rotation: "..rotationModes[rotationMode]) else rotationButton:Hide() end end
  if specButton then
    if currentTab=="Leveling" and ForeverCompanionSpecPlanner then
      local selected=ForeverCompanionSpecPlanner.Get(classToken())
      specButton:SetText("Spec: "..(selected and selected[1] or "N/A"))
      specButton:Show()
    else specButton:Hide() end
  end
  for _,b in ipairs(handbookButtons) do b:Hide() end
  for _,entry in ipairs(materialRows) do entry.label:Hide(); entry.minus:Hide(); entry.plus:Hide() end
  if materialPageLabel then materialPageLabel:Hide(); materialPrevious:Hide(); materialNext:Hide() end
  for _, b in ipairs(questRows) do b:Hide() end
  if questSectionLabel then questSectionLabel:Hide() end
  if filterButton then if currentTab=="Quests" then filterButton:Show() else filterButton:Hide() end end
  local lines = {}
  if currentTab == "Overview" then
    lines = {"YOUR ADVENTURE AT A GLANCE", "Recommended next steps", "1. Review your current quests in the Quest Planner.", "2. Open Leveling for class-specific ability priorities.", "3. Track crafting materials and profession goals.", "All suggestions are advisory. You remain in control."}
    if ForeverCompanionCraftingPlanner then lines[#lines+1]=ForeverCompanionCraftingPlanner.Summary() end
    if ForeverCompanionDiagnostics then lines[#lines+1]=ForeverCompanionDiagnostics.Collect() end
  elseif currentTab == "Leveling" then
    lines = {"CLASS GUIDANCE",experienceText()}
    local rotations=ROTATIONS and ROTATIONS[classToken()]
    if rotations then
      local mode=rotationModes[rotationMode]
      lines[#lines+1]="ROTATION / PRIORITY: "..string.upper(mode)
      local presentation=ForeverCompanionRotationPresentation
      local context=presentation and presentation.contexts[mode]
      if context then lines[#lines+1]=context.title.." - "..context.description end
      local icons=ForeverCompanionRotationIcons and ForeverCompanionRotationIcons[classToken()]
      if rotationIcon and icons and icons[1] then rotationIcon:SetTexture(icons[1]); rotationIcon:Show() end
      local priorities=rotations[mode] or {}
      if rotationDetail>#priorities then rotationDetail=1 end
      for i,ability in ipairs(priorities) do
        lines[#lines+1]=i..". "..ability
        local row=rotationRows[i]
        if row then
          row:SetText((rotationDetail==i and "> " or "").."Priority "..i)
          row.detail=ability
          row:SetScript("OnEnter",function(self)
            if GameTooltip then
              GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
              GameTooltip:SetText("Priority "..i,1,0.8,0.3)
              GameTooltip:AddLine(self.detail or "",1,1,1,true)
              GameTooltip:Show()
            end
          end)
          row:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
          local iconList=ForeverCompanionRotationIcons and ForeverCompanionRotationIcons[classToken()]
          if row.icon and iconList and #iconList>0 then row.icon:SetTexture(iconList[((i-1)%#iconList)+1]) end
          row:SetScript("OnClick",function() rotationDetail=i; render() end)
          row:Show()
        end
      end
      if priorities[rotationDetail] then
        lines[#lines+1]="FOCUSED PRIORITY: "..priorities[rotationDetail]
      end
      if ForeverCompanionFormatCooldowns then
        lines[#lines+1]=ForeverCompanionFormatCooldowns(classToken(),mode)
      end
      if ForeverCompanionSpecPlanner then lines[#lines+1]=ForeverCompanionSpecPlanner.Format(classToken(),mode) end
      if ForeverCompanionSpellbook then lines[#lines+1]=ForeverCompanionSpellbook.Cooldowns(classToken()) end
      lines[#lines+1]="General reference only; verify abilities and talents on Forever."
    end
    local guide=DATA.classHandbook and DATA.classHandbook[classToken()]
    if guide then
      lines[#lines+1]="LEVELING: "..guide.leveling
      lines[#lines+1]="DUNGEON: "..guide.dungeon
      lines[#lines+1]="PVP: "..guide.pvp
      lines[#lines+1]="PROFESSIONS: "..guide.professions
      if handbookIcon then handbookIcon:SetTexture(guide.icon); handbookIcon:Show() end
    end
    for _, tip in ipairs(DATA.classes[classToken()] or {}) do lines[#lines+1] = "- "..tip end
    local deep=ADVANCED and ADVANCED.classes[classToken()]
    if deep then
      lines[#lines+1]="SPECIALIZATION OVERVIEW (GENERAL REFERENCE)"
      lines[#lines+1]=table.concat(deep.specializations," / ")
      lines[#lines+1]="Core: "..deep.core
      lines[#lines+1]="Party: "..deep.party
      for _,tip in ipairs(deep.sections) do lines[#lines+1]="- "..tip end
    end
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
    if not ForeverCompanionQuestPlanner.IsSupported() then
      table.insert(lines,1,"Quest-log API unavailable: automatic tracking needs client verification.")
    end
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
    if pageBack then pageBack:SetEnabled(questPage>1); pageForward:SetEnabled(questPage<pages) end
  elseif currentTab == "Settings" then
    lines = {"Detected class: "..(classNames[actualClass()] or actualClass()), "Preview: "..classLabel(), "Role: "..(DB.role or "Not selected"), "Professions: "..(DB.professions or "Not selected"), "Commands:", "/fc class Warrior  |  /fc class auto", "/fc role Tank  |  /fc professions Mining + Blacksmithing", "/fc check Dungeons 1  |  /fc reset", "/fc position reset", "Class preview does not change your actual character class."}
    if ForeverCompanionDiagnostics then lines[#lines+1]=ForeverCompanionDiagnostics.Collect() end
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
      if ForeverCompanionProfessionScanner then
        lines[#lines+1]=ForeverCompanionProfessionScanner.Format()
      end
      local guide=DATA.professionHandbook and DATA.professionHandbook[professionIndex]
      if guide then
        lines[#lines+1]="PROFESSION HANDBOOK: "..guide.name
        lines[#lines+1]="Pairs with: "..guide.pair
        if ForeverCompanionProfessionProgress then
          lines[#lines+1]=ForeverCompanionProfessionProgress.ForProfession(guide.name)
        end
        if ForeverCompanionCraftingPlanner then
          local materials=ForeverCompanionCraftingPlanner.GetEntries(guide.name)
          local pages=math.max(1,math.ceil(#materials/5))
          materialPage=math.min(materialPage,pages)
          materialPageLabel:SetText("Materials "..materialPage.."/"..pages)
          materialPageLabel:Show(); materialPrevious:Show(); materialNext:Show()
          materialPrevious:SetEnabled(materialPage>1)
          materialNext:SetEnabled(materialPage<pages)
          for i,entry in ipairs(materialRows) do
            local index=(materialPage-1)*5+i
            local material=materials[index]
            if material then
              local remaining=math.max(0,(tonumber(material.needed) or 0)-(tonumber(material.owned) or 0))
              entry.label:SetText(material.name.."  "..material.owned.."/"..material.needed.."  (need "..remaining..")")
              entry.label:Show(); entry.minus:Show(); entry.plus:Show()
              entry.minus:SetScript("OnClick",function() ForeverCompanionCraftingPlanner.AdjustOwned(guide.name,index,-1); render() end)
              entry.plus:SetScript("OnClick",function() ForeverCompanionCraftingPlanner.AdjustOwned(guide.name,index,1); render() end)
            end
          end
          lines[#lines+1]=ForeverCompanionCraftingPlanner.Summary()
          lines[#lines+1]=ForeverCompanionCraftingPlanner.Format(guide.name)
        end
        if ForeverCompanionRecipePlans then
          lines[#lines+1]=ForeverCompanionRecipePlans.Format(guide.name)
        end
        if ForeverCompanionCraftingBridge then
          lines[#lines+1]=ForeverCompanionCraftingBridge.Preview(guide.name)
        end
        lines[#lines+1]=guide.summary
        for i,step in ipairs(guide.steps) do lines[#lines+1]=i..". "..step end
        local deep=ADVANCED and ADVANCED.crafting[guide.name]
        if deep then
          lines[#lines+1]="CRAFTING PROGRESSION (GENERAL REFERENCE)"
          lines[#lines+1]="Materials: "..deep.materials.."  |  Output: "..deep.output
          for i,step in ipairs(deep.stages) do lines[#lines+1]=i..". "..step end
        end
        if handbookIcon then handbookIcon:SetTexture(guide.icon); handbookIcon:Show() end
        for i,button in ipairs(handbookButtons) do
          local entry=DATA.professionHandbook[i]
          if entry then button:SetText(entry.name); button:SetScript("OnClick",function() professionIndex=i; materialPage=1; render() end); button:Show() end
        end
      end
      lines[#lines+1] = "Selected professions: "..(DB.professions or "Not selected")
      lines[#lines+1] = "Set with /fc professions <names>"
    elseif currentTab == "PvP" then
      lines[#lines+1] = "Use game-supported tools and coordinate objectives with your group."
    end
  end
  if pageBack then if currentTab=="Quests" then pageBack:Show(); pageForward:Show(); pageLabel:Show() else pageBack:Hide(); pageForward:Hide(); pageLabel:Hide() end end
  content:SetText(table.concat(lines, "\n\n"))
  content:ClearAllPoints()
  content:SetPoint("TOPLEFT",scrollChild,"TOPLEFT",5,currentTab=="Quests" and -455 or (currentTab=="Professions" and -260 or (currentTab=="Leveling" and -48 or (currentTab=="Overview" and -215 or -5))))
  if scrollChild then scrollChild:SetHeight(math.max(420, (tonumber(content:GetStringHeight()) or 0) + (currentTab=="Quests" and 480 or (currentTab=="Professions" and 284 or (currentTab=="Leveling" and 70 or 24))))) end
  -- Keep the player's current scroll position during refresh.
  if classButton then classButton:SetText("Class: "..classLabel()) end
  if roleButton then roleButton:SetText("Role: "..(DB.role or "Choose")) end
  if nextQuestButton then if currentTab=="Quests" then nextQuestButton:Show() else nextQuestButton:Hide() end end
  if previousQuestButton then if currentTab=="Quests" then previousQuestButton:Show() else previousQuestButton:Hide() end end
  if questFocusText then
    local q=ForeverCompanionQuestPlanner and ForeverCompanionQuestPlanner.GetSelected()
    questFocusText:SetText(currentTab=="Quests" and (q and ("Focused: "..q.title) or "No quest selected") or "")
  end
end
local function fitWindow()
  if not window or not window.SetScale or not UIParent or not UIParent.GetWidth or not UIParent.GetHeight then return end
  local width,height=UIParent:GetWidth(),UIParent:GetHeight()
  if type(width)~="number" or type(height)~="number" or width<=0 or height<=0 then return end
  local wantedHeight=DB.compact and 620 or 720
  local scale=math.min(1,(width-32)/1080,(height-32)/wantedHeight)
  if scale>0 then window:SetScale(math.max(0.35,scale)) end
end
local function createUI()
  local template = BackdropTemplateMixin and "BackdropTemplate" or nil
  window = CreateFrame("Frame", "ForeverCompanionMainFrame", UIParent, template)
  window:SetSize(1080, DB.compact and 620 or 720)
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
  fitWindow()
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
  titleText:SetPoint("TOPLEFT", 86, -22)
  titleText:SetTextColor(1,0.79,0.36)
  subtitleText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  subtitleText:SetPoint("TOPLEFT",86,-51)
  subtitleText:SetText("Guides  -  Professions  -  Quests  -  Builds  -  More")
  subtitleText:SetTextColor(0.72,0.78,0.84)
  local crest=window:CreateTexture(nil,"OVERLAY")
  crest:SetPoint("TOPLEFT",window,"TOPLEFT",19,-17)
  crest:SetSize(54,54)
  crest:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  headerMeta=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  headerMeta:SetPoint("TOPRIGHT",window,"TOPRIGHT",-48,-22)
  headerMeta:SetTextColor(0.94,0.78,0.47)
  questCountText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  questCountText:SetPoint("TOPRIGHT",-48,-43)
  questCountText:SetTextColor(0.70,0.85,0.74)
  local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -4, -4)
  local sidebar=window:CreateTexture(nil,"BORDER")
  sidebar:SetPoint("TOPLEFT",window,"TOPLEFT",12,-98)
  sidebar:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",12,92)
  sidebar:SetWidth(185)
  colorTexture(sidebar,0.055,0.067,0.09,0.98)
  local sidebarTrim=window:CreateTexture(nil,"ARTWORK")
  sidebarTrim:SetPoint("TOPLEFT",sidebar,"TOPRIGHT",-2,0)
  sidebarTrim:SetPoint("BOTTOMLEFT",sidebar,"BOTTOMRIGHT",-2,0)
  sidebarTrim:SetWidth(2)
  colorTexture(sidebarTrim,0.62,0.44,0.19,0.9)
  local navHeading=window:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  navHeading:SetPoint("TOPLEFT",window,"TOPLEFT",28,-112)
  navHeading:SetText("NAVIGATION")
  navHeading:SetTextColor(0.95,0.72,0.32)
  local navIcons={
    "Interface\\Icons\\INV_Misc_Map_01",
    "Interface\\Icons\\INV_Misc_Book_09",
    "Interface\\Icons\\INV_Misc_Note_01",
    "Interface\\Icons\\INV_Weapon_ShortBlade_01",
    "Interface\\Icons\\Trade_BlackSmithing",
    "Interface\\Icons\\Ability_DualWield",
    "Interface\\Icons\\INV_Gizmo_02"
  }
  for i, section in ipairs(tabs) do
    local b = CreateFrame("Button", nil, window)
    b:SetSize(164, 37)
    b:SetPoint("TOPLEFT",window,"TOPLEFT",23,-138-(i-1)*43)
    b.section=section
    b.navBackground=b:CreateTexture(nil,"BACKGROUND")
    b.navBackground:SetAllPoints(b)
    colorTexture(b.navBackground,0.10,0.13,0.17,1)
    b.navAccent=b:CreateTexture(nil,"ARTWORK")
    b.navAccent:SetPoint("TOPLEFT",b,"TOPLEFT",0,0)
    b.navAccent:SetSize(3,37)
    colorTexture(b.navAccent,0.29,0.25,0.18,1)
    local icon=b:CreateTexture(nil,"ARTWORK")
    icon:SetPoint("LEFT",b,"LEFT",11,0)
    icon:SetSize(21,21)
    icon:SetTexture(navIcons[i])
    b.navLabel=b:CreateFontString(nil,"OVERLAY","GameFontHighlight")
    b.navLabel:SetPoint("LEFT",b,"LEFT",40,0)
    b.navLabel:SetText(section)
    b.navLabel:SetTextColor(0.88,0.87,0.83)
    b:SetScript("OnEnter",function(self)
      if currentTab~=self.section then colorTexture(self.navBackground,0.18,0.17,0.14,1) end
    end)
    b:SetScript("OnLeave",function(self)
      if currentTab~=self.section then colorTexture(self.navBackground,0.10,0.13,0.17,1) end
    end)
    b:SetScript("OnClick", function()
      currentTab=section; DB.tab=section
      if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
      render()
    end)
    tabButtons[#tabButtons+1]=b
  end
  local panel=CreateFrame("Frame",nil,window)
  panel:SetPoint("TOPLEFT",198,-98)
  panel:SetPoint("BOTTOMRIGHT",-16,88)
  local panelTexture=panel:CreateTexture(nil,"BACKGROUND")
  panelTexture:SetAllPoints(panel)
  colorTexture(panelTexture,0.085,0.105,0.13,0.95)
  local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
  scrollFrame = scroll
  scroll:SetPoint("TOPLEFT", 216, -108)
  scroll:SetPoint("BOTTOMRIGHT", -35, 92)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(790, 800)
  scrollChild = child
  scroll:SetScrollChild(child)
  if ForeverCompanionDashboard then
    ForeverCompanionDashboard.Create(window,function(section)
      currentTab=section; DB.tab=section
      if scrollFrame and scrollFrame.SetVerticalScroll then scrollFrame:SetVerticalScroll(0) end
      render()
    end,{db=function() return DB end,class=classLabel,level=level})
  end
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
  pageForward:SetPoint("LEFT",pageBack,"RIGHT",115,0)
  pageForward:SetText("Next Page")
  pageForward:SetScript("OnClick",function() questPage=math.min(math.max(1,math.ceil(#ForeverCompanionQuestPlanner.GetVisible() / #questRows)),questPage+1); render() end)
  pageLabel=child:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  pageLabel:SetPoint("LEFT",pageBack,"RIGHT",12,0)
  rotationIcon=window:CreateTexture(nil,"OVERLAY")
  rotationIcon:SetSize(28,28)
  rotationIcon:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",220,78)
  rotationIcon:Hide()
  rotationButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  rotationButton:SetSize(155,23)
  rotationButton:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",60,80)
  rotationButton:SetScript("OnClick",function() rotationMode=(rotationMode % #rotationModes)+1; rotationDetail=1; render() end)
  rotationButton:Hide()
  specButton=CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
  specButton:SetSize(195,23)
  specButton:SetPoint("LEFT",rotationButton,"RIGHT",42,0)
  specButton:SetScript("OnClick",function() ForeverCompanionSpecPlanner.Next(classToken()); rotationDetail=1; render() end)
  specButton:Hide()
  handbookIcon=window:CreateTexture(nil,"OVERLAY")
  handbookIcon:SetSize(30,30)
  handbookIcon:SetPoint("BOTTOMLEFT",window,"BOTTOMLEFT",20,82)
  handbookIcon:Hide()
  for i=1,9 do
    local b=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
    b:SetSize(114,22)
    b:SetPoint("TOPLEFT",child,"TOPLEFT",8+((i-1)%5)*120,-10-math.floor((i-1)/5)*25)
    b:Hide()
    handbookButtons[i]=b
  end
  materialPrevious=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  materialPrevious:SetSize(65,22)
  materialPrevious:SetPoint("TOPLEFT",child,"TOPLEFT",8,-67)
  materialPrevious:SetText("Prev")
  materialPrevious:Hide()
  materialPrevious:SetScript("OnClick",function() materialPage=math.max(1,materialPage-1); render() end)
  materialNext=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
  materialNext:SetSize(65,22)
  materialNext:SetPoint("TOPLEFT",child,"TOPLEFT",195,-67)
  materialNext:SetText("Next")
  materialNext:Hide()
  materialNext:SetScript("OnClick",function() materialPage=materialPage+1; render() end)
  materialPageLabel=child:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  materialPageLabel:SetPoint("TOPLEFT",child,"TOPLEFT",80,-72)
  materialPageLabel:Hide()
  for i=1,5 do
    local entry={}
    entry.label=child:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    entry.label:SetWidth(445)
    entry.label:SetJustifyH("LEFT")
    entry.label:SetPoint("TOPLEFT",child,"TOPLEFT",8,-96-(i-1)*29)
    entry.minus=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
    entry.minus:SetSize(34,24)
    entry.minus:SetPoint("TOPLEFT",child,"TOPLEFT",510,-91-(i-1)*29)
    entry.minus:SetText("-")
    entry.plus=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
    entry.plus:SetSize(34,24)
    entry.plus:SetPoint("LEFT",entry.minus,"RIGHT",4,0)
    entry.plus:SetText("+")
    entry.label:Hide(); entry.minus:Hide(); entry.plus:Hide()
    materialRows[i]=entry
  end
  for i=1,5 do
    local row=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
    row:SetSize(118,30)
    row:SetPoint("TOPLEFT",child,"TOPLEFT",8+(i-1)*124,-8)
    row.icon=row:CreateTexture(nil,"ARTWORK")
    row.icon:SetSize(19,19)
    row.icon:SetPoint("LEFT",row,"LEFT",3,0)
    row:Hide()
    rotationRows[i]=row
  end
  content = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  content:SetPoint("TOPLEFT", 5, -5)
  questSectionLabel=child:CreateFontString(nil,"OVERLAY","GameFontNormal")
  questSectionLabel:SetPoint("TOPLEFT",child,"TOPLEFT",8,-10)
  questSectionLabel:SetTextColor(1,0.79,0.36)
  questSectionLabel:Hide()
  for i=1,15 do
    local row=CreateFrame("Button",nil,child,"UIPanelButtonTemplate")
    row:SetSize(700,23)
    row:SetPoint("TOPLEFT",child,"TOPLEFT",8,-34-(i-1)*25)
    row:Hide()
    questRows[i]=row
  end
  content:SetWidth(760)
  if content.SetSpacing then content:SetSpacing(4) end
  content:SetJustifyH("LEFT")
  content:SetJustifyV("TOP")
  questFocusText=window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  questFocusText:SetPoint("BOTTOMLEFT",20,83)
  questFocusText:SetWidth(385)
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
    window:SetHeight(DB.compact and 620 or 720)
    fitWindow()
    compactButton:SetText(DB.compact and "Expand" or "Compact")
    render()
  end)
  local footer=window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  footer:SetPoint("BOTTOMLEFT", 20, 19)
  footer:SetText("v3.9 Beta  |  /fc help  |  Read-only advisor  |  No gameplay automation")
  currentTab = DB.tab or "Overview"
  local validTab=false
  for _, section in ipairs(tabs) do if section==currentTab then validTab=true end end
  if not validTab then currentTab="Overview" end
  window:Hide()
  render()
end
for _,event in ipairs({"ADDON_LOADED","PLAYER_LEVEL_UP","PLAYER_ENTERING_WORLD","PLAYER_XP_UPDATE","SKILL_LINES_CHANGED","CHAT_MSG_SKILL"}) do
  pcall(function() addon:RegisterEvent(event) end)
end
addon:SetScript("OnEvent", function(_, event, arg)
  if event == "ADDON_LOADED" and arg == addonName then
    ForeverCompanionDB = ForeverCompanionDB or {}
    DB = ForeverCompanionDB
    if type(DB.checks)~="table" then DB.checks={} end
    if type(DB.tab)~="string" then DB.tab="Overview" end
    createUI()
    if not DB.welcomed then DB.welcomed=true; window:Show() end
  elseif DB and (event == "PLAYER_LEVEL_UP" or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_XP_UPDATE" or event == "SKILL_LINES_CHANGED" or event == "CHAT_MSG_SKILL") then
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
