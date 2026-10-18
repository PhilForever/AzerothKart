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
for file in ['addon/AzerothKart/Track.lua','addon/AzerothKart/Physics.lua','addon/AzerothKart/UI.lua','addon/AzerothKart/Core.lua','tests/test_track.lua','tests/test_physics.lua','tests/test_determinism.lua']:
 l=lib.luaL_loadfilex(s,file.encode(),None)
 if l:
  print(file,'SYNTAX_FAIL',lib.lua_tolstring(s,-1,None).decode());had_error=True;break
 # Do NOT execute Core/UI because depends on WoW; only parse. Execute tests after parsing; test files execute their own Track Physics scripts
 if file.startswith('tests/'):
  l=lib.lua_pcallk(s,0,0,0,0,None)
  if l:
   print(file,'FAIL',lib.lua_tolstring(s,-1,None).decode());had_error=True;break
  print(file,'PASS')
 else: print(file,'syntax OK')
 lib.lua_settop(s,0)
else: print('PASS: syntax all and pure Lua tests with Lua 5.4 library')
lib.lua_close(s)

if had_error: raise SystemExit(1)
