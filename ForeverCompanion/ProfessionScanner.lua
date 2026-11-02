-- Read-only profession detection for both modern and Classic-era WoW APIs.
-- Never opens a trade skill, changes the selected skill, or casts an ability.
ForeverCompanionProfessionScanner = {}
local scanner=ForeverCompanionProfessionScanner

local function safeText(value)
  local ok,text=pcall(function()
    if type(value)=="string" and value~="" then return value end
  end)
  if ok then return text end
end
local function safeNumber(value)
  local ok,n=pcall(function()
    local number=tonumber(value)
    if type(number)=="number" and number>=0 and number<=100000 then return number end
  end)
  if ok then return n end
end
local function readModern()
  if type(GetProfessions)~="function" or type(GetProfessionInfo)~="function" then return nil end
  local ok,a,b,c,d,e=pcall(GetProfessions)
  if not ok then return nil end
  local slots={a,b,c,d,e}
  local results,seen={},{}
  -- Numeric iteration is intentional: ipairs stops at the first missing slot.
  for i=1,5 do
    local index=slots[i]
    if type(index)=="number" and index>=1 and index<=100 and not seen[index] then
      seen[index]=true
      local success,name,icon,skill,maxSkill=pcall(GetProfessionInfo,index)
      name=safeText(name)
      if success and name then
        results[#results+1]={name=name,icon=icon,skill=safeNumber(skill),
          maxSkill=safeNumber(maxSkill),source="profession slots"}
      end
    end
  end
  return results
end

-- Classic clients may expose only the general skill-line list. Restrict this
-- fallback to known trade skills to avoid treating weapon skills as professions.
-- Unknown/custom/localized profession names require the client-specific API.
local tradeNames={
  ["alchemy"]=true,["blacksmithing"]=true,["enchanting"]=true,
  ["engineering"]=true,["herbalism"]=true,["leatherworking"]=true,
  ["mining"]=true,["skinning"]=true,["tailoring"]=true,
  ["cooking"]=true,["first aid"]=true,["fishing"]=true,
  ["jewelcrafting"]=true,["inscription"]=true,["archaeology"]=true
}
local function readLegacy()
  if type(GetNumSkillLines)~="function" or type(GetSkillLineInfo)~="function" then return nil end
  local ok,count=pcall(GetNumSkillLines)
  if not ok or type(count)~="number" or count<0 or count>1000 then
    return nil,"Legacy skill-line scan failed."
  end
  local results,seen={},{}
  for i=1,count do
    local good,name,isHeader,_,skill,_,_,maximum=pcall(GetSkillLineInfo,i)
    if not good then return nil,"Legacy skill-line scan failed." end
    name=safeText(name)
    if name and not isHeader and tradeNames[name:lower()] and not seen[name:lower()] then
      seen[name:lower()]=true
      results[#results+1]={name=name,skill=safeNumber(skill),
        maxSkill=safeNumber(maximum),source="legacy skill lines"}
    end
  end
  return results
end

function scanner.Read()
  local modern=readModern()
  if modern and #modern>0 then return modern,nil end
  local legacy,reason=readLegacy()
  if legacy and #legacy>0 then return legacy,nil end
  if modern or legacy then
    return {},"No learned professions detected (or profession data not yet loaded)."
  end
  return nil,reason or "Profession API unavailable on this client."
end
function scanner.Format()
  local professions,reason=scanner.Read()
  if not professions or #professions==0 then return reason end
  local lines={"DETECTED PROFESSIONS (READ-ONLY)"}
  for _,p in ipairs(professions) do
    local progress=""
    if p.skill and p.maxSkill and p.maxSkill>0 then
      progress="  "..p.skill.."/"..p.maxSkill
    end
    lines[#lines+1]=p.name..progress
  end
  if professions[1] and professions[1].source=="legacy skill lines" then
    lines[#lines+1]="Classic skill-line fallback; custom/localized names may need manual notes."
  end
  return table.concat(lines,"\n")
end
