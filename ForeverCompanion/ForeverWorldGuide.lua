-- Official Forever world/talent milestones, not a quest-route database.
-- Blizzard 2026-09-12: https://worldofwarcraft.blizzard.com/en-us/news/24303862/world-of-warcraft-forever-whats-next
-- Blizzard class deep dive: https://worldofwarcraft.blizzard.com/en-us/news/24302099
ForeverCompanionWorldGuide={}
local W=ForeverCompanionWorldGuide
function W.Milestones(level)
 level=tonumber(level) or 1
 local lines={"FOREVER MILESTONES - BLIZZARD PUBLISHED PREVIEW"}
 if level<10 then
  lines[#lines+1]="At level 10: talent points become available (per Blizzard class deep dives)."
 elseif level<40 then
  lines[#lines+1]="Talents: available from level 10; dual specialization is announced for level 40."
 else
  lines[#lines+1]="Dual specialization: Blizzard announced availability starting at level 40; confirm trainer and client rules."
 end
 if level<=12 then
  lines[#lines+1]="Zephras Isle: published level 1-12 starting area for Skyborne characters, not a universal starting route."
 end
 if level>=30 and level<=47 then
  lines[#lines+1]="Riverglades: Blizzard describes 150+ quests spanning much of the mid-30s to mid-40s."
 end
 if level>=50 then
  lines[#lines+1]="Mount Hyjal and Shen'dralas are announced new regions; their exact quest prerequisites need in-game verification."
 end
 if level>=60 then
  lines[#lines+1]="Level 60 is the published Forever level cap."
 end
 lines[#lines+1]="Forever adds 1,000+ quests across levels 1-60. These are world facts, not verified quest coordinates or optimized routes."
 lines[#lines+1]="Sources: Blizzard What's Next (2026-09-12); Blizzard class deep dives (2026-10)."
 return lines
end
function W.Format(level)
 return table.concat(W.Milestones(level),"\n")
end
