-- Plain-language setup status. Reads cached indexing state; never invents coverage.
local S={}
ForeverCompanionQuestSetup=S
local root,body
function S.Lines(map)
 local status=ForeverCompanionAvailableQuests.Status(map)
 local supported=ForeverCompanionQuestPlanner.IsSupported()
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
function S.Refresh()
 if not root or not root:IsShown() then return end
 local map
 if C_Map and type(C_Map.GetBestMapForUnit)=='function' then
  local ok,value=pcall(C_Map.GetBestMapForUnit,'player')
  if ok and not (issecretvalue and issecretvalue(value)) and type(value)=='number' then map=value end
 end
 body:SetText(table.concat(S.Lines(map),'\n\n'))
 local height=math.max(160,body:GetStringHeight()+8)
 body:SetHeight(height);root:SetHeight(height+95)
 if UIParent.GetWidth and UIParent.GetHeight then
  local width,availableHeight=UIParent:GetWidth(),UIParent:GetHeight()
  if type(width)=='number' and type(availableHeight)=='number' and width>32 and availableHeight>32 then
   root:SetScale(math.min(1,(width-32)/620,(availableHeight-32)/(height+95)))
  end
 end
end
function S.Toggle()
 if not root then
  local U=ForeverCompanionInterface
  root=CreateFrame('Frame','ForeverCompanionQuestSetupPanel',UIParent)
  root:SetSize(620,460);root:SetPoint('CENTER');root:SetClampedToScreen(true);root:SetFrameStrata('DIALOG');root:EnableMouse(true)
  U.Surface(root)
  local title=U.Text(root,18);title:SetPoint('TOPLEFT',18,-15);title:SetWidth(550);title:SetText('QUEST DATA & SETUP')
  U.CloseButton(root,function() root:Hide() end)
  body=U.Text(root,13);body:SetPoint('TOPLEFT',18,-52);body:SetWidth(584);body:SetWordWrap(true);body:SetJustifyV('TOP')
  local refresh=U.Button(root);refresh:SetPoint('BOTTOMRIGHT',-18,12);refresh:SetSize(110,26);refresh:SetText('Refresh status');refresh:SetScript('OnClick',S.Refresh)
  root:Hide()
 end
 root:SetShown(not root:IsShown());S.Refresh()
end
