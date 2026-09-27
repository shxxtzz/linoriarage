-- linoriarage modules/triggerbot (optimized)
-- Uses mouse1click() to fire shots. Distance-limited.
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

local Triggerbot = {}
Triggerbot.__index = Triggerbot

local Utils = _G.LR_UTILS

function Triggerbot.new()
    local self = setmetatable({}, Triggerbot)
    self.currentTarget = nil
    self._conn = nil
    self._cooldown = 0
    self.destroyed = false

    local function getSettings()
        return {
            enabled = (_G.Toggles and _G.Toggles.trig_enabled and _G.Toggles.trig_enabled.Value) or false,
            reaction = (_G.Options and _G.Options.trig_reaction and _G.Options.trig_reaction.Value) or 100,
            delay = (_G.Options and _G.Options.trig_delay and _G.Options.trig_delay.Value) or 0,
            maxDist = 500,
        }
    end

    local function onButton1Down(input, gameProcessed)
        if gameProcessed then return end
        local s = getSettings()
        if not s.enabled then return end
        if self.destroyed then return end
        if tick() - self._cooldown < s.delay / 1000 then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local target, _ = Utils.acquire(s.maxDist, 50, screenCenter, "head")

        if target then
            local dist = (target.Position - cam.CFrame.Position).Magnitude
            if dist > s.maxDist then return end
            task.wait(s.reaction / 1000)
            pcall(function()
                mouse1click(0, 0)
            end)
            self._cooldown = tick()
        end
    end

    self._conn = UIS.InputBegan:Connect(onButton1Down)
    return self
end

function Triggerbot:Destroy()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
    self.destroyed = true
end

local function construct()
    task.defer(function()
        if _G.Toggles and _G.Toggles.trig_enabled then
            _G.LR_TRIGGERBOT = Triggerbot.new()
        end
    end)
end

construct()
return Triggerbot