local isMenuOpen = false
local myServerId = nil
local canSeeIdentifiers = false
local cachedOnline = {}
local cachedDisconnected = {}
local activeThreadRunning = false

---Get active locale table
---@return table
local function getLocaleData()
    local lang = Config.Locale or 'en'
    if Locales and Locales[lang] then
        return Locales[lang]
    end
    return Locales and Locales['en'] or {}
end

---Close the player list menu
local function closeMenu()
    if not isMenuOpen then return end
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'close'
    })
    TriggerServerEvent('mazilkata-playerlist:server:closeMenu')
end

---Start the single background thread for 3D Head IDs and proximity area scanning
local function startActiveThread()
    if activeThreadRunning then return end
    activeThreadRunning = true

    CreateThread(function()
        local headDistSq = (Config.HeadIdDistance or 15.0) ^ 2
        local areaDistSq = (Config.AreaRadius or 25.0) ^ 2
        local heightOffset = vector3(0.0, 0.0, Config.HeadIdHeightOffset or 1.05)
        local normalColor = Config.HeadIdNormalColor or { r = 255, g = 255, b = 255, a = 230 }
        local speakingColor = Config.HeadIdSpeakingColor or { r = 34, g = 211, b = 238, a = 255 }
        local font = Config.HeadIdFont or 4
        local scale = Config.HeadIdScale or 0.36

        local lastSync = 0
        local lastAreaCount = -1
        local lastSig = nil

        while isMenuOpen do
            local myPed = (cache and cache.ped) or PlayerPedId()
            local myCoords = (cache and cache.coords) or GetEntityCoords(myPed)
            local activePlayers = GetActivePlayers()
            local myPlayerId = PlayerId()

            local areaCount = 0
            local talkingMap = {}
            local nearbyToDraw = {}
            local now = GetGameTimer()

            for i = 1, #activePlayers do
                local player = activePlayers[i]
                local ped = GetPlayerPed(player)
                if DoesEntityExist(ped) then
                    local targetCoords = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
                    if targetCoords == vector3(0.0, 0.0, 0.0) then
                        targetCoords = GetEntityCoords(ped)
                    end

                    local dx = myCoords.x - targetCoords.x
                    local dy = myCoords.y - targetCoords.y
                    local dz = myCoords.z - targetCoords.z
                    local distSq = dx * dx + dy * dy + dz * dz

                    -- Count in area (including self)
                    if distSq <= areaDistSq then
                        areaCount = areaCount + 1
                    end

                    local sId = GetPlayerServerId(player)
                    local isTalking = HeadIds.IsPlayerTalking(player)
                    talkingMap[sId] = isTalking

                    -- Nearby 3D head tag (excluding self for cleaner view)
                    if player ~= myPlayerId and distSq <= headDistSq then
                        nearbyToDraw[#nearbyToDraw + 1] = {
                            coords = targetCoords,
                            serverId = sId,
                            isTalking = isTalking
                        }
                    end
                end
            end

            -- Sync live area count and talking states to the NUI (only when something changed)
            if (now - lastSync) > 200 then
                lastSync = now
                local sig = {}
                for sId, talking in pairs(talkingMap) do
                    if talking then sig[#sig + 1] = sId end
                end
                table.sort(sig)
                local sigStr = areaCount .. ':' .. table.concat(sig, ',')

                if sigStr ~= lastSig then
                    lastSig = sigStr
                    lastAreaCount = areaCount
                    SendNUIMessage({
                        action = 'updateLiveStats',
                        areaCount = areaCount,
                        talking = talkingMap
                    })
                end
            end

            -- If there are players nearby within HeadIdDistance, render every frame
            if #nearbyToDraw > 0 then
                for i = 1, #nearbyToDraw do
                    local item = nearbyToDraw[i]
                    local sId = item.serverId
                    local playerData = cachedOnline[sId]

                    local text = ''
                    local color = normalColor

                    if item.isTalking then
                        color = speakingColor
                        if canSeeIdentifiers and playerData and playerData.identifier and playerData.identifier ~= 'N/A' then
                            text = ('[%d] %s'):format(sId, playerData.identifier)
                        else
                            text = ('[%d]'):format(sId)
                        end
                    else
                        color = normalColor
                        if playerData and playerData.name then
                            text = ('[%d] %s'):format(sId, playerData.name)
                        else
                            text = ('[%d]'):format(sId)
                        end
                    end

                    HeadIds.DrawText3D(item.coords + heightOffset, text, color, scale, font)
                end
                Wait(0)
            else
                -- No players in head ID range: sleep briefly to preserve CPU
                Wait(100)
            end
        end

        activeThreadRunning = false
    end)
end

---Open the player list menu
local function openMenu()
    if isMenuOpen then return end
    isMenuOpen = true
    TriggerServerEvent('mazilkata-playerlist:server:openMenu')
end

---Toggle menu state
local function toggleMenu()
    if isMenuOpen then
        closeMenu()
    else
        openMenu()
    end
end

-- Register Keybind using ox_lib
lib.addKeybind({
    name = 'mazilkata_playerlist',
    description = 'Toggle Player List Menu',
    defaultKey = Config.OpenKey or 'F10',
    onPressed = function()
        toggleMenu()
    end
})

-- Also register a console command fallback
RegisterCommand('playerlist', function()
    toggleMenu()
end, false)

---Handle receiving initial menu data from server
RegisterNetEvent('mazilkata-playerlist:client:receiveMenuData', function(data)
    if not isMenuOpen then return end

    myServerId = data.mySource
    canSeeIdentifiers = data.canSeeIdentifiers

    cachedOnline = {}
    if data.online then
        for _, p in ipairs(data.online) do
            cachedOnline[p.id] = p
        end
    end
    cachedDisconnected = data.disconnected or {}

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'open',
        data = {
            online = data.online or {},
            disconnected = data.disconnected or {},
            mySource = myServerId,
            canSeeIdentifiers = canSeeIdentifiers,
            locale = getLocaleData(),
            showPing = Config.ShowPing ~= false,
            showSearch = Config.ShowSearch == true,
            openKey = Config.OpenKey or 'F6'
        }
    })

    startActiveThread()
end)

---Live delta updates from server
RegisterNetEvent('mazilkata-playerlist:client:playerJoined', function(player)
    if not isMenuOpen then return end
    cachedOnline[player.id] = player
    SendNUIMessage({
        action = 'playerJoined',
        player = player
    })
end)

RegisterNetEvent('mazilkata-playerlist:client:playerLeft', function(data)
    if not isMenuOpen then return end
    cachedOnline[data.id] = nil
    SendNUIMessage({
        action = 'playerLeft',
        id = data.id,
        disconnectedRecord = data.disconnectedRecord
    })
end)

RegisterNetEvent('mazilkata-playerlist:client:playerUpdated', function(player)
    if not isMenuOpen then return end
    cachedOnline[player.id] = player
    SendNUIMessage({
        action = 'playerUpdated',
        player = player
    })
end)

RegisterNetEvent('mazilkata-playerlist:client:updatePings', function(pings)
    if not isMenuOpen then return end
    for id, ping in pairs(pings) do
        if cachedOnline[id] then
            cachedOnline[id].ping = ping
        end
    end
    SendNUIMessage({
        action = 'updatePings',
        pings = pings
    })
end)

RegisterNetEvent('mazilkata-playerlist:client:syncDisconnected', function(discoList)
    if not isMenuOpen then return end
    cachedDisconnected = discoList
    SendNUIMessage({
        action = 'syncDisconnected',
        disconnected = discoList
    })
end)

-- NUI Callbacks
RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('ready', function(_, cb)
    SendNUIMessage({
        action = 'setLocale',
        locale = getLocaleData()
    })
    cb('ok')
end)

-- Ensure cleanup on resource stop
AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if isMenuOpen then
        SetNuiFocus(false, false)
    end
end)
