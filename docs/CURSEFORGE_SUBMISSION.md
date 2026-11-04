# CurseForge Beta submission — operator handoff

**Project:** Brady's Forever Companion
**Version:** 3.18.0-beta
**Release channel:** Beta
**Repository branch:** develop only
**Current verification:** GitHub Actions run [#1908](https://github.com/BradyTheGoat94/ForeverCompanion/actions/runs/41752074999) completed successfully. This is an automated package check, not a live-client certification or CurseForge approval.

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

1. In the successful GitHub Actions run, download the **ForeverCompanion** artifact.
2. Unzip the GitHub artifact wrapper and identify the **inner installable addon ZIP**. Do not upload the outer Actions artifact to CurseForge.
3. Verify the inner archive contains `ForeverCompanion/ForeverCompanion.toc` and the expected Lua files, with no extra root directory.
4. In CurseForge, choose the **actual supported Forever game/version** shown by the publisher UI. Do not guess a game version from `## Interface: 16001`.
5. Select **Beta**, not Release; version label **3.18.0-beta**.
6. Upload an original logo and truthful screenshots. Label offline UI mockups as previews, not game captures.
7. Choose a license **only after the owner explicitly decides** whether others may modify or redistribute the original code. Review ownership of bundled assets first.
8. Submit for moderation; record the resulting project and file IDs only when confirmed.

## Changelog (paste into CurseForge)

**3.18.0-beta**
- Refined dark-and-gold dashboard, class navigation and learning views.
- Expanded specialization guidance, ability priorities, cooldown explanations and spell icon fallbacks.
- Added gear/stat reference pages and dungeon, loot, profession, Legacy and alt planning tools.
- Added diagnostics, offline UI smoke tests and reproducible package/provenance validation.
- Clarified evidence labels for unverified Forever-specific mechanics and priorities.
- No combat automation. Final-client compatibility testing remains pending.

## Release decision log

| Gate | Status |
| --- | --- |
| Automated build and package integrity | PASS — Actions #1908 |
| Correct project title/version in TOC | PASS — 3.18.0-beta |
| License choice and third-party asset review | BLOCKED — owner decision/review |
| Original logo and truthful showcase images | NEEDS REVIEW |
| Correct CurseForge game/version selection | NEEDS PUBLISHER UI |
| Live-client installation, icons, SavedVariables and protected actions | UNVERIFIED |
| CurseForge project/file approval | NOT SUBMITTED |

**Do not claim publication, approval, perfect visual fidelity, or verified Forever-specific DPS optimization until independently confirmed.**
