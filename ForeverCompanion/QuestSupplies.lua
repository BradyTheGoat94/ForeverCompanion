-- Read-only bridge between live item objectives and optional material sources.
local Q={};ForeverCompanionQuestSupplies=Q
local function finite(n) return not(issecretvalue and issecretvalue(n)) and type(n)=='number' and n==n and math.abs(n)<math.huge end
local function read(fn,...)
 if type(fn)~='function' then return end
 local ok,a=pcall(fn,...);if ok then return a end
end
function Q.Live()
 local p=ForeverCompanionQuestPlanner
 local quests=p and read(p.GetLive)
 return type(quests)=='table' and quests or {},p and read(p.IsSupported)==true
end
function Q.Resolve(context,quests,supported)
 if supported~=true then return nil,nil,'Quest scan unavailable. Reopen the quest log before choosing a source.' end
 if type(context)~='table' or not finite(context.questID) or not finite(context.objectiveIndex) or not finite(context.questItemID) then return nil,nil,'Quest item context is unavailable.' end
 for _,q in ipairs(type(quests)=='table' and quests or {}) do
  if type(q)=='table' and q.id==context.questID then
   if context.questTitle and q.title~=context.questTitle then return nil,nil,'The quest identity changed. Reopen its guide.' end
   local item=ForeverCompanionQuestLocations.ObjectiveItem(q,context.objectiveIndex)
   if not item or item.id~=context.questItemID then return nil,nil,'The objective or item reference changed. Reopen its guide.' end
   if item.done then return nil,nil,'This objective is complete. Return to the quest guide for your next step.' end
   return q,item
  end
 end
 return nil,nil,'This quest is no longer in your log.'
end
function Q.ResolveDestination(entry,quests,supported)
 local q,item,message=Q.Resolve(entry,quests,supported)
 if not q then return nil,message end
 local sources=ForeverCompanionMaterialSources
 local point=sources and read(sources.Resolve,entry.questItemID,entry.sourceField,entry.sourceEntityID,entry)
 if not point then return nil,'The item source or its location changed. Review source references again.' end
 point.questID=q.id;point.questTitle=q.title;point.questItemID=item.id;point.objectiveIndex=entry.objectiveIndex
 point.sourceField=entry.sourceField;point.sourceEntityID=entry.sourceEntityID;point.kind='quest-item-source'
 if ForeverCompanionQuestLocations.IsReported(q,point) then return nil,'This location was excluded for this quest.' end
 return point
end
function Q.Navigate(context,source,target)
 if type(context)~='table' or type(source)~='table' or type(target)~='table' then return 'Choose a current quest item source first.' end
 local entry={};for k,v in pairs(context) do entry[k]=v end
 entry.sourceField=source.field;entry.sourceEntityID=source.id;entry.map=target.map;entry.x=target.x;entry.y=target.y
 local quests,supported=Q.Live();local fresh,message=Q.ResolveDestination(entry,quests,supported)
 if not fresh then return message end
 return ForeverCompanionQuestWaypoints.Navigate(fresh,true,fresh.questTitle..' · item source',context.questID)
end
function Q.ItemsForQuest(quest)
 local items={}
 for index in ipairs(type(quest)=='table' and type(quest.objectives)=='table' and quest.objectives or {}) do
  local item=ForeverCompanionQuestLocations.ObjectiveItem(quest,index)
  if item and not item.done then items[#items+1]=item end
 end
 return items
end
function Q.Open(anchor,questID,title,onResult)
 local quests,supported=Q.Live()
 if not supported then return 'Quest scan unavailable. Reopen your quest log first.' end
 local quest
 for _,q in ipairs(quests) do if type(q)=='table' and q.id==questID and q.title==title then quest=q;break end end
 if not quest then return 'This quest changed or left your log. Refresh the tracker.' end
 local items=Q.ItemsForQuest(quest)
 if #items==0 then return 'No unfinished item objective is uniquely matched. Inspect the quest guide.' end
 if #items==1 then local ok,message=ForeverCompanionMaterialFinder.OpenQuestItem(questID,items[1].objectiveIndex,items[1].id,title);return message end
 local entries={}
 for _,item in ipairs(items) do
  local id,index=item.id,item.objectiveIndex
  entries[#entries+1]={label='Objective '..index..': '..item.name,action=function() local ok,message=ForeverCompanionMaterialFinder.OpenQuestItem(questID,index,id,title);if type(onResult)=='function' then onResult(message or 'Review the quest source view.') end end}
 end
 ForeverCompanionInterface.PagedMenu(anchor,'QUEST ITEM OBJECTIVES',entries,nil,460)
 return 'Choose an item objective to inspect its reference sources.'
end
function Q.Return(context)
 local quests=Q.Live()
 for _,q in ipairs(quests) do
  if type(q)=='table' and type(context)=='table' and q.id==context.questID and q.title==context.questTitle and type(ForeverCompanionOpenQuestGuide)=='function' then ForeverCompanionOpenQuestGuide(q.id);return true end
 end
 return false
end
