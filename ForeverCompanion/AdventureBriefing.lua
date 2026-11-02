-- Native dark-fantasy preparation cards for Dungeons and PvP.
-- The progress bar measures only manual addon checklist ticks, never combat readiness.
-- No protected game actions, automated targeting, queueing, or spell casts.
local Briefing={}
ForeverCompanionAdventureBriefing=Briefing

local root, context, navigate
local labels={},{}
local progressFill, section
local GOLD={0.94,0.72,0.32,1}
local PALE={0.93,0.89,0.81,1}
local MUTED={0.68,0.73,0.78,1}
local BAR_WIDTH=344

local function paint(texture,r,g,b,a)
  if texture.SetColorTexture then texture:SetColorTexture(r,g,b,a or 1)
  else texture:SetTexture(r,g,b,a or 1) end
end
local function strip(parent,x,y,w,h,color)
  local t=parent:CreateTexture(nil,"ARTWORK")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetSize(w,h)
  paint(t,color[1],color[2],color[3],color[4])
  return t
end
local function label(parent,x,y,w,initial,style,color)
  local t=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlightSmall")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetWidth(w)
  t:SetJustifyH("LEFT")
  t:SetText(initial or "")
  if color then t:SetTextColor(color[1],color[2],color[3],color[4]) end
  return t
end
local function short(value,limit)
  local s=tostring(value or "Unavailable"):gsub("[%c|]"," ")
  if #s>limit then return s:sub(1,limit-3).."..." end
  return s
end
local function safe(fn,...)
  if type(fn)~="function" then return nil end
  local ok,value=pcall(fn,...)
  if ok then return value end
end
local function card(parent,x,w)
  local frame=CreateFrame("Frame",nil,parent)
  frame:SetSize(w,165)
  frame:SetPoint("TOPLEFT",parent,"TOPLEFT",x,0)
  local bg=frame:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(frame)
  paint(bg,0.055,0.071,0.100,0.99)
  strip(frame,0,0,w,2,GOLD)
  strip(frame,0,-164,w,1,{0.38,0.30,0.20,1})
  strip(frame,0,0,1,165,{0.38,0.30,0.20,1})
  strip(frame,w-1,0,1,165,{0.38,0.30,0.20,1})
  -- Fine gilded corner inlays, drawn in the actual WoW UI.
  for _,xx in ipairs({5,w-21}) do strip(frame,xx,-5,16,2,GOLD) end
  strip(frame,5,-5,2,14,GOLD)
  strip(frame,w-7,-5,2,14,GOLD)
  strip(frame,5,-150,2,14,GOLD)
  strip(frame,w-7,-150,2,14,GOLD)
  return frame
end
local function navButton(parent,x,title,target)
  local b=CreateFrame("Button",nil,parent)
  b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-125)
  b:SetSize(162,27)
  local bg=b:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(b)
  paint(bg,0.15,0.14,0.12,1)
  strip(b,0,0,162,1,GOLD)
  local text=b:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  text:SetPoint("CENTER",b,"CENTER",0,0)
  text:SetText(title)
  text:SetTextColor(0.97,0.86,0.65)
  b:SetScript("OnClick",function()
    if type(navigate)=="function" then navigate(target) end
  end)
  b:SetScript("OnEnter",function() paint(bg,0.27,0.22,0.14,1) end)
  b:SetScript("OnLeave",function() paint(bg,0.15,0.14,0.12,1) end)
  return b
end

-- Pure, deterministic checklist summary for offline tests and honest UI labels.
function Briefing.Summary(tasks,checked)
  tasks=type(tasks)=="table" and tasks or {}
  checked=type(checked)=="table" and checked or {}
  local total,done,nextTask=#tasks,0
  for i=1,total do
    if checked[i]==true then done=done+1
    elseif not nextTask then nextTask=tasks[i] end
  end
  return {total=total,done=done,nextTask=nextTask}
end

function Briefing.Create(parent,openPage,ctx)
  navigate=openPage
  context=ctx or {}
  root=CreateFrame("Frame",nil,parent)
  root:SetSize(770,165)
  root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-5)
  local left=card(root,0,376)
  local right=card(root,389,381)
  local emblem=left:CreateTexture(nil,"OVERLAY")
  emblem:SetPoint("TOPLEFT",left,"TOPLEFT",14,-13)
  emblem:SetSize(27,27)
  labels.icon=emblem
  labels.heading=label(left,50,-17,310,"PREPARATION CHECKLIST","GameFontNormal",GOLD)
  labels.count=label(left,15,-55,344,"Manual checklist not loaded","GameFontHighlight",PALE)
  labels.next=label(left,15,-80,344,"Next step unavailable","GameFontHighlightSmall",MUTED)
  strip(left,15,-108,BAR_WIDTH,9,{0.19,0.24,0.30,1})
  progressFill=strip(left,15,-108,1,9,{0.91,0.68,0.29,1})
  for i=1,3 do strip(left,15+math.floor(BAR_WIDTH*i/4),-108,1,9,{0.75,0.64,0.43,0.58}) end
  labels.note=label(left,15,-133,345,"Manual planning only; no game-state changes","GameFontHighlightSmall",MUTED)
  label(right,15,-17,345,"CLASS & ROLE GUIDANCE","GameFontNormal",GOLD)
  labels.class=label(right,15,-46,346,"Class and role not available","GameFontHighlight",PALE)
  labels.tip=label(right,15,-70,346,"Reference advice appears here","GameFontHighlightSmall",MUTED)
  labels.roleTip=label(right,15,-100,346,"Verify mechanics in your game client","GameFontHighlightSmall",{0.91,0.73,0.43,1})
  navButton(right,15,"OPEN CLASS GUIDE","Leveling")
  navButton(right,203,"OPEN QUEST JOURNAL","Quests")
  root:Hide()
  return root
end

function Briefing.Render(page)
  if not root then return end
  page=page=="PvP" and "PvP" or "Dungeons"
  section=page
  local data=ForeverCompanionData
  local tasks=data and data.checklist and data.checklist[page]
  local db=safe(context and context.db) or {}
  local checks=type(db.checks)=="table" and db.checks[page] or nil
  local summary=Briefing.Summary(tasks,checks)
  labels.heading:SetText(page=="PvP" and "PVP PREPARATION" or "DUNGEON PREPARATION")
  labels.icon:SetTexture(page=="PvP" and "Interface\\Icons\\Ability_DualWield" or "Interface\\Icons\\INV_Weapon_ShortBlade_01")
  labels.count:SetText(summary.done.."/"..summary.total.." preparation tasks marked complete")
  labels.next:SetText(short(summary.nextTask and ("Next: "..summary.nextTask) or (summary.total>0 and "All tasks checked - review again before play" or "No checklist available"),52))
  progressFill:SetWidth(summary.total>0 and math.max(1,math.floor(BAR_WIDTH*summary.done/summary.total)) or 1)
  labels.note:SetText("Manual checklist only  |  "..(page=="PvP" and "No automated PvP actions" or "No automatic group or dungeon actions"))
  local token=safe(context and context.classToken)
  local className=safe(context and context.classLabel) or "Unknown class"
  local role=safe(context and context.role) or "Role not selected"
  labels.class:SetText(short(className,25).."  |  "..short(role,22))
  local handbook=data and data.classHandbook
  local guide=handbook and handbook[token]
  local tip=guide and (page=="PvP" and guide.pvp or guide.dungeon)
  labels.tip:SetText(short(tip or "Review class guidance and coordinate with your group.",84))
  local roleTips=data and data.roleAdvice and data.roleAdvice[role]
  local roleTip=type(roleTips)=="table" and roleTips[1] or nil
  labels.roleTip:SetText(short(roleTip or "Confirm objectives, positioning and defensive plans.",62))
end

function Briefing.Show(page)
  if not root then return end
  if page=="Dungeons" or page=="PvP" then
    root:Show()
    Briefing.Render(page)
  else
    root:Hide()
  end
end
