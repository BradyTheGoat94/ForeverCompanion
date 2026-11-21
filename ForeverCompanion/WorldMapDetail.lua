-- Project client minimap imagery onto the native world-map canvas.
local D={}
ForeverCompanionWorldMapDetail=D
local layer,projection
local textures={}
local tileSize=1600/3

local function finite(n)
 return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and math.abs(n)<math.huge
end
local function world(map,x,y)
 local api=C_Map and C_Map.GetWorldPosFromMapPos
 if not api or not CreateVector2D then return end
 local ok,id,point=pcall(api,map,CreateVector2D(x,y))
 if not ok or not finite(id) or not point or (issecretvalue and issecretvalue(point)) then return end
 local good,wx,wy=pcall(point.GetXY,point)
 if good and finite(wx) and finite(wy) then return id,wx,wy end
end

function D.Layout(map,index)
 -- Sample inside the zone, then extrapolate edges. Reject transforms that
 -- change continents, swap axes, rotate, or vary across the map.
 local id,north,west=world(map,.25,.25)
 local eastID,eastNorth,east=world(map,.75,.25)
 local southID,south,southWest=world(map,.25,.75)
 local midID,midNorth,midWest=world(map,.5,.5)
 local files=id and index[id]
 if not files or eastID~=id or southID~=id or midID~=id then return end
 local spanX,spanY=2*(west-east),2*(north-south)
 if spanX<=0 or spanY<=0 or math.abs(eastNorth-north)>1 or math.abs(southWest-west)>1
  or math.abs(midNorth-(north+south)/2)>1 or math.abs(midWest-(west+east)/2)>1 then return end
 west,north=west+spanX/4,north+spanY/4
 local xMin,yMin=32-west/tileSize,32-north/tileSize
 local xMax,yMax=xMin+spanX/tileSize,yMin+spanY/tileSize
 local firstX,lastX=math.max(0,math.floor(xMin)),math.min(63,math.ceil(xMax)-1)
 local firstY,lastY=math.max(0,math.floor(yMin)),math.min(63,math.ceil(yMax)-1)
 if firstX>lastX or firstY>lastY or (lastX-firstX+1)*(lastY-firstY+1)>384 then return end
 local tiles={}
 for ix=firstX,lastX do
  for iy=firstY,lastY do
   local file=files[ix*64+iy]
   if file then
    local left,right=math.max(xMin,ix),math.min(xMax,ix+1)
    local top,bottom=math.max(yMin,iy),math.min(yMax,iy+1)
    if left<right and top<bottom then
     tiles[#tiles+1]={
      file=file,left=(left-xMin)/(xMax-xMin),right=(right-xMin)/(xMax-xMin),
      top=(top-yMin)/(yMax-yMin),bottom=(bottom-yMin)/(yMax-yMin),
      u1=left-ix,u2=right-ix,v1=top-iy,v2=bottom-iy,
     }
    end
   end
  end
 end
 return tiles
end
function D.Hide()
 if layer then layer:Hide() end
end
function D.Refresh(map,canvas,mapID,enabled)
 local types=Enum and Enum.UIMapType
 if not enabled or not types or not C_Map or not C_Map.GetMapInfo or not map.GetCanvasZoomPercent then D.Hide();return end
 local ok,zoom=pcall(map.GetCanvasZoomPercent,map)
 if not ok or not finite(zoom) or zoom<=.18 then D.Hide();return end
 local index=ForeverCompanionMinimapTiles
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 if not index or not finite(width) or not finite(height) or width<=0 or height<=0 then D.Hide();return end
 if not layer or layer:GetParent()~=canvas then
  D.Hide()
  layer=CreateFrame('Frame',nil,canvas)
  layer:SetAllPoints(canvas)
  layer:SetFrameLevel(canvas:GetFrameLevel()+20)
  layer:EnableMouse(false)
  textures={}
  projection=nil
 end
 if not projection or projection.mapID~=mapID or projection.width~=width or projection.height~=height then
  for _,texture in ipairs(textures) do texture:Hide() end
  projection={mapID=mapID,width=width,height=height}
  local readable,info=pcall(C_Map.GetMapInfo,mapID)
  if readable and info and (not issecretvalue or not issecretvalue(info)) and (info.mapType==types.Zone or info.mapType==types.City) then
   projection.tiles=D.Layout(mapID,index)
  end
  for i,tile in ipairs(projection.tiles or {}) do
   local texture=textures[i]
   if not texture then texture=layer:CreateTexture(nil,'ARTWORK');textures[i]=texture end
   texture:ClearAllPoints()
   texture:SetPoint('TOPLEFT',layer,'TOPLEFT',tile.left*width,-tile.top*height)
   texture:SetPoint('BOTTOMRIGHT',layer,'TOPLEFT',tile.right*width,-tile.bottom*height)
   texture:SetTexCoord(tile.u1,tile.u2,tile.v1,tile.v2)
   if texture:SetTexture(tile.file)~=false then texture:Show() end
  end
 end
 if projection.tiles and #projection.tiles>0 then
  layer:SetAlpha(math.min(1,(zoom-.18)/.42))
  layer:Show()
 else D.Hide() end
end
