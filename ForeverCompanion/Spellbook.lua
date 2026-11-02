-- Read-only spellbook availability checks; no casting, timers or gameplay automation.
-- API availability differs across client versions. Unknown is NOT the same as missing.
ForeverCompanionSpellbook={}
local S=ForeverCompanionSpellbook
local function normalized(v)
 return tostring(v or ""):lower():gsub("^%s+",""):gsub("%s+$","")
end
function S.Scan()
 local known={}
 local inspected=0
 local supported=false
 if type(GetNumSpellTabs)=="function" and type(GetSpellTabInfo)=="function" and type(GetSpellBookItemName)=="function" then
  local ok,count=pcall(GetNumSpellTabs)
  if ok and type(count)=="number" and count>=0 and count<=20 then
   supported=true
   for tab=1,count do
    local good,_,_,offset,num=pcall(GetSpellTabInfo,tab)
    if good and type(offset)=="number" and type(num)=="number" then
     for i=offset+1,math.min(offset+num,offset+500) do
      local found,name=pcall(GetSpellBookItemName,i,"spell")
      if found and type(name)=="string" and name~="" then known[normalized(name)]=true; inspected=inspected+1 end
     end
    end
   end
  end
 end
 return {known=known,inspected=inspected,supported=supported}
end
function S.Status(name,scan)
 scan=scan or S.Scan()
 if not scan.supported then return "unverified (spellbook API unavailable)" end
 if scan.inspected==0 then return "unverified (spellbook returned no spells)" end
 if scan.known[normalized(name)] then return "learned" end
 return "not found in scanned spellbook"
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
