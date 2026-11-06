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

- [ ] Focus an active quest with a known location and click **Show on map**. Check the map pin and native arrow. **Clear pin** should remove the addon’s waypoint only. Repeat with a quest lacking coordinates and verify no waypoint is created.
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
