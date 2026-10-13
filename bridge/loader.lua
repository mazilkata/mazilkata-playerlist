Bridge = Bridge or {}

local function detectFramework()
    local cfgMode = (Config.Framework or 'auto'):lower()
    if cfgMode ~= 'auto' then
        return cfgMode
    end

    if GetResourceState('qbx_core') == 'started' then
        return 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        return 'qb'
    elseif GetResourceState('es_extended') == 'started' then
        return 'esx'
    end

    return 'standalone'
end

local active = detectFramework()
Bridge.ActiveFramework = active

if active == 'qbx' and Bridge.QBX then
    Bridge.getDisplayName = Bridge.QBX.getDisplayName
    Bridge.isAdmin = Bridge.QBX.isAdmin
elseif active == 'qb' and Bridge.QB then
    Bridge.getDisplayName = Bridge.QB.getDisplayName
    Bridge.isAdmin = Bridge.QB.isAdmin
elseif active == 'esx' and Bridge.ESX then
    Bridge.getDisplayName = Bridge.ESX.getDisplayName
    Bridge.isAdmin = Bridge.ESX.isAdmin
else
    Bridge.getDisplayName = Bridge.Standalone.getDisplayName
    Bridge.isAdmin = Bridge.Standalone.isAdmin
end

if Config.Debug then
    print(('[^2mazilkata-playerlist^7] Framework initialized: ^3%s^7'):format(Bridge.ActiveFramework))
end
