local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local function prop(v)
    if type(v) == "string" then
        return string.format("%q", v)
    elseif typeof(v) == "UDim2" then
        return string.format("UDim2.new(%f, %d, %f, %d)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
    elseif typeof(v) == "UDim" then
        return string.format("UDim.new(%f, %d)", v.Scale, v.Offset)
    elseif typeof(v) == "Vector2" then
        return string.format("Vector2.new(%f, %f)", v.X, v.Y)
    elseif typeof(v) == "Color3" then
        return string.format("Color3.fromRGB(%d, %d, %d)", math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5))
    elseif typeof(v) == "EnumItem" then
        return "Enum." .. tostring(v.EnumType) .. "." .. v.Name
    else
        return tostring(v)
    end
end

local output = {"-- UI Rebuild", ""}

local function walk(inst, indent)
    local i = string.rep("    ", indent)
    local props = ""
    local nameVar = "V_" .. indent .. "_" .. tostring(math.random(10000, 99999))

    if inst:IsA("GuiObject") then
        props = props .. "\n" .. i .. "    Size = " .. prop(inst.Size)
        props = props .. ",\n" .. i .. "    Position = " .. prop(inst.Position)
        props = props .. ",\n" .. i .. "    AnchorPoint = " .. prop(inst.AnchorPoint)
        props = props .. ",\n" .. i .. "    BackgroundColor3 = " .. prop(inst.BackgroundColor3)
        props = props .. ",\n" .. i .. "    BackgroundTransparency = " .. tostring(inst.BackgroundTransparency)
        props = props .. ",\n" .. i .. "    BorderSizePixel = " .. tostring(inst.BorderSizePixel)
        props = props .. ",\n" .. i .. "    Visible = " .. tostring(inst.Visible)
        props = props .. ",\n" .. i .. "    ZIndex = " .. tostring(inst.ZIndex)
        if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
            props = props .. ",\n" .. i .. "    Text = " .. prop(inst.Text)
            props = props .. ",\n" .. i .. "    TextColor3 = " .. prop(inst.TextColor3)
            props = props .. ",\n" .. i .. "    TextSize = " .. tostring(inst.TextSize)
            props = props .. ",\n" .. i .. "    Font = " .. prop(inst.Font)
        end
        if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
            props = props .. ",\n" .. i .. "    Image = " .. prop(inst.Image)
        end
    end

    table.insert(output, i .. "local " .. nameVar .. " = Instance.new(" .. prop(inst.ClassName) .. ")")
    table.insert(output, i .. nameVar .. ".Name = " .. prop(inst.Name))
    if props ~= "" then
        table.insert(output, i .. nameVar .. props)
    end
    if inst.Parent and inst.Parent ~= game then
        table.insert(output, i .. nameVar .. ".Parent = " .. (inst.Parent.Name or "game"))
    end

    for _, child in ipairs(inst:GetChildren()) do
        if not child:IsA("Script") and not child:IsA("LocalScript") and not child:IsA("ModuleScript") then
            walk(child, indent + 1)
        end
    end
    table.insert(output, "")
end

for _, root in ipairs({LP.PlayerGui, game:GetService("CoreGui")}) do
    for _, gui in ipairs(root:GetChildren()) do
        if gui:IsA("ScreenGui") then
            table.insert(output, "-- " .. gui.Name .. " (in " .. root.Name .. ")")
            walk(gui, 0)
        end
    end
end

local text = table.concat(output, "\n")

local old = LP.PlayerGui:FindFirstChild("UIExtractorGui")
if old then old:Destroy() end
pcall(function()
    local cg = game:GetService("CoreGui"):FindFirstChild("UIExtractorGui")
    if cg then cg:Destroy() end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "UIExtractorGui"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() sg.Parent = game:GetService("CoreGui") end)
if not sg.Parent then sg.Parent = LP.PlayerGui end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 400)
main.Position = UDim2.new(0.5, -170, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
main.BorderSizePixel = 0
main.Active = true
main.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = main

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
header.BorderSizePixel = 0
header.Parent = main

local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 8)
hc.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "UI Extractor  |  " .. #output .. " lines"
title.TextColor3 = Color3.fromRGB(0, 229, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Parent = header
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 5)
cc.Parent = closeBtn

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -96)
scroll.Position = UDim2.new(0, 8, 0, 42)
scroll.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(0, 229, 255)
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = main
local sc = Instance.new("UICorner")
sc.CornerRadius = UDim.new(0, 5)
sc.Parent = scroll

local txt = Instance.new("TextLabel")
txt.Size = UDim2.new(1, -12, 0, 0)
txt.Position = UDim2.new(0, 6, 0, 6)
txt.BackgroundTransparency = 1
txt.Text = text
txt.TextColor3 = Color3.fromRGB(220, 235, 255)
txt.Font = Enum.Font.Code
txt.TextSize = 10
txt.TextXAlignment = Enum.TextXAlignment.Left
txt.TextYAlignment = Enum.TextYAlignment.Top
txt.TextWrapped = true
txt.AutomaticSize = Enum.AutomaticSize.Y
txt.Parent = scroll

local function makeBtn(text, x, color, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 155, 0, 34)
    b.Position = UDim2.new(0, x, 1, -42)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = main
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 5)
    bc.Parent = b
    b.MouseButton1Click:Connect(callback)
    b.MouseButton1Down:Connect(function()
        b.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
    end)
    b.MouseButton1Up:Connect(function()
        b.BackgroundColor3 = color
    end)
    return b
end

makeBtn("COPY", 8, Color3.fromRGB(0, 130, 170), function()
    local ok = pcall(function()
        if setclipboard then
            setclipboard(text)
        elseif toclipboard then
            toclipboard(text)
        else
            error("no clipboard")
        end
    end)
    if ok then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "OK",
                Text = "Copied to clipboard",
                Duration = 3,
            })
        end)
    else
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Fail",
                Text = "clipboard unsupported",
                Duration = 3,
            })
        end)
    end
end)

makeBtn("SAVE", 177, Color3.fromRGB(0, 150, 100), function()
    local ok = pcall(function()
        writefile("ui_source.txt", text)
    end)
    if ok then
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "OK",
                Text = "Saved: ui_source.txt",
                Duration = 5,
            })
        end)
    else
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "Fail",
                Text = "writefile unavailable",
                Duration = 5,
            })
        end)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    sg:Destroy()
end)

-- 拖动
do
    local dragging = false
    local startPos, startInput
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = input.Position
            startPos = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - startInput
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "UI Extractor",
        Text = "Done. " .. #output .. " lines.",
        Duration = 5,
    })
end)