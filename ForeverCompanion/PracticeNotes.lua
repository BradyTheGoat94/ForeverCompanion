-- General WoW learning goals, not verified Forever mechanics or simulated APLs.
-- No numerical breakpoints, talent unlock levels or DPS promises are inferred.
local notes={
 WARRIOR={
  Arms={"Stay in melee while saving Rage for your next priority attack.","Spending Rage on a nearly defeated target can leave the next pull slow."},
  Fury={"Keep weapon attacks connecting before adding more buttons.","Avoid chasing cooldown use while losing time out of melee range."},
  Protection={"Practice recovering a loose enemy while keeping the pack positioned.","Threat alone is not safety; save a defensive for incoming danger."}},
 PALADIN={
  Holy={"Choose a heal by urgency and watch how much healing is wasted.","Repeated emergency heals during light damage can consume mana unnecessarily."},
  Protection={"Confirm your threat setup before the group begins dealing damage.","Do not spend so much mana on damage that you cannot respond to danger."},
  Retribution={"Keep melee uptime while maintaining your trained support effects.","Utility that prevents a death can be more valuable than another damage cast."}},
 HUNTER={
  ["Beast Mastery"]={"Keep your pet on the intended target and watch its survival.","Sending the pet ahead can start unwanted combat or break assigned control."},
  Marksmanship={"Practice maintaining ranged attacks while choosing safe positions.","Movement and unnecessary target changes can interrupt sustained damage."},
  Survival={"Decide whether the pull needs ranged pressure or close-range control.","Do not enter melee without a safe plan to survive or regain distance."}},
 ROGUE={
  Assassination={"Track Energy and combo points before choosing the next builder.","An extra builder at full combo points wastes a resource opportunity."},
  Combat={"Practice finishers on durable targets while keeping Kick available.","Spending all Energy can leave no immediate response to a dangerous cast."},
  Subtlety={"Choose your opener and an escape route before leaving Stealth.","Using every control tool at once can leave no recovery option."}},
 PRIEST={
  Discipline={"Practice prevention and efficient recovery without exhausting mana.","Absorbs that expire unused may not justify their resource cost."},
  Holy={"Match each heal to the number of allies who actually need it.","Large group heals during isolated damage can waste mana and time."},
  Shadow={"Apply periodic damage only when the target should live long enough.","Refreshing effects too early or applying them to dying targets wastes mana."}},
 SHAMAN={
  Elemental={"Keep safe casting uptime and budget mana for group utility.","Damage spells should not leave you unable to provide an urgent heal or interrupt."},
  Enhancement={"Maintain melee uptime while placing useful totems deliberately.","Repeatedly replacing totems without a purpose can waste mana and actions."},
  Restoration={"Practice efficient healing while keeping the group within range.","A group heal loses value when its potential recipients do not need healing."}},
 MAGE={
  Arcane={"Plan a sustainable mana pace before committing to a burst window.","Spending everything early can cost more uptime than the burst gains."},
  Fire={"Choose a safe casting position before starting sustained damage.","Repeated movement during casts can lose more damage than a small spell-order change."},
  Frost={"Practice using control to create room for uninterrupted casts.","Breaking your own crowd control can turn a safe pull into recovery time."}},
 WARLOCK={
  Affliction={"Keep useful periodic effects active while maintaining pet control.","Applying a full set of effects to a dying enemy wastes setup time."},
  Demonology={"Watch pet target, positioning and health during each pull.","Pet downtime and uncontrolled movement can undermine an otherwise tidy rotation."},
  Destruction={"Secure casting uptime and watch threat before committing burst.","Large damage followed by lost control of the enemy can cost the group more time."}},
 DRUID={
  Balance={"Plan safe casting time and mana recovery across several pulls.","A short burst that forces extended drinking may reduce sustained progress."},
  Feral={"Stay in the intended form and manage its resources deliberately.","Unplanned form changes can interrupt the resource flow you were practicing."},
  Restoration={"Use periodic healing where its duration will provide useful recovery.","Refreshing effects with little benefit can consume mana needed for emergencies."},
  ["Guardian / Bear"]={"Treat this as a bear-form planning alternative until the live talent tree confirms it.","Do not infer that a separate Guardian specialization exists in Forever."}}
}
ForeverCompanionPracticeNotes={}
function ForeverCompanionPracticeNotes.Lines(class)
 local spec=ForeverCompanionSpecPlanner and ForeverCompanionSpecPlanner.Get(class)
 local entry=spec and notes[class] and notes[class][spec[1]]
 if not entry then return {} end
 local lines={"PRACTICE GOAL / "..spec[1].." / GENERAL WOW GUIDANCE","Try this: "..entry[1],"Common mistake: "..entry[2]}
 local role=spec[2]
 if role=="Healer" then
  lines[#lines+1]="Cooldown practice: plan a recovery tool for rising damage; agree on coverage with the group."
 elseif role=="Tank" then
  lines[#lines+1]="Cooldown practice: anticipate incoming danger and avoid overlapping every defensive without a reason."
 else
  lines[#lines+1]="Cooldown practice: use offense when you can stay active; keep a defensive or escape available for danger."
 end
 lines[#lines+1]="Review one pull: did you lose uptime, waste resources, miss utility, or need emergency recovery? Change one habit and repeat."
 lines[#lines+1]="This is an observational learning exercise, not a DPS benchmark or verified Forever priority. Consult the source-reviewed conditional guide for spell order."
 return lines
end
