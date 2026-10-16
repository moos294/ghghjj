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
	for k, v in pairs(props) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function vpart(props, parent)
	local p = new("Part", {
		Anchored = true,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
		Material = Enum.Material.SmoothPlastic,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	}, nil)
	for k, v in pairs(props) do
		p[k] = v
	end
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

local function clamp01(x)
	return math.clamp(x, 0, 1)
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function smooth(t)
	t = clamp01(t)
	return t * t * (3 - 2 * t)
end

local function gauss()
	return math.random() + math.random() + math.random() - 1.5
end

local function rotY(v, a)
	return CFrame.Angles(0, a, 0):VectorToWorldSpace(v)
end

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

local fxFolder = new("Folder", { Name = "SpaceCannonFX" }, Workspace)

local function playSound(id, volume, speed, looped)
	if not id or id == "" then
		return nil
	end
	local s = new("Sound", { SoundId = id, Volume = volume or 1, PlaybackSpeed = speed or 1, Looped = looped or false }, SoundService)
	s:Play()
	if not looped then
		Debris:AddItem(s, 8)
	end
	return s
end

local state = "idle"
local selectedWeapon = nil
local lastFire = -1e9

local flash = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.new(1, 1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ZIndex = 100,
	Active = false,
}, SG)
local function setFlash(a, color)
	flash.BackgroundColor3 = color or Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1 - clamp01(a)
end

local barTop = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 90 }, SG)
local barBottom = new("Frame", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.fromScale(0, 1),
	Size = UDim2.new(1, 0, 0, 0),
	BackgroundColor3 = Color3.new(0, 0, 0),
	BorderSizePixel = 0,
	ZIndex = 90,
}, SG)
local function showBars(on)
	local s = UDim2.new(1, 0, on and 0.1 or 0, 0)
	tween(barTop, 0.8, { Size = s })
	tween(barBottom, 0.8, { Size = s })
end

local caption = new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 0.9, 0),
	Size = UDim2.new(0.9, 0, 0, 40),
	BackgroundTransparency = 1,
	Text = "",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 22,
	TextTransparency = 1,
	TextStrokeTransparency = 0.6,
	ZIndex = 95,
}, SG)
local function setCaption(text, color)
	if text == "" then
		tween(caption, 0.4, { TextTransparency = 1 })
		return
	end
	caption.Text = text
	caption.TextColor3 = color or Color3.new(1, 1, 1)
	caption.TextTransparency = 1
	tween(caption, 0.4, { TextTransparency = 0 })
end

local toastLabel = new("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 110),
	Size = UDim2.new(0.8, 0, 0, 36),
	BackgroundColor3 = Color3.fromRGB(20, 22, 30),
	BackgroundTransparency = 0.1,
	TextColor3 = Color3.fromRGB(255, 220, 220),
	Font = Enum.Font.GothamMedium,
	TextSize = 18,
	Text = "",
	Visible = false,
	ZIndex = 40,
}, SG)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, toastLabel)
local toastId = 0
local function toast(msg)
	toastId += 1
	local id = toastId
	toastLabel.Text = msg
	toastLabel.Visible = true
	task.delay(2.2, function()
		if id == toastId then
			toastLabel.Visible = false
		end
	end)
end

local fx = {}
local function ensureFx()
	if fx.cc then
		return
	end
	fx.cc = new("ColorCorrectionEffect", { Name = "SC_CC" }, Lighting)
	fx.bloom = new("BloomEffect", { Name = "SC_Bloom", Intensity = 0.5, Size = 28, Threshold = 1 }, Lighting)
	fx.blur = new("BlurEffect", { Name = "SC_Blur", Size = 0 }, Lighting)
end
local function clearFx()
	for k, v in pairs(fx) do
		v:Destroy()
		fx[k] = nil
	end
end

local savedLighting = nil
local function enterSpaceLighting()
	if savedLighting then
		return
	end
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
	savedLighting.sky = new("Sky", {
		Name = "SC_Sky",
		SkyboxBk = "",
		SkyboxDn = "",
		SkyboxFt = "",
		SkyboxLf = "",
		SkyboxRt = "",
		SkyboxUp = "",
		StarCount = 0,
		CelestialBodiesShown = false,
	}, Lighting)
end
local function restoreLighting()
	if not savedLighting then
		return
	end
	if savedLighting.sky then
		savedLighting.sky:Destroy()
	end
	for k, v in pairs(savedLighting.props) do
		Lighting[k] = v
	end
	for _, c in ipairs(savedLighting.removed) do
		c.Parent = Lighting
	end
	savedLighting = nil
end

local function setControls(enabled)
	pcall(function()
		local pm = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
		local c = pm:GetControls()
		if enabled then
			c:Enable()
		else
			c:Disable()
		end
	end)
end
local function setCoreGui(enabled)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, enabled)
	end)
end

local impactFlash = { t = -1e9, a = 0 }
local impactShake = { t = -1e9, amp = 0 }
local function impactFlashValue()
	local e = os.clock() - impactFlash.t
	if e < 0 or e > 2.4 then
		return 0
	end
	return impactFlash.a * (1 - e / 2.4) ^ 1.5
end
local function impactShakeAmount()
	local e = os.clock() - impactShake.t
	if e < 0 or e > 3.5 then
		return 0
	end
	return impactShake.amp * (1 - e / 3.5) ^ 2
end
local function shakeCF(cf, amp, t, rotAmp)
	if amp <= 0.001 then
		return cf
	end
	local nx = math.noise(t * 23, 1.3, 0) * 2
	local ny = math.noise(t * 27, 5.1, 0) * 2
	local nz = math.noise(t * 19, 9.7, 0) * 2
	return cf * CFrame.new(nx * amp, ny * amp, 0) * CFrame.Angles(ny * rotAmp, nx * rotAmp, nz * rotAmp * 0.5)
end

local wasShaking = false
RunService.RenderStepped:Connect(function()
	if state ~= "cinematic" then
		local f = impactFlashValue()
		if f > 0.003 then
			setFlash(f)
		elseif flash.BackgroundTransparency < 1 and flash.BackgroundColor3 == Color3.new(1, 1, 1) then
			setFlash(0)
		end
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
	local bb = new("BillboardGui", {
		Size = UDim2.fromOffset(size, size),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Adornee = part,
		MaxDistance = 1e9,
	}, part)
	local function bar(len, thick, rot, tr)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(len, 0, 0, thick),
			BackgroundColor3 = color,
			BackgroundTransparency = tr,
			BorderSizePixel = 0,
			Rotation = rot,
		}, bb)
		new("UIGradient", { Transparency = NumberSequence.new({ NK(0, 1), NK(0.5, 0), NK(1, 1) }) }, f)
	end
	local function glow(s, tr)
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(s, s),
			BackgroundColor3 = color,
			BackgroundTransparency = tr,
			BorderSizePixel = 0,
		}, bb)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
	end
	glow(0.55, 0.93)
	glow(0.3, 0.82)
	glow(0.14, 0.55)
	glow(0.06, 0)
	bar(1, 3, 0, 0.1)
	bar(1, 3, 90, 0.1)
	bar(0.5, 2, 45, 0.35)
	bar(0.5, 2, -45, 0.35)
	return bb
end

local function makeBeam(parent, a0, a1, width, color, transparency)
	return new("Beam", {
		Attachment0 = a0,
		Attachment1 = a1,
		Width0 = width,
		Width1 = width,
	