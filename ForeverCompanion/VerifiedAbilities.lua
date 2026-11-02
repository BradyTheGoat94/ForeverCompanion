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
 for _,entry in ipairs(entries) do
  local gate=not n and "LEVEL UNKNOWN" or (n>=entry.level and "LEVEL MET" or "LOCKED BY LEVEL")
  local requirement=entry.kind=="Talent" and "Talent investment required" or (entry.kind=="Quest" and "Quest completion required" or "Trainer / spellbook check required")
  result[#result+1]=entry.name.." (spell "..entry.id..") | "..entry.tree.." | level "..entry.level.." | "..gate
  result[#result+1]="  "..requirement..". "..entry.note
 end
 return result
end
