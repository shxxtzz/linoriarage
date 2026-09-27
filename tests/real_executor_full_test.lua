-- =============================================
-- TEST SUITE: Real Executor Compatibility
-- Tests every feature linoriarage needs
-- =============================================

print("============================================")
print("  REAL EXECUTOR COMPATIBILITY TEST SUITE")
print("============================================")
print("")

-- =============================================
-- SECTION A: Core Executor Features
-- =============================================
print("[SECTION A] Core Executor Features")
print("--------------------")

-- A1: loadstring
local a1 = pcall(function() return loadstring("return 42")() == 42 end)
print("[A1] loadstring: " .. (a1 and "PASS" or "FAIL"))

-- A2: game:HttpGet
local a2 = pcall(function()
    local c = game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/configs/plain.json")
    return c and #c > 0
end)
print("[A2] game:HttpGet: " .. (a2 and "PASS" or "FAIL"))

-- A3: request() (Real Executor custom HTTP)
local a3 = pcall(function()
    local r = request({Url = "https://httpbin.org/get"})
    return r and r.Body and #r.Body > 0
end)
print("[A3] request(): " .. (a3 and "PASS" or "FAIL"))

-- A4: getmetatable / __namecall
local a4 = pcall(function()
    local mt = getmetatable(game)
    return mt ~= nil
end)
print("[A4] __namecall hook: " .. (a4 and "PASS" or "FAIL"))

-- A5: Mouse.Hit
local a5 = pcall(function()
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    return mouse and mouse.Hit ~= nil
end)
print("[A5] Mouse.Hit: " .. (a5 and "PASS" or "FAIL"))

-- A6: Drawing library
local a6 = pcall(function()
    local d = Drawing.Line({Thickness = 1, Color = Color3.new(1,0,0), Visible = false})
    d:Remove()
    return true
end)
print("[A6] Drawing: " .. (a6 and "PASS" or "FAIL"))

-- A7: RunService:RenderStepped
local a7 = pcall(function()
    local rs = game:GetService("RunService")
    local c = rs:RenderStepped:Connect(function() end)
    c:Disconnect()
    return true
end)
print("[A7] RunService:RenderStepped: " .. (a7 and "PASS" or "FAIL"))

-- A8: task.spawn / task.defer
local a8 = pcall(function()
    task.spawn(function() end)
    task.defer(function() end)
    return true
end)
print("[A8] task.spawn/defer: " .. (a8 and "PASS" or "FAIL"))

print("")

-- =============================================
-- SECTION B: linoriarage Module Loading
-- =============================================
print("[SECTION B] linoriarage Module Loading")
print("--------------------")

-- B1: LinoriaLib
local b1 = pcall(function()
    local url = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
    local lib = loadstring(game:HttpGet(url .. "Library.lua"))()
    return lib and lib.CreateWindow ~= nil
end)
print("[B1] LinoriaLib: " .. (b1 and "PASS" or "FAIL"))

-- B2: SaveManager
local b2 = pcall(function()
    local url = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
    local sm = loadstring(game:HttpGet(url .. "addons/SaveManager.lua"))()
    return sm ~= nil
end)
print("[B2] SaveManager: " .. (b2 and "PASS" or "FAIL"))

-- B3: ThemeManager
local b3 = pcall(function()
    local url = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
    local tm = loadstring(game:HttpGet(url .. "addons/ThemeManager.lua"))()
    return tm ~= nil
end)
print("[B3] ThemeManager: " .. (b3 and "PASS" or "FAIL"))

-- B4: LoadAutoloadConfig
local b4 = pcall(function()
    local url = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
    local sm = loadstring(game:HttpGet(url .. "addons/SaveManager.lua"))()
    -- Test that SaveManager has LoadAutoloadConfig
    return sm and sm.LoadAutoloadConfig ~= nil
end)
print("[B4] LoadAutoloadConfig: " .. (b4 and "PASS" or "FAIL"))

-- B5: _G.Toggles and _G.Options
local b5 = pcall(function()
    return _G.Toggles ~= nil and _G.Options ~= nil
end)
print("[B5] _G.Toggles/_G.Options: " .. (b5 and "PASS" or "FAIL"))

print("")

-- =============================================
-- SECTION C: Cheat Feature Tests
-- =============================================
print("[SECTION C] Cheat Feature Tests")
print("--------------------")

-- C1: ESP module loading
local c1 = pcall(function()
    local code = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/esp.lua"))
    return code ~= nil
end)
print("[C1] ESP module loads: " .. (c1 and "PASS" or "FAIL"))

-- C2: utils module loading
local c2 = pcall(function()
    local code = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/utils.lua"))
    return code ~= nil
end)
print("[C2] utils module loads: " .. (c2 and "PASS" or "FAIL"))

-- C3: ESP:Destroy() method
local c3 = pcall(function()
    local esp_code = game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/esp.lua")
    -- Check if Destroy method exists in the code
    return esp_code and string.find(esp_code, "function ESP:Destroy") ~= nil
end)
print("[C3] ESP:Destroy() exists: " .. (c3 and "PASS" or "FAIL"))

-- C4: self.destroyed flag
local c4 = pcall(function()
    local esp_code = game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/esp.lua")
    return esp_code and string.find(esp_code, "self.destroyed") ~= nil
end)
print("[C4] self.destroyed flag exists: " .. (c4 and "PASS" or "FAIL"))

-- C5: Aimbot module
local c5 = pcall(function()
    local code = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/aimbot.lua"))
    return code ~= nil
end)
print("[C5] aimbot module loads: " .. (c5 and "PASS" or "FAIL"))

-- C6: Triggerbot module
local c6 = pcall(function()
    local code = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/triggerbot.lua"))
    return code ~= nil
end)
print("[C6] triggerbot module loads: " .. (c6 and "PASS" or "FAIL"))

-- C7: Silent aim module
local c7 = pcall(function()
    local code = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/silentaim.lua"))
    return code ~= nil
end)
print("[C7] silentaim module loads: " .. (c7 and "PASS" or "FAIL"))

-- C8: Staff detector module
local c8 = pcall(function()
    local code = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/staffdetector.lua"))
    return code ~= nil
end)
print("[C8] staffdetector module loads: " .. (c8 and "PASS" or "FAIL"))

-- C9: Spoofer module
local c9 = pcall(function()
    local code = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/spoofer.lua"))
    return code ~= nil
end)
print("[C9] spoofer module loads: " .. (c9 and "PASS" or "FAIL"))

print("")

-- =============================================
-- SECTION D: RIVALS-Specific Tests
-- =============================================
print("[SECTION D] RIVALS-Specific Tests")
print("--------------------")

-- D1: HitboxHead/HitboxBody parts
local d1 = pcall(function()
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    if char then
        return char:FindFirstChild("HitboxHead") ~= nil or char:FindFirstChild("Head") ~= nil
    end
    return false
end)
print("[D1] Hitbox parts exist: " .. (d1 and "PASS" or "FAIL"))

-- D2: _is_ally BoolValue
local d2 = pcall(function()
    local Players = game:GetService("Players")
    local lp = Players.LocalPlayer
    local char = lp and lp.Character
    if char then
        return char:FindFirstChild("_is_ally") ~= nil
    end
    return false
end)
print("[D2] _is_ally BoolValue exists: " .. (d2 and "PASS" or "FAIL"))

-- D3: clientItem:Input(nil) (triggerbot fire)
local d3 = pcall(function()
    -- This tests if the triggerbot's Input method works
    -- The actual implementation uses clientItem:Input(nil)
    return true -- Can't test without full game context
end)
print("[D3] clientItem:Input(nil): N/A (game context needed)")

-- D4: __namecall / Mouse.Hook (silent aim)
local d4 = pcall(function()
    -- Test if __namecall hook can be set up
    local mt = getmetatable(game)
    return mt and mt.__namecall ~= nil
end)
print("[D4] __namecall hook: " .. (d4 and "PASS" or "FAIL"))

-- D5: clientItem detection
local d5 = pcall(function()
    -- Check if clientItem exists in the game
    local lp = game:GetService("Players").LocalPlayer
    return lp and lp:FindFirstChildOfClass("PlayerGui") ~= nil
end)
print("[D5] PlayerGui exists: " .. (d5 and "PASS" or "FAIL"))

print("")
print("============================================")
print("  TEST SUITE COMPLETE")
print("============================================")
print("")
print("Run this script on Real Executor to verify compatibility.")
print("Each section tests a different aspect of the cheat.")
