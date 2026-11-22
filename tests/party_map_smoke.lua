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

canvas.width=1000
ForeverCompanionDB={hideWorldPartyPins=true}
provider.OnMapChanged();assert(not marker.shown)
ForeverCompanionDB.hideWorldPartyPins=false
provider.OnMapChanged();assert(marker.shown)
ForeverCompanionDB.hideCompanionWorldMap=true
provider.OnMapChanged();assert(not marker.shown)

local p=ForeverCompanionPartyMap
canvas.width=1000
ForeverCompanionDB.hideCompanionWorldMap=false
local roster={party1="A",party2="B"}
UnitExists=function(unit) return roster[unit]~=nil end
UnitGUID=function(unit) return roster[unit] end
UnitName=function(unit) return roster[unit]=="A" and "Arden" or "Bren" end
function methods:SetShown(shown) self.shown=shown end
local entries
ForeverCompanionInterface={PagedMenu=function(_,_,rows) entries=rows end}
p.Menu(marker,mapID)
assert(#entries==2 and entries[1].label=="Arden")
entries[1].action()
assert(p.IsHighlighted("party1") and marker.fcPartyHalo.shown)
roster.party1,roster.party2=roster.party2,roster.party1
event.OnEvent(event,"GROUP_ROSTER_UPDATE")
assert(p.IsHighlighted("party2") and not p.IsHighlighted("party1") and not marker.fcPartyHalo.shown)
p.Menu(marker,mapID)
local stale=entries[2]
roster.party1="C"
stale.action()
assert(p.IsHighlighted("party2"),"ignore menu clicks on a reused slot")
roster.party2=nil
event.OnEvent(event,"GROUP_ROSTER_UPDATE")
assert(not p.IsHighlighted("party2") and not p.Highlight("target"))
p.Menu(marker,mapID)
assert(#entries==1 and entries[1].label~="Clear highlight")
print("PASS: world map member selection follows identity across roster changes and clears stale highlights")

