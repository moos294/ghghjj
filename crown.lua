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
local ScriptStartTime = tick() -- 记录脚本启动时间，用于计算总运行时长

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

local function makeDataRow(parent, label, color)
    local r = Instance.new("Frame")
    r.Size = UDim2.new(1, 0, 0, 24)
    r.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    r.BackgroundTransparency = 0.3
    r.BorderSizePixel = 0
    r.ZIndex = 13
    r.Parent = parent
    corner(r, 6)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.55, -10, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = label
    l.TextColor3 = C.textDim
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.ZIndex = 14
    l.Parent = r

    local v = Instance.new("TextLabel")
    v.Size = UDim2.new(0.45, -10, 1, 0)
    v.Position = UDim2.new(0.55, 0, 0, 0)
    v.BackgroundTransparency = 1
    v.Text = "—"
    v.TextColor3 = color or C.text
    v.TextXAlignment = Enum.TextXAlignment.Right
    v.Font = Enum.Font.GothamBold
    v.TextSize = 12
    v.ZIndex = 14
    v.Parent = r
    return v
end

local function makeToggle(parent, title, desc, key, onToggle)
    local card = makeCard(parent, desc and 60 or 48)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -100, 0, 20)
    t.Position = UDim2.new(0, 14, 0, 10)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = C.text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Font = Enum.Font.GothamBold
    t.TextSize = 13
    t.ZIndex = 13
    t.Parent = card

    if desc then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -32, 0, 26)
        d.Position = UDim2.new(0, 14, 0, 30)
        d.BackgroundTransparency = 1
        d.Text = desc
        d.TextColor3 = C.textDim
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextYAlignment = Enum.TextYAlignment.Top
        d.TextWrapped = true
        d.Font = Enum.Font.Gotham
        d.TextSize = 10
        d.ZIndex = 13
        d.Parent = card
    end

    local on = Config[key] and true or false

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 22)
    track.Position = UDim2.new(1, -54, 0, 13)
    track.BackgroundColor3 = on and C.green or Color3.fromRGB(60, 60, 68)
    track.BorderSizePixel = 0
    track.ZIndex = 13
    track.Parent = card
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    knob.BorderSizePixel = 0
    knob.ZIndex = 14
    knob.Parent = track
    corner(knob, 9)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 15
    hit.Parent = card

    hit.MouseButton1Click:Connect(function()
        on = not on
        Config[key] = on
        if key == "AutoRebirth" and on and not RebirthEvent then
            on = false
            Config[key] = false
            notify("未找到重生事件", C.red)
        end
        TweenService:Create(track, TweenInfo.new(0.18), {
            BackgroundColor3 = on and C.green or Color3.fromRGB(60, 60, 68)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {
            Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }):Play()
        if onToggle then onToggle(on) end
        saveConfig()
    end)
end

local function makeNumberInput(parent, title, key, minV, maxV, onChange)
    local card = makeCard(parent, 50)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0.45, -10, 1, 0)
    t.Position = UDim2.new(0, 14, 0, 0)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = C.text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.ZIndex = 13
    t.Parent = card

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.5, -14, 0, 32)
    box.Position = UDim2.new(0.5, 0, 0.5, -16)
    box.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
    box.Text = tostring(Config[key])
    box.TextColor3 = C.accent
    box.Font = Enum.Font.Code
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    box.ZIndex = 13
    box.Parent = card
    corner(box, 6)
    stroke(box, Color3.fromRGB(60, 80, 110), 1, 0.5)

    box.Focused:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3 = C.cardHover}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(box, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 24, 34)}):Play()
        local n = tonumber(box.Text)
        if n and n >= minV and n <= maxV then
            Config[key] = n
            box.Text = tostring(n)
            if onChange then onChange(n) end
            saveConfig()
        else
            box.Text = tostring(Config[key])
            notify(string.format("范围 %s ~ %s", tostring(minV), tostring(maxV)), C.red)
        end
    end)
end

local function makeAction(parent, text, color, onClick)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 40)
    b.BackgroundColor3 = color or C.card
    b.BackgroundTransparency = 0.15
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 13
    b.Parent = parent
    corner(b, 10)
    stroke(b, color or C.stroke, 1, 0.4)
    b.MouseEnter:Connect(function()
        local hc = color or C.card
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundTransparency = 0.05,
            BackgroundColor3 = Color3.fromRGB(
                math.min(255, hc.R * 255 + 25),
                math.min(255, hc.G * 255 + 25),
                math.min(255, hc.B * 255 + 25)
            )
        }):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundTransparency = 0.15,
            BackgroundColor3 = color or C.card
        }):Play()
    end)
    if onClick then b.MouseButton1Click:Connect(onClick) end
    return b
end

local isTraining, trainThread = false, nil
local trainCount, totalCount = 0, tonumber(Config.TotalReps) or 0
local startTime = 0
local sessionStartStrength = nil
local flying, flyBV, flyBG = false, nil, nil
local flySpeed = Config.FlySpeed or 50
local startAutoTrain, stopAutoTrain, updateStartBtn
local startFly, stopFly, applyWalkSpeed

local pendingRebirth = false
local pendingRebirthStart = 0
local pendingRebirthLastValue = 0

local MobileInput = { Forward = false, Back = false, Left = false, Right = false, Up = false, Down = false }

makeNavBtn("📊", "总览", "overview")
makeNavBtn("💪", "训练", "training")
makeNavBtn("🔄", "重生", "rebirth")
makeNavBtn("⚡", "移动", "move")
makeNavBtn("⚙", "设置", "settings")

local overview = makePage("overview")

local overviewDataCard = makeCard(overview, 0)
overviewDataCard.AutomaticSize = Enum.AutomaticSize.Y
local overviewDataLayout = Instance.new("UIListLayout")
overviewDataLayout.Padding = UDim.new(0, 6)
overviewDataLayout.Parent = overviewDataCard
local overviewDataPad = Instance.new("UIPadding")
overviewDataPad.PaddingTop = UDim.new(0, 12)
overviewDataPad.PaddingBottom = UDim.new(0, 12)
overviewDataPad.PaddingLeft = UDim.new(0, 10)
overviewDataPad.PaddingRight = UDim.new(0, 10)
overviewDataPad.Parent = overviewDataCard

local overviewTitle = Instance.new("TextLabel")
overviewTitle.Size = UDim2.new(1, 0, 0, 18)
overviewTitle.BackgroundTransparency = 1
overviewTitle.Text = "力量数据"
overviewTitle.TextColor3 = C.text
overviewTitle.TextXAlignment = Enum.TextXAlignment.Left
overviewTitle.Font = Enum.Font.GothamBold
overviewTitle.TextSize = 13
overviewTitle.LayoutOrder = 1
overviewTitle.ZIndex = 13
overviewTitle.Parent = overviewDataCard

local rowStrength = makeDataRow(overviewDataCard, "当前力量", C.accent)
rowStrength.Parent.LayoutOrder = 2
local rowSession  = makeDataRow(overviewDataCard, "本次增长", C.green)
rowSession.Parent.LayoutOrder = 3
local rowBefore   = makeDataRow(overviewDataCard, "训练前", C.textDim)
rowBefore.Parent.LayoutOrder = 4
local rowPerRep   = makeDataRow(overviewDataCard, "每次增量", C.textDim)
rowPerRep.Parent.LayoutOrder = 5

local overviewStatCard = makeCard(overview, 0)
overviewStatCard.AutomaticSize = Enum.AutomaticSize.Y
local overviewStatLayout = Instance.new("UIListLayout")
overviewStatLayout.Padding = UDim.new(0, 6)
overviewStatLayout.Parent = overviewStatCard
local overviewStatPad = Instance.new("UIPadding")
overviewStatPad.PaddingTop = UDim.new(0, 12)
overviewStatPad.PaddingBottom = UDim.new(0, 12)
overviewStatPad.PaddingLeft = UDim.new(0, 10)
overviewStatPad.PaddingRight = UDim.new(0, 10)
overviewStatPad.Parent = overviewStatCard

local overviewStatTitle = Instance.new("TextLabel")
overviewStatTitle.Size = UDim2.new(1, 0, 0, 18)
overviewStatTitle.BackgroundTransparency = 1
overviewStatTitle.Text = "训练统计"
overviewStatTitle.TextColor3 = C.text
overviewStatTitle.TextXAlignment = Enum.TextXAlignment.Left
overviewStatTitle.Font = Enum.Font.GothamBold
overviewStatTitle.TextSize = 13
overviewStatTitle.LayoutOrder = 1
overviewStatTitle.ZIndex = 13
overviewStatTitle.Parent = overviewStatCard

local statSession = makeDataRow(overviewStatCard, "本次训练", C.text)
statSession.Parent.LayoutOrder = 2
local statTotal = makeDataRow(overviewStatCard, "累计训练", C.text)
statTotal.Parent.LayoutOrder = 3
local statRate = makeDataRow(overviewStatCard, "每秒平均", C.text)
statRate.Parent.LayoutOrder = 4

-- ================== 新增：累计总数据卡片 ==================
local overviewTotalCard = makeCard(overview, 0)
overviewTotalCard.AutomaticSize = Enum.AutomaticSize.Y
local overviewTotalLayout = Instance.new("UIListLayout")
overviewTotalLayout.Padding = UDim.new(0, 6)
overviewTotalLayout.Parent = overviewTotalCard
local overviewTotalPad = Instance.new("UIPadding")
overviewTotalPad.PaddingTop = UDim.new(0, 12)
overviewTotalPad.PaddingBottom = UDim.new(0, 12)
overviewTotalPad.PaddingLeft = UDim.new(0, 10)
overviewTotalPad.PaddingRight = UDim.new(0, 10)
overviewTotalPad.Parent = overviewTotalCard

local overviewTotalTitle = Instance.new("TextLabel")
overviewTotalTitle.Size = UDim2.new(1, 0, 0, 18)
overviewTotalTitle.BackgroundTransparency = 1
overviewTotalTitle.Text = "📊 累计总数据"
overviewTotalTitle.TextColor3 = C.accent -- 蓝色主题
overviewTotalTitle.TextXAlignment = Enum.TextXAlignment.Left
overviewTotalTitle.Font = Enum.Font.GothamBold
overviewTotalTitle.TextSize = 13
overviewTotalTitle.LayoutOrder = 1
overviewTotalTitle.ZIndex = 13
overviewTotalTitle.Parent = overviewTotalCard

local rowTotalReps = makeDataRow(overviewTotalCard, "总训练次数", C.accent)
rowTotalReps.Parent.LayoutOrder = 2

local rowTotalRebirth = makeDataRow(overviewTotalCard, "总转生次数", C.accent)
rowTotalRebirth.Parent.LayoutOrder = 3

local rowTotalTime = makeDataRow(overviewTotalCard, "总运行时长", C.accent)
rowTotalTime.Parent.LayoutOrder = 4
-- =======================================================

local training = makePage("training")

local actionCard = makeCard(training, 50)
local actionTitle = Instance.new("TextLabel")
actionTitle.Size = UDim2.new(0.4, -10, 1, 0)
actionTitle.Position = UDim2.new(0, 14, 0, 0)
actionTitle.BackgroundTransparency = 1
actionTitle.Text = "动作"
actionTitle.TextColor3 = C.text
actionTitle.TextXAlignment = Enum.TextXAlignment.Left
actionTitle.Font = Enum.Font.GothamBold
actionTitle.TextSize = 12
actionTitle.ZIndex = 13
actionTitle.Parent = actionCard

local actionBtn = Instance.new("TextButton")
actionBtn.Size = UDim2.new(0.55, -14, 0, 32)
actionBtn.Position = UDim2.new(0.45, 0, 0.5, -16)
actionBtn.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
actionBtn.Text = ActionNames[Config.Action] or Config.Action
actionBtn.TextColor3 = C.accent
actionBtn.Font = Enum.Font.GothamBold
actionBtn.TextSize = 13
actionBtn.AutoButtonColor = false
actionBtn.BorderSizePixel = 0
actionBtn.ZIndex = 13
actionBtn.Parent = actionCard
corner(actionBtn, 6)
stroke(actionBtn, Color3.fromRGB(60, 80, 110), 1, 0.5)

local actionIndex = 1
for i, v in ipairs(Actions) do
    if v == Config.Action then actionIndex = i break end
end

actionBtn.MouseEnter:Connect(function()
    TweenService:Create(actionBtn, TweenInfo.new(0.15), {BackgroundColor3 = C.cardHover}):Play()
end)
actionBtn.MouseLeave:Connect(function()
    TweenService:Create(actionBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 24, 34)}):Play()
end)
actionBtn.MouseButton1Click:Connect(function()
    actionIndex = actionIndex % #Actions + 1
    Config.Action = Actions[actionIndex]
    actionBtn.Text = ActionNames[Config.Action] or Config.Action
    saveConfig()
end)

makeNumberInput(training, "训练间隔", "Interval", MIN_INTERVAL, MAX_INTERVAL, nil)

local startBtn = makeAction(training, "▶  开始训练", C.green, nil)

updateStartBtn = function()
    if isTraining then
        startBtn.Text = "■  停止训练"
        startBtn.BackgroundColor3 = C.red
    else
        startBtn.Text = "▶  开始训练"
        startBtn.BackgroundColor3 = C.green
    end
end

local rebirth = makePage("rebirth")

makeToggle(rebirth, "自动重生", "达到重生门槛后自动发送 RebirthEvent", "AutoRebirth")
makeToggle(rebirth, "反挂机", "防止因长时间无操作被踢出", "AntiAfk")
makeToggle(rebirth, "自动重置", "定时重置角色", "AutoReset")

local countCard = makeCard(rebirth, 70)
local countTitle = Instance.new("TextLabel")
countTitle.Size = UDim2.new(1, -28, 0, 18)
countTitle.Position = UDim2.new(0, 14, 0, 8)
countTitle.BackgroundTransparency = 1
countTitle.Text = "自定义重生次数"
countTitle.TextColor3 = C.text
countTitle.TextXAlignment = Enum.TextXAlignment.Left
countTitle.Font = Enum.Font.GothamBold
countTitle.TextSize = 12
countTitle.ZIndex = 13
countTitle.Parent = countCard

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 30, 0, 28)
minusBtn.Position = UDim2.new(0, 14, 0, 32)
minusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
minusBtn.Text = "−"
minusBtn.TextColor3 = C.red
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 16
minusBtn.AutoButtonColor = false
minusBtn.BorderSizePixel = 0
minusBtn.ZIndex = 13
minusBtn.Parent = countCard
corner(minusBtn, 6)

local countBox = Instance.new("TextBox")
countBox.Size = UDim2.new(1, -92, 0, 28)
countBox.Position = UDim2.new(0, 48, 0, 32)
countBox.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
countBox.Text = tostring(Config.AutoRebirthCount)
countBox.TextColor3 = C.accent
countBox.Font = Enum.Font.Code
countBox.TextSize = 13
countBox.ClearTextOnFocus = false
countBox.BorderSizePixel = 0
countBox.ZIndex = 13
countBox.Parent = countCard
corner(countBox, 6)
stroke(countBox, Color3.fromRGB(60, 80, 110), 1, 0.5)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 30, 0, 28)
plusBtn.Position = UDim2.new(1, -44, 0, 32)
plusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
plusBtn.Text = "+"
plusBtn.TextColor3 = C.green
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 16
plusBtn.AutoButtonColor = false
plusBtn.BorderSizePixel = 0
plusBtn.ZIndex = 13
plusBtn.Parent = countCard
corner(plusBtn, 6)

local updateRebirthDisplay

local function commitCount(n)
    n = math.clamp(math.floor(tonumber(n) or 0), 0, 99999)
    Config.AutoRebirthCount = n
    countBox.Text = tostring(n)
    saveConfig()
    if updateRebirthDisplay then updateRebirthDisplay() end
end

minusBtn.MouseButton1Click:Connect(function()
    local step = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 10 or 1
    commitCount(Config.AutoRebirthCount - step)
end)
plusBtn.MouseButton1Click:Connect(function()
    local step = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 10 or 1
    commitCount(Config.AutoRebirthCount + step)
end)
countBox.FocusLost:Connect(function()
    local n = tonumber(countBox.Text)
    if n and n >= 0 and n <= 99999 then
        commitCount(n)
    else
        countBox.Text = tostring(Config.AutoRebirthCount)
        notify("范围 0 ~ 99999", C.red)
    end
end)

local progressCard = makeCard(rebirth, 70)
local progressTitle = Instance.new("TextLabel")
progressTitle.Size = UDim2.new(1, -28, 0, 18)
progressTitle.Position = UDim2.new(0, 14, 0, 8)
progressTitle.BackgroundTransparency = 1
progressTitle.Text = "重生进度"
progressTitle.TextColor3 = C.text
progressTitle.TextXAlignment = Enum.TextXAlignment.Left
progressTitle.Font = Enum.Font.GothamBold
progressTitle.TextSize = 12
progressTitle.ZIndex = 13
progressTitle.Parent = progressCard

local doneLbl = Instance.new("TextLabel")
doneLbl.Size = UDim2.new(0.5, 0, 0, 24)
doneLbl.Position = UDim2.new(0, 14, 0, 32)
doneLbl.BackgroundTransparency = 1
doneLbl.Text = "0"
doneLbl.TextColor3 = C.green
doneLbl.TextXAlignment = Enum.TextXAlignment.Left
doneLbl.Font = Enum.Font.GothamBold
doneLbl.TextSize = 16
doneLbl.ZIndex = 13
doneLbl.Parent = progressCard

local targetLbl = Instance.new("TextLabel")
targetLbl.Size = UDim2.new(0.5, -14, 0, 24)
targetLbl.Position = UDim2.new(0.5, 0, 0, 32)
targetLbl.BackgroundTransparency = 1
targetLbl.Text = "∞"
targetLbl.TextColor3 = C.accent
targetLbl.TextXAlignment = Enum.TextXAlignment.Right
targetLbl.Font = Enum.Font.GothamBold
targetLbl.TextSize = 16
targetLbl.ZIndex = 13
targetLbl.Parent = progressCard

updateRebirthDisplay = function()
    doneLbl.Text = tostring(Config.AutoRebirthDone)
    if Config.AutoRebirthCount == 0 then
        targetLbl.Text = "∞"
    else
        targetLbl.Text = tostring(Config.AutoRebirthCount)
    end
end
updateRebirthDisplay()

makeAction(rebirth, "重置计数", C.card, function()
    Config.AutoRebirthDone = 0
    saveConfig()
    updateRebirthDisplay()
    notify("计数已重置", C.accent)
end)

local move = makePage("move")

makeToggle(move, "飞行模式", "开启后可自由飞行", "Fly", function(on)
    if on then
        startFly()
        if IS_TOUCH then
            notify("飞行开启 — 方向键", C.accent)
        else
            notify("飞行开启 — 空格/左Ctrl", C.accent)
        end
    else
        stopFly()
        notify("飞行关闭", C.red)
    end
end)

makeNumberInput(move, "步行速度", "WalkSpeed", 16, 500, function(v)
    Config.WalkSpeed = v
    applyWalkSpeed()
end)

makeNumberInput(move, "飞行速度", "FlySpeed", 10, 500, function(v)
    flySpeed = v
end)

local settings = makePage("settings")

makeToggle(settings, "通知提示", "打开或关闭所有通知弹窗", "Notifications")
makeToggle(settings, "自动启动", "打开后游戏启动时自动开始训练", "AutoStart")

makeAction(settings, "重置所有设置", C.red, function()
    Config.Interval = 0.1
    Config.WalkSpeed = 16
    Config.FlySpeed = 50
    Config.AutoRebirthCount = 0
    Config.AutoRebirthDone = 0
    Config.TotalReps = 0
    saveConfig()
    notify("已重置设置", C.accent)
end)

makeInfoCard(settings, "力量之冠封存 v1.0", {
    "基于 WindUI 风格的手机布局",
    "支持触控和实时数据刷新",
    "所有功能保留，UI 全部重构"
})

showPage("overview")

local mainDrag = false
local mainStart = nil
local mainOrigin = nil

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        mainDrag = true
        mainStart = input.Position
        mainOrigin = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                mainDrag = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if mainDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - mainStart
        Main.Position = UDim2.new(
            mainOrigin.X.Scale, mainOrigin.X.Offset + delta.X,
            mainOrigin.Y.Scale, mainOrigin.Y.Offset + delta.Y
        )
    end
end)

local MiniBar = Instance.new("TextButton")
MiniBar.Size = UDim2.new(0, 220, 0, 42)
MiniBar.Position = UDim2.new(0.5, -110, 0, 20)
MiniBar.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
MiniBar.BackgroundTransparency = 0.1
MiniBar.Text = ""
MiniBar.AutoButtonColor = false
MiniBar.BorderSizePixel = 0
MiniBar.Visible = false
MiniBar.ZIndex = 100
MiniBar.Parent = SG
corner(MiniBar, 21)
stroke(MiniBar, Color3.fromRGB(80, 150, 220), 1.2, 0.3)

local MiniCat = Instance.new("Frame")
MiniCat.Size = UDim2.new(0, 30, 0, 30)
MiniCat.Position = UDim2.new(0, 8, 0.5, -15)
MiniCat.BackgroundTransparency = 1
MiniCat.ZIndex = 101
MiniCat.Parent = MiniBar
drawCatFace(MiniCat, 15, 15, 0.28, 0, 102)

local miniText = Instance.new("TextLabel")
miniText.Size = UDim2.new(1, -50, 1, 0)
miniText.Position = UDim2.new(0, 46, 0, 0)
miniText.BackgroundTransparency = 1
miniText.Text = "力量之冠封存"
miniText.TextColor3 = Color3.fromRGB(230, 230, 235)
miniText.Font = Enum.Font.GothamBold
miniText.TextSize = 14
miniText.TextXAlignment = Enum.TextXAlignment.Left
miniText.ZIndex = 101
miniText.Parent = MiniBar

local miniDrag = false
local miniMoved = false
local miniStart = nil
local miniOrigin = nil

MiniBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        miniDrag = true
        miniMoved = false
        miniStart = input.Position
        miniOrigin = MiniBar.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                miniDrag = false
                if not miniMoved then
                    MiniBar.Visible = false
                    Main.Visible = true
                    Main.Size = UDim2.new(0, 0, 0, 0)
                    TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
                        Size = UDim2.new(0, W, 0, H)
                    }):Play()
                end
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if miniDrag and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - miniStart
        if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then
            miniMoved = true
        end
        MiniBar.Position = UDim2.new(
            miniOrigin.X.Scale, miniOrigin.X.Offset + delta.X,
            miniOrigin.Y.Scale, miniOrigin.Y.Offset + delta.Y
        )
    end
end)

MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    MiniBar.Visible = true
end)

local ConfirmOverlay = Instance.new("Frame")
ConfirmOverlay.Size = UDim2.new(1, 0, 1, 0)
ConfirmOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ConfirmOverlay.BackgroundTransparency = 0.5
ConfirmOverlay.BorderSizePixel = 0
ConfirmOverlay.Visible = false
ConfirmOverlay.ZIndex = 200
ConfirmOverlay.Parent = Main

local ConfirmBox = Instance.new("Frame")
ConfirmBox.Size = UDim2.new(0, 360, 0, 180)
ConfirmBox.Position = UDim2.new(0.5, -180, 0.5, -90)
ConfirmBox.BackgroundColor3 = Color3.fromRGB(30, 34, 46)
ConfirmBox.BorderSizePixel = 0
ConfirmBox.ZIndex = 201
ConfirmBox.Parent = ConfirmOverlay
corner(ConfirmBox, 14)
stroke(ConfirmBox, Color3.fromRGB(80, 100, 130), 1, 0.3)

local ConfirmTitle = Instance.new("TextLabel")
ConfirmTitle.Size = UDim2.new(1, -32, 0, 30)
ConfirmTitle.Position = UDim2.new(0, 20, 0, 22)
ConfirmTitle.BackgroundTransparency = 1
ConfirmTitle.Text = "确认关闭"
ConfirmTitle.TextColor3 = C.text
ConfirmTitle.TextXAlignment = Enum.TextXAlignment.Left
ConfirmTitle.Font = Enum.Font.GothamBold
ConfirmTitle.TextSize = 18
ConfirmTitle.ZIndex = 202
ConfirmTitle.Parent = ConfirmBox

local ConfirmDesc = Instance.new("TextLabel")
ConfirmDesc.Size = UDim2.new(1, -32, 0, 50)
ConfirmDesc.Position = UDim2.new(0, 20, 0, 60)
ConfirmDesc.BackgroundTransparency = 1
ConfirmDesc.Text = "确定要关闭当前界面吗？关闭后将无法再次打开。"
ConfirmDesc.TextColor3 = C.textDim
ConfirmDesc.TextXAlignment = Enum.TextXAlignment.Left
ConfirmDesc.TextYAlignment = Enum.TextYAlignment.Top
ConfirmDesc.TextWrapped = true
ConfirmDesc.Font = Enum.Font.Gotham
ConfirmDesc.TextSize = 12
ConfirmDesc.ZIndex = 202
ConfirmDesc.Parent = ConfirmBox

local function confirmBtn(text, x, w, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, w, 0, 36)
    b.Position = UDim2.new(1, x, 1, -52)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 202
    b.Parent = ConfirmBox
    corner(b, 8)
    return b
end

local CancelBtn = confirmBtn("点错了", -284, 130, Color3.fromRGB(70, 70, 80))
local CloseConfirmBtn = confirmBtn("关闭", -144, 130, Color3.fromRGB(200, 60, 70))

CancelBtn.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = false
end)
CloseConfirmBtn.MouseButton1Click:Connect(function()
    SG:Destroy()
end)
CloseBtn.MouseButton1Click:Connect(function()
    ConfirmOverlay.Visible = true
end)

startAutoTrain = function()
    if isTraining then return end
    if not TrainEvent then notify("未找到训练事件", C.red) return end
    isTraining = true
    trainCount = 0
    startTime = tick()
    refreshAllStats()
    if hasStatSource("Strength") then
        sessionStartStrength = getStat("Strength")
    end
    trainThread = task.spawn(function()
        while isTraining and SG.Parent do
            local ok = pcall(function() TrainEvent:FireServer(Config.Action) end)
            if ok then
                trainCount = trainCount + 1
                totalCount = totalCount + 1
                Config.TotalReps = totalCount
            end
            task.wait(Config.Interval)
        end
        if isTraining then isTraining = false end
    end)
    updateStartBtn()
end

stopAutoTrain = function()
    if not isTraining then return end
    isTraining = false
    if trainThread then
        pcall(task.cancel, trainThread)
        trainThread = nil
    end
    saveConfig()
    updateStartBtn()
end

startBtn.MouseButton1Click:Connect(function()
    if isTraining then
        stopAutoTrain()
        notify("训练已停止", C.red)
    else
        startAutoTrain()
        if isTraining then notify("训练已开始", C.green) end
    end
    updateStartBtn()
end)

applyWalkSpeed = function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = Config.WalkSpeed end
end

local FlyControls = Instance.new("Frame")
FlyControls.Size = UDim2.new(0, 170, 0, 104)
FlyControls.Position = UDim2.new(0.5, -85, 1, -120)
FlyControls.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
FlyControls.BackgroundTransparency = 0.2
FlyControls.Visible = false
FlyControls.ZIndex = 30
FlyControls.Parent = SG
corner(FlyControls, 8)
stroke(FlyControls, C.accent, 1.2, 0.3)

local function flyButton(text, x, y, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 34, 0, 34)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    b.Text = text
    b.TextColor3 = color or C.accent
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 31
    b.Parent = FlyControls
    corner(b, 6)
    return b
end

local BtnUp    = flyButton("▲", 42, 4, C.accent)
local BtnDown  = flyButton("▼", 42, 66, Color3.fromRGB(180, 120, 255))
local BtnLeft  = flyButton("◀", 4, 35, C.accent)
local BtnRight = flyButton("▶", 80, 35, C.accent)
local BtnRise  = flyButton("＋", 118, 4, C.green)
local BtnFall  = flyButton("－", 118, 66, C.red)

local function bindHold(btn, key)
    local function set(v)
        MobileInput[key] = v
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = v and 0.6 or 0}):Play()
    end
    btn.MouseButton1Down:Connect(function() set(true) end)
    btn.MouseButton1Up:Connect(function() set(false) end)
    btn.MouseLeave:Connect(function() set(false) end)
end

bindHold(BtnUp, "Forward")
bindHold(BtnDown, "Back")
bindHold(BtnLeft, "Left")
bindHold(BtnRight, "Right")
bindHold(BtnRise, "Up")
bindHold(BtnFall, "Down")

startFly = function()
    if flying then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end

    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 3000
    flyBG.D = 500
    flyBG.Parent = hrp

    flying = true
end

stopFly = function()
    if not flying then return end
    flying = false
    for k in pairs(MobileInput) do MobileInput[k] = false end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    applyWalkSpeed()
end

RunService.RenderStepped:Connect(function()
    if not flying then return end
    local char = LP.Character
    if not char then stopFly() return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not flyBV or not flyBG then return end

    local cam = workspace.CurrentCamera
    local dir = Vector3.zero

    local fwd = UserInputService:IsKeyDown(Enum.KeyCode.W) or MobileInput.Forward
    local bck = UserInputService:IsKeyDown(Enum.KeyCode.S) or MobileInput.Back
    local lft = UserInputService:IsKeyDown(Enum.KeyCode.A) or MobileInput.Left
    local rgt = UserInputService:IsKeyDown(Enum.KeyCode.D) or MobileInput.Right
    local up  = UserInputService:IsKeyDown(Enum.KeyCode.Space) or MobileInput.Up
    local dn  = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or MobileInput.Down

    if fwd then dir = dir + cam.CFrame.LookVector end
    if bck then dir = dir - cam.CFrame.LookVector end
    if lft then dir = dir - cam.CFrame.RightVector end
    if rgt then dir = dir + cam.CFrame.RightVector end
    if up  then dir = dir + Vector3.new(0, 1, 0) end
    if dn  then dir = dir - Vector3.new(0, 1, 0) end

    if dir.Magnitude > 0 then dir = dir.Unit * flySpeed end
    flyBV.Velocity = dir
    flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    applyWalkSpeed()
    if flying then
        flying = false
        if flyBV then flyBV:Destroy(); flyBV = nil end
        if flyBG then flyBG:Destroy(); flyBG = nil end
        if Config.Fly then startFly() end
    end
end)

task.spawn(function()
    while SG.Parent do
        local elapsed = isTraining and (tick() - startTime) or 0
        local aps = elapsed > 0 and (trainCount / elapsed) or 0
        statSession.Text = tostring(trainCount)
        statTotal.Text = tostring(totalCount)
        statRate.Text = string.format("%.2f", aps)

        -- ============ 更新总数据 ============
        rowTotalReps.Text = fmt(totalCount)
        rowTotalRebirth.Text = fmt(Config.AutoRebirthDone)
        
        -- 计算总运行时长
        local elapsedTime = tick() - ScriptStartTime
        local hours = math.floor(elapsedTime / 3600)
        local mins = math.floor((elapsedTime % 3600) / 60)
        local secs = math.floor(elapsedTime % 60)
        rowTotalTime.Text = string.format("%02d:%02d:%02d", hours, mins, secs)
        -- ====================================

        refreshAllStats()
        local curStrength = getStat("Strength")
        if sessionStartStrength == nil then sessionStartStrength = curStrength end
        local gain = curStrength - sessionStartStrength

        rowStrength.Text = fmt(curStrength)
        rowSession.Text = (gain >= 0 and "+" or "") .. fmt(gain)
        rowBefore.Text = fmt(sessionStartStrength)
        rowSession.TextColor3 = gain > 0 and C.green or (gain < 0 and C.red or C.text)

        if trainCount > 0 and gain > 0 then
            rowPerRep.Text = string.format("%.2f", gain / trainCount)
        else
            rowPerRep.Text = "—"
        end

        task.wait(0.5)
    end
end)

local function fireAntiAfk()
    if not Config.AntiAfk then return end
    if pcall(function()
        VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, true, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, false, false, game)
    end) then return end
    pcall(function()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

LP.Idled:Connect(fireAntiAfk)

task.spawn(function()
    while SG.Parent do
        task.wait(60)
        if Config.AntiAfk then fireAntiAfk() end
    end
end)

task.spawn(function()
    while SG.Parent do
        task.wait(0.5)
        if pendingRebirth then
            refreshAllStats()
            if hasStatSource("Rebirth") then
                local cur = getStat("Rebirth")
                if cur > pendingRebirthLastValue then
                    pendingRebirth = false
                    Config.AutoRebirthDone = Config.AutoRebirthDone + 1
                    saveConfig()
                    updateRebirthDisplay()
                elseif tick() - pendingRebirthStart > REBIRTH_TIMEOUT then
                    pendingRebirth = false
                    notify("重生超时", C.red)
                end
            else
                pendingRebirth = false
            end
        end
    end
end)

task.spawn(function()
    while SG.Parent do
        task.wait(Config.AutoRebirthDelay)
        if Config.AutoRebirth and RebirthEvent and not pendingRebirth then
            local target = Config.AutoRebirthCount
            local done = Config.AutoRebirthDone

            if target > 0 and done >= target then
                Config.AutoRebirth = false
                saveConfig()
                notify("已达成目标 " .. target .. " 次", C.green)
            else
                refreshAllStats()
                local hasRebirthStat = hasStatSource("Rebirth")
                if hasRebirthStat then
                    pendingRebirthLastValue = getStat("Rebirth")
                    pendingRebirth = true
                    pendingRebirthStart = tick()
                end
                pcall(function() RebirthEvent:FireServer("Start") end)
                task.wait(0.5)
                pcall(function() RebirthEvent:FireServer("Update") end)
                if not hasRebirthStat then
                    Config.AutoRebirthDone = done + 1
                    saveConfig()
                    updateRebirthDisplay()
                end
            end
        end
    end
end)

task.spawn(function()
    while SG.Parent do
        task.wait(Config.AutoResetInterval)
        if Config.AutoReset then
            pcall(function()
                local char = LP.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 else char:BreakJoints() end
                end
            end)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        Main.Visible = not Main.Visible
    elseif input.KeyCode == Enum.KeyCode.RightShift then
        if isTraining then
            stopAutoTrain()
            notify("训练已停止", C.red)
        else
            startAutoTrain()
            if isTraining then notify("训练已开始", C.green) end
        end
        updateStartBtn()
    end
end)

updateStartBtn()
refreshAllStats()
applyWalkSpeed()

if Config.AutoStart then
    startAutoTrain()
    updateStartBtn()
end

if Config.Fly then
    task.defer(function()
        startFly()
    end)
end

if Config.MinimizeOnStart then
    task.defer(function()
        Main.Visible = false
        MiniBar.Visible = true
    end)
end

notify("力量之冠封存 — 已启动", C.accent)