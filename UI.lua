--[[
================================================================
  OrigamiUI Lite  v2  ·  纯视觉 UI 面板（无任何业务逻辑）
----------------------------------------------------------------
  本版更新：
    · 缩小后的方块支持拖动（位移超过 5px 判定为拖动，不误触打开）
    · 方块改为毛玻璃质感：玻璃底 + 颗粒噪点 + 流动高光 + 双层描边
    · 关闭按钮改为红色叉号（用图形绘制，不依赖字体，不会渲染成方块）
    · 关闭前弹出二次确认悬浮窗（"点错了" / "确认关闭"）
    · 内容行增加悬停高亮与描边

  使用方法（二选一）：
    1) Roblox Studio：放到 StarterPlayer/StarterPlayerScripts 下的 LocalScript
    2) 执行器 / 模组加载器：loadstring(readfile("/sdcard/Download/OrigamiUI_Lite.lua"))()

  所有可调参数在 CONFIG / COLOR 两个表里。
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
	BgImage = "rbxasset://b33a43199a0a3f7d776cac641182db83/bg.jpg",

	Title    = "ORIGAMI",
	Subtitle = "BUILD TOOL",

	PanelSize   = UDim2.fromOffset(440, 300),
	PanelCorner = 12,

	-- 缩小后的玻璃方块
	MiniSize       = 48,   -- 方块边长
	MiniCorner     = 17,   -- 圆角
	MiniIconScale  = 0.60, -- 图片占方块比例
	MiniIconCorner = 11,   -- 图片自身圆角
	MiniPos        = UDim2.fromScale(0.5, 0.5),

	OpenTime      = 0.32,
	MiniTime      = 0.24,
	OpenFromScale = 0.82,
	StartOpen     = true,

	DragThreshold = 5, -- 拖动判定阈值（像素），小于该值算点击
}

local COLOR = {
	Panel   = Color3.fromRGB(22, 23, 28),
	Panel2  = Color3.fromRGB(34, 36, 44),
	Text    = Color3.fromRGB(238, 240, 246),
	TextDim = Color3.fromRGB(146, 152, 168),
	Accent  = Color3.fromRGB(96, 165, 250),
	Accent2 = Color3.fromRGB(180, 120, 255),
	Stroke  = Color3.fromRGB(255, 255, 255),
	Danger  = Color3.fromRGB(255, 92, 92),
	Glass   = Color3.fromRGB(198, 214, 255),
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

local bg = new("ImageLabel", {
	Name = "Bg",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Image = CONFIG.BgImage,
	ScaleType = Enum.ScaleType.Crop,
	ZIndex = 1,
}, panel)
corner(bg, CONFIG.PanelCorner)

local dim = new("Frame", {
	Name = "Dim",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.48,
	BorderSizePixel = 0,
	ZIndex = 2,
}, panel)
corner(dim, CONFIG.PanelCorner)

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

-- 标题栏底部一条极淡的分隔光
local titleLine = new("Frame", {
	Position = UDim2.fromOffset(0, 43),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = COLOR.Stroke,
	BackgroundTransparency = 0.9,
	BorderSizePixel = 0,
	ZIndex = 3,
}, panel)
new("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, titleLine)

-- ---------------- 最小化按钮（图形绘制） ----------------
local btnMin = new("TextButton", {
	Name = "BtnMin",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -46, 0, 22),
	Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 5,
	Parent = titleBar,
})
corner(btnMin, 8)

local minLine = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(11, 2),
	BackgroundColor3 = COLOR.TextDim,
	BorderSizePixel = 0,
	ZIndex = 6,
}, btnMin)
corner(minLine, 2)

-- ---------------- 关闭按钮：红色叉号（图形绘制） ----------------
local btnClose = new("TextButton", {
	Name = "BtnClose",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -14, 0, 22),
	Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = Color3.fromRGB(255, 92, 92),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Text = "",
	ZIndex = 5,
	Parent = titleBar,
})
corner(btnClose, 8)

local crossColor = COLOR.Danger
local crossA = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(10, 2),
	BackgroundColor3 = crossColor,
	BorderSizePixel = 0,
	Rotation = 45,
	ZIndex = 6,
}, btnClose)
corner(crossA, 2)

local crossB = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(10, 2),
	BackgroundColor3 = crossColor,
	BorderSizePixel = 0,
	Rotation = -45,
	ZIndex = 6,
}, btnClose)
corner(crossB, 2)

btnMin.MouseEnter:Connect(function()
	tween(btnMin, 0.14, { BackgroundTransparency = 0.88 }, Enum.EasingStyle.Quad)
	minLine.BackgroundColor3 = COLOR.Text
end)
btnMin.MouseLeave:Connect(function()
	tween(btnMin, 0.14, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
	minLine.BackgroundColor3 = COLOR.TextDim
end)

btnClose.MouseEnter:Connect(function()
	tween(btnClose, 0.14, { BackgroundTransparency = 0.8 }, Enum.EasingStyle.Quad)
	crossA.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	crossB.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
end)
btnClose.MouseLeave:Connect(function()
	tween(btnClose, 0.14, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
	crossA.BackgroundColor3 = crossColor
	crossB.BackgroundColor3 = crossColor
end)

-- ======================== 内容区（保留原排版） ========================
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

	local rowStroke = new("UIStroke", {
		Color = COLOR.Stroke,
		Transparency = 1,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, row)

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

	-- 行悬停效果
	row.MouseEnter:Connect(function()
		tween(row, 0.16, { BackgroundTransparency = 0.08 }, Enum.EasingStyle.Quad)
		tween(rowStroke, 0.16, { Transparency = 0.88 }, Enum.EasingStyle.Quad)
		tween(chip, 0.16, { BackgroundTransparency = 0.05 }, Enum.EasingStyle.Quad)
	end)
	row.MouseLeave:Connect(function()
		tween(row, 0.16, { BackgroundTransparency = 0.25 }, Enum.EasingStyle.Quad)
		tween(rowStroke, 0.16, { Transparency = 1 }, Enum.EasingStyle.Quad)
		tween(chip, 0.16, { BackgroundTransparency = 0.35 }, Enum.EasingStyle.Quad)
	end)
end

-- ============================================================
--  缩小后的毛玻璃方块
--  Frame(Mini) -> UIScale(弹出) -> Frame(Hover) -> UIScale(悬停)
--     |-- Glass    玻璃底（颗粒 + 流动高光 + 内描边）
--     |-- GlowHost 外发光（呼吸）
--     |-- RingHost 渐变描边（旋转）
--     |-- Icon     图片
--     |-- Click    拖拽 / 点击层
-- ============================================================
local mini = new("Frame", {
	Name = "Mini",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = CONFIG.MiniPos,
	Size = UDim2.fromOffset(CONFIG.MiniSize, CONFIG.MiniSize),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
})

local miniScale = new("UIScale", { Scale = 0.55 }, mini)

local hover = new("Frame", {
	Name = "Hover",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
}, mini)
local hoverScale = new("UIScale", { Scale = 1 }, hover)

-- ① 玻璃底：淡蓝白半透明 + 颗粒 + 高光
local glass = new("Frame", {
	Name = "Glass",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = COLOR.Glass,
	BackgroundTransparency = 0.62,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	ZIndex = 1,
}, hover)
corner(glass, CONFIG.MiniCorner)

-- 玻璃颗粒（磨砂质感）
math.randomseed(os.time())
for i = 1, 20 do
	local dot = new("Frame", {
		Name = "Grain" .. i,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(math.random(6, 94) / 100, math.random(6, 94) / 100),
		Size = UDim2.fromOffset(math.random(1, 2), math.random(1, 2)),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.82 + math.random() * 0.12,
		BorderSizePixel = 0,
		ZIndex = 2,
	}, glass)
	corner(dot, 2)
end

-- 流动的斜向高光（玻璃反光）
local sheen = new("Frame", {
	Name = "Sheen",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.5,
	BorderSizePixel = 0,
	ZIndex = 3,
}, glass)
corner(sheen, CONFIG.MiniCorner)

local sheenGrad = new("UIGradient", {
	Rotation = 18,
	Offset = Vector2.new(-1.6, 0),
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1),
		NumberSequenceKeypoint.new(0.42, 0.70),
		NumberSequenceKeypoint.new(0.58, 0.70),
		NumberSequenceKeypoint.new(1.00, 1),
	}),
}, sheen)

TweenService:Create(
	sheenGrad,
	TweenInfo.new(2.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
	{ Offset = Vector2.new(1.6, 0) }
):Play()

-- 玻璃内侧细高光描边
new("UIStroke", {
	Color = Color3.new(1, 1, 1),
	Transparency = 0.72,
	Thickness = 1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, glass)

-- ② 外发光层（呼吸）
local glowHost = new("Frame", {
	Name = "GlowHost",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 4,
}, hover)
corner(glowHost, CONFIG.MiniCorner)
local glowStroke = new("UIStroke", {
	Color = COLOR.Accent,
	Thickness = 4,
	Transparency = 0.7,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, glowHost)

-- ③ 渐变描边层（旋转）
local ringHost = new("Frame", {
	Name = "RingHost",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 5,
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

-- ④ 图片（缩小塞进方块）
local miniImg = new("ImageLabel", {
	Name = "Icon",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromScale(CONFIG.MiniIconScale, CONFIG.MiniIconScale),
	BackgroundTransparency = 1,
	Image = CONFIG.BgImage,
	ScaleType = Enum.ScaleType.Crop,
	ImageTransparency = 1,
	ZIndex = 6,
}, hover)
corner(miniImg, CONFIG.MiniIconCorner)

-- ⑤ 点击 / 拖拽层
local miniBtn = new("TextButton", {
	Name = "Click",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 7,
}, hover)
corner(miniBtn, CONFIG.MiniCorner)

-- ======================== 方块透明度驱动 ========================
local miniAlpha = Instance.new("NumberValue")
miniAlpha.Value = 0

local function applyMiniAlpha()
	local a = miniAlpha.Value
	glass.BackgroundTransparency = 0.62 + (1 - a) * 0.38
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
		glowTarget = 0.24 + s * 0.28
		ringTarget = 0.00 + s * 0.12
	else
		glowTarget = 0.56 + s * 0.22
		ringTarget = 0.16 + s * 0.14
	end

	glowStroke.Transparency = 1 - (1 - glowTarget) * a
	ringStroke.Transparency = 1 - (1 - ringTarget) * a
end)

local function setHover(on)
	hovering = on
	tween(hoverScale, 0.18, { Scale = on and 1.08 or 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

miniBtn.MouseEnter:Connect(function() setHover(true) end)
miniBtn.MouseLeave:Connect(function() setHover(false) end)

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
	ZIndex = 30,
	Parent = gui,
})
corner(revive, 99)

-- ============================================================
--  二次确认悬浮窗
-- ============================================================
local confirmOverlay = new("TextButton", {
	Name = "ConfirmOverlay",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Text = "",
	AutoButtonColor = false,
	Visible = false,
	ZIndex = 40,
	Parent = gui,
})

local confirm = new("CanvasGroup", {
	Name = "Confirm",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(264, 138),
	BackgroundColor3 = Color3.fromRGB(26, 27, 34),
	BackgroundTransparency = 0.04,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	GroupTransparency = 1,
	Visible = false,
	ZIndex = 41,
	Parent = gui,
})
corner(confirm, 14)

local confirmScale = new("UIScale", { Scale = 0.86 }, confirm)

new("UIStroke", {
	Color = COLOR.Danger,
	Transparency = 0.72,
	Thickness = 1.2,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, confirm)

-- 顶部淡红光晕
local confirmGlow = new("Frame", {
	Size = UDim2.new(1, 0, 0, 70),
	BackgroundColor3 = COLOR.Danger,
	BackgroundTransparency = 0.92,
	BorderSizePixel = 0,
	ZIndex = 42,
}, confirm)
corner(confirmGlow, 14)
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, confirmGlow)

new("TextLabel", {
	Position = UDim2.fromOffset(0, 18),
	Size = UDim2.new(1, 0, 0, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = "确认关闭面板？",
	TextSize = 15,
	TextColor3 = COLOR.Text,
	ZIndex = 43,
}, confirm)

new("TextLabel", {
	Position = UDim2.fromOffset(0, 40),
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "关闭后可点右下角小圆点重新唤出",
	TextSize = 10,
	TextColor3 = COLOR.TextDim,
	ZIndex = 43,
}, confirm)

local function makeDialogButton(text, baseColor, isRight)
	local btn = new("TextButton", {
		AnchorPoint = Vector2.new(isRight and 1 or 0, 1),
		Position = UDim2.new(isRight and 1 or 0, isRight and -14 or 14, 1, -16),
		Size = UDim2.fromOffset(114, 34),
		BackgroundColor3 = baseColor,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextSize = 13,
		TextColor3 = COLOR.Text,
		ZIndex = 44,
		Parent = confirm,
	})
	corner(btn, 9)

	local stroke = new("UIStroke", {
		Color = baseColor,
		Transparency = 0.45,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, btn)

	btn.MouseEnter:Connect(function()
		tween(btn, 0.15, { BackgroundTransparency = 0.55 }, Enum.EasingStyle.Quad)
		tween(stroke, 0.15, { Transparency = 0.1 }, Enum.EasingStyle.Quad)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.15, { BackgroundTransparency = 0.78 }, Enum.EasingStyle.Quad)
		tween(stroke, 0.15, { Transparency = 0.45 }, Enum.EasingStyle.Quad)
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, 0.07, { BackgroundTransparency = 0.35 }, Enum.EasingStyle.Quad)
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, 0.14, { BackgroundTransparency = 0.55 }, Enum.EasingStyle.Quad)
	end)

	return btn
end

local btnWrong = makeDialogButton("点错了", Color3.fromRGB(120, 124, 140), false)
local btnSure  = makeDialogButton("确认关闭", COLOR.Danger, true)

local confirmOpen = false

local function showConfirm()
	if confirmOpen then
		return
	end
	confirmOpen = true

	confirmOverlay.Visible = true
	confirm.Visible = true

	confirmOverlay.BackgroundTransparency = 1
	confirm.GroupTransparency = 1
	confirmScale.Scale = 0.86

	tween(confirmOverlay, 0.22, { BackgroundTransparency = 0.45 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tween(confirm, 0.22, { GroupTransparency = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tween(confirmScale, 0.32, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function hideConfirm(afterFn)
	if not confirmOpen then
		return
	end
	confirmOpen = false

	tween(confirmOverlay, 0.18, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(confirm, 0.18, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	tween(confirmScale, 0.18, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Once(function()
		confirm.Visible = false
		confirmOverlay.Visible = false
		if afterFn then
			afterFn()
		end
	end)
end

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

	confirmOpen = false
	confirm.Visible = false
	confirmOverlay.Visible = false

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

-- ======================== 事件绑定 ========================
btnMin.MouseButton1Click:Connect(toMini)
btnClose.MouseButton1Click:Connect(showConfirm)
btnWrong.MouseButton1Click:Connect(function() hideConfirm(nil) end)
btnSure.MouseButton1Click:Connect(function() hideConfirm(closeAll) end)
confirmOverlay.MouseButton1Click:Connect(function() hideConfirm(nil) end)

revive.MouseButton1Click:Connect(function()
	revive.Visible = false
	openPanel()
end)

-- ======================== 方块：拖动 + 点击 ========================
local miniDragging = false
local miniMoved = false
local miniDragStart = nil
local miniStartPos = nil

miniBtn.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		miniDragging = true
		miniMoved = false
		miniDragStart = input.Position
		miniStartPos = mini.Position
	end
end)

-- ======================== 热键兜底 ========================
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightControl then
		if confirmOpen then
			hideConfirm(nil)
			return
		end
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
	local isPointer = input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
	if not isPointer then
		return
	end

	-- 方块拖动
	if miniDragging then
		local d = input.Position - miniDragStart
		if math.abs(d.X) > CONFIG.DragThreshold or math.abs(d.Y) > CONFIG.DragThreshold then
			miniMoved = true
		end
		mini.Position = UDim2.new(
			miniStartPos.X.Scale, miniStartPos.X.Offset + d.X,
			miniStartPos.Y.Scale, miniStartPos.Y.Offset + d.Y
		)
		return
	end

	-- 面板拖动
	if dragging then
		local d = input.Position - dragStart
		panel.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	-- 方块释放：没移动过才算点击
	if miniDragging then
		miniDragging = false
		setHover(false)
		if not miniMoved then
			fromMini()
		end
		miniDragStart = nil
		return
	end

	dragging = false
end)

-- ======================== 开场 ========================
if CONFIG.StartOpen then
	task.wait(0.1)
	openPanel()
else
	showMini()
end