-- Beta readiness overview. Honest, local read-only diagnostics; not a release certification.
ForeverCompanionReadiness={}
local R=ForeverCompanionReadiness
function R.Build(class,level,profession)
 local checks={}
 local function add(name,state,note) checks[#checks+1]={name=name,state=state,note=note} end
 local changes=ForeverCompanionClassChangeIndex
 local rows=changes and changes.Build and changes.Build(class,level) or {}
 add("Class preview",#rows>0 and "PUBLISHED" or "UNKNOWN",#rows>0 and (#rows.." sourced preview notes; check learned abilities in-game") or "No sourced class entries")
 local camping=ForeverCompanionCampingReadiness
 local gate=camping and camping.ForProfession and camping.ForProfession(profession) or nil
 add("Camping",gate and "PREVIEW" or "UNKNOWN",gate or "No client skill comparison")
 local plans=ForeverCompanionRecipePlans
 local recipes=plans and plans.Get and plans.Get(profession) or {}
 add("Recipe goals",#recipes>0 and "MANUAL" or "EMPTY",#recipes.." user-entered goals; no live recipe database")
 local budget=ForeverCompanionShoppingBudget
 local b=budget and budget.Build and budget.Build(profession) or nil
 add("Material budget",not b and "UNKNOWN" or (b.unknown==0 and "ESTIMATED" or "PARTIAL"),b and (b.knownCopper.." copper known subtotal; "..b.unknown.." unpriced shortage materials") or "Cost planner unavailable")
 add("Live client", "UNTESTED", "Offline CI does not verify WoW Forever client API compatibility or addon appearance")
 return checks
end
function R.Format(class,level,profession)
 local lines={"BETA READINESS - "..tostring(class or "?").." / "..tostring(profession or "?")}
 for _,check in ipairs(R.Build(class,level,profession)) do lines[#lines+1]=check.name.." ["..check.state.."] "..check.note end
 lines[#lines+1]="No gameplay automation; do not interpret published previews as verified unlocks."
 return table.concat(lines,"\n")
end
