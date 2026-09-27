-- linoriarage main.lua (scaffold v1: menu shell, ZERO cheat logic)
-- Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/main.lua"))()
repeat task.wait() until game:IsLoaded()

local LINORIA_URL = "https://raw.githubusercontent.com/mstudio45/LinoriaLib/main/"

local Library = loadstring(game:HttpGet(LINORIA_URL .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(LINORIA_URL .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(LINORIA_URL .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "linoriarage",
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Visuals = Window:AddTab("Visuals"),
    Misc = Window:AddTab("Misc"),
    Spoofer = Window:AddTab("Spoofer"),
    Settings = Window:AddTab("Settings"),
}

-- Global option containers, wired so modules can read Values.
-- Spec §1: "Option convention: Linoria Toggles.* / Options.* globals"
_G.Toggles = {}
_G.Options = {}

-- Main / Aimbot group (controls only; logic lands in modules/aimbot.lua)
local AimG = Tabs.Main:AddLeftGroupbox("Aimbot")
_G.Toggles.aim_enabled    = AimG:AddToggle("aim_enabled",    { Text = "Enable", Default = false })
_G.Toggles.aim_showfov    = AimG:AddToggle("aim_showfov",    { Text = "FOV Circle", Default = false })
_G.Toggles.aim_sticky     = AimG:AddToggle("aim_sticky",     { Text = "Sticky target", Default = false })
_G.Toggles.aim_visible    = AimG:AddToggle("aim_visible",    { Text = "Visible Only", Default = false })
_G.Options.aim_smoothing  = AimG:AddSlider("aim_smoothing",  { Text = "Smoothing", Default = 35, Min = 1, Max = 100, Rounding = 0 })
_G.Options.aim_fov        = AimG:AddSlider("aim_fov",        { Text = "FOV", Default = 90, Min = 10, Max = 300, Rounding = 0 })
_G.Options.aim_target     = AimG:AddDropdown("aim_target",   { Values = { "head", "body", "root", "lower", "r.arm", "l.arm", "r.leg", "l.leg" }, Default = 1, Multi = false, Text = "Target" })
_G.Options.aim_grace      = AimG:AddSlider("aim_grace",      { Text = "Sticky grace (cm)", Default = 1, Min = 0, Max = 10, Rounding = 1 })
_G.Options.AimKeybind = AimG:AddKeyPicker("AimKeybind", { Default = "RightShift", Text = "Aim Keybind" })

-- Main / Silent Aim group
local SilG = Tabs.Main:AddRightGroupbox("Silent Aim")
_G.Toggles.silent_enabled    = SilG:AddToggle("silent_enabled",    { Text = "Enable", Default = false })
_G.Options.silent_fov        = SilG:AddSlider("silent_fov",        { Text = "FOV", Default = 90, Min = 10, Max = 300, Rounding = 0 })
_G.Options.silent_hitchance  = SilG:AddSlider("silent_hitchance",  { Text = "Hit Chance%", Default = 100, Min = 0, Max = 100, Rounding = 0 })

-- Main / Triggerbot group
local TrgG = Tabs.Main:AddRightGroupbox("Triggerbot")
_G.Toggles.trig_enabled   = TrgG:AddToggle("trig_enabled",   { Text = "Enable", Default = false })
_G.Options.trig_reaction  = TrgG:AddSlider("trig_reaction",  { Text = "Reaction (ms)", Default = 100, Min = 0, Max = 500, Rounding = 0 })
_G.Options.trig_delay     = TrgG:AddSlider("trig_delay",     { Text = "Delay (ms)", Default = 0, Min = 0, Max = 300, Rounding = 0 })
_G.Toggles.trig_scope     = TrgG:AddToggle("trig_scope",     { Text = "Scope Check", Default = false })

-- Visuals / ESP group
local EspG = Tabs.Visuals:AddLeftGroupbox("Player ESP")
_G.Toggles.esp_enabled      = EspG:AddToggle("esp_enabled",      { Text = "Enable", Default = false })
_G.Toggles.esp_box          = EspG:AddToggle("esp_box",          { Text = "Corners", Default = false })
_G.Toggles.esp_healthbar    = EspG:AddToggle("esp_healthbar",    { Text = "Health Bar", Default = false })
_G.Toggles.esp_name         = EspG:AddToggle("esp_name",         { Text = "Name", Default = false })
_G.Toggles.esp_distance     = EspG:AddToggle("esp_distance",     { Text = "Distance", Default = false })
_G.Toggles.esp_number       = EspG:AddToggle("esp_number",       { Text = "Number", Default = false })
_G.Toggles.esp_skeleton     = EspG:AddToggle("esp_skeleton",     { Text = "Skeleton", Default = false })

-- Misc / Staff Detector group
local StfG = Tabs.Misc:AddLeftGroupbox("Staff Detector")
_G.Toggles.staff_enabled    = StfG:AddToggle("staff_enabled",    { Text = "Enable", Default = false })
_G.Toggles.staff_autoleave  = StfG:AddToggle("staff_autoleave",  { Text = "Auto-leave on detect", Default = false })

-- Spoofer / Visuals-only group
local SpfG = Tabs.Spoofer:AddLeftGroupbox("Visuals Only")
_G.Toggles.spoof_nametag  = SpfG:AddToggle("spoof_nametag",  { Text = "Custom nametag", Default = false })
_G.Toggles.spoof_streak   = SpfG:AddToggle("spoof_streak",   { Text = "Win-streak display", Default = false })

-- Rage / DEAD checkboxes (visible, inert — scoped OFF per spec)
local RageG = Tabs.Main:AddLeftGroupbox("Rage (disabled)")
_G.Toggles.rage_nospread  = RageG:AddToggle("rage_nospread",  { Text = "No Spread", Default = false })
_G.Toggles.rage_rapidfire = RageG:AddToggle("rage_rapidfire", { Text = "Rapid Fire", Default = false })
_G.Toggles.rage_norecoil  = RageG:AddToggle("rage_norecoil",  { Text = "No Recoil", Default = false })

-- Settings / menu + configs
local MenuG = Tabs.Settings:AddLeftGroupbox("Menu")
_G.Options.MenuKeybind = MenuG:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuG:AddButton("Unload", function()
    if _G.LR_ESP then pcall(function() _G.LR_ESP:Destroy() end) end
    if _G.LR_AIMBOT then pcall(function() _G.LR_AIMBOT:Destroy() end) end
    if _G.LR_TRIGGERBOT then pcall(function() _G.LR_TRIGGERBOT:Destroy() end) end
    Library:Unload()
end)


ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
ThemeManager:SetFolder("linoriarage")
SaveManager:SetFolder("linoriarage/saves")
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- Modules (Real Executor compatible: Drawing→BillboardGui, __namecall→Mouse.Button1Down)
local Utils = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/utils.lua"))()
local ESP   = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/esp.lua"))()
local Aimbot   = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/aimbot.lua"))()
local Triggerbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/shxxtzz/linoriarage/main/modules/triggerbot.lua"))()
-- Silent aim removed: __namecall hooks not supported on Real Executor
-- Staff detector and spoofer modules pending
