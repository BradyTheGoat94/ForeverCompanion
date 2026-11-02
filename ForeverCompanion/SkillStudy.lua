-- Class skill-study guidance based on curated spell records, never auto-casts.
ForeverCompanionSkillStudy={}
local S=ForeverCompanionSkillStudy
function S.Build(classToken,level)
 local reference=ForeverCompanionVerifiedAbilities
 local result={"SKILL STUDY / CHARACTER SPELLBOOK"}
 if not reference or not reference.entries then
  result[#result+1]="Client-data reference unavailable."
  return result
 end
 local entries=reference.entries[classToken]
 if not entries then
  result[#result+1]="No audited spell entries for this class yet. Consult the in-game spellbook and trainer."
  return result
 end
 local n=tonumber(level)
 local available,missing,upcoming,unknown={},{},{},{}
 for _,entry in ipairs(entries) do
  local state,reason=ForeverCompanionAbilityState(classToken,entry.id,n)
  local line=entry.name.." (level "..entry.level..", "..entry.kind..") - "..reason
  if state=="KNOWN" then available[#available+1]=line
  elseif state=="LEVEL LOCKED" then upcoming[#upcoming+1]={level=entry.level,line=line}
  elseif state=="NOT LEARNED" or state=="QUEST UNLEARNED" or state=="TALENT UNLEARNED" then missing[#missing+1]=line
  else unknown[#unknown+1]=line end
 end
 table.sort(upcoming,function(a,b) if a.level==b.level then return a.line<b.line end return a.level<b.level end)
 result[#result+1]="KNOWN SKILLS ("..#available..")"
 for _,line in ipairs(available) do result[#result+1]="  "..line end
 result[#result+1]="ELIGIBLE / CHECK TRAINER, QUEST OR TALENTS ("..#missing..")"
 for _,line in ipairs(missing) do result[#result+1]="  "..line end
 result[#result+1]="UPCOMING UNLOCKS ("..#upcoming..")"
 for _,row in ipairs(upcoming) do result[#result+1]="  "..row.line end
 if #unknown>0 then
  result[#result+1]="UNCONFIRMED ("..#unknown..")"
  for _,line in ipairs(unknown) do result[#result+1]="  "..line end
 end
 result[#result+1]="This is a partial client-data study list, not a verified rotation or exhaustive skill tree."
 return result
end
function S.Format(classToken,level) return table.concat(S.Build(classToken,level),"\n") end

-- Small, contextual skill-study checklist; excludes unlearned abilities from
-- the usable list and never pretends that unknown API state is verified.
function S.NextActions(classToken,level,limit)
 local entries=ForeverCompanionVerifiedAbilities and ForeverCompanionVerifiedAbilities.entries[classToken]
 if not entries then return {"Skill checklist pending class-data verification."} end
 limit=math.max(1,math.min(8,math.floor(tonumber(limit) or 5)))
 local missing,upcoming,uncertain={},{},{}
 for _,entry in ipairs(entries) do
  local state=ForeverCompanionAbilityState(classToken,entry.id,level)
  if state=="NOT LEARNED" then missing[#missing+1]="Train/check "..entry.name.." (level "..entry.level..")"
  elseif state=="TALENT UNLEARNED" then missing[#missing+1]="Review talent choice: "..entry.name
  elseif state=="QUEST UNLEARNED" then missing[#missing+1]="Check quest unlock: "..entry.name
  elseif state=="LEVEL LOCKED" then upcoming[#upcoming+1]={level=entry.level,text="At level "..entry.level..": "..entry.name}
  elseif state=="UNCONFIRMED" or state=="LEVEL UNKNOWN" then uncertain[#uncertain+1]="Check spellbook: "..entry.name end
 end
 table.sort(upcoming,function(a,b) if a.level==b.level then return a.text<b.text end return a.level<b.level end)
 local result={}
 for _,line in ipairs(missing) do if #result<limit then result[#result+1]=line end end
 for _,item in ipairs(upcoming) do if #result<limit then result[#result+1]=item.text end end
 for _,line in ipairs(uncertain) do if #result<limit then result[#result+1]=line end end
 if #result==0 then result[1]="No pending actions in the currently audited subset." end
 return result
end
function S.FormatNextActions(classToken,level)
 local lines={"NEXT SKILL CHECKLIST (AUDITED SUBSET)"}
 for i,line in ipairs(S.NextActions(classToken,level,5)) do lines[#lines+1]=i..". "..line end
 return table.concat(lines,"\n")
end
