local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

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

local function makeCatIcon(parent, size, zIndex)
    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, size, 0, size)
    box.BackgroundTransparency = 1
    box.ZIndex = zIndex or 3
    box.Parent = parent

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 6, 1, 6)
    glow.Position = UDim2.new(0, -3, 0, -3)
    glow.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
    glow.BackgroundTransparency = 0.6
    glow.BorderSizePixel = 0
    glow.ZIndex = (zIndex or 3) - 1
    glow.Parent = box
    corner(glow, size)

    local head = Instance.new("Frame")
    head.Size = UDim2.new(1, 0, 1, 0)
    head.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    head.BorderSizePixel = 0
    head.ZIndex = zIndex or 3
    head.Parent = box
    corner(head, size / 2)
    stroke(head, Color3.fromRGB(120, 200, 255), 1, 0.3)

    local earL = Instance.new("Frame")
    earL.Size = UDim2.new(0, size * 0.28, 0, size * 0.28)
    earL.Position = UDim2.new(0, size * 0.08, 0, -size * 0.1)
    earL.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    earL.BorderSizePixel = 0
    earL.ZIndex = zIndex or 3
    earL.Parent = box
    corner(earL, 3)

    local earR = Instance.new("Frame")
    earR.Size = UDim2.new(0, size * 0.28, 0, size * 0.28)
    earR.Position = UDim2.new(1, -size * 0.36, 0, -size * 0.1)
    earR.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    earR.BorderSizePixel = 0
    earR.ZIndex = zIndex or 3
    earR.Parent = box
    corner(earR, 3)

    local eyeLGlow = Instance.new("Frame")
    eyeLGlow.Size = UDim2.new(0, size * 0.28, 0, size * 0.22)
    eyeLGlow.Position = UDim2.new(0, size * 0.2, 0.5, -size * 0.18)
    eyeLGlow.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    eyeLGlow.BackgroundTransparency = 0.4
    eyeLGlow.BorderSizePixel = 0
    eyeLGlow.ZIndex = zIndex or 3
    eyeLGlow.Parent = box
    corner(eyeLGlow, size / 4)

    local eyeL = Instance.new("Frame")
    eyeL.Size = UDim2.new(0, size * 0.2, 0, size * 0.14)
    eyeL.Position = UDim2.new(0, size * 0.24, 0.5, -size * 0.14)
    eyeL.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    eyeL.BorderSizePixel = 0
    eyeL.ZIndex = (zIndex or 3) + 1
    eyeL.Parent = box
    corner(eyeL, size / 4)

    local eyeRGlow = Instance.new("Frame")
    eyeRGlow.Size = UDim2.new(0, size * 0.28, 0, size * 0.22)
    eyeRGlow.Position = UDim2.new(1, -size * 0.48, 0.5, -size * 0.18)
    eyeRGlow.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    eyeRGlow.BackgroundTransparency = 0.4
    eyeRGlow.BorderSizePixel = 0
    eyeRGlow.ZIndex = zIndex or 3
    eyeRGlow.Parent = box
    corner(eyeRGlow, size / 4)

    local eyeR = Instance.new("Frame")
    eyeR.Size = UDim2.new(0, size * 0.2, 0, size * 0.14)
    eyeR.Position = UDim2.new(1, -size * 0.44, 0.5, -size * 0.14)
    eyeR.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    eyeR.BorderSizePixel = 0
    eyeR.ZIndex = (zIndex or 3) + 1
    eyeR.Parent = box
    corner(eyeR, size / 4)

    local nose = Instance.new("Frame")
    nose.Size = UDim2.new(0, size * 0.1, 0, size * 0.08)
    nose.Position = UDim2.new(0.5, -size * 0.05, 0.5, size * 0.05)
    nose.BackgroundColor3 = Color3.fromRGB(180, 130, 100)
    nose.BorderSizePixel = 0
    nose.ZIndex = (zIndex or 3) + 1
    nose.Parent = box
    corner(nose, 2)

    local bolt = Instance.new("Frame")
    bolt.Size = UDim2.new(0, size * 0.12, 0, size * 0.5)
    bolt.Position = UDim2.new(0.5, -size * 0.06, 1, -size * 0.15)
    bolt.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
    bolt.BorderSizePixel = 0
    bolt.Rotation = 25
    bolt.ZIndex = (zIndex or 3) - 1
    bolt.Parent = box
    corner(bolt, 2)

    local bolt2 = Instance.new("Frame")
    bolt2.Size = UDim2.new(0, size * 0.12, 0, size * 0.5)
    bolt2.Position = UDim2.new(0.5, -size * 0.06, 1, -size * 0.15)
    bolt2.BackgroundColor3 = Color3.fromRGB(160, 230, 255)
    bolt2.BorderSizePixel = 0
    bolt2.Rotation = -25
    bolt2.ZIndex = (zIndex or 3) - 1
    bolt2.Parent = box
    corner(bolt2, 2)

    return box
end

local W, H = 500, 320

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, W, 0, H)
Main.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true
Main.Parent = SG
corner(Main, 12)
stroke(Main, C.stroke, 1, 0.3)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 44)
TopBar.BackgroundColor3 = C.sidebar
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2
TopBar.Parent = Main

local TopLogo = Instance.new("Frame")
TopLogo.Size = UDim2.new(0, 28, 0, 28)
TopLogo.Position = UDim2.new(0, 12, 0.5, -14)
TopLogo.BackgroundTransparency = 1
TopLogo.ZIndex = 3
TopLogo.Parent = TopBar
makeCatIcon(TopLogo, 28, 4)

local TopTitle = Instance.new("TextLabel")
TopTitle.Size = UDim2.new(0, 260, 1, 0)
TopTitle.Position = UDim2.new(0, 46, 0, 0)
TopTitle.BackgroundTransparency = 1
TopTitle.Text = "力量之冠封存"
TopTitle.TextColor3 = C.text
TopTitle.TextXAlignment = Enum.TextXAlignment.Left
TopTitle.Font = Enum.Font.GothamBold
TopTitle.TextSize = 15
TopTitle.ZIndex = 3
TopTitle.Parent = TopBar

local TopSub = Instance.new("TextLabel")
TopSub.Size = UDim2.new(0, 260, 0, 12)
TopSub.Position = UDim2.new(0, 46, 1, -16)
TopSub.BackgroundTransparency = 1
TopSub.Text = "log-based build · mobile ready"
TopSub.TextColor3 = C.textSub
TopSub.TextXAlignment = Enum.TextXAlignment.Left
TopSub.Font = Enum.Font.Gotham
TopSub.TextSize = 10
TopSub.ZIndex = 3
TopSub.Parent = TopBar

local TopDeco = Instance.new("Frame")
TopDeco.Size = UDim2.new(0, 32, 0, 32)
TopDeco.Position = UDim2.new(1, -116, 0.5, -16)
TopDeco.BackgroundTransparency = 1
TopDeco.ZIndex = 3
TopDeco.Parent = TopBar
makeCatIcon(TopDeco, 32, 3)

local function topBtn(text, x, isRed)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 32, 0, 28)
    b.Position = UDim2.new(1, x, 0.5, -14)
    b.BackgroundColor3 = C.card
    b.Text = text
    b.TextColor3 = isRed and C.red or C.textDim
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 4
    b.Parent = TopBar
    corner(b, 6)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = C.cardHover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = C.card end)
    return b
end

local CloseBtn = topBtn("×", -28, true)
local MinBtn = topBtn("−", -68, false)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -44)
Sidebar.Position = UDim2.new(0, 0, 0, 44)
Sidebar.BackgroundColor3 = C.sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 2
Sidebar.Parent = Main

local SideDeco = Instance.new("Frame")
SideDeco.Size = UDim2.new(0, 50, 0, 50)
SideDeco.Position = UDim2.new(0.5, -25, 1, -56)
SideDeco.BackgroundTransparency = 1
SideDeco.ZIndex = 2
SideDeco.Parent = Sidebar
makeCatIcon(SideDeco, 50, 2)

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
Content.BackgroundColor3 = C.bg
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.ZIndex = 2
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
            TweenService:Create(b, TweenInfo.new(0.18), {BackgroundColor3 = C.accent}):Play()
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            TweenService:Create(b, TweenInfo.new(0.18), {BackgroundColor3 = C.card}):Play()
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
    p.ZIndex = 2
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
    b.Text = "  " .. icon .. "  " .. label
    b.TextColor3 = C.textDim
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 3
    b.Parent = Sidebar
    corner(b, 8)

    b.MouseEnter:Connect(function()
        if currentPage ~= pageName then
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.cardHover}):Play()
        end
    end)
    b.MouseLeave:Connect(function()
        if currentPage ~= pageName then
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.card}):Play()
        end
    end)
    b.MouseButton1Click:Connect(function() showPage(pageName) end)

    navButtons[pageName] = b
end

local function makeCard(parent, title, desc, height)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, height or 60)
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    card.ZIndex = 3
    card.Parent = parent
    corner(card, 10)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -110, 0, 20)
    t.Position = UDim2.new(0, 16, 0, 10)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = C.text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.ZIndex = 4
    t.Parent = card

    if desc then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -32, 0, 30)
        d.Position = UDim2.new(0, 16, 0, 30)
        d.BackgroundTransparency = 1
        d.Text = desc
        d.TextColor3 = C.textDim
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextYAlignment = Enum.TextYAlignment.Top
        d.TextWrapped = true
        d.Font = Enum.Font.Gotham
        d.TextSize = 11
        d.ZIndex = 4
        d.Parent = card
    end

    return card
end

local function makeToggle(parent, title, desc)
    local card = makeCard(parent, title, desc, 60)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 22)
    track.Position = UDim2.new(1, -56, 0, 19)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
    track.BorderSizePixel = 0
    track.ZIndex = 4
    track.Parent = card
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = track
    corner(knob, 9)

    local on = false
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.ZIndex = 6
    hit.Parent = card
    hit.MouseButton1Click:Connect(function()
        on = not on
        TweenService:Create(track, TweenInfo.new(0.18), {
            BackgroundColor3 = on and C.green or Color3.fromRGB(60, 60, 68)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.18), {
            Position = on and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
        }):Play()
    end)
end

local function makeSlider(parent, title, desc, defaultVal, minV, maxV)
    local card = makeCard(parent, title, desc, 68)

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 50, 0, 24)
    valLabel.Position = UDim2.new(1, -160, 0, 16)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(defaultVal)
    valLabel.TextColor3 = C.text
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 14
    valLabel.ZIndex = 4
    valLabel.Parent = card

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 90, 0, 4)
    barBg.Position = UDim2.new(1, -100, 0, 26)
    barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 4
    barBg.Parent = card
    corner(barBg, 2)

    local fill = Instance.new("Frame")
    local pct = (defaultVal - minV) / (maxV - minV)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    fill.Parent = barBg
    corner(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = barBg
    corner(knob, 7)

    local drag = false

    local function update(input)
        local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        local v = math.floor(minV + (maxV - minV) * rel + 0.5)
        valLabel.Text = tostring(v)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -7, 0.5, -7)
    end

    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
            update(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
end

local function makeAction(parent, text, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 40)
    b.BackgroundColor3 = color or C.card
    b.Text = text
    b.TextColor3 = C.text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 4
    b.Parent = parent
    corner(b, 10)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.cardHover}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = color or C.card}):Play()
    end)
    return b
end

local function makeInfoCard(parent, title, lines)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    card.ZIndex = 3
    card.Parent = parent
    corner(card, 10)

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 14)
    pad.PaddingRight = UDim.new(0, 14)
    pad.Parent = card

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = card

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, 20)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = C.text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.LayoutOrder = 1
    t.ZIndex = 4
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
        l.TextSize = 12
        l.LayoutOrder = i + 1
        l.ZIndex = 4
        l.Parent = card
    end

    return card
end

makeNavBtn("📊", "总览", "overview")
makeNavBtn("💪", "自动锻炼", "training")
makeNavBtn("🔄", "转生", "rebirth")
makeNavBtn("⚡", "性能 / 工具", "tools")
makeNavBtn("⚙", "设置 / 关于", "settings")

local overview = makePage("overview")
makeInfoCard(overview, "PUMP LAB · 力量训练控制台", {
    "已识别的游戏接口：",
    "  RebirthEvent（转生/刷新）、PointEvent（无参数事件）。",
    "  属性来自服务器的 PropertyEvent / DataEvent / UiEvent 广播。"
})
makeInfoCard(overview, "使用提示", {
    "开启自动锻炼后会自动触发当前角色已装备的可用工具。"
})
makeAction(overview, "查看当前属性快照")
makeAction(overview, "紧急停止：锻炼 + 转生", C.red)
makeToggle(overview, "显示可拖动实时状态卡", "在屏幕右上角显示力量、宝石、速度、转生、生命和训练请求次数。")
makeAction(overview, "刷新服务器转生要求")

local training = makePage("training")
makeInfoCard(training, "自动锻炼控制", {"调整锻炼频率与自动触发模式。"})
makeSlider(training, "锻炼频率（次/秒）", "限制在 1 到 30 次/秒。", 8, 1, 30)
makeToggle(training, "自动锻炼", "循环触发当前已装备工具，直接开始自动锻炼。")
makeToggle(training, "被动锻炼", "不检查工具和当前锻炼状态，直接发送训练请求。")
makeAction(training, "手动锻炼一次")
makeAction(training, "停止自动锻炼", C.red)

local rebirth = makePage("rebirth")
makeInfoCard(rebirth, "条件转生", {
    "自动读取当前力量与服务器广播的转生门槛，达标后发送 RebirthEvent Start；每次至少间隔 8 秒。"
})
makeToggle(rebirth, "自动转生", "自动读取当前力量与服务器广播的转生门槛，达标后发送请求。")
makeAction(rebirth, "手动转生")
makeAction(rebirth, "刷新下一次转生门槛")
makeInfoCard(rebirth, "注意", {
    "转生可能重置力量。自动转生仅在当前力量达到门槛后才会发送请求。"
})

local tools = makePage("tools")
makeInfoCard(tools, "手机性能优化", {"减少渲染负载，提升游戏帧率。"})
makeToggle(tools, "低特效模式", "本地关闭粒子、光束、火焰、烟雾和部分后处理；关闭时尽量恢复原状态。")
makeAction(tools, "检查 Remote 接口可用性")
makeAction(tools, "请求点数相关事件（手动）")
makeAction(tools, "输出属性快照到控制台")

local settings = makePage("settings")
makeInfoCard(settings, "设置与恢复", {"保存配置或重置界面。"})
makeAction(settings, "保存当前设置")
makeAction(settings, "重载当前 UI / 清理脚本", C.red)
makeInfoCard(settings, "版本与接口依据", {
    "PUMP LAB v1.4 · WindUI 手机布局、触控支持和实时 HUD。",
    "自动锻炼仅触发当前角色已装备的 Roblox 工具。"
})
makeInfoCard(settings, "安全 / 稳定性设计", {
    "自动锻炼默认关闭；锻炼频率限制在 1 到 30 次/秒。",
    "自动转生默认关闭并检查服务器广播门槛；提供紧急停止、配置保存和重复执行清理。"
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
MiniBar.Size = UDim2.new(0, 200, 0, 40)
MiniBar.Position = UDim2.new(0.5, -100, 0, 20)
MiniBar.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
MiniBar.Text = ""
MiniBar.AutoButtonColor = false
MiniBar.BorderSizePixel = 0
MiniBar.Visible = false
MiniBar.ZIndex = 100
MiniBar.Parent = SG
corner(MiniBar, 20)
stroke(MiniBar, Color3.fromRGB(60, 60, 68), 1, 0.3)

local miniIcon = Instance.new("Frame")
miniIcon.Size = UDim2.new(0, 28, 0, 28)
miniIcon.Position = UDim2.new(0, 8, 0.5, -14)
miniIcon.BackgroundTransparency = 1
miniIcon.ZIndex = 101
miniIcon.Parent = MiniBar
makeCatIcon(miniIcon, 28, 102)

local miniText = Instance.new("TextLabel")
miniText.Size = UDim2.new(1, -50, 1, 0)
miniText.Position = UDim2.new(0, 42, 0, 0)
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

CloseBtn.MouseButton1Click:Connect(function()
    SG:Destroy()
end)