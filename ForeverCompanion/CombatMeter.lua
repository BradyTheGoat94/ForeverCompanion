-- Forever Companion Combat Meter (experimental, native C_DamageMeter only).
-- No combat log listeners, gameplay automation, or arithmetic on secret values.
local M={}
ForeverCompanionCombatMeter=M
local frame,rows,heading,notice,modeButton,sessionButton,previousButton,nextButton,dragHandle
local pastIndex=1
local rowCount=8
local windowWidth=290
local selectedRow=nil
local detailOpen=false
local detailRows={}
local detailPanel,detailTitle,detailClose
local detailLabel
local metricIndex,sessionIndex=1,1
local metrics={{"DPS","Dps"},{"Damage","DamageDone"},{"HPS","Hps"},{"Healing","HealingDone"},{"Absorbs","Absorbs"},{"Interrupts","Interrupts"},{"Dispels","Dispels"},{"Taken","DamageTaken"}}
local sessions={{"Current","Current"},{"Past","Expired"},{"Overall","Overall"}}
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
 b:SetPoint("TOPRIGHT",parent,"TOPRIGHT",x,-37)
 b:SetText(label)
 b:SetScript("OnClick",callback)
 return b
end
local function build()
 frame=CreateFrame("Frame","ForeverCompanionCombatMeterWindow",UIParent,"BackdropTemplate")
 frame:SetSize(290,302)
 frame:SetPoint("CENTER",UIParent,"CENTER",330,0)
 frame:SetFrameStrata("MEDIUM")
 frame:SetClampedToScreen(true)
 frame:SetMovable(true)
 frame:EnableMouse(true)
 frame:RegisterForDrag("LeftButton")
 frame:SetScript("OnDragStart",function(self)
  if not saved().locked then self:StartMoving() end
 end)
 frame:SetScript("OnDragStop",function(self)
  self:StopMovingOrSizing()
  local point,_,relative,x,y=self:GetPoint()
  if type(x)=="number" and type(y)=="number" then saved().position={point=point,relative=relative,x=x,y=y} end
 end)
 if frame.SetBackdrop then
  frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  frame:SetBackdropColor(.035,.055,.085,.96)
  frame:SetBackdropBorderColor(.66,.48,.23,1)
 end
 local db=saved()
 if type(db.rows)=="number" and db.rows==db.rows and db.rows~=math.huge and db.rows~=-math.huge then rowCount=math.max(4,math.min(12,math.floor(db.rows))) end
 if type(db.width)=="number" and db.width==db.width and db.width~=math.huge and db.width~=-math.huge then windowWidth=math.max(260,math.min(440,math.floor(db.width))) end
 frame:SetSize(windowWidth,110+rowCount*24)
 if type(db.position)=="table" and type(db.position.x)=="number" and type(db.position.y)=="number" then
  frame:ClearAllPoints()
  frame:SetPoint(db.position.point or "CENTER",UIParent,db.position.relative or "CENTER",db.position.x,db.position.y)
 end
 local trim=frame:CreateTexture(nil,"ARTWORK")
 trim:SetColorTexture(.85,.62,.29,1)
 trim:SetPoint("TOPLEFT",1,-1)
 trim:SetPoint("TOPRIGHT",-1,-1)
 trim:SetHeight(3)
 heading=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
 heading:SetPoint("TOPLEFT",frame,"TOPLEFT",13,-11)
 heading:SetTextColor(1,.82,.51)
 heading:SetText("COMPANION  /  COMBAT")
 local subtitle=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 subtitle:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-29)
 subtitle:SetTextColor(.54,.68,.77)
 subtitle:SetText("NATIVE METER  |  EXPERIMENTAL")
 -- Drag by the header as well as the body; do not drag on controls.
 dragHandle=CreateFrame("Frame",nil,frame)
 dragHandle:SetPoint("TOPLEFT",frame,"TOPLEFT",4,-4)
 dragHandle:SetSize(238,29)
 dragHandle:EnableMouse(true)
 dragHandle:RegisterForDrag("LeftButton")
 dragHandle:SetScript("OnDragStart",function() if not saved().locked then frame:StartMoving() end end)
 dragHandle:SetScript("OnDragStop",function()
  frame:StopMovingOrSizing()
  local point,_,relative,x,y=frame:GetPoint()
  if type(x)=="number" and type(y)=="number" then saved().position={point=point,relative=relative,x=x,y=y} end
 end)
 local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton")
 close:SetPoint("TOPRIGHT",frame,"TOPRIGHT",2,2)
 close:SetScript("OnClick",function() M.Hide() end)
 modeButton=button(frame,"Damage",91,-190,function()
  for _=1,#metrics do
   metricIndex=metricIndex%#metrics+1
   if types()~=nil then break end
  end
  M.Refresh()
 end)
 sessionButton=button(frame,"Current",92,-91,function()
  for _=1,#sessions do
   sessionIndex=sessionIndex%#sessions+1
   if sessionType()~=nil then break end
  end
  pastIndex=1
  selectedRow=nil
  detailOpen=false
  M.Refresh()
 end)
 previousButton=button(frame,"<",27,-63,function() pastIndex=math.min(historyCount(),pastIndex+1);selectedRow=nil;detailOpen=false;M.Refresh() end)
 nextButton=button(frame,">",27,-35,function() pastIndex=math.max(1,pastIndex-1);selectedRow=nil;detailOpen=false;M.Refresh() end)
 previousButton:ClearAllPoints()
 previousButton:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-45,8)
 nextButton:ClearAllPoints()
 nextButton:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-15,8)
 rows={}
 for i=1,12 do
  local row=CreateFrame("Frame",nil,frame)
  row:SetSize(windowWidth-26,21)
  row:SetPoint("TOPLEFT",frame,"TOPLEFT",13,-72-(i-1)*24)
  local bg=row:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(row)
  bg:SetColorTexture(i%2==0 and .085 or .11,i%2==0 and .13 or .17,i%2==0 and .19 or .24,.97)
  local fill=CreateFrame("StatusBar",nil,row)
  fill:SetAllPoints(row)
  fill:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  fill:SetMinMaxValues(0,1)
  fill:SetValue(0)
  fill:SetStatusBarColor(.85,.65,.32,.78)
  local rank=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  rank:SetPoint("LEFT",row,"LEFT",5,0)
  rank:SetWidth(18)
  rank:SetTextColor(.75,.63,.43)
  rank:SetText(i)
  local name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  name:SetPoint("LEFT",row,"LEFT",25,0)
  name:SetWidth(windowWidth-145)
  name:SetJustifyH("LEFT")
  local amount=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  amount:SetPoint("RIGHT",row,"RIGHT",-5,0)
  amount:SetJustifyH("RIGHT")
  local accent=row:CreateTexture(nil,"OVERLAY")
  accent:SetPoint("LEFT",row,"LEFT",0,0)
  accent:SetSize(2,21)
  accent:SetColorTexture(.86,.65,.35,1)
  local hover=row:CreateTexture(nil,"OVERLAY")
  hover:SetAllPoints(row)
  hover:SetColorTexture(1,1,1,.07)
  hover:Hide()
  row:EnableMouse(true)
  row:SetScript("OnEnter",function() hover:Show() end)
  row:SetScript("OnLeave",function() hover:Hide() end)
  row:SetScript("OnMouseDown",function()
   selectedRow=(selectedRow==i) and nil or i
   detailOpen=selectedRow~=nil
   M.Refresh()
  end)
  rows[i]={frame=row,fill=fill,name=name,amount=amount,accent=accent,background=bg}
  if i>rowCount then row:Hide() end
 end
 detailLabel=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 detailLabel:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",13,29)
 detailLabel:SetWidth(windowWidth-26)
 detailLabel:SetJustifyH("LEFT")
 detailLabel:SetTextColor(.98,.78,.45)
 detailLabel:SetText("Select a player row for details")
 notice=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 notice:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",13,12)
 notice:SetWidth(windowWidth-100)
 notice:SetTextColor(.65,.76,.84)
 frame:SetScript("OnUpdate",function(_,dt)
  elapsed=elapsed+dt
  if elapsed>=.4 then elapsed=0;M.Refresh() end
 end)
 detailPanel=CreateFrame("Frame",nil,frame,"BackdropTemplate")
 detailPanel:SetSize(290,110+8*23)
 detailPanel:SetPoint("TOPLEFT",frame,"TOPRIGHT",5,0)
 if detailPanel.SetBackdrop then
  detailPanel:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
  detailPanel:SetBackdropColor(.035,.055,.085,.96)
  detailPanel:SetBackdropBorderColor(.66,.48,.23,1)
 end
 detailTitle=detailPanel:CreateFontString(nil,"OVERLAY","GameFontNormal")
 detailTitle:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",12,-12)
 detailTitle:SetText("SPELL BREAKDOWN")
 detailClose=CreateFrame("Button",nil,detailPanel,"UIPanelCloseButton")
 detailClose:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",2,2)
 detailClose:SetScript("OnClick",function() detailOpen=false;selectedRow=nil;M.Refresh() end)
 local detailTrim=detailPanel:CreateTexture(nil,"ARTWORK")
 detailTrim:SetColorTexture(.85,.62,.29,1)
 detailTrim:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",1,-1)
 detailTrim:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-1,-1)
 detailTrim:SetHeight(3)
 for i=1,8 do
  local label=detailPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  label:SetPoint("TOPLEFT",detailPanel,"TOPLEFT",12,-35-(i-1)*23)
  label:SetWidth(175)
  label:SetJustifyH("LEFT")
  local value=detailPanel:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  value:SetPoint("TOPRIGHT",detailPanel,"TOPRIGHT",-12,-35-(i-1)*23)
  value:SetWidth(85)
  value:SetJustifyH("RIGHT")
  detailRows[i]={label=label,value=value}
 end
 detailPanel:Hide()
 frame:Hide()
end
function M.Refresh()
 if not frame or not frame:IsShown() then return end
 modeButton:SetText(metrics[metricIndex][1])
 sessionButton:SetText(sessions[sessionIndex][1])
 local isPast=sessionIndex==2
 previousButton:SetShown(isPast)
 nextButton:SetShown(isPast)
 previousButton:SetEnabled(isPast and type(C_DamageMeter)=="table" and type(C_DamageMeter.GetAvailableCombatSessions)=="function" and pastIndex<historyCount())
 nextButton:SetEnabled(isPast and pastIndex>1)
 if detailPanel then detailPanel:SetShown(detailOpen and selectedRow~=nil) end
 if not M.Available() then
  if detailPanel then detailPanel:Hide() end
  for _,row in ipairs(rows) do row.frame:Hide() end
  notice:SetText("Blizzard combat meter API unavailable")
  return
 end
 local data
 if isPast and type(C_DamageMeter.GetCombatSessionFromID)=="function" and type(C_DamageMeter.GetAvailableCombatSessions)=="function" then
  local entry=availableHistory()[pastIndex]
  local id=type(entry)=="table" and entry.sessionID
  if id~=nil then data=read(C_DamageMeter.GetCombatSessionFromID,id,types()) end
  if data==nil and pastIndex==1 then data=read(C_DamageMeter.GetCombatSessionFromType,sessionType(),types()) end
 else
  data=read(C_DamageMeter.GetCombatSessionFromType,sessionType(),types())
 end
 local sources=type(data)=="table" and data.combatSources
 if type(sources)~="table" then sources={} end
 local colors=RAID_CLASS_COLORS or {}
 for i,row in ipairs(rows) do
  local source=i<=rowCount and sources[i]
  if type(source)=="table" then
   row.frame:Show()
   if selectedRow==i then row.background:SetColorTexture(.22,.19,.12,.98)
   else row.background:SetColorTexture(i%2==0 and .085 or .11,i%2==0 and .13 or .17,i%2==0 and .19 or .24,.97) end
   -- Direct display is permitted for secret strings/numbers; do not format or compare them.
   -- No Lua boolean tests, comparisons or formatting on secret source values.
   row.name:SetText(source.name)
   row.amount:SetText((metrics[metricIndex][2]=="Dps" or metrics[metricIndex][2]=="Hps") and source.amountPerSecond or source.totalAmount)
   -- Use only NeverSecret class metadata for class color.
   local class=source.classFilename
   local color
   if not (issecretvalue and issecretvalue(class)) and type(class)=="string" then color=colors[class] end
   if color then
    row.fill:SetStatusBarColor(color.r,color.g,color.b,.75)
    row.accent:SetColorTexture(color.r,color.g,color.b,1)
   else
    row.fill:SetStatusBarColor(.85,.65,.32,.78)
    row.accent:SetColorTexture(.86,.65,.35,1)
   end
   -- In-combat percentage may be secret. Avoid Lua arithmetic entirely.
   -- The session may omit a maximum; only pass known-safe values to the bar.
   local maximum=data.maxAmount
   if (issecretvalue and issecretvalue(maximum)) or maximum~=nil then
    row.fill:SetMinMaxValues(0,maximum)
    row.fill:SetValue(source.totalAmount)
   else
    row.fill:SetMinMaxValues(0,1)
    row.fill:SetValue(0)
   end
  else row.frame:Hide() end
 end
 if selectedRow then
  local selected=sources[selectedRow]
  if type(selected)=="table" then
   detailLabel:SetText(selected.name)
  else selectedRow=nil;detailOpen=false;detailLabel:SetText("Select a player row for details") end
 else detailLabel:SetText("Select a player row for details") end
 if detailPanel then detailPanel:SetShown(detailOpen and selectedRow~=nil) end
 if detailPanel and detailOpen and selectedRow then
  local selected=sources[selectedRow]
  local safeToInspect=not (InCombatLockdown and InCombatLockdown())
  local breakdown
  if safeToInspect and type(selected)=="table" and type(C_DamageMeter)=="table" then
   local guid=selected.sourceGUID
   local creatureID=selected.sourceCreatureID
   if not (issecretvalue and issecretvalue(guid)) and not (issecretvalue and issecretvalue(creatureID)) then
    if isPast and type(C_DamageMeter.GetCombatSessionSourceFromID)=="function" then
     local entry=availableHistory()[pastIndex]
     if type(entry)=="table" and entry.sessionID then
      breakdown=read(C_DamageMeter.GetCombatSessionSourceFromID,entry.sessionID,types(),guid,creatureID)
     end
    else
     breakdown=read(C_DamageMeter.GetCombatSessionSourceFromType,sessionType(),types(),guid,creatureID)
    end
   end
  end
  local spells=type(breakdown)=="table" and breakdown.combatSpells
  detailTitle:SetText(safeToInspect and "SPELL BREAKDOWN  |  BETA" or "SPELLS  |  AFTER COMBAT")
  for i,item in ipairs(detailRows) do
   local spell=type(spells)=="table" and spells[i]
   if type(spell)=="table" then
    local spellID=spell.spellID
    if issecretvalue and issecretvalue(spellID) then spellID=nil end
    local info=type(spellID)=="number" and C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    item.label:SetText((type(info)=="table" and info.name) or ("Spell "..tostring(spellID or i)))
    item.value:SetText(spell.totalAmount)
   else
    item.label:SetText(i==1 and (safeToInspect and "No spell data available" or "Available after combat") or "")
    item.value:SetText("")
   end
  end
 end
 if isPast then
  local entry=availableHistory()[pastIndex]
  local title=type(entry)=="table" and entry.name
  if not (issecretvalue and issecretvalue(title)) and type(title)=="string" and title~="" then
   notice:SetText(title)
  else
   notice:SetText("Past fight "..pastIndex.." | Native history")
  end
 else
  notice:SetText(#sources==0 and "Waiting for Blizzard combat data" or "Native Blizzard combat data  |  Experimental")
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
 if type(width)~="number" or width~=width or width==math.huge or width==-math.huge or width~=math.floor(width) or width<260 or width>440 then return false end
 saved().width=width
 windowWidth=width
 if frame then
  frame:SetWidth(width)
  notice:SetWidth(width-100)
  for _,row in ipairs(rows) do
   row.frame:SetWidth(width-26)
   row.name:SetWidth(width-145)
  end
  if detailLabel then detailLabel:SetWidth(width-26) end

 end
 M.Refresh()
 return true
end
function M.SetRows(count)
 if type(count)~="number" or count~=count or count==math.huge or count==-math.huge or count~=math.floor(count) or count<4 or count>12 then return false end
 saved().rows=count
 rowCount=count
 if frame then frame:SetHeight(110+rowCount*24) end
 M.Refresh()
 return true
end
function M.SetSession(mode)
 for i,item in ipairs(sessions) do
  if item[1]:lower()==tostring(mode):lower() then sessionIndex=i;pastIndex=1;selectedRow=nil;detailOpen=false;M.Refresh();return true end
 end
 return false
end
function M.SetMode(mode)
 for i,item in ipairs(metrics) do
  if item[1]:lower()==tostring(mode):lower() then metricIndex=i;selectedRow=nil;detailOpen=false;M.Refresh();return true end
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
 elseif msg=="details" then
  if selectedRow then detailOpen=not detailOpen;M.Refresh() else M.Show() end
 elseif msg=="resetpos" then
  saved().position=nil
  if frame then frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"CENTER",330,0) end
 elseif msg:match("^width%s+%d+$") then
  M.SetWidth(tonumber(msg:match("%d+")))
  M.Show()
 elseif msg:match("^rows%s+%d+$") then
  M.SetRows(tonumber(msg:match("%d+")))
  M.Show()
 elseif M.SetSession(msg) or M.SetMode(msg) then M.Show()
 else M.Toggle() end
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
