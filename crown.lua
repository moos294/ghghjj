local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local PlayerGui = LP:WaitForChild("PlayerGui")

local Config = {
    Action = "PushUp", Interval = 0.1, AutoStart = false,
    AutoRebirth = false, AutoRebirthDelay = 3, AntiAfk = true,
    AutoReset = false, AutoResetInterval = 300, SaveSettings = true,
    Notifications = true, MinimizeOnStart = false, TotalReps = 0,
    Fly = false, FlySpeed = 50, WalkSpeed = 16,
    AutoRebirthCount = 0, AutoRebirthDone = 0,
}

local Actions = { "PushUp", "SitUp", "PullUp", "Squat" }
local ActionNames = { PushUp = "俯卧撑", SitUp = "仰卧起坐", PullUp = "引体向上", Squat = "深蹲" }
local CONFIG_FILE = "CrownStrength_config.json"
local MIN_INTERVAL, MAX_INTERVAL = 0.08, 10
local IS_TOUCH = UserInputService.TouchEnabled
local REBIRTH_TIMEOUT = 15
local ScriptStartTime = tick()

local function findRemote(name, alt)
    local list = { ReplicatedStorage }
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if folder then table.insert(list, folder) end
    for _, p in ipairs(list) do
        local r = p:FindFirstChild(name) or (alt and p:FindFirstChild(alt))
        if r then return r end
    end
end

local TrainEvent = findRemote("TrainEvent", "Train")
local RebirthEvent = findRemote("RebirthEvent", "Rebirth")

local function saveConfig()
    if not Config.SaveSettings or type(writefile) ~= "function" then return end
    pcall(function()
        local d = {}
        for k, v in pairs(Config) do
            if type(v) ~= "table" and type(v) ~= "function" then d[k] = v end
        end
        writefile(CONFIG_FILE, HttpService:JSONEncode(d))
    end)
end

local function loadConfig()
    if not Config.SaveSettings or type(isfile) ~= "function" or type(readfile) ~= "function" then return end
    if not isfile(CONFIG_FILE) then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if ok and type(data) == "table" then
        for k, v in pairs(data) do
            if Config[k] ~= nil and type(Config[k]) == type(v) then Config[k] = v end
        end
    end
end
loadConfig()

local C = {
    bg = Color3.fromRGB(22, 22, 26),
    sidebar = Color3.fromRGB(16, 16, 20),
    card = Color3.fromRGB(32, 32, 38),
    cardHover = Color3.fromRGB(40, 40, 48),
    stroke = Color3.fromRGB(48, 48, 56),
    accent = Color3.fromRGB(60, 150, 230),
    text = Color3.fromRGB(230, 230, 235),
    textDim = Color3.fromRGB(150, 150, 160),
    textSub = Color3.fromRGB(100, 100, 110),
    green = Color3.fromRGB(0, 200, 140),
    red = Color3.fromRGB(220, 70, 80),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function stroke(p, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or C.stroke
    s.Thickness = t or 1
    s.Transparency = tr or 0
    s.Parent = p
    return s
end

local function fmt(n)
    n = math.floor(tonumber(n) or 0)
    local s = tostring(n)
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if out:sub(1, 1) == "," then out = out:sub(2) end
    return out
end

local function drawCatFace(parent, cx, cy, scale, alpha, zBase)
    scale = scale or 1
    alpha = alpha or 0
    zBase = zBase or 3
    local baseSize = 100 * scale

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(0, baseSize + 20, 0, baseSize + 20)
    glow.Position = UDim2.new(0, cx - baseSize/2 - 10, 0, cy - baseSize/2 - 10)
    glow.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
    glow.BackgroundTransparency = 1 - (0.35 * (1 - alpha))
    glow.BorderSizePixel = 0
    glow.ZIndex = zBase - 1
    glow.Parent = parent
    corner(glow, baseSize)

    local earL = Instance.new("Frame")
    earL.Size = UDim2.new(0, baseSize * 0.32, 0, baseSize * 0.32)
    earL.Position = UDim2.new(0, cx - baseSize * 0.45, 0, cy - baseSize * 0.55)
    earL.BackgroundColor3 = Color3.fromRGB(55, 60, 75)
    earL.BackgroundTransparency = alpha
    earL.BorderSizePixel = 0
    earL.Rotation = 25
    earL.ZIndex = zBase
    earL.Parent = parent
    corner(earL, 6)

    local earLInner = Instance.new("Frame")
    earLInner.Size = UDim2.new(0, baseSize * 0.16, 0, baseSize * 0.16)
    earLInner.Position = UDim2.new(0.5, -baseSize * 0.08, 0.5, -baseSize * 0.08)
    earLInner.BackgroundColor3 = Color3.fromRGB(180, 130, 150)
    earLInner.BackgroundTransparency = alpha + 0.1
    earLInner.BorderSizePixel = 0
    earLInner.ZIndex = zBase + 1
    earLInner.Parent = earL
    corner(earLInner, 4)

    local earR = Instance.new("Frame")
    earR.Size = UDim2.new(0, baseSize * 0.32, 0, baseSize * 0.32)
    earR.Position = UDim2.new(0, cx + baseSize * 0.13, 0, cy - baseSize * 0.55)
    earR.BackgroundColor3 = Color3.fromRGB(55, 60, 75)
    earR.BackgroundTransparency = alpha
    earR.BorderSizePixel = 0
    earR.Rotation = -25
    earR.ZIndex = zBase
    earR.Parent = parent
    corner(earR, 6)

    local earRInner = Instance.new("Frame")
    earRInner.Size = UDim2.new(0, baseSize * 0.16, 0, baseSize * 0.16)
    earRInner.Position = UDim2.new(0.5, -baseSize * 0.08, 0.5, -baseSize * 0.08)
    earRInner.BackgroundColor3 = Color3.fromRGB(180, 130, 150)
    earRInner.BackgroundTransparency = alpha + 0.1
    earRInner.BorderSizePixel = 0
    earRInner.ZIndex = zBase + 1
    earRInner.Parent = earR
    corner(earRInner, 4)

    local head = Instance.new("Frame")
    head.Size = UDim2.new(0, baseSize, 0, baseSize)
    head.Position = UDim2.new(0, cx - baseSize/2, 0, cy - baseSize/2)
    head.BackgroundColor3 = Color3.fromRGB(55, 60, 75)
    head.BackgroundTransparency = alpha
    head.BorderSizePixel = 0
    head.ZIndex = zBase
    head.Parent = parent
    corner(head, baseSize / 2)
    stroke(head, Color3.fromRGB(120, 200, 255), 1.5, alpha + 0.2)

    local stripe1 = Instance.new("Frame")
    stripe1.Size = UDim2.new(0, baseSize * 0.15, 0, baseSize * 0.04)
    stripe1.Position = UDim2.new(0, cx - baseSize * 0.1, 0, cy - baseSize * 0.32)
    stripe1.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    stripe1.BackgroundTransparency = alpha + 0.2
    stripe1.BorderSizePixel = 0
    stripe1.Rotation = -20
    stripe1.ZIndex = zBase + 1
    stripe1.Parent = parent
    corner(stripe1, 3)

    local stripe2 = Instance.new("Frame")
    stripe2.Size = UDim2.new(0, baseSize * 0.15, 0, baseSize * 0.04)
    stripe2.Position = UDim2.new(0, cx - baseSize * 0.05, 0, cy - baseSize * 0.34)
    stripe2.BackgroundColor3 = Color3.fromRGB(35, 40, 55)
    stripe2.BackgroundTransparency = alpha + 0.2
    stripe2.BorderSizePixel = 0
    stripe2.ZIndex = zBase + 1
    stripe2.Parent = parent
    corner(stripe2, 3)

    local eyeLGlow = Instance.new("Frame")
    eyeLGlow.Size = UDim2.new(0, baseSize * 0.34, 0, baseSize * 0.28)
    eyeLGlow.Position = UDim2.new(0, cx - baseSize * 0.36, 0, cy - baseSize * 0.16)
    eyeLGlow.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    eyeLGlow.BackgroundTransparency = 1 - (0.35 * (1 - alpha))
    eyeLGlow.BorderSizePixel = 0
    eyeLGlow.ZIndex = zBase + 1
    eyeLGlow.Parent = parent
    corner(eyeLGlow, baseSize / 4)

    local eyeL = Instance.new("Frame")
    eyeL.Size = UDim2.new(0, baseSize * 0.22, 0, baseSize * 0.18)
    eyeL.Position = UDim2.new(0, cx - baseSize * 0.3, 0, cy - baseSize * 0.11)
    eyeL.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
    eyeL.BackgroundTransparency = alpha
    eyeL.BorderSizePixel = 0
    eyeL.ZIndex = zBase + 2
    eyeL.Parent = parent
    corner(eyeL, baseSize / 4)

    local eyeLPupil = Instance.new("Frame")
    eyeLPupil.Size = UDim2.new(0, baseSize * 0.13, 0, baseSize * 0.14)
    eyeLPupil.Position = UDim2.new(0, cx - baseSize * 0.255, 0, cy - baseSize * 0.09)
    eyeLPupil.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    eyeLPupil.BackgroundTransparency = alpha
    eyeLPupil.BorderSizePixel = 0
    eyeLPupil.ZIndex = zBase + 3
    eyeLPupil.Parent = parent
    corner(eyeLPupil, baseSize / 5)

    local eyeRGlow = Instance.new("Frame")
    eyeRGlow.Size = UDim2.new(0, baseSize * 0.34, 0, baseSize * 0.28)
    eyeRGlow.Position = UDim2.new(0, cx + baseSize * 0.02, 0, cy - baseSize * 0.16)
    eyeRGlow.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    eyeRGlow.BackgroundTransparency = 1 - (0.35 * (1 - alpha))
    eyeRGlow.BorderSizePixel = 0
    eyeRGlow.ZIndex = zBase + 1
    eyeRGlow.Parent = parent
    corner(eyeRGlow, baseSize / 4)

    local eyeR = Instance.new("Frame")
    eyeR.Size = UDim2.new(0, baseSize * 0.22, 0, baseSize * 0.18)
    eyeR.Position = UDim2.new(0, cx + baseSize * 0.08, 0, cy - baseSize * 0.11)
    eyeR.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
    eyeR.BackgroundTransparency = alpha
    eyeR.BorderSizePixel = 0
    eyeR.ZIndex = zBase + 2
    eyeR.Parent = parent
    corner(eyeR, baseSize / 4)

    local eyeRPupil = Instance.new("Frame")
    eyeRPupil.Size = UDim2.new(0, baseSize * 0.13, 0, baseSize * 0.14)
    eyeRPupil.Position = UDim2.new(0, cx + baseSize * 0.125, 0, cy - baseSize * 0.09)
    eyeRPupil.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    eyeRPupil.BackgroundTransparency = alpha
    eyeRPupil.BorderSizePixel = 0
    eyeRPupil.ZIndex = zBase + 3
    eyeRPupil.Parent = parent
    corner(eyeRPupil, baseSize / 5)

    local nose = Instance.new("Frame")
    nose.Size = UDim2.new(0, baseSize * 0.1, 0, baseSize * 0.08)
    nose.Position = UDim2.new(0, cx - baseSize * 0.05, 0, cy + baseSize * 0.12)
    nose.BackgroundColor3 = Color3.fromRGB(200, 130, 150)
    nose.BackgroundTransparency = alpha
    nose.BorderSizePixel = 0
    nose.Rotation = 45
    nose.ZIndex = zBase + 2
    nose.Parent = parent
    corner(nose, 3)

    local mouth = Instance.new("Frame")
    mouth.Size = UDim2.new(0, baseSize * 0.24, 0, baseSize * 0.14)
    mouth.Position = UDim2.new(0, cx - baseSize * 0.12, 0, cy + baseSize * 0.22)
    mouth.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mouth.BackgroundTransparency = alpha
    mouth.BorderSizePixel = 0
    mouth.ZIndex = zBase + 2
    mouth.Parent = parent
    corner(mouth, baseSize * 0.09)

    local tongue = Instance.new("Frame")
    tongue.Size = UDim2.new(0, baseSize * 0.16, 0, baseSize * 0.28)
    tongue.Position = UDim2.new(0, cx - baseSize * 0.08, 0, cy + baseSize * 0.32)
    tongue.BackgroundColor3 = Color3.fromRGB(255, 120, 145)
    tongue.BackgroundTransparency = alpha
    tongue.BorderSizePixel = 0
    tongue.ZIndex = zBase + 3
    tongue.Parent = parent
    corner(tongue, baseSize * 0.08)

    local tongueLine = Instance.new("Frame")
    tongueLine.Size = UDim2.new(0, baseSize * 0.025, 0, baseSize * 0.18)
    tongueLine.Position = UDim2.new(0.5, -baseSize * 0.0125, 0, baseSize * 0.05)
    tongueLine.BackgroundColor3 = Color3.fromRGB(200, 70, 95)
    tongueLine.BackgroundTransparency = alpha + 0.2
    tongueLine.BorderSizePixel = 0
    tongueLine.ZIndex = zBase + 4
    tongueLine.Parent = tongue
    corner(tongueLine, 1)

    local tongueTip = Instance.new("Frame")
    tongueTip.Size = UDim2.new(0, baseSize * 0.16, 0, baseSize * 0.12)
    tongueTip.Position = UDim2.new(0, cx - baseSize * 0.08, 0, cy + baseSize * 0.54)
    tongueTip.BackgroundColor3 = Color3.fromRGB(255, 120, 145)
    tongueTip.BackgroundTransparency = alpha
    tongueTip.BorderSizePixel = 0
    tongueTip.ZIndex = zBase + 3
    tongueTip.Parent = parent
    corner(tongueTip, baseSize * 0.08)

    for _, side in ipairs({ -1, 1 }) do
        local wL = Instance.new("Frame")
        wL.Size = UDim2.new(0, baseSize * 0.35, 0, baseSize * 0.015)
        wL.Position = UDim2.new(0, cx + side * baseSize * 0.15, 0, cy + baseSize * 0.22)
        wL.BackgroundColor3 = Color3.fromRGB(180, 200, 220)
        wL.BackgroundTransparency = alpha + 0.4
        wL.BorderSizePixel = 0
        wL.Rotation = side * 8
        wL.ZIndex = zBase + 2
        wL.Parent = parent
        corner(wL, 1)
    end
end

local function drawBolt(parent, x, y, w, h, rot, color, alpha, z)
    local b = Instance.new("Frame")
    b.Size = UDim2.new(0, w, 0, h)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = color
    b.BackgroundTransparency = alpha or 0.3
    b.BorderSizePixel = 0
    b.Rotation = rot
    b.ZIndex = z or 2
    b.Parent = parent
    corner(b, 2)

    local b2 = Instance.new("Frame")
    b2.Size = UDim2.new(0, w * 0.6, 0, h * 0.7)
    b2.Position = UDim2.new(0, x + 8, 0, y + h * 0.5)
    b2.BackgroundColor3 = color
    b2.BackgroundTransparency = alpha or 0.3
    b2.BorderSizePixel = 0
    b2.Rotation = rot - 30
    b2.ZIndex = z or 2
    b2.Parent = parent
    corner(b2, 2)
end

local function drawLightningField(parent, alpha, z)
    local AB = Color3.fromRGB(120, 210, 255)
    local AB2 = Color3.fromRGB(180, 230, 255)
    local AB3 = Color3.fromRGB(80, 170, 255)

    drawBolt(parent, 30, -20, 5, 90, 20, AB, alpha, z)
    drawBolt(parent, 60, 30, 4, 60, -25, AB2, alpha, z)
    drawBolt(parent, 15, 70, 4, 80, 35, AB3, alpha, z)
    drawBolt(parent, 90, -15, 5, 100, -15, AB2, alpha, z)

    drawBolt(parent, 430, -20, 5, 100, -25, AB, alpha, z)
    drawBolt(parent, 400, 40, 4, 70, 30, AB2, alpha, z)
    drawBolt(parent, 450, 90, 5, 80, -35, AB3, alpha, z)
    drawBolt(parent, 470, 10, 4, 90, 15, AB2, alpha, z)

    drawBolt(parent, 130, 260, 4, 70, -20, AB, alpha, z)
    drawBolt(parent, 340, 270, 5, 80, 15, AB2, alpha, z)
    drawBolt(parent, 220, 280, 4, 60, -10, AB3, alpha, z)

    drawBolt(parent, 5, 150, 4, 60, 45, AB2, alpha, z)
    drawBolt(parent, 480, 180, 4, 70, -40, AB, alpha, z)
end

local STAT_DEFS = {
    { key = "Strength", label = "力量",
      names = { "Strength", "Power", "Str", "StrengthValue", "力量", "TotalStrength", "CrownStrength" } },
    { key = "Rebirth", label = "重生",
      names = { "Rebirth", "Rebirths", "RebirthCount", "RebirthLevel", "重生", "RebirthValue" } },
    { key = "Gems", label = "宝石",
      names = { "Gems", "Gem", "GemCount", "Diamonds", "Crystal", "宝石", "Diamond" } },
    { key = "Agility", label = "敏捷",
      names = { "Agility", "Speed", "Agil", "AgilityValue", "敏捷", "SpeedValue" } },
}

local statSources = {}
for _, def in ipairs(STAT_DEFS) do
    statSources[def.key] = { src = nil, attr = nil }
end

local function findStat(key)
    local s = statSources[key]
    if s.src and s.src.Parent then return true end
    local def
    for _, d in ipairs(STAT_DEFS) do
        if d.key == key then def = d break end
    end
    if not def then return false end

    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        for _, n in ipairs(def.names) do
            local v = ls:FindFirstChild(n)
            if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then
                s.src, s.attr = v, nil
                return true
            end
        end
    end
    for _, n in ipairs(def.names) do
        local v = LP:GetAttribute(n)
        if type(v) == "number" then
            s.src, s.attr = nil, n
            return true
        end
    end
    for _, n in ipairs(def.names) do
        local direct = LP:FindFirstChild(n)
        if direct and (direct:IsA("IntValue") or direct:IsA("NumberValue")) then
            s.src, s.attr = direct, nil
            return true
        end
    end
    return false
end

local function getStat(key)
    local s = statSources[key]
    if s.src and s.src.Parent then
        return tonumber(s.src.Value) or 0
    end
    if s.attr then
        return tonumber(LP:GetAttribute(s.attr)) or 0
    end
    return 0
end

local function hasStatSource(key)
    local s = statSources[key]
    if s.src and s.src.Parent then return true end
    if s.attr and type(LP:GetAttribute(s.attr)) == "number" then return true end
    return false
end

local function refreshAllStats()
    for _, def in ipairs(STAT_DEFS) do
        findStat(def.key)
    end
end

pcall(function()
    for _, root in ipairs({LP.PlayerGui, game:GetService("CoreGui")}) do
        local old = root:FindFirstChild("PumpLabUI")
        if old then old:Destroy() end
    end
end)

local SG = Instance.new("ScreenGui")
SG.Name = "PumpLabUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then SG.Parent = LP.PlayerGui end

local function notify(text, color)
    if not Config.Notifications or not SG.Parent then return end
    color = color or C.accent
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 220, 0, 34)
    toast.Position = UDim2.new(0.5, -110, 0, -40)
    toast.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
    toast.BackgroundTransparency = 0.05
    toast.BorderSizePixel = 0
    toast.ZIndex = 300
    toast.Parent = SG
    corner(toast, 8)
    stroke(toast, color, 1.2, 0.2)

    local acc = Instance.new("Frame")
    acc.Size = UDim2.new(0, 3, 0, 20)
    acc.Position = UDim2.new(0, 8, 0.5, -10)
    acc.BackgroundColor3 = color
    acc.BorderSizePixel = 0
    acc.ZIndex = 301
    acc.Parent = toast
    corner(acc, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C.text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 301
    lbl.Parent = toast

    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        BackgroundTransparency = 0, Position = UDim2.new(0.5, -110, 0, 20)
    }):Play()
    task.delay(2.4, function()
        if not toast.Parent then return end
        TweenService:Create(toast, TweenInfo.new(0.3), {
            BackgroundTransparency = 1, Position = UDim2.new(0.5, -110, 0, -40)
        }):Play()
        task.wait(0.35)
        if toast.Parent then toast:Destroy() end
    end)
end

local W, H = 500, 320

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, W, 0, H)
Main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
Main.BackgroundColor3 = Color3.fromRGB(10, 12, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = SG
corner(Main, 12)
stroke(Main, Color3.fromRGB(80, 150, 220), 1.2, 0.3)

local CatBG = Instance.new("Frame")
CatBG.Size = UDim2.new(1, 0, 1, 0)
CatBG.BackgroundTransparency = 1
CatBG.ZIndex = 0
CatBG.ClipsDescendants = true
CatBG.Parent = Main
corner(CatBG, 12)

local BgGrad = Instance.new("Frame")
BgGrad.Size = UDim2.new(1, 0, 1, 0)
BgGrad.BackgroundColor3 = Color3.fromRGB(18, 22, 34)
BgGrad.BackgroundTransparency = 0
BgGrad.BorderSizePixel = 0
BgGrad.ZIndex = 0
BgGrad.Parent = CatBG
corner(BgGrad, 12)

local BgGradFill = Instance.new("UIGradient")
BgGradFill.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 28, 48)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 16, 26)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 32, 52)),
})
BgGradFill.Rotation = 135
BgGradFill.Parent = BgGrad

drawLightningField(CatBG, 0.55, 1)
drawCatFace(CatBG, W / 2, H / 2 + 10, 1.9, 0.72, 2)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
TopBar.BackgroundTransparency = 0.15
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 10
TopBar.Parent = Main

local TopLogo = Instance.new("Frame")
TopLogo.Size = UDim2.new(0, 28, 0, 28)
TopLogo.Position = UDim2.new(0, 12, 0.5, -14)
TopLogo.BackgroundTransparency = 1
TopLogo.ZIndex = 11
TopLogo.Parent = TopBar
drawCatFace(TopLogo, 14, 14, 0.28, 0, 12)

local TopTitle = Instance.new("TextLabel")
TopTitle.Size = UDim2.new(0, 260, 1, 0)
TopTitle.Position = UDim2.new(0, 46, 0, 0)
TopTitle.BackgroundTransparency = 1
TopTitle.Text = "力量之冠封存"
TopTitle.TextColor3 = C.text
TopTitle.TextXAlignment = Enum.TextXAlignment.Left
TopTitle.Font = Enum.Font.GothamBold
TopTitle.TextSize = 15
TopTitle.ZIndex = 11
TopTitle.Parent = TopBar

local TopSub = Instance.new("TextLabel")
TopSub.Size = UDim2.new(0, 260, 0, 12)
TopSub.Position = UDim2.new(0, 46, 1, -16)
TopSub.BackgroundTransparency = 1
TopSub.Text = "Crown Strength · v1.0"
TopSub.TextColor3 = C.textSub
TopSub.TextXAlignment = Enum.TextXAlignment.Left
TopSub.Font = Enum.Font.Gotham
TopSub.TextSize = 10
TopSub.ZIndex = 11
TopSub.Parent = TopBar

local TopDeco = Instance.new("Frame")
TopDeco.Size = UDim2.new(0, 32, 0, 32)
TopDeco.Position = UDim2.new(1, -132, 0.5, -16)
TopDeco.BackgroundTransparency = 1
TopDeco.ZIndex = 11
TopDeco.Parent = TopBar
drawCatFace(TopDeco, 16, 16, 0.32, 0, 12)

local function topBtn(text, x, isRed)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 32, 0, 28)
    b.Position = UDim2.new(1, x, 0.5, -14)
    b.BackgroundColor3 = C.card
    b.BackgroundTransparency = 0.15
    b.Text = text
    b.TextColor3 = isRed and C.red or C.textDim
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 12
    b.Parent = TopBar
    corner(b, 6)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = C.cardHover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = C.card end)
    return b
end

local CloseBtn = topBtn("×", -44, true)
local MinBtn = topBtn("−", -84, false)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -44)
Sidebar.Position = UDim2.new(0, 0, 0, 44)
Sidebar.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
Sidebar.BackgroundTransparency = 0.3
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 10
Sidebar.Parent = Main

local NavList = Instance.new("UIListLayout")
NavList.Padding = UDim.new(0, 6)
NavList.Parent = Sidebar

local NavPad = Instance.new("UIPadding")
NavPad.PaddingTop = UDim.new(0, 12)
NavPad.PaddingLeft = UDim.new(0, 8)
NavPad.PaddingRight = UDim.new(0, 8)
NavPad.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -130, 1, -44)
Content.Position = UDim2.new(0, 130, 0, 44)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.ZIndex = 10
Content.Parent = Main

local pages = {}
local navButtons = {}
local currentPage = nil

local function showPage(name)
    if currentPage == name then return end
    for n, p in pairs(pages) do
        p.Visible = (n == name)
    end
    for n, b in pairs(navButtons) do
        if n == name then
            TweenService:Create(b, TweenInfo.new(0.18), {BackgroundColor3 = C.accent, BackgroundTransparency = 0.1}):Play()
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            TweenService:Create(b, TweenInfo.new(0.18), {BackgroundColor3 = C.card, BackgroundTransparency = 0.25}):Play()
            b.TextColor3 = C.textDim
        end
    end
    currentPage = name
end

local function makePage(name)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 4
    p.ScrollBarImageColor3 = C.accent
    p.ScrollBarImageTransparency = 0.5
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false
    p.ZIndex = 11
    p.Parent = Content

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 14)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = p

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = p

    pages[name] = p
    return p
end

local function makeNavBtn(icon, label, pageName)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 36)
    b.BackgroundColor3 = C.card
    b.BackgroundTransparency = 0.25
    b.Text = "  " .. icon .. "  " .. label
    b.TextColor3 = C.textDim
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 11
    b.Parent = Sidebar
    corner(b, 8)

    b.MouseEnter:Connect(function()
        if currentPage ~= pageName then
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.cardHover, BackgroundTransparency = 0.15}):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if currentPage ~= pageName then
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.card, BackgroundTransparency = 0.25}):Play()
        end
    end)
    b.MouseButton1Click:Connect(function() showPage(pageName) end)

    navButtons[pageName] = b
end

local function makeCard(parent, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height or 60)
    card.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    card.ZIndex = 12
    card.Parent = parent
    corner(card, 10)
    stroke(card, Color3.fromRGB(60, 80, 110), 1, 0.5)
    return card
end

local function makeInfoCard(parent, title, lines)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(28, 32, 44)
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    card.ZIndex = 12
    card.Parent = parent
    corner(card, 10)
    stroke(card, Color3.fromRGB(60, 80, 110), 1, 0.5)

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = card

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = card

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, 18)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = C.text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Font = Enum.Font.GothamBold
    t.TextSize = 13
    t.LayoutOrder = 1
    t.ZIndex = 13
    t.Parent = card

    for i, line in ipairs(lines) do
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 0)
        l.AutomaticSize = Enum.AutomaticSize.Y
        l.BackgroundTransparency = 1
        l.Text = line
        l.TextColor3 = C.textDim
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextWrapped = true
        l.Font = Enum.Font.Gotham
        l.TextSize = 11
        l.LayoutOrder = i + 1
        l.ZIndex = 13
        l.Parent = card
    end

    return card
end