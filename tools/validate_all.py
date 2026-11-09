"""One offline acceptance command for local work and all release workflows.

Uses Lua 5.1 from PATH, or the optional local work/python lupa installation.
Never certifies client behavior or publishes files.
"""
import os
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SUITES = (
    'offline_smoke', 'combat_meter_ui_smoke', 'service_clusters_smoke',
    'journey_route_smoke', 'quest_pickups_smoke', 'available_quests_smoke',
    'quest_discovery_smoke', 'quest_locations_smoke', 'quest_guide_smoke',
    'quest_sync_metadata_smoke', 'quest_history_smoke', 'material_workspace_smoke',
    'loot_boss_smoke', 'icons_and_gear_smoke', 'study_board_smoke',
    'research_notebook_smoke', 'refresh_queue_smoke', 'quest_setup_smoke', 'objective_route_smoke',
    'navigation_hud_smoke', 'party_map_smoke', 'session_progress_smoke', 'service_atlas_smoke', 'map_overlay_smoke', 'map_tools_smoke', 'mock_ui',
)

def main():
    os.chdir(ROOT)
    env = dict(os.environ, PYTHONUTF8='1')
    scratch=ROOT / 'work/tmp'
    scratch.mkdir(parents=True,exist_ok=True)
    tempfile.tempdir=str(scratch)
    def run(*args):
        subprocess.run(args, cwd=ROOT, env=env, check=True)
    lua = shutil.which('lua5.1') or shutil.which('lua')
    if lua:
        run(lua, '-e', 'assert(_VERSION == "Lua 5.1", "Lua 5.1 required")')
        for source in sorted(Path('ForeverCompanion').glob('*.lua')):
            run(lua, '-e', 'assert(loadfile(' + json.dumps(source.as_posix()) + '))')
        for suite in SUITES:
            run(lua, 'tests/' + suite + '.lua')
    else:
        # Optional developer-only runtime; excluded from all addon archives.
        sys.path.insert(0, str(ROOT / 'work/python'))
        from lupa.lua51 import LuaRuntime
        for source in sorted(Path('ForeverCompanion').glob('*.lua')):
            LuaRuntime().execute('assert(loadstring(...))', source.read_text(encoding='utf-8-sig'))
        for suite in SUITES:
            print('RUN', suite, flush=True)
            LuaRuntime().execute(Path('tests/' + suite + '.lua').read_text(encoding='utf-8-sig'))
    for script in ('release_audit.py', 'tools/audit_curseforge_submission.py',
                   'tools/audit_forever_apis.py', 'tools/audit_no_combat_automation.py',
                   'tests/validate_guide_preflight.py', 'tests/validate_beta_gate.py'):
        run(sys.executable, script)
    run(sys.executable, '-c', 'import tempfile,unittest; tempfile.tempdir=' + repr(str(scratch)) +
        '; r=unittest.TextTestRunner().run(unittest.defaultTestLoader.discover("tests",pattern="test_*.py")); raise SystemExit(not r.wasSuccessful())')
    with tempfile.TemporaryDirectory() as directory:
        run(sys.executable, 'tools/build_curseforge_beta.py', '--output', directory)
        archives = list(Path(directory).glob('*.zip'))
        assert len(archives) == 1
        run(sys.executable, 'tests/validate_package.py', str(archives[0]))
    print('PASS: unified offline acceptance; in-game acceptance remains separate')

if __name__ == '__main__':
    main()
