local widgets,choices={},{}
local noop=function() end
local function widget()
 local w={shown=true,value=''}
 local methods={SetText=function(s,v) s.value=v end,GetText=function(s) return s.value end,
  SetScript=function(s,k,v) s[k]=v end,Show=function(s) s.shown=true end,Hide=function(s) s.shown=false end,
  IsShown=function(s) return s.shown end,GetHeight=function() return 420 end,
  CreateTexture=function() return widget() end,CreateFontString=function() return widget() end}
 widgets[#widgets+1]=w
 return setmetatable(w,{__index=function(_,k) return methods[k] or noop end})
end
CreateFrame=widget;UIParent=widget();SlashCmdList={};date=os.date
ForeverCompanionInterface={Button=widget,Text=widget,EditBox=widget,PagedMenu=function(_,_,entries) choices=entries end}
ForeverCompanionVisualTheme=setmetatable({},{__index=function() return noop end})
UnitName=function() return 'Brady' end;GetRealmName=function() return 'Realm' end
ForeverCompanionDB={}
local function snapshot() return {items={{id=1,count=3,name='Copper Bar',tab='Tab 1'}},slots=8,savedAt=1} end
ForeverCompanionInventoryDB={['Brady - Realm']={bank=snapshot()},['Alt - Realm']={mail=snapshot()}}
dofile('ForeverCompanion/BankView.lua')
ForeverCompanionBankView.Create(UIParent);ForeverCompanionBankView.Show(true)
for _,w in ipairs(widgets) do if w.value=='Alts' then w.OnClick() end end
assert(choices[1].label=='All characters and inventories');choices[1].action()
local locations={}
for _,w in ipairs(widgets) do locations[w.value]=true end
assert(locations['Alt - Realm / Mailbox / Tab 1'] and locations['Brady - Realm / Bank / Tab 1'])
local function recipe(id,name) return {id=id,name=name,materials={{name='Copper Bar',id=1,count=1}},yellow=50,gray=70,ups=1} end
local a,b=recipe(11,'Copper A'),recipe(12,'Copper B')
ForeverCompanionProfessionReference={build='test'}
local owner
ForeverCompanionProfessionLeveling={names={'Alchemy','Blacksmithing'},Catalog=function(n) return {n=='Alchemy' and a or b} end,
 Settings=function() return {current=1,target=20,reserve=0} end,Build=function() return {steps={},materials={},current=1,target=20,reserve=0} end,
 LiveSkill=noop,RecipeState=function() return 'Reference' end,HideRecipeTooltip=noop,ImportStep=function(n) owner=n;return true,'Added' end}
for _,k in ipairs({'Surface','PreparePanel','CloseButton','HoverNote','StyleButton'}) do ForeverCompanionInterface[k]=noop end
dofile('ForeverCompanion/ProfessionGuideWorkspace.lua')
local W=ForeverCompanionProfessionGuideWorkspace
W.Open(nil,'recipes',true);W.query='copper bar';W.Refresh();assert(#W.results==2)
W.rows[2].OnClick(W.rows[2]);W.addButton.OnClick();assert(owner=='Blacksmithing')
