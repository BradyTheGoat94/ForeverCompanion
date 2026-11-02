-- Native profession briefing, using only read-only skill API results and manual goals.
local B={}
ForeverCompanionProfessionBriefing=B
local root, values, skillBars, materialFill
local BAR=304
local function paint(t,r,g,b,a)
  if t.SetColorTexture then t:SetColorTexture(r,g,b,a or 1)
  else t:SetTexture(r,g,b,a or 1) end
end
local function text(parent,x,y,w,value,style,color)
  local t=parent:CreateFontString(nil,"OVERLAY",style or "GameFontHighlightSmall")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetWidth(w)
  t:SetJustifyH("LEFT")
  t:SetText(value or "")
  if color then t:SetTextColor(color[1],color[2],color[3]) end
  return t
end
local function panel(parent,x,w,heading)
  local p=CreateFrame("Frame",nil,parent)
  p:SetSize(w,156)
  p:SetPoint("TOPLEFT",parent,"TOPLEFT",x,0)
  local bg=p:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(p)
  paint(bg,0.058,0.076,0.104,0.99)
  local trim=p:CreateTexture(nil,"ARTWORK")
  trim:SetPoint("TOPLEFT",p,"TOPLEFT",0,0)
  trim:SetSize(w,2)
  paint(trim,0.92,0.67,0.29,1)
  local bottom=p:CreateTexture(nil,"ARTWORK")
  bottom:SetPoint("BOTTOMLEFT",p,"BOTTOMLEFT",0,0)
  bottom:SetSize(w,1)
  paint(bottom,0.35,0.29,0.20,1)
  local left=p:CreateTexture(nil,"ARTWORK")
  left:SetPoint("TOPLEFT",p,"TOPLEFT",0,0)
  left:SetSize(1,156)
  paint(left,0.35,0.29,0.20,1)
  local right=p:CreateTexture(nil,"ARTWORK")
  right:SetPoint("TOPRIGHT",p,"TOPRIGHT",0,0)
  right:SetSize(1,156)
  paint(right,0.35,0.29,0.20,1)
  text(p,15,-14,w-30,heading,"GameFontNormal",{0.95,0.76,0.39})
  return p
end
local function progress(parent,x,y,w,color)
  local track=parent:CreateTexture(nil,"ARTWORK")
  track:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  track:SetSize(w,8)
  paint(track,0.17,0.21,0.27,1)
  local fill=parent:CreateTexture(nil,"OVERLAY")
  fill:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  fill:SetSize(1,8)
  paint(fill,color[1],color[2],color[3],1)
  return fill
end
local function shorten(value,max)
  local v=tostring(value or "Unavailable"):gsub("[\r\n|]"," ")
  if #v>max then return v:sub(1,max-3).."..." end
  return v
end
function B.Create(parent)
  root=CreateFrame("Frame",nil,parent)
  root:SetSize(770,156)
  root:SetPoint("TOPLEFT",parent,"TOPLEFT",8,-5)
  values={};skillBars={}
  local skills=panel(root,0,378,"PROFESSION SKILLS")
  values.status=text(skills,15,-41,345,"Detecting learned professions...","GameFontHighlightSmall",{0.70,0.77,0.82})
  for i=1,2 do
    local y=-64-(i-1)*42
    values["skill"..i]=text(skills,15,y,345,"","GameFontHighlightSmall",{0.94,0.89,0.77})
    skillBars[i]=progress(skills,15,y-20,344,{0.34,0.72,0.50})
  end
  local goals=panel(root,390,380,"MATERIAL GOALS")
  values.guide=text(goals,15,-43,350,"Select a profession below","GameFontHighlightSmall",{0.93,0.89,0.79})
  values.materials=text(goals,15,-69,350,"No material goals tracked","GameFontHighlightSmall",{0.70,0.77,0.82})
  materialFill=progress(goals,15,-93,345,{0.91,0.66,0.28})
  values.missing=text(goals,15,-117,350,"Counts are entered manually","GameFontHighlightSmall",{0.92,0.77,0.49})
  values.note=text(goals,15,-137,350,"All tracked lists; no inventory scanning","GameFontHighlightSmall",{0.66,0.71,0.77})
  root:Hide()
  return root
end
function B.Render(guideName)
  if not root then return end
  values.guide:SetText("Guide: "..shorten(guideName or "Not selected",35))
  local scanner=ForeverCompanionProfessionScanner
  local learned,reason
  if scanner and type(scanner.Read)=="function" then
    local ok,items,why=pcall(scanner.Read)
    if ok then learned,reason=items,why else reason="Profession scan failed on this client." end
  else
    reason="Profession API not available."
  end
  if type(learned)=="table" and #learned>0 then
    values.status:SetText(tostring(#learned).." detected  |  read-only skill levels")
  else
    values.status:SetText(shorten(reason or "No professions detected",47))
  end
  for i=1,2 do
    local item=type(learned)=="table" and learned[i] or nil
    local caption=values["skill"..i]
    if item then
      local skill=tonumber(item.skill)
      local cap=tonumber(item.maxSkill)
      caption:SetText(shorten(item.name,23).."  "..(skill and tostring(skill) or "?").."/"..(cap and tostring(cap) or "?"))
      skillBars[i]:SetWidth(skill and cap and cap>0 and math.max(1,math.floor(344*math.max(0,math.min(1,skill/cap)))) or 1)
    else
      caption:SetText(i==1 and "No verified skill data" or "")
      skillBars[i]:SetWidth(1)
    end
  end
  local craft=ForeverCompanionCraftingPlanner
  local stats
  if craft and type(craft.Stats)=="function" then
    local ok,result=pcall(craft.Stats)
    if ok and type(result)=="table" then stats=result end
  end
  local total=stats and tonumber(stats.materials) or 0
  local complete=stats and tonumber(stats.complete) or 0
  local missing=stats and tonumber(stats.missing) or 0
  values.materials:SetText(total>0 and (complete.."/"..total.." material goals completed") or "No material goals tracked")
  values.missing:SetText(total>0 and (missing.." units remaining (manual counts)") or "Add materials with /fcm add")
  materialFill:SetWidth(total>0 and math.max(1,math.floor(345*math.max(0,math.min(1,complete/total)))) or 1)
end
function B.Show(show)
  if not root then return end
  if show then root:Show() else root:Hide() end
end
