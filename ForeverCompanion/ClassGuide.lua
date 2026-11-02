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
  paint(bg,0.035,0.044,0.066,0.99)
  local trim=f:CreateTexture(nil,"ARTWORK")
  trim:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
  trim:SetSize(w,2)
  paint(trim,0.82,0.59,0.25)
  local bottom=f:CreateTexture(nil,"ARTWORK")
  bottom:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",0,0)
  bottom:SetSize(w,1)
  paint(bottom,0.35,0.29,0.20)
  local left=f:CreateTexture(nil,"ARTWORK")
  left:SetPoint("TOPLEFT",f,"TOPLEFT",0,0)
  left:SetSize(1,h)
  paint(left,0.35,0.29,0.20)
  local right=f:CreateTexture(nil,"ARTWORK")
  right:SetPoint("TOPRIGHT",f,"TOPRIGHT",0,0)
  right:SetSize(1,h)
  paint(right,0.35,0.29,0.20)
  -- Double-line gilded inlay, ornamental corner studs, and velvet header.
  local function ornament(x,y,w,h,r,g,b,a)
    local t=f:CreateTexture(nil,"ARTWORK")
    t:SetPoint("TOPLEFT",f,"TOPLEFT",x,y)
    t:SetSize(w,h)
    paint(t,r,g,b,a)
  end
  ornament(4,-5,w-8,1,0.58,0.39,0.17,0.9)
  ornament(5,-h+6,w-10,1,0.46,0.33,0.18,0.7)
  ornament(4,-4,16,2,0.98,0.76,0.34,1)
  ornament(4,-4,2,16,0.98,0.76,0.34,1)
  ornament(w-20,-4,16,2,0.98,0.76,0.34,1)
  ornament(w-6,-4,2,16,0.98,0.76,0.34,1)
  ornament(4,-h+19,2,15,0.68,0.49,0.23,0.95)
  ornament(w-6,-h+19,2,15,0.68,0.49,0.23,0.95)
  ornament(13,-34,w-26,1,0.57,0.42,0.23,0.55)
  if ForeverCompanionOrnaments then ForeverCompanionOrnaments.Hero(f,w,h) end
  return f
end
local function safeXP()
  if type(UnitXP)~="function" or type(UnitXPMax)~="function" then return nil end
  local ok,a,b=pcall(function() return UnitXP("player"),UnitXPMax("player") end)
  if not ok then return nil end
  local success,ratio=pcall(function()
    if type(a)=="number" and type(b)=="number" and a==a and b==b and b>0 and b<math.huge then
      return math.max(0,math.min(1,a/b))
    end
  end)
  if success and type(ratio)=="number" and ratio==ratio then return ratio end
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
  local profileGlow=profile:CreateTexture(nil,"BORDER")
  profileGlow:SetPoint("TOPLEFT",profile,"TOPLEFT",7,-39)
  profileGlow:SetSize(368,102)
  paint(profileGlow,0.08,0.13,0.20,0.38)
  -- Built-in class artwork provides a real native hero motif without shipping
  -- copyrighted screenshots or relying on external image downloads.
  values.heroArt=profile:CreateTexture(nil,"BORDER")
  values.heroArt:SetPoint("TOPRIGHT",profile,"TOPRIGHT",-15,-37)
  values.heroArt:SetSize(122,110)
  if values.heroArt.SetAlpha then values.heroArt:SetAlpha(0.12) end
  local heroVeil=profile:CreateTexture(nil,"ARTWORK")
  heroVeil:SetPoint("TOPRIGHT",profile,"TOPRIGHT",-11,-36)
  heroVeil:SetSize(113,110)
  paint(heroVeil,0.025,0.035,0.055,0.19)
  label(profile,15,-13,300,"CLASS GUIDE  /  LEVELING","GameFontNormal",GOLD)
  local iconFrame=profile:CreateTexture(nil,"ARTWORK")
  iconFrame:SetPoint("TOPLEFT",profile,"TOPLEFT",13,-41)
  iconFrame:SetSize(54,54)
  iconFrame:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  values.icon=profile:CreateTexture(nil,"OVERLAY")
  values.icon:SetPoint("TOPLEFT",profile,"TOPLEFT",16,-44)
  values.icon:SetSize(48,48)
  values.name=label(profile,80,-45,265,"","GameFontNormalLarge",PALE)
  values.classSigil=label(profile,330,-13,36,"","GameFontNormal",GOLD)
  values.role=label(profile,80,-73,255,"","GameFontHighlightSmall",MUTED)
  values.band=label(profile,16,-101,350,"","GameFontHighlightSmall",GOLD)
  values.tip=label(profile,16,-123,352,"","GameFontHighlightSmall",PALE)
  -- The compact card shows a short actionable focus. Hover for the complete,
  -- class-specific practice note; this tooltip never changes game state.
  profile:EnableMouse(true)
  profile:SetScript("OnEnter",function(self)
    if GameTooltip and values.currentTip then
      GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
      GameTooltip:SetText("CURRENT LEVELING FOCUS",0.96,0.75,0.36)
      GameTooltip:AddLine(values.currentTip,0.92,0.89,0.82,true)
      GameTooltip:AddLine("General guidance: verify skills and unlocks in the live Forever client.",0.67,0.76,0.83,true)
      GameTooltip:Show()
    end
  end)
  profile:SetScript("OnLeave",function()
    if GameTooltip then GameTooltip:Hide() end
  end)
  local build=plate(root,394,0,386,151)
  local buildGlow=build:CreateTexture(nil,"BORDER")
  buildGlow:SetPoint("TOPLEFT",build,"TOPLEFT",7,-39)
  buildGlow:SetSize(372,102)
  paint(buildGlow,0.13,0.09,0.06,0.32)
  label(build,15,-13,345,"TALENTS  /  ROTATIONS  /  GEAR","GameFontNormal",GOLD)
  label(build,339,-13,30,"II","GameFontNormal",GOLD)
  values.spec=label(build,16,-45,351,"","GameFontHighlight",PALE)
  values.mode=label(build,16,-70,351,"","GameFontHighlightSmall",MUTED)
  values.xp=label(build,16,-93,351,"","GameFontHighlightSmall",PALE)
  values.xpCaption=label(build,16,-108,351,"LEVEL PROGRESS","GameFontNormalSmall",GOLD)
  local trackShadow=build:CreateTexture(nil,"BORDER")
  trackShadow:SetPoint("TOPLEFT",build,"TOPLEFT",14,-123)
  trackShadow:SetSize(354,12)
  paint(trackShadow,0.035,0.028,0.020,0.92)
  local track=build:CreateTexture(nil,"ARTWORK")
  track:SetPoint("TOPLEFT",build,"TOPLEFT",16,-125)
  track:SetSize(350,8)
  paint(track,0.10,0.13,0.19)
  local xpBorder=build:CreateTexture(nil,"ARTWORK")
  xpBorder:SetPoint("TOPLEFT",build,"TOPLEFT",15,-124)
  xpBorder:SetSize(352,10)
  paint(xpBorder,0.50,0.36,0.18,0.38)
  xpFill=build:CreateTexture(nil,"OVERLAY")
  xpFill:SetPoint("TOPLEFT",build,"TOPLEFT",16,-125)
  xpFill:SetSize(1,8)
  paint(xpFill,0.92,0.67,0.28)
  root:Hide()
  return root
end
function Guide.Render(classToken,classLabel,level,role,mode)
  if not root then return end
  local handbook=type(ForeverCompanionData)=="table" and ForeverCompanionData.classHandbook
  local entry=type(handbook)=="table" and handbook[classToken]
  values.icon:SetTexture(type(entry)=="table" and entry.icon or "Interface\\Icons\\INV_Misc_Book_09")
  values.heroArt:SetTexture(type(entry)=="table" and entry.icon or "Interface\\Icons\\INV_Misc_Book_09")
  -- Tint the class motif with native class colors when exposed by the client.
  local classColor=type(RAID_CLASS_COLORS)=="table" and RAID_CLASS_COLORS[classToken]
  if type(values.heroArt.SetVertexColor)=="function" then
    if type(classColor)=="table" then
      values.heroArt:SetVertexColor(type(classColor.r)=="number" and classColor.r or 1,type(classColor.g)=="number" and classColor.g or 1,type(classColor.b)=="number" and classColor.b or 1)
    else
      values.heroArt:SetVertexColor(0.95,0.72,0.36)
    end
  end
  values.name:SetText(short(classLabel,18).."  |  Lv "..short(level or "?",4))
  values.classSigil:SetText(({WARRIOR="I",PALADIN="II",HUNTER="III",ROGUE="IV",PRIEST="V",SHAMAN="VI",MAGE="VII",WARLOCK="VIII",DRUID="IX"})[classToken] or "*")
  values.role:SetText("Preferred role: "..short(role or "Not selected",23))
  local band,number=nil,tonumber(level)
  if number and (number~=number or number<1 or number==math.huge) then number=nil end
  local zones=type(ForeverCompanionData)=="table" and ForeverCompanionData.zones
  if number and type(zones)=="table" then
    for _,candidate in ipairs(zones) do
      if type(candidate)=="table" and type(candidate[1])=="number" and type(candidate[2])=="number" and number>=candidate[1] and number<=candidate[2] then band=candidate;break end
    end
  end
  values.band:SetText(band and ("Leveling phase: "..short(band[3],20).." ("..band[1].."-"..band[2]..")") or "Leveling phase: unavailable")
  local curriculum=type(ForeverCompanionLevelingCurriculum)=="table" and ForeverCompanionLevelingCurriculum
  local stage
  if curriculum and type(curriculum.Stage)=="function" then
    local ok,result=pcall(curriculum.Stage,number or 1)
    if ok and (type(result)=="number" or type(result)=="string") then stage=result end
  end
  local notes=curriculum and type(curriculum.classes)=="table" and curriculum.classes[classToken]
  values.currentTip=(type(notes)=="table" and notes[stage]) or (type(entry)=="table" and entry.leveling) or "Review class-specific tips below."
  values.tip:SetText("FOCUS: "..short(values.currentTip,38))
  local planner=ForeverCompanionSpecPlanner
  local spec
  if type(planner)=="table" and type(planner.Get)=="function" then
    local ok,result=pcall(planner.Get,classToken)
    if ok and type(result)=="table" then spec=result end
  end
  values.spec:SetText("Suggested build: "..short(type(spec)=="table" and spec[1] or "Not available",24))
  local contexts=type(ForeverCompanionRotationPresentation)=="table" and ForeverCompanionRotationPresentation.contexts
  local context=type(contexts)=="table" and contexts[mode]
  values.mode:SetText("Suggested priority: "..short((type(context)=="table" and context.title) or mode or "Leveling",24))
  local fraction=safeXP()
  if fraction then
    values.xpCaption:SetText("LEVEL PROGRESS")
    values.xp:SetText("Experience progress: "..math.floor(fraction*100+0.5).."%")
    xpFill:SetWidth(math.max(1,math.floor(350*fraction)))
  else
    values.xpCaption:SetText("LEVEL PROGRESS  /  UNAVAILABLE")
    values.xp:SetText("Experience: unavailable on this client/level")
    xpFill:SetWidth(1)
  end
end
function Guide.Show(visible)
  if not root then return end
  if visible then root:Show() else root:Hide() end
end
