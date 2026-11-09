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
function S.Create(parent,context)
  ctx=context or {}
  root=CreateFrame("Frame",nil,parent)
  root:SetSize(770,470)
  root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-5)
  values={}
  local left=plate(root,0,376,"PREFERENCES & CHARACTER")
  values.character=label(left,16,-47,344,"Character preview loading","GameFontHighlight",{0.94,0.90,0.81})
  values.role=label(left,16,-74,344,"Role preference loading","GameFontHighlightSmall",{0.70,0.77,0.84})
  values.layout=label(left,16,-101,344,"Window layout loading","GameFontHighlightSmall",{0.91,0.74,0.44})
  values.saved=label(left,16,-129,344,"Per-character preferences","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.disclosure=label(left,16,-151,344,"Preview does not change game talents.","GameFontHighlightSmall",{0.69,0.75,0.81})
  local right=plate(root,389,381,"CLIENT API VISIBILITY")
  values.client=label(right,16,-43,349,"Client build not available","GameFontHighlightSmall",{0.94,0.90,0.81})
  values.quest=label(right,16,-69,349,"Quest API: checking","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.profession=label(right,16,-91,349,"Profession API: checking","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.spellbook=label(right,16,-113,349,"Spellbook API: checking","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.xp=label(right,16,-135,349,"XP API: checking","GameFontHighlightSmall",{0.69,0.75,0.81})
  values.warning=label(root,14,-238,740,"Use /fcdiag for a full client report.","GameFontHighlightSmall",{0.93,0.71,0.38})
  values.warning:SetWidth(500)
  local setup=ForeverCompanionInterface.Button(root)
  setup:SetPoint('TOPRIGHT',root,'TOPRIGHT',-2,-237);setup:SetSize(180,26);setup:SetText('Quest data & setup')
  setup:SetScript('OnClick',function() ForeverCompanionQuestSetup.Toggle() end)
  actions={
    button(root,0,"AUTO-DETECT CLASS",ctx.autoClass),
    button(root,264,"CENTER WINDOW",ctx.centerWindow),
    button(root,528,"TOGGLE COMPACT",ctx.toggleCompact)
  }
  local commands=CreateFrame('Frame',nil,root)
  commands:SetPoint('TOPLEFT',0,-276);commands:SetSize(770,186)
  ForeverCompanionVisualTheme.Panel(commands,770,186)
  label(commands,16,-12,738,'QUICK REFERENCE','GameFontNormal',ForeverCompanionVisualTheme.colors.accent)
  local entries={
    {'/fc help','Show all addon commands'},
    {'/fcdiag','Print the client compatibility report'},
    {'/fc tracker','Show or hide the floating quest tracker'},
    {'/fc discover','Browse quest pickup locations'},
    {'/fc history','Review your recorded quest turn-ins'},
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
