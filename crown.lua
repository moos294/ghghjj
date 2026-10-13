local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local function prop(v)
    if type(v) == "string" then return string.format("%q", v)
    elseif typeof(v) == "UDim2" then return string.format("UDim2.new(%f, %d, %f, %d)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
    elseif typeof(v) == "Color3" then return string.format("Color3.fromRGB(%d, %d, %d)", math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5))
    elseif typeof(v) == "EnumItem" then return "Enum." .. tostring(v.EnumType) .. "." .. v.Name
    else return tostring(v) end
end

local output = {"-- UI Rebuild", ""}

local function walk(inst, indent)
    if not inst:IsA("GuiObject") then return end
    if not inst.Visible then return end
    if inst.Name == "ShortcutBar" or inst.Name == "FoundationOverlay" or inst.Name == "SafeAreaFrame" then return end

    local i = string.rep("    ", indent)
    local props = ""
    local varName = "V_" .. indent .. "_" .. tostring(math.random(10000, 99999))

    props = props .. "\n" .. i .. "    Size = " .. prop(inst.Size)
    props = props .. ",\n" .. i .. "    Position = " .. prop(inst.Position)
    props = props .. ",\n" .. i .. "    BackgroundColor3 = " .. prop(inst.BackgroundColor3)
    props = props .. ",\n" .. i .. "    BackgroundTransparency = " .. tostring(inst.BackgroundTransparency)
    props = props .. ",\n" .. i .. "    BorderSizePixel = " .. tostring(inst.BorderSizePixel)
    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
        props = props .. ",\n" .. i .. "    Text = " .. prop(inst.Text)
        props = props .. ",\n" .. i .. "    TextColor3 = " .. prop(inst.TextColor3)
        props = props .. ",\n" .. i .. "    TextSize = " .. tostring(inst.TextSize)
    end

    table.insert(output, i .. "local " .. varName .. " = Instance.new(" .. prop(inst.ClassName) .. ")")
    table.insert(output, i .. varName .. ".Name = " .. prop(inst.Name))
    table.insert(output, i .. varName .. props)
    if inst.Parent and inst.Parent ~= game then
        table.insert(output, i .. varName .. ".Parent = " .. (inst.Parent.Name or "game"))
    end

    for _, child in ipairs(inst:GetChildren()) do
        walk(child, indent + 1)
    end
    table.insert(output, "")
end

for _, root in ipairs({LP.PlayerGui, game:GetService("CoreGui")}) do
    for _, gui in ipairs(root:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "UIExtractorGui" and gui.Name ~= "ChunkCopier" then
            table.insert(output, "-- " .. gui.Name)
            walk(gui, 0)
        end
    end
end

local text = table.concat(output, "\n")
local ok, err = pcall(function()
    if writefile then writefile("ui_source_clean.txt", text) end
end)
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = ok and "OK" or "FAIL",
        Text = ok and ("Saved: ui_source_clean.txt ("..#output.." lines)") or tostring(err),
        Duration = 6,
    })
end)