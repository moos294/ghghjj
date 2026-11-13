--[[
================================================================
  OrigamiUI Lite  ·  纯视觉 UI 面板（无任何业务逻辑）
----------------------------------------------------------------
  作者说明：
    这是一个零依赖的纯 UI 模板，只包含界面结构与动画，
    不绑定任何 RemoteEvent、不读写任何数据、不修改游戏状态。
    你可以把内容区的占位行替换成自己的控件。

  使用方法（二选一）：
    1) Roblox Studio
       放到 StarterPlayer/StarterPlayerScripts 下，做成 LocalScript
       直接运行即可看到效果。

    2) 执行器 / 模组加载器（Delta 等）
       loadstring(readfile("/sdcard/Download/OrigamiUI_Lite.lua"))()

  可调参数都集中在下面的 CONFIG / COLOR 两个表里。
================================================================
]]

--!nolint

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- ======================== 配置区 ========================
local CONFIG = {
	-- 面板背景图 / 方块小图标的图片
	-- 若显示为空白，改成 "rbxassetid://数字ID" 或 getcustomasset("bg.jpg")
	BgImage = "rbxasset://b33a43199a0a3f7d776cac641182db83/bg.jpg",

	Title    = "ORIGAMI",
	Subtitle = "BUILD TOOL",

	PanelSize   = UDim2.fromOffset(440, 300),
	PanelCorner = 12,

	-- 缩小后的方块
	MiniSize       = 46,   -- 方块边长
	MiniCorner     = 16,   -- 圆角（约 1/3 边长，圆润但仍是方块）
	MiniIconScale  = 0.62, -- 图片占方块的比例（越小内边距越大）
	MiniIconCorner = 10,   -- 图片自身圆角
	MiniPos        = UDim2.fromScale(0.5, 0.5),

	OpenTime      = 0.32, -- 打开动画时长
	MiniTime      = 0.24, -- 收起动画时长
	OpenFromScale = 0.82, -- 打开时的起始缩放
	StartOpen     = true, -- true=开场直接展开；false=先显示方块
}

local COLOR = {
	Panel   = Color3.fromRGB(22, 23, 28),
	Panel2  = Color3.fromRGB(34, 36, 44),
	Text    = Color3.fromRGB(238, 240, 246),
	TextDim = Color3.fromRGB(146, 152, 168),
	Accent  = Color3.fromRGB(96, 165, 250),
	Accent2 = Color3.fromRGB(180, 120, 255),
	Stroke  = Color3.fromRGB(255, 255, 255),
}

-- ======================== 小工具 ========================
local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		o[k] = v
	end
	if parent then
		o.Parent = parent
	end
	return o
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function tween(obj, time, props, style, dir)
	local info = TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

-- ======================== 根容器 ========================
local gui = new("ScreenGui", {
	Name = "OrigamiUI",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 999,
	Parent = playerGui,
})

local vp = workspace.CurrentCamera.ViewportSize
local BASE_SCALE = math.clamp(math.min(
	1,
	(vp.X - 40) / CONFIG.PanelSize.X.Offset,
	(vp.Y - 40) / CONFIG.PanelSize.Y.Offset
), 0.45, 1)

-- ======================== 主面板 ========================
local panel = new("CanvasGroup", {
	Name = "Panel",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = CONFIG.PanelSize,
	BackgroundColor3 = COLOR.Panel,
	BackgroundTransparency = 0.06,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	GroupTransparency = 1,
	Visible = false,
	Parent = gui,
})
corner(panel, CONFIG.PanelCorner)

local panelScale = new("UIScale", { Scale = BASE_SCALE * CONFIG.OpenFromScale }, panel)

new("UIStroke", {
	Color = COLOR.Stroke,
	Transparency = 0.88,
	Thickness = 1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, panel)

-- 背景图
local bg = new("ImageLabel", {
	Name = "Bg",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Image = CONFIG.BgImage,
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 1,
}, panel)
corner(bg, CONFIG.PanelCorner)

-- 压暗层
local dim = new("Frame", {
	Name = "Dim",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.42,
	BorderSizePixel = 0,
	ZIndex = 2,
}, panel)
corner(dim, CONFIG.PanelCorner)

-- 顶部高光
local glowTop = new("Frame", {
	Name = "GlowTop",
	Size = UDim2.new(1, 0, 0, 96),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.94,
	BorderSizePixel = 0,
	ZIndex = 2,
}, panel)
corner(glowTop, CONFIG.PanelCorner)
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, glowTop)

-- ======================== 标题栏 ========================
local titleBar = new("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	ZIndex = 3,
}, panel)

new("TextLabel", {
	Position = UDim2.fromOffset(16, 8),
	Size = UDim2.new(1, -120, 0, 18),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = CONFIG.Title,
	TextSize = 14,
	TextColor3 = COLOR.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, titleBar)

new("TextLabel", {
	Position = UDim2.fromOffset(16, 25),
	Size = UDim2.new(1, -120, 0, 14),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = CONFIG.Subtitle,
	TextSize = 10,
	TextColor3 = COLOR.TextDim,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 4,
}, titleBar)

local function makeIconButton(text, xOffset, hoverColor)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, xOffset, 0, 22),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		Text = text,
		TextSize = 14,
		TextColor3 = COLOR.TextDim,
		ZIndex = 5,
		Parent = titleBar,
	})
	corner(btn, 8)
	btn.MouseEnter:Connect(function()
		tween(btn, 0.14, { BackgroundTransparency = 0.86, TextColor3 = hoverColor }, Enum.EasingStyle.Quad)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.14, { BackgroundTransparency = 1, TextColor3 = COLOR.TextDim }, Enum.EasingStyle.Quad)
	end)
	return btn
end

local btnMin   = makeIconButton("—", -46, COLOR.Text)
local btnClose = makeIconButton("✕", -14, Color3.fromRGB(255, 120, 120))

-- ======================== 内容区（纯占位，可替换） ========================
local body = new("ScrollingFrame", {
	Name = "Body",
	Position = UDim2.fromOffset(10, 52),
	Size = UDim2.new(1, -20, 1, -62),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = COLOR.TextDim,
	ScrollBarImageTransparency = 0.5,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 3,
}, panel)

new("UIListLayout", {
	Padding = UDim.new(0, 6),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, body)

for i = 1, 5 do
	local row = new("Frame", {
		Name = "Row" .. i,
		Size = UDim2.new(1, -6, 0, 42),
		BackgroundColor3 = COLOR.Panel2,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		LayoutOrder = i,
		ZIndex = 4,
	}, body)
	corner(row, 8)

	local chip = new("Frame", {
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = COLOR.Accent,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, row)
	corner(chip, 6)

	new("TextLabel", {
		Position = UDim2.fromOffset(44, 0),
		Size = UDim2.new(1, -90, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = "占位项目 " .. string.format("%02d", i),
		TextSize = 13,
		TextColor3 = COLOR.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 5,
	}, row)

	local pill = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(34, 16),
		BackgroundColor3 = COLOR.TextDim,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ZIndex = 5,
	}, row)
	corner(pill, 8)
end

-- ============================================================
--  缩小后的方块
--  Frame(Mini) → UIScale(弹出) → Frame(Hover) → UIScale(悬停)
--    → 外发光层 / 渐变描边层 / 图片 / 点击层
-- ============================================================
local mini = new("Frame", {
	Name = "Mini",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = CONFIG.MiniPos,
	Size = UDim2.fromOffset(CONFIG.MiniSize, CONFIG.MiniSize),
	BackgroundColor3 = Color3.fromRGB(14, 15, 19),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
})
corner(mini, CONFIG.MiniCorner)

local miniScale = new("UIScale", { Scale = 0.55 }, mini)

local hover = new("Frame", {
	Name = "Hover",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
}, mini)
local hoverScale = new("UIScale", { Scale = 1 }, hover)

-- ① 外发光层（呼吸）
local glowHost = new("Frame", {
	Name = "GlowHost",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 1,
}, hover)
corner(glowHost, CONFIG.MiniCorner)
local glowStroke = new("UIStroke", {
	Color = COLOR.Accent,
	Thickness = 4,
	Transparency = 0.7,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, glowHost)

-- ② 渐变描边层（旋转）
local ringHost = new("Frame", {
	Name = "RingHost",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 2,
}, hover)
corner(ringHost, CONFIG.MiniCorner)
local ringStroke = new("UIStroke", {
	Thickness = 1.6,
	Transparency = 0.15,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, ringHost)
local ringGrad = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, COLOR.Accent),
		ColorSequenceKeypoint.new(0.50, COLOR.Accent2),
		ColorSequenceKeypoint.new(1.00, COLOR.Accent),
	}),
}, ringStroke)

TweenService:Create(
	ringGrad,
	TweenInfo.new(3.2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
	{ Rotation = 360 }
):Play()

-- ③ 图片（缩小塞进方块）
local miniImg = new("ImageLabel", {
	Name = "Icon",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(CONFIG.MiniIconScale, CONFIG.MiniIconScale),
	BackgroundTransparency = 1,
	Image = CONFIG.BgImage,
	ScaleType = Enum.ScaleType.Crop,
	ImageTransparency = 1,
	ZIndex = 3,
}, hover)
corner(miniImg, CONFIG.MiniIconCorner)

-- ④ 点击层
local miniBtn = new("TextButton", {
	Name = "Click",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 5,
}, hover)
corner(miniBtn, CONFIG.MiniCorner)

-- ======================== 方块透明度驱动 ========================
local miniAlpha = Instance.new("NumberValue")
miniAlpha.Value = 0

local function applyMiniAlpha()
	local a = miniAlpha.Value
	mini.BackgroundTransparency = 0.06 + (1 - a) * 0.94
	miniImg.ImageTransparency = 1 - a
end
miniAlpha.Changed:Connect(applyMiniAlpha)
applyMiniAlpha()

-- ======================== 边框呼吸 + 悬停高亮 ========================
local hovering = false
local phase = 0

RunService.Heartbeat:Connect(function(dt)
	if not mini.Visible then
		return
	end
	local a = miniAlpha.Value
	if a <= 0.01 then
		return
	end
	phase += dt
	local s = (math.sin(phase * 2.4) + 1) * 0.5

	local glowTarget, ringTarget
	if hovering then
		glowTarget = 0.28 + s * 0.30
		ringTarget = 0.00 + s * 0.12
	else
		glowTarget = 0.58 + s * 0.22
		ringTarget = 0.16 + s * 0.14
	end

	glowStroke.Transparency = 1 - (1 - glowTarget) * a
	ringStroke.Transparency = 1 - (1 - ringTarget) * a
end)

local function setHover(on)
	hovering = on
	tween(hoverScale, 0.18, { Scale = on and 1.08 or 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	if miniAlpha.Value >= 0.99 then
		tween(mini, 0.18, { BackgroundTransparency = on and 0 or 0.06 })
	end
end

miniBtn.MouseEnter:Connect(function() setHover(true) end)
miniBtn.MouseLeave:Connect(function() setHover(false) end)
miniBtn.MouseButton1Down:Connect(function()
	tween(hoverScale, 0.07, { Scale = 0.92 }, Enum.EasingStyle.Quad)
end)
miniBtn.MouseButton1Up:Connect(function()
	if hovering then
		tween(hoverScale, 0.16, { Scale = 1.08 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
end)

-- ======================== 关闭后的"复活"圆点 ========================
local revive = new("TextButton", {
	Name = "Revive",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -12),
	Size = UDim2.fromOffset(14, 14),
	BackgroundColor3 = COLOR.Accent,
	BackgroundTransparency = 0.3,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 10,
	Parent = gui,
})
corner(revive, 99)

-- ======================== 状态机 ========================
local state = "closed"

local function openPanel()
	state = "open"
	revive.Visible = false
	mini.Visible = false

	panel.Visible = true
	panelScale.Scale = BASE_SCALE * CONFIG.OpenFromScale
	panel.GroupTransparency = 1

	tween(panelScale, CONFIG.OpenTime, { Scale = BASE_SCALE }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tween(panel, CONFIG.OpenTime, { GroupTransparency = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

local function showMini()
	state = "mini"
	mini.Visible = true
	miniScale.Scale = 0.55
	hoverScale.Scale = 1
	hovering = false
	miniAlpha.Value = 0

	tween(miniScale, 0.34, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	tween(miniAlpha, 0.2, { Value = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

local function toMini()
	if state ~= "open" then
		return
	end
	state = "mini"

	tween(panel, CONFIG.MiniTime, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local shrink = tween(panelScale, CONFIG.MiniTime, { Scale = BASE_SCALE * 0.14 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	shrink.Completed:Once(function()
		if state ~= "mini" then
			return
		end
		panel.Visible = false
		showMini()
	end)
end

local function fromMini()
	if state ~= "mini" then
		return
	end
	state = "opening"

	tween(miniScale, 0.16, { Scale = 0.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local fade = tween(miniAlpha, 0.16, { Value = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	fade.Completed:Once(function()
		if state ~= "opening" then
			return
		end
		mini.Visible = false
		openPanel()
	end)
end

local function closeAll()
	if state == "closed" then
		return
	end
	state = "closed"

	if mini.Visible then
		tween(miniScale, 0.16, { Scale = 0.6 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tween(miniAlpha, 0.16, { Value = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end

	tween(panel, 0.2, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local fade = tween(panelScale, 0.2, { Scale = BASE_SCALE * 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	fade.Completed:Once(function()
		if state ~= "closed" then
			return
		end
		panel.Visible = false
		mini.Visible = false
		revive.Visible = true
		revive.BackgroundTransparency = 1
		tween(revive, 0.3, { BackgroundTransparency = 0.3 }, Enum.EasingStyle.Quint)
	end)
end

btnMin.MouseButton1Click:Connect(toMini)
btnClose.MouseButton1Click:Connect(closeAll)
miniBtn.MouseButton1Click:Connect(fromMini)
revive.MouseButton1Click:Connect(function()
	revive.Visible = false
	openPanel()
end)

-- 热键兜底：右 Ctrl 在三态间循环
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightControl then
		if state == "closed" then
			revive.Visible = false
			openPanel()
		elseif state == "mini" then
			fromMini()
		elseif state == "open" then
			toMini()
		end
	end
end)

-- ======================== 拖动标题栏 ========================
local dragging, dragStart, startPos = false, nil, nil

local function insideButton(pos)
	for _, b in ipairs({ btnMin, btnClose }) do
		local ap, as = b.AbsolutePosition, b.AbsoluteSize
		if pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y then
			return true
		end
	end
	return false
end

titleBar.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if insideButton(input.Position) then
		return
	end
	dragging = true
	dragStart = input.Position
	startPos = panel.Position
end)

UserInputService.InputChanged:Connect(function(input)
	if not dragging then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local d = input.Position - dragStart
	panel.Position = UDim2.new(
		startPos.X.Scale, startPos.X.Offset + d.X,
		startPos.Y.Scale, startPos.Y.Offset + d.Y
	)
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

-- ======================== 开场 ========================
if CONFIG.StartOpen then
	task.wait(0.1)
	openPanel()
else
	showMini()
end
