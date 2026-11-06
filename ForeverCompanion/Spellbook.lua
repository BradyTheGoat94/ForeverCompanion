-- Read-only spellbook availability checks; no casting, timers or gameplay automation.
-- API availability differs across client versions. Unknown is NOT the same as missing.
ForeverCompanionSpellbook={}
local S=ForeverCompanionSpellbook
local function normalized(v)
 return tostring(v or ""):gsub("’","'"):lower():gsub("^%s+",""):gsub("%s+$","")
end
function S.Scan()
 local known,inspected={},0
 local book=C_SpellBook
 local bank=Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
 if type(book)~="table" or type(book.GetNumSpellBookSkillLines)~="function" or type(book.GetSpellBookSkillLineInfo)~="function" or type(book.GetSpellBookItemName)~="function" or bank==nil then
  return {known=known,inspected=0,supported=false,complete=false}
 end
 local ok,count=pcall(book.GetNumSpellBookSkillLines)
 if not ok or type(count)~="number" or count<1 or count>100 then
  return {known=known,inspected=0,supported=false,complete=false}
 end
 local locale=type(GetLocale)=="function" and GetLocale()
 local englishNames=not locale or locale=="enUS" or locale=="enGB"
 local complete=true
 for tab=1,count do
  local good,info=pcall(book.GetSpellBookSkillLineInfo,tab)
  if not good or type(info)~="table" or type(info.itemIndexOffset)~="number" or type(info.numSpellBookItems)~="number" then complete=false
  else
   local offset,num=info.itemIndexOffset,info.numSpellBookItems
   if num<0 or num>500 then complete=false
   else
    for i=offset+1,offset+num do
     local found,name=pcall(book.GetSpellBookItemName,i,bank)
     if found and type(name)=="string" and name~="" then
      known[normalized(name)]=true
      inspected=inspected+1
     else
      -- A missing/secret/unnamed slot means this cannot be a definitive
      -- absence scan, even when the API call itself did not throw.
      complete=false
     end
    end
   end
  end
 end
 return {known=known,inspected=inspected,supported=true,complete=complete,englishNames=englishNames}
end
function S.HasName(scan,name)
 return scan.supported and scan.known and scan.known[normalized(name)]==true
end
function S.CanCheckEnglishNames(scan)
 return scan.supported and scan.complete and (scan.inspected or 0)>0 and scan.englishNames~=false
end
function S.Status(name,scan)
 scan=scan or S.Scan()
 if not scan.supported then return "unverified (spellbook API unavailable)" end
 if scan.inspected==0 then return "unverified (spellbook returned no spells)" end
 if S.HasName(scan,name) then return "found in spellbook" end
 if scan.englishNames==false then return "unverified (guide uses English spell names)" end
 if not S.CanCheckEnglishNames(scan) then return "unverified (partial scan)" end
 return "not found in scanned spellbook (not proof of unavailable)"
end
function S.Cooldowns(class)
 local guides=ForeverCompanionCooldownGuides and ForeverCompanionCooldownGuides[class]
 if not guides then return "No class cooldown candidates available." end
 local scan=S.Scan()
 local lines={"SPELLBOOK CHECK (READ-ONLY)",scan.supported and ("Scanned "..scan.inspected.." named spellbook entries.") or "Spellbook API unavailable; cannot verify known abilities."}
 for _,category in ipairs({"offense","defense","utility"}) do
  lines[#lines+1]=string.upper(category)
  for _,candidate in ipairs(guides[category] or {}) do
   -- Alternatives and talent/version notes cannot be resolved reliably from a raw name.
   local simple=candidate:match("^([%a%s':%-]+)$")
   if simple then
    lines[#lines+1]="- "..candidate.." ["..S.Status(candidate,scan).."]"
   else
    lines[#lines+1]="- "..candidate.." [availability not checked: conditional/alternative]"
   end
  end
 end
 lines[#lines+1]="Spellbook matches do not establish rank, talent choice, cooldown duration, or Forever mechanics."
 return table.concat(lines,"\n")
end
