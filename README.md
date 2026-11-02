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

## Recipe-to-material bridge (3.1 beta)

The Professions tab now compares the aggregated demand from your recipe goals with manually entered owned quantities, displaying the remaining shortage for each ingredient.

- `/fcbridge preview Alchemy` shows a read-only demand and shortage breakdown.
- `/fcbridge sync Alchemy` **explicitly** copies recipe ingredient requirements into the existing material checklist, keeping manually entered owned counts and unrelated material goals.

Synchronization is never automatic. Existing checklist targets matching recipe ingredients are replaced, so preview first. Sync validates checklist capacity and quantity limits before applying changes. Ingredient names are matched case-insensitively after trimming surrounding whitespace. Inventory is not scanned; counts remain manually supplied.

## Read-only spellbook availability (3.2 beta)

The Leveling rotation panel now attempts to inspect the player's spellbook using guarded legacy spellbook APIs and labels simple cooldown candidates **learned**, **not found in scanned spellbook**, or **unverified**. Compound alternatives and version/talent-qualified candidates remain explicitly unverified rather than being guessed. Unsupported clients display an unavailable notice. This does **not** verify rank, talents, cooldown duration, or server mechanics and does not cast spells.

**Important:** Class preview may show a class different from the player's real character; spellbook results always reflect the actual player's known spells, not the preview class. This feature needs live testing on the Forever client before relying on its availability labels.

## Forever API compatibility research (3.3 beta)

Forever beta uses a modern Mainline-derived API despite interface 16001. The spellbook reader has been migrated from removed legacy globals to `C_SpellBook.GetNumSpellBookSkillLines`, `C_SpellBook.GetSpellBookSkillLineInfo`, and `C_SpellBook.GetSpellBookItemName` with the Player spellbook bank. Missing or incomplete results are handled conservatively. Sources: [captured Forever API](https://atraeau.github.io/WoW-Addons/), [beta client testing](https://github.com/Thunderz96/forever-addon-kit), and [C_SpellBook API](https://warcraft.wiki.gg/wiki/API_C_SpellBook.GetSpellBookItemName).

Other legacy API modules still require audit and live-client tests. Spec previews are manual and not a claim of the player's active Forever talent specialization. Combat secrets and restricted data limit automated combat-driven features.

## Safe client diagnostics (3.5 beta)

Use `/fcdiag` to print the detected client build and the availability of key spellbook, talent, quest, profession and XP APIs. The same compatibility summary appears in Overview. These are passive presence checks only: they do not run combat actions, inspect process memory, access network packets, or prove that an API behaves correctly. Record the report and any Lua errors during a future official test window; do not treat a successful report as Blizzard approval.

## Offline regression tests (3.6 beta)

Run `lua5.1 tests/offline_smoke.lua` from the repository root. The CI pipeline runs these mocked-client tests before packaging. They verify spellbook API fallback and name matching, multi-recipe ingredient demand, owned-count preservation during manual sync, and diagnostics when client APIs are absent. These tests do not connect to the game and cannot certify compatibility or account safety; live client verification remains mandatory before public release.

## Guarded quest log compatibility (3.7 beta)

The quest planner now uses the modern `C_QuestLog` APIs through protected calls. Header sections are used as zone fallback when quest-specific metadata is absent. If the client API throws an error or is temporarily unavailable, the addon retains the last successfully scanned quest snapshot instead of erasing it. This snapshot may be stale; it is not evidence that quests remain active. The change is covered by mocked-client regression tests and still requires live Forever verification.
