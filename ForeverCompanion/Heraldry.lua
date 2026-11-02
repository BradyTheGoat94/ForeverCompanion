-- Original native-UI heraldic monogram for Forever Companion.
-- Drawn entirely with standard WoW textures/fontstrings; no external artwork
-- or unsupported animation API is required.
local H={}
ForeverCompanionHeraldry=H

local function paint(t,r,g,b,a)
  if t.SetColorTexture then t:SetColorTexture(r,g,b,a or 1)
  else t:SetTexture(r,g,b,a or 1) end
end
local function strip(parent,x,y,w,h,color)
  local t=parent:CreateTexture(nil,"ARTWORK")
  t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  t:SetSize(w,h)
  paint(t,color[1],color[2],color[3],color[4])
  return t
end
function H.Create(parent,x,y,size)
  size=tonumber(size) or 60
  size=math.max(42,math.min(100,size))
  local frame=CreateFrame("Frame",nil,parent)
  frame:SetSize(size,size)
  frame:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
  local bg=frame:CreateTexture(nil,"BACKGROUND")
  bg:SetAllPoints(frame)
  paint(bg,0.030,0.042,0.061,1)
  local gold={0.90,0.68,0.31,1}
  local dim={0.47,0.34,0.17,1}
  local edge=math.max(2,math.floor(size/24))
  strip(frame,0,0,size,edge,gold)
  strip(frame,0,-size+edge,size,edge,gold)
  strip(frame,0,0,edge,size,gold)
  strip(frame,size-edge,0,edge,size,gold)
  local inset=math.floor(size*0.12)
  strip(frame,inset,-inset,size-2*inset,1,dim)
  strip(frame,inset,-size+inset,size-2*inset,1,dim)
  strip(frame,inset,-inset,1,size-2*inset,dim)
  strip(frame,size-inset-1,-inset,1,size-2*inset,dim)
  -- Stepped crown detail and side finials make this a distinct heraldic mark,
  -- rather than a reused stock item icon.
  local center=math.floor(size/2)
  strip(frame,center-10,-4,20,2,gold)
  strip(frame,center-6,-7,12,2,gold)
  strip(frame,5,-math.floor(size*0.35),6,2,gold)
  strip(frame,size-11,-math.floor(size*0.35),6,2,gold)
  local initials=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  initials:SetPoint("CENTER",frame,"CENTER",0,0)
  initials:SetText("FC")
  initials:SetTextColor(0.99,0.82,0.46)
  frame.mark=initials
  return frame
end
