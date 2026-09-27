-- linoriarage modules/aimbot.lua (Real Executor compatible)
-- Aim keybind fires mouse1click(0,0) at nearest enemy when key pressed.
-- Uses UIS.InputBegan for key detection. Not mouse movement (not supported on Real Executor).
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
    self.lastShot = 0

    local function getSettings()
        return {
            enabled = (_G.Toggles and _G.Toggles.aim_enabled and _G.Toggles.aim_enabled.Value) or false,
            fov = (_G.Options and _G.Options.aim_fov and _G.Options.aim_fov.Value) or 90,
            targetMode = (_G.Options and _G.Options.aim_target and _G.Options.aim_target.Value) or "head",
            maxDist = 500,
            smoothing = (_G.Options and _G.Options.aim_smoothing and _G.Options.aim_smoothing.Value) or 35,
            grace = (_G.Options and _G.Options.aim_grace and _G.Options.aim_grace.Value) or 1,
        }
    end

    local function findTarget(s)
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local target, _ = Utils.acquire(s.maxDist, s.fov, screenCenter, s.targetMode)
        if target then
            local dist = (target.Position - cam.CFrame.Position).Magnitude
            if dist > s.maxDist then return nil end
        end
        return target
    end

    local function onInputBegan(input, gameProcessed)
        if gameProcessed then return end
        local s = getSettings()
        if not s.enabled then return end
        if self.destroyed then return end

        -- Check if input matches aim keybind
        local keybind = (_G.Options and _G.Options.AimKeybind and _G.Options.AimKeybind.Value) or "RightShift"
        local keyName = input.KeyCode and input.KeyCode.Name or ""
        if keyName ~= keybind then return end

        -- Cooldown check
        if tick() - self.lastShot < (s.smoothing / 1000) then return end

        local target = findTarget(s)
        if target then
            pcall(function()
                mouse1click(0, 0)
            end)
            self.lastShot = tick()
            self.currentTarget = target
        else
            self.currentTarget = nil
        end
    end

    self._conn = UIS.InputBegan:Connect(onInputBegan)
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