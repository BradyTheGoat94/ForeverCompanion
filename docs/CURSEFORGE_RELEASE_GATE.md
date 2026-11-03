# CurseForge beta release gate — Brady's Forever Companion

## Automated package
On every push to `develop`, the `CurseForge beta package audit` workflow validates the manifest and creates a **review artifact only**. It does not upload or publish to CurseForge.

Download the `bradys-forever-companion-beta-review` GitHub Actions artifact. The contained ZIP has exactly one top-level addon folder: `ForeverCompanion/`. Its manifest is `ForeverCompanion/ForeverCompanion.toc`. The **public title** is Brady's Forever Companion; the technical folder, addon name and saved-variable keys remain unchanged to protect existing installations.

To build locally, run `python3 tools/build_curseforge_beta.py --output dist`. To validate only, use `--check-only`. Inspect `dist/release-audit.json` for SHA-256 and file count. The build rejects missing TOC dependencies, duplicate paths, symlinks, unexpected extensions, oversized assets and mismatched branding. ZIP timestamps are normalized for reproducibility.

## Human checks required before upload
- Confirm the actual WoW Forever client interface number with `/dump select(4, GetBuildInfo())`; Public client captures independently report **16001** for Forever 1.60.1, including a 2026-10-30 live-client build; verify the installed release build and addon behavior in-game before claiming compatibility.
- Install the ZIP in the target client's AddOns folder and confirm that the addon loads without Lua errors, including fresh installs and upgrades preserving `ForeverCompanionDB`.
- Test dashboard, all nine class selectors, spec switching, navigation, quest API fallbacks, rotations, loot search, note persistence, combat lockdown behavior and performance in the real client.
- Validate that spell/class icons resolve in the target client and that the native UI matches expectations; offline preview renders are **not** in-game screenshots.
- Clearly distinguish general WoW advice, source-reviewed theorycraft, and actually Forever-tested information. No invented encounter mechanics, drop rates, verified BiS or automation claims.
- Verify authorship and redistribution permissions for every included image, texture and third-party contribution. Never copy third-party addon code or graphics without appropriate permission/license and attribution.
- Prepare a unique original 400x400+ PNG project logo, actual in-game screenshots once available, description, installation instructions and a changelog.
- Confirm the chosen CurseForge game version and project-name acceptance with moderators. A distinct display title does not guarantee approval.
- Choose a **Beta** file classification for the initial preview. CurseForge requires a Release file for default app distribution; do not silently classify an untested build as stable.

## Suggested CurseForge summary
Class guides, rotation priorities, gear references, dungeon preparation, loot notes, and progression planning for WoW Forever.

## Honest release description
Brady's Forever Companion is an independent, free, in-game guide and planning addon. It offers beginner-friendly class guidance, manually managed gear and loot goals, dungeon research, profession planning, Legacy and alt checklists, and quest information where supported by the client. Many recommendations are source-reviewed references rather than verified WoW Forever benchmarks. The addon does not play the game or execute combat actions. Some features and client compatibility remain under beta testing.

Not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft and related trademarks belong to their respective owners.

## References
- https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project
- https://support.curseforge.com/support/solutions/articles/9000209856-multi-toc-for-world-of-warcraft-addons
- https://support.curseforge.com/support/solutions/articles/9000199552

## Independent Forever API references (read-only research)
- https://github.com/Thunderz96/forever-addon-kit — captured 1.60.1 API surface, dated September 2026
- https://github.com/Atraeau/WoW-Addons — generated client API docs and `_Camelot` TOC convention
- https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/docs/forever-api.md — client probes through October 30, including the live `_forever_` folder

These sources establish API names and version evidence, **not** that our addon runs correctly. The project does not vendor third-party code. Run `python3 tools/audit_forever_apis.py` to flag known-removed global calls. `/fcdiag` provides non-invasive checks inside the client. Recheck each new Forever patch.
