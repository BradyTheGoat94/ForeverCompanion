-- Small client-native UI system: restrained surfaces, bounded labels and
-- explicit selection menus. Contains no gameplay or combat-data processing.
local U={}
ForeverCompanionInterface=U
U.palette={background={.027,.037,.052,.99},surface={.072,.093,.120,1},rail={.17,.145,.102,1},border={.21,.26,.31,1},accent={.96,.77,.46,1},text={.94,.95,.97,1},muted={.70,.75,.82,1}}
local controls=setmetatable({},{__mode='k'})
local popup
local function finite(n) return not(issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
function U.PanelScale(width,height,availableWidth,availableHeight)
 if not finite(width) or not finite(height) or not finite(availableWidth) or not finite(availableHeight) or width<=0 or height<=0 or availableWidth<=32 or availableHeight<=32 then return 1 end
 return math.min(1,(availableWidth-32)/width,(availableHeight-32)/height)
end
local function windowSettings(name)
 ForeverCompanionDB=ForeverCompanionDB or {};ForeverCompanionDB.windowLayouts=type(ForeverCompanionDB.windowLayouts)=='table' and ForeverCompanionDB.windowLayouts or {}
 local all=ForeverCompanionDB.windowLayouts;all[name]=type(all[name])=='table' and all[name] or {};return all[name]
end
function U.SizePreference(frame)
 local name=frame and frame.fcWindowName;local value=name and windowSettings(name).scale
 return finite(value) and math.max(.55,math.min(1.5,value)) or 1
end
function U.WindowControls(frame,name,width,height)
 if frame.fcWindowControls or not name then return end
 frame.fcWindowControls=true;frame.fcWindowName=name;frame:SetMovable(true);frame:SetClampedToScreen(true);frame:EnableMouse(true)
 local saved=windowSettings(name)
 if finite(saved.x) and finite(saved.y) then frame:ClearAllPoints();frame:SetPoint('CENTER',UIParent,'CENTER',saved.x,saved.y) end
 local drag=CreateFrame('Frame',nil,frame);drag:SetPoint('TOPLEFT',8,-2);drag:SetPoint('TOPRIGHT',-44,-2);drag:SetHeight(22);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton')
 drag:SetScript('OnDragStart',function() frame:StartMoving() end)
 drag:SetScript('OnDragStop',function()
  frame:StopMovingOrSizing()
  if frame.GetCenter and UIParent and UIParent.GetCenter then
   local x,y=frame:GetCenter();local px,py=UIParent:GetCenter()
   local fs=frame.GetEffectiveScale and frame:GetEffectiveScale();local ps=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()
   if finite(fs) and fs>0 and finite(ps) and ps>0 then px,py=px*ps/fs,py*ps/fs end
   if finite(x) and finite(y) and finite(px) and finite(py) then local latest=windowSettings(name);latest.x,latest.y=x-px,y-py end
  end
 end)
 local grip=CreateFrame('Button',nil,frame);grip:SetPoint('BOTTOMRIGHT',0,0);grip:SetSize(9,9);grip:EnableMouse(true);grip:RegisterForClicks('LeftButtonUp','RightButtonUp')
 local icon=grip:CreateTexture(nil,'ARTWORK');icon:SetAllPoints(grip);icon:SetTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up')
 local resizing,startX,startY,startScale
 local function stop() resizing=false;grip:SetScript('OnUpdate',nil) end
 grip:SetScript('OnMouseDown',function(_,button)
  if button~='LeftButton' or type(GetCursorPosition)~='function' then return end
  startX,startY=GetCursorPosition();startScale=frame.GetScale and frame:GetScale() or 1
  if not finite(startX) or not finite(startY) or not finite(startScale) then return end
  resizing=true
  grip:SetScript('OnUpdate',function()
   if not resizing then return end
   local x,y=GetCursorPosition();if not finite(x) or not finite(y) then stop();return end
   local parentScale=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
   if not finite(parentScale) or parentScale<=0 then parentScale=1 end
   local w,h=frame:GetWidth() or width,frame:GetHeight() or height
   local fit=math.min(1.5,(UIParent:GetWidth()-32)/w,(UIParent:GetHeight()-32)/h)
   local base=frame.fcScaleBase or 1
   local scale=math.max(.1,math.min(1.5*base,fit,math.max(.55*base,startScale+((x-startX)+(startY-y))/((w+h)*parentScale))))
   windowSettings(name).scale=scale/(frame.fcScaleBase or 1);frame:SetScale(scale)
  end)
 end)
 grip:SetScript('OnMouseUp',stop)
 grip:SetScript('OnClick',function(_,button) if button=='RightButton' then stop();windowSettings(name).scale=nil;if frame.fcApplyScale then frame.fcApplyScale() else U.FitPanel(frame,frame:GetWidth(),frame:GetHeight()) end end end)
 grip:SetScript('OnEnter',function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_LEFT');GameTooltip:SetText('Resize window');GameTooltip:AddLine('Drag to resize the whole interface. Right-click to reset size.',.85,.85,.8,true);GameTooltip:Show() end end)
 grip:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
 frame:HookScript('OnDragStop',function() if drag.GetScript then local finish=drag:GetScript('OnDragStop');if finish then finish() end end end)
 frame:HookScript('OnShow',function() local latest=windowSettings(name);if finite(latest.x) and finite(latest.y) then frame:ClearAllPoints();frame:SetPoint('CENTER',UIParent,'CENTER',latest.x,latest.y) end end)
 frame:HookScript('OnHide',stop);frame.fcResizeGrip=grip;frame.fcTitleDrag=drag
end
function U.FitPanel(frame,width,height)
 if UIParent and UIParent.GetWidth and UIParent.GetHeight then frame:SetScale(math.min(U.SizePreference(frame),(UIParent:GetWidth()-32)/width,(UIParent:GetHeight()-32)/height)) end
end
function U.PreparePanel(frame,name,width,height)
 U.WindowControls(frame,name,width,height)
 if U.FrameChrome then U.FrameChrome(frame) end
 U.FitPanel(frame,width,height)
 frame:RegisterEvent('UI_SCALE_CHANGED');frame:RegisterEvent('DISPLAY_SIZE_CHANGED')
 frame:SetScript('OnEvent',function() U.FitPanel(frame,width,height) end)
 if type(UISpecialFrames)=='table' then
  for _,existing in ipairs(UISpecialFrames) do if existing==name then return end end
  UISpecialFrames[#UISpecialFrames+1]=name
 end
end
local function paint(texture,color) texture:SetColorTexture(unpack(color)) end
function U.Text(parent,size,color)
 local text=parent:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
 if text.SetFont then text:SetFont((size or 12)>=15 and 'Fonts\\FRIZQT__.TTF' or 'Fonts\\ARIALN.TTF',size or 12,'') end
 text:SetTextColor(unpack(color or U.palette.text))
 text:SetJustifyH('LEFT')
 text:SetWordWrap(false)
 text:SetHeight((size or 12)+5)
 return text
end
-- Installed-client marble material. A texture region cannot intercept clicks or
-- raise above child frames; no animation or per-frame work is needed.
function U.Material(parent,anchor,alpha)
 local t=parent:CreateTexture(nil,'BORDER')
 t:SetAllPoints(anchor or parent)
 t:SetTexture('Interface\\FrameGeneral\\UI-Background-Marble')
 t:SetAlpha(alpha or .32)
 return t
end
-- Beveled metal edges use regions on the owning frame, never a covering frame.
function U.Bevel(parent,inset)
 local edges={}
 for _,side in ipairs({'TOP','BOTTOM','LEFT','RIGHT'}) do
  local t=parent:CreateTexture(nil,'BORDER')
  local horizontal=side=='TOP' or side=='BOTTOM'
  if horizontal then
   t:SetPoint(side..'LEFT',parent,side..'LEFT',2,side=='TOP' and -2 or 2)
   t:SetPoint(side..'RIGHT',parent,side..'RIGHT',-2,side=='TOP' and -2 or 2);t:SetHeight(2)
  else
   t:SetPoint('TOP'..side,parent,'TOP'..side,side=='LEFT' and 2 or -2,-4)
   t:SetPoint('BOTTOM'..side,parent,'BOTTOM'..side,side=='LEFT' and 2 or -2,4);t:SetWidth(2)
  end
  local lit=(side=='TOP' or side=='LEFT')~=not not inset
  paint(t,lit and {.36,.32,.24,1} or {.025,.021,.017,1})
  edges[#edges+1]=t
 end
 return edges
end
function U.FrameChrome(parent)
 if parent.fcChrome then return end
 parent.fcChrome=true
 if parent.SetBackdrop then
  parent:SetBackdrop({edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',edgeSize=24})
  if parent.SetBackdropBorderColor then parent:SetBackdropBorderColor(1,1,1,1) end
 end
 if not parent.SetBackdrop then U.Bevel(parent) end
end
function U.Surface(parent,palette)
 if parent.GetParent and parent:GetParent()==UIParent and parent.GetObjectType and parent:GetObjectType()=='Frame' and parent.GetName and parent:GetName() then U.WindowControls(parent,parent:GetName(),parent:GetWidth(),parent:GetHeight()) end
 local p=palette or U.palette
 local bg=parent:CreateTexture(nil,'BACKGROUND')
 bg:SetAllPoints(parent);paint(bg,p.background or U.palette.background)
 if not p.flat and parent.GetObjectType and parent:GetObjectType()=='Frame' then
  local material=parent:CreateTexture(nil,'BACKGROUND',nil,1)
  material:SetPoint('TOPLEFT',parent,'TOPLEFT',6,-6)
  material:SetPoint('BOTTOMRIGHT',parent,'BOTTOMRIGHT',-6,6)
  material:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Background')
  material:SetAlpha(.26)
 end
 local edge=parent:CreateTexture(nil,'BORDER')
 edge:SetPoint('TOPLEFT',0,0);edge:SetPoint('TOPRIGHT',0,0);edge:SetHeight(1)
 paint(edge,p.border or U.palette.border)
 local bottom=parent:CreateTexture(nil,'BORDER')
 bottom:SetPoint('BOTTOMLEFT',0,0);bottom:SetPoint('BOTTOMRIGHT',0,0);bottom:SetHeight(1)
 paint(bottom,p.border or U.palette.border)
 for _,side in ipairs({'LEFT','RIGHT'}) do
  local line=parent:CreateTexture(nil,'BORDER')
  line:SetPoint('TOP'..side,parent,'TOP'..side,0,0)
  line:SetPoint('BOTTOM'..side,parent,'BOTTOM'..side,0,0)
  line:SetWidth(1);paint(line,p.border or U.palette.border)
 end
 return bg,edge
end
function U.Button(parent,palette)
 local b=CreateFrame('Button',nil,parent)
 local p=palette or U.palette
 local bg,edge=U.Surface(b,{background=p.surface or U.palette.surface,border=p.border})
 local bevel=p.flat and {} or U.Bevel(b)
 local text=U.Text(b,12,p.text)
 text:ClearAllPoints();text:SetPoint('LEFT',b,'LEFT',7,0);text:SetPoint('RIGHT',b,'RIGHT',-7,0)
 text:SetJustifyH('CENTER')
 b:SetFontString(text)
 b:HookScript('OnEnter',function(self)
  if text.IsTruncated and text:IsTruncated() and GameTooltip and not GameTooltip:IsOwned(self) then
   GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self:GetText() or '',1,1,1,true);GameTooltip:Show()
  end
 end)
 b:HookScript('OnLeave',function(self) if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
 if b.SetDisabledFontObject then b:SetDisabledFontObject("GameFontDisableSmall") end
 b:SetHighlightTexture('Interface\\Buttons\\WHITE8X8','ADD')
 local highlight=b.GetHighlightTexture and b:GetHighlightTexture()
 if highlight then highlight:SetVertexColor(.35,.55,.75,.14) end
 b:SetPushedTexture('Interface\\Buttons\\WHITE8X8','ADD')
 local pushed=b.GetPushedTexture and b:GetPushedTexture()
 if pushed then pushed:SetVertexColor(.2,.4,.6,.18) end
 local marker=b:CreateTexture(nil,'ARTWORK')
 marker:SetPoint('TOPLEFT',b,'TOPLEFT',0,-1)
 marker:SetPoint('BOTTOMLEFT',b,'BOTTOMLEFT',0,1)
 marker:SetWidth(2);paint(marker,p.accent or U.palette.accent);marker:Hide()
 controls[b]={background=bg,edge=edge,text=text,marker=marker,palette=p,bevel=bevel}
 -- Explicit states keep custom font strings legible without relying on a
 -- stock template's font objects. Focus and selection have separate cues.
 local function state()
  local parts=controls[b]
  local enabled=not b.IsEnabled or b:IsEnabled()
  text:SetTextColor(unpack(enabled and (parts.active and (parts.palette.accent or U.palette.accent) or (parts.palette.text or U.palette.text)) or {.43,.49,.57,1}))
  bg:SetAlpha(enabled and 1 or .5)
  marker:SetShown(enabled and parts.active or false)
 end
 b:HookScript('OnMouseDown',function()
  if b.IsEnabled and not b:IsEnabled() then return end
  for i,t in ipairs(bevel) do paint(t,(i==1 or i==3) and {.025,.021,.017,1} or {.36,.32,.24,1}) end
 end)
 b:HookScript('OnMouseUp',function()
  for i,t in ipairs(bevel) do paint(t,(i==1 or i==3) and {.36,.32,.24,1} or {.025,.021,.017,1}) end
 end)
 b:HookScript('OnEnable',state);b:HookScript('OnDisable',state)
 b:HookScript('OnEnter',function()
  if not b.IsEnabled or b:IsEnabled() then paint(edge,controls[b].palette.accent or U.palette.accent) end
 end)
 b:HookScript('OnLeave',function()
  local parts=controls[b]
  paint(edge,parts.active and (parts.palette.accent or U.palette.accent) or (parts.palette.border or U.palette.border))
 end)
 return b
end
-- Search and note fields share the same inset and focus treatment.
function U.EditBox(parent,placeholder)
 local edit=CreateFrame('EditBox',nil,parent)
 edit:SetFontObject('ChatFontNormal')
 if edit.SetFont then edit:SetFont('Fonts\\ARIALN.TTF',12,'') end
 edit:SetTextColor(unpack(U.palette.text))
 edit:SetTextInsets(9,9,2,2)
 edit:SetAutoFocus(false)
 local bg,edge=U.Surface(edit,{background={.015,.020,.028,1},border={.20,.24,.30,1}})
 edit:HookScript('OnEditFocusGained',function() paint(edge,U.palette.accent) end)
 edit:HookScript('OnEditFocusLost',function() paint(edge,U.palette.border) end)
 if placeholder then
  local hint=U.Text(edit,12,U.palette.muted)
  hint:SetPoint('LEFT',edit,'LEFT',9,0);hint:SetPoint('RIGHT',edit,'RIGHT',-9,0)
  hint:SetText(placeholder)
  local function refreshHint(self)
   local empty=(self:GetText() or '')==''
   hint:SetShown(empty and not (self.HasFocus and self:HasFocus()))
  end
  if edit.HookScript then
   edit:HookScript('OnTextChanged',refreshHint)
   edit:HookScript('OnEditFocusGained',refreshHint)
   edit:HookScript('OnEditFocusLost',refreshHint)
  end
  edit.fcPlaceholder=hint
  refreshHint(edit)
 end
 return edit
end
function U.StyleButton(button,palette,active)
 local parts=controls[button]
 if not parts then return end
 local p=palette or U.palette
 parts.palette=p;parts.active=active and true or false
 paint(parts.marker,p.accent or U.palette.accent)
 paint(parts.background,active and (p.rail or U.palette.rail) or (p.surface or U.palette.surface))
 paint(parts.edge,active and (p.accent or U.palette.accent) or (p.border or U.palette.border))
 local enabled=not button.IsEnabled or button:IsEnabled()
 parts.text:SetTextColor(unpack(enabled and (active and (p.accent or U.palette.accent) or (p.text or U.palette.text)) or {.43,.49,.57,1}))
 parts.marker:SetShown(enabled and parts.active or false)
end
function U.CloseMenu()
 if popup then popup:Hide();popup=nil end
end
function U.Menu(anchor,title,entries,palette,width)
 U.CloseMenu()
 local p=palette or U.palette
 local shade=CreateFrame('Button',nil,UIParent)
 shade:SetAllPoints(UIParent);shade:SetFrameStrata('FULLSCREEN_DIALOG')
 shade:SetScript('OnClick',U.CloseMenu)
 local panel=CreateFrame('Frame',nil,shade,'BackdropTemplate')
 width=width or 224
 panel:SetSize(width,40+#entries*27)
 panel:SetPoint('TOPLEFT',anchor,'BOTTOMLEFT',0,-5)
 panel:SetClampedToScreen(true)
 panel:SetFrameLevel(shade:GetFrameLevel()+1)
 panel:EnableMouse(true)
 if panel.SetBackdrop then
  panel:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
  panel:SetBackdropColor(unpack(p.background or U.palette.background))
  panel:SetBackdropBorderColor(unpack(p.border or U.palette.border))
 end
 local heading=U.Text(panel,11,p.muted)
 heading:SetPoint('TOPLEFT',12,-12);heading:SetWidth(width-49);heading:SetText(title)
 local close=U.Button(panel,p)
 close:SetPoint('TOPRIGHT',-6,-5);close:SetSize(24,24);close:SetText('x')
 close:SetScript('OnClick',U.CloseMenu)
 for i,entry in ipairs(entries) do
  local row=U.Button(panel,p)
  row:SetSize(width-16,25);row:SetPoint('TOPLEFT',8,-34-(i-1)*27)
  row:SetText(entry.label)
  U.StyleButton(row,p,entry.selected)
  row:SetEnabled(entry.enabled~=false)
  if entry.enabled==false then row:GetFontString():SetTextColor(.35,.4,.46) end
  row:SetScript('OnClick',function() if entry.enabled==false or type(entry.action)~='function' then return end;U.CloseMenu();entry.action() end)
  if entry.tooltip then
   row:SetScript('OnEnter',function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(entry.label);GameTooltip:AddLine(entry.tooltip,.8,.85,.9,true);GameTooltip:Show() end end)
   row:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
  end
 end
 shade:SetScript('OnHide',function() if popup==shade then popup=nil end end)
 -- Do not capture keyboard input on the dismiss overlay. WoW can protect
 -- SetPropagateKeyboardInput in combat or restricted UI contexts.
 -- Clicking outside the menu or its close button dismisses it safely.
 popup=shade
 return shade
end

-- Shared bounded pages prevent valid reference locations being silently cut off.
function U.MenuPage(entries,page,size)
 entries=type(entries)=='table' and entries or {}
 size=finite(size) and math.max(4,math.min(10,math.floor(size))) or 8
 local pages=math.max(1,math.ceil(#entries/size))
 page=finite(page) and math.max(1,math.min(pages,math.floor(page))) or 1
 local visible={}
 for i=(page-1)*size+1,math.min(#entries,page*size) do visible[#visible+1]=entries[i] end
 return visible,page,pages
end
function U.PagedMenu(anchor,title,entries,palette,width,page)
 local visible,current,pages=U.MenuPage(entries,page)
 if #visible==0 then visible[1]={label='No locations available',enabled=false} end
 if pages>1 then
  visible[#visible+1]={label='Previous locations',enabled=current>1,action=function() U.PagedMenu(anchor,title,entries,palette,width,current-1) end}
  visible[#visible+1]={label='More locations',enabled=current<pages,action=function() U.PagedMenu(anchor,title,entries,palette,width,current+1) end}
 end
 return U.Menu(anchor,title..(pages>1 and (' · '..current..' / '..pages) or ''),visible,palette,width)
end

function U.SetHoverHelp(button,title,description)
 button:SetScript('OnEnter',function(self)
  if not GameTooltip then return end
  GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(title)
  GameTooltip:AddLine(type(description)=='function' and description() or description,.85,.89,.94,true)
  GameTooltip:Show()
 end)
 local function hide(self)
  if GameTooltip and (not GameTooltip.IsOwned or GameTooltip:IsOwned(self)) then GameTooltip:Hide() end
 end
 button:SetScript('OnLeave',hide);button:SetScript('OnHide',hide)
 return button
end

function U.HoverNote(parent,x,y,title,description)
 local button=U.Button(parent)
 button:SetPoint('TOPLEFT',x,y);button:SetSize(23,23);button:SetText('?')
 return U.SetHoverHelp(button,title,description)
end

function U.CloseButton(parent,action)
 local button=U.Button(parent)
 button:SetSize(26,26);button:SetPoint('TOPRIGHT',parent,'TOPRIGHT',-8,-8)
 button:SetText('x');button:SetScript('OnClick',action)
 local exit=button:CreateTexture(nil,'OVERLAY');exit:SetAllPoints(button)
 if exit.SetAtlas then exit:SetAtlas('RedButton-Exit');button:SetText('') end
 return button
end
