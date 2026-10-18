-- Physical held keys and allocation-free semantic samples. No client APIs.
local _, namespace = ...
local Input = {}
local supported = {
    W=true, UP=true, S=true, DOWN=true,
    A=true, LEFT=true, D=true, RIGHT=true,
}

function Input.new()
    return {}
end

function Input.set(held, key, down)
    if type(key) ~= "string" then return false end
    key = string.upper(key)
    if not supported[key] then return false end
    held[key] = down and true or nil
    return true
end

function Input.clear(held)
    for key in pairs(held) do held[key] = nil end
end

function Input.sample(held, output)
    output = output or {}
    output.accelerate = not not (held.W or held.UP)
    output.brake = not not (held.S or held.DOWN)
    output.left = not not (held.A or held.LEFT)
    output.right = not not (held.D or held.RIGHT)
    return output
end

if type(namespace) == "table" then namespace.Input = Input end
return Input
