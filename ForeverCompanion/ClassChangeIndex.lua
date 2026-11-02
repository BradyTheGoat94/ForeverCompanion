-- Compact source-attributed class-change index for fast in-game reading.
ForeverCompanionClassChangeIndex={}
local I=ForeverCompanionClassChangeIndex
function I.Build(class,level)
 local source=ForeverCompanionClassChanges
 local entry=source and source.classes and source.classes[class]
 if not entry then return {} end
 local n=tonumber(level) or 1
 local rows={}
 for _,fact in ipairs(entry.notes or {}) do
  local gate=fact[1]
  rows[#rows+1]={status=not gate and "VERIFY IN CLIENT" or (n>=gate and "LEVEL REACHED" or "UPCOMING"),level=gate,description=fact[2],source=entry.source}
 end
 return rows
end
function I.Format(class,level)
 local rows=I.Build(class,level)
 if #rows==0 then return "CLASS CHANGE INDEX: No sourced entries for this class." end
 local lines={"CLASS CHANGE INDEX - PUBLISHED PREVIEW"}
 for i,row in ipairs(rows) do
  lines[#lines+1]=i..". ["..row.status.."] "..(row.level and ("Lv "..row.level.." - ") or "")..row.description
 end
 lines[#lines+1]="Level reached does not mean trained or unlocked. Check live spellbook and trainer."
 return table.concat(lines,"\n")
end
