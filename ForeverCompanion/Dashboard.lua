-- Premium dashboard. All game reads are optional and protected; actions only navigate
-- guide pages or toggle a per-character planning checklist.
local D={}
ForeverCompanionDashboard=D
local root, context, navigate, compact
local values, bars, focusButtons, focusLabels={}, {}, {}, {}
local lowerWidgets={}
local beginnerPanel, focusPanel, modeButton, beginnerHint
local beginnerQuest, beginnerClass, beginnerMap
local beginnerHero, beginnerHeadline, beginnerDescription, beginnerQuestAction, advancedCards
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
  ForeverCompanionVisualTheme.Panel(p,w,h)
  local start=15
  if icon then
    local image=p:CreateTexture(nil,"OVERLAY")
    image:SetPoint("TOPLEFT",p,"TOPLEFT",14,-11)
    image:SetSize(23,23)
    image:SetTexture(icon)
    start=45
  end
  p.heading=text(p,p,start,-13,w-start-12,label,"GameFontNormal",GOLD)
  if ForeverCompanionVisualTheme then
    ForeverCompanionVisualTheme.Font(p.heading,13)
  end
  return p
end
local function action(parent,x,y,w,label,icon,fn,height)
  local h=height or 30
  local b=CreateFrame("Button",nil,parent)
  b:SetSize(w,h)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  local bg=b:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(b)
  paint(bg,.043,.052,.068,1)
  ForeverCompanionInterface.Bevel(b)
  local rail=strip(b,0,0,3,h,{.22,.37,.32,1})
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
  caption:SetTextColor(.90,.93,.97)
  caption:SetWordWrap(true);caption:SetHeight(h-3)
  ForeverCompanionVisualTheme.Font(caption,12)
  b.caption=caption
  b:SetScript("OnClick",fn)
  b:SetScript("OnEnter",function(self)
    paint(bg,.075,.09,.115,1)
    paint(rail,.82,.68,.43,1)
    caption:SetTextColor(.98,.97,.93)
    if GameTooltip and type(GameTooltip.SetOwner)=="function" and type(GameTooltip.SetText)=="function" then
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      GameTooltip:SetText(self.detail or caption:GetText(),1,0.84,0.47,true)
      if self.extraDetail and type(GameTooltip.AddLine)=="function" then
        GameTooltip:AddLine(self.extraDetail,0.74,0.80,0.83,true)
      end
      if type(GameTooltip.Show)=="function" then GameTooltip:Show() end
    end
  end)
  b:SetScript("OnLeave",function()
    paint(bg,.043,.052,.068,1)
    paint(rail,.22,.27,.34,1)
    caption:SetTextColor(.90,.93,.97)
    if GameTooltip and type(GameTooltip.Hide)=="function" then GameTooltip:Hide() end
  end)
  return b
end
-- All custom actions use their owned caption FontString; Button:SetText alone
-- does not reliably display text on an untemplated WoW Button.
local function updateAction(button,value)
  local full=tostring(value or ""):gsub("[\r\n]"," ")
  button.detail=full
  button.caption:SetText(full)
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
    if GameTooltip and type(GameTooltip.SetOwner)=="function" and type(GameTooltip.SetText)=="function" then
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      GameTooltip:SetText(label,1,0.82,0.48)
      if type(GameTooltip.AddLine)=="function" then
        GameTooltip:AddLine(explanation or "Open the related guide.",0.89,0.89,0.82,true)
        GameTooltip:AddLine("Current: "..tostring(self.detail or "N/A"),0.70,0.79,0.85)
      end
      if type(GameTooltip.Show)=="function" then GameTooltip:Show() end
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
  ForeverCompanionVisualTheme.EnvironmentArt(banner,'TOPRIGHT',-2,-2,662,91,'Overview',.97,.11,'BORDER',2)
  if ForeverCompanionHeraldry then
    ForeverCompanionHeraldry.Create(banner,16,-13,68)
  else
    local crest=banner:CreateTexture(nil,"OVERLAY")
    crest:SetPoint("TOPLEFT",banner,"TOPLEFT",23,-20)
    crest:SetSize(54,54)
    crest:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
  end
  local welcome=text(banner,banner,93,-18,540,"ADVENTURE JOURNAL","GameFontNormalLarge",PALE)
  if ForeverCompanionVisualTheme then ForeverCompanionVisualTheme.Font(welcome,18) end

  values.bannerStatus=text(banner,banner,94,-72,540,"Loading character…","GameFontHighlightSmall",MUTED)
  strip(banner,94,-88,402,1,{0.69,0.51,0.24,0.75})
  -- Keep the headline readable over the brighter portions of the citadel.
  local headlineShade=banner:CreateTexture(nil,"ARTWORK")
  headlineShade:SetPoint("TOPLEFT",banner,"TOPLEFT",84,-7)
  headlineShade:SetSize(430,79)
  paint(headlineShade,0.018,0.047,0.040,0.43)
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
  -- Icon-first tiles mirror the reference; each remains an explicit page action.
  local shortcuts={{"Journey","INV_Misc_Map_01","Leveling Route"},{"Quests","INV_Misc_Note_01"},{"Professions","Trade_BlackSmithing"},{"Dungeons","INV_Weapon_ShortBlade_01"},{"Legacy","INV_Misc_Book_11"},{"Session","INV_Misc_GroupNeedMore","My Session"}}
  for i,entry in ipairs(shortcuts) do
    local target=entry[1]
    local b=action(quick,12+((i-1)%3)*96,-44-math.floor((i-1)/3)*63,90,entry[3] or target,nil,function() if target=='Session' then ForeverCompanionSessionProgress.Toggle() else navigate(target) end end,57)
    b.extraDetail='Open '..(entry[3] or target)..'.'
    local r,g,v=unpack(ForeverCompanionVisualTheme.Destination(target).rgb)
    strip(b,3,-55,84,2,{r,g,v,1})
    local icon=b:CreateTexture(nil,"ARTWORK");icon:SetPoint("TOP",b,"TOP",0,-5);icon:SetSize(27,27);icon:SetTexture("Interface\\Icons\\"..entry[2])
    b.caption:ClearAllPoints();b.caption:SetPoint("BOTTOM",b,"BOTTOM",0,5);b.caption:SetWidth(86);b.caption:SetJustifyH("CENTER")
    if ForeverCompanionVisualTheme then ForeverCompanionVisualTheme.Font(b.caption,10) end
  end
  local goals=panel(593,-108,253,176,"PROGRESS & GOALS","Interface\\Icons\\INV_Misc_Rune_01")
  progress(goals,15,-48,221,"Experience",{0.30,0.76,0.40,1},"Leveling","Read-only XP progress toward your next level.")
  progress(goals,15,-88,221,"Quests ready",{0.25,0.60,0.94,1},"Quests","Ready-to-turn-in quests in the latest successful quest-log scan.")
  progress(goals,15,-128,221,"Materials ready",{0.94,0.67,0.23,1},"Professions","Manual material goal completion; not a live inventory scan.")
  -- Beginner dashboard deliberately hides the three data-heavy cards. One
  -- clear decision is easier to understand than six unrelated shortcuts.
  advancedCards={character,quick,goals}
  beginnerHero=panel(0,-108,846,176,"CURRENT OBJECTIVE","Interface\\Icons\\INV_Misc_Map_01")
  beginnerHero.heading:SetTextColor(.43,.90,.67)
  beginnerHeadline=text(beginnerHero,beginnerHero,20,-49,790,"Checking your quests...","GameFontNormalLarge",PALE)
  beginnerDescription=text(beginnerHero,beginnerHero,20,-82,785,"","GameFontHighlight",MUTED)
  beginnerDescription:SetHeight(38)
  beginnerDescription:SetWordWrap(true)
  beginnerQuestAction=action(beginnerHero,20,-127,210,"Open my quests","Interface\\Icons\\INV_Misc_Note_01",function()
    local planner=ForeverCompanionQuestPlanner
    if planner and type(planner.GetLive)=="function" and type(planner.Select)=="function" then
      local ok,quests=pcall(planner.GetLive)
      if ok and type(quests)=="table" then
        for index,quest in ipairs(quests) do
          if quest.complete then pcall(planner.Select,index);break end
        end
      end
    end
    if type(navigate)=="function" then navigate("Quests") end
  end,34)
  action(beginnerHero,240,-127,180,"Plan my session","Interface\\Icons\\INV_Misc_Map_01",function() navigate('Plan') end,34)
  local classAction=action(beginnerHero,430,-127,175,"Class guide","Interface\\Icons\\INV_Misc_Book_09",function()
    if type(navigate)=="function" then navigate("Leveling") end
  end,34)
  classAction.detail="See suggested abilities and leveling advice. Nothing is cast automatically."
  local mapAction=action(beginnerHero,615,-127,210,"World map","Interface\\Icons\\INV_Misc_Map_01",function()
    if type(navigate)=="function" then navigate("Map") end
  end,34)
  mapAction.detail="Only verified or recorded locations can show navigation markers."
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
  focusPanel=focus
  focus.heading:SetWidth(260)
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
  -- Beginner-first guided entry. Advanced daily checklists remain one click away.
  beginnerPanel=panel(0,-296,846,148,"JOURNAL SHORTCUTS","Interface\\Icons\\INV_Misc_Book_09")
  beginnerPanel.heading:SetTextColor(.47,.88,.97)
  local shortcutIcons={"INV_Misc_Note_01","Spell_Holy_BlessingOfStrength","INV_Misc_Map_01"}
  local beginnerActions={
    {"FIND YOUR NEXT QUEST", "Quests", "Open your active quests and choose one objective."},
    {"LEARN YOUR CLASS", "Leveling", "See beginner ability priorities; check trained spells in-game."},
    {"OPEN THE WORLD MAP", "Map", "Review quest locations and available navigation markers."},
  }
  for i,entry in ipairs(beginnerActions) do
    local target=entry[2]
    local button=action(beginnerPanel,14+(i-1)*274,-43,264,entry[1],"Interface\\Icons\\"..shortcutIcons[i],function()
      if target=="Quests" then
        local planner=ForeverCompanionQuestPlanner
        if planner and type(planner.IsSupported)=="function" and planner.IsSupported() then
          local live=type(planner.GetLive)=="function" and planner.GetLive() or nil
          local chosen
          if type(live)=="table" then
            for index,quest in ipairs(live) do
              if quest.complete then chosen=index;break end
            end
          end
          if not chosen and type(planner.GetPinned)=="function" then
            local _,index=planner.GetPinned()
            chosen=index
          end
          if chosen and type(planner.Select)=="function" then pcall(planner.Select,chosen) end
        end
      end
      if type(navigate)=="function" then navigate(target) end
    end,68)
    button.caption:SetWordWrap(true);button.caption:SetHeight(52);button.caption:SetWidth(211)
    button.detail=entry[3]
    if i==1 then beginnerQuest=button
    elseif i==2 then beginnerClass=button
    else beginnerMap=button end
  end
  beginnerHint=text(beginnerPanel,beginnerPanel,16,-125,810,"","GameFontHighlightSmall",MUTED)
  modeButton=action(banner,648,-50,180,"Show advanced view",nil,function()
    local db=getDB()
    db.beginnerMode=(db.beginnerMode==false)
    if ForeverCompanionRefresh then ForeverCompanionRefresh() else D.Render() end
  end,30)
  lowerWidgets={steps}
  safePlate=CreateFrame("Frame",nil,root)
  safePlate:SetPoint("TOPLEFT",root,"TOPLEFT",0,-492);safePlate:SetSize(846,48)
  ForeverCompanionInterface.Surface(safePlate)
  local statusTitle=text(safePlate,safePlate,14,-7,805,"DATA STATUS","GameFontHighlightSmall",MUTED)
  ForeverCompanionVisualTheme.Font(statusTitle,10)
  values.sources=text(safePlate,safePlate,14,-26,805,"Quest data: awaiting scan   |   Professions: awaiting scan   |   Materials: manually entered","GameFontHighlightSmall",MUTED)
  values.sources:SetHeight(15);values.sources:SetWordWrap(false)
  setCompact(false)
  return root
end
function D.Render()
  if not root then return end
  local db=getDB()
  local beginner=db.beginnerMode~=false
  -- The hero already provides all three actions. The duplicate steps card
  -- does not fit above the compact data-status/footer area.
  if beginnerPanel then beginnerPanel:SetShown(beginner and not compact) end
  if beginnerHero then beginnerHero:SetShown(beginner) end
  if advancedCards then
    for _,card in ipairs(advancedCards) do card:SetShown(not beginner) end
  end
  if lowerWidgets then
    for _,widget in ipairs(lowerWidgets) do widget:SetShown(not beginner and not compact) end
  end
  if focusPanel then focusPanel:SetShown(not beginner and not compact) end
  if modeButton then updateAction(modeButton,beginner and "Show advanced view" or "Show beginner view") end
  local class=context and context.class and context.class() or "Unknown"
  local level=context and context.level and context.level() or "?"
  local player=safeCall(UnitName,"player") or "Adventurer"
  values.character:SetText(tostring(player).."   •   Level "..tostring(level))
  values.class:SetText("Class: "..tostring(class))
  if values.classIcon then
    ForeverCompanionIcons.ApplyClass(values.classIcon,context and context.classToken and context.classToken() or string.upper(tostring(class)))
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
  local questFocus=firstReady or (type(pinned)=="table" and not pinned.complete and pinned) or selected
  -- A beginner sees one concrete, honest next action rather than a feature menu.
  -- This never invents a quest or assumes that a stale quest snapshot is current.
  if beginnerHeadline then
    local title,description="Open your quest log","Quest tracking unavailable"
    if firstReady then
      title="Turn in: "..tostring(firstReady.title or "completed quest")
      description=(firstReady.zone and firstReady.zone~="" and firstReady.zone.."  /  " or "").."Ready to turn in"
    elseif questFocus then
      title="Continue: "..tostring(questFocus.title or "active quest")
      description=(questFocus.zone and questFocus.zone~="" and questFocus.zone.."  /  " or "").."In progress"
    elseif questSupported then
      title="Find your first quest"
      description="No active quests"
    else
      description="Quest tracking unavailable"
    end
    beginnerHeadline:SetText(title)
    beginnerDescription:SetText(description)
    if beginnerQuestAction then
      updateAction(beginnerQuestAction,firstReady and "Review turn-in" or "Open my quests")
      beginnerQuestAction.extraDetail=questSupported and "Review objectives, turn-ins and available map locations." or "Open the quest panel for tracking status and manual notes."
    end
  end
  if beginnerQuest then
    if questSupported and firstReady and firstReady.title then
      updateAction(beginnerQuest,"TURN IN: "..tostring(firstReady.title))
      beginnerQuest.extraDetail="This quest was marked complete in the latest quest scan. Open Quests to check the turn-in."
    elseif questSupported and type(questFocus)=="table" and questFocus.title then
      updateAction(beginnerQuest,"CONTINUE: "..tostring(questFocus.title))
      beginnerQuest.extraDetail="Open Quests to see objectives. Map markers only appear when reliable coordinates are available."
    elseif questSupported and questCount==0 then
      updateAction(beginnerQuest,"FIND A QUEST TO START")
      beginnerQuest.extraDetail="No active quests were detected. Visit a quest giver or check the in-game quest log."
    else
      updateAction(beginnerQuest,"CHECK YOUR ACTIVE QUESTS")
      beginnerQuest.extraDetail="The quest scan is unavailable or incomplete; use the game's quest log as the source of truth."
    end
  end
  if beginnerClass then
    updateAction(beginnerClass,"LEARN YOUR "..string.upper(tostring(class)).." ABILITIES")
    beginnerClass.extraDetail="Beginner priorities are advice, not automatic combat. Verify spells and talents for your client."
  end
  if beginnerMap then
    updateAction(beginnerMap,"SEE WHERE TO GO ON THE MAP")
    beginnerMap.extraDetail="Map markers require known coordinates; missing locations are not guessed."
  end
  if beginnerHint then
    beginnerHint:SetText(questSupported and "" or "Quest tracking unavailable: check your in-game quest log first.")
  end
  values.step1.extraDetail=nil
  if type(questFocus)=="table" then
    local zone=type(questFocus.zone)=="string" and questFocus.zone or "Zone not supplied"
    local objective=type(questFocus.objectives)=="table" and questFocus.objectives[1] or nil
    objective=type(objective)=="string" and objective or "Objective details not supplied"
    values.step1.extraDetail=("Zone: "..zone.."  |  Objective: "..objective.."  |  Addon focus only"):sub(1,350)
  end
  if firstReady and firstReady.title then
    updateAction(values.step1, "Turn in: "..tostring(firstReady.title))
  elseif questSupported and pinned and pinned.title and not pinned.complete then
    updateAction(values.step1, "Pinned: "..tostring(pinned.title))
  elseif questSupported and selected and selected.title then
    updateAction(values.step1, "Continue: "..tostring(selected.title))
  elseif questSupported then
    updateAction(values.step1,"Open quest log")
  else
    updateAction(values.step1,"Quest tracking unavailable")
  end
  updateAction(values.step2,tostring(class).." class guide")
  values.step2.extraDetail="Select a specialization and compare trained spells before using advisory priorities."
  local shortage=type(stats)=="table" and tonumber(stats.missing) or nil
  values.step3.extraDetail="Material totals are manual planning entries, not an inventory or market-price scan."
  if shortage and shortage>0 then
    local top=safeCall(craft and craft.TopShortages,1)
    local item=type(top)=="table" and top[1] or nil
    if item then
      updateAction(values.step3,"Gather "..item.missing.." "..tostring(item.name))
    else
      updateAction(values.step3,shortage.." materials needed")
    end
  else
    updateAction(values.step3,"Open profession goals")
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
