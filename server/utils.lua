Utils = Utils or {}

---Convert a Steam hex identifier string to standard decimal SteamID64
---@param hexStr string
---@return string
function Utils.ConvertSteamHexTo64(hexStr)
    if not hexStr then return nil end
    local cleanHex = hexStr:gsub('^steam:', ''):gsub('^0x', '')
    if cleanHex == '' then return nil end

    local num = tonumber(cleanHex, 16)
    if num then
        return string.format('%.0f', num)
    end
    return hexStr
end

---Extract all available identifiers for a player source
---@param source number|string
---@return table<string, string>
function Utils.GetPlayerIdentifiersTable(source)
    local identifiers = {}
    local num = GetNumPlayerIdentifiers(source)
    for i = 0, num - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            if id:find('^steam:') then
                identifiers.steam = id
            elseif id:find('^discord:') then
                identifiers.discord = id
            elseif id:find('^license:') then
                identifiers.license = id
            elseif id:find('^license2:') and not identifiers.license then
                identifiers.license = id
            elseif id:find('^fivem:') then
                identifiers.fivem = id
            end
        end
    end
    return identifiers
end

---Get the configured primary identifier for a player with graceful fallbacks
---@param source number|string
---@return string
function Utils.GetPlayerPrimaryIdentifier(source)
    local idTable = Utils.GetPlayerIdentifiersTable(source)
    local pref = (Config.IdentifierType or 'steam'):lower()

    local fallbacks = { 'steam', 'discord', 'license', 'fivem' }
    -- Place preferred type first in priority
    local priority = { pref }
    for _, t in ipairs(fallbacks) do
        if t ~= pref then
            table.insert(priority, t)
        end
    end

    local chosen = nil
    local chosenType = nil
    for _, t in ipairs(priority) do
        if idTable[t] then
            chosen = idTable[t]
            chosenType = t
            break
        end
    end

    if not chosen then
        return 'N/A'
    end

    if chosenType == 'steam' then
        if Config.ConvertSteamTo64 then
            local steam64 = Utils.ConvertSteamHexTo64(chosen)
            return steam64 or chosen
        end
        return chosen
    elseif chosenType == 'discord' then
        return chosen:gsub('^discord:', '')
    elseif chosenType == 'fivem' then
        return chosen:gsub('^fivem:', '')
    end

    return chosen
end

---Check whether a given client source is authorized to view identifiers
---@param viewerSource number|string
---@return boolean
function Utils.CanViewerSeeIdentifiers(viewerSource)
    local mode = (Config.ShowIdentifiersTo or 'admins'):lower()
    if mode == 'everyone' then
        return true
    elseif mode == 'admins' then
        return Bridge.isAdmin(viewerSource)
    end
    return false
end

---Sanitize text string to prevent control characters or malformed strings
---@param str string
---@return string
function Utils.SanitizeString(str)
    if type(str) ~= 'string' then return '' end
    -- Remove non-printable control characters while preserving unicode letters
    return (str:gsub('[%c]', ''))
end

---Get a player's raw Discord user ID (digits only) regardless of Config.IdentifierType
---@param source number|string
---@return string|nil
function Utils.GetDiscordId(source)
    local id = GetPlayerIdentifierByType and GetPlayerIdentifierByType(source, 'discord')
    if not id then
        local idTable = Utils.GetPlayerIdentifiersTable(source)
        id = idTable.discord
    end
    if not id then return nil end
    return (id:gsub('^discord:', ''))
end

---Check whether a given client source is authorized to see avatars
---@param viewerSource number|string
---@return boolean
function Utils.CanViewerSeeAvatars(viewerSource)
    if Config.ShowAvatars == false then return false end
    local mode = (Config.ShowAvatarsTo or 'everyone'):lower()
    if mode == 'everyone' then
        return true
    elseif mode == 'admins' then
        return Bridge.isAdmin(viewerSource)
    end
    return false
end

local avatarCache = {}      -- [cacheKey] = { url = string|nil, expires = os.time }
local avatarPending = {}    -- [cacheKey] = { callbacks }

local function getBotToken()
    local token = GetConvar('mazilkata_discord_token', '')
    if token == '' then token = Config.DiscordBotToken or '' end
    return token
end

---Default Discord avatar (used when the user has no custom avatar)
local function defaultDiscordAvatar(discordId)
    local n = tonumber(discordId)
    local idx = n and ((n >> 22) % 6) or 0
    return ('https://cdn.discordapp.com/embed/avatars/%d.png'):format(idx)
end

---Run a cached + de-duplicated async lookup.
---@param key string cache key
---@param fetch function(done: function(url: string|nil, ok: boolean))
---@param cb function(url: string|nil)
local function cachedLookup(key, fetch, cb)
    local cached = avatarCache[key]
    if cached and cached.expires > os.time() then
        return cb(cached.url)
    end

    if avatarPending[key] then
        table.insert(avatarPending[key], cb)
        return
    end
    avatarPending[key] = { cb }

    fetch(function(url, ok)
        local ttl = ok and ((Config.AvatarCacheMinutes or 30) * 60) or 60
        avatarCache[key] = { url = url, expires = os.time() + ttl }
        local callbacks = avatarPending[key] or {}
        avatarPending[key] = nil
        for _, fn in ipairs(callbacks) do fn(url) end
    end)
end

---Discord avatar (needs a bot token)
local function fetchDiscordAvatar(discordId, cb)
    local token = getBotToken()
    if not discordId or token == '' then return cb(nil) end

    cachedLookup('discord:' .. discordId, function(done)
        PerformHttpRequest(('https://discord.com/api/v10/users/%s'):format(discordId), function(status, body)
            if status == 200 and body then
                local ok, data = pcall(json.decode, body)
                if ok and data then
                    if data.avatar and data.avatar ~= '' then
                        local ext = data.avatar:sub(1, 2) == 'a_' and 'gif' or 'png'
                        return done(('https://cdn.discordapp.com/avatars/%s/%s.%s?size=128'):format(discordId, data.avatar, ext), true)
                    end
                    return done(defaultDiscordAvatar(discordId), true)
                end
            end
            if Config.Debug then
                print(('[^1mazilkata-playerlist^7] Discord avatar lookup failed for %s (HTTP %s)'):format(discordId, tostring(status)))
            end
            done(nil, false)
        end, 'GET', '', {
            ['Authorization'] = 'Bot ' .. token,
            ['Content-Type'] = 'application/json'
        })
    end, cb)
end

---Cfx.re (FiveM forum) avatar - NO token needed.
---Uses the same public endpoint txAdmin uses to resolve Cfx.re accounts (unofficial, may change).
local function fetchCfxAvatar(fivemId, cb)
    if not fivemId then return cb(nil) end

    cachedLookup('cfx:' .. fivemId, function(done)
        PerformHttpRequest(('https://policy-live.fivem.net/api/getUserInfo/%s'):format(fivemId), function(status, body)
            if status == 200 and body then
                local ok, data = pcall(json.decode, body)
                local tpl = ok and type(data) == 'table' and data.avatar_template
                if type(tpl) == 'string' and tpl ~= '' then
                    tpl = tpl:gsub('{size}', '128')
                    if tpl:sub(1, 2) == '//' then
                        tpl = 'https:' .. tpl
                    elseif tpl:sub(1, 1) == '/' then
                        tpl = 'https://forum.cfx.re' .. tpl
                    end
                    return done(tpl, true)
                end
            end
            if Config.Debug then
                print(('[^1mazilkata-playerlist^7] Cfx.re avatar lookup failed for %s (HTTP %s)'):format(fivemId, tostring(status)))
            end
            done(nil, false)
        end, 'GET', '', { ['User-Agent'] = 'mazilkata-playerlist' })
    end, cb)
end

---Get a player's raw Cfx.re user ID (digits only)
---@param source number|string
---@return string|nil
function Utils.GetFivemId(source)
    local id = GetPlayerIdentifierByType and GetPlayerIdentifierByType(source, 'fivem')
    if not id then
        id = Utils.GetPlayerIdentifiersTable(source).fivem
    end
    if not id then return nil end
    return (id:gsub('^fivem:', ''))
end

---A string that changes when the player's avatar identity changes (used to avoid refetching)
---@param source number|string
---@return string
function Utils.GetAvatarKey(source)
    return (Utils.GetDiscordId(source) or '-') .. '|' .. (Utils.GetFivemId(source) or '-')
end

---Resolve an avatar URL for a player (async, cached). cb(url|nil)
---Config.AvatarSource: 'cfx' (no token) | 'discord' (needs bot token) | 'auto' (discord if token set, else cfx)
---@param source number|string
---@param cb function
function Utils.GetAvatar(source, cb)
    if Config.ShowAvatars == false then return cb(nil) end

    local mode = (Config.AvatarSource or 'auto'):lower()
    local discordId = Utils.GetDiscordId(source)
    local fivemId = Utils.GetFivemId(source)

    if mode == 'discord' then
        return fetchDiscordAvatar(discordId, cb)
    elseif mode == 'cfx' then
        return fetchCfxAvatar(fivemId, cb)
    end

    -- auto: Discord when a token is configured, otherwise (or on failure) Cfx.re
    if getBotToken() ~= '' and discordId then
        return fetchDiscordAvatar(discordId, function(url)
            if url then return cb(url) end
            fetchCfxAvatar(fivemId, cb)
        end)
    end
    fetchCfxAvatar(fivemId, cb)
end
