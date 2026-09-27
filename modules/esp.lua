-- linoriarage modules/esp.lua (ScreenGui renderer; single-sample projections)
-- Real Executor compatible: no Drawing library, no __namecall.
-- One ScreenGui in PlayerGui; per-player Frames/TextLabels in screen pixels.
-- Anchors (head/feet) and skeleton project from the same per-frame snapshot,
-- so plates and skeletons cannot disagree (no smear on sprinters).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local _TG = _G.Toggles
local T = (_TG ~= nil and _TG) or ((Toggles ~= nil and Toggles) or {})
local _OP = _G.Options
local O = (_OP ~= nil and _OP) or ((Options ~= nil and Options) or {})

local function toggle(name, default)
    local v = T[name]
    if v ~= nil and v.Value ~= nil then return v.Value end
    return default
end

local function option(name)
    return O[name]
end

local ESP = {}
ESP.__index = ESP

local SKEL = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" }, { "UpperTorso", "RightUpperArm" },
    { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" }, { "LowerTorso", "RightUpperLeg" },
    { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}

local SKEL_PARTS = {
    "Head", "HitboxHead",
    "UpperTorso", "HitboxBody", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "HumanoidRootPart",
}

local SKEL_COLOR = Color3.fromRGB(255, 0, 0)
local SKEL_THICK = 2

local function mk(className, props, parent)
    local o = Instance.new(className)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

function ESP.new()
    local self = setmetatable({}, ESP)
    self.states = {}
    self.num = 0
    self.destroyed = false

    local gui = Instance.new("ScreenGui")
    gui.Name = "linoriarage_esp"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    self.gui = gui

    local function newState(player)
        self.num = self.num + 1
        local st = { player = player, idx = self.num, lines = {} }
        st.box = mk("Frame", {
            BackgroundTransparency = 1, BorderSizePixel = 1,
            BorderColor3 = Color3.fromRGB(255, 255, 255), Visible = false,
        }, gui)
        st.barBg = mk("Frame", {
            BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
            Visible = false,
        }, gui)
        st.bar = mk("Frame", {
            BackgroundColor3 = Color3.fromRGB(0, 255, 0), BorderSizePixel = 0,
            Visible = false,
        }, gui)
        local function lbl(sz)
            return mk("TextLabel", {
                BackgroundTransparency = 1, Font = Enum.Font.GothamBold,
                TextSize = sz, TextColor3 = Color3.fromRGB(255, 255, 255),
                TextStrokeTransparency = 0, Visible = false,
            }, gui)
        end
        st.name = lbl(13)
        st.dist = lbl(12)
        st.num = lbl(13)
        for _ = 1, #SKEL do
            table.insert(st.lines, mk("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = SKEL_COLOR, BorderSizePixel = 0,
                Visible = false,
            }, gui))
        end
        return st
    end

    local function hide(st)
        for _, o in ipairs({ st.box, st.barBg, st.bar, st.name, st.dist, st.num }) do
            if o then o.Visible = false end
        end
        for _, ln in ipairs(st.lines) do ln.Visible = false end
    end

    local function setLine(ln, ax, ay, bx, by)
        local dx, dy = bx - ax, by - ay
        local len = math.sqrt(dx * dx + dy * dy)
        if len < 1 then ln.Visible = false; return end
        ln.Position = UDim2.fromOffset((ax + bx) / 2, (ay + by) / 2)
        ln.Size = UDim2.fromOffset(len, SKEL_THICK)
        ln.Rotation = math.deg(math.atan2(dy, dx))
        ln.Visible = true
    end

    local function healthPos(hPos)
        local opt = option("healthbar_pos")
        if opt and type(opt.Value) == "number" then
            local vals = (type(opt.Values) == "table" and #opt.Values > 0)
                and opt.Values or { "top", "bottom", "left", "right" }
            return vals[opt.Value] or hPos
        end
        return hPos
    end

    local function tick()
        if self.destroyed then return end
        if not toggle("esp_enabled", false) then
            for _, st in pairs(self.states) do hide(st) end
            return
        end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local camPos, camLook = cam.CFrame.Position, cam.CFrame.LookVector
        local vp = cam.ViewportSize

        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local st = self.states[player]
            if not st then st = newState(player); self.states[player] = st end
            local character = player.Character
            local hum = character and character:FindFirstChild("Humanoid")
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            -- ally = confirmed same team as local player (fail-open: no team
            -- info on either side means show, so FFA/un-teamed modes work).
            local ally = player.Team ~= nil and LocalPlayer.Team ~= nil
                and player.Team == LocalPlayer.Team
            if not character or not hum or hum.Health <= 0 or not hrp or ally then
                hide(st); continue
            end

            -- single sample: snapshot part positions ONCE per frame
            local pos = {}
            for _, pn in ipairs(SKEL_PARTS) do
                local part = character:FindFirstChild(pn)
                if part then pos[pn] = part.Position end
            end
            local head = character:FindFirstChild("HitboxHead")
                or character:FindFirstChild("Head")
            local headP = head and head.Position or (pos.Head or hrp.Position)
            local feetP = hrp.Position - Vector3.new(0, 3, 0)

            local headScr, headOn = cam:WorldToViewportPoint(headP)
            local feetScr, feetOn = cam:WorldToViewportPoint(feetP)
            local dir = headP - camPos
            local dist = dir.Magnitude
            if not headOn or not feetOn or dist < 0.001
                or camLook:Dot(dir / dist) <= 0 then
                hide(st); continue
            end

            local h = math.max(10, math.abs(feetScr.Y - headScr.Y))
            local w = h * 0.55
            local x, y = feetScr.X - w / 2, headScr.Y

            -- whole plate far off-screen: skip
            if x > vp.X + 100 or x + w < -100 or y > vp.Y + 100 or y + h < -100 then
                hide(st); continue
            end

            -- box
            if toggle("esp_box", false) then
                st.box.Position = UDim2.fromOffset(x, y)
                st.box.Size = UDim2.fromOffset(w, h)
                st.box.Visible = true
            else
                st.box.Visible = false
            end

            -- health bar (bottom-up fill)
            if toggle("esp_healthbar", false) then
                local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                local hPos = healthPos("left")
                local bx, by, bw, bh = x - 8, y, 4, h
                local fx, fy, fw, fh = bx, by + h * (1 - frac), 4, h * frac
                if hPos == "right" then
                    bx, fx = x + w + 4, x + w + 4
                elseif hPos == "top" then
                    bx, by, bw, bh = x, y - 8, w, 4
                    fx, fy, fw, fh = x, y - 8, w * frac, 4
                elseif hPos == "bottom" then
                    bx, by, bw, bh = x, y + h + 4, w, 4
                    fx, fy, fw, fh = x, y + h + 4, w * frac, 4
                end
                st.barBg.Position = UDim2.fromOffset(bx, by)
                st.barBg.Size = UDim2.fromOffset(bw, bh)
                st.barBg.Visible = true
                st.bar.Position = UDim2.fromOffset(fx, fy)
                st.bar.Size = UDim2.fromOffset(fw, fh)
                st.bar.BackgroundColor3 = Color3.fromRGB(
                    255 - math.floor(255 * frac), math.floor(255 * frac), 0)
                st.bar.Visible = true
            else
                st.barBg.Visible = false
                st.bar.Visible = false
            end

            -- name
            if toggle("esp_name", false) then
                st.name.Text = player.Name
                st.name.Size = UDim2.fromOffset(200, 14)
                st.name.Position = UDim2.fromOffset(feetScr.X - 100, y - 16)
                st.name.Visible = true
            else
                st.name.Visible = false
            end

            -- distance (studs, same unit as external)
            if toggle("esp_distance", false) then
                st.dist.Text = math.floor(dist) .. "st"
                st.dist.Size = UDim2.fromOffset(200, 12)
                st.dist.Position = UDim2.fromOffset(feetScr.X - 100, y + h + 2)
                st.dist.Visible = true
            else
                st.dist.Visible = false
            end

            -- number
            if toggle("esp_number", false) then
                st.num.Text = tostring(st.idx)
                st.num.Size = UDim2.fromOffset(40, 14)
                st.num.Position = UDim2.fromOffset(x + w + 4, y)
                st.num.Visible = true
            else
                st.num.Visible = false
            end

            -- skeleton from the SAME sample (zero skew by construction)
            local showSkel = toggle("esp_skeleton", false)
            for i, pair in ipairs(SKEL) do
                local ln = st.lines[i]
                local a, b = pos[pair[1]], pos[pair[2]]
                if showSkel and a and b then
                    local aScr, oa = cam:WorldToViewportPoint(a)
                    local bScr, ob = cam:WorldToViewportPoint(b)
                    if oa and ob then
                        setLine(ln, aScr.X, aScr.Y, bScr.X, bScr.Y)
                    else
                        ln.Visible = false
                    end
                else
                    ln.Visible = false
                end
            end
        end

        -- drop players who left (destroy their objects)
        local activeSet = {}
        for _, p in ipairs(Players:GetPlayers()) do activeSet[p] = true end
        for player, st in pairs(self.states) do
            if not activeSet[player] then
                for _, ln in ipairs(st.lines) do
                    pcall(function() ln:Destroy() end)
                end
                for _, o in ipairs({ st.box, st.barBg, st.bar, st.name, st.dist, st.num }) do
                    pcall(function() o:Destroy() end)
                end
                self.states[player] = nil
            end
        end
    end

    self._conn = RunService.RenderStepped:Connect(tick)
    return self
end

function ESP:Destroy()
    if self._conn then
        self._conn:Disconnect()
        self._conn = nil
    end
    if self.gui then
        pcall(function() self.gui:Destroy() end)
        self.gui = nil
    end
    self.states = {}
    self.destroyed = true
    _G.LR_ESP = nil
end

_G.LR_ESP = ESP.new()
return ESP
