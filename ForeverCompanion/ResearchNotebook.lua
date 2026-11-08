-- Personal, per-character research. Entered notes never become verified data.
local N={}
ForeverCompanionResearchNotebook=N
local root,host,fields,status,current,heading
-- Session-only drafts survive navigation; only Save writes SavedVariables.
local drafts=setmetatable({},{__mode="k"})
local function draftStore(db)
 if not drafts[db] then drafts[db]={} end
 return drafts[db]
end
local function captureDraft()
 if current and current.dirty then
  local entry={}
  for name,edit in pairs(fields) do entry[name]=edit:GetText() end
  draftStore(current.db)[current.key]=entry
 end
end
local limits={note=320,source=240,build=80}
local function clean(value,limit)
 if type(value)~="string" then return "" end
 local text=value:gsub("[%c|]"," ")
 if #text<=limit then return text end
 -- Byte limits must preserve complete UTF-8 characters in localized notes.
 local last=limit
 while last>0 do
  local nextByte=text:byte(last+1)
  if not nextByte or nextByte<128 or nextByte>=192 then break end
  last=last-1
 end
 return text:sub(1,last)
end
function N.Context(tab)
 if tab=="Legacy" or tab=="Alts" then return tab end
 if tab=="Dungeons" then
  local e=ForeverCompanionEncounterBrowser
  if e and e.dungeon~="" and e.boss~="" then return "Boss:"..e.dungeon..":"..e.boss end
 end
end
function N.Read(db,key)
 local all=type(db)=="table" and db.researchNotes
 local entry=type(all)=="table" and all[key]
 entry=type(entry)=="table" and entry or {}
 return {note=clean(entry.note,320),source=clean(entry.source,240),build=clean(entry.build,80)}
end
function N.Save(db,key,entry)
 if type(db)~="table" or type(key)~="string" or #key>200 or not (key=="Legacy" or key=="Alts" or key:match("^Boss:")) or type(entry)~="table" then return false end
 if type(db.researchNotes)~="table" then db.researchNotes={} end
 local result={}
 for field,limit in pairs(limits) do result[field]=clean(entry[field],limit) end
 if result.note=="" and result.source=="" and result.build=="" then db.researchNotes[key]=nil
 else db.researchNotes[key]=result end
 return true
end
local function label(parent,x,y,w,value)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 t:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);t:SetWidth(w);t:SetJustifyH("LEFT");t:SetText(value);return t
end
function N.Create(parent)
 host=parent
 root=CreateFrame("Frame",nil,parent);root:SetSize(770,226)
 ForeverCompanionVisualTheme.Panel(root,770,226)
 heading=label(root,16,-12,730,"PERSONAL RESEARCH / NOT VERIFIED");heading:SetTextColor(0.96,0.76,0.39)
 label(root,16,-34,730,"Save observations with a source and client build. Entered text does not verify a rule or encounter.")
 fields={}
 local names={{"note","Observation / plan",320},{"source","Source / URL",240},{"build","Client version / build",80}}
 for i,info in ipairs(names) do
  local y=-60-(i-1)*32
  label(root,16,y,155,info[2])
  local edit=ForeverCompanionInterface.EditBox(root,info[2])
  edit:SetSize(540,24);edit:SetPoint("TOPLEFT",root,"TOPLEFT",188,y+4)
  if edit.SetAutoFocus then edit:SetAutoFocus(false) end
  if edit.SetMaxLetters then edit:SetMaxLetters(info[3]) end
  edit:SetScript("OnEscapePressed",function(self)
   if self.ClearFocus then self:ClearFocus() end
   if current then N.Render(current.tab,current.db,true) end
  end)
  fields[info[1]]=edit
 end
 local function save()
  if not current then return end
  local entry={}
  for name,edit in pairs(fields) do entry[name]=edit:GetText();if edit.ClearFocus then edit:ClearFocus() end end
  if N.Save(current.db,current.key,entry) then status:SetText("Saved locally for this character. Personal observation; not verified.");current.dirty=false;draftStore(current.db)[current.key]=nil end
 end
 for _,edit in pairs(fields) do
  edit:SetScript("OnEnterPressed",save)
  edit:SetScript("OnTextChanged",function(_,userInput) if userInput and current then current.dirty=true;status:SetText("Unsaved changes. Save or press Enter; Escape restores the saved note.") end end)
 end
 local button=ForeverCompanionInterface.Button(root);button:SetSize(150,24);button:SetPoint("TOPLEFT",root,"TOPLEFT",16,-157);button:SetText("Save research note");button:SetScript("OnClick",save)
 local clear=ForeverCompanionInterface.Button(root);clear:SetSize(150,24);clear:SetPoint("TOPLEFT",root,"TOPLEFT",178,-157);clear:SetText("Clear research note")
 clear:SetScript("OnClick",function()
  if current then N.Save(current.db,current.key,{});N.Render(current.tab,current.db,true);status:SetText("Personal note cleared. Guide evidence unchanged.") end
 end)
 status=label(root,16,-190,730,"")
 status:SetHeight(32);status:SetWordWrap(true)
 ForeverCompanionVisualTheme.Font(status,11)
 root:Hide()
end
function N.Render(tab,db,reload)
 if not root then return end
 local key=N.Context(tab)
 if not key then captureDraft();root:Hide();current=nil;return end
 local changed=not current or current.key~=key or current.db~=db
 if changed or reload then
  if changed then captureDraft() end
  local pending=draftStore(db)
  if reload then pending[key]=nil end
  current={tab=tab,db=db,key=key,dirty=false}
  local entry=pending[key] or N.Read(db,key)
  current.dirty=pending[key]~=nil
  for name,edit in pairs(fields) do edit:SetText(entry[name]) end
  status:SetText(current.dirty and "Unsaved draft restored. Save before reloading the UI; Escape discards this draft." or "Personal notes only; no source, mechanic or client compatibility is verified here.")
 end
 root:ClearAllPoints();root:SetPoint("TOPLEFT",host,"TOPLEFT",8,tab=="Dungeons" and -728 or -395)
 heading:SetText("PERSONAL RESEARCH / "..(tab=="Dungeons" and "SELECTED BOSS" or string.upper(tab)).." / NOT VERIFIED")
 root:Show()
end

