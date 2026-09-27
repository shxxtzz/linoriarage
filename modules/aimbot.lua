-- linoriarage modules/aimbot.lua (Real Executor compatible)
-- Uses UIS.InputBegan for key detection.
-- mouse1click(screenX, screenY) clicks at target's viewport position.
-- No AddKeyPicker — RightShift hardcoded as keybind.
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
        local t = _G.Toggles or {}
        local o = _G.Options or {}
        local keybindIdx = o.aim_keybind and o.aim_keybind.Value or 1
        local keybindVals = o.aim_keybind and o.aim_keybind.Values or { "LeftAlt" }
        local keybind = type(keybindIdx) == "number" and keybindVals[keybindIdx] or "LeftAlt"
        return {
            enabled = t.aim_enabled and t.aim_enabled.Value == true,
            fov = o.aim_fov and o.aim_fov.Value or 90,
            targetMode = o.aim_target and o.aim_target.Value or "head",
            maxDist = 500,
            smoothing = o.aim_smoothing and o.aim_smoothing.Value or 35,
            grace = o.aim_grace and o.aim_grace.Value or 1,
            keybind = keybind,
        }
    end

    local function findTarget(s)
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
        local target, _ = Utils.acquire(s.maxDist, s.fov, screenCenter, s.targetMode)
        return target
    end

    local function onInputBegan(input, gameProcessed)
        if gameProcessed then return end
        local s = getSettings()
        if not s.enabled or self.destroyed then return end

        local keyName = input.KeyCode and input.KeyCode.Name or ""
        if keyName ~= s.keybind then return end

        -- Cooldown
        if tick() - self.lastShot < (s.smoothing / 1000) then return end

        local target = findTarget(s)
        if not target then
            self.currentTarget = nil
            return
        end

        -- Get target screen position and click there
        local cam = workspace.CurrentCamera
        if not cam then return end
        local screenPos, onScreen = cam:WorldToViewportPoint(target.Position)
        if not onScreen then return end

        mouse1click(screenPos.X, screenPos.Y)
        self.lastShot = tick()
        self.currentTarget = target
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
    _G.LR_AIMBOT = nil
end

_G.LR_AIMBOT = Aimbot.new()
return Aimbot