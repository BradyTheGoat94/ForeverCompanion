-- Small client-native UI system: restrained surfaces, bounded labels and
-- explicit selection menus. Contains no gameplay or combat-data processing.
local U={}
ForeverCompanionInterface=U
U.palette={background={.025,.032,.044,.99},surface={.065,.080,.103,1},border={.23,.28,.35,1},accent={.82,.68,.43,1},text={.93,.95,.98,1},muted={.66,.72,.80,1}}
local controls=setmetatable({},{__mode='k'})
local popup
local function paint(texture,color) texture:SetColorTexture(unpack(color)) end
function U.Text(parent,size,color)
 local text=parent:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall')
 if text.SetFont then text:SetFont('Fonts\\ARIALN.TTF',size or 12,'') end
 text:SetTextColor(unpack(color or U.palette.text))
 text:SetJustifyH('LEFT')
 text:SetWordWrap(false)
 text:SetHeight((size or 12)+5)
 return text
end
function U.Surface(parent,palette)
 local p=palette or U.palette
 local bg=parent:CreateTexture(nil,'BACKGROUND')
 bg:SetAllPoints(parent);paint(bg,p.background or U.palette.background)
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
 local text=U.Text(b,12,p.text)
 text:ClearAllPoints();text:SetPoint('LEFT',b,'LEFT',7,0);text:SetPoint('RIGHT',b,'RIGHT',-7,0)
 text:SetJustifyH('CENTER')
 b:SetFontString(text)
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
 controls[b]={background=bg,edge=edge,text=text,marker=marker,palette=p}
 -- Explicit states keep custom font strings legible without relying on a
 -- stock template's font objects. Focus and selection have separate cues.
 local function state()
  local parts=controls[b]
  local enabled=not b.IsEnabled or b:IsEnabled()
  text:SetTextColor(unpack(enabled and (parts.active and (parts.palette.accent or U.palette.accent) or (parts.palette.text or U.palette.text)) or {.43,.49,.57,1}))
  bg:SetAlpha(enabled and 1 or .5)
  marker:SetShown(enabled and parts.active or false)
 end
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
 paint(parts.background,active and (p.rail or U.palette.surface) or (p.surface or U.palette.surface))
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
  panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Buttons\\WHITE8X8',edgeSize=1})
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
  row:SetScript('OnClick',function() U.CloseMenu();entry.action() end)
  if entry.tooltip then
   row:SetScript('OnEnter',function(self) if GameTooltip then GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(entry.label);GameTooltip:AddLine(entry.tooltip,.8,.85,.9,true);GameTooltip:Show() end end)
   row:SetScript('OnLeave',function() if GameTooltip then GameTooltip:Hide() end end)
  end
 end
 shade:SetScript('OnHide',function() if popup==shade then popup=nil end end)
 if shade.EnableKeyboard and shade.SetPropagateKeyboardInput then
  shade:EnableKeyboard(true);shade:SetPropagateKeyboardInput(true)
  shade:SetScript('OnKeyDown',function(self,key)
   self:SetPropagateKeyboardInput(key~='ESCAPE')
   if key=='ESCAPE' then U.CloseMenu() end
  end)
 end
 popup=shade
 return shade
end

function U.CloseButton(parent,action)
 local button=U.Button(parent)
 button:SetSize(26,26);button:SetPoint('TOPRIGHT',parent,'TOPRIGHT',-8,-8)
 button:SetText('x');button:SetScript('OnClick',action)
 return button
end
