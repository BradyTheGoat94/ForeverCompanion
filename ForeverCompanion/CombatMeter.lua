-- Forever Companion Combat Meter (experimental, native C_DamageMeter only).
-- No combat log listeners, gameplay automation, or arithmetic on secret values.
local M={}
ForeverCompanionCombatMeter=M
local frame,rows,heading,notice,modeButton,sessionButton,previousButton,nextButton,dragHandle
local pastIndex=1
local rowCount=8
local ROW_HEIGHT=25
local ROW_STEP=27
local BASE_HEIGHT=112
local windowWidth=320
local selectedRow=nil
local detailOpen=false
local detailRows={}
local detailPanel,detailTitle,detailClose
local detailTabs={}
local detailTab="Spells"
local detailLabel
local metricIndex,sessionIndex=1,1
local metrics={{"DPS","Dps"},{"Damage","DamageDone"},{"HPS","Hps"},{"Healing","HealingDone"},{"Absorbs","Absorbs"},{"Interrupts","Interrupts"},{"Dispels","Dispels"},{"Taken","DamageTaken"}}
local sessions={{"Current","Current"},{"Past","Expired"},{"Overall","Overall"}}
local skins={
 details={background={.012,.018,.027,.98},border={.24,.31,.36,1},accent={.22,.82,.96,1},rail={.025,.038,.052,.95},barAlpha=.92,texture="Interface\\\\TargetingFrame\\\\UI-StatusBar"},
 recount={background={.028,.023,.032,.98},border={.43,.32,.20,1},accent={.98,.67,.22,1},rail={.075,.045,.065,.96},barAlpha=.83,texture="Interface\\\\Buttons\\\\WHITE8X8"}
}
local skinName="details"
local function skin() return skins[skinName] or skins.details end
local elapsed=0
local function availableHistory()
 local api=C_DamageMeter
 if not api or type(api.GetAvailableCombatSessions)~="function" then return {} end
 local ok,result=pcall(api.GetAvailableCombatSessions)
 if ok and type(result)=="table" then return result end
 return {}
end
local function historyCount()
 return #availableHistory()
end
local function historyID(entry)
 if issecretvalue and issecretvalue(entry) then return nil end
 if type(entry)=="number" or type(entry)=="string" then return entry end
 if type(entry)~="table" then return nil end
 local id=entry.sessionID
 if issecretvalue and issecretvalue(id) then return nil end
 return id
end
local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,value=pcall(fn,...)
 if ok then return value end
end
local function saved()
 ForeverCompanionDB=ForeverCompanionDB or {}
 local db=ForeverCompanionDB
 db.combatMeter=db.combatMeter or {}
 return db.combatMeter
end
local function safeNumber(value)
 if issecretvalue and issecretvalue(value) then return false end
 return type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end
local function savePosition(target)
 if not target or not UIParent or not target.GetCenter or not UIParent.GetCenter then return end
 local x,y=target:GetCenter()
 local parentX,parentY=UIParent:GetCenter()
 if safeNumber(x) and safeNumber(y) and safeNumber(parentX) and safeNumber(parentY) then
  saved().position={point="CENTER",relative="CENTER",x=x-parentX,y=y-parentY}
 end
end
local function types()
 local e=Enum and Enum.DamageMeterType
 return e and e[metrics[metricIndex][2]]
end
local function sessionType()
 local e=Enum and Enum.DamageMeterSessionType
 return e and e[sessions[sessionIndex][2]]
end
function M.Available()
 if type(C_DamageMeter)~="table" or type(C_DamageMeter.GetCombatSessionFromType)~="function"
  or types()==nil or sessionType()==nil then return false end
 if type(C_DamageMeter.IsDamageMeterAvailable)=="function" then
  local ok,available=pcall(C_DamageMeter.IsDamageMeterAvailable)
  if not ok or not available then return false end
 end
 return true
end
local function button(parent,label,width,x,callback)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(width,23)
 b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,-39)
 b:SetText(label)
 b:SetScript("OnClick",callback)
 return b
end
local function build()
 frame=CreateFrame("Frame","ForeverCompanionCombatMeterWindow",UIParent,"BackdropTemplate")
 frame:SetSize(320,328)
 frame:SetPoint("CENTER",UIParent,"CENTER",330,0)
 frame:SetFrameStrata("MEDIUM")
 frame:SetClampedToScreen(true)
 frame:SetMovable(true)
 if frame.SetResizable then frame:SetResizable(true) end
 if frame.SetResizeBounds then frame:SetResizeBounds(280,BASE_HEIGHT+4*ROW_STEP,500,BASE_HEIGHT+12*ROW_STEP)
 elseif frame.SetMinResize and frame.SetMaxResize then
  frame:SetMinResize(280,BASE_HEIGHT+4*ROW_STEP)
  frame:SetMaxResize(500,BASE_HEIGHT+12*ROW_STEP)
 end
 frame:EnableMouse(true)
 frame:RegisterForDrag("LeftButton")
 frame:SetScript("OnDragStart",function(self)
  if not saved().locked then self:StartMoving() end
 end)
 frame:SetScript("OnDragStop",function(self)
  self:StopMovingOrSizing()
  savePosition(self)
 end)
 if frame.SetBackdrop then
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  frame:SetBackdropColor(.012,.018,.027,.98)
  frame:SetBackdropBorderColor(.24,.31,.36,1)
 end
 local db=saved()
 if skins[db.skin] then skinName=db.skin end
 if type(db.metric)=="string" then
  for i,item in ipairs(metrics) do
   if item[1]==db.metric then metricIndex=i;break end
  end
 end
 if type(db.session)=="string" then
  for i,item in ipairs(sessions) do
   if item[1]==db.session then sessionIndex=i;break end
  end
 end
 if safeNumber(db.rows) then rowCount=math.max(4,math.min(12,math.floor(db.rows))) end
 if safeNumber(db.width) then windowWidth=math.max(280,math.min(500,math.floor(db.width))) end
 frame:SetSize(windowWidth,BASE_HEIGHT+rowCount*ROW_STEP)
 if type(db.position)=="table" and safeNumber(db.position.x) and safeNumber(db.position.y) then
  frame:ClearAllPoints()
  frame:SetPoint("CENTER",UIParent,"CENTER",db.position.x,db.position.y)
 end
 -- Drag the lower-right grip to resize the meter. Snap the result to
 -- whole player rows, keeping all persisted dimensions within safe bounds.
 local resizeGrip=CreateFrame("Button",nil,frame)
 resizeGrip:SetSize(18,18)
 resizeGrip:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-1,1)
 resizeGrip:SetFrameLevel(frame:GetFrameLevel()+10)
 local gripText=resizeGrip:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 gripText:SetAllPoints(resizeGrip)
 gripText:SetText("◢")
 gripText:SetTextColor(.55,.82,.92)
 resizeGrip:RegisterForDrag("LeftButton")
 resizeGrip:SetScript("OnDragStart",function()
  if not saved().locked and frame.StartSizing then frame:StartSizing("BOTTOMRIGHT") end
 end)
 resizeGrip:SetScript("OnDragStop",function()
  if frame.StopMovingOrSizing then frame:StopMovingOrSizing() end
  local width,height=frame:GetWidth(),frame:GetHeight()
  if safeNumber(width) and safeNumber(height) then
   M.SetWidth(math.max(280,math.min(500,math.floor(width+.5))))
   M.SetRows(math.max(4,math.min(12,math.floor((height-BASE_HEIGHT)/ROW_STEP+.5))))
  end
  savePosition(frame)
 end)
 resizeGrip:SetScript("OnEnter",function(self)
  if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText("Drag to resize • /fcmeter lock");GameTooltip:Show() end
 end)
 resizeGrip:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 local trim=frame:CreateTexture(nil,"ARTWORK")
 trim:SetColorTexture(.22,.82,.96,1)
 frame.meterTrim=trim
 trim:SetPoint("TOPLEFT",1,-1)
 trim:SetPoint("TOPRIGHT",-1,-1)
 trim:SetHeight(3)
 heading=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
 heading:SetPoint("TOPLEFT",frame,"TOPLEFT",44,-11)
 heading:SetTextColor(.95,.98,1)
 heading:SetShadowOffset(1,-1)
 heading:SetShadowColor(0,0,0,.9)
 heading:SetText("Forever Companion")
 local headerIcon=frame:CreateTexture(nil,"OVERLAY")
 headerIcon:SetSize(27,27)
 headerIcon:SetPoint("TOPLEFT",frame,"TOPLEFT",9,-8)
 headerIcon:SetTexture("Interface\\Icons\\Ability_Warrior_BattleShout")
 local headerIconBorder=frame:CreateTexture(nil,"ARTWORK")
 headerIconBorder:SetPoint("TOPLEFT",headerIcon,"TOPLEFT",-2,2)
 headerIconBorder:SetPoint("BOTTOMRIGHT",headerIcon,"BOTTOMRIGHT",2,-2)
 headerIconBorder:SetColorTexture(.55,.45,.78,.8)
 headerIconBorder:SetDrawLayer("ARTWORK",-1)
 local headerDivider=frame:CreateTexture(nil,"ARTWORK")
 headerDivider:SetPoint("TOPLEFT",frame,"TOPLEFT",13,-46)
 headerDivider:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-13,-46)
 headerDivider:SetHeight(1)
 headerDivider:SetColorTexture(.18,.47,.56,.85)
 local subtitle=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 subtitle:SetPoint("TOPLEFT",frame,"TOPLEFT",44,-29)
 subtitle:SetTextColor(.54,.75,.80)
 subtitle:SetText("Damage Done  /  Current Fight")
 -- Drag by the header as well as the body; do not drag on controls.
 dragHandle=CreateFrame("Frame",nil,frame)
 dragHandle:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-4)
 dragHandle:SetSize(170,32)
 dragHandle:EnableMouse(true)
 dragHandle:RegisterForDrag("LeftButton")
 dragHandle:SetScript("OnDragStart",function() if not saved().locked then frame:StartMoving() end end)
 dragHandle:SetScript("OnDragStop",function()
  frame:StopMovingOrSizing()
  savePosition(frame)
 end)
 -- Details/Recount-style quick controls without protected combat actions.
 local smaller=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
 smaller:SetSize(22,20)
 smaller:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-47,-8)
 smaller:SetText("-")
 smaller:SetScript("OnClick",function()
  M.SetRows(math.max(4,rowCount-1))
 end)
 smaller:SetScript("OnEnter",function(self)
  if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText("Show fewer players");GameTooltip:Show() end
 end)
 smaller:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 local larger=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
 larger:SetSize(22,20)
 larger:SetPoint("LEFT",smaller,"RIGHT",2,0)
 larger:SetText("+")
 larger:SetScript("OnClick",function()
  M.SetRows(math.min(12,rowCount+1))
 end)
 larger:SetScript("OnEnter",function(self)
  if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText("Show more players");GameTooltip:Show() end
 end)
 larger:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 local skinToggle=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
 skinToggle:SetSize(48,19)
 skinToggle:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-95,-9)
 skinToggle:SetText("SKIN")
 skinToggle:SetScript("OnClick",function()
  M.SetSkin(skinName=="details" and "recount" or "details")
 end)
 skinToggle:SetScript("OnEnter",function(self)
  if GameTooltip then
   GameTooltip:SetOwner(self,"ANCHOR_TOP")
   GameTooltip:SetText("Switch visual skin")
   GameTooltip:AddLine("Details-inspired / Recount-inspired",.75,.87,.94)
   GameTooltip:Show()
  end
 end)
 skinToggle:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
 close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",2,2)
 close:SetScript("OnClick",function() M.Hide() end)
 modeButton=button(frame,"Damage",91,13,function()
  for _=1,#metrics do
   metricIndex=metricIndex%#metrics+1
   if types()~=nil then break end
  end
  saved().metric=metrics[metricIndex][1]
  M.Refresh()
 end)
 sessionButton=button(frame,"Current",92,110,function()
  for _=1,#sessions do
   sessionIndex=sessionIndex%#sessions+1
   if sessionType()~=nil then break end
  end
  pastIndex=1
  selectedRow=nil
  detailOpen=false
  saved().session=sessions[sessionIndex][1]
  M.Refresh()
 end)
 previousButton=button(frame,"<",27,13,function() pastIndex=math.min(historyCount(),pastIndex+1);selectedRow=nil;detailOpen=false;M.Refresh() end)
 nextButton=button(frame,">",27,42,function() pastIndex=math.max(1,pastIndex-1);selectedRow=nil;detailOpen=false;M.Refresh() end)
 previousButton:ClearAllPoints()
 previousButton:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-45,8)
 nextButton:ClearAllPoints()
 nextButton:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-15,8)
 local footer=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 footer:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",12,10)
 footer:SetTextColor(.72,.76,.84)
 footer:SetText("Current Fight")
 frame.meterFooter=footer
 local footerRule=frame:CreateTexture(nil,"ARTWORK")
 footerRule:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",9,30)
 footerRule:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-9,30)
 footerRule:SetHeight(1)
 footerRule:SetColorTexture(.25,.28,.35,.7)
 rows={}
 for i=1,12 do
  local row=CreateFrame("Frame",nil,frame)
  row:SetSize(windowWidth-18,ROW_HEIGHT)
  row:SetPoint("TOPLEFT",frame,"TOPLEFT",9,-70-(i-1)*ROW_STEP)
  local bg=row:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(row)
  bg:SetColorTexture(i%2==0 and .035 or .045,i%2==0 and .060 or .075,i%2==0 and .095 or .12,.97)
  local rail=row:CreateTexture(nil,"BORDER")
  rail:SetAllPoints(row)
  rail:SetColorTexture(.025,.038,.052,.95)
  local fill=CreateFrame("StatusBar",nil,row)
  fill:SetAllPoints(row)
  fill:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  fill:SetMinMaxValues(0,1)
  fill:SetValue(0)
  fill:SetStatusBarColor(.18,.72,.87,.88)
  -- Thin luminous separator and a dark value column reproduce the readable,
  -- layered combat-bar hierarchy familiar from Details and Recount.
  local separator=row:CreateTexture(nil,"OVERLAY")
  separator:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",0,0)
  separator:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",0,0)
  separator:SetHeight(1)
  separator:SetColorTexture(0,0,0,.72)
  local valueShade=row:CreateTexture(nil,"ARTWORK")
  valueShade:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
  valueShade:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",0,0)
  valueShade:SetWidth(112)
  valueShade:SetColorTexture(.008,.018,.026,.5)
  local sheen=row:CreateTexture(nil,"OVERLAY")
  sheen:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
  sheen:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
  sheen:SetHeight(2)
  sheen:SetColorTexture(1,1,1,.12)
  -- Dual-layer bar treatment: a narrow luminous top strip and subtle
  -- right-side value well make the ranking readable at a glance.
  local gloss=row:CreateTexture(nil,"OVERLAY")
  gloss:SetPoint("TOPLEFT",row,"TOPLEFT",1,-2)
  gloss:SetPoint("TOPRIGHT",row,"TOPRIGHT",-1,-2)
  gloss:SetHeight(1)
  gloss:SetColorTexture(1,1,1,.2)
  local valueDivider=row:CreateTexture(nil,"OVERLAY")
  valueDivider:SetPoint("TOPRIGHT",row,"TOPRIGHT",-111,-3)
  valueDivider:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-111,3)
  valueDivider:SetWidth(1)
  valueDivider:SetColorTexture(1,1,1,.13)
  local rank=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  rank:SetPoint("LEFT",row,"LEFT",5,0)
  rank:SetWidth(19)
  rank:SetTextColor(.74,.81,.86)
  rank:SetShadowOffset(1,-1)
  rank:SetText(i)
  local classIcon=row:CreateTexture(nil,"OVERLAY")
  classIcon:SetSize(19,19)
  classIcon:SetPoint("LEFT",row,"LEFT",26,0)
  classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
  classIcon:Hide()
  local iconBorder=row:CreateTexture(nil,"ARTWORK")
  iconBorder:SetPoint("TOPLEFT",classIcon,"TOPLEFT",-1,1)
  iconBorder:SetPoint("BOTTOMRIGHT",classIcon,"BOTTOMRIGHT",1,-1)
  iconBorder:SetColorTexture(.7,.79,.85,.55)
  iconBorder:SetDrawLayer("ARTWORK",-1)
  local name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  name:SetPoint("LEFT",row,"LEFT",51,0)
  name:SetWidth(windowWidth-160)
  name:SetJustifyH("LEFT")
  name:SetShadowOffset(1,-1)
  name:SetShadowColor(0,0,0,1)
  local amount=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  amount:SetPoint("RIGHT",row,"RIGHT",-9,0)
  amount:SetJustifyH("RIGHT")
  amount:SetShadowOffset(1,-1)
  amount:SetShadowColor(0,0,0,1)
  local accent=row:CreateTexture(nil,"OVERLAY")
  accent:SetPoint("LEFT",row,"LEFT",0,0)
  accent:SetSize(3,ROW_HEIGHT)
  accent:SetColorTexture(.18,.83,.96,1)
  local hover=row:CreateTexture(nil,"OVERLAY")
  hover:SetAllPoints(row)
  hover:SetColorTexture(.31,.82,1,.12)
  hover:Hide()
  row:EnableMouse(true)
  row:SetScript("OnEnter",function(self)
   hover:Show()
   if GameTooltip and self.sourceLabel then
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(self.sourceLabel)
    GameTooltip:AddLine("Left-click: spell breakdown",.8,.9,1)
    GameTooltip:AddLine("Right-click: next damage/healing view",.8,.9,1)
    GameTooltip:AddLine("Mouse wheel: cycle damage/healing views",.65,.85,.92)
    GameTooltip:Show()
   end
  end)
  row:SetScript("OnLeave",function()
   hover:Hide()
   if GameTooltip then GameTooltip:Hide() end
  end)
  row:EnableMouseWheel(true)
  row:SetScript("OnMouseWheel",function(_,delta)
   -- Recount-style quick metric switching, without touching combat state.
   local direction=delta>0 and -1 or 1
   for _=1,#metrics do
    metricIndex=(metricIndex-1+direction+#metrics)%#metrics+1
    if types()~=nil then break end
   end
   saved().metric=metrics[metricIndex][1]
   selectedRow=nil
   detailOpen=false
   M.Refresh()
  end)
  row:SetScript("OnMouseDown",function(_,mouseButton)
   if mouseButton=="RightButton" then
    for _=1,#metrics do
     metricIndex=metricIndex%#metrics+1
     if types()~=nil then break end
    end
    selectedRow=nil;detailOpen=false
    saved().metric=metrics[metricIndex][1]
   else
    selectedRow=(selectedRow==i) and nil or i
    detailOpen=selectedRow~=nil
   end
   M.Refresh()
  end)
  name:SetTextColor(1,1,1)
  amount:SetTextColor(1,.97,.87)
  rows[i]={frame=row,fill=fill,name=name,amount=amount,accent=accent,background=bg,classIcon=classIcon,rail=rail}
  if i>rowCount then row:Hide() end
 end
 detailLabel=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 detailLabel:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",9,29)
 detailLabel:SetWidth(windowWidth-26)
 detailLabel:SetJustifyH("LEFT")
 detailLabel:SetTextColor(.98,.78,.45)
 detailLabel:SetText("Select a player row for details")
 notice=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 notice:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",9,12)
 notice:SetWidth(windowWidth-100)
 notice:SetTextColor(.65,.76,.84)
 frame:SetScript("OnUpdate",function(_,dt)
  elapsed=elapsed+dt
  if elapsed>=.4 then elapsed=0;M.Refresh() end
 end)
 detailPanel=CreateFrame("Frame",nil,frame,"BackdropTemplate")
 detailPanel:SetSize(340,120+8*27)
 detailPanel:SetPoint("TOPLEFT",frame,"TOPRIGHT",5,0)
 if detailPanel.SetBackdrop then
  detailPanel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  detailPanel:SetBackdropColor(.035,.055,.085,.96)
  detailPanel:SetBackdropBorderColor(.66,.48,.23,1)
 end
 detailTitle=detailPanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
 detailTitle:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",12,-12)
 detailTitle:SetText("PLAYER  /  DAMAGE DONE")
 detailClose=CreateFrame("Button",nil,detailPanel,"UIPanelCloseButton")
 detailClose:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",2,2)
 detailClose:SetScript("OnClick",function() detailOpen=false;selectedRow=nil;M.Refresh() end)
 -- Screenshot-inspired tab strip. Only Spells is populated from verified
 -- native breakdown data; unsupported views are explicitly labeled.
 local tabNames={"Spells","Auras","Targets","Compare"}
 for i,tabName in ipairs(tabNames) do
  local tab=CreateFrame("Button",nil,detailPanel,"UIPanelButtonTemplate")
  tab:SetSize(77,24)
  tab:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",9+(i-1)*81,-32)
  tab:SetText(tabName)
  tab:SetScript("OnClick",function()
   detailTab=tabName
   M.Refresh()
  end)
  detailTabs[i]=tab
 end
 local detailTrim=detailPanel:CreateTexture(nil,"ARTWORK")
 detailTrim:SetColorTexture(.85,.62,.29,1)
 detailTrim:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",1,-1)
 detailTrim:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-1,-1)
 detailTrim:SetHeight(3)
 for i=1,8 do
  local stripe=detailPanel:CreateTexture(nil,"BACKGROUND")
  stripe:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",8,-66-(i-1)*27)
  stripe:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-8,-31-(i-1)*23)
  stripe:SetHeight(25)
  stripe:SetColorTexture(i%2==0 and .045 or .065,i%2==0 and .075 or .095,i%2==0 and .105 or .135,.85)
  local spellTrack=detailPanel:CreateTexture(nil,"BORDER")
  spellTrack:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",34,-88-(i-1)*27)
  spellTrack:SetSize(285,3)
  spellTrack:SetColorTexture(.24,.14,.29,.8)
  local icon=detailPanel:CreateTexture(nil,"ARTWORK")
  icon:SetSize(17,17)
  icon:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",12,-69-(i-1)*27)
  icon:Hide()
  local label=detailPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  label:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",34,-70-(i-1)*27)
  label:SetWidth(194)
  label:SetJustifyH("LEFT")
  local value=detailPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  value:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-12,-70-(i-1)*27)
  value:SetWidth(95)
  value:SetJustifyH("RIGHT")
  detailRows[i]={label=label,value=value,icon=icon}
 end
 detailPanel:Hide()
 frame:Hide()
 M.SetSkin(skinName)
end
function M.SetSkin(name)
 if type(name)~="string" then return false end
 name=name:lower()
 if not skins[name] then return false end
 skinName=name
 saved().skin=name
 if frame then
  local style=skin()
  if frame.SetBackdropColor then frame:SetBackdropColor(unpack(style.background)) end
  if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(unpack(style.border)) end
  if frame.meterTrim then frame.meterTrim:SetColorTexture(unpack(style.accent)) end
  if heading then heading:SetText("Forever Companion") end
  for _,entry in ipairs(rows or {}) do
   entry.fill:SetStatusBarTexture(style.texture)
   entry.rail:SetColorTexture(unpack(style.rail))
  end
 end
 M.Refresh()
 return true
end
function M.Refresh()
 if not frame or not frame:IsShown() then return end
 modeButton:SetText(metrics[metricIndex][1])
 sessionButton:SetText(sessions[sessionIndex][1])
 if frame.meterFooter then
  frame.meterFooter:SetText(sessions[sessionIndex][1].." Fight  /  "..metrics[metricIndex][1])
 end
 local isPast=sessionIndex==2
 previousButton:SetShown(isPast)
 nextButton:SetShown(isPast)
 previousButton:SetEnabled(isPast and type(C_DamageMeter)=="table" and type(C_DamageMeter.GetAvailableCombatSessions)=="function" and pastIndex<historyCount())
 nextButton:SetEnabled(isPast and pastIndex>1)
 if detailPanel then detailPanel:SetShown(detailOpen and selectedRow~=nil) end
 if not M.Available() then
  if detailPanel then detailPanel:Hide() end
  selectedRow=nil
  detailOpen=false
  if detailLabel then detailLabel:SetText("Select a player row for details") end
  for _,row in ipairs(rows) do row.frame:Hide() end
  notice:SetText("Blizzard combat meter API unavailable")
  return
 end
 local data
 if isPast then
  local canReadHistory=type(C_DamageMeter.GetCombatSessionFromID)=="function" and type(C_DamageMeter.GetAvailableCombatSessions)=="function"
  if canReadHistory then
   local history=availableHistory()
   if pastIndex>#history then pastIndex=math.max(1,#history);selectedRow=nil;detailOpen=false end
   local id=historyID(history[pastIndex])
   if id~=nil then data=read(C_DamageMeter.GetCombatSessionFromID,id,types()) end
   if #history==0 then data=read(C_DamageMeter.GetCombatSessionFromType,sessionType(),types()) end
  else
   -- The native Expired session is the only supported history fallback.
   data=read(C_DamageMeter.GetCombatSessionFromType,sessionType(),types())
  end
 else
  data=read(C_DamageMeter.GetCombatSessionFromType,sessionType(),types())
 end
 local sources=type(data)=="table" and data.combatSources
 if type(sources)~="table" then sources={} end
 if selectedRow and selectedRow>rowCount then selectedRow=nil;detailOpen=false end
 local colors=RAID_CLASS_COLORS or {}
 for i,row in ipairs(rows) do
  local source=i<=rowCount and sources[i]
  if type(source)=="table" then
   row.frame:Show()
   local displayName=source.name
   if not (issecretvalue and issecretvalue(displayName)) and type(displayName)=="string" then
    row.frame.sourceLabel=displayName
   else row.frame.sourceLabel=nil end
   if selectedRow==i then row.background:SetColorTexture(.075,.19,.23,.98)
   elseif not (issecretvalue and issecretvalue(source.isLocalPlayer)) and source.isLocalPlayer==true then
    row.background:SetColorTexture(.13,.16,.08,.98)
   else row.background:SetColorTexture(i%2==0 and .035 or .045,i%2==0 and .060 or .075,i%2==0 and .095 or .12,.97) end
   -- Direct display is permitted for secret strings/numbers; do not format or compare them.
   -- No Lua boolean tests, comparisons or formatting on secret source values.
   row.name:SetText(source.name)
   if metrics[metricIndex][2]=="Dps" or metrics[metricIndex][2]=="Hps" then
    row.amount:SetText(source.amountPerSecond)
   else
    row.amount:SetText(source.totalAmount)
   end
   -- Use only NeverSecret class metadata for class color.
   local class=source.classFilename
   local icon=row.classIcon
   local spec=source.specIconID
   if not (issecretvalue and issecretvalue(spec)) and type(spec)=="number" and spec>0 then
    icon:SetTexture(spec)
    icon:SetTexCoord(0,1,0,1)
    icon:Show()
   else
    local coords=not (issecretvalue and issecretvalue(class)) and type(class)=="string"
     and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if coords then
     icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
     icon:SetTexCoord(coords[1],coords[2],coords[3],coords[4])
     icon:Show()
    else icon:Hide() end
   end
   local color
   if not (issecretvalue and issecretvalue(class)) and type(class)=="string" then color=colors[class] end
   if color then
    row.fill:SetStatusBarColor(color.r,color.g,color.b,skin().barAlpha)
    row.accent:SetColorTexture(color.r,color.g,color.b,1)
   else
    row.fill:SetStatusBarColor(.18,.72,.87,.68)
    row.accent:SetColorTexture(.18,.83,.96,1)
   end
   -- In-combat percentage may be secret. Avoid Lua arithmetic entirely.
   -- The session may omit a maximum; only pass known-safe values to the bar.
   -- Blizzard's combat session provides the shared maximum for all sources.
   -- A per-source maximum can make every player's bar appear full.
   -- Pass secret numeric values only to secret-safe native status-bar methods.
   local maximum=data and data.maxAmount
   if (issecretvalue and issecretvalue(maximum)) or maximum~=nil then
    row.fill:SetMinMaxValues(0,maximum)
    row.fill:SetValue(source.totalAmount)
   else
    row.fill:SetMinMaxValues(0,1)
    row.fill:SetValue(0)
   end
  else row.frame.sourceLabel=nil;row.frame:Hide() end
 end
 if selectedRow then
  local selected=sources[selectedRow]
  if type(selected)=="table" then
   detailLabel:SetText(selected.name)
  else selectedRow=nil;detailOpen=false;detailLabel:SetText("Select a player row for details") end
 else detailLabel:SetText("Select a player row for details") end
 if detailPanel then detailPanel:SetShown(detailOpen and selectedRow~=nil) end
 if detailPanel and detailOpen and selectedRow then
  -- Keep the details readable when the meter is docked near the right edge.
  if not (InCombatLockdown and InCombatLockdown()) and frame.GetRight and UIParent and UIParent.GetRight then
   local right,screenRight=frame:GetRight(),UIParent:GetRight()
   if safeNumber(right) and safeNumber(screenRight) then
    local side=(screenRight-right)<300 and "LEFT" or "RIGHT"
    if detailPanel.anchorSide~=side then
     detailPanel:ClearAllPoints()
     if side=="LEFT" then
      detailPanel:SetPoint("TOPRIGHT",frame,"TOPLEFT",-5,0)
     else
      detailPanel:SetPoint("TOPLEFT",frame,"TOPRIGHT",5,0)
     end
     detailPanel.anchorSide=side
    end
   end
  end
  local selected=sources[selectedRow]
  if type(selected)=="table" then
   local selectedName=selected.name
   if not (issecretvalue and issecretvalue(selectedName)) and type(selectedName)=="string" then
    detailTitle:SetText(selectedName.."  /  "..metrics[metricIndex][1])
   end
  end
  local safeToInspect=not (InCombatLockdown and InCombatLockdown())
  local breakdown
  if safeToInspect and type(selected)=="table" and type(C_DamageMeter)=="table" then
   local guid=selected.sourceGUID
   local creatureID=selected.sourceCreatureID
   if not (issecretvalue and issecretvalue(guid)) and not (issecretvalue and issecretvalue(creatureID)) then
    if isPast and type(C_DamageMeter.GetCombatSessionSourceFromID)=="function" then
     local entry=availableHistory()[pastIndex]
     local sessionID=historyID(entry)
     if sessionID~=nil then
      breakdown=read(C_DamageMeter.GetCombatSessionSourceFromID,sessionID,types(),guid,creatureID)
     end
    else
     breakdown=read(C_DamageMeter.GetCombatSessionSourceFromType,sessionType(),types(),guid,creatureID)
    end
   end
  end
  local spells=type(breakdown)=="table" and breakdown.combatSpells
  detailTitle:SetText(detailTab=="Spells" and
   (safeToInspect and "PLAYER  /  SPELL DAMAGE" or "PLAYER  /  AFTER COMBAT")
   or ("PLAYER  /  "..detailTab:upper()))
  for _,tab in ipairs(detailTabs) do
   local active=tab:GetText()==detailTab
   tab:GetFontString():SetTextColor(active and 1 or .65,active and .82 or .72,active and .98 or .8)
  end
  for i,item in ipairs(detailRows) do
   local spell=detailTab=="Spells" and type(spells)=="table" and spells[i]
   if type(spell)=="table" then
    local spellID=spell.spellID
    if issecretvalue and issecretvalue(spellID) then spellID=nil end
    local info
    if type(spellID)=="number" and C_Spell and type(C_Spell.GetSpellInfo)=="function" then
     info=read(C_Spell.GetSpellInfo,spellID)
    end
    item.label:SetText((type(info)=="table" and info.name) or ("Spell "..tostring(spellID or i)))
    local iconID=type(info)=="table" and info.iconID
    if not (issecretvalue and issecretvalue(iconID)) and type(iconID)=="number" and iconID>0 then
     item.icon:SetTexture(iconID)
     item.icon:Show()
    else item.icon:Hide() end
    item.value:SetText(spell.totalAmount)
   else
    item.label:SetText(i==1 and (detailTab~="Spells" and "Not available from native meter" or (safeToInspect and "No spell data available" or "Available after combat")) or "")
    item.value:SetText("")
    item.icon:Hide()
   end
  end
 end
 if isPast then
  local entry=availableHistory()[pastIndex]
  local title=type(entry)=="table" and entry.name
  if not (issecretvalue and issecretvalue(title)) and type(title)=="string" and title~="" then
   notice:SetText(title:sub(1,36))
  else
   notice:SetText("Past fight "..pastIndex.." | Native history")
  end
 else
  notice:SetText(#sources==0 and "Waiting for Blizzard combat data" or "Native data  |  Experimental")
 end
end
function M.SelectedRow()
 -- Expose only the selected ranking index, never protected combat data.
 return selectedRow
end
M.SelectedSource=M.SelectedRow -- Compatibility with existing callers.
function M.Show()
 if not frame then build() end
 saved().visible=true
 frame:Show()
 M.Refresh()
end
function M.Hide()
 saved().visible=false
 if frame then frame:Hide() end
 if detailPanel then detailPanel:Hide() end
end
function M.Toggle()
 if frame and frame:IsShown() then M.Hide() else M.Show() end
end
function M.SetWidth(width)
 if issecretvalue and issecretvalue(width) then return false end
 if type(width)~="number" or width~=width or width==math.huge or width==-math.huge or width~=math.floor(width) or width<280 or width>500 then return false end
 saved().width=width
 windowWidth=width
 if frame then
  frame:SetWidth(width)
  notice:SetWidth(width-100)
  for _,row in ipairs(rows) do
   row.frame:SetWidth(width-18)
   row.name:SetWidth(width-160)
  end
  if detailLabel then detailLabel:SetWidth(width-26) end

 end
 M.Refresh()
 return true
end
function M.SetRows(count)
 if issecretvalue and issecretvalue(count) then return false end
 if type(count)~="number" or count~=count or count==math.huge or count==-math.huge or count~=math.floor(count) or count<4 or count>12 then return false end
 saved().rows=count
 rowCount=count
 if selectedRow and selectedRow>rowCount then selectedRow=nil;detailOpen=false end
 if frame then frame:SetHeight(BASE_HEIGHT+rowCount*ROW_STEP) end
 M.Refresh()
 return true
end
-- Named layout presets keep the meter usable on small screens without
-- changing the underlying Blizzard damage data or class colors.
function M.SetLayout(layout)
 if layout~="compact" and layout~="standard" and layout~="expanded" then return false end
 local width,count
 if layout=="compact" then width,count=280,4
 elseif layout=="standard" then width,count=320,8
 else width,count=440,12 end
 M.SetWidth(width)
 M.SetRows(count)
 saved().layout=layout
 return true
end
function M.SetSession(mode)
 local enums=Enum and Enum.DamageMeterSessionType
 for i,item in ipairs(sessions) do
  if item[1]:lower()==tostring(mode):lower() then
   if type(enums)~="table" or enums[item[2]]==nil then return false end
   sessionIndex=i;pastIndex=1;selectedRow=nil;detailOpen=false;saved().session=item[1];M.Refresh()
   return true
  end
 end
 return false
end
function M.SetMode(mode)
 local enums=Enum and Enum.DamageMeterType
 for i,item in ipairs(metrics) do
  if item[1]:lower()==tostring(mode):lower() then
   if type(enums)~="table" or enums[item[2]]==nil then return false end
   metricIndex=i;selectedRow=nil;detailOpen=false;saved().metric=item[1];M.Refresh()
   return true
  end
 end
 return false
end
SLASH_FOREVERCOMPANIONMETER1="/fcmeter"
SlashCmdList.FOREVERCOMPANIONMETER=function(msg)
 msg=(msg or ""):lower():match("^%s*(.-)%s*$")
 if msg=="hide" or msg=="off" then M.Hide()
 elseif msg=="show" or msg=="on" then M.Show()
 elseif msg=="lock" then saved().locked=true
 elseif msg=="unlock" then saved().locked=false
 elseif msg=="compact" or msg=="standard" or msg=="expanded" then
  M.SetLayout(msg)
  M.Show()
 elseif msg=="skin details" or msg=="skin recount" then
  M.SetSkin(msg:match("^skin%s+(%w+)$"))
  M.Show()
 elseif msg=="details" then
  if selectedRow then detailOpen=not detailOpen;M.Refresh() else M.Show() end
 elseif msg=="resetpos" then
  saved().position=nil
  if frame then frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"CENTER",330,0) end
 elseif msg:match("^width%s+") then
  local width=tonumber(msg:match("^width%s+(%d+)$"))
  if width and M.SetWidth(width) then M.Show() end
 elseif msg:match("^rows%s+") then
  local count=tonumber(msg:match("^rows%s+(%d+)$"))
  if count and M.SetRows(count) then M.Show() end
 elseif msg=="" or msg=="toggle" then M.Toggle()
 elseif M.SetSession(msg) or M.SetMode(msg) then M.Show()
 end
end
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
for _,event in ipairs({"DAMAGE_METER_COMBAT_SESSION_UPDATED","DAMAGE_METER_CURRENT_SESSION_UPDATED","DAMAGE_METER_RESET"}) do
 pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,name)
 if event=="ADDON_LOADED" and name=="ForeverCompanion" and saved().visible then M.Show()
 elseif event~="ADDON_LOADED" then M.Refresh() end
end)
