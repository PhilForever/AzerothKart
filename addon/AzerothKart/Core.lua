local addonName, AK = ...
assert(type(AK) == "table", "addon namespace required")
_G.AzerothKart = AK -- only bootstrap exports the public diagnostics namespace
AK.version = "0.0.1"
AK.events = {}

local eventFrame = CreateFrame("Frame")
AK.TransportProbe.Init(eventFrame) -- Reuse bootstrap; no network registration/traffic on load.
AK.SessionTransport.Init(eventFrame) -- Exclusive lease; menu actions opt in later.
AK.ScoreChannelProbe.Init(eventFrame) -- Explicit channel check; no score publishing.
local failures = {}
for _,event in ipairs({"ADDON_LOADED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED",
    "PLAYER_LEAVING_WORLD","PLAYER_LOGOUT"}) do
    local ok, result = pcall(eventFrame.RegisterEvent,eventFrame,event)
    if ok and result ~= false then AK.events[event] = true else failures[#failures+1] = event end
end
if #failures > 0 then AK.eventFailures = table.concat(failures,",") end
eventFrame:SetScript("OnEvent",function(_,event,...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize absent data/version markers. Malformed/future saves stay available
        -- for recovery; neither preferences nor highscores may reset them.
        if AzerothKartDB == nil then AzerothKartDB = {} end
        if type(AzerothKartDB) == "table" and AzerothKartDB.schemaVersion == nil then
            AzerothKartDB.schemaVersion = 1
        end
        AK.SoloRecords.Init()
        if AK.ScoreSharing then AK.ScoreSharing.Init(eventFrame) end
        AK.UI.Create()
        if AK.Menu and type(AK.Menu.SetSessionBridge)=="function" then
            AK.Menu.SetSessionBridge({view=AK.SessionTransport.GetView,
                action=function(name,...)
                    if type(AK.UI.MultiplayerAction)~="function" then return false,"unavailable" end
                    return AK.UI.MultiplayerAction(name,...)
                end})
        end
        eventFrame:UnregisterEvent("ADDON_LOADED")
    elseif event == "CHAT_MSG_ADDON_LOGGED" then
        AK.TransportProbe.Message(...)
        AK.SessionTransport.Message(...)
        AK.ScoreChannelProbe.Message(...)
    else
        AK.TransportProbe.HandleEvent(event)
        AK.SessionTransport.HandleEvent(event)
        AK.ScoreChannelProbe.HandleEvent(event)
        AK.UI.HandleEvent(event,arg1)
    end
end)

SLASH_AZEROTHKART1 = "/akart"
SLASH_AZEROTHKART2 = "/azerothkart"
SlashCmdList.AZEROTHKART = function(message)
    local command,argument
    if type(message) == "string" then command,argument = message:match("^%s*(%S+)%s*(.-)%s*$") end
    if command == "probe" and argument == "" then
        AK.UI.ReportProbe()
    elseif command == "perf" then
        AK.UI.PerformanceCommand(argument)
    elseif command == "net" then
        AK.TransportProbe.Command(argument)
    elseif command == "scores" then
        if AK.ScoreSharing and (argument=="" or argument=="status") then AK.ScoreSharing.Report()
        else AK.ScoreChannelProbe.Command(argument) end
    else AK.UI.Toggle() end
end
