local DrawText3D = {}
HeadIds = {}

-- Localized native references for maximum performance in loop
local SetTextScale = SetTextScale
local SetTextFont = SetTextFont
local SetTextProportional = SetTextProportional
local SetTextColour = SetTextColour
local SetTextDropshadow = SetTextDropshadow
local SetTextEdge = SetTextEdge
local SetTextDropShadow = SetTextDropShadow
local SetTextOutline = SetTextOutline
local SetTextCentre = SetTextCentre
local BeginTextCommandDisplayText = BeginTextCommandDisplayText
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local EndTextCommandDisplayText = EndTextCommandDisplayText
local World3dToScreen2d = World3dToScreen2d
local GetPedBoneCoords = GetPedBoneCoords

---Draw 3D text in world space above an entity
---@param coords vector3
---@param text string
---@param color table {r, g, b, a}
---@param scale number
---@param font number
function HeadIds.DrawText3D(coords, text, color, scale, font)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(scale, scale)
    SetTextFont(font or 4)
    SetTextProportional(true)
    SetTextColour(color.r, color.g, color.b, color.a)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)

    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(screenX, screenY)
end

---Determine if a player is currently speaking
---@param player number
---@return boolean
function HeadIds.IsPlayerTalking(player)
    if NetworkIsPlayerTalking(player) then
        return true
    end
    if MumbleIsPlayerTalking and MumbleIsPlayerTalking(player) then
        return true
    end
    return false
end
