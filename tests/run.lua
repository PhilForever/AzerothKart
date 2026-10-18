-- Usage: from repository root: lua tests/run.lua
-- Requires Lua runtime; intentionally does not stub in WoW globals.
local tests = {"tests/test_track.lua", "tests/test_physics.lua", "tests/test_determinism.lua"}
for _,path in ipairs(tests) do
    io.write("RUN ",path," ... ")
    local ok,err=pcall(dofile,path)
    if not ok then
        io.write("FAIL\n",tostring(err),"\n")
        os.exit(1)
    end
    io.write("PASS\n")
end
print("All authored pure Lua starter tests passed.")
