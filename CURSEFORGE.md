# CurseForge publication checklist

Forever Companion is an independent, free, in-game reference addon.

## Before submission
- Confirm that the **World of Warcraft Forever** game flavor exists and select the exact supported game version from the CurseForge project UI; do not guess.
- Verify the actual game client's `Interface` number and supported addon APIs. The current manifest value is **provisional**.
- Confirm the ZIP contains `ForeverCompanion/ForeverCompanion.toc`, `Core.lua`, and `GuideData.lua` with no executable installers.
- Run the launch-day checklist in [TESTING.md](TESTING.md), save screenshots, and record the tested client version.
- Decide on a license with the project owner before opening the source or publishing.
- Use original descriptions, screenshots, and artwork. Only reference game textures through supported APIs.
- Clearly label beta features and remove unverified claims about Forever-exclusive content.
- Create a CurseForge author project; supply a category, summary, description, game version, icon, screenshots, changelog, and ZIP file.
- Submit for moderation. **Approval timing is controlled by CurseForge and cannot be guaranteed by a target date.**

## Proposed listing copy

**Name:** Forever Companion

**Short description:** A class-aware, in-game leveling, dungeon, profession, and PvP reference companion.

**Description:**
Forever Companion offers an easy-to-open guide window with class-aware reference tips, leveling preparation, dungeon checklists, profession notes, and PvP preparation. The beta includes nine class profiles, per-character saved preferences, movable interface, and manual checklist tracking.

The addon does not automate combat, movement, targeting, or questing. Content is being expanded and game-client compatibility is pending live testing.

**Install:** Extract the addon ZIP so that `ForeverCompanion` is directly inside the game's `Interface/AddOns` folder. Use `/fc` to open the guide.

**Support:** Use the GitHub Issues tab in the project's repository when it becomes publicly accessible.

## Release safeguards
- Do not claim official Blizzard endorsement or CurseForge certification.
- Do not claim complete dungeon boss and loot coverage without verified data.
- Do not upload to CurseForge without the owner's approval and account access.
