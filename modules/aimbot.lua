-- linoriarage modules/aimbot.lua (optimized)
-- Uses Mouse.Button1Down instead of __namecall (Real Executor compatible).
-- Distance-limited aimbot via Utils.acquire.
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local Aimbot = {}
Aimbot.__index = Aimbot

local Utils = _G.LR_UTILS

function Aimbot.new()
    local self = setmetatable({}, Aimbot)
    self.currentTarget = nil
    self._conn = nil
    self.destroyed = false

    local function getSettings()
        return {
            enabled = (_G.Toggles and _G.Toggles.aim_enabled and _G.Toggles.aim_enabled.Value) or false,
            smoothing = (_G.Options and _G.Options.aim_smoothing and _G.Options.aim_smoothing.Value) or 35,
            fov = (_G.Options and _G.Options.aim_fov and _G.Options.aim_fov.Value) or 90,
            targetMode = (_G.Options and _G.Options.aim_target and _G.Options.aim_target.Value) or "head",
            grace = (_G.Options and _G.Options.aim_grace and _G.Options.aim_grace.Value) or 1,
            maxDist = 500,
            showfov = (_G.Toggles and _G.Toggles.aim_showfov and _G.Toggles.aim_showfov.Value) or false,
            visible = (_G.Toggles and _G.Toggles.aim_visible and _G.Toggles.aim_visible.Value) or false,
            sticky = (_G.Toggles and _G.Toggles.aim_sticky and _G.Toggles.aim_sticky.Value) or false,
        }
    end

    local function getTarget(s)
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        return Utils.acquire(s.maxDist, s.fov, screenCenter, s.targetMode)
    end

    local function aimAt(target, targetScr, s)
        local mouse = LocalPlayer:GetMouse()
        local dx = targetScr.X - mouse.X
        local dy = targetScr.Y - mouse.Y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < 2 then return end
        local speed = math.min(dist / s.smoothing, dist * 0.1)
        pcall(function()
            mouse.X = mouse.X + dx * speed
            mouse.Y = mouse.Y + dy * speed
        end)
    end

    local function onButton1Down(input, gameProcessed)
        if gameProcessed then return end
        local s = getSettings()
        if not s.enabled then return end
        if self.destroyed then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local target, targetScr = getTarget(s)
        if target then
            local dist = (target.Position - cam.CFrame.Position).Magnitude
            if dist > s.maxDist then return end
            aimAt(target, targetScr, s)
            self.currentTarget = target
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

local function construct()
    task.defer(function()
        if _G.Toggles and _G.Toggles.aim_enabled then
            _G.LR_AIMBOT = Aimbot.new()
        end
    end)
end

construct()
return Aimbot