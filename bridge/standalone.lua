Bridge = Bridge or {}
Bridge.Standalone = {}

---Get the display name for a player in Standalone mode
---@param source number|string
---@return string
function Bridge.Standalone.getDisplayName(source)
    local name = GetPlayerName(source)
    if name and name ~= '' then
        return name
    end
    return 'Player ' .. tostring(source)
end

---Check if player has administrator privileges in Standalone mode
---@param source number|string
---@return boolean
function Bridge.Standalone.isAdmin(source)
    local permission = Config.AdminAcePermission or 'playerlist.admin'
    if IsPlayerAceAllowed(source, permission) then
        return true
    end
    if IsPlayerAceAllowed(source, 'command') then
        return true
    end
    return false
end
