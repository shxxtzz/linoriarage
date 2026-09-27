-- linoriarage modules/esp.lua (BillboardGui renderer for Real Executor)
-- Replaces Drawing library with BillboardGui + Frame/TextLabel children.
-- Keeps: per-player state, RenderStepped loop, box/healthbar/name/distance/number,
-- dynamic bounds, ally skip, dead hide, skeleton via frames.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ESP = {}
ESP.__index = ESP

-- RIVALS uses Hitbox* parts. Standard R15 parts may not exist.
local SKEL = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" },
    { "LeftLowerArm", "LeftHand" }, { "UpperTorso", "RightUpperArm" },
    { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" },
    { "LeftLowerLeg", "LeftFoot" }, { "LowerTorso", "RightUpperLeg" },
    { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
    { "HitboxHead", "HitboxBody" },
    { "HitboxBody", "HumanoidRootPart" },
}

local SKEL_PARTS = {
    "Head", "HitboxHead",
    "UpperTorso", "HitboxBody", "LowerTorso",
    "LeftUpperArm", "LeftHand",
    "RightUpperArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "HumanoidRootPart",
}

local function makeBillboard(parent)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(2, 0, 1, 0)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.Parent = parent
    return bb
end

local function makeBox(bb)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Parent = bb
    return frame
end

local function makeTextLabel(bb, text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 14)
    lbl.BackgroundTransparency = 1
    lbl.Text = text or ""
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextScaled = true
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = bb
    return lbl
end

local function makeHealthBar(bb)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 4, 1, 0)
    bg.Position = UDim2.new(0, -6, 0, 0)
    bg.BackgroundColor3 = Color3.new(0, 0, 0)
    bg.BorderSizePixel = 0
    bg.Parent = bb

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    bar.BorderSizePixel = 0
    bar.Parent = bb

    return bg, bar
end

function ESP.new()
    local self = setmetatable({}, ESP)
    self.states = {}
    self.num = 0
    self.destroyed = false

    local function newState(player)
        local char = player.Character
        local head = char and (char:FindFirstChild("HitboxHead") or char:FindFirstChild("Head"))
        local bb = head and makeBillboard(head) or nil

        local st = {
            player = player,
            character = nil,
            idx = 0,
            bb = bb,
            box = bb and makeBox(bb) or nil,
            barBg = bb and makeHealthBar(bb) or nil,
            name = bb and makeTextLabel(bb, player.Name) or nil,
            dist = bb and makeTextLabel(bb, "") or nil,
            num = bb and makeTextLabel(bb, "") or nil,
            bar = nil,
            lines = {},
        }

        if st.barBg then
            st.bar = st.barBg:FindFirstChildOfClass("Frame")
        end

        for i = 1, #SKEL do
            local ln = makeBox(bb)
            if ln then
                ln.Visible = false
                table.insert(st.lines, ln)
            end
        end

        self.num = self.num + 1
        st.idx = self.num
        return st
    end

    local function hide(st)
        if st.box then st.box.BackgroundTransparency = 1 end
        if st.barBg then
            st.barBg.BackgroundTransparency = 1
            if st.bar then st.bar.BackgroundTransparency = 1 end
        end
        if st.name then st.name.TextTransparency = 1 end
        if st.dist then st.dist.TextTransparency = 1 end
        if st.num then st.num.TextTransparency = 1 end
        for _, ln in ipairs(st.lines) do
            if ln then ln.BackgroundTransparency = 1 end
        end
    end

    local function show(st)
        if st.box then st.box.BackgroundTransparency = 0 end
        if st.barBg then
            st.barBg.BackgroundTransparency = 0
            if st.bar then st.bar.BackgroundTransparency = 0 end
        end
        if st.name then st.name.TextTransparency = 0 end
        if st.dist then st.dist.TextTransparency = 0 end
        if st.num then st.num.TextTransparency = 0 end
        for _, ln in ipairs(st.lines) do
            if ln then ln.BackgroundTransparency = 1 end
        end
    end

    local function tick()
        if self.destroyed then return end
        local esp_enabled = (_G.Toggles and _G.Toggles.esp_enabled and _G.Toggles.esp_enabled.Value) or false
        if not esp_enabled then
            for _, st in pairs(self.states) do hide(st) end
            return
        end
        local cam = workspace.CurrentCamera
        if not cam then return end

        local allPlayers = Players:GetPlayers()
        if #allPlayers <= 1 then
            for _, st in pairs(self.states) do hide(st) end
            return
        end

        -- Cache viewport size once per frame
        local vpW, vpH = cam.ViewportSize.X, cam.ViewportSize.Y
        local camPos = cam.CFrame.Position
        local camLook = cam.CFrame.LookVector

        for _, player in ipairs(allPlayers) do
            if player == LocalPlayer then continue end
            local st = self.states[player]
            if not st then st = newState(player); self.states[player] = st end
            local character = player.Character
            local hum = character and character:FindFirstChild("Humanoid")
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local ally = nil
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character == character then
                    ally = p.Team ~= nil and p.Team ~= Enum.Team.Neutral
                    break
                end
            end
            if not character or not hum or hum.Health <= 0 or not hrp
                or ally then
                hide(st); continue
            end

            -- Single sample: snapshot part positions ONCE per frame
            local pos = {}
            for _, pn in ipairs(SKEL_PARTS) do
                local part = character:FindFirstChild(pn)
                if part then pos[pn] = part.Position end
            end
            local head = character:FindFirstChild("HitboxHead")
                or character:FindFirstChild("Head")
            local headP = head and head.Position or (pos.Head or hrp.Position)
            local feetP = hrp.Position - Vector3.new(0, 3, 0)

            -- Pre-compute screen positions ONCE
            local headScr, headOn = cam:WorldToViewportPoint(headP)
            local feetScr, feetOn = cam:WorldToViewportPoint(feetP)

            -- Behind-camera guard
            local toHead = (headP - camPos)
            if not headOn or not feetOn or camLook:Dot(toHead.Unit) <= 0 then
                hide(st); continue
            end

            local h = math.max(10, math.abs(feetScr.Y - headScr.Y))
            local w = h * 0.55
            local x, y = feetScr.X - w / 2, headScr.Y

            -- Box
            if _G.Toggles.esp_box and _G.Toggles.esp_box.Value then
                if st.box then
                    st.box.Size = UDim2.new(w / 2 + 2, 0, h, 0)
                    st.box.Position = UDim2.new(0, x - 2, 0, y)
                    st.box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    st.box.BackgroundTransparency = 0
                end
            elseif st.box then
                st.box.BackgroundTransparency = 1
            end

            -- health bar
            if _G.Toggles.esp_healthbar and _G.Toggles.esp_healthbar.Value then
                local frac = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                if st.barBg then
                    local hPos = (_G.Options and _G.Options.healthbar_pos and _G.Options.healthbar_pos.Value) or "top"
                    local barX, barY = x - 8, y
                    if hPos == "bottom" then barY = y + h end
                    if hPos == "left" then barX = x - 12 end
                    if hPos == "right" then barX = x + w + 4 end
                    st.barBg.Position = UDim2.new(0, barX, 0, barY)
                    st.barBg.Size = UDim2.new(0, 4, 0, h)
                    st.barBg.BackgroundTransparency = 0
                end
                if st.bar then
                    st.bar.Size = UDim2.new(1, 0, 0, h * frac)
                    st.bar.BackgroundColor3 = Color3.fromRGB(255 - math.floor(255 * frac), math.floor(255 * frac), 0)
                    st.bar.BackgroundTransparency = 0
                end
            else
                if st.barBg then st.barBg.BackgroundTransparency = 1 end
                if st.bar then st.bar.BackgroundTransparency = 1 end
            end

            -- name
            if _G.Toggles.esp_name and _G.Toggles.esp_name.Value then
                if st.name then
                    st.name.Text = player.Name
                    st.name.Position = UDim2.new(0, 0, 0, y - 16)
                    st.name.TextTransparency = 0
                end
            elseif st.name then
                st.name.TextTransparency = 1
            end

            -- distance
            if _G.Toggles.esp_distance and _G.Toggles.esp_distance.Value then
                local d = math.floor((hrp.Position - cam.CFrame.Position).Magnitude)
                if st.dist then
                    st.dist.Text = d .. "st"
                    st.dist.Position = UDim2.new(0, 0, 0, y + h + 4)
                    st.dist.TextTransparency = 0
                end
            elseif st.dist then
                st.dist.TextTransparency = 1
            end

            -- number
            if _G.Toggles.esp_number and _G.Toggles.esp_number.Value then
                if st.num then
                    st.num.Text = tostring(st.idx)
                    st.num.Position = UDim2.new(0, x + w + 8, 0, y)
                    st.num.TextTransparency = 0
                end
            elseif st.num then
                st.num.TextTransparency = 1
            end

            -- skeleton
            local showSkel = _G.Toggles.esp_skeleton and _G.Toggles.esp_skeleton.Value
            for i, pair in ipairs(SKEL) do
                local ln = st.lines[i]
                local a = pos[pair[1]]
                local b = pos[pair[2]]
                if showSkel and a and b and ln then
                    local aScr, _ = cam:WorldToViewportPoint(a)
                    local bScr, _ = cam:WorldToViewportPoint(b)
                    if aScr and bScr then
                        ln.Position = UDim2.new(0, aScr.X, 0, aScr.Y)
                        ln.Size = UDim2.new(math.max(1, bScr.X - aScr.X), 0, 1, 0)
                        ln.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                        ln.BackgroundTransparency = 0
                    else
                        ln.BackgroundTransparency = 1
                    end
                elseif ln then
                    ln.BackgroundTransparency = 1
                end
            end
        end

        -- drop drawings for players who left
        local activeSet = {}
        for _, p in ipairs(allPlayers) do activeSet[p] = true end
        for player, st in pairs(self.states) do
            if not activeSet[player] then
                hide(st)
                if st.bb then pcall(function() st.bb:Destroy() end) end
                self.states[player] = nil
            end
        end
    end

    self._renderConn = RunService.RenderStepped:Connect(tick)
    return self
end

function ESP:Destroy()
    if self._renderConn then
        self._renderConn:Disconnect()
        self._renderConn = nil
    end
    for _, st in pairs(self.states) do
        if st.bb then pcall(function() st.bb:Destroy() end) end
    end
    self.states = {}
    self.destroyed = true
    _G.LR_ESP = nil
end

local function construct()
    if _G.Toggles then
        _G.LR_ESP = ESP.new()
    else
        task.defer(function()
            if _G.Toggles then
                _G.LR_ESP = ESP.new()
            end
        end)
    end
end

construct()

return ESP