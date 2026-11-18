-- An explicit, bounded acquisition plan for manual material and recipe goals.
local A={page=1,sourcePage=1,items={},loading=false,generation=0};ForeverCompanionGatheringPlan=A
local function read(fn,...) if type(fn)~='function' then return end;local ok,v=pcall(fn,...);if ok then return v end end
local function clean(s) return type(s)=='string' and s:lower():match('^%s*(.-)%s*$') or '' end
local function number(n) return not (issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and n>=0 and n<1e9 end
function A.Demand(profession)
 local rows,byName={},{}
 for _,goal in ipairs(ForeverCompanionCraftingPlanner.GetEntries(profession)) do
  if type(goal)=='table' and clean(goal.name)~='' and number(goal.needed) and number(goal.owned) then
   local key=clean(goal.name);local row=byName[key]
   if not row then row={name=goal.name,key=key,required=goal.needed,owned=goal.owned};byName[key]=row;rows[#rows+1]=row end
  end
 end
 for _,demand in ipairs(ForeverCompanionRecipePlans.MaterialForecast(profession)) do
  local key=clean(demand.name);local row=byName[key]
  if not row then row={name=demand.name,key=key,required=0,owned=demand.owned};byName[key]=row;rows[#rows+1]=row end
  row.required=math.max(row.required,demand.required)
 end
 for _,row in ipairs(rows) do row.shortage=math.max(0,row.required-row.owned) end
 table.sort(rows,function(a,b) if (a.shortage>0)~=(b.shortage>0) then return a.shortage>0 end;return a.key<b.key end)
 return rows
end
function A.Signature(rows) local parts={};for _,r in ipairs(rows) do parts[#parts+1]=r.key..':'..r.required..':'..r.owned end;return table.concat(parts,'|') end
function A.Readiness(profession)
 local available={};for _,r in ipairs(A.Demand(profession)) do available[r.key]=r.owned end
 local result={}
 for _,recipe in ipairs(ForeverCompanionRecipePlans.Get(profession)) do
  local remaining=math.max(0,recipe.quantity-recipe.done);local craftable=remaining;local needs={};local known=#recipe.ingredients>0
  for _,ing in ipairs(recipe.ingredients) do local key=clean(ing.name);needs[key]=(needs[key] or 0)+ing.count end
  for key,count in pairs(needs) do if count>0 then craftable=math.min(craftable,math.floor((available[key] or 0)/count)) else known=false end end
  if not known then craftable=0 end
  for key,count in pairs(needs) do available[key]=math.max(0,(available[key] or 0)-craftable*count) end
  result[#result+1]={recipe=recipe,remaining=remaining,craftable=craftable,known=known}
 end
 return result
end
local function database() return ForeverCompanionQuestLocations and read(ForeverCompanionQuestLocations.Provider) end
function A.Cancel() A.generation=A.generation+1;A.loading=false end
function A.Search(profession,onComplete)
 A.Cancel();A.profession=profession;A.items=A.Demand(profession);A.signature=A.Signature(A.items);A.provider=database();A.matches={};A.sources={};A.selected=nil;A.page=1;A.sourcePage=1
 local db=A.provider;local items=db and db.Item;local ids=items and read(items.GetAllIds)
 if not items or type(ids)~='table' or not C_Timer or type(C_Timer.After)~='function' then return false,'Install compatible Forever QuestieDB for recorded material sources. Your manual plan is unchanged.' end
 if #A.items==0 then return false,'Add material goals or recipe ingredients first.' end
 local wanted={};for _,row in ipairs(A.items) do wanted[row.key]=true;A.matches[row.key]={} end
 local cursor,token=1,A.generation;A.loading=true
 local function batch()
  if token~=A.generation then return end
  if database()~=db or A.Signature(A.Demand(profession))~=A.signature then A.Cancel();A.message='Goals or source provider changed. Search again.';if onComplete then onComplete() end;return end
  for i=cursor,math.min(cursor+79,#ids) do
   local itemID=ids[i]
   if number(itemID) and itemID>0 and itemID%1==0 then
    local name=read(items.name,itemID);local key=clean(name)
    if wanted[key] and #A.matches[key]<8 then A.matches[key][#A.matches[key]+1]=itemID end
   end
  end
  cursor=cursor+80
  if cursor<=#ids then C_Timer.After(.01,batch)
  else
   A.loading=false
   local exact,ambiguous=0,0
   for _,row in ipairs(A.items) do local matches=A.matches[row.key];if #matches==1 then row.itemID=matches[1];exact=exact+1 elseif #matches>1 then ambiguous=ambiguous+1 end end
   A.message=exact..' exact item matches · '..ambiguous..' ambiguous names. Counts are manual; sources are references.'
   if onComplete then onComplete() end
  end
 end
 C_Timer.After(0,batch);return true,'Matching all planned materials in bounded database batches…'
end
function A.Valid()
 return A.provider~=nil and database()==A.provider and A.signature==A.Signature(A.Demand(A.profession))
end
function A.Sources(row,view,map)
 if not A.Valid() or not row or not row.itemID then return {} end
 local sources=ForeverCompanionMaterialSources.ForItem(row.itemID)
 local result={}
 for _,source in ipairs(sources) do
  for _,point in ipairs(source.points) do
   if (view==nil or view=='all' or source.field==view or view=='current' and point.map==map) then result[#result+1]={source=source,point=point,itemID=row.itemID} end
  end
 end
 table.sort(result,function(a,b)
  local ac,bc=a.point.map==map,b.point.map==map;if ac~=bc then return ac end
  if a.point.zone~=b.point.zone then return a.point.zone<b.point.zone end
  if a.source.name~=b.source.name then return a.source.name<b.source.name end
  if a.point.x~=b.point.x then return a.point.x<b.point.x end;return a.point.y<b.point.y
 end)
 return result
end
function A.Navigate(row,entry)
 if not A.Valid() or not row or type(entry)~='table' or row.itemID~=entry.itemID then return false,'Material plan changed. Search again.' end
 local target=ForeverCompanionMaterialSources.Resolve(entry.itemID,entry.source.field,entry.source.id,entry.point)
 if not target then return false,'Source changed or coordinates unavailable. Reopen sources.' end
 return true,ForeverCompanionQuestWaypoints.Navigate(target,true,row.name..' · '..entry.source.name)
end
local panel,title,summary,needRows,sourceRows,selectedText,counter,sourceCounter,viewButton,notice
local view='all'
local materialPrevious,materialNext,sourcePrevious,sourceNext
function A.Refresh()
 if not panel or not panel:IsShown() then return end
 local rows=A.items;A.selected=A.selected or rows[1];local pages=math.max(1,math.ceil(#rows/6));A.page=math.max(1,math.min(A.page,pages))
 notice:SetText('Locations are database references, not guaranteed spawns, stock, drop rates or an optimized farming route.')
 title:SetText('GATHERING JOURNAL · '..(A.profession or 'Profession'))
 summary:SetText(A.loading and 'Searching source references for your entire material plan…' or A.message or 'Choose Search sources. Your manually entered inventory is preserved.')
 for i,b in ipairs(needRows) do
  local row=rows[(A.page-1)*6+i];b.record=row;b:SetShown(row~=nil)
  if row then b:SetText(row.name..'\n'..row.owned..' / '..row.required..' · '..(row.shortage==0 and 'READY' or row.shortage..' MISSING')..(row.itemID and '' or (A.matches and #(A.matches[row.key] or {})>1 and ' · choose ID' or ' · no exact match')));ForeverCompanionInterface.StyleButton(b,nil,row==A.selected) end
 end
 counter:SetText('Materials '..A.page..' / '..pages);materialPrevious:SetEnabled(A.page>1);materialNext:SetEnabled(A.page<pages)
 local row=A.selected;local map=C_Map and read(C_Map.GetBestMapForUnit,'player');local entries=A.Sources(row,view,map);local spages=math.max(1,math.ceil(#entries/6));A.sourcePage=math.max(1,math.min(A.sourcePage,spages))
 selectedText:SetText(row and (row.name..' · '..#entries..' recorded locations') or 'Select a material to inspect its sources')
 viewButton:SetText(({all='All source types',current='Current map',npcDrops='Enemy drops',objectDrops='Gather / objects',vendors='Vendors'})[view])
 for i,b in ipairs(sourceRows) do
  local entry=entries[(A.sourcePage-1)*6+i];b.entry=entry;b.material=row;b:SetShown(entry~=nil)
  if entry then b:SetText(entry.source.name..' · '..entry.source.kind..'\n'..entry.point.zone..(' · %.1f, %.1f'):format(entry.point.x*100,entry.point.y*100)) end
 end
 sourceCounter:SetText('Locations '..A.sourcePage..' / '..spages);sourcePrevious:SetEnabled(A.sourcePage>1);sourceNext:SetEnabled(A.sourcePage<spages)
 if not A.loading and row and #entries==0 then notice:SetText(not A.Valid() and (A.provider and 'Goals or provider changed. Search again before traveling.' or 'Choose Search all planned materials to load source references.') or not row.itemID and 'No unique item match. Choose an exact ID or search this material in Material Finder.' or 'No mapped source in this view. Try All source types; locations and vendor stock are not guaranteed.') end
end
function A.OpenSelected()
 local row=A.selected;if not row then return false,'Select a planned material first.' end
 if row.itemID then
  if not A.Valid() then return false,'Goals or provider changed. Search again before opening this item.' end
  return ForeverCompanionMaterialFinder.OpenItem(row.itemID,row.name)
 end
 ForeverCompanionMaterialFinder.Open(row.name);return true,'Search this material and choose an exact item.'
end
function A.Open(profession)
 if not panel then
  local U=ForeverCompanionInterface
  panel=CreateFrame('Frame','ForeverCompanionGatheringJournal',UIParent,'BackdropTemplate');panel:SetSize(820,570);panel:SetPoint('CENTER');panel:SetFrameStrata('DIALOG');U.Surface(panel);U.PreparePanel(panel,'ForeverCompanionGatheringJournal',820,570);U.CloseButton(panel,function() A.Cancel();panel:Hide() end)
  local function text(x,y,w,size) local t=U.Text(panel,size);t:SetPoint('TOPLEFT',x,y);t:SetWidth(w);return t end
  local function button(x,y,w,label,fn,h) local b=U.Button(panel);b:SetPoint('TOPLEFT',x,y);b:SetSize(w,h or 26);b:SetText(label);b:SetScript('OnClick',fn);return b end
  title=text(16,-16,740,16);summary=text(16,-48,788,11);summary:SetHeight(32);summary:SetWordWrap(true)
  button(16,-87,236,'Search all planned materials',function() local _,msg=A.Search(A.profession,A.Refresh);A.message=msg;notice:SetText('');A.Refresh() end)
  viewButton=button(268,-87,260,'All source types',function(self)
   local entries={};for _,v in ipairs({{'all','All source types'},{'current','Current map'},{'npcDrops','Enemy drops'},{'objectDrops','Gather / objects'},{'vendors','Vendors'}}) do local key,label=v[1],v[2];entries[#entries+1]={label=label,selected=view==key,action=function() view=key;A.sourcePage=1;notice:SetText('');A.Refresh() end} end;U.Menu(self,'SOURCE FILTER',entries)
  end)
  button(540,-87,264,'Open selected in Material Finder',function() local _,msg=A.OpenSelected();notice:SetText(msg) end)
  selectedText=text(268,-125,536,12);needRows={};sourceRows={}
  for i=1,6 do
   local b=button(16,-125-(i-1)*55,236,'',function(self)
    A.selected=self.record;A.sourcePage=1;notice:SetText('')
    local row=self.record;local ids=A.matches and A.matches[row.key] or {}
    if not row.itemID and #ids>1 then local choices={};for _,itemID in ipairs(ids) do local item=itemID;choices[#choices+1]={label=row.name..' · Item #'..item,action=function() if not A.Valid() then notice:SetText('Goals changed. Search again.');return end;row.itemID=item;A.Refresh() end} end;U.Menu(self,'CHOOSE EXACT ITEM ID',choices,nil,350) end
    A.Refresh()
   end,49);b:GetFontString():SetWordWrap(true);b:GetFontString():SetHeight(43);needRows[i]=b
   local source=button(268,-151-(i-1)*49,536,'',function(self) if self.entry then local _,msg=A.Navigate(self.material,self.entry);notice:SetText(msg) end end,44);source:GetFontString():SetWordWrap(true);source:GetFontString():SetHeight(38);sourceRows[i]=source
  end
  materialPrevious=button(16,-461,65,'Previous',function() A.page=math.max(1,A.page-1);A.Refresh() end);materialNext=button(187,-461,65,'Next',function() A.page=A.page+1;A.Refresh() end)
  counter=text(84,-467,100,10);counter:SetJustifyH('CENTER')
  sourcePrevious=button(268,-461,90,'Previous',function() A.sourcePage=math.max(1,A.sourcePage-1);A.Refresh() end);sourceNext=button(714,-461,90,'Next',function() A.sourcePage=A.sourcePage+1;A.Refresh() end);sourceCounter=text(370,-467,330,10);sourceCounter:SetJustifyH('CENTER')
  notice=text(16,-503,788,11);notice:SetHeight(48);notice:SetWordWrap(true)
  panel:HookScript('OnHide',A.Cancel);A.panel=panel;A.notice=notice
 end
 if A.profession~=profession or A.Signature(A.items)~=A.Signature(A.Demand(profession)) then A.Cancel();A.profession=profession;A.items=A.Demand(profession);A.selected=nil;A.message=nil;A.matches={};A.provider=nil;A.page=1 end
 panel:Show();notice:SetText('Locations are database references, not guaranteed spawns, stock, drop rates or an optimized farming route.');A.Refresh()
end
