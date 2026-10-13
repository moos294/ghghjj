local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local SG = Instance.new("ScreenGui")
SG.Name = "UIRebuildPanel"
SG.ResetOnSpawn = false
SG.DisplayOrder = 9999
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then SG.Parent = LP.PlayerGui end

local Box = Instance.new("TextButton")
Box.Size = UDim2.new(0, 320, 0, 220)
Box.Position = UDim2.new(0, 10, 0, 80)
Box.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
Box.TextColor3 = Color3.fromRGB(0, 255, 200)
Box.Font = Enum.Font.Code
Box.TextSize = 12
Box.TextWrapped = true
Box.TextXAlignment = Enum.TextXAlignment.Left
Box.TextYAlignment = Enum.TextYAlignment.Top
Box.BorderSizePixel = 0
Box.Text = "start..."
Box.Parent = SG

local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, 6)
c.Parent = Box

local function log(s)
    Box.Text = Box.Text .. "\n" .. tostring(s)
end

Box.Text = "== UI Extract =="

log("writefile: " .. tostring(type(writefile)))
log("readfile: " .. tostring(type(readfile)))
log("setclipboard: " .. tostring(type(setclipboard)))

local function prop(v)
    if type(v) == "string" then return string.format("%q", v)
    elseif typeof(v) == "UDim2" then return string.format("UDim2.new(%f, %d, %f, %d)", v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
    elseif typeof(v) == "Color3" then return string.format("Color3.fromRGB(%d, %d, %d)", math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5))
    elseif typeof(v) == "EnumItem" then return "Enum." .. tostring(v.EnumType) .. "." .. v.Name
    else return tostring(v) end
end

local output = {"-- UI Rebuild", ""}
local count = 0

local function walk(inst, indent)
    if not inst:IsA("GuiObject") then return end
    if not inst.Visible then return end
    if inst.Name == "ShortcutBar" or inst.Name == "FoundationOverlay" or inst.Name == "SafeAreaFrame" then return end

    count = count + 1

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

local ok, err = pcall(function()
    for _, root in ipairs({LP.PlayerGui, game:GetService("CoreGui")}) do
        for _, gui in ipairs(root:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name ~= "UIExtractorGui" and gui.Name ~= "ChunkCopier" and gui.Name ~= "UIRebuildPanel" then
                table.insert(output, "-- " .. gui.Name)
                walk(gui, 0)
            end
        end
    end
end)

if not ok then
    log("ERROR: " .. tostring(err))
    return
end

log("Found " .. count .. " visible elements")
log("Total lines: " .. #output)

local text = table.concat(output, "\n")
log("Text length: " .. #text .. " chars")

local saveOk, saveErr = pcall(function()
    writefile("ui_clean.txt", text)
end)
if saveOk then
    log("SAVED: ui_clean.txt")
else
    log("SAVE FAIL: " .. tostring(saveErr))
end

if setclipboard then
    local cpOk = pcall(function() setclipboard(text) end)
    if cpOk then
        log("COPIED to clipboard")
    else
        log("COPY FAIL")
    end
else
    log("no setclipboard")
end

log("--- done ---")