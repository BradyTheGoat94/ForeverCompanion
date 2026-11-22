local function noop() end
local function widget()
 local w={shown=true}
 local methods={
  SetText=function(self,value) self.text=value end,
  SetSize=function(self,width,height) self.width,self.height=width,height end,
  SetWidth=function(self,value) self.width=value end,
  SetHeight=function(self,value) self.height=value end,
  GetHeight=function(self) return self.height or 0 end,
  GetStringHeight=function(self) return #(self.text or '') end,
  SetShown=function(self,value) self.shown=value end,Hide=function(self) self.shown=false end,
  SetEnabled=function(self,value) self.enabled=value end,
  SetVerticalScroll=function(self,value) self.offset=value end,
  GetVerticalScroll=function(self) return self.offset or 0 end,
  SetScript=function(self,key,fn) self[key]=fn end,
  GetFontString=function(self) return self end,
 }
 return setmetatable(w,{__index=function(_,key)
  return methods[key] or (key:match('^[A-Z]') and noop)
 end})
end
CreateFrame=widget
ForeverCompanionInterface={Text=widget,Button=widget,Surface=noop,StyleButton=noop,SetHoverHelp=noop,palette={}}
dofile('ForeverCompanion/ReferenceWorkspace.lua')
local R=ForeverCompanionReferenceWorkspace
local a,b=R.Topic('Readiness: Check your training.')
assert(a=='Readiness' and b=='Check your training.')
a,b=R.Topic('SOURCE / Published guide')
assert(a=='SOURCE' and b=='Published guide')
local long=('Long evidence line. '):rep(30)
local list={{title='Unlocks',body='Short'},{title='Full reference',body=long}}
for i=3,8 do list[i]={title='Topic '..i,body='Text '..i} end
local ui=R.CreateBrowser(widget(),738,282)
ui:SetItems(list,'Class A')
assert(ui.title.text=='Unlocks' and not ui.previous.enabled and ui.next.enabled)
ui.rows[2].OnClick(ui.rows[2]);assert(ui.body.text==long and ui.scrollHint.shown)
ui.scroll.OnMouseWheel(ui.scroll,-1)
assert(ui.scroll.offset==32)
ui:SetItems(list,'Class A');assert(ui.scroll.offset==32,'refresh preserves reading position')
ui.next.OnClick()
assert(ui.rows[2].item.title=='Topic 8' and ui.title.text=='Full reference')
ui.rows[2].OnClick(ui.rows[2]);assert(ui.title.text=='Topic 8' and ui.scroll.offset==0)
ui:SetItems(list,'Class B')
assert(ui.title.text=='Unlocks' and ui.page==1 and ui.index==1)
ui:SetItems({},'None');assert(not ui.rows[1].shown and ui.body.text=='')
print('PASS: indexed reference navigation, bounded reading area and scroll preservation')
