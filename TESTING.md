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
