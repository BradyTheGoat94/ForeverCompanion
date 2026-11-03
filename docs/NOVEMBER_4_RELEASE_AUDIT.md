# November 4 CurseForge beta release audit

**Scope:** develop branch. **Status:** conditional; not yet approved for upload.
This audit distinguishes static review from executed tests and real-client verification.

## Reviewed
- Manifest: ForeverCompanion/ForeverCompanion.toc; title Brady's Forever Companion, internal folder ForeverCompanion, interface 16001, version 3.18.0-beta.
- Release builder: tools/build_curseforge_beta.py; one root folder, dependency checks, asset extension restrictions, symlink restrictions, integrity check, deterministic timestamps and SHA-256 report.
- CI: .github/workflows/curseforge-beta.yml; Lua 5.1 parser, offline and Study Board smoke tests, static API scanner, manifest checks, repeated ZIP build, artifact upload.
- Presentation source: VisualTheme.lua, Dashboard.lua, ClassGuide.lua, Heraldry.lua, Icons.lua, Core.lua.
- Reference systems: Spellbook.lua, RotationWorkspace.lua, StudyBoard.lua, GearStats.lua, LootAtlas.lua.
- Diagnostics.lua and tools/audit_forever_apis.py.
- This review inspected source, **not** the rendered addon in the target game. CI success has not been independently confirmed in this audit.

## Release blockers — resolve before uploading
1. Obtain a successful CurseForge beta package audit workflow on the intended develop commit. Review failed steps, especially the legacy API scan and manifest reachability validation.
2. Inspect generated ZIP's one-folder root, TOC, packaged Media assets, checksum, and Lua module load order.
3. Check rendered offline UI snapshots for clipping, overlap, tiny text and missing icons. Offline snapshots are illustrative, not game screenshots.
4. Confirm ownership/license and original project logo; choose CurseForge-supported Forever game version. Avoid presenting unverified Forever gameplay details as fact.
5. Review the submitted description and changelog for transparent beta language.
6. Obtain actual game client test results when available; this can follow a clearly labeled beta submission if moderation permits.

## Known limitations
- No proof yet that all class rotations, BiS items, dungeon mechanics, or Legacy details match final client.
- Public interface 16001 reports relate to beta captures; final-client build can change.
- Mocked Lua tests cannot verify game events, persistence after logout, protected action rules, or frame appearance.
- Do not imply CurseForge approval or claim publication before a confirmed project/file approval.

## Submission metadata draft
Project title: Brady's Forever Companion
Summary: In-game class guides, rotations, gear planning, dungeons, loot and progression tools for WoW Forever.
Release type: Beta
File display name: Brady's Forever Companion 3.18.0 Beta
Changelog:
- Dark-and-gold guide dashboard and class presentation
- Class/spec learning references and spell icon fallbacks
- Dungeon, loot, professions, Legacy and alt planning tools
- Compatibility diagnostics and offline QA
- Pre-release: final-client testing pending

## Submission flow
1. Sign into https://authors.curseforge.com/#/projects/create/choose-game and create the project.
2. Supply an original logo, correct game/category/version, license and accurate description.
3. Upload the **successful audited GitHub Actions ZIP** and select **Beta**.
4. Monitor project and file moderation separately; do not report it as published until both are approved.
5. Update the file after real-client testing, fixing any compatibility issues.

Source: https://support.curseforge.com/support/solutions/articles/9000197242
Source: https://support.curseforge.com/support/solutions/articles/9000197241
