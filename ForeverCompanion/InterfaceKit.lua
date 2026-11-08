-- Small client-native UI system: restrained surfaces, bounded labels and
-- explicit selection menus. Contains no gameplay or combat-data processing.
local U={}
ForeverCompanionInterface=U
U.palette={background={.018,.022,.029,.99},surface={.045,.055,.070,1},border={.17,.21,.26,1},accent={.82,.68,.43,1},text={.93,.95,.98,1},muted={.57,.65,.73,1}}
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
 bottom:SetColorTexture(.08,.10,.14,1)
 return bg,edge
end
function U.Button(parent,palette)
 local b=CreateFrame('Button',nil,parent)
 local p=palette or U.palette
 local bg,edge=U.Surface(b,{background=p.surface or U.palette.surface,border=p.border})
 local text=U.Text(b,11,p.text)
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
 controls[b]={background=bg,edge=edge,text=text}
 return b
end
-- Search and note fields share the same inset and focus treatment.
function U.EditBox(parent)
 local edit=CreateFrame('EditBox',nil,parent)
 edit:SetFontObject('ChatFontNormal')
 if edit.SetFont then edit:SetFont('Fonts\\ARIALN.TTF',12,'') end
 edit:SetTextColor(unpack(U.palette.text))
 edit:SetTextInsets(9,9,2,2)
 edit:SetAutoFocus(false)
 local bg,edge=U.Surface(edit,{background={.015,.020,.028,1},border={.20,.24,.30,1}})
 edit:SetScript('OnEditFocusGained',function() paint(edge,U.palette.accent) end)
 edit:SetScript('OnEditFocusLost',function() paint(edge,U.palette.border) end)
 return edit
end
function U.StyleButton(button,palette,active)
 local parts=controls[button]
 if not parts then return end
 local p=palette or U.palette
 paint(parts.background,active and (p.rail or U.palette.surface) or (p.surface or U.palette.surface))
 paint(parts.edge,active and (p.accent or U.palette.accent) or (p.border or U.palette.border))
 parts.text:SetTextColor(unpack(active and (p.accent or U.palette.accent) or (p.text or U.palette.text)))
end
function U.CloseMenu()
 if popup then popup:Hide();popup=nil end
end
function U.Menu(anchor,title,entries,palette)
 U.CloseMenu()
 local p=palette or U.palette
 local shade=CreateFrame('Button',nil,UIParent)
 shade:SetAllPoints(UIParent);shade:SetFrameStrata('FULLSCREEN_DIALOG')
 shade:SetScript('OnClick',U.CloseMenu)
 local panel=CreateFrame('Frame',nil,shade,'BackdropTemplate')
 panel:SetSize(224,40+#entries*27)
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
 heading:SetPoint('TOPLEFT',12,-12);heading:SetWidth(175);heading:SetText(title)
 local close=U.Button(panel,p)
 close:SetPoint('TOPRIGHT',-6,-5);close:SetSize(24,24);close:SetText('x')
 close:SetScript('OnClick',U.CloseMenu)
 for i,entry in ipairs(entries) do
  local row=U.Button(panel,p)
  row:SetSize(208,25);row:SetPoint('TOPLEFT',8,-34-(i-1)*27)
  row:SetText(entry.label)
  U.StyleButton(row,p,entry.selected)
  row:SetEnabled(entry.enabled~=false)
  if entry.enabled==false then row:GetFontString():SetTextColor(.35,.4,.46) end
  row:SetScript('OnClick',function() U.CloseMenu();entry.action() end)
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
