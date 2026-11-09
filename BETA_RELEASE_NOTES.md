# Forever Companion 3.45.0-beta release notes (draft)

## Map tools update

Open `/fc notes` for personal map notes and nearby services. `/fc note <name>` saves your current position; `/fc nearest repair` offers current-zone repairs. Other service types include mail, inn, flight, vendor, bank, auction and trainer. `/fc overlay exploring`, `questing` and `town` apply coordinated presets. Location evidence is clearer, and the arrow has a nearby-arrival cue plus a manual Another objective action. In-game acceptance remains pending.

## Transparent map overlay

Use `/fc overlay` to toggle; `/fc overlay options` adjusts opacity, size and markers. Drag with `/fc overlay edit`, then `/fc overlay lock`. This uses translucent native zone art and needs in-game beta verification.

## What the beta includes

- Read-only leveling, class, specialization, dungeon and profession guide surfaces.
- Illustrated ability priorities and class study checklists. These are **not** verified optimal Forever rotations.
- Spellbook-aware skill availability with explicit uncertain states when client APIs are incomplete.
- Manual recipe targets, ingredient requirements, progress, material forecasts, prioritized craft queues, and gathering shortages.
- Character profession skill/cap guidance where the client API supplies values.
- Nine class-specific leveling curricula, level-aware official Forever zone/talent milestones, and selected source-attributed Blizzard class-change previews (not verified live spellbook unlocks).
- Blizzard-published Camping feature reference for 11 professions, including skill requirements and buff conflicts; manual profession readiness remains clearly distinguished from actual item ownership.
- Role-aware dungeon preparation and class PvP checklists; these are practice guidance, not verified optimized builds.
- Dark-fantasy black-and-gold interface with original gilded inlays on quest and profession cards, class focus tooltips, and compact-mode support.

## Known limitations

- The curated spell reference covers only a subset of Warrior abilities. Officially published class changes are a **small preview**, not complete spell or talent tables, and require live client validation.
- Recipes, trainers, skill-up probabilities and unlocks are not claimed to be a complete Forever database.
- Inventory counts and crafting goals are entered manually; the addon does not scan bags for the planner.
- Guides do not cast spells, automate gameplay, buy items or craft for the player.
- The interface version, addon ZIP and visuals require verification in the live client before public release.

## Reporting problems

Include the addon version, Forever client build, class, profession, the tab you opened, reproduction steps and the first Lua error (if any). Never include account credentials.

## Release status

**Candidate under development — not approved for public upload.** See `BETA_RELEASE_GATE.md` for the required acceptance checklist.

## 3.41 update

Spell search, pet-only analysis, route filters, direct objective navigation, movable arrow controls, service filters and refresh resilience. See CHANGELOG.md and docs/SPRINT_3_41.md. This candidate has not been uploaded to CurseForge or verified in the game client.

## 3.42 update

New observed leveling session tracker with pause/resume and bounded saved summaries; temporary itinerary deferrals; persistent discovery preferences; explicit selection menus; stale pickup and catalog navigation checks. See docs/SPRINT_3_42.md.

## 3.43 map update

Compact map dock, searchable Service Atlas, configurable service pins and local merchant-visit records. Current provider references remain distinct from approximate visited positions. See docs/SPRINT_3_43.md for source, setup and acceptance details.
