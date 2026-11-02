-- Premium dashboard. All game reads are optional and protected; actions only navigate
-- guide pages or toggle a per-character planning checklist.
local D={}
ForeverCompanionDashboard=D
local root, context, navigate, compact
local values, bars, focusButtons, focusLabels={}, {}, {}, {}
local lowerWidgets={}
local safePlate
local GOLD={0.92,0.70,0.31,1}
local PALE={0.93,0.90,0.82,1}
local MUTED={0.65,0.70,0.76,1}
local function paint(texture,r,g,b,a)
  if texture.SetColorTexture then texture:SetColorTexture(r,g,b,a)
  else texture:SetTexture(r,g,b,a) end
end
local function text(parent,anchor,x,y,width,value,font,color)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
  t:SetPoint("TOPLEFT",anchor or parent,"TOPLEFT",x,y)
  t:SetWidth(width)
  t:SetJustifyH("LEFT")
  t:SetText(value or "")
  if color then t:SetTextColor(color[1],color[2],color[3],color[4]) end
  return t
end
local function strip(parent,x,y,w,h,color)
  local t=parent:CreateTexture(nil,"ARTWORK")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetSize(w,h)
  paint(t,color[1],color[2],color[3],color[4] or 1)
  return t
end
local function panel(x,y,w,h,label,icon)
  local p=CreateFrame("Frame",nil,root)
  p:SetSize(w,h)
  p:SetPoint("TOPLEFT",root,"TOPLEFT",x,y)
  local bg=p:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(p)
  paint(bg,0.055,0.069,0.093,0.98)
  strip(p,0,0,w,2,GOLD)
  strip(p,0,-h+2,w,1,{0.36,0.29,0.19,0.9})
  strip(p,0,0,1,h,{0.34,0.29,0.22,0.8})
  strip(p,w-1,0,1,h,{0.34,0.29,0.22,0.8})
  local start=15
  if icon then
    local image=p:CreateTexture(nil,"OVERLAY")
    image:SetPoint("TOPLEFT",p,"TOPLEFT",14,-11)
    image:SetSize(23,23)
    image:SetTexture(icon)
    start=45
  end
  text(p,p,start,-13,w-start-12,label,"GameFontNormal",GOLD)
  return p
end
local function action(parent,x,y,w,label,icon,fn,height)
  local h=height or 46
  local b=CreateFrame("Button",nil,parent)
  b:SetSize(w,h)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  local bg=b:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(b)
  paint(bg,0.12,0.15,0.20,1)
  strip(b,0,0,w,1,{0.60,0.45,0.23,1})
  strip(b,0,-h+1,w,1,{0.45,0.35,0.21,1})
  local offset=12
  if icon then
    local i=b:CreateTexture(nil,"ARTWORK")
    i:SetPoint("LEFT",b,"LEFT",9,0)
    i:SetSize(27,27)
    i:SetTexture(icon)
    offset=42
  end
  local caption=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  caption:SetPoint("LEFT",b,"LEFT",offset,0)
  caption:SetWidth(w-offset-6)
  caption:SetJustifyH("LEFT")
  caption:SetText(label)
  caption:SetTextColor(0.96,0.88,0.69)
  b.caption=caption
  b:SetScript("OnClick",fn)
  b:SetScript("OnEnter",function() paint(bg,0.24,0.20,0.12,1) end)
  b:SetScript("OnLeave",function() paint(bg,0.12,0.15,0.20,1) end)
  return b
end
local function progress(parent,x,y,w,label,color)
  local caption=text(parent,parent,x,y,w,label,"GameFontHighlightSmall",PALE)
  local track=strip(parent,x,y-20,w,9,{0.18,0.22,0.29,1})
  local fill=strip(parent,x,y-20,1,9,color or {0.27,0.72,0.39,1})
  local value=text(parent,parent,x+w-78,y,78,"","GameFontHighlightSmall",GOLD)
  value:SetJustifyH("RIGHT")
  bars[label]={fill=fill,width=w,value=value,caption=caption}
end
local function setBar(name,fraction,detail)
  local bar=bars[name]
  if not bar then return end
  local n=tonumber(fraction)
  bar.fill:SetWidth(n and math.max(1,math.floor(bar.width*math.max(0,math.min(1,n)))) or 1)
  bar.value:SetText(detail or "N/A")
end
local function safeCall(fn,...)
  if type(fn)~="function" then return nil end
  local ok,result=pcall(fn,...)
  if ok then return result end
end
local function getDB()
  return context and context.db and context.db() or {}
end
local function xp()
  local current=safeCall(UnitXP,"player")
  local maximum=safeCall(UnitXPMax,"player")
  -- Some client builds restrict arithmetic on API values; never crash the UI.
  local ok,fraction=pcall(function()
    if type(current)=="number" and type(maximum)=="number" and maximum>0 then
      return math.max(0,math.min(1,current/maximum))
    end
  end)
  if ok and fraction then return fraction,current,maximum end
  return nil
end
local function focusState()
  local db=getDB()
  if type(db.dashboardFocus)~="table" then db.dashboardFocus={} end
  -- The focus list represents a day, not a permanent achievement checklist.
  -- If the client does not expose a usable date, preserve existing choices.
  if type(date)=="function" then
    local ok,key=pcall(date,"%Y-%m-%d")
    if ok and type(key)=="string" and key:match("^%d%d%d%d%-%d%d%-%d%d$") then
      if db.dashboardFocusDay and db.dashboardFocusDay~=key then db.dashboardFocus={} end
      db.dashboardFocusDay=key
    end
  end
  return db.dashboardFocus
end
local function setCompact(isCompact)
  compact=not not isCompact
  for _,w in ipairs(lowerWidgets) do
    if compact then w:Hide() else w:Show() end
  end
  if safePlate then
    safePlate:ClearAllPoints()
    safePlate:SetPoint("TOPLEFT",root,"TOPLEFT",0,compact and -300 or -495)
  end
end
D.SetCompact=setCompact
function D.Create(parent,openPage,ctx)
  context=ctx
  navigate=openPage
  root=CreateFrame("Frame",nil,parent)
  root:SetPoint("TOPLEFT",parent,"TOPLEFT",210,-100)
  root:SetSize(846,535)
  -- Welcome banner: a real in-game widget, not baked into the preview.
  local banner=panel(0,0,846,95,"",nil)
  local bannerBg=banner:CreateTexture(nil,"ARTWORK")
  bannerBg:SetPoint("TOPLEFT",banner,"TOPLEFT",1,-3)
  bannerBg:SetSize(844,90)
  paint(bannerBg,0.105,0.116,0.16,0.98)
  -- A lightweight castle skyline built from native UI textures, not a fake image.
  local towers={{615,28,29},{648,44,36},{689,33,31},{724,58,41},{770,39,34},{808,27,25}}
  for _,tower in ipairs(towers) do
    local left,height,width=tower[1],tower[2],tower[3]
    local silhouette=banner:CreateTexture(nil,"ARTWORK")
    silhouette:SetPoint("BOTTOMLEFT",banner,"BOTTOMLEFT",left,5)
    silhouette:SetSize(width,height)
    paint(silhouette,0.14,0.16,0.22,1)
    local spire=banner:CreateTexture(nil,"ARTWORK")
    spire:SetPoint("BOTTOMLEFT",banner,"BOTTOMLEFT",left+math.floor(width/2)-2,height+5)
    spire:SetSize(4,12)
    paint(spire,0.20,0.18,0.20,1)
    local windowLight=banner:CreateTexture(nil,"OVERLAY")
    windowLight:SetPoint("BOTTOMLEFT",banner,"BOTTOMLEFT",left+math.floor(width/2)-2,11)
    windowLight:SetSize(4,8)
    paint(windowLight,0.76,0.53,0.22,0.8)
  end
  local crest=banner:CreateTexture(nil,"OVERLAY")
  crest:SetPoint("TOPLEFT",banner,"TOPLEFT",19,-16)
  crest:SetSize(59,59)
  crest:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  text(banner,banner,93,-18,700,"WELCOME TO FOREVER COMPANION","GameFontNormalLarge",GOLD)
  text(banner,banner,94,-52,700,"Your in-game guide for leveling, quests, builds and professions","GameFontHighlight",PALE)
  -- Three-card top row, echoing the original reference artwork.
  local character=panel(0,-108,263,176,"CHARACTER OVERVIEW","Interface\\Icons\\INV_Misc_Head_Human_01")
  values.character=text(character,character,16,-48,185,"","GameFontHighlight",PALE)
  values.classIcon=character:CreateTexture(nil,"OVERLAY")
  values.classIcon:SetPoint("TOPRIGHT",character,"TOPRIGHT",-15,-48)
  values.classIcon:SetSize(34,34)
  values.class=text(character,character,16,-76,236,"","GameFontHighlightSmall",MUTED)
  values.role=text(character,character,16,-99,236,"","GameFontHighlightSmall",MUTED)
  values.professions=text(character,character,16,-125,236,"","GameFontHighlightSmall",MUTED)
  local quick=panel(275,-108,306,176,"QUICK ACTIONS","Interface\\Icons\\INV_Misc_Map_01")
  action(quick,12,-46,137,"Leveling","Interface\\Icons\\INV_Misc_Book_09",function() navigate("Leveling") end)
  action(quick,157,-46,137,"Quests","Interface\\Icons\\INV_Misc_Note_01",function() navigate("Quests") end)
  action(quick,12,-100,137,"Professions","Interface\\Icons\\Trade_BlackSmithing",function() navigate("Professions") end)
  action(quick,157,-100,137,"Diagnostics","Interface\\Icons\\INV_Gizmo_02",function() navigate("Settings") end)
  local goals=panel(593,-108,253,176,"PROGRESS & GOALS","Interface\\Icons\\INV_Misc_Rune_01")
  progress(goals,15,-48,221,"Experience",{0.30,0.76,0.40,1})
  progress(goals,15,-88,221,"Quests ready",{0.25,0.60,0.94,1})
  progress(goals,15,-128,221,"Materials ready",{0.94,0.67,0.23,1})
  local steps=panel(0,-296,416,186,"RECOMMENDED NEXT STEPS","Interface\\Icons\\INV_Misc_Map_01")
  values.step1=text(steps,steps,18,-48,382,"","GameFontHighlightSmall",PALE)
  values.step2=text(steps,steps,18,-90,382,"","GameFontHighlightSmall",PALE)
  values.step3=text(steps,steps,18,-132,382,"","GameFontHighlightSmall",PALE)
  local focus=panel(428,-296,418,186,"TODAY'S FOCUS","Interface\\Icons\\INV_Misc_Note_01")
  local names={"Review active quests","Check leveling priorities","Review material goals","Check client diagnostics"}
  for i,label in ipairs(names) do
    local index=i
    local button=action(focus,14,-45-(i-1)*34,390,"[ ]  "..label,nil,function()
      local state=focusState()
      state[index]=not state[index]
      D.Render()
    end,29)
    focusButtons[i]=button
    focusLabels[i]=label
  end
  lowerWidgets={steps,focus}
  safePlate=panel(0,-495,846,39,"READ-ONLY ADVISOR   •   NO AUTOMATION   •   CHECK /fcdiag FOR API SUPPORT",nil)
  setCompact(false)
  return root
end
function D.Render()
  if not root then return end
  local db=getDB()
  local class=context and context.class and context.class() or "Unknown"
  local level=context and context.level and context.level() or "?"
  local player=safeCall(UnitName,"player") or "Adventurer"
  values.character:SetText(tostring(player).."   •   Level "..tostring(level))
  values.class:SetText("Class: "..tostring(class))
  if values.classIcon then
    local handbook=ForeverCompanionData and ForeverCompanionData.classHandbook
    local entry=handbook and handbook[string.upper(tostring(class))]
    values.classIcon:SetTexture(entry and entry.icon or "Interface\\Icons\\INV_Misc_Book_09")
  end
  values.role:SetText("Role preference: "..tostring(db.role or "Not selected"))
  local professions=ForeverCompanionProfessionScanner
  local detected=professions and professions.Read and professions.Read()
  if type(detected)=="table" and #detected>0 then
    local names={}
    for i=1,math.min(2,#detected) do
      local p=detected[i]
      names[#names+1]=tostring(p.name)..(p.skill and " ("..p.skill..")" or "")
    end
    values.professions:SetText("Professions: "..(names[1] or "Not detected")..(names[2] and ("\n"..names[2]) or ""))
  else
    values.professions:SetText("Professions: "..tostring(db.professions or "Not detected"))
  end
  local fraction,current,maximum=xp()
  setBar("Experience",fraction,fraction and (math.floor(fraction*100+0.5).."%") or "N/A")
  local planner=ForeverCompanionQuestPlanner
  local questSupported=planner and planner.IsSupported and planner.IsSupported()
  local questCount=questSupported and planner.AutoCount() or nil
  local ready=questSupported and planner.ReadyCount() or nil
  setBar("Quests ready",questCount and questCount>0 and ready/questCount or nil,questCount and (ready.."/"..questCount) or "N/A")
  local craft=ForeverCompanionCraftingPlanner
  local stats=craft and craft.Stats and craft.Stats()
  setBar("Materials ready",stats and stats.materials>0 and stats.complete/stats.materials or nil,
    stats and stats.materials>0 and (stats.complete.."/"..stats.materials) or "N/A")
  local selected=planner and planner.GetSelected and planner.GetSelected()
  local firstReady
  if questSupported and planner.GetLive then
    for _,quest in ipairs(planner.GetLive()) do
      if quest.complete then firstReady=quest; break end
    end
  end
  if firstReady and firstReady.title then
    values.step1:SetText("1. Ready to turn in: "..tostring(firstReady.title):sub(1,58))
  elseif questSupported and selected and selected.title then
    values.step1:SetText("1. Quest focus: "..tostring(selected.title):sub(1,65))
  elseif questSupported then
    values.step1:SetText("1. Review your quest log for a new objective.")
  else
    values.step1:SetText("1. Quest API unavailable; check the game log or manual notes.")
  end
  values.step2:SetText("2. Review "..tostring(class).." leveling and rotation priorities.")
  if stats and stats.missing>0 then
    values.step3:SetText("3. Gather "..stats.missing.." units for tracked material goals.")
  else
    values.step3:SetText("3. Add or review your manual profession goals.")
  end
  local state=focusState()
  for i,b in ipairs(focusButtons) do
    local label=(state[i] and "[x]  " or "[ ]  ")..focusLabels[i]
    -- Use the existing button caption; never create new fontstrings during refresh.
    if b.caption then b.caption:SetText(label) end
  end
end
function D.Show(visible)
  if not root then return end
  if visible then root:Show();D.Render() else root:Hide() end
end
