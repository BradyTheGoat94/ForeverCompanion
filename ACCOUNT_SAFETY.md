# Account safety and release policy

**Status: not certified, not approved by Blizzard or CurseForge, and not tested on a release client.**

Forever Companion is designed as a read-only in-game reference. The addon must not perform actions on the player's behalf.

## Prohibited design patterns
- No automated casting, targeting, movement, combat decisions, queueing or input simulation.
- No process injection, memory inspection, packet capture, network interception, or executable helper.
- No dynamic code downloads, code obfuscation, remote execution, or hidden functionality.
- No in-game paid unlocks, advertisements or donation solicitation.
- No claim that CurseForge approval guarantees Blizzard account safety.
- No unsupported claims that Forever-specific mechanics or API behavior are verified.

## Allowed design target (subject to actual client rules)
- Local guide windows, user-selected checklists, manual profession plans and recipe goals.
- Passive, guarded reads of supported addon APIs.
- Explicit user clicks for configuration and manual progress updates.
- All addon Lua code included in the distribution and publicly inspectable.

## Release gates
1. Automated Lua syntax, manifest and account-safety audit must pass.
2. Manual review of every new API call and third-party dependency.
3. Verify Blizzard's current addon policy and any Forever-specific policies against primary sources.
4. Test the real client on an account whose owner understands the risks; no promise of zero ban risk.
5. Obtain the project owner's approval for the license, public source distribution, artwork and CurseForge submission.
6. Publish only after confirming supported game version and CurseForge moderation requirements.

This document is engineering policy, not legal advice or an official safety endorsement.
