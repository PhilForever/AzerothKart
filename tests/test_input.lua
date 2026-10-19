local I=dofile("addon/AzerothKart/Input.lua")
local held=I.new()
local output={}
local aliases={
    {"W","UP","accelerate"}, {"S","DOWN","brake"},
    {"A","LEFT","left"}, {"D","RIGHT","right"},
}
for _,pair in ipairs(aliases) do
    I.clear(held)
    assert(I.set(held,string.lower(pair[1]),true),"lowercase key must normalize")
    I.set(held,pair[2],true)
    I.set(held,pair[1],false)
    assert(I.sample(held,output)==output,"sample must reuse supplied output")
    assert(output[pair[3]],"releasing one alias must preserve other held alias")
    I.set(held,pair[2],false)
    I.sample(held,output)
    assert(output[pair[3]]==false,"releasing final alias clears action")
end
I.set(held,"W",true)
I.set(held,"W",true)
I.set(held,"A",true)
I.set(held,"D",true)
I.sample(held,output)
assert(output.accelerate and output.left and output.right,"opposites remain explicit")
assert(I.set(held,"space",true),"Space drift key must normalize and be handled")
I.sample(held,output)
assert(output.drift,"held Space samples drift alongside steering")
I.set(held,"SPACE",false)
I.sample(held,output)
assert(not output.drift,"releasing Space clears drift")
I.set(held,"SPACE",true)
assert(not I.set(held,"ENTER",true),"unsupported key must remain unhandled")
assert(not I.set(held,nil,true),"invalid key must remain unhandled")
local sameHeld=held
I.clear(held)
assert(held==sameHeld and next(held)==nil,"clear must reuse and empty held state")
I.sample(held,output)
for _,key in ipairs({"accelerate","brake","left","right","drift"}) do
    assert(output[key]==false,"clearing must not leave stale sampled controls")
end
local before=_G.AzerothKart
dofile("addon/AzerothKart/Input.lua")
assert(_G.AzerothKart==before,"input import must remain pure")
