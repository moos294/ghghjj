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

local iconBox = Instance.new("Frame")
iconBox.Size = UDim2.new(0, 22, 0, 22)
iconBox.Position = UDim2.new(0, 12, 0.5, -11)
iconBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
iconBox.BorderSizePixel = 0
iconBox.ZIndex = 101
iconBox.Parent = MiniBar
corner(iconBox, 4)

local iconInner = Instance.new("Frame")
iconInner.Size = UDim2.new(0, 10, 0, 10)
iconInner.Position = UDim2.new(0.5, -5, 0.5, -5)
iconInner.BackgroundColor3 = Color3.fromRGB(40, 40, 46)
iconInner.BorderSizePixel = 0
iconInner.ZIndex = 102
iconInner.Parent = iconBox
corner(iconInner, 2)

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