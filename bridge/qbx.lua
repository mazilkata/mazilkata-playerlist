Bridge = Bridge or {}
Bridge.QBX = {}

---Get the display name for a player in QBox mode
---@param source number|string
---@return string
function Bridge.QBX.getDisplayName(source)
    if Config.DisplayNameMode == 'character' then
        if GetResourceState('qbx_core') == 'started' then
            local success, player = pcall(function()
                return exports.qbx_core:GetPlayer(source)
            end)
            if success and player and player.PlayerData and player.PlayerData.charinfo then
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

---Check if player has administrator privileges in QBox mode
---@param source number|string
---@return boolean
function Bridge.QBX.isAdmin(source)
    if GetResourceState('qbx_core') == 'started' then
        local success, hasPerm = pcall(function()
            if exports.qbx_core.HasPermission then
                return exports.qbx_core:HasPermission(source, 'admin')
            end
            if exports.qbx_core.HasGroup then
                return exports.qbx_core:HasGroup(source, 'admin')
            end
            return false
        end)
        if success and hasPerm then
            return true
        end
    end

    return Bridge.Standalone.isAdmin(source)
end
