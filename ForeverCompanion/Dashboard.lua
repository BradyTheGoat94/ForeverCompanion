-- Premium dashboard. All game reads are optional and protected; actions only navigate
-- guide pages or toggle a per-character planning checklist.
local D={}
ForeverCompanionDashboard=D
local root, context, navigate, compact
local values, bars, focusButtons, focusLabels={}, {}, {}, {}
local lowerWidgets={}
local safePlate, focusFill
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
  -- Layered header rule and inset bevel create a deeper gilded card frame.
  strip(p,0,0,w,2,GOLD)
  strip(p,3,-4,w-6,1,{0.72,0.53,0.25,0.52})
  strip(p,5,-h+6,w-10,1,{0.22,0.28,0.34,0.85})
  strip(p,0,-h+2,w,1,{0.36,0.29,0.19,0.9})
  strip(p,0,0,1,h,{0.34,0.29,0.22,0.8})
  strip(p,w-1,0,1,h,{0.34,0.29,0.22,0.8})
  -- Fine antique-gold corner inlays; native texture strips avoid external assets.
  local corner={0.91,0.69,0.31,0.94}
  strip(p,4,-4,15,2,corner)
  strip(p,4,-4,2,15,corner)
  strip(p,w-19,-4,15,2,corner)
  strip(p,w-6,-4,2,15,corner)
  strip(p,4,-h+19,2,15,corner)
  strip(p,w-6,-h+19,2,15,corner)
  -- A restrained illuminated title rail reinforces hierarchy on every card.
  strip(p,12,-37,w-24,1,{0.48,0.36,0.21,0.48})
  local start=15
  if icon then
    local image=p:CreateTexture(nil,"OVERLAY")
    image:SetPoint("TOPLEFT",p,"TOPLEFT",14,-11)
    image:SetSize(23,23)
    image:SetTexture(icon)
    start=45
  end
  p.heading=text(p,p,start,-13,w-start-12,label,"GameFontNormal",GOLD)
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
  local rail=strip(b,0,0,3,h,{0.46,0.35,0.20,1})
  strip(b,w-11,-6,6,1,{0.67,0.51,0.26,0.9})
  strip(b,w-6,-6,1,6,{0.67,0.51,0.26,0.9})
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
  b:SetScript("OnEnter",function(self)
    paint(bg,0.24,0.20,0.12,1)
    paint(rail,0.98,0.73,0.30,1)
    caption:SetTextColor(1,0.91,0.72)
    if self.detail and GameTooltip and type(GameTooltip.SetOwner)=="function" then
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      GameTooltip:SetText(self.detail,1,0.84,0.47)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave",function()
    paint(bg,0.12,0.15,0.20,1)
    paint(rail,0.46,0.35,0.20,1)
    caption:SetTextColor(0.96,0.88,0.69)
    if GameTooltip and type(GameTooltip.Hide)=="function" then GameTooltip:Hide() end
  end)
  return b
end
-- All custom actions use their owned caption FontString; Button:SetText alone
-- does not reliably display text on an untemplated WoW Button.
local function updateAction(button,value)
  local full=tostring(value or ""):gsub("[\r\n]"," ")
  button.detail=full
  local max=52
  button.caption:SetText(#full>max and (full:sub(1,max-3).."...") or full)
end
local function progress(parent,x,y,w,label,color,target,explanation)
  local caption=text(parent,parent,x,y,w,label,"GameFontHighlightSmall",PALE)
  local track=strip(parent,x,y-20,w,9,{0.18,0.22,0.29,1})
  local fill=strip(parent,x,y-20,1,9,color or {0.27,0.72,0.39,1})
  -- Small graduation marks make progress readable without relying on color.
  for i=1,3 do
    local tick=parent:CreateTexture(nil,"OVERLAY")
    tick:SetPoint("TOPLEFT",parent,"TOPLEFT",x+math.floor(w*i/4),y-20)
    tick:SetSize(1,9)
    paint(tick,0.73,0.65,0.46,0.58)
  end
  local value=text(parent,parent,x+w-78,y,78,"","GameFontHighlightSmall",GOLD)
  value:SetJustifyH("RIGHT")
  -- An invisible native button makes each metric a real guide shortcut.
  -- It never changes game state; it only navigates between addon pages.
  local hit=CreateFrame("Button",nil,parent)
  hit:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y+3)
  hit:SetSize(w,35)
  hit.dashboardTarget=target
  local hover=strip(hit,0,0,w,1,{0.94,0.71,0.31,0})
  hit:SetScript("OnClick",function() if type(navigate)=="function" then navigate(target) end end)
  hit:SetScript("OnEnter",function(self)
    paint(hover,0.94,0.71,0.31,0.95)
    if GameTooltip and type(GameTooltip.SetOwner)=="function" then
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      GameTooltip:SetText(label,1,0.82,0.48)
      if type(GameTooltip.AddLine)=="function" then
        GameTooltip:AddLine(explanation or "Open the related guide.",0.89,0.89,0.82,true)
        GameTooltip:AddLine("Current: "..tostring(self.detail or "N/A"),0.70,0.79,0.85)
      end
      GameTooltip:Show()
    end
  end)
  hit:SetScript("OnLeave",function()
    paint(hover,0.94,0.71,0.31,0)
    if GameTooltip and type(GameTooltip.Hide)=="function" then GameTooltip:Hide() end
  end)
  bars[label]={fill=fill,width=w,value=value,caption=caption,action=hit}
end
local function setBar(name,fraction,detail)
  local bar=bars[name]
  if not bar then return end
  local n=tonumber(fraction)
  bar.fill:SetWidth(n and math.max(1,math.floor(bar.width*math.max(0,math.min(1,n)))) or 1)
  bar.value:SetText(detail or "N/A")
  if bar.action then bar.action.detail=detail or "N/A" end
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
  if ForeverCompanionHeraldry then
    ForeverCompanionHeraldry.Create(banner,16,-13,68)
  else
    local crest=banner:CreateTexture(nil,"OVERLAY")
    crest:SetPoint("TOPLEFT",banner,"TOPLEFT",23,-20)
    crest:SetSize(54,54)
    crest:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  end
  text(banner,banner,93,-18,700,"WELCOME TO FOREVER COMPANION","GameFontNormalLarge",GOLD)
  text(banner,banner,94,-49,700,"Your in-game guide for leveling, quests, builds and professions","GameFontHighlight",PALE)
  values.bannerStatus=text(banner,banner,94,-72,670,"Checking current character progress...","GameFontHighlightSmall",MUTED)
  strip(banner,94,-88,402,1,{0.69,0.51,0.24,0.75})
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
  progress(goals,15,-48,221,"Experience",{0.30,0.76,0.40,1},"Leveling","Read-only XP progress toward your next level.")
  progress(goals,15,-88,221,"Quests ready",{0.25,0.60,0.94,1},"Quests","Ready-to-turn-in quests in the latest successful quest-log scan.")
  progress(goals,15,-128,221,"Materials ready",{0.94,0.67,0.23,1},"Professions","Manual material goal completion; not a live inventory scan.")
  local steps=panel(0,-296,416,186,"RECOMMENDED NEXT STEPS","Interface\\Icons\\INV_Misc_Map_01")
  -- Recommended steps are genuine navigation actions, not decorative text.
  values.step1=action(steps,12,-44,392,"",nil,function()
    local planner=ForeverCompanionQuestPlanner
    if planner and planner.IsSupported and planner.IsSupported() and planner.GetLive then
      local target
      for i,quest in ipairs(planner.GetLive()) do if quest.complete then target=i;break end end
      if not target and planner.GetPinned then local _,index=planner.GetPinned();target=index end
      if target and planner.Select then planner.Select(target) end
    end
    navigate("Quests")
  end,39)
  values.step2=action(steps,12,-89,392,"",nil,function() navigate("Leveling") end,39)
  values.step3=action(steps,12,-134,392,"",nil,function() navigate("Professions") end,39)
  local focus=panel(428,-296,418,186,"TODAY'S FOCUS","Interface\\Icons\\INV_Misc_Note_01")
  values.focusCount=text(focus,focus,312,-14,92,"0/4 done","GameFontHighlightSmall",GOLD)
  values.focusCount:SetJustifyH("RIGHT")
  strip(focus,15,-181,388,3,{0.19,0.24,0.30,1})
  focusFill=strip(focus,15,-181,1,3,{0.92,0.70,0.31,1})
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
  safePlate=panel(0,-495,846,55,"READ-ONLY ADVISOR   •   NO AUTOMATION   •   CHECK /fcdiag FOR API SUPPORT",nil)
  values.sources=text(safePlate,safePlate,16,-34,805,"Quest data: awaiting scan   |   Professions: awaiting scan   |   Materials: manually entered","GameFontHighlightSmall",MUTED)
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
  local detected=safeCall(professions and professions.Read)
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
  local questSupported=safeCall(planner and planner.IsSupported)==true
  local questCount=questSupported and safeCall(planner.AutoCount) or nil
  local questStale=safeCall(planner and planner.IsSnapshotStale)==true
  local ready=questSupported and safeCall(planner.ReadyCount) or nil
  local questValid=type(questCount)=="number" and type(ready)=="number" and questCount>=0 and ready>=0 and ready<=questCount
  setBar("Quests ready",questValid and questCount>0 and ready/questCount or nil,questValid and (ready.."/"..questCount) or "N/A")
  local questSource=questSupported and "current snapshot" or (questStale and "CACHED - VERIFY IN GAME" or "unavailable")
  local professionSource=type(detected)=="table" and (#detected>0 and "detected" or "none detected") or "API unavailable"
  if values.sources then values.sources:SetText("Quest data: "..questSource.."   |   Professions: "..professionSource.."   |   Materials: manual counts") end
  local craft=ForeverCompanionCraftingPlanner
  local stats=safeCall(craft and craft.Stats)
  local materialTotal=type(stats)=="table" and tonumber(stats.materials) or nil
  local materialDone=type(stats)=="table" and tonumber(stats.complete) or nil
  local materialValid=materialTotal and materialDone and materialTotal>0 and materialDone>=0 and materialDone==materialDone
  setBar("Materials ready",materialValid and materialDone/materialTotal or nil,
    materialValid and (materialDone.."/"..materialTotal) or "N/A")
  local selected=questSupported and safeCall(planner.GetSelected) or nil
  local firstReady
  local live=questSupported and safeCall(planner.GetLive) or nil
  if type(live)=="table" then
    for _,quest in ipairs(live) do
      if type(quest)=="table" and quest.complete then firstReady=quest; break end
    end
  end
  local pinned=questSupported and safeCall(planner.GetPinned) or nil
  if firstReady and firstReady.title then
    updateAction(values.step1,"1. Ready to turn in: "..tostring(firstReady.title))
  elseif questSupported and pinned and pinned.title and not pinned.complete then
    updateAction(values.step1,"1. Pinned priority: "..tostring(pinned.title))
  elseif questSupported and selected and selected.title then
    updateAction(values.step1,"1. Quest focus: "..tostring(selected.title))
  elseif questSupported then
    updateAction(values.step1,"1. Review your quest log for a new objective.")
  else
    updateAction(values.step1,"1. Quest API unavailable; check the game log or manual notes.")
  end
  updateAction(values.step2,"2. Review "..tostring(class).." leveling and rotation priorities.")
  local shortage=type(stats)=="table" and tonumber(stats.missing) or nil
  if shortage and shortage>0 then
    local top=safeCall(craft and craft.TopShortages,1)
    local item=type(top)=="table" and top[1] or nil
    if item then
      updateAction(values.step3,"3. Gather "..item.missing.." "..tostring(item.name).." for "..tostring(item.profession).." (manual).")
    else
      updateAction(values.step3,"3. Review "..shortage.." missing units in manual material goals.")
    end
  else
    updateAction(values.step3,"3. Add or review your manual profession goals.")
  end
  local summary=questSupported and (questValid and (ready.." ready of "..questCount.." quests") or "Quest scan incomplete") or (questStale and "Quest snapshot stale" or "Quest scan unavailable")
  local materialSummary=shortage and (shortage.." material units needed (manual)") or "Material goals unverified"
  if values.bannerStatus then values.bannerStatus:SetText("LEVEL "..tostring(level).."  |  "..summary.."  |  "..materialSummary) end
  local state=focusState()
  local checked=0
  for i,b in ipairs(focusButtons) do
    if state[i]==true then checked=checked+1 end
    local label=(state[i] and "[x]  " or "[ ]  ")..focusLabels[i]
    -- Use the existing button caption; never create new fontstrings during refresh.
    if b.caption then b.caption:SetText(label) end
  end
  if values.focusCount then values.focusCount:SetText(checked.."/"..#focusButtons.." done") end
  if focusFill then focusFill:SetWidth(math.max(1,math.floor(388*checked/math.max(1,#focusButtons)))) end
end
function D.Show(visible)
  if not root then return end
  if visible then root:Show();D.Render() else root:Hide() end
end
