-- Optional native item-tooltip estimates with in-place refresh after equipment/profile changes.
local T={};ForeverCompanionGearTooltips=T
local G=ForeverCompanionGearFinder
local V=ForeverCompanionGearVisuals
local installed,busy=false,false
local function existing(tooltip)
 local name=G.Call(tooltip.GetName,tooltip);local lines=G.Call(tooltip.NumLines,tooltip)
 if type(name)=='string' and type(lines)=='number' and lines>=0 and lines<=300 then
  for i=1,lines do
   local line=_G[name..'TextLeft'..i];local value=line and G.Call(line.GetText,line)
   if type(value)=='string' and value:find('Forever estimate:',1,true) then return line,_G[name..'TextLeft'..(i+1)] end
  end
 end
end
local function write(field,text,color)
 if field then G.Call(field.SetText,field,text);if color then G.Call(field.SetTextColor,field,color[1],color[2],color[3]) end end
end
function T.Add(tooltip)
 if not tooltip or tooltip~=GameTooltip or busy then return end
 if tooltip.IsForbidden and G.Call(tooltip.IsForbidden,tooltip) then return end
 local first,second=existing(tooltip)
 if G.Settings().tooltips==false then if first then write(first,'Forever estimate: disabled');write(second,'') end;return end
 local _,link=G.Call(tooltip.GetItem,tooltip)
 if type(link)~='string' then if first then write(first,'Forever estimate: comparison unavailable');write(second,'') end;return end
 busy=true;local ok,row=pcall(G.CompareLink,link)
 if not ok or not row then
  if first then write(first,'Forever estimate: comparison unavailable');write(second,'') end
  busy=false;return
 end
 local color=V and (row.delta and row.delta>0 and not row.partial and V.colors.green or row.delta and row.delta<0 and V.colors.coral or V.colors.amber) or {.85,.78,.6}
 local title='Forever estimate: '..row.reason
 local caption='vs '..row.slot[1]..' (slot '..row.slot[2]..') · '..G.Settings().profile..' weights · /fc gear'
 if first then write(first,title,color);write(second,caption,{.68,.74,.82})
 else G.Call(tooltip.AddLine,tooltip,title,color[1],color[2],color[3],true);G.Call(tooltip.AddLine,tooltip,caption,.68,.74,.82,true) end
 busy=false
end
function T.Refresh()
 if GameTooltip and (not GameTooltip.IsShown or G.Call(GameTooltip.IsShown,GameTooltip)) then T.Add(GameTooltip) end
end
function T.Install()
 if installed or type(TooltipDataProcessor)~='table' or type(TooltipDataProcessor.AddTooltipPostCall)~='function' or not Enum or not Enum.TooltipDataType or Enum.TooltipDataType.Item==nil then return false end
 installed=pcall(TooltipDataProcessor.AddTooltipPostCall,Enum.TooltipDataType.Item,T.Add)
 return installed
end
T.Install()
