local T={}
ForeverCompanionWelcomeTour=T

local slides={
 {'Your first quest loop','Open the leveling guide. It picks a chapter for your faction, level and location. The first card tells you what to pick up, finish or turn in. Use Chapters to browse ahead or choose a different zone.'},
 {'Follow the next objective','Click Directions to point the arrow at the current destination. Turn Follow on to advance the arrow when the quest log changes. Compact keeps just the current step on screen. The arrow points straight at the destination. Use roads and terrain to choose your path.'},
 {'Make the map work for you','Use /fc overlay combined for active quests, services and terrain. Change its layers under Overlay Options. In the world-map dock, use Service filters for mailbox pins. The quest tracker menu controls minimap quest and mailbox pins separately.'},
 {'Find the rest of your tools','Use /fc to open Companion or /fc meter for the combat meter. Questing holds your quest log and session plan. Professions holds material sources and saved inventory. Open your bank or mailbox in game to refresh its saved items.'},
 {'Ready to level','Open the guide and take the first available step. Use Skip quest when a detour is too slow and Restore skipped when you want it back. The guide reads the current quest log and completed quests when you return. Type /fc tutorial to replay this tour.'},
}
local frame,title,body,progress,back,nextButton
local page=1
local function prefs()
 ForeverCompanionTutorialDB=type(ForeverCompanionTutorialDB)=='table' and ForeverCompanionTutorialDB or {}
 return ForeverCompanionTutorialDB
end
local function refresh()
 local slide=slides[page]
 title:SetText(slide[1]);body:SetText(slide[2]);progress:SetText(page..' / '..#slides)
 back:SetEnabled(page>1);nextButton:SetText(page==#slides and 'Open leveling guide' or 'Next')
end
function T.Open()
 if not frame then
  local U=ForeverCompanionInterface
  frame=CreateFrame('Frame','ForeverCompanionWelcomeTourFrame',UIParent,'BackdropTemplate')
  frame:SetSize(560,280);frame:SetPoint('CENTER');frame:SetFrameStrata('DIALOG')
  U.Surface(frame);U.PreparePanel(frame,'ForeverCompanionWelcomeTourFrame',560,280)
  local function label(y,width,height,size)
   local t=U.Text(frame,size);t:SetPoint('TOPLEFT',22,-y);t:SetWidth(width);t:SetHeight(height)
   t:SetJustifyH('LEFT');t:SetJustifyV('TOP');t:SetWordWrap(true);return t
  end
  local function button(x,width,caption,action)
   local b=U.Button(frame);b:SetPoint('BOTTOMLEFT',x,20);b:SetSize(width,30);b:SetText(caption);b:SetScript('OnClick',action);return b
  end
  progress=label(19,450,20,12)
  title=label(54,510,35,21);body=label(99,510,113,15)
  back=button(22,96,'Back',function() page=math.max(1,page-1);refresh() end)
  button(126,110,'Skip tutorial',function() frame:Hide() end)
  nextButton=button(354,184,'Next',function()
   if page<#slides then page=page+1;refresh();return end
   frame:Hide();ForeverCompanionWalkthrough.Open()
  end)
  U.CloseButton(frame,function() frame:Hide() end)
 end
 page=1;refresh();frame:Show()
 prefs().welcomeTourSeen=true
end
function T.FirstLogin()
 if not prefs().welcomeTourSeen then T.Open() end
end
