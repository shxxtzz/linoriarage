-- linoriarage modules/triggerbot.lua
-- Uses mouse1click() to fire shots instead of clientItem:Input(nil).
-- On click, checks if enemy is in crosshair, then fires after delay.
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Triggerbot = {}
Triggerbot.__index = Triggerbot

local Utils = _G.LR_UTILS

function Triggerbot.new()
    local self = setmetatable({}, Triggerbot)
    self.enabled = false
    self.reaction = 100
    self.delay = 0
    self.scopeCheck = false
    self.destroyed = false
    self._conn = nil
    self._cooldown = 0

    local function onButton1Down(input, gameProcessed)
        if gameProcessed then return end
        if not (_G.Toggles and _G.Toggles.trig_enabled and _G.Toggles.trig_enabled.Value) then return end
        if self.destroyed then return end
        if tick() - self._cooldown < self.delay / 1000 then return end

        local cam = workspace.CurrentCamera
        if not cam then return end

        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)

        local target, targetScr = Utils.acquire(
            500, 50, screenCenter, "head"
        )

        if target then
            local reactionMs = (_G.Options and _G.Options.trig_reaction and _G.Options.trig_reaction.Value) or 100
            local delayMs = (_G.Options and _G.Options.trig_delay and _G.Options.trig_delay.Value) or 0

            task.wait(reactionMs / 1000)
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
    if _G.Toggles and _G.Toggles.trig_enabled then
        _G.LR_TRIGGERBOT = Triggerbot.new()
    else
        task.defer(function()
            if _G.Toggles and _G.Toggles.trig_enabled then
                _G.LR_TRIGGERBOT = Triggerbot.new()
            end
        end)
    end
end

construct()

return Triggerbot