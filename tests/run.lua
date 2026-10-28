-- Usage: from repository root: lua tests/run.lua
-- Pure tests plus explicitly mocked UI lifecycle checks, not a WoW client test.
local tests = {
    "tests/test_group_probe.lua",
    "tests/test_layered_track.lua", "tests/test_layered_physics.lua", "tests/test_grass_boost.lua", "tests/test_open_grass.lua", "tests/test_arathi_grass_map.lua", "tests/test_warsong.lua", "tests/test_arathi.lua", "tests/test_arathi_guide.lua",
    "tests/test_score_channel_probe.lua",
    "tests/test_highscores.lua", "tests/test_community_scores.lua", "tests/test_solo_records.lua",
    "tests/test_kart_handling.lua",
    "tests/test_drift_payoff.lua",
    "tests/test_score_sync.lua", "tests/test_score_discovery.lua", "tests/test_score_sharing.lua",
    "tests/test_clock_protocol.lua", "tests/test_start_clock.lua", "tests/test_race_start.lua",
    "tests/test_live_protocol.lua", "tests/test_race_grid.lua", "tests/test_live_race.lua",
    "tests/test_track.lua", "tests/test_obstacles.lua", "tests/test_wall_slide.lua", "tests/test_mirage.lua", "tests/test_circuit.lua", "tests/test_dungeon.lua", "tests/test_physics.lua", "tests/test_handling.lua", "tests/test_steering.lua", "tests/test_drift.lua", "tests/test_surface.lua", "tests/test_input.lua",
    "tests/test_loop.lua", "tests/test_performance.lua", "tests/test_presentation.lua", "tests/test_checkpoints.lua", "tests/test_laps.lua", "tests/test_race.lua", "tests/test_determinism.lua", "tests/test_network_probe.lua", "tests/test_race_protocol.lua", "tests/test_peer_session.lua", "tests/test_transport_probe.lua", "tests/test_session_transport.lua", "tests/test_ui.lua", "tests/test_menu.lua", "tests/test_multiplayer_integration.lua",
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
