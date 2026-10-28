local beforeGlobal = _G.AzerothKart
local P = dofile("addon/AzerothKart/Presentation.lua")
local pi, tau = math.pi, 2 * math.pi
local function near(actual, expected, message)
    assert(math.abs(actual - expected) < 1e-10, message)
end

local square = P.fitViewport(1024,1024,800,480)
assert(square.scale==0.46875 and square.offsetX==160 and square.offsetY==0
       and square.width==480 and square.height==480, "square world is centered without stretching")
assert(square.worldWidth==1024 and square.worldHeight==1024 and
       square.canvasWidth==800 and square.canvasHeight==480, "viewport retains its source dimensions")
assert(P.fitViewport(1024,1024,800,480)~=square, "viewport factory returns a fresh value")
local snapshotView = {}
for key,value in pairs(square) do snapshotView[key]=value end
local function projected(view,x,y,expectedX,expectedY,label)
    local px,py = P.project(view,x,y)
    near(px,expectedX,label.." x")
    near(py,expectedY,label.." y")
    local wx,wy = P.unproject(view,px,py)
    near(wx,x,label.." round-trip x")
    near(wy,y,label.." round-trip y")
end
projected(square,0,0,160,0,"square bottom-left")
projected(square,1024,1024,640,480,"square top-right")
projected(square,512,512,400,240,"square center")
projected(square,-512,1536,-80,720,"outside world remains unclamped")
local outsideX,outsideY = P.unproject(square,40,-120)
assert(outsideX==-256 and outsideY==-256, "letterbox and outside canvas coordinates stay unclamped")
local landscape = P.fitViewport(1600,400,800,480)
assert(landscape.scale==0.5 and landscape.offsetX==0 and landscape.offsetY==140
       and landscape.width==800 and landscape.height==200, "landscape world is letterboxed vertically")
projected(landscape,1600,400,800,340,"landscape top-right")
local portrait = P.fitViewport(400,1600,800,480)
assert(portrait.scale==0.3 and portrait.offsetX==340 and portrait.offsetY==0
       and portrait.width==120 and portrait.height==480, "portrait world is letterboxed horizontally")
projected(portrait,200,800,400,240,"portrait center")
assert(select("#",P.project(square,0,0))==2 and select("#",P.unproject(square,160,0))==2,
       "viewport mapping returns two scalars without allocating point tables")
for key,value in pairs(square) do assert(snapshotView[key]==value,"projection changed viewport "..key) end
for key,value in pairs(snapshotView) do assert(square[key]==value,"projection lost viewport "..key) end
for _,invalid in ipairs({false,"1024",0,-1,0/0,math.huge,-math.huge}) do
    assert(not pcall(P.fitViewport,invalid,1024,800,480), "invalid world width must reject")
    assert(not pcall(P.fitViewport,1024,invalid,800,480), "invalid world height must reject")
    assert(not pcall(P.fitViewport,1024,1024,invalid,480), "invalid canvas width must reject")
    assert(not pcall(P.fitViewport,1024,1024,800,invalid), "invalid canvas height must reject")
end
assert(not pcall(P.fitViewport,nil,1024,800,480), "missing dimensions must reject")
for _,map in ipairs({P.project,P.unproject}) do
    for _,invalid in ipairs({false,"1024",0/0,math.huge,-math.huge}) do
        assert(not pcall(map,square,invalid,0) and not pcall(map,square,0,invalid),
            "mapping rejects nonfinite or nonnumeric coordinates")
    end
    assert(not pcall(map,nil,0,0) and not pcall(map,square,nil,0),
        "mapping requires a viewport and both coordinates")
    for _,view in ipairs({{}, {scale=0,offsetX=0,offsetY=0},
        {scale=math.huge,offsetX=0,offsetY=0}, {scale=1,offsetX=0/0,offsetY=0},
        {scale=1,offsetX=0,offsetY=math.huge}}) do
        assert(not pcall(map,view,0,0), "mapping rejects invalid transforms")
    end
end
assert(not pcall(P.fitViewport,1e-308,1e-308,1e308,1e308)
       and not pcall(P.fitViewport,1e308,1e308,1e-308,1e-308),
       "unrepresentable viewport scales cannot produce poisoned transforms")
assert(not pcall(P.project,{scale=2,offsetX=0,offsetY=0},1e308,0)
       and not pcall(P.unproject,{scale=0.1,offsetX=0,offsetY=0},1e308,0),
       "unrepresentable mapped coordinates must reject")

local camera = P.cameraViewport(1024,1024,800,480,1.5)
assert(camera.scale==1.5 and camera.width==800 and camera.height==480
       and camera.follow==true, "close camera fills the full landscape canvas uniformly")
near(camera.viewWidth,800/1.5,"camera visible world width")
near(camera.viewHeight,320,"camera visible world height")
assert(P.cameraViewport(1024,1024,800,480).scale==1.5,"close camera has a deliberate default zoom")
local cameraBefore = {}
for key,value in pairs(camera) do cameraBefore[key]=value end
assert(P.follow(camera,700,360,pi/2)==camera,"follow reuses the same viewport")
projected(camera,700,360,400,150,"Mirage start has forward road space")
near(112*camera.scale,168,"Mirage road is 168 canvas units wide")
near(17*camera.scale,25.5,"placeholder kart is readable at the close camera scale")
for key,value in pairs(cameraBefore) do
    if key~="offsetX" and key~="offsetY" then
        assert(camera[key]==value,"follow only changes presentation offsets: "..key)
    end
end
local function crop(view,left,right,top,bottom,label)
    local l,r,t,b = P.texCoords(view)
    near(l,left,label.." left"); near(r,right,label.." right")
    near(t,top,label.." top"); near(b,bottom,label.." bottom")
    assert(l>=0 and r<=1 and t>=0 and b<=1 and l<r and t<b,
        label.." stays inside the image with upright UV ordering")
end
local spawnLeft,spawnBottom = P.unproject(camera,0,0)
crop(camera,spawnLeft/1024,(spawnLeft+800/1.5)/1024,
    1-(spawnBottom+320)/1024,1-spawnBottom/1024,"spawn crop")
assert(select("#",P.texCoords(camera))==4,"camera crop returns four scalars")
local offsetX,offsetY = camera.offsetX,camera.offsetY
P.texCoords(camera)
assert(camera.offsetX==offsetX and camera.offsetY==offsetY,"UV lookup does not move the camera")
P.follow(camera,0,0,pi)
assert(camera.offsetX==0 and camera.offsetY==0,"lookahead clamps at the bottom-left world edge")
crop(camera,0,(800/1.5)/1024,1-320/1024,1,"bottom-left crop")
P.follow(camera,1024,1024,0)
near(camera.offsetX,800-1024*1.5,"right-edge camera clamp")
near(camera.offsetY,480-1024*1.5,"top-edge camera clamp")
crop(camera,1-(800/1.5)/1024,1,0,320/1024,"top-right crop")
local covered = P.cameraViewport(1024,1024,800,480,0.1)
assert(covered.scale==800/1024,"too-wide requested view clamps to cover the canvas")
P.follow(covered,0,1024,pi/2)
crop(covered,0,1,0,480/800,"cover zoom has no side margins or out-of-world UVs")
P.follow(camera,700,360,pi/2,0)
projected(camera,700,360,400,240,"zero lookahead centers the kart")
P.follow(camera,600,360,0)
projected(camera,600,360,310,240,"heading changes shift visible road ahead without rotating art")

P.follow(camera,512,512,0,0)
local left,bottom = P.unproject(camera,0,0)
local function clipped(x,y,width,height,expectedX,expectedY,expectedW,expectedH,label)
    local px,py,w,h = P.clipRect(camera,x,y,width,height)
    near(px,expectedX,label.." x"); near(py,expectedY,label.." y")
    near(w,expectedW,label.." width"); near(h,expectedH,label.." height")
end
clipped(left+10,bottom+20,112,2,15,30,168,3,"fully visible gate")
clipped(left-10,bottom+10,20,20,0,15,15,30,"left-edge gate fragment")
clipped(left+10,bottom+310,20,20,15,465,30,15,"top-edge wall fragment")
clipped(left-10,bottom-10,1000,1000,0,0,800,480,"rectangle covering the camera")
assert(P.clipRect(camera,left-20,bottom,10,10)==nil
       and P.clipRect(camera,left,bottom-20,10,10)==nil,
       "offscreen regions hide instead of leaking onto other UI")
assert(P.clipRect(camera,left-10,bottom,10,10)==nil
       and P.clipRect(camera,left,bottom,0,10)==nil,
       "edge-only or empty rectangles have no visible fragment")
assert(select("#",P.clipRect(camera,left,bottom,20,20))==4,
       "clipping returns scalar dimensions without allocating rectangles")
local cameraKeys = {}
for key,value in pairs(camera) do cameraKeys[key]=value end
P.clipRect(camera,left-10,bottom,20,20)
P.texCoords(camera)
for key,value in pairs(cameraKeys) do assert(camera[key]==value,"crop/clip keeps the camera unchanged") end
for _,invalid in ipairs({false,"1.5",0,-1,0/0,math.huge,-math.huge}) do
    assert(not pcall(P.cameraViewport,1024,1024,800,480,invalid),"invalid zoom rejects")
end
assert(not pcall(P.cameraViewport,0,1024,800,480)
       and not pcall(P.cameraViewport,1024,1024,0,480),"invalid camera dimensions reject")
assert(not pcall(P.follow,square,0,0,0)
       and not pcall(P.texCoords,square),"an overview cannot accidentally use follow-camera UVs")
assert(not pcall(P.follow,camera,0/0,0,0)
       and not pcall(P.follow,camera,0,0,math.huge)
       and not pcall(P.follow,camera,0,0,0,-1),"invalid camera target/lookahead rejects")
assert(not pcall(P.clipRect,camera,0,0,-1,20)
       and not pcall(P.clipRect,camera,0,0,20,math.huge),"invalid rectangle dimensions reject")

local function pose(previous, current, alpha, x, y, heading, message)
    local px, py, ph = P.pose(previous, current, alpha)
    near(px, x, message .. " x")
    near(py, y, message .. " y")
    near(ph, heading, message .. " heading")
end

local marker = {}
local previous = {x=-10, y=8, heading=0.2, tick=19, marker=marker}
local current = {x=30, y=-12, heading=0.8, tick=20, marker=marker}
pose(previous, current, 0.5, 10, -2, 0.5, "midpoint")
pose(previous, current, 0.25, 0, 3, 0.35, "quarter tick")
pose(previous, current, 0, previous.x, previous.y, previous.heading, "previous endpoint")
pose(previous, current, 1, current.x, current.y, current.heading, "current endpoint")
pose(previous, current, -100, previous.x, previous.y, previous.heading, "negative clamp")
pose(previous, current, 100, current.x, current.y, current.heading, "positive clamp")
pose(previous, current, -math.huge, previous.x, previous.y, previous.heading, "negative infinity")
pose(previous, current, math.huge, current.x, current.y, current.heading, "positive infinity")
pose(previous, current, nil, current.x, current.y, current.heading, "default latest")
pose(previous, current, 0/0, current.x, current.y, current.heading, "NaN latest")
pose(previous, current, false, current.x, current.y, current.heading, "boolean latest")
pose(previous, current, "0.5", current.x, current.y, current.heading, "string latest")
pose(nil, current, 0, current.x, current.y, current.heading, "missing previous")
assert(not pcall(P.pose, previous, nil, 0.5), "current pose is required")

local nearEnd = {x=0, y=0, heading=tau - 0.1}
local nearStart = {x=2, y=4, heading=0.1}
pose(nearEnd, nearStart, 0.5, 1, 2, tau, "forward across zero")
pose(nearStart, nearEnd, 0.5, 1, 2, 0, "reverse across zero")
local wrappedX, wrappedY, wrappedHeading = P.pose(nearEnd, nearStart, 1)
assert(wrappedX == nearStart.x and wrappedY == nearStart.y and wrappedHeading == nearStart.heading,
       "current endpoint preserves the exact raw heading after wrap")
local _, _, previousHeading = P.pose(nearStart, nearEnd, 0)
assert(previousHeading == nearStart.heading, "previous endpoint preserves exact raw heading")
local manyTurns = {x=4, y=8, heading=40 * tau + 0.1}
local negativeTurns = {x=8, y=12, heading=-30 * tau + 0.3}
pose(manyTurns, negativeTurns, 0.5, 6, 10, 40 * tau + 0.2, "unbounded headings")
local _, _, rawHeading = P.pose(manyTurns, negativeTurns, 1)
assert(rawHeading == negativeTurns.heading, "latest endpoint never normalizes physics heading")
pose({x=0, y=0, heading=0}, {x=0, y=0, heading=pi}, 0.5,
     0, 0, -pi/2, "half-turn tie is deterministic")

assert(previous.x == -10 and previous.y == 8 and previous.heading == 0.2 and
       previous.tick == 19 and previous.marker == marker, "previous simulation state stays unchanged")
assert(current.x == 30 and current.y == -12 and current.heading == 0.8 and
       current.tick == 20 and current.marker == marker, "current simulation state stays unchanged")
assert(select("#", P.pose(previous, current, 0.5)) == 3,
       "render pose returns exactly three scalars")

-- Remote display uses the packet's estimated state age, without adding a
-- receive-time interpolation interval. This is bounded visual prediction,
-- not input replay, authoritative correction or a promise of the real pose.
do
    local straight = {resolveMovement=function(x,y,tx,ty) return tx,ty,false end}
    local older = {x=10,y=30,heading=0,speed=100,sampleMS=0,status="running",marker=marker}
    local latest = {x=60,y=30,heading=0,speed=100,sampleMS=500,status="running",marker=marker}
    local function copy(value)
        local result = {}
        for key,item in pairs(value) do result[key]=item end
        return result
    end
    local beforeOlder,beforeLatest = copy(older),copy(latest)
    local path = P.buildRemotePath(older,latest,straight)
    assert(#path.points==31 and path.maxAgeMS==500 and P.MAX_REMOTE_PREDICTION_MS==500,
        "one observation caches at most thirty fixed steps plus the observed pose")
    local function remote(path,age,x,y,h,predicted,message)
        local rx,ry,rh,rp = P.remotePose(path,age)
        near(rx,x,message.." x"); near(ry,y,message.." y"); near(rh,h,message.." heading")
        assert(rp==predicted,message.." prediction label")
    end
    remote(path,0,60,30,0,false,"zero age is exactly the latest observation")
    remote(path,350,95,30,0,true,"350ms wire age advances from the sender pose")
    remote(path,500,110,30,0,true,"500ms forecast cap")
    remote(path,1500,110,30,0,true,"stale data freezes at the same cap")
    remote(path,-100,60,30,0,false,"negative age clamps to latest")
    for _,age in ipairs({0/0,math.huge,-math.huge,false,"350"}) do
        remote(path,age,60,30,0,false,"invalid age never poisons the pose")
    end
    remote(path,nil,60,30,0,false,"missing age does not guess latency")
    assert(select("#",P.remotePose(path,350))==4,"remote rendering returns four scalars")
    local extended = P.buildRemotePath(older,latest,straight,1000)
    assert(#extended.points==61 and extended.maxAgeMS==1000,
        "a one-second horizon remains a bounded cached path")
    remote(extended,1000,160,30,0,true,"extended horizon advances through transit and the next packet interval")
    remote(extended,4000,160,30,0,true,"a stale extended path freezes at its own cap")
    local longest = P.buildRemotePath(older,latest,straight,1e300)
    assert(P.MAX_REMOTE_HORIZON_MS==1250 and longest.maxAgeMS==1250 and #longest.points==76,
        "caller-selected horizons cannot exceed 75 fixed movement segments")
    remote(longest,1250,185,30,0,true,"maximum supported horizon")
    remote(longest,5000,185,30,0,true,"maximum horizon also freezes stale observations")
    for _,horizon in ipairs({0,-1,100,0/0,math.huge,-math.huge,false,"1000",{}}) do
        local bounded=P.buildRemotePath(older,latest,straight,horizon)
        assert(bounded.maxAgeMS==500 and #bounded.points==31,
            "invalid or undersized horizon keeps the original finite forecast bound")
    end
    local savedHorizon=extended.maxAgeMS
    extended.maxAgeMS=0/0
    remote(extended,4000,110,30,0,true,"malformed path horizon cannot bypass the default bound")
    extended.maxAgeMS=savedHorizon
    -- Skipped, repeated and out-of-order rendered frames read the same path.
    local px,py,ph = P.remotePose(path,350)
    for _,age in ipairs({16,400,10,500,350,1000,0}) do P.remotePose(path,age) end
    local rx,ry,rh = P.remotePose(path,350)
    assert(px==rx and py==ry and ph==rh,"remote pose is independent of render cadence")
    for key,value in pairs(older) do assert(beforeOlder[key]==value,"older observation stays read-only") end
    for key,value in pairs(latest) do assert(beforeLatest[key]==value,"latest observation stays read-only") end
    for key,value in pairs(beforeOlder) do assert(older[key]==value,"older fields retained") end
    for key,value in pairs(beforeLatest) do assert(latest[key]==value,"latest fields retained") end
    assert(older.marker==marker and latest.marker==marker,"nested observation references are untouched")

    local fast = copy(latest); fast.speed=1e300
    local capped = P.buildRemotePath(nil,fast,straight)
    remote(capped,500,190,30,0,true,"excessive signed speed is bounded at 260 units/s")
    fast.speed=-100
    remote(P.buildRemotePath(nil,fast,straight),350,25,30,0,true,"reverse travels behind the heading")
    local lateral = copy(older); lateral.x,lateral.y=60,-20
    remote(P.buildRemotePath(lateral,latest,straight),350,60,65,0,true,
        "valid measured travel direction preserves drift without changing facing")
    local teleported = copy(older); teleported.x=-1000
    remote(P.buildRemotePath(teleported,latest,straight),350,95,30,0,true,
        "unbounded baseline displacement cannot choose the travel direction")
    for _,stamp in ipairs({500,600,0/0,math.huge,-10000}) do
        local baseline = copy(lateral); baseline.sampleMS=stamp
        remote(P.buildRemotePath(baseline,latest,straight),350,95,30,0,true,
            "invalid or old baseline duration falls back to current speed and heading")
    end
    local noStamp = copy(lateral); noStamp.sampleMS=nil
    remote(P.buildRemotePath(noStamp,latest,straight),350,95,30,0,true,
        "missing baseline duration falls back to current speed and heading")
    local seamBefore = {x=10,y=30,heading=tau-0.05,speed=100,sampleMS=0,status="running"}
    local seamNow = copy(latest); seamNow.heading=0.05
    local seam = P.buildRemotePath(seamBefore,seamNow,straight)
    local _,_,seamHeading = P.remotePose(seam,500)
    near(seamHeading,0.15,"remote yaw follows the short arc across zero")
    seamBefore.heading=-3
    local turning = P.buildRemotePath(seamBefore,seamNow,straight)
    local _,_,turnHeading = P.remotePose(turning,500)
    near(turnHeading,0.05+3.0/2,"remote heading rate is bounded")
    local agileYaw=dofile("addon/AzerothKart/Physics.lua").GetHandling("dwarven_biker").steerRate
    local agileBefore=copy(older); agileBefore.heading=seamNow.heading-agileYaw/2
    local agilePath=P.buildRemotePath(agileBefore,seamNow,straight)
    local _,_,agileHeading=P.remotePose(agilePath,500)
    near(agileHeading,seamNow.heading+agileYaw/2,
        "observed agile turning stays within the forecast bound without underprediction")

    -- At constant angular velocity the previous interval's displacement is a
    -- chord, not the velocity at the latest sample. Correcting it must preserve
    -- both the current tangent and a steady drift offset from kart facing.
    local function turnObservation(seconds,slip)
        local angle=seconds*2.6
        return {x=200/2.6*math.sin(angle),y=200/2.6*(1-math.cos(angle)),
            heading=angle+(slip or 0),speed=200,sampleMS=seconds*1000,status="running"}
    end
    local turnError
    for _,slip in ipairs({0,0.4}) do
        local a,b=turnObservation(0,slip),turnObservation(0.5,slip)
        local target=turnObservation(0.85,slip)
        local x,y=P.remotePose(P.buildRemotePath(a,b,straight,1000),350)
        local error=math.sqrt((x-target.x)^2+(y-target.y)^2)
        assert(error<2,"a steady turn forecast follows the current tangent rather than the old chord")
        assert(a.x==0 and a.y==0 and b.sampleMS==500 and b.heading==1.3+slip,
            "turn correction does not write the source observations")
        turnError=error
    end

    -- Replay actual display paths, not a substitute implementation: 2Hz source
    -- packets arrive 350ms later and the canvas renders at60Hz. The old 500ms
    -- horizon expires only150ms after receipt, causing hold/jump cycles even
    -- with perfect constant motion. Covering the next interval removes them.
    local function straightMetric(horizon)
        local function observation(ms)
            return {x=ms*0.2,y=0,heading=0,speed=200,sampleMS=ms,status="running"}
        end
        local sample,path,lastX,held,maxStep,maxError=nil,nil,nil,0,0,0
        for frame=51,300 do
            local now=frame*1000/60
            local latest=math.floor((now-350)/500)*500
            if latest~=sample then
                sample=latest
                path=P.buildRemotePath(observation(sample-500),observation(sample),straight,horizon)
            end
            local x=P.remotePose(path,now-sample)
            if lastX then
                local distance=math.abs(x-lastX)
                if distance<1e-8 then held=held+1 end
                maxStep=math.max(maxStep,distance)
            end
            maxError=math.max(maxError,math.abs(x-now*0.2))
            lastX=x
        end
        return held,maxStep,maxError
    end
    local oldHeld,oldStep,oldError=straightMetric(nil)
    local held,step,error=straightMetric(950)
    assert(oldHeld>150 and oldStep>69 and oldError>66,
        "the retained legacy horizon reproduces the source freeze/jump defect")
    assert(held==0 and step<=200/60+1e-8 and error<1e-7,
        "bounded extended paths remove healthy-stream freezes without adding receive delay")
    print(("offline remote replay (synthetic 2Hz/350ms/60Hz): held=%d->%d maxStep=%.3f->%.3f peakError=%.3f->%.3f; steady-turn error=%.3f"):format(
        oldHeld,held,oldStep,step,oldError,error,turnError))

    -- Steering begins/ends between packets. Replacing the old forecast can
    -- otherwise jump by most of a turn even though its ordinary frames move
    -- smoothly. Angular reconciliation limits that discontinuity; translation
    -- remains the exact forecast above, without an interpolation delay.
    local function steeringObservation(ms)
        local seconds,yaw = ms/1000,2.6
        local turning = math.max(0,math.min(seconds-0.55,0.9))
        local angle = yaw*turning
        local x,y
        if seconds<=0.55 then x,y=200*seconds,0
        else
            x,y=110+200/yaw*math.sin(angle),200/yaw*(1-math.cos(angle))
            local after=math.max(0,seconds-1.45)
            x,y=x+200*after*math.cos(angle),y+200*after*math.sin(angle)
        end
        return {x=x,y=y,heading=angle,speed=200,sampleMS=ms,status="running"}
    end
    local sample,headingPath,lastRaw,shown,maxRaw,maxShown=nil,nil,nil,nil,0,0
    for frame=21,180 do
        local now=frame*1000/60
        local newest=math.floor((now-350+1e-8)/500)*500
        if newest~=sample then
            sample=newest
            headingPath=P.buildRemotePath(steeringObservation(sample-500),steeringObservation(sample),straight,950)
        end
        local x,y,target=P.remotePose(headingPath,now-sample)
        local nextShown=P.remoteHeading(shown,target,1000/60)
        if lastRaw then maxRaw=math.max(maxRaw,math.abs((target-lastRaw+pi)%tau-pi)) end
        if shown then maxShown=math.max(maxShown,math.abs((nextShown-shown+pi)%tau-pi)) end
        local checkX,checkY=P.remotePose(headingPath,now-sample)
        assert(checkX==x and checkY==y,"angular reconciliation cannot alter forecast position")
        lastRaw,shown=target,nextShown
    end
    assert(maxRaw>1.8,"steering onset/release reproduces the packet-sized angular correction")
    assert(maxShown<=6/60+1e-10 and maxShown<maxRaw/10,
        "angular reconciliation bounds each rendered correction at six radians/second")
    print(("offline remote steering (synthetic 2Hz/350ms/60Hz): maxHeadingStepDegrees=%.3f->%.3f"):format(
        maxRaw*180/pi,maxShown*180/pi))

    near(P.remoteHeading(nil,1,16),1,"missing previous heading initializes at the target")
    near(P.remoteHeading(tau-0.05,0.05,20),tau+0.05,"reconciliation crosses zero on the short arc")
    near(P.remoteHeading(0,pi,10),-0.06,"an exact half-turn uses the negative arc")
    near(P.remoteHeading(0,2,1e9),0.6,"one slow render cannot apply more than 100ms correction")
    near(P.remoteHeading(2,0,-100),2,"negative elapsed time cannot turn backwards in time")
    near(P.remoteHeading(0,0.01,100),0.01,"small errors reach their target without overshoot")
    local extremeHeading=P.remoteHeading(-1e308,1e308,100)
    assert(extremeHeading==extremeHeading and extremeHeading>-math.huge and extremeHeading<math.huge,
        "finite accumulated headings cannot overflow their shortest-arc subtraction")
    near(P.remoteHeading(2,0,0),2,"zero elapsed time preserves the shown heading")
    near(P.remoteHeading(2,0,nil),2,"missing elapsed time preserves the shown heading")
    for _,invalid in ipairs({0/0,math.huge,-math.huge,false,"16",{}}) do
        assert(P.remoteHeading(0,invalid,16)==nil,"invalid targets return no display heading")
        near(P.remoteHeading(invalid,1,16),1,"invalid previous headings safely initialize at target")
        near(P.remoteHeading(2,0,invalid),2,"invalid elapsed time cannot snap a valid heading")
    end
    assert(P.remoteHeading(0,nil,16)==nil,"missing target returns no display heading")
    assert(select("#",P.remoteHeading(0,1,16))==1,"angular reconciliation returns one scalar")

    local cx,cy=P.remoteCorrection(30,40,0)
    near(cx,30,"same clock preserves positional error x"); near(cy,40,"same clock preserves positional error y")
    local nx,ny=P.remoteCorrection(cx,cy,1000/60)
    assert(nx>0 and ny>0 and nx<cx and ny<cy and math.abs(nx/ny-3/4)<1e-9,
        "positional correction approaches the target without changing direction or overshoot")
    assert(math.sqrt((nx-cx)^2+(ny-cy)^2)<=400/60+1e-8,
        "correction velocity is bounded independently of packet error")
    for _=1,60 do cx,cy=P.remoteCorrection(cx,cy,1000/60) end
    assert(cx==0 and cy==0,"a settled correction has no permanent display delay")
    cx,cy=P.remoteCorrection(1e3,0,1e9)
    near(cx,960,"a render hitch consumes at most100ms correction"); near(cy,0,"no orthogonal error")
    for _,invalid in ipairs({0/0,math.huge,-math.huge,false,"16",{}}) do
        cx,cy=P.remoteCorrection(30,40,invalid)
        assert(cx==30 and cy==40,"invalid time cannot advance positional error")
        cx,cy=P.remoteCorrection(invalid,40,16)
        assert(cx==0 and cy==0,"invalid position does not create an offset")
    end
    assert(select("#",P.remoteCorrection(30,40,16))==2,"positional correction returns only scalars")

    local floorCalls=0
    local floorTrack={layered=true,resolveMovement=function(x,y,tx,ty,level)
        assert(level==1,"forecast collision uses the observed floor, not the default")
        floorCalls=floorCalls+1
        if tx>=80 then return tx,ty,false,0 end
        return tx,ty,false,1
    end}
    local onFloor={x=60,y=30,heading=0,speed=100,sampleMS=500,status="running",level=1}
    local floorPath=P.buildRemotePath(nil,onFloor,floorTrack)
    local fx,fy=P.remotePose(floorPath,500)
    assert(floorCalls>0 and floorPath.level==1 and fx<80 and fy==30,
        "an estimated peer stops before a ramp switch until an explicit new-floor packet arrives")
    assert(onFloor.level==1 and onFloor.x==60,"forecast cannot switch the received floor")

    local wall = {resolveMovement=function(x,y,tx,ty)
        assert(math.sqrt((tx-x)^2+(ty-y)^2)<=260/60+1e-9,"small projection sweep")
        return math.min(tx,100),ty,tx>100
    end}
    remote(P.buildRemotePath(older,latest,wall),500,100,30,0,true,
        "a forecast freezes at the first resolved wall contact")
    remote(P.buildRemotePath(older,latest,wall,1250),1250,100,30,0,true,
        "a longer horizon still freezes at the first wall instead of sliding onward")
    local turningAtWall = copy(latest); turningAtWall.heading=0.5
    local solid = {resolveMovement=function(x,y) return x,y,true end}
    local wallTurn = P.buildRemotePath(older,turningAtWall,solid,1250)
    assert(#wallTurn.points==2,"turning does not add movement sweeps after a wall stops translation")
    remote(wallTurn,500,60,30,1,true,"wall contact retains bounded observed turning")
    remote(wallTurn,5000,60,30,1.75,true,"wall turning freezes at the same stale horizon")
    local road = {isDrivable=function(x,y) return x<=95 end}
    local roadPath = P.buildRemotePath(older,latest,road)
    local roadX = P.remotePose(roadPath,500)
    assert(roadX<=95 and roadX>=95-100/60,"road-only fallback never projects an outside endpoint")
    local clamped = {resolveMovement=function(x,y,tx,ty) return tx-1,ty,false end}
    local clampPath = P.buildRemotePath(older,latest,clamped)
    assert(#clampPath.points==2,"a geometry clamp freezes even without an explicit hit flag")
    local badResolver = {resolveMovement=function() return 0/0,math.huge,false end}
    remote(P.buildRemotePath(older,latest,badResolver),500,60,30,0,false,
        "nonfinite geometry output falls back to the last valid point")
    local recovery = {resolveMovement=function() return 5000,30,true end}
    remote(P.buildRemotePath(older,latest,recovery),500,60,30,0,false,
        "far recovery cannot become a projected teleport")
    local Oval = dofile("addon/AzerothKart/Track.lua")
    local nearCrate = {x=240,y=410,heading=0,speed=200,sampleMS=500,status="running"}
    local cratePath = P.buildRemotePath(nil,nearCrate,Oval)
    local crateX,crateY = P.remotePose(cratePath,500)
    near(crateX,252,"actual Oval sweep stops at the crate's expanded west face")
    near(crateY,410,"actual Oval sweep retains the observed lane")

    for _,status in ipairs({"finished","stopped","stale"}) do
        local terminal = copy(latest); terminal.status=status
        remote(P.buildRemotePath(older,terminal,straight),500,60,30,0,false,
            "non-running observations stay frozen")
        remote(P.buildRemotePath(older,terminal,straight,1250),5000,60,30,0,false,
            "extended horizons never predict beyond a terminal observation")
    end
    local stopped = copy(latest); stopped.speed=0
    remote(P.buildRemotePath(older,stopped,straight),500,60,30,0,false,"zero speed without observed yaw stays frozen")
    stopped.heading=0.5
    local stoppedBefore = copy(stopped)
    local stoppedTurn = P.buildRemotePath(older,stopped,straight,1250)
    assert(#stoppedTurn.points==1,"stationary turning allocates no movement forecast")
    remote(stoppedTurn,0,60,30,0.5,false,"stationary zero age is exactly the observation")
    remote(stoppedTurn,350,60,30,0.85,true,"stationary steering predicts heading without translation")
    remote(stoppedTurn,5000,60,30,1.75,true,"stationary yaw freezes at the bounded stale horizon")
    remote(P.buildRemotePath(older,stopped,straight),5000,60,30,1,true,
        "stationary yaw retains the original default horizon")
    for key,value in pairs(stoppedBefore) do assert(stopped[key]==value,"stationary source stays read-only") end
    for _,status in ipairs({"finished","stopped","stale"}) do
        local terminal=copy(stopped); terminal.status=status
        remote(P.buildRemotePath(older,terminal,straight,1250),5000,60,30,0.5,false,
            "terminal heading never continues a previous turn")
    end
    for _,invalid in ipairs({0/0,math.huge,-math.huge,false,"100"}) do
        local badSpeed = copy(latest); badSpeed.speed,badSpeed.heading=invalid,0.5
        remote(P.buildRemotePath(older,badSpeed,straight),500,60,30,0.5,false,
            "invalid speed stays finite and frozen")
        for _,field in ipairs({"x","y","heading"}) do
            local malformed = copy(latest); malformed[field]=invalid
            remote(P.buildRemotePath(older,malformed,straight),500,10,30,0,false,
                "invalid pose falls back to the previous valid observation")
        end
    end
    local absentStatus = copy(latest); absentStatus.status=nil
    remote(P.buildRemotePath(older,absentStatus,straight),500,60,30,0,false,"unknown status stays frozen")
    remote(P.buildRemotePath(nil,latest,{}),500,60,30,0,false,"missing geometry stays frozen")
    assert(P.buildRemotePath(nil,{x=0/0,y=0,heading=0},straight)==nil,
        "no valid observation draws no invented pose")
    assert(P.remotePose(nil,500)==nil and P.remotePose({points={{x=0/0,y=0,heading=0}}},500)==nil,
        "invalid paths never return NaN to the renderer")
    print("offline remote presentation: default 500ms/31 points, optional 1250ms/76 points, wall/solid translation stops, bounded independent yaw, read-only observations and scalar angular reconciliation")
end

local config = dofile("addon/AzerothKart/Physics.lua")
local state = {surface="road", drifting=true, driftTicks=29, driftTier=2, boostTicks=0, driftGraceTicks=0}
local function meter(ticks, fraction, phase)
    state.driftTicks = ticks
    local actualFraction, actualPhase = P.meter(state, config)
    near(actualFraction, fraction, "meter fraction at " .. ticks)
    assert(actualPhase == phase, "meter phase at " .. ticks)
end
-- Read actual ticks rather than a possibly stale/inconsistent driftTier.
meter(0, 0, "idle")
meter(29, 29/60, "charging")
meter(30, 30/60, "tier1")
meter(59, 59/60, "tier1")
meter(60, 1, "tier2")
meter(500, 1, "tier2")
state.driftGraceTicks = 1
meter(30, 0.5, "holding")
state.driftGraceTicks = 12
meter(60, 1, "holding")
state.driftGraceTicks = 0
state.drifting = false
meter(60, 0, "idle")
for _, remaining in ipairs({config.BOOST_TIER1_TICKS-1, config.BOOST_TIER2_TICKS-1,
        config.BOOST_TIER2_TICKS, config.BOOST_TIER2_TICKS+20}) do
    state.boostTicks = remaining
    local fraction, phase = P.meter(state, config)
    near(fraction, math.min(1, remaining/config.BOOST_TIER2_TICKS), "shared boost capacity")
    assert(phase == "boost", "boost takes precedence over charge")
end
state.boostTicks = 0
meter(60, 0, "idle")
for _, surface in ipairs({"grass", "wall"}) do
    state.surface, state.drifting, state.boostTicks = surface, true, 47
    local fraction, phase = P.meter(state, config)
    assert(fraction == 0 and phase == "idle", "surface cancellation clears the meter")
end
local track = dofile("addon/AzerothKart/Track.lua")
local freshState = config.new(track)
local fraction, phase = P.meter(freshState, config)
assert(fraction == 0 and phase == "idle", "fresh drive starts with an empty meter")
state.surface = "road"
local snapshot = {}
for key, value in pairs(state) do snapshot[key] = value end
assert(select("#", P.meter(state, config)) == 2, "meter returns exactly two scalars")
for key, value in pairs(state) do assert(snapshot[key] == value, "meter preserves state") end
for key, value in pairs(snapshot) do assert(state[key] == value, "meter retains every state field") end
assert(config.DRIFT_TIER1_TICKS == 30 and config.DRIFT_TIER2_TICKS == 60
       and config.BOOST_TIER2_TICKS == 78, "meter preserves injected configuration")

-- Kart sprite registry and the shipped TGA bytes. This checks the packaging
-- contract and offline alpha only; client loading, filtering and facing are
-- separate in-game checks.
assert(P.KART_FOOTPRINT_WIDTH == 17 and P.KART_FOOTPRINT_HEIGHT == 31,
       "sprite body matches the primitive footprint and the 18-unit wall clearance")
near(P.KART_FOOTPRINT_WIDTH * camera.scale, 25.5, "sprite body width at the close camera")
assert(type(P.KART_SPRITES[P.DEFAULT_KART]) == "table", "the default kart sprite is registered")
local function powerOfTwo(value)
    if type(value) ~= "number" or value < 1 or value % 1 ~= 0 then return false end
    while value > 1 do
        if value % 2 ~= 0 then return false end
        value = value / 2
    end
    return true
end
local addonPrefix = "Interface\\AddOns\\AzerothKart\\"
local spriteFiles = 0
local coverageFloors = {goblin_mortar_trike=0.12, steam_tank=0.12,
    dwarven_biker=0.12, gryphon_rider=0.025, gyrocopter=0.06,  -- the gryphon: wings tucked, in a 58-unit window
    dwarf_car=0.10, orc_demolisher=0.10, meat_wagon=0.10, glaive_thrower=0.10,
    goblin_drag_car=0.08} -- the pod racer: two pods and a cart, open between them
for id, sprite in pairs(P.KART_SPRITES) do
    local w, h = sprite.textureWidth, sprite.textureHeight
    assert(type(sprite.path) == "string" and sprite.path:sub(1, #addonPrefix) == addonPrefix
           and sprite.path:find("\\Assets\\Karts\\[%w]+%.tga$"), id .. ": addon kart TGA path")
    assert(powerOfTwo(w) and powerOfTwo(h), id .. ": power-of-two texture")
    assert(w * sprite.quadHeight == h * sprite.quadWidth, id .. ": square texels in world units")
    assert(sprite.quadWidth >= P.KART_FOOTPRINT_WIDTH and sprite.quadHeight >= P.KART_FOOTPRINT_HEIGHT,
           id .. ": quad pads the body rather than cropping it")
    local file = assert(io.open("addon/AzerothKart/" .. (sprite.path:sub(#addonPrefix + 1):gsub("\\", "/")),
                                "rb"), id .. ": declared sprite file exists in the addon")
    local data = file:read("*a")
    file:close()
    local function u16(index) return data:byte(index) + 256 * data:byte(index + 1) end
    assert(data:byte(1) == 0 and data:byte(2) == 0 and data:byte(3) == 2 and u16(13) == w
           and u16(15) == h and data:byte(17) == 32 and data:byte(18) == 8,
           id .. ": uncompressed BGRA32, eight alpha bits, bottom-left origin")
    assert(#data == 18 + w * h * 4, id .. ": exact payload size")
    local function alpha(column, rowFromTop)
        return data:byte(18 + ((h - 1 - rowFromTop) * w + column) * 4 + 4)
    end
    if sprite.frames then
        -- Directional sheet: an even grid of square frames (a sheet with
        -- phases holds every heading once per phase, phase after phase), each
        -- with a transparent border so filtering never pulls in a neighbor, a
        -- substantial vehicle, and distinct pictures for opposite headings and
        -- for one heading's phases.
        local columns, frames, phases = sprite.columns, sprite.frames, sprite.phases or 1
        local rows = frames * phases / columns
        assert(phases % 1 == 0 and phases >= 1 and (frames * phases) % columns == 0 and w % columns == 0
               and h % rows == 0, id .. ": even frame grid")
        local fw, fh = w / columns, h / rows
        assert(fw == fh and fw / sprite.quadWidth == fh / sprite.quadHeight, id .. ": square frames and texels")
        assert(type(sprite.pivotX) == "number" and type(sprite.pivotY) == "number", id .. ": frame pivot")
        local function origin(phase, frame)
            local index = phase * frames + frame
            return (index % columns) * fw, math.floor(index / columns) * fh
        end
        local fewest, most = fw * fh, 0
        for phase = 0, phases - 1 do
            for frame = 0, frames - 1 do
                local ox, oy = origin(phase, frame)
                local solid = 0
                for row = 0, fh - 1 do
                    for column = 0, fw - 1 do
                        local a = alpha(ox + column, oy + row)
                        if row == 0 or column == 0 or row == fh - 1 or column == fw - 1 then
                            assert(a == 0, id .. ": frame " .. frame .. " keeps a transparent border")
                        end
                        if a == 255 then solid = solid + 1 end
                    end
                end
                -- Thin flyers have explicit lower floors; ground kart coverage
                -- must not regress when a new aircraft is registered.
                local floor = assert(coverageFloors[id], id .. ": directional coverage floor declared")
                assert(solid > floor * fw * fh, id .. ": frame " .. frame .. " shows the vehicle")
                fewest, most = math.min(fewest, solid), math.max(most, solid)
                local l, r, top, b = P.kartFrameCoords(sprite, frame, phase)
                assert(math.abs(l - ox / w) < 1e-12 and math.abs(r - (ox + fw) / w) < 1e-12 and
                       math.abs(top - oy / h) < 1e-12 and math.abs(b - (oy + fh) / h) < 1e-12,
                       id .. ": frame " .. frame .. " of phase " .. phase .. " crop matches the sheet layout")
                if phase == 0 then
                    local l0, r0, t0, b0 = P.kartFrameCoords(sprite, frame)
                    assert(l0 == l and r0 == r and t0 == top and b0 == b, id .. ": the default crop is phase 0")
                end
            end
        end
        local function differ(phase, frame, otherPhase, other)
            local ox, oy = origin(phase, frame)
            local px, py = origin(otherPhase, other)
            for row = 0, fh - 1 do
                for column = 0, fw - 1 do
                    if alpha(ox + column, oy + row) ~= alpha(px + column, py + row) then return true end
                end
            end
            return false
        end
        for phase = 0, phases - 1 do
            for frame = 0, frames / 2 - 1 do
                assert(differ(phase, frame, phase, frame + frames / 2),
                       id .. ": opposite headings " .. frame .. "/" .. frame + frames / 2 .. " are different pictures")
            end
            for other = phase + 1, phases - 1 do
                for frame = 0, frames - 1 do
                    assert(differ(phase, frame, other, frame),
                           id .. ": phases " .. phase .. "/" .. other .. " at heading " .. frame .. " differ")
                end
            end
        end
        -- Heading lookup: east is frame 0, counter-clockwise, nearest frame, any turn count.
        local step = 2 * math.pi / frames
        assert(P.kartFrame(sprite, 0) == 0 and P.kartFrame(sprite, math.pi / 2) == frames / 4 and
               P.kartFrame(sprite, math.pi) == frames / 2 and P.kartFrame(sprite, -math.pi / 2) == 3 * frames / 4,
               id .. ": cardinal headings map to their frames")
        assert(P.kartFrame(sprite, 0.49 * step) == 0 and P.kartFrame(sprite, 0.51 * step) == 1 and
               P.kartFrame(sprite, -0.49 * step) == 0 and P.kartFrame(sprite, -0.51 * step) == frames - 1 and
               P.kartFrame(sprite, 2 * math.pi + step) == 1 and P.kartFrame(sprite, -4 * math.pi + 2 * step) == 2,
               id .. ": nearest frame with wrap-around")
        spriteFiles = spriteFiles + 1
        print(("offline kart sheet %s: %dx%d TGA, %d x %d frames of %dx%d, %d-%d opaque texels per frame")
            :format(id, w, h, phases, frames, fw, fh, fewest, most))
    else
        local perUnit = w / sprite.quadWidth
        local halfW, halfH = P.KART_FOOTPRINT_WIDTH * perUnit / 2, P.KART_FOOTPRINT_HEIGHT * perUnit / 2
        local visible, solid = 0, 0
        local left, right, top, bottom = w, -1, h, -1
        for row = 0, h - 1 do
            for column = 0, w - 1 do
                local a = alpha(column, row)
                if a > 0 then
                    assert(math.abs(column + 0.5 - w / 2) <= halfW and math.abs(row + 0.5 - h / 2) <= halfH,
                           id .. ": visible texels stay inside the 17x31 body")
                    assert(column > 0 and column < w - 1 and row > 0 and row < h - 1,
                           id .. ": a transparent border protects filtered edges")
                    visible = visible + 1
                    if a == 255 then solid = solid + 1 end
                    left, right = math.min(left, column), math.max(right, column)
                    top, bottom = math.min(top, row), math.max(bottom, row)
                end
            end
        end
        assert(solid > 0.4 * 4 * halfW * halfH, id .. ": substantial opaque silhouette")
        assert(math.abs((left + right + 1) / 2 - w / 2) <= 0.5 and math.abs((top + bottom + 1) / 2 - h / 2) <= 1,
               id .. ": silhouette centered on the quad (kart pivot)")
        spriteFiles = spriteFiles + 1
        print(("offline kart sprite %s: %dx%d TGA, %d visible/%d opaque texels inside %dx%d body")
            :format(id, w, h, visible, solid, P.KART_FOOTPRINT_WIDTH, P.KART_FOOTPRINT_HEIGHT))
    end
end
assert(spriteFiles >= 1, "at least one kart sprite is validated")

-- The player's optional outline (Settings): every directional sheet names a
-- half-resolution outline sheet of the same frames and phases (512x512 for
-- the usual sheet; build_kart_outlines.py).
-- White so the UI tints it; a clear border per frame; a line in every frame
-- that never covers the kart's body (texels at least half opaque).
do
    local O = P.KART_OUTLINE
    assert(type(O) == "table" and O.textureWidth == 512 and O.textureHeight == 512 and #O.color == 3,
           "outline sheet size and tint declared")
    for _, c in ipairs(O.color) do assert(c >= 0 and c <= 1, "outline tint is a colour") end
    local function read(path)
        local file = assert(io.open("addon/AzerothKart/" .. (path:sub(#addonPrefix + 1):gsub("\\", "/")), "rb"),
                            path .. ": declared file exists in the addon")
        local data = file:read("*a")
        file:close()
        return data
    end
    local outlines = 0
    for id, sprite in pairs(P.KART_SPRITES) do
        if sprite.frames then
            local file = sprite.path:match("([%w]+%.tga)$")
            assert(sprite.outline == addonPrefix .. "Assets\\Karts\\Outlines\\" .. file,
                   id .. ": the outline sheet shares the kart sheet's name")
            local data, kart = read(sprite.outline), read(sprite.path)
            local w, h = sprite.textureWidth / 2, sprite.textureHeight / 2
            assert(sprite.phases or (w == O.textureWidth and h == O.textureHeight), id .. ": the usual 512x512 outline")
            local function u16(index) return data:byte(index) + 256 * data:byte(index + 1) end
            assert(data:byte(3) == 2 and u16(13) == w and u16(15) == h and data:byte(17) == 32 and
                   data:byte(18) == 8 and #data == 18 + w * h * 4, id .. ": outline BGRA32, bottom-left, half size")
            local kw, kh = sprite.textureWidth, sprite.textureHeight
            local function kartAlpha(column, rowFromTop)
                return kart:byte(18 + ((kh - 1 - rowFromTop) * kw + column) * 4 + 4)
            end
            local cells = sprite.frames * (sprite.phases or 1)
            local fw, fh = w / sprite.columns, h / (cells / sprite.columns)
            local fewest = fw * fh
            for frame = 0, cells - 1 do
                local ox, oy = (frame % sprite.columns) * fw, math.floor(frame / sprite.columns) * fh
                local lit = 0
                for row = 0, fh - 1 do
                    local base = 18 + (h - 1 - (oy + row)) * w * 4
                    for column = 0, fw - 1 do
                        local at = base + (ox + column) * 4
                        local a = data:byte(at + 4)
                        if row == 0 or column == 0 or row == fh - 1 or column == fw - 1 then
                            assert(a == 0, id .. ": outline frame " .. frame .. " keeps a clear border")
                        end
                        if a > 0 then
                            lit = lit + 1
                            assert(data:byte(at + 1) == 255 and data:byte(at + 2) == 255 and data:byte(at + 3) == 255,
                                   id .. ": the outline is white, for the UI's tint")
                            local kx, ky = 2 * (ox + column), 2 * (oy + row)
                            assert(math.min(kartAlpha(kx, ky), kartAlpha(kx + 1, ky), kartAlpha(kx, ky + 1),
                                            kartAlpha(kx + 1, ky + 1)) < 128,
                                   id .. ": outline frame " .. frame .. " never covers the kart")
                        end
                    end
                end
                assert(lit > 0, id .. ": outline frame " .. frame .. " has a line")
                fewest = math.min(fewest, lit)
            end
            outlines = outlines + 1
            print(("offline kart outline %s: %dx%d white TGA, at least %d lit texels per frame"):format(id, w, h, fewest))
        end
    end
    assert(outlines >= 1, "at least one outline sheet is validated")
end

-- Wing phases: a winged sheet beats its wings on a clock and glides on
-- request; every other sheet stays in its one pose. Pure: nothing is read
-- from the simulation, and the crops follow the sheet's phase layout.
do
    local gryphon = P.KART_SPRITES.gryphon_rider
    local wings = gryphon.wings
    assert(gryphon.phases == 4 and gryphon.columns == 16 and gryphon.textureWidth == 2048 and
           gryphon.textureHeight == 2048, "the gryphon's sheet holds four phases, 16 frames a row")
    assert(type(wings) == "table" and wings.beat > 0 and wings.glide == 3 and #wings.cycle == 4,
           "the gryphon's wings: a beat, its steps and a glide")
    for _, phase in ipairs(wings.cycle) do
        assert(phase >= 0 and phase < gryphon.phases and phase ~= wings.glide, "the beat's steps are flying poses")
    end
    for id, sprite in pairs(P.KART_SPRITES) do
        if id ~= "gryphon_rider" then
            assert(sprite.wings == nil and sprite.phases == nil, id .. ": one pose")
            for _, time in ipairs({0, 0.2, 0.4, 7.5}) do
                assert(P.wingPhase(sprite, time, false) == 0 and P.wingPhase(sprite, time, true) == 0,
                       id .. ": no wings, always the rest pose")
            end
        end
    end
    local beat, step = wings.beat, wings.beat / 4
    local seen = {}
    for n = 0, 7 do
        local time = (n + 0.5) * step
        seen[#seen + 1] = P.wingPhase(gryphon, time, false)
    end
    assert(table.concat(seen, ",") == "0,1,0,2,0,1,0,2", "one beat: rest, top, rest, bottom, again: " .. table.concat(seen, ","))
    assert(P.wingPhase(gryphon, 0, false) == 0 and P.wingPhase(gryphon, beat * 100 + 1.5 * step, false) == 1,
           "the beat starts at rest and repeats")
    assert(P.wingPhase(gryphon, -0.5 * step, false) == 2, "before zero the beat runs on backwards")
    for _, time in ipairs({0, step * 1.5, step * 3.5, 1e6}) do
        assert(P.wingPhase(gryphon, time, true) == wings.glide, "gliding holds the glide at any time")
    end
    assert(P.wingPhase(gryphon, 0 / 0, false) == 0 and P.wingPhase(gryphon, math.huge, false) == 0
           and P.wingPhase(gryphon, nil, false) == 0 and P.wingPhase(nil, 1, false) == 0,
           "an unreadable time or sheet gives the rest pose")
    local l, r, t, b = P.kartFrameCoords(gryphon, 63, 3)
    assert(l == 15 / 16 and r == 1 and t == 15 / 16 and b == 1, "the glide's last heading is the sheet's last cell")
    l, r, t, b = P.kartFrameCoords(gryphon, 5, 1)
    assert(l == 5 / 16 and r == 6 / 16 and t == 4 / 16 and b == 5 / 16, "phase 1 starts on the sheet's fifth row")
    l, r, t, b = P.kartFrameCoords(P.KART_SPRITES.steam_tank, 9)
    assert(l == 1 / 8 and r == 2 / 8 and t == 1 / 8 and b == 2 / 8, "a one-pose sheet keeps its 8x8 layout")
    print("offline presentation: the gryphon's wing phases (beat 0,1,0,2 every " .. beat .. "s, glide 3), crops")
end

-- Drift and boost effects: the shipped atlases match Presentation.EFFECTS, and
-- the particle logic follows drift/boost state without writing it. Offline
-- only; client loading, blending and look are in-game checks.
do
    local E = P.EFFECTS
    local function atlas(path, w, h)
        assert(path:sub(1, #addonPrefix) == addonPrefix and path:find("\\Assets\\Effects\\[%w]+%.tga$"),
               path .. ": addon effect TGA path")
        assert(powerOfTwo(w) and powerOfTwo(h), path .. ": power-of-two texture")
        local file = assert(io.open("addon/AzerothKart/" .. (path:sub(#addonPrefix + 1):gsub("\\", "/")), "rb"),
                            path .. ": declared effect atlas exists in the addon")
        local data = file:read("*a")
        file:close()
        local function u16(index) return data:byte(index) + 256 * data:byte(index + 1) end
        assert(data:byte(1) == 0 and data:byte(3) == 2 and u16(13) == w and u16(15) == h and data:byte(17) == 32
               and data:byte(18) == 8 and #data == 18 + w * h * 4, path .. ": BGRA32, bottom-left, declared size")
        return function(column, rowFromTop) return data:byte(18 + ((h - 1 - rowFromTop) * w + column) * 4 + 4) end
    end
    local particleAlpha = atlas(E.particlesPath, E.particlesWidth, E.particlesHeight)
    local flameAlpha = atlas(E.flamePath, E.flameWidth, E.flameHeight)
    -- Each cell: the crop matches the layout, a transparent border, paint, and
    -- (for sparks and flames) alpha weighted toward the cell's direction.
    local function cell(alpha, kind, index, size, w, h, dx, dy)
        local l, r, top, b = P.effectCoords(kind, index)
        local ox, oy = l * w, top * h
        assert(ox % 1 == 0 and oy % 1 == 0 and math.abs((r - l) * w - size) < 1e-9
               and math.abs((b - top) * h - size) < 1e-9, kind .. " " .. index .. ": crop matches the atlas layout")
        local covered, mx, my = 0, 0, 0
        for row = 0, size - 1 do
            for column = 0, size - 1 do
                local a = alpha(ox + column, oy + row)
                if row == 0 or column == 0 or row == size - 1 or column == size - 1 then
                    assert(a == 0, kind .. " " .. index .. ": cell keeps a transparent border")
                end
                if a > 0 then
                    covered = covered + 1
                    mx = mx + ((column + 0.5) / size * 2 - 1) * a
                    my = my + (1 - (row + 0.5) / size * 2) * a
                end
            end
        end
        assert(covered > size * size / 40, kind .. " " .. index .. ": cell is painted")
        if dx then assert(mx * dx + my * dy > 0, kind .. " " .. index .. ": cell points along its direction") end
    end
    for index = 0, E.smokeVariants - 1 do
        cell(particleAlpha, "smoke", index, E.smokeCell, E.particlesWidth, E.particlesHeight)
    end
    for index = 0, E.sparkDirections - 1 do
        local angle = index * tau / E.sparkDirections
        cell(particleAlpha, "spark", index, E.sparkCell, E.particlesWidth, E.particlesHeight,
             math.cos(angle), math.sin(angle))
    end
    for index = 0, E.flameDirections - 1 do       -- the sheet camera foreshortens north by 0.8
        local angle = index * tau / E.flameDirections
        cell(flameAlpha, "flame", index, E.flameCell, E.flameWidth, E.flameHeight,
             math.cos(angle), 0.8 * math.sin(angle))
    end

    local trike = P.KART_SPRITES.goblin_mortar_trike.effects
    local options = {anchors = trike, dust = {0.9, 0.85, 0.8}, boostFullTicks = 48}
    local function live(fx, now)
        local smoke, sparks, newestSpark = 0, 0, nil
        for _, p in ipairs(fx.smoke) do if P.particleAt(p, now) then smoke = smoke + 1 end end
        for _, p in ipairs(fx.sparks) do
            if P.particleAt(p, now) then
                sparks = sparks + 1
                if not newestSpark or p.born > newestSpark.born then newestSpark = p end
            end
        end
        return smoke, sparks, newestSpark
    end
    -- Drive the effects tick by tick through a state script, checking that
    -- no state is ever written.
    local function run(fx, from, ticks, fields)
        local previous
        for tick = from, from + ticks - 1 do
            local state = {x = 500, y = 200 + 3 * tick, heading = math.pi / 2, tick = tick, speed = 180,
                           drifting = false, driftTier = 0, driftTicks = 0, driftGraceTicks = 0,
                           driftDirection = 0, boostTicks = 0, surface = "road"}
            for key, value in pairs(fields) do state[key] = type(value) == "function" and value(tick) or value end
            local before = {}
            for key, value in pairs(state) do before[key] = value end
            local now = P.advanceEffects(fx, previous, state, 1, options)
            assert(now == tick, "a stopped or exact frame draws at the current tick")
            for key, value in pairs(before) do assert(state[key] == value, "effects never write state: " .. key) end
            for key in pairs(state) do assert(before[key] ~= nil, "effects add no state fields: " .. key) end
            previous = state
        end
        return previous
    end
    local fx = P.newEffects()
    assert(#fx.smoke == E.smokeCount and #fx.sparks == E.sparkCount and #fx.flames == E.flameCount,
           "fixed effect pools")
    local last = run(fx, 1, 20, {})
    local smoke, sparks = live(fx, last.tick)
    assert(smoke == 0 and sparks == 0 and not fx.flames[1].on, "plain driving emits nothing")
    for tier = 0, 2 do
        last = run(fx, last.tick + 1, 12, {drifting = true, driftTier = tier, driftDirection = 1})
        local smokeNow, sparksNow, newest = live(fx, last.tick)
        assert(smokeNow > 0 and sparksNow > 0, "drift tier " .. tier .. " shows dust and sparks")
        local color = E.sparkColors[tier]
        assert(newest.r == color[1] and newest.g == color[2] and newest.b == color[3],
               "drift tier " .. tier .. " sparks use the meter's colour")
    end
    local _, sparks2 = live(fx, last.tick)
    -- Release: the first boost tick bursts soot from every exhaust; flames burn.
    local puffsBefore = fx.puffs
    last = run(fx, last.tick + 1, 1, {boostTicks = 48})
    assert(fx.puffs == puffsBefore + 2 * #trike.exhausts, "a fired boost bursts soot from every pipe")
    assert(fx.flames[1].on and fx.flames[2].on and fx.flames[1].cell == 24,
           "both pipes burn, pointing behind a north-facing kart (heading 3pi/2)")
    assert(fx.flames[1].front and fx.flames[2].front, "a north-facing kart shows its exhausts in front")
    -- Same tick (same flicker), less boost left: a smaller flame.
    local fading = P.newEffects()
    run(fading, last.tick, 1, {boostTicks = 6})
    assert(fading.flames[1].size < fx.flames[1].size, "the flame shrinks as the boost runs out")
    last = run(fx, last.tick + 1, 40, {boostTicks = 30})
    last = run(fx, last.tick + 1, 1, {boostTicks = 20, heading = -math.pi / 2})
    assert(fx.flames[1].cell == 8 and not fx.flames[1].front and not fx.flames[2].front,
           "a south-facing kart's flames point north, behind its body")
    last = run(fx, last.tick + 1, 1, {})
    assert(not fx.flames[1].on and not fx.flames[2].on, "flames stop with the boost")
    -- Effects age with ticks and fade out; the pools never grow.
    for _, p in ipairs(fx.smoke) do
        if p.on then
            local x, y, size, a = P.particleAt(p, p.born + 1)
            local x2, y2, size2, a2 = P.particleAt(p, p.born + p.life - 1)
            assert(size2 > size and a2 < a and P.particleAt(p, p.born + p.life + 0.001) == nil,
                   "puffs grow, fade and expire")
        end
    end
    assert(#fx.smoke == E.smokeCount and #fx.sparks == E.sparkCount, "pools keep their size")
    -- Interpolated frames sit between ticks; a new run (tick going back) clears.
    local previous = {x = 0, y = 0, heading = 0, tick = 99}
    local current = {x = 3, y = 0, heading = 0, tick = 100, boostTicks = 0}
    assert(P.advanceEffects(fx, previous, current, 0.25, options) == 99.25, "effect time follows the drawn pose")
    P.advanceEffects(fx, nil, {x = 0, y = 0, heading = 0, tick = 0}, 1, options)
    smoke, sparks = live(fx, 0)
    assert(smoke == 0 and sparks == 0 and not fx.flames[1].on, "a restarted run clears all effects")
    -- The same states give the same particles.
    local a, b = P.newEffects(), P.newEffects()
    for _, f in ipairs({a, b}) do
        run(f, 1, 30, {drifting = true, driftTier = 2, driftDirection = -1})
        run(f, 31, 10, {boostTicks = 48})
    end
    for _, pool in ipairs({"smoke", "sparks"}) do
        for i, p in ipairs(a[pool]) do
            for key, value in pairs(p) do assert(b[pool][i][key] == value, "deterministic effects: " .. key) end
        end
    end
    -- Overhead art has no near side; its flames burn behind the kart.
    local overhead = P.newEffects()
    local overheadOptions = {anchors = P.DEFAULT_EFFECT_ANCHORS, dust = options.dust, boostFullTicks = 48}
    P.advanceEffects(overhead, nil, {x = 0, y = 0, heading = math.pi / 2, tick = 1, boostTicks = 0}, 1, overheadOptions)
    P.advanceEffects(overhead, nil, {x = 0, y = 3, heading = math.pi / 2, tick = 2, boostTicks = 30}, 1, overheadOptions)
    assert(overhead.flames[1].on and not overhead.flames[1].front and not overhead.flames[2].on,
           "the primitive kart's single rear exhaust burns behind it")
    print(("offline effects: %dx%d particle and %dx%d flame atlases; %d smoke/%d spark pools; "
        .. "tier colours, boost flames and soot follow state without writing it (%d sparks at tier 2)")
        :format(E.particlesWidth, E.particlesHeight, E.flameWidth, E.flameHeight, E.smokeCount, E.sparkCount, sparks2))
end

-- Mirage background registration: the shipped TGA against the actual Lua
-- geometry. Interior road texels must stay darker than the 0.5-3 unit salt rim
-- outside every edge, so the painted boundary matches isDrivable. Offline bytes
-- only; client appearance is a separate in-game check.
do
    local Oval = dofile("addon/AzerothKart/Track.lua")
    local Mirage = dofile("addon/AzerothKart/MirageRaceway.lua").new(Oval.crossesGate)
    local file = assert(io.open("addon/AzerothKart/Assets/Tracks/SaltFlats/Background.tga", "rb"))
    local data = file:read("*a")
    file:close()
    local size = 1024
    assert(#data == 18 + size * size * 4 and data:byte(3) == 2 and data:byte(17) == 32
           and data:byte(18) == 8, "background stays an uncompressed bottom-left BGRA32 TGA")
    local line = Mirage.centerline
    local function centerDistance(px, py)
        local best = math.huge
        for i = 1, #line do
            local a, b = line[i], line[i % #line + 1]
            local dx, dy = b.x - a.x, b.y - a.y
            local u = math.max(0, math.min(1, ((px - a.x) * dx + (py - a.y) * dy) / (dx * dx + dy * dy)))
            local ox, oy = px - (a.x + u * dx), py - (a.y + u * dy)
            best = math.min(best, ox * ox + oy * oy)
        end
        return math.sqrt(best)
    end
    local function luma(x, y)
        local offset = 18 + (y * size + x) * 4
        return 0.299 * data:byte(offset + 3) + 0.587 * data:byte(offset + 2) + 0.114 * data:byte(offset + 1)
    end
    local road, rim = 0, 0
    for y = 0, size - 1, 3 do
        for x = 0, size - 1, 3 do
            local px, py = x + 0.5, y + 0.5
            local d = centerDistance(px, py)
            if Mirage.isDrivable(px, py) then
                local startLine = y >= 351 and y <= 368 and x >= 643 and x <= 756
                if d <= 44 and not startLine then
                    assert(luma(x, y) <= 180, ("painted road too light at (%d,%d)"):format(x, y))
                    road = road + 1
                end
            elseif d - 56 >= 0.5 and d - 56 <= 3 then
                assert(luma(x, y) >= 190, ("salt rim too dark at (%d,%d)"):format(x, y))
                rim = rim + 1
            end
        end
    end
    assert(road > 15000 and rim > 900, "registration samples cover the whole circuit")
    print(("offline Mirage background: %d road / %d rim samples agree with isDrivable"):format(road, rim))
end

-- Race standings: display estimates from each racer's own progress.
do
    -- A square course, four gates of 100 across, the start/finish the fourth.
    local course = {gates={
        {ax=400, ay=0, bx=400, by=100, nx=1, ny=0}, {ax=500, ay=400, bx=600, by=400, nx=0, ny=1},
        {ax=100, ay=500, bx=100, by=600, nx=-1, ny=0}, {ax=0, ay=100, bx=100, by=100, nx=0, ny=-1}}}
    -- Before the first gate, from the start line (the fourth's middle, 50,100):
    -- the fraction of the straight distance to gate 1.
    near(P.raceProgress(course, 0, 0, 50, 100), 0, "at the previous gate: no progress yet")
    near(P.raceProgress(course, 0, 0, 225, 50), 0.5, "halfway to the next gate: half")
    near(P.raceProgress(course, 0, 0, 400, 50), 0.999, "at the next gate's line: just short of it")
    local third = P.raceProgress(course, 0, 2, 300, 550)        -- 200 from gate 3, which is 461 from gate 2
    assert(third > 2.56 and third < 2.57, "two gates passed, then the fraction toward the third: " .. third)
    assert(P.raceProgress(course, 1, 0, 50, 100) == 4, "a completed lap counts every gate")
    assert(P.raceProgress(course, 0, 1, 600, 200) > P.raceProgress(course, 0, 0, 399, 50),
        "one more gate passed is further on, however near the other is to its gate")
    assert(P.raceProgress(course, 0, 0, -900, 900) == 0, "far behind the previous gate clamps at 0")
    for _, bad in ipairs({{course, -1, 0, 0, 0}, {course, 0, 4, 0, 0}, {course, 0, 1.5, 0, 0},
        {course, 0, 0, 0 / 0, 0}, {course, 0, 0, 0, math.huge}, {{gates={}}, 0, 0, 0, 0}, {nil, 0, 0, 0, 0}}) do
        assert(P.raceProgress(bad[1], bad[2], bad[3], bad[4], bad[5]) == nil, "unreadable progress is nil")
    end
    local one = {gates={{ax=0, ay=0, bx=0, by=100, nx=1, ny=0}}}
    assert(P.raceProgress(one, 0, 0, 50, 50) == 0, "a one-gate course has no fraction")

    -- Placing: finished first by tick, then racing by progress, then out.
    local finishedLate = {name="late", finishTicks=4000}
    local finishedEarly = {name="early", finishTicks=3900}
    local leading = {name="leading", progress=11.4}
    local trailing = {name="trailing", progress=9.2}
    local left = {name="left", progress=11.9, out=true}
    assert(P.ahead(finishedEarly, finishedLate) and not P.ahead(finishedLate, finishedEarly), "the earlier finish")
    assert(P.ahead(finishedLate, leading) and P.ahead(leading, trailing) and P.ahead(trailing, left),
        "finished, then racing by progress, then out, whatever the progress")
    assert(not P.ahead(leading, {progress=11.4}) and not P.ahead(left, {out=true}), "a tie is not ahead")
    local order = P.standings({left, trailing, finishedLate, leading, finishedEarly})
    local names = {}
    for index, racer in ipairs(order) do names[index] = racer.name .. racer.place end
    assert(table.concat(names, ",") == "early1,late2,leading3,trailing4,left5", "standings: " .. table.concat(names, ","))
    local a, b = {name="a", progress=3}, {name="b", progress=3}
    order = P.standings({a, b})
    assert(order[1] == a and order[2] == b and a.place == 1 and b.place == 2, "ties keep the given order")
    assert(#P.standings({}) == 0, "no racers, no standings")

    local ordinals = {}
    for _, n in ipairs({1, 2, 3, 4, 8, 11, 12, 13, 21, 22, 23, 101, 111}) do ordinals[#ordinals + 1] = P.ordinal(n) end
    assert(table.concat(ordinals, " ") == "1st 2nd 3rd 4th 8th 11th 12th 13th 21st 22nd 23rd 101st 111th",
        "ordinals: " .. table.concat(ordinals, " "))
    assert(P.ordinal(0) == "--" and P.ordinal(1.5) == "--" and P.ordinal(nil) == "--", "no ordinal for a non-place")
    print("offline presentation: race progress, placing (finished, racing, out) and ordinals")
end

-- Two-floor courses (Warsong Gulch): which karts draw over the roofs, each
-- roof's fade, its crop of the world-aligned roof picture, and the guiding arrow.
do
    local track = {ramps={{x=100, y=100, width=40, height=80}},
        gates={{name="A", ax=0, ay=200, bx=100, by=200}, {name="B", ax=300, ay=0, bx=300, by=100}}}
    assert(P.drawnHigh(track, 10, 10, 1) and P.drawnHigh(track, 120, 140, 0) and not P.drawnHigh(track, 10, 10, 0)
        and not P.drawnHigh({}, 120, 140, 0) and not P.drawnHigh(track, 0/0, 140, 0),
        "over the roofs: floor 1, or anywhere on a ramp")
    local roof = {x0=0, y0=0, x1=400, y1=400, under={{x0=100, y0=100, x1=200, y1=300}}}
    assert(P.roofAlpha(roof, 50, 50, false) == 1 and P.roofAlpha(roof, 150, 200, true) == 1,
        "a roof stands whole unless the player is on the ground under it")
    assert(math.abs(P.roofAlpha(roof, 150, 200, false) - P.ROOF_FADED) < 1e-12
        and math.abs(P.roofAlpha(roof, 112, 200, false) - (1 - 0.75 * 44 / 56)) < 1e-12
        and math.abs(P.roofAlpha(roof, 124, 200, false) - P.ROOF_FADED) < 1e-12,
        "it fades from 32 units before an under box to 24 units in, to a quarter")
    assert(math.abs(P.roofAlpha(roof, 150, 84, false) - (1 - 0.75 * 16 / 56)) < 1e-12
        and P.roofAlpha(roof, 150, 68, false) == 1 and P.roofAlpha(roof, 150, 40, false) == 1,
        "approaching a tunnel's mouth the cover starts to fade before the kart is under it")
    local view = P.cameraViewport(1024, 2048, 800, 480, 1.5)
    P.follow(view, 200, 200, 0, 0)
    local px, py, pw, ph, l, r, t, b = P.roofCrop(view, roof)
    -- The camera shows x 0..533, y 40..360: the roof's part in it.
    assert(px == 0 and py == 0 and math.abs(pw - 600) < 1e-9 and math.abs(ph - 480) < 1e-9,
        "the crop is placed on the canvas: " .. tostring(pw) .. "x" .. tostring(ph))
    assert(l == 0 and math.abs(r - 400 / 1024) < 1e-12 and math.abs(t - (1 - 360 / 2048)) < 1e-12
        and math.abs(b - (1 - 40 / 2048)) < 1e-12, "and cuts the matching part of the world-aligned picture")
    assert(P.roofCrop(view, {x0=900, y0=1900, x1=1000, y1=2000, under={}}) == nil, "a roof off the camera is not drawn")
    local heading, distance = P.guideHeading(track, {nextGate=2, passed=1, complete=false}, 300, 250)
    assert(math.abs(heading + math.pi / 2) < 1e-12 and math.abs(distance - 200) < 1e-12,
        "the arrow points at the middle of the next gate")
    assert(P.guideHeading(track, {nextGate=3, passed=2, complete=true}, 0, 0) == nil, "none once the lap is done")
    -- With a route, the arrow follows it: `ahead` units on from its nearest
    -- point, looked for between the previous gate's crossing and the next's.
    local route = {points={{x=0, y=0}, {x=0, y=300}, {x=300, y=300}, {x=300, y=0}}, gates={2, 4}}
    local atan2 = math.atan2 or math.atan
    heading, distance = P.guideHeading(track, {nextGate=1, passed=0}, 10, 100, route)
    assert(math.abs(heading - atan2(110, -10)) < 1e-12 and math.abs(distance - math.sqrt(110 ^ 2 + 10 ^ 2)) < 1e-9,
        "up the route's first leg, 110 on from the nearest point")
    heading = P.guideHeading(track, {nextGate=2, passed=1}, 0, 260, route)
    assert(math.abs(heading - atan2(40, 70)) < 1e-12,
        "round the corner: 40 to the corner and 70 along the next leg, not straight at the gate")
    heading = P.guideHeading(track, {nextGate=2, passed=1}, 300, 100, route)
    assert(math.abs(heading - atan2(-100, 0)) < 1e-12,
        "near the route's end it aims at the end, the last leg down")
    heading = P.guideHeading(track, {nextGate=2, passed=1}, 300, 250, {points={{x=0, y=0}}, gates={}})
    assert(math.abs(heading + math.pi / 2) < 1e-12, "a route too short to follow: the gate's middle")
    heading = P.guideHeading(track, {nextGate=2, passed=1}, 300, 250, {points=route.points, gates={2, 9}})
    assert(math.abs(heading + math.pi / 2) < 1e-12, "a crossing past the route's end: the gate's middle")
    assert(P.gateGlow(0) == 0.55 and math.abs(P.gateGlow(0.4) - 1) < 1e-12 and math.abs(P.gateGlow(0.2) - 0.775) < 1e-12
        and P.gateGlow(0 / 0) == 1, "the next gate's glow pulses between 0.55 and 1")
    -- Round a bend the arrow aims only where the kart can drive straight on
    -- its floor (Codex's review of Warsong v2): an L of floor, the corner's
    -- inside at (100, 240); from (95, 220) the route's point 110 on lies
    -- across the corner, the one 90 on does not.
    local bend = {gates={{name="G", ax=280, ay=240, bx=280, by=300}},
        isDrivable=function(px, py, level)
            return level == 0 and ((px >= 0 and px <= 100 and py >= 0 and py <= 260)
                or (px >= 0 and px <= 300 and py >= 240 and py <= 300))
        end}
    local corner = {points={{x=50, y=0}, {x=50, y=270}, {x=280, y=270}}, gates={3}}
    local along
    heading, distance, along = P.guideHeading(bend, {nextGate=1, passed=0}, 95, 220, corner, 0)
    assert(math.abs(heading - atan2(50, 90.2 - 95)) < 1e-9 and along == true,
        "round the bend the arrow aims at the farthest point it could drive to: " .. heading)
    heading = P.guideHeading(bend, {nextGate=1, passed=0}, 95, 220, corner)
    assert(math.abs(heading - atan2(50, 15)) < 1e-9, "without the kart's floor, 110 on, as before")
    heading, distance, along = P.guideHeading(bend, {nextGate=1, passed=0}, 300, 250, nil, 0)
    assert(math.abs(heading - atan2(20, -20)) < 1e-12 and not along, "without a route, the gate's middle")
    -- And with a few units to spare (Warsong v3): from (60, 200) the route's
    -- point 70.4 on lies on the diagonal through the corner itself, a line
    -- only grazing it; the arrow takes the next look in, 50.6 on.
    local diagonal = {points={{x=60, y=200}, {x=110, y=250}, {x=280, y=250}}, gates={3}}
    heading, distance, along = P.guideHeading(bend, {nextGate=1, passed=0}, 60, 200, diagonal, 0)
    assert(math.abs(heading - math.pi / 4) < 1e-9 and math.abs(distance - 0.46 * 110) < 1e-9 and along,
        "a line grazing a corner is not clear: " .. distance)
    local ramps = {ramps={{x=100, y=100, width=40, height=80}}}
    assert(P.onRamp(ramps, 120, 140) and P.onRamp(ramps, 100, 180) and not P.onRamp(ramps, 99, 140)
        and not P.onRamp({}, 120, 140) and not P.onRamp(ramps, 0 / 0, 140), "on a ramp: within one's box")
    assert(P.arrowFrame(0) == 0 and P.arrowFrame(math.pi / 2) == 4 and P.arrowFrame(-math.pi / 2) == 12
        and P.arrowFrame(2 * math.pi - 0.01) == 0, "sixteen headings counter-clockwise from east")
    local c1, c2, c3, c4 = P.arrowCoords(6)
    assert(c1 == 0.5 and c2 == 0.75 and c3 == 0.25 and c4 == 0.5, "frame 6: third column, second row")
    print("offline presentation: two floors' draw order, roof fades and crops, guiding arrow")
end

assert(_G.AzerothKart == beforeGlobal, "offline import must not create or replace an addon global")
local namespace = {sentinel=marker}
local loaded = assert(loadfile("addon/AzerothKart/Presentation.lua"))("AzerothKart", namespace)
assert(namespace.Presentation == loaded and namespace.sentinel == marker,
       "addon import registers with its explicit namespace")
assert(_G.AzerothKart == beforeGlobal, "namespace import must not replace an addon global")
print("offline presentation: close follow camera/cropped UVs/marker clipping, aspect-fit mapping, poses and drift meter")
