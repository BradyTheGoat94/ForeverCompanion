-- Forever Companion Combat Meter (experimental, native C_DamageMeter only).
-- No combat log listeners, gameplay automation, or arithmetic on secret values.
local M={}
ForeverCompanionCombatMeter=M
local frame,rows,heading,notice,modeButton,sessionButton
local metricIndex,sessionIndex=1,1
local metrics={{"DPS","Dps"},{"Damage","DamageDone"},{"HPS","Hps"},{"Healing","HealingDone"},{"Absorbs","Absorbs"},{"Interrupts","Interrupts"},{"Dispels","Dispels"},{"Taken","DamageTaken"}}
local sessions={{"Current","Current"},{"Expired","Expired"},{"Overall","Overall"}}
local elapsed=0
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
 return type(C_DamageMeter)=="table" and type(C_DamageMeter.GetCombatSessionFromType)=="function"
  and types()~=nil and sessionType()~=nil
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
  M.Refresh()
 end)
 rows={}
 for i=1,8 do
  local row=CreateFrame("Frame",nil,frame)
  row:SetSize(264,21)
  row:SetPoint("TOPLEFT",frame,"TOPLEFT",13,-72-(i-1)*24)
  local bg=row:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(row)
  bg:SetColorTexture(.10,.15,.21,.93)
  local fill=CreateFrame("StatusBar",nil,row)
  fill:SetAllPoints(row)
  fill:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
  fill:SetMinMaxValues(0,1)
  fill:SetValue(0)
  fill:SetStatusBarColor(.85,.65,.32,.78)
  local name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  name:SetPoint("LEFT",row,"LEFT",5,0)
  name:SetWidth(160)
  name:SetJustifyH("LEFT")
  local amount=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  amount:SetPoint("RIGHT",row,"RIGHT",-5,0)
  amount:SetJustifyH("RIGHT")
  rows[i]={frame=row,fill=fill,name=name,amount=amount}
 end
 notice=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 notice:SetPoint("BOTTOM",frame,"BOTTOM",0,12)
 notice:SetWidth(266)
 notice:SetTextColor(.65,.76,.84)
 frame:SetScript("OnUpdate",function(_,dt)
  elapsed=elapsed+dt
  if elapsed>=.4 then elapsed=0;M.Refresh() end
 end)
 frame:Hide()
end
function M.Refresh()
 if not frame or not frame:IsShown() then return end
 modeButton:SetText(metrics[metricIndex][1])
 sessionButton:SetText(sessions[sessionIndex][1])
 if not M.Available() then
  for _,row in ipairs(rows) do row.frame:Hide() end
  notice:SetText("Blizzard combat meter API unavailable")
  return
 end
 local data=read(C_DamageMeter.GetCombatSessionFromType,sessionType(),types())
 local sources=type(data)=="table" and data.combatSources
 if type(sources)~="table" then sources={} end
 local colors=RAID_CLASS_COLORS or {}
 for i,row in ipairs(rows) do
  local source=sources[i]
  if type(source)=="table" then
   row.frame:Show()
   -- Direct display is permitted for secret strings/numbers; do not format or compare them.
   -- No Lua boolean tests, comparisons or formatting on secret source values.
   local okName=pcall(row.name.SetText,row.name,source.name)
   if not okName then row.name:SetText("Player") end
   local okAmount=pcall(row.amount.SetText,row.amount,(metrics[metricIndex][2]=="Dps" or metrics[metricIndex][2]=="Hps") and source.amountPerSecond or source.totalAmount)
   if not okAmount then row.amount:SetText("--") end
   -- Use only NeverSecret class metadata for class color.
   local class=source.classFilename
   local color=type(class)=="string" and colors[class]
   if color then row.fill:SetStatusBarColor(color.r,color.g,color.b,.75)
   else row.fill:SetStatusBarColor(.85,.65,.32,.78) end
   -- In-combat percentage may be secret. Avoid Lua arithmetic entirely.
   local okRatio=pcall(row.fill.SetValue,row.fill,source.relativeAmount)
   if not okRatio then row.fill:SetValue(0) end
  else row.frame:Hide() end
 end
 notice:SetText(#sources==0 and "Waiting for Blizzard combat data" or "Native Blizzard combat data  •  Experimental")
end
function M.Show()
 if not frame then build() end
 saved().visible=true
 frame:Show()
 M.Refresh()
end
function M.Hide()
 saved().visible=false
 if frame then frame:Hide() end
end
function M.Toggle()
 if frame and frame:IsShown() then M.Hide() else M.Show() end
end
function M.SetMode(mode)
 for i,item in ipairs(metrics) do
  if item[1]:lower()==tostring(mode):lower() then metricIndex=i;M.Refresh();return true end
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
 elseif M.SetMode(msg) then M.Show()
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
