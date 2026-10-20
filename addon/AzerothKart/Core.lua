local addonName, AK = ...
assert(type(AK) == "table", "addon namespace required")
_G.AzerothKart = AK -- only bootstrap exports the public diagnostics namespace
AK.version = "0.0.1"
AK.events = {}

local eventFrame = CreateFrame("Frame")
AK.TransportProbe.Init(eventFrame) -- Reuse bootstrap; no network registration/traffic on load.
local failures = {}
for _,event in ipairs({"ADDON_LOADED","PLAYER_REGEN_DISABLED","PLAYER_REGEN_ENABLED",
    "GLOBAL_MOUSE_DOWN","PLAYER_LEAVING_WORLD","PLAYER_LOGOUT"}) do
    local ok, result = pcall(eventFrame.RegisterEvent,eventFrame,event)
    if ok and result ~= false then AK.events[event] = true else failures[#failures+1] = event end
end
if #failures > 0 then AK.eventFailures = table.concat(failures,",") end
eventFrame:SetScript("OnEvent",function(_,event,...)
    local arg1 = ...
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Preserve unknown fields/schema versions; this M0 probe only initializes v1.
        if type(AzerothKartDB) ~= "table" then AzerothKartDB = {} end
        if AzerothKartDB.schemaVersion == nil then AzerothKartDB.schemaVersion = 1 end
        AK.UI.Create()
        eventFrame:UnregisterEvent("ADDON_LOADED")
    elseif event == "CHAT_MSG_ADDON" then
        AK.TransportProbe.Message(...)
    else
        AK.TransportProbe.HandleEvent(event)
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
    else AK.UI.Toggle() end
end
