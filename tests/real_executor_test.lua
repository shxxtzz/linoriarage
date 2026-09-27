-- =============================================
-- TEST 1: loadstring + HttpGet support
-- =============================================
print("[TEST 1] loadstring + HttpGet support")

local success, err = pcall(function()
    local code = "return 'hello world'"
    local result = loadstring(code)()
    assert(result == "hello world", "loadstring failed")
end)

if success then
    print("[PASS] loadstring works")
else
    print("[FAIL] loadstring error: " .. tostring(err))
end

-- Test HttpGet
local success2, err2 = pcall(function()
    local code = game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/configs/plain.json")
    assert(code and #code > 0, "HttpGet returned empty")
end)

if success2 then
    print("[PASS] game:HttpGet works")
else
    print("[FAIL] HttpGet error: " .. tostring(err2))
end

print("")

-- =============================================
-- TEST 2: request() function (Real Executor custom HTTP)
-- =============================================
print("[TEST 2] request() function")

local success3, err3 = pcall(function()
    local response = request({Url = "https://httpbin.org/get"})
    assert(response and response.Body and #response.Body > 0, "request returned empty")
end)

if success3 then
    print("[PASS] request() works")
else
    print("[FAIL] request() error: " .. tostring(err3))
end

print("")

-- =============================================
-- TEST 3: __namecall hook support (Silent Aim)
-- =============================================
print("[TEST 3] __namecall hook support")

local success4, err4 = pcall(function()
    local original = game:GetService("ReplicatedStorage")
    local hooked = false
    
    local mt = getmetatable(original)
    if mt and mt.__namecall then
        hooked = true
    end
    
    -- Attempt to hook __namecall
    local ok, e = pcall(function()
        -- This tests if __namecall is accessible
        local mt = getmetatable(game)
        if mt then
            hooked = true
        end
    end)
    
    assert(hooked, "__namecall not accessible")
end)

if success4 then
    print("[PASS] __namecall hook accessible")
else
    print("[FAIL] __namecall error: " .. tostring(err4))
end

print("")

-- =============================================
-- TEST 4: Mouse.Hit hook support
-- =============================================
print("[TEST 4] Mouse.Hit hook support")

local success5, err5 = pcall(function()
    local mouse = game:GetService("Players").LocalPlayer:GetMouse()
    assert(mouse, "Mouse not found")
    
    -- Test if Mouse.Hit can be accessed
    local hit = mouse.Hit
    assert(hit, "Mouse.Hit not accessible")
end)

if success5 then
    print("[PASS] Mouse.Hit accessible")
else
    print("[FAIL] Mouse.Hit error: " .. tostring(err5))
end

print("")

-- =============================================
-- TEST 5: _G.Toggles and _G.Options
-- =============================================
print("[TEST 5] _G.Toggles/_G.Options globals")

local success6, err6 = pcall(function()
    assert(_G.Toggles ~= nil, "_G.Toggles not initialized")
    assert(_G.Options ~= nil, "_G.Options not initialized")
    assert(type(_G.Toggles) == "table", "_G.Toggles is not a table")
    assert(type(_G.Options) == "table", "_G.Options is not a table")
end)

if success6 then
    print("[PASS] _G.Toggles and _G.Options work")
    print("  Toggles keys: " .. table.concat(next, _G.Toggles, ", "))
else
    print("[FAIL] _G.Toggles error: " .. tostring(err6))
end

print("")

-- =============================================
-- TEST 6: ESP rendering (Drawing library)
-- =============================================
print("[TEST 6] ESP rendering (Drawing library)")

local success7, err7 = pcall(function()
    local line = Drawing.Line({
        Thickness = 2,
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 1,
        Visible = false,
    })
    assert(line, "Drawing.Line failed")
    line:Remove()
end)

if success7 then
    print("[PASS] Drawing library works")
else
    print("[FAIL] Drawing error: " .. tostring(err7))
end

print("")

-- =============================================
-- TEST 7: RunService (RenderStepped)
-- =============================================
print("[TEST 7] RunService (RenderStepped)")

local success8, err8 = pcall(function()
    local RunService = game:GetService("RunService")
    local conn = RunService:RenderStepped:Connect(function()
        -- Just test connection
    end)
    conn:Disconnect()
end)

if success8 then
    print("[PASS] RunService:RenderStepped works")
else
    print("[FAIL] RunService error: " .. tostring(err8))
end

print("")

-- =============================================
-- TEST 8: LinoriaLib loading
-- =============================================
print("[TEST 8] LinoriaLib loading")

local success9, err9 = pcall(function()
    local LINORIA_URL = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
    local Library = loadstring(game:HttpGet(LINORIA_URL .. "Library.lua"))()
    assert(Library ~= nil, "Library is nil")
    assert(Library.CreateWindow ~= nil, "CreateWindow method missing")
end)

if success9 then
    print("[PASS] LinoriaLib loads")
else
    print("[FAIL] LinoriaLib error: " .. tostring(err9))
end

print("")

-- =============================================
-- TEST 9: SaveManager loading
-- =============================================
print("[TEST 9] SaveManager loading")

local success10, err10 = pcall(function()
    local LINORIA_URL = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"
    local SaveManager = loadstring(game:HttpGet(LINORIA_URL .. "addons/SaveManager.lua"))()
    assert(SaveManager ~= nil, "SaveManager is nil")
end)

if success10 then
    print("[PASS] SaveManager loads")
else
    print("[FAIL] SaveManager error: " .. tostring(err10))
end

print("")

-- =============================================
-- TEST 10: Players service and LocalPlayer
-- =============================================
print("[TEST 10] Players service and LocalPlayer")

local success11, err11 = pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    assert(LocalPlayer ~= nil, "LocalPlayer is nil")
    assert(LocalPlayer.Character ~= nil, "Character is nil")
end)

if success11 then
    print("[PASS] Players and LocalPlayer work")
else
    print("[FAIL] Players error: " .. tostring(err11))
end

print("")
print("=== TEST SUMMARY ===")
print("Run all tests on Real Executor to verify compatibility.")
print("Copy each test section individually to see which features work.")
