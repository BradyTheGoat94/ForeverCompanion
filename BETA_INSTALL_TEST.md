# Installing and testing the Forever Companion beta

1. Open the successful **Validate and package addon** GitHub Actions run on the `develop` branch.
2. Download the **ForeverCompanion** artifact, extract the outer GitHub artifact archive if needed, and locate `ForeverCompanion.zip`.
3. Extract `ForeverCompanion.zip` into the appropriate WoW Forever `Interface/AddOns/` directory. The final folder must be `Interface/AddOns/ForeverCompanion/ForeverCompanion.toc`, **not** a double-nested folder.
4. Verify the game client accepts the addon interface version. The repository currently declares `16001`, which requires checking against the live client before public release.
5. Start the game and confirm the addon appears in the addon list. Open the guide and switch every section, including Professions and class skill guides.
6. Run `/fcdiag` and record the client build, interface and which APIs are available. The diagnostics are read-only.
7. Create a manual recipe plan, adjust a material count, inspect the gather list, reload the UI, and confirm saved progress remains.
8. Check that the addon never casts abilities, crafts, purchases, or performs any protected gameplay action.
9. Capture actual in-game screenshots and note any Lua errors, overlapping text, missing buttons or unreadable panels.

## Report format

- Addon version and commit SHA:
- Client version/build/interface from `/fcdiag`:
- Character class and specialization:
- Screen/tab:
- Expected result:
- Actual result:
- Reproduction steps:
- Lua error text (if any):
- Screenshot (optional):

Do not share passwords, authentication tokens or account details.

## If installation fails

Confirm the nested directory path first. Then check that the client recognizes the declared interface number, disable conflicting addons for a clean-room test, and report the first Lua error. Do not treat an offline UI preview as proof of an in-game rendering pass.
