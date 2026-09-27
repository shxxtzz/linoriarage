-- linoriarage modules/triggerbot.lua (Real Executor compatible)
-- Uses mouse1click(screenX, screenY) at target position when looking at enemy.
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local Triggerbot = {}
Triggerbot.__index = Triggerbot

local Utils = _G.LR_UTILS

function Triggerbot.new()
    local self = setmetatable({}, Triggerbot)
    self._conn = nil
    self.destroyed = false
    self.lastShot = 0

    local function getSettings()
        local t = _G.Toggles or {}
        local o = _G.Options or {}
        return {
            enabled = t.trig_enabled and t.trig_enabled.Value == true,
            reaction = o.trig_reaction and o.trig_reaction.Value or 100,
            delay = o.trig_delay and o.trig_delay.Value or 0,
        }
    end

    local function getTarget()
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local target, _ = Utils.acquire(500, 10, screenCenter, "head")
        return target
    end

    local function onInputBegan(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local s = getSettings()
        if not s.enabled or self.destroyed then return end
        if tick() - self.lastShot < (s.reaction / 1000) then return end

        local target = getTarget()
        if not target then return end

        local cam = workspace.CurrentCamera
        local screenPos, onScreen = cam:WorldToViewportPoint(target.Position)
        if not onScreen then return end

        mouse1click(screenPos.X, screenPos.Y)
        self.lastShot = tick()
    end

    self._conn = UIS.InputBegan:Connect(onInputBegan)
    return self
end

function Triggerbot:Destroy()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
    self.destroyed = true
    _G.LR_TRIGGERBOT = nil
end

_G.LR_TRIGGERBOT = Triggerbot.new()
return Triggerbot