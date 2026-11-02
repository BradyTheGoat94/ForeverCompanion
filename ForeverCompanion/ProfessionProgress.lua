-- Profession progression helper: general planning prompts, not a verified recipe database.
ForeverCompanionProfessionProgress={}
local P=ForeverCompanionProfessionProgress
local function validSkill(value, allowZero)
  local n=tonumber(value)
  if not n or n~=n or n==math.huge or n==-math.huge or n<0 or (not allowZero and n==0) or n>100000 then return nil end
  return n
end
local function tier(skill)
  if skill<75 then return "Getting started"
  elseif skill<150 then return "Early progression"
  elseif skill<225 then return "Developing"
  elseif skill<300 then return "Advanced progression"
  else return "High skill / expansion-specific" end
end
function P.ForProfession(name)
  if not ForeverCompanionProfessionScanner then return "Profession scan unavailable." end
  local ok,found,reason=pcall(ForeverCompanionProfessionScanner.Read)
  if not ok then return "Profession API unavailable on this client." end
  if type(found)~="table" then return reason or "Profession data unavailable." end
  for _,entry in ipairs(found) do
    if type(entry)=="table" and type(entry.name)=="string" and type(name)=="string" and entry.name:lower()==name:lower() then
      local skill=validSkill(entry.skill,true)
      local maximum=validSkill(entry.maxSkill,false)
      if not skill then return "Detected "..entry.name.."; skill level unavailable." end
      local lines={"CURRENT PROGRESSION: "..entry.name, "Skill: "..skill..(maximum and ("/"..maximum) or ""), "Planning stage: "..tier(skill)}
      if maximum and skill>=maximum then lines[#lines+1]="Current trained skill cap reached; check trainer availability." end
      lines[#lines+1]="Recipe colors, ranks and material counts must be checked in the live profession UI."
      return table.concat(lines,"\n")
    end
  end
  return "This profession was not detected on your character. Select a handbook entry to preview its general guide."
end

-- Current skill progress is observed from client APIs, never estimated from recipes.
function P.Overview()
  if not ForeverCompanionProfessionScanner then return nil,"Profession API scanner unavailable." end
  local ok,entries,reason=pcall(ForeverCompanionProfessionScanner.Read)
  if not ok then return nil,"Profession API unavailable on this client." end
  if type(entries)~="table" then return nil,reason or "Profession API unavailable." end
  local result={}
  for _,entry in ipairs(entries) do
    -- Partial client records must not be mistaken for valid progress.
    if type(entry)~="table" then entry={} end
    local skill=validSkill(entry.skill,true)
    local maximum=validSkill(entry.maxSkill,false)
    local missing=(skill and maximum) and math.max(0,maximum-skill) or nil
    local percent=(skill and maximum) and math.floor(math.min(100,skill*100/maximum)+0.5) or nil
    result[#result+1]={name=type(entry.name)=="string" and entry.name or "Unknown profession",skill=skill,maximum=maximum,remaining=missing,percent=percent,stage=skill and tier(skill) or "Unknown"}
  end
  return result,reason
end
function P.FormatOverview()
  local entries,reason=P.Overview()
  if not entries then return "PROFESSION STATUS\n"..tostring(reason) end
  local lines={"PROFESSION STATUS (CLIENT DATA)"}
  if #entries==0 then lines[#lines+1]=reason or "No learned professions detected." end
  for _,entry in ipairs(entries) do
    local progress=entry.skill and (entry.skill..(entry.maximum and "/"..entry.maximum or "")) or "Skill unavailable"
    local note=entry.remaining and (entry.remaining==0 and "At current cap" or (entry.remaining.." skill to current cap")) or "Cap unavailable"
    lines[#lines+1]=entry.name.." | "..progress.." | "..note
    if entry.percent then lines[#lines+1]="  Progress to current cap: "..entry.percent.."%" end
    lines[#lines+1]="  General stage: "..entry.stage
  end
  lines[#lines+1]="Recipe availability, prices and trainer upgrades are not verified."
  return table.concat(lines,"\n")
end

-- Skill-up planning deliberately avoids claiming a particular recipe is orange/yellow.
function P.NextSteps(skill,cap)
 local s=validSkill(skill,true)
 local maximum=validSkill(cap,false)
 if not s then return {"Profession skill unavailable; open the profession window to verify it."} end
 local lines={}
 if maximum and s>=maximum then
  lines[#lines+1]="Current trained skill cap reached. Check an appropriate profession trainer before crafting further."
 else
  lines[#lines+1]="Open the profession window and prefer available recipes with a favorable skill-up color."
  lines[#lines+1]="Compare material cost per likely skill point before committing scarce reagents."
  lines[#lines+1]="Check vendor-sold reagents and required tools before gathering."
 end
 lines[#lines+1]="Current skill "..s..(maximum and ("/"..maximum) or " (cap unknown)")
 lines[#lines+1]="Recipe colors and skill-up probabilities must be verified in the live client."
 return lines
end
function P.FormatNextSteps(skill,cap)
 return table.concat(P.NextSteps(skill,cap),"\n")
end
