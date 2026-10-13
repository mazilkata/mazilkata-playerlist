Bridge = Bridge or {}
Bridge.QB = {}

local QBCore = nil

local function getQBCore()
    if QBCore then return QBCore end
    if GetResourceState('qb-core') == 'started' then
        local success, obj = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if success and obj then
            QBCore = obj
            return QBCore
        end
    end
    return nil
end

---Get the display name for a player in QBCore mode
---@param source number|string
---@return string
function Bridge.QB.getDisplayName(source)
    if Config.DisplayNameMode == 'character' then
        local qb = getQBCore()
        if qb then
            local player = qb.Functions.GetPlayer(source)
            if player and player.PlayerData and player.PlayerData.charinfo then
                local charinfo = player.PlayerData.charinfo
                if charinfo.firstname and charinfo.lastname then
                    local fullName = ('%s %s'):format(charinfo.firstname, charinfo.lastname)
                    if fullName:gsub('%s+', '') ~= '' then
                        return fullName
                    end
                end
            end
        end
    end

    local name = GetPlayerName(source)
    return (name and name ~= '') and name or ('Player ' .. tostring(source))
end

---Check if player has administrator privileges in QBCore mode
---@param source number|string
---@return boolean
function Bridge.QB.isAdmin(source)
    local qb = getQBCore()
    if qb then
        if qb.Functions.HasPermission then
            if qb.Functions.HasPermission(source, 'admin') or qb.Functions.HasPermission(source, 'god') then
                return true
            end
        end
    end

    return Bridge.Standalone.isAdmin(source)
end
