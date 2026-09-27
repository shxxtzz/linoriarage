-- linoriarage modules/utils.lua (shared target-selection core)
-- Fixed: removed HitboxHands (not in RIVALS), uses Player.Team for ally check.
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Utils = {}

function Utils.getTargetPart(character, mode)
    if not character then return nil end
    if mode == "root" then
        return character:FindFirstChild("HumanoidRootPart")
    elseif mode == "body" then
        return character:FindFirstChild("HitboxBody")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("HumanoidRootPart")
    end
    -- default "head": HitboxHead first, then fallbacks
    return character:FindFirstChild("HitboxHead")
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end

-- Team check via Player.Team (not _is_ally BoolValue which doesn't exist in RIVALS)
function Utils.isAlly(character)
    local player = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character == character then
            player = p
            break
        end
    end
    if not player then return false end
    return player.Team ~= nil and player.Team ~= Enum.Team.Neutral
end

function Utils.isAlive(character)
    local hum = character and character:FindFirstChild("Humanoid")
    return hum ~= nil and hum.Health > 0
end

function Utils.acquire(maxDist, fovRadius, fovCenter, partMode)
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local origin = cam.CFrame.Position
    local best, bestD2, bestScr = nil, math.huge, nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local character = player.Character
        if not character then continue end
        if not Utils.isAlive(character) then continue end
        if Utils.isAlly(character) then continue end
        local part = Utils.getTargetPart(character, partMode)
        if not part then continue end
        if (part.Position - origin).Magnitude > maxDist then continue end
        local scr, onScreen = cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        local dx, dy = scr.X - fovCenter.X, scr.Y - fovCenter.Y
        local d2 = dx * dx + dy * dy
        if d2 > fovRadius * fovRadius or d2 >= bestD2 then continue end
        best, bestD2, bestScr = part, d2, scr
    end
    return best, bestScr
end

function Utils.boneVisible(part)
    local cam = workspace.CurrentCamera
    local localChar = LocalPlayer.Character
    if not cam or not part or not localChar then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { localChar }
    local origin = cam.CFrame.Position
    local dir = part.Position - origin
    local dist = dir.Magnitude
    if dist < 0.25 then return false end
    local result = workspace:Raycast(origin, dir, params)
    if not result then return true end
    local hitChar = result.Instance:FindFirstAncestorOfClass("Model")
    local targetChar = part:FindFirstAncestorOfClass("Model")
    return hitChar ~= nil and hitChar == targetChar
end

_G.LR_UTILS = Utils
return Utils