-- Class guide hero cards. Native, read-only UI: no spell casts or protected actions.
local Guide={}
ForeverCompanionClassGuide=Guide
local root, values, xpFill
local GOLD={0.93,0.70,0.30}
local PALE={0.92,0.89,0.81}
local MUTED={0.67,0.72,0.78}
local function paint(texture,r,g,b,a)
  if texture.SetColorTexture then texture:SetColorTexture(r,g,b,a or 1)
  else texture:SetTexture(r,g,b,a or 1) end
end
local function label(parent,x,y,w,value,font,color)
  local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
  f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  f:SetWidth(w)
  f:SetJustifyH("LEFT")
  f:SetText(value or "")
  if color then f:SetTextColor(color[1],color[2],color[3]) end
  return f
end
local function plate(parent,x,y,w,h)
  local f=CreateFrame("Frame",nil,parent)
  f:SetSize(w,h)
  f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  local bg=f:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(f)
  paint(bg,0.065,0.083,0.112,0.99)
  local trim=f:CreateTexture(nil,"ARTWORK")
  trim:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
  trim:SetSize(w,2)
  paint(trim,0.82,0.59,0.25)
  return f
end
local function safeXP()
  if type(UnitXP)~="function" or type(UnitXPMax)~="function" then return nil end
  local ok,a,b=pcall(function() return UnitXP("player"),UnitXPMax("player") end)
  if not ok then return nil end
  local success,ratio=pcall(function()
    if type(a)=="number" and type(b)=="number" and b>0 then
      return math.max(0,math.min(1,a/b))
    end
  end)
  if success then return ratio end
end
local function short(value,max)
  value=tostring(value or "Not available"):gsub("[\r\n]"," ")
  if #value>max then return value:sub(1,max-3).."..." end
  return value
end
function Guide.Create(parent)
  root=CreateFrame("Frame",nil,parent)
  root:SetSize(780,151)
  root:SetPoint("TOPLEFT",parent,"TOPLEFT",5,-4)
  values={}
  local profile=plate(root,0,0,382,151)
  label(profile,15,-13,300,"CHARACTER & LEVELING","GameFontNormal",GOLD)
  values.icon=profile:CreateTexture(nil,"OVERLAY")
  values.icon:SetPoint("TOPLEFT",profile,"TOPLEFT",16,-44)
  values.icon:SetSize(43,43)
  values.name=label(profile,71,-45,292,"","GameFontNormalLarge",PALE)
  values.role=label(profile,71,-73,292,"","GameFontHighlightSmall",MUTED)
  values.tip=label(profile,16,-103,352,"","GameFontHighlightSmall",PALE)
  local build=plate(root,394,0,386,151)
  label(build,15,-13,345,"BUILD & ROTATION REFERENCE","GameFontNormal",GOLD)
  values.spec=label(build,16,-46,351,"","GameFontHighlight",PALE)
  values.mode=label(build,16,-71,351,"","GameFontHighlightSmall",MUTED)
  values.xp=label(build,16,-100,351,"","GameFontHighlightSmall",PALE)
  local track=build:CreateTexture(nil,"ARTWORK")
  track:SetPoint("TOPLEFT",build,"TOPLEFT",16,-125)
  track:SetSize(350,8)
  paint(track,0.18,0.22,0.28)
  xpFill=build:CreateTexture(nil,"OVERLAY")
  xpFill:SetPoint("TOPLEFT",build,"TOPLEFT",16,-125)
  xpFill:SetSize(1,8)
  paint(xpFill,0.92,0.67,0.28)
  root:Hide()
  return root
end
function Guide.Render(classToken,classLabel,level,role,mode)
  if not root then return end
  local handbook=ForeverCompanionData and ForeverCompanionData.classHandbook
  local entry=handbook and handbook[classToken]
  values.icon:SetTexture(entry and entry.icon or "Interface\\Icons\\INV_Misc_Book_09")
  values.name:SetText(short(classLabel,25).."  |  Lv "..tostring(level or "?"))
  values.role:SetText("Preferred role: "..short(role or "Not selected",30))
  values.tip:SetText(short(entry and entry.leveling or "Review your class-specific leveling guide below.",85))
  local spec=ForeverCompanionSpecPlanner and ForeverCompanionSpecPlanner.Get and ForeverCompanionSpecPlanner.Get(classToken)
  values.spec:SetText("Spec preview: "..short(spec and spec[1] or "Not available",30))
  local contexts=ForeverCompanionRotationPresentation and ForeverCompanionRotationPresentation.contexts
  local context=contexts and contexts[mode]
  values.mode:SetText("Priority context: "..short(context and context.title or mode or "Leveling",38))
  local fraction=safeXP()
  if fraction then
    values.xp:SetText("Experience progress: "..math.floor(fraction*100+0.5).."%")
    xpFill:SetWidth(math.max(1,math.floor(350*fraction)))
  else
    values.xp:SetText("Experience: unavailable on this client/level")
    xpFill:SetWidth(1)
  end
end
function Guide.Show(visible)
  if not root then return end
  if visible then root:Show() else root:Hide() end
end
