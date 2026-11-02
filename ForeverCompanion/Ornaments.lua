-- Shared, original, texture-only dark-fantasy inlays for read-only guide cards.
-- Uses basic WoW UI texture methods and no protected actions or external assets.
local O={}
ForeverCompanionOrnaments=O
local function strip(frame,x,y,w,h,r,g,b,a)
  local t=frame:CreateTexture(nil,"ARTWORK")
  t:SetPoint("TOPLEFT",frame,"TOPLEFT",x,y)
  t:SetSize(w,h)
  if t.SetColorTexture then t:SetColorTexture(r,g,b,a or 1)
  else t:SetTexture(r,g,b,a or 1) end
  return t
end
function O.Inlay(frame,w,h)
  if not frame or type(w)~="number" or type(h)~="number" or w<100 or h<80 then return false end
  local gold={0.89,0.65,0.29,0.87}
  local dim={0.46,0.32,0.17,0.72}
  -- Thin secondary inner border, intentionally inset from the primary card edge.
  strip(frame,7,-6,w-14,1,dim[1],dim[2],dim[3],dim[4])
  strip(frame,7,-h+7,w-14,1,dim[1],dim[2],dim[3],dim[4])
  strip(frame,6,-7,1,h-14,dim[1],dim[2],dim[3],dim[4])
  strip(frame,w-7,-7,1,h-14,dim[1],dim[2],dim[3],dim[4])
  -- Symmetric gilded corner brackets.
  for _,x in ipairs({12,w-31}) do
    strip(frame,x,-11,19,2,gold[1],gold[2],gold[3],gold[4])
    strip(frame,x,-h+13,19,2,gold[1],gold[2],gold[3],gold[4])
  end
  strip(frame,12,-11,2,14,gold[1],gold[2],gold[3],gold[4])
  strip(frame,w-14,-11,2,14,gold[1],gold[2],gold[3],gold[4])
  strip(frame,12,-h+25,2,14,gold[1],gold[2],gold[3],gold[4])
  strip(frame,w-14,-h+25,2,14,gold[1],gold[2],gold[3],gold[4])
  -- Dark velvet divider beneath the heading and tiny blue jewel at the far right.
  strip(frame,16,-34,w-32,1,0.48,0.34,0.18,0.50)
  strip(frame,w-29,-22,4,4,0.31,0.64,0.76,0.90)
  strip(frame,w-28,-23,2,6,0.66,0.83,0.85,0.65)
  return true
end

-- Rich original ornamentation built from native textures; no external art assets.
function O.Corners(frame,w,h)
 if not frame or type(w)~="number" or type(h)~="number" or w<80 or h<35 then return false end
 local gold={0.96,0.75,0.36}
 for _,x in ipairs({3,w-28}) do
  -- Both lower brackets point inward, not below the frame boundary.
  strip(frame,x,-3,25,2,gold[1],gold[2],gold[3],0.95)
  strip(frame,x,-3,2,25,gold[1],gold[2],gold[3],0.95)
  strip(frame,x,-h+5,25,2,gold[1],gold[2],gold[3],0.95)
  strip(frame,x,-h+28,2,25,gold[1],gold[2],gold[3],0.95)
  strip(frame,x+5,-8,13,1,0.75,0.52,0.24,0.75)
  strip(frame,x+5,-h+10,13,1,0.75,0.52,0.24,0.75)
 end
 return true
end
function O.Hero(frame,w,h)
 if not frame or w<160 or h<70 then return false end
 strip(frame,2,-2,w-4,2,0.97,0.73,0.32,0.95)
 strip(frame,2,-h+4,w-4,2,0.67,0.46,0.21,0.84)
 strip(frame,2,-3,2,h-6,0.64,0.46,0.24,0.85)
 strip(frame,w-4,-3,2,h-6,0.64,0.46,0.24,0.85)
 strip(frame,10,-9,w-20,1,0.50,0.35,0.18,0.8)
 strip(frame,10,-h+11,w-20,1,0.50,0.35,0.18,0.8)
 O.Corners(frame,w,h)
 -- Small symmetric inset gems and heraldic gold strokes.
 for _,x in ipairs({36,w-44}) do
  strip(frame,x,-12,8,2,0.93,0.68,0.27,0.95)
  strip(frame,x+3,-9,2,8,0.28,0.63,0.79,0.85)
 end
 return true
end
function O.Ribbon(frame,w,y)
 if not frame or w<100 then return false end
 strip(frame,16,y,w-32,2,0.66,0.44,0.18,0.8)
 strip(frame,16,y-4,w-32,1,0.24,0.18,0.11,0.9)
 strip(frame,12,y+2,7,7,0.90,0.65,0.29,0.95)
 strip(frame,w-19,y+2,7,7,0.90,0.65,0.29,0.95)
 return true
end

-- Unified low-contrast ornamental panel treatment for secondary surfaces.
function O.Panel(frame,w,h)
 if not frame or type(w)~="number" or type(h)~="number" or w<90 or h<35 then return false end
 strip(frame,0,0,w,1,0.73,0.54,0.26,0.78)
 strip(frame,0,-h+1,w,1,0.40,0.30,0.19,0.75)
 strip(frame,0,0,1,h,0.40,0.30,0.19,0.75)
 strip(frame,w-1,0,1,h,0.40,0.30,0.19,0.75)
 strip(frame,5,-5,14,1,0.96,0.72,0.33,0.85)
 strip(frame,5,-5,1,11,0.96,0.72,0.33,0.85)
 strip(frame,w-19,-5,14,1,0.96,0.72,0.33,0.85)
 strip(frame,w-6,-5,1,11,0.96,0.72,0.33,0.85)
 return true
end
