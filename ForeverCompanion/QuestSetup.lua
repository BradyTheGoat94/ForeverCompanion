-- Plain-language setup status. Reads cached indexing state; never invents coverage.
local S={}
ForeverCompanionQuestSetup=S
local root
function S.Lines(map,status,supported)
 status=status or ForeverCompanionAvailableQuests.Status(map)
 if supported==nil then supported=ForeverCompanionQuestPlanner.IsSupported() end
 local lines={supported and 'ACTIVE QUESTS\nYour client quest log is available.' or 'ACTIVE QUESTS\nWaiting for a successful quest-log scan. Open your in-game quest log, then try again.'}
 if not status.provider then
  lines[#lines+1]='EXPANDED QUEST LOCATIONS\nCompatible Forever QuestieDB data is not available. Native quest markers can still appear when your client reports them. Install the Forever-compatible QuestieDB provider and reload to expand coverage; generic Questie data is not assumed compatible.'
 elseif not status.contract then
  lines[#lines+1]='EXPANDED QUEST LOCATIONS\nA Forever provider is present, but its quest-pickup interface is too old. Update Forever QuestieDB for pickup and catalog support.'
 elseif status.loading then
  lines[#lines+1]='EXPANDED QUEST LOCATIONS\nLoading quest-giver references in small batches. The list will refresh when indexing finishes.'
 elseif not status.initialized then
  lines[#lines+1]='EXPANDED QUEST LOCATIONS\nProvider ready. Open Find new quests or Zone catalog to load references for your character.'
 else
  lines[#lines+1]='EXPANDED QUEST LOCATIONS\n'..status.quests..' character-compatible mapped quests / '..status.locations..' giver references in this map index. These are coverage counts, not a count of quests currently available to accept.'
 end
 if not status.completion then lines[#lines+1]='COMPLETION CHECKS\nYour client completion API is unavailable. Database pickup eligibility stays unknown; native pickups may still be reported.' end
 lines[#lines+1]='WHY A MARKER MAY BE MISSING\nCheck the selected map and filters. Quests already accepted/completed, unsupported locations, prerequisites, or unavailable completion information can suppress markers. Reputation, profession and seasonal rules still require confirmation with the giver.'
 lines[#lines+1]='GET STARTED\nAccept a quest in game. Choose it in Quest Log, then press Next objective. Find new quests browses known pickup references; the floating tracker keeps remaining objectives visible.'
 return lines
end
function S.StatusLabels(status,supported)
 local provider
 if not status.provider then provider='Unavailable'
 elseif not status.contract then provider='Update needed'
 elseif status.loading then provider='Indexing'
 elseif not status.initialized then provider='Ready'
 else provider='Indexed' end
 return {supported and 'Available' or 'Awaiting scan',provider,status.completion and 'Available' or 'Unavailable'}
end
local values,coverage,lines
function S.Refresh()
 if not root or not root:IsShown() then return end
 local map
 if C_Map and type(C_Map.GetBestMapForUnit)=='function' then
  local ok,value=pcall(C_Map.GetBestMapForUnit,'player')
  if ok and not (issecretvalue and issecretvalue(value)) and type(value)=='number' then map=value end
 end
 local state=ForeverCompanionAvailableQuests.Status(map)
 local supported=ForeverCompanionQuestPlanner.IsSupported()
 local labels=S.StatusLabels(state,supported)
 lines=S.Lines(map,state,supported)
 for i,label in ipairs(labels) do values[i].value:SetText(label) end
 coverage:SetShown(state.initialized==true and state.contract==true and not state.loading)
 coverage:SetText((state.quests or 0)..' mapped quests  /  '..(state.locations or 0)..' giver references')
end
function S.Toggle()
 if not root then
  local U=ForeverCompanionInterface
  local name='ForeverCompanionQuestSetupPanel'
  root=CreateFrame('Frame',name,UIParent,'BackdropTemplate')
  root:SetSize(620,216);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG')
  U.Surface(root);U.PreparePanel(root,name,620,216)
  local title=U.Text(root,18);title:SetPoint('TOPLEFT',18,-13);title:SetWidth(550);title:SetText('Quest data')
  U.CloseButton(root,function() root:Hide() end)
  local captions={'Active quest log','Expanded locations','Completion checks'}
  values={}
  for i,caption in ipairs(captions) do
   values[i]=U.MetricTile(root,18+(i-1)*198,-56,188,caption,function()
    if i==3 then return values[i].value:GetText()=='Available' and 'The client can check quest completion.' or 'Without completion checks, database pickup eligibility stays unknown.' end
    return lines and lines[i] or ''
   end)
  end
  coverage=U.Text(root,12,U.palette.muted);coverage:SetPoint('TOPLEFT',18,-132);coverage:SetWidth(584)
  local function button(x,w,label,help,action)
   local b=U.Button(root);b:SetPoint('BOTTOMLEFT',x,15);b:SetSize(w,27);b:SetText(label);b:SetScript('OnClick',action)
   U.SetHoverHelp(b,label,help)
  end
  button(18,150,'Refresh status','Read the current quest-log and provider status.',S.Refresh)
  button(180,190,'Browse quest catalog','Open the catalog for the current map.',function()
   if ForeverCompanionOpenQuestBook then root:Hide();ForeverCompanionOpenQuestBook('catalog') end
  end)
  button(382,220,'Setup & marker help','Read setup instructions and why a marker can be missing.',function()
   ForeverCompanionReferenceWorkspace.Open('Quest data & setup',lines)
  end)
  root:Hide()
 end
 root:SetShown(not root:IsShown());S.Refresh()
end
