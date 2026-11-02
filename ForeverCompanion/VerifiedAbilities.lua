-- Curated Forever beta spellbook entries. Verified against published client-data
-- extracts (not against an in-game character). This is deliberately a partial
-- reference, not an exhaustive trainer list or an optimized rotation.
-- Source: https://foreverdb.net/spells?cls=1
-- Snapshot: 1.60.1.70707 (2026-10-31). Recheck on each beta patch.
ForeverCompanionVerifiedAbilities = {
 build="1.60.1.70707",
 checked="2026-11-02",
 source="https://foreverdb.net/spells?cls=1",
 status="Client-data reference only; in-game trainer/talent availability unverified",
 entries={
  WARRIOR={
   {name="Battle Shout",level=1,id=25289,kind="Trainer",tree="Fury",note="Maintain the appropriate group attack-power buff"},
   {name="Battle Stance",level=1,id=2457,kind="Trainer",tree="Arms",note="Check your stance before using stance-restricted abilities"},
   {name="Heroic Strike",level=1,id=25286,kind="Trainer",tree="Arms",note="Rage spender; evaluate opportunity cost before using"},
   {name="Hamstring",level=8,id=7373,kind="Trainer",tree="Arms",note="Situational movement control, not a universal damage button"},
   {name="Bloodrage",level=10,id=2687,kind="Trainer",tree="Protection",note="Check resource and survival implications"},
   {name="Disarm",level=18,id=676,kind="Trainer",tree="Protection",note="Situational utility where the target can be disarmed"},
   {name="Berserker Rage",level=30,id=18499,kind="Trainer",tree="Fury",note="Situational defensive/control response"},
   {name="Berserker Stance",level=30,id=2458,kind="Quest",tree="Fury",note="Requires its quest; level alone does not grant it"},
   {name="Execute",level=24,id=20662,kind="Trainer",tree="Fury",note="Conditional finishing ability"},
   {name="Bloodthirst",level=40,id=23881,kind="Talent",tree="Fury",note="Requires talent investment; level alone does not grant it"},
   {name="Anger Management",level=20,id=12296,kind="Talent",tree="Arms",note="Requires talent investment"},
   {name="Bastion",level=35,id=16538,kind="Talent",tree="Protection",note="Requires talent investment"}
  }
 }
}
-- Optional character spellbook checks are independent of the level gate:
-- level eligibility never implies the spell was trained or a talent was chosen.
function ForeverCompanionKnownSpell(spellID)
 if type(IsSpellKnown)=="function" then
  local ok,known=pcall(IsSpellKnown,spellID)
  if ok and type(known)=="boolean" then return known end
 end
 if type(IsPlayerSpell)=="function" then
  local ok,known=pcall(IsPlayerSpell,spellID)
  if ok and type(known)=="boolean" then return known end
 end
 return nil
end

-- Read-only audit helpers for patch updates and data quality checks.
function ForeverCompanionAbilityAudit()
 local data=ForeverCompanionVerifiedAbilities
 local classes={"WARRIOR","PALADIN","HUNTER","ROGUE","PRIEST","SHAMAN","MAGE","WARLOCK","DRUID"}
 local report={build=data.build,checked=data.checked,classes={},total=0,issues={}}
 local ids={}
 for _,token in ipairs(classes) do
  local entries=data.entries[token] or {}
  report.classes[token]=#entries
  report.total=report.total+#entries
  for _,entry in ipairs(entries) do
   if type(entry.id)~="number" or entry.id<=0 or type(entry.level)~="number" or entry.level<1 then
    report.issues[#report.issues+1]=token..": invalid spell ID or level"
   elseif ids[entry.id] then
    report.issues[#report.issues+1]=token..": duplicate spell ID "..entry.id
   else ids[entry.id]=true end
   if entry.kind~="Trainer" and entry.kind~="Quest" and entry.kind~="Talent" then
    report.issues[#report.issues+1]=token..": unsupported unlock kind"
   end
  end
 end
 return report
end

function ForeverCompanionAbilityReferenceLines(classToken,level)
 local data=ForeverCompanionVerifiedAbilities
 local result={"FOREVER CLIENT SPELL REFERENCE | "..data.build,
               data.status.." | Last reviewed "..data.checked}
 local entries=data.entries[classToken]
 if not entries then
  result[#result+1]="This class is pending spell-by-spell client-data verification."
  return result
 end
 local n=tonumber(level)
 local ordered={}
 for i,entry in ipairs(entries) do ordered[i]=entry end
 table.sort(ordered,function(a,b) if a.level==b.level then return a.name<b.name end return a.level<b.level end)
 for _,entry in ipairs(ordered) do
  local gate=not n and "LEVEL UNKNOWN" or (n>=entry.level and "LEVEL MET" or "LOCKED BY LEVEL")
  local known=ForeverCompanionKnownSpell(entry.id)
  local ownership=known==true and "KNOWN IN SPELLBOOK" or (known==false and "NOT KNOWN" or "SPELLBOOK STATUS UNKNOWN")
  local requirement=entry.kind=="Talent" and "Talent investment required" or (entry.kind=="Quest" and "Quest completion required" or "Trainer / spellbook check required")
  result[#result+1]=entry.name.." (spell "..entry.id..") | "..entry.tree.." | level "..entry.level.." | "..gate.." | "..ownership
  result[#result+1]="  "..requirement..". "..entry.note
 end
 return result
end
