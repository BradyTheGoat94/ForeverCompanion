-- Screen-space clusters retain real provider coordinates for navigation.
local C={}
ForeverCompanionServiceClusters=C
function C.Build(points,width,height,radius)
 local ordered={}
 for _,p in ipairs(points or {}) do
  if type(p.x)=='number' and type(p.y)=='number' and p.x>=0 and p.x<=1 and p.y>=0 and p.y<=1
   and type(p.symbol)=='string' and type(p.label)=='string' then ordered[#ordered+1]=p end
 end
 table.sort(ordered,function(a,b)
  if a.x~=b.x then return a.x<b.x end
  if a.y~=b.y then return a.y<b.y end
  if a.symbol~=b.symbol then return a.symbol<b.symbol end
  return a.label<b.label
 end)
 local cells,groups={},{}
 for _,p in ipairs(ordered) do
  local x,y=p.x*width,p.y*height
  local cx,cy=math.floor(x/radius),math.floor(y/radius)
  local nearest,best=nil,radius*radius
  for dx=-1,1 do for dy=-1,1 do
   for _,g in ipairs(cells[(cx+dx)..':'..(cy+dy)] or {}) do
    local distance=(x-g.x)^2+(y-g.y)^2
    if distance<=best then nearest,best=g,distance end
   end
  end end
  if nearest then nearest[#nearest+1]=p
  else
   local g={p,x=x,y=y}
   groups[#groups+1]=g
   local key=cx..':'..cy
   cells[key]=cells[key] or {}
   cells[key][#cells[key]+1]=g
  end
 end
 return groups
end
