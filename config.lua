Config = {}

-- Framework configuration
-- Options: 'auto' | 'qbx' | 'qb' | 'esx' | 'standalone'
-- 'auto' will automatically detect installed core resource (qbx_core, qb-core, es_extended)
Config.Framework = 'auto'

-- Active locale for the resource and UI
-- Options: 'en' | 'bg' (extendable in locales/)
Config.Locale = 'en'

-- Default keybind to toggle the player list menu (registered via ox_lib lib.addKeybind)
-- Players can customize this key in FiveM Settings -> Key Bindings -> FiveM
Config.OpenKey = 'F6'

-- Player name display mode
-- 'character' = Character roleplay name (Firstname Lastname) if available in framework
-- 'account'   = FiveM / platform account name (GetPlayerName)
Config.DisplayNameMode = 'account'

-- Primary identifier type to display
-- Options: 'steam' | 'license' | 'discord' | 'fivem'
-- If chosen identifier is missing for a player, automatically falls back to next available type
Config.IdentifierType = 'discord'

-- Convert Steam Hex identifier (e.g. steam:110000105b630df) to decimal SteamID64 (e.g. 76561198055891167)
Config.ConvertSteamTo64 = true

-- Privacy: Who is permitted to view player identifiers (in UI & 3D head labels)
-- Options:
-- 'everyone' = All players see identifiers
-- 'admins'   = Only players with admin permissions see identifiers (standard players see server ID)
-- 'none'     = Identifiers are never sent to clients
Config.ShowIdentifiersTo = 'everyone'

-- ACE permission for admin verification (checked for standalone fallback or framework secondary check)
Config.AdminAcePermission = 'playerlist.admin'

-- 3D Head ID Settings (Active ONLY while menu is open)
-- Maximum distance in meters to render player tags above their heads
Config.HeadIdDistance = 15.0

-- Vertical height offset above the player's ped head for the 3D text
Config.HeadIdHeightOffset = 1.05

-- 3D Text font style (0 = standard, 4 = stylized condensed)
Config.HeadIdFont = 4

-- 3D Text scale factor
Config.HeadIdScale = 0.36

-- 3D Text color when player is NOT talking (RGBA)
Config.HeadIdNormalColor = { r = 255, g = 255, b = 255, a = 230 }

-- 3D Text color when player IS talking (Cyan / Neon Blue RGBA)
Config.HeadIdSpeakingColor = { r = 34, g = 211, b = 238, a = 255 }

-- Proximity radius in meters for the "PLAYERS IN AREA" header counter
Config.AreaRadius = 25.0

-- Voice detection mode: 'auto' | 'pma-voice' | 'native'
-- 'native' uses NetworkIsPlayerTalking / MumbleIsPlayerTalking
Config.VoiceResource = 'auto'

-- Disconnected Players History Settings
-- Maximum number of recently disconnected players retained in server memory
Config.MaxDisconnected = 20

-- Expiration time in minutes for disconnected records before being pruned
Config.DisconnectedMaxAge = 15

-- UI & Performance Settings
-- Refresh interval (in milliseconds) for ping syncing to players who have the menu open
Config.PingRefreshInterval = 5000

-- Whether to show ping (ms) badge on player rows
Config.ShowPing = true

-- Enable debug print logs in server/client console
Config.Debug = false

-- Player profile pictures (avatars) in the player list
Config.ShowAvatars = true

-- Where avatars come from:
-- 'cfx'     = Cfx.re / FiveM forum profile picture. NO token or setup needed (default-friendly).
--             Uses the public endpoint txAdmin uses (policy-live.fivem.net) - unofficial, may change.
-- 'discord' = Discord profile picture. Needs a Discord bot token (see below).
-- 'auto'    = Discord if a token is configured, otherwise Cfx.re
Config.AvatarSource = 'cfx'

-- (Only for 'discord' / 'auto') Do NOT put your token in this file if the repo is public!
-- Put it in your private server.cfg instead:
--   set mazilkata_discord_token "YOUR_BOT_TOKEN"
Config.DiscordBotToken = ''

-- Who can see avatars: 'everyone' | 'admins' | 'none'
-- NOTE: avatar links reveal the player's Cfx.re username / Discord ID, so use 'admins'
-- if you do not want regular players to be able to find that.
Config.ShowAvatarsTo = 'everyone'

-- How long (minutes) a fetched avatar is cached on the server
Config.AvatarCacheMinutes = 30

-- Show the search bar under the tabs (set to true if you want to search players by name / ID)
Config.ShowSearch = false
