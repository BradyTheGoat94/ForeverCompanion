-- Selected, paraphrased class changes from Blizzard's 2026 Forever deep dives.
-- These are published beta descriptions, NOT confirmation that the player's
-- current client has the spell or that a given build is optimal.
ForeverCompanionClassChanges={}
local C=ForeverCompanionClassChanges
C.classes={
 WARRIOR={source="https://worldofwarcraft.blizzard.com/en-us/news/24301514",notes={
  {14,"Tactical Mastery is announced as a learned skill retaining 10 Rage when swapping stances."},
  {20,"Victory Rush is announced as a kill-triggered attack with a small self-heal."},
  {nil,"Blizzard describes revised Rage generation and separate cooldowns for major Warrior defensives."},
 }},
 PRIEST={source="https://worldofwarcraft.blizzard.com/en-us/news/24301514",notes={
  {20,"Fear Ward and Devouring Plague are announced for all Priests."},
  {30,"Divine Spirit is described as a baseline ability."},
  {32,"Shadow Word: Death is announced as a baseline spell."},
 }},
 HUNTER={source="https://worldofwarcraft.blizzard.com/en-us/news/24301515",notes={
  {20,"Aimed Shot is described as a baseline Hunter ability."},
  {nil,"Traps can be used during combat in the published Forever redesign."},
  {nil,"Pets gain stat scaling and additional family-specific abilities."},
 }},
 DRUID={source="https://worldofwarcraft.blizzard.com/en-us/news/24301515",notes={
  {nil,"Nature's Grasp and Omen of Clarity move into the baseline Druid kit."},
  {nil,"A new out-of-combat resurrection spell, Revive, is announced."},
  {nil,"Many consumables and weapon effects work while shapeshifted in the published changes."},
 }},
 MAGE={source="https://worldofwarcraft.blizzard.com/en-us/news/24302097",notes={
  {40,"Frostfire Bolt is announced as a spell benefiting from Fire and Frost interactions."},
  {nil,"Arcane Blast becomes an 11-point Arcane talent with a redesigned follow-up-spell mechanic."},
  {nil,"Ignite is described as a separate damage-over-time effect per Mage rather than shared."},
 }},
 SHAMAN={source="https://worldofwarcraft.blizzard.com/en-us/news/24302097",notes={
  {20,"Totemic Recall and Call of the Elements are announced as learned utility abilities."},
  {30,"Call of the Spirits provides a second preset set of totems."},
  {40,"Call of the Ancestors provides a third preset set of totems."},
 }},
 ROGUE={source="https://worldofwarcraft.blizzard.com/en-us/news/24310968/world-of-warcraft-forever-class-deep-dives-rogue-and-warlock",notes={
  {nil,"Sap is described as no longer breaking Stealth."},
  {nil,"Poisons can coexist with temporary weapon enchants in the published redesign."},
  {nil,"Rogues can learn to use one-handed axes."},
 }},
 WARLOCK={source="https://worldofwarcraft.blizzard.com/en-us/news/24310968/world-of-warcraft-forever-class-deep-dives-rogue-and-warlock",notes={
  {nil,"Agony and Doom become Banes, separated from utility Curses."},
  {nil,"Firestone and Spellstone become compatible weapon imbues."},
  {nil,"Warlock demons gain scaling from their owner's statistics."},
 }},
 PALADIN={source="https://worldofwarcraft.blizzard.com/en-us/news/24302099",notes={
  {6,"Holy Strike is announced as a learned baseline attack."},
  {nil,"Judgement is described as no longer consuming the active Seal."},
  {nil,"Holy, Protection and Retribution receive revised talents and new combat options."},
 }},
}
function C.Format(class,level)
 local entry=C.classes[class]
 if not entry then return "OFFICIAL CLASS PREVIEW: No curated published changes." end
 local n=tonumber(level) or 1
 local lines={"FOREVER CLASS CHANGES - BLIZZARD PUBLISHED BETA PREVIEW"}
 for _,fact in ipairs(entry.notes) do
  local gate=fact[1]
  local label=gate and (n<gate and ("Announced for level "..gate.." (later): ") or ("Published level "..gate..": ")) or "Published change: "
  lines[#lines+1]=label..fact[2]
 end
 lines[#lines+1]="Source: "..entry.source
 lines[#lines+1]="Check live spellbook and trainer; published beta mechanics may change."
 return table.concat(lines,"\n")
end
