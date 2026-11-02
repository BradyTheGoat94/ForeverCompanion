# Forever Companion beta acceptance checklist

This form is completed only after running the exact GitHub Actions ZIP in the real WoW Forever client. Offline CI and preview PNGs cannot satisfy it.

## Build identification

- Commit SHA:
- GitHub Actions run URL:
- ZIP SHA256 (compare with beta-build-manifest.json):
- Addon version:
- WoW Forever client build and interface number:
- Test date:

## In-game acceptance

Mark each item PASS / FAIL / NOT TESTED, and record the first Lua error.

| Test | Result | Notes |
| --- | --- | --- |
| Clean install folder contains ForeverCompanion.toc directly | NOT TESTED | |
| Addon loads with no Lua error | NOT TESTED | |
| Class guide art and black/gold borders match reference | NOT TESTED | |
| Long class names, roles, phase labels and priority text remain inside cards | NOT TESTED | |
| XP unavailable state is visibly distinguished from 0% XP | NOT TESTED | |
| Navigation gold trim and icons remain readable when selected and hovered | NOT TESTED | |
| Rotation tile hover color resets after leaving or changing tabs | NOT TESTED | |
| Navigation, selected tabs, scrolling and window resizing | NOT TESTED | |
| Leveling guidance for all nine classes | NOT TESTED | |
| Spellbook and missing-API behavior | NOT TESTED | |
| Quest guidance and non-automated quest tracking | NOT TESTED | |
| Dungeon role preparation and PvP notes | NOT TESTED | |
| Profession scanner and sourced Camping preview | NOT TESTED | |
| Manual recipe, material, price and purchase budget workflows | NOT TESTED | |
| Save and reload settings, plans and prices | NOT TESTED | |
| No protected gameplay automation | NOT TESTED | |

## Decision

- Release approved: **NO — pending real-client testing**
- Blocking bugs:
- Screenshots from the real client:
- Tester sign-off:

Never mark an item PASS solely because a mocked UI screenshot or CI job succeeded.
