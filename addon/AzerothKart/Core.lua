local AK = _G.AzerothKart or {}
_G.AzerothKart=AK
AK.version="0.0.1"

local eventFrame=CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent",function(_,event,arg1)
    if event=="ADDON_LOADED" and arg1=="AzerothKart" then
        -- SavedVariables can be malformed; repair only a minimal schema here.
        if type(AzerothKartDB) ~= "table" then AzerothKartDB={} end
        if type(AzerothKartDB.schemaVersion) ~= "number" then
            AzerothKartDB.schemaVersion=1
        end
        AK.UI.Create()
        eventFrame:UnregisterEvent("ADDON_LOADED")
    elseif event=="PLAYER_REGEN_DISABLED" then
        if AK.UI and AK.UI.active then AK.UI.Stop("Combat interrupted test drive") end
    elseif event=="PLAYER_REGEN_ENABLED" then
        if AK.UI then AK.UI.OnCombatEnded() end
    end
end)

SLASH_AZEROTHKART1="/akart"
SLASH_AZEROTHKART2="/azerothkart"
SlashCmdList.AZEROTHKART=function() AK.UI.Toggle() end
