-- Profession progression helper: general planning prompts, not a verified recipe database.
ForeverCompanionProfessionProgress={}
local P=ForeverCompanionProfessionProgress
local function tier(skill)
  if skill<75 then return "Getting started"
  elseif skill<150 then return "Early progression"
  elseif skill<225 then return "Developing"
  elseif skill<300 then return "Advanced progression"
  else return "High skill / expansion-specific" end
end
function P.ForProfession(name)
  if not ForeverCompanionProfessionScanner then return "Profession scan unavailable." end
  local found,reason=ForeverCompanionProfessionScanner.Read()
  if not found then return reason end
  for _,entry in ipairs(found) do
    if entry.name and name and entry.name:lower()==name:lower() then
      local skill=tonumber(entry.skill)
      local maximum=tonumber(entry.maxSkill)
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
  local entries,reason=ForeverCompanionProfessionScanner.Read()
  if not entries then return nil,reason or "Profession API unavailable." end
  local result={}
  for _,entry in ipairs(entries) do
    -- Partial client records must not be mistaken for valid progress.
    if type(entry)~="table" then entry={} end
    local skill=tonumber(entry.skill)
    local maximum=tonumber(entry.maxSkill)
    if skill and (skill<0 or skill~=skill) then skill=nil end
    if maximum and (maximum<=0 or maximum~=maximum) then maximum=nil end
    local missing=(skill and maximum) and math.max(0,maximum-skill) or nil
    result[#result+1]={name=type(entry.name)=="string" and entry.name or "Unknown profession",skill=skill,maximum=maximum,remaining=missing,stage=skill and tier(skill) or "Unknown"}
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
    lines[#lines+1]="  General stage: "..entry.stage
  end
  lines[#lines+1]="Recipe availability, prices and trainer upgrades are not verified."
  return table.concat(lines,"\n")
end
