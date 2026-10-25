-- Cached/event-fed channel roster reader. No joins, sends, frames or UI writes.
local _, AK = ...
local Scores = assert(AK and AK.Highscores, "highscores required")
local Discovery = {MAX_CHANNELS=128, MAX_MEMBERS=256}
AK.ScoreDiscovery = Discovery

local function fold(value)
    return (value:gsub("[A-Z]", function(char) return string.char(char:byte()+32) end))
end

local function bytesBefore(a, b)
    for index=1,math.min(#a,#b) do
        local first,second=a:byte(index),b:byte(index)
        if first~=second then return first<second end
    end
    return #a<#b
end

-- Read(api, channelName, selfName) -> detachedSnapshot | nil, reason.
-- api supplies the three native getters and optionally issecretvalue. A nil
-- roster row is pending data, never proof of an empty or complete member list.
-- Display indices identify roster entries; localID is only channel metadata.
function Discovery.Read(api, channelName, selfName)
    if type(api)~="table" or type(api.GetNumDisplayChannels)~="function"
        or type(api.GetChannelDisplayInfo)~="function" or type(api.C_ChatInfo)~="table"
        or type(api.C_ChatInfo.GetChannelRosterInfo)~="function"
        or (api.issecretvalue~=nil and type(api.issecretvalue)~="function") then
        return nil,"unsupported"
    end
    local function visible(value)
        if api.issecretvalue then
            local ok,secret=pcall(api.issecretvalue,value)
            if not ok or secret~=false then return false end
        end
        return true
    end
    if not visible(channelName) or not visible(selfName) then return nil,"protected" end
    if type(channelName)~="string" or #channelName<1 or #channelName>96
        or channelName:find("[%z\001-\031\127|]") then return nil,"invalid_channel" end
    local own=Scores.NormalizeName(selfName)
    if not own then return nil,"invalid_name" end
    local ownKey,wanted=fold(own),fold(channelName)
    local ok,total=pcall(api.GetNumDisplayChannels)
    if not ok then return nil,"api_error" end
    if not visible(total) then return nil,"protected" end
    if total==nil then return nil,"pending" end
    if type(total)~="number" or total~=total or total%1~=0 or total<0 then
        return nil,"unreadable"
    end
    if total>Discovery.MAX_CHANNELS then return nil,"too_large" end

    local function candidate(index)
        local read,name,header,_,localID,count,active=pcall(api.GetChannelDisplayInfo,index)
        if not read then return nil,"api_error" end
        if not visible(header) then return nil,"protected" end
        if header==true then return false end
        if header~=false then return nil,"pending" end
        if not visible(name) then return nil,"protected" end
        if name==nil then return nil,"pending" end
        if type(name)~="string" or #name>96 then return nil,"unreadable" end
        if fold(name)~=wanted then return false end
        if not visible(active) or not visible(localID) or not visible(count) then
            return nil,"protected"
        end
        if active~=true or localID==nil or count==nil then return nil,"pending" end
        if type(localID)~="number" or localID~=localID or localID%1~=0 or localID<1
            or type(count)~="number" or count~=count or count%1~=0 or count<0 then
            return nil,"unreadable"
        end
        if count>Discovery.MAX_MEMBERS then return nil,"too_large" end
        if count==0 then return nil,"pending" end
        return {displayIndex=index,localID=localID,members=count}
    end

    local selected
    for index=1,total do
        local found,reason=candidate(index)
        if found==nil then return nil,reason end
        if found then
            if selected then return nil,"ambiguous" end
            selected=found
        end
    end
    if not selected then return nil,"pending" end
    local players,keys={},{}
    for index=1,selected.members do
        local read,name=pcall(api.C_ChatInfo.GetChannelRosterInfo,selected.displayIndex,index)
        if not read then return nil,"api_error" end
        if not visible(name) then return nil,"protected" end
        local normalized=Scores.NormalizeName(name)
        if not normalized then return nil,"pending" end
        local key=fold(normalized)
        if key~=ownKey then
            local previous=players[key]
            if not previous then keys[#keys+1]=key end
            if not previous or bytesBefore(normalized,previous) then players[key]=normalized end
        end
    end
    -- Native callbacks may have changed display indices or membership while
    -- reading. Re-resolve the exact entry before returning a usable snapshot.
    local current,reason=candidate(selected.displayIndex)
    if current==nil then return nil,reason end
    if not current or current.localID~=selected.localID or current.members~=selected.members then
        return nil,"pending"
    end
    table.sort(keys,bytesBefore)
    local peers={}
    for index,key in ipairs(keys) do peers[index]=players[key] end
    return {peers=peers,ready=true,localID=selected.localID,
        displayIndex=selected.displayIndex,members=selected.members}
end

return Discovery
