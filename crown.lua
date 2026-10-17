local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

local ActionMap = {
    ["俯卧撑"] = "PushUp", ["哑铃"] = "Dumbbell", ["肩部推举1"] = "ShoulderPress_1",
    ["肩部推举2"] = "ShoulderPress_2", ["肩部推举3"] = "ShoulderPress_3",
    ["跑步机1"] = "TrendMill_1", ["平躺卧推1"] = "FlatBench_1", ["平躺卧推L1"] = "FlatBench_L1",
    ["平躺卧推K1"] = "FlatBench_K1", ["举石1"] = "Rock_1", ["举石2"] = "Rock_2",
    ["举石3"] = "Rock_3", ["杠铃架L1"] = "BarbellRack_L1", ["杠铃架S1"] = "BarbellRack_S1",
    ["杠铃架1"] = "BarbellRack_1", ["杠铃架2"] = "BarbellRack_2",
    ["卧推L1"] = "BenchPress_L1", ["卧推1"] = "BenchPress_1", ["卧推2"] = "BenchPress_2",
    ["红史莱姆"] = "Red slime", ["天空史莱姆"] = "SkySlime",
}
local ActionListCN = {}
for cn, _ in pairs(ActionMap) do table.insert(ActionListCN, cn) end
table.sort(ActionListCN)

local Cfg = {
    AutoPetEgg = false, PetEggName = "SkyPetEgg", PetEggQty = 1, PetEggInterval = 2.0,
    AutoHaloEgg = false, HaloEggName = "SkyHaloEgg", HaloEggQty = 1, HaloEggInterval = 2.0,
    EggCurrency = "Gem",
    AutoTrain = false, TrainAction = "Dumbbell", TrainActionCN = "哑铃", TrainInterval = 0.2,
    AutoRebirth = false, TargetStrength = 10000, RebirthInc = 10000, TargetRebirthCount = 5,
    RebirthCheckInterval = 0.1, RebirthCooldown = 0.1,
    InfiniteRebirth = false, BaseStrength = 10000,
    AutoDelete = false,
    DeletePetNames = "Flying Wreath, Shining Star, Crystalline Globe",
    DeleteInterval = 1.0,
}

local function getCurrentStrength()
    local str = 0
    pcall(function()
        local attr = player:GetAttribute("Strength") or player:GetAttribute("Power")
        if attr then str = attr; return end
        if player.leaderstats then
            local ls = player.leaderstats
            if ls:FindFirstChild("Strength") then str = ls.Strength.Value; return end
            if ls:FindFirstChild("Power") then str = ls.Power.Value; return end
        end
    end)
    return str
end

local function getCurrentRebirths()
    local count = 0
    pcall(function()
        local attr = player:GetAttribute("Rebirths") or player:GetAttribute("Rebirth") or player:GetAttribute("RebirthCount")
        if attr then count = attr; return end
        if player.leaderstats then
            local ls = player.leaderstats
            for _, n in ipairs({"Rebirths", "Rebirth", "RebirthCount", "Prestige", "Reborn"}) do
                if ls:FindFirstChild(n) and (ls[n]:IsA("IntValue") or ls[n]:IsA("NumberValue")) then count = ls[n].Value; return end
            end
        end
    end)
    return count
end

local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"))()
end)

if not success or not WindUI then
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "UI加载失败", Text = "请检查网络或执行器权限", Duration = 10})
    return
end

local Window = WindUI:CreateWindow({
    Title = "综合挂机面板 V3.6", Icon = "zap", Author = "Assistant",
    Folder = "DualEgg_V36", Theme = "Dark", Transparent = true, Resizable = false,
    Size = UDim2.fromOffset(460, 760),
})

local MainTab = Window:Tab({ Title = "控制面板", Icon = "settings" })
local FunTab = Window:Tab({ Title = "娱乐区", Icon = "sparkles" })

local PetSection = MainTab:Section({ Title = "🐾 宠物区", Icon = "paw" })
PetSection:Toggle({ Title = "开启自动开宠物蛋", Value = false, Callback = function(s) Cfg.AutoPetEgg = s end })
PetSection:Input({ Title = "宠物蛋名字", Value = "SkyPetEgg", Callback = function(t) Cfg.PetEggName = t end })
PetSection:Dropdown({ Title = "每次开蛋数量", Values = {"1", "3"}, Value = "1", Callback = function(sel) local v = tonumber(sel); if v then Cfg.PetEggQty = v end end })
PetSection:Slider({ Title = "开蛋间隔 (秒)", Value = { Min = 1.0, Max = 3.0, Default = 2.0 }, Step = 0.1, Callback = function(v) Cfg.PetEggInterval = v end })
local PetStatus = PetSection:Paragraph({ Title = "宠物区状态", Desc = "待机中..." })

local HaloSection = MainTab:Section({ Title = "✨ 光环区", Icon = "star" })
HaloSection:Toggle({ Title = "开启自动开光环蛋", Value = false, Callback = function(s) Cfg.AutoHaloEgg = s end })
HaloSection:Input({ Title = "光环蛋名字", Value = "SkyHaloEgg", Callback = function(t) Cfg.HaloEggName = t end })
HaloSection:Dropdown({ Title = "每次开蛋数量", Values = {"1", "3"}, Value = "1", Callback = function(sel) local v = tonumber(sel); if v then Cfg.HaloEggQty = v end end })
HaloSection:Slider({ Title = "开蛋间隔 (秒)", Value = { Min = 1.0, Max = 3.0, Default = 2.0 }, Step = 0.1, Callback = function(v) Cfg.HaloEggInterval = v end })
local HaloStatus = HaloSection:Paragraph({ Title = "光环区状态", Desc = "待机中..." })

local TrainSection = MainTab:Section({ Title = "🏋️ 自动锻炼", Icon = "activity" })
TrainSection:Toggle({ Title = "自动锻炼", Value = false, Callback = function(s) Cfg.AutoTrain = s end })
TrainSection:Dropdown({ Title = "选择动作 (中文)", Values = ActionListCN, Value = "哑铃", Callback = function(sel) local en = ActionMap[sel]; if en then Cfg.TrainAction = en; Cfg.TrainActionCN = sel end end })
TrainSection:Slider({ Title = "锻炼间隔 (秒)", Value = { Min = 0.1, Max = 1.0, Default = 0.2 }, Step = 0.05, Callback = function(v) Cfg.TrainInterval = v end })
local TrainStatus = TrainSection:Paragraph({ Title = "锻炼状态", Desc = "待机中..." })

local RebirthSection = MainTab:Section({ Title = "💀 自动重生 (限次)", Icon = "refresh-cw" })
RebirthSection:Toggle({ Title = "自动重生", Value = false, Callback = function(s) Cfg.AutoRebirth = s end })
RebirthSection:Input({ Title = "初始目标力量", Value = "10000", Callback = function(t) local v = tonumber(t); if v then Cfg.TargetStrength = v end end })
RebirthSection:Input({ Title = "每次递增数值", Value = "10000", Callback = function(t) local v = tonumber(t); if v then Cfg.RebirthInc = v end end })
RebirthSection:Input({ Title = "目标重生次数", Value = "5", Callback = function(t) local v = tonumber(t); if v then Cfg.TargetRebirthCount = v end end })
local RebirthStatus = RebirthSection:Paragraph({ Title = "重生状态", Desc = "待机中..." })

local InfiniteSection = MainTab:Section({ Title = "♻️ 无限循环重生", Icon = "repeat" })
InfiniteSection:Toggle({ Title = "无限循环重生", Value = false, Callback = function(s) Cfg.InfiniteRebirth = s; if s then Cfg.AutoRebirth = false end end })
InfiniteSection:Input({ Title = "基础目标力量", Value = "10000", Callback = function(t) local v = tonumber(t); if v then Cfg.BaseStrength = v end end })
local InfiniteStatus = InfiniteSection:Paragraph({ Title = "无限循环状态", Desc = "待机中..." })

local DeleteSection = MainTab:Section({ Title = "🗑️ 自动删除指定宠物", Icon = "trash" })
DeleteSection:Toggle({ Title = "开启自动删除", Desc = "每秒扫描宠物界面，自动删除列表中指定名字的宠物", Value = false, Callback = function(state) Cfg.AutoDelete = state end })
DeleteSection:Input({ Title = "要删除的宠物名字", Desc = "多个名字用英文逗号隔开", Placeholder = "Flying Wreath, Shining Star", Value = "Flying Wreath, Shining Star, Crystalline Globe", Callback = function(text) Cfg.DeletePetNames = text end })
DeleteSection:Button({ Title = "🚨 立即执行一次删除", Desc = "立刻扫描并删除列表中指定名字的宠物", Color = Color3.fromRGB(200, 80, 80), Callback = function()
    task.spawn(function()
        local success, err = pcall(function()
            local delEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DelItemEvent")
            local targetNames = {}
            for name in string.gmatch(Cfg.DeletePetNames .. ",", "([^,]+)") do
                local trimmed = string.match(name, "^%s*(.-)%s*$")
                if trimmed ~= "" then targetNames[trimmed] = true end
            end
            local uids = {}
            local deletedCount = 0
            for _, obj in ipairs(player:GetDescendants()) do
                if obj:IsA("ImageButton") and targetNames[obj.Name] then
                    local ok, uid = pcall(function() return obj:GetAttribute("UID") end)
                    if ok and uid then
                        local uidStr = tostring(uid)
                        if uidStr:match("^%d+_%d+$") then
                            uids[uidStr] = true
                            deletedCount = deletedCount + 1
                        end
                    end
                end
            end
            if deletedCount > 0 then
                delEvent:FireServer("Pet", uids)
                WindUI:Notify({ Title = "✅ 删除请求已发送", Content = "共 " .. deletedCount .. " 只宠物", Duration = 3 })
            else
                WindUI:Notify({ Title = "🔍 没有找到匹配的宠物", Content = "请检查名字是否正确", Duration = 3 })
            end
        end)
        if not success then WindUI:Notify({ Title = "❌ 删除失败", Content = tostring(err), Duration = 5 }) end
    end)
end })
local DeleteStatus = DeleteSection:Paragraph({ Title = "删除状态", Desc = "待机中..." })

task.spawn(function()
    local storeEvent; pcall(function() storeEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("StoreEvent") end)
    while true do
        task.wait(Cfg.PetEggInterval)
        if Cfg.AutoPetEgg and storeEvent then pcall(function() storeEvent:FireServer("Egg", Cfg.PetEggQty, Cfg.EggCurrency, Cfg.PetEggName) PetStatus:SetDesc("正在开蛋: " .. Cfg.PetEggName) end) else PetStatus:SetDesc("待机中") end
    end
end)

task.spawn(function()
    local storeEvent; pcall(function() storeEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("StoreEvent") end)
    while true do
        task.wait(Cfg.HaloEggInterval)
        if Cfg.AutoHaloEgg and storeEvent then pcall(function() storeEvent:FireServer("Egg", Cfg.HaloEggQty, Cfg.EggCurrency, Cfg.HaloEggName) HaloStatus:SetDesc("正在开蛋: " .. Cfg.HaloEggName) end) else HaloStatus:SetDesc("待机中") end
    end
end)

task.spawn(function()
    local trainEvent; pcall(function() trainEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TrainEvent") end)
    while true do
        task.wait(Cfg.TrainInterval)
        if Cfg.AutoTrain and trainEvent then pcall(function() trainEvent:FireServer(Cfg.TrainAction) TrainStatus:SetDesc("正在锻炼: " .. Cfg.TrainActionCN) end) else TrainStatus:SetDesc("待机中") end
    end
end)

task.spawn(function()
    local rebirthEvent; pcall(function() rebirthEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RebirthEvent") end)
    while true do
        task.wait(Cfg.RebirthCheckInterval)
        if Cfg.AutoRebirth and not Cfg.InfiniteRebirth and rebirthEvent then
            local gameRebirths = getCurrentRebirths()
            if gameRebirths >= Cfg.TargetRebirthCount then Cfg.AutoRebirth = false; RebirthStatus:SetDesc("已完成 " .. gameRebirths .. " 次重生，已停止")
            else
                local currentStr = getCurrentStrength()
                if currentStr >= Cfg.TargetStrength then
                    pcall(function() rebirthEvent:FireServer("Update") end)
                    Cfg.TargetStrength = Cfg.TargetStrength + Cfg.RebirthInc
                    RebirthStatus:SetDesc("进度: " .. gameRebirths .. "/" .. Cfg.TargetRebirthCount)
                    task.wait(Cfg.RebirthCooldown)
                else RebirthStatus:SetDesc("力量: " .. math.floor(currentStr) .. "/" .. Cfg.TargetStrength) end
            end
        end
    end
end)

task.spawn(function()
    local rebirthEvent; pcall(function() rebirthEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RebirthEvent") end)
    while true do
        task.wait(Cfg.RebirthCheckInterval)
        if Cfg.InfiniteRebirth and rebirthEvent then
            local currentStr = getCurrentStrength()
            if currentStr >= Cfg.BaseStrength then
                pcall(function() rebirthEvent:FireServer("Update") end)
                InfiniteStatus:SetDesc("正在重生...")
                task.wait(Cfg.RebirthCooldown)
            else InfiniteStatus:SetDesc("力量: " .. math.floor(currentStr) .. "/" .. Cfg.BaseStrength) end
        else InfiniteStatus:SetDesc("待机中...") end
    end
end)

task.spawn(function()
    local deletedUIDs = {}
    while true do
        task.wait(Cfg.DeleteInterval)
        if Cfg.AutoDelete then
            pcall(function()
                local delEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("DelItemEvent")
                local targetNames = {}
                for name in string.gmatch(Cfg.DeletePetNames .. ",", "([^,]+)") do
                    local trimmed = string.match(name, "^%s*(.-)%s*$")
                    if trimmed ~= "" then targetNames[trimmed] = true end
                end
                local uids = {}
                for _, obj in ipairs(player:GetDescendants()) do
                    if obj:IsA("ImageButton") and targetNames[obj.Name] then
                        local ok, uid = pcall(function() return obj:GetAttribute("UID") end)
                        if ok and uid then
                            local uidStr = tostring(uid)
                            if uidStr:match("^%d+_%d+$") and not deletedUIDs[uidStr] then uids[uidStr] = true; deletedUIDs[uidStr] = true end
                        end
                    end
                end
                local count = 0
                for _ in pairs(uids) do count = count + 1 end
                if count > 0 then delEvent:FireServer("Pet", uids); DeleteStatus:SetDesc("已自动删除 " .. count .. " 只宠物") else DeleteStatus:SetDesc("未发现目标宠物") end
            end)
        else DeleteStatus:SetDesc("待机中") end
    end
end)

local DANGER_RADIUS = 480
local CRATER_RADIUS = 480
local CRATER_DEPTH = 185
local SPACE_ORIGIN = Vector3.new(0, 300000, 0)
local EARTH_RADIUS = 80
local GALAXY_RADIUS = 34000
local SUN_RADIUS = 1400
local EARTH_ORBIT_RADIUS = 3600
local T = { lockEnd = 2, ascentEnd = 6, orbitEnd = 9.5, pullEnd = 12.5, holdEnd = 13.5, swoopEnd = 17, fireT = 21.5, groundT = 23.4, imp = 25, endT = 32 }
local FLAT = CFrame.Angles(0, 0, math.rad(90))
local RED = Color3.fromRGB(255, 56, 56)

local function new(class, props, parent) local inst = Instance.new(class); for k, v in pairs(props) do inst[k] = v end; if parent then inst.Parent = parent end; return inst end
local function vpart(props, parent) local p = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false, Material = Enum.Material.SmoothPlastic, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, nil); for k, v in pairs(props) do p[k] = v end; p.Parent = parent; return p end
local function bigSphere(parent, pos, diameter, color, material, transparency) local p; if diameter <= 2048 then p = vpart({ Shape = Enum.PartType.Ball, Size = Vector3.one * diameter, Position = pos, Color = color, Material = material, Transparency = transparency }, parent) else p = vpart({ Size = Vector3.one * 2048, Position = pos, Color = color, Material = material, Transparency = transparency }, parent); new("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Scale = Vector3.one * (diameter / 2048) }, p) end; return p end
local function clamp01(x) return math.clamp(x, 0, 1) end
local function smooth(t) t = clamp01(t); return t * t * (3 - 2 * t) end
local function rotY(v, a) return CFrame.Angles(0, a, 0):VectorToWorldSpace(v) end
local function randDir() local z = math.random() * 2 - 1; local a = math.random() * math.pi * 2; local r = math.sqrt(1 - z * z); return Vector3.new(r * math.cos(a), z, r * math.sin(a)) end
local function tween(inst, time, props, style, dir) return TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play() end
local fxFolder = new("Folder", { Name = "SpaceCannonFX" }, Workspace)

local isTargeting, targetPos, targetMarker = false, nil, nil

local FunSection = FunTab:Section({ Title = "末日影院轨道炮", Icon = "crosshair" })
local FunStatus = FunSection:Paragraph({ Title = "状态", Desc = "请选择发射目标" })

FunSection:Button({ Title = "🎯 选择发射目标", Callback = function() isTargeting = true; FunStatus:SetDesc("请在游戏画面中点击地面...") end })
FunSection:Button({ Title = "🎬 影院模式发射", Callback = function() if not targetPos then FunStatus:SetDesc("请先选择目标！") return end; isTargeting = false; if targetMarker then targetMarker:Destroy() end; runSequence(targetPos) end })

mouse.Button1Down:Connect(function()
    if isTargeting then
        local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {player.Character, fxFolder}
        local r = Workspace:Raycast(ray.Origin, ray.Direction * 5000, params)
        if r then
            targetPos = r.Position
            isTargeting = false
            FunStatus:SetDesc("目标已选定！")
            if targetMarker then targetMarker:Destroy() end
            local f = new("Folder", { Name = "Marker" }, fxFolder)
            vpart({ Size = Vector3.new(10, 0.5, 10), Shape = Enum.PartType.Cylinder, CFrame = CFrame.new(targetPos) * FLAT, Color = RED, Material = Enum.Material.Neon }, f)
            bigSphere(f, targetPos + Vector3.new(0, 1, 0), 4, RED, Enum.Material.Neon, 0)
            targetMarker = f
        end
    end
end)

local function doImpact(center)
    local R, D = CRATER_RADIUS, CRATER_DEPTH
    local folder = new("Folder", { Name = "Crater" }, Workspace)
    pcall(function()
        local terrain = Workspace.Terrain
        terrain:FillBall(center, R, Enum.Material.Air)
        terrain:FillBall(center - Vector3.new(0, D * 0.5, 0), R * 0.7, Enum.Material.Air)
        terrain:FillBall(center - Vector3.new(0, D * 0.85, 0), R * 0.35, Enum.Material.CrackedLava)
    end)
    local lava = bigSphere(folder, center - Vector3.new(0, D * 0.85, 0), R * 0.9, Color3.fromRGB(255, 40, 0), Enum.Material.Neon, 0.2)
    new("PointLight", { Color = Color3.fromRGB(255, 80, 20), Range = 150, Brightness = 8 }, lava)
    for i = 1, 100 do
        task.spawn(function()
            task.wait(math.random(0, 15) / 10)
            local ang = math.random() * math.pi * 2
            local dist = R * (0.6 + math.random() * 0.4)
            local rock = new("Part", { Size = Vector3.one * math.random(10, 40), Position = center + Vector3.new(math.cos(ang)*dist, 10, math.sin(ang)*dist), Anchored = false, CanCollide = true, Material = Enum.Material.Slate, Color = Color3.fromRGB(30, 30, 30) }, Workspace)
            rock.AssemblyLinearVelocity = Vector3.new(math.random(-100, 100), math.random(100, 250), math.random(-100, 100))
            Debris:AddItem(rock, 15)
        end)
    end
end

local function buildCannon(folder, cf)
    local SCALE = 40
    local model = new("Model", { Name = "StarDestroyer" }, folder)
    local HULL = Color3.fromRGB(28, 31, 39)
    local METAL = Color3.fromRGB(80, 85, 95)
    local function box(x, y, z, sx, sy, sz, col, rz) return vpart({ Size = Vector3.new(sx*SCALE, sy*SCALE, sz*SCALE), Color = col or HULL, Material = Enum.Material.Metal, CFrame = cf * CFrame.new(x*SCALE, y*SCALE, z*SCALE) * CFrame.Angles(0,0,rz or 0) }, model) end
    local function axialCylinder(z, radius, length, col) return vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(length*SCALE, radius*2*SCALE, radius*2*SCALE), Color = col, Material = Enum.Material.Metal, CFrame = cf * CFrame.new(0,0,z*SCALE) * CFrame.Angles(0, math.rad(90), 0) }, model) end
    axialCylinder(0, 3, 20, HULL)
    for i=0,7 do local a = i * math.pi/4; box(math.cos(a)*2.5, math.sin(a)*2.5, 0, 1.5, 2, 20, HULL, a) end
    for k=0,16 do
        local z = -8 + k * 1.0
        for i=0,7 do local a = i * math.pi/4; box(math.cos(a)*3.2, math.sin(a)*3.2, z, 1.2, 0.4, 0.3, METAL, a); box(math.cos(a)*2.8, math.sin(a)*2.8, z, 0.2, 0.6, 0.4, Color3.fromRGB(255, 40, 40), a) end
    end
    axialCylinder(10, 4, 4, HULL)
    for i=0,5 do local a = i * math.pi/3; box(math.cos(a)*4, math.sin(a)*4, 10, 1, 2, 3, METAL, a) end
    for i=1,10 do box(0, 2.5, -5 + i*2, 0.2, 2, 0.2, METAL) end
    return model
end

local function buildPlanet(folder, pos, radius, color)
    local core = bigSphere(folder, pos, radius*2, color, Enum.Material.SmoothPlastic, 0)
    for i=1,250 do
        local land = vpart({ Size = Vector3.one * math.random(2, 8), Position = pos + randDir()*radius, Color = Color3.fromRGB(50,120,50), Material = Enum.Material.SmoothPlastic }, folder)
        land.CFrame = CFrame.lookAt(land.Position, pos)
    end
    bigSphere(folder, pos, radius*2.1, color:Lerp(Color3.new(1,1,1), 0.5), Enum.Material.Neon, 0.85)
    return core
end

function runSequence(target)
    FunStatus:SetDesc("影院模式播放中...")
    local stage = new("Folder", { Name = "SpaceStage" }, Workspace)
    local GC = SPACE_ORIGIN
    local CP = GC + Vector3.new(18000, 1200, 9000)
    local cannonCF = CFrame.lookAt(CP, CP + Vector3.new(-0.78, -0.02, -0.2).Unit)
    local EC = CP + cannonCF.LookVector * 5200
    
    buildCannon(stage, cannonCF)
    buildPlanet(stage, EC, EARTH_RADIUS, Color3.fromRGB(20, 80, 160))
    local sunPos = EC + Vector3.new(3600, 0, 0)
    local sun = buildPlanet(stage, sunPos, SUN_RADIUS, Color3.fromRGB(255, 180, 0))
    new("PointLight", { Color = Color3.fromRGB(255, 220, 100), Range = 100000, Brightness = 5 }, sun)
    
    for i=1,3000 do vpart({ Size = Vector3.one * math.random(10,50), Position = GC + randDir() * 45000, Color = Color3.new(1,1,1), Material = Enum.Material.Neon }, stage) end
    
    local oldAmbient = Lighting.Ambient
    local oldBrightness = Lighting.Brightness
    local oldClock = Lighting.ClockTime
    for _,v in ipairs(Lighting:GetChildren()) do if v:IsA("Sky") or v:IsA("Atmosphere") then v.Parent = nil end end
    Lighting.Ambient = Color3.fromRGB(10,10,20); Lighting.Brightness = 1; Lighting.ClockTime = 0; Lighting.FogEnd = 100000
    
    local oldCamType = camera.CameraType
    camera.CameraType = Enum.CameraType.Scriptable
    local t0 = tick()
    local conn
    
    conn = RunService.RenderStepped:Connect(function()
        local t = tick() - t0
        local camPos, lookAt = Vector3.zero, Vector3.zero
        
        if t < T.ascentEnd then
            camPos = Vector3.new(0, t*2000, 0); lookAt = target + Vector3.new(0, t*500, 0)
        elseif t < T.pullEnd then
            camPos = EC + rotY((CP - EC).Unit, t*0.05) * 6000; lookAt = EC
        elseif t < T.fireT then
            camPos = CP + cannonCF:VectorToWorldSpace(Vector3.new(300 + math.sin(t)*50, 150, 600)); lookAt = CP
        else
            camPos = target + Vector3.new(0, 150, -300); lookAt = target
        end
        
        camera.CFrame = CFrame.lookAt(camPos, lookAt)
        
        if t >= T.fireT and t < T.groundT then
            local beam = vpart({ Size = Vector3.new(10, 10, 2000), CFrame = CFrame.lookAt(CP, target) * CFrame.new(0,0,-1000), Color = RED, Material = Enum.Material.Neon }, stage)
            Debris:AddItem(beam, 0.5)
        end
        
        if t >= T.imp and t < T.imp + 0.1 then doImpact(target) end
        
        if t > T.endT then
            conn:Disconnect(); stage:Destroy(); camera.CameraType = oldCamType
            Lighting.Ambient = oldAmbient; Lighting.Brightness = oldBrightness; Lighting.ClockTime = oldClock; Lighting.FogEnd = 100000
            local sky = Instance.new("Sky", Lighting)
            sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex"; sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
            sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex"; sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
            sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex"; sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
            FunStatus:SetDesc("影院模式完成")
        end
    end)
end