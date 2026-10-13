Bridge = Bridge or {}
Bridge.ESX = {}

local ESX = nil

local function getESX()
    if ESX then return ESX end
    if GetResourceState('es_extended') == 'started' then
        local success, obj = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if success and obj then
            ESX = obj
            return ESX
        end
    end
    return nil
end

---Get the display name for a player in ESX mode
---@param source number|string
---@return string
function Bridge.ESX.getDisplayName(source)
    if Config.DisplayNameMode == 'character' then
        local esx = getESX()
        if esx then
            local xPlayer = esx.GetPlayerFromId(source)
            if xPlayer then
                if xPlayer.getName then
                    local charName = xPlayer.getName()
                    if charName and charName ~= '' then
                        return charName
                    end
                end
                local firstName = xPlayer.get('firstName')
                local lastName = xPlayer.get('lastName')
                if firstName and lastName then
                    return firstName .. ' ' .. lastName
                end
            end
        end
    end

    local name = GetPlayerName(source)
    return (name and name ~= '') and name or ('Player ' .. tostring(source))
end

---Check if player has administrator privileges in ESX mode
---@param source number|string
---@return boolean
function Bridge.ESX.isAdmin(source)
    local esx = getESX()
    if esx then
        local xPlayer = esx.GetPlayerFromId(source)
        if xPlayer then
            local group = xPlayer.getGroup()
            if group == 'admin' or group == 'superadmin' or group == 'mod' or group == 'owner' then
                return true
            end
        end
    end

    return Bridge.Standalone.isAdmin(source)
end
