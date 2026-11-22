-- Native Settings briefing: preferences and read-only compatibility indicators.
-- API presence is not proof of WoW Forever support or successful live-client testing.
local S={}
ForeverCompanionSettingsBriefing=S
local root,ctx,values,actions
local GOLD={0.94,0.72,0.34}
local function paint(t,r,g,b,a)
  if t.SetColorTexture then t:SetColorTexture(r,g,b,a or 1)
  else t:SetTexture(r,g,b,a or 1) end
end
local function label(parent,x,y,width,value,font,color)
  local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
  f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  f:SetWidth(width)
  f:SetJustifyH("LEFT")
  f:SetText(value or "")
  ForeverCompanionVisualTheme.Font(f,12)
  if color then f:SetTextColor(color[1],color[2],color[3]) end
  return f
end
local function edge(parent,x,y,w,h,r,g,b)
  local t=parent:CreateTexture(nil,"ARTWORK")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetSize(w,h)
  paint(t,r,g,b,1)
end
local function plate(parent,x,width,title)
  local p=CreateFrame("Frame",nil,parent)
  p:SetSize(width,175)
  p:SetPoint("TOPLEFT",parent,"TOPLEFT",x,0)
  ForeverCompanionVisualTheme.Panel(p,width,175)
  local heading=label(p,16,-12,width-32,title,"GameFontNormal",{.82,.71,.50})
  ForeverCompanionVisualTheme.Font(heading,12)
  return p
end
local function button(parent,x,text,fn)
  local b=ForeverCompanionInterface.Button(parent)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-190)
  b:SetSize(240,37)
  b:SetText(text);b.caption=b:GetFontString()
  b:SetScript("OnClick",function() if type(fn)=="function" then fn() end end)
  return b
end
local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if ok then return value end
end
local function apiStatus(present)
  return present and "API exposed; compatibility unverified" or "API not exposed"
end
-- Pure summary for testing: no protected game actions, no guessed interface ID.
function S.Capabilities(apis)
  apis=type(apis)=="table" and apis or {}
  return {
    quests=apis.modernQuests==true or apis.legacyQuests==true,
    professions=apis.modernProfessions==true or apis.legacyProfessions==true,
    xp=apis.xp==true,
    spellbook=apis.modernSpellbook==true or apis.legacySpellbook==true
  }
end

local function preferences()
  if type(ForeverCompanionDB)~="table" then ForeverCompanionDB={} end
  return ForeverCompanionDB
end
local function worldRefresh() ForeverCompanionQuestMap.Refresh() end
local function refreshWorldLayers()
  worldRefresh()
  ForeverCompanionPartyMap.Refresh()
  ForeverCompanionSocialMap.Refresh()
end
local function savedFeature(name,description,key,default,refresh,section,invert)
  invert=invert==true
  local function storage()
    local db=preferences()
    if not section then return db end
    if type(db[section])~="table" then db[section]={} end
    return db[section]
  end
  return {name=name,description=description,get=function()
    local value=storage()[key]
    if type(value)~="boolean" then return default end
    return value~=invert
  end,set=function(enabled)
    storage()[key]=enabled~=invert
    if refresh then refresh() end
  end}
end
local function option(name,description,get,set)
  return {name=name,description=description,get=get,set=set}
end
local function overlayLayer(name,description,key)
  return option(name,description,
    function() return ForeverCompanionMapOverlay.LayerEnabled(key) end,
    function(value) ForeverCompanionMapOverlay.SetLayerEnabled(key,value) end)
end
local function featureGroups()
  local world=ForeverCompanionQuestMap
  local mini=ForeverCompanionQuestMinimap
  local worldOptions={
    savedFeature("Companion world map","Show the Companion map dock, terrain and world map markers. Your layer choices are kept when this is off.","hideCompanionWorldMap",true,refreshWorldLayers,nil,true),
    option("Active quest markers","Show objectives and turn-ins using the map's All or Focus mode.",world.ObjectivesEnabled,world.SetObjectivesEnabled),
    option("Quest pickups","Show available quest givers and zone starters independently of active objectives.",world.PickupsEnabled,world.SetPickupsEnabled),
    savedFeature("Reveal unexplored terrain","Show cached terrain in unexplored areas of supported maps.","mapRevealTerrain",true,worldRefresh),
    option("Close-up terrain detail","Show higher-detail art on supported zones. The default follows your map style.",world.CloseupEnabled,world.SetCloseupEnabled),
    savedFeature("Dungeon entrances","Show the entrance pins and associated dungeon panels.","hideDungeonPins",true,worldRefresh,nil,true),
    savedFeature("Dungeon level labels","Show level ranges on dungeon entrance pins.","mapShowDungeonLevels",true,worldRefresh),
    savedFeature("Zone level labels","Show suggested levels when browsing zones.","mapShowLevels",true,worldRefresh),
    savedFeature("Zone briefing","Show the automatic zone briefing in the Companion map dock.","mapBriefingHidden",true,worldRefresh,nil,true),
    savedFeature("Personal notes","Show saved note pins on the world map.","mapHideNotes",true,worldRefresh,nil,true),
    savedFeature("Party markers","Show Companion markers for your party on the world map.","hideWorldPartyPins",true,ForeverCompanionPartyMap.Refresh,nil,true),
    savedFeature("Friends and guild dots","Show incoming shared locations on the world map. Your own location sharing is managed separately.","hideSharedMapDots",true,ForeverCompanionSocialMap.Refresh,nil,true),
    savedFeature("Player coordinates","Show your coordinates in the Companion map dock.","mapShowCoordinates",true,worldRefresh),
    savedFeature("Cursor coordinates","Show map coordinates for your cursor in the Companion map dock.","mapShowCursor",true,worldRefresh),
    savedFeature("Waypoint bearing","Show the Companion bearing from the player toward the active waypoint.","mapShowBearing",true,worldRefresh),
  }
  local services={
    savedFeature("World map services","Show service markers on the world map. Individual category choices are kept when this is off.","questMapHideTowns",true,worldRefresh,nil,true),
    savedFeature("Service names","Show service names beside icons at supported zoom levels.","mapServiceLabels",false,worldRefresh),
  }
  for _,entry in ipairs(ForeverCompanionServiceAtlas.Categories) do
    if entry[1]~="all" then
      local key,name=entry[1],entry[2]
      services[#services+1]=option(name,"Show "..name:lower().." on the world map.",
        function() return world.ServiceEnabled(key) end,
        function(value) world.SetServiceEnabled(key,value) end)
    end
  end
  local overlay={
    savedFeature("Map overlay","Show the movable transparent map. Your layer choices are kept when this is off.","visible",false,ForeverCompanionMapOverlay.ApplyVisibility,"mapOverlay"),
    overlayLayer("Quest markers","Show active quest objectives and turn-ins.","quests"),
    overlayLayer("All active quests","Include every active quest with a location on this map when quest markers are on.","allQuests"),
    overlayLayer("Mailboxes","Show mailbox pins independently of other service markers.","mailboxes"),
    overlayLayer("Town services","Show services using the shared service category filters. Mailboxes have their own switch.","services"),
    overlayLayer("Native landmarks","Show location markers provided by the client.","landmarks"),
    overlayLayer("Personal notes","Show saved note pins on the overlay.","notes"),
    overlayLayer("Party highlight","Show the highlighted party member on this overlay when a position is available.","partyHighlight"),
    overlayLayer("Explored terrain detail","Show the client's explored terrain details on the overlay.","detail"),
  }
  local minimap={
    savedFeature("Companion launcher","Show the movable Companion minimap button.","hidden",true,
      function() ForeverCompanionMinimapButton.SetHidden(preferences().minimapButton.hidden) end,"minimapButton",true),
    option("Quest objectives","Show nearby objective locations for the selected quest.",mini.IsEnabled,mini.SetEnabled),
    option("Mailbox markers","Show nearby mailboxes independently of quest objectives.",mini.MailEnabled,mini.SetMailEnabled),
    savedFeature("Party markers","Show Companion party markers on compatible minimaps.","partyMinimapEnabled",false,ForeverCompanionPartyMinimap.Refresh),
  }
  local widgets={
    option("My Quests tracker","Show the movable My Quests window.",ForeverCompanionQuestTracker.IsShown,
      function(value) if value then ForeverCompanionQuestTracker.Show() else ForeverCompanionQuestTracker.Hide() end end),
    option("Navigation arrow","Show the arrow or travel strip when you start Companion navigation.",ForeverCompanionQuestDirection.Enabled,ForeverCompanionQuestDirection.SetEnabled),
    savedFeature("Combat meter","Show the movable combat meter window.","visible",false,
      function() if preferences().combatMeter.visible then ForeverCompanionCombatMeter.Show() else ForeverCompanionCombatMeter.Hide() end end,"combatMeter"),
    savedFeature("Party distance","Show the distance panel when you are in a party.","partyDistanceEnabled",false,ForeverCompanionPartyDistance.Refresh),
    savedFeature("Pet XP tracker","Show the XP and kill panel when a Hunter pet is active.","petXPHidden",true,ForeverCompanionPetXPTracker.Refresh,nil,true),
    option("Flight timer","Show flight countdowns and estimated travel times on flight destination tooltips.",ForeverCompanionFlightTimer.Enabled,ForeverCompanionFlightTimer.SetEnabled),
    option("Sent mail history","Record new confirmed sends in Inventory > Sent mail. Existing records are kept.",ForeverCompanionBankView.SentHistoryEnabled,ForeverCompanionBankView.SetSentHistoryEnabled),
  }
  return {{"World Map",worldOptions},{"Services",services},{"Map Overlay",overlay},{"Minimap",minimap},{"Widgets & Mail",widgets}}
end

local selectedGroup=1
local featureRows,featureTabs,groups
local function renderFeatures()
  local U=ForeverCompanionInterface
  for i,tab in ipairs(featureTabs) do U.StyleButton(tab,nil,i==selectedGroup) end
  for i,row in ipairs(featureRows) do
    local feature=groups[selectedGroup][2][i]
    row.feature=feature
    row:SetShown(feature~=nil)
    if feature then
      local enabled=feature.get()==true
      row:SetText(feature.name)
      row.status:SetText(enabled and "On" or "Off")
      row.status:SetTextColor(unpack(enabled and {.42,.88,.69} or {.73,.76,.83}))
      U.StyleButton(row,nil,enabled)
    end
  end
end
local function createFeatures(parent)
  local U=ForeverCompanionInterface
  local panel=CreateFrame("Frame",nil,parent)
  panel:SetPoint("TOPLEFT",0,0)
  panel:SetSize(770,344)
  ForeverCompanionVisualTheme.Panel(panel,770,344)
  label(panel,16,-11,738,"FEATURE CONTROLS","GameFontNormal",ForeverCompanionVisualTheme.colors.accent)
  groups=featureGroups()
  featureRows,featureTabs={},{}
  local rows=0
  for i,group in ipairs(groups) do
    rows=math.max(rows,#group[2])
    local index=i
    local tab=U.Button(panel)
    tab:SetPoint("TOPLEFT",15+(i-1)*149,-34)
    tab:SetSize(144,26)
    tab:SetText(group[1])
    tab:SetScript("OnClick",function() selectedGroup=index;renderFeatures() end)
    featureTabs[i]=tab
  end
  for i=1,rows do
    local row=U.Button(panel)
    row:SetSize(365,29)
    row:SetPoint("TOPLEFT",15+375*((i-1)%2),-68-33*math.floor((i-1)/2))
    local caption=row:GetFontString()
    caption:ClearAllPoints()
    caption:SetPoint("LEFT",10,0)
    caption:SetPoint("RIGHT",-52,0)
    caption:SetJustifyH("LEFT")
    row.status=U.Text(row,12)
    row.status:SetPoint("RIGHT",-12,0)
    U.SetHoverHelp(row,"Feature setting",function() return row.feature and row.feature.description or "" end)
    row:SetScript("OnClick",function(self)
      local feature=self.feature
      if feature then feature.set(not feature.get());renderFeatures() end
    end)
    featureRows[i]=row
  end
end

S.Height=830
function S.Create(parent,context)
  ctx=context or {}
  root=CreateFrame("Frame",nil,parent)
  root:SetSize(770,S.Height)
  root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-5)
  createFeatures(root)
  local preferencesPanel=CreateFrame("Frame",nil,root)
  preferencesPanel:SetPoint("TOPLEFT",0,-356)
  preferencesPanel:SetSize(770,470)
  values={}
  local left=plate(preferencesPanel,0,376,"PREFERENCES & CHARACTER")
  values.character=label(left,16,-47,344,"Character preview loading","GameFontHighlight",{0.94,0.90,0.81})
  values.role=label(left,16,-74,344,"Role preference loading","GameFontHighlightSmall",{0.70,0.77,0.84})
  values.layout=label(left,16,-101,344,"Window layout loading","GameFontHighlightSmall",{0.91,0.74,0.44})
  values.saved=label(left,16,-129,344,"Per-character preferences","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.disclosure=label(left,16,-151,344,"Preview does not change game talents.","GameFontHighlightSmall",{0.69,0.75,0.81})
  local right=plate(preferencesPanel,389,381,"CLIENT API VISIBILITY")
  values.client=label(right,16,-43,349,"Client build not available","GameFontHighlightSmall",{0.94,0.90,0.81})
  values.quest=label(right,16,-69,349,"Quest API: checking","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.profession=label(right,16,-91,349,"Profession API: checking","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.spellbook=label(right,16,-113,349,"Spellbook API: checking","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.xp=label(right,16,-135,349,"XP API: checking","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.warning=label(preferencesPanel,14,-238,740,"Use /fcdiag for a full client report.","GameFontHighlightSmall",{0.93,0.71,0.38})
  values.warning:SetWidth(360)
  local performance=ForeverCompanionInterface.Button(preferencesPanel)
  performance:SetPoint('TOPLEFT',preferencesPanel,'TOPLEFT',400,-237);performance:SetSize(180,26);performance:SetText('Performance sample')
  performance:SetScript('OnClick',function() ForeverCompanionRefreshQueue.ToggleReport() end)
  local setup=ForeverCompanionInterface.Button(preferencesPanel)
  setup:SetPoint('TOPRIGHT',preferencesPanel,'TOPRIGHT',-2,-237);setup:SetSize(180,26);setup:SetText('Quest data & setup')
  setup:SetScript('OnClick',function() ForeverCompanionQuestSetup.Toggle() end)
  actions={
    button(preferencesPanel,0,"AUTO-DETECT CLASS",ctx.autoClass),
    button(preferencesPanel,264,"CENTER WINDOW",ctx.centerWindow),
    button(preferencesPanel,528,"TOGGLE COMPACT",ctx.toggleCompact)
  }
  local commands=CreateFrame('Frame',nil,preferencesPanel)
  commands:SetPoint('TOPLEFT',0,-276);commands:SetSize(770,186)
  ForeverCompanionVisualTheme.Panel(commands,770,186)
  label(commands,16,-12,738,'QUICK REFERENCE','GameFontNormal',ForeverCompanionVisualTheme.colors.accent)
  local entries={
    {'/fc next','Navigate to the next matched objective on this map'},
    {'/fc arrow','Arrow size, position lock and reset'},
    {'/fc session','XP, time, turn-ins and previous leveling sessions'},
    {'/fc tracker','Show or hide the floating quest tracker'},
    {'/fc setup','Check quest data and missing-marker guidance'},
  }
  for i,entry in ipairs(entries) do
    local y=-46-(i-1)*25
    label(commands,16,y,150,entry[1],nil,ForeverCompanionVisualTheme.colors.accent)
    label(commands,180,y,570,entry[2],nil,ForeverCompanionVisualTheme.colors.muted)
  end
  root:Hide()
  return root
end
function S.Render()
  if not root then return end
  renderFeatures()
  local db=safe(ctx.db) or {}
  if type(db)~="table" then db={} end
  local actual=safe(ctx.actualClass) or "Unknown class"
  local display=safe(ctx.displayClass) or "Unknown class"
  values.character:SetText("Detected: "..tostring(actual).."  |  Preview: "..tostring(display))
  values.role:SetText("Preferred role: "..tostring(db.role or "Not selected"))
  values.layout:SetText("Layout: "..(db.compact and "Compact" or "Expanded").."  |  Drag title to move")
  values.saved:SetText("Settings are stored for this character.")
  local version,build,_,interface
  if type(GetBuildInfo)=="function" then
    local ok,a,b,c,d=pcall(GetBuildInfo)
    if ok then version,build,interface=a,b,d end
  end
  values.client:SetText("Client: "..tostring(version or "Unknown").."  |  Interface: "..tostring(interface or "?"))
  local flags=S.Capabilities({
    modernQuests=type(C_QuestLog)=="table" and type(C_QuestLog.GetInfo)=="function",
    legacyQuests=type(GetNumQuestLogEntries)=="function" and type(GetQuestLogTitle)=="function",
    modernProfessions=type(GetProfessions)=="function" and type(GetProfessionInfo)=="function",
    legacyProfessions=type(GetNumSkillLines)=="function" and type(GetSkillLineInfo)=="function",
    modernSpellbook=type(C_SpellBook)=="table" and type(C_SpellBook.GetSpellBookItemName)=="function",
    legacySpellbook=type(GetSpellBookItemName)=="function",
    xp=type(UnitXP)=="function" and type(UnitXPMax)=="function"
  })
  values.quest:SetText("Quest log: "..apiStatus(flags.quests))
  values.profession:SetText("Professions: "..apiStatus(flags.professions))
  values.spellbook:SetText("Spellbook: "..apiStatus(flags.spellbook))
  values.xp:SetText("Experience: "..apiStatus(flags.xp))
end
function S.Show(visible)
  if not root then return end
  if visible then root:Show();S.Render() else root:Hide() end
end
