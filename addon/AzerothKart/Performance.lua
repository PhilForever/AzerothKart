-- Bounded scalar aggregates for injected profiler timestamps, in milliseconds.
-- This module reads no client APIs and retains no individual samples.
local _, namespace = ...

local Performance = {}
Performance.LIMIT = 600

function Performance.validTimestamp(value)
    return type(value) == "number" and value == value
        and value >= 0 and value < math.huge
end

function Performance.new()
    return {
        attempts=0, samples=0, invalid=0,
        simulationMs=0, simulationMaxMs=0,
        renderMs=0, renderMaxMs=0,
        totalMs=0, totalMaxMs=0,
    }
end

local function reject(stats)
    stats.attempts = stats.attempts + 1
    stats.invalid = stats.invalid + 1
    return false
end

function Performance.record(stats, begin, afterSimulation, finish)
    if stats.attempts >= Performance.LIMIT then return false end
    if not Performance.validTimestamp(begin)
        or not Performance.validTimestamp(afterSimulation)
        or not Performance.validTimestamp(finish)
        or afterSimulation < begin or finish < afterSimulation then
        return reject(stats)
    end

    local simulation = afterSimulation - begin
    local render = finish - afterSimulation
    local total = finish - begin
    local simulationSum = stats.simulationMs + simulation
    local renderSum = stats.renderMs + render
    local totalSum = stats.totalMs + total
    if not Performance.validTimestamp(simulationSum)
        or not Performance.validTimestamp(renderSum)
        or not Performance.validTimestamp(totalSum) then
        return reject(stats)
    end

    -- Commit only after all timestamp arithmetic and total validation succeeds.
    stats.attempts = stats.attempts + 1
    stats.samples = stats.samples + 1
    stats.simulationMs = simulationSum
    stats.renderMs = renderSum
    stats.totalMs = totalSum
    if simulation > stats.simulationMaxMs then stats.simulationMaxMs = simulation end
    if render > stats.renderMaxMs then stats.renderMaxMs = render end
    if total > stats.totalMaxMs then stats.totalMaxMs = total end
    return true
end

if type(namespace) == "table" then namespace.Performance = Performance end
return Performance
