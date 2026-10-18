#!/usr/bin/env python3
"""Offline structural/package validator. This does NOT validate Lua syntax or run WoW."""
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
ADDON=ROOT/'addon'/'AzerothKart'
REQUIRED=[
 'README.md','AGENTS.md','PROMPT_01_MASTER.md','PROMPT_02_SCHEDULED_CONTINUE.md',
 'docs/INDEX.md','docs/FEASIBILITY.md','docs/ARCHITECTURE.md',
 'docs/ROADMAP.md','docs/PROGRESS.md','docs/TEST_PLAN.md','docs/CLIENT_API.md',
 'addon/AzerothKart/Track.lua','addon/AzerothKart/Physics.lua',
 'addon/AzerothKart/UI.lua','addon/AzerothKart/Core.lua','tests/run.lua',
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
 if loads!=['Track.lua','Physics.lua','UI.lua','Core.lua']:
  errors.append(f'{tocname}: unexpected source load order: {loads}')
 for f in loads:
  if not (ADDON/f).is_file():errors.append(f'{tocname}: missing {f}')
raw=(ROOT/'docs'/'PROTOCOL.md').read_text('utf-8')
if '255' not in raw or 'AZKART1' not in raw: errors.append('Protocol missing byte-cap or prefix specification')
if not (ROOT/'docs'/'PROGRESS.md').read_text('utf-8').count('Next exact task'):
 errors.append('PROGRESS missing next-task handoff')
if errors:
 for e in errors: print('FAIL',e)
 sys.exit(1)
print(f'STATIC PASS: {len(REQUIRED)} expected paths; TOC order; protocol docs; no Lua runtime executed.')
