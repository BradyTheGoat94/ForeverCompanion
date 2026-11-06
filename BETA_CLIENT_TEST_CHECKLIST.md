# Forever Companion — Hands-on beta acceptance sheet

**Branch:** develop only. Complete this checklist in the actual WoW Forever client before public submission.

## 1. Get the exact candidate build
1. Obtain the versioned addon ZIP and its `release-audit.json` from the same candidate kit or successful **CurseForge beta package audit** run on `develop`.
2. Verify the ZIP SHA-256 against the audit report. Record the candidate commit below.
3. Keep the ZIP you test so the later upload uses identical bytes.
4. Unzip into the active WoW Forever installation's `Interface/AddOns` directory. The final layout must contain `Interface/AddOns/ForeverCompanion/ForeverCompanion.toc` (not two nested ForeverCompanion folders).
5. On the character selection screen, open AddOns and enable Forever Companion. Do not rely on "Load out of date AddOns" as proof of interface compatibility.

## 2. Five-minute startup gate
- [ ] Enable Lua errors with `/console scriptErrors 1`. The addon appears in the AddOns list and loads without a Lua error.
- [ ] Run `/fcdiag` and record the client build and interface match.
- [ ] The title and sidebar are readable at normal UI scale.
- [ ] The compact and normal sizes preserve readable headings and buttons.
- [ ] Every tab opens without errors: Leveling, Class, Quests, Dungeons, PvP, Professions, Settings.
- [ ] Scrolling reaches the last line of each long guide.
- [ ] Black/gold ornaments, active navigation, and rotation tiles display without overlap.
- [ ] `/reload` does not lose the selected settings or break the window.

## 3. Guide safety and data gate
- [ ] Select at least two specialization paths on a character; the five-step playbook and its priority explanation change together.
- [ ] Open Class Guides → Talents. Compare three tree tabs, icons, tooltips and rank limits with the live class talent window. Scroll to the source footer in normal and compact modes.
- [ ] Preview a Recommended Build and switch trees. Copy it into an empty draft and confirm an existing draft is preserved.
- [ ] In Gear & Loot, search for Barbaric Crossbow, hover for the item tooltip, then open the selected boss research and confirm Oggleflint in Ragefire Chasm.
- [ ] Load the suggested opening into an empty draft. Add and refund a rank, try refunding a prerequisite, change the plan level and check that a draft survives `/reload`. Confirm the live character's talents never change.
- [ ] Verify recommended talents and spells against the character's real spellbook. Missing or inaccessible data is labeled **unconfirmed**, not **unlearned**.
- [ ] Check a low-level character: high-level abilities must not be described as immediately available.
- [ ] Check November tuning warnings for affected classes; reported changes are not represented as official confirmations.
- [ ] Verify a profession tab with and without a learned profession.
- [ ] Confirm guide interactions never automatically cast, target, craft, buy, or accept quests.

- [ ] Accept a quest with **Auto focus: On**. Confirm the journal focuses it and the world map shows a cyan focus marker and the client objective area when available. Switch maps and zoom. Verify turn-ins and objectives remain distinct and the existing user waypoint is untouched.
- [ ] Select another quest manually and accept one more. The chosen focus should stay until re-enabling Auto Focus or removing the selected quest. Hover a map marker for quest details.
- [ ] Focus an active quest with a known location and click **Show on map**. Check the map pin and native arrow. **Clear pin** should remove the addon’s waypoint only. Repeat with a quest lacking coordinates and verify no waypoint is created.
- [ ] Test an unfinished kill or collection quest without a Blizzard boundary. With Forever QuestieDB enabled, compare the destination rings and marker tooltips to known spawn locations. Complete one objective and verify its markers disappear. Shift-click a remaining marker to choose the native arrow destination.
- [ ] With the standalone Forever QuestieDB installed, verify a completed quest with a single fixed turn-in. Compare the marker to the in-game location.

## 4. Visual review and screenshots
Capture screenshots from the **actual client** at normal and compact sizes: home/leveling, class rotation tiles, quests, professions, dungeons, PvP, settings. Compare to the approved visual reference; note clipping, contrast, font scale, icon gaps, and scroll behavior.

## 5. Record and decision
- Tested commit SHA:
- GitHub Actions run ID:
- Forever client version/interface number:
- Game installation path (optional):
- Character class, level, and specialization:
- Lua errors (exact text):
- Visual discrepancies:
- Missing or incorrect spell advice:
- Screenshots saved:
- Result: **PASS / BLOCKED**
- User approval for CurseForge upload: **PENDING**

**Stop-ship:** broken addon loading, unverified interface version, severe unreadable UI, protected-action automation, failed CI, invalid ZIP/hash, or missing user approval. Offline mocks are not live-client evidence.

- [ ] Compare Protection and Retribution Paladin at levels 10–19 and at level cap. Confirm only the tank guide recommends Seal of Fury, and that spell tooltips, role, and unlock cues match the active build.

### Leveling route and map clarity

- [ ] In Westfall with several accepted quests, open **Leveling Route**. Check the suggested quest and objective. Use **Find on map**, then click a highlighted marker.
- [ ] Confirm **Map: Focus** shows up to three cyan destinations for the selected quest, with no numbered Companion markers. Check **All**, **Off**, and **Zoom focus**.
- [ ] Close the map, face away from the destination, then turn toward it. The arrow should turn, the distance should decrease as you approach, and the arrow should hide near the point. Close the arrow and check that a different personal waypoint survives.
- [ ] Test the route browser on both factions and a Skyborne character if available. Check that Open map shows the advertised zone.

### Atlas, town services and bank

- [ ] Open the world map with many active quests. Verify **Map: All** represents every quest that has a location on the displayed map, including shared pins. Switch between **Style: Atlas** and **Style: Original**.
- [ ] With Forever QuestieDB enabled, verify friendly vendor, bank, auction house and flight master pins in a capital. Click a service and confirm the arrow uses its location. Toggle **Towns: Off** and verify quest pins remain.
- [ ] Visit a banker and open the Bank tab. Check items across multiple personal tabs. Change a stack, leave the banker, and reopen **/fc bank** to confirm the saved contents and timestamp.
