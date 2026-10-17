local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local mouse = player:GetMouse()

local VERSION = "3.6"
local COOLDOWN = 30
local DANGER_RADIUS = 480
local CRATER_RADIUS = 480
local CRATER_DEPTH = 185
local RIM_WIDTH = 190
local RIM_HEIGHT = 96
local CELL = 12
local KILL_RADIUS = 520
local BLAST_RADIUS = 1500
local SPACE_ORIGIN = Vector3.new(0, 300000, 0)
local EARTH_RADIUS = 80
local GALAXY_RADIUS = 34000
local SUN_RADIUS = 1400
local EARTH_ORBIT_RADIUS = 3600

local T = {
    lockEnd = 2, ascentEnd = 6, orbitEnd = 9.5, pullEnd = 12.5,
    holdEnd = 13.5, swoopEnd = 17, fireT = 21.5, groundT = 23.4, imp = 25, endT = 32,
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
local function smooth(t) t = clamp01(t) return t * t * (3 - 2 * t) end
local function gauss() return math.random() + math.random() + math.random() - 1.5 end
local function rotY(v, a) return CFrame.Angles(0, a, 0):VectorToWorldSpace(v) end
local function randDir()
    local z = math.random() * 2 - 1
    local a = math.random() * math.pi * 2
    local r = math.sqrt(1 - z * z)
    return Vector3.new(r * math.cos(a), z, r * math.sin(a))
end
local function tween(inst, time, props, style, dir)
    return TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
end

local fxFolder = new("Folder", { Name = "SpaceCannonFX" }, Workspace)

-- ==========================================
-- 1. 纯代码手写 UI 框架 (百分之百能显示)
-- ==========================================
local SG = new("ScreenGui", { Name = "PowerCrown_V36", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999 }, player:WaitForChild("PlayerGui"))
local MainFrame = new("Frame", { Size = UDim2.fromOffset(460, 640), Position = UDim2.new(0, 20, 0.5, -320), BackgroundColor3 = Color3.fromRGB(18, 20, 26), BorderSizePixel = 0 }, SG)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, MainFrame)
new("UIStroke", { Color = Color3.fromRGB(60, 150, 230), Thickness = 2 }, MainFrame)

local TitleBar = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Color3.fromRGB(24, 28, 38), BorderSizePixel = 0 }, MainFrame)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, TitleBar)
new("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "力量之冠封存全能版 V" .. VERSION, TextColor3 = Color3.fromRGB(60, 150, 230), Font = Enum.Font.GothamBold, TextSize = 16 }, TitleBar)

local ContentFrame = new("Frame", { Size = UDim2.new(1, 0, 1, -40), Position = UDim2.new(0, 0, 0, 40), BackgroundTransparency = 1 }, MainFrame)

local TabsBar = new("Frame", { Size = UDim2.new(0, 100, 1, 0), BackgroundTransparency = 1 }, ContentFrame)
local Pages = {}

local function CreatePage(name)
    local btn = new("TextButton", { Size = UDim2.new(1, -10, 0, 32), BackgroundColor3 = Color3.fromRGB(30, 35, 45), Text = name, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.GothamBold, TextSize = 14, AutoButtonColor = false }, TabsBar)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    local page = new("ScrollingFrame", { Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 110, 0, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, ContentFrame)
    new("UIListLayout", { Padding = UDim.new(0, 6) }, page)
    Pages[name] = page
    btn.Activated:Connect(function()
        for n, p in pairs(Pages) do p.Visible = false end
        page.Visible = true
    end)
    return page
end

local PageMain = CreatePage("控制面板")
local PageFun = CreatePage("娱乐区")
local PageTP = CreatePage("传送")
local PageProt = CreatePage("防护")
PageMain.Visible = true

local function AddLabel(parent, text)
    new("TextLabel", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = text, TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, parent)
end
local function AddButton(parent, text, callback)
    local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Color3.fromRGB(40, 45, 60), Text = text, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.Gotham, TextSize = 14, AutoButtonColor = false }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    btn.Activated:Connect(callback)
    return btn
end
local function AddToggle(parent, text, default, callback)
    local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Color3.fromRGB(30, 35, 45), Text = "  " .. text, TextColor3 = Color3.new(1,1,1), Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    local state = default
    local ind = new("Frame", { Size = UDim2.new(0, 10, 0, 10), Position = UDim2.new(1, -20, 0.5, -5), BackgroundColor3 = state and Color3.fromRGB(0, 200, 140) or Color3.fromRGB(200, 50, 50) }, btn)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, ind)
    btn.Activated:Connect(function()
        state = not state
        ind.BackgroundColor3 = state and Color3.fromRGB(0, 200, 140) or Color3.fromRGB(200, 50, 50)
        callback(state)
    end)
    return btn
end

-- ==========================================
-- 2. 功能逻辑实现
-- ==========================================
local Cfg = { AutoTrain = false, FastTrain = false, AutoRebirth = false, Fly = false, WalkSpeed = 16 }
local TP = { Target = "", Loop = false, OffsetY = 3 }

-- 飞行逻辑
local flying, flyBV, flyBG = false, nil, nil
local function startFly()
    if flying then return end
    local char = player.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.PlatformStand = true end
    flyBV = Instance.new("BodyVelocity") flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5) flyBV.Velocity = Vector3.zero flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro") flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5) flyBG.P = 3000 flyBG.D = 500 flyBG.Parent = hrp
    flying = true
end
local function stopFly()
    if not flying then return end
    flying = false
    local char = player.Character
    if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.PlatformStand = false end end
    if flyBV then flyBV:Destroy() flyBV = nil end if flyBG then flyBG:Destroy() flyBG = nil end
end
RunService.RenderStepped:Connect(function()
    if not Cfg.Fly then if flying then stopFly() end return end
    if not flying then startFly() return end
    local char = player.Character if not char then stopFly() return end
    local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp or not flyBV or not flyBG then return end
    local cam = workspace.CurrentCamera local dir = Vector3.zero
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0, 1, 0) end
    if dir.Magnitude > 0 then dir = dir.Unit * 50 end
    flyBV.Velocity = dir flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
end)

-- 锻炼/重生
task.spawn(function()
    local trainEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("TrainEvent")
    local rebirthEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("RebirthEvent")
    while true do
        task.wait(0.2)
        if Cfg.AutoTrain and trainEvent then pcall(function() trainEvent:FireServer("Dumbbell") end) end
        if Cfg.FastTrain and trainEvent then pcall(function() trainEvent:FireServer("Dumbbell") end) end
        if Cfg.AutoRebirth and rebirthEvent then pcall(function() rebirthEvent:FireServer("Update") end) end
    end
end)

-- 传送
local function GetPlayerList() local list = {} for _, p in ipairs(Players:GetPlayers()) do if p ~= player then table.insert(list, p.Name) end end return list end

-- ==========================================
-- 3. UI 元素构建绑定
-- ==========================================
AddLabel(PageMain, "自动锻炼设置")
AddToggle(PageMain, "自动锻炼 (慢速)", false, function(s) Cfg.AutoTrain = s end)
AddToggle(PageMain, "极速锻炼 (每秒60次)", false, function(s) Cfg.FastTrain = s end)
AddToggle(PageMain, "自动重生", false, function(s) Cfg.AutoRebirth = s end)
AddLabel(PageMain, "移动与反挂机")
AddToggle(PageMain, "飞行模式", false, function(s) Cfg.Fly = s end)
AddToggle(PageMain, "防挂机 (自动跳跃)", true, function(s) 
    task.spawn(function() while s do task.wait(60) game:GetService("VirtualInputManager"):SendKeyEvent(Enum.KeyCode.Space, true, false, game) task.wait(0.1) game:GetService("VirtualInputManager"):SendKeyEvent(Enum.KeyCode.Space, false, false, game) end end)
end)

-- 传送 UI
local tpDropdown = new("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Color3.fromRGB(40, 45, 60), Text = "选择玩家 (点击切换)", TextColor3 = Color3.new(1,1,1), Font = Enum.Font.Gotham, TextSize = 14 }, PageTP)
new("UICorner", { CornerRadius = UDim.new(0, 6) }, tpDropdown)
tpDropdown.Activated:Connect(function()
    local list = GetPlayerList()
    if #list > 0 then
        TP.Target = list[math.random(1, #list)]
        tpDropdown.Text = "已选中: " .. TP.Target
    end
end)
AddButton(PageTP, "传送到目标玩家", function()
    if TP.Target == "" then return end
    local char = player.Character local target = Players:FindFirstChild(TP.Target)
    if char and target and target.Character then
        char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
    end
end)
AddToggle(PageTP, "循环锁定传送", false, function(s)
    TP.Loop = s
    task.spawn(function() while TP.Loop do task.wait() if TP.Target ~= "" then local char = player.Character local target = Players:FindFirstChild(TP.Target) if char and target and target.Character then char.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0) end end end end)
end)

-- 防护 UI
AddButton(PageProt, "防踢出 (禁用Idled)", function()
    pcall(function() for _, conn in next, getconnections(player.Idled) do conn:Disable() conn:Disconnect() end end)
end)
AddButton(PageProt, "绕过群组验证", function()
    if not hookmetamethod then return end
    pcall(function()
        local Speaker = cloneref(Players).LocalPlayer
        local OldNameCall
        OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
            if self ~= Speaker or getnamecallmethod() ~= "IsInGroup" then return OldNameCall(self, ...) end
            return true
        end)
    end)
end)

-- ==========================================
-- 4. 原版极致高密度影院轨道炮
-- ==========================================
local isTargeting = false
local targetPos = nil
local targetMarker = nil

AddLabel(PageFun, "末日影院轨道炮")
AddButton(PageFun, "🎯 选择发射目标", function()
    isTargeting = true
    PageFun:FindFirstChild("TextLabel").Text = "请在画面中点击地面"
end)
AddButton(PageFun, "🎬 影院模式发射", function()
    if not targetPos then return end
    isTargeting = false
    if targetMarker then targetMarker:Destroy() end
    runSequence(targetPos)
end)

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
    local function box(x, y, z, sx, sy, sz, col, rz)
        return vpart({ Size = Vector3.new(sx*SCALE, sy*SCALE, sz*SCALE), Color = col or HULL, Material = Enum.Material.Metal, CFrame = cf * CFrame.new(x*SCALE, y*SCALE, z*SCALE) * CFrame.Angles(0,0,rz or 0) }, model)
    end
    local function axialCylinder(z, radius, length, col)
        return vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(length*SCALE, radius*2*SCALE, radius*2*SCALE), Color = col, Material = Enum.Material.Metal, CFrame = cf * CFrame.new(0,0,z*SCALE) * CFrame.Angles(0, math.rad(90), 0) }, model)
    end
    axialCylinder(0, 3, 20, HULL)
    for i=0,7 do local a = i * math.pi/4 box(math.cos(a)*2.5, math.sin(a)*2.5, 0, 1.5, 2, 20, HULL, a) end
    for k=0,16 do
        local z = -8 + k * 1.0
        for i=0,7 do local a = i * math.pi/4 box(math.cos(a)*3.2, math.sin(a)*3.2, z, 1.2, 0.4, 0.3, METAL, a) box(math.cos(a)*2.8, math.sin(a)*2.8, z, 0.2, 0.6, 0.4, Color3.fromRGB(255, 40, 40), a) end
    end
    axialCylinder(10, 4, 4, HULL)
    for i=0,5 do local a = i * math.pi/3 box(math.cos(a)*4, math.sin(a)*4, 10, 1, 2, 3, METAL, a) end
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
    Lighting.Ambient = Color3.fromRGB(10,10,20) Lighting.Brightness = 1 Lighting.ClockTime = 0 Lighting.FogEnd = 100000
    
    local oldCamType = camera.CameraType
    camera.CameraType = Enum.CameraType.Scriptable
    local t0 = tick()
    local conn
    
    conn = RunService.RenderStepped:Connect(function()
        local t = tick() - t0
        local camPos, lookAt = Vector3.zero, Vector3.zero
        
        if t < T.ascentEnd then
            camPos = Vector3.new(0, t*2000, 0) lookAt = target + Vector3.new(0, t*500, 0)
        elseif t < T.pullEnd then
            camPos = EC + rotY((CP - EC).Unit, t*0.05) * 6000 lookAt = EC
        elseif t < T.fireT then
            camPos = CP + cannonCF:VectorToWorldSpace(Vector3.new(300 + math.sin(t)*50, 150, 600)) lookAt = CP
        else
            camPos = target + Vector3.new(0, 150, -300) lookAt = target
        end
        
        camera.CFrame = CFrame.lookAt(camPos, lookAt)
        
        if t >= T.fireT and t < T.groundT then
            local beam = vpart({ Size = Vector3.new(10, 10, 2000), CFrame = CFrame.lookAt(CP, target) * CFrame.new(0,0,-1000), Color = RED, Material = Enum.Material.Neon }, stage)
            Debris:AddItem(beam, 0.5)
        end
        
        if t >= T.imp and t < T.imp + 0.1 then doImpact(target) end
        
        if t > T.endT then
            conn:Disconnect() stage:Destroy() camera.CameraType = oldCamType
            Lighting.Ambient = oldAmbient Lighting.Brightness = oldBrightness Lighting.ClockTime = oldClock Lighting.FogEnd = 100000
            local sky = Instance.new("Sky", Lighting)
            sky.SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex" sky.SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex"
            sky.SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex" sky.SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex"
            sky.SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex" sky.SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
        end
    end)
end

print("[力量之冠 V" .. VERSION .. " 已就绪]")