# Forever Companion — Hands-on beta acceptance sheet

**Target:** November 4, 2026. **Branch:** develop only. **Do not publish or merge** until this checklist is completed in the actual WoW Forever client.

## 1. Get the exact CI build
1. Open GitHub Actions > latest **successful** "Validate and package addon" run on develop.
2. Download the `ForeverCompanion` artifact containing `ForeverCompanion.zip` and `beta-build-manifest.json`.
3. Verify the manifest SHA256 against the ZIP; use only files from the same run. Record the tested commit below.
4. Unzip into the active WoW Forever installation's `Interface/AddOns` directory. The final layout must contain `Interface/AddOns/ForeverCompanion/ForeverCompanion.toc` (not two nested ForeverCompanion folders).
5. On the character selection screen, open AddOns and enable Forever Companion. Do not rely on "Load out of date AddOns" as proof of interface compatibility.

## 2. Five-minute startup gate
- [ ] The addon appears in the AddOns list and loads without a Lua error.
- [ ] The title and sidebar are readable at normal UI scale.
- [ ] The compact and normal sizes preserve readable headings and buttons.
- [ ] Every tab opens without errors: Leveling, Class, Quests, Dungeons, PvP, Professions, Settings.
- [ ] Scrolling reaches the last line of each long guide.
- [ ] Black/gold ornaments, active navigation, and rotation tiles display without overlap.
- [ ] `/reload` does not lose the selected settings or break the window.

## 3. Guide safety and data gate
- [ ] Select at least two specialization paths on a character; the five-step playbook and its priority explanation change together.
- [ ] Verify recommended talents and spells against the character's real spellbook. Missing or inaccessible data is labeled **unconfirmed**, not **unlearned**.
- [ ] Check a low-level character: high-level abilities must not be described as immediately available.
- [ ] Check November tuning warnings for affected classes; reported changes are not represented as official confirmations.
- [ ] Verify a profession tab with and without a learned profession.
- [ ] Confirm guide interactions never automatically cast, target, craft, buy, or accept quests.

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
