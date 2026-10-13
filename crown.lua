local content = readfile("ui_source_clean.txt")
local CHUNK_SIZE = 30000
local chunks = {}
for i = 1, #content, CHUNK_SIZE do
    table.insert(chunks, content:sub(i, i + CHUNK_SIZE - 1))
end

local SG = Instance.new("ScreenGui")
SG.Name = "ChunkCopier"
SG.ResetOnSpawn = false
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then SG.Parent = game:GetService("Players").LocalPlayer.PlayerGui end

local Btn = Instance.new("TextButton")
Btn.Size = UDim2.new(0, 240, 0, 70)
Btn.Position = UDim2.new(0.5, -120, 0.5, -35)
Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
Btn.Text = "COPY chunk 1 / " .. #chunks
Btn.TextColor3 = Color3.fromRGB(0, 255, 200)
Btn.Font = Enum.Font.GothamBold
Btn.TextSize = 16
Btn.BorderSizePixel = 0
Btn.Parent = SG

local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, 8)
c.Parent = Btn

local idx = 1
Btn.MouseButton1Click:Connect(function()
    if idx > #chunks then
        Btn.Text = "DONE"
        return
    end
    if setclipboard then
        setclipboard(chunks[idx])
        Btn.Text = "Copied chunk " .. idx .. " / " .. #chunks .. " (tap for next)"
        idx = idx + 1
    else
        Btn.Text = "No clipboard"
    end
end)