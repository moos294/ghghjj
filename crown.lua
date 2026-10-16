local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

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
    TotalReps = 0, AutoRebirthDone = 0, ScriptStartTime = tick(),
    TeleportTarget = "", TeleportLoop = false, TeleportOffsetY = 3,
    AntiIdleKick = true, AntiClientKick = false, BypassGroup = false,

    RailgunKeyBind = true,
    RailgunCooldown = 1.2,
    RailgunWidthOuter = 4,
    RailgunWidthMid = 2.4,
    RailgunWidthCore = 1,
    RailgunCraterRadius = 14,
    RailgunCraterDepth = 12,
    RailgunCraterEnabled = true,
    RailgunDebrisCount = 35,
    RailgunDebrisEnabled = true,
    RailgunShake = true,
    RailgunShakeIntensity = 2.2,
    RailgunShakeDuration = 0.55,
    RailgunColorOuter = Color3.fromRGB(255, 40, 0),
    RailgunColorMid = Color3.fromRGB(255, 160, 40),
    RailgunColorCore = Color3.fromRGB(255, 255, 255),
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
    return c
end

local function stroke(p, c, t, tr)
    local s = Instance.new("UIStroke")
    s.Color = c or C.stroke
    s.Thickness = t or 1
    s.Transparency = tr or 0
    s.Parent = p
    return s
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
        if player:FindFirstChild("Strength") then str = player.Strength.Value return end
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
        local names = {"Rebirths", "Rebirth", "RebirthCount"}
        for _, n in ipairs(names) do
            if player:FindFirstChild(n) and (player[n]:IsA("IntValue") or player[n]:IsA("NumberValue")) then
                count = player[n].Value return
            end
        end
    end)
    return count
end

local function applyAntiIdleKick()
    if not getconnections then
        warn("[反挂机-kick] 当前执行器不支持 getconnections")
        return
    end
    pcall(function()
        for _, conn in next, getconnections(player.Idled) do
            pcall(function() conn:Disable() end)
            pcall(function() conn:Disconnect() end)
        end
    end)
end

local function applyAntiClientKick()
    if not getgc then
        warn("[防踢] 当前执行器不支持 getgc")
        return
    end
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
    if not hookmetamethod or not hookfunction then
        warn("[绕过群组] 当前执行器不支持 hookmetamethod / hookfunction")
        return
    end
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

        hookfunction(Speaker.IsInGroup, function(self, ...)
            return true
        end)
    end)
end

local function applyGrayBuildings()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local isCharacter = false
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character and obj:IsDescendantOf(plr.Character) then
                    isCharacter = true
                    break
                end
            end
            local isPet = false
            local parent = obj.Parent
            while parent and parent ~= workspace do
                if parent.Name:lower():find("pet") or parent.Name:lower():find("宠物") then
                    isPet = true
                    break
                end
                parent = parent.Parent
            end
            if not isCharacter and not isPet then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Color = Color3.fromRGB(128, 128, 128)
                obj.Reflectance = 0
                for _, child in ipairs(obj:GetChildren()) do
                    if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance") then
                        child:Destroy()
                    end
                end
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
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                        end
                    end
                end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("pet") or obj.Name:lower():find("宠物")) then
            for _, part in ipairs(obj:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 1
                end
            end
        end
    end
end

local function boostPerformance()
    local Lighting = game:GetService("Lighting")
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
        if v:IsA("PostEffect") then
            v:Destroy()
        end
    end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
            v.Enabled = false
        end
        if v:IsA("Beam") then
            v.Enabled = false
        end
        if v:IsA("Texture") or v:IsA("Decal") then
            v.Transparency = 1
        end
        if v:IsA("SurfaceAppearance") then
            v:Destroy()
        end
    end
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    pcall(function()
        collectgarbage()
    end)
end

local TP = {
    Target = "",
    Loop = false,
    OffsetY = 3,
    Thread = nil,
}

function TP:GetPlayerList(includeLocal)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if includeLocal or p ~= player then
            table.insert(list, p.Name)
        end
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

local function newEffectPart(shape, material, color, transparency)
    local p = Instance.new("Part")
    p.Shape = shape
    p.Material = material
    p.Color = color
    p.Transparency = transparency or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = false
    return p
end

local function createBeam(startPos, endPos, width, color, transparency)
    local holder = newEffectPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, color, 1)
    holder.Size = Vector3.new(0.1, 0.1, 0.1)
    holder.CFrame = CFrame.new(startPos)
    holder.Parent = workspace

    local att0 = Instance.new("Attachment")
    att0.WorldPosition = startPos
    att0.Parent = holder

    local att1 = Instance.new("Attachment")
    att1.WorldPosition = endPos
    att1.Parent = holder

    local beam = Instance.new("Beam")
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Color = ColorSequence.new(color)
    beam.Width0 = width
    beam.Width1 = width
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Transparency = NumberSequence.new(transparency)
    beam.Segments = 10
    beam.Parent = holder

    return holder, beam
end

local function createMuzzleFlash(position)
    local flash = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 220, 180), 0.2)
    flash.Size = Vector3.new(4, 4, 4)
    flash.Position = position
    flash.Parent = workspace

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 180, 80)
    light.Range = 25
    light.Brightness = 8
    light.Parent = flash

    TweenService:Create(flash, TweenInfo.new(0.25), {
        Size = Vector3.new(8, 8, 8),
        Transparency = 1
    }):Play()

    Debris:AddItem(flash, 0.4)
end

local function createImpactFlash(position)
    local flash = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 255, 220), 0)
    flash.Size = Vector3.new(2, 2, 2)
    flash.Position = position
    flash.Parent = workspace

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 200, 100)
    light.Range = 45
    light.Brightness = 20
    light.Parent = flash

    TweenService:Create(flash, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(35, 35, 35),
        Transparency = 1
    }):Play()

    Debris:AddItem(flash, 0.8)
end

local function createShockwave(position, delay, maxScale, color)
    task.delay(delay, function()
        local ring = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, color, 0.15)
        ring.Size = Vector3.new(0.5, 2, 2)
        ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
        ring.Parent = workspace

        TweenService:Create(ring, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.5, maxScale, maxScale),
            Transparency = 1
        }):Play()

        Debris:AddItem(ring, 1)
    end)
end

local function createCrater(hitPosition)
    if not Cfg.RailgunCraterEnabled then return end
    
    local terrain = workspace.Terrain
    local radius = Cfg.RailgunCraterRadius
    local depth = Cfg.RailgunCraterDepth
    
    terrain:FillBall(hitPosition, radius, Enum.Material.Air)
    terrain:FillBall(hitPosition - Vector3.new(0, depth * 0.4, 0), radius * 0.8, Enum.Material.Air)
    terrain:FillBall(hitPosition - Vector3.new(0, depth * 0.8, 0), radius * 0.5, Enum.Material.Air)
    
    terrain:FillBall(hitPosition - Vector3.new(0, depth * 0.9, 0), radius * 0.55, Enum.Material.Basalt)
    for i = 1, 8 do
        local angle = math.random() * math.pi * 2
        local dist = radius * (0.7 + math.random() * 0.5)
        local offset = Vector3.new(math.cos(angle) * dist, math.random(-2, 1), math.sin(angle) * dist)
        terrain:FillBall(hitPosition + offset, math.random(2, 4), Enum.Material.Basalt)
    end

    local lava = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(255, 70, 0), 0.3)
    lava.Size = Vector3.new(0.5, radius * 0.5, radius * 0.5)
    lava.CFrame = CFrame.new(hitPosition - Vector3.new(0, depth * 0.85, 0)) * CFrame.Angles(0, 0, math.rad(90))
    lava.Parent = workspace
    
    TweenService:Create(lava, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.5, radius * 0.7, radius * 0.7),
        Transparency = 1,
        Color = Color3.fromRGB(100, 20, 0)
    }):Play()
    Debris:AddItem(lava, 4.5)

    for i = 1, 6 do
        local crack = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 120, 0), 0.2)
        local crackLen = math.random(radius * 1.2, radius * 2.5)
        crack.Size = Vector3.new(0.3, 0.3, crackLen)
        local angle = math.random() * math.pi * 2
        crack.CFrame = CFrame.new(hitPosition) * CFrame.Angles(0, angle, 0) * CFrame.new(0, 0.2, -crackLen / 2)
        crack.Parent = workspace
        
        TweenService:Create(crack, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Transparency = 1
        }):Play()
        Debris:AddItem(crack, 3)
    end

    local particleHolder = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), 1)
    particleHolder.Size = Vector3.new(1, 1, 1)
    particleHolder.Position = hitPosition - Vector3.new(0, depth * 0.4, 0)
    particleHolder.Parent = workspace

    local smoke = Instance.new("ParticleEmitter")
    smoke.Texture = "rbxassetid://243660364"
    smoke.Color = ColorSequence.new(Color3.fromRGB(40, 40, 40), Color3.fromRGB(120, 120, 120))
    smoke.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 12)})
    smoke.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1)})
    smoke.Lifetime = NumberRange.new(1.5, 4)
    smoke.Rate = 40
    smoke.Speed = NumberRange.new(5, 15)
    smoke.SpreadAngle = Vector2.new(30, 30)
    smoke.Parent = particleHolder

    local embers = Instance.new("ParticleEmitter")
    embers.Texture = "rbxassetid://243660364"
    embers.Color = ColorSequence.new(Color3.fromRGB(255, 180, 0), Color3.fromRGB(255, 40, 0))
    embers.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0)})
    embers.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1)})
    embers.Lifetime = NumberRange.new(1, 2.5)
    embers.Rate = 80
    embers.Speed = NumberRange.new(15, 40)
    embers.SpreadAngle = Vector2.new(180, 180)
    embers.Parent = particleHolder

    task.delay(2.5, function()
        smoke.Enabled = false
        embers.Enabled = false
    end)
    Debris:AddItem(particleHolder, 6)
end

local function spawnRailgunDebris(hitPosition)
    if not Cfg.RailgunDebrisEnabled then return end
    for i = 1, Cfg.RailgunDebrisCount do
        local size = math.random(10, 35) / 10
        local rock = Instance.new("Part")
        rock.Shape = Enum.PartType.Block
        rock.Material = Enum.Material.Slate
        rock.Color = Color3.fromRGB(70, 65, 60)
        rock.Size = Vector3.new(
            size * (0.7 + math.random() * 0.6),
            size * (0.7 + math.random() * 0.6),
            size * (0.7 + math.random() * 0.6)
        )
        rock.Anchored = false
        rock.CanCollide = false
        rock.CanQuery = false
        rock.CanTouch = false

        local angle = math.random() * math.pi * 2
        local radius = math.random() * 2
        rock.Position = hitPosition + Vector3.new(
            math.cos(angle) * radius,
            math.random() * 2 - 1,
            math.sin(angle) * radius
        )
        rock.CFrame = CFrame.new(rock.Position) * CFrame.Angles(
            math.random() * math.pi * 2,
            math.random() * math.pi * 2,
            math.random() * math.pi * 2
        )
        rock.Parent = workspace

        local dir = Vector3.new(math.cos(angle), 1, math.sin(angle)).Unit
        rock.AssemblyLinearVelocity = dir * 60 * (0.5 + math.random()) + Vector3.new(0, math.random(15, 40), 0)
        rock.AssemblyAngularVelocity = Vector3.new(
            math.random(-20, 20), math.random(-20, 20), math.random(-20, 20)
        )

        Debris:AddItem(rock, 3.5)
    end
end

local function screenShake(intensity, duration)
    if not Cfg.RailgunShake then return end
    local startTime = tick()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local elapsed = tick() - startTime
        if elapsed >= duration then
            conn:Disconnect()
            return
        end
        local fade = 1 - (elapsed / duration)
        local sx = (math.random() - 0.5) * intensity * fade
        local sy = (math.random() - 0.5) * intensity * fade
        camera.CFrame = camera.CFrame * CFrame.new(sx, sy, 0)
    end)
end

local function raycastGround()
    local character = player.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end

    local origin = (rootPart.CFrame * CFrame.new(0, 5, -3)).Position
    local direction = Vector3.new(0, -300, 0)

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = false

    local result = workspace:Raycast(origin, direction, params)
    if result then
        return origin, result.Position
    end
    return nil
end

local lastRailgunFire = 0

local function fireRailgun()
    local now = tick()
    if now - lastRailgunFire < Cfg.RailgunCooldown then return end
    lastRailgunFire = now

    local origin, hitPos = raycastGround()
    if not hitPos then return end

    createMuzzleFlash(origin)

    local beams = {}
    table.insert(beams, createBeam(origin, hitPos, Cfg.RailgunWidthOuter, Cfg.RailgunColorOuter, NumberSequence.new(0.45)))
    table.insert(beams, createBeam(origin, hitPos, Cfg.RailgunWidthMid, Cfg.RailgunColorMid, NumberSequence.new(0.15)))
    table.insert(beams, createBeam(origin, hitPos, Cfg.RailgunWidthCore, Cfg.RailgunColorCore, NumberSequence.new(0)))

    createImpactFlash(hitPos)
    createShockwave(hitPos, 0, Cfg.RailgunCraterRadius * 2.4, Color3.fromRGB(255, 180, 80))
    createShockwave(hitPos, 0.1, Cfg.RailgunCraterRadius * 3.2, Color3.fromRGB(255, 80, 40))

    createCrater(hitPos)
    spawnRailgunDebris(hitPos)
    screenShake(Cfg.RailgunShakeIntensity, Cfg.RailgunShakeDuration)

    task.delay(0.45, function()
        for _, part in ipairs(beams) do
            if part and part.Parent then
                local beam = part:FindFirstChildOfClass("Beam")
                if beam then
                    TweenService:Create(beam, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {
                        Width0 = 0,
                        Width1 = 0
                    }):Play()
                end
                Debris:AddItem(part, 0.6)
            end
        end
    end)
end

_G.FireRailgun = fireRailgun

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "力量之冠封存全能版", Icon = "zap", Author = "力量之冠",
    Folder = "PowerCrownSave", Theme = "Dark", Transparent = true,
    Resizable = false, Size = UDim2.fromOffset(460, 780),
})
local MainTab = Window:Tab({ Title = "控制面板", Icon = "settings" })

local CommonSection = MainTab:Section({ Title = "公共设置", Icon = "settings" })
CommonSection:Slider({ Title = "抽蛋间隔 (秒)", Desc = "0.1 最快", Value = { Min = 0.1, Max = 1.0, Default = 0.1 }, Step = 0.05, Callback = function(value) Cfg.EggInterval = value end })

local PetSection = MainTab:Section({ Title = "🐾 宠物区", Icon = "paw" })
PetSection:Toggle({ Title = "自动抽宠物蛋", Value = false, Callback = function(state) Cfg.AutoPetEgg = state end })
PetSection:Input({ Title = "宠物蛋名字", Placeholder = "SkyPetEgg", Value = "SkyPetEgg", Callback = function(text) Cfg.PetEggName = text end })
PetSection:Dropdown({ Title = "宠物蛋数量", Values = {"1", "3"}, Value = "1", Multi = false, Callback = function(selected) local val = tonumber(selected) if val then Cfg.PetEggQty = val end end })
PetSection:Input({ Title = "宠物蛋单价", Placeholder = "3", Value = "3", Callback = function(text) local val = tonumber(text) if val then Cfg.PetEggPrice = val end end })
local PetStatus = PetSection:Paragraph({ Title = "宠物区状态", Desc = "待机中..." })

local HaloSection = MainTab:Section({ Title = "✨ 光环区", Icon = "star" })
HaloSection:Toggle({ Title = "自动抽光环蛋", Value = false, Callback = function(state) Cfg.AutoHaloEgg = state end })
HaloSection:Input({ Title = "光环蛋名字", Placeholder = "SkyHaloEgg", Value = "SkyHaloEgg", Callback = function(text) Cfg.HaloEggName = text end })
HaloSection:Dropdown({ Title = "光环蛋数量", Values = {"1", "3"}, Value = "1", Multi = false, Callback = function(selected) local val = tonumber(selected) if val then Cfg.HaloEggQty = val end end })
HaloSection:Input({ Title = "光环蛋单价", Placeholder = "1", Value = "1", Callback = function(text) local val = tonumber(text) if val then Cfg.HaloEggPrice = val end end })
local HaloStatus = HaloSection:Paragraph({ Title = "光环区状态", Desc = "待机中..." })

local TrainSection = MainTab:Section({ Title = "🏋️ 自动锻炼", Icon = "activity" })
TrainSection:Toggle({ Title = "自动锻炼", Value = false, Callback = function(state) Cfg.AutoTrain = state end })
TrainSection:Dropdown({ Title = "选择动作 (中文)", Values = ActionListCN, Value = "哑铃", Multi = false, Callback = function(selected) local cn = selected local en = ActionMap[cn] if en then Cfg.TrainAction = en Cfg.TrainActionCN = cn end end })
TrainSection:Slider({ Title = "锻炼间隔 (秒)", Value = { Min = 0.1, Max = 1.0, Default = 0.2 }, Step = 0.05, Callback = function(value) Cfg.TrainInterval = value end })
local TrainStatus = TrainSection:Paragraph({ Title = "锻炼状态", Desc = "待机中..." })

local FastTrainSection = MainTab:Section({ Title = "⚡ 无间隔锻炼 (极速)", Icon = "gauge" })
FastTrainSection:Toggle({ Title = "无间隔自动锻炼", Value = false, Callback = function(state) Cfg.FastTrain = state end })
FastTrainSection:Dropdown({ Title = "选择动作 (中文)", Values = ActionListCN, Value = "哑铃", Multi = false, Callback = function(selected) local cn = selected local en = ActionMap[cn] if en then Cfg.FastTrainAction = en Cfg.FastTrainActionCN = cn end end })
FastTrainSection:Slider({ Title = "每帧触发次数", Desc = "1=每帧1次 (≈60次/秒)", Value = { Min = 1, Max = 10, Default = 1 }, Step = 1, Callback = function(value) Cfg.FastPerBeat = value end })
FastTrainSection:Slider({ Title = "每秒上限 (0=不限)", Desc = "防踢设置", Value = { Min = 0, Max = 100, Default = 0 }, Step = 5, Callback = function(value) Cfg.FastMaxPerSecond = value end })
local FastTrainStatus = FastTrainSection:Paragraph({ Title = "极速锻炼状态", Desc = "待机中..." })

local RebirthSection = MainTab:Section({ Title = "💀 自动重生 (限次)", Icon = "refresh-cw" })
RebirthSection:Toggle({ Title = "自动重生", Value = false, Callback = function(state) Cfg.AutoRebirth = state end })
RebirthSection:Input({ Title = "初始目标力量", Placeholder = "10000", Value = "10000", Callback = function(text) local val = tonumber(text) if val then Cfg.TargetStrength = val end end })
RebirthSection:Input({ Title = "每次递增数值", Placeholder = "10000", Value = "10000", Callback = function(text) local val = tonumber(text) if val then Cfg.RebirthInc = val end end })
RebirthSection:Input({ Title = "目标重生次数", Placeholder = "5", Value = "5", Callback = function(text) local val = tonumber(text) if val then Cfg.TargetRebirthCount = val end end })
local RebirthStatus = RebirthSection:Paragraph({ Title = "重生状态", Desc = "待机中..." })

local InfiniteSection = MainTab:Section({ Title = "♻️ 无限循环重生", Icon = "repeat" })
InfiniteSection:Toggle({ Title = "无限循环重生", Value = false, Callback = function(state) Cfg.InfiniteRebirth = state if state then Cfg.AutoRebirth = false end end })
InfiniteSection:Input({ Title = "基础目标力量", Placeholder = "10000", Value = "10000", Callback = function(text) local val = tonumber(text) if val then Cfg.BaseStrength = val end end })
local InfiniteStatus = InfiniteSection:Paragraph({ Title = "无限循环状态", Desc = "待机中..." })

local MoveSection = MainTab:Section({ Title = "⚡ 移动与反挂机", Icon = "move" })
MoveSection:Toggle({ Title = "飞行模式", Value = false, Callback = function(state) Cfg.Fly = state end })
MoveSection:Slider({ Title = "步行速度", Value = { Min = 16, Max = 500, Default = 16 }, Step = 1, Callback = function(value) Cfg.WalkSpeed = value local char = player.Character if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed = value end end end })
MoveSection:Slider({ Title = "飞行速度", Value = { Min = 10, Max = 500, Default = 50 }, Step = 1, Callback = function(value) Cfg.FlySpeed = value end })
MoveSection:Toggle({ Title = "反挂机", Value = true, Callback = function(state) Cfg.AntiAfk = state end })

local VisualSection = MainTab:Section({ Title = "场景优化", Icon = "eye" })
VisualSection:Button({
    Title = "灰色建筑模式",
    Callback = function()
        applyGrayBuildings()
    end
})
VisualSection:Button({
    Title = "隐藏宠物",
    Callback = function()
        hidePets()
    end
})
VisualSection:Button({
    Title = "提高帧率并降低延迟",
    Callback = function()
        boostPerformance()
    end
})

local FunTab = Window:Tab({ Title = "娱乐区", Icon = "sparkles" })

local RailgunSection = FunTab:Section({ Title = "轨道炮激光", Icon = "zap" })

local RailgunStatus = RailgunSection:Paragraph({ Title = "轨道炮状态", Desc = "按 F 或点击下方按钮发射" })

RailgunSection:Button({
    Title = "立即发射",
    Callback = function()
        fireRailgun()
        RailgunStatus:SetDesc("已发射轨道炮")
    end
})

RailgunSection:Toggle({
    Title = "启用 F 键发射",
    Value = true,
    Callback = function(state)
        Cfg.RailgunKeyBind = state
        RailgunStatus:SetDesc(state and "F 键发射已启用" or "F 键发射已关闭")
    end
})

RailgunSection:Slider({
    Title = "发射冷却 (秒)",
    Value = { Min = 0.1, Max = 5, Default = 1.2 },
    Step = 0.1,
    Callback = function(value)
        Cfg.RailgunCooldown = value
    end
})

RailgunSection:Slider({
    Title = "外层激光宽度",
    Value = { Min = 1, Max = 15, Default = 4 },
    Step = 0.5,
    Callback = function(value)
        Cfg.RailgunWidthOuter = value
    end
})

RailgunSection:Slider({
    Title = "中层激光宽度",
    Value = { Min = 0.5, Max = 10, Default = 2.4 },
    Step = 0.2,
    Callback = function(value)
        Cfg.RailgunWidthMid = value
    end
})

RailgunSection:Slider({
    Title = "内核激光宽度",
    Value = { Min = 0.2, Max = 5, Default = 1 },
    Step = 0.1,
    Callback = function(value)
        Cfg.RailgunWidthCore = value
    end
})

RailgunSection:Slider({
    Title = "坑洞半径",
    Value = { Min = 0, Max = 40, Default = 14 },
    Step = 1,
    Callback = function(value)
        Cfg.RailgunCraterRadius = value
    end
})

RailgunSection:Slider({
    Title = "坑洞深度",
    Value = { Min = 0, Max = 30, Default = 12 },
    Step = 1,
    Callback = function(value)
        Cfg.RailgunCraterDepth = value
    end
})

RailgunSection:Slider({
    Title = "碎石数量",
    Value = { Min = 0, Max = 100, Default = 35 },
    Step = 5,
    Callback = function(value)
        Cfg.RailgunDebrisCount = value
    end
})

RailgunSection:Slider({
    Title = "屏幕震动强度",
    Value = { Min = 0, Max = 10, Default = 2.2 },
    Step = 0.2,
    Callback = function(value)
        Cfg.RailgunShakeIntensity = value
    end
})

RailgunSection:Toggle({
    Title = "启用屏幕震动",
    Value = true,
    Callback = function(state)
        Cfg.RailgunShake = state
    end
})

RailgunSection:Toggle({
    Title = "启用挖坑",
    Value = true,
    Callback = function(state)
        Cfg.RailgunCraterEnabled = state
    end
})

RailgunSection:Toggle({
    Title = "启用碎石飞溅",
    Value = true,
    Callback = function(state)
        Cfg.RailgunDebrisEnabled = state
    end
})

local FunStatus = FunTab:Section({ Title = "说明", Icon = "info" })
FunStatus:Paragraph({ Title = "使用提示", Desc = "轨道炮特效仅本机可见。按 F 键或点击「立即发射」即可引爆。所有效果（坑洞、碎石、激光）不会影响其他玩家。" })

local TeleportTab = Window:Tab({ Title = "传送", Icon = "send" })

local TPSection = TeleportTab:Section({ Title = "传送玩家", Icon = "user" })

local function GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            table.insert(list, p.Name)
        end
    end
    return list
end

local TPStatus = TPSection:Paragraph({ Title = "传送状态", Desc = "待机中..." })

local TPDropdown = TPSection:Dropdown({
    Title = "选择在线玩家",
    Values = GetPlayerList(),
    Value = "",
    Multi = false,
    Callback = function(selected)
        if type(selected) == "table" then
            selected = selected[1]
        end
        TP.Target = selected or ""
        Cfg.TeleportTarget = TP.Target
    end
})

TPSection:Button({
    Title = "刷新玩家列表",
    Callback = function()
        local list = GetPlayerList()
        pcall(function() TPDropdown:Refresh(list) end)
        TPStatus:SetDesc("已刷新，共 " .. #list .. " 名玩家")
    end
})

TPSection:Slider({
    Title = "传送高度偏移 (Y)",
    Value = { Min = 0, Max = 20, Default = 3 },
    Step = 1,
    Callback = function(value)
        Cfg.TeleportOffsetY = value
        TP.OffsetY = value
    end
})

TPSection:Button({
    Title = "传送到目标玩家",
    Callback = function()
        if TP.Target == "" then
            TPStatus:SetDesc("请先选择玩家")
            return
        end
        local ok = TP:ToTarget()
        if ok then
            TPStatus:SetDesc("已传送到 " .. TP.Target)
        else
            TPStatus:SetDesc("传送失败：找不到目标或角色")
        end
    end
})

TPSection:Toggle({
    Title = "循环锁定传送",
    Value = false,
    Callback = function(state)
        if state then
            if TP.Target == "" then
                TPStatus:SetDesc("请先选择玩家")
                return
            end
            TP:StartLoop()
            TPStatus:SetDesc("循环传送中 -> " .. TP.Target)
        else
            TP:StopLoop()
            TPStatus:SetDesc("已停止循环传送")
        end
    end
})

Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    pcall(function() TPDropdown:Refresh(GetPlayerList()) end)
end)

Players.PlayerRemoving:Connect(function()
    task.wait(0.2)
    pcall(function() TPDropdown:Refresh(GetPlayerList()) end)
end)

local ProtectTab = Window:Tab({ Title = "防护", Icon = "shield" })

local AntiSection = ProtectTab:Section({ Title = "反挂机 / 防踢", Icon = "shield-check" })
AntiSection:Toggle({
    Title = "反挂机踢出 (getconnections)",
    Value = true,
    Callback = function(state)
        Cfg.AntiIdleKick = state
        if state then applyAntiIdleKick() end
    end
})
AntiSection:Toggle({
    Title = "防客户端踢出",
    Value = false,
    Callback = function(state)
        Cfg.AntiClientKick = state
        if state then applyAntiClientKick() end
    end
})

local GroupSection = ProtectTab:Section({ Title = "群组验证", Icon = "users" })
GroupSection:Toggle({
    Title = "绕过群组验证",
    Value = false,
    Callback = function(state)
        Cfg.BypassGroup = state
        if state then applyBypassGroup() end
    end
})

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
HUDTitle.Text = "📊 力量之冠封存全能版 · 累计总数据"
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
LabelReps.TextColor3 = Color3.fromRGB(230, 230, 235)
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
LabelRebirth.TextColor3 = Color3.fromRGB(230, 230, 235)
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
LabelTime.TextColor3 = Color3.fromRGB(230, 230, 235)
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F and Cfg.RailgunKeyBind then
        fireRailgun()
    end
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

print("[力量之冠封存全能版 · 娱乐区已集成]")