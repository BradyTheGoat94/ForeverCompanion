dofile('ForeverCompanion/WorldMapTileIndex.lua')
assert(next(ForeverCompanionMinimapTiles[0]) and next(ForeverCompanionMinimapTiles[1]))
dofile('ForeverCompanion/WorldMapDetail.lua')
local D=ForeverCompanionWorldMapDetail
local span=1600/3
local index={[0]={[32*64+31]=777}}
CreateVector2D=function(x,y) return {x=x,y=y} end
local function vec(x,y) return {GetXY=function() return x,y end} end
local skew=false
C_Map={
 GetMapInfo=function(id) return {mapType=id==1429 and 3 or 2} end,
 GetWorldPosFromMapPos=function(_,v)
  return 0,vec((.5-v.y+(skew and v.x*.1 or 0))*span,(.5-v.x)*span)
 end,
}
local tiles=D.Layout(1429,index)
assert(#tiles==1 and tiles[1].file==777)
local t=tiles[1]
assert(t.left==.5 and t.right==1 and t.top==0 and t.bottom==.5)
assert(t.u1==0 and t.u2==.5 and t.v1==.5 and t.v2==1,'edge tiles crop rather than stretch')
skew=true;assert(not D.Layout(1429,index),'a rotated or skewed extent falls back to native art');skew=false
Enum={UIMapType={Zone=3,City=4}}
local layer,textureCount
local function noop() end
CreateFrame=function(_,_,parent)
 layer={
  GetParent=function() return parent end,SetAllPoints=noop,SetFrameLevel=noop,EnableMouse=noop,
  SetAlpha=function(self,alpha) self.alpha=alpha end,Show=function(self) self.shown=true end,
  Hide=function(self) self.shown=false end,
  CreateTexture=function()
   textureCount=(textureCount or 0)+1
   return {ClearAllPoints=noop,SetPoint=noop,SetTexCoord=noop,SetTexture=function(_,file) assert(file==777) end,Hide=noop,Show=noop}
  end,
 }
 return layer
end
local z=.1
local map={GetCanvasZoomPercent=function() return z end}
local canvas={GetWidth=function() return 500 end,GetHeight=function() return 400 end,GetFrameLevel=function() return 1 end}
ForeverCompanionMinimapTiles=index
D.Refresh(map,canvas,1429,true);assert(not layer)
z=.4;D.Refresh(map,canvas,1429,true);assert(layer.shown and layer.alpha>0 and layer.alpha<1 and textureCount==1)
z=1;D.Refresh(map,canvas,1429,true);assert(layer.shown and layer.alpha==1 and textureCount==1)
D.Refresh(map,canvas,1,true);assert(not layer.shown,'no detail at continent scale')
D.Refresh(map,canvas,1429,true);assert(layer.shown and textureCount==1)
D.Refresh(map,canvas,1429,false);assert(not layer.shown)
print('PASS: standalone minimap tile clipping, zone guards, zoom fade and pool reuse')
