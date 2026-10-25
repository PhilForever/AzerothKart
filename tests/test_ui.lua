-- Lua-only regression doubles: this is NOT proof of Forever focus/combat safety.
-- The real client must still execute the F1/F2/F5 manual acceptance probes.
local originalPrint = print
local globalNames = {
    "CreateFrame", "UIParent", "InCombatLockdown", "MouseIsOver",
    "GetCurrentKeyBoardFocus", "IsGameWindowFocused", "GetBuildInfo",
    "GetFramerate", "GetTime", "debugprofilestop", "DEFAULT_CHAT_FRAME", "C_AddOns",
    "SlashCmdList", "SLASH_AZEROTHKART1", "SLASH_AZEROTHKART2",
    "AzerothKart", "AzerothKartDB", "print", "NameUtil", "UnitNameUnmodified", "Constants", "GetServerTime", "date", "issecretvalue",
}

local function withMock(savedDB, initialCombat, test, unsupportedEvent, snappingMode)
    local previous = {}
    for _,name in ipairs(globalNames) do
        previous[#previous+1] = {name=name, value=_G[name]}
    end
    local env = {
        combat=initialCombat or false, focus=nil, focused=true, mouseInside=true,
        frames={}, textures={}, output={}, counts={frames=0, textures=0, fontStrings=0},
        propagationCalls=0, combatPropagationCalls=0, keyboardReleaseCalls=0,
        profileTime=0, profileCalls=0, snappingCalls=0, drawLayerCalls=0,
        textureCalls=0, texCoordCalls=0, texturePaths={},
    }
    local methods = {}
    local function object(kind)
        env.counts[kind] = env.counts[kind]+1
        return setmetatable({scripts={}, events={}, shown=true, enabled=true}, {
            __index=function(_,key)
                if key=="akNetworkOwner" or key=="akNetworkSending" then return nil end
                return methods[key] or function() end
            end,
        })
    end
    function methods:SetScript(name, callback) self.scripts[name]=callback end
    function methods:RegisterEvent(event)
        if event==unsupportedEvent then error("mock unsupported event") end
        self.events[event]=true
    end
    function methods:UnregisterEvent(event) self.events[event]=nil end
    function methods:IsShown() return self.shown end
    function methods:Show()
        if self.shown then return end
        self.shown=true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:Hide()
        if not self.shown then return end
        self.shown=false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:Enable() self.enabled=true end
    function methods:Disable() self.enabled=false end
    function methods:IsEnabled() return self.enabled end
    function methods:EnableKeyboard(enabled)
        self.keyboard=enabled
        if not enabled then
            env.keyboardReleaseCalls=env.keyboardReleaseCalls+1
        end
    end
    function methods:SetPropagateKeyboardInput(propagate)
        env.propagationCalls=env.propagationCalls+1
        if env.combat then
            env.combatPropagationCalls=env.combatPropagationCalls+1
        end
        self.propagate=propagate
    end
    function methods:SetText(text)
        self.text=text
        self.textWrites=(rawget(self,"textWrites") or 0)+1
    end
    function methods:GetText() return self.text end
    function methods:SetSize(width,height)
        self.width,self.height=width,height
        self.sizeWrites=(rawget(self,"sizeWrites") or 0)+1
    end
    function methods:SetPoint(...) self.point={...} end
    function methods:SetRotation(value) self.rotation=value end
    function methods:SetColorTexture(...)
        self.color={...}
        self.colorWrites=(rawget(self,"colorWrites") or 0)+1
    end
    function methods:SetTexture(path)
        env.textureCalls=env.textureCalls+1
        env.texturePaths[#env.texturePaths+1]=path
        -- A per-path outcome lets one asset fail while the others load.
        local mode=env.textureModes and env.textureModes[path] or env.textureMode
        if mode=="throws" then error("mock texture load refuses") end
        if mode=="false" then return false end
        if mode=="nil" then return nil end
        self.texturePath=path
        self.textureWrites=(rawget(self,"textureWrites") or 0)+1
        return true
    end
    function methods:SetVertexColor(...)
        self.vertexColor={...}
        self.vertexColorWrites=(rawget(self,"vertexColorWrites") or 0)+1
    end
    function methods:SetTexCoord(...)
        env.texCoordCalls=env.texCoordCalls+1
        self.texCoords={...}
        self.texCoordWrites=(rawget(self,"texCoordWrites") or 0)+1
    end
    function methods:SetDrawLayer(layer,sublevel)
        env.drawLayerCalls=env.drawLayerCalls+1
        self.layer,self.sublevel=layer,sublevel or 0
        self.drawLayerWrites=(rawget(self,"drawLayerWrites") or 0)+1
    end
    local function geometryReady(item)
        return type(rawget(item,"color"))=="table" and
            type(rawget(item,"width"))=="number" and
            type(rawget(item,"height"))=="number" and
            type(rawget(item,"point"))=="table"
    end
    function methods:SetTexelSnappingBias(value)
        env.snappingCalls=env.snappingCalls+1
        self.snappingBias=value
        self.biasAfterGeometry=geometryReady(self)
    end
    function methods:SetSnapToPixelGrid(value)
        env.snappingCalls=env.snappingCalls+1
        self.snapToGrid=value
        self.gridAfterGeometry=geometryReady(self)
    end
    function methods:CreateTexture(_,layer)
        local item=object("textures")
        item.parent,item.layer,item.sublevel=self,layer,0
        if snappingMode=="missing" then
            item.SetTexelSnappingBias,item.SetSnapToPixelGrid=false,false
        elseif snappingMode=="throws" then
            item.SetTexelSnappingBias=function() error("mock snapping API refuses") end
            item.SetSnapToPixelGrid=function() error("mock grid API refuses") end
        end
        env.textures[#env.textures+1]=item
        if env.onCreateTexture then env.onCreateTexture(item,self,layer) end
        return item
    end
    function methods:CreateFontString() return object("fontStrings") end

    _G.CreateFrame=function(_,name,parent)
        local frame=object("frames")
        frame.name, frame.parent=name,parent
        env.frames[#env.frames+1]=frame
        return frame
    end
    _G.UIParent={}
    _G.InCombatLockdown=function() return env.combat end
    _G.MouseIsOver=function() return env.mouseInside end
    _G.GetCurrentKeyBoardFocus=function() return env.focus end
    _G.IsGameWindowFocused=function() return env.focused end
    _G.GetBuildInfo=function() return "mock", "0", "test", 16001 end
    _G.GetFramerate=function() return 60 end
    _G.GetTime=function() return env.profileTime/1000 end
    _G.debugprofilestop=function()
        env.profileCalls=env.profileCalls+1
        env.profileTime=env.profileTime+0.01
        return env.profileTime
    end
    _G.print=function(...)
        local words={}
        for n=1,select("#",...) do words[n]=tostring(select(n,...)) end
        env.output[#env.output+1]=table.concat(words," ")
    end
    _G.DEFAULT_CHAT_FRAME={AddMessage=function(_,text)
        env.output[#env.output+1]=tostring(text)
    end}
    _G.SlashCmdList={}
    _G.C_AddOns=nil
    _G.AzerothKart=nil
    _G.AzerothKartDB=savedDB
    _G.NameUtil={GetUnmodifiedUnitFullName=function()
        env.nameReads=(env.nameReads or 0)+1; return "Lene Conradi"
    end}
    _G.UnitNameUnmodified=nil
    _G.Constants=nil
    _G.GetServerTime=function() env.dateReads=(env.dateReads or 0)+1; return 1792756800 end
    _G.date=function() return "2026-10-23" end
    _G.issecretvalue=nil

    function env.fire(event, arg1)
        for _,frame in ipairs(env.frames) do
            if frame.events[event] and frame.scripts.OnEvent then
                frame.scripts.OnEvent(frame,event,arg1)
            end
        end
    end
    function env.key(ui, script, key)
        assert(ui.window.scripts[script], "missing keyboard callback: "..script)
        ui.window.scripts[script](ui.window,key)
    end
    local ok, err=pcall(function()
        local namespace={}
        for _,name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Courses", "Physics", "Input", "Loop", "Performance", "Presentation", "Checkpoints", "Laps", "Race", "Highscores", "SoloRecords", "UI", "Menu", "RaceProtocol", "PeerSession", "ClockProtocol", "StartClock", "RaceStart", "LiveProtocol", "LiveRace", "RaceGrid", "NetworkProbe", "TransportProbe", "SessionTransport", "ScoreChannelProbe", "Core"}) do
            assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart",namespace)
        end
        env.namespace=namespace
        test(env,namespace.UI)
    end)
    for _,entry in ipairs(previous) do _G[entry.name]=entry.value end
    assert(ok,err)
end

local KART_PATH="Interface\\AddOns\\AzerothKart\\Assets\\Karts\\GoblinMortarTrike.tga"
-- No shipped kart is a single image since the Goblin Pod Racer took the
-- original drag car's slot. This test-only kart keeps that rotated path
-- covered; the mock loads any path.
local SINGLE_PATH="Interface\\AddOns\\AzerothKart\\Assets\\Karts\\SingleImageFixture.tga"
local function singleImageKart(env)
    env.namespace.Presentation.KART_SPRITES.basic={name="Single Image Fixture",path=SINGLE_PATH,
        textureWidth=64,textureHeight=128,quadWidth=20,quadHeight=40,
        effects={wheels={{-14,6.6},{-14,-6.6}},exhausts={{-15.3,0,0}},view={1,0}}}
    return "basic" -- registered balanced handling with synthetic single-image art
end
-- Where the active kart visual is anchored for a projected kart position, and
-- whether it faces a heading: a directional sheet shows the nearest frame,
-- unrotated, offset by its pivot; a single image or the primitive rotates.
local function kartAnchor(UI,x,y)
    local sprite=UI.kartSprite
    if sprite and sprite.frames then
        return x+sprite.pivotX*UI.view.scale,y+sprite.pivotY*UI.view.scale
    end
    return x,y
end
local function kartFaces(env,UI,heading)
    local sprite=UI.kartSprite
    if sprite and sprite.frames then
        local P=env.namespace.Presentation
        local frame=P.kartFrame(sprite,heading)
        local l,r,t,b=P.kartFrameCoords(sprite,frame)
        local uv=rawget(UI.kart,"texCoords")
        return UI.kartFrame==frame and type(uv)=="table" and uv[1]==l and uv[2]==r and
            uv[3]==t and uv[4]==b and UI.kart.rotation==0
    end
    return UI.kart.rotation==heading-math.pi/2
end
local BACKGROUND_PATH="Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\SaltFlats\\Background.tga"

-- Core reuses its bootstrap for the opt-in probe and forwards the real event
-- payload, while net commands leave the racing window/capture untouched.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local transport=env.namespace.TransportProbe
    local session=env.namespace.SessionTransport
    local scores=env.namespace.ScoreChannelProbe
    local bootstrap=env.frames[1]
    assert(transport.frame==bootstrap and not session.IsActive() and not bootstrap.akNetworkOwner
        and not bootstrap.events.CHAT_MSG_ADDON_LOGGED
        and not bootstrap.scripts.OnUpdate,"cold bootstrap has no network event/update work")
    local before=#env.output
    SlashCmdList.AZEROTHKART(" net report ")
    assert(#env.output==before+1 and env.output[#env.output]:find("Idle:",1,true)
        and not UI.window:IsShown() and not UI.active,"net slash routes without toggling the kart")
    local scoreCommand,scoreEvent,scoreLifecycle
    scores.Command=function(arg) scoreCommand=arg end
    scores.Message=function(...) scoreEvent={...} end
    scores.HandleEvent=function(event) scoreLifecycle=event end
    SlashCmdList.AZEROTHKART(" scores check ")
    assert(scoreCommand=="check" and not UI.window:IsShown() and not UI.active,
        "explicit score check dispatch never starts a drive")
    bootstrap.scripts.OnEvent(bootstrap,"CHAT_MSG_ADDON_LOGGED","AZKSCP1","1|H|1","CHANNEL",
        "Lene Conradi","7. AzerothKartScoresProbe",0,7,"AzerothKartScoresProbe",0)
    assert(#scoreEvent==9 and scoreEvent[7]==7 and scoreEvent[8]=="AzerothKartScoresProbe",
        "Core preserves numeric channel metadata for the route check")
    bootstrap.scripts.OnEvent(bootstrap,"PLAYER_LEAVING_WORLD")
    assert(scoreLifecycle=="PLAYER_LEAVING_WORLD","score check receives lifecycle cleanup")
    local received
    transport.Message=function(...) received={...} end
    bootstrap.scripts.OnEvent(bootstrap,"CHAT_MSG_ADDON","AZKART1","payload","WHISPER","Tester-Realm")
    assert(not received,"unlogged events cannot enter the logged transport")
    bootstrap.scripts.OnEvent(bootstrap,"CHAT_MSG_ADDON_LOGGED","AZKART1","payload","WHISPER","Tester-Realm","target")
    assert(received[1]=="AZKART1" and received[2]=="payload" and received[3]=="WHISPER"
        and received[4]=="Tester-Realm" and received[5]=="target","Core forwards addon event arguments")
    local sessionReceived
    session.Message=function(...) sessionReceived={...} end
    bootstrap.scripts.OnEvent(bootstrap,"CHAT_MSG_ADDON_LOGGED","AZKART2","control","WHISPER","Amber Stone","extra")
    assert(sessionReceived[1]=="AZKART2" and sessionReceived[2]=="control"
        and sessionReceived[3]=="WHISPER" and sessionReceived[4]=="Amber Stone"
        and sessionReceived[5]=="extra","Core preserves native full-name logged session event arguments")
    local stoppedEvent
    local sessionEvent
    transport.HandleEvent=function(event) stoppedEvent=event end
    session.HandleEvent=function(event) sessionEvent=event end
    env.fire("PLAYER_LEAVING_WORLD")
    assert(stoppedEvent=="PLAYER_LEAVING_WORLD" and sessionEvent=="PLAYER_LEAVING_WORLD"
        and not UI.active,"both adapters and UI share lifecycle routing")
    local reason
    session.Stop=function(value) reason=value; assert(not UI.active) end
    UI.Toggle(); UI.Start()
    assert(reason=="local_drive" and UI.active,"accepted solo Start ends session control before capturing input")
    UI.Stop("session routing fixture")
end)

local function loads(env,path)
    local count=0
    for _,value in ipairs(env.texturePaths) do
        if value==path then count=count+1 end
    end
    return count
end

-- Drift/boost effects add pooled textures: 20 smoke, 14 sparks and two
-- exhaust flames of two layers each, created and loaded once with the window.
local EFFECT_TEXTURES=20+14+2*2
-- The front end (Menu.lua) creates its header, menu screens, race overlay and
-- results buttons once with the window; it replaced the old title line. The
-- track list holds eight buttons (five tracks, three coming-soon cities) under
-- two cup headings.
local MENU_FRAMES,MENU_TEXTURES,MENU_FONTS=74,9,120 -- ten pooled score rows and bounded navigation/result notice
-- City circuits have up to eight gates: the gate pool holds eight strips
-- (the oval's four plus four kept hidden on the oval and Mirage Raceway).
local GATE_STRIPS=8
-- One additional hidden staging texture preserves the visible background on
-- failed city/Mirage picture loads without relying on a second load to undo it.
-- One more is the player's optional kart outline, hidden until switched on.
local UI_TEXTURES=112+GATE_STRIPS+EFFECT_TEXTURES+MENU_TEXTURES
-- The Close results and Kart buttons add two Frames to the earlier nine; the
-- Settings check "Outline my kart" adds a button and its two lines of text.
local OUTLINE_CHECK_FRAMES,OUTLINE_CHECK_FONTS=1,2
local UI_FRAMES=11+MENU_FRAMES+OUTLINE_CHECK_FRAMES
local UI_FONTS=13+MENU_FONTS+OUTLINE_CHECK_FONTS
local PARTICLES_PATH="Interface\\AddOns\\AzerothKart\\Assets\\Effects\\Particles.tga"
local FLAME_PATH="Interface\\AddOns\\AzerothKart\\Assets\\Effects\\Flame.tga"
local function effectPieces(UI)
    local pieces={}
    for _,list in ipairs({UI.fxSmoke,UI.fxSparks,UI.fxFlames}) do
        for _,piece in ipairs(list) do pieces[#pieces+1]=piece end
    end
    return pieces
end
-- Explicit draw-layer writes on everything except the effect pools.
local function sceneLayerCalls(env,UI)
    local effect,total={},0
    for _,piece in ipairs(effectPieces(UI)) do effect[piece]=true end
    for _,item in ipairs(env.textures) do
        if not effect[item] then total=total+(rawget(item,"drawLayerWrites") or 0) end
    end
    return total
end

local countdownTicks=180
local function finishCountdown(UI)
    assert(UI.active and UI.race.status=="countdown","fixture must enter the real countdown")
    for _=1,countdownTicks do UI.OnUpdate(1/60) end
    assert(UI.race.status=="running" and UI.race.startTick==countdownTicks and
           UI.race.totalTicks==0 and UI.state.tick==countdownTicks,
        "fixture consumes the actual fixed-step countdown without resetting clock or state")
end

-- Check the actual static rectangles, rather than a second copy of the drawing
-- formula. Row sampling can differ from the analytical edge by at most half a
-- band vertically; samples farther than 3.5 units away must classify identically.
local renderSummary
withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local Track=env.namespace.Track
    local outer,inner={},{}
    local grass,grassCount=nil,0
    local walls={}
    local function sameColor(actual,r,g,b)
        return type(actual)=="table" and actual[1]==r and actual[2]==g
            and actual[3]==b and actual[4]==1
    end
    for _,item in ipairs(env.textures) do
        local color=rawget(item,"color")
        local bands
        if sameColor(color,0.26,0.25,0.23) then
            assert(item.layer=="BACKGROUND","outer road must use its background layer")
            bands=outer
        elseif sameColor(color,0.08,0.24,0.12) and item.layer=="BORDER" then
            bands=inner
        elseif sameColor(color,0.08,0.24,0.12) and item.layer=="BACKGROUND" then
            grass,grassCount=item,grassCount+1
        elseif sameColor(color,0.42,0.44,0.48) then
            assert(item.layer=="ARTWORK","visible wall strips sit above the road and grass")
            local point=rawget(item,"point")
            assert(type(point)=="table" and point[1]=="BOTTOMLEFT" and
                   point[2]==UI.canvas and point[3]=="BOTTOMLEFT",
                "wall strips use canvas coordinates")
            walls[#walls+1]={item=item,x=point[4],y=point[5],
                width=rawget(item,"width"),height=rawget(item,"height")}
        end
        if bands then
            assert(rawget(item,"snappingBias")==0 and rawget(item,"snapToGrid")==false,
                "road band disables texture sharpening/pixel snapping at creation")
            assert(rawget(item,"biasAfterGeometry")==true and rawget(item,"gridAfterGeometry")==true,
                "road snapping is configured after color, size and anchor setup")
            if bands==outer then
                assert(item.sublevel==0,"outer bands retain their default background sublevel")
            end
            local point=rawget(item,"point")
            assert(type(point)=="table" and point[2]==UI.canvas and point[3]=="BOTTOMLEFT",
                "road bands must use canvas coordinates")
            local width,height=rawget(item,"width"),rawget(item,"height")
            assert(type(width)=="number" and type(height)=="number" and width>0 and height>0,
                "road bands must have positive finite dimensions")
            local x,y=point[4],point[5]
            assert(type(x)=="number" and type(y)=="number","road bands need numeric positions")
            if point[1]=="CENTER" then x,y=x-width/2,y-height/2
            else assert(point[1]=="BOTTOMLEFT","unsupported band anchor") end
            local rect={left=x,right=x+width,bottom=y,top=y+height}
            assert(rect.left>=0 and rect.right<=Track.width and
                   rect.bottom>=0 and rect.top<=Track.height,"road band escaped the canvas")
            bands[#bands+1]=rect
        end
    end
    assert(#outer==64 and #inner==32,"road uses 64 outer bands and 32 island bands")
    assert(grassCount==1 and grass.sublevel==-1,
        "full-canvas grass must be explicitly below the outer bands")
    assert(rawget(grass,"snappingBias")==nil and rawget(grass,"snapToGrid")==nil,
        "grass snapping stays unchanged; explicit draw priority separates it from the road")
    assert(sceneLayerCalls(env,UI)==2 and env.drawLayerCalls==2+EFFECT_TEXTURES and
           UI.kartOutline.layer=="OVERLAY" and UI.kartOutline.sublevel==1,
        "only the grass, the kart outline (over the kart) and the effect pools set explicit draw sublevels")
    assert(env.snappingCalls==192,"only the 96 road bands configure snapping once")
    assert(#walls==4,"four preallocated wall strips mark the play boundary")
    local thickness=4
    local expectedWalls={
        {0,0,Track.width,thickness}, {0,Track.height-thickness,Track.width,thickness},
        {0,thickness,thickness,Track.height-2*thickness},
        {Track.width-thickness,thickness,thickness,Track.height-2*thickness},
    }
    for index,wall in ipairs(walls) do
        local expected=expectedWalls[index]
        assert(wall.x==expected[1] and wall.y==expected[2] and
               wall.width==expected[3] and wall.height==expected[4],
            "thin wall strips follow the canvas perimeter")
        assert(wall.item.colorWrites==1,"static wall color is configured once")
    end
    assert(UI.objects.frames==UI_FRAMES and UI.objects.textures==UI_TEXTURES and UI.objects.fontStrings==UI_FONTS,
        ("pooled run summary, lap/checkpoint HUD, drift meter and walls match the explicit UI object budget"
            .." (%d/%d/%d, expected %d/%d/%d)"):format(UI.objects.frames,UI.objects.textures,
            UI.objects.fontStrings,UI_FRAMES,UI_TEXTURES,UI_FONTS))
    local function covered(rectangles,x,y)
        for _,rect in ipairs(rectangles) do
            if y>=rect.bottom and y<=rect.top and x>=rect.left and x<=rect.right then
                return true
            end
        end
        return false
    end
    local function paintedRoad(x,y)
        return covered(outer,x,y) and not covered(inner,x,y)
    end
    assert(Track.isDrivable(400,440) and paintedRoad(400,440),
        "drivable road near the top must be painted instead of misleading grass")
    local function nearBoundary(x,y,radiusX,radiusY)
        local dx=x-Track.centerX
        if math.abs(dx)>radiusX then return false end
        local extent=radiusY*math.sqrt(math.max(0,1-(dx/radiusX)^2))
        return math.abs(y-(Track.centerY-extent))<=3.5 or
               math.abs(y-(Track.centerY+extent))<=3.5
    end
    local checked=0
    for y=0,Track.height,2 do
        for x=0,Track.width,2 do
            if not nearBoundary(x,y,Track.outerX,Track.outerY) and
               not nearBoundary(x,y,Track.innerX,Track.innerY) then
                assert(paintedRoad(x,y)==Track.isDrivable(x,y),
                    ("render/track mismatch away from boundary at (%d,%d)"):format(x,y))
                checked=checked+1
            end
        end
    end
    assert(checked>90000,"dense grid must cover the canvas away from raster edges")
    renderSummary=("mock road: %d outer + %d island bands; %d grid points agree outside 3.5-unit vertical margin")
        :format(#outer,#inner,checked)
end)
originalPrint(renderSummary.." (client appearance still pending)")

-- Solid fixtures are visible only on Oval. Their physical rectangles come
-- from Track data; the 18-unit center clearance belongs to collision.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local Oval=env.namespace.Track
    local markers=UI.obstacleTextures
    assert(#Oval.obstacles==2 and #markers==2,"two pooled Oval obstacle markers")
    local counts={}
    for kind,value in pairs(env.counts) do counts[kind]=value end
    for index,obstacle in ipairs(Oval.obstacles) do
        local piece=markers[index]
        assert(piece.layer=="ARTWORK" and piece:IsShown(),"solid markers draw over road")
        assert(piece.point[1]=="BOTTOMLEFT" and piece.point[4]==obstacle.x
            and piece.point[5]==obstacle.y and piece.width==obstacle.width
            and piece.height==obstacle.height,"marker uses physical geometry at scale one")
        assert(Oval.isDrivable(obstacle.x+obstacle.width/2,obstacle.y+obstacle.height/2)
            and Oval.surfaceAt(obstacle.x+obstacle.width/2,obstacle.y+obstacle.height/2)=="wall",
            "solid footprint overrides road surface without repainting the road mask")
    end
    UI.Toggle(); UI.Start(); finishCountdown(UI)
    local obstacle=Oval.obstacles[1]
    UI.state.x=obstacle.x+obstacle.width/2
    UI.state.y=obstacle.y-Oval.wallInset-0.5
    UI.state.heading,UI.state.speed=math.pi/2,200
    UI.previousState=UI.state
    local impacts=UI.state.impacts
    UI.OnUpdate(1/60)
    assert(UI.state.surface=="wall" and UI.state.impacts==impacts+1
        and UI.state.y<=obstacle.y-Oval.wallInset,"UI fixed step resolves the visible solid")
    UI.Stop("obstacle fixture")
    for _=1,3 do
        assert(UI.SelectTrack("mirage_raceway"),"select scenery without solid props")
        assert(UI.track.obstacles==nil and UI.track.resolveMovement==nil,
            "Mirage keeps original geometry and movement hook")
        for _,piece in ipairs(markers) do assert(not piece:IsShown(),"Oval solids hidden on Mirage") end
        UI.Start(); UI.OnUpdate(1/60); UI.Stop("Mirage visibility")
        for _,piece in ipairs(markers) do assert(not piece:IsShown(),"camera cannot reshow Oval solids") end
        assert(UI.SelectTrack("test_oval"),"return to Oval")
        for _,piece in ipairs(markers) do assert(piece:IsShown(),"same solid markers reused") end
    end
    for kind,value in pairs(counts) do
        assert(env.counts[kind]==value,"map switches/steps cannot create obstacle UI objects")
    end
end)

-- Mirage uses one cropped image and a closer, north-up follow camera. The same
-- uniform transform controls the readable kart and clipped geometry markers.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local Oval,Physics=env.namespace.Track,env.namespace.Physics
    assert(UI.track==Oval and UI.view.scale==1 and not UI.mirageBackground:IsShown(),
        "cold load retains the working Test Oval and hides the unloaded image")
    assert(env.textureCalls==1+EFFECT_TEXTURES and env.texturePaths[1]==KART_PATH and UI.kartSprite and
           UI.kart.texturePath==KART_PATH and loads(env,BACKGROUND_PATH)==0 and
           loads(env,PARTICLES_PATH)==34 and loads(env,FLAME_PATH)==4,
        "creation loads the kart sheet and effect atlases; the background waits for deliberate Mirage selection")
    UI.Toggle()
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    assert(UI.SelectTrack("mirage_raceway"),"stopped user can select Mirage")
    local Mirage=UI.track
    assert(Mirage.id=="mirage_raceway" and UI.view.scale==1.5 and UI.view.follow==true,
        "Mirage uses the closer uniform follow camera")
    assert(UI.canvas.width==800 and UI.canvas.height==480 and
           UI.mirageBackground:IsShown() and env.textureCalls==2+EFFECT_TEXTURES and
           loads(env,BACKGROUND_PATH)==1 and
           UI.mirageBackground.texturePath==
               "Interface\\AddOns\\AzerothKart\\Assets\\Tracks\\SaltFlats\\Background.tga",
        "one custom background is loaded at the declared addon path")
    assert(UI.mirageBackground.width==800 and UI.mirageBackground.height==480 and
           UI.mirageBackground.point[1]=="BOTTOMLEFT" and
           UI.mirageBackground.point[4]==0 and UI.mirageBackground.point[5]==0,
        "background fills the playable canvas without overview side margins")
    assert(#UI.ovalTextures==96,"fallback bands remain pooled")
    for _,piece in ipairs(UI.ovalTextures) do
        assert(not piece:IsShown(),"fallback bands cannot cover the Mirage image")
    end
    local function close(actual,expected,label)
        assert(math.abs(actual-expected)<1e-9,label)
    end
    local scale=UI.view.scale
    local spawn=Mirage.spawn()
    local Presentation=env.namespace.Presentation
    close(UI.kart.width,UI.kartSprite.quadWidth*scale,"closer sprite quad keeps its uniform padding at play size")
    close(UI.kart.height,UI.kartSprite.quadHeight*scale,"closer sprite quad keeps its uniform padding at play size")
    close(Presentation.KART_FOOTPRINT_WIDTH*scale,25.5,"closer kart body width is readable at play size")
    close(Presentation.KART_FOOTPRINT_HEIGHT*scale,46.5,"closer kart body height is readable at play size")
    close(Mirage.roadWidth*scale,168,"road and kart magnify by the same scale")
    local spawnX,spawnY=kartAnchor(UI,400,150)
    close(UI.kart.point[4],spawnX,"spawn kart is centered across the camera")
    close(UI.kart.point[5],spawnY,"spawn camera leaves room ahead of the kart")
    assert(kartFaces(env,UI,spawn.heading),"kart keeps the tested heading convention")
    local expectedWalls={
        {0,0,1024,4},{0,1020,1024,4},{0,4,4,1016},{1020,4,4,1016},
    }
    assert(#UI.wallTextures==4,"maps reuse the four perimeter walls")
    local function cameraMatchesPose(label)
        local alpha=UI.active and UI.clock and UI.clock.accumulator/UI.clock.dt or 1
        local x,y,heading=env.namespace.Presentation.pose(UI.previousState,UI.state,alpha)
        local view=UI.view
        local targetX,targetY=x+60*math.cos(heading),y+60*math.sin(heading)
        local left=math.max(0,math.min(1024-800/scale,targetX-400/scale))
        local bottom=math.max(0,math.min(1024-480/scale,targetY-240/scale))
        close(view.offsetX,-left*scale,label..": camera follows interpolated x with lookahead")
        close(view.offsetY,-bottom*scale,label..": camera follows interpolated y with lookahead")
        local anchorX,anchorY=kartAnchor(UI,view.offsetX+x*scale,view.offsetY+y*scale)
        close(UI.kart.point[4],anchorX,label..": kart uses the same camera x")
        close(UI.kart.point[5],anchorY,label..": kart uses the same camera y")
        assert(kartFaces(env,UI,heading),label..": kart shows the interpolated heading")
        local uv=rawget(UI.mirageBackground,"texCoords")
        assert(type(uv)=="table" and #uv==4,label..": crop calls the four-coordinate texture API")
        assert(uv[1]>=0 and uv[1]<uv[2] and uv[2]<=1 and
               uv[3]>=0 and uv[3]<uv[4] and uv[4]<=1,
            label..": cropped UVs stay inside the image without mirroring or flipping")
        close(uv[1],left/1024,label..": crop left matches world origin")
        close(uv[2],(left+800/scale)/1024,label..": crop right preserves world scale")
        close(uv[3],1-(bottom+480/scale)/1024,label..": crop top accounts for image Y direction")
        close(uv[4],1-bottom/1024,label..": crop bottom accounts for image Y direction")
    end
    local function clippedMarker(piece,x,y,width,height,label)
        local px,py=UI.view.offsetX+x*scale,UI.view.offsetY+y*scale
        local left,bottom=math.max(0,px),math.max(0,py)
        local right,top=math.min(800,px+width*scale),math.min(480,py+height*scale)
        local visible=left<right and bottom<top
        assert(piece:IsShown()==visible,label..": only intersecting markers are visible")
        if not visible then return false end
        assert(piece.point[1]=="BOTTOMLEFT" and piece.point[2]==UI.canvas and
               piece.point[3]=="BOTTOMLEFT",label..": clipped marker uses the canvas origin")
        close(piece.point[4],left,label..": clipped marker x matches geometry")
        close(piece.point[5],bottom,label..": clipped marker y matches geometry")
        close(piece.width,right-left,label..": clipped marker width matches geometry")
        close(piece.height,top-bottom,label..": clipped marker height matches geometry")
        assert(piece.width>0 and piece.height>0 and piece.point[4]>=0 and piece.point[5]>=0 and
               piece.point[4]+piece.width<=800+1e-9 and piece.point[5]+piece.height<=480+1e-9,
            label..": markers cannot escape the canvas into controls or other WoW UI")
        return true
    end
    local function markersMatchGeometry(label)
        local visible,hidden=0,0
        for index,gate in ipairs(Mirage.gates) do
            local width=gate.ax==gate.bx and 5 or math.abs(gate.bx-gate.ax)
            local height=gate.ay==gate.by and 5 or math.abs(gate.by-gate.ay)
            local shown=clippedMarker(UI.gateTextures[index],
                (gate.ax+gate.bx-width)/2,(gate.ay+gate.by-height)/2,width,height,
                label.." gate "..index)
            if shown then visible=visible+1 else hidden=hidden+1 end
        end
        for index,wall in ipairs(UI.wallTextures) do
            local rect=expectedWalls[index]
            clippedMarker(wall,rect[1],rect[2],rect[3],rect[4],label.." wall "..index)
        end
        return visible,hidden
    end
    cameraMatchesPose("ready spawn")
    local visible,hidden=markersMatchGeometry("ready spawn")
    assert(visible>0 and hidden>0,"closer camera shows nearby gates and hides distant ones")
    assert(UI.gateTextures[2]:IsShown() and UI.gateTextures[2].point[4]==0 and
           UI.gateTextures[2].width<Mirage.roadWidth*scale,
        "a gate crossing the camera edge is clipped instead of overflowing")
    assert(UI.state.tick==0 and UI.clock==nil and UI.race==nil and UI.result==nil and
           UI.laps.completedLaps==0 and not UI.summary:IsShown(),
        "selecting a map creates ready state without claiming a started race")
    local ready=UI.state
    assert(not UI.SelectTrack("unknown_course") and UI.track==Mirage and UI.state==ready,
        "unknown map cannot replace the ready session")
    env.combat=true
    assert(not UI.SelectTrack("test_oval") and UI.track==Mirage and UI.state==ready,
        "combat refuses a map switch without mutating the session")
    env.combat=false
    UI.Start()
    assert(UI.active and UI.race.status=="countdown" and not UI.trackButton:IsEnabled(),
        "Mirage starts the existing countdown and disables map selection")
    cameraMatchesPose("fresh countdown")
    local race,state,clock=UI.race,UI.state,UI.clock
    assert(not UI.SelectTrack("test_oval") and UI.race==race and UI.state==state and
           UI.clock==clock and UI.track==Mirage,
        "direct active selection cannot replace the running session")
    env.key(UI,"OnKeyDown","W")
    finishCountdown(UI)
    assert(UI.state.x==spawn.x and UI.state.y==spawn.y and UI.state.speed==0,
        "Mirage shares the neutral fixed-step countdown")
    local expectedState=Physics.step(UI.state,{accelerate=true},Physics.FIXED_DT,Mirage)
    UI.OnUpdate(Physics.FIXED_DT)
    assert(UI.state.y>spawn.y and UI.race.totalTicks==1,
        "the held throttle drives Mirage after GO using the existing physics")
    for field,value in pairs(expectedState) do
        assert(UI.state[field]==value,"follow camera cannot alter fixed-step state field "..field)
    end
    cameraMatchesPose("first driving tick")
    local firstOffsetY=UI.view.offsetY
    local fixedState,previous=UI.state,UI.previousState
    UI.OnUpdate(Physics.FIXED_DT/2)
    assert(UI.state==fixedState and UI.previousState==previous and UI.race.totalTicks==1 and
           UI.view.offsetY<firstOffsetY,
        "a fractional render frame follows interpolated motion without adding a physics tick")
    cameraMatchesPose("fractional driving frame")
    markersMatchGeometry("fractional driving frame")
    local function cross(index)
        local gate=Mirage.gates[index]
        UI.state.x=(gate.ax+gate.bx)/2-gate.nx
        UI.state.y=(gate.ay+gate.by)/2-gate.ny
        UI.state.heading=gate.nx==1 and 0 or gate.nx==-1 and math.pi or
            gate.ny==1 and math.pi/2 or -math.pi/2
        UI.state.speed=200; UI.state.steering=0
        UI.OnUpdate(Physics.FIXED_DT)
        cameraMatchesPose("gate crossing "..index)
        markersMatchGeometry("gate crossing "..index)
    end
    for _=1,3 do for index=1,4 do cross(index) end end
    assert(not UI.active and UI.race.status=="finished" and UI.result.status=="finished" and
           UI.laps.completedLaps==3 and UI.race.totalTicks==13 and
           UI.laps.bestLapTicks==4 and UI.laps.bestLapNumber==2 and UI.summary:IsShown(),
        "Mirage preserves exact third-lap finish, result summary and earliest tied best lap")
    assert(UI.trackButton:IsEnabled() and next(UI.keys)==nil,
        "finishing releases held controls and permits a deliberate next map")
    local finishedState,finishedRace,finishedClock=UI.state,UI.race,UI.clock
    local offsetX,offsetY=UI.view.offsetX,UI.view.offsetY
    local crop=table.concat(UI.mirageBackground.texCoords,",")
    local cameraWrites=UI.mirageBackground.texCoordWrites
    for _=1,3 do UI.OnUpdate(1) end
    UI.Toggle(); UI.Toggle()
    assert(UI.state==finishedState and UI.race==finishedRace and UI.clock==finishedClock and
           UI.view.offsetX==offsetX and UI.view.offsetY==offsetY and
           table.concat(UI.mirageBackground.texCoords,",")==crop and UI.summary:IsShown(),
        "inactive updates and close/reopen retain the finished camera, sample and result")
    assert(UI.mirageBackground.texCoordWrites<=cameraWrites+1,
        "inactive updates cannot repeatedly rewrite the background crop")
    UI.restartButton.scripts.OnClick(UI.restartButton)
    assert(UI.active and UI.race.status=="countdown" and UI.state.tick==0 and
           UI.state.x==spawn.x and UI.state.y==spawn.y and not UI.summary:IsShown(),
        "Restart keeps Mirage selected and restores its fresh spawn/countdown")
    cameraMatchesPose("restarted spawn")
    markersMatchGeometry("restarted spawn")
    UI.Stop("camera restart fixture")
    assert(UI.SelectTrack("test_oval") and UI.track==Oval and UI.view.scale==1 and
           not UI.mirageBackground:IsShown() and UI.kart.width==UI.kartSprite.quadWidth and
           UI.kart.height==UI.kartSprite.quadHeight,
        "Test Oval remains selectable with its original projection and unscaled sprite quad")
    for _,piece in ipairs(UI.ovalTextures) do
        assert(piece:IsShown(),"returning to Test Oval restores its pooled bands")
    end
    assert(UI.state.tick==0 and UI.clock==nil and UI.race==nil and UI.result==nil and
           not UI.summary:IsShown(),"changing maps clears the old terminal session")
    for _=1,3 do
        assert(UI.SelectTrack("mirage_raceway"))
        assert(UI.SelectTrack("test_oval"))
    end
    assert(env.textureCalls==2+EFFECT_TEXTURES and loads(env,BACKGROUND_PATH)==1 and loads(env,KART_PATH)==1,
        "background, kart sprite and effect atlases each load once and are reused across later selections")
    UI.Start()
    env.fire("GLOBAL_MOUSE_DOWN","LeftButton")
    local activeState,activeRace,activeClock=UI.state,UI.race,UI.clock
    UI.OnUpdate(0)
    UI.trackButton.scripts.OnClick(UI.trackButton)
    assert(UI.active and UI.track==Oval and UI.state==activeState and
           UI.race==activeRace and UI.clock==activeClock and not UI.trackButton:IsEnabled(),
        "an active track click neither stops the run nor changes maps")
    UI.stopButton.scripts.OnClick(UI.stopButton)
    env.fire("GLOBAL_MOUSE_DOWN","LeftButton")
    UI.trackButton.scripts.OnClick(UI.trackButton)
    assert(UI.track.id=="mirage_raceway" and UI.race==nil and UI.clock==nil,
        "a later deliberate stopped click can select the other map")
    UI.state.surface="grass"; UI.Stop("rough-salt fixture")
    assert(UI.driftHud.text:find("Rough salt",1,true) and
           not UI.driftHud.text:find("Grass",1,true),
        "Mirage labels its recoverable rough surface as salt")
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"switches, races and fallback reuse all UI objects: "..key)
    end
end)

-- An unavailable texture or UV API must preserve a complete previous sample,
-- including its real interruption result, while leaving the fallback playable.
for _,mode in ipairs({"false","nil","throws","missing","uv missing","uv throws"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart")
        UI.Toggle(); UI.Start(); UI.OnUpdate(1/60)
        env.combat=true; env.fire("PLAYER_REGEN_DISABLED")
        env.combat=false; env.fire("PLAYER_REGEN_ENABLED"); UI.Toggle()
        local track,state,previous,race,clock,result,laps,checkpoints=
            UI.track,UI.state,UI.previousState,UI.race,UI.clock,UI.result,UI.laps,UI.checkpoints
        local reason,hud,lapHud,summary=UI.stopReason,UI.hud.text,UI.lapHud.text,UI.summaryDetail.text
        local counts={}
        for key,value in pairs(env.counts) do counts[key]=value end
        env.textureMode=mode
        local staging=UI.backgroundStaging
        local loader=staging.SetTexture
        local cropper=staging.SetTexCoord
        if mode=="missing" then staging.SetTexture=false end
        if mode=="uv missing" then staging.SetTexCoord=false
        elseif mode=="uv throws" then
            staging.SetTexCoord=function() error("mock UV API refuses") end
        end
        assert(not UI.SelectTrack("mirage_raceway"),"renderer refusal is explicit: "..mode)
        assert(UI.track==track and UI.state==state and UI.previousState==previous and
               UI.race==race and UI.clock==clock and UI.result==result and
               UI.laps==laps and UI.checkpoints==checkpoints,
            "failed texture cannot replace any retained session identity: "..mode)
        assert(UI.stopReason==reason and UI.hud.text==hud and UI.lapHud.text==lapHud and
               UI.summaryDetail.text==summary and UI.summary:IsShown() and
               not UI.mirageBackground:IsShown() and UI.trackButton:IsEnabled(),
            "failed texture retains sample/result display and working fallback: "..mode)
        assert(UI.status.text:find("Mirage",1,true),"texture refusal stays visible: "..mode)
        for _,piece in ipairs(UI.ovalTextures) do
            assert(piece:IsShown(),"failed texture cannot hide the fallback road: "..mode)
        end
        for key,value in pairs(counts) do
            assert(env.counts[key]==value,"failed texture allocated UI objects: "..mode.."/"..key)
        end
        env.textureMode=nil
        staging.SetTexture=loader
        staging.SetTexCoord=cropper
        assert(UI.SelectTrack("mirage_raceway") and UI.result==nil,
            "explicit retry after fixing a texture can create a fresh map session: "..mode)
    end)
end

-- Scenery-to-scenery selection is staged: even a destructive failed load or
-- UV probe cannot alter the currently shown image, pose or retained run. The
-- active texture's loader also fails here, so preservation cannot rely on a
-- rollback load. Both pooled textures must pass their own UV check.
for _,sourceId in ipairs({"mirage_raceway","stormwind_city","ironforge_gp"}) do
    for _,mode in ipairs({"false","throws","uv missing","uv throws"}) do
        withMock(nil,false,function(env,UI)
            env.fire("ADDON_LOADED","AzerothKart")
            UI.Toggle()
            assert(UI.SelectTrack(sourceId),"load the retained scenery: "..sourceId)
            UI.Start(); UI.OnUpdate(1/60); UI.Stop("retained scenery fixture")
            local targetId=sourceId=="stormwind_city" and "ironforge_gp" or "stormwind_city"
            local front,staging=UI.mirageBackground,UI.backgroundStaging
            local oldPath,oldReady=UI.backgroundPath,UI.mirageTextureReady
            local image=front.texturePath
            local crop=table.concat(front.texCoords,",")
            local cropWrites=front.texCoordWrites
            local track,state,previous,race,clock,result,laps,checkpoints,view=
                UI.track,UI.state,UI.previousState,UI.race,UI.clock,UI.result,UI.laps,UI.checkpoints,UI.view
            local keys,input=UI.keys,UI.input
            env.namespace.Input.set(keys,"W",true)
            env.namespace.Input.sample(keys,input)
            local reason,hud,lapHud,summary=UI.stopReason,UI.hud.text,UI.lapHud.text,UI.summaryDetail.text
            local counts={}
            for key,value in pairs(env.counts) do counts[key]=value end
            assert(UI.cameraApiReady and front:IsShown() and not staging:IsShown(),
                "a previously verified front does not validate its hidden staging partner")
            local frontLoader,loader,cropper=front.SetTexture,staging.SetTexture,staging.SetTexCoord
            local rollbackCalls,attempts=0,0
            front.SetTexture=function(self)
                rollbackCalls=rollbackCalls+1
                self.texturePath=nil
                return false
            end
            staging.SetTexture=function(self)
                attempts=attempts+1
                self.texturePath=nil
                if mode=="throws" then error("destructive staged load refuses") end
                return false
            end
            if mode=="uv missing" then staging.SetTexCoord=false
            elseif mode=="uv throws" then
                staging.SetTexCoord=function(self)
                    self.texCoords={-1,-1,-1,-1}
                    error("destructive staged UV probe refuses")
                end
            end
            assert(not UI.SelectTrack(targetId),"staged refusal is explicit: "..sourceId.."/"..mode)
            assert(UI.mirageBackground==front and UI.backgroundStaging==staging and
                   UI.backgroundPath==oldPath and UI.mirageTextureReady==oldReady and
                   front:IsShown() and not staging:IsShown() and front.texturePath==image and
                   table.concat(front.texCoords,",")==crop and front.texCoordWrites==cropWrites,
                "refused selection preserves the exact visible image, UVs and loaded metadata")
            assert(rollbackCalls==0 and attempts==((mode=="false" or mode=="throws") and 1 or 0),
                "only a UV-validated hidden texture loads; no active-image load or rollback occurs")
            assert(UI.track==track and UI.state==state and UI.previousState==previous and
                   UI.race==race and UI.clock==clock and UI.result==result and UI.laps==laps and
                   UI.checkpoints==checkpoints and UI.view==view and not UI.active and
                   UI.keys==keys and UI.input==input and keys.W and input.accelerate,
                "failed scenery selection preserves authoritative state, clock, camera and input")
            assert(UI.stopReason==reason and UI.hud.text==hud and UI.lapHud.text==lapHud and
                   UI.summaryDetail.text==summary and UI.summary:IsShown(),
                "the retained sample and results remain visible")
            assert(UI.SelectTrack(sourceId) and UI.mirageBackground==front and front.texturePath==image,
                "the retained same-ID choice still points to its valid image")
            front.SetTexture=frontLoader
            staging.SetTexture,staging.SetTexCoord=loader,cropper
            assert(UI.SelectTrack(targetId) and UI.mirageBackground==staging and
                   UI.backgroundStaging==front and not front:IsShown() and staging:IsShown() and
                   staging.texturePath==env.namespace.Courses.get(targetId).background and UI.race==nil,
                "an explicit successful retry swaps the verified staging image and resets the run")
            assert(UI.SelectTrack("test_oval") and not UI.mirageBackground:IsShown() and
                   not UI.backgroundStaging:IsShown(),"the Oval hides both pooled scenery textures")
            for index=#UI.track.gates+1,#UI.gateTextures do
                assert(not UI.gateTextures[index]:IsShown(),"extra city gate strips hide on the Oval")
            end
            for key,value in pairs(counts) do
                assert(env.counts[key]==value,"staging and retries allocate no UI objects: "..key)
            end
        end)
    end
end

-- A gate that was visible near a city's finish cannot survive as an extra
-- strip when selecting a course with fewer gates. The pool itself is reused.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle()
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    for _,fixture in ipairs({{id="ironforge_gp",gates=7},{id="stormwind_city",gates=6},
            {id="orgrimmar_canyon",gates=4},{id="test_oval",gates=4}}) do
        assert(UI.SelectTrack(fixture.id) and #UI.track.gates==fixture.gates,
            "the selected course supplies its actual gate count: "..fixture.id)
        for index=fixture.gates+1,#UI.gateTextures do
            assert(not UI.gateTextures[index]:IsShown(),
                "a shorter course hides the prior city's extra gate: "..fixture.id.."/"..index)
        end
        -- Bring the last gate into the follow camera using a stopped pose,
        -- so the next selection must hide an actually visible surplus strip.
        local gate=UI.track.gates[fixture.gates]
        UI.state.x,UI.state.y=(gate.ax+gate.bx)/2,(gate.ay+gate.by)/2
        UI.Stop("gate pool fixture")
        assert(UI.gateTextures[fixture.gates]:IsShown(),
            "the current course's last gate is visible before switching: "..fixture.id)
    end
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"city gate switches reuse the existing pool: "..key)
    end
end)

-- Countdown cues follow fixed ticks independently of the timing HUD. Actual
-- controls are sampled, while neutral physics prevents pre-start preparation.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    assert(not UI.countdownCue:IsShown(),"cold creation keeps the countdown cue hidden")
    UI.Toggle(); UI.Start()
    local Physics,Track=env.namespace.Physics,env.namespace.Track
    local dt=Physics.FIXED_DT
    local spawn=Physics.new(Track)
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    local function neutral(label)
        for field,value in pairs(spawn) do
            if field~="tick" then assert(UI.state[field]==value,label..": changed spawn "..field) end
        end
    end
    local function advance(ticks)
        for _=1,ticks do UI.OnUpdate(dt) end
    end
    local function cue(value)
        assert(UI.countdownCue:IsShown() and UI.countdownCue.text==value,
            "expected visible countdown cue "..value)
    end
    assert(UI.race.status=="countdown" and UI.race.startTick==nil and UI.race.totalTicks==0 and
           UI.state.tick==0 and not UI.summary:IsShown(),"Start begins an untimed pre-start phase")
    assert(UI.countdownCue.point[1]=="CENTER" and UI.countdownCue.point[2]==UI.canvas,
        "preallocated countdown cue sits in the canvas center")
    cue("3")
    env.key(UI,"OnKeyDown","W"); env.key(UI,"OnKeyDown","A"); env.key(UI,"OnKeyDown","SPACE")
    local input=UI.input
    local writes=UI.countdownCue.textWrites
    advance(59); cue("3"); neutral("first countdown second")
    assert(UI.input==input and input.accelerate and input.left and input.drift,
        "held controls are sampled into the reused input table during countdown")
    UI.OnUpdate(0)
    assert(UI.countdownCue.textWrites==writes,"unchanged cue avoids repeated text writes")
    advance(1); cue("2"); neutral("second countdown cue")
    advance(59); cue("2")
    advance(1); cue("1"); neutral("third countdown cue")
    advance(59); cue("1"); neutral("last pre-start tick")
    assert(UI.state.tick==179 and UI.race.totalTicks==0 and UI.checkpoints.passed==0 and
           UI.laps.completedLaps==0,"pre-start ticks award no course progress or race time")
    advance(1); cue("GO"); neutral("GO transition tick")
    assert(UI.state.tick==180 and UI.clock.steps==180 and UI.race.status=="running" and
           UI.race.startTick==180 and UI.race.totalTicks==0 and UI.laps.lapStartTick==180 and
           UI.checkpoints.lastTick==180,"GO shares the global tick and starts fresh lap timing")
    advance(1)
    assert(UI.state.tick==181 and UI.race.totalTicks==1 and UI.state.speed>0 and
           UI.state.steering>0 and UI.state.driftTicks==0 and UI.state.boostTicks==0,
        "held controls first affect the tick after GO without stored steering or drift charge")
    writes=UI.countdownCue.textWrites
    advance(58); cue("GO")
    assert(UI.race.totalTicks==59 and UI.countdownCue.textWrites==writes,
        "GO stays visible and cached for the first 59 driving ticks")
    advance(1)
    assert(UI.race.totalTicks==60 and not UI.countdownCue:IsShown(),
        "GO hides after one simulated driving second")
    writes=UI.countdownCue.textWrites; UI.OnUpdate(0)
    assert(UI.countdownCue.textWrites==writes,"hidden cue also avoids repeated text writes")
    UI.Stop("countdown controls fixture")

    -- One render callback spans neutral GO and two actual held-input ticks.
    UI.Start(); advance(179)
    env.key(UI,"OnKeyDown","W"); env.key(UI,"OnKeyDown","A"); env.key(UI,"OnKeyDown","SPACE")
    UI.OnUpdate(3*dt)
    local reference=Physics.new(Track)
    local empty,held={}, {accelerate=true,left=true,drift=true}
    for _=1,180 do reference=Physics.step(reference,empty,dt,Track) end
    for _=1,2 do reference=Physics.step(reference,held,dt,Track) end
    for field,value in pairs(reference) do
        assert(UI.state[field]==value,"catch-up crossed GO incorrectly for "..field)
    end
    assert(UI.clock.steps==182 and UI.clock.lastSteps==3 and UI.race.totalTicks==2 and
           UI.clock.droppedSeconds==0,"catch-up applies countdown and driving in exact tick order")
    UI.Stop("held GO fixture")
    UI.Start(); env.key(UI,"OnKeyDown","W"); env.key(UI,"OnKeyDown","SPACE")
    advance(179)
    env.key(UI,"OnKeyUp","W"); env.key(UI,"OnKeyUp","SPACE")
    UI.OnUpdate(3*dt); neutral("released before GO")
    assert(UI.state.tick==182 and not UI.input.accelerate and not UI.input.drift,
        "keys released before GO cannot produce stored throttle or drift")
    UI.Stop("released GO fixture")

    for _,exit in ipairs({"Stop","Escape","focus","combat"}) do
        UI.Start(); env.key(UI,"OnKeyDown","W"); advance(17)
        if exit=="Stop" then UI.Stop("countdown stopped")
        elseif exit=="Escape" then env.key(UI,"OnKeyDown","ESCAPE")
        elseif exit=="focus" then env.focused=false; UI.OnUpdate(dt); env.focused=true
        else env.combat=true; env.fire("PLAYER_REGEN_DISABLED") end
        assert(not UI.active and not UI.countdownCue:IsShown() and next(UI.keys)==nil and
               not UI.input.accelerate and UI.race.totalTicks==0 and UI.race.startTick==nil and
               UI.race.laps.completedLaps==0 and UI.checkpoints.passed==0 and
               UI.summary:IsShown(),exit..": cancellation retains zero race time and releases controls")
        assert(UI.race.status==(exit=="combat" and "interrupted" or "stopped"),
            exit..": cancellation records its actual terminal state")
        local race,clock=UI.race,UI.clock
        local output=#env.output
        UI.OnUpdate(1)
        if exit=="combat" then env.combat=false; env.fire("PLAYER_REGEN_ENABLED") end
        if not UI.window:IsShown() then UI.Toggle() end
        assert(UI.race==race and UI.clock==clock and not UI.active and
               not UI.countdownCue:IsShown() and #env.output==output,
            exit..": inactive update and reopen cannot resume the cancelled countdown")
        UI.restartButton.scripts.OnClick(UI.restartButton)
        assert(UI.active and UI.state.tick==0 and UI.race.status=="countdown" and
               UI.race.totalTicks==0 and UI.race.startTick==nil and not UI.summary:IsShown(),
            exit..": explicit Restart creates a complete fresh countdown")
        cue("3"); neutral(exit.." restart")
        UI.Stop("next cancellation fixture")
    end
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"countdown/cancel/restart allocated UI objects: "..key)
    end
end)

-- Consecutive directional checkpoints award repeatable fixed-tick laps. Finish
-- feedback is immediate, while the running lap clock shares the throttled HUD.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle(); UI.Start()
    local Track,Physics=env.namespace.Track,env.namespace.Physics
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    local function gateColor(index,r,g,b,a)
        local color=UI.gateTextures[index].color
        assert(color[1]==r and color[2]==g and color[3]==b and color[4]==a,
            "unexpected checkpoint tint for gate "..index)
    end
    assert(#Track.gates==4 and #UI.gateTextures==GATE_STRIPS,"four track gates use pooled strips")
    for index=#Track.gates+1,GATE_STRIPS do
        assert(not UI.gateTextures[index]:IsShown(),"strips beyond the track's gates stay hidden")
    end
    assert(UI.checkpoints.passed==0 and UI.checkpoints.nextGate==1 and
           not UI.checkpoints.complete and UI.checkpoints.lastTick==0,
        "fresh drive starts before the first checkpoint")
    assert(UI.checkpointHud.text=="Checkpoints: 0/4 | Next: North",
        "fresh HUD explains the first required checkpoint")
    assert(UI.checkpointHud.point[5]==154,"checkpoint text stays above the other HUD rows")
    assert(UI.laps.completedLaps==0 and UI.laps.currentLapTicks==0 and
           UI.laps.lastLapTicks==nil and UI.laps.lapStartTick==0 and
           UI.laps.lastTick==0 and UI.laps.lastFinishTick==nil and
           UI.laps.bestLapTicks==nil and UI.laps.bestLapNumber==nil and
           UI.laps.checkpoints==UI.checkpoints,
        "fresh lap timing owns the same checkpoint sample")
    assert(UI.lapHud.text=="Laps: 0 | Current: 0.00s | Last: -- | Best: --" and
           UI.lapHud.point[5]==176,"fresh lap HUD has its own pooled row")
    for index,gate in ipairs(Track.gates) do
        local strip=UI.gateTextures[index]
        local width=gate.ax==gate.bx and 5 or math.abs(gate.bx-gate.ax)
        local height=gate.ay==gate.by and 5 or math.abs(gate.by-gate.ay)
        assert(strip.point[1]=="BOTTOMLEFT" and strip.point[2]==UI.canvas and
               strip.point[3]=="BOTTOMLEFT" and strip.point[4]==(gate.ax+gate.bx-width)/2 and
               strip.point[5]==(gate.ay+gate.by-height)/2,
            "gate strip follows track endpoints with its clipped rectangle anchor")
        if gate.ax==gate.bx then
            assert(strip.width==5 and strip.height==math.abs(gate.by-gate.ay),
                "vertical gate strip covers its crossing segment")
        else
            assert(gate.ay==gate.by and strip.height==5 and strip.width==math.abs(gate.bx-gate.ax),
                "horizontal gate strip covers its crossing segment")
        end
        if index==1 then gateColor(index,.98,.93,.45,.9)
        else gateColor(index,.55,.58,.62,.65) end
    end
    local startGate=Track.gates[4]
    assert(startGate.name=="Start" and startGate.ay==Track.centerY and
           startGate.by==Track.centerY and startGate.nx==0 and startGate.ny==1,
        "right-side start gate crosses the spawn lane in the driving direction")
    local function cross(index,wrongWay)
        local gate=Track.gates[index]
        local nx,ny=gate.nx,gate.ny
        if wrongWay then nx,ny=-nx,-ny end
        UI.state.x=(gate.ax+gate.bx)/2-nx
        UI.state.y=(gate.ay+gate.by)/2-ny
        UI.state.heading=nx==1 and 0 or nx==-1 and math.pi or
            ny==1 and math.pi/2 or -math.pi/2
        UI.state.speed=200; UI.state.steering=0
        UI.OnUpdate(Physics.FIXED_DT)
    end
    finishCountdown(UI)
    cross(3)
    assert(UI.checkpoints.passed==0,"crossing South before North cannot skip the ordered course")
    cross(1)
    assert(UI.checkpoints.passed==1 and UI.checkpoints.nextGate==2 and
           UI.checkpoints.lastTick==UI.state.tick,
        "actual fixed-step North crossing advances one checkpoint")
    assert(UI.checkpointHud.text=="Checkpoints: 1/4 | Next: West",
        "checkpoint HUD refreshes immediately before the periodic timing HUD")
    gateColor(1,.25,.80,.72,.9); gateColor(2,.98,.93,.45,.9)
    local writes={}
    for index,strip in ipairs(UI.gateTextures) do writes[index]=strip.colorWrites end
    local hudWrites=UI.checkpointHud.textWrites
    for _=1,3 do UI.OnUpdate(0) end
    cross(1)
    assert(UI.checkpoints.passed==1,"recrossing an accepted gate cannot duplicate progress")
    for index,strip in ipairs(UI.gateTextures) do
        assert(strip.colorWrites==writes[index],"unchanged progress does not rewrite gate tints")
    end
    assert(UI.checkpointHud.textWrites==hudWrites,
        "render-only and irrelevant crossings do not rewrite checkpoint text")
    for index=2,4 do cross(index) end
    local firstFinishTick=UI.state.tick
    local firstLapTicks=firstFinishTick-countdownTicks
    assert(UI.laps.completedLaps==1 and UI.laps.lastLapTicks==firstLapTicks and
           UI.laps.currentLapTicks==0 and UI.laps.lastFinishTick==firstFinishTick and
           UI.laps.lapStartTick==firstFinishTick and UI.laps.bestLapTicks==firstLapTicks and
           UI.laps.bestLapNumber==1,
        "first ordered circuit records its exact duration from the GO tick")
    assert(not UI.checkpoints.complete and UI.checkpoints.passed==0 and
           UI.checkpoints.nextGate==1 and UI.checkpoints.lastTick==firstFinishTick and
           UI.checkpoints==UI.laps.checkpoints and UI.active and UI.result==nil,
        "a nonfinal lap rearms North while the three-lap run remains active")
    local function lapCaption(completed,current,last)
        return ("Laps: %d | Current: %.2fs | Last: %.2fs | Best: %.2fs (lap 1)"):format(
            completed,current*Physics.FIXED_DT,last*Physics.FIXED_DT,
            firstLapTicks*Physics.FIXED_DT)
    end
    assert(UI.lapHud.text==lapCaption(1,0,firstLapTicks),
        "finish refreshes exact lap feedback before the periodic HUD interval")
    assert(UI.checkpointHud.text=="Checkpoints: 0/4 | Next: North",
        "a completed lap displays the next circuit's first required gate")
    gateColor(1,.98,.93,.45,.9)
    for index=2,4 do gateColor(index,.55,.58,.62,.65) end
    cross(4); cross(1,true)
    assert(UI.laps.completedLaps==1 and UI.laps.lastLapTicks==firstLapTicks and
           UI.checkpoints.passed==0,
        "duplicate Start crossings and wrong-way North cannot award another lap")
    local lapWrites=UI.lapHud.textWrites
    for _=1,3 do UI.OnUpdate(0) end
    assert(UI.lapHud.textWrites==lapWrites,"render-only frames do not rewrite lap timing")
    UI.state.speed=0
    for _=1,15 do UI.OnUpdate(Physics.FIXED_DT) end
    assert(UI.laps.currentLapTicks==UI.state.tick-firstFinishTick and
           UI.lapHud.textWrites>lapWrites and
           UI.lapHud.text:find("Laps: 1 | Current:",1,true),
        "running lap time advances only on fixed ticks and refreshes at the HUD interval")
    for index=1,4 do cross(index) end
    local secondFinishTick=UI.state.tick
    local secondLapTicks=secondFinishTick-firstFinishTick
    assert(UI.laps.completedLaps==2 and UI.laps.lastLapTicks==secondLapTicks and
           secondLapTicks>firstLapTicks and UI.laps.currentLapTicks==0 and
           UI.laps.bestLapTicks==firstLapTicks and UI.laps.bestLapNumber==1 and
           UI.laps.lastFinishTick==secondFinishTick and
           UI.laps.lapStartTick==secondFinishTick and
           UI.lapHud.text==lapCaption(2,0,secondLapTicks),
        "a slower second circuit updates last-lap timing and retains the first lap as best")
    assert(UI.checkpoints.passed==0 and UI.checkpoints.nextGate==1 and
           not UI.checkpoints.complete and UI.laps.checkpoints==UI.checkpoints,
        "every finished lap rearms the same directional course")
    UI.state.speed=0; UI.OnUpdate(Physics.FIXED_DT)
    UI.Stop("lap fixture")
    local progress,pose,hud=UI.checkpoints,UI.state,UI.checkpointHud.text
    local laps,lapHud=UI.laps,UI.lapHud.text
    local retained,retainedLaps={},{}
    for key,value in pairs(progress) do retained[key]=value end
    for key,value in pairs(laps) do retainedLaps[key]=value end
    assert(hud=="Last drive | Checkpoints: 0/4 | Next: North" and
           lapHud=="Last drive | "..lapCaption(2,1,secondLapTicks),
        "Stop flushes the partial next lap and labels all retained progress")
    local bestCaption=("Best: %.2fs (lap 1)"):format(firstLapTicks*Physics.FIXED_DT)
    assert(UI.summaryDetail.text:find("\n"..bestCaption,1,true),
        "partial Stop summary includes the completed best lap on its third line")
    UI.OnUpdate(1); UI.Toggle(); UI.Toggle()
    assert(UI.checkpoints==progress and UI.state==pose and UI.checkpointHud.text==hud and
           UI.laps==laps and UI.lapHud.text==lapHud,
        "inactive update and reopen retain the same lap/checkpoint samples and captions")
    for key,value in pairs(retained) do
        assert(progress[key]==value,"stopped checkpoint progress changed "..key)
    end
    for key,value in pairs(retainedLaps) do
        assert(laps[key]==value,"stopped lap timing changed "..key)
    end
    env.focus={}; UI.Start()
    assert(UI.laps==laps and UI.lapHud.text==lapHud and
           UI.summaryDetail.text:find(bestCaption,1,true),
        "refused Start retains completed best-lap timing in both stopped displays")
    env.focus=nil
    UI.Start()
    assert(UI.checkpoints~=progress and UI.checkpoints.passed==0 and
           UI.checkpoints.nextGate==1 and not UI.checkpoints.complete and
           UI.checkpoints.lastTick==0 and UI.checkpointHud.text=="Checkpoints: 0/4 | Next: North",
        "fresh Start resets the course sample and its retained caption")
    assert(UI.laps~=laps and UI.laps.completedLaps==0 and UI.laps.currentLapTicks==0 and
           UI.laps.lapStartTick==0 and UI.laps.lastTick==0 and
           UI.laps.lastFinishTick==nil and UI.laps.lastLapTicks==nil and
           UI.laps.bestLapTicks==nil and UI.laps.bestLapNumber==nil and
           UI.laps.checkpoints==UI.checkpoints and
           UI.lapHud.text=="Laps: 0 | Current: 0.00s | Last: -- | Best: --",
        "fresh Start resets all lap timing and replaces the retained lap object")
    gateColor(1,.98,.93,.45,.9)
    for index=2,4 do gateColor(index,.55,.58,.62,.65) end
    UI.Stop("lap fixture done")
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"lap/checkpoint updates allocated UI objects: "..key)
    end
end)

-- Closing results dismisses presentation only, and stays dismissed for that
-- ended run while its final pose, timing and lap feedback remain available.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle(); UI.Start()
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    local activeRace=UI.race
    UI.DismissSummary()
    assert(UI.active and UI.race==activeRace and UI.window.keyboard and
           not UI.summary:IsShown(),"dismissal cannot end an active countdown")
    finishCountdown(UI)
    env.key(UI,"OnKeyDown","W")
    for _=1,8 do UI.OnUpdate(1/60) end
    UI.Stop("dismissal fixture")
    assert(UI.summary:IsShown() and UI.summaryTitle.text=="RUN STOPPED",
        "stopping a run presents its partial result")
    local button=UI.dismissSummaryButton
    assert(button and button.parent==UI.summary and button.text=="Close results" and
           type(button.scripts.OnClick)=="function","results have a reachable close control")
    local race,pose,clock,laps,checkpoints=UI.race,UI.state,UI.clock,UI.laps,UI.checkpoints
    local previous,result=UI.previousState,UI.result
    local lapHud,checkpointHud,detail=UI.lapHud.text,UI.checkpointHud.text,UI.summaryDetail.text
    local snapshots={}
    for _,sample in ipairs({race,pose,clock,laps,checkpoints}) do
        local values={}
        for key,value in pairs(sample) do values[key]=value end
        snapshots[#snapshots+1]={sample=sample,values=values}
    end
    button.scripts.OnClick(button)
    assert(UI.window:IsShown() and not UI.summary:IsShown() and not UI.active and
           UI.startButton:IsEnabled() and UI.trackButton:IsEnabled() and
           not UI.stopButton:IsEnabled() and not UI.window.keyboard and UI.window.propagate,
        "Close results leaves the track and idle menu available without recapturing input")
    UI.OnUpdate(1); UI.Stop("repeated stop"); UI.Toggle(); UI.Toggle()
    local closeButton
    for _,item in ipairs(env.frames) do if item.text=="Close" then closeButton=item end end
    closeButton.scripts.OnClick(closeButton); UI.Start(); UI.Toggle()
    env.focus={}; UI.Start(); env.focus=nil
    env.combat=true; UI.Start(); env.combat=false
    assert(UI.window:IsShown() and not UI.summary:IsShown() and not UI.active and
           UI.race==race and UI.state==pose and UI.clock==clock and UI.laps==laps and
           UI.checkpoints==checkpoints and UI.previousState==previous and UI.result==result and
           UI.lapHud.text==lapHud and UI.checkpointHud.text==checkpointHud and
           UI.summaryDetail.text==detail,
        "repeated Stop, close/reopen and rejected Starts cannot resurrect dismissed results")
    for _,snapshot in ipairs(snapshots) do
        for key,value in pairs(snapshot.values) do
            assert(snapshot.sample[key]==value,"dismissed result sample changed: "..key)
        end
        for key,value in pairs(snapshot.sample) do
            assert(snapshot.values[key]==value,"dismissed result sample gained a field: "..key)
        end
    end
    UI.Start()
    local nextRace=UI.race
    assert(UI.active and nextRace~=race and nextRace.status=="countdown" and
           not UI.summary:IsShown(),"Start creates a fresh run after dismissing results")
    UI.DismissSummary()
    assert(UI.active and UI.race==nextRace and UI.window.keyboard,
        "result dismissal cannot interfere with the next active run")
    UI.Stop("next ended run")
    assert(UI.summary:IsShown() and UI.summaryTitle.text=="RUN STOPPED",
        "the next ended run presents a new summary")
    button.scripts.OnClick(button)
    assert(UI.SelectTrack("mirage_raceway") and UI.race==nil and not UI.summary:IsShown(),
        "track selection clears the ended session after results are dismissed")
    UI.Start(); UI.Stop("new track run")
    assert(UI.summary:IsShown(),"a run on the newly selected track still presents results")
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"result dismissal/restart allocated UI objects: "..key)
    end
end)

-- The third ordered circuit is terminal, including when the finish lands in a
-- multi-tick render callback. Results and the pooled restart flow stay usable.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    assert(UI.race==nil and not UI.summary:IsShown(),
        "cold creation does not invent a run or display a result")
    UI.Toggle(); UI.Start()
    local Track,Physics=env.namespace.Track,env.namespace.Physics
    local dt=Physics.FIXED_DT
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    assert(UI.race.status=="countdown" and UI.race.targetLaps==3 and
           UI.laps==UI.race.laps and UI.checkpoints==UI.laps.checkpoints,
        "deliberate Start creates a countdown with shared lap/checkpoint samples")
    assert(not UI.summary:IsShown(),"running drive keeps the pooled summary hidden")
    local function cross(index,elapsed)
        local gate=Track.gates[index]
        UI.state.x=(gate.ax+gate.bx)/2-gate.nx
        UI.state.y=(gate.ay+gate.by)/2-gate.ny
        UI.state.heading=gate.nx==1 and 0 or gate.nx==-1 and math.pi or
            gate.ny==1 and math.pi/2 or -math.pi/2
        UI.state.speed=200; UI.state.steering=0
        UI.OnUpdate(elapsed or dt)
    end
    finishCountdown(UI)
    env.key(UI,"OnKeyDown","W"); env.key(UI,"OnKeyDown","SPACE")
    UI.OnUpdate(2*dt) -- First lap is slower; the second and third then tie.
    for lap=1,3 do
        for index=1,4 do
            cross(index,lap==3 and index==4 and 3*dt or dt)
        end
        if lap<3 then
            assert(UI.active and UI.race.status=="running" and UI.result==nil,
                "nonfinal laps keep the run active without a terminal result")
        end
        assert(UI.laps.bestLapTicks==(lap==1 and 6 or 4) and
               UI.laps.bestLapNumber==(lap==1 and 1 or 2),
            "a faster second lap replaces the best and a tied third keeps lap two")
    end
    local race,result,clock,pose=UI.race,UI.result,UI.clock,UI.state
    local records=env.namespace.SoloRecords
    local savedScores,finishedRun=AzerothKartDB.highscores,UI.soloRun
    local score=records.GetView("test_oval").rows[1]
    assert(UI.scoreResult.saved and UI.soloRun.attempted and score.totalTicks==14 and
        score.playerName=="Lene Conradi" and score.finishedAt==1792756800 and
        env.nameReads==1 and env.dateReads==1,
        "one solo total/name/date saved at the actual finish, excluding post-finish remainder")
    assert(not UI.active and race.status=="finished" and race.finishTick==countdownTicks+14 and
           race.totalTicks==14 and race.laps.completedLaps==3 and
           race.laps.lastLapTicks==4 and pose.tick==countdownTicks+14,
        "the third directional finish freezes the fourteenth driving tick and all three laps")
    assert(result.status=="finished" and result.reason=="Three-lap run complete" and
           result.tick==countdownTicks+14 and result.totalTicks==14 and result.completedLaps==3,
        "finish result exposes actual terminal lap/time values")
    assert(clock.steps==countdownTicks+14 and clock.lastSteps==1 and clock.hitchFrames==0 and
           math.abs(clock.droppedSeconds-2*dt)<1e-10 and math.abs(clock.accumulator)<1e-10,
        "finish stops remaining catch-up ticks and accounts for them without a false hitch")
    assert(math.abs(clock.steps*dt+clock.droppedSeconds+clock.accumulator-
           clock.elapsedSeconds)<1e-10,"finish frame retains complete elapsed accounting")
    assert(UI.window.keyboard==false and UI.window.propagate and next(UI.keys)==nil and
           not UI.input.accelerate and not UI.input.drift and not UI.countdownCue:IsShown(),
        "automatic finish releases held/sampled controls and hides the start cue")
    local poseX,poseY=kartAnchor(UI,pose.x,pose.y)
    assert(UI.previousState==pose and UI.kart.point[4]==poseX and UI.kart.point[5]==poseY and
           kartFaces(env,UI,pose.heading),
        "automatic finish renders the exact terminal pose")
    assert(UI.checkpointHud.text:find("Checkpoints: 3-lap run complete",1,true),
        "terminal checkpoint HUD explains completion instead of requesting another circuit")
    assert(UI.summary:IsShown() and UI.summary.parent==UI.canvas and
           UI.summary.width==460 and UI.summary.height==336 and
           UI.summaryTitle.text=="RUN COMPLETE",
        "finished run displays its preallocated summary panel")
    assert(UI.summaryDetail.text:find("3/3",1,true) and
           UI.summaryDetail.text:find(("%.2fs"):format(14*dt),1,true) and
           UI.summaryDetail.text:find(("%.2fs"):format(4*dt),1,true) and
           UI.summaryDetail.text:find(("\nBest: %.2fs (lap 2)"):format(4*dt),1,true) and
           UI.lapHud.text:find(("Best: %.2fs (lap 2)"):format(4*dt),1,true),
        "summary and final HUD display the faster second lap, retained after a tied third")
    assert(UI.restartButton.parent==UI.summary and UI.restartButton.text=="Restart" and
           type(UI.restartButton.scripts.OnClick)=="function",
        "summary exposes a reachable explicit Restart control")
    local output=#env.output
    local finishReason,finishHud,finishDetail=UI.stopReason,UI.hud.text,UI.summaryDetail.text
    UI.OnUpdate(1); UI.Stop("later ordinary stop"); UI.Toggle(); UI.Toggle()
    assert(AzerothKartDB.highscores==savedScores and env.nameReads==1 and env.dateReads==1,
        "Stop/close/reopen/inactive callbacks do not resubmit a completed score")
    assert(UI.race==race and UI.result==result and UI.clock==clock and UI.state==pose and
           UI.state.tick==countdownTicks+14 and UI.stopReason==finishReason and UI.hud.text==finishHud and
           UI.summaryDetail.text==finishDetail and UI.summary:IsShown() and
           UI.summaryTitle.text=="RUN COMPLETE",
        "inactive updates, Stop, close and reopen retain the same completed run")
    local closeButton
    for _,item in ipairs(env.frames) do if item.text=="Close" then closeButton=item end end
    closeButton.scripts.OnClick(closeButton)
    UI.Start()
    assert(not UI.window:IsShown() and UI.race==race and UI.result==result,
        "hidden Start cannot replace a completed result")
    UI.Toggle(); env.combat=true; UI.Start()
    assert(not UI.active and UI.race==race and UI.result==result and UI.summary:IsShown() and
           UI.summaryDetail.text==finishDetail,
        "refused combat-time Start preserves the completed summary")
    env.fire("PLAYER_REGEN_DISABLED"); UI.InterruptCombat(); UI.OnUpdate(1)
    assert(not UI.window:IsShown() and UI.race==race and UI.result==result and #env.output==output,
        "combat after finish cannot turn the completed result into a new interruption")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED"); UI.Toggle()
    env.focus={}; UI.Start()
    assert(UI.race==race and UI.result==result and UI.summary:IsShown() and
           UI.summaryDetail.text==finishDetail,
        "refused text-focus Start preserves the same completed summary")
    env.focus=nil
    UI.restartButton.scripts.OnClick(UI.restartButton)
    assert(UI.soloRun~=finishedRun and not UI.soloRun.attempted and UI.scoreResult==nil,
        "accepted Restart creates a fresh capture and clears its saved notice")
    assert(UI.active and UI.race~=race and UI.race.status=="countdown" and
           UI.result==nil and UI.state.tick==0 and UI.clock~=clock and
           UI.laps==UI.race.laps and UI.laps.completedLaps==0 and
           UI.laps.bestLapTicks==nil and UI.laps.bestLapNumber==nil and
           UI.lapHud.text:find("Best: --",1,true) and not UI.summary:IsShown(),
        "summary Restart begins a fresh run and hides the retained result")
    finishCountdown(UI)
    cross(1); UI.Stop("partial run fixture")
    assert(UI.race.status=="stopped" and UI.race.totalTicks==1 and
           UI.race.laps.completedLaps==0 and UI.checkpoints.passed==1 and
           UI.summary:IsShown() and UI.summaryTitle.text=="RUN STOPPED" and
           UI.summaryDetail.text:find("\nBest: --",1,true),
        "ordinary Stop displays actual partial progress without a finish award")
    UI.restartButton.scripts.OnClick(UI.restartButton)
    finishCountdown(UI)
    for index=1,4 do cross(index) end
    cross(1); env.combat=true; env.fire("PLAYER_REGEN_DISABLED")
    local interrupted=UI.race
    assert(interrupted.status=="interrupted" and interrupted.totalTicks==5 and
           interrupted.laps.completedLaps==1 and UI.checkpoints.passed==1 and
           interrupted.laps.bestLapTicks==4 and interrupted.laps.bestLapNumber==1 and
           UI.summaryDetail.text:find(("\nBest: %.2fs (lap 1)"):format(4*dt),1,true) and
           UI.summaryTitle.text=="GAME INTERRUPTED BY COMBAT" and not UI.window:IsShown(),
        "combat interruption freezes actual partial progress and its summary")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED"); UI.Toggle()
    local interruptedDetail=UI.summaryDetail.text
    assert(UI.race==interrupted and not UI.active and UI.summary:IsShown() and
           UI.lapHud.text:find(("Best: %.2fs (lap 1)"):format(4*dt),1,true),
        "explicit reopen shows the frozen interrupted summary without resuming")
    env.focus={}; UI.Start()
    assert(UI.race==interrupted and UI.summaryDetail.text==interruptedDetail,
        "refused Start retains the best completed lap after interruption")
    env.focus=nil; UI.restartButton.scripts.OnClick(UI.restartButton)
    assert(UI.race.status=="countdown" and UI.laps.bestLapTicks==nil and
           UI.laps.bestLapNumber==nil and UI.lapHud.text:find("Best: --",1,true),
        "explicit Restart clears the interrupted best-lap record")
    UI.Stop("finish/best-lap fixture done")
    assert(AzerothKartDB.highscores==savedScores and env.nameReads==1 and env.dateReads==1,
        "partial Stop/combat/rejected Starts never overwrite the completed personal best")
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"finish/restart/partial flow allocated UI objects: "..key)
    end
end)

-- Render interpolation uses the retained fixed-step pair, including updates
-- without a simulation tick. Stop/reopen displays the exact frozen sample.
withMock(nil,false,function(env,UI)
    UI.Stop("before creation")
    -- The single-image kart rotates continuously, so it exposes the exact
    -- interpolated heading; the directional sheet is covered separately.
    env.namespace.Presentation.DEFAULT_KART=singleImageKart(env)
    env.fire("ADDON_LOADED","AzerothKart")
    assert(UI.kart.texturePath==SINGLE_PATH and not UI.kartSprite.frames,"rotating kart fixture")
    UI.Toggle(); UI.Start()
    local function close(actual,expected,label)
        assert(math.abs(actual-expected)<1e-10,label)
    end
    local function exactPose(label)
        close(UI.kart.point[4],UI.state.x,label..": x")
        close(UI.kart.point[5],UI.state.y,label..": y")
        close(UI.kart.rotation,UI.state.heading-math.pi/2,label..": heading")
    end
    assert(UI.previousState==UI.state,"fresh Start collapses interpolation history")
    exactPose("fresh Start")
    finishCountdown(UI)
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    env.key(UI,"OnKeyDown","W"); env.key(UI,"OnKeyDown","A")
    local dt=env.namespace.Physics.FIXED_DT
    UI.OnUpdate(dt*1.5)
    assert(UI.state.tick==countdownTicks+1 and UI.previousState.tick==countdownTicks,
        "first driving tick retains its GO predecessor")
    local previous,current=UI.previousState,UI.state
    local function blended(alpha)
        close(UI.kart.point[4],previous.x+(current.x-previous.x)*alpha,"blended x")
        close(UI.kart.point[5],previous.y+(current.y-previous.y)*alpha,"blended y")
        close(UI.kart.rotation,previous.heading+(current.heading-previous.heading)*alpha-math.pi/2,
            "blended heading")
    end
    blended(0.5)
    local snapshot={}
    for key,value in pairs(current) do snapshot[key]=value end
    UI.OnUpdate(dt*0.25)
    assert(UI.clock.lastSteps==0 and UI.clock.steps==countdownTicks+1 and
           UI.clock.frames==countdownTicks+2 and
           UI.state==current and UI.previousState==previous,
        "zero-step render advances the blend without replacing simulation history")
    blended(0.75)
    for key,value in pairs(snapshot) do
        assert(current[key]==value,"render interpolation changed simulation field "..key)
    end
    close(UI.clock.accumulator,dt*0.75,"zero-step remainder")
    UI.Stop("interpolation fixture")
    assert(UI.previousState==UI.state,"Stop collapses interpolation history")
    exactPose("Stop")
    local point=UI.kart.point
    local clock={}
    for key,value in pairs(UI.clock) do clock[key]=value end
    UI.OnUpdate(1)
    assert(UI.kart.point==point,"inactive update does not render or resume the blend")
    UI.Toggle(); UI.Toggle()
    exactPose("reopened stopped sample")
    for key,value in pairs(clock) do
        assert(UI.clock[key]==value,"stopped interpolation changed clock "..key)
    end
    UI.Start()
    assert(UI.state.tick==0 and UI.previousState==UI.state,"fresh Start replaces frozen history")
    exactPose("restarted")
    UI.Stop("interpolation fixture done")
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"interpolation allocated UI objects: "..key)
    end
end)

-- A short shared-input reference checks every simulation field at three render
-- cadences; visual positions remain within the center clearance of the walls.
for _,fps in ipairs({30,60,144}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart")
        UI.Toggle(); UI.Start()
        local Physics,Track=env.namespace.Physics,env.namespace.Track
        local reference=Physics.new(Track)
        local neutral={}
        for _=1,countdownTicks do reference=Physics.step(reference,neutral,Physics.FIXED_DT,Track) end
        finishCountdown(UI)
        local controls={accelerate=true,left=true,drift=true}
        for _=1,120 do reference=Physics.step(reference,controls,Physics.FIXED_DT,Track) end
        env.key(UI,"OnKeyDown","W"); env.key(UI,"OnKeyDown","A")
        env.key(UI,"OnKeyDown","SPACE")
        for _=1,2*fps do
            UI.OnUpdate(1/fps)
            local offsetX,offsetY=kartAnchor(UI,0,0)
            local x,y=UI.kart.point[4]-offsetX,UI.kart.point[5]-offsetY
            assert(x>=Track.wallInset and x<=Track.width-Track.wallInset and
                   y>=Track.wallInset and y<=Track.height-Track.wallInset,
                "interpolated kart stays inside wall clearance at "..fps.." FPS")
        end
        for _,field in ipairs({"x","y","heading","speed","tick","impacts","drifting",
            "driftDirection","driftTicks","driftTier","boostTicks","slipAngle","surface","steering","driftGraceTicks"}) do
            assert(UI.state[field]==reference[field],
                "render cadence changed simulation field "..field.." at "..fps.." FPS")
        end
        assert(UI.clock.frames==countdownTicks+2*fps and UI.clock.steps==countdownTicks+120 and
               UI.clock.droppedSeconds==0 and math.abs(UI.clock.accumulator)<1e-10 and
               math.abs(UI.clock.elapsedSeconds-5)<1e-10,
            "interpolation leaves fixed-step clock accounting intact at "..fps.." FPS")
        UI.Stop("cadence fixture done")
    end)
end

-- One short real-track integration: Space survives the key adapter and reaches
-- fixed-step physics. Tier HUD states are injected to avoid a long wall drive.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle(); UI.Start()
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    assert(UI.driftHud.text:find("Drift:",1,true),"fresh Start shows drift controls")
    finishCountdown(UI)
    UI.state.speed=150
    env.key(UI,"OnKeyDown","W")
    env.key(UI,"OnKeyDown","A")
    env.key(UI,"OnKeyDown","SPACE")
    UI.OnUpdate(1/60)
    assert(UI.active and UI.input.drift and UI.state.drifting and UI.state.driftTicks==1,
        "Space is handled without releasing capture and starts a moving turn drift")
    local tintWrites=UI.kart.vertexColorWrites
    for _=1,15 do UI.OnUpdate(1/60) end
    assert(UI.state.impacts==0 and UI.state.drifting and UI.driftHud.text:find("Drifting",1,true),
        "short drift remains on the real track and appears on the throttled HUD")
    assert(UI.kart.vertexColorWrites==tintWrites and rawget(UI.kart,"color")==nil,
        "drifting never tints the loaded art or replaces the image")
    UI.Stop("drift fixture")
    assert(not UI.input.drift and not UI.keys.SPACE,"Stop clears held and sampled Space")
    for _,tier in ipairs({1,2}) do
        UI.state.drifting=true; UI.state.driftTier=tier
        UI.state.driftTicks=tier==1 and env.namespace.Physics.DRIFT_TIER1_TICKS
            or env.namespace.Physics.DRIFT_TIER2_TICKS
        UI.state.driftGraceTicks=0
        UI.Stop("tier display fixture")
        assert(UI.driftHud.text:find("Tier "..tier.." ready",1,true),"charged tier has visible release feedback")
        local color=UI.meterFill.color
        UI.state.driftGraceTicks=1
        UI.Stop("correction display fixture")
        assert(UI.driftHud.text:find("Correcting",1,true),"correction grace has visible held-charge feedback")
        assert(UI.meterCaption.text:find("CHARGE HELD",1,true),"held charge is explained on the meter")
        for channel,value in ipairs(color) do
            assert(UI.meterFill.color[channel]==value,"correction preserves the earned tier color")
        end
    end
    UI.state.drifting=false; UI.state.driftTier=0; UI.state.driftGraceTicks=0; UI.state.boostTicks=20
    UI.Stop("boost display fixture")
    assert(UI.driftHud.text:find("BOOST",1,true),"remaining boost is visible on the stopped HUD")
    UI.Start()
    assert(not UI.state.drifting and UI.state.driftTicks==0 and UI.state.driftTier==0 and
           UI.state.boostTicks==0 and UI.state.slipAngle==0 and UI.state.steering==0
           and UI.state.driftGraceTicks==0,
        "fresh Start clears charge, correction grace, boost, slip and steering")
    assert(UI.driftHud.text:find("Drift:",1,true),"fresh Start clears old boost feedback")
    UI.Stop("drift fixture done")
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"drift feedback allocates no additional UI objects: "..key)
    end
end)

-- Meter feedback uses actual fixed-step charge/boost capacity and preallocated
-- widgets. Inject boundary states and render without a simulation tick.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle(); UI.Start()
    local boostCapacity=env.namespace.Physics.BOOST_TIER2_TICKS
    local halfBoost=boostCapacity/2
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    local function close(actual,expected,label)
        assert(math.abs(actual-expected)<1e-10,label)
    end
    local function caption(words)
        assert(UI.meterCaption.text:find(words,1,true),"missing meter caption: "..words)
    end
    local function sample(ticks,boost,surface,grace)
        UI.state.surface=surface or "road"
        UI.state.drifting=ticks>0
        UI.state.driftTicks=ticks
        UI.state.driftTier=0 -- Display must derive thresholds from actual charge.
        UI.state.driftGraceTicks=grace or 0
        UI.state.boostTicks=boost or 0
        local tick=UI.state.tick
        UI.OnUpdate(0)
        assert(UI.state.tick==tick,"meter render must not advance simulation")
    end
    assert(UI.window.width==856 and UI.window.height==762,"lap/checkpoint HUD and meter fit the expanded window")
    assert(UI.meterBackground.width==300 and UI.meterBackground.height==12,
        "meter has a fixed readable capacity")
    local point=UI.meterBackground.point
    assert(point[1]=="BOTTOMLEFT" and point[2]==UI.window and point[3]=="BOTTOMLEFT" and
           point[4]==28 and point[5]==52,"meter stays below the text HUD")
    for index,mark in ipairs({UI.meterTier1Mark,UI.meterTier2Mark}) do
        assert(mark.width==2 and mark.height==16,"tier markers remain visible above the fill")
        assert(mark.point[4]==28+150*index-1 and mark.point[5]==50,
            "tier markers identify half and full charge")
    end
    sample(0); caption("DRIFT CHARGE")
    assert(not UI.meterFill:IsShown(),"zero charge hides the fill")
    assert(UI.meterTier1Label.text=="Tier 1" and UI.meterTier2Label.text=="Tier 2",
        "charge meter labels explain its thresholds")
    sample(29); caption("DRIFT CHARGE")
    assert(UI.meterFill:IsShown(),"partial charge shows the fill")
    close(UI.meterFill.width,300*29/60,"charge before tier one")
    sample(30); caption("TIER 1 READY")
    close(UI.meterFill.width,150,"tier one reaches the first marker")
    sample(60); caption("TIER 2 READY")
    close(UI.meterFill.width,300,"tier two reaches full charge")
    local tierTwoColor=UI.meterFill.color
    sample(60,0,nil,12); caption("CHARGE HELD")
    close(UI.meterFill.width,300,"correcting retains full earned charge")
    for channel,value in ipairs(tierTwoColor) do
        assert(UI.meterFill.color[channel]==value,"holding retains tier-two color")
    end
    sample(30); caption("TIER 1 READY")
    local tierOneColor=UI.meterFill.color
    sample(30,0,nil,1); caption("CHARGE HELD")
    close(UI.meterFill.width,150,"correcting retains the earned first tier")
    for channel,value in ipairs(tierOneColor) do
        assert(UI.meterFill.color[channel]==value,"holding retains tier-one color")
    end
    sample(0,boostCapacity-1); caption("BOOST REMAINING")
    close(UI.meterFill.width,300*(boostCapacity-1)/boostCapacity,"boost uses the common maximum duration")
    assert(UI.meterTier1Label.text=="0.65 s" and UI.meterTier2Label.text=="1.3 s",
        "boost meter labels show remaining-time capacity")
    sample(0,halfBoost)
    close(UI.meterFill.width,150,"half remaining boost reaches the same halfway mark")
    local sizeWrites,colorWrites,textWrites=UI.meterFill.sizeWrites,
        UI.meterFill.colorWrites,UI.meterCaption.textWrites
    UI.OnUpdate(0)
    assert(UI.meterFill.sizeWrites==sizeWrites and UI.meterFill.colorWrites==colorWrites and
           UI.meterCaption.textWrites==textWrites,
        "unchanged meter state does not repeat geometry, color or caption setters")
    for _,surface in ipairs({"grass","wall"}) do
        sample(60,boostCapacity-1,surface,1)
        assert(not UI.meterFill:IsShown(),surface.." clears stale charge and boost feedback")
        caption("DRIFT CHARGE")
    end
    sample(0,halfBoost)
    UI.state.tick=1 -- A retained drive label requires an actual completed sample.
    UI.Stop("meter fixture")
    caption("Last drive | "); caption("BOOST REMAINING")
    close(UI.meterFill.width,150,"Stop retains the actual remaining boost")
    local frozenText=UI.meterCaption.text
    UI.OnUpdate(1)
    assert(UI.meterCaption.text==frozenText and UI.state.boostTicks==halfBoost,
        "stopped meter and boost stay frozen")
    UI.Start()
    assert(not UI.meterFill:IsShown() and UI.state.boostTicks==0,
        "fresh Start resets old boost and meter fill")
    caption("DRIFT CHARGE")
    assert(not UI.meterCaption.text:find("Last drive",1,true),"new drive clears the retained label")
    UI.Stop("meter fixture done")
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"meter updates allocated additional UI objects: "..key)
    end
end)

-- Surface feedback shares the existing drift label, including stopped samples.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle(); UI.Start()
    assert(UI.state.surface=="road" and UI.driftHud.text:find("Road | Drift:",1,true),
        "fresh drive reports road controls")
    finishCountdown(UI)
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    local walls={}
    for _,item in ipairs(env.textures) do
        local color=rawget(item,"color")
        if color and color[1]==0.42 and color[2]==0.44 and color[3]==0.48 then
            walls[#walls+1]={item=item,point=item.point,width=item.width,height=item.height,
                colorWrites=item.colorWrites}
        end
    end
    UI.state.x=400; UI.state.y=240; UI.state.speed=120
    UI.OnUpdate(1/60)
    UI.Stop("grass fixture")
    assert(UI.state.surface=="grass" and UI.driftHud.text:find("Last drive | Grass |",1,true) and
           UI.driftHud.text:find("Rejoin the road",1,true),
        "drivable grass has visible feedback in the retained sample")
    UI.Start()
    finishCountdown(UI)
    UI.state.x=env.namespace.Track.wallInset; UI.state.y=240
    UI.state.heading=math.pi; UI.state.speed=120
    UI.state.steering=1
    UI.state.drifting=true; UI.state.driftDirection=1
    UI.state.driftTicks=60; UI.state.driftTier=2; UI.state.driftGraceTicks=1
    UI.state.boostTicks=20; UI.state.slipAngle=0.2
    env.key(UI,"OnKeyDown","A")
    env.key(UI,"OnKeyDown","SPACE")
    UI.OnUpdate(1/60)
    assert(UI.state.steering==1 and not UI.state.drifting and
           UI.state.driftDirection==0 and UI.state.driftTicks==0 and
           UI.state.driftTier==0 and UI.state.driftGraceTicks==0 and
           UI.state.boostTicks==0 and UI.state.slipAngle==0,
        "wall contact clears drift, boost and slip while retaining the steering command")
    UI.Stop("wall fixture")
    assert(UI.state.surface=="wall" and UI.driftHud.text:find("Last drive | Wall |",1,true),
        "wall contact has visible feedback in the retained sample")
    UI.Start(); finishCountdown(UI); UI.OnUpdate(1/60); UI.Stop("surface fixture done")
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,"surface feedback allocates no additional UI objects: "..key)
    end
    for _,wall in ipairs(walls) do
        assert(wall.item.point==wall.point and wall.item.width==wall.width and
               wall.item.height==wall.height and wall.item.colorWrites==wall.colorWrites,
            "wall strips remain static across driving and restarting")
    end
end)

for _,mode in ipairs({"missing", "throws"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart")
        UI.Toggle(); UI.Start(); UI.OnUpdate(1/60)
        assert(UI.active and UI.state.tick==1,"optional snapping APIs cannot block driving: "..mode)
        assert(UI.objects.frames==UI_FRAMES and UI.objects.textures==UI_TEXTURES and UI.objects.fontStrings==UI_FONTS,
            "snapping fallback preserves UI object budget: "..mode)
        assert(sceneLayerCalls(env,UI)==2,
            "grass and kart outline priorities remain explicit when snapping is unavailable: "..mode)
    end,nil,mode)
end

local summary
withMock({schemaVersion=1, custom={keep=true}}, false, function(env,UI)
    local originalDB=AzerothKartDB
    env.fire("ADDON_LOADED","UnrelatedAddon")
    assert(not UI.window,"unrelated ADDON_LOADED must not create UI")
    assert(AzerothKartDB==originalDB,"unrelated load must not repair saves")
    assert(#env.frames==1,"bootstrap creates only its event frame")
    local bootstrapFrames=env.counts.frames
    env.fire("ADDON_LOADED","AzerothKart")
    assert(UI.window and not UI.window:IsShown(),"load creates hidden probe window")
    assert(AzerothKartDB==originalDB and AzerothKartDB.custom.keep,
        "valid unknown save fields must survive initialization")
    assert(not env.frames[1].events.ADDON_LOADED,"load event unregisters after own load")
    for _,event in ipairs({"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
                          "PLAYER_LEAVING_WORLD", "PLAYER_LOGOUT"}) do
        assert(env.frames[1].events[event],"missing lifecycle registration: "..event)
    end
    assert(UI.objects.frames==env.counts.frames-bootstrapFrames,"frame counter matches wrappers")
    assert(UI.objects.textures==env.counts.textures,"texture counter matches wrappers")
    assert(UI.objects.fontStrings==env.counts.fontStrings,"font counter matches wrappers")
    local counts={frames=env.counts.frames,textures=env.counts.textures,
                  fontStrings=env.counts.fontStrings}
    local snappingCalls,drawLayerCalls=env.snappingCalls,sceneLayerCalls(env,UI)
    local function assertPooled()
        assert(env.snappingCalls==snappingCalls and sceneLayerCalls(env,UI)==drawLayerCalls,
            "updates/reopen never reconfigure snapping or draw priority")
        for kind,count in pairs(counts) do
            assert(env.counts[kind]==count,"UI object count grew: "..kind)
        end
    end
    local held=UI.keys
    local function assertReleased(reason)
        assert(not UI.active,reason..": drive stopped")
        assert(UI.window.keyboard==false,reason..": keyboard disabled")
        assert(UI.keys==held and next(held)==nil,reason..": held table cleared in place")
        assert(not UI.input.accelerate and not UI.input.brake and
               not UI.input.left and not UI.input.right and not UI.input.drift,
               reason..": sampled input cleared")
    end
    local function start()
        env.focus=nil; env.focused=true; env.mouseInside=true; env.combat=false
        if not UI.window:IsShown() then UI.Toggle() end
        UI.Start()
        assert(UI.active and UI.window.keyboard,"deliberate Start captures keyboard")
        assert(UI.window.propagate==false,"active input does not propagate")
        assert(UI.state.tick==0 and UI.state.speed==0,"restart resets simulation")
        assert(UI.clock.frames==0 and UI.clock.steps==0,"restart resets clock")
        assert(next(held)==nil,"restart clears prior held keys")
    end
    UI.Start()
    assert(not UI.active,"hidden window cannot capture keyboard")
    UI.Toggle(); env.focus={}; UI.Start()
    assert(not UI.active,"text input focus prevents Start capture")
    env.focus=nil
    start()
    finishCountdown(UI)
    env.key(UI,"OnKeyDown","W")
    env.key(UI,"OnKeyDown","UP")
    env.key(UI,"OnKeyUp","W")
    UI.OnUpdate(1/60)
    assert(UI.input.accelerate and UI.state.speed>0,
        "releasing W must not clear separately held Up")
    env.key(UI,"OnKeyUp","UP")
    UI.OnUpdate(1/60)
    assert(not UI.input.accelerate,"releasing both aliases clears throttle")
    for _,key in ipairs({"ESCAPE","ENTER","NUMPADENTER"}) do
        start(); env.key(UI,"OnKeyDown","W"); UI.OnUpdate(1/60)
        env.key(UI,"OnKeyDown",key)
        assertReleased("keyboard exit "..key)
    end
    start(); env.key(UI,"OnKeyDown","A"); UI.Stop("test")
    assertReleased("Stop")
    start(); UI.window:Hide(); assertReleased("OnHide")
    start(); finishCountdown(UI)
    env.key(UI,"OnKeyDown","W"); UI.OnUpdate(1/60)
    local stopState,stopClock,stopTicks=UI.state,UI.clock,UI.race.totalTicks
    assert(UI.stopButton:IsEnabled() and not UI.startButton:IsEnabled(),
        "Stop is enabled while racing and Start cannot discard the active run")
    env.fire("GLOBAL_MOUSE_DOWN","LeftButton")
    -- Also exercise the old callback directly: even a stray forwarded event
    -- cannot disable Stop before its actual OnClick.
    UI.HandleEvent("GLOBAL_MOUSE_DOWN","LeftButton")
    assert(UI.active and UI.stopButton:IsEnabled(),"mouse-down leaves Stop clickable")
    UI.stopButton.scripts.OnClick(UI.stopButton); assertReleased("Stop button")
    assert(UI.race.status=="stopped" and UI.state==stopState and UI.clock==stopClock and
           UI.race.totalTicks==stopTicks and UI.summary:IsShown() and
           UI.startButton:IsEnabled() and not UI.stopButton:IsEnabled() and
           UI.trackButton:IsEnabled(),"Stop ends the run and retains its partial result")
    assert(not UI.summaryHint.text:find("Controls released",1,true),
        "results offer deliberate next actions without a misleading pause label")
    UI.OnUpdate(1)
    assert(UI.state==stopState and UI.clock==stopClock and UI.race.totalTicks==stopTicks,
        "stopped updates cannot advance race or replace the sample")
    local closeButton
    for _,frame in ipairs(env.frames) do
        if frame.text=="Close" then closeButton=frame end
    end
    assert(closeButton and closeButton.scripts.OnClick,"clickable Close control exists")
    start(); closeButton.scripts.OnClick(closeButton); assertReleased("Close button")
    assert(not UI.window:IsShown(),"Close hides window")
    start(); UI.Toggle(); assertReleased("toggle closed")
    start(); finishCountdown(UI); env.key(UI,"OnKeyDown","W")
    env.key(UI,"OnKeyDown","SPACE")
    local retainedClock=UI.clock
    local retainedRace=UI.race
    local retainedState=UI.state
    for _,key in ipairs({"F","M","1","TAB","LSHIFT","RSHIFT","LCTRL","RCTRL","LALT","RALT","UNKNOWN"}) do
        env.key(UI,"OnKeyDown",key); env.key(UI,"OnKeyUp",key)
        assert(UI.active and UI.window.keyboard and UI.window.propagate==false and
               UI.keys.W and UI.keys.SPACE and UI.clock==retainedClock and
               UI.race==retainedRace and UI.state==retainedState and not UI.summary:IsShown(),
            "unassigned key preserves run and held input: "..key)
    end
    for _,inside in ipairs({true,false}) do
        env.mouseInside=inside
        for _,button in ipairs({"LeftButton","RightButton","MiddleButton","Button4"}) do
            env.fire("GLOBAL_MOUSE_DOWN",button); UI.HandleEvent("GLOBAL_MOUSE_DOWN",button)
            assert(UI.active and UI.stopButton:IsEnabled() and UI.keys.W and UI.keys.SPACE and
                   UI.state==retainedState and UI.race==retainedRace and UI.clock==retainedClock,
                "incidental click keeps controls and run: "..button)
        end
    end
    UI.OnUpdate(1/60)
    assert(UI.active and UI.input.accelerate and UI.input.drift and UI.state.speed>0 and
           UI.race.totalTicks==retainedRace.totalTicks+1,"run continues after incidental input")
    env.key(UI,"OnKeyUp","W"); env.key(UI,"OnKeyUp","SPACE"); UI.OnUpdate(1/60)
    assert(not UI.input.accelerate and not UI.input.drift,"held keys still release normally")
    start(); env.focus={}; UI.OnUpdate(1/60); assertReleased("chat edit box focus")
    start(); env.focus={}; env.key(UI,"OnKeyDown","W")
    assertReleased("chat focus noticed by keyboard callback")
    start(); env.focused=false; UI.OnUpdate(1/60); assertReleased("application focus loss")
    env.focused=true; UI.OnUpdate(1/60)
    assert(not UI.active,"application focus regain must not resume")
    start(); _G.IsGameWindowFocused=nil; UI.OnUpdate(1/60)
    assert(UI.active,"optional focus API absence must not crash")
    _G.IsGameWindowFocused=function() return env.focused end
    UI.Stop("optional API probe")
    for _,event in ipairs({"PLAYER_LEAVING_WORLD","PLAYER_LOGOUT"}) do
        start(); env.key(UI,"OnKeyDown","W"); UI.OnUpdate(1/60)
        env.fire(event); assertReleased(event)
    end
    start(); env.key(UI,"OnKeyDown","W"); UI.OnUpdate(1/60)
    env.combat=true
    local releaseCalls=env.keyboardReleaseCalls
    local interruptionOutput=#env.output
    local interruptedTick=UI.state.tick
    env.fire("PLAYER_REGEN_DISABLED")
    assertReleased("combat event")
    assert(not UI.window:IsShown(),"combat closes the racing window")
    assert(UI.result.status=="interrupted" and UI.result.reason=="Game interrupted by combat",
        "combat keeps the explicit interruption result")
    assert(UI.result.tick==interruptedTick and UI.stopReason==UI.result.reason,
        "hiding preserves the terminal tick/reason")
    local result=UI.result
    env.fire("PLAYER_REGEN_DISABLED"); UI.OnUpdate(1); UI.InterruptCombat()
    assert(UI.result==result and UI.state.tick==interruptedTick,"interruption is terminal once")
    assert(#env.output==interruptionOutput+1,"combat interruption note emitted once")
    assert(env.keyboardReleaseCalls>releaseCalls,"combat explicitly disables keyboard")
    assert(UI.pendingPropagationRelease,"combat defers propagation setter")
    local setters=env.propagationCalls
    UI.Start(); UI.ReleaseInput(); UI.Create(); UI.OnUpdate(1/60)
    assert(env.propagationCalls==setters,"combat paths never invoke propagation setter")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
    assert(not UI.pendingPropagationRelease and UI.window.propagate,
        "combat end restores propagation")
    assert(not UI.active,"combat end must not resume")
    UI.Toggle()
    assert(UI.result==result and UI.status.text:find("Game interrupted by combat",1,true),
        "deliberate reopen retains interruption note until new Start")
    local interruptedClock, interruptedState = UI.clock, UI.state
    local clockValues, stateValues = {}, {}
    for key,value in pairs(interruptedClock) do clockValues[key]=value end
    for key,value in pairs(interruptedState) do stateValues[key]=value end
    local interruptedHud = UI.hud.text
    local function assertRetained(label)
        assertReleased(label)
        assert(UI.result==result and UI.result.tick==interruptedTick,
            label..": terminal result identity/tick retained")
        assert(UI.stopReason==result.reason and UI.status.text:find(result.reason,1,true),
            label..": interruption stays visible and authoritative")
        assert(UI.clock==interruptedClock and UI.state==interruptedState,
            label..": stopped clock/state retained")
        for key,value in pairs(clockValues) do
            assert(UI.clock[key]==value,label..": stopped clock changed "..key)
        end
        for key,value in pairs(stateValues) do
            assert(UI.state[key]==value,label..": stopped state changed "..key)
        end
        assert(UI.hud.text==interruptedHud,label..": stopped HUD retained")
        assert(#env.output==interruptionOutput+1,label..": no duplicate interruption output")
        assertPooled()
    end
    for attempt=1,2 do
        UI.Toggle()
        assert(not UI.window:IsShown(),"repeated toggle closes interrupted window")
        assertRetained("toggle close "..attempt)
        local hiddenStatus=UI.status.text
        UI.Start()
        assert(UI.status.text==hiddenStatus,"hidden Start leaves terminal status unchanged")
        assertRetained("hidden Start "..attempt)
        UI.Toggle()
        assertRetained("toggle reopen "..attempt)
    end
    closeButton.scripts.OnClick(closeButton)
    assert(not UI.window:IsShown(),"Close button hides interrupted window")
    assertRetained("Close button")
    UI.Toggle()
    assertRetained("Close button reopen")
    UI.Stop("Idle stop after interruption")
    assertRetained("inactive Stop")
    local function refusedStart(label, reason)
        UI.Start()
        assertRetained(label)
        assert(UI.status.text:find(reason,1,true),label..": actual Start refusal stays visible")
    end
    env.combat=true
    refusedStart("combat Start refusal","Cannot start while in combat")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
    env.focus={}
    refusedStart("text focus Start refusal","Close text input before starting")
    env.focus=nil
    local textFocusAPI=GetCurrentKeyBoardFocus
    _G.GetCurrentKeyBoardFocus=nil
    refusedStart("missing text focus Start refusal","Input safety APIs unavailable")
    _G.GetCurrentKeyBoardFocus=textFocusAPI
    for _,method in ipairs({"EnableKeyboard","SetPropagateKeyboardInput"}) do
        local prior=UI.window[method]
        UI.window[method]=false
        refusedStart("missing "..method.." Start refusal","Input safety APIs unavailable")
        UI.window[method]=prior
    end
    start()
    assert(UI.result==nil and UI.clock~=interruptedClock,
        "successful explicit Start clears interrupted result and replaces clock")
    assert(not UI.status.text:find(result.reason,1,true),
        "successful Start clears visible interruption note")
    UI.Stop("Ordinary stop")
    assert(UI.stopReason=="Ordinary stop" and UI.status.text:find("Ordinary stop",1,true),
        "later ordinary stop uses its own reason")
    assert(not UI.status.text:find(result.reason,1,true),
        "later ordinary stop does not resurrect interruption note")
    closeButton.scripts.OnClick(closeButton)
    assert(UI.stopReason=="Closed" and not UI.status.text:find(result.reason,1,true),
        "later ordinary Close uses its own reason without stale interruption note")
    start(); env.combat=true; UI.OnUpdate(1/60)
    assertReleased("OnUpdate combat fallback")
    assert(not UI.window:IsShown(),"combat OnUpdate fallback also closes the window")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
    for _,api in ipairs({"InCombatLockdown","GetCurrentKeyBoardFocus"}) do
        UI.Stop("capability probe")
        local prior=_G[api]
        _G[api]=nil
        UI.Start()
        assert(not UI.active,"missing safety API prevents capture: "..api)
        _G[api]=prior
        UI.OnCombatEnded()
    end
    env.namespace.events.GLOBAL_MOUSE_DOWN=false
    if not UI.window:IsShown() then UI.Toggle() end
    UI.Start()
    assert(UI.active,"global mouse event is no longer a capture dependency")
    env.namespace.events.GLOBAL_MOUSE_DOWN=true
    for _,method in ipairs({"EnableKeyboard","SetPropagateKeyboardInput"}) do
        UI.Stop("keyboard capability probe")
        local prior=UI.window[method]
        UI.window[method]=false
        UI.Start()
        assert(not UI.active,"missing keyboard method prevents capture: "..method)
        UI.window[method]=prior
    end
    start()
    local outputBefore=#env.output
    for _=1,1000 do UI.OnUpdate(1/144) end
    assert(UI.clock.frames==1000 and UI.clock.steps>0,"measurable clock advances")
    UI.OnUpdate(1)
    assert(UI.clock.lastSteps<=UI.clock.maxSteps and UI.clock.droppedSeconds>0,
        "frame hitch is bounded and lost time measured")
    assert(#env.output==outputBefore,"OnUpdate must not print chat diagnostics")
    assertPooled()
    UI.Stop("pool probe")
    for _=1,5 do UI.Toggle(); UI.Toggle(); UI.Create() end
    assertPooled()
    UI.ReportProbe()
    assert(#env.output>outputBefore,"explicit probe reports measurable output")
    assert(env.combatPropagationCalls==0,"all mock combat paths avoid propagation setters")
    summary=("mock UI: frames=%d textures=%d fontStrings=%d; tickFrames=%d; combatPropagationCalls=%d")
        :format(UI.objects.frames,UI.objects.textures,UI.objects.fontStrings,
                1001,env.combatPropagationCalls)
end)

withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local function probe()
        local first=#env.output+1
        SlashCmdList.AZEROTHKART("probe")
        assert(#env.output==first+5,"explicit probe has six bounded report lines")
        return env.output[first+1],env.output[first+2]
    end
    local _,duration=probe()
    assert(duration:find("activeFrameSeconds=0.0000 simulatedSeconds=0.0000 callbackHz=0.00",1,true),
        "probe before Start has finite zero timing metrics")
    UI.Toggle(); UI.Start()
    assert(UI.hud.text=="Speed: 0 | Ticks: 0 | Dropped: 0.000s | Sample: 0.0s",
        "Start immediately displays a fresh sample")
    env.key(UI,"OnKeyDown","W")
    UI.OnUpdate(1/60+0.004)
    assert(UI.state.tick==1 and UI.hud.text:find("Ticks: 0",1,true),
        "active HUD updates stay throttled")
    UI.Stop("timing sample")
    assert(UI.hud.text:find("Ticks: 1",1,true) and UI.hud.text:find("Speed: 0",1,true),
        "Stop flushes final tick and neutral countdown speed before the next HUD interval")
    local clock=UI.clock
    assert(math.abs(clock.accumulator-0.004)<1e-10,"Stop retains final fractional remainder")
    assert(math.abs(clock.elapsedSeconds-clock.steps*clock.dt-clock.droppedSeconds-clock.accumulator)<1e-10,
        "stopped timing sample accounts for all delivered frame time")
    local counters={}
    for key,value in pairs(clock) do counters[key]=value end
    local hud=UI.hud.text
    local frameLine,timeLine=probe()
    assert(timeLine:find("activeFrameSeconds=0.0207 simulatedSeconds=0.0167 callbackHz=48.39",1,true),
        "probe reports measured frame duration, executed simulation time and callback cadence")
    local output=#env.output
    for _=1,10 do UI.OnUpdate(1) end
    UI.Toggle(); UI.Toggle()
    for key,value in pairs(counters) do
        assert(clock[key]==value,"stopped/reopened sample changed "..key)
    end
    assert(UI.hud.text==hud and #env.output==output,"stopped samples retain their HUD text and do not print automatically")
    local repeatedFrame,repeatedTime=probe()
    assert(repeatedFrame==frameLine and repeatedTime==timeLine,"repeated stopped reports retain identical timing")
    UI.Start()
    assert(UI.clock~=clock and UI.clock.elapsedSeconds==0 and UI.clock.accumulator==0,
        "fresh Start replaces the frozen clock and its remainder")
    assert(UI.hud.text=="Speed: 0 | Ticks: 0 | Dropped: 0.000s | Sample: 0.0s",
        "fresh Start clears the old stopped HUD immediately")
    local writes=UI.hud.textWrites
    output=#env.output
    for _=1,144 do UI.OnUpdate(1/144) end
    assert(UI.hud.textWrites>writes and UI.hud.textWrites-writes<=4,
        "HUD writes stay bounded at four per simulated second during motion")
    UI.OnUpdate(0.537)
    UI.Stop("hitch timing sample")
    assert(UI.clock.lastSteps==5 and UI.clock.droppedSeconds>0.4,"hitch keeps bounded catch-up")
    assert(UI.hud.text:find("Ticks: "..UI.state.tick,1,true),"hitch Stop flushes final HUD")
    assert(math.abs(UI.clock.elapsedSeconds-UI.clock.steps*UI.clock.dt-
           UI.clock.droppedSeconds-UI.clock.accumulator)<1e-10,"hitch sample retains all elapsed time")
    assert(#env.output==output,"active sampling and Stop do not print periodic chat")
end)

-- Optional profiler readings are diagnostic only; normal updates do no reads.
withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle(); UI.Start()
    for _=1,10 do UI.OnUpdate(1/60) end
    assert(not UI.performanceEnabled and UI.performance==nil and env.profileCalls==0,
        "profiling is off by default with zero profiler calls")
    local clock=UI.clock
    SlashCmdList.AZEROTHKART("perf on")
    assert(UI.active and UI.clock==clock and not UI.performanceEnabled,
        "changing profiling during capture is refused without changing driving")
    UI.Stop("profile setup")
    local before=#env.output
    SlashCmdList.AZEROTHKART("  perf  ")
    assert(#env.output==before+3 and env.output[before+1]:find("state=not-started",1,true),
        "explicit perf query has three bounded lines and labels absent samples")
    SlashCmdList.AZEROTHKART("perf nonsense")
    assert(UI.window:IsShown() and env.output[#env.output]:find("Usage:",1,true),
        "invalid perf arguments show usage rather than toggling the window")
    SlashCmdList.AZEROTHKART(" perf on ")
    assert(UI.performanceEnabled and env.profileCalls==1,"arming checks one valid clock reading")
    UI.Start()
    local sample=UI.performance
    before=#env.output
    env.key(UI,"OnKeyDown","W")
    for frame=1,650 do
        if frame==100 then env.key(UI,"OnKeyDown","A") end
        if frame==200 then env.key(UI,"OnKeyUp","A") end
        UI.OnUpdate(1/60)
    end
    assert(sample.attempts==600 and sample.samples==600 and sample.invalid==0,
        "profiled sample caps at 600 active updates")
    assert(env.profileCalls==1801,"no profiler calls occur after the window is full")
    assert(math.abs(sample.simulationMs-6)<1e-8 and math.abs(sample.renderMs-6)<1e-8 and
           math.abs(sample.totalMs-12)<1e-8,"profile phases accumulate known mock milliseconds")
    assert(#env.output==before,"sampling/completion never prints per-frame chat")
    assert(UI.objects.frames==UI_FRAMES and UI.objects.textures==UI_TEXTURES and UI.objects.fontStrings==UI_FONTS,
        "profiling creates no UI objects")
    local state={}
    for key,value in pairs(UI.state) do state[key]=value end
    UI.Stop("profile stopped"); UI.Toggle(); UI.Toggle()
    for _=1,10 do UI.OnUpdate(1) end
    assert(UI.performance==sample and sample.samples==600 and env.profileCalls==1801,
        "Stop and reopen freeze the same diagnostic window")
    before=#env.output
    SlashCmdList.AZEROTHKART("perf")
    assert(#env.output==before+3 and env.output[before+1]:find("state=complete",1,true),
        "completed window is reported explicitly")
    assert(env.output[before+2]:find("totalAvg=0.0200",1,true) and
           env.output[before+3]:find("exclusiveCPU=false",1,true),"timing units/scope are explicit")
    SlashCmdList.AZEROTHKART("perf off")
    assert(not UI.performanceEnabled and UI.performance==sample,"off retains the stopped result")
    UI.Start()
    assert(UI.performance==nil,"a new unprofiled Start clears the prior diagnostic window")
    env.key(UI,"OnKeyDown","W")
    for frame=1,650 do
        if frame==100 then env.key(UI,"OnKeyDown","A") end
        if frame==200 then env.key(UI,"OnKeyUp","A") end
        UI.OnUpdate(1/60)
    end
    for key,value in pairs(state) do
        assert(UI.state[key]==value,"profiling altered deterministic driving field "..key)
    end
    assert(env.profileCalls==1801,"unprofiled drive never reads the profiler")
    UI.Stop("fresh profile")
    SlashCmdList.AZEROTHKART("perf on"); UI.Start()
    assert(UI.performance~=sample and UI.performance.attempts==0,
        "a fresh profiled Start creates a new empty window")
end)

withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle()
    local reader=debugprofilestop
    for _,mode in ipairs({"missing", "throws", "string", "nan", "infinity", "negative"}) do
        if mode=="missing" then _G.debugprofilestop=nil
        else _G.debugprofilestop=function()
            if mode=="throws" then error("mock timer unavailable") end
            if mode=="string" then return "invalid" end
            if mode=="nan" then return 0/0 end
            if mode=="infinity" then return math.huge end
            return -1
        end end
        SlashCmdList.AZEROTHKART("perf on")
        assert(not UI.performanceEnabled,"invalid arm reading rejected: "..mode)
        UI.Start(); UI.OnUpdate(1/60)
        assert(UI.active and UI.state.tick==1,"unavailable profiler cannot block driving: "..mode)
        UI.Stop("unavailable profile")
    end
    -- A reader can fail after arming. Invalid attempts are bounded and must not
    -- become valid zero-cost samples or abort the fixed-step simulation.
    local calls=0
    _G.debugprofilestop=function()
        calls=calls+1
        if calls==1 then return 10 end
        if calls%3==0 then error("mock timer reset/error") end
        return "bad"
    end
    SlashCmdList.AZEROTHKART("perf on"); UI.Start()
    local before=#env.output
    for _=1,610 do UI.OnUpdate(1/60) end
    assert(UI.active and UI.state.tick==610,"clock errors do not stop simulation")
    assert(UI.performance.attempts==600 and UI.performance.samples==0 and UI.performance.invalid==600,
        "invalid reads consume the bounded attempt budget without fabricated samples")
    assert(calls==1801 and #env.output==before,"invalid sampling remains bounded and silent")
    UI.Stop("invalid sample retained")
    _G.debugprofilestop=reader
    SlashCmdList.AZEROTHKART("perf on"); UI.Start()
    local validTimestamp=env.namespace.Performance.validTimestamp
    env.namespace.Performance.validTimestamp=function() error("mock opaque timestamp cannot be compared") end
    for _=1,610 do UI.OnUpdate(1/60) end
    env.namespace.Performance.validTimestamp=validTimestamp
    assert(UI.active and UI.state.tick==610 and UI.performance.attempts==600 and
           UI.performance.invalid==600 and UI.performance.samples==0,
        "arithmetic/validation refusal remains bounded and cannot interrupt driving")
end)

-- Combat onset must also clear an open stopped window. It is not a new
-- interruption of a drive that already ended, and must retain its sample.
for _,scenario in ipairs({"never started", "stopped", "interrupted"}) do
    withMock(nil, false, function(env,UI)
        env.combat=true; env.fire("PLAYER_REGEN_DISABLED")
        assert(not UI.window,"combat before own load does not construct UI")
        env.combat=false
        env.fire("ADDON_LOADED","AzerothKart")
        UI.Toggle()
        if scenario~="never started" then
            UI.Start()
            env.key(UI,"OnKeyDown","W")
            UI.OnUpdate(1/60+0.004)
            if scenario=="interrupted" then
                env.combat=true; env.fire("PLAYER_REGEN_DISABLED")
                env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
                UI.Toggle()
            else
                UI.Stop("Mouse click released controls")
            end
        end
        local clock, state, result=UI.clock, UI.state, UI.result
        local reason, hud, status=UI.stopReason, UI.hud.text, UI.status.text
        local counters, stateValues={}, {}
        for key,value in pairs(clock or {}) do counters[key]=value end
        for key,value in pairs(state) do stateValues[key]=value end
        local output, allocations=#env.output, {}
        for key,value in pairs(env.counts) do allocations[key]=value end
        env.combat=true; env.fire("PLAYER_REGEN_DISABLED")
        assert(not UI.window:IsShown(),scenario..": combat hides stopped window")
        env.fire("PLAYER_REGEN_DISABLED"); UI.InterruptCombat(); UI.OnUpdate(1)
        assert(not UI.active and UI.window.keyboard==false and next(UI.keys)==nil,
            scenario..": combat leaves capture released")
        assert(UI.clock==clock and UI.state==state and UI.result==result,
            scenario..": combat preserves stopped sample/result identities")
        for key,value in pairs(counters) do
            assert(clock[key]==value,scenario..": combat changed stopped clock "..key)
        end
        for key,value in pairs(stateValues) do
            assert(state[key]==value,scenario..": combat changed stopped state "..key)
        end
        assert(UI.stopReason==reason and UI.hud.text==hud and UI.status.text==status,
            scenario..": stopped reason/HUD retained")
        assert(#env.output==output,scenario..": no new interrupted-drive announcement")
        assert(env.combatPropagationCalls==0,scenario..": combat never sets propagation")
        for key,value in pairs(allocations) do
            assert(env.counts[key]==value,scenario..": combat allocated UI objects")
        end
        -- A deliberate reopen can still inspect the old note and Start refusal.
        UI.Toggle(); UI.Start(); UI.OnUpdate(1)
        assert(UI.window:IsShown() and not UI.active,
            scenario..": explicit combat-time inspection stays inactive")
        assert(UI.status.text:find("Cannot start while in combat",1,true),
            scenario..": combat Start refusal remains visible")
        assert(UI.result==result and #env.output==output,
            scenario..": inspection cannot duplicate or replace a result")
        UI.Toggle()
        env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
        assert(not UI.window:IsShown() and not UI.active,
            scenario..": combat ending cannot reopen or resume")
    end)
end

withMock(nil, false, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    assert(not env.namespace.events.GLOBAL_MOUSE_DOWN,"unsupported event not claimed available")
    assert(not env.namespace.eventFailures,"unused mouse event is never registered")
    UI.Toggle(); UI.Start()
    assert(UI.active,"unsupported global mouse event cannot block a drive")
end, "GLOBAL_MOUSE_DOWN")

-- Cold load and toggle in combat may construct ordinary UI, but cannot capture
-- input or invoke the guarded propagation setter. Real API legality is pending.
withMock(nil, true, function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    assert(UI.window and not UI.window:IsShown(),"combat startup creates hidden probe UI")
    assert(UI.window.keyboard==false,"combat startup keeps keyboard disabled")
    UI.Create(); UI.Toggle(); UI.Start()
    assert(not UI.active,"combat cannot start capture")
    assert(env.combatPropagationCalls==0,"combat startup never sets propagation")
    env.combat=false; env.fire("PLAYER_REGEN_ENABLED")
    assert(not UI.active,"deferred startup does not resume a drive")
    assert(UI.window.propagate,"combat end restores propagation after cold load")
    if UI.window:IsShown() then UI.Toggle() end
    UI.Toggle()
    assert(UI.window and UI.window:IsShown(),"explicit toggle can create after combat")
end)

for _,fixture in ipairs({
    {value=false}, {value="bad save"}, {value=42},
    {value={custom="preserve"}},
    {value={schemaVersion="bad",custom="preserve"}},
    {value={schemaVersion=0/0,custom="preserve"}},
    {value={schemaVersion=math.huge,custom="preserve"}},
    {value={schemaVersion=0,custom="preserve"}},
    {value={schemaVersion=1.5,custom="preserve"}},
    {value={schemaVersion=42,custom="preserve"}},
}) do
    local originalSchema=type(fixture.value)=="table" and fixture.value.schemaVersion or nil
    withMock(fixture.value, false, function(env)
        env.fire("ADDON_LOADED","AzerothKart")
        if type(fixture.value)~="table" then
            assert(AzerothKartDB==fixture.value,"malformed root save is preserved for recovery")
            assert(not env.namespace.SoloRecords.GetView("test_oval").writable,"malformed root makes scores read-only")
            return
        end
        assert(type(AzerothKartDB)=="table","table save remains a table")
        local expected=originalSchema
        if expected==nil then expected=1 end
        local actual=AzerothKartDB.schemaVersion
        assert(actual==expected or (actual~=actual and expected~=expected),
            "M0 schema marker initialized only when absent; existing values preserved")
        if type(fixture.value)=="table" then
            assert(AzerothKartDB==fixture.value and AzerothKartDB.custom=="preserve",
                "save repair preserves unknown fields in place")
        end
    end)
end
-- Kart sprite (Claude visual scope). The goblin drag car loads once at creation,
-- is tinted with vertex colors and is never replaced by SetColorTexture; every
-- failed load keeps the original primitive. Mock calls only: actual client
-- alpha, filtering, facing and missing-file semantics remain pending.
-- Loaded art stays untinted in every phase (the drift/boost effects show it);
-- only the primitive fallback keeps phase colours.
local NEUTRAL={1,1,1}
local primitiveColors={[0]={0.98,0.54,0.14},{0.35,0.65,1.00},{1.00,0.86,0.20},{1.00,0.35,0.78},
    {0.20,1.00,0.88}}
local function expectedTint(state)
    return state.boostTicks>0 and 4 or (state.drifting and 1+state.driftTier or 0)
end
local function sameRGB(actual,expected)
    return type(actual)=="table" and math.abs(actual[1]-expected[1])<1e-12 and
        math.abs(actual[2]-expected[2])<1e-12 and math.abs(actual[3]-expected[3])<1e-12 and
        actual[4]==1
end
local function showPhase(UI,tint,label)
    -- Inject a stopped phase and redraw through the existing Stop path.
    local state=UI.state
    state.boostTicks=tint==4 and 20 or 0
    state.drifting=tint>=1 and tint<=3
    state.driftTier=state.drifting and tint-1 or 0
    state.driftTicks=({[0]=0,10,30,60,0})[tint]
    state.driftGraceTicks=0
    UI.Stop(label)
    assert(expectedTint(UI.state)==tint,"phase fixture maps to tint "..tint)
end
local function sameCounts(env,counts,label)
    for key,value in pairs(counts) do
        assert(env.counts[key]==value,label..": "..key)
    end
end
local spriteSummary
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local P=env.namespace.Presentation
    local sprite=P.KART_SPRITES[P.DEFAULT_KART]
    assert(P.DEFAULT_KART=="goblin_mortar_trike" and UI.kartSprite==sprite and sprite.path==KART_PATH and
           sprite.frames==64 and sprite.columns==8,
        "the Goblin Mortar Trike directional sheet is the active default kart visual")
    assert(UI.kart.texturePath==KART_PATH and UI.kart.textureWrites==1 and loads(env,KART_PATH)==1,
        "creation loads the kart sheet once from its declared addon path")
    assert(rawget(UI.kart,"color")==nil and sameRGB(UI.kart.vertexColor,NEUTRAL),
        "the loaded sprite starts untinted and is never filled with a solid color")
    assert(UI.kart.layer=="OVERLAY" and UI.kart.parent==UI.canvas,
        "the sprite stays on the canvas above background, road and marker layers")
    assert(UI.kart.width==41 and UI.kart.height==41,"Test Oval draws one 41-unit frame at scale 1")
    local spawn=UI.state
    assert(UI.kart.point[1]=="CENTER" and UI.kart.point[2]==UI.canvas and
           UI.kart.point[3]=="BOTTOMLEFT" and UI.kart.point[4]==spawn.x+3 and
           UI.kart.point[5]==spawn.y and kartFaces(env,UI,spawn.heading) and
           UI.kart.rotation==0,
        "the frame for the spawn heading sits at its pivot offset from the kart center, unrotated")
    -- Every heading shows its nearest frame; the crop is only rewritten when
    -- the frame changes, and the image is never rotated.
    local step=2*math.pi/64
    for _,heading in ipairs({0,0.2*step,0.6*step,math.pi/2,math.pi,-math.pi/2,3*math.pi,-0.51*step}) do
        UI.state.heading=heading; UI.previousState=UI.state
        local calls=UI.kart.texCoordWrites
        local frameBefore=UI.kartFrame
        UI.Stop("heading fixture")
        assert(kartFaces(env,UI,heading),"heading "..heading.." shows its nearest frame")
        assert(UI.kart.texCoordWrites==calls+(UI.kartFrame==frameBefore and 0 or 1),
            "the frame crop is written only when the frame changes")
    end
    assert(UI.kartFrame==63 and UI.kart.rotation==0,"slightly clockwise of east is the last frame")
    UI.state.heading=spawn.heading; UI.previousState=UI.state; UI.Stop("heading fixture done")
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    UI.Toggle()
    local writes=UI.kart.vertexColorWrites
    for _,tint in ipairs({1,2,3,4,0,4,1,0}) do
        showPhase(UI,tint,"sprite phase fixture")
        assert(sameRGB(UI.kart.vertexColor,NEUTRAL) and UI.kart.vertexColorWrites==writes,
            "phase "..tint.." leaves the loaded art untinted")
        assert(rawget(UI.kart,"color")==nil and UI.kart.texturePath==KART_PATH and
               UI.kart.textureWrites==1,
            "phase "..tint.." neither reloads nor replaces the sprite image")
    end
    assert(UI.SelectTrack("mirage_raceway"))
    assert(math.abs(UI.kart.width-61.5)<1e-9 and math.abs(UI.kart.height-61.5)<1e-9,
        "Mirage scales the whole frame quad uniformly")
    UI.Start(); UI.OnUpdate(1/60); UI.Stop("sprite reuse fixture")
    assert(UI.SelectTrack("test_oval") and UI.kart.width==41 and UI.kart.height==41,
        "returning to Test Oval restores the unscaled quad")
    UI.Start(); UI.Stop("sprite reuse fixture")
    assert(loads(env,KART_PATH)==1 and UI.kart.textureWrites==1 and rawget(UI.kart,"color")==nil,
        "starts and map switches reuse the loaded sprite; no per-run or per-frame texture load")
    assert(UI.objects.frames==UI_FRAMES and UI.objects.textures==UI_TEXTURES and UI.objects.fontStrings==UI_FONTS,
        "the sprite reuses the existing kart texture without new UI objects")
    sameCounts(env,counts,"sprite phases and switches allocate no UI objects")
end)

-- A single-image sprite keeps the rotated path: one north-facing image
-- centered on the kart and turned by heading - pi/2.
withMock(nil,false,function(env,UI)
    local P=env.namespace.Presentation
    P.DEFAULT_KART=singleImageKart(env)
    env.fire("ADDON_LOADED","AzerothKart")
    assert(UI.kartSprite==P.KART_SPRITES.basic and UI.kart.texturePath==SINGLE_PATH and
           loads(env,SINGLE_PATH)==1 and loads(env,KART_PATH)==0 and UI.kartFrame==nil,
        "a single-image default loads only its own file")
    assert(UI.kart.width==20 and UI.kart.height==40 and UI.kart.point[4]==UI.state.x and
           UI.kart.point[5]==UI.state.y and UI.kart.rotation==UI.state.heading-math.pi/2 and
           UI.kart.texCoords[1]==0 and UI.kart.texCoords[2]==1 and
           UI.kart.texCoords[3]==0 and UI.kart.texCoords[4]==1,
        "the single image is centered on the kart and rotated, never cropped")
    UI.Toggle()
    assert(UI.SelectTrack("mirage_raceway") and math.abs(UI.kart.width-30)<1e-9 and
           math.abs(UI.kart.height-60)<1e-9,"Mirage scales the single-image quad uniformly")
end)

-- Each refused sprite path keeps the primitive, its 17x31 footprint and the
-- original drift/boost colors, with no load retry per frame, run or map.
for _,mode in ipairs({"false","nil","throws","missing","tint missing","tint throws","uv missing","uv throws",
                      "rotation missing","rotation throws"}) do
    withMock(nil,false,function(env,UI)
        if mode~="false" and mode~="nil" and mode~="throws" then
            env.onCreateTexture=function(item,parent,layer)
                if parent~=UI.canvas or layer~="OVERLAY" then return end
                if mode=="missing" then item.SetTexture=false
                elseif mode=="tint missing" then item.SetVertexColor=false
                elseif mode=="tint throws" then
                    item.SetVertexColor=function() error("mock tint API refuses") end
                elseif mode=="uv missing" then item.SetTexCoord=false
                elseif mode=="rotation missing" then item.SetRotation=false
                elseif mode=="rotation throws" then item.SetRotation=function() error("mock rotation API refuses") end
                else item.SetTexCoord=function() error("mock crop API refuses") end end
            end
        else env.textureModes={[KART_PATH]=mode} end
        env.fire("ADDON_LOADED","AzerothKart")
        local attempts=(mode=="missing" or mode=="tint missing" or mode=="uv missing" or mode=="rotation missing") and 0 or 1
        assert(UI.kartSprite==nil and loads(env,KART_PATH)==attempts,
            "refused sprite selects the primitive after one guarded attempt: "..mode)
        assert(UI.kart.width==17 and UI.kart.height==31,"primitive keeps its 17x31 body: "..mode)
        assert(sameRGB(UI.kart.color,primitiveColors[0]) and
               (rawget(UI.kart,"vertexColor")==nil or sameRGB(UI.kart.vertexColor,NEUTRAL)),
            "primitive starts orange with neutral vertex colour: "..mode)
        UI.Toggle()
        for _,tint in ipairs({1,2,3,4,0}) do
            showPhase(UI,tint,"primitive tint fixture")
            assert(sameRGB(UI.kart.color,primitiveColors[tint]),
                "primitive keeps phase color "..tint..": "..mode)
        end
        assert(UI.SelectTrack("mirage_raceway") and math.abs(UI.kart.width-25.5)<1e-9 and
               math.abs(UI.kart.height-46.5)<1e-9 and UI.mirageBackground:IsShown(),
            "Mirage stays playable with the scaled primitive kart: "..mode)
        UI.Start()
        for _=1,3 do UI.OnUpdate(1/60) end
        assert(UI.active and UI.state.tick==3 and UI.race.status=="countdown",
            "the fallback kart drives the normal fixed-step session: "..mode)
        UI.Stop("fallback fixture done")
        assert(loads(env,KART_PATH)==attempts and
               (rawget(UI.kart,"vertexColor")==nil or sameRGB(UI.kart.vertexColor,NEUTRAL)),
            "no sprite retry per frame, run or map: "..mode)
        assert(UI.objects.frames==UI_FRAMES and UI.objects.textures==UI_TEXTURES and UI.objects.fontStrings==UI_FONTS,
            "fallback keeps the explicit UI object budget: "..mode)
    end)
end

-- Drift/boost effects: pooled textures on the canvas, hidden while idle, shown
-- for a real Mirage drift and boost (sparks in every tier colour, flames only
-- while boosting, on either side of the kart), always whole inside the canvas,
-- never reloaded or reallocated, and cleared by a map change.
local effectsSummary
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local E=env.namespace.Presentation.EFFECTS
    local pieces=effectPieces(UI)
    assert(UI.fx and #pieces==EFFECT_TEXTURES,"effect pools are created and loaded with the window")
    for _,piece in ipairs(pieces) do
        assert(piece.parent==UI.canvas and not piece:IsShown(),"effects start hidden on the canvas")
    end
    for _,piece in ipairs(UI.fxSmoke) do
        assert(piece.layer=="ARTWORK" and piece.sublevel==6 and piece.texturePath==PARTICLES_PATH,
            "smoke sits above the track markers, below the kart")
    end
    for _,piece in ipairs(UI.fxSparks) do
        assert(piece.layer=="OVERLAY" and piece.sublevel==-2 and piece.texturePath==PARTICLES_PATH,
            "sparks sit just below the kart")
    end
    for index,piece in ipairs(UI.fxFlames) do
        assert(piece.layer=="OVERLAY" and piece.sublevel==(index%2==1 and 2 or 3) and piece.texturePath==FLAME_PATH,
            "each flame's inner layer sits above its outer layer")
    end
    UI.Toggle()
    assert(UI.SelectTrack("mirage_raceway"))
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    local loadsBefore=env.textureCalls
    UI.Start()
    env.key(UI,"OnKeyDown","W")
    local seen,colors,front,behind,shownMost={},{},false,false,0
    local script={{340,"OnKeyDown","A"},{340,"OnKeyDown","SPACE"},{415,"OnKeyUp","SPACE"},{450,"OnKeyUp","A"},
        {548,"OnKeyDown","D"},{548,"OnKeyDown","SPACE"},{622,"OnKeyUp","SPACE"},{650,"OnKeyUp","D"}}
    local done={}
    for _=1,760 do
        for index,step in ipairs(script) do
            if UI.state.tick>=step[1] and not done[index] then done[index]=true; env.key(UI,step[2],step[3]) end
        end
        UI.OnUpdate(1/60)
        local shown=0
        for _,piece in ipairs(pieces) do
            if piece:IsShown() then
                shown=shown+1
                local x,y,half=piece.point[4],piece.point[5],piece.width/2
                assert(piece.point[1]=="CENTER" and piece.point[2]==UI.canvas and piece.width==piece.height and
                       x-half>=0 and y-half>=0 and x+half<=800 and y+half<=480,
                    "a shown effect quad lies whole inside the canvas")
            end
        end
        shownMost=math.max(shownMost,shown)
        for _,piece in ipairs(UI.fxSmoke) do if piece:IsShown() then seen.smoke=true end end
        for _,piece in ipairs(UI.fxSparks) do
            if piece:IsShown() then
                seen.spark=true
                local c=piece.vertexColor
                colors[c[1]..","..c[2]..","..c[3]]=true
            end
        end
        for _,piece in ipairs(UI.fxFlames) do
            if piece:IsShown() then
                assert(UI.state.boostTicks>0,"flames burn only while boosting")
                seen.flame=true
                if piece.sublevel>=2 then front=true else behind=true end
            end
        end
    end
    assert(seen.smoke and seen.spark and seen.flame,"a Mirage drift and boost shows dust, sparks and flames")
    for tier=0,2 do
        local c=E.sparkColors[tier]
        assert(colors[c[1]..","..c[2]..","..c[3]],"drift tier "..tier.." sparks use the meter's colour")
    end
    assert(front and behind,"flames move between the kart's near and far side as it turns")
    assert(env.textureCalls==loadsBefore,"effects never reload a texture during play")
    sameCounts(env,counts,"effects allocate no UI objects during play")
    UI.Stop("effects fixture")
    assert(UI.SelectTrack("test_oval"))
    for _,piece in ipairs(pieces) do assert(not piece:IsShown(),"a map change clears every effect") end
    effectsSummary=("mock effects: %d pooled textures, at most %d shown; dust, three spark tiers and "..
        "boost flames on both sides of the kart during a Mirage drive"):format(#pieces,shownMost)
end)

-- Kart picker: while stopped, the Kart button cycles KART_ORDER. Each choice
-- loads that art with the guarded checks, resizes the quad, moves the effect
-- anchors and relabels the button, without touching the run, track or state.
-- It is disabled and refused during a run, and a refused load keeps the kart.
local kartSummary
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local P=env.namespace.Presentation
    UI.Toggle()
    assert(UI.kartId=="goblin_mortar_trike" and UI.kartButton:GetText()=="Kart: Goblin Mortar Trike" and
           UI.kartButton:IsEnabled(),"the default kart is named on an enabled button")
    assert(P.nextKart("goblin_mortar_trike")=="steam_tank" and P.nextKart("goblin_drag_car")=="goblin_mortar_trike"
           and P.nextKart("unknown")==P.KART_ORDER[1],"the cycle wraps and starts over for unknown ids")
    local counts={}
    for key,value in pairs(env.counts) do counts[key]=value end
    local state,track,loadsBefore=UI.state,UI.trackId,env.textureCalls
    local seen,views=0,{}
    for _=1,#P.KART_ORDER do
        UI.kartButton.scripts.OnClick(UI.kartButton)
        local id=UI.kartId
        local sprite=P.KART_SPRITES[id]
        seen=seen+1
        assert(UI.kartSprite==sprite and UI.kart.texturePath==sprite.path and
               UI.kartButton:GetText()=="Kart: "..sprite.name,id..": the button loads, shows and names the kart")
        assert(UI.kart.width==sprite.quadWidth*UI.view.scale and UI.kart.height==sprite.quadHeight*UI.view.scale,
            id..": the quad follows the kart's frame window")
        assert(UI.fxOptions.anchors==sprite.effects,id..": effects use the kart's own anchors")
        assert(UI.state==state and UI.trackId==track and UI.race==nil,id..": the kart choice leaves run and track")
        if sprite.frames then
            local frame=P.kartFrame(sprite,state.heading)
            local l,r,t,b=P.kartFrameCoords(sprite,frame)
            local uv,rotation=rawget(UI.kart,"texCoords"),rawget(UI.kart,"rotation")
            assert(UI.kartFrame==frame and uv[1]==l and uv[2]==r and uv[3]==t and uv[4]==b and
                   (rotation==nil or rotation==0),id..": a sheet shows its nearest frame, unrotated")
        else
            local uv=rawget(UI.kart,"texCoords")
            assert(UI.kart.rotation==state.heading-math.pi/2 and uv[1]==0 and uv[2]==1 and uv[3]==0 and uv[4]==1,
                id..": a single image shows the whole texture, rotated")
        end
        views[#views+1]=id
    end
    assert(seen==#P.KART_ORDER and UI.kartId=="goblin_mortar_trike","the cycle returns to the first kart")
    assert(env.textureCalls==loadsBefore+#P.KART_ORDER,"one guarded load per choice, none per frame")
    sameCounts(env,counts,"choosing karts allocates no UI objects")
    -- A refused load keeps the current kart and its art.
    env.textureModes={[P.KART_SPRITES.steam_tank.path]="false"}
    assert(not UI.SelectKart("steam_tank") and UI.kartId=="goblin_mortar_trike" and
           UI.kart.texturePath==KART_PATH,"a refused kart keeps the current one")
    env.textureModes=nil
    -- During a run the button is disabled and direct choices are refused.
    UI.Start()
    assert(not UI.kartButton:IsEnabled() and not UI.SelectKart("gyrocopter") and UI.kartId=="goblin_mortar_trike",
        "no kart change during a run")
    UI.Stop("kart fixture")
    assert(UI.kartButton:IsEnabled(),"stopping re-enables the kart button")
    -- Every kart drives a short Mirage run with effects drawn and no errors.
    assert(UI.SelectTrack("mirage_raceway"))
    for _,id in ipairs(P.KART_ORDER) do
        assert(UI.SelectKart(id))
        UI.Start()
        env.key(UI,"OnKeyDown","W")
        for _=1,200 do UI.OnUpdate(1/60) end
        assert(UI.active and UI.state.tick==200 and UI.kartId==id,id..": drives the normal session")
        UI.Stop("kart run "..id)
    end
    sameCounts(env,counts,"kart runs allocate no UI objects")
    kartSummary=("mock karts: %d karts cycle while stopped (%s); one guarded load per choice; refused while "..
        "driving or when a load fails"):format(#P.KART_ORDER,table.concat(views,", "))
end)

-- A late load failure can already have changed the image, UVs or orientation.
-- Restore all of them along with the previous frame/metadata, in both sheet and
-- single-image directions. A failed rollback must leave a consistent primitive.
for _,fixture in ipairs({
    {"basic","steam_tank","SetVertexColor"},
    {"basic","steam_tank","SetRotation"},
    {"steam_tank","basic","SetTexCoord"},
    {"steam_tank","basic","SetVertexColor"},
}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart")
        singleImageKart(env)
        UI.Toggle()
        assert(UI.SelectKart(fixture[1]))
        UI.Start(); UI.OnUpdate(1/60); UI.Stop("kart rollback fixture")
        UI.state.heading=0.9; UI.previousState=UI.state; UI.Stop("kart rollback pose")
        local sprite,id,frame=UI.kartSprite,UI.kartId,UI.kartFrame
        local state,race,result,track,laps=UI.state,UI.race,UI.result,UI.trackId,UI.laps
        local tick,x,y,heading=state.tick,state.x,state.y,state.heading
        local previousUV={(table.unpack or unpack)(UI.kart.texCoords)} -- Lua 5.1 and 5.4
        local previousRotation,width,height=UI.kart.rotation,UI.kart.width,UI.kart.height
        local counts={}
        for key,value in pairs(env.counts) do counts[key]=value end
        local setter=UI.kart[fixture[3]]
        local failures=0
        UI.kart[fixture[3]]=function(self,...)
            setter(self,...)
            if failures==0 then failures=1; error("mock late kart setter refusal") end
        end
        assert(not UI.SelectKart(fixture[2]),"late "..fixture[3].." failure refuses the choice")
        UI.kart[fixture[3]]=setter
        assert(UI.kartSprite==sprite and UI.kartId==id and UI.kartFrame==frame and
               UI.kart.texturePath==sprite.path and UI.kart.rotation==previousRotation and
               UI.kart.width==width and UI.kart.height==height,
            "rollback restores the previous image, orientation, frame and dimensions")
        for index,value in ipairs(previousUV) do
            assert(UI.kart.texCoords[index]==value,"rollback restores every UV coordinate")
        end
        assert(sameRGB(UI.kart.vertexColor,NEUTRAL) and UI.fxOptions.anchors==sprite.effects and
               UI.kartButton:GetText()=="Kart: "..sprite.name,
            "rollback restores neutral tint, effect anchors and label")
        assert(UI.state==state and UI.race==race and UI.result==result and UI.trackId==track and UI.laps==laps and
               state.tick==tick and state.x==x and state.y==y and state.heading==heading,
            "failed cosmetic switching preserves the stopped run, result, track and physics")
        sameCounts(env,counts,"rollback allocates no UI objects")
    end)
end

for _,method in ipairs({"SetTexCoord","SetRotation","SetVertexColor"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart")
        UI.Toggle()
        assert(UI.SelectKart(singleImageKart(env)))
        UI.Start(); UI.OnUpdate(1/60); UI.Stop("kart fallback fixture")
        local state,race,result,track,laps=UI.state,UI.race,UI.result,UI.trackId,UI.laps
        local setter=UI.kart[method]
        UI.kart[method]=function() error("mock persistent kart setter refusal") end
        assert(not UI.SelectKart("steam_tank"),"a failed rollback refuses selection: "..method)
        assert(UI.kartSprite==nil and UI.kartId==nil and UI.kartFrame==nil and
               UI.kart.width==17 and UI.kart.height==31 and sameRGB(UI.kart.color,primitiveColors[0]) and
               UI.kartButton:GetText()=="Kart: Basic" and
               UI.fxOptions.anchors==env.namespace.Presentation.DEFAULT_EFFECT_ANCHORS,
            "failed rollback clears sprite identity and uses the primitive/default effects: "..method)
        for _,piece in ipairs(effectPieces(UI)) do assert(not piece:IsShown(),"fallback clears pooled effects") end
        assert(UI.state==state and UI.race==race and UI.result==result and UI.trackId==track and UI.laps==laps,
            "failed rollback preserves authoritative run state: "..method)
        UI.Stop("primitive renders despite refused sprite setter")
        UI.kart[method]=setter
        assert(UI.SelectKart("steam_tank") and UI.kartRotationReady and
               kartFaces(env,UI,state.heading),"later deliberate selection recovers after API restoration")
    end)
end

-- The player's optional outline (Settings: "Outline my kart"): off and never
-- loaded by default; switched on, the current kart's outline sheet loads once
-- and follows the kart's frame, quad and position through a drive; a new kart
-- loads its own; a refused load hides the line without retries; a single
-- image or the primitive shows none. It never touches the simulation.
local outlineSummary
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    local P=env.namespace.Presentation
    local trike=P.KART_SPRITES.goblin_mortar_trike
    assert(not UI.kartOutline:IsShown() and loads(env,trike.outline)==0,"the outline is off and unloaded by default")
    UI.Toggle()
    local state=UI.state
    UI.SetKartOutline(true)
    local line=UI.kartOutline
    local function follows(label)
        local sprite=UI.kartSprite
        local l,r,t,b=P.kartFrameCoords(sprite,UI.kartFrame)
        local uv,kp,lp=line.texCoords,UI.kart.point,line.point
        assert(line:IsShown() and line.texturePath==sprite.outline and uv[1]==l and uv[2]==r and uv[3]==t and
               uv[4]==b and line.width==UI.kart.width and line.height==UI.kart.height and
               lp[1]=="CENTER" and lp[4]==kp[4] and lp[5]==kp[5],label..": the line has the kart's frame and place")
    end
    follows("switched on")
    local color=P.KART_OUTLINE.color
    assert(loads(env,trike.outline)==1 and line.vertexColor[1]==color[1] and line.vertexColor[2]==color[2] and
           line.vertexColor[3]==color[3] and sameRGB(UI.kart.vertexColor,NEUTRAL) and UI.state==state,
        "one load, tinted line, untinted kart, unchanged state")
    UI.Start()
    env.key(UI,"OnKeyDown","W"); env.key(UI,"OnKeyDown","A")
    for _=1,240 do UI.OnUpdate(1/60) end
    follows("driving")
    assert(loads(env,trike.outline)==1,"driving never reloads the outline")
    UI.Stop("outline fixture")
    assert(UI.SelectKart("steam_tank") and loads(env,P.KART_SPRITES.steam_tank.outline)==1 and
           loads(env,trike.outline)==1,"a new kart loads its own outline once")
    follows("new kart")
    env.textureModes={[P.KART_SPRITES.gyrocopter.outline]="false"}
    assert(UI.SelectKart("gyrocopter") and UI.kartId=="gyrocopter" and not line:IsShown(),
        "a refused outline hides the line and keeps the kart")
    for _=1,3 do UI.OnUpdate(1/60) end
    assert(loads(env,P.KART_SPRITES.gyrocopter.outline)==1,"a refused outline is not retried")
    env.textureModes=nil
    assert(UI.SelectKart(singleImageKart(env)) and not line:IsShown(),"a single image has no outline")
    UI.SetKartOutline(false)
    assert(UI.SelectKart("steam_tank") and not line:IsShown() and loads(env,P.KART_SPRITES.steam_tank.outline)==1,
        "switched off, the line hides and nothing loads")
    outlineSummary="mock kart outline: off and unloaded by default; one load per kart while on; follows the "..
        "kart's frame, quad and pose through a drive; a refused load hidden, not retried"
end)
print(outlineSummary)

-- A refused effect atlas leaves every effect hidden and the drive unchanged.
withMock(nil,false,function(env,UI)
    env.textureModes={[FLAME_PATH]="throws"}
    env.fire("ADDON_LOADED","AzerothKart")
    assert(UI.fx==nil and UI.kartSprite and UI.objects.textures==UI_TEXTURES,
        "a refused effect atlas disables effects, keeps the kart sheet and the texture budget")
    UI.Toggle()
    UI.Start()
    for _=1,3 do UI.OnUpdate(1/60) end
    assert(UI.active and UI.state.tick==3,"the drive runs without effects")
    for _,piece in ipairs(effectPieces(UI)) do assert(not piece:IsShown(),"refused effects stay hidden") end
    UI.Stop("refused effects fixture")
end)

-- The visual path cannot alter simulation: an identical scripted Mirage drive
-- with irregular frame times yields identical state in sprite and primitive
-- mode, while every rendered frame shows the tint for the actual state.
local function scriptedDrive(mode,effectsOff)
    local trace,seen={}, {}
    withMock(nil,false,function(env,UI)
        env.textureModes={}
        if mode then env.textureModes[KART_PATH]=mode end
        if effectsOff then env.textureModes[PARTICLES_PATH]="false" end
        env.fire("ADDON_LOADED","AzerothKart")
        assert((UI.kartSprite~=nil)==(mode==nil),"fixture selects the intended kart visual")
        assert((UI.fx~=nil)==(not effectsOff),"fixture selects the intended effects state")
        UI.Toggle()
        assert(UI.SelectTrack("mirage_raceway"))
        UI.Start()
        env.key(UI,"OnKeyDown","W")
        local frames={1/60,1/30,1/144,0.05,1/90}
        local drifting,released,straight=false,false,false
        for frame=1,900 do
            local tick=UI.state.tick
            if tick>=340 and not drifting then
                drifting=true; env.key(UI,"OnKeyDown","A"); env.key(UI,"OnKeyDown","SPACE")
            elseif tick>=415 and not released then
                released=true; env.key(UI,"OnKeyUp","SPACE")
            elseif tick>=450 and not straight then
                straight=true; env.key(UI,"OnKeyUp","A")
            end
            UI.OnUpdate(frames[frame%#frames+1])
            assert(UI.active,"scripted drive keeps capture")
            local snapshot={status=UI.race.status,totalTicks=UI.race.totalTicks,
                nextGate=UI.checkpoints.nextGate,completedLaps=UI.laps.completedLaps}
            for field,value in pairs(UI.state) do snapshot[field]=value end
            trace[frame]=snapshot
            local tint=expectedTint(UI.state)
            seen[tint]=true
            if mode==nil then
                assert(sameRGB(UI.kart.vertexColor,NEUTRAL) and
                       rawget(UI.kart,"color")==nil and UI.kart.textureWrites==1,
                    "sprite frame "..frame.." stays untinted in phase "..tint.." without replacing its image")
            else
                assert(sameRGB(UI.kart.color,primitiveColors[tint]),
                    "primitive frame "..frame.." shows color "..tint)
            end
        end
        UI.Stop("scripted drive done")
    end)
    return trace,seen
end
local spriteTrace,spriteSeen=scriptedDrive(nil)
local primitiveTrace=scriptedDrive("false")
local quietTrace=scriptedDrive(nil,true)
assert(#spriteTrace==900 and #primitiveTrace==900 and #quietTrace==900,"all scripted drives complete")
for frame,snapshot in ipairs(spriteTrace) do
    for field,value in pairs(snapshot) do
        assert(primitiveTrace[frame][field]==value,
            ("kart visual changed simulation field %s at frame %d"):format(field,frame))
        assert(quietTrace[frame][field]==value,
            ("drift/boost effects changed simulation field %s at frame %d"):format(field,frame))
    end
end
local last=spriteTrace[#spriteTrace]
assert(spriteSeen[0] and spriteSeen[1] and spriteSeen[2] and spriteSeen[3],
    "the scripted drive exercises charge and both ready tiers on Mirage")
spriteSummary=("mock kart sheet: 1 creation load, nearest-heading frames unrotated, untinted in every phase, "..
    "10 refused-load fallbacks; single-image rotation path kept; "..
    "900-frame Mirage drive identical in sprite/primitive and effects on/off modes through tick %d "..
    "(phases seen:%s%s%s%s%s)")
    :format(last.tick,spriteSeen[0] and " 0" or "",spriteSeen[1] and " 1" or "",
        spriteSeen[2] and " 2" or "",spriteSeen[3] and " 3" or "",spriteSeen[4] and " 4/boost" or "")
originalPrint(spriteSummary)
originalPrint(effectsSummary)
originalPrint(kartSummary)

originalPrint(summary.." (mock regression only; live-client probes pending)")


-- Canvas uses one deliberate Ready arm and copied LiveRace views. The backend
-- owns all fixed ticks; native transport/GO exchange is tested separately.
local function liveFixture(env,UI,trackId)
    local AK=env.namespace
    local clock=1000
    local token,closed,phase,grid=nil,false,"lobby",nil
    local calls={ready=0,advance=0,stop=0}
    local transport={}
    local session="AKTUI1"
    local function liveView()
        local view=token and AK.LiveRace.view(token) or nil
        if view then
            view.localKartId=grid and grid.localKartId or "basic"
            view.peerKartId=grid and grid.peerKartId or "basic"
        end
        return view
    end
    function transport.GetView()
        return {session=session,phase=phase,liveMode=true,transportBusy=not closed,
            canSetReady=phase=="lobby",offer={trackId=trackId or "test_oval"},
            peer="Amber Stone",grid=grid,live=liveView()}
    end
    function transport.Ready(ready) calls.ready=calls.ready+1; calls.readyValue=ready; return true end
    function transport.PrepareStart() calls.prepared=true; return true end
    function transport.HostLive(...) calls.host={...}; return true end
    function transport.ListenLive(...) calls.listen={...}; return true end
    function transport.Join() return true end
    function transport.Leave() calls.left=true; transport.Stop("stopped"); return true end
    function transport.Stop(reason)
        calls.stop=calls.stop+1; closed,phase=true,"closed"
        if token then AK.LiveRace.stop(token,clock,reason) end
        return true
    end
    function transport.AdvanceLive(input)
        calls.advance=calls.advance+1
        AK.LiveRace.advance(token,clock,input)
        return liveView()
    end
    AK.SessionTransport=transport
    local function launch()
        local track=UI.track
        local vehicle=AK.Physics.new(track)
        if grid then
            vehicle.x,vehicle.y,vehicle.heading=grid.localPose.x,grid.localPose.y,grid.localPose.heading
            grid.staged=false
        end
        token=assert(AK.LiveRace.new({session=session,role="host",seed=0,trackId=track.id,
            trackVersion=track.version,physicsVersion=AK.Physics.VERSION,localEpochMS=clock,
            hostEpochMS=clock,uncertaintyMS=352,peerAcknowledged=true,track=track,
            vehicle=vehicle,race=AK.Race.newRunning(track,AK.Checkpoints,AK.Laps,0),
            fixedDt=AK.Physics.FIXED_DT},"Amber Stone",clock,AK))
        phase="racing"
        return token
    end
    local function stage(cue,peerKartId)
        if not grid then
            local here,there=assert(AK.RaceGrid.pose(UI.track,"host"))
            grid={ready=true,staged=true,localPose=here,peerPose=there,
                localKartId=UI.kartId or "basic",peerKartId=peerKartId or "steam_tank"}
        end
        phase,grid.cue="coordinating",cue or "GET READY"
        return grid
    end
    return calls,transport,launch,function(ms) clock=clock+ms end,stage
end

withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle()
    local calls,transport,launch,advance=liveFixture(env,UI)
    local objects={}; for key,value in pairs(env.counts) do objects[key]=value end
    local initial=UI.state
    UI.OnUpdate(1)
    assert(not UI.active and UI.state==initial and calls.advance==0,"navigation never adopts live state")
    assert(UI.MultiplayerAction("ready",true) and UI.liveArmed and not UI.active,
        "deliberate Ready arms without capture or solo countdown")
    assert(not UI.SelectTrack("mirage_raceway") and not UI.SelectKart("steam_tank"),
        "armed compatibility choices cannot change under the start clock")
    assert(UI.MultiplayerAction("start") and calls.prepared,"Start uses coordinated backend action")
    local token=launch()
    UI.OnUpdate(0.016)
    assert(UI.active and UI.liveActive and UI.multiplayer and not UI.liveArmed
        and UI.race.status=="running" and UI.race.countdownTicks==0 and UI.state.tick==0,
        "GO adopts tick-zero running bundle without solo countdown")
    assert(UI.window.keyboard and UI.window.propagate==false and calls.advance==0,
        "adoption captures once; authoritative simulation starts on next update")
    env.key(UI,"OnKeyDown","W")
    env.key(UI,"OnKeyDown","F")
    for _=1,12 do advance(17); UI.OnUpdate(0.017) end
    assert(UI.active and UI.state.tick==12 and calls.advance==12 and UI.state.speed>0,
        "one backend advance per update; no second solo Physics/Loop path")
    local authoritative=env.namespace.LiveRace.view(token)
    UI.state.x=1
    assert(env.namespace.LiveRace.view(token).vehicle.x==authoritative.vehicle.x,
        "renderer consumes copies and cannot edit authoritative physics")
    advance(17); UI.OnUpdate(0.017)
    assert(UI.state.x~=1,"next authoritative view replaces changed presentation copy")
    local LP=env.namespace.LiveProtocol
    local payload=assert(LP.encode({kind="STATE",session="AKTUI1",sequence=1,tick=1,x=400,y=100,
        headingQ=0,speedQ=0,driftTier=0,boosting=false,completedLaps=0,passed=0,status="running",sampleMS=0}))
    assert(env.namespace.LiveRace.receive(token,1221,LP.PREFIX,payload,"WHISPER","Amber Stone"))
    advance(17); UI.OnUpdate(0.017)
    assert(UI.opponent:IsShown() and UI.opponentLabel:IsShown()
        and UI.opponentLabel.text:find("observed kart",1,true),"pooled opponent shows unverified observation")
    local remote=UI.liveView.remote
    remote.x=-500
    UI.OnUpdate(0)
    assert(UI.liveView.remote.x==400,"render cannot change backend remote observation")
    local counts={}; for key,value in pairs(env.counts) do counts[key]=value end
    env.key(UI,"OnKeyDown","ESCAPE")
    local state,clock,race=UI.state,UI.clock,UI.race
    assert(not UI.active and not UI.liveActive and not UI.window.keyboard and next(UI.keys)==nil
        and calls.stop==1 and UI.race.status=="stopped" and UI.result.resultVerified==false,
        "explicit Escape stops native live owner and freezes actual partial result")
    UI.OnUpdate(2)
    assert(UI.state==state and UI.clock==clock and UI.race==race,"idle polling cannot advance stopped state")
    assert(UI.summaryHint.text:find("No agreed winner",1,true),"live results do not invent standings")
    for key,value in pairs(objects) do assert(env.counts[key]==value,"live loop allocated objects: "..key) end
    for key,value in pairs(counts) do assert(env.counts[key]==value,"stop allocated objects: "..key) end
end)

-- Readiness and late GO fail closed without capturing or creating solo state.
for _,mode in ipairs({"combat","focus","window","api","gamefocus","track"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
        local calls,transport,launch=liveFixture(env,UI,mode=="track" and "stormwind_circuit" or nil)
        if mode=="combat" then env.combat=true
        elseif mode=="focus" then env.focus={}
        elseif mode=="window" then UI.window:Hide()
        elseif mode=="api" then GetCurrentKeyBoardFocus=nil
        elseif mode=="gamefocus" then env.focused=false end
        assert(not UI.MultiplayerAction("ready",true) and calls.ready==0 and not UI.liveArmed
            and not UI.active,"Ready refuses unsafe or unsupported selection: "..mode)
    end)
end
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
    local calls,transport,launch=liveFixture(env,UI,"mirage_raceway")
    assert(UI.MultiplayerAction("ready",true) and UI.trackId=="mirage_raceway",
        "guest Ready transaction loads exactly the offered supported course")
    launch(); env.focused=false; UI.OnUpdate(0.016)
    assert(not UI.active and not UI.liveArmed and calls.stop==1 and not UI.window.keyboard,
        "focus loss between Ready and GO prevents capture")
end)
for _,exit in ipairs({"combat","focus","chat","close","world"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
        local calls,transport,launch,advance=liveFixture(env,UI)
        assert(UI.MultiplayerAction("ready",true)); launch(); UI.OnUpdate(0)
        advance(17); UI.OnUpdate(0.017)
        if exit=="combat" then env.combat=true; UI.HandleEvent("PLAYER_REGEN_DISABLED")
        elseif exit=="focus" then env.focused=false; UI.OnUpdate(0.017)
        elseif exit=="chat" then env.key(UI,"OnKeyDown","ENTER")
        elseif exit=="close" then UI.window:Hide()
        else UI.HandleEvent("PLAYER_LEAVING_WORLD") end
        assert(not UI.active and calls.stop>=1 and not UI.window.keyboard and next(UI.keys)==nil,
            "live lifecycle releases native owner and capture: "..exit)
        assert(env.combatPropagationCalls==0,"combat exit never calls propagation setter")
        assert(UI.race.totalTicks==1,"exit retains exact partial ticks")
    end)
end

withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
    local calls,transport,launch=liveFixture(env,UI)
    assert(UI.MultiplayerAction("ready",true)); local token=launch(); UI.OnUpdate(0)
    local frozen=env.namespace.LiveRace.view(token)
    frozen.phase="finishing"
    frozen.race.status="finished"
    frozen.race.reason="local_finished"
    frozen.race.laps.completedLaps=3
    frozen.race.laps.lastLapTicks=100
    frozen.race.laps.bestLapTicks=100
    frozen.race.laps.bestLapNumber=1
    frozen.race.totalTicks=300
    transport.AdvanceLive=function() return frozen end
    local busy=true
    transport.GetView=function()
        return {session="AKTUI1",phase=busy and "finishing" or "closed",liveMode=true,
            transportBusy=busy,live=frozen}
    end
    UI.OnUpdate(0)
    assert(not UI.active and not UI.liveActive and UI.multiplayer and not UI.window.keyboard
        and calls.stop==0 and not UI.restartButton:IsEnabled() and not UI.startButton:IsEnabled(),
        "local finish releases capture while preserving terminal output drain")
    assert(UI.summaryTitle.text:find("UNVERIFIED",1,true) and UI.result.resultVerified==false,
        "finished UI never declares an agreed winner")
    local race,state,clock=UI.race,UI.state,UI.clock
    UI.Start()
    assert(not UI.active and UI.race==race and UI.state==state and UI.clock==clock and calls.stop==0,
        "solo restart cannot replace a draining live run")
    assert(not UI.SelectTrack("mirage_raceway") and not UI.SelectKart("steam_tank"),
        "draining live result holds compatibility and presentation state")
    busy=false; frozen.phase="closed"; UI.OnUpdate(0.1)
    assert(UI.race==race and UI.state==state and UI.clock==clock and UI.restartButton:IsEnabled(),
        "terminal transport close preserves frozen result object and enables fresh solo restart")
    assert(UI.SelectTrack("mirage_raceway") and not UI.multiplayer and not UI.liveView
        and not UI.opponent:IsShown(),"fresh track selection clears old observational opponent")
end)
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
    local calls,transport,launch,advance=liveFixture(env,UI)
    assert(UI.MultiplayerAction("ready",true)); local token=launch(); UI.OnUpdate(0)
    local LP=env.namespace.LiveProtocol
    local function observation(sequence,tick,x,y)
        return assert(LP.encode({kind="STATE",session="AKTUI1",sequence=sequence,tick=tick,x=x,y=y,
            headingQ=0,speedQ=0,driftTier=0,boosting=false,completedLaps=0,passed=0,status="running",sampleMS=0}))
    end
    assert(env.namespace.LiveRace.receive(token,1000,LP.PREFIX,observation(1,1,400,100),"WHISPER","Amber Stone"))
    advance(1601); UI.OnUpdate(1.601)
    assert(UI.opponent:IsShown() and UI.opponentLabel.text:find("stale",1,true),
        "stale remote observations fade and never extrapolate")
    assert(env.namespace.LiveRace.receive(token,2601,LP.PREFIX,observation(2,2,0,0),"WHISPER","Amber Stone"))
    advance(1601); UI.OnUpdate(1.601)
    assert(not UI.opponent:IsShown(),"off-viewport rotated marker cannot draw beyond canvas")
    assert(UI.opponentLabel:IsShown() and UI.opponentLabel.text:find("off-screen",1,true)
        and UI.opponentLabel.text:find("units",1,true) and not UI.opponentLabel.text:find("behind",1,true),
        "off-screen bearing and distance do not invent a behind/ahead race position")
    assert(UI.MultiplayerAction("leave") and not UI.active and calls.left and calls.stop==1,
        "explicit Leave releases capture then invokes paced cancellation once")
end)

for _,action in ipairs({"host","listen"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
        local calls,transport=liveFixture(env,UI)
        assert(UI.MultiplayerAction(action,"Amber Stone","AKTUI1","test_oval"))
        local command=calls[action]
        assert(command[1]=="Amber Stone" and command[2]=="AKTUI1"
            and command[action=="host" and 4 or 3]==UI.kartId,
            "Host/Listen explicitly pass the selected local kart profile")
        assert(not UI.liveArmed and not UI.liveSession and not UI.active,
            "pre-Ready session never owns input")
        local chosen=UI.kartId
        assert(not UI.SelectKart("steam_tank") and UI.kartId==chosen,
            "kart profile cannot change programmatically after Host/Listen starts agreement")
        UI.window:Hide()
        assert(calls.left and calls.stop==1 and not UI.active,
            "hiding window cancels even pre-Ready "..action.." session")
    end)
end

-- Native shared grid is presentation-only until mapped GO. Held controls are
-- consumed there without advancing Physics, laps or the solo countdown.
withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
    local calls,transport,launch,advance,stage=liveFixture(env,UI)
    local objects={}; for key,value in pairs(env.counts) do objects[key]=value end
    assert(UI.MultiplayerAction("ready",true)); assert(UI.MultiplayerAction("start"))
    local state,race,clock=UI.state,UI.race,UI.clock
    local grid=stage()
    UI.OnUpdate(0)
    local displayState,displayLaps=UI.state,UI.laps
    assert(UI.gridStaged and UI.multiplayer and not UI.active and UI.liveArmed,
        "matching explicit Start stages the copied grid, never starts the solo loop")
    assert(displayState~=state and UI.race==nil and UI.clock==nil and UI.state.tick==0
        and UI.laps.completedLaps==0 and UI.laps.currentLapTicks==0,
        "a deliberate staged start resets only the ended tick-zero display")
    assert(UI.window.keyboard and UI.window.propagate==false and UI.opponent:IsShown(),
        "both grid karts show before GO and throttle cannot move the WoW character")
    assert(UI.countdownCue.text=="GET READY" and UI.countdownCue:IsShown(),
        "grid is visible before the timed 3-2-1")
    assert(env.namespace.Menu.screen==nil and not env.namespace.Menu.root:IsShown()
        and UI.stopButton:IsShown() and UI.stopButton:IsEnabled(),
        "grid hides lobby without Leave and keeps the explicit Stop control")
    local sprite=env.namespace.Presentation.KART_SPRITES.steam_tank
    assert(UI.opponentSprite==sprite and UI.opponent.texturePath==sprite.path
        and UI.opponent.rotation==0 and UI.opponent.vertexColor[1]==1,
        "peer's chosen directional art is shown neutrally, instead of a square")
    local P=env.namespace.Presentation
    local frame=P.kartFrame(sprite,grid.peerPose.heading)
    local left,right,top,bottom=P.kartFrameCoords(sprite,frame)
    assert(UI.opponentFrame==frame and UI.opponent.texCoords[1]==left
        and UI.opponent.texCoords[2]==right and UI.opponent.texCoords[3]==top
        and UI.opponent.texCoords[4]==bottom,
        "peer sheet uses the same heading-to-frame crop as the own kart")
    local kartLoads=loads(env,sprite.path)
    env.key(UI,"OnKeyDown","W"); env.key(UI,"OnKeyDown","F")
    for _,cue in ipairs({"3","2","1"}) do
        stage(cue); advance(1000); UI.OnUpdate(1)
        assert(UI.countdownCue:IsShown() and UI.countdownCue.text==cue,
            "shared countdown shows "..cue)
        assert(UI.state==displayState and UI.race==nil and UI.clock==nil and UI.state.tick==0
            and UI.laps==displayLaps and UI.laps.completedLaps==0 and calls.advance==0,
            "grid cue cannot run Physics, laps or either game loop")
    end
    assert(loads(env,sprite.path)==kartLoads,"grid image loads once, never per callback")
    local released=env.keyboardReleaseCalls
    local localX,localY=grid.localPose.x,grid.localPose.y
    launch(); UI.OnUpdate(0)
    assert(not UI.gridStaged and UI.active and UI.liveActive and UI.state.tick==0
        and UI.state.x==localX and UI.state.y==localY and UI.race.totalTicks==0
        and UI.race.countdownTicks==0 and UI.countdownCue.text=="GO",
        "GO adopts the actual offset grid spawn without a second countdown")
    assert(env.keyboardReleaseCalls==released and next(UI.keys)~=nil,
        "GO retains staged held input without releasing/reacquiring capture")
    advance(17); UI.OnUpdate(0.017)
    assert(UI.state.speed>0 and UI.state.tick==1 and UI.input.accelerate,
        "held grid throttle reaches the first native simulation tick")
    UI.Stop("grid test stopped")
    assert(not UI.gridStaged and not UI.gridView and not UI.window.keyboard
        and next(UI.keys)==nil and not UI.countdownCue:IsShown(),
        "Stop clears all grid/cue/capture state")
    for key,value in pairs(objects) do assert(env.counts[key]==value,"grid allocated objects: "..key) end
end)

withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
    local AK=env.namespace
    UI.race=AK.Race.newRunning(UI.track,AK.Checkpoints,AK.Laps,0)
    UI.race.status,UI.race.totalTicks="finished",300
    UI.laps=UI.race.laps
    UI.laps.completedLaps,UI.laps.currentLapTicks=3,0
    UI.laps.lastLapTicks,UI.laps.bestLapTicks,UI.laps.bestLapNumber=100,100,1
    UI.checkpoints=UI.laps.checkpoints
    UI.Stop("prior finish")
    assert(UI.summary:IsShown() and UI.race.status=="finished","fixture retains a previous completed run")
    local ended=UI.race
    local calls,transport,launch,advance,stage=liveFixture(env,UI)
    assert(UI.MultiplayerAction("ready",true))
    assert(UI.race==ended and UI.summary:IsShown(),"Ready alone preserves the previous result display")
    assert(UI.MultiplayerAction("start")); stage("3"); UI.OnUpdate(0)
    assert(UI.race==nil and UI.laps.completedLaps==0 and UI.state.tick==0 and not UI.summary:IsShown(),
        "first legitimate shared grid clears old three-lap presentation without simulation")
    UI.Stop("grid cancelled")
    assert(not UI.summary:IsShown() and UI.race==nil and UI.laps.completedLaps==0,
        "cancelling this new grid cannot resurrect the previous completed race")
end)

for _,mode in ipairs({"not_ready","wrong_session"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
        local calls,transport,launch,advance,stage=liveFixture(env,UI)
        if mode=="wrong_session" then
            assert(UI.MultiplayerAction("ready",true)); UI.liveSession="OTHER1"
        end
        stage("3"); UI.OnUpdate(1)
        assert(not UI.gridStaged and not UI.active and not UI.window.keyboard and calls.advance==0,
            "a copied grid alone cannot capture without the matching explicit Ready: "..mode)
    end)
end

withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
    local calls,transport,launch,advance=liveFixture(env,UI)
    assert(UI.MultiplayerAction("ready",true)); local token=launch(); UI.OnUpdate(0)
    local Live,P=env.namespace.LiveRace,env.namespace.Presentation
    local view=Live.view(token)
    view.remote={x=400,y=100,heading=0,speed=200,status="running",sampleMS=0,
        receivedAtMS=1200,sampleAgeMS=350}
    view.peerKartId="steam_tank"
    transport.AdvanceLive=function() return view end
    local builds=0
    local builder=P.buildRemotePath
    P.buildRemotePath=function(...) builds=builds+1; return builder(...) end
    UI.OnUpdate(0)
    local path=UI.remotePath
    local x,y=P.remotePose(path,350)
    local projectedX,projectedY=P.project(UI.view,x,y)
    local sprite=P.KART_SPRITES.steam_tank
    assert(UI.opponent.point[4]==projectedX+sprite.pivotX*UI.view.scale
        and UI.opponent.point[5]==projectedY+sprite.pivotY*UI.view.scale and x>400,
        "peer is displayed at mapped sample age instead of an extra interval behind")
    for age=351,360 do view.remote.sampleAgeMS=age; UI.OnUpdate(0) end
    assert(builds==1 and UI.remotePath==path,"the bounded future path is rebuilt once per received snapshot")
    view.remote.receivedAtMS=1500; UI.OnUpdate(0)
    assert(builds==2,"a new snapshot refreshes the cached future path")
    assert(view.remote.x==400 and view.remote.y==100,"remote display prediction cannot modify observed state")
    P.buildRemotePath=builder
    UI.Stop("prediction fixture")
end)

for _,exit in ipairs({"escape","stop","combat","focus","chat","close","world","native"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
        local calls,transport,launch,advance,stage=liveFixture(env,UI)
        assert(UI.MultiplayerAction("ready",true)); assert(UI.MultiplayerAction("start"))
        stage("3"); UI.OnUpdate(0); env.key(UI,"OnKeyDown","W")
        if exit=="escape" then env.key(UI,"OnKeyDown","ESCAPE")
        elseif exit=="stop" then UI.Stop("Stopped")
        elseif exit=="combat" then env.combat=true; UI.HandleEvent("PLAYER_REGEN_DISABLED")
        elseif exit=="focus" then env.focused=false; UI.OnUpdate(0)
        elseif exit=="chat" then env.key(UI,"OnKeyDown","ENTER")
        elseif exit=="close" then UI.window:Hide()
        elseif exit=="world" then UI.HandleEvent("PLAYER_LEAVING_WORLD")
        else transport.Stop("timeout"); UI.OnUpdate(0) end
        assert(not UI.active and not UI.gridStaged and not UI.liveArmed
            and not UI.window.keyboard and next(UI.keys)==nil and not UI.countdownCue:IsShown()
            and calls.advance==0 and UI.state.tick==0,
            "staged lifecycle releases input without simulation: "..exit)
        assert(env.combatPropagationCalls==0,"staged combat never calls propagation setters")
    end)
end

for _,mode in ipairs({"false","throws"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart"); UI.Toggle()
        local calls,transport,launch,advance,stage=liveFixture(env,UI)
        local sprite=env.namespace.Presentation.KART_SPRITES.steam_tank
        env.textureModes={[sprite.path]=mode}
        assert(UI.MultiplayerAction("ready",true)); assert(UI.MultiplayerAction("start"))
        stage("3"); UI.OnUpdate(0)
        local tried=loads(env,sprite.path)
        assert(not UI.opponentSprite and UI.opponent:IsShown() and UI.opponent.color[2]==0.85,
            "refused peer image has a visible cyan primitive fallback: "..mode)
        UI.OnUpdate(0); UI.OnUpdate(0)
        assert(loads(env,sprite.path)==tried,"refused peer image is not retried every frame")
        UI.Stop("peer art test")
    end)
end

for _,scenario in ipairs({"hitch", "save_error", "reentrant_save"}) do
    withMock(nil,false,function(env,UI)
        env.fire("ADDON_LOADED","AzerothKart")
        UI.Toggle(); UI.Start(); finishCountdown(UI)
        local ns,dt=env.namespace,env.namespace.Physics.FIXED_DT
        if scenario=="hitch" then
            UI.OnUpdate(0.5)
            assert(UI.soloRun.timingLost and UI.race.status=="running", "nonterminal dropped time disqualifies the score")
        elseif scenario=="save_error" then
            ns.SoloRecords.Finish=function() error("save failed") end
        else
            local original=_G.GetServerTime
            _G.GetServerTime=function()
                local tick=UI.state.tick
                UI.OnUpdate(dt)
                assert(UI.state.tick==tick and not UI.active, "native callback cannot advance a finished kart")
                return original()
            end
        end
        for lap=1,3 do
            for _,gate in ipairs(ns.Track.gates) do
                UI.state.x=(gate.ax+gate.bx)/2-gate.nx
                UI.state.y=(gate.ay+gate.by)/2-gate.ny
                UI.state.heading=gate.nx==1 and 0 or gate.nx==-1 and math.pi or
                    gate.ny==1 and math.pi/2 or -math.pi/2
                UI.state.speed=200; UI.state.steering=0
                UI.OnUpdate(dt)
            end
        end
        assert(not UI.active and UI.race.status=="finished" and UI.summary:IsShown()
            and UI.window.keyboard==false and UI.window.propagate, "score problems must not wedge finish or controls")
        if scenario=="reentrant_save" then assert(UI.scoreResult.saved and AzerothKartDB.highscores)
        else assert(not UI.scoreResult.saved and AzerothKartDB.highscores==nil) end
    end)
end

withMock(nil,false,function(env,UI)
    env.fire("ADDON_LOADED","AzerothKart")
    UI.Toggle()
    local P = env.namespace.Physics
    assert(UI.SelectKart("steam_tank"))
    UI.Start(); finishCountdown(UI)
    assert(not UI.SelectKart("dwarven_biker"), "active choice cannot replace the latched handling")
    env.key(UI,"OnKeyDown","W")
    UI.kartId = "dwarven_biker" -- even an unrelated presentation write cannot retune the run
    UI.OnUpdate(P.FIXED_DT)
    assert(math.abs(UI.state.speed - P.GetHandling("steam_tank").accel * P.FIXED_DT) < 1e-10,
        "solo physics uses the kart captured at Start, not the current display ID")
    UI.Stop("handling fixture")
    UI.Start(); finishCountdown(UI)
    env.key(UI,"OnKeyDown","W"); UI.OnUpdate(P.FIXED_DT)
    assert(math.abs(UI.state.speed - P.GetHandling("dwarven_biker").accel * P.FIXED_DT) < 1e-10,
        "a fresh run captures the new choice")
    UI.Stop("handling fixture")
    UI.kartId = "unknown_future_kart"
    local state = UI.state
    UI.Start()
    assert(not UI.active and UI.state == state and UI.status.text:find("handling unavailable",1,true),
        "an unregistered kart refuses capture instead of failing inside the game loop")
end)

originalPrint("test_ui live integration: shared static grid/cues, held GO, peer sprites, copied observations and exits PASS")
