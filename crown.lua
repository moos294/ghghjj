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
    accentDim = Color3.fromRGB(40, 100, 160),
    text = Color3.fromRGB(230, 230, 235),
    textDim = Color3.fromRGB(150, 150, 160),
    textSub = Color3.fromRGB(100, 100, 110),
    green = Color3.fromRGB(0, 200, 140),
    red = Color3.fromRGB(220, 70, 80),
}

local old = LP.PlayerGui:FindFirstChild("PumpLabUI")
if old then old:Destroy() end
pcall(function()
    local cg = game:GetService("CoreGui"):FindFirstChild("PumpLabUI")
    if cg then cg:Destroy() end
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
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local W, H = 680, 420

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
TopBar.Parent = Main

local TopTitle = Instance.new("TextLabel")
TopTitle.Size = UDim2.new(0, 400, 1, 0)
TopTitle.Position = UDim2.new(0, 20, 0, 0)
TopTitle.BackgroundTransparency = 1
TopTitle.Text = "PUMP LAB  |  力量助手 v1.2"
TopTitle.TextColor3 = C.text
TopTitle.TextXAlignment = Enum.TextXAlignment.Left
TopTitle.Font = Enum.Font.GothamBold
TopTitle.TextSize = 15
TopTitle.Parent = TopBar

local TopSub = Instance.new("TextLabel")
TopSub.Size = UDim2.new(0, 400, 0, 12)
TopSub.Position = UDim2.new(0, 20, 1, -16)
TopSub.BackgroundTransparency = 1
TopSub.Text = "log-based build · mobile ready"
TopSub.TextColor3 = C.textSub
TopSub.TextXAlignment = Enum.TextXAlignment.Left
TopSub.Font = Enum.Font.Gotham
TopSub.TextSize = 10
TopSub.Parent = TopBar

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
    b.Parent = TopBar
    corner(b, 6)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = C.cardHover end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = C.card end)
    return b
end

local CloseBtn = topBtn("×", -16, true)
local MinBtn = topBtn("−", -56, false)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, -44)
Sidebar.Position = UDim2.new(0, 0, 0, 44)
Sidebar.BackgroundColor3 = C.sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local NavList = Instance.new("UIListLayout")
NavList.Padding = UDim.new(0, 6)
NavList.SortOrder = Enum.SortOrder.LayoutOrder
NavList.Parent = Sidebar

local NavPad = Instance.new("UIPadding")
NavPad.PaddingTop = UDim.new(0, 12)
NavPad.PaddingLeft = UDim.new(0, 10)
NavPad.PaddingRight = UDim.new(0, 10)
NavPad.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -160, 1, -44)
Content.Position = UDim2.new(0, 160, 0, 44)
Content.BackgroundColor3 = C.bg
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
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
    p.Parent = Content

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 16)
    pad.PaddingBottom = UDim.new(0, 16)
    pad.PaddingLeft = UDim.new(0, 18)
    pad.PaddingRight = UDim.new(0, 18)
    pad.Parent = p

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = p

    pages[name] = p
    return p
end

local function makeNavBtn(icon, label, pageName)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 38)
    b.BackgroundColor3 = C.card
    b.Text = "  " .. icon .. "   " .. label
    b.TextColor3 = C.textDim
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.LayoutOrder = #navButtons + 1
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
    card.Size = UDim2.new(1, 0, 0, height or 64)
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    card.Parent = parent
    corner(card, 10)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -110, 0, 20)
    t.Position = UDim2.new(0, 16, 0, 12)
    t.BackgroundTransparency = 1
    t.Text = title
    t.TextColor3 = C.text
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Font = Enum.Font.GothamBold
    t.TextSize = 14
    t.Parent = card

    if desc then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, -32, 0, 32)
        d.Position = UDim2.new(0, 16, 0, 32)
        d.BackgroundTransparency = 1
        d.Text = desc
        d.TextColor3 = C.textDim
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextYAlignment = Enum.TextYAlignment.Top
        d.TextWrapped = true
        d.Font = Enum.Font.Gotham
        d.TextSize = 11
        d.Parent = card
    end

    return card
end

local function makeToggle(parent, title, desc)
    local card = makeCard(parent, title, desc, 64)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 22)
    track.Position = UDim2.new(1, -56, 0, 20)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
    track.BorderSizePixel = 0
    track.Parent = card
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(240, 240, 245)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 9)

    local on = false
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text = ""
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
    local card = makeCard(parent, title, desc, 72)

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 60, 0, 24)
    valLabel.Position = UDim2.new(1, -180, 0, 18)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(defaultVal)
    valLabel.TextColor3 = C.text
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 14
    valLabel.Parent = card

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 100, 0, 4)
    barBg.Position = UDim2.new(1, -110, 0, 28)
    barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 68)
    barBg.BorderSizePixel = 0
    barBg.Parent = card
    corner(barBg, 2)

    local fill = Instance.new("Frame")
    local pct = (defaultVal - minV) / (maxV - minV)
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BackgroundColor3 = C.accent
    fill.BorderSizePixel = 0
    fill.Parent = barBg
    corner(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 3
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
    b.Size = UDim2.new(1, 0, 0, 44)
    b.BackgroundColor3 = color or C.card
    b.Text = text
    b.TextColor3 = C.text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.Parent = parent
    corner(b, 10)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.15), {
            BackgroundColor3 = color and Color3.fromRGB(
                math.min(255, color.R * 255 + 20),
                math.min(255, color.G * 255 + 20),
                math.min(255, color.B * 255 + 20)
            ) or C.cardHover
        }):Play()
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
    card.Parent = parent
    corner(card, 10)

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 14)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.PaddingLeft = UDim.new(0, 16)
    pad.PaddingRight = UDim.new(0, 16)
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
makeAction(overview, "查看当前属性快照", C.card)
makeAction(overview, "紧急停止：锻炼 + 转生", C.red)
makeToggle(overview, "显示可拖动实时状态卡", "在屏幕右上角显示力量、宝石、速度、转生、生命和训练请求次数。")
makeAction(overview, "刷新服务器转生要求", C.card)

local training = makePage("training")
makeInfoCard(training, "自动锻炼控制", {"调整锻炼频率与自动触发模式。"})
makeSlider(training, "锻炼频率（次/秒）", "限制在 1 到 30 次/秒。", 8, 1, 30)
makeToggle(training, "自动锻炼", "循环触发当前已装备工具，直接开始自动锻炼。")
makeToggle(training, "被动锻炼", "不检查工具和当前锻炼状态，直接发送训练请求。")
makeAction(training, "手动锻炼一次", C.card)
makeAction(training, "停止自动锻炼", C.red)

local rebirth = makePage("rebirth")
makeInfoCard(rebirth, "条件转生", {
    "自动读取当前力量与服务器广播的转生门槛，达标后发送 RebirthEvent Start；每次至少间隔 8 秒。"
})
makeToggle(rebirth, "自动转生", "自动读取当前力量与服务器广播的转生门槛，达标后发送请求。")
makeAction(rebirth, "手动转生", C.card)
makeAction(rebirth, "刷新下一次转生门槛", C.card)
makeInfoCard(rebirth, "注意", {
    "转生可能重置力量。自动转生仅在当前力量达到门槛后才会发送请求。"
})

local tools = makePage("tools")
makeInfoCard(tools, "手机性能优化", {"减少渲染负载，提升游戏帧率。"})
makeToggle(tools, "低特效模式", "本地关闭粒子、光束、火焰、烟雾和部分后处理；关闭时尽量恢复原状态。")
makeAction(tools, "检查 Remote 接口可用性", C.card)
makeAction(tools, "请求点数相关事件（手动）", C.card)
makeAction(tools, "输出属性快照到控制台", C.card)

local settings = makePage("settings")
makeInfoCard(settings, "设置与恢复", {"保存配置或重置界面。"})
makeAction(settings, "保存当前设置", C.card)
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

do
    local dragging, dragStart, startPos = false, nil, nil
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 160, 0, 44)
    }):Play()
    task.delay(0.2, function()
        TweenService:Create(Main, TweenInfo.new(0.2), {
            Size = UDim2.new(0, W, 0, H)
        }):Play()
    end)
end)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.2), {
        BackgroundTransparency = 1
    }):Play()
    task.wait(0.2)
    SG:Destroy()
end)