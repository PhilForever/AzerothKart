#!/usr/bin/env python3
"""Make a local test addon ZIP only. Publishing remains a manual, authorized action."""
from pathlib import Path
import zipfile
ROOT=Path(__file__).resolve().parents[1]
ADDON=ROOT/'addon'/'AzerothKart'
DEST=ROOT/'release'/'AzerothKart-dev.zip'
DEST.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(DEST,'w',zipfile.ZIP_DEFLATED) as z:
 for f in ADDON.rglob('*'):
  if f.is_file(): z.write(f,Path('AzerothKart')/f.relative_to(ADDON))
print(f'Created (NOT tested in game or published): {DEST}')
