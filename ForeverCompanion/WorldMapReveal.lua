
-- Paint unrevealed patches using textures from the installed client.
local R={}
ForeverCompanionMapReveal=R
local surface,cache
local textures={}
local function visible(value) return not (issecretvalue and issecretvalue(value)) end
local function read(api,...)
 if type(api)~='function' then return end
 local ok,result=pcall(api,...);if ok and visible(result) then return result end
end
local function extent(value)
 return visible(value) and type(value)=='number' and value>0 and value<16384
end
local function padded(size)
 local span=1
 while span<size do span=span*2 end
 return span
end
function R.Layout(patches,layer,explored)
 if type(patches)~='table' or type(layer)~='table' then return {} end
 local width,height,stepX,stepY=layer.layerWidth,layer.layerHeight,layer.tileWidth,layer.tileHeight
 if not extent(width) or not extent(height) or not extent(stepX) or not extent(stepY) then return {} end
 local known={}
 for _,patch in ipairs(explored or {}) do
  if visible(patch) and type(patch)=='table' and visible(patch.isShownByMouseOver) and not patch.isShownByMouseOver
     and extent(patch.textureWidth) and extent(patch.textureHeight)
     and visible(patch.offsetX) and type(patch.offsetX)=='number' and visible(patch.offsetY) and type(patch.offsetY)=='number' then
   known[('%d:%d:%d:%d'):format(patch.textureWidth,patch.textureHeight,patch.offsetX,patch.offsetY)]=true
  end
 end
 local keys={}
 for key in pairs(patches) do if not known[key] then keys[#keys+1]=key end end
 table.sort(keys)
 local result={}
 for _,key in ipairs(keys) do
  local w,h,x,y=key:match('^(%d+):(%d+):(%d+):(%d+)$')
  w,h,x,y=tonumber(w),tonumber(h),tonumber(x),tonumber(y)
  if w and w>0 and h>0 and x<width and y<height then
   local cols,rows=math.ceil(w/stepX),math.ceil(h/stepY)
   local files={}
   for value in patches[key]:gmatch('%d+') do files[#files+1]=tonumber(value) end
   if cols*rows==#files and #result+#files<=512 then
    for row=0,rows-1 do
     for col=0,cols-1 do
      local left,top=x+col*stepX,y+row*stepY
      local tileWidth,tileHeight=math.min(stepX,w-col*stepX),math.min(stepY,h-row*stepY)
      local right,bottom=math.min(width,left+tileWidth),math.min(height,top+tileHeight)
      if left<right and top<bottom then
       result[#result+1]={file=files[row*cols+col+1],x=left/width,y=top/height,
        right=right/width,bottom=bottom/height,u=(right-left)/padded(tileWidth),v=(bottom-top)/padded(tileHeight)}
      end
     end
    end
   end
  end
 end
 return result
end
function R.Hide() if surface then surface:Hide() end end
function R.Invalidate() cache=nil end
function R.Refresh(canvas,mapID,enabled)
 if not enabled or not C_Map or not canvas then R.Hide();return end
 local art=read(C_Map.GetMapArtID,mapID)
 local patches=art and ForeverCompanionPaintedReveal and ForeverCompanionPaintedReveal[art]
 if not patches then R.Hide();return end
 local width,height=canvas:GetWidth(),canvas:GetHeight()
 if not extent(width) or not extent(height) then R.Hide();return end
 if not surface or surface:GetParent()~=canvas then
  R.Hide()
  surface=CreateFrame('Frame',nil,canvas)
  surface:SetAllPoints(canvas);surface:EnableMouse(false)
  surface:SetFrameLevel(canvas:GetFrameLevel()+3)
  cache=nil;textures={}
 end
 if not cache or cache.art~=art or cache.map~=mapID or cache.width~=width or cache.height~=height then
  for _,texture in ipairs(textures) do texture:Hide() end
  local layers=read(C_Map.GetMapArtLayers,mapID)
  local explored=read(C_MapExplorationInfo and C_MapExplorationInfo.GetExploredMapTextures,mapID)
  local tiles=R.Layout(patches,type(layers)=='table' and layers[1],type(explored)=='table' and explored)
  cache={art=art,map=mapID,width=width,height=height,count=0}
  for i,tile in ipairs(tiles) do
   local texture=textures[i] or surface:CreateTexture(nil,'ARTWORK')
   textures[i]=texture
   texture:ClearAllPoints()
   texture:SetPoint('TOPLEFT',surface,'TOPLEFT',tile.x*width,-tile.y*height)
   texture:SetPoint('BOTTOMRIGHT',surface,'TOPLEFT',tile.right*width,-tile.bottom*height)
   texture:SetTexCoord(0,tile.u,0,tile.v)
   if texture:SetTexture(tile.file,nil,nil,'TRILINEAR')~=false then texture:Show();cache.count=cache.count+1 end
  end
 end
 surface:SetShown(cache.count>0)
end
