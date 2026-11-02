# Forever Companion — CurseForge and Blizzard compliance review

Status: PRE-SUBMISSION REVIEW, not approval or legal certification. Review updated 2026-11-02.

## Distribution and intellectual property
- Addon must be free to download and use; no premium features, paid access or required subscriptions.
- Keep Lua source code visible and unobfuscated in the distributed package.
- No in-game advertisements, donation solicitations or promotional links. If donations are offered, keep them outside the addon and follow CurseForge placement rules.
- Use original artwork or properly licensed assets; do not copy another addon's logo, screenshots, UI textures or text without permission.
- Choose and document a license before publishing; check the rights for any third-party assets and guide content.

## Blizzard-native skill icons

- Prefer spell icons returned by the running client's supported spellbook or spell-info APIs; use a guarded call and never assume an ID exists in Forever.
- When live spell data is unavailable, use Blizzard interface texture paths already installed with the game. If a texture is absent, keep the text label visible and show a neutral fallback icon.
- Do not bundle extracted Blizzard texture files, rehost them as original art, or claim ownership of Blizzard's spell illustrations.
- Do not treat a generic class emblem as proof that a specific spell ID, talent, rank, or icon is verified for Forever.
- Verify actual icon resolution, class correctness, and missing-API behavior in the client before publishing.

## Gameplay safety
- The addon is a read-only guide. Manual player decisions remain mandatory for spells, targeting, combat, quests, purchases and crafting.
- No automatic combat decisions, input injection, botting, macro execution, protected gameplay calls, or external executable bundled in the ZIP.
- A static test blocks direct calls to common protected actions. It cannot prove compliance: manual source review and in-game verification are still required.
- Respect Forever-specific API restrictions, including combat data restrictions. Do not bypass restricted or secret values.
- Avoid excessive scans, network/chat spam, and performance degradation.

## Pre-upload intellectual-property review

- Inspect every packaged file, not only Lua: confirm there are no extracted Blizzard art files, unlicensed fonts, third-party addon code, copyrighted guide screenshots or misleading branding.
- Blizzard trademarks and game art remain Blizzard property; project name, logo and listing must not imply official endorsement.
- Referencing built-in client icon paths is not a grant of permission to republish those images outside the game, including in a future mobile app.
- A phone companion is out of scope for this beta and would require its own licensing, data-access and privacy review.
- Record any third-party source and its license in the release notes; block upload when rights are unclear.

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
