-- Usage: from repository root: lua tests/run.lua
-- Pure tests plus explicitly mocked UI lifecycle checks, not a WoW client test.
local tests = {
    "tests/test_track.lua", "tests/test_mirage.lua", "tests/test_physics.lua", "tests/test_handling.lua", "tests/test_steering.lua", "tests/test_drift.lua", "tests/test_surface.lua", "tests/test_input.lua",
    "tests/test_loop.lua", "tests/test_performance.lua", "tests/test_presentation.lua", "tests/test_checkpoints.lua", "tests/test_laps.lua", "tests/test_race.lua", "tests/test_determinism.lua", "tests/test_ui.lua",
}
for _,path in ipairs(tests) do
    io.write("RUN ",path," ... ")
    local ok,err=pcall(dofile,path)
    if not ok then
        io.write("FAIL\n",tostring(err),"\n")
        error("Offline suite failed: "..path)
    end
    io.write("PASS\n")
end
print("All offline tests passed; live client behavior remains unverified.")
