-- Original paraphrased teaching cues derived from Blizzard Forever class deep dives.
-- Published beta design only. Not a validated rotation or spellbook assertion.
ForeverCompanionForeverLessons={
 WARRIOR={source="https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior",steps={"Build Rage with sustained attacks; do not assume every spender is affordable.","Stance swapping changes which abilities are available; check your current stance.","Check whether Victory Rush is available after a qualifying kill before planning a heal."}},
 PALADIN={source="https://worldofwarcraft.blizzard.com/en-us/news/24303313",steps={"Maintain an appropriate Seal and Blessing; Forever Judgement does not consume the Seal.","Use trained Holy Strike when appropriate; evaluate target and cooldown.","Consecration is baseline at level 20, but conserve mana and avoid unsafe area pulls.","Protection: verify Seal of Fury before expecting its Judgement taunt."}},
 HUNTER={source="https://www.wowhead.com/news/druid-and-hunter-class-deep-dives-in-world-of-warcraft-forever-383190",steps={"Keep the pet on the intended target; its survival affects your uptime.","At level 20, check your trainer for baseline Aimed Shot.","Aimed Shot and Multi-Shot share a cooldown; Arcane Shot does not share that cooldown.","Traps can be used during combat; avoid ranged dead-zone positioning."}},
 ROGUE={source="https://www.wowhead.com/news/rogue-and-warlock-class-deep-dive-in-world-of-warcraft-forever-383299",steps={"Apply trained poisons; Forever permits them alongside temporary weapon enhancements.","Build combo points, then spend on a useful finisher instead of wasting points.","Assassination: only use Mutilate with two daggers and the required talent.","Assassination: Venom is a talented finisher; do not assume it is baseline."}},
 PRIEST={source="https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior",steps={"Use trained shields or heals when survival requires them; do not spend all mana on damage.","Fear Ward and Devouring Plague become available across races at level 20.","Divine Spirit is baseline at level 30; Shadow Word: Death is baseline at level 32.","Shadow Word: Death is situational; consider the risk of its backlash."}},
 SHAMAN={source="https://worldofwarcraft.blizzard.com/en-us/news/24302097",steps={"Place totems to support the pull, then avoid leaving their useful range.","Check the level-20 Totemic Recall and Call of the Elements utility.","Use shocks deliberately so mana remains available for emergencies.","Enhancement and Elemental priorities differ; choose the role and trained talents first."}},
 MAGE={source="https://worldofwarcraft.blizzard.com/en-us/news/24302097",steps={"Keep a safe casting distance and manage mana between pulls.","Arcane Blast is a Forever talent, not evidence that retail Arcane Charges exist.","Use Frost control to survive when enemies close distance.","Frostfire Bolt is described as a level-40 spell; check trainer and patch."}},
 WARLOCK={source="https://www.wowhead.com/news/rogue-and-warlock-class-deep-dive-in-world-of-warcraft-forever-383299",steps={"Choose and command a pet suited to the pull; pet stats scale with yours.","Use damage-over-time effects on enemies that will live long enough.","Forever Banes and utility Curses have distinct roles; check your spellbook.","Life Tap only when health is safe; avoid sacrificing survival for mana."}},
 DRUID={source="https://www.wowhead.com/news/druid-and-hunter-class-deep-dives-in-world-of-warcraft-forever-383190",steps={"Match Cat, Bear, or caster form to your role and current resource.","Omen of Clarity becomes baseline at level 20; Nature's Grasp at level 10.","Lacerate moved to a Feral talent in the latest reported tuning; check your talents and current patch before planning around it.","Weapon effects and many consumables now work while shapeshifted.","Revive is an out-of-combat resurrection spell described for level 12."}}
}
-- Patch-watch advisories from Wowhead's November 2026 live-server
-- observations. These reports were not yet confirmed by official notes.
ForeverCompanionNovemberTuning={
 DRUID={"Feral Lacerate is now reported as a talent, not a baseline spell.","Feral Berserk is reported removed; recheck saved builds.","Balance Genesis periodic scaling and talent locations changed."},
 PALADIN={"Protection talent placements and Shield specialization ranks changed.","Retribution Champion of the Light, Conviction, and Two-Handed Weapon Specialization changed.","Review Judgement and tank threat builds before following an older talent string."},
 PRIEST={"Shadow Word: Death backlash was reported increased to 30%; check survivability."},
 WARLOCK={"Improved Drains was retuned to affect Drain Mana rather than Wrack."},
 WARRIOR={"Revenge attack-power scaling was updated across ranks."}
}
function ForeverCompanionNovemberTuningLines(classToken)
 local notes=ForeverCompanionNovemberTuning[classToken]
 if not notes then return {} end
 local lines={"NOVEMBER 2026 TUNING WATCH | REPORTED, NOT OFFICIALLY CONFIRMED"}
 for i,note in ipairs(notes) do lines[#lines+1]=i..". "..note end
 lines[#lines+1]="SOURCE: https://www.wowhead.com/news/massive-talent-tree-changes-to-druids-and-paladins-class-tuning-for-wow-forever-383670"
 return lines
end

function ForeverCompanionForeverLessonLines(classToken)
 local data=ForeverCompanionForeverLessons[classToken]
 if not data then return {} end
 local lines={"FOREVER-SPECIFIC MECHANICS | PUBLISHED BETA"}
 for i,step in ipairs(data.steps) do lines[#lines+1]=i..". "..step end
 lines[#lines+1]="SOURCE: "..data.source
 lines[#lines+1]="Published design; November tuning may supersede earlier notes. Verify unlocks, talents, ranks and current patch in game."
 return lines
end
