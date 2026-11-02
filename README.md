# Forever Companion

Independent, free World of Warcraft addon project for class-aware leveling, dungeon, profession, and PvP reference guides.

## Status

Prelaunch beta. Not yet tested in the target game client. Game-specific claims, Interface version, and CurseForge compatibility require verification.

## Premium dashboard (develop beta)

The Overview is now a native WoW UI with a gold-accented sidebar, welcome banner, character summary, four quick actions, read-only progress bars, recommended next steps, and a manually checked **Today's Focus** list. The checklist is saved per character; it never executes gameplay actions. The compact toggle hides the lower dashboard panels, and the window scales down when the game UI is smaller.

- Character name, class, level, and role preference come from game APIs and saved settings.
- Quest count, ready count, and selected quest come from the quest log **only if that API is available and a successful scan has occurred**.
- Experience progress uses optional XP APIs and shows N/A when unavailable.
- Profession names/skill levels use the profession API when available. Crafting-goal progress comes from **manual** /fcm entries, not inventory scans.
- Diagnostics opens Settings, where API-presence information is displayed. These checks do not establish compatibility or compliance.

The GitHub Actions `offline-ui-snapshot` artifact includes a source-validated PNG illustration of the mocked interface. It is **not an in-game screenshot**, and the example character, quests, and materials are test fixtures. The real target-client Interface number and API behavior remain unverified.

## What's new in 3.11.0-beta (develop, November 2, 2026)

- **Quest Journal:** Native gold-accented quest rows show title, zone and ready/active status. Sorting can be switched between log, zone and ready order through the UI or `/fcq sort`; filtering and pagination remain available. Clicking a row changes only the addon's focus.
- **Objective detail:** Modern and Classic quest APIs now provide *known* objective-completion counts when the client supplies completion flags. Missing flags remain unknown; no progress is guessed.
- **Profession compatibility:** Modern profession slots are scanned even when some slots are empty. A read-only Classic skill-line fallback recognizes standard English profession names; custom or localized names may require manual notes.
- **Profession selector:** The nine handbook categories use native black-and-gold icon tabs with a selected state.
- **Dashboard:** Recommended steps are clickable navigation controls. The Today's Focus checklist resets on a confirmed client date change, and retains state if the date API is unavailable.
- **Leveling:** The class hero shows the player's current general leveling band alongside class guidance and the existing XP indicator.
- **Resilience:** The window responds to display/UI-scale changes and tolerates unavailable geometry reads. Mocked tests cover API failures, daily focus rollover, quest sorting, objective flags and navigation.
- **Visuals:** Native gold corner ornaments and a framed crest were added. The offline previews are illustrative approximations generated from the mock widget tree, not real game screenshots.

All guide routes, class ability priorities, recipe recommendations and game-version claims remain general references until tested in the target client. The addon does not cast spells, turn in quests, move the player, or perform crafting actions.

## Beta features

- Premium black-and-gold seven-section UI with native sidebar, responsive scaling, dashboard and class-guide panels
- Character/class/role overview, guarded XP display, quest readiness and manual material-goal progress
- Quest Journal with read-only modern/legacy quest-log scanning, focus controls, filters, pagination, zone summary and stale-data warnings
- Profession Skills and Material Goals cards, detected skill/cap information, manual material adjustments and recipe-planning references
- Nine Classic-era class references with role and rotation priorities; nine profession handbooks with detailed general planning advice
- Per-character saved checklists, preferences, focus goals and movable window position
- Offline mocked UI tests and clearly labeled illustrative PNG previews; Lua syntax, manifest audit and ZIP packaging in GitHub Actions

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

**Prelaunch limitations:** This is not a full Questie replacement. It attempts passive automatic quest-log detection through supported APIs, but that behavior has not been verified in the Forever client. There is no verified Forever-specific quest database, map overlay or pathfinding. The manifest Interface value is provisional. Live client testing is required before claiming compatibility.

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
