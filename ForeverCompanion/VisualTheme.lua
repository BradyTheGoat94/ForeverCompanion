-- Reference-inspired presentation only. Fonts/icons remain client-native;
-- bundled environment and crest art are original generated project assets.
local T={}
ForeverCompanionVisualTheme=T
T.citadel="Interface\\AddOns\\ForeverCompanion\\Media\\Citadel.tga"
T.crest="Interface\\AddOns\\ForeverCompanion\\Media\\Crest.tga"
T.warrior="Interface\\AddOns\\ForeverCompanion\\Media\\Warrior.tga"
-- Each destination has its own accent and environmental artwork.
T.environments={
 forest={index=1,rgb={.37,.88,.62}}, forge={index=2,rgb={1,.63,.31}},
 vault={index=3,rgb={.86,.61,1}}, arcane={index=4,rgb={.46,.79,1}},
 war={index=5,rgb={1,.49,.41}}, harbor={index=6,rgb={.41,.91,.90}},
}
local destinations={
 Overview='forest',Journey='forest',Quests='forest',Alts='forest',
 Leveling='arcane',Training='arcane',Legacy='arcane',
 Dungeons='vault',Loot='vault',Gear='vault',
 Professions='forge',Materials='forge',Bank='harbor',
 PvP='war',Meter='war',Settings='harbor',Map='forest',
}
local classColors={
 WARRIOR={.78,.61,.43},PALADIN={.96,.55,.73},HUNTER={.67,.83,.45},
 ROGUE={1,.96,.41},PRIEST={.95,.95,1},SHAMAN={.29,.65,1},
 MAGE={.37,.80,.98},WARLOCK={.76,.63,.98},DRUID={1,.59,.28},
}
local palettes={}
function T.Destination(page)
 return T.environments[destinations[page] or 'harbor']
end
function T.ClassAccent(token)
 return classColors[token] or T.environments.arcane.rgb
end
function T.NavigationPalette(page)
 local environment=T.Destination(page)
 local index=environment.index
 if not palettes[index] then
  local r,g,b=unpack(environment.rgb)
  palettes[index]={flat=true,accent={r,g,b,1},border={r*.38,g*.38,b*.38,1},
   surface={.045+r*.10,.045+g*.10,.065+b*.10,1},
   rail={.045+r*.30,.045+g*.30,.065+b*.30,1}}
 end
 return palettes[index]
end
T.environmentAtlas="Interface\\AddOns\\ForeverCompanion\\Media\\Environments.tga"
function T.PaintEnvironment(texture,page,alpha,spread)
 local row=T.Destination(page).index-1
 local left,top=(row%3)/3,math.floor(row/3)/2
 local half=spread or .14
 texture:SetTexture(T.environmentAtlas)
 texture:SetTexCoord(left+.006,left+1/3-.006,top+.25-half,top+.25+half)
 texture:SetAlpha(alpha or .8)
end
function T.EnvironmentArt(parent,point,x,y,w,h,page,alpha,spread,layer,sublevel)
 local art=parent:CreateTexture(nil,layer or 'BORDER',nil,sublevel or 0)
 art:SetPoint(point or 'TOPLEFT',parent,point or 'TOPLEFT',x,y);art:SetSize(w,h)
 T.PaintEnvironment(art,page,alpha,spread)
 return art
end

-- Shared type scale: display 22/18, body 13, labels 11. Native game fonts.
T.colors={background={.027,.037,.052,1},surface={.043,.063,.086,1},raised={.081,.115,.154,1},border={.21,.26,.31,1},accent={.96,.77,.46,1},text={.94,.95,.97,1},muted={.70,.75,.82,1}}
function T.Font(widget,size,display)
 if widget and type(widget.SetFont)=="function" then
  size=size or 12
  pcall(widget.SetFont,widget,(display or size>=15) and "Fonts\\FRIZQT__.TTF" or "Fonts\\ARIALN.TTF",size,"")
 end
end
local function strip(parent,x,y,w,h,r,g,b,a,layer)
 local t=parent:CreateTexture(nil,layer or "BORDER")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetSize(w,h)
 if t.SetColorTexture then t:SetColorTexture(r,g,b,a or 1) else t:SetTexture(r,g,b,a or 1) end
 return t
end
function T.Panel(parent,w,h)
 -- Inset journal sections with a raised metal rim.
 local bg=parent:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(parent)
 bg:SetColorTexture(unpack(T.colors.surface))
 strip(parent,1,-1,w-2,34,.081,.115,.154,1,"BORDER")
 strip(parent,1,-1,3,33,.84,.64,.32,1,"ARTWORK")
 strip(parent,4,-34,w-6,1,.27,.37,.39,.85,"ARTWORK")
 local top=strip(parent,0,0,w,1,.25,.28,.33,1)
 local bottom=strip(parent,0,-h+1,w,1,.14,.17,.22,1)
 local left=strip(parent,0,0,1,h,.14,.17,.22,1)
 local right=strip(parent,w-1,0,1,h,.14,.17,.22,1)
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
