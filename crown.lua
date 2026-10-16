local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
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
    RailgunKeyBind = true, RailgunCooldown = 1.2, RailgunCraterRadius = 35,
    RailgunCraterDepth = 25, RailgunDebrisCount = 25, RailgunShakeIntensity = 8, RailgunShakeDuration = 2,
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
            local isPet = false
            local parent = obj.Parent
            while parent and parent ~= workspace do
                if parent.Name:lower():find("pet") or parent.Name:lower():find("宠物") then isPet = true break end
                parent = parent.Parent
            end
            if not isCharacter and not isPet then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Color = Color3.fromRGB(128, 128, 128)
                obj.Reflectance = 0
                for _, child in ipairs(obj:GetChildren()) do
                    if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance") then child:Destroy() end
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
                        if part:IsA("BasePart") then part.Transparency = 1 end
                    end
                end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("pet") or obj.Name:lower():find("宠物")) then
            for _, part in ipairs(obj:GetDescendants()) do
                if part:IsA("BasePart") then part.Transparency = 1 end
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
        if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled = false end
        if v:IsA("Beam") then v.Enabled = false end
        if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end
        if v:IsA("SurfaceAppearance") then v:Destroy() end
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
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    return p
end

local targetPosition = nil
local isTargeting = false
local targetMarker = nil

local originalLighting = {
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd
}

local function setDoomsdaySky(active)
    pcall(function()
        if active then
            local cc = Lighting:FindFirstChild("DoomsdayCC") or Instance.new("ColorCorrectionEffect")
            cc.Name = "DoomsdayCC"
            cc.TintColor = Color3.fromRGB(255, 60, 60)
            cc.Contrast = 0.4
            cc.Saturation = -0.1
            cc.Parent = Lighting
            
            local atm = Lighting:FindFirstChild("DoomsdayAtm") or Instance.new("Atmosphere")
            atm.Name = "DoomsdayAtm"
            atm.Density = 0.5
            atm.Color = Color3.fromRGB(180, 20, 20)
            atm.Decay = Color3.fromRGB(120, 0, 0)
            atm.Glare = 0.2
            atm.Haze = 1.5
            atm.Parent = Lighting
            
            TweenService:Create(Lighting, TweenInfo.new(1.5), {
                Ambient = Color3.fromRGB(100, 10, 10),
                OutdoorAmbient = Color3.fromRGB(120, 20, 20),
                Brightness = 0.8,
                ClockTime = 0,
                FogColor = Color3.fromRGB(150, 0, 0),
                FogEnd = 600
            }):Play()
        else
            local cc = Lighting:FindFirstChild("DoomsdayCC")
            if cc then cc:Destroy() end
            local atm = Lighting:FindFirstChild("DoomsdayAtm")
            if atm then atm:Destroy() end
            TweenService:Create(Lighting, TweenInfo.new(2), {
                Ambient = originalLighting.Ambient,
                OutdoorAmbient = originalLighting.OutdoorAmbient,
                Brightness = originalLighting.Brightness,
                ClockTime = originalLighting.ClockTime,
                FogColor = originalLighting.FogColor,
                FogEnd = originalLighting.FogEnd
            }):Play()
        end
    end)
end

local function createChargingOrb(position)
    local orb = newEffectPart(Enum.PartType.Ball, Enum.Material.Glass, Color3.fromRGB(0, 0, 0), 0.1)
    orb.Size = Vector3.new(1, 1, 1)
    orb.Position = position + Vector3.new(0, 2, 0)
    orb.Reflectance = 0.9
    orb.Parent = workspace
    
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 0, 0)
    light.Range = 30
    light.Brightness = 10
    light.Parent = orb
    
    TweenService:Create(orb, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(45, 45, 45),
        Transparency = 0.3,
        Color = Color3.fromRGB(20, 0, 0)
    }):Play()
    
    return orb
end

local function createLaserFromSky(targetPos)
    local beamHeight = 220
    local beamWidth = 35
    
    local beam = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(255, 240, 200), 0.05)
    beam.Size = Vector3.new(beamHeight, beamWidth, beamWidth)
    beam.CFrame = CFrame.new(targetPos + Vector3.new(0, beamHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
    beam.Parent = workspace
    
    local beamLight = Instance.new("PointLight")
    beamLight.Color = Color3.fromRGB(255, 150, 80)
    beamLight.Range = 120
    beamLight.Brightness = 25
    beamLight.Parent = beam
    
    for i = 0, 35 do
        local orb = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 210, 130), 0.1)
        orb.Size = Vector3.new(55, 55, 55)
        orb.Position = targetPos + Vector3.new(math.random(-3, 3), i * 6, math.random(-3, 3))
        orb.Parent = workspace
        Debris:AddItem(orb, 3)
    end
    
    task.delay(1.5, function()
        if beam and beam.Parent then
            TweenService:Create(beam, TweenInfo.new(0.6), {Transparency = 1, Size = Vector3.new(beamHeight, beamWidth * 2, beamWidth * 2)}):Play()
            Debris:AddItem(beam, 0.7)
        end
    end)
end

local function createRockSpike(basePos, upVector, height, baseWidth, outwardDir)
    local model = Instance.new("Model")
    model.Name = "RockSpike"
    local mat = Enum.Material.Slate
    local col = Color3.fromRGB(40, 40, 40)
    local parts = {}
    
    local bottom = newEffectPart(Enum.PartType.Block, mat, col, 0)
    bottom.Size = Vector3.new(baseWidth, height * 0.55, baseWidth)
    bottom.CFrame = CFrame.lookAt(basePos + upVector * (height * 0.275), basePos + upVector * (height * 0.275) + upVector)
    bottom.Parent = model
    table.insert(parts, bottom)
    
    local mid = newEffectPart(Enum.PartType.Block, mat, col, 0)
    mid.Size = Vector3.new(baseWidth * 0.75, height * 0.4, baseWidth * 0.75)
    mid.CFrame = CFrame.lookAt(basePos + upVector * (height * 0.75), basePos + upVector * (height * 0.75) + upVector)
    mid.Parent = model
    table.insert(parts, mid)
    
    local tip = newEffectPart(Enum.PartType.Block, mat, col, 0)
    tip.Size = Vector3.new(baseWidth * 0.35, height * 0.3, baseWidth * 0.35)
    tip.CFrame = CFrame.lookAt(basePos + upVector * (height * 1.05), basePos + upVector * (height * 1.05) + upVector)
    tip.Parent = model
    table.insert(parts, tip)
    
    local sideDir1 = Vector3.new(outwardDir.Z, 0, -outwardDir.X).Unit
    local bump1 = newEffectPart(Enum.PartType.Block, mat, col, 0)
    bump1.Size = Vector3.new(baseWidth * 0.5, height * 0.35, baseWidth * 0.5)
    local bump1Center = basePos + upVector * (height * 0.4) + sideDir1 * (baseWidth * 0.6)
    bump1.CFrame = CFrame.lookAt(bump1Center, bump1Center + upVector)
    bump1.Parent = model
    table.insert(parts, bump1)
    
    local sideDir2 = -sideDir1
    local bump2 = newEffectPart(Enum.PartType.Block, mat, col, 0)
    bump2.Size = Vector3.new(baseWidth * 0.45, height * 0.3, baseWidth * 0.45)
    local bump2Center = basePos + upVector * (height * 0.55) + sideDir2 * (baseWidth * 0.55)
    bump2.CFrame = CFrame.lookAt(bump2Center, bump2Center + upVector)
    bump2.Parent = model
    table.insert(parts, bump2)
    
    model.PrimaryPart = bottom
    model.Parent = workspace
    return model, parts
end

local function spawnNuclearCrater(hitPosition)
    local craterRadius = Cfg.RailgunCraterRadius
    local craterDepth = Cfg.RailgunCraterDepth
    
    pcall(function()
        local terrain = workspace.Terrain
        terrain:FillBall(hitPosition, craterRadius, Enum.Material.Air)
        terrain:FillBall(hitPosition - Vector3.new(0, craterDepth * 0.45, 0), craterRadius * 0.85, Enum.Material.Air)
        terrain:FillBall(hitPosition - Vector3.new(0, craterDepth * 0.85, 0), craterRadius * 0.6, Enum.Material.Air)
        for i = 1, 12 do
            local a = (i / 12) * math.pi * 2
            local dist = craterRadius * (0.9 + math.random() * 0.3)
            terrain:FillBall(hitPosition + Vector3.new(math.cos(a) * dist, math.random(-2, 0), math.sin(a) * dist), math.random(3, 6), Enum.Material.Slate)
        end
    end)
    
    local lavaCenter = hitPosition - Vector3.new(0, craterDepth * 0.75, 0)
    local lavaBase = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 60, 0), 0)
    lavaBase.Size = Vector3.new(craterRadius * 1.6, 4, craterRadius * 1.6)
    lavaBase.Position = lavaCenter
    lavaBase.Parent = workspace
    
    local lavaLight = Instance.new("PointLight")
    lavaLight.Color = Color3.fromRGB(255, 90, 20)
    lavaLight.Range = craterRadius * 3
    lavaLight.Brightness = 6
    lavaLight.Parent = lavaBase
    Debris:AddItem(lavaBase, 120)
    
    for i = 1, 25 do
        local angle = math.random() * math.pi * 2
        local r = math.random() * craterRadius * 0.8
        local glow = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 150, 40), 0)
        glow.Size = Vector3.new(math.random(4, 8), math.random(3, 6), math.random(4, 8))
        glow.Position = lavaCenter + Vector3.new(math.cos(angle) * r, math.random(0, 2), math.sin(angle) * r)
        glow.CFrame = CFrame.new(glow.Position) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
        glow.Parent = workspace
        Debris:AddItem(glow, 120)
    end
    
    for i = 1, 20 do
        local angle = math.random() * math.pi * 2
        local len = math.random(10, 22)
        local crack = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 0, 0), 0)
        crack.Size = Vector3.new(3, 5, len)
        local cx = math.cos(angle) * math.random(0, craterRadius * 0.7)
        local cz = math.sin(angle) * math.random(0, craterRadius * 0.7)
        crack.CFrame = CFrame.new(lavaCenter + Vector3.new(cx, 3, cz)) * CFrame.Angles(0, angle + math.random(-0.5, 0.5), 0)
        crack.Parent = workspace
        Debris:AddItem(crack, 120)
    end
    
    local pillarCount = 18
    for i = 1, pillarCount do
        task.spawn(function()
            task.wait(math.random(0, 4) / 10)
            local angle = (i / pillarCount) * math.pi * 2 + math.random(-0.1, 0.1)
            local dist = craterRadius * (0.95 + math.random(-0.05, 0.08))
            local x = math.cos(angle) * dist
            local z = math.sin(angle) * dist
            local height = math.random(40, 90)
            local width = math.random(10, 18)
            local outwardDir = Vector3.new(x, 0, z).Unit
            local tiltRad = math.rad(10 + math.random() * 15)
            local upVector = (Vector3.new(0, 1, 0) + outwardDir * math.tan(tiltRad)).Unit
            local basePos = hitPosition + Vector3.new(x, -height * 1.5, z)
            local model, parts = createRockSpike(basePos, upVector, height, width, outwardDir)
            local targetPos = hitPosition + Vector3.new(x, height * 0.15, z)
            local offset = targetPos - basePos
            for _, part in ipairs(parts) do
                TweenService:Create(part, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {CFrame = part.CFrame + offset}):Play()
            end
            Debris:AddItem(model, 90)
        end)
    end
    
    local smokeHolder = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.new(1,1,1), 1)
    smokeHolder.Size = Vector3.new(2, 2, 2)
    smokeHolder.Position = hitPosition + Vector3.new(0, 20, 0)
    smokeHolder.Parent = workspace
    
    local smoke = Instance.new("Smoke")
    smoke.Color = Color3.fromRGB(40, 40, 40)
    smoke.Opacity = 0.7
    smoke.RiseVelocity = 25
    smoke.Size = 25
    smoke.Parent = smokeHolder
    
    local smokeCap = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.new(1,1,1), 1)
    smokeCap.Size = Vector3.new(2, 2, 2)
    smokeCap.Position = hitPosition + Vector3.new(0, 110, 0)
    smokeCap.Parent = workspace
    
    local smoke2 = Instance.new("Smoke")
    smoke2.Color = Color3.fromRGB(30, 30, 30)
    smoke2.Opacity = 0.8
    smoke2.RiseVelocity = 15
    smoke2.Size = 60
    smoke2.Parent = smokeCap
    
    task.delay(25, function()
        if smoke then smoke.Enabled = false end
        if smoke2 then smoke2.Enabled = false end
    end)
    Debris:AddItem(smokeHolder, 30)
    Debris:AddItem(smokeCap, 30)
end

local function spawnRailgunDebris(hitPosition)
    for i = 1, Cfg.RailgunDebrisCount do
        local size = math.random(15, 40) / 10
        local rock = Instance.new("Part")
        rock.Shape = Enum.PartType.Block
        rock.Material = Enum.Material.Slate
        rock.Color = Color3.fromRGB(55, 55, 55)
        rock.Size = Vector3.new(size, size, size)
        rock.Anchored = false
        rock.CanCollide = true
        rock.CanQuery = false
        rock.Position = hitPosition + Vector3.new(math.random(-8, 8), math.random(8, 15), math.random(-8, 8))
        rock.CFrame = CFrame.new(rock.Position) * CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2)
        rock.Parent = workspace
        rock.AssemblyLinearVelocity = Vector3.new(math.random(-80, 80), math.random(60, 120), math.random(-80, 80))
        rock.AssemblyAngularVelocity = Vector3.new(math.random(-40, 40), math.random(-40, 40), math.random(-40, 40))
        Debris:AddItem(rock, 15)
    end
end

local function screenShake(intensity, duration)
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            local elapsed = tick() - startTime
            local fade = 1 - (elapsed / duration)
            hum.CameraOffset = Vector3.new((math.random() - 0.5) * intensity * fade, (math.random() - 0.5) * intensity * fade, 0)
            RunService.Heartbeat:Wait()
        end
        hum.CameraOffset = Vector3.zero
    end)
end

local lastRailgunFire = 0

local function executeRailgunStrike(targetPos)
    local now = tick()
    if now - lastRailgunFire < Cfg.RailgunCooldown then return end
    lastRailgunFire = now
    
    local chargeOrb = createChargingOrb(targetPos)
    task.spawn(function()
        task.wait(3)
        if chargeOrb and chargeOrb.Parent then chargeOrb:Destroy() end
        setDoomsdaySky(true)
        createLaserFromSky(targetPos)
        screenShake(Cfg.RailgunShakeIntensity, Cfg.RailgunShakeDuration)
        task.wait(1.2)
        spawnNuclearCrater(targetPos)
        spawnRailgunDebris(targetPos)
        task.wait(20)
        setDoomsdaySky(false)
    end)
end

-- 电影黑边 UI
local function createLetterbox()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CinematicLetterbox"
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 998
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = player.PlayerGui end

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.new(0, 0, 0)
    topBar.BorderSizePixel = 0
    topBar.Parent = gui

    local bottomBar = Instance.new("Frame")
    bottomBar.Size = UDim2.new(1, 0, 0, 0)
    bottomBar.Position = UDim2.new(0, 0, 1, 0)
    bottomBar.BackgroundColor3 = Color3.new(0, 0, 0)
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = gui

    return gui, topBar, bottomBar
end

-- 精致地球（带有大陆和大气层）
local function createDetailedEarth(origin)
    local earthFolder = Instance.new("Folder")
    earthFolder.Name = "DetailedEarth"
    earthFolder.Parent = workspace

    local earthPos = origin + Vector3.new(550, 0, 0)

    -- 海洋球体
    local ocean = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(30, 90, 160), 0)
    ocean.Size = Vector3.new(100, 100, 100)
    ocean.Position = earthPos
    ocean.Parent = earthFolder

    -- 大气层（外部半透明发光层）
    local atmosphere = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(100, 180, 255), 0.85)
    atmosphere.Size = Vector3.new(106, 106, 106)
    atmosphere.Position = earthPos
    atmosphere.Parent = earthFolder

    -- 大陆（用不规则的薄片拼凑，看起来更真实）
    local landColor = Color3.fromRGB(60, 140, 60)
    local landParts = {
        {pos = Vector3.new(0, 40, 30), size = Vector3.new(50, 20, 40)},
        {pos = Vector3.new(30, 20, -20), size = Vector3.new(40, 25, 35)},
        {pos = Vector3.new(-35, 25, 10), size = Vector3.new(35, 20, 45)},
        {pos = Vector3.new(10, -30, 40), size = Vector3.new(45, 20, 30)},
        {pos = Vector3.new(-15, -20, -40), size = Vector3.new(30, 25, 40)},
    }

    for _, data in ipairs(landParts) do
        local land = newEffectPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, landColor, 0)
        land.Size = data.size
        land.Position = earthPos + data.pos
        land.CFrame = CFrame.new(land.Position) * CFrame.Angles(math.random() * 0.5, math.random() * math.pi * 2, math.random() * 0.5)
        land.Parent = earthFolder
    end

    -- 云层
    for i = 1, 8 do
        local cloud = newEffectPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, Color3.new(1, 1, 1), 0.5)
        cloud.Size = Vector3.new(math.random(15, 30), math.random(10, 20), math.random(15, 30))
        local angle = math.random() * math.pi * 2
        local dist = 45
        cloud.Position = earthPos + Vector3.new(math.cos(angle) * dist, math.random(-40, 40), math.sin(angle) * dist)
        cloud.CFrame = CFrame.new(cloud.Position) * CFrame.Angles(math.random() * math.pi, math.random() * math.pi, math.random() * math.pi)
        cloud.Parent = earthFolder
    end

    return earthFolder, earthPos
end

-- 空间站轨道炮（精致建模）
local function createSpaceStationRailgun(earthPos)
    local folder = Instance.new("Folder")
    folder.Name = "SpaceStationRailgun"
    folder.Parent = workspace

    local gunBase = earthPos + Vector3.new(0, 600, 0)

    -- 中央核心舱（横向圆柱体）
    local core = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(80, 85, 95), 0)
    core.Size = Vector3.new(300, 60, 60)
    core.CFrame = CFrame.new(gunBase) * CFrame.Angles(0, 0, math.rad(90))
    core.Parent = folder

    -- 核心舱前端（对接环）
    local ring1 = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(60, 65, 75), 0)
    ring1.Size = Vector3.new(20, 90, 90)
    ring1.CFrame = CFrame.new(gunBase + Vector3.new(150, 0, 0)) * CFrame.Angles(0, 0, math.rad(90))
    ring1.Parent = folder

    -- 炮管支架
    local mount = newEffectPart(Enum.PartType.Block, Enum.Material.Metal, Color3.fromRGB(50, 55, 65), 0)
    mount.Size = Vector3.new(60, 150, 60)
    mount.Position = gunBase + Vector3.new(0, -100, 0)
    mount.Parent = folder

    -- 炮管（向下延伸）
    local barrel = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(40, 45, 55), 0)
    barrel.Size = Vector3.new(500, 50, 50)
    barrel.CFrame = CFrame.new(gunBase + Vector3.new(0, -250, 0)) * CFrame.Angles(0, 0, math.rad(90))
    barrel.Parent = folder

    -- 炮口
    local muzzle = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(80, 160, 255), 0.3)
    muzzle.Size = Vector3.new(80, 80, 80)
    muzzle.Position = gunBase + Vector3.new(0, -480, 0)
    muzzle.Parent = folder

    -- 侧翼太阳能板
    for _, side in ipairs({-1, 1}) do
        local panelHolder = newEffectPart(Enum.PartType.Block, Enum.Material.Metal, Color3.fromRGB(60, 60, 60), 0)
        panelHolder.Size = Vector3.new(10, 40, 200)
        panelHolder.Position = gunBase + Vector3.new(0, 0, side * 200)
        panelHolder.Parent = folder

        for i = 1, 3 do
            local panel = newEffectPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, Color3.fromRGB(20, 80, 160), 0.1)
            panel.Size = Vector3.new(8, 80, 60)
            panel.Position = gunBase + Vector3.new(0, 0, side * (170 + i * 70))
            panel.Parent = folder

            local panelLine = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(100, 200, 255), 0.2)
            panelLine.Size = Vector3.new(10, 80, 2)
            panelLine.Position = panel.Position + Vector3.new(0, 0, -side * 30)
            panelLine.Parent = folder
        end
    end

    -- 蓄力光球
    local charge = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(150, 220, 255), 0)
    charge.Size = Vector3.new(15, 15, 15)
    charge.Position = muzzle.Position
    charge.Parent = folder

    local chargeLight = Instance.new("PointLight")
    chargeLight.Color = Color3.fromRGB(150, 220, 255)
    chargeLight.Range = 800
    chargeLight.Brightness = 6
    chargeLight.Parent = charge

    -- 太空背景（黑色盒子）
    local boxSize = 8000
    local t = 20
    local function blackPart(size, pos)
        local p = newEffectPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, Color3.new(0,0,0), 0)
        p.Size = size
        p.Position = pos
        p.Parent = folder
        return p
    end
    blackPart(Vector3.new(boxSize, t, boxSize), earthPos + Vector3.new(0, boxSize/2, 0))
    blackPart(Vector3.new(boxSize, t, boxSize), earthPos + Vector3.new(0, -boxSize/2, 0))

    return folder, charge, muzzle.Position
end

local function playCinematic(targetPos)
    local oldCameraType = camera.CameraType
    local oldSubject = camera.CameraSubject

    local blackoutGui = Instance.new("ScreenGui")
    blackoutGui.Name = "CinematicBlackout"
    blackoutGui.ResetOnSpawn = false
    blackoutGui.IgnoreGuiInset = true
    blackoutGui.DisplayOrder = 999
    pcall(function() blackoutGui.Parent = game:GetService("CoreGui") end)
    if not blackoutGui.Parent then blackoutGui.Parent = player.PlayerGui end

    local blackFrame = Instance.new("Frame")
    blackFrame.Size = UDim2.new(1, 0, 1, 0)
    blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    blackFrame.BackgroundTransparency = 1
    blackFrame.BorderSizePixel = 0
    blackFrame.Parent = blackoutGui

    -- 电影黑边
    local letterboxGui, topBar, bottomBar = createLetterbox()
    TweenService:Create(topBar, TweenInfo.new(0.6), {Size = UDim2.new(1, 0, 0, 60)}):Play()
    TweenService:Create(bottomBar, TweenInfo.new(0.6), {Size = UDim2.new(1, 0, 0, 60)}):Play()

    camera.CameraType = Enum.CameraType.Scriptable
    local startCF = camera.CFrame

    -- 阶段1：镜头升空
    task.spawn(function()
        local dur = 1.2
        local startT = tick()
        while tick() - startT < dur do
            local a = (tick() - startT) / dur
            camera.CFrame = startCF:Lerp(CFrame.new(startCF.Position + Vector3.new(0, 200 * a, 0), startCF.Position + startCF.LookVector * 100 + Vector3.new(0, 200 * a, 0)), a)
            RunService.RenderStepped:Wait()
        end
    end)
    task.wait(1.2)

    -- 阶段2：黑屏
    TweenService:Create(blackFrame, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
    task.wait(0.5)

    -- 创建太空场景
    local origin = Vector3.new(0, 200000, 0)
    local spaceFolder = Instance.new("Folder")
    spaceFolder.Name = "CinematicSpace"
    spaceFolder.Parent = workspace

    -- 太阳
    local sun = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 220, 80), 0)
    sun.Size = Vector3.new(250, 250, 250)
    sun.Position = origin
    sun.Parent = spaceFolder
    local sunLight = Instance.new("PointLight")
    sunLight.Color = Color3.fromRGB(255, 220, 100)
    sunLight.Range = 4000
    sunLight.Brightness = 10
    sunLight.Parent = sun

    -- 地球（精细建模）
    local earthFolder, earthPos = createDetailedEarth(origin)
    spaceFolder = earthFolder

    -- 空间站轨道炮
    local stationFolder, chargeOrb, muzzlePos = createSpaceStationRailgun(earthPos)

    -- 阶段3：黑屏中摆好镜头
    camera.CFrame = CFrame.new(origin + Vector3.new(0, 400, 3000), origin)
    task.wait(0.3)

    -- 阶段4：太阳系全景
    TweenService:Create(blackFrame, TweenInfo.new(0.6), {BackgroundTransparency = 1}):Play()
    local c1Start = camera.CFrame
    local c1End = CFrame.new(origin + Vector3.new(-800, 300, 1800), origin + Vector3.new(300, 0, 0))
    task.spawn(function()
        local dur = 2
        local startT = tick()
        while tick() - startT < dur do
            camera.CFrame = c1Start:Lerp(c1End, (tick() - startT) / dur)
            RunService.RenderStepped:Wait()
        end
    end)
    task.wait(2)

    -- 阶段5：推向空间站
    local c2Start = camera.CFrame
    local c2End = CFrame.new(earthPos + Vector3.new(400, 500, 800), earthPos + Vector3.new(0, 600, 0))
    task.spawn(function()
        local dur = 1.8
        local startT = tick()
        while tick() - startT < dur do
            camera.CFrame = c2Start:Lerp(c2End, (tick() - startT) / dur)
            RunService.RenderStepped:Wait()
        end
    end)
    task.wait(1.8)

    -- 阶段6：蓄力（镜头环绕空间站）
    task.spawn(function()
        local dur = 3
        local startT = tick()
        while tick() - startT < dur do
            local a = (tick() - startT) / dur
            local angle = a * math.pi * 0.5
            local radius = 600
            local camPos = earthPos + Vector3.new(math.cos(angle) * radius, 300, math.sin(angle) * radius)
            camera.CFrame = CFrame.new(camPos, muzzlePos)
            RunService.RenderStepped:Wait()
        end
    end)

    -- 充能动画
    task.spawn(function()
        local dur = 3
        local startT = tick()
        while tick() - startT < dur do
            local a = (tick() - startT) / dur
            local s = 15 + a * 180
            chargeOrb.Size = Vector3.new(s, s, s)
            chargeOrb.Color = Color3.fromRGB(150 + 100 * a, 220 + 30 * a, 255)
            RunService.RenderStepped:Wait()
        end
    end)

    -- 能量球汇聚
    for i = 1, 30 do
        task.spawn(function()
            task.wait(math.random(0, 25) / 10)
            local angle = math.random() * math.pi * 2
            local dist = 250 + math.random() * 300
            local energy = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(150, 220, 255), 0.1)
            energy.Size = Vector3.new(25, 25, 25)
            energy.Position = muzzlePos + Vector3.new(math.cos(angle) * dist, math.random(-150, 150), math.sin(angle) * dist)
            energy.Parent = workspace
            TweenService:Create(energy, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = muzzlePos, Size = Vector3.new(5, 5, 5), Transparency = 1
            }):Play()
            Debris:AddItem(energy, 1)
        end)
    end
    task.wait(3)

    -- 阶段7：发射
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.new(1, 1, 1)
    flash.BackgroundTransparency = 0
    flash.BorderSizePixel = 0
    flash.Parent = blackoutGui
    TweenService:Create(flash, TweenInfo.new(0.4), {BackgroundTransparency = 1}):Play()
    Debris:AddItem(flash, 0.6)

    local beamFromGun = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(150, 220, 255), 0.05)
    local dir = (earthPos - muzzlePos).Unit
    local dist = (earthPos - muzzlePos).Magnitude
    beamFromGun.Size = Vector3.new(dist, 80, 80)
    beamFromGun.CFrame = CFrame.new(muzzlePos + dir * dist / 2, earthPos) * CFrame.Angles(0, math.rad(90), 0)
    beamFromGun.Parent = workspace
    Debris:AddItem(beamFromGun, 1.5)
    task.wait(0.5)

    -- 阶段8：切回地球
    TweenService:Create(blackFrame, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    task.wait(0.25)

    stationFolder:Destroy()
    spaceFolder:Destroy()

    camera.CameraType = oldCameraType
    if oldSubject then camera.CameraSubject = oldSubject end

    local skyBeamStart = targetPos + Vector3.new(2000, 1200, 2000)
    local skyBeamDir = (targetPos - skyBeamStart).Unit
    local skyBeamDist = (targetPos - skyBeamStart).Magnitude
    local skyBeam = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(200, 240, 255), 0.1)
    skyBeam.Size = Vector3.new(skyBeamDist, 100, 100)
    skyBeam.CFrame = CFrame.new(skyBeamStart + skyBeamDir * skyBeamDist / 2, targetPos) * CFrame.Angles(0, math.rad(90), 0)
    skyBeam.Parent = workspace

    TweenService:Create(blackFrame, TweenInfo.new(0.7), {BackgroundTransparency = 1}):Play()
    task.wait(0.35)

    TweenService:Create(skyBeam, TweenInfo.new(0.5), {Size = Vector3.new(skyBeamDist, 180, 180)}):Play()
    task.wait(0.5)

    setDoomsdaySky(true)
    screenShake(Cfg.RailgunShakeIntensity * 1.5, 1.5)
    spawnNuclearCrater(targetPos)
    spawnRailgunDebris(targetPos)

    TweenService:Create(skyBeam, TweenInfo.new(1.2), {Transparency = 1}):Play()
    Debris:AddItem(skyBeam, 1.5)

    task.wait(10)
    setDoomsdaySky(false)

    -- 收起黑边
    TweenService:Create(topBar, TweenInfo.new(0.6), {Size = UDim2.new(1, 0, 0, 0)}):Play()
    TweenService:Create(bottomBar, TweenInfo.new(0.6), {Size = UDim2.new(1, 0, 0, 0)}):Play()
    task.wait(0.6)

    blackFrame:Destroy()
    blackoutGui:Destroy()
    letterboxGui:Destroy()
end

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
VisualSection:Button({ Title = "灰色建筑模式", Callback = function() applyGrayBuildings() end })
VisualSection:Button({ Title = "隐藏宠物", Callback = function() hidePets() end })
VisualSection:Button({ Title = "提高帧率并降低延迟", Callback = function() boostPerformance() end })

local FunTab = Window:Tab({ Title = "娱乐区", Icon = "sparkles" })
local RailgunSection = FunTab:Section({ Title = "末日轨道炮", Icon = "zap" })
local RailgunStatus = RailgunSection:Paragraph({ Title = "轨道炮状态", Desc = "请先点击「选择发射目标」选择地点" })

RailgunSection:Button({ Title = "选择发射目标", Callback = function()
    isTargeting = true
    RailgunStatus:SetDesc("请在游戏画面中点击地面选择目标...")
end })

RailgunSection:Button({ Title = "立即发射", Callback = function()
    if not targetPosition then RailgunStatus:SetDesc("请先点击「选择发射目标」选择地点！") return end
    executeRailgunStrike(targetPosition)
    RailgunStatus:SetDesc("末日轨道炮已发射！")
end })

RailgunSection:Button({ Title = "🎬 影院模式发射", Callback = function()
    if not targetPosition then RailgunStatus:SetDesc("请先点击「选择发射目标」选择地点！") return end
    RailgunStatus:SetDesc("影院模式播放中...")
    task.spawn(function()
        playCinematic(targetPosition)
        RailgunStatus:SetDesc("影院模式完成！")
    end)
end })

RailgunSection:Toggle({ Title = "启用 F 键发射", Value = true, Callback = function(state) Cfg.RailgunKeyBind = state end })
RailgunSection:Slider({ Title = "发射冷却 (秒)", Value = { Min = 0.1, Max = 10, Default = 1.2 }, Step = 0.1, Callback = function(value) Cfg.RailgunCooldown = value end })
RailgunSection:Slider({ Title = "坑洞半径", Value = { Min = 10, Max = 80, Default = 35 }, Step = 1, Callback = function(value) Cfg.RailgunCraterRadius = value end })
RailgunSection:Slider({ Title = "坑洞深度", Value = { Min = 5, Max = 60, Default = 25 }, Step = 1, Callback = function(value) Cfg.RailgunCraterDepth = value end })
RailgunSection:Slider({ Title = "碎石数量", Value = { Min = 0, Max = 100, Default = 25 }, Step = 5, Callback = function(value) Cfg.RailgunDebrisCount = value end })
RailgunSection:Slider({ Title = "屏幕震动强度", Value = { Min = 0, Max = 30, Default = 8 }, Step = 0.5, Callback = function(value) Cfg.RailgunShakeIntensity = value end })
FunTab:Section({ Title = "说明", Icon = "info" }):Paragraph({ Title = "使用提示", Desc = "先点「选择发射目标」再点地面，然后点「立即发射」或「影院模式发射」或按 F 键。" })

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
local TPDropdown = TPSection:Dropdown({ Title = "选择在线玩家", Values = GetPlayerList(), Value = "", Multi = false, Callback = function(selected)
    if type(selected) == "table" then selected = selected[1] end
    TP.Target = selected or ""
    Cfg.TeleportTarget = TP.Target
end })
TPSection:Button({ Title = "刷新玩家列表", Callback = function() local list = GetPlayerList() pcall(function() TPDropdown:Refresh(list) end) TPStatus:SetDesc("已刷新，共 " .. #list .. " 名玩家") end })
TPSection:Slider({ Title = "传送高度偏移 (Y)", Value = { Min = 0, Max = 20, Default = 3 }, Step = 1, Callback = function(value) Cfg.TeleportOffsetY = value TP.OffsetY = value end })
TPSection:Button({ Title = "传送到目标玩家", Callback = function()
    if TP.Target == "" then TPStatus:SetDesc("请先选择玩家") return end
    local ok = TP:ToTarget()
    if ok then TPStatus:SetDesc("已传送到 " .. TP.Target) else TPStatus:SetDesc("传送失败：找不到目标或角色") end
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

local ProtectTab = Window:Tab({ Title = "防护", Icon = "shield" })
local AntiSection = ProtectTab:Section({ Title = "反挂机 / 防踢", Icon = "shield-check" })
AntiSection:Toggle({ Title = "反挂机踢出 (getconnections)", Value = true, Callback = function(state) Cfg.AntiIdleKick = state if state then applyAntiIdleKick() end end })
AntiSection:Toggle({ Title = "防客户端踢出", Value = false, Callback = function(state) Cfg.AntiClientKick = state if state then applyAntiClientKick() end end })
local GroupSection = ProtectTab:Section({ Title = "群组验证", Icon = "users" })
GroupSection:Toggle({ Title = "绕过群组验证", Value = false, Callback = function(state) Cfg.BypassGroup = state if state then applyBypassGroup() end end })

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
    if isTargeting then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if targetMarker then targetMarker:Destroy() end
            local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {player.Character}
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if result then
                targetPosition = result.Position
                targetMarker = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 0, 0), 0.3)
                targetMarker.Size = Vector3.new(14, 14, 14)
                targetMarker.Position = targetPosition + Vector3.new(0, 5, 0)
                targetMarker.Parent = workspace
                RailgunStatus:SetDesc("目标已选定！点击「立即发射」或按 F 键")
                isTargeting = false
            else
                RailgunStatus:SetDesc("未检测到地面，请重新点击「选择发射目标」")
            end
        end
        return
    end
    if input.KeyCode == Enum.KeyCode.F and Cfg.RailgunKeyBind then
        if targetPosition then executeRailgunStrike(targetPosition) end
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
        else PetStatus:SetDesc("待机中") end
        if Cfg.AutoHaloEgg and storeEvent then
            pcall(function()
                storeEvent:FireServer("Egg", Cfg.HaloEggQty, Cfg.EggCurrency, Cfg.HaloEggName)
                HaloStatus:SetDesc("正在抽: " .. Cfg.HaloEggName .. " x" .. Cfg.HaloEggQty)
            end)
        else HaloStatus:SetDesc("待机中") end
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
        else TrainStatus:SetDesc("待机中") end
    end
end)

task.spawn(function()
    local fastTrainEvent
    pcall(function() fastTrainEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TrainEvent") end)
    local beatCount, windowStart = 0, tick()
    RunService.Heartbeat:Connect(function()
        if not Cfg.FastTrain or not fastTrainEvent then beatCount = 0 windowStart = tick() return end
        if tick() - windowStart >= 1 then windowStart = tick() beatCount = 0 end
        for _ = 1, Cfg.FastPerBeat do
            if Cfg.FastMaxPerSecond > 0 and beatCount >= Cfg.FastMaxPerSecond then break end
            local ok = pcall(function() fastTrainEvent:FireServer(Cfg.FastTrainAction) end)
            if ok then
                Cfg.FastTotalReps = Cfg.FastTotalReps + 1
                Cfg.TotalReps = Cfg.TotalReps + 1
                beatCount = beatCount + 1
            else break end
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
        else FastTrainStatus:SetDesc("待机中...") end
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
        else InfiniteStatus:SetDesc("待机中...") end
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

print("[力量之冠封存全能版 · 影院模式轨道炮已就绪]")