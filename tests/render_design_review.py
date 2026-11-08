"""Render the real mocked widget captures into a compact design-review gallery.

Run mock_ui.lua first. Icons and fonts are approximations, not game captures.
"""
import argparse
import html
from pathlib import Path
from render_native_preview import render


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', default='work/design-review')
    args = parser.parse_args()
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    sections = ('dashboard', 'journey', 'class', 'gear', 'topic', 'quest',
                'profession', 'loot', 'encounter', 'legacy', 'alts', 'practice',
                'pvp', 'settings', 'meter')
    cards = []
    for section in sections:
        source = Path('ui_' + section + '_native.json')
        if not source.exists():
            continue
        target = output / (section + '.png')
        options = {'window_name': 'ForeverCompanionCombatMeterWindow'} if section == 'meter' else {}
        render(source, target, **options)
        label = {'topic': 'Talent planner', 'class': 'Class guides', 'quest': 'Quest journal',
                 'profession': 'Profession planning', 'meter': 'Meter — empty API state'}.get(section, section.title())
        cards.append(f'<figure><a href="{section}.png"><img loading="lazy" src="{section}.png" alt="{html.escape(label)}"></a><figcaption>{html.escape(label)}</figcaption></figure>')
    body = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Forever Companion — interface review</title>
<style>body{margin:0;background:#0d1118;color:#e7edf5;font:16px/1.5 system-ui,sans-serif}header,main{max-width:1440px;margin:auto;padding:32px}h1{font-size:28px;margin:0 0 10px}p{color:#acb9ca;max-width:900px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(360px,1fr));gap:24px;padding-top:0}figure{margin:0;background:#151d29;border:1px solid #2a3545}img{display:block;width:100%;height:auto}figcaption{padding:14px 18px;color:#dfc58f}a{color:inherit}</style>
<header><h1>Forever Companion · interface review</h1><p>Offline captures of the addon's actual widget structure and layout. Fonts and Blizzard icons are approximated. Sample quests and character names are test fixtures. These are not in-game screenshots. The meter preview contains no fabricated combat values. Click any image for full size.</p></header><main>'''
    (output / 'index.html').write_text(body + ''.join(cards) + '</main></html>', encoding='utf-8')
    print('PASS: design-review gallery:', output / 'index.html')


if __name__ == '__main__':
    main()
