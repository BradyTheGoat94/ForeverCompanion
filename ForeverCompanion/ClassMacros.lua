-- Reference and copy UI. The player creates and presses each macro in the client.
local M={}
ForeverCompanionClassMacros=M

local function cast(name,spell,conditions,note,timestamp)
 return {name=name,note=note,time=timestamp,code='#showtooltip '..spell..'\n/cast '..conditions..' '..spell}
end
local ally='[@mouseover,help,nodead][help,nodead][@player]'
local enemy='[@mouseover,harm,nodead][harm,nodead]'
M.entries={
 WARRIOR={
  cast('Mouseover Taunt','Taunt',enemy,'Taunt a hostile mouseover or your target. Be in the required stance.',198),
  cast('Mouseover Mocking Blow','Mocking Blow',enemy,'Force a hostile unit to attack you briefly. Check the talent and stance requirements in your spellbook.',170),
  cast('Mouseover Shield Bash','Shield Bash',enemy,'Interrupt without changing your target. Requires a shield and an eligible stance.',239),
 },
 PALADIN={
  cast('Mouseover Blessing of Protection','Blessing of Protection',ally,'Protect a friendly mouseover, friendly target, or yourself from physical attacks. Check Forbearance before use.',59),
  cast('Mouseover Hammer of Justice','Hammer of Justice',enemy,'Stun the enemy under your cursor without changing targets.',112),
  cast('Mouseover Cleanse','Cleanse',ally,'Cleanse a friendly mouseover, friendly target, or yourself once you learn Cleanse. Check your spellbook if you only know Purify.',59),
 },
 HUNTER={
  {name='Send pet to mouseover',note='Send your active pet to a hostile mouseover or your current target.',time=294,code='/petattack '..enemy},
  {name='Recall pet',note='Stop your pet from attacking and call it back to you.',time=266,code='/petpassive\n/petfollow'},
  cast('Mouseover Hunter\'s Mark',"Hunter's Mark",enemy,'Mark a hostile mouseover or your target before a pull.',294),
 },
 ROGUE={
  cast('Mouseover Kick','Kick',enemy,'Interrupt a hostile mouseover or your current target. Stay in melee range.',390),
  cast('Mouseover Pick Pocket','Pick Pocket',enemy,'Pick a hostile unit\'s pocket without changing targets. Stealth and range still apply.',388),
  {name='Start attack with Sinister Strike',note='Start melee auto-attacks against your hostile target even if you are waiting for energy.',time=388,code='#showtooltip Sinister Strike\n/startattack [harm,nodead]\n/cast [harm,nodead] Sinister Strike'},
 },
 PRIEST={
  cast('Mouseover Power Word: Shield','Power Word: Shield',ally,'Shield a friendly mouseover, friendly target, or yourself. Weakened Soul still applies.',772),
  cast('Mouseover Dispel Magic','Dispel Magic',ally,'Dispel a friendly mouseover, friendly target, or yourself. Use your ordinary spell binding for offensive dispels.',749),
  cast('Mouseover Renew','Renew',ally,'Apply Renew to a party frame without changing targets.',772),
 },
 SHAMAN={
  cast('Mouseover Earth Shock','Earth Shock',enemy,'Shock a hostile mouseover or your current target. Check the Forever spell tooltip for its current effects.',663),
  cast('Mouseover Healing Wave','Healing Wave',ally,'Heal the ally under your mouse, your friendly target, or yourself.',30),
  {name='Choose a shield',note='Press for Lightning Shield. Hold Shift for Water Shield once learned.',time=682,code='#showtooltip\n/cast [mod:shift] Water Shield; Lightning Shield'},
 },
 MAGE={
  cast('Mouseover Counterspell','Counterspell',enemy,'Interrupt the enemy under your cursor or your target. Finish or cancel your current cast if the interrupt cannot fire.',30),
  cast('Mouseover Polymorph','Polymorph',enemy,'Crowd-control a valid mouseover or your target. Confirm the target type and avoid breaking it with damage.',30),
  {name='Conjure water or food',note='Press for water. Hold Shift for food. Train the conjuration spells before using it.',time=475,code='#showtooltip\n/cast [mod:shift] Conjure Food; Conjure Water'},
 },
 WARLOCK={
  cast('Mouseover Banish','Banish',enemy,'Banish an eligible hostile mouseover or your target. Check creature type before casting.',520),
  {name='Recall demon',note='Set your active demon to passive and call it back, useful before a skip or regroup.',time=573,code='/petpassive\n/petfollow'},
  cast('Mouseover Devour Magic','Devour Magic',ally,'With a Felhunter active, dispel a friendly mouseover, friendly target, or yourself. The demon must know the ability.',573),
 },
 DRUID={
  cast('Mouseover Rejuvenation','Rejuvenation',ally,'Apply a heal over time to a friendly mouseover, friendly target, or yourself.',30),
  cast('Mouseover Growl','Growl',enemy,'Taunt a hostile mouseover or your target while in bear form.',594),
  {name='Keep Cat Form or enter it',note='Enter Cat Form without toggling it off on repeated presses. Learn Cat Form first.',time=628,code='#showtooltip Cat Form\n/cast !Cat Form'},
 },
}
local video='https://www.youtube.com/watch?v=O9kB7smMVH0&t='
local wowhead='https://www.wowhead.com/classic/guide/classic-wow-basic-macro-guide-10007'
local panel,description,code,choices
local currentClass,selected

local function fill(value)
 code:ClearFocus()
 code.value=value
 code:SetText(value)
 code:SetCursorPosition(0)
end
local function selectText()
 code:SetFocus()
 code:HighlightText()
end
local function refresh()
 local list=M.entries[currentClass] or {}
 local entry=list[selected]
 for i,button in ipairs(choices) do
  button:SetShown(list[i]~=nil)
  if list[i] then button:SetText(list[i].name);button:SetEnabled(i~=selected) end
 end
 description:SetText(entry and entry.note or 'Choose a supported class to view its macros.')
 fill(entry and entry.code or '')
end
function M.Create(parent)
 local U=ForeverCompanionInterface
 panel=CreateFrame('Frame',nil,parent)
 panel:SetPoint('TOPLEFT',16,-51);panel:SetSize(738,280)
 local function label(x,y,w,h,message)
  local t=U.Text(panel,12)
  t:SetPoint('TOPLEFT',x,-y);t:SetSize(w,h);t:SetJustifyV('TOP');t:SetWordWrap(true);t:SetText(message)
  return t
 end
 local function button(x,y,w,title,action)
  local b=U.Button(panel);b:SetPoint('TOPLEFT',x,-y);b:SetSize(w,27);b:SetText(title);b:SetScript('OnClick',action)
  return b
 end
 label(0,0,738,35,'Choose a macro, select its text, and press Ctrl+C. Paste it into a new macro via /macro.')
 choices={}
 for i=1,3 do
  local index=i
  choices[i]=button((i-1)*248,36,240,'',function() selected=index;refresh() end)
 end
 description=label(0,75,738,45,'')
 code=U.EditBox(panel);code:SetPoint('TOPLEFT',0,-126);code:SetSize(738,72)
 code:SetMultiLine(true)
 code:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
 code:SetScript('OnTextChanged',function(self,userInput)
  if userInput and self:GetText()~=self.value then self:SetText(self.value or '') end
 end)
 button(0,209,147,'Select macro text',function()
  local entry=(M.entries[currentClass] or {})[selected]
  if entry then fill(entry.code);selectText() end
 end)
 button(155,209,161,'Related video URL',function()
  local entry=(M.entries[currentClass] or {})[selected]
  if entry then fill(video..entry.time..'s');selectText() end
 end)
 button(324,209,171,'Wowhead syntax URL',function() fill(wowhead);selectText() end)
 label(0,247,738,31,'English spell names. Use the name shown in your spellbook on other clients. Reference reviewed for Forever; try each macro in game.')
 panel:SetScript('OnHide',function() code:ClearFocus() end)
 panel:Hide()
end
function M.Render(class)
 local changed=currentClass~=class
 if changed then currentClass=class;selected=1 end
 if changed or not panel:IsShown() then refresh() end
 panel:Show()
end
function M.Hide()
 if panel then panel:Hide() end
end
