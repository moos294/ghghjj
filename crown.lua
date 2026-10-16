local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local ActionMap = {
    ["俯卧撑"] = "PushUp", ["哑铃"] = "Dumbbell", ["肩部推举1"] = "ShoulderPress_1",
    ["肩部推举2"] = "ShoulderPress_2", ["肩部推举3"] = "ShoulderPress_3",
    ["跑步机1"] = "TrendMill_1", ["平躺卧推1"] = "FlatBench_1", ["平躺卧推L1"] = "FlatBench_L1",
    ["平躺卧推K1"] = "FlatBench_K1", ["举石1"] = "Rock_1", ["举石2"] = "Rock_2", ["举石3"] = "Rock_3",
    ["杠铃架L1"] = "BarbellRack_L1", ["杠铃架S1"] = "BarbellRack_S1", ["杠铃架1"] = "BarbellRack_1",
    ["杠铃架2"] = "BarbellRack_2", ["卧推L1"] = "BenchPress_L1", ["卧推1"] = "BenchPress_1",
    ["卧推2"] = "BenchPress_2", ["红史莱姆"] = "Red slime", ["天空史莱姆"] = "SkySlime",
}
local ActionListCN = {}
for cn, _ in pairs(ActionMap) do table.insert(ActionListCN, cn) end
table.sort(ActionListCN)

local Cfg = {
    AutoPetEgg = false, PetEggName = "SkyPetEgg", PetEggPrice = 3, PetEggQty = 1,
    AutoHaloEgg = false, HaloEggName = "SkyHaloEgg", HaloEggPrice = 1, HaloEggQty = 1,
    EggCurrency = "Gem", EggInterval = 0.1,
    AutoTrain = false, TrainAction = "Dumbbell", TrainActionCN = "哑铃", TrainInterval = 0.2,
    FastTrain = false, FastTrainAction = "Dumbbell", FastTrainActionCN = "哑铃",
    FastPerBeat = 1, FastMaxPerSecond = 0, FastTotalReps = 0,
    AutoRebirth = false, TargetStrength = 10000, RebirthInc = 10000, TargetRebirthCount = 5,
    RebirthCheckInterval = 0.1, RebirthCooldown = 0.1,
    InfiniteRebirth = false, BaseStrength = 10000,
    Fly = false, FlySpeed = 50, WalkSpeed = 16, AntiAfk = true,
    TotalReps = 0, ScriptStartTime = tick(),
    TeleportTarget = "", TeleportLoop = false, TeleportOffsetY = 3,
    AntiIdleKick = true, AntiClientKick = false, BypassGroup = false,
}

local C = {
    accent = Color3.fromRGB(60, 150, 230), text = Color3.fromRGB(230, 230, 235),
    textDim = Color3.fromRGB(150, 150, 160), green = Color3.fromRGB(0, 200, 140),
    red = Color3.fromRGB(220, 70, 80), stroke = Color3.fromRGB(48, 48, 56),
}

local function corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
end

local function stroke(p, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or C.stroke
    s.Thickness = t or 1
    s.Transparency = tr or 0
    s.Parent = p
end

local function fmt(n)
    n = math.floor(tonumber(n) or 0)
    local s = tostring(n)
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if out:sub(1, 1) == "," then out = out:sub(2) end
    return out
end

local function getCurrentStrength()
    local str = 0
    pcall(function()
        local attr = player:GetAttribute("Strength") or player:GetAttribute("Power")
        if attr then str = attr return end
        if player.leaderstats then
            local ls = player.leaderstats
            if ls:FindFirstChild("Strength") then str = ls.Strength.Value return end
            if ls:FindFirstChild("Power") then str = ls.Power.Value return end
        end
    end)
    return str
end

local function getCurrentRebirths()
    local count = 0
    pcall(function()
        local attr = player:GetAttribute("Rebirths") or player:GetAttribute("Rebirth") or player:GetAttribute("RebirthCount")
        if attr then count = attr return end
        if player.leaderstats then
            local ls = player.leaderstats
            local names = {"Rebirths", "Rebirth", "RebirthCount", "Prestige", "Reborn"}
            for _, n in ipairs(names) do
                if ls:FindFirstChild(n) and (ls[n]:IsA("IntValue") or ls[n]:IsA("NumberValue")) then
                    count = ls[n].Value return
                end
            end
        end
    end)
    return count
end

local function applyAntiIdleKick()
    if not getconnections then return end
    pcall(function()
        for _, conn in next, getconnections(player.Idled) do
            pcall(function() conn:Disable() end)
            pcall(function() conn:Disconnect() end)
        end
    end)
end

local function applyAntiClientKick()
    if not getgc then return end
    pcall(function()
        for _, Value in next, getgc(true) do
            if typeof(Value) == "table" then
                if rawget(Value, "indexInstance") or rawget(Value, "newindexInstance") or rawget(Value, "newIndexInstance") then
                    Value.tvk = {"kick", function() return task.wait(9e9) end}
                end
            end
        end
    end)
end

local function applyBypassGroup()
    if not hookmetamethod or not hookfunction then return end
    pcall(function()
        local clonerefFunc = cloneref or function(o) return o end
        local getnamecallmethod = getnamecallmethod
        local Speaker = clonerefFunc(Players).LocalPlayer
        local OldNameCall
        OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
            if self ~= Speaker or getnamecallmethod() ~= "IsInGroup" then
                return OldNameCall(self, ...)
            end
            return true
        end)
        hookfunction(Speaker.IsInGroup, function(self, ...) return true end)
    end)
end

local function applyGrayBuildings()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local isCharacter = false
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character and obj:IsDescendantOf(plr.Character) then isCharacter = true break end
            end
            if not isCharacter then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Color = Color3.fromRGB(128, 128, 128)
                obj.Reflectance = 0
            end
        end
    end
end

local function hidePets()
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if char then
            for _, obj in ipairs(char:GetChildren()) do
                if obj:IsA("Model") and (obj.Name:lower():find("pet") or obj.Name:lower():find("宠物")) then
                    for _, part in ipairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then part.Transparency = 1 end
                    end
                end
            end
        end
    end
end

local function boostPerformance()
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = 1
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        Lighting.ClockTime = 12
    end)
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then v:Destroy() end
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") or v:IsA("Beam") then v.Enabled = false end
        if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end
    end
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    pcall(function() collectgarbage() end)
end

local TP = { Target = "", Loop = false, OffsetY = 3, Thread = nil }
function TP:GetPlayerList(includeLocal)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if includeLocal or p ~= player then table.insert(list, p.Name) end
    end
    return list
end
function TP:ToTarget()
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local target = Players:FindFirstChild(self.Target)
    if not target or not target.Character then return false end
    local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHrp then return false end
    hrp.CFrame = targetHrp.CFrame + Vector3.new(0, self.OffsetY, 0)
    return true
end
function TP:StartLoop()
    if self.Loop then return end
    self.Loop = true
    self.Thread = task.spawn(function()
        while self.Loop do
            self:ToTarget()
            task.wait()
        end
    end)
end
function TP:StopLoop()
    self.Loop = false
    self.Thread = nil
end
_G.TP = TP

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "力量之冠封存全能版", Icon = "zap", Author = "力量之冠",
    Folder = "PowerCrownSave", Theme = "Dark", Transparent = true,
    Resizable = false, Size = UDim2.fromOffset(460, 780),
})

local MainTab = Window:Tab({ Title = "控制面板", Icon = "settings" })
local CommonSection = MainTab:Section({ Title = "公共设置", Icon = "settings" })
CommonSection:Slider({ Title = "抽蛋间隔 (秒)", Desc = "0.1 最快", Value = { Min = 0.1, Max = 1.0, Default = 0.1 }, Step = 0.05, Callback = function(value) Cfg.EggInterval = value end })

local PetSection = MainTab:Section({ Title = "宠物区", Icon = "paw" })
PetSection:Toggle({ Title = "自动抽宠物蛋", Value = false, Callback = function(state) Cfg.AutoPetEgg = state end })
PetSection:Input({ Title = "宠物蛋名字", Placeholder = "SkyPetEgg", Value = "SkyPetEgg", Callback = function(text) Cfg.PetEggName = text end })
PetSection:Dropdown({ Title = "宠物蛋数量", Values = {"1", "3"}, Value = "1", Multi = false, Callback = function(selected) local val = tonumber(selected) if val then Cfg.PetEggQty = val end end })
PetSection:Input({ Title = "宠物蛋单价", Placeholder = "3", Value = "3", Callback = function(text) local val = tonumber(text) if val then Cfg.PetEggPrice = val end end })
local PetStatus = PetSection:Paragraph({ Title = "宠物区状态", Desc = "待机中..." })

local HaloSection = MainTab:Section({ Title = "光环区", Icon = "star" })
HaloSection:Toggle({ Title = "自动抽光环蛋", Value = false, Callback = function(state) Cfg.AutoHaloEgg = state end })
HaloSection:Input({ Title = "光环蛋名字", Placeholder = "SkyHaloEgg", Value = "SkyHaloEgg", Callback = function(text) Cfg.HaloEggName = text end })
HaloSection:Dropdown({ Title = "光环蛋数量", Values = {"1", "3"}, Value = "1", Multi = false, Callback = function(selected) local val = tonumber(selected) if val then Cfg.HaloEggQty = val end end })
HaloSection:Input({ Title = "光环蛋单价", Placeholder = "1", Value = "1", Callback = function(text) local val = tonumber(text) if val then Cfg.HaloEggPrice = val end end })
local HaloStatus = HaloSection:Paragraph({ Title = "光环区状态", Desc = "待机中..." })

local TrainSection = MainTab:Section({ Title = "自动锻炼", Icon = "activity" })
TrainSection:Toggle({ Title = "自动锻炼", Value = false, Callback = function(state) Cfg.AutoTrain = state end })
TrainSection:Dropdown({ Title = "选择动作 (中文)", Values = ActionListCN, Value = "哑铃", Multi = false, Callback = function(selected) local cn = selected local en = ActionMap[cn] if en then Cfg.TrainAction = en Cfg.TrainActionCN = cn end end })
TrainSection:Slider({ Title = "锻炼间隔 (秒)", Value = { Min = 0.1, Max = 1.0, Default = 0.2 }, Step = 0.05, Callback = function(value) Cfg.TrainInterval = value end })
local TrainStatus = TrainSection:Paragraph({ Title = "锻炼状态", Desc = "待机中..." })

local FastTrainSection = MainTab:Section({ Title = "无间隔锻炼 (极速)", Icon = "gauge" })
FastTrainSection:Toggle({ Title = "无间隔自动锻炼", Value = false, Callback = function(state) Cfg.FastTrain = state end })
FastTrainSection:Dropdown({ Title = "选择动作 (中文)", Values = ActionListCN, Value = "哑铃", Multi = false, Callback = function(selected) local cn = selected local en = ActionMap[cn] if en then Cfg.FastTrainAction = en Cfg.FastTrainActionCN = cn end end })
FastTrainSection:Slider({ Title = "每帧触发次数", Desc = "1=每帧1次 (≈60次/秒)", Value = { Min = 1, Max = 10, Default = 1 }, Step = 1, Callback = function(value) Cfg.FastPerBeat = value end })
FastTrainSection:Slider({ Title = "每秒上限 (0=不限)", Desc = "防踢设置", Value = { Min = 0, Max = 100, Default = 0 }, Step = 5, Callback = function(value) Cfg.FastMaxPerSecond = value end })
local FastTrainStatus = FastTrainSection:Paragraph({ Title = "极速锻炼状态", Desc = "待机中..." })

local RebirthSection = MainTab:Section({ Title = "自动重生 (限次)", Icon = "refresh-cw" })
RebirthSection:Toggle({ Title = "自动重生", Value = false, Callback = function(state) Cfg.AutoRebirth = state end })
RebirthSection:Input({ Title = "初始目标力量", Placeholder = "10000", Value = "10000", Callback = function(text) local val = tonumber(text) if val then Cfg.TargetStrength = val end end })
RebirthSection:Input({ Title = "每次递增数值", Placeholder = "10000", Value = "10000", Callback = function(text) local val = tonumber(text) if val then Cfg.RebirthInc = val end end })
RebirthSection:Input({ Title = "目标重生次数", Placeholder = "5", Value = "5", Callback = function(text) local val = tonumber(text) if val then Cfg.TargetRebirthCount = val end end })
local RebirthStatus = RebirthSection:Paragraph({ Title = "重生状态", Desc = "待机中..." })

local InfiniteSection = MainTab:Section({ Title = "无限循环重生", Icon = "repeat" })
InfiniteSection:Toggle({ Title = "无限循环重生", Value = false, Callback = function(state) Cfg.InfiniteRebirth = state if state then Cfg.AutoRebirth = false end end })
InfiniteSection:Input({ Title = "基础目标力量", Placeholder = "10000", Value = "10000", Callback = function(text) local val = tonumber(text) if val then Cfg.BaseStrength = val end end })
local InfiniteStatus = InfiniteSection:Paragraph({ Title = "无限循环状态", Desc = "待机中..." })

local MoveSection = MainTab:Section({ Title = "移动与反挂机", Icon = "move" })
MoveSection:Toggle({ Title = "飞行模式", Value = false, Callback = function(state) Cfg.Fly = state end })
MoveSection:Slider({ Title = "步行速度", Value = { Min = 16, Max = 500, Default = 16 }, Step = 1, Callback = function(value) Cfg.WalkSpeed = value local char = player.Character if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed = value end end end })
MoveSection:Slider({ Title = "飞行速度", Value = { Min = 10, Max = 500, Default = 50 }, Step = 1, Callback = function(value) Cfg.FlySpeed = value end })
MoveSection:Toggle({ Title = "反挂机", Value = true, Callback = function(state) Cfg.AntiAfk = state end })

local VisualSection = MainTab:Section({ Title = "场景优化", Icon = "eye" })
VisualSection:Button({ Title = "灰色建筑模式", Callback = function() applyGrayBuildings() end })
VisualSection:Button({ Title = "隐藏宠物", Callback = function() hidePets() end })
VisualSection:Button({ Title = "提高帧率并降低延迟", Callback = function() boostPerformance() end })

local TeleportTab = Window:Tab({ Title = "传送", Icon = "send" })
local TPSection = TeleportTab:Section({ Title = "传送玩家", Icon = "user" })

local function GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then table.insert(list, p.Name) end
    end
    return list
end

local TPStatus = TPSection:Paragraph({ Title = "传送状态", Desc = "待机中..." })
local TPDropdown = TPSection:Dropdown({
    Title = "选择在线玩家", Values = GetPlayerList(), Value = "", Multi = false,
    Callback = function(selected)
        if type(selected) == "table" then selected = selected[1] end
        TP.Target = selected or ""
    end
})
TPSection:Button({ Title = "刷新玩家列表", Callback = function()
    local list = GetPlayerList()
    pcall(function() TPDropdown:Refresh(list) end)
    TPStatus:SetDesc("已刷新，共 " .. #list .. " 名玩家")
end })
TPSection:Slider({ Title = "传送高度偏移 (Y)", Value = { Min = 0, Max = 20, Default = 3 }, Step = 1, Callback = function(value) TP.OffsetY = value end })
TPSection:Button({ Title = "传送到目标玩家", Callback = function()
    if TP.Target == "" then TPStatus:SetDesc("请先选择玩家") return end
    if TP:ToTarget() then TPStatus:SetDesc("已传送到 " .. TP.Target) else TPStatus:SetDesc("传送失败") end
end })
TPSection:Toggle({ Title = "循环锁定传送", Value = false, Callback = function(state)
    if state then
        if TP.Target == "" then TPStatus:SetDesc("请先选择玩家") return end
        TP:StartLoop()
        TPStatus:SetDesc("循环传送中 -> " .. TP.Target)
    else
        TP:StopLoop()
        TPStatus:SetDesc("已停止循环传送")
    end
end })
Players.PlayerAdded:Connect(function() task.wait(0.5) pcall(function() TPDropdown:Refresh(GetPlayerList()) end) end)
Players.PlayerRemoving:Connect(function() task.wait(0.2) pcall(function() TPDropdown:Refresh(GetPlayerList()) end) end)

local ProtectTab = Window:Tab({ Title = "防护", Icon = "shield" })
local AntiSection = ProtectTab:Section({ Title = "反挂机 / 防踢", Icon = "shield-check" })
AntiSection:Toggle({ Title = "反挂机踢出", Value = true, Callback = function(state) if state then applyAntiIdleKick() end end })
AntiSection:Toggle({ Title = "防客户端踢出", Value = false, Callback = function(state) if state then applyAntiClientKick() end end })
local GroupSection = ProtectTab:Section({ Title = "群组验证", Icon = "users" })
GroupSection:Toggle({ Title = "绕过群组验证", Value = false, Callback = function(state) if state then applyBypassGroup() end end })

local SG = Instance.new("ScreenGui")
SG.Name = "PowerCrownUI"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then SG.Parent = player.PlayerGui end

local DataHUD = Instance.new("Frame")
DataHUD.Size = UDim2.new(0, 210, 0, 105)
DataHUD.Position = UDim2.new(0, 20, 0.3, 0)
DataHUD.BackgroundColor3 = Color3.fromRGB(20, 24, 34)
DataHUD.BackgroundTransparency = 0.1
DataHUD.BorderSizePixel = 0
DataHUD.ZIndex = 500
DataHUD.Parent = SG
corner(DataHUD, 10)
stroke(DataHUD, C.accent, 1.5, 0.2)

local HUDTitle = Instance.new("TextLabel")
HUDTitle.Size = UDim2.new(1, 0, 0, 24)
HUDTitle.BackgroundTransparency = 1
HUDTitle.Text = "累计总数据"
HUDTitle.TextColor3 = C.accent
HUDTitle.Font = Enum.Font.GothamBold
HUDTitle.TextSize = 12
HUDTitle.ZIndex = 501
HUDTitle.Parent = DataHUD

local LabelReps = Instance.new("TextLabel")
LabelReps.Size = UDim2.new(0.5, -10, 0, 18)
LabelReps.Position = UDim2.new(0, 10, 0, 30)
LabelReps.BackgroundTransparency = 1
LabelReps.Text = "总训练: 0"
LabelReps.TextColor3 = C.text
LabelReps.Font = Enum.Font.Gotham
LabelReps.TextSize = 11
LabelReps.TextXAlignment = Enum.TextXAlignment.Left
LabelReps.ZIndex = 501
LabelReps.Parent = DataHUD

local LabelRebirth = Instance.new("TextLabel")
LabelRebirth.Size = UDim2.new(0.5, -10, 0, 18)
LabelRebirth.Position = UDim2.new(0, 10, 0, 50)
LabelRebirth.BackgroundTransparency = 1
LabelRebirth.Text = "总转生: 0"
LabelRebirth.TextColor3 = C.text
LabelRebirth.Font = Enum.Font.Gotham
LabelRebirth.TextSize = 11
LabelRebirth.TextXAlignment = Enum.TextXAlignment.Left
LabelRebirth.ZIndex = 501
LabelRebirth.Parent = DataHUD

local LabelTime = Instance.new("TextLabel")
LabelTime.Size = UDim2.new(1, -20, 0, 18)
LabelTime.Position = UDim2.new(0, 10, 0, 70)
LabelTime.BackgroundTransparency = 1
LabelTime.Text = "总时长: 00:00:00"
LabelTime.TextColor3 = C.text
LabelTime.Font = Enum.Font.Gotham
LabelTime.TextSize = 11
LabelTime.TextXAlignment = Enum.TextXAlignment.Left
LabelTime.ZIndex = 501
LabelTime.Parent = DataHUD

local HUDDrag, HUDStart, HUDOrigin = false, nil, nil
DataHUD.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        HUDDrag = true
        HUDStart = input.Position
        HUDOrigin = DataHUD.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then HUDDrag = false end end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if HUDDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - HUDStart
        DataHUD.Position = UDim2.new(HUDOrigin.X.Scale, HUDOrigin.X.Offset + delta.X, HUDOrigin.Y.Scale, HUDOrigin.Y.Offset + delta.Y)
    end
end)

local MobileInput = { Forward = false, Back = false, Left = false, Right = false, Up = false, Down = false }
local FlyControls = Instance.new("Frame")
FlyControls.Size = UDim2.new(0, 170, 0, 104)
FlyControls.Position = UDim2.new(0.5, -85, 1, -120)
FlyControls.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
FlyControls.BackgroundTransparency = 0.2
FlyControls.Visible = false
FlyControls.ZIndex = 30
FlyControls.Parent = SG
corner(FlyControls, 8)
stroke(FlyControls, C.accent, 1.2, 0.3)

local function flyButton(text, x, y, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 34, 0, 34)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
    b.Text = text
    b.TextColor3 = color or C.accent
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.AutoButtonColor = false
    b.BorderSizePixel = 0
    b.ZIndex = 31
    b.Parent = FlyControls
    corner(b, 6)
    return b
end

local BtnUp = flyButton("▲", 42, 4, C.accent)
local BtnDown = flyButton("▼", 42, 66, Color3.fromRGB(180, 120, 255))
local BtnLeft = flyButton("◀", 4, 35, C.accent)
local BtnRight = flyButton("▶", 80, 35, C.accent)
local BtnRise = flyButton("＋", 118, 4, C.green)
local BtnFall = flyButton("－", 118, 66, C.red)

local function bindHold(btn, key)
    local function set(v)
        MobileInput[key] = v
        TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = v and 0.6 or 0}):Play()
    end
    btn.MouseButton1Down:Connect(function() set(true) end)
    btn.MouseButton1Up:Connect(function() set(false) end)
    btn.MouseLeave:Connect(function() set(false) end)
end
bindHold(BtnUp, "Forward")
bindHold(BtnDown, "Back")
bindHold(BtnLeft, "Left")
bindHold(BtnRight, "Right")
bindHold(BtnRise, "Up")
bindHold(BtnFall, "Down")

local flying, flyBV, flyBG = false, nil, nil
local startFly, stopFly, applyWalkSpeed

applyWalkSpeed = function()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = Cfg.WalkSpeed end
end

startFly = function()
    if flying then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    flyBG.P = 3000
    flyBG.D = 500
    flyBG.Parent = hrp
    flying = true
end

stopFly = function()
    if not flying then return end
    flying = false
    for k in pairs(MobileInput) do MobileInput[k] = false end
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    applyWalkSpeed()
end

RunService.RenderStepped:Connect(function()
    if not Cfg.Fly then
        if flying then stopFly() end
        FlyControls.Visible = false
        return
    end
    FlyControls.Visible = true
    if not flying then startFly() return end
    local char = player.Character
    if not char then stopFly() return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not flyBV or not flyBG then return end
    local cam = workspace.CurrentCamera
    local dir = Vector3.zero
    local fwd = UserInputService:IsKeyDown(Enum.KeyCode.W) or MobileInput.Forward
    local bck = UserInputService:IsKeyDown(Enum.KeyCode.S) or MobileInput.Back
    local lft = UserInputService:IsKeyDown(Enum.KeyCode.A) or MobileInput.Left
    local rgt = UserInputService:IsKeyDown(Enum.KeyCode.D) or MobileInput.Right
    local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) or MobileInput.Up
    local dn = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or MobileInput.Down
    if fwd then dir = dir + cam.CFrame.LookVector end
    if bck then dir = dir - cam.CFrame.LookVector end
    if lft then dir = dir - cam.CFrame.RightVector end
    if rgt then dir = dir + cam.CFrame.RightVector end
    if up then dir = dir + Vector3.new(0, 1, 0) end
    if dn then dir = dir - Vector3.new(0, 1, 0) end
    if dir.Magnitude > 0 then dir = dir.Unit * Cfg.FlySpeed end
    flyBV.Velocity = dir
    flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
end)

player.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    applyWalkSpeed()
    if flying then stopFly() end
end)

task.spawn(function()
    local storeEvent
    pcall(function() storeEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("StoreEvent") end)
    while true do
        task.wait(Cfg.EggInterval)
        if Cfg.AutoPetEgg and storeEvent then
            pcall(function()
                storeEvent:FireServer("Egg", Cfg.PetEggQty, Cfg.EggCurrency, Cfg.PetEggName)
                PetStatus:SetDesc("正在抽: " .. Cfg.PetEggName .. " x" .. Cfg.PetEggQty)
            end)
        else
            PetStatus:SetDesc("待机中")
        end
        if Cfg.AutoHaloEgg and storeEvent then
            pcall(function()
                storeEvent:FireServer("Egg", Cfg.HaloEggQty, Cfg.EggCurrency, Cfg.HaloEggName)
                HaloStatus:SetDesc("正在抽: " .. Cfg.HaloEggName .. " x" .. Cfg.HaloEggQty)
            end)
        else
            HaloStatus:SetDesc("待机中")
        end
    end
end)

task.spawn(function()
    local trainEvent
    pcall(function() trainEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TrainEvent") end)
    while true do
        task.wait(Cfg.TrainInterval)
        if Cfg.AutoTrain and trainEvent then
            pcall(function()
                trainEvent:FireServer(Cfg.TrainAction)
                Cfg.TotalReps = Cfg.TotalReps + 1
                TrainStatus:SetDesc("正在锻炼: " .. Cfg.TrainActionCN)
            end)
        else
            TrainStatus:SetDesc("待机中")
        end
    end
end)

task.spawn(function()
    local fastTrainEvent
    pcall(function() fastTrainEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TrainEvent") end)
    local beatCount, windowStart = 0, tick()
    RunService.Heartbeat:Connect(function()
        if not Cfg.FastTrain or not fastTrainEvent then
            beatCount = 0
            windowStart = tick()
            return
        end
        if tick() - windowStart >= 1 then
            windowStart = tick()
            beatCount = 0
        end
        for _ = 1, Cfg.FastPerBeat do
            if Cfg.FastMaxPerSecond > 0 and beatCount >= Cfg.FastMaxPerSecond then break end
            local ok = pcall(function() fastTrainEvent:FireServer(Cfg.FastTrainAction) end)
            if ok then
                Cfg.FastTotalReps = Cfg.FastTotalReps + 1
                Cfg.TotalReps = Cfg.TotalReps + 1
                beatCount = beatCount + 1
            else
                break
            end
        end
    end)
end)

task.spawn(function()
    local lastReps, lastTime = 0, tick()
    while SG.Parent do
        task.wait(0.5)
        if Cfg.FastTrain then
            local now = tick()
            local dt = now - lastTime
            local rate = 0
            if dt >= 0.5 then
                rate = math.floor((Cfg.FastTotalReps - lastReps) / dt)
                lastReps = Cfg.FastTotalReps
                lastTime = now
            end
            FastTrainStatus:SetDesc(string.format("极速: %s | 速率 %d/s | 累计 %d", Cfg.FastTrainActionCN, rate, Cfg.FastTotalReps))
        else
            FastTrainStatus:SetDesc("待机中...")
        end
    end
end)

task.spawn(function()
    local rebirthEvent
    pcall(function() rebirthEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RebirthEvent") end)
    while true do
        task.wait(Cfg.RebirthCheckInterval)
        if Cfg.AutoRebirth and rebirthEvent and not Cfg.InfiniteRebirth then
            pcall(function()
                local gameRebirths = getCurrentRebirths()
                if gameRebirths >= Cfg.TargetRebirthCount then
                    Cfg.AutoRebirth = false
                    RebirthStatus:SetDesc("已完成 " .. gameRebirths .. " 次重生，已停止")
                    return
                end
                local currentStr = getCurrentStrength()
                if currentStr >= Cfg.TargetStrength then
                    rebirthEvent:FireServer("Update")
                    Cfg.TargetStrength = Cfg.TargetStrength + Cfg.RebirthInc
                    RebirthStatus:SetDesc("进度: " .. gameRebirths .. "/" .. Cfg.TargetRebirthCount .. " | 目标力量: " .. Cfg.TargetStrength)
                    task.wait(Cfg.RebirthCooldown)
                else
                    RebirthStatus:SetDesc("力量: " .. math.floor(currentStr) .. "/" .. Cfg.TargetStrength .. " | 重生: " .. gameRebirths .. "/" .. Cfg.TargetRebirthCount)
                end
            end)
        end
    end
end)

task.spawn(function()
    local rebirthEvent
    pcall(function() rebirthEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RebirthEvent") end)
    while true do
        task.wait(Cfg.RebirthCheckInterval)
        if Cfg.InfiniteRebirth and rebirthEvent then
            pcall(function()
                local currentStr = getCurrentStrength()
                local gameRebirths = getCurrentRebirths()
                if currentStr >= Cfg.BaseStrength then
                    rebirthEvent:FireServer("Update")
                    InfiniteStatus:SetDesc("正在重生... 已重生 " .. gameRebirths .. " 次")
                    task.wait(Cfg.RebirthCooldown)
                else
                    InfiniteStatus:SetDesc("力量: " .. math.floor(currentStr) .. "/" .. Cfg.BaseStrength .. " | 已重生: " .. gameRebirths .. " 次")
                end
            end)
        else
            InfiniteStatus:SetDesc("待机中...")
        end
    end
end)

task.spawn(function()
    while SG.Parent do
        task.wait(60)
        if Cfg.AntiAfk then
            pcall(function()
                local VirtualInputManager = game:GetService("VirtualInputManager")
                VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, true, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, false, false, game)
            end)
        end
    end
end)

task.spawn(function()
    while SG.Parent do
        local elapsedTime = tick() - Cfg.ScriptStartTime
        local hours = math.floor(elapsedTime / 3600)
        local mins = math.floor((elapsedTime % 3600) / 60)
        local secs = math.floor(elapsedTime % 60)
        LabelReps.Text = "总训练: " .. fmt(Cfg.TotalReps)
        LabelRebirth.Text = "总转生: " .. fmt(getCurrentRebirths())
        LabelTime.Text = "总时长: " .. string.format("%02d:%02d:%02d", hours, mins, secs)
        task.wait(0.5)
    end
end)

player.Idled:Connect(function()
    if Cfg.AntiAfk then
        pcall(function()
            local VirtualInputManager = game:GetService("VirtualInputManager")
            VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, true, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, false, false, game)
        end)
    end
end)

applyWalkSpeed()
if Cfg.AntiIdleKick then applyAntiIdleKick() end

do
local T = {
	lockEnd = 2,
	ascentEnd = 6,
	orbitEnd = 9.5,
	pullEnd = 12.5,
	holdEnd = 13.5,
	swoopEnd = 17,
	fireT = 21.5,
	groundT = 23.4,
	imp = 25,
	endT = 32,
}

local SOUNDS = {
	click = "rbxasset://sounds/switch.wav",
	select = "rbxasset://sounds/electronicpingshort.wav",
	lock = "rbxasset://sounds/electronicpingshort.wav",
	whoosh = "rbxasset://sounds/Rocket whoosh 01.wav",
	charge = "rbxasset://sounds/Rocket whoosh 01.wav",
	fire = "rbxasset://sounds/Rocket shot.wav",
	boom = "rbxasset://sounds/impact_explosion_03.mp3",
}

local WEAPONS = {
	{ id = "StarDestroyer", name = "歼星炮", desc = "轨道巨炮 · 红色湮灭光束", icon = "☄" },
}

local NK, CK = NumberSequenceKeypoint.new, ColorSequenceKeypoint.new
local FLAT = CFrame.Angles(0, 0, math.rad(90))
local RED = Color3.fromRGB(255, 56, 56)

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end

local function vpart(props, parent)
	local p = new("Part", {
		Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
		Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
	}, nil)
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end

local function bigSphere(parent, pos, diameter, color, material, transparency)
	local p
	if diameter <= 2048 then
		p = vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * diameter, Position = pos, Color = color, Material = material, Transparency = transparency }, parent)
	else
		p = vpart({ Size = Vector3.one * 2048, Position = pos, Color = color, Material = material, Transparency = transparency }, parent)
		new("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Scale = Vector3.one * (diameter / 2048) }, p)
	end
	return p
end

local function clamp01(x) return math.clamp(x, 0, 1) end
local function lerp(a, b, t) return a + (b - a) * t end
local function smooth(t) t = clamp01(t); return t * t * (3 - 2 * t) end
local function gauss() return math.random() + math.random() + math.random() - 1.5 end
local function rotY(v, a) return CFrame.Angles(0, a, 0):VectorToWorldSpace(v) end
local function randDir()
	local z = math.random() * 2 - 1
	local a = math.random() * math.pi * 2
	local r = math.sqrt(1 - z * z)
	return Vector3.new(r * math.cos(a), z, r * math.sin(a))
end
local function tween(inst, time, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local fxFolder = new("Folder", { Name = "SpaceCannonFX" }, workspace)

local function playSound(id, volume, speed, looped)
	if not id or id == "" then return nil end
	local s = new("Sound", { SoundId = id, Volume = volume or 1, PlaybackSpeed = speed or 1, Looped = looped or false }, game:GetService("SoundService"))
	s:Play()
	if not looped then game:GetService("Debris"):AddItem(s, 8) end
	return s
end

local state = "idle"
local selectedWeapon = nil
local lastFire = -1e9

local function setFlash(a, color)
	if color then
		local flashGui = Instance.new("Frame", SG)
		flashGui.Size = UDim2.fromScale(1, 1)
		flashGui.BackgroundColor3 = color
		flashGui.BackgroundTransparency = 1 - clamp01(a)
		flashGui.BorderSizePixel = 0
		flashGui.ZIndex = 100
		flashGui.Active = false
		game:GetService("Debris"):AddItem(flashGui, 0.5)
	else
		local flashGui = Instance.new("Frame", SG)
		flashGui.Size = UDim2.fromScale(1, 1)
		flashGui.BackgroundColor3 = Color3.new(1, 1, 1)
		flashGui.BackgroundTransparency = 1 - clamp01(a)
		flashGui.BorderSizePixel = 0
		flashGui.ZIndex = 100
		flashGui.Active = false
		game:GetService("Debris"):AddItem(flashGui, 0.5)
	end
end

local function showBars(on) end

local function setCaption(text, color)
	if text == "" then return end
	WindUI:Notify({ Title = "系统提示", Content = text, Duration = 2 })
end

local function toast(msg)
	WindUI:Notify({ Title = "提示", Content = msg, Duration = 2 })
end

local fx = {}
local function ensureFx()
	if fx.cc then return end
	fx.cc = new("ColorCorrectionEffect", { Name = "SC_CC" }, Lighting)
	fx.bloom = new("BloomEffect", { Name = "SC_Bloom", Intensity = 0.5, Size = 28, Threshold = 1 }, Lighting)
	fx.blur = new("BlurEffect", { Name = "SC_Blur", Size = 0 }, Lighting)
end
local function clearFx()
	for k, v in pairs(fx) do v:Destroy() fx[k] = nil end
end

local savedLighting = nil
local function enterSpaceLighting()
	if savedLighting then return end
	savedLighting = { props = {}, removed = {} }
	for _, k in ipairs({ "ClockTime", "Ambient", "OutdoorAmbient", "Brightness", "FogStart", "FogEnd", "FogColor", "ExposureCompensation" }) do
		savedLighting.props[k] = Lighting[k]
	end
	for _, c in ipairs(Lighting:GetChildren()) do
		if c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("Clouds") then
			savedLighting.removed[#savedLighting.removed + 1] = c
			c.Parent = nil
		end
	end
	Lighting.ClockTime = 14
	Lighting.Ambient = Color3.fromRGB(26, 30, 46)
	Lighting.OutdoorAmbient = Color3.fromRGB(34, 40, 62)
	Lighting.Brightness = 3.2
	Lighting.FogStart = 1e8
	Lighting.FogEnd = 1e8
	Lighting.ExposureCompensation = 0
	savedLighting.sky = new("Sky", { Name = "SC_Sky", SkyboxBk = "", SkyboxDn = "", SkyboxFt = "", SkyboxLf = "", SkyboxRt = "", SkyboxUp = "", StarCount = 0, CelestialBodiesShown = false }, Lighting)
end
local function restoreLighting()
	if not savedLighting then return end
	if savedLighting.sky then savedLighting.sky:Destroy() end
	for k, v in pairs(savedLighting.props) do Lighting[k] = v end
	for _, c in ipairs(savedLighting.removed) do c.Parent = Lighting end
	savedLighting = nil
end

local function setControls(enabled)
	pcall(function()
		local pm = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		local c = pm:GetControls()
		if enabled then c:Enable() else c:Disable() end
	end)
end
local function setCoreGui(enabled)
	pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, enabled) end)
end

local impactFlash = { t = -1e9, a = 0 }
local impactShake = { t = -1e9, amp = 0 }
local function impactFlashValue()
	local e = os.clock() - impactFlash.t
	if e < 0 or e > 2.4 then return 0 end
	return impactFlash.a * (1 - e / 2.4) ^ 1.5
end
local function impactShakeAmount()
	local e = os.clock() - impactShake.t
	if e < 0 or e > 3.5 then return 0 end
	return impactShake.amp * (1 - e / 3.5) ^ 2
end
local function shakeCF(cf, amp, t, rotAmp)
	if amp <= 0.001 then return cf end
	local nx = math.noise(t * 23, 1.3, 0) * 2
	local ny = math.noise(t * 27, 5.1, 0) * 2
	local nz = math.noise(t * 19, 9.7, 0) * 2
	return cf * CFrame.new(nx * amp, ny * amp, 0) * CFrame.Angles(ny * rotAmp, nx * rotAmp, nz * rotAmp * 0.5)
end

local wasShaking = false
RunService.RenderStepped:Connect(function()
	if state ~= "cinematic" then
		local f = impactFlashValue()
		if f > 0.003 then setFlash(f) end
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			local a = impactShakeAmount()
			if a > 0.01 then
				wasShaking = true
				local t = os.clock()
				hum.CameraOffset = Vector3.new(math.noise(t * 25, 1, 0), math.noise(t * 31, 2, 0), math.noise(t * 17, 3, 0)) * 2 * a
			elseif wasShaking then
				wasShaking = false
				hum.CameraOffset = Vector3.zero
			end
		end
	end
end)

local function starFlare(part, size, color)
	local bb = new("BillboardGui", { Size = UDim2.fromOffset(size, size), AlwaysOnTop = true, LightInfluence = 0, Adornee = part, MaxDistance = 1e9 }, part)
	local function bar(len, thick, rot, tr)
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(len, 0, 0, thick), BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0, Rotation = rot }, bb)
		new("UIGradient", { Transparency = NumberSequence.new({ NK(0, 1), NK(0.5, 0), NK(1, 1) }) }, f)
	end
	local function glow(s, tr)
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0 }, bb)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	end
	glow(0.55, 0.93) glow(0.3, 0.82) glow(0.14, 0.55) glow(0.06, 0)
	bar(1, 3, 0, 0.1) bar(1, 3, 90, 0.1) bar(0.5, 2, 45, 0.35) bar(0.5, 2, -45, 0.35)
	return bb
end

local function makeBeam(parent, a0, a1, width, color, transparency)
	return new("Beam", { Attachment0 = a0, Attachment1 = a1, Width0 = width, Width1 = width, Color = ColorSequence.new(color), LightEmission = 1, LightInfluence = 0, Transparency = NumberSequence.new(transparency), FaceCamera = true, Segments = 1, Texture = "" }, parent)
end

local function makeLaser(folder, startPos, widths)
	local p0 = vpart({ Transparency = 1, Size = Vector3.one, Position = startPos }, folder)
	local p1 = vpart({ Transparency = 1, Size = Vector3.one, Position = startPos }, folder)
	local at0 = new("Attachment", {}, p0)
	local at1 = new("Attachment", {}, p1)
	local layers = {
		{ w = widths[1], col = Color3.fromRGB(255, 30, 30), tr = 0.55 },
		{ w = widths[2], col = Color3.fromRGB(255, 70, 45), tr = 0.1 },
		{ w = widths[3], col = Color3.fromRGB(255, 255, 255), tr = 0 },
	}
	local beams = {}
	for _, L in ipairs(layers) do
		beams[#beams + 1] = { beam = makeBeam(p0, at0, at1, 0, L.col, L.tr), w = L.w }
	end
	local laser = { p0 = p0, p1 = p1 }
	function laser.setEnd(pos) p1.Position = pos end
	function laser.setWidth(k)
		for _, b in ipairs(beams) do b.beam.Width0 = b.w * k b.beam.Width1 = b.w * k end
	end
	function laser.destroy() p0:Destroy() p1:Destroy() end
	return laser
end

local function makeMarker(radius)
	local f = new("Folder", { Name = "Marker" }, fxFolder)
	local outer = vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, radius * 2, radius * 2), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 40, 40), Transparencdo
local T = {
	lockEnd = 2, ascentEnd = 6, orbitEnd = 9.5, pullEnd = 12.5,
	holdEnd = 13.5, swoopEnd = 17, fireT = 21.5, groundT = 23.4,
	imp = 25, endT = 32,
}
local SOUNDS = {
	click = "rbxasset://sounds/switch.wav", select = "rbxasset://sounds/electronicpingshort.wav",
	lock = "rbxasset://sounds/electronicpingshort.wav", whoosh = "rbxasset://sounds/Rocket whoosh 01.wav",
	charge = "rbxasset://sounds/Rocket whoosh 01.wav", fire = "rbxasset://sounds/Rocket shot.wav",
	boom = "rbxasset://sounds/impact_explosion_03.mp3",
}
local NK, CK = NumberSequenceKeypoint.new, ColorSequenceKeypoint.new
local FLAT = CFrame.Angles(0, 0, math.rad(90))
local RED = Color3.fromRGB(255, 56, 56)
local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in pairs(props) do inst[k] = v end
	if parent then inst.Parent = parent end
	return inst
end
local function vpart(props, parent)
	local p = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, nil)
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end
local function bigSphere(parent, pos, diameter, color, material, transparency)
	local p
	if diameter <= 2048 then
		p = vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * diameter, Position = pos, Color = color, Material = material, Transparency = transparency }, parent)
	else
		p = vpart({ Size = Vector3.one * 2048, Position = pos, Color = color, Material = material, Transparency = transparency }, parent)
		new("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Scale = Vector3.one * (diameter / 2048) }, p)
	end
	return p
end
local function clamp01(x) return math.clamp(x, 0, 1) end
local function lerp(a, b, t) return a + (b - a) * t end
local function smooth(t) t = clamp01(t); return t * t * (3 - 2 * t) end
local function gauss() return math.random() + math.random() + math.random() - 1.5 end
local function rotY(v, a) return CFrame.Angles(0, a, 0):VectorToWorldSpace(v) end
local function randDir()
	local z = math.random() * 2 - 1
	local a = math.random() * math.pi * 2
	local r = math.sqrt(1 - z * z)
	return Vector3.new(r * math.cos(a), z, r * math.sin(a))
end
local function tween(inst, time, props, style, dir)
	local tw = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local fxFolder = new("Folder", { Name = "SpaceCannonFX" }, workspace)
local function playSound(id, volume, speed, looped)
	if not id or id == "" then return nil end
	local s = new("Sound", { SoundId = id, Volume = volume or 1, PlaybackSpeed = speed or 1, Looped = looped or false }, game:GetService("SoundService"))
	s:Play()
	if not looped then game:GetService("Debris"):AddItem(s, 8) end
	return s
end
local state = "idle"
local selectedWeapon = nil
local lastFire = -1e9
local function setFlash(a, color)
	local flashGui = Instance.new("Frame", SG)
	flashGui.Size = UDim2.fromScale(1, 1)
	flashGui.BackgroundColor3 = color or Color3.new(1, 1, 1)
	flashGui.BackgroundTransparency = 1 - clamp01(a)
	flashGui.BorderSizePixel = 0
	flashGui.ZIndex = 100
	flashGui.Active = false
	game:GetService("Debris"):AddItem(flashGui, 0.5)
end
local function showBars(on) end
local function setCaption(text, color)
	if text == "" then return end
	WindUI:Notify({ Title = "系统提示", Content = text, Duration = 2 })
end
local function toast(msg)
	WindUI:Notify({ Title = "提示", Content = msg, Duration = 2 })
end
local fx = {}
local function ensureFx()
	if fx.cc then return end
	fx.cc = new("ColorCorrectionEffect", { Name = "SC_CC" }, Lighting)
	fx.bloom = new("BloomEffect", { Name = "SC_Bloom", Intensity = 0.5, Size = 28, Threshold = 1 }, Lighting)
	fx.blur = new("BlurEffect", { Name = "SC_Blur", Size = 0 }, Lighting)
end
local function clearFx()
	for k, v in pairs(fx) do v:Destroy() fx[k] = nil end
end
local savedLighting = nil
local function enterSpaceLighting()
	if savedLighting then return end
	savedLighting = { props = {}, removed = {} }
	for _, k in ipairs({ "ClockTime", "Ambient", "OutdoorAmbient", "Brightness", "FogStart", "FogEnd", "FogColor", "ExposureCompensation" }) do
		savedLighting.props[k] = Lighting[k]
	end
	for _, c in ipairs(Lighting:GetChildren()) do
		if c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("Clouds") then
			savedLighting.removed[#savedLighting.removed + 1] = c
			c.Parent = nil
		end
	end
	Lighting.ClockTime = 14
	Lighting.Ambient = Color3.fromRGB(26, 30, 46)
	Lighting.OutdoorAmbient = Color3.fromRGB(34, 40, 62)
	Lighting.Brightness = 3.2
	Lighting.FogStart = 1e8
	Lighting.FogEnd = 1e8
	Lighting.ExposureCompensation = 0
	savedLighting.sky = new("Sky", { Name = "SC_Sky", SkyboxBk = "", SkyboxDn = "", SkyboxFt = "", SkyboxLf = "", SkyboxRt = "", SkyboxUp = "", StarCount = 0, CelestialBodiesShown = false }, Lighting)
end
local function restoreLighting()
	if not savedLighting then return end
	if savedLighting.sky then savedLighting.sky:Destroy() end
	for k, v in pairs(savedLighting.props) do Lighting[k] = v end
	for _, c in ipairs(savedLighting.removed) do c.Parent = Lighting end
	savedLighting = nil
end
local function setControls(enabled)
	pcall(function()
		local pm = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		local c = pm:GetControls()
		if enabled then c:Enable() else c:Disable() end
	end)
end
local function setCoreGui(enabled)
	pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, enabled) end)
end
local impactFlash = { t = -1e9, a = 0 }
local impactShake = { t = -1e9, amp = 0 }
local function impactFlashValue()
	local e = os.clock() - impactFlash.t
	if e < 0 or e > 2.4 then return 0 end
	return impactFlash.a * (1 - e / 2.4) ^ 1.5
end
local function impactShakeAmount()
	local e = os.clock() - impactShake.t
	if e < 0 or e > 3.5 then return 0 end
	return impactShake.amp * (1 - e / 3.5) ^ 2
end
local function shakeCF(cf, amp, t, rotAmp)
	if amp <= 0.001 then return cf end
	local nx = math.noise(t * 23, 1.3, 0) * 2
	local ny = math.noise(t * 27, 5.1, 0) * 2
	local nz = math.noise(t * 19, 9.7, 0) * 2
	return cf * CFrame.new(nx * amp, ny * amp, 0) * CFrame.Angles(ny * rotAmp, nx * rotAmp, nz * rotAmp * 0.5)
end
local wasShaking = false
RunService.RenderStepped:Connect(function()
	if state ~= "cinematic" then
		local f = impactFlashValue()
		if f > 0.003 then setFlash(f) end
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			local a = impactShakeAmount()
			if a > 0.01 then
				wasShaking = true
				local t = os.clock()
				hum.CameraOffset = Vector3.new(math.noise(t * 25, 1, 0), math.noise(t * 31, 2, 0), math.noise(t * 17, 3, 0)) * 2 * a
			elseif wasShaking then
				wasShaking = false
				hum.CameraOffset = Vector3.zero
			end
		end
	end
end)
local function starFlare(part, size, color)
	local bb = new("BillboardGui", { Size = UDim2.fromOffset(size, size), AlwaysOnTop = true, LightInfluence = 0, Adornee = part, MaxDistance = 1e9 }, part)
	local function bar(len, thick, rot, tr)
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(len, 0, 0, thick), BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0, Rotation = rot }, bb)
		new("UIGradient", { Transparency = NumberSequence.new({ NK(0, 1), NK(0.5, 0), NK(1, 1) }) }, f)
	end
	local function glow(s, tr)
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(s, s), BackgroundColor3 = color, BackgroundTransparency = tr, BorderSizePixel = 0 }, bb)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	end
	glow(0.55, 0.93) glow(0.3, 0.82) glow(0.14, 0.55) glow(0.06, 0)
	bar(1, 3, 0, 0.1) bar(1, 3, 90, 0.1) bar(0.5, 2, 45, 0.35) bar(0.5, 2, -45, 0.35)
	return bb
end
local function makeBeam(parent, a0, a1, width, color, transparency)
	return new("Beam", { Attachment0 = a0, Attachment1 = a1, Width0 = width, Width1 = width, Color = ColorSequence.new(color), LightEmission = 1, LightInfluence = 0, Transparency = NumberSequence.new(transparency), FaceCamera = true, Segments = 1, Texture = "" }, parent)
end
local function makeLaser(folder, startPos, widths)
	local p0 = vpart({ Transparency = 1, Size = Vector3.one, Position = startPos }, folder)
	local p1 = vpart({ Transparency = 1, Size = Vector3.one, Position = startPos }, folder)
	local at0 = new("Attachment", {}, p0)
	local at1 = new("Attachment", {}, p1)
	local layers = {
		{ w = widths[1], col = Color3.fromRGB(255, 30, 30), tr = 0.55 },
		{ w = widths[2], col = Color3.fromRGB(255, 70, 45), tr = 0.1 },
		{ w = widths[3], col = Color3.fromRGB(255, 255, 255), tr = 0 },
	}
	local beams = {}
	for _, L in ipairs(layers) do beams[#beams + 1] = { beam = makeBeam(p0, at0, at1, 0, L.col, L.tr), w = L.w } end
	local laser = { p0 = p0, p1 = p1 }
	function laser.setEnd(pos) p1.Position = pos end
	function laser.setWidth(k) for _, b in ipairs(beams) do b.beam.Width0 = b.w * k b.beam.Width1 = b.w * k end end
	function laser.destroy() p0:Destroy() p1:Destroy() end
	return laser
end
local function makeMarker(radius)
	local f = new("Folder", { Name = "Marker" }, fxFolder)
	local outer = vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, radius * 2, radius * 2), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 40, 40), Transparency = 0.78 }, f)
	local inner = vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, radius * 1.1, radius * 1.1), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 120, 60), Transparency = 0.6 }, f)
	local m = { outer = outer, inner = inner }
	function m.place(pos) outer.CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * FLAT inner.CFrame = CFrame.new(pos + Vector3.new(0, 0.7, 0)) * FLAT end
	function m.destroy() f:Destroy() end
	return m
end
local function makeReticle(radius, pos)
	local f = new("Folder", { Name = "Reticle" }, fxFolder)
	local R = radius
	local y = pos.Y + 0.7
	local c = Vector3.new(pos.X, y, pos.Z)
	local function blk(sx, sz, col, tr) return vpart({ Size = Vector3.new(sx, 0.5, sz), Material = Enum.Material.Neon, Color = col or RED, Transparency = tr or 0 }, f) end
	local function onRing(part, r, a, tangent)
		local p = c + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		local dir = tangent and Vector3.new(-math.sin(a), 0, math.cos(a)) or Vector3.new(-math.cos(a), 0, -math.sin(a))
		part.CFrame = CFrame.lookAt(p, p + dir)
	end
	local disc = vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, R * 2, R * 2), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 40, 40), Transparency = 0.86, CFrame = CFrame.new(c) * FLAT }, f)
	local edge = {}
	for i = 1, 120 do edge[i] = blk(1.4, 2 * math.pi * R / 120 * 1.06) onRing(edge[i], R, i / 120 * math.pi * 2, true) end
	local ticks = {}
	for i = 1, 72 do local big = i % 6 == 0 ticks[i] = { part = blk(big and 1.6 or 0.8, big and 11 or 5), a = i / 72 * math.pi * 2 } end
	local brackets = {}
	for i = 1, 4 do
		brackets[#brackets + 1] = { part = blk(1.8, 24), a = i * math.pi / 2, tangent = true }
		brackets[#brackets + 1] = { part = blk(1.8, 14), a = i * math.pi / 2, tangent = false }
	end
	local inner = {}
	for i = 1, 28 do inner[i] = blk(0.9, 2 * math.pi * 7 / 28 * 1.1) onRing(inner[i], 7, i / 28 * math.pi * 2, true) end
	local crossA = blk(0.9, 18) crossA.CFrame = CFrame.lookAt(c, c + Vector3.xAxis)
	local crossB = blk(0.9, 18) crossB.CFrame = CFrame.lookAt(c, c + Vector3.zAxis)
	local sweep = {}
	for i = 1, 9 do sweep[i] = blk(i == 1 and 1.6 or 1.2, R * 0.98, Color3.fromRGB(255, 120, 90), i == 1 and 0 or 0.12 * i) end
	local pulse = {}
	for i = 1, 90 do pulse[i] = blk(1.2, 2 * math.pi * R / 90 * 1.2, Color3.fromRGB(255, 150, 110), 0.3) end
	local reticle = {}
	function reticle.update(t)
		for _, tk in ipairs(ticks) do
			local a = tk.a + t * 0.35
			local len = tk.part.Size.Z
			local r = R - len * 0.5 - 1
			local p = c + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
			tk.part.CFrame = CFrame.lookAt(p, c)
		end
		local rb = lerp(R * 0.74, R * 0.52, 0.5 + 0.5 * math.sin(t * 1.6))
		for _, b in ipairs(brackets) do
			local a = b.a + t * 0.8
			local p = c + Vector3.new(math.cos(a) * rb, 0, math.sin(a) * rb)
			local dir
			if b.tangent then dir = Vector3.new(-math.sin(a), 0, math.cos(a)) else dir = Vector3.new(-math.cos(a), 0, -math.sin(a)) p += dir * 7 end
			local pp = b.tangent and p + dir * 0 or p
			b.part.CFrame = CFrame.lookAt(pp, pp + dir)
		end
		for i, s in ipairs(sweep) do
			local a = t * 2.2 - (i - 1) * 0.07
			local d = Vector3.new(math.cos(a), 0, math.sin(a))
			local p = c + d * (R * 0.49)
			s.CFrame = CFrame.lookAt(p, p + d)
		end
		local k = (t * 0.55) % 1
		local pr = R * (1 - k)
		for i, p in ipairs(pulse) do
			local a = i / 90 * math.pi * 2
			p.Size = Vector3.new(1.2, 0.5, math.max(0.1, 2 * math.pi * pr / 90 * 1.2))
			p.Transparency = 0.25 + 0.75 * k
			onRing(p, math.max(pr, 0.5), a, true)
		end
		disc.Transparency = 0.82 + 0.06 * math.sin(t * 6)
	end
	function reticle.destroy() f:Destroy() end
	return reticle
end

local function groundLaser(target, travel)
	local S = target + Vector3.new(2400, 5600, -1700)
	local laser = makeLaser(fxFolder, S, { 190, 100, 42 })
	local head = vpart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.new(1, 1, 1), Size = Vector3.one * 40, Position = S }, fxFolder)
	new("PointLight", { Color = Color3.fromRGB(255, 80, 60), Range = 60, Brightness = 8 }, head)
	local flare = starFlare(head, 700, Color3.fromRGB(255, 120, 110))
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local e = os.clock() - t0
		if e < travel then
			local u = (e / travel) ^ 2.2
			local p = S:Lerp(target, u)
			laser.setEnd(p) laser.setWidth(0.35 + 0.65 * (e / travel))
			head.Position = p head.Size = Vector3.one * (40 + 60 * u)
			flare.Size = UDim2.fromOffset(300 + 700 * u, 300 + 700 * u)
		else
			local e2 = e - travel
			local k
			if e2 < 0.5 then k = 1 + 0.9 * (e2 / 0.5) elseif e2 < 2.6 then k = 1.9 else k = 1.9 * (1 - (e2 - 2.6) / 1.4) end
			k = math.max(k, 0)
			laser.setEnd(target) laser.setWidth(k)
			head.Position = target + Vector3.new(0, 4, 0)
			head.Size = Vector3.one * (20 + 90 * k)
			flare.Size = UDim2.fromOffset(200 + 800 * k, 200 + 800 * k)
			if e2 > 4.0 then conn:Disconnect() laser.destroy() head:Destroy() end
		end
	end)
end
local function explosionFX(center, isShooter)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local dist = root and (root.Position - center).Magnitude or 0
	local falloff = clamp01(1 - dist / 2600)
	playSound(SOUNDS.boom, 1.4, 0.55)
	local fire = vpart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 140, 40), Size = Vector3.one * 20, Position = center + Vector3.new(0, 10, 0), Transparency = 0.1 }, fxFolder)
	tween(fire, 1.2, { Size = Vector3.one * 340, Transparency = 1 }, Enum.EasingStyle.Quart)
	game:GetService("Debris"):AddItem(fire, 1.4)
	local core = vpart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.new(1, 1, 1), Size = Vector3.one * 10, Position = center + Vector3.new(0, 10, 0) }, fxFolder)
	tween(core, 0.7, { Size = Vector3.one * 220, Transparency = 1 }, Enum.EasingStyle.Quart)
	game:GetService("Debris"):AddItem(core, 0.9)
	local bubble = vpart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 200, 150), Size = Vector3.one * 30, Position = center, Transparency = 0.7 }, fxFolder)
	tween(bubble, 1.8, { Size = Vector3.one * 1800, Transparency = 1 })
	game:GetService("Debris"):AddItem(bubble, 2)
	for i = 1, 2 do
		local ring = vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 20, 20), Material = Enum.Material.Neon, Color = i == 1 and Color3.fromRGB(255, 170, 80) or Color3.fromRGB(255, 80, 40), Transparency = 0.45, CFrame = CFrame.new(center + Vector3.new(0, 2 + i, 0)) * FLAT }, fxFolder)
		task.delay((i - 1) * 0.18, function() tween(ring, 1.5, { Size = Vector3.new(2, 1500, 1500), Transparency = 1 }) end)
		game:GetService("Debris"):AddItem(ring, 2.2)
	end
	local cap = vpart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 150, 60), Size = Vector3.one * 60, Position = center + Vector3.new(0, 20, 0), Transparency = 0.3 }, fxFolder)
	tween(cap, 7, { Size = Vector3.one * 430, Position = center + Vector3.new(0, 560, 0), Color = Color3.fromRGB(70, 56, 50), Transparency = 1 })
	game:GetService("Debris"):AddItem(cap, 7.5)
	local stem = vpart({ Shape = Enum.PartType.Cylinder, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 120, 40), Size = Vector3.new(10, 40, 40), CFrame = CFrame.new(center + Vector3.new(0, 5, 0)) * FLAT, Transparency = 0.4 }, fxFolder)
	tween(stem, 6, { Size = Vector3.new(500, 120, 120), CFrame = CFrame.new(center + Vector3.new(0, 250, 0)) * FLAT, Color = Color3.fromRGB(80, 64, 58), Transparency = 1 })
	game:GetService("Debris"):AddItem(stem, 6.5)
	local anchor = vpart({ Transparency = 1, Size = Vector3.one, Position = center + Vector3.new(0, 4, 0) }, fxFolder)
	local att = new("Attachment", {}, anchor)
	local smoke = new("ParticleEmitter", { Enabled = false, Rate = 0, Texture = "rbxasset://textures/particles/smoke_main.dds", Lifetime = NumberRange.new(5, 9), Speed = NumberRange.new(60, 220), SpreadAngle = Vector2.new(70, 70), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-30, 30), Size = NumberSequence.new({ NK(0, 40), NK(1, 260) }), Transparency = NumberSequence.new({ NK(0, 0.35), NK(1, 1) }), Color = ColorSequence.new(Color3.fromRGB(70, 56, 48)), Drag = 2, Acceleration = Vector3.new(0, 14, 0) }, att)
	smoke:Emit(170)
	local sparks = new("ParticleEmitter", { Enabled = false, Rate = 0, Lifetime = NumberRange.new(1.2, 2.4), Speed = NumberRange.new(200, 650), SpreadAngle = Vector2.new(80, 80), Size = NumberSequence.new({ NK(0, 9), NK(1, 0) }), Transparency = NumberSequence.new({ NK(0, 0), NK(1, 1) }), Color = ColorSequence.new(Color3.fromRGB(255, 190, 80), Color3.fromRGB(255, 60, 20)), LightEmission = 1, Acceleration = Vector3.new(0, -140, 0) }, att)
	sparks:Emit(320)
	local embers = new("ParticleEmitter", { Rate = 28, Lifetime = NumberRange.new(3, 6), Speed = NumberRange.new(10, 40), SpreadAngle = Vector2.new(45, 45), Size = NumberSequence.new({ NK(0, 3), NK(1, 0) }), Transparency = NumberSequence.new({ NK(0, 0), NK(1, 1) }), Color = ColorSequence.new(Color3.fromRGB(255, 150, 60), Color3.fromRGB(255, 60, 20)), LightEmission = 1, Acceleration = Vector3.new(0, 12, 0) }, att)
	task.delay(20, function() embers.Enabled = false end)
	game:GetService("Debris"):AddItem(anchor, 30)
	impactFlash = { t = os.clock(), a = isShooter and 1 or math.max(0.35, falloff) }
	impactShake = { t = os.clock(), amp = isShooter and 14 or 3 * falloff }
end
local function touchingSelf(part)
	local ch = player.Character
	if not ch or not part.Parent then return false end
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { ch }
	return #workspace:GetPartsInPart(part, op) > 0
end
local function killSelf()
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		hum.Health = 0
		hum:ChangeState(Enum.HumanoidStateType.Dead)
		ch:BreakJoints()
	end
end
local function isCarvable(inst)
	return inst:IsA("Part") and inst.Shape == Enum.PartType.Block and inst.Anchored and inst.Size.X >= 60 and inst.Size.Z >= 60 and inst.CFrame.UpVector.Y > 0.97
end
local function raycastDown(pos, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list = { fxFolder }
	if player.Character then list[#list + 1] = player.Character end
	for _, i in ipairs(ignore) do list[#list + 1] = i end
	params.FilterDescendantsInstances = list
	return workspace:Raycast(pos + Vector3.new(0, 500, 0), Vector3.new(0, -2500, 0), params)
end
local function resolveGround(targetPos)
	local ignore = {}
	local center = targetPos
	for _ = 1, 4 do
		local r = raycastDown(center, ignore)
		if not r then break end
		center = r.Position
		if r.Instance:IsA("Terrain") or isCarvable(r.Instance) then return center, r.Instance end
		table.insert(ignore, r.Instance)
	end
	return center, nil
end
local function carveGroundPart(ground, center, folder)
	local cf, size = ground.CFrame, ground.Size
	local half = size / 2
	local lc = cf:PointToObjectSpace(center)
	local Rc, rimW, cell = 55, 24, 5
	local reach = Rc + rimW + cell * 2
	local x0 = math.max(-half.X, lc.X - reach)
	local x1 = math.min(half.X, lc.X + reach)
	local z0 = math.max(-half.Z, lc.Z - reach)
	local z1 = math.min(half.Z, lc.Z + reach)
	local D = (size.Y > 6) and math.min(22, size.Y - 1) or 22
	local molten = {}
	local function box(minx, maxx, minz, maxz, ybot, ytop)
		local sx, sz, sy = maxx - minx, maxz - minz, ytop - ybot
		if sx < 0.05 or sz < 0.05 or sy < 0.05 then return nil end
		local p = ground:Clone()
		for _, c in ipairs(p:GetChildren()) do if c:IsA("LuaSourceContainer") then c:Destroy() end end
		p.Anchored = true
		p.Size = Vector3.new(sx, sy, sz)
		p.CFrame = cf * CFrame.new((minx + maxx) / 2, (ybot + ytop) / 2, (minz + maxz) / 2)
		p.Parent = folder
		return p
	end
	local function style(p, r)
		for _, c in ipairs(p:GetChildren()) do if c:IsA("Decal") or c:IsA("Texture") then c:Destroy() end end
		if r < Rc * 0.38 then p.Material = Enum.Material.CrackedLava p.Color = Color3.fromRGB(255, 110, 20) molten[#molten + 1] = p
		elseif r < Rc * 0.78 then p.Material = Enum.Material.Basalt p.Color = Color3.fromRGB(32, 26, 24)
		elseif r < Rc then p.Material = Enum.Material.Slate p.Color = Color3.fromRGB(55, 45, 40)
		else p.Material = Enum.Material.Rock p.Color = Color3.fromRGB(78, 64, 52) end
	end
	local function heightAt(lx, lz)
		local dx, dz = lx - lc.X, lz - lc.Z
		local r = math.sqrt(dx * dx + dz * dz)
		local ang = math.atan2(dz, dx)
		local H = 18 * (1 + 0.9 * math.noise(ang * 2.3, 7.7, 0))
		local jitter = math.noise(lx * 0.15, lz * 0.15, 3.1) * 4
		if r < Rc then local k = r / Rc return -D + (D + H) * k * k * k + jitter * 0.5, r
		elseif r < Rc + rimW then local t = (r - Rc) / rimW return H * (1 - t) * (1 - t) + jitter * (1 - t), r end
		return 0, r
	end
	box(-half.X, x0, -half.Z, half.Z, -half.Y, half.Y)
	box(x1, half.X, -half.Z, half.Z, -half.Y, half.Y)
	box(x0, x1, -half.Z, z0, -half.Y, half.Y)
	box(x0, x1, z1, half.Z, -half.Y, half.Y)
	local nx = math.max(1, math.ceil((x1 - x0) / cell))
	local nz = math.max(1, math.ceil((z1 - z0) / cell))
	local wx, wz = (x1 - x0) / nx, (z1 - z0) / nz
	for iz = 0, nz - 1 do
		local zmin = z0 + iz * wz
		local zmax = zmin + wz
		local lz = (zmin + zmax) / 2
		local runStart = nil
		for ix = 0, nx do
			local isFlat, y, r = true, 0, 0
			if ix < nx then local lx = x0 + ix * wx + wx / 2 y, r = heightAt(lx, lz) isFlat = r >= Rc + rimW end
			if isFlat and ix < nx then runStart = runStart or (x0 + ix * wx)
			else
				if runStart then box(runStart, x0 + ix * wx, zmin, zmax, -half.Y, half.Y) runStart = nil end
				if ix < nx then local p = box(x0 + ix * wx, x0 + (ix + 1) * wx, zmin, zmax, -half.Y, half.Y + y) if p then style(p, r) end end
			end
		end
	end
	task.delay(9, function() for _, p in ipairs(molten) do if p.Parent then p.Material = Enum.Material.Basalt tween(p, 2, { Color = Color3.fromRGB(26, 20, 18) }) end end end)
	if molten[1] then new("PointLight", { Color = Color3.fromRGB(255, 110, 30), Range = 60, Brightness = 4 }, molten[1]) end
end
local function carveTerrain(center)
	local terrain = workspace.Terrain
	local R = 55
	local backup
	pcall(function()
		local half = Vector3.new(1, 1, 1) * (R * 1.8)
		local region = Region3.new(center - half, center + half):ExpandToGrid(4)
		local copy = terrain:CopyRegion(region)
		local minCorner = region.CFrame.Position - region.Size / 2
		backup = { copy = copy, corner = Vector3int16.new(math.floor(minCorner.X / 4), math.floor(minCorner.Y / 4), math.floor(minCorner.Z / 4)) }
	end)
	pcall(function()
		terrain:FillBall(center + Vector3.new(0, R * 0.62, 0), R * 1.05, Enum.Material.Air)
		terrain:FillBall(center + Vector3.new(0, -R * 0.43 - 4, 0), 14, Enum.Material.CrackedLava)
		for i = 1, 36 do local a = (i / 36) * math.pi * 2 local rr = R * (0.86 + math.random() * 0.2) terrain:FillBall(center + Vector3.new(math.cos(a) * rr, 2 + math.random() * 3, math.sin(a) * rr), 5 + math.random() * 5, Enum.Material.Basalt) end
	end)
	return backup
end
local function blastHumanoids(center)
	local op = OverlapParams.new()
	op.MaxParts = 3000
	local seen = {}
	for _, part in ipairs(workspace:GetPartBoundsInRadius(center, 280, op)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and not seen[hum] and hum.Health > 0 then
			seen[hum] = true
			local isSelf = model == player.Character
			local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or part
			local offset = root.Position - center
			local d = offset.Magnitude
			if d <= 100 then if isSelf then killSelf() else hum.Health = 0 end
			else
				local t = (d - 100) / (280 - 100)
				local dir = d > 0.01 and offset.Unit or Vector3.yAxis
				if root:IsA("BasePart") then root.AssemblyLinearVelocity = dir * (170 * (1 - t)) + Vector3.new(0, 80 * (1 - t), 0) end
				hum.Health = hum.Health - 180 * (1 - t) ^ 1.2
			end
		end
	end
end
local function blastParts(center, groundInst, folder)
	local op = OverlapParams.new()
	op.MaxParts = 1500
	local n = 0
	for _, p in ipairs(workspace:GetPartBoundsInRadius(center, 55 + 24, op)) do
		if p ~= groundInst and not p:IsA("Terrain") and not p:IsDescendantOf(folder) and not p:IsDescendantOf(fxFolder) then
			local model = p:FindFirstAncestorOfClass("Model")
			local isChar = model and model:FindFirstChildOfClass("Humanoid")
			local big = math.max(p.Size.X, p.Size.Y, p.Size.Z) > 120
			if not isChar and not (big and p.Anchored) and n < 600 then
				n += 1
				p:BreakJoints()
				p.Anchored = false
				local off = p.Position - center
				local dir = Vector3.new(off.X, 0, off.Z)
				dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
				p.AssemblyLinearVelocity = dir * (60 + math.random() * 170) + Vector3.new(0, 100 + math.random() * 150, 0)
				p.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 14
				game:GetService("Debris"):AddItem(p, 14)
			end
		end
	end
end
local rockMats = { Enum.Material.Slate, Enum.Material.Basalt, Enum.Material.Granite }
local function spawnRocks(center, debrisFolder)
	for i = 1, 48 do
		local s = 3 + math.random() * 10
		local ang = math.random() * math.pi * 2
		local spd = 70 + math.random() * 130
		local shade = math.random(40, 80)
		local rock = new("Part", { Size = Vector3.new(s * (0.7 + math.random() * 0.6), s * (0.7 + math.random() * 0.6), s * (0.7 + math.random() * 0.6)), Material = rockMats[math.random(1, #rockMats)], Color = Color3.fromRGB(shade + 14, shade + 4, shade - 6), Anchored = false, CanCollide = true, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth, CFrame = CFrame.new(center + Vector3.new((math.random() - 0.5) * 40, 8 + math.random() * 10, (math.random() - 0.5) * 40)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6) }, debrisFolder)
		rock.AssemblyLinearVelocity = Vector3.new(math.cos(ang) * spd, 110 + math.random() * 160, math.sin(ang) * spd)
		rock.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 12
		if i % 3 == 0 then new("Fire", { Size = 9, Heat = 0, Color = Color3.fromRGB(255, 120, 30), SecondaryColor = Color3.fromRGB(120, 20, 10) }, rock) end
		game:GetService("Debris"):AddItem(rock, 18)
		task.spawn(function()
			local t0 = os.clock()
			while rock.Parent and os.clock() - t0 < 6 do
				if rock.AssemblyLinearVelocity.Magnitude > 28 and touchingSelf(rock) then killSelf() end
				task.wait(0.06)
			end
		end)
	end
end

local function spawnSpires(center, folder)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = { fxFolder }
	if player.Character then ex[#ex + 1] = player.Character end
	params.FilterDescendantsInstances = ex
	for _ = 1, 24 do
		local ang = math.random() * math.pi * 2
		local rad = 55 * 0.7 + math.random() * (55 * 0.3 + 24 + 70)
		local px, pz = center.X + math.cos(ang) * rad, center.Z + math.sin(ang) * rad
		local r = workspace:Raycast(Vector3.new(px, center.Y + 300, pz), Vector3.new(0, -700, 0), params)
		local gy = r and r.Position.Y or center.Y
		local w = 7 + math.random() * 11
		local h = 50 + math.random() * 90
		local h1, h2, h3 = h * 0.46, h * 0.34, h * 0.26
		local mat = rockMats[math.random(1, #rockMats)]
		local shade = math.random(38, 70)
		local model = Instance.new("Model")
		local function seg(sz, yoff, yaw)
			return new("Part", { Size = sz, Anchored = true, CanCollide = true, Material = mat, Color = Color3.fromRGB(shade + 12, shade + 2, shade - 8), CFrame = CFrame.new(0, yoff, 0) * CFrame.Angles(0, yaw, 0), TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, model)
		end
		local base = seg(Vector3.new(w, h1, w), 0, 0)
		seg(Vector3.new(w * 0.64, h2, w * 0.64), h1 / 2 + h2 / 2 - 1.5, math.rad(20))
		local tip = seg(Vector3.new(w * 0.34, h3, w * 0.34), h1 / 2 + h2 + h3 / 2 - 3, math.rad(-25))
		tip.Material = Enum.Material.CrackedLava
		tip.Color = Color3.fromRGB(255, 100, 20)
		model.PrimaryPart = base
		local final = CFrame.new(px, gy + h1 / 2 - 7, pz) * CFrame.Angles((math.random() - 0.5) * 0.6, math.random() * 6, (math.random() - 0.5) * 0.6)
		local start = final * CFrame.new(0, -(h + 10), 0)
		model:PivotTo(start)
		model.Parent = folder
		local cv = Instance.new("CFrameValue")
		cv.Value = start
		cv.Changed:Connect(function(v) if model.Parent then model:PivotTo(v) end end)
		task.delay(math.random() * 0.4, function()
			tween(cv, 0.5 + math.random() * 0.35, { Value = final }, Enum.EasingStyle.Quart)
			for _ = 1, 18 do
				if not model.Parent then break end
				for _, p in ipairs(model:GetChildren()) do if touchingSelf(p) then killSelf() end end
				task.wait(0.06)
			end
			cv:Destroy()
		end)
	end
end
local craters = {}
local function restoreAll()
	for i = #craters, 1, -1 do
		local c = craters[i]
		if c.folder then c.folder:Destroy() end
		for _, b in ipairs(c.backups) do b.part.Parent = b.parent or workspace end
		if c.terrain then pcall(function() workspace.Terrain:PasteRegion(c.terrain.copy, c.terrain.corner, true) end) end
		craters[i] = nil
	end
end
local function doImpact(targetPos, isShooter)
	local center, groundInst = resolveGround(targetPos)
	explosionFX(center, isShooter)
	blastHumanoids(center)
	local record = { backups = {} }
	local folder = new("Folder", { Name = "SpaceCannonCrater" }, workspace)
	record.folder = folder
	if groundInst and groundInst:IsA("Terrain") then
		record.terrain = carveTerrain(center)
	elseif groundInst then
		local parent = groundInst.Parent
		carveGroundPart(groundInst, center, folder)
		table.insert(record.backups, { part = groundInst, parent = parent })
		groundInst.Parent = nil
	end
	craters[#craters + 1] = record
	if true then blastParts(center, groundInst, folder) end
	local debrisFolder = new("Folder", { Name = "SpaceCannonDebris" }, workspace)
	game:GetService("Debris"):AddItem(debrisFolder, 20)
	spawnRocks(center, debrisFolder)
	spawnSpires(center, folder)
	if 120 > 0 then
		task.delay(120, function() if state ~= "cinematic" then restoreAll() end end)
	end
end
local function buildStars(folder, GC)
	local palette = { Color3.fromRGB(190, 215, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 232, 190), Color3.fromRGB(255, 190, 140), Color3.fromRGB(160, 190, 255) }
	local bn = Vector3.new(0.35, 0.85, 0.4).Unit
	local e1 = bn:Cross(Vector3.yAxis).Unit
	local e2 = bn:Cross(e1).Unit
	local coreA = 1.2
	local function addStar(dir, radius, sizeScale)
		local s = (55 + (math.random() ^ 3) * 140) * sizeScale
		vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * s, Position = GC + dir * radius, Material = Enum.Material.Neon, Color = palette[math.random(1, #palette)] }, folder)
	end
	for i = 1, 1500 do
		addStar(randDir(), 29000 + math.random() * 2500, 0.8)
		if i % 300 == 0 then task.wait() end
	end
	local made = 0
	while made < 3200 do
		local a = math.random() * math.pi * 2
		local da = math.abs(((a - coreA + math.pi) % (math.pi * 2)) - math.pi)
		if math.random() < 0.35 + 0.65 * math.exp(-da * da / 0.9) then
			local dir = (e1 * math.cos(a) + e2 * math.sin(a) + bn * gauss() * 0.2).Unit
			addStar(dir, 28500 + math.random() * 3000, 1 + 0.5 * math.exp(-da * da / 0.9))
			made += 1
			if made % 300 == 0 then task.wait() end
		end
	end
	local hazeColors = { Color3.fromRGB(100, 120, 255), Color3.fromRGB(255, 100, 170), Color3.fromRGB(255, 170, 90), Color3.fromRGB(110, 255, 230) }
	for i = 1, 56 do
		local a = math.random() * math.pi * 2
		local dir = (e1 * math.cos(a) + e2 * math.sin(a) + bn * gauss() * 0.12).Unit
		bigSphere(folder, GC + dir * 26500, 5000 + math.random() * 6500, hazeColors[math.random(1, #hazeColors)], Enum.Material.Neon, 0.93 + math.random() * 0.04)
	end
	bigSphere(folder, GC + (e1 * math.cos(coreA) + e2 * math.sin(coreA)).Unit * 26000, 15000, Color3.fromRGB(255, 200, 140), Enum.Material.Neon, 0.9)
	for i = 1, 38 do
		local a = math.random() * math.pi * 2
		local dir = (e1 * math.cos(a) + e2 * math.sin(a) + bn * gauss() * 0.1).Unit
		bigSphere(folder, GC + dir * 25000, 3200 + math.random() * 4200, Color3.fromRGB(4, 4, 8), Enum.Material.SmoothPlastic, 0.82)
	end
end
local function buildGalaxy(folder, GC)
	local ARMS, R = 3, 6000
	for i = 1, 1500 do
		local arm = i % ARMS
		local tt = math.random() ^ 0.65
		local r = tt * R + 200 * math.random()
		local ang = arm * (2 * math.pi / ARMS) + tt * 4.4 + gauss() * 0.22 * (1.2 - tt)
		local rr = r + gauss() * 130 * (0.4 + tt)
		local pos = GC + Vector3.new(math.cos(ang) * rr, gauss() * (50 * (1 - tt) + 14), math.sin(ang) * rr)
		local size = (30 + math.random() * 130) * (1.1 - 0.5 * tt)
		local col = Color3.fromRGB(255, 225, 170):Lerp(Color3.fromRGB(255, 140, 150), clamp01(tt * 1.6)):Lerp(Color3.fromRGB(110, 150, 255), clamp01((tt - 0.5) * 2))
		vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * size, Position = pos, Material = Enum.Material.Neon, Color = col, Transparency = 0.05 + 0.5 * math.random() }, folder)
		if i % 150 == 0 then task.wait() end
	end
	for i = 1, 1300 do
		local arm = i % ARMS
		local tt = math.random() ^ 0.8
		local ang = arm * (2 * math.pi / ARMS) + tt * 4.4 + gauss() * 0.3
		local rr = tt * R + gauss() * 200
		local pos = GC + Vector3.new(math.cos(ang) * rr, gauss() * 40, math.sin(ang) * rr)
		vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * (14 + math.random() * 30), Position = pos, Material = Enum.Material.Neon, Color = Color3.fromRGB(190, 210, 255), Transparency = 0.2 }, folder)
		if i % 200 == 0 then task.wait() end
	end
	for i = 1, 160 do
		local v = Vector3.new(gauss(), gauss() * 0.45, gauss()) * 900
		vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * (90 + math.random() * 200), Position = GC + v, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 235, 190), Transparency = 0.2 + 0.4 * math.random() }, folder)
	end
	bigSphere(folder, GC, 2200, Color3.fromRGB(255, 220, 150), Enum.Material.Neon, 0.45)
	bigSphere(folder, GC, 4600, Color3.fromRGB(255, 150, 90), Enum.Material.Neon, 0.86)
	task.wait()
	local hazeCols = { Color3.fromRGB(255, 90, 130), Color3.fromRGB(110, 140, 255) }
	for i = 1, 70 do
		local arm = i % ARMS
		local tt = 0.15 + math.random() * 0.85
		local ang = arm * (2 * math.pi / ARMS) + tt * 4.4 + gauss() * 0.15
		local pos = GC + Vector3.new(math.cos(ang) * tt * R, gauss() * 40, math.sin(ang) * tt * R)
		bigSphere(folder, pos, 700 + math.random() * 900, hazeCols[i % 2 + 1], Enum.Material.Neon, 0.9 + math.random() * 0.05)
	end
	for i = 1, 40 do
		local arm = i % ARMS
		local tt = 0.2 + math.random() * 0.8
		local ang = arm * (2 * math.pi / ARMS) + tt * 4.4 + 0.12
		local pos = GC + Vector3.new(math.cos(ang) * tt * R, gauss() * 20, math.sin(ang) * tt * R)
		bigSphere(folder, pos, 500 + math.random() * 700, Color3.fromRGB(6, 4, 8), Enum.Material.SmoothPlastic, 0.8)
	end
end
local function landAt(n)
	return math.noise(n.X * 2.1 + 3.7, n.Y * 2.1 + 1.3, n.Z * 2.1 + 8.1) + 0.45 * math.noise(n.X * 5 + 1, n.Y * 5 + 2, n.Z * 5 + 3) > 0.04
end
local function cloudAt(n)
	return math.noise(n.X * 3.3 + 9.1, n.Y * 3.3 + 4.2, n.Z * 3.3 + 2.7) + 0.5 * math.noise(n.X * 8 + 5, n.Y * 8 + 6, n.Z * 8 + 7) > 0.12
end
local function plateOnSphere(folder, EC, n, r, w, color, material, transparency, thick)
	local p = EC + n * r
	return vpart({ Size = Vector3.new(w, w, thick or 2), CFrame = CFrame.lookAt(p, p + n), Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0 }, folder)
end
local function buildEarth(folder, EC)
	local ER = 1200
	local ocean = bigSphere(folder, EC, ER * 2, Color3.fromRGB(16, 64, 148), Enum.Material.SmoothPlastic, 0)
	ocean.Reflectance = 0.12
	local landCols = { Color3.fromRGB(58, 118, 56), Color3.fromRGB(76, 132, 62), Color3.fromRGB(150, 138, 84), Color3.fromRGB(104, 92, 60), Color3.fromRGB(40, 92, 52) }
	local placed = 0
	local tries = 0
	while placed < 780 and tries < 6000 do
		tries += 1
		local n = randDir()
		if landAt(n) then
			placed += 1
			local polar = math.abs(n.Y) > 0.86
			local col = polar and Color3.fromRGB(238, 244, 250) or landCols[math.random(1, #landCols)]
			plateOnSphere(folder, EC, n, ER * 1.0015, 90 + math.random() * 90, col, Enum.Material.SmoothPlastic, 0, 3)
			if placed % 200 == 0 then task.wait() end
		end
	end
	for _ = 1, 3 do
		local n = Vector3.new(0, 1, 0)
		local a = math.random() * math.pi * 2
		plateOnSphere(folder, EC, (Vector3.new(math.cos(a) * 0.12, 1, math.sin(a) * 0.12)).Unit * (math.random() > 0.5 and 1 or -1), ER * 1.002, 220, Color3.fromRGB(240, 246, 252), Enum.Material.SmoothPlastic, 0, 3)
	end
	placed, tries = 0, 0
	while placed < 460 and tries < 5000 do
		tries += 1
		local n = randDir()
		if cloudAt(n) then
			placed += 1
			plateOnSphere(folder, EC, n, ER * 1.016, 190 + math.random() * 190, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 0.3 + math.random() * 0.25, 2)
			if placed % 150 == 0 then task.wait() end
		end
	end
	bigSphere(folder, EC, ER * 2.07, Color3.fromRGB(110, 175, 255), Enum.Material.Neon, 0.86)
	bigSphere(folder, EC, ER * 2.16, Color3.fromRGB(110, 175, 255), Enum.Material.Neon, 0.95)
end
local function buildMoon(folder, pos)
	bigSphere(folder, pos, 660, Color3.fromRGB(150, 148, 144), Enum.Material.SmoothPlastic, 0)
	for _ = 1, 45 do
		local n = randDir()
		plateOnSphere(folder, pos, n, 331, 26 + math.random() * 60, Color3.fromRGB(96, 94, 92), Enum.Material.SmoothPlastic, 0, 1)
	end
end
local function buildCannon(folder, cf)
	local C = { rings = {}, coils = {}, gantry = {}, beams = {}, glows = {} }
	local DARK = Color3.fromRGB(52, 56, 68)
	local MID = Color3.fromRGB(72, 78, 92)
	local GOLD = Color3.fromRGB(196, 156, 70)
	local HOT = Color3.fromRGB(255, 225, 205)
	local function cyl(zc, len, dia, col, mat)
		return vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(len, dia, dia), Color = col, Material = mat or Enum.Material.Metal, CFrame = cf * CFrame.new(0, 0, zc) * CFrame.Angles(0, math.rad(90), 0) }, folder)
	end
	local function blk(localCF, size, col, mat)
		return vpart({ Size = size, Color = col, Material = mat or Enum.Material.Metal, CFrame = cf * localCF }, folder)
	end
	cyl(40, 380, 140, DARK)
	cyl(-245, 190, 104, MID)
	cyl(-515, 350, 70, DARK)
	cyl(-712, 64, 108, MID)
	cyl(-740, 18, 80, RED, Enum.Material.Neon)
	vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 230, Color = DARK, Material = Enum.Material.Metal, CFrame = cf * CFrame.new(0, 0, 200) }, folder)
	cyl(210, 12, 156, GOLD)
	cyl(-150, 12, 134, GOLD)
	cyl(-340, 12, 112, GOLD)
	for _, spec in ipairs({ { -190, 132 }, { -265, 132 }, { -390, 98 }, { -470, 98 }, { -550, 98 }, { -630, 98 } }) do
		local ring = cyl(spec[1], 10, spec[2], RED, Enum.Material.Neon)
		ring:SetAttribute("Dia", spec[2])
		C.rings[#C.rings + 1] = ring
	end
	for i = 0, 5 do C.coils[#C.coils + 1] = blk(CFrame.Angles(0, 0, math.rad(i * 60)) * CFrame.new(0, 72, 40), Vector3.new(4, 4, 300), RED, Enum.Material.Neon) end
	for _, deg in ipairs({ 45, 135, 225, 315 }) do blk(CFrame.Angles(0, 0, math.rad(deg)) * CFrame.new(0, 112, 70), Vector3.new(8, 110, 200), DARK) end
	for _, sx in ipairs({ -1, 1 }) do
		vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(260, 46, 46), Color = MID, Material = Enum.Material.Metal, CFrame = cf * CFrame.new(sx * 150, 0, -20) * CFrame.Angles(0, math.rad(90), 0) }, folder)
		blk(CFrame.new(sx * 85, 0, -20), Vector3.new(90, 10, 14), DARK)
		C.glows[#C.glows + 1] = vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 42, Color = Color3.fromRGB(80, 220, 255), Material = Enum.Material.Neon, CFrame = cf * CFrame.new(sx * 150, 0, -150) }, folder)
	end
	for i = 0, 2 do
		local a = math.rad(i * 120)
		vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(50, 64, 64), Color = DARK, Material = Enum.Material.Metal, CFrame = cf * CFrame.Angles(0, 0, a) * CFrame.new(0, 55, 290) * CFrame.Angles(0, math.rad(90), 0) }, folder)
		C.glows[#C.glows + 1] = vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 54, 54), Color = Color3.fromRGB(90, 190, 255), Material = Enum.Material.Neon, CFrame = cf * CFrame.Angles(0, 0, a) * CFrame.new(0, 55, 318) * CFrame.Angles(0, math.rad(90), 0) }, folder)
	end
	local function gantryPart(lc, size, col, mat)
		local p = vpart({ Size = size, Color = col, Material = mat or Enum.Material.Metal, CFrame = cf * lc }, folder)
		C.gantry[#C.gantry + 1] = { part = p, lc = lc }
		return p
	end
	for i = 0, 11 do
		local lc = CFrame.Angles(0, 0, math.rad(i * 30)) * CFrame.new(0, 235, -40)
		gantryPart(lc, Vector3.new(128, 14, 26), MID)
		gantryPart(lc * CFrame.new(0, 10, 0), Vector3.new(16, 16, 16), Color3.fromRGB(80, 200, 255), Enum.Material.Neon)
	end
	for i = 0, 5 do gantryPart(CFrame.Angles(0, 0, math.rad(i * 60)) * CFrame.new(0, 152, -40), Vector3.new(10, 166, 10), DARK) end
	C.muzzleCF = cf * CFrame.new(0, 0, -745)
	C.orb = vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 6, Color = RED, Material = Enum.Material.Neon, CFrame = C.muzzleCF }, folder)
	C.orbLight = new("PointLight", { Color = Color3.fromRGB(255, 60, 40), Range = 60, Brightness = 4 }, C.orb)
	C.orbFlare = starFlare(C.orb, 10, Color3.fromRGB(255, 150, 130))
	local orbAtt = new("Attachment", {}, C.orb)
	local sphereP = vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 380, Transparency = 1, CFrame = C.muzzleCF }, folder)
	local ok = pcall(function()
		C.chargeEm = new("ParticleEmitter", { Rate = 0, Lifetime = NumberRange.new(1.2, 1.6), Speed = NumberRange.new(200, 260), Size = NumberSequence.new({ NK(0, 26), NK(1, 0) }), Transparency = NumberSequence.new({ NK(0, 0.2), NK(1, 0.4) }), Color = ColorSequence.new(Color3.fromRGB(255, 80, 60), Color3.fromRGB(255, 230, 200)), LightEmission = 1, Shape = Enum.ParticleEmitterShape.Sphere, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface }, sphereP)
	end)
	if not ok then C.chargeEm = nil end
	for i = 1, #C.rings do
		local ring = C.rings[i]
		local d = ring:GetAttribute("Dia")
		local a = (i / #C.rings) * math.pi * 2
		local at0 = new("Attachment", { Position = Vector3.new(0, math.cos(a) * d / 2, math.sin(a) * d / 2) }, ring)
		local b = makeBeam(ring, at0, orbAtt, 0, Color3.fromRGB(255, 120, 90), 0)
		b.Segments = 14
		b.CurveSize0 = (math.random() - 0.5) * 160
		b.CurveSize1 = (math.random() - 0.5) * 160
		b.Enabled = false
		C.beams[#C.beams + 1] = b
	end
	function C.update(x, t)
		local rot = CFrame.Angles(0, 0, t * (0.15 + x * 0.9))
		for _, g in ipairs(C.gantry) do g.part.CFrame = cf * rot * g.lc end
		local pulse = 0.5 + 0.5 * math.sin(t * (4 + x * 26))
		local col = RED:Lerp(HOT, clamp01(x * 0.9 + pulse * 0.1 * x))
		for _, r in ipairs(C.rings) do r.Color = col end
		for _, c in ipairs(C.coils) do c.Color = col end
		local s = 6 + (x ^ 1.6) * 250 * (0.94 + 0.06 * pulse)
		C.orb.Size = Vector3.one * s
		C.orb.Color = RED:Lerp(HOT, x ^ 2)
		C.orbLight.Brightness = 2 + 10 * x
		local fs = 10 + 1600 * (x ^ 1.4)
		C.orbFlare.Size = UDim2.fromOffset(fs, fs)
		for i, b in ipairs(C.beams) do
			b.Enabled = x > 0.12
			local w = math.abs((1 + x * 11) * (0.6 + 0.8 * math.noise(t * 9, i, 0)))
			b.Width0 = w b.Width1 = w
		end
		if C.chargeEm then C.chargeEm.Rate = 450 * x end
	end
	return C
end

local function buildStage(stage)
	local folder = new("Folder", { Name = "SpaceStage" }, workspace)
	stage.folder = folder
	local GC = Vector3.new(0, 300000, 0)
	local CP = GC + Vector3.new(6400, 400, 1500)
	local fwd = Vector3.new(-0.78, -0.02, -0.2).Unit
	local cannonCF = CFrame.lookAt(CP, CP + fwd)
	local EC = CP + fwd * 5200 + cannonCF.RightVector * -500 + cannonCF.UpVector * -150
	stage.GC, stage.CP, stage.cannonCF, stage.EC = GC, CP, cannonCF, EC
	local nT = (CP - EC).Unit
	stage.nT = nT
	stage.markPt = EC + nT * 1200
	stage.cannon = buildCannon(folder, cannonCF)
	buildGalaxy(folder, GC)
	buildStars(folder, GC)
	buildEarth(folder, EC)
	buildMoon(folder, EC + Vector3.new(2600, 500, -1500))
	for _ = 1, 70 do
		local off = Vector3.new(gauss(), gauss() * 0.6, gauss()) * 1500
		if off.Magnitude > 450 then
			vpart({ Size = Vector3.new(14 + math.random() * 70, 14 + math.random() * 50, 14 + math.random() * 70), Material = Enum.Material.Slate, Color = Color3.fromRGB(70, 66, 70), CFrame = CFrame.new(CP + off) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6) }, folder)
		end
	end
	local dot = vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * 26, Position = stage.markPt, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 60, 60) }, folder)
	stage.markFlare = starFlare(dot, 420, Color3.fromRGB(255, 110, 100))
	stage.markLaser = makeLaser(folder, stage.markPt + nT * 3200, { 36, 18, 7 })
	stage.markLaser.setEnd(stage.markPt)
	stage.markLaser.setWidth(0)
	stage.ready = true
end
local function finishStage(stage)
	local dir = Lighting:GetSunDirection()
	stage.sunDir = dir
	local sunPos = stage.GC + dir * 24000
	local sun = bigSphere(stage.folder, sunPos, 1800, Color3.fromRGB(255, 246, 225), Enum.Material.Neon, 0)
	starFlare(sun, 1400, Color3.fromRGB(255, 240, 210))
	local placed, tries = 0, 0
	while placed < 420 and tries < 4000 do
		tries += 1
		local n = randDir()
		if n:Dot(dir) < -0.12 and landAt(n) then
			placed += 1
			plateOnSphere(stage.folder, stage.EC, n, 1200 * 1.003, 6 + math.random() * 8, Color3.fromRGB(255, 205, 120), Enum.Material.Neon, 0.1, 1)
		end
	end
end
local function finishCinematic(stage, conn)
	if conn then conn:Disconnect() end
	if stage and stage.folder then stage.folder:Destroy() end
	restoreLighting() clearFx() showBars(false) setCaption("")
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	setControls(true) setCoreGui(true) setFlash(0) state = "idle"
end
local function pulseWin(t, center, rise, fall)
	if t < center then return clamp01(1 - (center - t) / rise) end
	return clamp01(1 - (t - center) / fall)
end
local function runSequence(target)
	state = "cinematic"
	lastFire = os.clock()
	local startCF = camera.CFrame
	local startFov = camera.FieldOfView
	local startPos = startCF.Position
	local imp = 25
	camera.CameraType = Enum.CameraType.Scriptable
	setControls(false) setCoreGui(false) showBars(true) ensureFx() restoreAll() playSound(SOUNDS.lock, 1, 0.9)
	local stage = { ready = false }
	task.spawn(function() buildStage(stage) end)
	local reticle = makeReticle(110, target)
	local lockLaser = makeLaser(fxFolder, target + Vector3.new(0, 4500, 0), { 12, 6, 2.4 })
	lockLaser.setEnd(target) lockLaser.setWidth(0)
	task.delay(math.max(imp - 1.6, 0), function() groundLaser(target, 1.6) end)
	local rotStart = startCF.Rotation
	local rotEnd = CFrame.lookAt(Vector3.zero, Vector3.new(0, -1, 0), Vector3.new(0, 0, -1))
	local lv = startCF.LookVector
	local heading = math.atan2(lv.Z, lv.X)
	local groundCamBase = Vector3.new(math.cos(heading + math.pi), 0, math.sin(heading + math.pi)) * 520 + Vector3.new(0, 170, 0)
	local inSpace, fired, groundFlag, impacted, finished = false, false, false, false, false
	local laser, fireClock = nil, 0
	local captionStage = 0
	local chargeSnd = nil
	local ascentSnd = nil
	local t0 = os.clock()
	local conn
	local function spaceCam(t)
		local ER = 1200
		local nT = stage.nT
		local EC = stage.EC
		local markPt = stage.markPt
		local dirA0 = (rotY(nT, 0.45) + Vector3.new(0, 0.35, 0)).Unit
		local dirOv = Vector3.new(0.18, 0.7, 0.69).Unit
		local OV = 16000
		if t < 9.5 then
			local u = t - 6
			local dirA = rotY(dirA0, u * 0.05)
			local d = 3600 - 160 * u
			local pos = EC + dirA * d
			return CFrame.lookAt(pos, markPt + (EC - markPt) * 0.1), 70
		elseif t < 12.5 then
			local u = smooth((t - 9.5) / (12.5 - 9.5))
			local dirStart = rotY(dirA0, (9.5 - 6) * 0.05)
			local dist = 3440 * (OV / 3440) ^ u
			local pivot = markPt:Lerp(stage.GC, u)
			local dir = dirStart:Lerp(dirOv, u).Unit
			return CFrame.lookAt(pivot + dir * dist, pivot), 70
		elseif t < 13.5 then
			local dir = rotY(dirOv, (t - 12.5) * 0.04)
			return CFrame.lookAt(stage.GC + dir * OV, stage.GC), 70
		else
			local e = smooth(clamp01((t - 13.5) / (17 - 13.5)))
			local dirHold = rotY(dirOv, (13.5 - 12.5) * 0.04)
			local orbit = (t > 17) and (t - 17) or 0
			local localOff = CFrame.Angles(0, orbit * 0.035, 0) * Vector3.new(560, 250, 330)
			local dirE = stage.cannonCF:VectorToWorldSpace(localOff).Unit
			local dist = OV * (1000 / OV) ^ e
			local pf = smooth(clamp01((e - 0.05) / 0.95))
			local push = (t > 17) and (1 - 0.1 * clamp01((t - 17) / (21.5 - 17))) or 1
			local dir = dirHold:Lerp(dirE, e).Unit
			local pivot = stage.GC:Lerp(stage.CP, pf)
			local lookPoint = pivot + stage.cannonCF:VectorToWorldSpace(Vector3.new(0, 0, -330)) * pf
			return CFrame.lookAt(pivot + dir * dist * push, lookPoint), 70
		end
	end
	local function step(t)
		local cf
		local fov = 70
		local shakeAmp, rotAmp = 0, 0
		local f = 0
		if t < 6 then
			if t < 2 then
				cf = startCF
				fov = startFov
				lockLaser.setWidth(smooth(t / 0.6))
				if captionStage < 1 and t > 0.2 then captionStage = 1 setCaption("目标锁定  ·  TARGET LOCKED", Color3.fromRGB(255, 120, 120)) end
			else
				local u = clamp01((t - 2) / (6 - 2))
				local h = 40 * ((14000 / 40) ^ u - 1)
				local eo = smooth(u)
				local pos = Vector3.new(lerp(startPos.X, target.X, eo * 0.9), startPos.Y + h, lerp(startPos.Z, target.Z, eo * 0.9))
				local rot = rotStart:Lerp(rotEnd, smooth(clamp01((u - 0.1) / 0.9)))
				cf = CFrame.new(pos) * rot
				fov = lerp(startFov, 55, u)
				fx.blur.Size = lerp(0, 22, clamp01((t - (6 - 1.2)) / 1.2))
				fx.cc.Brightness = lerp(0, -0.05, u)
				fx.cc.Saturation = lerp(0, 0.2, u)
				if captionStage < 2 then captionStage = 2 setCaption("升空  ·  ASCENT", Color3.new(1, 1, 1)) ascentSnd = playSound(SOUNDS.whoosh, 0.9, 0.5) end
				f = math.max(f, pulseWin(t, 6, 0.7, 0.01) * (t > 6 - 0.7 and 1 or 0))
			end
			reticle.update(t)
		elseif t < 23.4 then
			if not inSpace then
				inSpace = true
				enterSpaceLighting()
				fx.blur.Size = 0
				fx.bloom.Intensity = 1.2
				fx.bloom.Threshold = 0.9
				fx.cc.Brightness = 0
				fx.cc.Saturation = 0.15
				setCaption("近地轨道  ·  LOW EARTH ORBIT", Color3.new(1, 1, 1))
				chargeSnd = playSound(SOUNDS.charge, 0.7, 0.35, true)
			end
			if not stage.ready then
				setFlash(1)
				return
			end
			if inSpace and not stage.finished then
				stage.finished = true
				task.spawn(finishStage, stage)
			end
			cf, fov = spaceCam(t)
			if stage.markLaser then stage.markLaser.setWidth(smooth((t - 6) / 1.2) * (0.85 + 0.15 * math.sin(t * 9))) end
			if t >= 12.5 - 0.4 and captionStage < 3 then captionStage = 3 setCaption("银河系  ·  MILKY WAY", Color3.new(1, 1, 1)) end
			if t >= 13.5 + 0.6 and captionStage < 4 then captionStage = 4 setCaption("歼星炮  ·  STAR-DESTROYER ONLINE", Color3.fromRGB(255, 140, 140)) end
			if t < 17 then
				stage.cannon.update(0, t)
			elseif t < 21.5 then
				local x = clamp01((t - 17) / (21.5 - 17))
				stage.cannon.update(x, t)
				shakeAmp = 4 * x * x
				rotAmp = 0.004 * x * x
				setCaption(string.format("充能中  ·  CHARGING  %d%%", math.floor(x * 100)), Color3.fromRGB(255, 90, 90))
				if chargeSnd then chargeSnd.PlaybackSpeed = 0.35 + 1.2 * x chargeSnd.Volume = 0.7 + 0.6 * x end
			else
				stage.cannon.update(1, t)
			end
			if t >= 21.5 then
				if not fired then
					fired = true
					fireClock = os.clock()
					setCaption("发射  ·  FIRE", Color3.new(1, 1, 1))
					if chargeSnd then chargeSnd:Destroy() chargeSnd = nil end
					playSound(SOUNDS.fire, 1.5, 0.3)
					laser = makeLaser(stage.folder, stage.cannon.muzzleCF.Position, { 240, 130, 55 })
					laser.setWidth(0)
					if stage.cannon.chargeEm then stage.cannon.chargeEm.Rate = 0 end
				end
				local u = os.clock() - fireClock
				local muzzle = stage.cannon.muzzleCF.Position
				laser.setEnd(muzzle:Lerp(stage.markPt, smooth(u / 0.5)))
				laser.setWidth(smooth(u / 0.25))
				shakeAmp = 16 * math.exp(-u * 1.6)
				rotAmp = 0.012 * math.exp(-u * 1.6)
				fov = 70 + 20 * math.exp(-u * 4)
				f = math.max(f, 0.9 * pulseWin(t, 21.5, 0.02, 0.9))
			end
			f = math.max(f, pulseWin(t, 6, 0.01, 1.1))
			f = math.max(f, pulseWin(t, 23.4, 0.25, 0.01) * (t > 23.4 - 0.25 and 1 or 0))
		else
			if not groundFlag then
				groundFlag = true
				if chargeSnd then chargeSnd:Destroy() end
				if stage.folder then stage.folder:Destroy() stage.folder = nil end
				restoreLighting()
				fx.bloom.Intensity = 0.9
				fx.bloom.Threshold = 0.95
				fx.cc.Saturation = 0
				tween(fx.cc, 1.4, { TintColor = Color3.fromRGB(255, 190, 180), Brightness = -0.1 })
				setCaption("命中  ·  IMPACT", Color3.fromRGB(255, 90, 90))
			end
			if not impacted and t >= 25 then
				impacted = true
				task.spawn(doImpact, target, true)
			end
			local g = t - 23.4
			local ang = math.max(0, t - 25) * 0.06
			local offs = CFrame.Angles(0, ang, 0) * (groundCamBase * (1 - 0.08 * clamp01(g / (25 - 23.4))))
			cf = CFrame.lookAt(target + offs, target + Vector3.new(0, 45, 0))
			fov = lerp(70, 62, clamp01(g / 6))
			f = math.max(f, pulseWin(t, 23.4, 0.01, 0.8))
			reticle.update(t)
			if t > 25 + 3 then setCaption("") end
		end
		f = math.max(f, impactFlashValue())
		local ia = impactShakeAmount()
		shakeAmp += ia
		rotAmp += ia * 0.0015
		if t > 32 - 0.8 then setFlash(clamp01((t - (32 - 0.8)) / 0.8), Color3.new(0, 0, 0)) else setFlash(f) end
		camera.FieldOfView = fov
		camera.CFrame = shakeCF(cf, shakeAmp, t, rotAmp)
	end
	conn = RunService.RenderStepped:Connect(function()
		if finished then return end
		local t = os.clock() - t0
		if t >= 32 then
			finished = true
			reticle.destroy() lockLaser.destroy()
			if ascentSnd then ascentSnd:Destroy() end
			finishCinematic(stage, conn)
			return
		end
		local ok, err = pcall(step, t)
		if not ok then
			warn("[SpaceCannon]", err)
			finished = true
			reticle.destroy() lockLaser.destroy()
			finishCinematic(stage, conn)
		end
	end)
end
local marker = nil
local markerConn = nil
local function aimPoint()
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list = { fxFolder }
	if player.Character then list[#list + 1] = player.Character end
	params.FilterDescendantsInstances = list
	local r = workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
	return r and r.Position or nil
end
local function stopTargeting()
	if markerConn then markerConn:Disconnect() markerConn = nil end
	if marker then marker.destroy() marker = nil end
end
local function startTargeting()
	stopTargeting()
	marker = makeMarker(110)
	markerConn = RunService.RenderStepped:Connect(function()
		local p = aimPoint()
		if p and marker then
			marker.place(p)
			marker.outer.Transparency = 0.7 + 0.12 * (0.5 + 0.5 * math.sin(os.clock() * 6))
		end
	end)
end
local OrbitalTab = Window:Tab({ Title = "轨道武器", Icon = "crosshair" })
local OrbitalSection = OrbitalTab:Section({ Title = "歼星炮控制", Icon = "target" })
OrbitalSection:Button({
	Title = "呼叫歼星炮",
	Callback = function()
		if state == "idle" then
			local left = 30 - (os.clock() - lastFire)
			if left > 0 then
				toast(string.format("武器冷却中：%d 秒", math.ceil(left)))
				return
			end
			playSound(SOUNDS.click, 0.9, 1)
			state = "targeting"
			startTargeting()
		elseif state == "targeting" then
			local pt = aimPoint()
			if not pt then
				toast("请点击地面或物体表面")
				return
			end
			stopTargeting()
			playSound(SOUNDS.select, 1, 0.8)
			runSequence(pt)
		end
	end
})
OrbitalSection:Button({
	Title = "取消当前锁定",
	Callback = function()
		if state == "targeting" then
			stopTargeting()
			state = "idle"
		end
	end
})
OrbitalSection:Button({
	Title = "强制重置冷却",
	Callback = function()
		lastFire = -1e9
		state = "idle"
		stopTargeting()
		toast("冷却已重置")
	end
})
OrbitalSection:Paragraph({ Title = "提示", Desc = "点击呼叫后，在地面点击即可发射" })
print("轨道武器加载成功")
end