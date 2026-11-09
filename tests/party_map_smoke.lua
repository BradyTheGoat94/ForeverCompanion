local objects={}
local methods={}
local function obj()
 local o=setmetatable({},{__index=function(_,key) return methods[key] or function() end end})
 objects[#objects+1]=o;return o
end
function methods:SetScript(key,fn) self[key]=fn end
function methods:CreateTexture() return obj() end
function methods:CreateFontString() return obj() end
function methods:GetFrameLevel() return 1 end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:GetWidth() return rawget(self,'width') or 1000 end
function methods:GetHeight() return 600 end
function methods:GetScale() return 1 end
CreateFrame=function() return obj() end
local canvas=obj()
local mapID=1
local provider
WorldMapFrame={IsShown=function() return true end,GetCanvas=function() return canvas end,GetMapID=function() return mapID end,AddDataProvider=function(_,p) provider=p end}
MapCanvasDataProviderMixin={};CreateFromMixins=function() return {} end
UnitExists=function(unit) return unit=='party1' end
UnitIsUnit=function() return false end
C_Map={GetPlayerMapPosition=function() return {GetXY=function() return .5,.5 end} end}
dofile('ForeverCompanion/PartyMap.lua')
local event=objects[#objects];event.OnEvent(event,'PLAYER_ENTERING_WORLD')
local marker
for _,o in ipairs(objects) do if o.unit=='party1' then marker=o end end
assert(provider and marker and marker.shown)
mapID=nil;provider.OnMapChanged();assert(not marker.shown,'missing map must hide previous party blips')
mapID=2;provider.OnMapChanged();assert(marker.shown)
canvas.width=0;provider.OnCanvasSizeChanged();assert(not marker.shown,'invalid canvas must hide previous blips')
print('PASS: party map clears stale markers on unavailable maps and canvas changes')
