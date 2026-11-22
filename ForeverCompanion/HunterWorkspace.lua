-- Original Blizzard-style field journal: list, details, native model and explicit map choices.
local W={view='beasts',page=1,detailPage=1,rank=1,look=1,options={query='',family='',role=''}};ForeverCompanionHunterWorkspace=W
local H=ForeverCompanionHunterGuide;local D=ForeverCompanionHunterData
local root,summary,search,filter,familyButton,roleButton,listRows,detailTitle,info,body,model,modelHint,modelCaption,counter,detailCounter,notice,actions,tabs,selected
local previous,nextPage,detailPrevious,detailNext
local petTiles,compareButton
local facing,zoom=.5,1
local modelControls={}
local function text(parent,x,y,w,size,value,height)
 local t=ForeverCompanionInterface.Text(parent,size);t:SetPoint('TOPLEFT',x,y);t:SetWidth(w);t:SetText(value or '')
 if height then t:SetHeight(height);t:SetWordWrap(true);t:SetJustifyV('TOP') end;return t
end
local function button(parent,x,y,w,label,fn,h)
 local b=ForeverCompanionInterface.Button(parent);b:SetPoint('TOPLEFT',x,y);b:SetSize(w,h or 26);b:SetText(label);b:SetScript('OnClick',fn);return b
end
local function tell(msg) notice:SetText(msg or '') end
local function modelFor(entry)
 if model and model.ClearModel then pcall(model.ClearModel,model) end
 for _,control in ipairs(modelControls) do control:Hide() end
 if not model then modelHint:SetShown(W.view=='beasts' or W.view=='pet' or W.view=='families');modelHint:SetText('3D models are unavailable on this client.');return end
 local ok=false
 local showPreview=W.view=='beasts' or W.view=='pet' or W.view=='families'
 modelCaption:SetShown(showPreview)
 local preview=W.view=='families' and entry and H.FamilyPreview(entry.name)
 if W.view=='pet' then
  if not W.showSnapshot and H.Read(UnitExists,'pet')==true and model.SetUnit then ok=pcall(model.SetUnit,model,'pet') end
 elseif preview or (W.view=='beasts' and entry) then
  local beast=preview or entry
  local looks=H.Looks(beast.id);W.look=math.max(1,math.min(W.look,#looks));local look=looks[W.look]
  if look and model.SetDisplayInfo then ok=pcall(model.SetDisplayInfo,model,look.display)
  end
  if not ok and model.SetCreature then ok=pcall(model.SetCreature,model,beast.id) end
 end
 model:SetShown(ok);modelHint:SetShown(showPreview and not ok)
 for _,control in ipairs(modelControls) do control:SetShown(ok) end
 modelHint:SetText('3D preview requires a creature model available in your installed client.')
 if ok then
  if model.SetFacing then pcall(model.SetFacing,model,facing) end
  if model.SetCamDistanceScale then pcall(model.SetCamDistanceScale,model,zoom) end
 end
 modelCaption:SetText(ok and (preview and ('Family preview · '..preview.name) or '3D preview') or (W.view=='beasts' or W.view=='pet' or W.view=='families') and 'Model unavailable' or 'Select a beast for its 3D appearance')
end
local function selectedNow()
 if W.view=='pet' then return selected end
 for _,r in ipairs(H.Build(W.view,W.options)) do if selected and (r.id and r.id==selected.id or not r.id and r.name==selected.name) then selected=r;return r end end
 tell('Filters or source selection changed. Choose the entry again.');return nil
end
local function sourceLines()
 return {'REFERENCE SOURCES','TrueshotLodge (MIT), pinned '..D.revision:sub(1,7),'Beastmaster.io Forever pages: separate community cross-checks.','Reviewed '..D.reviewed..'; no live-client certification.', 'Upstream tame dates are reports from that source, not proof from your character.','Pet health changed in the November 10 Blizzard hotfix. Older health comparisons may be stale.','No universal best pet: match family tools to your activity, then confirm in game.'}
end
local spellRows,spellHeading,showOnMap={}
local function hideSpellTip(row)
 if GameTooltip and (not GameTooltip.IsOwned or GameTooltip:IsOwned(row)) then GameTooltip:Hide() end
end
local function showSpellTip(row)
 local spell=row.spell
 if not GameTooltip then return end
 if row.tamer then
  local entry=row.tamer
  GameTooltip:SetOwner(row,'ANCHOR_RIGHT');GameTooltip:SetText(entry.name,1,.83,.54,true)
  GameTooltip:AddLine('Level '..H.Level(entry.record)..' / '..H.Zones(entry.record),.84,.94,.86,true)
  GameTooltip:AddLine('Click for the beast and its recorded locations.',.84,.94,.86,true)
  GameTooltip:Show();return
 end
 if not spell then return end
 local tip=GameTooltip;tip:SetOwner(row,'ANCHOR_RIGHT')
 if tip.ClearLines then tip:ClearLines() end
 local ok,value=false,nil
 if tip.SetSpellByID then ok,value=pcall(tip.SetSpellByID,tip,spell.rank.spell_id) end
 if not ok or value==false or (tip.NumLines and tip:NumLines()==0) then tip:SetText(spell.name) end
 if spell.rank.pet_level then tip:AddLine('Pet level '..spell.rank.pet_level,1,.82,.45) end
 if spell.rank.training_cost then tip:AddLine(spell.rank.training_cost..' training points',1,.82,.45) end
 tip:Show()
end
function W.Refresh()
 if not root or not root:IsShown() then return end
 local isPet=W.view=='pet';local isBeasts=W.view=='beasts'
 local results
 if isPet then
  results={{id='live',name='Active companion',record={},live=true}}
  for i,pet in ipairs(H.Settings().snapshots) do results[#results+1]={id='snapshot:'..i,name=pet.name~='' and pet.name or 'Saved companion',record=pet,snapshotIndex=i} end
 else results=H.Build(W.view,W.options) end
 local pages=math.max(1,math.ceil(#results/8));W.page=math.max(1,math.min(W.page,pages));W.results=results
 for key,b in pairs(tabs) do ForeverCompanionInterface.StyleButton(b,nil,W.view==key) end
 local exists=false
 if isPet then selected=results[W.showSnapshot and ((W.snapshotIndex or 1)+1) or 1];exists=true end
 for _,r in ipairs(isPet and {} or results) do if selected and (r.id and r.id==selected.id or not r.id and r.name==selected.name) then selected=r;exists=true;break end end
 if not exists then selected=results[(W.page-1)*8+1];W.rank=1;W.look=1;W.detailPage=1 end
 W.selected=selected
 for i,row in ipairs(listRows) do
  local r=results[(W.page-1)*8+i];row.record=r;row:SetShown(r~=nil)
  if r then
   row.title:SetText((not isPet and r.id and H.Settings().favorites[tostring(r.id)] and '* ' or '')..r.name)
   local data=r.record
   local icons={beasts='Ability_Hunter_BeastTaming',families='Ability_Hunter_BeastCall',trainers='INV_Misc_Book_09',pet='Ability_Hunter_BeastCall',abilities='INV_Misc_QuestionMark'}
   local rank=W.view=='abilities' and data.ranks[1]
   local icon=rank and C_Spell and H.Read(C_Spell.GetSpellTexture,rank.spell_id)
   row.icon:SetTexture(icon or ('Interface\\Icons\\'..icons[W.view]))
   row.meta:SetText(isPet and (r.live and 'Active pet' or ('Snapshot '..r.snapshotIndex..' · '..(data.savedAt or 'Date unknown'))) or W.view=='beasts' and (data.family..' · Lv '..H.Level(data)..' · '..H.Speed(data)) or W.view=='families' and H.FamilyLevel(r) or W.view=='abilities' and (#data.ranks..' ranks · '..(data.unique and 'Family skill' or data.passive and 'Passive' or 'Shared skill')) or ((data.zone or 'Zone unknown')..' · '..(data.side or 'Faction unknown')))
   ForeverCompanionInterface.StyleButton(row,nil,r==selected)
  end
 end
 counter:SetText('Page '..W.page..' / '..pages);previous:SetEnabled(W.page>1);nextPage:SetEnabled(W.page<pages)
 summary:SetText(isPet and 'Active pet and saved snapshots' or (#results..' results'..(isBeasts and W.options.ability and ' · Filtered by ability' or '')))
 search:SetShown(not isPet);familyButton:SetShown(not isPet);roleButton:SetShown(not isPet);filter:SetShown(not isPet)
 familyButton:SetEnabled(isBeasts);roleButton:SetEnabled(isBeasts)
 familyButton:SetText(isBeasts and (W.options.family~='' and W.options.family or 'All families') or 'Beast families only');roleButton:SetText(isBeasts and (W.options.role~='' and W.options.role or 'All purposes') or 'Beast purposes only')
 local lines,spells,points,tamers={},{},{},{};local r=selected and selected.record
 compareButton:SetShown(isBeasts);compareButton:SetEnabled(isBeasts and selected~=nil)
 for _,tile in ipairs(petTiles) do tile:Hide() end
 info:ClearAllPoints();info:SetPoint('TOPLEFT',280,-41);info:SetWidth(278);info:SetHeight(175)
 actions[1]:SetEnabled(selected~=nil or isPet);actions[2]:SetEnabled(selected~=nil or isPet);actions[3]:SetEnabled(selected~=nil or isPet)
 if isPet then
  local pet;if W.showSnapshot then pet=H.Settings().snapshots[W.snapshotIndex or 1] else pet=H.LivePet() end;modelFor(nil)
  detailTitle:SetText(W.showSnapshot and ('SAVED PET SNAPSHOT '..(W.snapshotIndex or 1)..' / '..#H.Settings().snapshots) or 'ACTIVE PET / CLIENT READINGS')
  if pet then
   local function n(v) return H.Finite(v) and string.format('%.1f',v) or 'Unknown' end
   info:SetText((pet.name~='' and pet.name or 'Pet')..'\n'..(pet.family~='' and pet.family or 'Family unknown')..' · Level '..n(pet.level)..'\nHealth '..n(pet.health)..' / '..n(pet.maximum)..'\nArmor '..n(pet.armor)..'\nDamage '..n(pet.low)..'–'..n(pet.high)..'\nAttack interval '..n(pet.speed)..' sec\nWhite-melee estimate '..n(pet.dps)..' / sec\n'..(pet.savedAt and ('Saved '..pet.savedAt) or 'Current readable values'))
   lines={'PET ACTION BAR / only client-reported actions',#pet.actions>0 and table.concat(pet.actions,', ') or 'Actions unavailable. Open the pet spellbook to review all known skills.','White-melee estimate averages reported damage and divides by the observed attack interval. It excludes abilities, misses, armor and encounter effects.','Values can include current buffs. Faster attacks alone do not establish higher total damage.'}
  else info:SetText(W.showSnapshot and 'No saved pet snapshot.\nShow your live pet and save one first.' or 'No readable active pet.\nSummon your companion and refresh.');lines={'Your pet must exist and expose readable data. Combat restrictions can make individual values unavailable.'} end
  actions[1]:SetText('Save pet snapshot');actions[2]:SetText(W.showSnapshot and 'Show live pet' or 'Last snapshot');actions[3]:SetText(W.showSnapshot and 'Next snapshot' or 'Refresh readings')
 elseif r then
  detailTitle:SetText(selected.name)
  modelFor(selected)
  if W.view=='beasts' then
   local f=D.TameableFamilies[r.family] or {};local role=H.roles[r.family] or {'Reference family','Review family skills in game.'}
   local values={H.Level(r),H.Speed(r),(r.class or 'Normal')}
   for i,tile in ipairs(petTiles) do tile.value:SetText(values[i]);tile:Show() end
   info:ClearAllPoints();info:SetPoint('TOPLEFT',280,-112);info:SetHeight(108)
   info:SetText(r.family..' / '..role[1]..'\n'..H.FamilyStats(r.family)..'\nDiet: '..table.concat(f.foods or {},', ')..'\n'..H.Zones(r))
   lines={role[2]}
   for _,skill in ipairs(H.Abilities(selected.id)) do
    if not skill.ability.passive and not skill.ability.interval then spells[#spells+1]=skill end
   end
   if #spells==0 then lines[#lines+1]='No starting abilities are documented for this beast.' end
   local sighting=H.Settings().sightings[tostring(selected.id)]
   if type(sighting)=='table' then
    lines[#lines+1]='Your field sighting is in Map locations.'..(H.Finite(sighting.level) and (' Observed level '..sighting.level..'.') or '')
   end
   lines[#lines+1]='Reported native interval already includes its speed passive. Do not apply Faster Attack twice.'
   points=H.Points(selected.id)
   actions[1]:SetText(#points>0 and ('Locations ('..#points..')') or 'No mapped locations');actions[1]:SetEnabled(#points>0);actions[2]:SetText(H.Settings().favorites[tostring(selected.id)] and 'Remove favorite' or 'Favorite beast');actions[3]:SetText('Next appearance')
  elseif W.view=='families' then
   local role=H.roles[selected.name] or {'Reference family','Check family skills against your activity.'}
   info:SetText(H.FamilyLevel(selected)..' / '..role[1]..'\n\n'..H.FamilyStats(selected.name)..'\nRelative to base pet stats\n\nDiet: '..table.concat(r.foods or {},', ')..(r.id and ('\nFamily #'..r.id) or '\nTameability unconfirmed'))
   lines={role[2]}
   if r.referenceOnly then lines[#lines+1]='Tameability unconfirmed in Forever.' end
   for _,a in ipairs(H.Build('abilities',{})) do
    for _,family in ipairs(a.record.learned_by or {}) do
     if family==selected.name and a.record.ranks[1] then
      spells[#spells+1]={name=a.name,rank=a.record.ranks[1],family=true};break
     end
    end
   end
   actions[1]:SetText('Browse family');actions[1]:SetEnabled(not r.referenceOnly);actions[2]:SetText('Purpose advice');actions[3]:SetText('Reference notes')
  elseif W.view=='abilities' then
   W.rank=math.max(1,math.min(W.rank,#r.ranks));local rank=r.ranks[W.rank]
   tamers=H.TameSources(rank)
   local nextRank=r.ranks[W.rank+1]
   info:ClearAllPoints();info:SetPoint('TOPLEFT',14,-42);info:SetWidth(544);info:SetHeight(108)
   info:SetText('Rank '..rank.rank..' / Pet level '..tostring(rank.pet_level or '?')..' / '..tostring(rank.training_cost or '?')..' training points\n'..
    (#tamers..' known tame sources')..(nextRank and (' / Next rank: '..nextRank.rank..' at pet level '..tostring(nextRank.pet_level or '?')) or '')..
    '\n\nTame a listed beast, then use the skill until your hunter learns it. Train it to a compatible pet.')
   spells={{name=r.name,rank=rank}}
   local desc=C_Spell and H.Read(C_Spell.GetSpellDescription,rank.spell_id)
   lines={r.interval and 'Native interval reference: not a promise of a transferable skill. Reported speed already includes the native passive.' or (type(desc)=='string' and desc~='' and desc or 'Current spell description unavailable. Hover or inspect this spell in the game.'),'CAN LEARN: '..(#(r.learned_by or {})>0 and table.concat(r.learned_by,', ') or 'Trainer/passive rules require in-game confirmation.'),'Training requirements and source ranks are community references. An ability found on a beast is not automatically transferable to every family.'}
   actions[1]:SetText('Browse tame sources');actions[2]:SetText('Previous rank');actions[3]:SetText('Next rank');actions[2]:SetEnabled(W.rank>1);actions[3]:SetEnabled(W.rank<#r.ranks)
  else
   info:SetText((r.tag or 'Pet trainer')..'\n'..(r.zone or 'Zone unknown')..'\nFaction: '..(r.side or 'Unknown')..'\nNPC #'..selected.id..'\nService availability is a reference, not a guarantee.')
   lines={'Visit a trainer to inspect current training costs, requirements and available ranks. This addon never trains, purchases or resets abilities automatically.'};actions[1]:SetText('Trainer locations');actions[2]:SetText('Reference notes');actions[3]:SetText('Reference notes')
  end
 else detailTitle:SetText('No matching records');info:SetText('Clear filters or change your search.');modelFor(nil);lines={'Missing information remains unknown. No pet location, speed or ability is invented.'} end
 if W.sourceNotes then lines=sourceLines();spells={} end
 local wrapped={}
 for _,line in ipairs(lines) do
  local current=''
  for word in tostring(line):gmatch('%S+') do if #current+#word+1>78 and current~='' then wrapped[#wrapped+1]=current;current=word else current=current=='' and word or current..' '..word end end
  wrapped[#wrapped+1]=current;wrapped[#wrapped+1]=''
 end
 lines=wrapped
 showOnMap:SetShown(isBeasts and #points>0)
 W.detailLines=lines
 local showingTamers=W.view=='abilities' and #tamers>0 and not W.sourceNotes
 local hasSpells=#spells>0
 local pageSize=(hasSpells or showingTamers) and #spellRows or 9
 local dpages=math.max(1,math.ceil((showingTamers and #tamers or hasSpells and #spells or #lines)/pageSize))
 W.detailPage=math.max(1,math.min(W.detailPage,dpages))
 local visible={}
 for i=(W.detailPage-1)*9+1,math.min(#lines,W.detailPage*9) do visible[#visible+1]=lines[i] end
 body:SetShown(not hasSpells and not showingTamers);body:SetText(table.concat(visible,'\n'))
 spellHeading:SetShown(hasSpells or showingTamers)
 spellHeading:SetText(showingTamers and 'Beasts that teach this rank / select for locations' or W.view=='families' and 'Family tame skills' or 'Starting pet skills')
 spellHeading:ClearAllPoints();spellHeading:SetPoint('TOPLEFT',14,showingTamers and -158 or -242)
 for i,row in ipairs(spellRows) do
  local index=(W.detailPage-1)*pageSize+i
  local spell=not showingTamers and spells[index] or nil
  row.tamer=showingTamers and tamers[index] or nil
  row:ClearAllPoints()
  row:SetPoint('TOPLEFT',14+((i-1)%2)*274,(showingTamers and -180 or -263)-math.floor((i-1)/2)*42)
  if row.spell~=spell then hideSpellTip(row) end
  row.spell=spell;row:SetShown(spell~=nil or row.tamer~=nil)
  row.zone:SetShown(row.tamer~=nil)
  row.caption:ClearAllPoints()
  row.caption:SetPoint('TOPLEFT',40,row.tamer and -4 or -10)
  if row.tamer then
   row.zone:SetText(H.Zones(row.tamer.record))
   row.icon:SetTexture('Interface\\Icons\\Ability_Hunter_BeastTaming')
   row.caption:SetText(row.tamer.name..' / Lv '..H.Level(row.tamer.record))
  elseif spell then
   local icon=C_Spell and H.Read(C_Spell.GetSpellTexture,spell.rank.spell_id)
   row.icon:SetTexture(icon or 'Interface\\Icons\\INV_Misc_QuestionMark')
   row.caption:SetText(spell.name..(spell.family and '' or (' · Rank '..spell.rank.rank)))
  end
 end
 detailCounter:SetText(dpages>1 and ((showingTamers and 'Tame sources ' or hasSpells and 'Abilities ' or 'Details ')..W.detailPage..' / '..dpages) or '')
 detailPrevious:SetShown(dpages>1);detailNext:SetShown(dpages>1)
 detailPrevious:SetEnabled(W.detailPage>1);detailNext:SetEnabled(W.detailPage<dpages)
end
local function locations(anchor,entry)
 local training=W.view=='trainers';local id=entry.id;local points=H.Points(id,training);local entries={}
 for _,p in ipairs(points) do local point=p;entries[#entries+1]={label=p.zone..(' · %.1f, %.1f'):format(p.x*100,p.y*100)..(p.observed and ' · Your position at sighting' or ' · Reference'),action=function() if not root:IsShown() then return end;local current=selectedNow();if not current or current.id~=id or (W.view=='trainers')~=training then return end;local _,msg=H.Navigate(id,point,training);tell(msg) end} end
 if #entries==0 then tell('No supported map coordinates. Review the documented zone; a marker will not be guessed.');return end
 ForeverCompanionInterface.PagedMenu(anchor,'RECORDED SPAWN AREAS / NOT LIVE POSITIONS',entries,nil,440)
end
local function act(which,anchor)
 local entry=selectedNow();if W.view~='pet' and not entry then return end
 W.sourceNotes=false;W.detailPage=1
 if W.view=='pet' then
  if which==1 then local _,msg=H.SavePet();W.snapshotIndex=1;tell(msg) elseif which==2 then W.showSnapshot=not W.showSnapshot;W.snapshotIndex=1 elseif W.showSnapshot then W.snapshotIndex=(W.snapshotIndex or 1)%math.max(1,#H.Settings().snapshots)+1 end
 elseif W.view=='beasts' then
  if which==1 then locations(anchor,entry);return elseif which==2 then local f=H.Settings().favorites;local key=tostring(entry.id);f[key]=not f[key] or nil else W.look=W.look+1;if W.look>#H.Looks(entry.id) then W.look=1 end end
 elseif W.view=='families' then
  if which==1 then W.options.family=entry.name;W.options.ability=nil;W.options.rank=nil;W.view='beasts';W.page=1;selected=nil else W.sourceNotes=which==3 end
 elseif W.view=='abilities' then
  if which==1 then local rank=entry.record.ranks[W.rank];W.options.ability=entry.key;W.options.rank=rank.rank;W.options.family='';W.options.role='';W.options.query='';search:SetText('');W.view='beasts';W.page=1;selected=nil
  elseif which==2 then W.rank=math.max(1,W.rank-1) else W.rank=math.min(#entry.record.ranks,W.rank+1) end
 elseif which==1 then locations(anchor,entry);return else W.sourceNotes=true end
 W.Refresh()
end
local comparison,compareCards
local function compare()
 if not selected or W.view~='beasts' then return end
 W.compareIDs=W.compareIDs or {}
 local ids=W.compareIDs
 if ids[1]~=selected.id and ids[2]~=selected.id then
  if #ids==2 then ids[1],ids[2]=ids[2],selected.id else ids[#ids+1]=selected.id end
 end
 local left,right=H.Comparison(ids[1]),H.Comparison(ids[2])
 if not left or not right then tell('Pick a second beast and click Compare.');return end
 local U=ForeverCompanionInterface
 if not comparison then
  local name='ForeverCompanionPetComparison'
  comparison=CreateFrame('Frame',name,UIParent,'BackdropTemplate')
  comparison:SetSize(650,346);comparison:SetPoint('CENTER');comparison:SetFrameStrata('DIALOG')
  U.Surface(comparison);U.PreparePanel(comparison,name,650,346);U.CloseButton(comparison,function() comparison:Hide() end)
  text(comparison,18,-12,572,20,'Compare beasts')
  compareCards={}
  for i=1,2 do
   local frame=CreateFrame('Frame',nil,comparison)
   frame:SetPoint('TOPLEFT',18+(i-1)*311,-53);frame:SetSize(300,244)
   U.Surface(frame,{background=U.palette.surface,flat=true})
   local fields={}
   fields.name=text(frame,12,-8,276,16,'',40)
   fields.family=text(frame,12,-50,276,12,'')
   fields.speed=text(frame,12,-75,276,12,'')
   fields.stats=text(frame,12,-100,276,11,'',32)
   fields.diet=text(frame,12,-135,276,11,'',32)
   fields.skills=text(frame,12,-169,276,11,'',33)
   fields.zone=text(frame,12,-204,276,11,'',36)
   compareCards[i]=fields
  end
  button(comparison,18,-307,145,'Clear comparison',function() W.compareIDs={};comparison:Hide() end)
 end
 for i,data in ipairs({left,right}) do
  local fields=compareCards[i]
  fields.name:SetText(data.name)
  fields.family:SetText(data.family..' / Level '..data.level)
  fields.speed:SetText('Attack interval: '..data.speed)
  fields.stats:SetText(data.stats)
  fields.diet:SetText(data.diet~='' and ('Diet: '..data.diet) or 'Diet unknown')
  fields.skills:SetText(data.skills~='' and ('Starting skills: '..data.skills) or 'Starting skills undocumented')
  fields.zone:SetText(data.zone)
 end
 comparison:Show()
end

local function openTamer(beast)
 W.view='beasts';W.options={query='',family='',role=''};W.page=1;W.detailPage=1;W.look=1
 search:SetText('')
 selected=beast
 for i,candidate in ipairs(H.Build('beasts',W.options)) do
  if candidate.id==beast.id then W.page=math.floor((i-1)/8)+1;break end
 end
 W.Refresh()
end
function W.Open()
 if not root then
  local U=ForeverCompanionInterface
  root=CreateFrame('Frame','ForeverCompanionHunterFieldGuide',UIParent,'BackdropTemplate');W.root=root;root:SetSize(920,680);root:SetPoint('CENTER');root:SetFrameStrata('DIALOG');ForeverCompanionDungeonChrome.Skin(root,920,680,40,true);U.PreparePanel(root,'ForeverCompanionHunterFieldGuide',920,680);U.CloseButton(root,function() root:Hide() end)
  ForeverCompanionVisualTheme.EnvironmentArt(root,'TOPRIGHT',-4,-4,505,42,'Journey',.85,.09,'ARTWORK')
  text(root,16,-13,510,18,'HUNTER’S FIELD GUIDE')
  tabs={}
  compareButton=button(root,566,-8,144,'Compare',compare)
  U.SetHoverHelp(compareButton,'Compare beasts','Pick two beasts to compare their level, speed, family traits and skills.')
  button(root,724,-8,146,'Toggle pet XP',function() tell(ForeverCompanionPetXPTracker.Toggle()) end)
  for i,v in ipairs({{'beasts','Beasts & locations'},{'families','Families & roles'},{'abilities','Tame skills'},{'trainers','Pet trainers'},{'pet','My companion'}}) do local key=v[1];tabs[key]=button(root,16+(i-1)*179,-50,171,v[2],function() W.view=key;W.page=1;W.rank=1;W.detailPage=1;W.sourceNotes=false;selected=nil;W.Refresh() end) end
  search=U.EditBox(root,'Search pet, family, skill, zone or NPC ID');search:SetPoint('TOPLEFT',16,-91);search:SetSize(288,26);search:SetMaxLetters(80);search:SetScript('OnTextChanged',function(self) W.options.query=self:GetText();W.page=1;W.Refresh() end)
  familyButton=button(root,316,-91,184,'All families',function(self) local menu={{label='All families',action=function() W.options.family='';W.page=1;W.Refresh() end}};for _,f in ipairs(H.Build('families',{})) do local name=f.name;menu[#menu+1]={label=name,action=function() W.options.family=name;W.page=1;W.Refresh() end} end;U.PagedMenu(self,'FAMILY',menu,nil,280) end)
  roleButton=button(root,512,-91,184,'All purposes',function(self) local menu={};for _,name in ipairs({'','Solo tank','Damage','Control','Group utility'}) do local role=name;menu[#menu+1]={label=role=='' and 'All purposes' or role,action=function() W.options.role=role;W.page=1;W.Refresh() end} end;U.Menu(self,'CHOOSE BY PURPOSE / NOT BIS',menu) end)
  filter=button(root,708,-91,196,'Filters / clear',function(self)
   local entries={}
   if W.view=='beasts' then
    entries[#entries+1]={label='Record targeted beast',action=function()
     local _,msg=H.RecordTarget();tell(msg);W.Refresh()
    end}
   end
   for _,v in ipairs(W.view=='beasts' and {{'level','Within my level'},{'zone','My current zone'},{'rare','Rare beasts'},{'favorites','Favorite beasts'},{'seen','Beasts I have seen'}} or W.view=='trainers' and {{'faction','My faction trainers'}} or {}) do local key,label=v[1],v[2];entries[#entries+1]={label=label,selected=W.options[key]==true,action=function() W.options[key]=not W.options[key];W.page=1;W.Refresh() end} end
   entries[#entries+1]={label='Clear all filters and search',action=function() W.options={query='',family='',role=''};search:SetText('');W.page=1;W.Refresh() end};U.Menu(self,'JOURNAL FILTERS',entries,nil,300)
  end)
  U.HoverNote(root,881,-126,'About this field guide','Spawn locations, tame reports and attack intervals come from reference data. Your own sightings and active pet readings are labeled separately.')
  local function listWheel(_,delta)
   if delta~=0 then W.page=W.page+(delta<0 and 1 or -1);W.Refresh() end
  end
  root:EnableMouseWheel(true);root:SetScript('OnMouseWheel',listWheel)
  summary=text(root,16,-130,850,11,'',32);listRows={}
  for i=1,8 do
   local b=button(root,16,-174-(i-1)*49,300,'',function(self) selected=self.record;if W.view=='pet' and selected then W.showSnapshot=not selected.live;W.snapshotIndex=selected.snapshotIndex or 1 end;W.rank=1;W.look=1;W.detailPage=1;W.sourceNotes=false;W.Refresh() end,44)
   b:EnableMouseWheel(true);b:SetScript('OnMouseWheel',listWheel)
   b:GetFontString():SetText('')
   b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(25,25);b.icon:SetPoint('LEFT',8,0)
   b.title=text(b,40,-5,252,12,'');b.meta=text(b,40,-25,252,10,'');listRows[i]=b
  end
  local detail=CreateFrame('Frame',nil,root);detail:SetPoint('TOPLEFT',332,-174);detail:SetSize(572,408);U.Surface(detail);U.Bevel(detail,true)
  detailTitle=text(detail,14,-9,544,16,'');info=text(detail,280,-41,278,11,'',175);body=text(detail,14,-242,544,11,'',157)
  local function detailWheel(_,delta)
   if delta~=0 then W.detailPage=W.detailPage+(delta<0 and 1 or -1);W.Refresh() end
  end
  detail:EnableMouseWheel(true);detail:SetScript('OnMouseWheel',detailWheel)
  petTiles={U.MetricTile(detail,280,-41,88,'Beast level'),U.MetricTile(detail,373,-41,88,'Attack'),U.MetricTile(detail,466,-41,92,'Rarity')}
  spellHeading=text(detail,14,-242,544,11,'')
  for i=1,6 do
   local row=button(detail,14+((i-1)%2)*274,-263-math.floor((i-1)/2)*42,264,'',nil,36)
   row.icon=row:CreateTexture(nil,'ARTWORK');row.icon:SetSize(24,24);row.icon:SetPoint('LEFT',8,0)
   row.caption=text(row,40,-10,214,11,'',20)
   row.zone=text(row,40,-20,214,10,'')
   row.zone:SetTextColor(.69,.81,.71)
   row:SetScript('OnClick',function(self) if self.tamer then openTamer(self.tamer) end end)
   row:EnableMouseWheel(true);row:SetScript('OnMouseWheel',detailWheel)
   row:SetScript('OnEnter',showSpellTip);row:SetScript('OnLeave',hideSpellTip);row:SetScript('OnHide',hideSpellTip)
   spellRows[i]=row
  end
  W.spellRows=spellRows
  modelHint=text(detail,20,-86,240,12,'3D preview available inside WoW',90);modelHint:SetJustifyH('CENTER')
  local ok,result=pcall(CreateFrame,'PlayerModel',nil,detail)
  if ok and result then model=result;model:SetPoint('TOPLEFT',14,-40);model:SetSize(250,174) end
  showOnMap=button(detail,154,-189,110,'Show on map',function()
   local entry=selectedNow()
   if W.view~='beasts' or not entry then return end
   local points=H.Points(entry.id)
   local map=C_Map and H.Read(C_Map.GetBestMapForUnit,'player')
   local point=points[1]
   local position=map and H.Read(C_Map.GetPlayerMapPosition,map,'player')
   local x,y
   if position then x,y=H.Read(function() return position:GetXY() end) end
   local distance=math.huge
   for _,candidate in ipairs(points) do
    if candidate.map==map then
     local delta=H.Finite(x) and H.Finite(y) and ((candidate.x-x)^2+(candidate.y-y)^2) or 0
     if delta<distance then point,distance=candidate,delta end
    end
   end
   if not point then tell('No verified coordinates. See the listed zones for this beast.');return end
   local _,message=H.Navigate(entry.id,point,false);tell(message)
  end,22)
  U.SetHoverHelp(showOnMap,'Show on map','Pin the nearest recorded point on your current zone map when possible. Open Locations to choose another spot.')
  W.showOnMap=showOnMap
  modelCaption=text(detail,14,-218,544,10,'')
  modelControls[1]=U.SetHoverHelp(button(detail,14,-189,30,'<',function() facing=facing-.35;if model and model.SetFacing then pcall(model.SetFacing,model,facing) end end,22),'Rotate left','Turn the pet model left.')
  modelControls[2]=U.SetHoverHelp(button(detail,48,-189,30,'>',function() facing=facing+.35;if model and model.SetFacing then pcall(model.SetFacing,model,facing) end end,22),'Rotate right','Turn the pet model right.')
  modelControls[3]=U.SetHoverHelp(button(detail,82,-189,30,'+',function() zoom=math.max(.3,zoom-.1);if model and model.SetCamDistanceScale then pcall(model.SetCamDistanceScale,model,zoom) end end,22),'Zoom in','Move closer to the pet model.')
  modelControls[4]=U.SetHoverHelp(button(detail,116,-189,30,'-',function() zoom=math.min(2,zoom+.1);if model and model.SetCamDistanceScale then pcall(model.SetCamDistanceScale,model,zoom) end end,22),'Zoom out','Move farther from the pet model.')
  previous=button(root,16,-590,90,'Previous',function() W.page=math.max(1,W.page-1);W.Refresh() end);nextPage=button(root,226,-590,90,'Next',function() W.page=W.page+1;W.Refresh() end);counter=text(root,111,-596,110,10,'');counter:SetJustifyH('CENTER')
  actions={};for i=1,3 do local index=i;actions[i]=button(root,332+(i-1)*191,-590,183,'',function(self) act(index,self) end) end
  detailPrevious=button(root,332,-626,80,'< details',function() W.detailPage=math.max(1,W.detailPage-1);W.Refresh() end);detailNext=button(root,824,-626,80,'details >',function() W.detailPage=W.detailPage+1;W.Refresh() end);detailCounter=text(root,420,-632,396,10,'');detailCounter:SetJustifyH('CENTER')
  notice=text(root,16,-659,888,10,'',16)
  for _,event in ipairs({'UNIT_PET','UNIT_STATS','UNIT_DAMAGE','UNIT_ATTACK_SPEED','PET_BAR_UPDATE'}) do pcall(root.RegisterEvent,root,event) end
  root:SetScript('OnEvent',function(_,event,unit) if event=='UI_SCALE_CHANGED' or event=='DISPLAY_SIZE_CHANGED' then U.FitPanel(root,920,680) elseif W.view=='pet' and (unit==nil or unit=='pet' or unit=='player') then W.Refresh() end end)
  root:Hide();W.previous=previous;W.nextPage=nextPage;W.familyButton=familyButton;W.roleButton=roleButton;W.filter=filter;W.rows=listRows;W.tabs=tabs;W.search=search;W.actions=actions;W.model=model;W.detail=detail;W.detailTitle=detailTitle;W.detailBody=body;W.detailInfo=info
 end
 root:Show();W.Refresh()
end
SLASH_FCHUNTERPETS1='/fcpets';SlashCmdList.FCHUNTERPETS=W.Open
