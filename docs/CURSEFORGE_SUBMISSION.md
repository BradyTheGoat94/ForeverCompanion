# CurseForge Beta submission — operator handoff

**Project:** Brady's Forever Companion
**Version:** 3.40.0-beta
**Release channel:** Beta
**Repository branch:** develop for work; main for promoted candidates
**CurseForge project:** 1793299
**Moderation status:** Pending review (owner-reported submission; approval not independently confirmed)
**Verification:** Run `python tools/validate_all.py` on the exact candidate. Offline checks do not certify the target client. Manual CurseForge uploads remain enabled; no automatic publishing is configured.

## Project summary (paste into CurseForge)

Free class builds, rotation guides, dungeon loot, and progression planning for World of Warcraft: Forever.

## Long description (paste into CurseForge)

**Brady's Forever Companion** brings class learning, gearing and adventure preparation into a unified dark-and-gold in-game interface.

- **Class guides:** beginner-friendly priorities, rotation explanations, cooldown reminders, and spell artwork with safe fallback when an icon cannot be resolved.
- **Gear and stats:** specialization-specific reference priorities, practical comparisons, and clear caveats where live Forever benchmarks are unavailable.
- **Dungeons and loot:** 127 source-attributed equipment entries across nine dungeons, with boss search, item tooltips, a wishlist, and manual acquisition marks. Coverage is partial and drop rates remain unverified.
- **Progression:** live quest priorities, leveling routes, map highlights, a player-started arrow, Legacy and alternate-character planning, plus profession and crafting references.
- **Safety:** informational tools only; no automated spellcasting, targeting, or combat execution.

**Beta notice:** The addon has passed automated Lua, mock-client, content and package checks. It has not yet been certified in the final Forever client. Some guidance is sourced from historical or general WoW references and is explicitly labeled where Forever-specific confirmation is pending. No DPS guarantee, verified BiS claim, or drop-rate guarantee is made.

**Independent project:** Not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft names and Blizzard-owned game artwork belong to their respective owners. Do not imply that use of client-provided artwork is an independent grant of redistribution rights.

## Upload selection

1. In GitHub Actions, run **CurseForge beta package audit** on `develop` and confirm its commit matches the candidate. Download **bradys-forever-companion-beta-review** from the successful run. If the runner is unavailable, build the same review ZIP locally with `python3 tools/build_curseforge_beta.py --output dist` from the candidate checkout and use it for private testing.
2. Extract the GitHub artifact wrapper. The versioned addon ZIP inside is the upload file; keep `release-audit.json` beside it for review.
3. Compare the ZIP's SHA-256 to the report and verify that it contains `ForeverCompanion/ForeverCompanion.toc`. For manual installation, extract the addon folder into the Forever client's `Interface/AddOns/` directory. Launch the game, enable the addon and run `/fc` and `/fcdiag`.
4. In the publisher UI, select **World of Warcraft → Addons → Forever**. Existing Forever projects list **1.60.1**. Confirm that the tested client and the publisher version selector agree before uploading.
5. Select **Beta**, not Release; version label **3.40.0-beta**.
6. Use the original square PNG project crest from the candidate kit. Capture actual screenshots after the live test and label offline UI renders as previews. [CurseForge project submission guide](https://support.curseforge.com/support/solutions/articles/9000199552)
7. Choose a license **only after the owner explicitly decides** whether others may modify or redistribute the original code. Review ownership of bundled assets first.
8. After explicit owner approval, submit for moderation and record the resulting project and file IDs when confirmed.

## Changelog (paste into CurseForge)

**3.40.0-beta**
- Show all active quests with known map locations, add optional town service pins and an atlas style, and view a saved personal-bank snapshot anywhere.
- Added a faction-aware Leveling Route, a simpler quest map with Focus, All and Off modes, and a player-started on-screen navigation arrow.
- Added spec-specific rotation cards across all five practice modes, with a distinct Protection and Retribution Paladin progression.
- Add interactive world-map markers and destination highlights. The optional Forever edition of QuestieDB supplies additional objective locations at runtime, without bundling its database.
- Automatically add active quests to the journal and world map. High-contrast markers distinguish objectives, turn-ins and the focused quest. Highlight the focused objective area when the client provides its boundary.
- Added a player-clicked quest map pin and native direction arrow where supported. Uses available client quest locations first. An independently installed Forever QuestieDB can supply single-location turn-ins. No third-party database is bundled.
- Rebuilt Dungeon Journal around direct dungeon and boss selection, item icons and one-click loot details. Consolidated loot actions and kept longer profession notes behind a toggle.
- Added 100 equipment entries from six Forever dungeon guides, for 127 entries across nine dungeons. The catalog includes item IDs and separates reference data from observed drops.
- Skip window redraws while the addon is closed. Quest tracking keeps its read-only snapshot up to date.
- Save the planning level with each specialization’s talent draft. Spellbook changes refresh open class guides, and localized spell names and other-class previews no longer produce false missing-spell cues.
- Added a read-only Recommended Build view for all 27 specs, plus Bear tank. Preview or copy an Icy Veins level-60 PvE build into an empty addon draft. Allocations are checked against Forever build 1.60.1.70790.
- Added an interactive talent planner with 467 talents across all 27 trees, loadable leveling openings, build milestones, client icons and spell tooltips, and saved drafts. Base talent rules are from Forever build 1.60.1.70790. Talent grid adapted from [Zephras](https://zephras.com/data/) under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Names and icon references belong to Blizzard.
- Tagged primary abilities for all 27 standard specs and all nine class practice guides. The rotation panel checks your spellbook, promotes learned actions, and flags unconfirmed or missing primary spells. Icons and tooltips use the chosen ability’s client data.
- Put numbered press priorities in the rotation window for all nine classes, with published dungeon and boss priorities for 27 standard specs. Extra notes are collapsed by default.
- Added native spell and item hover tooltips, the Forever loot catalog, and a quest footer that keeps Previous and Next outside the scroll viewport.
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
| Correct project title/version in TOC | PASS — 3.40.0-beta |
| License choice and third-party asset review | BLOCKED — owner decision/review |
| Original logo and truthful showcase images | Square crest prepared. Live screenshots pending. |
| Correct CurseForge game/version selection | NEEDS PUBLISHER UI |
| Live-client installation, icons, SavedVariables and protected actions | UNVERIFIED |
| CurseForge project/file approval | Owner-reported submission; approval unverified. 3.40 candidate not uploaded. |

**Do not claim publication, approval, perfect visual fidelity, or verified Forever-specific DPS optimization until independently confirmed.**

## Candidate records

Use a successful **Validate and package addon** run on the same commit to review the `offline-ui-snapshot` artifact. Its fonts and game icons are approximations. Label these images as offline previews if approved for the gallery. The historical #1916 and #1918 archives predate this update.
