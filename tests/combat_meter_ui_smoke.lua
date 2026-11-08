-- Focused mocked-client regression for meter layering and secret-safe display.
local objects={}
local methods={}
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return rawget(self,"width") or 320 end
function methods:GetHeight() return rawget(self,"height") or 300 end
function methods:SetPoint(...) self.point={...} end
function methods:SetText(v) self.text=v;if rawget(self,"fontString") then self.fontString.text=v end end
function methods:GetText() return self.text end
function methods:GetFontString() return rawget(self,"fontString") or self end
function methods:SetFontString(v) self.fontString=v end
function methods:SetEnabled(v) self.enabled=v end
function methods:GetFrameLevel() return rawget(self,"level") or (rawget(self,"parent") and self.parent:GetFrameLevel()+1) or 1 end
function methods:SetFrameLevel(v) self.level=v end
function methods:SetScript(k,v) self[k]=v end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown~=false end
function methods:SetShown(v) self.shown=v end
function methods:SetValue(v) self.value=v end
function methods:SetMinMaxValues(a,b) self.minimum,self.maximum=a,b end
function methods:SetStatusBarColor(...) self.color={...} end
local function object(kind,parent)
 local o=setmetatable({kind=kind,parent=parent},{__index=function(_,k) return methods[k] or function() end end})
 objects[#objects+1]=o
 return o
end
function methods:CreateTexture() return object('Texture',self) end
function methods:CreateFontString() return object('FontString',self) end
UIParent=object('Frame')
CreateFrame=function(kind,name,parent) local o=object(kind,parent);if name then _G[name]=o end;return o end
SlashCmdList={}
ForeverCompanionDB={}
Enum={DamageMeterType={Dps=1,DamageDone=0,HealingDone=2,Hps=3},DamageMeterSessionType={Current=1,Expired=2,Overall=0}}
local secret=setmetatable({secret=true},{__tostring=function() error('secret formatted') end,__lt=function() error('secret compared') end})
issecretvalue=function(v) return type(v)=='table' and v.secret==true end
local source={name=secret,totalAmount=secret,amountPerSecond=secret,classFilename='MAGE'}
C_DamageMeter={GetCombatSessionFromType=function() return {combatSources={source},maxAmount=secret} end}
RAID_CLASS_COLORS={MAGE={r=.2,g=.7,b=1}}
dofile('ForeverCompanion/InterfaceKit.lua')
dofile('ForeverCompanion/CombatMeter.lua')
local m=ForeverCompanionCombatMeter
assert(rawequal(m.DisplayAmount(secret),secret),'secret identity must pass through untouched')
assert(m.ExactAmount(secret)==nil,'secret values must never enter tooltip formatting')
assert(m.DisplayAmount(12345)=='12.3k' and m.DisplayAmount(1234567)=='1.2m')
assert(m.DisplayAmount(999950)=='1m' and m.DisplayAmount(999950000)=='1b','compact rollover must remain readable')
assert(m.DisplayAmount(12.34)=='12.3' and m.DisplayAmount(0)=='0')
assert(m.ExactAmount(1234567)=='1234567' and m.ExactAmount(12.34)=='12.34')
assert(m.ExactAmount(0/0)==nil and m.ExactAmount(math.huge)==nil)
m.Show()
for _,layout in ipairs({'compact','standard','expanded'}) do
 assert(m.SetLayout(layout))
 m.Refresh()
 local window=ForeverCompanionCombatMeterWindow
 assert(window:GetHeight()==50+ForeverCompanionDB.combatMeter.rows*21)
 for _,o in ipairs(objects) do
  if o.kind=='FontString' and o.text==secret then
   if o.parent~=window then
    -- Row labels live above the bar, not on its parent frame.
    assert(o.parent:GetFrameLevel()>o.parent.parent:GetFrameLevel())
   end
  end
 end
end
local metricControl=ForeverCompanionCombatMeterWindow.metricButton
assert(metricControl)
metricControl.OnClick()
local healingControl
for _,o in ipairs(objects) do if o.kind=='Button' and o.text=='Healing Done' then healingControl=o end end
assert(healingControl and healingControl.enabled)
healingControl.OnClick()
assert(ForeverCompanionDB.combatMeter.metric=='Healing','explicit metric menu selects desired view')
assert(m.SetMode('DPS'))
assert(m.SetSkin('recount'));assert(m.SetSkin('details'))
assert(m.SetRows(4));assert(m.SetWidth(280));m.Refresh()
source.name='Public player';source.totalAmount=1234567;source.amountPerSecond=12345.67
m.Refresh()
local publicRow,compactFound
for _,o in ipairs(objects) do
 if o.kind=='FontString' and o.text=='12.3k' then compactFound=true end
 if rawget(o,'sourceLabel')=='Public player' then publicRow=o end
end
assert(compactFound and publicRow,'narrow meter uses compact inspectable amounts')
local nameLabel,totalLabel,rateLabel
for _,o in ipairs(objects) do
 if o.kind=='FontString' and rawget(o,'parent') and rawget(o.parent,'parent')==publicRow then
  if o.text=='Public player' then nameLabel=o
  elseif o.text=='1.2m' then totalLabel=o
  elseif o.text=='12.3k' then rateLabel=o end
 end
end
assert(nameLabel and totalLabel and rateLabel)
assert(nameLabel.point[4]+nameLabel.width<=publicRow.width+totalLabel.point[4]-totalLabel.width,'dual columns cannot collide with names at minimum width')
assert(publicRow.width+totalLabel.point[4]<=publicRow.width+rateLabel.point[4]-rateLabel.width,'total and rate columns remain separate')
assert(m.SetBothColumns(false))
assert(nameLabel.point[4]+nameLabel.width<=publicRow.width+totalLabel.point[4]-totalLabel.width,'single-column mode cannot collide with names')
assert(m.SetBothColumns(true))
local tooltipLines={}
GameTooltip={SetOwner=function() end,SetText=function() end,AddLine=function(_,line) tooltipLines[#tooltipLines+1]=line end,Show=function() end,Hide=function() end}
publicRow.OnEnter(publicRow)
local exactFound=false
for _,line in ipairs(tooltipLines) do if line=='Per second: 12345.67' then exactFound=true end end
assert(exactFound,'hover preserves the unrounded public rate')
GameTooltip=nil
source.name=secret;source.totalAmount=secret;source.amountPerSecond=secret
m.Refresh()
local calls=0
source.sourceGUID="Player-Test"
m.Refresh()
C_DamageMeter.GetCombatSessionSourceFromType=function()
 calls=calls+1
 local spells={}
 for i=10,1,-1 do spells[#spells+1]={spellID=i,totalAmount=100-i} end
 return {combatSpells=spells}
end
C_Spell={GetSpellInfo=function(id) return {name="Native spell "..id,iconID=id} end}
local playerRow
for _,o in ipairs(objects) do if rawget(o,"OnMouseDown") then playerRow=o;break end end
assert(playerRow)
playerRow.OnMouseDown(playerRow,"LeftButton")
assert(calls>0 and m.SelectedRow()==1,'selected player reads native breakdown out of combat')
local nextPage
for _,o in ipairs(objects) do
 if o.kind=='Button' and o.text==">" and o.parent and rawget(o.parent,"width")==640 then nextPage=o end
end
assert(nextPage)
nextPage.OnClick()
local found=false
for _,o in ipairs(objects) do if o.text=="Native spell 9" then found=true end end
assert(found,'spell pagination displays the next native spell entries')
local oldSession=C_DamageMeter.GetCombatSessionFromType
C_DamageMeter.GetCombatSessionFromType=function()
 return {combatSources={{name="Other",sourceGUID="Other",totalAmount=20,amountPerSecond=2},source},maxAmount=secret}
end
m.Refresh()
assert(m.SelectedRow()==2,'detail selection follows public source identity when rankings change')
C_DamageMeter.GetCombatSessionFromType=oldSession
m.Refresh()
assert(m.SelectedRow()==1)
local before=calls
InCombatLockdown=function() return true end
m.Refresh()
assert(calls==before,'no source inspection during combat')
InCombatLockdown=function() return false end
assert(m.SetMode('healing'))
playerRow.OnMouseDown(playerRow,"LeftButton")
assert(m.SelectedRow()==1)
-- Every native rank remains accessible in a four-row viewport.
assert(m.SetMode('DPS'));assert(m.SetRows(4))
local raid={}
for i=1,40 do raid[i]={name='Player '..i,sourceGUID='GUID-'..i,totalAmount=i*1000,amountPerSecond=i*100,classFilename='MAGE'} end
C_DamageMeter.GetCombatSessionFromType=function() return {combatSources=raid,maxAmount=40000} end
m.Refresh();assert(m.ScrollOffset()==0)
playerRow.OnMouseWheel(playerRow,-1)
assert(m.ScrollOffset()==1 and playerRow.sourceIndex==2,'wheel scrolls player ranks instead of changing metric')
assert(m.Scroll(1000) and m.ScrollOffset()==36 and playerRow.sourceIndex==37)
playerRow.OnMouseDown(playerRow,'LeftButton');assert(m.SelectedRow()==37)
assert(m.SetRows(8) and m.ScrollOffset()==32,'resize clamps the scroll range')
assert(m.SelectedRow()==37,'row-count change retains the selected player breakdown')
raid[1],raid[37]=raid[37],raid[1]
m.Refresh();assert(m.SelectedRow()==1,'off-screen selection still follows native GUID')
assert(m.Scroll(-1000) and m.ScrollOffset()==0 and playerRow.sourceGUID=='GUID-37')
assert(not m.Scroll(secret) and not m.Scroll(math.huge))
assert(m.SetBothColumns(false) and ForeverCompanionDB.combatMeter.showBoth==false)
assert(m.SetBothColumns(true));assert(m.SetTextSize(13));assert(not m.SetTextSize(99))
local sessionID
C_DamageMeter.GetAvailableCombatSessions=function() return {{sessionID=77,name='Native encounter'}} end
C_DamageMeter.GetCombatSessionFromID=function(id) sessionID=id;return {combatSources=raid,maxAmount=40000,durationSeconds=90} end
ForeverCompanionCombatMeterWindow.sessionButton.OnClick()
local recorded
for _,o in ipairs(objects) do if o.kind=='Button' and o.text=='1. Native encounter' then recorded=o end end
assert(recorded and recorded.enabled)
recorded.OnClick();assert(sessionID==77 and ForeverCompanionDB.combatMeter.session=='Past')
assert(not m.SelectPast(2),'nonexistent session cannot be selected')
local resetCount=0
C_DamageMeter.ResetAllCombatSessions=function() resetCount=resetCount+1;raid={} end
m.RequestReset(ForeverCompanionCombatMeterWindow.resetButton)
assert(resetCount==0,'opening reset confirmation must preserve data')
local confirm
for _,o in ipairs(objects) do if o.kind=='Button' and o.text=='Clear all native combat sessions' then confirm=o end end
assert(confirm and confirm.enabled)
InCombatLockdown=function() return true end
confirm.OnClick();assert(resetCount==0,'combat starting after confirmation still blocks reset')
InCombatLockdown=function() return false end
m.RequestReset(ForeverCompanionCombatMeterWindow.resetButton)
for _,o in ipairs(objects) do if o.kind=='Button' and o.text=='Clear all native combat sessions' then confirm=o end end
confirm.OnClick();assert(resetCount==1 and m.ScrollOffset()==0 and m.SelectedRow()==nil)
ForeverCompanionCombatMeterWindow.optionsButton.OnClick()
local lock
for _,o in ipairs(objects) do if o.kind=='Button' and o.text=='Lock window' then lock=o end end
assert(lock);lock.OnClick();assert(ForeverCompanionDB.combatMeter.locked and ForeverCompanionCombatMeterWindow.resizeGrip.shown==false)
SlashCmdList.FOREVERCOMPANIONMETER('unlock');assert(ForeverCompanionCombatMeterWindow.resizeGrip.shown)
C_DamageMeter=nil;m.Refresh()
print('PASS: compact meter geometry, secret-safe dual columns, raid scrolling, stable selection, segment menus, reset confirmation and options')

