local T=dofile("addon/AzerothKart/Track.lua")
local P=dofile("addon/AzerothKart/Physics.lua")
local function simulate()
    local st=P.new(T)
    for tick=1,10000 do
        local phase=tick%460
        local input={
            accelerate=(phase<380),
            brake=(phase>=380 and phase<405),
            left=(phase>=80 and phase<170),
            right=(phase>=220 and phase<270),
        }
        st=P.step(st,input,P.FIXED_DT,T)
    end
    return st
end
local a,b=simulate(),simulate()
for _,key in ipairs({"x","y","heading","speed","tick","impacts"}) do
    assert(a[key]==b[key],"non-deterministic field: "..key)
end
assert(a.tick==10000,"expected 10k ticks")
