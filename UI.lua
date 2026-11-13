--[[
================================================================
  OrigamiUI Lite  v4  ·  毛玻璃 UI 框架（可调用的控件库）
----------------------------------------------------------------
  外观部分完全保留：
    背景图 / 毛玻璃小方块 / 拖动 / 缩放动画 / 呼吸描边 /
    旋转渐变 / 色彩流光 / 扫光 / 涟漪 / 二次确认关闭

  v4 改动：
    · 删除原来的 5 个静态占位行
    · 内容区改为双栏：左侧 Tab 栏 + 右侧内容页
    · 暴露接口：CreateTab / CreateButton / CreateToggle /
                CreateDropdown / CreateInput / CreateParagraph
    · 文件末尾 return 一个表，供主脚本调用

  用法（主脚本）：
    local UI = loadstring(readfile("/sdcard/Download/OrigamiUI_Lite.lua"))()
    local tab = UI.CreateTab("主页")
    UI.CreateButton(tab, "点我", function() print("clicked") end)

  或者把本文件做成 ModuleScript，然后 require 它。
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
	BgImage = "rbxasset://b33a43199a0a3f7d776cac641182db83/bg.jpg",

	Title    = "ORIGAMI",
	Subtitle = "BUILD TOOL",

	PanelSize   = UDim2.fromOffset(440, 300),
	PanelCorner = 12,

	-- 双栏尺寸
	TabBarWidth = 96,
	TabBarX     = 10,
	TabItemH    = 30,   -- Tab 按钮高度
	ContentGap  = 12,   -- 左栏与右栏之间的间距

	-- 缩小后的玻璃方块
	MiniSize       = 48,
	MiniCorner     = 17,
	MiniIconScale  = 0.60,
	MiniIconCorner = 11,
	MiniPos        = UDim2.fromScale(0.5, 0.5),

	OpenTime      = 0.32,
	MiniTime      = 0.24,
	OpenFromScale = 0.82,
	StartOpen     = true,

	DragThreshold = 5,

	-- 特效开关
	FxRing     = true,
	FxBreathe  = true,
	FxCCTint   = true,
	FxSweep    = true,
	FxRipple   = true,
	FxRowIntro = true,

	SweepDelay = 3.8,
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
	Sunken  = Color3.fromRGB(14, 15, 19),
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

local panelStroke = new("UIStroke", {
	Color = COLOR.Stroke,
	Transparency = 0.9,
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

local tint = new("Frame", {
	Name = "Tint",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 0,
	ZIndex = 2,
}, panel)
corner(tint, CONFIG.PanelCorner)

local tintGrad = new("UIGradient", {
	Rotation = 0,
	Transparency = NumberSequence.new(0.9),
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, COLOR.Accent),
		ColorSequenceKeypoint.new(0.5, COLOR.Accent2),
		ColorSequenceKeypoint.new(1.0, COLOR.Accent),
	}),
}, tint)

if CONFIG.FxCCTint then
	TweenService:Create(
		tintGrad,
		TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Rotation = 360 }
	):Play()
end

local dim = new("Frame", {
	Name = "Dim",
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BackgroundTransparency = 0.48,
	BorderSizePixel = 0,
	ZIndex = 3,
}, panel)
corner(dim, CONFIG.PanelCorner)

local glowTop = new("Frame", {
	Name = "GlowTop",
	Size = UDim2.new(1, 0, 0, 96),
	BackgroundColor3 = Color3.fromRGB(255, 255, 255),
	BackgroundTransparency = 0.94,
	BorderSizePixel = 0,
	ZIndex = 3,
}, panel)
corner(glowTop, CONFIG.PanelCorner)
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, glowTop)

-- 外框旋转渐变
local panelRingHost = new("Frame", {
	Name = "PanelRingHost",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 8,
}, panel)
corner(panelRingHost, CONFIG.PanelCorner)

local panelRingStroke = new("UIStroke", {
	Thickness = 1.5,
	Transparency = 0.55,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, panelRingHost)

local panelRingGrad = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, COLOR.Accent),
		ColorSequenceKeypoint.new(0.50, COLOR.Accent2),
		ColorSequenceKeypoint.new(1.00, COLOR.Accent),
	}),
}, panelRingStroke)

if CONFIG.FxRing then
	TweenService:Create(
		panelRingGrad,
		TweenInfo.new(6.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{ Rotation = 360 }
	):Play()
end

-- 周期性扫光
local sweep = new("Frame", {
	Name = "Sweep",
	Size = UDim2.new(0.34, 0, 1.5, 0),
	Position = UDim2.fromScale(-0.7, -0.25),
	Rotation = 16,
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 0.55,
	BorderSizePixel = 0,
	ZIndex = 9,
}, panel)

new("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 1),
		NumberSequenceKeypoint.new(0.5, 0.4),
		NumberSequenceKeypoint.new(1.0, 1),
	}),
}, sweep)

if CONFIG.FxSweep then
	TweenService:Create(
		sweep,
		TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, CONFIG.SweepDelay),
		{ Position = UDim2.fromScale(1.4, -0.25) }
	):Play()
end

-- ======================== 标题栏 ========================
local titleBar = new("Frame", {
	Name = "TitleBar",
	Size = UDim2.new(1, 0, 0, 44),
	BackgroundTransparency = 1,
	ZIndex = 4,
}, panel)

local titleLabel = new("TextLabel", {
	Position = UDim2.fromOffset(16, 8),
	Size = UDim2.new(1, -120, 0, 18),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	Text = CONFIG.Title,
	TextSize = 14,
	TextColor3 = COLOR.Text,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 5,
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
	ZIndex = 5,
}, titleBar)

local titleLine = new("Frame", {
	Position = UDim2.fromOffset(0, 43),
	Size = UDim2.new(1, 0, 0, 1),
	BackgroundColor3 = COLOR.Stroke,
	BackgroundTransparency = 0.9,
	BorderSizePixel = 0,
	ZIndex = 4,
}, panel)
new("UIGradient", {
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, titleLine)

-- ---------------- 最小化按钮 ----------------
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
	ZIndex = 10,
	Parent = titleBar,
})
corner(btnMin, 8)

local minLine = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(11, 2),
	BackgroundColor3 = COLOR.TextDim,
	BorderSizePixel = 0,
	ZIndex = 11,
}, btnMin)
corner(minLine, 2)

-- ---------------- 关闭按钮：红色叉号 ----------------
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
	ZIndex = 10,
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
	ZIndex = 11,
}, btnClose)
corner(crossA, 2)

local crossB = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(10, 2),
	BackgroundColor3 = crossColor,
	BorderSizePixel = 0,
	Rotation = -45,
	ZIndex = 11,
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

-- ============================================================
--  双栏布局：左侧 Tab 栏 + 右侧内容页
-- ============================================================
local CONTENT_Y = 52
local CONTENT_H = CONFIG.PanelSize.Y.Offset - CONTENT_Y - 10

local tabBar = new("ScrollingFrame", {
	Name = "TabBar",
	Position = UDim2.fromOffset(CONFIG.TabBarX, CONTENT_Y),
	Size = UDim2.new(0, CONFIG.TabBarWidth, 1, -(CONTENT_Y + 10)),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ZIndex = 4,
}, panel)

new("UIListLayout", {
	Padding = UDim.new(0, 4),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, tabBar)

new("UIPadding", {
	PaddingLeft = UDim.new(0, 2),
	PaddingRight = UDim.new(0, 2),
	PaddingTop = UDim.new(0, 2),
	PaddingBottom = UDim.new(0, 8),
}, tabBar)

-- 左右分隔竖线
local splitLine = new("Frame", {
	Position = UDim2.fromOffset(CONFIG.TabBarX + CONFIG.TabBarWidth + 3, CONTENT_Y + 2),
	Size = UDim2.new(0, 1, 1, -(CONTENT_Y + 16)),
	BackgroundColor3 = COLOR.Stroke,
	BackgroundTransparency = 0.88,
	BorderSizePixel = 0,
	ZIndex = 4,
}, panel)
new("UIGradient", {
	Rotation = 90,
	Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	}),
}, splitLine)

-- 右侧内容容器
local contentHost = new("Frame", {
	Name = "ContentHost",
	Position = UDim2.fromOffset(CONFIG.TabBarX + CONFIG.TabBarWidth + CONFIG.ContentGap, CONTENT_Y),
	Size = UDim2.new(1, -(CONFIG.TabBarX + CONFIG.TabBarWidth + CONFIG.ContentGap + 10), 1, -(CONTENT_Y + 10)),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ClipsDescendants = false,
	ZIndex = 4,
}, panel)

-- ======================== 控件工具 ========================
local tabs = {}
local activeTab = nil
local currentMenu = nil

-- 行入场动画（对当前页所有行做轻微弹入）
local function playPageIntro(page)
	if not CONFIG.FxRowIntro or not page then
		return
	end
	local i = 0
	for _, child in ipairs(page:GetChildren()) do
		if child:IsA("Frame") and child.Visible then
			i += 1
			local sc = child:FindFirstChildOfClass("UIScale")
			if sc then
				sc.Scale = 0.92
				task.delay(i * 0.03, function()
					if page.Visible then
						tween(sc, 0.28, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					end
				end)
			end
			if i >= 12 then
				break
			end
		end
	end
end

-- 关闭已打开的下拉菜单
local function closeMenu()
	if not currentMenu then
		return
	end
	local m = currentMenu
	currentMenu = nil
	local tw = tween(m, 0.14, { GroupTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tw.Completed:Once(function()
		m.Visible = false
	end)
end

-- 切换 Tab
local function selectTab(tab)
	if activeTab == tab then
		return
	end
	closeMenu()
	activeTab = tab

	for _, t in ipairs(tabs) do
		local on = (t == tab)
		t.Active = on
		t.Page.Visible = on
		tween(t.Button, 0.18, { BackgroundTransparency = on and 0.82 or 1 }, Enum.EasingStyle.Quad)
		tween(t.Label, 0.18, { TextColor3 = on and COLOR.Text or COLOR.TextDim }, Enum.EasingStyle.Quad)
		tween(t.Indicator, 0.18, { BackgroundTransparency = on and 0 or 1 }, Enum.EasingStyle.Quad)
	end

	playPageIntro(tab.Page)
end

-- 创建一行（返回 row 与它的描边）
local function addRow(tab, height)
	tab.RowCount = (tab.RowCount or 0) + 1

	local row = new("Frame", {
		Name = "Row" .. tab.RowCount,
		Size = UDim2.new(1, -6, 0, height or 42),
		BackgroundColor3 = COLOR.Panel2,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		LayoutOrder = tab.RowCount,
		ZIndex = 5,
	}, tab.Page)
	corner(row, 8)

	new("UIScale", { Scale = 1 }, row)

	local stroke = new("UIStroke", {
		Color = COLOR.Stroke,
		Transparency = 1,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, row)

	return row, stroke
end

-- 行左侧标题
local function addTitle(row, text, widthOffset)
	return new("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -(widthOffset or 110), 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextSize = 13,
		TextColor3 = COLOR.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	}, row)
end

-- 行悬停
local function hookHover(row, stroke, onEnter, onLeave)
	row.MouseEnter:Connect(function()
		tween(row, 0.16, { BackgroundTransparency = 0.08 }, Enum.EasingStyle.Quad)
		tween(stroke, 0.16, { Transparency = 0.9 }, Enum.EasingStyle.Quad)
		if onEnter then
			onEnter()
		end
	end)
	row.MouseLeave:Connect(function()
		tween(row, 0.16, { BackgroundTransparency = 0.25 }, Enum.EasingStyle.Quad)
		tween(stroke, 0.16, { Transparency = 1 }, Enum.EasingStyle.Quad)
		if onLeave then
			onLeave()
		end
	end)
end

-- 画一个 ">" 箭头（两条线，不依赖字体）
local function makeChevron(row, color)
	local wrap = new("Frame", {
		Name = "Chevron",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(8, 12),
		BackgroundTransparency = 1,
		ZIndex = 6,
	}, row)

	local l1 = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.25, 0.3),
		Size = UDim2.fromOffset(6, 1.5),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Rotation = 45,
		ZIndex = 7,
	}, wrap)
	corner(l1, 2)

	local l2 = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.25, 0.7),
		Size = UDim2.fromOffset(6, 1.5),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Rotation = -45,
		ZIndex = 7,
	}, wrap)
	corner(l2, 2)

	return { l1, l2 }
end

-- ============================================================
--  公开接口 1：CreateTab
-- ============================================================
local function CreateTab(title)
	local index = #tabs + 1

	local btn = new("TextButton", {
		Name = "Tab_" .. tostring(title),
		Size = UDim2.new(1, 0, 0, CONFIG.TabItemH),
		BackgroundColor3 = COLOR.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = index,
		ZIndex = 5,
		Parent = tabBar,
	})
	corner(btn, 7)

	local indicator = new("Frame", {
		Position = UDim2.fromOffset(4, 8),
		Size = UDim2.new(0, 3, 0, CONFIG.TabItemH - 16),
		BackgroundColor3 = COLOR.Accent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, btn)
	corner(indicator, 2)

	local label = new("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -18, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = tostring(title),
		TextSize = 12,
		TextColor3 = COLOR.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	}, btn)

	local page = new("ScrollingFrame", {
		Name = "Page_" .. tostring(title),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = COLOR.TextDim,
		ScrollBarImageTransparency = 0.5,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		ZIndex = 5,
		Parent = contentHost,
	})

	new("UIListLayout", {
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, page)

	new("UIPadding", {
		PaddingRight = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 8),
	}, page)

	-- 页面滚动时收起下拉菜单，避免菜单与行错位
	page:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		closeMenu()
	end)

	local tab = {
		Title = tostring(title),
		Button = btn,
		Label = label,
		Indicator = indicator,
		Page = page,
		Active = false,
		RowCount = 0,
		Index = index,
	}
	tabs[index] = tab

	btn.MouseButton1Click:Connect(function()
		selectTab(tab)
	end)

	btn.MouseEnter:Connect(function()
		if not tab.Active then
			tween(btn, 0.14, { BackgroundTransparency = 0.92 }, Enum.EasingStyle.Quad)
		end
	end)
	btn.MouseLeave:Connect(function()
		if not tab.Active then
			tween(btn, 0.14, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
		end
	end)

	-- 第一个 Tab 自动选中
	if index == 1 then
		selectTab(tab)
	end

	return tab
end

-- ============================================================
--  公开接口 2：CreateButton
-- ============================================================
local function CreateButton(tab, title, callback)
	assert(tab and tab.Page, "CreateButton: 第一个参数必须是 CreateTab 返回的 tab")

	local row, stroke = addRow(tab, 42)
	addTitle(row, tostring(title))
	local chev = makeChevron(row, COLOR.TextDim)

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
	}, row)
	corner(hit, 8)

	local sc = row:FindFirstChildOfClass("UIScale")

	hookHover(row, stroke, function()
		chev[1].BackgroundColor3 = COLOR.Text
		chev[2].BackgroundColor3 = COLOR.Text
	end, function()
		chev[1].BackgroundColor3 = COLOR.TextDim
		chev[2].BackgroundColor3 = COLOR.TextDim
	end)

	hit.MouseButton1Down:Connect(function()
		if sc then
			tween(sc, 0.08, { Scale = 0.97 }, Enum.EasingStyle.Quad)
		end
	end)
	hit.MouseButton1Up:Connect(function()
		if sc then
			tween(sc, 0.2, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end)

	hit.MouseButton1Click:Connect(function()
		if type(callback) == "function" then
			local ok, err = pcall(callback)
			if not ok then
				warn("[OrigamiUI] CreateButton 回调出错: " .. tostring(err))
			end
		end
	end)

	return {
		Row = row,
		SetTitle = function(t)
			row:FindFirstChildOfClass("TextLabel").Text = tostring(t)
		end,
		SetVisible = function(v)
			row.Visible = v
		end,
	}
end

-- ============================================================
--  公开接口 3：CreateToggle
-- ============================================================
local function CreateToggle(tab, title, default, callback)
	assert(tab and tab.Page, "CreateToggle: 第一个参数必须是 CreateTab 返回的 tab")

	local row, stroke = addRow(tab, 42)
	addTitle(row, tostring(title))

	local track = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = COLOR.TextDim,
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, row)
	corner(track, 11)
	new("UIStroke", {
		Color = COLOR.Stroke,
		Transparency = 0.88,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, track)

	local thumb = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		ZIndex = 7,
	}, track)
	corner(thumb, 8)

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
	}, row)
	corner(hit, 8)

	hookHover(row, stroke)

	local value = default and true or false
	local ON_X = 42 - 16 - 3

	local function render(animate)
		local targetX = value and ON_X or 3
		local onColor = value and COLOR.Accent or COLOR.TextDim
		local onAlpha = value and 0.15 or 0.4
		if animate then
			tween(thumb, 0.22, { Position = UDim2.new(0, targetX, 0.5, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			tween(track, 0.2, { BackgroundColor3 = onColor, BackgroundTransparency = onAlpha }, Enum.EasingStyle.Quad)
		else
			thumb.Position = UDim2.new(0, targetX, 0.5, 0)
			track.BackgroundColor3 = onColor
			track.BackgroundTransparency = onAlpha
		end
	end

	render(false)

	hit.MouseButton1Click:Connect(function()
		value = not value
		render(true)
		if type(callback) == "function" then
			local ok, err = pcall(callback, value)
			if not ok then
				warn("[OrigamiUI] CreateToggle 回调出错: " .. tostring(err))
			end
		end
	end)

	return {
		Row = row,
		Get = function() return value end,
		Set = function(v)
			value = v and true or false
			render(true)
		end,
	}
end

-- ============================================================
--  公开接口 4：CreateDropdown
-- ============================================================
local function CreateDropdown(tab, title, options, default, callback)
	assert(tab and tab.Page, "CreateDropdown: 第一个参数必须是 CreateTab 返回的 tab")
	assert(type(options) == "table" and #options > 0, "CreateDropdown: options 必须是非空数组")

	local row, stroke = addRow(tab, 42)
	addTitle(row, tostring(title), 150)
	makeChevron(row, COLOR.TextDim)

	local valueLabel = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -28, 0.5, 0),
		Size = UDim2.fromOffset(100, 42),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = tostring(default or options[1]),
		TextSize = 12,
		TextColor3 = COLOR.Accent,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 6,
	}, row)

	local hit = new("TextButton", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 8,
	}, row)
	corner(hit, 8)

	hookHover(row, stroke)

	-- 菜单挂在 panel 上，避免被 ScrollingFrame 裁切
	local menu = new("CanvasGroup", {
		Name = "DropdownMenu",
		BackgroundColor3 = Color3.fromRGB(28, 30, 36),
		BackgroundTransparency = 0.02,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 20,
		Parent = panel,
	})
	corner(menu, 8)
	new("UIStroke", {
		Color = COLOR.Accent,
		Transparency = 0.7,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, menu)

	local itemButtons = {}
	local currentIndex = 1
	for i, opt in ipairs(options) do
		if tostring(opt) == tostring(default) then
			currentIndex = i
			break
		end
	end

	local function paintItems()
		for i, item in ipairs(itemButtons) do
			local on = (i == currentIndex)
			item.Text.TextColor3 = on and COLOR.Accent or COLOR.Text
			item.Dot.BackgroundTransparency = on and 0 or 1
		end
	end

	for i, opt in ipairs(options) do
		local item = new("TextButton", {
			Name = "Item" .. i,
			Position = UDim2.fromOffset(4, 4 + (i - 1) * 26),
			Size = UDim2.new(1, -8, 0, 26),
			BackgroundColor3 = COLOR.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Text = "",
			ZIndex = 21,
			Parent = menu,
		})
		corner(item, 6)

		local dot = new("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromOffset(8, 13),
			Size = UDim2.fromOffset(3, 3),
			BackgroundColor3 = COLOR.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 22,
		}, item)
		corner(dot, 99)

		local txt = new("TextLabel", {
			Position = UDim2.fromOffset(18, 0),
			Size = UDim2.new(1, -24, 1, 0),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = tostring(opt),
			TextSize = 12,
			TextColor3 = COLOR.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 22,
		}, item)

		table.insert(itemButtons, { Button = item, Text = txt, Dot = dot })

		item.MouseEnter:Connect(function()
			tween(item, 0.12, { BackgroundTransparency = 0.86 }, Enum.EasingStyle.Quad)
		end)
		item.MouseLeave:Connect(function()
			tween(item, 0.12, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
		end)

		item.MouseButton1Click:Connect(function()
			currentIndex = i
			valueLabel.Text = tostring(opt)
			paintItems()
			closeMenu()
			if type(callback) == "function" then
				local ok, err = pcall(callback, opt, i)
				if not ok then
					warn("[OrigamiUI] CreateDropdown 回调出错: " .. tostring(err))
				end
			end
		end)
	end

	paintItems()

	local function openMenu()
		local menuH = #options * 26 + 8
		local s = panelScale.Scale

		local rowAbs = row.AbsolutePosition
		local rowSize = row.AbsoluteSize
		local pAbs = panel.AbsolutePosition

		local localX = (rowAbs.X - pAbs.X) / s
		local localY = (rowAbs.Y - pAbs.Y) / s + rowSize.Y / s + 4
		local localW = rowSize.X / s

		-- 超出面板底部就改成向上弹
		local panelH = CONFIG.PanelSize.Y.Offset
		if localY + menuH > panelH - 8 then
			localY = (rowAbs.Y - pAbs.Y) / s - menuH - 4
		end

		menu.Position = UDim2.fromOffset(localX, localY)
		menu.Size = UDim2.fromOffset(localW, menuH)
		menu.Visible = true
		menu.GroupTransparency = 1
		tween(menu, 0.16, { GroupTransparency = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	end

	hit.MouseButton1Click:Connect(function()
		if currentMenu == menu then
			closeMenu()
			return
		end
		closeMenu()
		currentMenu = menu
		openMenu()
	end)

	return {
		Row = row,
		Get = function() return options[currentIndex], currentIndex end,
		Set = function(v)
			for i, opt in ipairs(options) do
				if tostring(opt) == tostring(v) then
					currentIndex = i
					valueLabel.Text = tostring(opt)
					paintItems()
					return
				end
			end
		end,
		Close = closeMenu,
	}
end

-- ============================================================
--  公开接口 5：CreateInput
-- ============================================================
local function CreateInput(tab, title, default, callback)
	assert(tab and tab.Page, "CreateInput: 第一个参数必须是 CreateTab 返回的 tab")

	local row, stroke = addRow(tab, 42)
	addTitle(row, tostring(title), 180)

	local box = new("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(150, 28),
		BackgroundColor3 = COLOR.Sunken,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		Font = Enum.Font.Gotham,
		Text = tostring(default or ""),
		PlaceholderText = "输入…",
		PlaceholderColor3 = COLOR.TextDim,
		TextSize = 12,
		TextColor3 = COLOR.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		ZIndex = 6,
	}, row)
	corner(box, 6)

	new("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	}, box)

	local boxStroke = new("UIStroke", {
		Color = COLOR.Accent,
		Transparency = 0.9,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, box)

	hookHover(row, stroke)

	box.Focused:Connect(function()
		tween(boxStroke, 0.16, { Transparency = 0.2 }, Enum.EasingStyle.Quad)
	end)
	box.FocusLost:Connect(function(enterPressed)
		tween(boxStroke, 0.16, { Transparency = 0.9 }, Enum.EasingStyle.Quad)
		if type(callback) == "function" then
			local ok, err = pcall(callback, box.Text, enterPressed)
			if not ok then
				warn("[OrigamiUI] CreateInput 回调出错: " .. tostring(err))
			end
		end
	end)

	return {
		Row = row,
		TextBox = box,
		Get = function() return box.Text end,
		Set = function(v) box.Text = tostring(v or "") end,
	}
end

-- ============================================================
--  公开接口 6：CreateParagraph
-- ============================================================
local function CreateParagraph(tab, title, desc)
	assert(tab and tab.Page, "CreateParagraph: 第一个参数必须是 CreateTab 返回的 tab")

	local hasDesc = (desc ~= nil and tostring(desc) ~= "")
	local row = addRow(tab, hasDesc and 56 or 28)
	row.BackgroundTransparency = 1 -- 段落不要底板

	local stroke = row:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 1
	end

	local label = new("TextLabel", {
		Position = UDim2.fromOffset(6, hasDesc and 2 or 4),
		Size = UDim2.new(1, -12, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = tostring(title or ""),
		TextSize = 13,
		TextColor3 = COLOR.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 6,
	}, row)

	local descLabel = nil
	if hasDesc then
		descLabel = new("TextLabel", {
			Position = UDim2.fromOffset(6, 21),
			Size = UDim2.new(1, -12, 0, 32),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			Text = tostring(desc),
			TextSize = 11,
			TextColor3 = COLOR.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			ZIndex = 6,
		}, row)
	end

	return {
		Row = row,
		SetTitle = function(t) label.Text = tostring(t) end,
		SetDesc = function(t)
			if descLabel then
				descLabel.Text = tostring(t)
			end
		end,
	}
end

-- ============================================================
--  缩小后的毛玻璃方块（外观保留）
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

new("UIStroke", {
	Color = Color3.new(1, 1, 1),
	Transparency = 0.72,
	Thickness = 1,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, glass)

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

local miniBtn = new("TextButton", {
	Name = "Click",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 7,
}, hover)
corner(miniBtn, CONFIG.MiniCorner)

local miniAlpha = Instance.new("NumberValue")
miniAlpha.Value = 0

local function applyMiniAlpha()
	local a = miniAlpha.Value
	glass.BackgroundTransparency = 0.62 + (1 - a) * 0.38
	miniImg.ImageTransparency = 1 - a
end
miniAlpha.Changed:Connect(applyMiniAlpha)
applyMiniAlpha()

local hovering = false

local function setHover(on)
	hovering = on
	tween(hoverScale, 0.18, { Scale = on and 1.08 or 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

miniBtn.MouseEnter:Connect(function() setHover(true) end)
miniBtn.MouseLeave:Connect(function() setHover(false) end)

-- ======================== 复活圆点 ========================
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
--  二次确认关闭
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

local confirmStroke = new("UIStroke", {
	Color = COLOR.Danger,
	Transparency = 0.72,
	Thickness = 1.2,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, confirm)

local confirmRingHost = new("Frame", {
	Name = "ConfirmRingHost",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	ZIndex = 45,
}, confirm)
corner(confirmRingHost, 14)

local confirmRingStroke = new("UIStroke", {
	Thickness = 1.4,
	Transparency = 0.5,
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
}, confirmRingHost)

local confirmRingGrad = new("UIGradient", {
	Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, COLOR.Danger),
		ColorSequenceKeypoint.new(0.50, Color3.fromRGB(255, 170, 90)),
		ColorSequenceKeypoint.new(1.00, COLOR.Danger),
	}),
}, confirmRingStroke)

TweenService:Create(
	confirmRingGrad,
	TweenInfo.new(3.6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
	{ Rotation = 360 }
):Play()

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

	local btnScale = new("UIScale", { Scale = 1 }, btn)

	btn.MouseEnter:Connect(function()
		tween(btn, 0.15, { BackgroundTransparency = 0.55 }, Enum.EasingStyle.Quad)
		tween(stroke, 0.15, { Transparency = 0.1 }, Enum.EasingStyle.Quad)
		tween(btnScale, 0.15, { Scale = 1.04 }, Enum.EasingStyle.Quint)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, 0.15, { BackgroundTransparency = 0.78 }, Enum.EasingStyle.Quad)
		tween(stroke, 0.15, { Transparency = 0.45 }, Enum.EasingStyle.Quad)
		tween(btnScale, 0.15, { Scale = 1 }, Enum.EasingStyle.Quint)
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btnScale, 0.07, { Scale = 0.96 }, Enum.EasingStyle.Quad)
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btnScale, 0.14, { Scale = 1.04 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
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
	closeMenu()

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

-- ======================== 涟漪 ========================
local function playRipple()
	if not CONFIG.FxRipple then
		return
	end
	local r = new("Frame", {
		Name = "Ripple",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(140, 140),
		BackgroundTransparency = 1,
		ZIndex = 12,
	}, panel)
	corner(r, 99)

	local st = new("UIStroke", {
		Color = COLOR.Accent,
		Thickness = 2,
		Transparency = 0.35,
	}, r)

	local sc = new("UIScale", { Scale = 0.4 }, r)

	tween(sc, 0.85, { Scale = 3.4 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tween(st, 0.85, { Transparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out).Completed:Once(function()
		r:Destroy()
	end)
end

-- ======================== 心跳 ========================
local phase = 0

RunService.Heartbeat:Connect(function(dt)
	phase += dt
	local s = (math.sin(phase * 2.4) + 1) * 0.5

	if mini.Visible then
		local a = miniAlpha.Value
		if a > 0.01 then
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
		end
	end

	if CONFIG.FxBreathe and panel.Visible then
		panelStroke.Transparency = 0.86 + s * 0.1
	end

	if confirm.Visible then
		confirmStroke.Transparency = 0.55 + s * 0.3
	end
end)

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

	playRipple()
	playPageIntro(activeTab and activeTab.Page)
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
	closeMenu()

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
	closeMenu()

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

-- ============================================================
--  拖动系统（多指安全）
-- ============================================================
local panelDragInput = nil
local panelDragStart = nil
local panelStartPos = nil

local miniDragInput = nil
local miniDragStart = nil
local miniStartPos = nil
local miniMoved = false

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
	if panelDragInput then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if insideButton(input.Position) then
		return
	end
	closeMenu()
	panelDragInput = input
	panelDragStart = input.Position
	panelStartPos = panel.Position
end)

miniBtn.InputBegan:Connect(function(input)
	if miniDragInput then
		return
	end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		miniDragInput = input
		miniDragStart = input.Position
		miniStartPos = mini.Position
		miniMoved = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if panelDragInput and input == panelDragInput then
		local d = input.Position - panelDragStart
		panel.Position = UDim2.new(
			panelStartPos.X.Scale, panelStartPos.X.Offset + d.X,
			panelStartPos.Y.Scale, panelStartPos.Y.Offset + d.Y
		)
		return
	end

	if miniDragInput and input == miniDragInput then
		local d = input.Position - miniDragStart
		if math.abs(d.X) > CONFIG.DragThreshold or math.abs(d.Y) > CONFIG.DragThreshold then
			miniMoved = true
		end
		mini.Position = UDim2.new(
			miniStartPos.X.Scale, miniStartPos.X.Offset + d.X,
			miniStartPos.Y.Scale, miniStartPos.Y.Offset + d.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if panelDragInput and input == panelDragInput then
		panelDragInput = nil
		panelDragStart = nil
		return
	end

	if miniDragInput and input == miniDragInput then
		miniDragInput = nil
		setHover(false)
		if not miniMoved then
			fromMini()
		end
		return
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

-- ======================== 开场 ========================
if CONFIG.StartOpen then
	task.wait(0.1)
	openPanel()
else
	showMini()
end

-- ============================================================
--  对外暴露
-- ============================================================
local OrigamiUI = {}

-- 窗口控制
OrigamiUI.Open = openPanel
OrigamiUI.Close = closeAll
OrigamiUI.Minimize = toMini
OrigamiUI.Toggle = function()
	if state == "open" then
		toMini()
	elseif state == "mini" then
		fromMini()
	else
		openPanel()
	end
end
OrigamiUI.IsOpen = function()
	return state == "open", state
end
OrigamiUI.SetTitle = function(t)
	titleLabel.Text = tostring(t)
end

-- 控件
OrigamiUI.CreateTab = CreateTab
OrigamiUI.CreateButton = CreateButton
OrigamiUI.CreateToggle = CreateToggle
OrigamiUI.CreateDropdown = CreateDropdown
OrigamiUI.CreateInput = CreateInput
OrigamiUI.CreateParagraph = CreateParagraph

-- 额外工具
OrigamiUI.SelectTab = selectTab
OrigamiUI.CloseMenu = closeMenu
OrigamiUI.GetTabs = function()
	return tabs
end
OrigamiUI.Destroy = function()
	gui:Destroy()
end

-- 原始引用（需要深度定制时可以拿）
OrigamiUI.Gui = gui
OrigamiUI.Panel = panel
OrigamiUI.TabBar = tabBar
OrigamiUI.Content = contentHost
OrigamiUI.Config = CONFIG
OrigamiUI.Colors = COLOR

-- 执行器环境下也方便直接取
_G.OrigamiUI = OrigamiUI

local WindUI = {}

function WindUI:Notify(args)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = args.Title or "通知",
        Text = args.Content or "",
        Duration = args.Duration or 3
    })
end

function WindUI:CreateWindow(args)
    local windowMock = {}
    function windowMock:Tab(tabArgs)
        local realTab = OrigamiUI.CreateTab(tabArgs.Title)
        local tabMock = {}
        
        tabMock.Button = function(self, btnArgs)
            OrigamiUI.CreateButton(realTab, btnArgs.Title, btnArgs.Callback)
        end
        
        tabMock.Toggle = function(self, args)
            local defaultVal = args.Default or args.CurrentValue or false
            OrigamiUI.CreateToggle(realTab, args.Title, defaultVal, args.Callback)
        end
        
        tabMock.Dropdown = function(self, args)
            local options = args.Values or args.Options or {}
            local defaultOpt = args.Value or args.CurrentOption or options[1]
            local dd = OrigamiUI.CreateDropdown(realTab, args.Title, options, defaultOpt, args.Callback)
            return {
                SetOptions = function() end, 
                SetValue = function(self, val) if dd.Set then dd.Set(val) end end,
                Refresh = function() end,
                Select = function(self, val) if dd.Set then dd.Set(val) end end
            }
        end
        
        tabMock.Input = function(self, args)
            OrigamiUI.CreateInput(realTab, args.Title, args.Value or args.CurrentValue, args.Callback)
        end
        
        tabMock.Paragraph = function(self, args)
            local p = OrigamiUI.CreateParagraph(realTab, args.Title, args.Desc)
            return {
                SetTitle = function(self, t) if p.SetTitle then p.SetTitle(t) end end,
                SetDesc = function(self, d) if p.SetDesc then p.SetDesc(d) end end,
                SetColor = function() end
            }
        end
        tabMock.Section = tabMock.Paragraph
        return tabMock
    end
    return windowMock
end

OrigamiUI.WindUI = WindUI
OrigamiUI.Window = WindUI:CreateWindow()

return OrigamiUI