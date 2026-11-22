-- Interior maps use the current instance's client data. Route diagrams use their
-- own display positions and never project the player or outdoor waypoints.
local D={}
ForeverCompanionDungeonMaps=D

local function read(fn,...)
 if type(fn)~="function" then return end
 local ok,a,b,c,d,e,f,g,h=pcall(fn,...)
 if ok then return a,b,c,d,e,f,g,h end
end
local function public(value)
 return not (issecretvalue and issecretvalue(value))
end
local function finite(n)
 return public(n) and type(n)=="number" and n==n and math.abs(n)<math.huge
end
local function id(n)
 return finite(n) and n>0 and n%1==0
end
local function coordinate(n)
 return finite(n) and n>=0 and n<=1
end
local function text(value)
 if public(value) and type(value)=="string" and value~="" then return value end
end
local function key(name)
 return (text(name) or ""):lower():gsub("^the ",""):gsub("[^%w]","")
end
local function journalName(name)
 local catalog=ForeverCompanionDungeonCatalog
 name=catalog.JournalName(name)
 if catalog.entries[name] then return name end
 local slug=key(name)
 for label in pairs(catalog.entries) do
  if key(label)==slug or key(catalog.DisplayName(label))==slug then return label end
 end
 return name
end
local function interior(map)
 if not C_Map or not id(map) then return end
 local info=read(C_Map.GetMapInfo,map)
 local types=Enum and Enum.UIMapType
 if not public(info) or type(info)~="table" or not types or not public(info.mapType) then return end
 if info.mapType and (info.mapType==types.Dungeon or info.mapType==types.Micro) then return info end
end

function D.Current()
 local name,kind,_,_,_,_,_,instance=read(GetInstanceInfo)
 if not text(name) or not public(kind) or (kind~="party" and kind~="raid") then return end
 local map=C_Map and read(C_Map.GetBestMapForUnit,"player")
 return journalName(name),interior(map) and map or nil,id(instance) and instance or nil
end

function D.Floors(map)
 local current=interior(map)
 if not current then return {} end
 local group=read(C_Map.GetMapGroupID,map)
 local members=id(group) and read(C_Map.GetMapGroupMembersInfo,group)
 local floors,seen={},{}
 if public(members) and type(members)=="table" then
  for i=1,math.min(#members,64) do
   local m=members[i]
   if public(m) and type(m)=="table" and id(m.mapID) and not seen[m.mapID] then
    local info=interior(m.mapID)
    local memberGroup=info and read(C_Map.GetMapGroupID,m.mapID)
    if id(memberGroup) and memberGroup==group then
     floors[#floors+1]={map=m.mapID,name=text(m.name) or text(info.name),level=finite(m.relativeHeightIndex) and m.relativeHeightIndex or 0}
     seen[m.mapID]=true
    end
   end
  end
 end
 if not seen[map] then floors={{map=map,name=text(current.name) or "Current floor",level=0}} end
 table.sort(floors,function(a,b)
  if a.level~=b.level then return a.level<b.level end
  return a.map<b.map
 end)
 local names={}
 for _,floor in ipairs(floors) do if floor.name then names[floor.name]=(names[floor.name] or 0)+1 end end
 for i,floor in ipairs(floors) do
  if not floor.name or names[floor.name]>1 then floor.name="Floor "..i end
 end
 return floors
end

function D.BossPins(map)
 local pins={}
 if not interior(map) or not EJ_GetMapEncounter then return pins end
 for i=1,32 do
  local x,y,_,name,_,encounter=read(EJ_GetMapEncounter,map,i)
  if not id(encounter) then break end
  if coordinate(x) and coordinate(y) and not (x==0 and y==0) and text(name) then
   pins[#pins+1]={x=x,y=y,name=name}
  end
 end
 return pins
end

function D.PlayerPoint(map)
 local _,current=D.Current()
 if not current or map~=current then return end
 local position=read(C_Map.GetPlayerMapPosition,map,"player")
 if not position or not public(position) then return end
 local valueType=type(position)
 if valueType~="table" and valueType~="userdata" then return end
 local x,y=read(position.GetXY,position)
 if coordinate(x) and coordinate(y) and not (x==0 and y==0) then return x,y end
end

local function artwork(map,width,height)
 local overlay=ForeverCompanionMapOverlay
 local layout,layer,files=overlay.BestArtwork(read(C_Map.GetMapArtLayers,map),function(index)
  return read(C_Map.GetMapArtLayerTextures,map,index)
 end,width)
 if layout and layout.height>height then layout=overlay.Layout(layer,files,width*height/layout.height) end
 return layout
end

local root,heading,subtitle,mapArea,detail,detailTitle,nextButton,backButton,guideButton
local floorButton,routeButton,followButton,section,empty,wing,player,nativeLegend
local tiles,bosses,routeNodes,paths={},{},{},{}
local state={}
local WIDTH,HEIGHT=524,332
local TEAL={.43,.87,.85}
local GOLD={.97,.70,.35}
local function hideAll(objects)
 for _,obj in ipairs(objects) do obj:Hide() end
end
local function button(parent,x,y,w,h,caption,action)
 local b=ForeverCompanionInterface.Button(parent)
 b:SetSize(w,h);b:SetPoint("TOPLEFT",x,-y);b:SetText(caption);b:SetScript("OnClick",action)
 return b
end
local function label(parent,x,y,w,sz,color)
 local f=ForeverCompanionInterface.Text(parent,sz,color)
 f:SetPoint("TOPLEFT",x,-y);f:SetWidth(w);f:SetJustifyH("LEFT")
 return f
end
local function setDetail(title,description,boss)
 detailTitle:SetText(title);detail:SetText(description)
 state.boss=boss
 guideButton:SetEnabled(boss~=nil)
end
local function updatePlayer()
 player:Hide()
 if not state.map then return end
 local x,y=D.PlayerPoint(state.map)
 if x then
  player:ClearAllPoints()
  player:SetPoint("CENTER",mapArea,"TOPLEFT",state.padX+x*state.layout.width,-state.padY-y*state.layout.height)
  player:Show()
 end
end

local function renderNative(floor,layout)
 state.map=floor.map;state.layout=layout
 state.padX=(WIDTH-layout.width)/2;state.padY=(HEIGHT-layout.height)/2
 for i,tile in ipairs(layout) do
  local t=tiles[i] or mapArea:CreateTexture(nil,"ARTWORK")
  tiles[i]=t
  t:SetTexture(tile.file)
  t:SetTexCoord(0,tile.u,0,tile.v)
  t:ClearAllPoints()
  t:SetPoint("TOPLEFT",mapArea,"TOPLEFT",state.padX+tile.x,-state.padY-tile.y)
  t:SetSize(tile.w,tile.h)
  t:Show()
 end
 local pins=D.BossPins(floor.map)
 for i,pin in ipairs(pins) do
  local b=bosses[i]
  if not b then
   local U=ForeverCompanionInterface
   b=button(mapArea,0,0,23,23,"",function(self)
    setDetail(self.boss,"Boss location reported by the client for this floor.",self.boss)
   end)
   U.SetHoverHelp(b,"Boss marker",function() return b.boss end)
   U.StyleButton(b,nil,true)
   bosses[i]=b
  end
  b.boss=pin.name;b:SetText(tostring(i))
  b:ClearAllPoints()
  b:SetPoint("CENTER",mapArea,"TOPLEFT",state.padX+pin.x*layout.width,-state.padY-pin.y*layout.height)
  b:Show()
 end
 local here=state.liveMap==floor.map
 setDetail(floor.name..(here and " (your floor)" or ""),#pins>0 and "Select a numbered boss marker for its name and guide." or "This floor has no boss locations reported by the client.")
 nativeLegend:SetText(here and "Cyan dot: your position when available" or "Browsing another floor")
 updatePlayer()
end

local function showStop(route)
 local step=math.max(1,math.min(#route,state.step or 1))
 state.step=step
 local entry=route[step]
 setDetail(("%d. %s"):format(step,entry[1]),entry[2],entry[3])
 local U=ForeverCompanionInterface
 for i=1,#route do U.StyleButton(routeNodes[i],nil,step==i) end
 backButton:SetEnabled(step>1);nextButton:SetEnabled(step<#route)
end
local function nodePosition(i)
 local row=math.floor((i-1)/2)
 local column=(i-1)%2
 if row%2==1 then column=1-column end
 return 11+column*263,20+row*72
end
local function renderRoute(route)
 local U=ForeverCompanionInterface
 for i,entry in ipairs(route) do
  local x,y=nodePosition(i)
  local b=routeNodes[i]
  if not b then
   local stop=i
   b=button(mapArea,x,y,239,43,"",function()
    state.step=stop
    showStop(state.route)
   end)
   U.SetHoverHelp(b,"Route landmark",function() return state.route[stop][2] end)
   routeNodes[i]=b
  end
  b:SetText(("%02d   %s"):format(i,entry[1]))
  b:Show()
  if i>1 then
   local oldX,oldY=nodePosition(i-1)
   local t=paths[i-1] or mapArea:CreateTexture(nil,"BORDER")
   paths[i-1]=t
   t:ClearAllPoints()
   if y==oldY then
    t:SetPoint("TOPLEFT",math.min(x,oldX)+239,-y-20);t:SetSize(24,2)
   else
    t:SetPoint("TOPLEFT",x+118,-oldY-43);t:SetSize(2,y-oldY-43)
   end
   t:SetColorTexture(.54,.45,.28,1);t:Show()
  end
 end
 showStop(route)
end

local function activeMatch(name)
 return state.auto or name and state.dungeon==name
end

local function render()
 local current,map,instance=D.Current()
 if state.auto and current~=state.dungeon then
  state.dungeon=current;state.section=1;state.step=1;state.floor=nil;state.mode=nil
 end
 local same=activeMatch(current)
 state.liveMap=same and map or nil
 state.liveInstance=same and instance or nil
 state.floors=D.Floors(state.liveMap)
 local selected
 for _,floor in ipairs(state.floors) do
  if floor.map==(state.mode=="floor" and state.floor or state.liveMap) then selected=floor;break end
 end
 if not selected then
  for _,floor in ipairs(state.floors) do if floor.map==state.liveMap then selected=floor;break end end
 end
 local package=ForeverCompanionDungeonRoutes[state.dungeon]
 local route=package and package[state.section or 1]
 state.route=route
 local layout=selected and artwork(selected.map,WIDTH,HEIGHT)
 local showFloor=state.mode~="route" and layout~=nil
 state.showFloor=showFloor
 state.map,state.layout=nil,nil
 for _,objects in ipairs({tiles,bosses,routeNodes,paths}) do hideAll(objects) end
 player:Hide()
 empty:Hide()
 heading:SetText(ForeverCompanionDungeonCatalog.DisplayName(state.dungeon or "Dungeon maps"))
 subtitle:SetText(showFloor and "Live instance floor art" or route and "Route schematic  |  Landmarks in travel order  |  Not to scale" or "Interior map coverage")
 local U=ForeverCompanionInterface
 U.StyleButton(floorButton,nil,showFloor);floorButton:SetEnabled(layout~=nil)
 U.StyleButton(routeButton,nil,not showFloor);routeButton:SetEnabled(route~=nil)
 followButton:SetEnabled(state.liveMap~=nil and state.floor~=nil)
 wing:SetShown(key(state.dungeon):find("^scarletmonastery")~=nil)
 section:SetEnabled(showFloor and #state.floors>1 or not showFloor and package and #package>1 or false)
 nativeLegend:SetShown(showFloor)
 backButton:SetShown(not showFloor and route~=nil);nextButton:SetShown(not showFloor and route~=nil)
 if showFloor then
  section:SetText(selected.name)
  renderNative(selected,layout)
 elseif route then
  section:SetText(route.name)
  renderRoute(route)
 else
  section:SetText("No floor available")
  empty:SetText(same and current and "The client did not expose floor artwork here." or "Enter the instance to load its client maps, when available.")
  empty:Show()
  setDetail("Interior map unavailable","This dungeon has no sourced route diagram yet. You can still browse its journal for bosses and quests.")
 end
end

local wings={"Graveyard","Library","Armory","Cathedral"}
local function openSections()
 local entries={}
 if state.showFloor or not state.route then
  for _,floor in ipairs(state.floors) do
   local map=floor.map
   entries[#entries+1]={label=floor.name..(map==state.liveMap and " (you)" or ""),selected=map==(state.floor or state.liveMap),action=function()
    state.floor=map;state.mode="floor";render()
   end}
  end
 else
  for i,route in ipairs(ForeverCompanionDungeonRoutes[state.dungeon]) do
   local index=i
   entries[#entries+1]={label=route.name,selected=index==state.section,action=function()
    state.section=index;state.step=1;render()
   end}
  end
 end
 ForeverCompanionInterface.PagedMenu(section,"CHOOSE A FLOOR OR ROUTE",entries,nil,300)
end

local function create()
 local U=ForeverCompanionInterface
 local name="ForeverCompanionDungeonMapFrame"
 root=CreateFrame("Frame",name,UIParent,"BackdropTemplate")
 root:SetSize(842,461);root:SetPoint("CENTER");root:SetFrameStrata("DIALOG")
 U.Surface(root);U.PreparePanel(root,name,842,461)
 U.CloseButton(root,function() U.CloseMenu();root:Hide() end)
 heading=label(root,17,12,675,22,GOLD)
 subtitle=label(root,17,42,800,12,U.palette.muted)
 floorButton=button(root,16,66,99,27,"Floor map",function() state.mode="floor";render() end)
 routeButton=button(root,121,66,99,27,"Route map",function() state.mode="route";render() end)
 followButton=button(root,226,66,104,27,"My floor",function() state.floor=nil;state.mode=nil;render() end)
 section=button(root,336,66,252,27,"",openSections)
 wing=button(root,594,66,103,27,"Choose wing",function()
  local entries={}
  for _,name in ipairs(wings) do
   local dungeon="Scarlet Monastery: "..name
   entries[#entries+1]={label=name,action=function() D.Open(dungeon) end}
  end
  U.Menu(wing,"SCARLET MONASTERY",entries)
 end)
 U.SetHoverHelp(followButton,"My floor","Return to the floor your character is on and follow floor changes.")
 mapArea=CreateFrame("Frame",nil,root)
 mapArea:SetPoint("TOPLEFT",16,-103);mapArea:SetSize(WIDTH,HEIGHT)
 U.Surface(mapArea,{flat=true})
 empty=label(mapArea,32,135,460,14,U.palette.muted);empty:SetJustifyH("CENTER")
 empty:SetHeight(60);empty:SetWordWrap(true)
 player=mapArea:CreateTexture(nil,"OVERLAY")
 player:SetSize(14,14)
 player:SetTexture("Interface\\COMMON\\Indicator-Green")
 if player.SetVertexColor then player:SetVertexColor(.37,.92,1) end
 local card=CreateFrame("Frame",nil,root)
 card:SetPoint("TOPLEFT",552,-103);card:SetSize(274,HEIGHT)
 U.Surface(card,{flat=true})
 detailTitle=label(card,13,15,248,17,TEAL);detailTitle:SetHeight(52);detailTitle:SetWordWrap(true)
 detail=label(card,13,75,248,13);detail:SetHeight(161);detail:SetWordWrap(true)
 nativeLegend=label(card,13,238,248,11,TEAL);nativeLegend:SetHeight(33);nativeLegend:SetWordWrap(true)
 backButton=button(card,13,242,119,28,"Previous stop",function() state.step=state.step-1;showStop(state.route) end)
 nextButton=button(card,140,242,121,28,"Next stop",function() state.step=state.step+1;showStop(state.route) end)
 guideButton=button(card,13,288,248,31,"Boss guide",function()
  if state.boss then ForeverCompanionBossGuideWorkspace.Open(state.dungeon,state.boss) end
 end)
 local elapsed=0
 root:SetScript("OnUpdate",function(_,dt)
  elapsed=elapsed+dt
  if elapsed<.25 then return end
  elapsed=0
  local current,map,instance=D.Current()
  if (state.auto and current~=state.dungeon)
   or (activeMatch(current) and (map~=state.liveMap or instance~=state.liveInstance))
   or (not activeMatch(current) and state.liveMap~=nil) then render()
  elseif state.map then updatePlayer() end
 end)
end

function D.Open(name)
 if not name and not D.Current() then
  return "Enter a dungeon or choose one in the Dungeon Journal."
 end
 if not root then create() end
 state={dungeon=name and journalName(name),auto=name==nil,section=1,step=1}
 root:Show();render()
end
