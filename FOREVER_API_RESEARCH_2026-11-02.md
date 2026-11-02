# WoW Forever API research — 2026-11-02

Research sources:
- https://warcraft.wiki.gg/wiki/Patch_1.60.1/API_changes/notes
- https://github.com/Thunderz96/forever-addon-kit
- https://github.com/xIGBClutchIx/ForeverPlusPlus/blob/main/docs/forever-api.md
- https://foreverdb.net/spells
- https://questing.wiki/wow-forever/spells/

## Engineering implications

1. Observed Forever beta interface number is 16001, but the addon API belongs to the modern mainline family, not old Classic.
2. Prefer guarded feature detection over assumptions based on interface version.
3. Avoid secret combat values and protected actions; guides must remain advisory.
4. Guard optional event registration and test it against the current client.
5. Test SavedVariables across a cold restart; older beta builds had loading bugs.
6. Do not assume the Retail GetSpecialization function exists; Forever talent systems differ.
7. Distinguish trainer, talent, quest, rank, and learned status. Client data does not establish that a player knows a spell.
8. Recheck frame anchoring and UI restrictions after every beta patch.

## Live-client release gate

- [ ] Clean installation and cold launch without Lua errors.
- [ ] Reload and open guide without errors.
- [ ] Cold restart preserves settings or known limitations are documented.
- [ ] Every class guide and coaching page opens.
- [ ] All six rotation cards render, select and show tooltips.
- [ ] No protected-action or secret-value errors during combat.
- [ ] Representative spellbook checks at low levels and with talents.
- [ ] Confirm current interface number, build and updated spell reference.
- [ ] Verify CurseForge zip and addon folder layout.

## Evidence levels

Client-data referenced: published extraction only.
Spellbook checked: character knows spell according to supported API.
Mechanically verified: current-client observation.
Log-tested: captured in-game result.
Benchmark validated: repeatable comparative evidence.

GitHub CI success does not establish live-client verification.