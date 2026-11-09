local objects={};local named={}
local function widget(name)
 local w={shown=true};objects[#objects+1]=w;if name then named[name]=w end
 function w:Show() self.shown=true end;function w:Hide() self.shown=false end
 function w:IsShown() return self.shown end;function w:SetShown(v) self.shown=v end
 function w:SetScript(k,f) self[k]=f end;function w:SetSize(x,y) self.width=x;self.height=y end
 function w:GetWidth() return self.width end;function w:GetHeight() return self.height end
 function w:SetPoint(...) self.point={...} end;function w:ClearAllPoints() self.point=nil end
 function w:EnableMouse(v) self.mouse=v end;function w:SetText(v) self.text=v end
 function w:SetTexture(v) self.texture=v end;function w:SetAlpha(v) self.alpha=v end
 function w:SetTexCoord(...) self.crop={...} end;function w:SetDesaturated(v) self.gray=v end
 function w:SetRotation(v) self.rotation=v end;function w:CreateTexture() return widget() end
 function w:GetCenter() return 100,200 end;function w:GetEffectiveScale() return 1 end
 for _,k in ipairs({'EnableMouseWheel','SetVertexColor','SetHeight','SetWordWrap','SetFrameStrata','SetMovable','SetClampedToScreen','RegisterForDrag','RegisterEvent','SetWidth','StartMoving','StopMovingOrSizing'}) do w[k]=function() end end
 return w
end
CreateFrame=function(_,name) return widget(name) end
UIParent=widget();UIParent:SetSize(1920,1080)
ForeverCompanionDB={}
ForeverCompanionInterface={palette={muted={}},Text=function() return widget() end,Button=function() return widget() end,Menu=function() end}
local id,art,valid=12,1,true;local reads=0
local layer={layerWidth=1002,layerHeight=668,tileWidth=256,tileHeight=256}
local files={};for i=1,12 do files[i]=i end
C_Map={GetBestMapForUnit=function() return id end,GetMapArtID=function() return art end,
 GetMapArtLayers=function() reads=reads+1;if valid then return {layer} end end,
 GetMapArtLayerTextures=function() return files end,GetMapInfo=function() return {name='Test zone'} end,
 GetPlayerMapPosition=function() return {GetXY=function() return .25,.75 end} end}
GetPlayerFacing=function() return 1 end
dofile('ForeverCompanion/MapOverlay.lua');local m=ForeverCompanionMapOverlay
local l=m.Layout(layer,files,501);assert(#l==12 and l.height==334)
assert(l[5].file==5 and l[5].x==0 and l[5].y==128,'row-major order')
assert(l[4].w==117 and l[4].u==234/256 and l[12].v==156/256,'crop edge tiles')
assert(not m.Layout(layer,{1},600));assert(not m.Layout(layer,files,0/0))
assert(not m.Layout({layerWidth=1e6,layerHeight=1,tileWidth=1,tileHeight=1},files,600))
m.Toggle(true);local f=named.ForeverCompanionMapOverlayFrame
assert(f.shown and f.mouse==false and f.width==600)
local n=reads;m.Refresh();assert(reads==n,'cached artwork is not rebuilt every tick')
local count=#objects;for i=1,100 do m.Refresh() end;assert(#objects==count,'textures remain bounded')
m.Command('edit');assert(f.mouse);m.Command('lock');assert(not f.mouse)
art=2;m.Refresh();assert(reads>n,'phase artwork changes refresh tiles')
valid=false;id=13;m.Refresh();for _,w in ipairs(objects) do if w.texture and type(w.texture)=='number' then assert(not w.shown,'old terrain cleared') end end
ForeverCompanionDB.mapOverlay.opacity=99;ForeverCompanionDB.mapOverlay.width=-100
valid=true;m.Refresh(true);assert(f.width==300 and ForeverCompanionDB.mapOverlay.opacity==.8)
m.Toggle(false);n=reads;m.Refresh();assert(reads==n,'hidden refresh does no map work')
m.Toggle(true);assert(not f.mouse,'reopening always starts click-through')
m.Command('hide');assert(not f.shown and not ForeverCompanionDB.mapOverlay.visible)
print('PASS: transparent overlay geometry, caching, stale clearing, bounded textures and interaction')

dofile('ForeverCompanion/ServiceClusters.lua')
ForeverCompanionTownServices={ForMap=function() return {{x=.2,y=.2,label='Repair',symbol='R'},{x=.201,y=.201,label='Vendor',symbol='V'}} end}
assert(m.Preset('town') and ForeverCompanionDB.mapOverlay.services and not ForeverCompanionDB.mapOverlay.quests and f.width==420)
local count=0;for _,o in ipairs(objects) do if o.shown and o.text=='2' then count=count+1 end end
assert(count==1,'nearby mixed service types receive a shared cluster count')
local before=#objects;for i=1,50 do m.Refresh() end;assert(#objects==before,'cluster badges and icons are reused')
assert(m.Preset('exploring') and f.width==780 and not ForeverCompanionDB.mapOverlay.services)
assert(m.Preset('questing') and ForeverCompanionDB.mapOverlay.quests and not ForeverCompanionDB.mapOverlay.services)
assert(not m.Preset('unknown'))
C_Map.GetPlayerMapPosition=function() return nil end;m.Refresh()
for _,o in ipairs(objects) do if o.texture=='Interface\\Minimap\\MinimapArrow' then assert(not o.shown,'lost player coordinates clear the overlay arrow') end end

assert(m.ContextAlpha(true,{fadeCombat=true},false)==.3)
assert(m.ContextAlpha(false,{fadeCombat=true},false)==1)
assert(m.ContextAlpha(true,{fadeCombat=true},true)==1,'manual override keeps full visibility')

UIParent:SetSize(500,400);m.Refresh();assert(f.width<=450 and f.height<=320,'overlay refits after a viewport change without a manual toggle')
id=14;f.OnUpdate(f,.2)
for _,o in ipairs(objects) do if type(o.texture)=='number' then assert(not o.shown,'fast updates clear old-zone art before the slower rebuild') end end
m.Refresh();assert(f.shown)

local view={zoom=2,centerX=.5,centerY=.5};local px,py,visible=m.Project(.5,.5,600,400,view)
assert(px==300 and py==200 and visible)
assert(not select(3,m.Project(0,0,600,400,view)),'off-view markers are hidden')
local tile={x=0,y=0,w=300,h=200,u=1,v=1};local clip=m.Clip(tile,600,400,view)
assert(clip.x==0 and clip.y==0 and clip.w==300 and clip.h==200 and clip.u1==.5 and clip.v1==.5,'zoom crops tile UVs rather than stretching the full map')
assert(m.SetZoom(4));assert(ForeverCompanionDB.mapOverlay.zoom==4);m.Pan(99,-99)
assert(ForeverCompanionDB.mapOverlay.centerX==.875 and ForeverCompanionDB.mapOverlay.centerY==.125,'pan remains within the zoomed map')
assert(not m.SetZoom(0/0));m.Inspect(true);assert(f.mouse);m.Inspect(false);assert(not f.mouse)
m.SetZoom(1);assert(ForeverCompanionDB.mapOverlay.centerX==.5 and ForeverCompanionDB.mapOverlay.centerY==.5)

assert(m.FacingAngle(0,600,400)==0)
assert(m.FacingAngle(math.pi/2,600,400)==math.pi/2,'west-facing must rotate counterclockwise, not east')
assert(math.abs(m.FacingAngle(math.pi/2,600,400,900,600)-math.pi/2)<.00001)
assert(math.abs(m.FacingAngle(math.pi/4,600,400,600,800)-math.atan2(1,.5))<.00001,'world/art aspect correction')
assert(not m.FacingAngle(nil,600,400),'unavailable facing must not imply north')
local detail=m.ExplorationLayout(layer,{{offsetX=100,offsetY=50,textureWidth=300,textureHeight=270,fileDataIDs={101,102,103,104}}},501)
assert(#detail==4 and detail[1].x==50 and detail[1].y==25)
assert(detail[2].w==22 and detail[2].u==44/64 and detail[4].v==14/16,'native power-of-two edge cropping differs from base tiles')
assert(#m.ExplorationLayout(layer,{{offsetX=0,offsetY=0,textureWidth=256,textureHeight=256,fileDataIDs={1},isShownByMouseOver=true}},600)==0,'hover-only highlights do not become permanent terrain')
assert(#m.ExplorationLayout(layer,{{offsetX=0/0,offsetY=0,textureWidth=256,textureHeight=256,fileDataIDs={1}}},600)==0)
C_MapExplorationInfo={GetExploredMapTextures=function() return {{offsetX=100,offsetY=50,textureWidth=300,textureHeight=270,fileDataIDs={101,102,103,104}}} end}
m.Preset('detailed');local explored=0
for _,o in ipairs(objects) do if o.shown and type(o.texture)=='number' and o.texture>=101 then explored=explored+1 end end
assert(explored==4,'outdoor detail is actually drawn, not merely projected')
print('PASS: facing, map aspects and outdoor explored-terrain layer')
