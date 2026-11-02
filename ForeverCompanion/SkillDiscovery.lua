-- Live spellbook discovery for all classes; no hard-coded server unlock claims.
ForeverCompanionSkillDiscovery={}
local D=ForeverCompanionSkillDiscovery
local function normalize(s) return tostring(s or ""):lower():match("^%s*(.-)%s*$") end
function D.Snapshot()
 local spellbook=ForeverCompanionSpellbook
 if not spellbook or not spellbook.Scan then return {supported=false,complete=false,known={},inspected=0} end
 local ok,result=pcall(spellbook.Scan)
 if not ok or type(result)~="table" then return {supported=false,complete=false,known={},inspected=0} end
 return result
end
function D.Find(names,snapshot)
 snapshot=snapshot or D.Snapshot()
 local rows={}
 for _,name in ipairs(names or {}) do
  local key=normalize(name)
  local state="UNCONFIRMED"
  if snapshot.supported and snapshot.known and snapshot.known[key] then state="IN SPELLBOOK"
  elseif snapshot.supported and snapshot.complete and (snapshot.inspected or 0)>0 then state="NOT IN SCANNED SPELLBOOK" end
  rows[#rows+1]={name=name,state=state}
 end
 return rows
end
function D.Format(classToken)
 local snapshot=D.Snapshot()
 local lines={"LIVE SPELLBOOK CHECK (ALL CLASSES)"}
 if not snapshot.supported then
  lines[#lines+1]="Spellbook scan unavailable on this client; no skill absence inferred."
  return table.concat(lines,"\n")
 end
 lines[#lines+1]="Scanned "..(snapshot.inspected or 0).." named entries; "..(snapshot.complete and "complete scan" or "partial scan").."."
 local guide=ForeverCompanionCooldownGuides and ForeverCompanionCooldownGuides[classToken]
 if not guide then
  lines[#lines+1]="No curated skill candidates for this class."
 else
  for _,group in ipairs({"offense","defense","utility"}) do
   local candidates={}
   for _,name in ipairs(guide[group] or {}) do
    if type(name)=="string" and name:match("^[%a%s':%-]+$") then candidates[#candidates+1]=name end
   end
   if #candidates>0 then
    lines[#lines+1]=group:upper()
    for _,row in ipairs(D.Find(candidates,snapshot)) do lines[#lines+1]="  "..row.name.." - "..row.state end
   end
  end
 end
 lines[#lines+1]="Spellbook presence does not verify best rotation, rank, talents or trainer requirements."
 return table.concat(lines,"\n")
end

-- Compact skill readiness overview for any class with curated candidates.
function D.Summary(classToken,snapshot)
 snapshot=snapshot or D.Snapshot()
 local guide=ForeverCompanionCooldownGuides and ForeverCompanionCooldownGuides[classToken]
 local result={known=0,unconfirmed=0,notScanned=0,candidates=0,supported=snapshot.supported and true or false}
 if not guide then return result end
 local seen={}
 for _,group in ipairs({"offense","defense","utility"}) do
  for _,name in ipairs(guide[group] or {}) do
   if type(name)=="string" and name:match("^[%a%s':%-]+$") then
    local key=normalize(name)
    if not seen[key] then
     seen[key]=true
     result.candidates=result.candidates+1
     local state=D.Find({name},snapshot)[1].state
     if state=="IN SPELLBOOK" then result.known=result.known+1
     elseif state=="NOT IN SCANNED SPELLBOOK" then result.notScanned=result.notScanned+1
     else result.unconfirmed=result.unconfirmed+1 end
    end
   end
  end
 end
 return result
end
function D.FormatSummary(classToken)
 local s=D.Summary(classToken)
 return "SKILL READINESS: "..s.known.."/"..s.candidates.." curated candidates found; "..s.notScanned.." not found in scan; "..s.unconfirmed.." unconfirmed. Not a class-completion score."
end

-- Recommend safe, manual verification steps based on scan confidence.
function D.Checklist(classToken,snapshot)
 snapshot=snapshot or D.Snapshot()
 local guide=ForeverCompanionCooldownGuides and ForeverCompanionCooldownGuides[classToken]
 local lines={"SKILL CHECKLIST"}
 if not guide then return {"SKILL CHECKLIST","Curated class data pending; review spellbook and trainer."} end
 if not snapshot.supported then
  lines[#lines+1]="Open the in-game spellbook and check class abilities manually."
  lines[#lines+1]="Spellbook API unavailable; no missing skills inferred."
  return lines
 end
 local missing,uncertain={},{}
 local seen={}
 for _,group in ipairs({"offense","defense","utility"}) do
  for _,name in ipairs(guide[group] or {}) do
   if type(name)=="string" and name:match("^[%a%s':%-]+$") and not seen[normalize(name)] then
    seen[normalize(name)]=true
    local state=D.Find({name},snapshot)[1].state
    if state=="NOT IN SCANNED SPELLBOOK" then missing[#missing+1]=name
    elseif state=="UNCONFIRMED" then uncertain[#uncertain+1]=name end
   end
  end
 end
 for i=1,math.min(5,#missing) do lines[#lines+1]="Check trainer, talent or quest eligibility: "..missing[i] end
 for i=1,math.min(3,#uncertain) do lines[#lines+1]="Verify in spellbook: "..uncertain[i] end
 if #missing+#uncertain==0 then lines[#lines+1]="All curated candidates were found in this scan." end
 lines[#lines+1]="Not found does not mean obtainable at this level or required for this specialization."
 return lines
end
function D.FormatChecklist(classToken)
 return table.concat(D.Checklist(classToken),"\n")
end
