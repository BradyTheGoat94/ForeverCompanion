-- Reference-inspired presentation only. Fonts/icons remain client-native;
-- bundled environment and crest art are original generated project assets.
local T={}
ForeverCompanionVisualTheme=T
T.citadel="Interface\\AddOns\\ForeverCompanion\\Media\\Citadel.tga"
T.crest="Interface\\AddOns\\ForeverCompanion\\Media\\Crest.tga"
function T.Font(widget,size,display)
 if widget and type(widget.SetFont)=="function" then
  pcall(widget.SetFont,widget,display and "Fonts\\MORPHEUS.TTF" or "Fonts\\FRIZQT__.TTF",size,"")
 end
end
local function strip(parent,x,y,w,h,r,g,b,a,layer)
 local t=parent:CreateTexture(nil,layer or "BORDER")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetSize(w,h)
 if t.SetColorTexture then t:SetColorTexture(r,g,b,a or 1) else t:SetTexture(r,g,b,a or 1) end
 return t
end
function T.Panel(parent,w,h)
 -- Charcoal rather than blue-gray; restrained brass edges and a lit title band.
 local bg=parent:CreateTexture(nil,"BACKGROUND");bg:SetAllPoints(parent)
 if bg.SetColorTexture then bg:SetColorTexture(0.023,0.025,0.030,1) end
 for i=0,7 do strip(parent,2,-2-i*4,w-4,4,0.12-i*.009,0.105-i*.007,0.077-i*.004,0.65) end
 strip(parent,0,0,w,1,0.87,0.71,0.40)
 strip(parent,0,-h+1,w,1,0.43,0.35,0.23)
 strip(parent,0,0,1,h,0.51,0.43,0.29)
 strip(parent,w-1,0,1,h,0.51,0.43,0.29)
 strip(parent,3,-3,w-6,1,0.36,0.30,0.21,0.55)
 strip(parent,12,-36,w-24,1,0.47,0.39,0.26,0.60)
end
function T.Banner(parent,x,y,w,h,alpha)
 local art=parent:CreateTexture(nil,"BORDER")
 art:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);art:SetSize(w,h);art:SetTexture(T.citadel)
 if art.SetTexCoord then art:SetTexCoord(0,1,0.02,0.72) end
 if art.SetAlpha then art:SetAlpha(alpha or 1) end
 return art
end
function T.Button(parent,w,h)
 local bg=strip(parent,0,0,w,h,0.025,0.028,0.034,1,"BACKGROUND")
 strip(parent,0,0,w,1,0.66,0.52,0.29,0.9)
 strip(parent,0,-h+1,w,1,0.30,0.27,0.21,1)
 return bg
end
