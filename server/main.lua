local onlinePlayers = {}
local disconnectedPlayers = {}
local menuViewers = {}
local rateLimits = {}

local notifyViewers

---Build the table sent to clients for one online player
---@param p table
---@param canSee boolean can the viewer see identifiers
---@param viewerSrc number
---@return table
local function buildPlayerPayload(p, canSee, viewerSrc)
    return {
        id = p.id,
        name = p.name,
        ping = GetPlayerPing(p.id),
        identifier = canSee and p.identifier or nil,
        avatar = Utils.CanViewerSeeAvatars(viewerSrc) and p.avatar or nil
    }
end

---Register or update a player in the online list
---@param src number|string
local function registerOnlinePlayer(src)
    src = tonumber(src)
    if not src or src <= 0 then return end

    local name = Utils.SanitizeString(Bridge.getDisplayName(src))
    local identifier = Utils.GetPlayerPrimaryIdentifier(src)
    local ping = GetPlayerPing(src)

    local previous = onlinePlayers[src]
    local avatarKey = Utils.GetAvatarKey(src)

    onlinePlayers[src] = {
        id = src,
        name = name,
        identifier = identifier,
        ping = ping,
        avatarKey = avatarKey,
        avatar = previous and previous.avatarKey == avatarKey and previous.avatar or nil
    }

    -- Fetch the avatar in the background, then push it to anyone with the menu open
    if not onlinePlayers[src].avatar then
        Utils.GetAvatar(src, function(url)
            local p = onlinePlayers[src]
            if not p or not url or p.avatarKey ~= avatarKey then return end
            p.avatar = url
            if next(menuViewers) ~= nil then
                notifyViewers('mazilkata-playerlist:client:playerUpdated', function(viewerSrc, canSee)
                    return buildPlayerPayload(p, canSee, viewerSrc)
                end)
            end
        end)
    end

    if Config.Debug then
        print(('[^2mazilkata-playerlist^7] Registered online player [%s] %s (Identifier: %s)'):format(src, name, identifier))
    end
end

---Notify all clients who currently have the player list open
---@param eventName string
---@param dataFn function (src, canSee) -> data
function notifyViewers(eventName, dataFn)
    for viewerSrc, _ in pairs(menuViewers) do
        if GetPlayerPing(viewerSrc) > 0 then
            local canSee = Utils.CanViewerSeeIdentifiers(viewerSrc)
            local payload = dataFn(viewerSrc, canSee)
            TriggerClientEvent(eventName, viewerSrc, payload)
        else
            menuViewers[viewerSrc] = nil
        end
    end
end

---Initialize online players on resource start
AddEventHandler('onResourceStart', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    Wait(500)
    for _, strSrc in ipairs(GetPlayers()) do
        local src = tonumber(strSrc)
        if src then
            registerOnlinePlayer(src)
        end
    end
end)

---Handle player connecting / loaded
RegisterNetEvent('playerJoining', function()
    local src = source
    Wait(1000) -- Allow session and identifiers to initialize
    registerOnlinePlayer(src)

    if next(menuViewers) ~= nil and onlinePlayers[src] then
        notifyViewers('mazilkata-playerlist:client:playerJoined', function(viewerSrc, canSee)
            return buildPlayerPayload(onlinePlayers[src], canSee, viewerSrc)
        end)
    end
end)

---Framework player character load listeners for display name resolution
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source
    Wait(500)
    registerOnlinePlayer(src)
    if next(menuViewers) ~= nil and onlinePlayers[src] then
        notifyViewers('mazilkata-playerlist:client:playerUpdated', function(viewerSrc, canSee)
            return buildPlayerPayload(onlinePlayers[src], canSee, viewerSrc)
        end)
    end
end)

RegisterNetEvent('esx:playerLoaded', function(playerId)
    local src = playerId or source
    Wait(500)
    registerOnlinePlayer(src)
    if next(menuViewers) ~= nil and onlinePlayers[src] then
        notifyViewers('mazilkata-playerlist:client:playerUpdated', function(viewerSrc, canSee)
            return buildPlayerPayload(onlinePlayers[src], canSee, viewerSrc)
        end)
    end
end)

RegisterNetEvent('qbx_core:server:playerLoaded', function()
    local src = source
    Wait(500)
    registerOnlinePlayer(src)
    if next(menuViewers) ~= nil and onlinePlayers[src] then
        notifyViewers('mazilkata-playerlist:client:playerUpdated', function(viewerSrc, canSee)
            return buildPlayerPayload(onlinePlayers[src], canSee, viewerSrc)
        end)
    end
end)

---Handle player disconnect
AddEventHandler('playerDropped', function(reason)
    local src = source
    local player = onlinePlayers[src]

    local name = player and player.name or (GetPlayerName(src) or ('Player ' .. tostring(src)))
    local identifier = player and player.identifier or Utils.GetPlayerPrimaryIdentifier(src)

    -- Insert into disconnected history
    local record = {
        id = src,
        name = Utils.SanitizeString(name),
        identifier = identifier,
        reason = reason or 'Disconnected',
        leftAt = os.time(),
        avatar = player and player.avatar or nil
    }

    table.insert(disconnectedPlayers, 1, record)
    if #disconnectedPlayers > (Config.MaxDisconnected or 20) then
        table.remove(disconnectedPlayers)
    end

    onlinePlayers[src] = nil
    menuViewers[src] = nil
    rateLimits[src] = nil

    if next(menuViewers) ~= nil then
        notifyViewers('mazilkata-playerlist:client:playerLeft', function(viewerSrc, canSee)
            return {
                id = src,
                disconnectedRecord = {
                    id = record.id,
                    name = record.name,
                    leftAt = record.leftAt,
                    identifier = canSee and record.identifier or nil,
                    avatar = Utils.CanViewerSeeAvatars(viewerSrc) and record.avatar or nil
                }
            }
        end)
    end
end)

---Client opens menu -> fetch data and register as active viewer
RegisterNetEvent('mazilkata-playerlist:server:openMenu', function()
    local src = source
    local now = GetGameTimer()

    -- Rate limiting: prevent spamming menu toggles
    if rateLimits[src] and (now - rateLimits[src]) < 400 then
        return
    end
    rateLimits[src] = now

    -- Ensure requesting player is recorded
    if not onlinePlayers[src] then
        registerOnlinePlayer(src)
    end

    menuViewers[src] = true

    local canSee = Utils.CanViewerSeeIdentifiers(src)

    -- Prepare sanitized online list for this viewer
    local onlineList = {}
    for pSrc, pData in pairs(onlinePlayers) do
        table.insert(onlineList, buildPlayerPayload(pData, canSee, src))
    end

    -- Prepare sanitized disconnected list
    local canSeeAvatars = Utils.CanViewerSeeAvatars(src)
    local nowEpoch = os.time()
    local maxAgeSec = (Config.DisconnectedMaxAge or 15) * 60
    local discoList = {}
    for _, r in ipairs(disconnectedPlayers) do
        if (nowEpoch - r.leftAt) <= maxAgeSec then
            table.insert(discoList, {
                id = r.id,
                name = r.name,
                leftAt = r.leftAt,
                identifier = canSee and r.identifier or nil,
                avatar = canSeeAvatars and r.avatar or nil
            })
        end
    end

    TriggerClientEvent('mazilkata-playerlist:client:receiveMenuData', src, {
        online = onlineList,
        disconnected = discoList,
        mySource = src,
        canSeeIdentifiers = canSee
    })
end)

---Client closes menu -> unregister viewer
RegisterNetEvent('mazilkata-playerlist:server:closeMenu', function()
    local src = source
    menuViewers[src] = nil
end)

---Sync pings at configured interval only to active menu viewers
CreateThread(function()
    while true do
        Wait(Config.PingRefreshInterval or 5000)
        if next(menuViewers) ~= nil then
            local pingMap = {}
            for pSrc, _ in pairs(onlinePlayers) do
                pingMap[pSrc] = GetPlayerPing(pSrc)
            end
            for viewerSrc, _ in pairs(menuViewers) do
                TriggerClientEvent('mazilkata-playerlist:client:updatePings', viewerSrc, pingMap)
            end
        end
    end
end)

---Prune expired disconnected players every 60 seconds
CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        local maxAgeSec = (Config.DisconnectedMaxAge or 15) * 60
        local pruned = false

        for i = #disconnectedPlayers, 1, -1 do
            if (now - disconnectedPlayers[i].leftAt) > maxAgeSec then
                table.remove(disconnectedPlayers, i)
                pruned = true
            end
        end

        if pruned and next(menuViewers) ~= nil then
            notifyViewers('mazilkata-playerlist:client:syncDisconnected', function(viewerSrc, canSee)
                local list = {}
                for _, r in ipairs(disconnectedPlayers) do
                    table.insert(list, {
                        id = r.id,
                        name = r.name,
                        leftAt = r.leftAt,
                        identifier = canSee and r.identifier or nil,
                        avatar = Utils.CanViewerSeeAvatars(viewerSrc) and r.avatar or nil
                    })
                end
                return list
            end)
        end
    end
end)
