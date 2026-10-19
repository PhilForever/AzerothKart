-- Pure render-pose interpolation; never feed the result back into simulation.
local _, namespace = ...
local Presentation = {}
local pi, tau = math.pi, 2 * math.pi

function Presentation.pose(previous, current, alpha)
    assert(current, "current pose required")
    -- Missing/invalid timing draws the exact latest state. Infinities clamp
    -- naturally below; NaN must be handled before comparisons/arithmetic.
    if type(alpha) ~= "number" or alpha ~= alpha then alpha = 1 end
    if not previous or alpha >= 1 then return current.x, current.y, current.heading end
    if alpha <= 0 then return previous.x, previous.y, previous.heading end

    -- Physics headings may accumulate whole turns. Only the shortest rotation
    -- matters between consecutive states; a half-turn chooses the negative arc.
    local delta = (current.heading - previous.heading + pi) % tau - pi
    return previous.x + (current.x - previous.x) * alpha,
           previous.y + (current.y - previous.y) * alpha,
           previous.heading + delta * alpha
end

if type(namespace) == "table" then namespace.Presentation = Presentation end
return Presentation
