-- Camping feature readiness from manually confirmed profession skill levels.
-- Published preview data, not a guarantee that an unlock exists on this client.
ForeverCompanionCampingReadiness={}
local R=ForeverCompanionCampingReadiness
function R.Check(name,skill)
 local guide=ForeverCompanionCampingGuide
 local feature=guide and guide.features and guide.features[name]
 if not feature then return {status="UNCONFIRMED",detail="No published sample feature for "..tostring(name)} end
 local n=tonumber(skill)
 if not n then return {status="CHECK SKILL",detail=feature.item.." requires skill "..feature.skill.." in the published preview; current skill unknown"} end
 if n<feature.skill then return {status="BELOW PREVIEW GATE",detail=feature.item.." preview requirement "..feature.skill.."; current skill "..n} end
 return {status="MEETS PREVIEW GATE",detail=feature.item.." preview requirement "..feature.skill.."; current skill "..n..". Verify actual unlock in-game"}
end
function R.Format(name,skill)
 local result=R.Check(name,skill)
 return "CAMP READINESS - "..result.status.."\n"..result.detail
end
