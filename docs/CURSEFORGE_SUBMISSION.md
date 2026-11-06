# CurseForge Beta submission — operator handoff

**Project:** Brady's Forever Companion
**Version:** 3.21.0-beta
**Release channel:** Beta
**Repository branch:** develop only
**Verification:** Use successful push runs for the exact candidate commit on `develop`. The prior baseline passed [Actions #1918](https://github.com/BradyTheGoat94/ForeverCompanion/actions/runs/41768040824) at `2433b6d`.

## Project summary (paste into CurseForge)

An in-game reference companion for World of Warcraft Forever, featuring class and specialization learning guides, ability priorities, gear and stat planning, dungeon and loot browsing, professions, leveling, Legacy, and alt progression tools. Forever Companion provides educational guidance only: it does not cast spells, select targets, run combat macros, or automate gameplay. This is a pre-release beta; final-client compatibility and Forever-specific recommendations are still being verified.

## Long description (paste into CurseForge)

**Brady's Forever Companion** brings class learning, gearing and adventure preparation into a unified dark-and-gold in-game interface.

- **Class guides:** beginner-friendly priorities, rotation explanations, cooldown reminders, and spell artwork with safe fallback when an icon cannot be resolved.
- **Gear and stats:** specialization-specific reference priorities, practical comparisons, and clear caveats where live Forever benchmarks are unavailable.
- **Dungeons and loot:** encounter browsing, planning and manual loot tracking; historical references are not claims of confirmed Forever drops or drop rates.
- **Progression:** leveling, Legacy and alternate-character planning, plus profession and crafting references.
- **Safety:** informational tools only; no automated spellcasting, targeting, or combat execution.

**Beta notice:** The addon has passed automated Lua, mock-client, content and package checks. It has not yet been certified in the final Forever client. Some guidance is sourced from historical or general WoW references and is explicitly labeled where Forever-specific confirmation is pending. No DPS guarantee, verified BiS claim, or drop-rate guarantee is made.

**Independent project:** Not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft names and Blizzard-owned game artwork belong to their respective owners. Do not imply that use of client-provided artwork is an independent grant of redistribution rights.

## Upload selection

1. Open the successful **CurseForge beta package audit** push run for the exact candidate commit and download **bradys-forever-companion-beta-review**.
2. Extract the GitHub artifact wrapper. The versioned addon ZIP inside is the upload file; keep `release-audit.json` beside it for review.
3. Compare the ZIP's SHA-256 to the report and verify that it contains `ForeverCompanion/ForeverCompanion.toc`. For manual installation, extract the addon folder into the Forever client's `Interface/AddOns/` directory. Launch the game, enable the addon and run `/fc` and `/fcdiag`.
4. In CurseForge, choose the **actual supported Forever game/version** shown by the publisher UI. Do not guess a game version from `## Interface: 16001`.
5. Select **Beta**, not Release; version label **3.21.0-beta**.
6. Upload an original logo and truthful screenshots. Label offline UI mockups as previews, not game captures.
7. Choose a license **only after the owner explicitly decides** whether others may modify or redistribute the original code. Review ownership of bundled assets first.
8. After explicit owner approval, submit for moderation and record the resulting project and file IDs when confirmed.

## Changelog (paste into CurseForge)

**3.21.0-beta**
- Added a read-only Recommended Build view for all 27 specs, plus Bear tank. Preview or copy an Icy Veins level-60 PvE build into an empty addon draft. Allocations are checked against Forever build 1.60.1.70790.
- Added an interactive talent planner with 467 talents across all 27 trees, loadable leveling openings, build milestones, client icons and spell tooltips, and saved drafts. Base talent rules are from Forever build 1.60.1.70790. Talent grid adapted from [Zephras](https://zephras.com/data/) under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Names and icon references belong to Blizzard.
- Tagged primary abilities for all 27 standard specs and all nine class practice guides. The rotation panel checks your spellbook, promotes learned actions, and flags unconfirmed or missing primary spells. Icons and tooltips use the chosen ability’s client data.
- Put numbered press priorities in the rotation window for all nine classes, with published dungeon and boss priorities for 27 standard specs. Extra notes are collapsed by default.
- Added native spell and item hover tooltips, a 27-item Forever loot catalog across three dungeons, and a quest footer that keeps Previous and Next outside the scroll viewport.
- Improved dashboard banner contrast and brought selected rotation explanations closer to the initial viewport. Class topic changes return to the heading.
- Put beginner actions and published PvE priorities for all 27 specializations in Class Guides → Overview. Updated Combat Rogue and Beast Mastery Hunter with patch 1.60.1 references.
- Added Blizzard-published Legacy and alt planning details and the nine new five-player dungeons with their suggested level bands. Long loot descriptions leave the catalog evidence disclosure visible.
- Added diagnostics, offline UI smoke tests and reproducible package/provenance validation.
- Clarified evidence labels for unverified Forever-specific mechanics and priorities.
- No combat automation. Final-client compatibility testing remains pending.

## Release decision log

| Gate | Status |
| --- | --- |
| Automated build and package integrity | Confirm on exact candidate commit |
| Correct project title/version in TOC | PASS — 3.21.0-beta |
| License choice and third-party asset review | BLOCKED — owner decision/review |
| Original logo and truthful showcase images | NEEDS REVIEW |
| Correct CurseForge game/version selection | NEEDS PUBLISHER UI |
| Live-client installation, icons, SavedVariables and protected actions | UNVERIFIED |
| CurseForge project/file approval | NOT SUBMITTED |

**Do not claim publication, approval, perfect visual fidelity, or verified Forever-specific DPS optimization until independently confirmed.**

## Candidate records

Use the successful **Validate and package addon** push run on the same commit to review the `offline-ui-snapshot` artifact. Its fonts and game icons are approximations. Label these images as offline previews if approved for the gallery. The historical #1916 and #1918 archives predate this update.
