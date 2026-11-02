-- Read-only profession detection; no crafting actions are performed.
ForeverCompanionProfessionScanner = {}
local scanner=ForeverCompanionProfessionScanner
local function safeText(value)
  if type(value)=="string" and value~="" then return value end
  return nil
end
local function safeNumber(value)
  local ok,n=pcall(function()
    local number=tonumber(value)
    if type(number)=="number" and number>=0 and number<=100000 then return number end
  end)
  if ok then return n end
end
function scanner.Read()
  if type(GetProfessions)~="function" or type(GetProfessionInfo)~="function" then
    return nil,"Profession API unavailable on this client."
  end
  local ok,a,b,c,d,e=pcall(GetProfessions)
  if not ok then return nil,"Profession slots unavailable." end
  local results={}
  for _,index in ipairs({a,b,c,d,e}) do
    if type(index)=="number" then
      local success,name,icon,skill,maxSkill=pcall(GetProfessionInfo,index)
      if success and safeText(name) then
        results[#results+1]={name=name,icon=icon,skill=safeNumber(skill),maxSkill=safeNumber(maxSkill)}
      end
    end
  end
  if #results==0 then return {},"No learned professions detected (or profession data not yet loaded)." end
  return results,nil
end
function scanner.Format()
  local professions,reason=scanner.Read()
  if not professions then return reason end
  if #professions==0 then return reason end
  local lines={"DETECTED PROFESSIONS (READ-ONLY)"}
  for _,p in ipairs(professions) do
    local progress=""
    if p.skill and p.maxSkill and p.maxSkill>0 then
      progress="  "..p.skill.."/"..p.maxSkill
    end
    lines[#lines+1]=p.name..progress
  end
  return table.concat(lines,"\n")
end
