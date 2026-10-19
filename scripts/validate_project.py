#!/usr/bin/env python3
"""Offline structural/package validator. This does NOT validate Lua syntax or run WoW."""
from pathlib import Path
import csv
import re
import sys

ROOT=Path(__file__).resolve().parents[1]
ADDON=ROOT/'addon'/'AzerothKart'
REQUIRED=[
 'README.md','AGENTS.md','PROMPT_01_MASTER.md','PROMPT_02_SCHEDULED_CONTINUE.md',
 'docs/INDEX.md','docs/FEASIBILITY.md','docs/ARCHITECTURE.md',
 'docs/ROADMAP.md','docs/PROGRESS.md','docs/TEST_PLAN.md','docs/CLIENT_API.md',
 'addon/AzerothKart/Track.lua','addon/AzerothKart/Physics.lua',
 'addon/AzerothKart/MirageRaceway.lua','tests/test_mirage.lua',
 'scripts/build_mirage_layout.py','docs/art/mirage-layout.json','docs/art/mirage-layout.svg',
 'scripts/build_mirage_background.py',
 'docs/art/mirage-background.md',
 'addon/AzerothKart/Assets/Tracks/SaltFlats/Background.tga',
 'addon/AzerothKart/Input.lua','addon/AzerothKart/Loop.lua',
 'addon/AzerothKart/Performance.lua','tests/test_performance.lua',
 'addon/AzerothKart/Presentation.lua','tests/test_presentation.lua',
 'addon/AzerothKart/Checkpoints.lua','tests/test_checkpoints.lua',
 'addon/AzerothKart/Laps.lua','tests/test_laps.lua',
 'addon/AzerothKart/Race.lua','tests/test_race.lua',
 'addon/AzerothKart/UI.lua','addon/AzerothKart/Core.lua','tests/run.lua',
 'tests/test_input.lua','tests/test_loop.lua','tests/test_ui.lua','tests/test_handling.lua','scripts/test_lua.py',
 'requirements-dev.txt','docs/experiments/network-ledger.csv',
 'scripts/install_local.ps1','tests/test_install_local.ps1',
]
errors=[]
for name in REQUIRED:
 if not (ROOT/name).is_file(): errors.append(f'Missing {name}')
for tocname in ('AzerothKart.toc','AzerothKart_Camelot.toc'):
 toc=ADDON/tocname
 if not toc.is_file(): errors.append(f'Missing {toc}') ; continue
 lines=toc.read_text('utf-8').splitlines()
 if '## Interface: 16001' not in lines: errors.append(f'{tocname}: unexpected interface')
 if '## SavedVariables: AzerothKartDB' not in lines: errors.append(f'{tocname}: missing SavedVariables')
 loads=[x.strip() for x in lines if x.strip() and not x.startswith('##')]
 if loads!=['Track.lua','MirageRaceway.lua','Physics.lua','Input.lua','Loop.lua','Performance.lua','Presentation.lua','Checkpoints.lua','Laps.lua','Race.lua','UI.lua','Core.lua']:
  errors.append(f'{tocname}: unexpected source load order: {loads}')
 for f in loads:
  if not (ADDON/f).is_file():errors.append(f'{tocname}: missing {f}')
 expected_toc='base' if tocname=='AzerothKart.toc' else 'Camelot'
 if f'## X-AzerothKart-TOC: {expected_toc}' not in lines:
  errors.append(f'{tocname}: missing discovery probe marker')
 # Both flavors must load exactly once into the same namespace and metadata.
 if len(loads)!=len(set(loads)): errors.append(f'{tocname}: duplicate module load')
raw=(ROOT/'docs'/'PROTOCOL.md').read_text('utf-8')
if '255' not in raw or 'AZKART1' not in raw: errors.append('Protocol missing byte-cap or prefix specification')
if not (ROOT/'docs'/'PROGRESS.md').read_text('utf-8').count('Next exact task'):
 errors.append('PROGRESS missing next-task handoff')
for file in [ROOT/'README.md', *sorted((ROOT/'docs').rglob('*.md')), *sorted((ROOT/'tests').glob('*.md'))]:
 for target in re.findall(r'\]\(([^)\s]+)\)', file.read_text('utf-8')):
  if '://' in target or target.startswith('#'): continue
  path=target.split('#',1)[0]
  if not (file.parent/path).exists(): errors.append(f'{file.relative_to(ROOT)}: broken link {target}')
ledger=ROOT/'docs'/'experiments'/'network-ledger.csv'
if ledger.is_file():
 rows=list(csv.reader(ledger.read_text('utf-8-sig').splitlines()))
 if not rows or len(rows[0])!=len(set(rows[0])): errors.append('Network ledger missing/duplicate headers')
 elif not {'data_attempts','ack_matched_unique','ack_timeouts_at_deadline','rtt_p95_ms','reordered_unique','throttle_events'} <= set(rows[0]):
  errors.append('Network ledger missing measurement fields')
 elif any(len(row)!=len(rows[0]) for row in rows[1:]): errors.append('Network ledger row/header width mismatch')
if errors:
 for e in errors: print('FAIL',e)
 sys.exit(1)
print(f'STATIC PASS: {len(REQUIRED)} expected paths; TOC order; protocol docs; local links; network ledger; no Lua runtime executed.')
