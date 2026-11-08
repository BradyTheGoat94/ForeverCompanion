-- Focused mocked-client regression for meter layering and secret-safe display.
local objects={}
local methods={}
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return rawget(self,"width") or 320 end
function methods:GetHeight() return rawget(self,"height") or 300 end
function methods:SetPoint(...) self.point={...} end
function methods:SetText(v) self.text=v end
function methods:GetText() return self.text end
function methods:GetFontString() return self end
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
dofile('ForeverCompanion/CombatMeter.lua')
local m=ForeverCompanionCombatMeter
m.Show()
for _,layout in ipairs({'compact','standard','expanded'}) do
 assert(m.SetLayout(layout))
 m.Refresh()
 local window=ForeverCompanionCombatMeterWindow
 assert(window:GetHeight()==170+ForeverCompanionDB.combatMeter.rows*27)
 for _,o in ipairs(objects) do
  if o.kind=='FontString' and o.text==secret then
   if o.parent~=window then
    -- Row labels live above the bar, not on its parent frame.
    assert(o.parent:GetFrameLevel()>o.parent.parent:GetFrameLevel())
   end
  end
 end
end
assert(m.SetSkin('recount'));assert(m.SetSkin('details'))
assert(m.SetRows(4));assert(m.SetWidth(280));m.Refresh()
local calls=0
source.sourceGUID="Player-Test"
C_DamageMeter.GetCombatSessionSourceFromType=function()
 calls=calls+1
 local spells={}
 for i=1,10 do spells[i]={spellID=i,totalAmount=100-i} end
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
 if o.kind=='Button' and o.text==">" and o.parent and rawget(o.parent,"width")==600 then nextPage=o end
end
assert(nextPage)
nextPage.OnClick()
local found=false
for _,o in ipairs(objects) do if o.text=="Native spell 9" then found=true end end
assert(found,'spell pagination displays the next native spell entries')
local before=calls
InCombatLockdown=function() return true end
m.Refresh()
assert(calls==before,'no source inspection during combat')
InCombatLockdown=function() return false end
assert(m.SetMode('healing'))
playerRow.OnMouseDown(playerRow,"LeftButton")
assert(m.SelectedRow()==1)
C_DamageMeter=nil;m.Refresh()
print('PASS: meter layouts, overlay frame levels, native secret display, missing API')

