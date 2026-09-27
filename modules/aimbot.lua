-- linoriarage modules/aimbot.lua
-- Uses Mouse.Button1Down instead of __namecall (Real Executor compatible).
-- On click, finds nearest enemy via Utils.acquire and moves mouse toward target.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local Aimbot = {}
Aimbot.__index = Aimbot

local Utils = _G.LR_UTILS
local function getTargetPart(character, mode)
    if not character then return nil end
    if mode == "root" then return character:FindFirstChild("HumanoidRootPart") end
    if mode == "body" then
        return character:FindFirstChild("HitboxBody")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("HumanoidRootPart")
    end
    return character:FindFirstChild("HitboxHead")
        or character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end

function Aimbot.new()
    local self = setmetatable({}, Aimbot)
    self.enabled = (_G.Toggles and _G.Toggles.aim_enabled and _G.Toggles.aim_enabled.Value) or false
    self.showfov = (_G.Toggles and _G.Toggles.aim_showfov and _G.Toggles.aim_showfov.Value) or false
    self.sticky = (_G.Toggles and _G.Toggles.aim_sticky and _G.Toggles.aim_sticky.Value) or false
    self.visible = (_G.Toggles and _G.Toggles.aim_visible and _G.Toggles.aim_visible.Value) or false
    self.smoothing = (_G.Options and _G.Options.aim_smoothing and _G.Options.aim_smoothing.Value) or 35
    self.fov = (_G.Options and _G.Options.aim_fov and _G.Options.aim_fov.Value) or 90
    self.targetMode = (_G.Options and _G.Options.aim_target and _G.Options.aim_target.Value) or "head"
    self.grace = (_G.Options and _G.Options.aim_grace and _G.Options.aim_grace.Value) or 1
    self.currentTarget = nil
    self.lastClick = 0
    self._conn = nil
    self.destroyed = false

    local function getTarget()
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local mouse = LocalPlayer:GetMouse()
        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)

        local best, bestScr = Utils.acquire(
            500, self.fov, screenCenter, self.targetMode
        )

        if best and bestScr then
            local dist = (best.Position - cam.CFrame.Position).Magnitude
            if dist > 500 then return nil end
            return best, bestScr
        end
        return nil, nil
    end

    local function aimAt(target, targetScr)
        local mouse = LocalPlayer:GetMouse()
        local currentX, currentY = mouse.X, mouse.Y
        local targetX, targetY = targetScr.X, targetScr.Y
        local dx = targetX - currentX
        local dy = targetY - currentY
        local dist = math.sqrt(dx * dx + dy * dy)

        if dist < 2 then return end

        local speed = math.min(dist / self.smoothing, dist * 0.1)
        local moveX = dx * speed
        local moveY = dy * speed

        pcall(function()
            mouse.X = currentX + moveX
            mouse.Y = currentY + moveY
        end)
    end

    local function onButton1Down(input, gameProcessed)
        if gameProcessed then return end
        if not (_G.Toggles and _G.Toggles.aim_enabled and _G.Toggles.aim_enabled.Value) then return end
        if self.destroyed then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local target, targetScr = getTarget()
        if target then
            aimAt(target, targetScr)
            self.currentTarget = target
            self.lastClick = tick()
        else
            self.currentTarget = nil
        end
    end

    self._conn = UIS.InputBegan:Connect(onButton1Down)
    return self
end

function Aimbot:Destroy()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
    self.destroyed = true
end

-- Auto-construct if Toggles already available
local function construct()
    if _G.Toggles and _G.Toggles.aim_enabled then
        _G.LR_AIMBOT = Aimbot.new()
    else
        task.defer(function()
            if _G.Toggles and _G.Toggles.aim_enabled then
                _G.LR_AIMBOT = Aimbot.new()
            end
        end)
    end
end

construct()

return Aimbot