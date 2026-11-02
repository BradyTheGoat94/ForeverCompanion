# Forever Companion

Independent, free World of Warcraft addon project for class-aware leveling, dungeon, profession, and PvP reference guides.

## Status

Prelaunch beta. Not yet tested in the target game client. Game-specific claims, Interface version, and CurseForge compatibility require verification.

## Beta features

- Seven-tab guide window: Overview, Leveling, Quests, Dungeons, Professions, PvP and Settings
- Automatic detection of the nine original classes, plus class preview and role preference
- General class guidance, leveling bands, dungeon preparation and manual checklists
- Per-character saved checklist progress, preferences and movable window position
- Manual quest planner with name, zone and completion state (up to 100 entries)
- GitHub Actions Lua syntax checking, manifest validation and ZIP packaging

## Commands

- `/fc` — toggle window
- `/fc help` — list guide commands
- `/fc class Mage` or `/fc class auto` — class preview or automatic detection
- `/fc role Damage` — set role preference
- `/fc professions Mining + Blacksmithing` — save profession notes
- `/fc check Dungeons 1` — toggle a checklist item
- `/fc position reset` — center the window
- `/fcq add Quest Name | Zone` — track a quest
- `/fcq list` — list quests
- `/fcq done 1` — toggle quest completion
- `/fcq remove 1` — remove a quest

**Prelaunch limitations:** This is not a full Questie replacement. There is no verified Forever-specific quest database, automatic quest detection, map overlay or pathfinding yet. The manifest Interface value is provisional. Live client testing is required before claiming compatibility.

## Development

Active work happens on `develop`; `main` is reserved for reviewed releases. The addon must use supported game APIs and must not automate protected gameplay actions.

## Installation (when tested)

Copy the `ForeverCompanion` folder to the game's `Interface/AddOns` directory. Enable it in the addon list and type `/fc`.

## License

All rights reserved pending an explicit license decision. Do not assume public distribution of source grants permission to reuse it.

## Crafting planner (1.7.0 beta)

The Professions tab displays detected skills when the client exposes the profession API, introductory progression advice, and a persistent **manual** material checklist per profession. No inventory scanning or automatic crafting is performed.

Example commands:

- `/fcm add Alchemy | Peacebloom | 20 | 7` — track 20 required, 7 owned.
- `/fcm owned Alchemy | 1 | 12` — update owned quantity of entry 1.
- `/fcm remove Alchemy | 1` — delete an entry.

These example materials are not a verified Forever recipe or leveling route. Skill stage labels are broad orientation, not verified recipe thresholds. Existing class rotations are educational priorities rather than tested optimization.

### Crafting goal dashboard (1.8 beta)

The Overview and Professions pages now show an aggregate count of material goals, completed goals, and outstanding material units. Additional commands: `/fcm summary` displays the totals; `/fcm needed Alchemy | 1 | 30` changes a target; `/fcm clear Alchemy` removes only completed goals. All quantities remain manually entered; there is no live bag scan.

## Multi-recipe planner (2.1 beta)

Track multiple manual recipe goals per profession and see **aggregate material demand** for the crafts still outstanding. This is a planning tool, not a verified WoW Forever recipe database. It does not scan bags or craft items.

- `/fcr add Alchemy | Sample Potion | 10` adds a goal to craft 10.
- `/fcr ingredient Alchemy | 1 | Sample Herb | 2` records two herbs per craft.
- `/fcr done Alchemy | 1 | 4` records four crafted, reducing remaining ingredient demand to 12 herbs.
- `/fcr show Alchemy` prints the recipe list and total ingredient demand.
- `/fcr remove Alchemy | 1` deletes a recipe goal.

Sample names above are illustrative placeholders, not validated game recipes. Ingredient demand is separate from the manual owned-material checklist; no automatic reconciliation is claimed.

## Specialization planning (3.0 beta)

The Leveling guide now has a clickable **Spec** selector beside the rotation-mode selector. It remembers the selected specialization per class and displays role-based planning priorities for leveling, dungeons, bosses, AoE, and PvP, including when to reserve offensive, defensive, and utility cooldowns. There are 28 preview profiles across the nine original classes; the Guardian/Bear entry is explicitly version-dependent.

Use `/fcspec WARRIOR` (replace WARRIOR with a class token) to cycle its preview. The spec profiles are **educational planning frameworks, not validated spell-by-spell rotations, talent builds, or measured DPS rankings**. WoW Forever's actual spell/talent data must be verified before claiming optimization.
