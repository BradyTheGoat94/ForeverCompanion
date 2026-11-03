# Forever API research and compatibility checkpoints (2026-11-03)

## Client-specific findings

The Forever client is based on the modern Retail UI API, not the old Classic addon API, even though the interface value is 16001. The observed beta client reported WOW_PROJECT_MAINLINE and modern C_* namespaces. Old GetSpellInfo, GetItemInfo, UnitAura and CombatLogGetCurrentEventInfo calls were absent in published beta captures. Traditional GetSpecialization-style globals are also reported absent; spec and Legacy information must not depend on them. These are **build-specific findings** and require rechecking at launch.

- https://github.com/Thunderz96/forever-addon-kit (captured build 1.60.1.69893, notes on 70009)
- https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/docs/forever-api.md (local, in-game, dump and addon evidence tiers; last stated self-test build 70338)
- https://github.com/Atraeau/WoW-Addons (generated API docs from the Forever client)
- https://github.com/Gethe/wow-ui-source/tree/forever (client UI source branch)

## Audit actions

- The addon API scanner checks for missing GetSpecialization and GetSpecializationInfo globals, in addition to legacy item/spell/talent calls. GetNumSpecializations is present in a captured Forever API dump and must not be classified as missing.
- Core.lua and Icons.lua were directly inspected for the cited build-check trap and specialization globals; no GetBuildInfo threshold or GetSpecialization calls were found in those two modules. This is not a repository-wide proof.
- TOC interface 16001 agrees with published beta-client evidence. Reconfirm after release.

## Content cross-check sources and limitations

- https://www.icy-veins.com/wow-forever/class-guides — nine classes, 27 specialization guides.
- https://db.icy-veins.com/wow-forever/ — datamined items, spells, NPCs and quests; early access, incomplete categories.
- https://nossuary.com/guides/ — explicit level-30 beta evidence boundary; post-30 guidance was not player-tested in beta.
- https://gearinsight.app/wow/en/forever — useful example of removing Classic raid gear without a confirmed Forever source.
- https://www.curseforge.com/wow/addons/foreverguide — existing Forever CurseForge listing, with clearly labeled post-30 theorycraft.

## Verification required before calling a feature accurate

For each spell and icon: compare the spell ID, client build and actual texture returned by the client. For each stat priority: compare source date, role, patch and caveats. For each dungeon drop: check an explicit Forever source and do not invent rates. For each UI panel: inspect a real screenshot with the target game running. For every claim beyond the beta's level-30 testing boundary: label it speculative until live evidence exists.

## Release status

Research corroborates the API approach and provisional TOC value, **not** full functionality. A passing GitHub Actions build, real-client visual review and source-by-source content validation remain separate gates.

## Cross-source correction (2026-11-03)

ForeverPlusPlus reports GetNumSpecializations still present in the API dump, even though GetSpecialization and GetSpecializationInfo globals are absent. The scanner was corrected to avoid flagging GetNumSpecializations. The published API docs also show C_SpecializationInfo.GetSpecialization as a modern replacement. Evidence: https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/docs/forever-api.md and https://warcraft.wiki.gg/wiki/API:C_SpecializationInfo.GetSpecialization
