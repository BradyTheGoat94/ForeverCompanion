# Brady's Forever Companion

Brady's Forever Companion is an independent, free World of Warcraft addon project for class-aware leveling, dungeon, profession, and PvP reference guides.

## Maps, quests, training and dungeons (3.49 beta)

Use `/fc overlay detailed` for richer outdoor terrain, `/fc overlay inspect` for wheel zoom, drag-to-pan and location details, and `/fc training` for the class training reference. Quest Log now includes search and a details/back flow. Location options in quest details can exclude a wrong reference point and copy a local report. The dungeon directory includes Stockades independently of partial loot imports. See docs/SPRINT_3_49.md and docs/LOOT_RESEARCH_2026_11_09.md for scope and remaining gaps.

## Status

Prelaunch beta. Not yet tested in the target game client. Game-specific claims, Interface version, and CurseForge compatibility require verification.

## Live objective itinerary and performance samples (3.40 beta)

Leveling Route now includes a paged itinerary of individual unfinished objectives
and known turn-ins on the current map. It uses explicitly matched locations,
rechecks a stop before navigation and reports gaps in coverage. Pinned quests and
turn-ins get priority; distance order is approximate and does not account for
terrain. Missing player position preserves quest-log order within priority groups.
This is not a playthrough-verified starter-zone walkthrough.

Settings → **Performance sample** (or `/fc performance window`) shows real refresh
call counts and available timings for the meter, map and itinerary. Use **Start new
sample** or `/fc performance reset` before comparing the same activity/settings.
Scopes may overlap; these are not total CPU or FPS measurements. Meter options →
**Refresh rate** offers 0.2, 0.4 or 0.8 seconds without modifying combat values.

## Quest setup and validation (3.39 beta)

Click **Quest data: … / Setup** in the journal, use Settings → **Quest data & setup**,
or type `/fc setup` to see which quest sources are available and why markers may
be missing. **Next objective** opens the field guide while retaining player-started
map navigation. Specialization and role buttons now offer direct choice menus.

`/fc performance` reports queued page-refresh requests, merged work and measured
batch timings where the client exposes a profiling clock. It does not measure
frame rate or total addon CPU. Run `python tools/validate_all.py` for the same
offline acceptance used by every workflow; Lua 5.1 is required (the optional local
lupa runtime is also supported). Manual CurseForge uploads remain the release path.

## Interface review (3.38 beta, develop)

Class reference pages use measured reading cards. Gear priorities sit beside
comparison advice and reported targets; attribution and beta caveats remain
available below. Settings has a structured command reference. Discovery and bank
panels fit short lists, shared rows have consistent hover feedback, and long pages
show continuation cues. The map toolbar follows the shared visual style.
Offline previews approximate native fonts and icons; they are not game screenshots.

## Questing workspace (3.36 beta, develop)

The Quest Log now combines an objective field guide, searchable pickup discovery,
a mapped quest-giver catalog and observed turn-in history. Use **Objective details**
for matched destinations and progress, **Find new quests** for discovery, or the
**Zone catalog** tab to inspect active, completed, blocked and unknown references.
The catalog explains supported prerequisites and can follow the world-map zone.
Its coverage is limited to character-compatible giver locations in Forever QuestieDB.

**Show tracker** enables a movable, collapsible companion tracker with pinned and
ready priorities. **Turn-in history** retains the latest 300 events observed while
the addon is running, including reported rewards. Older completion flags remain
separate from dated history. Shortcuts: `/fc tracker`, `/fc discover`,
`/fc questbook` and `/fc history`.

## Stat priorities, accurate icon identities and gear browsing (3.18.0-beta, develop)

**Class Guides → Gear & Stats** follows the selected specialization and now has
27 source-reviewed Forever PvE stat profiles, plus the conditional Bear tank
reference. Each includes a ranked reference, practical comparison notes, a source
URL and review date. These are beta theorycraft, not live-tested weights or a
universal shopping rule. Talent-adjusted targets and tank survival/threat choices
are explained. Conflicting Fury Hit figures are explicitly flagged; no universal
numeric cap is inferred for that profile. A complete verified BiS set is not yet
established. Sources and editorial decisions: [STAT_PRIORITY_SOURCES.md](docs/STAT_PRIORITY_SOURCES.md).

Class badges now use Blizzard's actual class-icon sheet and distinct class crops,
rather than spell art used as class symbols. Dashboard, class banner, class strip
and generic priority tiles share the same mapping. Named ability cards query the
client's spell-texture API only when that name occurs in the full instruction.
The selected detail and hover tooltip identify the artwork cue. Missing spell
art shows a question mark; general instructions use the class emblem. Artwork
lookup never proves a spell is trained. English-name lookup can remain unresolved
on a localized client; no cross-version spell IDs are guessed. See
[ICON_IDENTITY_AUDIT.md](docs/ICON_IDENTITY_AUDIT.md).

**Gear & Loot** now has six clickable catalog rows per page, a source-detail card,
slot filters, and All / Not marked / Obtained (manual) acquisition filters. These
combine with the existing search, dungeon, boss and wishlist filters. Selecting a
row updates the existing wishlist and acquisition controls. **Open selected boss
research** opens that encounter and its personal notebook. Opening loot from the
boss browser clears unrelated slot/acquisition filters; **Clear filters** resets
all filters. Acquisitions and saved targets remain separate per-character notes.
The eight existing sourced catalog records are unchanged; this is not a full loot
database, inventory scanner, drop-rate predictor, or automatically ranked BiS list.

Offline tests cover icon identity/crop resets, all stat profiles, compound filters,
paging, empty results, long source descriptions and the round trip between an item
and its boss notebook. `ui_gear_native.png` and `ui_loot_native.png` in CI illustrate
the captured layout; Blizzard icons and fonts are approximations, not client images.

## Readable class-guide detail (3.17.0-beta, develop)

Selected ability instructions now use a larger, multiline detail card whose height
follows the measured text. The practice desk and long reference guide move below
it. The instruction table has taller click targets, larger text and full hover
explanations. Resource and specialization information use separate labeled blocks.
Topic pages also expand for long text and move their handbook shortcut below it.
Gold frame edges follow resized cards. These changes apply across all nine classes
and five rotation contexts; they do not change ability recommendations or evidence.

CI exercises every available priority selection and forced long-text layouts,
including expansion, shrink-back, frame borders and separation from the practice
desk. `ui_long_priority_native.png` illustrates the expanded mock layout. Live
Forever font metrics and appearance still require client testing.

## Searchable encounter catalog (develop)

The Dungeons page has clickable boss rows with four results per page. Search the
selected dungeon by boss, dungeon or item name; use **Clear search** to restore
its list. Changing the search does not change the selected encounter. Click a
boss row to switch its research notebook, then **Open boss loot** to browse that
boss's attributed records. Changing dungeon clears the search and selects its
first catalog boss. This is a partial historical loot catalog, not a complete
boss roster or a verified encounter guide; no mechanics or drop rates are inferred.

Unsaved research text is retained as a session draft when switching between
bosses, Legacy, Alts and other pages. Returning to its context restores the draft.
**Save research note** (or Enter) writes it for the character; Escape restores the
saved note, and Clear removes that context's saved note and draft. Drafts are lost
on UI reload or logout, so save before leaving the session. Notes remain personal
observations and never change the guide's evidence status.

CI also captures `ui_encounter_snapshot.txt` and renders
`ui_encounter_preview.png` from the browser's native widget coordinates. This is
an offline illustration with approximate fonts, not an in-game screenshot.

## Illustrated class guide (3.16.0-beta, develop)

The **Class Guides** sidebar entry opens a wide class banner with eight functional
blue-accented topic tabs. Choose Overview, Talents, Rotations, Leveling, Dungeons,
PvP, Gear & Stats or Professions. The selected topic is saved per character;
invalid saved values safely return to Rotations. Topic content uses the existing
advisory references. Talents is a planning reference, not an interactive talent
allocation tool; Gear & Stats does not invent stat weights or best-in-slot lists.

The rotation view has a direct five-context rail, larger numbered icon tiles,
clickable explanation rows, class quick information and a complete selected
instruction. Concise captions never replace the full conditional instruction.
The class strip now includes icons, while specialization and role selectors sit
in the top header. Long-form guidance and the practice desk remain below.

Warrior has original illustrated header art. Other classes use the neutral
citadel backdrop. Spell artwork is read from the client through a guarded optional
API where a reference cue resolves; class icons are the fallback. The icon does
not mean a spell is trained, a talent is selected, or an action is recommended now.
English-name lookup may fall back on clients using another language.

`ui_class_native.png`, `ui_rotation_native.png` and `ui_topic_native.png` in CI
show captured widget layout with original project art. Fonts and game icons are
approximations. Live client appearance, texture loading and interactions still
require testing before release approval.

## Visual rebuild (3.15.0-beta, develop)

The dashboard now uses an original illustrated citadel banner and a matching
ivory-and-gold heraldic crest, with darker charcoal cards, serif headings and six
icon-first shortcuts. These textures ship inside the addon; they are not just
preview decorations. Game ability and class icons still use client-native assets.

The Leveling page has a five-context rotation sidebar, numbered priority tiles,
a visible selected-priority explanation, and a quick-tips card. Context buttons
update the existing advisory guide and reset priority focus. Selecting an ability
updates its explanation without casting or changing any game state. The practice
desk and long-form references remain below, accessible by scrolling.

The CI artifact includes `ui_dashboard_native.png`, `ui_class_native.png` and
`ui_rotation_native.png`. These use captured widget geometry and the bundled art;
fonts and game icons are approximations. They are not actual game screenshots.
See [ARTWORK_PROVENANCE.md](ARTWORK_PROVENANCE.md) for asset origins and prompts.
Live-client appearance, texture support and compatibility remain unverified.

## Quest priorities (3.14.0-beta, develop)

The Quest Journal now has a **Pin Focus / Unpin Focus** button. Select a quest row, then pin it to keep that quest as a personal priority. Pinned quests receive a gold-accented **[PIN]** badge, survive quest-log rescans and UI reloads through per-character SavedVariables, and can be brought to the top with the **Sort: pinned** mode. The journal briefing shows how many *currently scanned* quests are pinned. Dashboard recommendations prioritize quests ready for turn-in first, then an unfinished pinned quest; clicking a recommendation focuses the relevant quest in the addon before opening the journal.

Slash commands: `/fcq pin selected`, `/fcq pin 2` (live quest-log index, **not** the sorted row position), `/fcq pins`, `/fcq clearpins`, and `/fcq sort`. The addon limits saved pins to 100 and provides an explicit cleanup command for pins belonging to quests no longer present in the current log. Pinned priorities are **not** in-game quest tracking, map markers, automatic routing, or evidence of completion. If the quest API fails, cached quest information is clearly marked as outdated.

## Manual shopping priorities (3.14.0-beta, develop)

Use `/fcm shopping` to see the five largest outstanding quantities across your manually tracked profession material lists. The Professions handbook displays the same ranked needs, and the dashboard suggests the single largest shortage by material and profession. Results are sorted by remaining quantity and then alphabetically for reproducibility. Each profession list remains separate; the addon does not scan bags, inspect the auction house, purchase items, or assume two recipes share the same stock. Update quantities with the existing `/fcm owned` and `/fcm needed` commands.

## Premium dashboard (develop beta)

The Overview is now a native WoW UI with a gold-accented sidebar, welcome banner, character summary, four quick actions, read-only progress bars, recommended next steps, and a manually checked **Today's Focus** list. The checklist is saved per character; it never executes gameplay actions. The compact toggle hides the lower dashboard panels, and the window scales down when the game UI is smaller.

- Character name, class, level, and role preference come from game APIs and saved settings.
- Quest count, ready count, and selected quest come from the quest log **only if that API is available and a successful scan has occurred**.
- Experience progress uses optional XP APIs and shows N/A when unavailable.
- Profession names/skill levels use the profession API when available. Crafting-goal progress comes from **manual** /fcm entries, not inventory scans.
- Diagnostics opens Settings, where API-presence information is displayed. These checks do not establish compatibility or compliance.

The GitHub Actions `offline-ui-snapshot` artifact includes a source-validated PNG illustration of the mocked interface. It is **not an in-game screenshot**, and the example character, quests, and materials are test fixtures. The real target-client Interface number and API behavior remain unverified.

## What's new in 3.12.0-beta (develop, November 2, 2026)

The Dungeons and PvP pages now have **real native black-and-gold preparation panels** instead of relying on plain paragraphs and generic checklist buttons. Each page displays the character's class, selected role, class/role planning notes, a next-step suggestion, and four clickable preparation tiles. Their progress bar counts only tasks you personally mark complete; it is **not** an automated measurement of combat or group readiness. The two pages maintain independent per-character checklist states.

A new reusable **FC heraldic monogram** is drawn entirely with native UI primitives in the header and dashboard. It is original geometric artwork, not the final illustrated crest from the reference concepts. The CI pipeline also renders mock-derived Dungeon and PvP previews and checks that their task tiles are actual buttons.

The new page shortcuts navigate to Leveling and Quests without altering game state. All class advice remains general reference material until checked against the actual Forever client. The addon is not yet verified for CurseForge submission.

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

## Dashboard data and navigation

The black-and-gold Overview displays read-only quest snapshots, detected profession skills, and manually entered material goals. Quest data is labeled current, cached/outdated, or unavailable. Unknown quest zones remain visible under the current-zone filter and are marked **Unspecified zone**. Recommendations only navigate addon pages, never automate gameplay; full recommendation text appears on hover where supported.

Use `/fc open Quests` (or `/fc quests`) to navigate and `/fc status` for a concise snapshot/material-goal report. No game quests, spells, or inventory are changed.

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

## Settings dashboard (3.13 beta)

The Settings page now has native black-and-gold preference and client-API cards. Use **Auto-Detect Class** to clear the addon-only class preview, **Center Window** to reset its saved position, or **Toggle Compact** to change the addon layout. The actual class, talents and gameplay are not changed. The cards display the client version when exposed by `GetBuildInfo` and distinguish API visibility from confirmed functionality; an exposed quest, profession, spellbook or XP API does **not** establish compatibility. A mocked Settings preview is generated as `ui_settings_preview.png` in the offline CI artifact. Real client testing and Interface version verification remain mandatory before CurseForge publication.

