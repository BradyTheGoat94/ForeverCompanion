
dofile('ForeverCompanion/WorldMapRevealData.lua')
dofile('ForeverCompanion/WorldMapReveal.lua')
local R=ForeverCompanionMapReveal
local patches={['316:256:0:0']='91, 92',['230:300:373:60']='95, 96',['200:100:10:240']='97'}
local layer={layerWidth=576,layerHeight=320,tileWidth=256,tileHeight=256}
local explored={{textureWidth=200,textureHeight=100,offsetX=10,offsetY=240}}
local tiles=R.Layout(patches,layer,explored)
assert(#tiles==4)
local right
for _,tile in ipairs(tiles) do
 assert(tile.file~=97 and tile.right<=1 and tile.bottom<=1)
 if tile.file==92 then right=tile end
end
assert(right and right.x==256/576 and right.u==60/64)
assert(#R.Layout(patches,nil,explored)==0)
local surface,loads=0,0
local function noop() end
CreateFrame=function(_,_,parent)
 surface={GetParent=function() return parent end,SetAllPoints=noop,EnableMouse=noop,SetFrameLevel=noop,
  SetShown=function(self,shown) self.shown=shown end,Hide=function(self) self.shown=false end}
 function surface:CreateTexture()
  return {ClearAllPoints=noop,SetPoint=noop,SetTexCoord=noop,Hide=noop,Show=noop,
   SetTexture=function(_,file,_,_,filter) assert(file>0 and filter=='TRILINEAR');loads=loads+1 end}
 end
 return surface
end
local canvas={GetWidth=function() return 576 end,GetHeight=function() return 320 end,GetFrameLevel=function() return 7 end}
local art
ForeverCompanionPaintedReveal[99701]=patches
C_Map={GetMapArtID=function() return art end,GetMapArtLayers=function() return {layer} end}
C_MapExplorationInfo={GetExploredMapTextures=function() return explored end}
R.Refresh(canvas,1,true);assert(surface==0)
art=99701
R.Refresh(canvas,1,true);assert(surface.shown and loads==4)
R.Refresh(canvas,1,true);assert(loads==4)
explored[2]={textureWidth=316,textureHeight=256,offsetX=0,offsetY=0}
R.Invalidate();R.Refresh(canvas,1,true);assert(loads==6)
R.Refresh(canvas,1,false);assert(not surface.shown)
print('PASS: painted map reveal before exploration, edge cropping, native fog toggle and event refresh')

