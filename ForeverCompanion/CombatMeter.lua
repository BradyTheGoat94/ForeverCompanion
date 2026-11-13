-- Forever Companion Combat Meter (experimental, native C_DamageMeter only).
-- No combat log listeners, gameplay automation, or arithmetic on secret values.
local M={}
ForeverCompanionCombatMeter=M
local frame,rows,heading,notice,modeButton,sessionButton,previousButton,nextButton,dragHandle
local pastIndex=1
local rowOffset,sourceCount=0,0
local optionsButton
local metricNames={DPS="Damage / DPS",Damage="Damage Done",HPS="Healing / HPS",Healing="Healing Done",Absorbs="Absorbs",Interrupts="Interrupts",Dispels="Dispels",Taken="Damage Taken"}
local rowCount=8
local ROW_HEIGHT=20
local ROW_STEP=21
local BASE_HEIGHT=50
local ROW_TOP=26
local windowWidth=320
local selectedRow,selectedSourceKey=nil,nil
local detailOpen=false
local detailRows={}
local detailPanel,detailTitle,detailClose,detailEmpty,detailMessage
local detailSummary={}
local detailTabs={}
local detailTab="Spells"
local spellPage=1
local spellPageLabel
local spellQuery=''
local emptyTitle,emptyBody
local detailLabel
local metricIndex,sessionIndex=1,1
local metrics={{"DPS","Dps"},{"Damage","DamageDone"},{"HPS","Hps"},{"Healing","HealingDone"},{"Absorbs","Absorbs"},{"Interrupts","Interrupts"},{"Dispels","Dispels"},{"Taken","DamageTaken"}}
local sessions={{"Current","Current"},{"Past","Expired"},{"Overall","Overall"}}
local skins={
 details={background={.016,.016,.018,.96},border={.17,.17,.19,1},accent={.65,.65,.68,1},rail={.035,.035,.04,.95},barAlpha=.92,texture="Interface\\TargetingFrame\\UI-StatusBar"},
 recount={background={.028,.023,.032,.98},border={.43,.32,.20,1},accent={.98,.67,.22,1},rail={.075,.045,.065,.96},barAlpha=.83,texture="Interface\\Buttons\\WHITE8X8"}
}
local skinName="details"
local function skin() return skins[skinName] or skins.details end
local elapsed=0
local controls={}
local function flatButton(parent)
 local b=ForeverCompanionInterface.Button(parent,skin())
 controls[#controls+1]=b
 return b
end
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
function M.GetUpdateInterval()
 local value=saved().updateInterval
 return safeNumber(value) and (value==.2 or value==.4 or value==.8) and value or .4
end
function M.SetUpdateInterval(value)
 if not safeNumber(value) or (value~=.2 and value~=.4 and value~=.8) then return false end
 saved().updateInterval=value;elapsed=0;M.Refresh();return true
end
-- Compact only inspectable numbers. Secret values retain their native identity
-- and pass directly to FontString:SetText without conversion or arithmetic.
function M.DisplayAmount(value)
 if not safeNumber(value) then return value end
 local magnitude=math.abs(value)
 local divisor,suffix=1,''
 if magnitude>=999950000 then divisor,suffix=1000000000,'b'
 elseif magnitude>=999950 then divisor,suffix=1000000,'m'
 elseif magnitude>=1000 then divisor,suffix=1000,'k' end
 if divisor>1 then return (string.format('%.1f',value/divisor):gsub('%.0$',''))..suffix end
 return string.format(magnitude<100 and value~=math.floor(value) and '%.1f' or '%.0f',value)
end
function M.ExactAmount(value)
 if not safeNumber(value) then return nil end
 if value==math.floor(value) then return string.format('%.0f',value) end
 return tostring(value)
end
function M.SourceKey(source)
 if type(source)~='table' then return end
 local guid=source.sourceGUID
 if not (issecretvalue and issecretvalue(guid)) and type(guid)=='string' and guid~='' then return 'guid:'..guid end
 local creature=source.sourceCreatureID
 if safeNumber(creature) and creature>0 then return 'creature:'..tostring(creature) end
end
-- Only public names participate in search/sort; never stringify secret values.
function M.SpellLabel(spell,index)
 local id=spell.spellID
 if issecretvalue and issecretvalue(id) then id=nil end
 local info=type(id)=='number' and C_Spell and read(C_Spell.GetSpellInfo,id)
 local name=type(info)=='table' and info.name
 if (issecretvalue and issecretvalue(name)) or type(name)~='string' or name=='' then name='Spell '..tostring(type(id)=='number' and id or index or '?') end
 local creature=spell.creatureName
 local named=not (issecretvalue and issecretvalue(creature)) and type(creature)=='string' and creature~=''
 local details=spell.combatSpellDetails
 local flag=not (issecretvalue and issecretvalue(details)) and type(details)=='table' and details.isPet
 local pet=named or (not (issecretvalue and issecretvalue(flag)) and flag==true)
 if named then name=name..' ('..creature..')' elseif pet and name=='Attack' then name='Pet Attack' end
 return name,pet,info
end
function M.FilterSpells(spells,query,filter,order)
 local result={};query=type(query)=='string' and query:lower() or ''
 local sortable=true
 for index,spell in ipairs(spells or {}) do
  if type(spell)=='table' then
   local name,pet=M.SpellLabel(spell,index)
   if (filter~='pets' or pet) and (query=='' or name:lower():find(query,1,true)) then
    result[#result+1]={spell=spell,name=name,index=index}
    if not safeNumber(spell.totalAmount) then sortable=false end
   end
  end
 end
 if order=='name' then table.sort(result,function(a,b) if a.name~=b.name then return a.name<b.name end;return a.index<b.index end)
 elseif order~='native' and sortable then table.sort(result,function(a,b) if a.spell.totalAmount~=b.spell.totalAmount then return a.spell.totalAmount>b.spell.totalAmount end;return a.index<b.index end) end
 local output={};for i,entry in ipairs(result) do output[i]=entry.spell end
 return output
end
function M.SetSpellQuery(query)
 if (issecretvalue and issecretvalue(query)) or type(query)~='string' then return false end
 spellQuery=query:sub(1,120);spellPage=1;M.Refresh();return true
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
 frame.resizeGrip=resizeGrip
 resizeGrip:SetSize(18,18)
 resizeGrip:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-1,1)
 resizeGrip:SetFrameLevel(frame:GetFrameLevel()+10)
 -- Geometric resize grip avoids font-dependent Unicode symbols.
 for i=1,3 do
  local stroke=resizeGrip:CreateTexture(nil,"ARTWORK")
  stroke:SetSize(1,4+i*3)
  stroke:SetPoint("BOTTOMRIGHT",resizeGrip,"BOTTOMRIGHT",-3-(i-1)*4,3)
  stroke:SetColorTexture(.48,.60,.70,.8)
  stroke:SetRotation(-math.pi/4)
 end
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
 -- Compact title bar: native artwork and independently implemented controls.
 local header=frame:CreateTexture(nil,"BACKGROUND")
 header:SetPoint("TOPLEFT",1,-1);header:SetPoint("TOPRIGHT",-1,-1);header:SetHeight(23)
 header:SetColorTexture(.065,.065,.07,.98)
 local trim=frame:CreateTexture(nil,"BORDER")
 trim:SetPoint("TOPLEFT",0,0);trim:SetPoint("TOPRIGHT",0,0);trim:SetHeight(1)
 trim:SetColorTexture(.25,.25,.27,1);frame.meterTrim=trim
 heading=ForeverCompanionInterface.Text(frame,12)
 heading:SetPoint("TOPLEFT",frame,"TOPLEFT",8,-5);heading:SetWidth(windowWidth-124)
 heading:SetHeight(16);heading:SetText("Damage / DPS")
 dragHandle=CreateFrame("Frame",nil,frame)
 dragHandle:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-2);dragHandle:SetSize(windowWidth-120,21)
 dragHandle:EnableMouse(true);dragHandle:RegisterForDrag("LeftButton")
 dragHandle:SetScript("OnDragStart",function() if not saved().locked then frame:StartMoving() end end)
 dragHandle:SetScript("OnDragStop",function() frame:StopMovingOrSizing();savePosition(frame) end)
 dragHandle:SetScript("OnMouseUp",function(_,key)
  if key=="RightButton" then
   if IsShiftKeyDown and IsShiftKeyDown() then M.OpenSessions(dragHandle) else M.OpenMetrics(dragHandle) end
  end
 end)
 dragHandle:SetScript("OnEnter",function(self)
  if GameTooltip then
   GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText("Forever Companion meter")
   GameTooltip:AddLine("Drag to move. Right-click for displays.",.8,.85,.9)
   GameTooltip:AddLine("Shift + right-click for combat segments.",.8,.85,.9);GameTooltip:Show()
  end
 end)
 dragHandle:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
 local function tool(offset,texture,title,description,callback)
  local b=flatButton(frame);b:SetSize(19,19);b:SetPoint("TOPRIGHT",frame,"TOPRIGHT",offset,-3)
  b:SetFrameLevel(dragHandle:GetFrameLevel()+2)
  if texture then
   local icon=b:CreateTexture(nil,"ARTWORK");icon:SetSize(15,15);icon:SetPoint("CENTER",b,"CENTER",0,0)
   icon:SetTexture(texture);icon:SetTexCoord(.08,.92,.08,.92)
  else b:SetText("x") end
  b:SetScript("OnClick",callback)
  b:SetScript("OnEnter",function(self)
   if GameTooltip then GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(title);GameTooltip:AddLine(description,.8,.85,.9,true);GameTooltip:Show() end
  end)
  b:SetScript("OnLeave",function() if GameTooltip then GameTooltip:Hide() end end)
  return b
 end
 modeButton=tool(-67,"Interface\\Icons\\Ability_Warrior_SavageBlow","Displays","Choose damage, DPS, healing and utility views.",function() M.OpenMetrics(modeButton) end)
 local reset=tool(-88,"Interface\\Icons\\Spell_Holy_Renew","Reset combat data","Opens a confirmation. Clears all sessions in Blizzard's native meter too.",function() M.RequestReset(frame.resetButton) end)
 sessionButton=tool(-46,"Interface\\Icons\\INV_Misc_PocketWatch_01","Combat segments","Choose current, overall or a recorded combat segment.",function() M.OpenSessions(sessionButton) end)
 optionsButton=tool(-25,"Interface\\Icons\\INV_Misc_Gear_01","Meter options","Layouts, text size, columns, skins and position lock.",function() M.OpenOptions(optionsButton) end)
 tool(-4,nil,"Close meter","Reopen with /fcmeter or the dashboard.",function() M.Hide() end)
 frame.metricButton=modeButton;frame.sessionButton=sessionButton;frame.optionsButton=optionsButton;frame.resetButton=reset
 frame:EnableMouseWheel(true)
 frame:SetScript("OnMouseWheel",function(_,delta) M.Scroll(-delta) end)
 frame:SetScript("OnMouseUp",function(_,key) if key=="RightButton" then M.OpenQuickMenu(frame) end end)
 previousButton=flatButton(frame);previousButton:SetSize(16,17);previousButton:SetText("<")
 previousButton:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-36,3)
 previousButton:SetScript("OnClick",function() M.SelectPast(pastIndex+1) end)
 nextButton=flatButton(frame);nextButton:SetSize(16,17);nextButton:SetText(">")
 nextButton:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-19,3)
 nextButton:SetScript("OnClick",function() M.SelectPast(pastIndex-1) end)
 local footer=ForeverCompanionInterface.Text(frame,10)
 footer:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",6,5);footer:SetWidth(windowWidth-68)
 footer:SetTextColor(.7,.72,.76);frame.meterFooter=footer
 local range=ForeverCompanionInterface.Text(frame,10)
 range:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-19,5);range:SetWidth(70);range:SetJustifyH("RIGHT")
 frame.playerRange=range
 detailLabel=ForeverCompanionInterface.Text(frame,10);detailLabel:Hide()
 notice=ForeverCompanionInterface.Text(frame,10);notice:Hide()
 local footerRule=frame:CreateTexture(nil,"BORDER")
 footerRule:SetPoint("BOTTOMLEFT",0,23);footerRule:SetPoint("BOTTOMRIGHT",0,23);footerRule:SetHeight(1)
 footerRule:SetColorTexture(.17,.17,.19,1)
 rows={}
 for i=1,12 do
  local row=CreateFrame("Frame",nil,frame)
  row:SetSize(windowWidth-8,ROW_HEIGHT)
  row:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-ROW_TOP-(i-1)*ROW_STEP)
  local bg=row:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(row)
  bg:SetColorTexture(i%2==0 and .035 or .045,i%2==0 and .060 or .075,i%2==0 and .095 or .12,.97)
  local rail=row:CreateTexture(nil,"BORDER")
  rail:SetAllPoints(row)
  rail:SetColorTexture(.025,.038,.052,.95)
  local fill=CreateFrame("StatusBar",nil,row)
  fill:SetAllPoints(row)
  fill:EnableMouse(false)
  fill:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  fill:SetMinMaxValues(0,1)
  fill:SetValue(0)
  fill:SetStatusBarColor(.18,.72,.87,.88)
  -- Thin luminous separator and a dark value column reproduce the readable,
  -- layered combat-bar hierarchy familiar from Details and Recount.
  local content=CreateFrame("Frame",nil,row)
  content:SetAllPoints(row)
  content:SetFrameLevel(fill:GetFrameLevel()+1)
  local separator=content:CreateTexture(nil,"OVERLAY")
  separator:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",0,0)
  separator:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",0,0)
  separator:SetHeight(1)
  separator:SetColorTexture(0,0,0,.72)
  local valueShade=content:CreateTexture(nil,"ARTWORK")
  valueShade:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
  valueShade:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",0,0)
  valueShade:SetWidth(132)
  valueShade:SetColorTexture(0,0,0,.28)
  -- Readable text well over vivid class bars; preserve the class-colored fill.
  local nameShade=content:CreateTexture(nil,"OVERLAY")
  nameShade:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
  nameShade:SetPoint("BOTTOMRIGHT",valueShade,"BOTTOMLEFT",0,0)
  nameShade:SetColorTexture(0,0,0,.2)
  local sheen=content:CreateTexture(nil,"OVERLAY")
  sheen:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
  sheen:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,0)
  sheen:SetHeight(2)
  sheen:SetColorTexture(1,1,1,.06)
  -- Dual-layer bar treatment: a narrow luminous top strip and subtle
  -- right-side value well make the ranking readable at a glance.
  local gloss=content:CreateTexture(nil,"OVERLAY")
  gloss:SetPoint("TOPLEFT",row,"TOPLEFT",1,-2)
  gloss:SetPoint("TOPRIGHT",row,"TOPRIGHT",-1,-2)
  gloss:SetHeight(1)
  gloss:SetColorTexture(1,1,1,.08)
  local valueDivider=content:CreateTexture(nil,"OVERLAY")
  valueDivider:SetPoint("TOPRIGHT",row,"TOPRIGHT",-111,-3)
  valueDivider:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-111,3)
  valueDivider:SetWidth(1)
  valueDivider:SetColorTexture(1,1,1,0)
  local rank=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  rank:SetPoint("LEFT",row,"LEFT",2,0)
  rank:SetWidth(15)
  rank:SetTextColor(.9,.94,.98)
  rank:SetShadowOffset(1,-1)
  rank:SetText(i)
  local classIcon=content:CreateTexture(nil,"OVERLAY")
  classIcon:SetSize(17,17)
  classIcon:SetPoint("LEFT",row,"LEFT",19,0)
  classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
  classIcon:Hide()
  local iconBorder=content:CreateTexture(nil,"ARTWORK")
  iconBorder:SetPoint("TOPLEFT",classIcon,"TOPLEFT",-1,1)
  iconBorder:SetPoint("BOTTOMRIGHT",classIcon,"BOTTOMRIGHT",1,-1)
  iconBorder:SetColorTexture(.7,.79,.85,.55)
  iconBorder:SetDrawLayer("ARTWORK",-1)
  local name=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  name:SetPoint("LEFT",row,"LEFT",38,0)
  name:SetWidth(windowWidth-182)
  name:SetJustifyH("LEFT")
  name:SetShadowOffset(1,-1)
  name:SetShadowColor(0,0,0,1)
  name:SetFontObject("GameFontHighlightSmall")
  name:SetWordWrap(false)
  name:SetHeight(18)
  local amount=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  amount:SetPoint("RIGHT",row,"RIGHT",-9,0)
  amount:SetWidth(120)
  amount:SetFontObject("GameFontHighlightSmall")
  amount:SetWordWrap(false)
  amount:SetHeight(18)
  amount:SetJustifyH("RIGHT")
  amount:SetShadowOffset(1,-1)
  amount:SetTextColor(1,1,1,1)
  amount:SetShadowColor(0,0,0,1)
  local rate=content:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  rate:SetPoint("RIGHT",row,"RIGHT",-4,0);rate:SetWidth(58);rate:SetHeight(18)
  rate:SetJustifyH("RIGHT");rate:SetWordWrap(false);rate:SetTextColor(.9,.9,.9)
  rate:SetShadowOffset(1,-1);rate:SetShadowColor(0,0,0,1)
  local accent=content:CreateTexture(nil,"OVERLAY")
  accent:SetPoint("LEFT",row,"LEFT",0,0)
  accent:SetSize(3,ROW_HEIGHT)
  accent:SetColorTexture(.18,.83,.96,1)
  local hover=content:CreateTexture(nil,"OVERLAY")
  hover:SetAllPoints(row)
  hover:SetColorTexture(.31,.82,1,.12)
  hover:Hide()
  local selection=content:CreateTexture(nil,'OVERLAY')
  selection:SetPoint('BOTTOMLEFT',row,'BOTTOMLEFT',0,0);selection:SetPoint('BOTTOMRIGHT',row,'BOTTOMRIGHT',0,0)
  selection:SetHeight(1);selection:SetColorTexture(1,1,1,.75);selection:Hide()
  row:EnableMouse(true)
  row:SetScript("OnEnter",function(self)
   hover:Show()
   if GameTooltip and self.sourceLabel then
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:SetText(self.sourceLabel)
    local total=M.ExactAmount(self.totalAmount)
    local rate=M.ExactAmount(self.amountPerSecond)
    if total then GameTooltip:AddLine('Total: '..total,.94,.96,1) end
    if rate then GameTooltip:AddLine('Per second: '..rate,.94,.96,1) end
    if saved().showBoth~=false then GameTooltip:AddLine('Right columns: total | per second',.7,.8,.86) end
    GameTooltip:AddLine("Left-click: spell breakdown",.8,.9,1)
    GameTooltip:AddLine("Right-click: quick displays and options",.8,.9,1)
    GameTooltip:AddLine("Wheel: scroll players. Ctrl + wheel: change display.",.65,.85,.92)
    GameTooltip:Show()
   end
  end)
  row:SetScript("OnLeave",function()
   hover:Hide()
   if GameTooltip then GameTooltip:Hide() end
  end)
  row:EnableMouseWheel(true)
  row:SetScript("OnMouseWheel",function(_,delta)
   if IsControlKeyDown and IsControlKeyDown() then M.CycleMetric(delta>0 and -1 or 1)
   else M.Scroll(-delta) end
  end)
  row:SetScript("OnMouseDown",function(_,mouseButton)
   if mouseButton=="RightButton" then
    M.OpenQuickMenu(rows[i].frame);return
   else
    selectedRow=(selectedRow==rows[i].frame.sourceIndex) and nil or rows[i].frame.sourceIndex
    selectedSourceKey=selectedRow and rows[i].frame.sourceKey or nil
    spellPage=1
    detailOpen=selectedRow~=nil
   end
   M.Refresh()
  end)
  name:SetTextColor(1,1,1)
  amount:SetTextColor(1,1,1)
  rows[i]={frame=row,fill=fill,name=name,amount=amount,accent=accent,background=bg,classIcon=classIcon,rail=rail,rank=rank,rate=rate,valueShade=valueShade,selection=selection}
  if i>rowCount then row:Hide() end
 end
 emptyTitle=ForeverCompanionInterface.Text(frame,14)
 emptyTitle:SetJustifyH("CENTER")
 emptyBody=ForeverCompanionInterface.Text(frame,11)
 emptyBody:SetJustifyH("CENTER");emptyBody:SetWordWrap(true);emptyBody:SetHeight(40)
 frame:SetScript("OnUpdate",function(_,dt)
  elapsed=elapsed+dt
  if elapsed>=M.GetUpdateInterval() then elapsed=0;M.Refresh() end
 end)
 detailPanel=CreateFrame("Frame",'ForeverCompanionBreakdownWindow',frame,"BackdropTemplate")
 detailPanel:SetSize(640,448)
 detailPanel:SetPoint("TOPLEFT",frame,"TOPRIGHT",5,0)
 detailPanel:SetClampedToScreen(true)
 detailPanel:SetMovable(true)
 detailPanel:EnableMouse(true)
 detailPanel:EnableMouseWheel(true)
 detailPanel:SetScript('OnMouseWheel',function(_,delta)
  spellPage=math.max(1,spellPage+(delta>0 and -1 or 1));M.Refresh()
 end)
 local position=saved().detailPosition
 if type(position)=='table' and safeNumber(position.x) and safeNumber(position.y) then
  detailPanel:ClearAllPoints();detailPanel:SetPoint('CENTER',UIParent,'CENTER',position.x,position.y)
  detailPanel.detached=true
 end
 local detailDrag=CreateFrame('Frame',nil,detailPanel)
 detailDrag:SetPoint('TOPLEFT',detailPanel,'TOPLEFT',0,0);detailDrag:SetSize(604,29)
 detailDrag:EnableMouse(true);detailDrag:RegisterForDrag('LeftButton')
 detailDrag:SetScript('OnDragStart',function() detailPanel.detached=true;detailPanel:StartMoving() end)
 detailDrag:SetScript('OnDragStop',function()
  detailPanel:StopMovingOrSizing()
  local x,y=detailPanel:GetCenter()
  local px,py=UIParent:GetCenter()
  if safeNumber(x) and safeNumber(y) and safeNumber(px) and safeNumber(py) then
   saved().detailPosition={x=x-px,y=y-py}
   detailPanel:ClearAllPoints();detailPanel:SetPoint('CENTER',UIParent,'CENTER',x-px,y-py)
  end
 end)
 detailPanel.dragHandle=detailDrag
 if detailPanel.SetBackdrop then
  detailPanel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  detailPanel:SetBackdropColor(.035,.055,.085,.96)
  detailPanel:SetBackdropBorderColor(.66,.48,.23,1)
 end
 detailTitle=detailPanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
 detailTitle:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",12,-12)
 detailTitle:SetText("PLAYER  /  DAMAGE DONE")
 detailTitle:SetWidth(585)
 detailTitle:SetHeight(16)
 detailTitle:SetWordWrap(false)
 detailTitle:SetJustifyH("LEFT")
 detailClose=flatButton(detailPanel)
 detailClose:SetSize(22,22);detailClose:SetText("x")
 detailClose:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-7,-7)
 detailClose:SetScript("OnClick",function() detailOpen=false;selectedRow=nil;selectedSourceKey=nil;M.Refresh() end)
 -- Screenshot-inspired tab strip. Only Spells is populated from verified
 -- native breakdown data; unsupported views are explicitly labeled.
 local tabNames={"Spells"}
 for i,tabName in ipairs(tabNames) do
  local tab=flatButton(detailPanel)
  tab:SetSize(77,24)
  tab:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",9+(i-1)*81,-32)
  tab:SetText(tabName)
  tab:SetScript("OnClick",function()
   detailTab=tabName
   spellPage=1
   M.Refresh()
  end)
  detailTabs[i]=tab
 end
 local dock=flatButton(detailPanel)
 dock:SetSize(112,24);dock:SetText('Dock to meter')
 dock:SetPoint('TOPLEFT',detailPanel,'TOPLEFT',94,-32)
 dock:SetScript('OnClick',function() M.ResetDetailPosition() end)
 detailPanel.dockButton=dock
 local search=ForeverCompanionInterface.EditBox(detailPanel,'Search spells or pets')
 search:SetSize(230,26);search:SetPoint('TOPLEFT',12,-65);search:SetMaxLetters(120)
 search:HookScript('OnTextChanged',function(self) M.SetSpellQuery(self:GetText() or '') end)
 search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 detailPanel.spellSearch=search
 local clear=flatButton(detailPanel);clear:SetSize(55,26);clear:SetPoint('TOPLEFT',248,-65);clear:SetText('Clear')
 clear:SetScript('OnClick',function() search:SetText('');M.SetSpellQuery('');search:ClearFocus() end)
 local filter=flatButton(detailPanel);filter:SetSize(132,26);filter:SetPoint('TOPLEFT',309,-65)
 filter:SetScript('OnClick',function() saved().spellFilter=saved().spellFilter=='pets' and 'all' or 'pets';spellPage=1;M.Refresh() end)
 detailPanel.spellFilter=filter
 local sort=flatButton(detailPanel);sort:SetSize(181,26);sort:SetPoint('TOPLEFT',447,-65);sort:SetText('Sort spells')
 sort:SetScript('OnClick',function()
  local entries={}
  for _,option in ipairs({{'amount','Highest contribution'},{'name','Spell name'},{'native','Native order'}}) do
   local key,label=option[1],option[2]
   entries[#entries+1]={label=label,selected=(saved().spellOrder or 'amount')==key,action=function() saved().spellOrder=key;spellPage=1;M.Refresh() end}
  end
  ForeverCompanionInterface.Menu(sort,'SPELL ORDER',entries,skin())
 end)
 local prevSpells=flatButton(detailPanel)
 prevSpells:SetSize(24,22)
 prevSpells:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-91,-33)
 prevSpells:SetText("<")
 prevSpells:SetScript("OnClick",function() spellPage=math.max(1,spellPage-1);M.Refresh() end)
 local nextSpells=flatButton(detailPanel)
 nextSpells:SetSize(24,22)
 nextSpells:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-12,-33)
 nextSpells:SetText(">")
 nextSpells:SetScript("OnClick",function() spellPage=spellPage+1;M.Refresh() end)
 spellPageLabel=detailPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 spellPageLabel:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-41,-39)
 spellPageLabel:SetWidth(47)
 spellPageLabel:SetJustifyH("CENTER")
 detailPanel.prevSpells=prevSpells
 detailPanel.nextSpells=nextSpells
 local detailTrim=detailPanel:CreateTexture(nil,"ARTWORK")
 detailTrim:SetColorTexture(.85,.62,.29,1)
 detailTrim:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",1,-1)
 detailTrim:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-1,-1)
 detailTrim:SetHeight(3)
 local summaryPanel=CreateFrame("Frame",nil,detailPanel,"BackdropTemplate")
 summaryPanel:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-12,-130)
 summaryPanel:SetSize(216,270)
 if summaryPanel.SetBackdrop then
  summaryPanel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  summaryPanel:SetBackdropColor(.025,.035,.055,.92)
  summaryPanel:SetBackdropBorderColor(.23,.29,.38,.9)
 end
 local summaryHeading=summaryPanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
 summaryHeading:SetPoint("TOPLEFT",summaryPanel,"TOPLEFT",12,-13)
 summaryHeading:SetText("PLAYER SUMMARY")
 for i,key in ipairs({"Total","Per second","Metric","Session","Spell coverage"}) do
  local label=summaryPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  label:SetPoint("TOPLEFT",summaryPanel,"TOPLEFT",12,-41-(i-1)*42)
  label:SetText(key)
  label:SetTextColor(.7,.78,.85)
  local value=summaryPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  value:SetPoint("TOPLEFT",summaryPanel,"TOPLEFT",12,-56-(i-1)*42)
  value:SetWidth(192)
  value:SetHeight(22)
  value:SetWordWrap(false)
  value:SetJustifyH("LEFT")
  if value.SetFont then value:SetFont("Fonts\\FRIZQT__.TTF",15,"") end
  value:SetTextColor(.94,.97,1)
  detailSummary[i]=value
 end
 local spellHeader=ForeverCompanionInterface.Text(detailPanel,10,skin().accent)
 spellHeader:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",64,-110)
 spellHeader:SetText("SPELL BREAKDOWN")
 local valueHeader=ForeverCompanionInterface.Text(detailPanel,10,skin().accent)
 valueHeader:SetPoint("TOPRIGHT",detailPanel,"TOPLEFT",398,-110)
 valueHeader:SetText("AMOUNT / SHARE")
 detailEmpty=ForeverCompanionInterface.Text(detailPanel,13)
 detailEmpty:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",30,-192)
 detailEmpty:SetWidth(350);detailEmpty:SetHeight(90);detailEmpty:SetWordWrap(true)
 detailEmpty:SetJustifyH("CENTER")
 detailMessage=ForeverCompanionInterface.Text(detailPanel,10)
 detailMessage:SetPoint("BOTTOMLEFT",detailPanel,"BOTTOMLEFT",14,12)
 detailMessage:SetWidth(610)
 for i=1,8 do
  local row=CreateFrame("Frame",nil,detailPanel)
  row:EnableMouse(true)
  row:SetScript('OnEnter',function(self)
   if not GameTooltip or not self.spellName then return end
   GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.spellName)
   local exact=M.ExactAmount(self.totalAmount)
   if exact then GameTooltip:AddLine('Amount: '..exact,.94,.96,1) end
   GameTooltip:Show()
  end)
  row:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
  row:SetSize(388,32)
  row:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",12,-130-(i-1)*34)
  local stripe=row:CreateTexture(nil,"BACKGROUND")
  stripe:SetAllPoints(row)
  stripe:SetColorTexture(.04,.052,.069,i%2==0 and .6 or .95)
  local rank=ForeverCompanionInterface.Text(row,10)
  rank:SetPoint("LEFT",row,"LEFT",4,0);rank:SetWidth(16);rank:SetText(i)
  local icon=row:CreateTexture(nil,"ARTWORK")
  icon:SetSize(22,22);icon:SetPoint("LEFT",row,"LEFT",22,0);icon:Hide()
  local label=ForeverCompanionInterface.Text(row,12)
  label:SetPoint("TOPLEFT",row,"TOPLEFT",52,-3);label:SetWidth(200)
  local value=ForeverCompanionInterface.Text(row,12)
  value:SetPoint("TOPRIGHT",row,"TOPRIGHT",-4,-2);value:SetWidth(122);value:SetJustifyH("RIGHT")
  local percent=ForeverCompanionInterface.Text(row,10)
  percent:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",-4,1);percent:SetWidth(70);percent:SetJustifyH("RIGHT")
  percent:SetTextColor(.58,.7,.79)
  local track=row:CreateTexture(nil,"BACKGROUND")
  track:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",52,4);track:SetSize(200,3)
  track:SetColorTexture(.1,.15,.2,1)
  local bar=CreateFrame("StatusBar",nil,row)
  bar:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",52,4);bar:SetSize(200,3)
  bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  bar:SetStatusBarColor(unpack(skin().accent));bar:SetMinMaxValues(0,1);bar:SetValue(0)
  detailRows[i]={frame=row,label=label,value=value,icon=icon,bar=bar,percent=percent,rank=rank}
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
  for _,control in ipairs(controls) do ForeverCompanionInterface.StyleButton(control,style) end
  if frame.SetBackdropColor then frame:SetBackdropColor(unpack(style.background)) end
  if frame.SetBackdropBorderColor then frame:SetBackdropBorderColor(unpack(style.border)) end
  if detailPanel and detailPanel.SetBackdropColor then
   detailPanel:SetBackdropColor(unpack(style.background))
   detailPanel:SetBackdropBorderColor(unpack(style.border))
  end
  for _,entry in ipairs(detailRows) do entry.bar:SetStatusBarColor(unpack(style.accent)) end
  if frame.meterTrim then frame.meterTrim:SetColorTexture(unpack(style.accent)) end
  if heading then heading:SetText(metricNames[metrics[metricIndex][1]]) end
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
 heading:SetText(metricNames[metrics[metricIndex][1]])
 frame.resizeGrip:SetShown(not saved().locked)
 emptyTitle:ClearAllPoints();emptyTitle:SetPoint("TOP",frame,"TOP",0,-(ROW_TOP+rowCount*ROW_STEP/2-30));emptyTitle:SetWidth(windowWidth-28)
 emptyBody:ClearAllPoints();emptyBody:SetPoint("TOP",frame,"TOP",0,-(ROW_TOP+rowCount*ROW_STEP/2-2));emptyBody:SetWidth(windowWidth-36)
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
  selectedRow=nil;selectedSourceKey=nil
  detailOpen=false
  if detailLabel then detailLabel:SetText("Select a player row for details") end
  for _,row in ipairs(rows) do row.frame:Hide() end
  emptyTitle:SetText("Combat data unavailable");emptyTitle:Show()
  emptyBody:SetText("Enable the game's damage meter if available, then reopen this window.");emptyBody:Show()
  detailLabel:Hide()
  notice:SetText("Meter unavailable")
  frame.meterFooter:SetText("Native combat data unavailable")
  frame.playerRange:Hide();rowOffset=0;sourceCount=0
  return
 end
 local data
 if isPast then
  local canReadHistory=type(C_DamageMeter.GetCombatSessionFromID)=="function" and type(C_DamageMeter.GetAvailableCombatSessions)=="function"
  if canReadHistory then
   local history=availableHistory()
   if pastIndex>#history then pastIndex=math.max(1,#history);selectedRow=nil;selectedSourceKey=nil;detailOpen=false end
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
 emptyTitle:SetShown(#sources==0);emptyBody:SetShown(#sources==0);detailLabel:Hide()
 emptyTitle:SetText("No combat session data")
 emptyBody:SetText("Your combat session will appear here. Choose a metric or another session above.")
 if frame.meterFooter then
  local duration=type(data)=="table" and data.durationSeconds
  local suffix=""
  if safeNumber(duration) and duration>=0 then
   suffix=string.format("  /  %d:%02d",math.floor(duration/60),math.floor(duration%60))
  end
  frame.meterFooter:SetText(sessions[sessionIndex][1].."  /  "..#sources.." players"..suffix)
  frame.meterFooter:SetWidth(windowWidth-(isPast and 70 or (#sources>rowCount and 94 or 25)))
  if isPast then
   local entry=availableHistory()[pastIndex]
   local name=type(entry)=='table' and entry.name
   if not (issecretvalue and issecretvalue(name)) and type(name)=='string' and name~='' then frame.meterFooter:SetText(name..suffix) end
  end
 end
 if selectedSourceKey then
  local match
  for i,source in ipairs(sources) do
   if M.SourceKey(source)==selectedSourceKey then match=i;break end
  end
  selectedRow=match
  if not match then selectedSourceKey=nil;detailOpen=false end
 end
 if selectedRow and selectedRow>#sources then selectedRow=nil;selectedSourceKey=nil;detailOpen=false end
 sourceCount=#sources
 rowOffset=math.max(0,math.min(rowOffset,math.max(0,sourceCount-rowCount)))
 frame.playerRange:SetShown(not isPast and sourceCount>rowCount)
 frame.playerRange:SetText(sourceCount>0 and ((rowOffset+1).."-"..math.min(sourceCount,rowOffset+rowCount).."/"..sourceCount) or "")
 local colors=RAID_CLASS_COLORS or {}
 for i,row in ipairs(rows) do
  local sourceIndex=rowOffset+i
  local source=i<=rowCount and sources[sourceIndex]
  if type(source)=="table" then
   row.frame:Show()
   row.frame.sourceIndex=sourceIndex;row.frame.sourceKey=M.SourceKey(source);row.rank:SetText(sourceIndex)
   row.selection:SetShown(selectedRow==sourceIndex)
   local guid=source.sourceGUID
   row.frame.sourceGUID=not (issecretvalue and issecretvalue(guid)) and type(guid)=="string" and guid or nil
   local displayName=source.name
   if not (issecretvalue and issecretvalue(displayName)) and type(displayName)=="string" then
    row.frame.sourceLabel=displayName
   else row.frame.sourceLabel=nil end
   if selectedRow==sourceIndex then row.background:SetColorTexture(.075,.19,.23,.98)
   elseif not (issecretvalue and issecretvalue(source.isLocalPlayer)) and source.isLocalPlayer==true then
    row.background:SetColorTexture(.13,.16,.08,.98)
   else row.background:SetColorTexture(i%2==0 and .035 or .045,i%2==0 and .060 or .075,i%2==0 and .095 or .12,.97) end
   row.frame.totalAmount=source.totalAmount;row.frame.amountPerSecond=source.amountPerSecond
   -- Direct display is permitted for secret strings/numbers; do not format or compare them.
   -- No Lua boolean tests, comparisons or formatting on secret source values.
   row.name:SetText(source.name)
   local metric=metrics[metricIndex][2]
   local rateMetric=metric=="Dps" or metric=="Hps"
   local both=saved().showBoth~=false and (rateMetric or metric=="DamageDone" or metric=="HealingDone")
   row.rate:SetShown(both)
   row.amount:ClearAllPoints()
   row.amount:SetPoint("RIGHT",row.frame,"RIGHT",both and -68 or -5,0)
   row.amount:SetWidth(both and 64 or 96)
   row.name:SetWidth(windowWidth-(both and 182 or 158))
   row.valueShade:SetWidth(both and 132 or 108)
   if both then
    row.amount:SetText(M.DisplayAmount(source.totalAmount))
    row.rate:SetText(M.DisplayAmount(source.amountPerSecond))
   elseif rateMetric then row.amount:SetText(M.DisplayAmount(source.amountPerSecond))
   else row.amount:SetText(M.DisplayAmount(source.totalAmount)) end
   local fontSize=safeNumber(saved().textSize) and saved().textSize or 11
   if fontSize~=10 and fontSize~=11 and fontSize~=13 then fontSize=11 end
   if row.fontSize~=fontSize then
    for _,label in ipairs({row.name,row.amount,row.rate,row.rank}) do
     if label.SetFont then label:SetFont("Fonts\\FRIZQT__.TTF",fontSize,"OUTLINE") end
    end
    row.fontSize=fontSize
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
   if (issecretvalue and issecretvalue(maximum)) or (safeNumber(maximum) and maximum>0) then
    row.fill:SetMinMaxValues(0,maximum)
    row.fill:SetValue(source.totalAmount)
   else
    row.fill:SetMinMaxValues(0,1)
    row.fill:SetValue(0)
   end
  else row.frame.sourceLabel=nil;row.frame.sourceGUID=nil;row.frame.totalAmount=nil;row.frame.amountPerSecond=nil;row.frame:Hide() end
 end
 if selectedRow then
  local selected=sources[selectedRow]
  if type(selected)=="table" then
   detailLabel:SetText(selected.name)
  else selectedRow=nil;selectedSourceKey=nil;detailOpen=false;detailLabel:SetText("Select a player row for details") end
 else detailLabel:SetText("Select a player row for details") end
 if detailPanel then detailPanel:SetShown(detailOpen and selectedRow~=nil) end
 if detailPanel and detailOpen and selectedRow then
  detailPanel.dockButton:SetEnabled(detailPanel.detached==true)
  -- Keep the details readable when the meter is docked near the right edge.
  if not detailPanel.detached and not (InCombatLockdown and InCombatLockdown()) and frame.GetRight and UIParent and UIParent.GetRight then
   local right,screenRight=frame:GetRight(),UIParent:GetRight()
   if safeNumber(right) and safeNumber(screenRight) then
    -- The expanded analysis pane is 600px wide, not the old 300px.
    -- Prefer the side with sufficient space, and keep it screen-clamped.
    local left=frame:GetLeft()
    local screenLeft=UIParent:GetLeft()
    local leftSpace=safeNumber(left) and safeNumber(screenLeft) and (left-screenLeft) or 0
    local rightSpace=screenRight-right
    local side=(rightSpace<645 and leftSpace>rightSpace) and "LEFT" or "RIGHT"
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
  if type(selected)=="table" and #detailSummary==5 then
   detailSummary[1]:SetText(M.DisplayAmount(selected.totalAmount))
   detailSummary[2]:SetText(M.DisplayAmount(selected.amountPerSecond))
   detailSummary[3]:SetText(metrics[metricIndex][1])
   detailSummary[4]:SetText(sessions[sessionIndex][1])
  end
  local safeToInspect=not (InCombatLockdown and InCombatLockdown())
  local breakdown
  if safeToInspect and type(selected)=="table" and type(C_DamageMeter)=="table" then
   local guid=selected.sourceGUID
   local creatureID=selected.sourceCreatureID
   -- A player source must be queried by GUID, not by a creature identifier.
   -- Some client builds omit sourceGUID on the summary row for the local player.
   -- Recover that GUID only when Blizzard explicitly marks this row as local.
   if not (issecretvalue and issecretvalue(selected.isLocalPlayer)) and selected.isLocalPlayer==true
    and (type(guid)~="string" or guid=="") and type(UnitGUID)=="function" then
    guid=read(UnitGUID,"player")
   end
   if not (issecretvalue and issecretvalue(guid)) and not (issecretvalue and issecretvalue(creatureID)) then
    -- Spell reports are damage/healing amounts even when the leaderboard is
    -- displaying the corresponding per-second metric. Prefer the matching
    -- amount metric and fall back to the displayed metric for client variants.
    local reportType=types()
    local e=Enum and Enum.DamageMeterType
    if e then
     if reportType==e.Dps and e.DamageDone~=nil then reportType=e.DamageDone
     elseif reportType==e.Hps and e.HealingDone~=nil then reportType=e.HealingDone end
    end
    local function fetchSource(metric)
     if isPast and type(C_DamageMeter.GetCombatSessionSourceFromID)=="function" then
      local entry=availableHistory()[pastIndex]
      local sessionID=historyID(entry)
      if sessionID~=nil then
       return read(C_DamageMeter.GetCombatSessionSourceFromID,sessionID,metric,guid,creatureID)
      end
     end
     return read(C_DamageMeter.GetCombatSessionSourceFromType,sessionType(),metric,guid,creatureID)
    end
    breakdown=fetchSource(reportType)
    local entries=type(breakdown)=="table" and breakdown.combatSpells
    if (type(entries)~="table" or #entries==0) and reportType~=types() then
     local alternative=fetchSource(types())
     local alternativeSpells=type(alternative)=="table" and alternative.combatSpells
     if type(alternativeSpells)=="table" and #alternativeSpells>0 then breakdown=alternative end
    end
   end
  end
  local spells=type(breakdown)=="table" and breakdown.combatSpells
  local sortable=type(spells)=="table" and #spells>0
  for _,spell in ipairs(type(spells)=="table" and spells or {}) do
   if type(spell)~="table" or not safeNumber(spell.totalAmount) then sortable=false;break end
  end
  local hasSpells=type(spells)=="table" and #spells>0
  detailEmpty:SetShown(not hasSpells)
  detailEmpty:SetText(safeToInspect and "No spell breakdown is available for this player and view yet." or "Spell analysis is available after combat. Your meter continues updating.")
  detailMessage:SetText(hasSpells and (#spells.." spells  /  "..(sortable and "Highest contribution first" or "Native display order")) or "Choose another player or combat session to inspect.")
  -- Keep the selected player's identity in the title, including when
  -- switching tabs; only inspect names Blizzard marks nonsecret.
  local titleName="PLAYER"
  if type(selected)=="table" then
   local name=selected.name
   if not (issecretvalue and issecretvalue(name)) and type(name)=="string" and name~="" then
    titleName=name
   end
  end
  detailTitle:SetText(titleName.."  /  "..(detailTab=="Spells" and
   (safeToInspect and (metrics[metricIndex][1]:upper().." SPELLS") or "AFTER COMBAT")
   or detailTab:upper()))
  for _,tab in ipairs(detailTabs) do ForeverCompanionInterface.StyleButton(tab,skin(),tab:GetText()==detailTab) end
  -- Find the largest inspectable spell amount instead of assuming the
  -- native API sorts spell entries by damage. Never inspect secret amounts.
  local spellMaximum=0
  local spellTotal=0
  local allSpellAmountsSafe=type(spells)=="table" and #spells>0
  if detailTab=="Spells" and type(spells)=="table" then
   for _,entry in ipairs(spells) do
    if type(entry)=="table" and safeNumber(entry.totalAmount) and entry.totalAmount>=0 then
     spellTotal=spellTotal+entry.totalAmount
     if entry.totalAmount>spellMaximum then spellMaximum=entry.totalAmount end
    else
     allSpellAmountsSafe=false
    end
   end
  else
   allSpellAmountsSafe=false
  end
  -- Tab availability is explicit: do not suggest unsupported native data
  -- is implemented just because the visual tab exists.
  if detailPanel.prevSpells then
   detailPanel.prevSpells:SetShown(detailTab=="Spells")
   detailPanel.nextSpells:SetShown(detailTab=="Spells")
  end
  if spellPageLabel then spellPageLabel:SetShown(detailTab=="Spells") end
  local nativeCount=type(spells)=='table' and #spells or 0
  spells=M.FilterSpells(type(spells)=='table' and spells or {},spellQuery,saved().spellFilter,saved().spellOrder)
  detailPanel.spellFilter:SetText(saved().spellFilter=='pets' and 'Pets only' or 'All spells')
  if nativeCount>0 then
   detailEmpty:SetShown(#spells==0);detailEmpty:SetText('No spells match this search and filter.')
   detailMessage:SetText(#spells..' / '..nativeCount..' spells · Shares use all reported spells · Search includes pet names')
  end
  local pageCount=math.max(1,math.ceil(#spells/8))
  if spellPage>pageCount then spellPage=pageCount end
  if detailPanel.prevSpells then
   detailPanel.prevSpells:SetEnabled(detailTab=="Spells" and spellPage>1)
   detailPanel.nextSpells:SetEnabled(detailTab=="Spells" and spellPage<pageCount)
  end
  if spellPageLabel then spellPageLabel:SetText(spellPage.."/"..pageCount) end
  -- Coverage compares the sum of inspectable spell entries to the native
  -- player total. Hide it if any amount is secret or not numeric.
  if #detailSummary==5 then
   local nativeTotal=type(selected)=="table" and selected.totalAmount
   if allSpellAmountsSafe and safeNumber(nativeTotal) and nativeTotal>0 and spellTotal>0 and spellTotal<=nativeTotal then
    detailSummary[5]:SetText(string.format("%.1f%%",100*spellTotal/nativeTotal))
   else detailSummary[5]:SetText("N/A") end
  end
  for i,item in ipairs(detailRows) do
   local spell=detailTab=="Spells" and type(spells)=="table" and spells[(spellPage-1)*8+i]
   item.frame:SetShown(type(spell)=="table")
   if type(spell)=="table" then
    item.rank:SetText((spellPage-1)*8+i)
    local spellName,_,info=M.SpellLabel(spell,(spellPage-1)*8+i)
    item.label:SetText(spellName)
    item.frame.spellName=not (issecretvalue and issecretvalue(spellName)) and type(spellName)=='string' and spellName or nil
    item.frame.totalAmount=spell.totalAmount
    local iconID=type(info)=="table" and info.iconID
    if not (issecretvalue and issecretvalue(iconID)) and type(iconID)=="number" and iconID>0 then
     item.icon:SetTexture(iconID)
     item.icon:Show()
    else item.icon:Hide() end
    item.value:SetText(M.DisplayAmount(spell.totalAmount))
    local amount=spell.totalAmount
    local maxAmount=spellMaximum
    if safeNumber(amount) and safeNumber(maxAmount) and maxAmount>0 then
     item.bar:SetMinMaxValues(0,maxAmount)
     item.bar:SetValue(amount)
     item.percent:SetText(allSpellAmountsSafe and spellTotal>0 and string.format("%.1f%%",100*amount/spellTotal) or "")
    else item.bar:SetMinMaxValues(0,1);item.bar:SetValue(0);item.percent:SetText("") end
   else
    item.label:SetText(i==1 and (detailTab~="Spells" and "Not available from native meter" or (safeToInspect and "No spell data available" or "Available after combat")) or "")
    item.value:SetText("")
    item.bar:SetValue(0)
    item.percent:SetText("")
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
local refreshMeter=M.Refresh
function M.Refresh()
 if not frame or not frame:IsShown() then return end
 local profiler=ForeverCompanionRefreshQueue
 local started=profiler and profiler.Start('meter')
 refreshMeter()
 if profiler then profiler.Finish('meter',started) end
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
 if ForeverCompanionInterface then ForeverCompanionInterface.CloseMenu() end
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
 saved().layout=nil
 windowWidth=width
 if frame then
  frame:SetWidth(width)
  heading:SetWidth(width-124);dragHandle:SetWidth(width-120)
  notice:SetWidth(width-68)
  if frame.meterFooter then frame.meterFooter:SetWidth(width-92) end
  for _,row in ipairs(rows) do
   row.frame:SetWidth(width-8)
   row.name:SetWidth(width-182)
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
 saved().layout=nil
 rowCount=count

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
   sessionIndex=i;pastIndex=1;rowOffset=0;selectedRow=nil;selectedSourceKey=nil;detailOpen=false;saved().session=item[1];M.Refresh()
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
   metricIndex=i;rowOffset=0;selectedRow=nil;selectedSourceKey=nil;detailOpen=false;saved().metric=item[1];M.Refresh()
   return true
  end
 end
 return false
end
function M.Scroll(delta)
 if not safeNumber(delta) then return false end
 rowOffset=math.max(0,math.min(math.max(0,sourceCount-rowCount),rowOffset+math.floor(delta)))
 M.Refresh();return true
end
function M.ScrollOffset() return rowOffset end
function M.CycleMetric(delta)
 if not safeNumber(delta) or delta==0 then return false end
 delta=delta>0 and 1 or -1
 for _=1,#metrics do
  metricIndex=(metricIndex-1+delta+#metrics)%#metrics+1
  if types()~=nil then return M.SetMode(metrics[metricIndex][1]) end
 end
 return false
end
function M.SelectPast(index)
 if not safeNumber(index) or index~=math.floor(index) or index<1 or index>historyCount() then return false end
 if not C_DamageMeter or type(C_DamageMeter.GetCombatSessionFromID)~='function' then return false end
 if not M.SetSession('Past') then return false end
 pastIndex=index;rowOffset=0;M.Refresh();return true
end
function M.OpenMetrics(anchor)
 local entries={}
 local enums=Enum and Enum.DamageMeterType or {}
 for i,item in ipairs(metrics) do
  local index=i
  entries[#entries+1]={label=metricNames[item[1]],selected=i==metricIndex,enabled=enums[item[2]]~=nil,action=function() M.SetMode(metrics[index][1]) end}
 end
 ForeverCompanionInterface.Menu(anchor or modeButton,'SELECT DISPLAY',entries,skin())
end
function M.OpenSessions(anchor)
 local entries={}
 local enums=Enum and Enum.DamageMeterSessionType or {}
 for i,item in ipairs(sessions) do
  local index=i
  entries[#entries+1]={label=item[1]..' combat',selected=i==sessionIndex,enabled=enums[item[2]]~=nil,action=function() M.SetSession(sessions[index][1]) end}
 end
 local history=availableHistory()
 local first=math.max(1,math.min(pastIndex-4,#history-9))
 for i=first,math.min(#history,first+9) do
  local index=i
  local entry=history[i]
  local name=type(entry)=='table' and entry.name
  if (issecretvalue and issecretvalue(name)) or type(name)~='string' or name=='' then name='Fight '..i end
  entries[#entries+1]={label=i..'. '..name,selected=sessionIndex==2 and pastIndex==i,enabled=enums.Expired~=nil and historyID(entry)~=nil and C_DamageMeter and type(C_DamageMeter.GetCombatSessionFromID)=='function',action=function() M.SelectPast(index) end}
 end
 ForeverCompanionInterface.Menu(anchor or sessionButton,'COMBAT SEGMENTS',entries,skin())
end
function M.SetTextSize(size)
 if not safeNumber(size) or (size~=10 and size~=11 and size~=13) then return false end
 saved().textSize=size;M.Refresh();return true
end
function M.SetBothColumns(enabled)
 if type(enabled)~='boolean' then return false end
 saved().showBoth=enabled;M.Refresh();return true
end
function M.OpenQuickMenu(anchor)
 local entries={}
 for _,metric in ipairs({'Damage','DPS','Healing','HPS','Taken'}) do
  local name=metric
  local enabled=false
  for _,item in ipairs(metrics) do if item[1]==name then enabled=Enum and Enum.DamageMeterType and Enum.DamageMeterType[item[2]]~=nil end end
  entries[#entries+1]={label=metricNames[name],enabled=enabled,selected=metrics[metricIndex][1]==name,action=function() M.SetMode(name) end}
 end
 entries[#entries+1]={label='Combat segments...',action=function() M.OpenSessions(anchor) end}
 entries[#entries+1]={label='Meter options...',action=function() M.OpenOptions(anchor) end}
 ForeverCompanionInterface.Menu(anchor or frame,'QUICK DISPLAYS',entries,skin())
end
function M.ResetDetailPosition()
 saved().detailPosition=nil
 if detailPanel then
  detailPanel.detached=false;detailPanel.anchorSide=nil
  detailPanel:ClearAllPoints();detailPanel:SetPoint('TOPLEFT',frame,'TOPRIGHT',5,0)
 end
 M.Refresh()
end
function M.OpenOptions(anchor)
 local entries={}
 for _,layout in ipairs({'compact','standard','expanded'}) do
  local name=layout
  entries[#entries+1]={label=name:sub(1,1):upper()..name:sub(2)..' layout',selected=saved().layout==name,action=function() M.SetLayout(name) end}
 end
 entries[#entries+1]={label='Show fewer players',enabled=rowCount>4,action=function() M.SetRows(rowCount-1) end}
 entries[#entries+1]={label='Show more players',enabled=rowCount<12,action=function() M.SetRows(rowCount+1) end}
 entries[#entries+1]={label='Total + per second columns',selected=saved().showBoth~=false,action=function() M.SetBothColumns(saved().showBoth==false) end}
 entries[#entries+1]={label='Larger text',selected=saved().textSize==13,action=function() M.SetTextSize(saved().textSize==13 and 11 or 13) end}
 entries[#entries+1]={label='Refresh rate...',action=function()
  local choices={}
  for _,setting in ipairs({{'Fast / 0.2 seconds',.2},{'Standard / 0.4 seconds',.4},{'Low frequency / 0.8 seconds',.8}}) do
   local value=setting[2]
   choices[#choices+1]={label=setting[1],selected=M.GetUpdateInterval()==value,action=function() M.SetUpdateInterval(value) end}
  end
  ForeverCompanionInterface.Menu(anchor or optionsButton,'METER REFRESH RATE',choices,skin())
 end}
 entries[#entries+1]={label='Details-inspired skin',selected=skinName=='details',action=function() M.SetSkin('details') end}
 entries[#entries+1]={label='Recount-inspired skin',selected=skinName=='recount',action=function() M.SetSkin('recount') end}
 entries[#entries+1]={label=saved().locked and 'Unlock window' or 'Lock window',selected=saved().locked==true,action=function() saved().locked=not saved().locked;M.Refresh() end}
 entries[#entries+1]={label='Reset breakdown position',action=M.ResetDetailPosition}
 entries[#entries+1]={label='Reset window appearance',action=function()
  saved().locked=false;saved().position=nil;saved().showBoth=true;saved().textSize=11;saved().updateInterval=.4
  M.ResetDetailPosition()
  M.SetSkin('details');M.SetLayout('standard');rowOffset=0
  frame:ClearAllPoints();frame:SetPoint('CENTER',UIParent,'CENTER',330,0);M.Refresh()
 end}
 entries[#entries+1]={label='Reset combat data...',action=function() M.RequestReset(anchor) end}
 entries[#entries+1]={label='Close meter',action=M.Hide}
 ForeverCompanionInterface.Menu(anchor or optionsButton,'METER OPTIONS',entries,skin())
end
function M.RequestReset(anchor)
 local api=C_DamageMeter
 local enabled=type(api)=='table' and type(api.ResetAllCombatSessions)=='function' and not (InCombatLockdown and InCombatLockdown())
 ForeverCompanionInterface.Menu(anchor or frame,'CLEAR ALL NATIVE COMBAT DATA?',{
  {label='Clear all native combat sessions',enabled=enabled,action=function()
   if InCombatLockdown and InCombatLockdown() then return end
   local current=C_DamageMeter
   if not current or type(current.ResetAllCombatSessions)~='function' then return end
   local ok=pcall(current.ResetAllCombatSessions)
   if ok then rowOffset=0;pastIndex=1;selectedRow=nil;selectedSourceKey=nil;detailOpen=false;M.Refresh()
   elseif frame then frame.meterFooter:SetText('Native meter could not reset data') end
  end},
  {label='Cancel',action=function() end}
 },skin())
end
SLASH_FOREVERCOMPANIONMETER1="/fcmeter"
SlashCmdList.FOREVERCOMPANIONMETER=function(msg)
 msg=(msg or ""):lower():match("^%s*(.-)%s*$")
 if msg=="hide" or msg=="off" then M.Hide()
 elseif msg=="show" or msg=="on" then M.Show()
 elseif msg=="lock" then saved().locked=true;M.Refresh()
 elseif msg=="unlock" then saved().locked=false;M.Refresh()
 elseif msg=="options" then M.Show();M.OpenOptions(optionsButton)
 elseif msg=="reset" then M.Show();M.RequestReset(frame.resetButton)
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
  M.ResetDetailPosition()
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
for _,event in ipairs({"DAMAGE_METER_COMBAT_SESSION_UPDATED","DAMAGE_METER_CURRENT_SESSION_UPDATED","DAMAGE_METER_RESET","PLAYER_REGEN_ENABLED"}) do
 pcall(events.RegisterEvent,events,event)
end
events:SetScript("OnEvent",function(_,event,name)
 if event=="ADDON_LOADED" and name=="ForeverCompanion" and saved().visible then M.Show()
 elseif event~="ADDON_LOADED" and frame and frame:IsShown() then
  if ForeverCompanionRefreshQueue then ForeverCompanionRefreshQueue.Schedule('meter-event',function() M.Refresh() end)
  else M.Refresh() end
 end
end)
