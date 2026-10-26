-- Native API doubles; no Forever persistence/date/network claim.
local globals = {"AzerothKartDB", "NameUtil", "UnitNameUnmodified", "Constants",
    "GetServerTime", "date", "issecretvalue"}
local function fixture(db, test)
    local saved = {}
    for _, name in ipairs(globals) do saved[#saved+1] = {name, _G[name]} end
    local reads = {name=0, time=0, date=0}
    _G.AzerothKartDB = db
    _G.NameUtil = {GetUnmodifiedUnitFullName=function(unit)
        assert(unit == "player"); reads.name=reads.name+1; return "Lene Conradi"
    end}
    _G.UnitNameUnmodified, _G.Constants, _G.issecretvalue = nil, nil, nil
    _G.GetServerTime = function() reads.time=reads.time+1; return 1792756800 end
    _G.date = function(format, epoch)
        reads.date=reads.date+1
        assert(format == "!%Y-%m-%d" and epoch == 1792756800)
        return "2026-10-23"
    end
    local ok, why = pcall(function()
        local ns = {}
        for _, name in ipairs({"Track", "MirageRaceway", "Circuit", "CapitalCities", "Dungeon", "ScarletCrusade", "Courses", "Physics", "Highscores", "SoloRecords"}) do
            assert(loadfile("addon/AzerothKart/"..name..".lua"))("AzerothKart", ns)
        end
        ns.SoloRecords.Init()
        local function run(ticks)
            return ns.SoloRecords.Begin(ns.Courses.build("mirage_raceway", ns.Track.crossesGate), "goblin_mortar_trike"),
                {status="finished", targetLaps=3, laps={completedLaps=3},
                 startTick=180, finishTick=180+(ticks or 2345), totalTicks=ticks or 2345}
        end
        test(ns.SoloRecords, ns, run, reads)
    end)
    for _, pair in ipairs(saved) do _G[pair[1]] = pair[2] end
    assert(ok, why)
end

fixture({schemaVersion=1, custom={keep=true}, preferences={sound=false}}, function(R, ns, run, reads)
    local root, prefs = AzerothKartDB, AzerothKartDB.preferences
    local token, race = run()
    assert(reads.name==0 and reads.time==0 and root.highscores==nil, "load/start performs no date/name read or storage write")
    local result = R.Finish(token, race, false)
    assert(result.saved and result.totalTicks==2345 and result.message:find("0:39.08",1,true))
    assert(AzerothKartDB==root and root.preferences==prefs and root.custom.keep, "finish preserves unrelated saved data")
    local raw = root.highscores
    assert(R.Finish(token,race,false)==nil and root.highscores==raw and reads.name==1 and reads.time==1,
        "same run captured once even across repeated callbacks")
    local view = R.GetView("mirage_raceway")
    assert(view.writable and view.scope=="local" and view.publication=="Global publishing pending")
    local row = view.rows[1]
    assert(#view.rows==1 and row.playerName=="Lene Conradi" and row.totalTicks==2345 and row.finishedAt==1792756800)
    assert(row.trackId=="mirage_raceway" and row.trackVersion==ns.Courses.build("mirage_raceway",ns.Track.crossesGate).version and row.physicsVersion==12
        and row.tickRate==60 and row.lapCount==3 and row.rulesVersion==1)
    row.playerName="Mutated"; assert(R.GetView("mirage_raceway").rows[1].playerName=="Lene Conradi", "detached view")
    assert(#R.GetView("stormwind_city").rows==0, "boards separated by track")
    local slower, slowRace=run(2400)
    assert(not R.Finish(slower,slowRace,false).saved and root.highscores==raw, "slower run preserves best and date")
    local faster, fastRace=run(2300)
    assert(R.Finish(faster,fastRace,false).saved and R.GetView("mirage_raceway").rows[1].totalTicks==2300)
    R.Init(); assert(R.GetView("mirage_raceway").rows[1].totalTicks==2300, "save reload round trip")
    assert(R.FormatTime(60)=="0:01.00" and R.FormatTime(3599)=="0:59.98" and R.FormatTime(3600)=="1:00.00")
    assert(R.FormatTime(0/0)=="--" and R.FormatTime(-1)=="--")
    assert(R.FormatDate(1792756800)=="2026-10-23" and reads.date==1)
    _G.date=function() error("date unavailable") end
    assert(R.FormatDate(1792756800)=="Date unavailable" and R.FormatDate(0)=="--")
end)

fixture({schemaVersion=1}, function(R, ns, run, reads)
    local historical={trackId="test_oval",trackVersion=ns.Track.version,physicsVersion=12,
        lapCount=3,tickRate=60,rulesVersion=1,playerName="Lene Conradi",totalTicks=2500,
        finishedAt=1792756800,kartId="goblin_mortar_trike"}
    local old=ns.Highscores.Submit(ns.Highscores.Load(nil),historical)
    AzerothKartDB.highscores=old
    R.Init()
    assert(R.Context(ns.Track)==nil and R.Context({id="future_course",version=1})==nil,
        "retired and unknown courses cannot create current score contexts")
    for _,id in ipairs({"scarlet_library","scarlet_armory","scarlet_cathedral"}) do
        local track=ns.Courses.build(id,ns.Track.crossesGate)
        local context=assert(R.Context(track))
        assert(context.trackId==id and context.trackVersion==track.version and context.lapCount==1,
            "reviewed dungeon contexts use their actual one-run geometry: "..id)
    end
    local _,race=run()
    assert(R.Finish(R.Begin(ns.Track,"goblin_mortar_trike"),race,false)==nil)
    assert(reads.name==0 and reads.time==0 and AzerothKartDB.highscores==old,
        "retired course does not save, publish or read identity/date")
    assert(R.GetView("test_oval").context==nil and #R.GetView("test_oval").rows==0)
    local token,current=run()
    assert(R.Finish(token,current,false).saved and #R.GetView("mirage_raceway").rows==1)
    assert(ns.Highscores.View(AzerothKartDB.highscores,historical)[1].totalTicks==2500,
        "current production finish preserves historical retired-course records")
end)

for _, kind in ipairs({"stopped", "countdown", "interrupted", "partial", "inconsistent", "multiplayer", "hitch"}) do
    fixture({schemaVersion=1}, function(R, _, run, reads)
        local token, race=run()
        if kind=="partial" then race.laps.completedLaps=2
        elseif kind=="inconsistent" then race.finishTick=race.finishTick+1
        elseif kind=="hitch" then token.timingLost=true
        elseif kind~="multiplayer" then race.status=kind end
        local result=R.Finish(token,race,kind=="multiplayer")
        assert(AzerothKartDB.highscores==nil and reads.name==0 and reads.time==0, kind.." cannot save")
        assert(result==nil or (not result.saved and result.message:find("timing",1,true)))
        assert(R.Finish(token,race,false)==nil, "refusal is also once-only")
    end)
end

for _, bad in ipairs({false, "broken", 45, {schemaVersion=77, highscores={version=99, future="keep"}},
        {schemaVersion=1, highscores=false}, {schemaVersion=1, highscores={version=99}},
        {schemaVersion=1, highscores={version=1, boards="broken"}}}) do
    fixture(bad, function(R, _, run, reads)
        local before=AzerothKartDB
        local child=type(before)=="table" and before.highscores
        local token,race=run()
        local result=R.Finish(token,race,false)
        assert(not result.saved and not R.GetView("mirage_raceway").writable)
        assert(AzerothKartDB==before and (type(before)~="table" or before.highscores==child), "malformed/future save unchanged")
        assert(reads.name==0 and reads.time==0)
    end)
end

fixture({schemaVersion=1}, function(R, _, run)
    _G.NameUtil=nil
    _G.UnitNameUnmodified=function() return "Flaturlative", "Breeze" end
    _G.Constants={CharacterNameSeparatorConsts={CHARACTERNAME_SURNAME_SEPARATOR=" "}}
    local token,race=run()
    assert(R.Finish(token,race,false).saved and R.GetView("mirage_raceway").rows[1].playerName=="Flaturlative Breeze",
        "Forever first name + surname, no inferred realm")
end)

for _, failure in ipairs({"no_name", "bad_name", "secret_name", "no_date", "bad_date", "secret_date", "changed_save"}) do
    fixture({schemaVersion=1}, function(R, _, run)
        local token,race=run()
        if failure=="no_name" then _G.NameUtil=nil
        elseif failure=="bad_name" then _G.NameUtil.GetUnmodifiedUnitFullName=function() return "|Hbad|h" end
        elseif failure=="secret_name" then
            _G.issecretvalue=function(value) return value=="Lene Conradi" end
        elseif failure=="no_date" then _G.GetServerTime=nil
        elseif failure=="bad_date" then _G.GetServerTime=function() return 0/0 end
        elseif failure=="secret_date" then _G.issecretvalue=function(value) return value==1792756800 end
        elseif failure=="changed_save" then AzerothKartDB.highscores={version=1,boards={}} end
        local before=AzerothKartDB.highscores
        local result=R.Finish(token,race,false)
        assert(not result.saved and result.message:find("saved",1,true) or failure=="changed_save")
        assert(AzerothKartDB.highscores==before, failure.." preserves data")
    end)
end
for _, mutation in ipairs({"schema_before", "schema_callback", "replace_child", "child_future", "replace_root"}) do
    fixture({schemaVersion=1, highscores={version=1,boards={}}}, function(R, _, run)
        local token,race=run()
        local root, child=AzerothKartDB, AzerothKartDB.highscores
        if mutation=="schema_before" then root.schemaVersion=77 end
        _G.GetServerTime=function()
            if mutation=="schema_callback" then root.schemaVersion=77
            elseif mutation=="replace_child" then root.highscores={version=77,keep=true}
            elseif mutation=="child_future" then child.version=77
            elseif mutation=="replace_root" then _G.AzerothKartDB={schemaVersion=1,keep=true} end
            return 1792756800
        end
        local result=R.Finish(token,race,false)
        assert(not result.saved, mutation.." cannot overwrite a changing save")
        if mutation=="replace_child" then assert(root.highscores.version==77 and root.highscores.keep)
        elseif mutation=="child_future" then assert(root.highscores==child and child.version==77)
        elseif mutation=="replace_root" then assert(AzerothKartDB~=root and AzerothKartDB.keep and AzerothKartDB.highscores==nil)
        else assert(root.schemaVersion==77 and root.highscores==child and next(child.boards)==nil) end
    end)
end
print("solo records: full-name/date, total ticks, once-only, save protection and eligibility checked (mock APIs)")
