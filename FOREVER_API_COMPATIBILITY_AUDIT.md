# WoW Forever API and content compatibility audit

Reviewed 2026-11-02. **Status: conditional / not verified in a live client.** This document separates observed client evidence from addon assumptions.

## Client identity and packaging

- Independent client-export and beta developer references identify Forever as product `wowf`, build family `1.60.1`, interface `16001`, with a Mainline-derived UI runtime and a separate `Camelot` game type. Do **not** equate interface 16001 with original Classic API behavior.
- Current `ForeverCompanion.toc` specifies `## Interface: 16001`; consistent with the published beta snapshots, but must be rechecked against the installed client via `/dump select(4, GetBuildInfo())`.
- The observed beta install directory is `_classic_beta_/Interface/AddOns`; confirm against the user's launcher. A `ForeverCompanion_Camelot.toc` may be useful for game-flavour packaging, but don't assume it is required or replace the existing TOC without a real-client check.
- The 2026-10-28 exported Forever interface snapshot lists client `1.60.1.70658`. This is a dated snapshot, **not** proof of the latest live build.

## Runtime and security constraints

- Forever uses the modern, Mainline-family API, including Midnight-era secret values and restricted combat information. **No** protected gameplay actions, automatic casting, combat-driven targeting, or rotation execution should be implemented.
- Do not depend on legacy Classic globals (`GetSpellInfo`, `UnitAura`, `GetTalentInfo`, `CombatLogGetCurrentEventInfo`) merely because the content resembles Classic.
- Do not infer Retail specializations from `GetSpecialization`. Forever's talent/legacy trees use `C_Traits` according to beta measurements; our spec previews are editorial recommendations, not a verified reading of active talent choices.
- Unknown event registration may throw on this client. Core's `pcall(addon:RegisterEvent(...))` approach is appropriate; test whether each registered event actually fires.
- SavedVariables persistence had conflicting October beta reports: one tester reported loss after reload, another reported successful persistence. **Re-test persistence on the current client**, including cold start, reload, and relog. Do not promise saved plans/prices work until proven.
- The addon uses `C_SpellBook` with runtime feature detection and `pcall`; spellbook scan status is only a confidence indicator, not evidence a skill is obtainable or the best rotation.
- ProfessionScanner has modern `GetProfessions` / `GetProfessionInfo` detection and a legacy fallback. Confirm modern functions on the exact build; the fallback is not evidence Forever supports legacy skill-line globals.

## Content accuracy and evidence levels

- Source-backed announced class changes are **published previews**, not evidence of final tuning, unlock levels, or live availability.
- Leveling routes, zone bands, rotations, cooldowns, dungeon strategies, PvP priorities, profession/camping guidance and talent suggestions must remain labeled as *guide/editorial*, *announced*, or *live client checked* according to actual evidence.
- A spellbook match confirms a named entry was returned by the player's current client, **not** damage, talent prerequisites, spell rank, cooldown or optimization.
- Do not claim all nine class guides or 27 spec priority lists are mechanically validated without class-by-class client tests and reliable gameplay evidence.

## Live-client verification matrix

| Area | What to verify | Release status |
| --- | --- | --- |
| Interface / install | `GetBuildInfo`, game folder, TOC loading, addon enablement | NOT TESTED |
| Startup | No Lua errors, all modules load in correct order | NOT TESTED |
| Class guide | Nine classes, correct current level, no text overflow | NOT TESTED |
| Spellbook | `C_SpellBook` scan matches actual visible spells; missing API fallback | NOT TESTED |
| Talents | Never claim active specialization from editorial preview | NOT TESTED |
| Quests and zones | Read-only guidance, correct route and level bands | NOT TESTED |
| Professions | Modern detection and localized/custom skill names | NOT TESTED |
| SavedVariables | Reload, relog, full restart; prices/plans/settings persist | NOT TESTED |
| Combat restrictions | No protected actions or secret-value misuse | NOT TESTED |
| UI appearance | Compare real screenshot to design reference, scaling and hover | NOT TESTED |
| Distribution | Exact Actions ZIP, manifest hash, no double nesting | NOT TESTED |

## Evidence and primary references

- Blizzard-generated Forever UI export mirror: https://github.com/reckhou/WoWBlzCode (Forever tree and API indexes; snapshot 2026-10-28).
- Client-exported API documentation: https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/README.md (build 70170, 2026-10-01).
- Live-beta developer measurements, with explicitly dated limitations: https://github.com/Thunderz96/forever-addon-kit
- UI flavour/API comparison: https://github.com/Osso/wow-ui-sim/blob/master/docs/wowforever-1.60.1-ui-api-deltas.md
- Blizzard UI Discord statement as reported by Wowhead: https://www.wowhead.com/tbc/news/wow-forever-will-have-addon-changes-from-midnight-382921

## Release decision

**Do not approve** based on CI, a static preview, or this audit. Run the exact packaged build in the actual current Forever client and complete `BETA_CLIENT_ACCEPTANCE.md`.

## Optional spell artwork lookup (3.16 beta)

The guide uses guarded `C_Spell.GetSpellTexture` for representative leveling cues.
Only a positive finite numeric file ID is accepted; unresolved names, absent APIs,
restricted results and exceptions fall back to the class icon. This reads artwork,
not training, cooldowns, combat state or talent availability. English reference
names may not resolve in localized clients. There is no network access in the addon.

API contract reviewed from Blizzard-generated documentation mirrored at
https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua
(`GetSpellTexture`, `SpellIdentifier`, optional result). This contract review does
not establish target-client support; actual Forever texture loading remains pending.
