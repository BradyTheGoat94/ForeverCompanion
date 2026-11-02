# Forever Companion — CurseForge and Blizzard compliance review

Status: PRE-SUBMISSION REVIEW, not approval or legal certification. Review updated 2026-11-02.

## Distribution and intellectual property
- Addon must be free to download and use; no premium features, paid access or required subscriptions.
- Keep Lua source code visible and unobfuscated in the distributed package.
- No in-game advertisements, donation solicitations or promotional links. If donations are offered, keep them outside the addon and follow CurseForge placement rules.
- Use original artwork or properly licensed assets; do not copy another addon's logo, screenshots, UI textures or text without permission.
- Choose and document a license before publishing; check the rights for any third-party assets and guide content.

## Gameplay safety
- The addon is a read-only guide. Manual player decisions remain mandatory for spells, targeting, combat, quests, purchases and crafting.
- No automatic combat decisions, input injection, botting, macro execution, protected gameplay calls, or external executable bundled in the ZIP.
- A static test blocks direct calls to common protected actions. It cannot prove compliance: manual source review and in-game verification are still required.
- Respect Forever-specific API restrictions, including combat data restrictions. Do not bypass restricted or secret values.
- Avoid excessive scans, network/chat spam, and performance degradation.

## CurseForge submission
- Select the World of Warcraft **Forever** flavor and verify the supported game version against the actual installed client.
- Provide an English project title, clear one-sentence summary, accurate feature description and substantive changelog.
- Label unverified class recommendations as illustrative, not proven optimal or benchmark-validated.
- Supply actual in-game screenshots. Mocked or AI-enhanced screenshots must be conspicuously disclosed and must not misrepresent in-game functionality.
- Verify ZIP structure, license, version, metadata, source attribution, and malware-free contents.
- No repetitive low-effort file uploads for visibility; each update must make a meaningful change.
- Manual installation and UI checks are release blockers; moderation approval belongs solely to CurseForge.

## Evidence and limits
Official policy references:
- Blizzard UI Add-On Development Policy: https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534
- Blizzard combat addon restrictions: https://worldofwarcraft.blizzard.com/en-gb/news/24244638/how-midnights-upcoming-game-changes-will-impact-combat-addons
- CurseForge moderation policy: https://support.curseforge.com/support/solutions/articles/9000197279
- CurseForge Forever flavor example: https://www.curseforge.com/wow/addons/foreverforge

Do not describe the addon as approved, certified, or live-client verified before those checks occur.
