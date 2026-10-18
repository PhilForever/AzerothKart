import ctypes, os
from pathlib import Path
p=Path(__file__).resolve().parents[1]; os.chdir(p)

try:
    lib=ctypes.CDLL('liblua5.4.so.0')
except OSError as exc:
    raise SystemExit('Optional Linux liblua5.4.so.0 unavailable; use `lua tests/run.lua`: ' + str(exc))
lib.luaL_newstate.restype=ctypes.c_void_p
lib.luaL_openlibs.argtypes=[ctypes.c_void_p]
lib.luaL_loadfilex.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_char_p]
lib.luaL_loadfilex.restype=ctypes.c_int
lib.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_longlong,ctypes.c_void_p]
lib.lua_pcallk.restype=ctypes.c_int
lib.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.POINTER(ctypes.c_size_t)]
lib.lua_tolstring.restype=ctypes.c_char_p
lib.lua_settop.argtypes=[ctypes.c_void_p,ctypes.c_int]
lib.lua_close.argtypes=[ctypes.c_void_p]
s=lib.luaL_newstate();lib.luaL_openlibs(s)
had_error = False
files=sorted(Path('addon/AzerothKart').glob('*.lua'))+sorted(Path('tests').glob('*.lua'))
for path in files:
 file=path.as_posix()
 l=lib.luaL_loadfilex(s,file.encode(),None)
 if l:
  print(file,'SYNTAX_FAIL',lib.lua_tolstring(s,-1,None).decode());had_error=True;break
 # Only parse here: UI/Core need the explicit mocks in tests/test_ui.lua.
 print(file,'syntax OK')
 lib.lua_settop(s,0)
if not had_error:
 l=lib.luaL_loadfilex(s,b'tests/run.lua',None)
 if not l: l=lib.lua_pcallk(s,0,0,0,0,None)
 if l:
  print('SUITE FAIL',lib.lua_tolstring(s,-1,None).decode());had_error=True
 else: print('PASS: syntax all and complete offline suite with Lua 5.4 library; no live client')
lib.lua_close(s)

if had_error: raise SystemExit(1)
