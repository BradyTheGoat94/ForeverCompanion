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
