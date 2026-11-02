# Launch-day smoke test

This addon is **not verified on the target client**. Use this checklist on the first available login.

1. Extract the packaged ZIP and ensure the game sees one `ForeverCompanion` directory with `ForeverCompanion.toc`, `Core.lua` and `GuideData.lua`.
2. On the character-select AddOns screen, confirm the addon appears and is enabled. If it is flagged out-of-date, note the actual client Interface number; do not guess.
3. Log in and check for Lua errors. Enable Lua error reporting if supported: `/console scriptErrors 1` followed by a reload.
4. Run `/fc` to show/hide the window. Confirm the window is movable and can be closed.
5. Check that class and level are detected correctly. Test `/fc class Mage` then `/fc class auto`.
6. Test `/fc role Damage` and `/fc professions Mining + Blacksmithing`.
7. Open Dungeons and click Done 1; reload UI, reopen, and verify the checkbox state persists.
8. Check the Leveling, Professions, PvP and Settings tabs for rendering errors.
9. Test at different UI scales and screen resolutions if available.
10. Record the client build, exact error messages and screenshots in a GitHub issue.

## Release policy
- Never automate combat, movement, targeting, protected actions, or gameplay decisions that the client disallows.
- Don't publish speculative dungeon loot or boss mechanics as verified facts.
- Do not claim CurseForge approval until the listing is accepted.
- Do not tag a stable release until the smoke test passes.

## v0.7 quest and UI regression checklist
11. Accept a quest, confirm it appears automatically in Quests without using `/fcq add`.
12. Advance an objective, confirm its text updates after `QUEST_LOG_UPDATE`.
13. Verify ready-to-turn-in state when all objectives are complete.
14. Click a quest row, verify the focused quest title and objective details match.
15. Test Previous/Next Quest and list pagination with more than 15 active quests.
16. Abandon or turn in a quest; verify the live list updates and selection remains valid.
17. Test with an empty quest log and with no recognized quest-log API.
18. Verify all seven tabs fit at 720px width and no buttons overlap at 470px and 560px height.
19. Drag the window, reload, confirm position persists; use `/fc position reset`.
20. Check compact mode, character switching, different UI scales, and the initial welcome page.
21. Confirm manual quest notes are not erased when automatic quest-log state changes.
22. Confirm the addon does not accept, turn in, abandon, track, or route quests on its own.

### Acceptance gates
- No Lua errors during login, quest changes, tab switching or logout.
- No overlapping UI controls at supported scales.
- Quest counts and objective states match the native quest log.
- Accurate quest detection for the actual Forever client API; if unsupported, ship with an explicit compatibility notice instead of claiming it works.
- Save screenshots for CurseForge listing and issue reports.

## v0.8 additional verification
23. Cycle quest filters All / Ready / Zone; verify counts and empty states.
24. Check that current-zone filtering matches the native quest-log header data; do not claim accurate zones when the API omits them.
25. Change classes using the preview button, then select Auto Class; confirm actual class returns.
26. Choose Tank, Damage and Healer where supported; verify role-specific guide notes.
27. Verify focus text does not overlap Previous/Next buttons at compact and expanded heights.
28. Verify no quest data is modified by filter changes or tab switches.

## v1.0 handbook regression gates
29. Open Leveling for each of the nine classes; confirm specialization overview and icon load without Lua errors.
30. Open Professions and switch through all nine professions; verify title, icon, pairing and five-stage progression text.
31. Confirm the AdvancedGuides.lua file loads before Core.lua in the manifest.
32. Test a class preview and Auto Class restore while on the Leveling tab.
33. Confirm generic guidance is not presented as verified Forever-specific talent, skill, recipe or material data.
34. Inspect the long Leveling and Professions pages for scrolling, clipping, and button overlap in compact mode.
35. Confirm the profession handbook and manual profession preference remain separate.

## v1.2 rotation visual checks
36. Cycle all five rotation contexts for each of nine classes.
37. Confirm the class-themed icon renders, and that text remains readable if a texture is missing.
38. Confirm no overlap between the rotation selector, class icon, and compact-mode footer.
39. Compare priority text with available in-game abilities; report unavailable spells or unsupported mechanics.
40. Verify that switching tabs hides the rotation icon and selector.

## v1.3.1 rotation interactions
41. Click each visible priority tile; verify the selected priority line updates.
42. Change rotation mode after selecting a later priority; verify selection resets to the first item.
43. Change class preview with a selected priority; verify no out-of-range errors.
44. Switch away from Leveling and return; verify rotation tiles hide and reappear appropriately.
45. Check text truncation on long priority descriptions and at compact window height.

## v1.4.1 Forever API compatibility checks
46. Verify the installed Forever client interface number with /dump select(4, GetBuildInfo()).
47. Check that the modern C_QuestLog API returns active quests and objectives.
48. Confirm that quest completion state updates after objectives are completed.
49. If zone metadata is absent, the zone filter must not misleadingly hide all quests.
50. If the quest API is unavailable, show an explicit compatibility warning instead of silently displaying zero quests.
51. Verify the addon does not inspect secret combat values or automate gameplay.
52. Enable /console scriptErrors 1 and test UI loading, class preview, profession selection, and quest updates.
