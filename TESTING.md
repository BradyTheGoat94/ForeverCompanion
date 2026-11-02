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

## v1.5.0 modern client compatibility
53. Confirm unknown events do not abort addon loading on Forever.
54. Verify XP current/max and percentage at low level, level-up, and level cap.
55. Confirm missing or restricted XP values produce a readable unavailable message rather than Lua errors.
56. Confirm the in-game footer version matches the TOC version.
57. Recheck quest-log updates after safe event registration.

## v1.6 profession detection
58. Verify learned professions are listed using the live client profession APIs when supported.
59. Confirm profession skill current/max numbers match the in-game profession panel.
60. Verify missing profession APIs display a readable fallback.
61. Verify a character with no learned professions produces no Lua error.
62. Confirm the scanner never crafts items, spends materials, or changes character data.

## v1.7 crafting planner regression checks
63. Add a material for Alchemy with /fcm add Alchemy | Peacebloom | 20 | 7 and confirm remaining 13.
64. Update owned quantity with /fcm owned Alchemy | 1 | 12 and confirm remaining 8.
65. Remove material with /fcm remove Alchemy | 1 and confirm list updates.
66. Reload UI and verify per-character material checklists persist.
67. Confirm profession material lists are separate across professions.
68. Verify invalid counts, missing entries, and oversized material lists are rejected.
69. Confirm the detected profession progress text is absent or safely falls back if API data is missing.
70. Verify no crafting, inventory modification, or purchases occur.

## v1.8 crafting dashboard
71. Verify Overview shows correct profession-list, completed-material, and remaining-unit totals.
72. Verify /fcm summary matches the Overview dashboard.
73. Verify /fcm needed Profession | Index | Count changes the target and remaining units.
74. Verify /fcm clear Profession removes completed goals but preserves unfinished goals.
75. Verify goal summaries persist after /reload and across tab switches.
76. Verify malformed quantities and missing list indices do not crash the addon.

## v1.8.1 UI reliability
77. Scroll the Leveling guide and verify rotation tiles scroll with the content rather than floating over other tabs.
78. Hover a rotation tile and verify its full priority guidance appears in a tooltip.
79. Verify all rotation tiles remain legible at compact and normal window heights.
80. Confirm no modulo-by-zero error occurs when icon metadata is absent or empty.
81. Add the same material twice in one profession; duplicate should be rejected without changing totals.

## v2.0 visual crafting controls
82. Add six materials to one profession; confirm first five appear and the sixth is on page two.
83. Click plus/minus and confirm owned quantity and remaining count update immediately.
84. Minus at zero must remain zero; plus must not exceed 999999.
85. Switch profession and confirm material page resets to first page.
86. Switch away from Professions; verify all material buttons and labels disappear.
87. Reload UI; verify quantities persist and buttons show correct saved values.
88. Verify no overlap between profession selectors, material controls, and handbook text at both window heights.
89. Check text clipping for long material names and small UI scale.
