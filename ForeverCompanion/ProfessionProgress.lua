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
