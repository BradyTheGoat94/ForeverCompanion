-- Reference-inspired presentation only. Fonts/icons remain client-native;
-- bundled environment and crest art are original generated project assets.
local T={}
ForeverCompanionVisualTheme=T
T.citadel="Interface\\AddOns\\ForeverCompanion\\Media\\Citadel.tga"
T.crest="Interface\\AddOns\\ForeverCompanion\\Media\\Crest.tga"
T.warrior="Interface\\AddOns\\ForeverCompanion\\Media\\Warrior.tga"
-- Shared type scale: display 22/18, body 13, labels 11. Native game fonts.
T.colors={background={.025,.032,.044,1},surface={.038,.048,.064,1},raised={.065,.080,.103,1},border={.23,.28,.35,1},accent={.82,.68,.43,1},text={.93,.95,.98,1},muted={.66,.72,.80,1}}
function T.Font(widget,size,display)
 if widget and type(widget.SetFont)=="function" then
  pcall(widget.SetFont,widget,display and "Fonts\\FRIZQT__.TTF" or "Fonts\\ARIALN.TTF",size,"")
 end
end
local function strip(parent,x,y,w,h,r,g,b,a,layer)
 local t=parent:CreateTexture(nil,layer or "BORDER")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetSize(w,h)
 if t.SetColorTexture then t:SetColorTexture(r,g,b,a or 1) else t:SetTexture(r,g,b,a or 1) end
 return t
end
function T.Panel(parent,w,h)
 -- One surface and one perimeter. No stacked bevels or competing corner art.
 local bg=parent:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(parent)
 bg:SetColorTexture(unpack(T.colors.surface))
 local band=strip(parent,1,-1,w-2,34,.065,.080,.103,1,"BORDER")
 local top=strip(parent,0,0,w,1,.25,.28,.33,1)
 local bottom=strip(parent,0,-h+1,w,1,.14,.17,.22,1)
 local left=strip(parent,0,0,1,h,.14,.17,.22,1)
 local right=strip(parent,w-1,0,1,h,.14,.17,.22,1)
 strip(parent,12,-36,w-24,1,.14,.17,.22,.8)
 parent.fcPanelEdges={bottom=bottom,left=left,right=right}
 parent.fcPanelBackground=bg
end
function T.ResizePanel(parent,height)
 parent:SetHeight(height)
 local edges=parent.fcPanelEdges
 if edges then
  edges.bottom:ClearAllPoints();edges.bottom:SetPoint("TOPLEFT",parent,"TOPLEFT",0,-height+1)
  edges.left:SetHeight(height);edges.right:SetHeight(height)
 end
end
function T.Banner(parent,x,y,w,h,alpha)
 local art=parent:CreateTexture(nil,"BORDER")
 art:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);art:SetSize(w,h);art:SetTexture(T.citadel)
 if art.SetTexCoord then art:SetTexCoord(0,1,0.02,0.72) end
 if art.SetAlpha then art:SetAlpha(alpha or 1) end
 return art
end
function T.Button(parent,w,h)
 local bg=strip(parent,0,0,w,h,.055,.069,.090,1,"BACKGROUND")
 strip(parent,0,0,w,1,.23,.28,.35,1)
 strip(parent,0,-h+1,w,1,.16,.20,.26,1)
 strip(parent,0,0,1,h,.16,.20,.26,1)
 strip(parent,w-1,0,1,h,.16,.20,.26,1)
 if parent.SetHighlightTexture then
  parent:SetHighlightTexture("Interface\\Buttons\\WHITE8X8","ADD")
  local highlight=parent.GetHighlightTexture and parent:GetHighlightTexture()
  if highlight then highlight:SetVertexColor(.3,.4,.55,.12) end
 end
 return bg
end

-- Selected list rows retain a quiet surface and a distinct edge cue.
function T.SelectRow(row,background,selected)
 row.fcSelected=selected and true or false
 if row.HookScript and not row.fcRowHover then
  row.fcRowHover=true
  row:HookScript('OnEnter',function()
   background:SetColorTexture(.13,.16,.21,1)
  end)
  row:HookScript('OnLeave',function()
   background:SetColorTexture(row.fcSelected and .11 or .045,row.fcSelected and .13 or .056,row.fcSelected and .17 or .075,1)
  end)
 end
 background:SetColorTexture(selected and .11 or .045,selected and .13 or .056,selected and .17 or .075,1)
 if not row.fcSelection then
  row.fcSelection=row:CreateTexture(nil,"ARTWORK")
  row.fcSelection:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
  row.fcSelection:SetPoint("BOTTOMLEFT",row,"BOTTOMLEFT",0,0)
  row.fcSelection:SetWidth(2)
  row.fcSelection:SetColorTexture(unpack(T.colors.accent))
 end
 row.fcSelection:SetShown(selected)
end
