# Beta release candidate verification record

Use the **ForeverCompanion** artifact from a successful `develop` GitHub Actions run. It contains both `ForeverCompanion.zip` and `beta-build-manifest.json`.

## Build provenance

The JSON records the exact Git commit, GitHub Actions run ID, addon version, declared client interface, and SHA-256 hash of the ZIP. The `in_game_tested` and `release_approved` fields intentionally remain `false` for CI artifacts. CI cannot certify a real game-client test.

## Tester verification

- Run: `python3 -c "import hashlib;print(hashlib.sha256(open('ForeverCompanion.zip','rb').read()).hexdigest())"`
- Compare that digest with the `sha256` field in `beta-build-manifest.json`.
- Install the ZIP following `BETA_INSTALL_TEST.md`.
- In the game, run `/fcdiag` and record the reported build and interface.
- Confirm every addon tab, the class skill checks, crafting manual-input flow, and window sizing.
- Record the result in a GitHub issue or a private test note. Do not change the generated manifest to claim approval without a real test.

## Release decision template

Commit SHA:
GitHub Actions run:
ZIP SHA-256:
Addon version:
WoW Forever client build:
Client interface:
Clean install: PASS / FAIL
In-game load: PASS / FAIL
Class/skill pages: PASS / FAIL
Crafting pages: PASS / FAIL
Navigation/visuals: PASS / FAIL
Saved variables/reload: PASS / FAIL
Protected-action compliance: PASS / FAIL
Approved for CurseForge beta: YES / NO
Tester/date:
Outstanding issues:

**Do not publish** if any mandatory test fails or remains untested.
