-- Read-only material lookup. General WoW source categories are NOT verified Forever drops.
local F={};ForeverCompanionMaterialFinder=F
local records={
 {name='Copper Ore',kind='Mining',source='Copper Vein',zone='Zone not verified'},
 {name='Tin Ore',kind='Mining',source='Tin Vein',zone='Zone not verified'},
 {name='Iron Ore',kind='Mining',source='Iron Deposit',zone='Zone not verified'},
 {name='Silverleaf',kind='Herbalism',source='Silverleaf herb node',zone='Zone not verified'},
 {name='Peacebloom',kind='Herbalism',source='Peacebloom herb node',zone='Zone not verified'},
 {name='Linen Cloth',kind='Enemy drops',source='Humanoid enemies (general WoW guidance)',zone='Zone not verified'},
 {name='Wool Cloth',kind='Enemy drops',source='Humanoid enemies (general WoW guidance)',zone='Zone not verified'},
 {name='Light Leather',kind='Skinning',source='Skinnable beasts (general WoW guidance)',zone='Zone not verified'},
}
local panel,search,summary,rows,page= nil,nil,nil,nil,1
local category='All'
local categories={'All','Mining','Herbalism','Skinning','Enemy drops','Reported','Missing sources','Database'}
local filterButton,databaseButton,backToItems,backToQuest
local questContext,finderTitle
local sourceFilter='all'
local sourceViews={{'all','All sources'},{'npcDrops','Enemy drops'},{'objectDrops','Objects'},{'vendors','Vendors'},{'itemDrops','Containers'},{'current','Current map'}}
local selectedItem,selectedName,searchNotice,sourcePage=nil,nil,nil,1
local function clean(s) return type(s)=='string' and s:lower():gsub('[%c|]',' ') or '' end
local function validPoint(p)
 return type(p)=='table' and type(p.map)=='number' and p.map>0 and p.map%1==0 and type(p.x)=='number' and p.x==p.x and p.x>=0 and p.x<=1 and type(p.y)=='number' and p.y==p.y and p.y>=0 and p.y<=1
end
-- Providers can register source reports with a real map ID and normalized x/y.
-- The API deliberately does not infer locations or treat reports as verified.
function F.Register(report)
 if type(report)~='table' or type(report.name)~='string' or report.name:match('^%s*$') or #report.name>80 or type(report.source)~='string' or report.source:match('^%s*$') or #report.source>120 then return false end
 local r={name=report.name:gsub('[|%c]',' '),source=report.source:gsub('[|%c]',' '),kind='Reported',zone=type(report.zone)=='string' and report.zone:sub(1,100):gsub('[|%c]',' ') or 'Zone not verified',status='Community-reported; not verified for Forever'}
 if validPoint(report.point) then r.point={map=report.point.map,x=report.point.x,y=report.point.y} end
 if #records>=500 then return false end
 records[#records+1]=r
 if panel and panel:IsShown() then F.Refresh() end
 return true
end
function F.Search(query)
 local q=clean(query);local found={};local missingSeen={}
 for _,r in ipairs(records) do
  local hay=clean(r.name..' '..r.kind..' '..r.source..' '..r.zone)
  if (category=='All' or r.kind==category) and (q=='' or hay:find(q,1,true)) then found[#found+1]=r end
 end
 local supplied=ForeverCompanionMaterialSources and ForeverCompanionMaterialSources.Results() or {}
 for _,r in ipairs(supplied) do
  if (category=='All' or category=='Database') and (q=='' or clean(r.name..' '..r.id):find(q,1,true)) then found[#found+1]=r end
 end
 -- Material goals are searchable even if no source is known.
 local planner=ForeverCompanionCraftingPlanner
 if planner and planner.GetEntries then
  for _,profession in ipairs({'Alchemy','Blacksmithing','Enchanting','Engineering','Leatherworking','Tailoring','Herbalism','Mining','Skinning'}) do
   local ok,goals=pcall(planner.GetEntries,profession)
   if ok and type(goals)=='table' then for _,goal in ipairs(goals) do
    if (category=='All' or category=='Missing sources' or category==profession) and type(goal)=='table' and type(goal.name)=='string' and (q=='' or clean(goal.name..' '..profession):find(q,1,true)) then
     local exists=false;for _,r in ipairs(records) do if clean(r.name)==clean(goal.name) then exists=true;break end end
     if not exists then for _,r in ipairs(supplied) do if clean(r.name)==clean(goal.name) then exists=true;break end end end
     if not exists and not missingSeen[clean(goal.name)] then missingSeen[clean(goal.name)]=true;found[#found+1]={name=goal.name,kind='Missing sources',source='Source not documented',zone='Location not documented',status='Missing source data · '..profession..' goal'} end
    end
   end end
  end
 end
 table.sort(found,function(a,b) return clean(a.name)<clean(b.name) end)
 return found
end
local function label(parent,x,y,w,size,value)
 local t=ForeverCompanionInterface.Text(parent,size);t:SetPoint('TOPLEFT',parent,'TOPLEFT',x,y);t:SetWidth(w);t:SetText(value or '');return t
end
function F.FilterSources(records,view,map)
 local result={}
 for _,source in ipairs(type(records)=='table' and records or {}) do
  if view=='current' then
   local points={};for _,point in ipairs(source.points or {}) do if map and point.map==map then points[#points+1]=point end end
   if #points>0 then local copy={};for k,v in pairs(source) do copy[k]=v end;copy.points=points;result[#result+1]=copy end
  elseif view==nil or view=='all' or source.field==view then result[#result+1]=source end
 end
 return result
end
function F.OpenSourceViews(anchor)
 local entries={}
 for _,view in ipairs(sourceViews) do
  local key,label=view[1],view[2]
  entries[#entries+1]={label=label,selected=sourceFilter==key,action=function() sourceFilter=key;sourcePage=1;F.Refresh() end}
 end
 ForeverCompanionInterface.Menu(anchor,'ITEM SOURCE VIEW',entries,nil,270)
end
function F.StartDatabaseSearch()
 if not ForeverCompanionMaterialSources then searchNotice='Item database adapter unavailable.';return end
 questContext=nil;selectedItem=nil;page=1
 local ok,message=ForeverCompanionMaterialSources.Search(search:GetText(),function() F.Refresh() end)
 searchNotice=message
 if ok then category='All' end
 F.Refresh()
end
function F.Refresh()
 if not panel or not panel:IsShown() then return end
 local sources=ForeverCompanionMaterialSources
 local supplied,loading,truncated,term={},false,false,''
 if sources then supplied,loading,truncated,term=sources.Results() end
 finderTitle:SetText(questContext and 'QUEST ITEM SOURCES' or 'MATERIAL FINDER')
 local viewName='All sources';for _,view in ipairs(sourceViews) do if view[1]==sourceFilter then viewName=view[2] end end
 databaseButton:SetText(selectedItem and viewName or 'Search database')
 backToQuest:SetShown(questContext~=nil)
 backToItems:SetShown(selectedItem~=nil);filterButton:SetShown(selectedItem==nil)
 local contextMessage
 if questContext then
  local quests,supported=ForeverCompanionQuestSupplies.Live()
  local q,item,problem=ForeverCompanionQuestSupplies.Resolve(questContext,quests,supported)
  if not q then contextMessage=problem end
 end
 local results,pages,currentPage
 if selectedItem then
  local notice;results,notice=sources.ForItem(selectedItem)
  local total=#results;local map
  if C_Map and type(C_Map.GetBestMapForUnit)=='function' then local ok,id=pcall(C_Map.GetBestMapForUnit,'player');if ok then map=id end end
  results=F.FilterSources(results,sourceFilter,map)
  if #results==0 and total>0 then notice=sourceFilter=='current' and not map and 'Player map unavailable. Choose All sources.' or 'No sources match this view. Choose All sources or another category.' end
  summary:SetText(selectedName..' · '..#results..' / '..total..' source references. '..(notice or 'Reference locations are not guaranteed spawns or stock.'))
  pages=math.max(1,math.ceil(#results/6));sourcePage=math.max(1,math.min(sourcePage,pages));currentPage=sourcePage
 else
  results=F.Search(search:GetText());pages=math.max(1,math.ceil(#results/6));page=math.max(1,math.min(page,pages));currentPage=page
  filterButton:SetText(category=='All' and 'All sources' or category)
  local message=loading and 'Searching the installed database…' or (term~='' and ('Database matches: '..#supplied..(truncated and ' (limit 100; narrow search)' or '')) or (searchNotice or 'Press Search database for recorded item sources.'))
  summary:SetText(#results..' results · '..message..' All source records remain references.')
 end
 if contextMessage then summary:SetText(contextMessage) end
 for i,row in ipairs(rows) do
  local r=results[(currentPage-1)*6+i];row:SetShown(r~=nil);row.record=r
  if r then
   row.title:SetText(r.name..'  ·  '..r.kind)
   if selectedItem then
    local zones,seen={},{}
    for _,point in ipairs(r.points) do if not seen[point.zone] then zones[#zones+1]=point.zone;seen[point.zone]=true end end
    row.detail:SetText(#zones>0 and table.concat(zones,', ') or 'No supported map location recorded')
    row.status:SetText('Source reference · no drop-rate or availability guarantee')
    row.go:SetEnabled(#r.points>0 and not contextMessage);row.go:SetText(#r.points>0 and 'Choose area' or 'No map')
    local itemID,itemName,context=selectedItem,selectedName,questContext
    row.go:SetScript('OnClick',function(self)
     local menu={}
     for index=1,#r.points do
      local point=r.points[index]
      menu[#menu+1]={label=point.zone..(' · %.1f, %.1f (reference)'):format(point.x*100,point.y*100),action=function()
       if not panel:IsShown() or selectedItem~=itemID or questContext~=context then summary:SetText('The selected item changed. Reopen its source menu.');return end
       if context then summary:SetText(ForeverCompanionQuestSupplies.Navigate(context,r,point));return end
       local fresh=sources.Resolve(itemID,r.field,r.id,point)
       if not fresh then summary:SetText('This source location changed. Search again before traveling.');return end
       summary:SetText(ForeverCompanionQuestWaypoints.Navigate(fresh,true,itemName..' · '..r.name))
      end}
     end
     ForeverCompanionInterface.PagedMenu(self,'SOURCE AREAS / REFERENCES',menu,nil,440)
    end)
   else
    row.detail:SetText(r.source..'  |  '..r.zone)
    row.status:SetText(r.status or 'General WoW reference; Forever verification pending')
    row.go:SetEnabled(r.id~=nil or validPoint(r.point));row.go:SetText(r.id and 'Sources' or (validPoint(r.point) and 'Map' or 'No map'))
    row.go:SetScript('OnClick',function()
     if r.id then selectedItem=r.id;selectedName=r.name;sourcePage=1;sourceFilter='all';F.Refresh();return end
     if validPoint(r.point) and ForeverCompanionQuestWaypoints and ForeverCompanionQuestWaypoints.Navigate then
      local ok,msg=pcall(ForeverCompanionQuestWaypoints.Navigate,r.point,true,r.name)
      summary:SetText(ok and (msg or 'Confirm the marker on your map.') or 'Map navigation unavailable.')
     end
    end)
   end
  end
 end
 panel.counter:SetText('Page '..currentPage..' / '..pages)
 panel.prev:SetEnabled(currentPage>1);panel.next:SetEnabled(currentPage<pages)
end

function F.Open(query)
 if not panel then
  local U=ForeverCompanionInterface
  panel=CreateFrame('Frame','ForeverCompanionMaterialFinderPanel',UIParent);panel:SetSize(690,640);panel:SetPoint('CENTER');panel:SetFrameStrata('DIALOG');panel:SetClampedToScreen(true);panel:EnableMouse(true);U.Surface(panel);U.PreparePanel(panel,'ForeverCompanionMaterialFinderPanel',690,640)
  panel:SetScript('OnHide',function() questContext=nil;U.CloseMenu();if ForeverCompanionMaterialSources then ForeverCompanionMaterialSources.Cancel() end end)
  finderTitle=label(panel,18,-16,420,18,'MATERIAL FINDER');U.CloseButton(panel,function() panel:Hide() end)
  backToQuest=U.Button(panel);backToQuest:SetSize(170,25);backToQuest:SetPoint('TOPRIGHT',-54,-12);backToQuest:SetText('Back to quest')
  backToQuest:SetScript('OnClick',function()
   if ForeverCompanionQuestSupplies.Return(questContext) then panel:Hide() else summary:SetText('This quest is no longer in your log. Close this window to return to your adventure.') end
  end)
  search=U.EditBox(panel,'Search material, source or profession');search:SetSize(474,30);search:SetPoint('TOPLEFT',18,-53);search:SetMaxLetters(80)
  search:HookScript('OnTextChanged',function() questContext=nil;selectedItem=nil;page=1;searchNotice=nil;if ForeverCompanionMaterialSources then ForeverCompanionMaterialSources.Cancel() end;F.Refresh() end)
  search:SetScript('OnEnterPressed',function(self) self:ClearFocus();F.StartDatabaseSearch() end)
  databaseButton=U.Button(panel);databaseButton:SetSize(166,30);databaseButton:SetPoint('TOPRIGHT',-18,-53);databaseButton:SetText('Search database');databaseButton:SetScript('OnClick',function(self) if selectedItem then F.OpenSourceViews(self) else F.StartDatabaseSearch() end end)
  search:SetScript('OnEscapePressed',function(self) self:ClearFocus();panel:Hide() end)
  filterButton=U.Button(panel);filterButton:SetSize(155,26);filterButton:SetPoint('TOPLEFT',18,-94)
  filterButton:SetScript('OnClick',function()
   local options={}
   for _,name in ipairs(categories) do local selected=name;options[#options+1]={label=name,action=function() category=selected;page=1;F.Refresh() end} end
   U.Menu(filterButton,'SOURCE FILTER',options)
  end)
  backToItems=U.Button(panel);backToItems:SetSize(155,26);backToItems:SetPoint('TOPLEFT',18,-94);backToItems:SetText('Back to items');backToItems:SetScript('OnClick',function() questContext=nil;selectedItem=nil;F.Refresh() end)
  summary=label(panel,183,-96,485,11,'');summary:SetHeight(45);summary:SetWordWrap(true)
  rows={}
  for i=1,6 do
   local row=CreateFrame('Frame',nil,panel);row:SetSize(650,62);row:SetPoint('TOPLEFT',18,-152-(i-1)*67);U.Surface(row)
   row.title=label(row,10,-7,520,13,'');row.detail=label(row,10,-26,520,11,'');row.status=label(row,10,-44,520,10,'')
   row.go=U.Button(row);row.go:SetSize(94,29);row.go:SetPoint('RIGHT',-9,0);rows[i]=row
   row:EnableMouseWheel(true);row:SetScript('OnMouseWheel',function(_,delta)
    local action=delta<0 and panel.next or panel.prev
    if action and action:IsEnabled() then action:Click() end
   end)
  end
  panel.prev=U.Button(panel);panel.prev:SetSize(95,27);panel.prev:SetPoint('BOTTOMLEFT',18,16);panel.prev:SetText('Previous');panel.prev:SetScript('OnClick',function() if selectedItem then sourcePage=math.max(1,sourcePage-1) else page=math.max(1,page-1) end;F.Refresh() end)
  panel.next=U.Button(panel);panel.next:SetSize(95,27);panel.next:SetPoint('BOTTOMRIGHT',-18,16);panel.next:SetText('Next');panel.next:SetScript('OnClick',function() if selectedItem then sourcePage=sourcePage+1 else page=page+1 end;F.Refresh() end)
  panel.counter=label(panel,285,-599,180,12,'')
 end
 if query then category='All' end
 questContext=nil;selectedItem=nil;sourceFilter='all';searchNotice=nil;panel:Show();search:SetText(query or '');page=1;F.Refresh()
end
-- Preserve an explicitly chosen material identity without another index search.
function F.OpenItem(itemID,expectedName)
 local sources=ForeverCompanionMaterialSources;local name=sources and sources.ItemName(itemID)
 local function clean(value) return type(value)=='string' and value:lower():match('^%s*(.-)%s*$') or '' end
 if not name or (expectedName and clean(name)~=clean(expectedName)) then return false,'Item identity changed or source data is unavailable. Search your material again.' end
 F.Open(name);selectedItem=itemID;selectedName=name;sourcePage=1;sourceFilter='all';F.Refresh()
 return true,'Showing exact item #'..itemID..' reference sources.'
end
-- Exact ID handoff; no global item index scan is needed for a matched quest.
function F.OpenQuestItem(questID,index,itemID,expectedTitle)
 local Q=ForeverCompanionQuestSupplies
 local quests,supported=Q.Live()
 local context={questID=questID,questTitle=expectedTitle,objectiveIndex=index,questItemID=itemID}
 local q,item,message=Q.Resolve(context,quests,supported)
 if not q then return false,message end
 context.questTitle=q.title
 F.Open(item.name)
 questContext=context;selectedItem=item.id;selectedName=item.name;sourcePage=1
 F.Refresh();return true,'Showing reference sources for '..item.name..'.'
end
SLASH_FCMATERIALS1='/fcmaterials'
SlashCmdList.FCMATERIALS=function(msg) F.Open(msg) end
