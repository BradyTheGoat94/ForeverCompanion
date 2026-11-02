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

## Current moderation readiness (November 2026)

**Not approved or submitted.** CurseForge project and file moderation is a separate process from GitHub Actions. The project owner must authorize submission and complete account-side actions. Do not claim CurseForge certification before approval.

### Required before public submission
1. Run the GitHub Lua syntax, manifest, release audit and ZIP jobs; inspect the packaged folder structure.
2. Test on the actual Forever release client, not just the beta. Record build number, login, /reload, opening /fc, all seven tabs, quest and profession scanning, class/spec preview, spellbook inspection, and SavedVariables persistence. Record errors and screenshots.
3. Select a license with the owner and confirm any third-party art/code is compatible. Avoid implying Blizzard endorsement.
4. Confirm that CurseForge offers an appropriate WoW Forever game version/flavor. Use only supported versions actually tested.
5. Prepare an original 400x400 project icon (PNG preferred), real in-game screenshots, one-sentence summary, accurate detailed description, changelog, and a valid ZIP.
6. Submit from the owner's CurseForge author account; the uploaded file remains under review until moderation acts. Keep beta files marked beta until validated.
7. If moderation requests changes, address the feedback on the existing project rather than resubmitting duplicate projects.

### Moderation considerations
- No executable installers, external download links, paid features, automated combat, or deceptive compatibility claims.
- No AI-generated showcase that falsely depicts the actual addon UI; disclose generated or edited promotional images where required.
- Project name must be distinct; avoid game/version labels in the name.
- Changelogs should describe substantial changes; never upload cosmetic version bumps solely to boost visibility.
- A public support channel is recommended. The repository is currently private, so GitHub Issues may not be accessible to all users.
- Blizzard's UI addon policy and CurseForge's moderation policy are independent requirements. Approval is not guaranteed.

Official guidance:
- https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project
- https://support.curseforge.com/support/solutions/articles/9000197279

### Proposed first upload
**File:** ForeverCompanion.zip from the successful packaging workflow
**Release type:** Beta until live client verification passes
**Description accuracy:** Read-only leveling/quest/class/cooldown/profession/PvP planning; recipe and inventory quantities are manual; spellbook availability is experimental; specialization names are guide previews.
**Version:** Match the TOC and changelog exactly.

## Account-safety release gate

Read [ACCOUNT_SAFETY.md](ACCOUNT_SAFETY.md) before submission. The addon must remain read-only, with no automation, external executable, injection, packet capture, dynamic code execution, or misleading safety assurances. CurseForge approval is not a guarantee against enforcement by Blizzard. Do not submit or distribute an untested Forever-specific build as verified.
