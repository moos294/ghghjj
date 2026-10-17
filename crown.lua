local WindUI
local success, err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"))()
end)
if not success or not WindUI then
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "UI加载失败", Text = "网络错误或代码太长被拦截: " .. tostring(err), Duration = 10})
    return
end

local Players = game:GetService("Players")
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
    AutoPetEgg = false, PetEggName = "SkyPetEgg", PetEggQty = 1,
    AutoHaloEgg = false, HaloEggName = "SkyHaloEgg", HaloEggQty = 1,
    EggCurrency = "Gem", EggInterval = 0.1, AutoTrain = false, TrainAction = "Dumbbell",
    TrainActionCN = "哑铃", TrainInterval = 0.2, FastTrain = false, FastTrainAction = "Dumbbell",
    FastTrainActionCN = "哑铃", FastPerBeat = 1, FastMaxPerSecond = 0, FastTotalReps = 0,
    AutoRebirth = false, TargetStrength = 10000, RebirthInc = 10000, TargetRebirthCount = 5,
    InfiniteRebirth = false, BaseStrength = 10000,
    Fly = false, FlySpeed = 50, WalkSpeed = 16, AntiAfk = true, TotalReps = 0,
    ScriptStartTime = tick(), RailgunKeyBind = true, RailgunCooldown = 1.2, RailgunCraterRadius = 300,
    RailgunCraterDepth = 200, RailgunDebrisCount = 150, RailgunShakeIntensity = 20, RailgunShakeDuration = 4,
}

local C = { accent = Color3.fromRGB(60, 150, 230) }
local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = p return c end
local function stroke(p, c, t, tr) local s = Instance.new("UIStroke") s.Color = c or Color3.fromRGB(48, 48, 56) s.Thickness = t or 1 s.Transparency = tr or 0 s.Parent = p return s end
local function fmt(n) n = math.floor(tonumber(n) or 0) local s = tostring(n) local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse() if out:sub(1, 1) == "," then out = out:sub(2) end return out end

local function getCurrentStrength() local str = 0 pcall(function() local attr = player:GetAttribute("Strength") or player:GetAttribute("Power") if attr then str = attr return end if player.leaderstats then local ls = player.leaderstats if ls:FindFirstChild("Strength") then str = ls.Strength.Value return end if ls:FindFirstChild("Power") then str = ls.Power.Value return end end end) return str end
local function getCurrentRebirths() local count = 0 pcall(function() local attr = player:GetAttribute("Rebirths") or player:GetAttribute("Rebirth") if attr then count = attr return end if player.leaderstats then for _, n in ipairs({"Rebirths", "Rebirth", "RebirthCount", "Prestige"}) do if player.leaderstats:FindFirstChild(n) then count = player.leaderstats[n].Value return end end end end) return count end

local function applyAntiIdleKick() if not getconnections then return end pcall(function() for _, conn in next, getconnections(player.Idled) do pcall(function() conn:Disable() end) pcall(function() conn:Disconnect() end) end end) end
local function applyAntiClientKick() if not getgc then return end pcall(function() for _, Value in next, getgc(true) do if typeof(Value) == "table" then if rawget(Value, "indexInstance") or rawget(Value, "newindexInstance") then Value.tvk = {"kick", function() return task.wait(9e9) end} end end end end) end
local function applyBypassGroup() if not hookmetamethod then return end pcall(function() local clonerefFunc = cloneref or function(o) return o end local Speaker = clonerefFunc(Players).LocalPlayer local OldNameCall OldNameCall = hookmetamethod(game, "__namecall", function(self, ...) if self ~= Speaker or getnamecallmethod() ~= "IsInGroup" then return OldNameCall(self, ...) end return true end) hookfunction(Speaker.IsInGroup, function() return true end) end) end
local function applyGrayBuildings() for _, obj in ipairs(workspace:GetDescendants()) do if obj:IsA("BasePart") then local isChar = false for _, plr in ipairs(Players:GetPlayers()) do if plr.Character and obj:IsDescendantOf(plr.Character) then isChar = true break end end if not isChar and not obj.Parent.Name:lower():find("pet") then obj.Material = Enum.Material.SmoothPlastic obj.Color = Color3.fromRGB(128, 128, 128) obj.Reflectance = 0 for _, child in ipairs(obj:GetChildren()) do if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance") then child:Destroy() end end end end end end
local function hidePets() for _, plr in ipairs(Players:GetPlayers()) do local char = plr.Character if char then for _, obj in ipairs(char:GetChildren()) do if obj:IsA("Model") and obj.Name:lower():find("pet") then for _, part in ipairs(obj:GetDescendants()) do if part:IsA("BasePart") then part.Transparency = 1 end end end end end end end
local function boostPerformance() pcall(function() Lighting.GlobalShadows = false Lighting.FogEnd = 100000 Lighting.Brightness = 1 Lighting.EnvironmentDiffuseScale = 0 Lighting.EnvironmentSpecularScale = 0 Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0) Lighting.ClockTime = 12 end) for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("PostEffect") then v:Destroy() end end for _, v in ipairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") then v.Enabled = false end if v:IsA("Texture") or v:IsA("Decal") then v.Transparency = 1 end end pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end) end

local TP = { Target = "", Loop = false, OffsetY = 3, Thread = nil }
function TP:ToTarget() local char = player.Character if not char then return false end local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return false end local target = Players:FindFirstChild(self.Target) if not target or not target.Character then return false end local targetHrp = target.Character:FindFirstChild("HumanoidRootPart") if not targetHrp then return false end hrp.CFrame = targetHrp.CFrame + Vector3.new(0, self.OffsetY, 0) return true end
function TP:StartLoop() if self.Loop then return end self.Loop = true self.Thread = task.spawn(function() while self.Loop do self:ToTarget() task.wait() end end) end
function TP:StopLoop() self.Loop = false self.Thread = nil end

local function newEffectPart(shape, material, color, transparency) local p = Instance.new("Part") p.Shape = shape p.Material = material p.Color = color p.Transparency = transparency or 0 p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth return p end

local targetPosition, isTargeting, targetMarker = nil, false, nil
local originalLighting = { Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart }
local savedSky, spaceModeActive = nil, false

local function enterSpaceMode()
    spaceModeActive = true
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then savedSky = sky sky.Parent = nil end
    for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Atmosphere") or v:IsA("ColorCorrectionEffect") then v.Parent = nil end end
    Lighting.FogColor = Color3.new(0,0,0) Lighting.FogEnd = 200000 Lighting.FogStart = 0
    Lighting.Ambient = Color3.fromRGB(15, 15, 30) Lighting.OutdoorAmbient = Color3.fromRGB(20, 20, 40)
    Lighting.Brightness = 0 Lighting.ClockTime = 0
    Lighting.EnvironmentDiffuseScale = 0.2 Lighting.EnvironmentSpecularScale = 0.5 Lighting.GlobalShadows = true
end

local function exitSpaceMode()
    spaceModeActive = false
    if savedSky then savedSky.Parent = Lighting savedSky = nil end
    for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("Atmosphere") or v:IsA("ColorCorrectionEffect") then v:Destroy() end end
    Lighting.FogColor = originalLighting.FogColor Lighting.FogEnd = originalLighting.FogEnd Lighting.FogStart = originalLighting.FogStart
    Lighting.Ambient = originalLighting.Ambient Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    Lighting.Brightness = originalLighting.Brightness Lighting.ClockTime = originalLighting.ClockTime Lighting.GlobalShadows = true
end

local function setDoomsdaySky(active)
    pcall(function()
        if active then
            local cc = Instance.new("ColorCorrectionEffect") cc.TintColor = Color3.fromRGB(255, 50, 50) cc.Contrast = 0.4 cc.Saturation = -0.1 cc.Parent = Lighting
            local atm = Instance.new("Atmosphere") atm.Density = 0.6 atm.Color = Color3.fromRGB(200, 30, 30) atm.Decay = Color3.fromRGB(100, 0, 0) atm.Glare = 0.5 atm.Haze = 2 atm.Parent = Lighting
            TweenService:Create(Lighting, TweenInfo.new(1.5), { Ambient = Color3.fromRGB(100, 10, 10), OutdoorAmbient = Color3.fromRGB(150, 20, 20), Brightness = 0.5, ClockTime = 0, FogColor = Color3.fromRGB(150, 0, 0), FogEnd = 800 }):Play()
        else
            for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("ColorCorrectionEffect") or v:IsA("Atmosphere") then v:Destroy() end end
            TweenService:Create(Lighting, TweenInfo.new(2), { Ambient = originalLighting.Ambient, OutdoorAmbient = originalLighting.OutdoorAmbient, Brightness = originalLighting.Brightness, ClockTime = originalLighting.ClockTime, FogColor = originalLighting.FogColor, FogEnd = originalLighting.FogEnd }):Play()
        end
    end)
end

local function createBeamSegment(startPos, endPos, width, color, transparency)
    local dist = (endPos - startPos).Magnitude
    if dist < 0.1 then return nil end
    local beam = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, color, transparency)
    beam.Size = Vector3.new(dist, width, width)
    beam.CFrame = CFrame.lookAt(startPos + (endPos - startPos) * 0.5, endPos) * CFrame.Angles(0, math.rad(90), 0)
    beam.Parent = workspace
    return beam
end

local function createLaserFromSky(targetPos)
    local skyY = 1000
    local segments = {}
    local prevPos = targetPos + Vector3.new(0, skyY, 0)
    for i = 1, 60 do
        task.spawn(function()
            task.wait((i - 1) * 0.02)
            local currentY = skyY - (skyY / 60) * i
            local curPos = targetPos + Vector3.new(0, currentY, 0)
            local segOuter = createBeamSegment(curPos, prevPos, 55, Color3.fromRGB(255, 10, 10), 0.2)
            local segMid = createBeamSegment(curPos, prevPos, 30, Color3.fromRGB(255, 100, 0), 0.1)
            local segInner = createBeamSegment(curPos, prevPos, 10, Color3.fromRGB(255, 255, 255), 0)
            if segOuter then table.insert(segments, segOuter) end
            if segMid then table.insert(segments, segMid) end
            if segInner then table.insert(segments, segInner) end
            prevPos = curPos
        end)
    end
    for i = 1, 300 do
        task.spawn(function()
            task.wait(math.random(0, 10) / 10)
            local angle = math.random() * math.pi * 2 local dist = math.random(0, 200)
            local drop = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 20, 20), 0)
            drop.Size = Vector3.new(math.random(4, 12), math.random(4, 12), math.random(4, 12))
            drop.Position = targetPos + Vector3.new(math.cos(angle) * dist, 800, math.sin(angle) * dist)
            drop.Parent = workspace
            TweenService:Create(drop, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = targetPos + Vector3.new(math.cos(angle) * dist * 0.2, 0, math.sin(angle) * dist * 0.2), Size = Vector3.new(1, 1, 1), Transparency = 0.5 }):Play()
            Debris:AddItem(drop, 1.5)
        end)
    end
    task.delay(3, function()
        for _, seg in ipairs(segments) do
            if seg and seg.Parent then TweenService:Create(seg, TweenInfo.new(1.5), { Transparency = 1 }):Play() Debris:AddItem(seg, 2) end
        end
    end)
end

local function spawnGiantCrater(hitPosition)
    local craterRadius = Cfg.RailgunCraterRadius
    local craterDepth = Cfg.RailgunCraterDepth
    local craterModel = Instance.new("Model") craterModel.Name = "GiantCrater" craterModel.Parent = workspace
    for ring = 1, 8 do
        local r = craterRadius * (ring / 8)
        local yOffset = -craterDepth * (ring / 8)
        local blockCount = math.floor(40 * (ring / 8)) + 10
        for i = 1, blockCount do
            local angle = (i / blockCount) * math.pi * 2
            local x = math.cos(angle) * r
            local z = math.sin(angle) * r
            local block = newEffectPart(Enum.PartType.Block, Enum.Material.Slate, Color3.fromRGB(30, 30, 30), 0)
            block.Size = Vector3.new(craterRadius * 0.4, craterDepth * 0.15, craterRadius * 0.4)
            block.Position = hitPosition + Vector3.new(x, yOffset, z)
            block.CFrame = CFrame.new(block.Position) * CFrame.Angles(0, angle, 0)
            block.Parent = craterModel
        end
    end
    local lavaCenter = hitPosition - Vector3.new(0, craterDepth * 0.85, 0)
    local lavaBase = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(255, 40, 0), 0)
    lavaBase.Size = Vector3.new(5, craterRadius * 0.8, craterRadius * 0.8)
    lavaBase.CFrame = CFrame.new(lavaCenter) * CFrame.Angles(0, 0, math.rad(90))
    lavaBase.Parent = craterModel
    for i = 1, 150 do
        local angle = math.random() * math.pi * 2
        local r = math.random() * craterRadius * 0.8
        local yOffset = -craterDepth * (r / craterRadius)
        local crack = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 20, 0), 0)
        crack.Size = Vector3.new(math.random(4, 10), 15, math.random(20, 60))
        crack.CFrame = CFrame.new(hitPosition + Vector3.new(math.cos(angle) * r, yOffset, math.sin(angle) * r)) * CFrame.Angles(0, angle + math.random(-0.9, 0.9), math.random(-0.5, 0.5))
        crack.Parent = craterModel
    end
    for i = 1, Cfg.RailgunDebrisCount do
        task.spawn(function()
            task.wait(math.random(0, 20) / 10)
            local w = math.random(20, 60) / 10
            local rock = Instance.new("Part") rock.Shape = Enum.PartType.Block rock.Material = Enum.Material.Slate
            rock.Color = Color3.fromRGB(math.random(30, 60), math.random(30, 60), math.random(30, 60))
            rock.Size = Vector3.new(w, math.random(20, 60) / 10, math.random(20, 60) / 10)
            rock.Anchored = false rock.CanCollide = true rock.CanQuery = false
            local angle = math.random() * math.pi * 2 local dist = craterRadius * (0.4 + math.random() * 0.6)
            rock.Position = hitPosition + Vector3.new(math.cos(angle) * dist, math.random(10, 40), math.sin(angle) * dist)
            rock.CFrame = CFrame.new(rock.Position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6) rock.Parent = workspace
            rock.AssemblyLinearVelocity = Vector3.new(math.random(-80, 80), math.random(10, 40), math.random(-80, 80))
            rock.AssemblyAngularVelocity = Vector3.new(math.random(-60, 60), math.random(-60, 60), math.random(-60, 60))
            Debris:AddItem(rock, 90)
        end)
    end
    Debris:AddItem(craterModel, 120)
end

local function screenShake(intensity, duration)
    local char = player.Character if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid") if not hum then return end
    task.spawn(function()
        local startTime = tick()
        while tick() - startTime < duration do
            local elapsed = tick() - startTime local fade = 1 - (elapsed / duration)
            hum.CameraOffset = Vector3.new((math.random() - 0.5) * intensity * fade, (math.random() - 0.5) * intensity * fade, 0)
            RunService.Heartbeat:Wait()
        end
        hum.CameraOffset = Vector3.zero
    end)
end

local lastRailgunFire = 0
local function executeRailgunStrike(targetPos)
    local now = tick() if now - lastRailgunFire < Cfg.RailgunCooldown then return end lastRailgunFire = now
    local chargeOrb = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(80, 0, 0), 0.1)
    chargeOrb.Size = Vector3.new(1, 1, 1) chargeOrb.Position = targetPos + Vector3.new(0, 5, 0) chargeOrb.Parent = workspace
    local light = Instance.new("PointLight") light.Color = Color3.fromRGB(255, 0, 0) light.Range = 150 light.Brightness = 10 light.Parent = chargeOrb
    TweenService:Create(chargeOrb, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(100, 100, 100), Transparency = 0.1, Color = Color3.fromRGB(255, 0, 0) }):Play()
    task.spawn(function()
        task.wait(3)
        if chargeOrb and chargeOrb.Parent then chargeOrb:Destroy() end
        setDoomsdaySky(true) createLaserFromSky(targetPos)
        screenShake(Cfg.RailgunShakeIntensity, Cfg.RailgunShakeDuration) task.wait(2)
        spawnGiantCrater(targetPos) task.wait(40) setDoomsdaySky(false)
    end)
end

local spaceAnim = {}
local spaceFolderRef = nil

local function makeDetailedPlanet(pos, size, baseColor, type)
    local model = Instance.new("Model") model.Parent = spaceFolderRef
    local core = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, baseColor, 0)
    core.Size = Vector3.new(size, size, size) core.Position = pos core.Parent = model
    if type == "Earth" then
        for i = 1, 150 do
            local land = newEffectPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, Color3.fromRGB(50, 120, 50), 0)
            local s = size * math.random(3, 8) / 100
            land.Size = Vector3.new(s, s, s)
            local a = math.random() * math.pi * 2
            local phi = math.acos(2 * math.random() - 1)
            land.CFrame = CFrame.new(pos + Vector3.new(size * 0.49 * math.sin(phi) * math.cos(a), size * 0.49 * math.cos(phi), size * 0.49 * math.sin(phi) * math.sin(a)), pos) * CFrame.Angles(0,0,math.random()*6)
            land.Parent = model
        end
    elseif type == "Jupiter" then
        for i = 1, 20 do
            local band = newEffectPart(Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Color3.fromRGB(math.random(150,200), math.random(120,160), math.random(80,120)), 0)
            band.Size = Vector3.new(size / 100, size * 0.99, size * 0.99)
            band.CFrame = CFrame.new(pos + Vector3.new(0, (i - 10) * (size / 20), 0)) * CFrame.Angles(0, 0, math.rad(90))
            band.Parent = model
        end
    elseif type == "Saturn" then
        for i = 1, 15 do
            local band = newEffectPart(Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Color3.fromRGB(math.random(200,230), math.random(180,200), math.random(120,150)), 0)
            band.Size = Vector3.new(size / 100, size * 0.99, size * 0.99)
            band.CFrame = CFrame.new(pos + Vector3.new(0, (i - 7.5) * (size / 15), 0)) * CFrame.Angles(0, 0, math.rad(90))
            band.Parent = model
        end
        for i = 1, 10 do
            local ringRadius = size * 1.3 + i * size * 0.05
            local ring = newEffectPart(Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Color3.fromRGB(200, 180, 150), 0.2)
            ring.Size = Vector3.new(size / 200, ringRadius, ringRadius)
            ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(25), 0, math.rad(10))
            ring.Parent = model
        end
    end
    return model, core
end

local function createStarfield(origin)
    for i = 1, 1000 do
        local angle = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local dist = 6000 + math.random() * 2000
        local pos = origin + Vector3.new(dist * math.sin(phi) * math.cos(angle), dist * math.cos(phi), dist * math.sin(phi) * math.sin(angle))
        local star = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.new(1,1,1), 0)
        local s = math.random(5, 15)
        star.Size = Vector3.new(s, s, s) star.Position = pos star.Parent = spaceFolderRef
    end
end

local function createSpaceEnvironment(origin)
    local folder = Instance.new("Folder") folder.Name = "CinematicSpace" folder.Parent = workspace
    spaceFolderRef = folder
    createStarfield(origin)
    local sunPos = origin
    local sun = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 100, 0), 0)
    sun.Size = Vector3.new(800, 800, 800) sun.Position = sunPos sun.Parent = folder
    for i = 1, 10 do
        local corona = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, math.max(80 - i * 10, 20), 0), 0.85)
        corona.Size = Vector3.new(820 + i * 120, 820 + i * 120, 820 + i * 120) corona.Position = sunPos corona.Parent = folder
    end
    for i = 1, 30 do
        local flare = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 50, 0), 0.3)
        flare.Size = Vector3.new(math.random(200, 500), 20, 40)
        flare.CFrame = CFrame.new(sunPos) * CFrame.Angles(math.random()*6, math.random()*6, math.random()*6)
        flare.Parent = folder
    end
    local earthPos = origin + Vector3.new(4000, 0, 2000)
    local earth, earthCore = makeDetailedPlanet(earthPos, 300, Color3.fromRGB(20, 80, 160), "Earth")
    table.insert(spaceAnim, {model = earth, basePos = earthPos, rotSpeed = Vector3.new(0, 0.1, 0), floatSpeed = 0.15, floatAmp = 20, startTime = tick(), rot = 0, isPlanet = true, core = earthCore})
    local jupiterPos = origin + Vector3.new(-6000, 1000, 5000)
    local jupiter, jupCore = makeDetailedPlanet(jupiterPos, 700, Color3.fromRGB(200, 160, 120), "Jupiter")
    table.insert(spaceAnim, {model = jupiter, basePos = jupiterPos, rotSpeed = Vector3.new(0, 0.05, 0), floatSpeed = 0.1, floatAmp = 30, startTime = tick(), rot = 0, isPlanet = true, core = jupCore})
    local saturnPos = origin + Vector3.new(-10000, -800, -8000)
    local saturn, satCore = makeDetailedPlanet(saturnPos, 600, Color3.fromRGB(220, 200, 150), "Saturn")
    table.insert(spaceAnim, {model = saturn, basePos = saturnPos, rotSpeed = Vector3.new(0, 0.05, 0), floatSpeed = 0.1, floatAmp = 30, startTime = tick(), rot = 0, isPlanet = true, core = satCore})
    return folder, earthPos, sunPos
end

local function startSpaceAnimation()
    local connection = RunService.Heartbeat:Connect(function()
        if not spaceModeActive then return end
        local now = tick()
        for _, data in ipairs(spaceAnim) do
            if data.model and data.model.Parent then
                local elapsed = now - data.startTime
                local rot = data.rot + elapsed * data.rotSpeed.Y
                local floatY = math.sin(elapsed * data.floatSpeed * math.pi * 2) * data.floatAmp
                local newPos = data.basePos + Vector3.new(0, floatY, 0)
                if data.isPlanet and data.core then data.core.CFrame = CFrame.new(newPos) * CFrame.Angles(0, rot, 0) end
            end
        end
    end)
    return connection
end

local function createSpaceStationRailgun(earthPos)
    local folder = Instance.new("Folder") folder.Name = "SpaceStationRailgun" folder.Parent = workspace
    local gunBase = earthPos + Vector3.new(0, 1600, 0)
    local core = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(80, 80, 90), 0)
    core.Size = Vector3.new(350, 50, 50) core.CFrame = CFrame.new(gunBase) * CFrame.Angles(0, 0, math.rad(90)) core.Parent = folder
    for i = 1, 20 do
        local strut = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(100, 100, 110), 0)
        strut.Size = Vector3.new(370, 5, 5) 
        strut.CFrame = CFrame.new(gunBase + Vector3.new(0, math.cos(i)*25, math.sin(i)*25)) * CFrame.Angles(0, 0, math.rad(90))
        strut.Parent = folder
    end
    for i = 1, 8 do
        local ring = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(255, 20, 20), 0)
        ring.Size = Vector3.new(8, 55, 55) ring.CFrame = CFrame.new(gunBase + Vector3.new(-120 + i * 35, 0, 0)) * CFrame.Angles(0, 0, math.rad(90)) ring.Parent = folder
    end
    local barrel = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(50, 50, 60), 0)
    barrel.Size = Vector3.new(450, 40, 40) barrel.CFrame = CFrame.new(gunBase + Vector3.new(0, -240, 0)) * CFrame.Angles(0, 0, math.rad(90)) barrel.Parent = folder
    local muzzle = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 0, 0), 0)
    muzzle.Size = Vector3.new(50, 50, 50) muzzle.Position = gunBase + Vector3.new(0, -460, 0) muzzle.Parent = folder
    local charge = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 100, 100), 0)
    charge.Size = Vector3.new(20, 20, 20) charge.Position = muzzle.Position charge.Parent = folder
    return folder, charge, muzzle.Position
end

local function createLetterbox()
    local gui = Instance.new("ScreenGui") gui.Name = "CinematicLetterbox" gui.IgnoreGuiInset = true gui.ResetOnSpawn = false gui.DisplayOrder = 998
    pcall(function() gui.Parent = game:GetService("CoreGui") end) if not gui.Parent then gui.Parent = player.PlayerGui end
    local topBar = Instance.new("Frame") topBar.AnchorPoint = Vector2.new(0, 0) topBar.Size = UDim2.new(1, 0, 0, 0) topBar.Position = UDim2.new(0, 0, 0, 0) topBar.BackgroundColor3 = Color3.new(0, 0, 0) topBar.BorderSizePixel = 0 topBar.Parent = gui
    local bottomBar = Instance.new("Frame") bottomBar.AnchorPoint = Vector2.new(0, 1) bottomBar.Size = UDim2.new(1, 0, 0, 0) bottomBar.Position = UDim2.new(0, 0, 1, 0) bottomBar.BackgroundColor3 = Color3.new(0, 0, 0) bottomBar.BorderSizePixel = 0 bottomBar.Parent = gui
    return gui, topBar, bottomBar
end

local function playCinematic(targetPos)
    local oldCameraType = camera.CameraType local oldSubject = camera.CameraSubject
    local blackoutGui = Instance.new("ScreenGui") blackoutGui.Name = "CinematicBlackout" blackoutGui.ResetOnSpawn = false blackoutGui.IgnoreGuiInset = true blackoutGui.DisplayOrder = 999
    pcall(function() blackoutGui.Parent = game:GetService("CoreGui") end) if not blackoutGui.Parent then blackoutGui.Parent = player.PlayerGui end
    local blackFrame = Instance.new("Frame") blackFrame.Size = UDim2.new(1, 0, 1, 0) blackFrame.BackgroundColor3 = Color3.new(0, 0, 0) blackFrame.BackgroundTransparency = 1 blackFrame.BorderSizePixel = 0 blackFrame.Parent = blackoutGui
    local letterboxGui, topBar, bottomBar = createLetterbox()
    TweenService:Create(topBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 60) }):Play() TweenService:Create(bottomBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 60) }):Play()
    
    local camLock = RunService.RenderStepped:Connect(function() camera.CameraType = Enum.CameraType.Scriptable end)
    local startCF = camera.CFrame
    task.spawn(function()
        local dur = 1.2 local startT = tick()
        while tick() - startT < dur do
            local a = (tick() - startT) / dur
            camera.CFrame = startCF:Lerp(CFrame.new(startCF.Position + Vector3.new(0, 300 * a, 0), startCF.Position + startCF.LookVector * 100 + Vector3.new(0, 300 * a, 0)), a)
            RunService.RenderStepped:Wait()
        end
    end)
    task.wait(1.2) TweenService:Create(blackFrame, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play() task.wait(0.5)
    
    enterSpaceMode()
    local origin = Vector3.new(0, 50000, 0)
    local spaceFolder, earthPos, sunPos = createSpaceEnvironment(origin)
    local stationFolder, chargeOrb, muzzlePos = createSpaceStationRailgun(earthPos)
    local animConn = startSpaceAnimation()
    
    camera.CFrame = CFrame.new(sunPos + Vector3.new(2000, 600, 2000), sunPos)
    task.wait(0.3) TweenService:Create(blackFrame, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
    
    local function cameraMoveTo(startCF, endCF, dur)
        local startT = tick() while tick() - startT < dur do camera.CFrame = startCF:Lerp(endCF, (tick() - startT) / dur) RunService.RenderStepped:Wait() end
    end
    
    cameraMoveTo(camera.CFrame, CFrame.new(sunPos + Vector3.new(-1200, 400, 2500), sunPos), 2) task.wait(2)
    cameraMoveTo(camera.CFrame, CFrame.new(earthPos + Vector3.new(1000, 600, 1500), earthPos), 2) task.wait(2)
    
    local closeUpCF = CFrame.new(muzzlePos + Vector3.new(0, 150, 450), muzzlePos)
    cameraMoveTo(camera.CFrame, closeUpCF, 2) task.wait(2)
    
    task.spawn(function()
        local dur = 4 local startT = tick()
        while tick() - startT < dur do
            local a = (tick() - startT) / dur local s = 20 + a * 150
            chargeOrb.Size = Vector3.new(s, s, s) chargeOrb.Color = Color3.fromRGB(255, 0, 0) RunService.RenderStepped:Wait()
        end
    end)
    task.wait(4)
    
    local flash = Instance.new("Frame") flash.Size = UDim2.new(1, 0, 1, 0) flash.BackgroundColor3 = Color3.new(1, 1, 1) flash.BackgroundTransparency = 0 flash.BorderSizePixel = 0 flash.Parent = blackoutGui
    TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play() Debris:AddItem(flash, 0.6)
    
    local beamFromGun = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(255, 40, 0), 0)
    local dir = (earthPos - muzzlePos).Unit local dist = (earthPos - muzzlePos).Magnitude
    beamFromGun.Size = Vector3.new(dist, 150, 150) beamFromGun.CFrame = CFrame.new(muzzlePos + dir * dist / 2, earthPos) * CFrame.Angles(0, math.rad(90), 0) beamFromGun.Parent = workspace
    Debris:AddItem(beamFromGun, 1.5) task.wait(0.5)
    
    TweenService:Create(blackFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play() task.wait(0.25)
    animConn:Disconnect() spaceAnim = {} stationFolder:Destroy() spaceFolder:Destroy() spaceFolderRef = nil
    camLock:Disconnect()
    exitSpaceMode() camera.CameraType = oldCameraType if oldSubject then camera.CameraSubject = oldSubject end
    
    TweenService:Create(blackFrame, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play() task.wait(0.4)
    createLaserFromSky(targetPos) setDoomsdaySky(true) screenShake(Cfg.RailgunShakeIntensity * 2, 2)
    task.wait(3) spawnGiantCrater(targetPos) task.wait(30) setDoomsdaySky(false)
    
    TweenService:Create(topBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 0) }):Play() TweenService:Create(bottomBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 0) }):Play()
    task.wait(0.6) blackFrame:Destroy() blackoutGui:Destroy() letterboxGui:Destroy()
end

local Window = WindUI:CreateWindow({ Title = "力量之冠封存全能版 9.1", Icon = "zap", Author = "力量之冠", Folder = "PowerCrownSave", Theme = "Dark", Transparent = true, Resizable = false, Size = UDim2.fromOffset(460, 780) })

local MainTab = Window:Tab({ Title = "控制面板", Icon = "settings" })
local CommonSection = MainTab:Section({ Title = "公共设置", Icon = "settings" })
CommonSection:Slider({ Title = "抽蛋间隔 (秒)", Desc = "0.1 最快", Value = { Min = 0.1, Max = 1.0, Default = 0.1 }, Step = 0.05, Callback = function(value) Cfg.EggInterval = value end })

local PetSection = MainTab:Section({ Title = "🐾 宠物区", Icon = "paw" })
PetSection:Toggle({ Title = "自动抽宠物蛋", Value = false, Callback = function(state) Cfg.AutoPetEgg = state end })
PetSection:Input({ Title = "宠物蛋名字", Placeholder = "SkyPetEgg", Value = "SkyPetEgg", Callback = function(text) Cfg.PetEggName = text end })
PetSection:Dropdown({ Title = "宠物蛋数量", Values = {"1", "3"}, Value = "1", Multi = false, Callback = function(selected) local val = tonumber(selected) if val then Cfg.PetEggQty = val end end })
local PetStatus = PetSection:Paragraph({ Title = "宠物区状态", Desc = "待机中..." })

local HaloSection = MainTab:Section({ Title = "✨ 光环区", Icon = "star" })
HaloSection:Toggle({ Title = "自动抽光环蛋", Value = false, Callback = function(state) Cfg.AutoHaloEgg = state end })
HaloSection:Input({ Title = "光环蛋名字", Placeholder = "SkyHaloEgg", Value = "SkyHaloEgg", Callback = function(text) Cfg.HaloEggName = text end })
HaloSection:Dropdown({ Title = "光环蛋数量", Values = {"1", "3"}, Value = "1", Multi = false, Callback = function(selected) local val = tonumber(selected) if val then Cfg.HaloEggQty = val end end })
local HaloStatus = HaloSection:Paragraph({ Title = "光环区状态", Desc = "待机中..." })

local TrainSection = MainTab:Section({ Title = "🏋️ 自动锻炼", Icon = "activity" })
TrainSection:Toggle({ Title = "自动锻炼", Value = false, Callback = function(state) Cfg.AutoTrain = state end })
TrainSection:Dropdown({ Title = "选择动作 (中文)", Values = ActionListCN, Value = "哑铃", Multi = false, Callback = function(selected) local cn = selected local en = ActionMap[cn] if en then Cfg.TrainAction = en Cfg.TrainActionCN = cn end end })
TrainSection:Slider({ Title = "锻炼间隔 (秒)", Value = { Min = 0.1, Max = 1.0, Default = 0.2 }, Step = 0.05, Callback = function(value) Cfg.TrainInterval = value end })
local TrainStatus = TrainSection:Paragraph({ Title = "锻炼状态", Desc = "待机中..." })

local FastTrainSection = MainTab:Section({ Title = "⚡ 无间隔锻炼 (极速)", Icon = "gauge" })
FastTrainSection:Toggle({ Title = "无间隔自动锻炼", Value = false, Callback = function(state) Cfg.FastTrain = state end })
FastTrainSection:Dropdown({ Title = "选择动作 (中文)", Values = ActionListCN, Value = "哑铃", Multi = false, Callback = function(selected) local cn = selected local en = ActionMap[cn] if en then Cfg.FastTrainAction = en Cfg.FastTrainActionCN = cn end end })
FastTrainSection:Slider({ Title = "每帧触发次数", Value = { Min = 1, Max = 10, Default = 1 }, Step = 1, Callback = function(value) Cfg.FastPerBeat = value end })
FastTrainSection:Slider({ Title = "每秒上限 (0=不限)", Value = { Min = 0, Max = 100, Default = 0 }, Step = 5, Callback = function(value) Cfg.FastMaxPerSecond = value end })
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
RailgunSection:Button({ Title = "选择发射目标", Callback = function() isTargeting = true RailgunStatus:SetDesc("请在游戏画面中点击地面选择目标...") end })
RailgunSection:Button({ Title = "立即发射", Callback = function() if not targetPosition then RailgunStatus:SetDesc("请先点击「选择发射目标」选择地点！") return end executeRailgunStrike(targetPosition) RailgunStatus:SetDesc("末日轨道炮已发射！") end })
RailgunSection:Button({ Title = "🎬 影院模式发射 9.1", Callback = function() if not targetPosition then RailgunStatus:SetDesc("请先点击「选择发射目标」选择地点！") return end RailgunStatus:SetDesc("影院模式播放中...") task.spawn(function() playCinematic(targetPosition) RailgunStatus:SetDesc("影院模式完成！") end) end })
RailgunSection:Toggle({ Title = "启用 F 键发射", Value = true, Callback = function(state) Cfg.RailgunKeyBind = state end })
RailgunSection:Slider({ Title = "坑洞半径", Value = { Min = 30, Max = 1500, Default = 300 }, Step = 10, Callback = function(value) Cfg.RailgunCraterRadius = value end })
RailgunSection:Slider({ Title = "坑洞深度", Value = { Min = 20, Max = 800, Default = 200 }, Step = 10, Callback = function(value) Cfg.RailgunCraterDepth = value end })
RailgunSection:Slider({ Title = "碎石数量", Value = { Min = 0, Max = 500, Default = 150 }, Step = 10, Callback = function(value) Cfg.RailgunDebrisCount = value end })
RailgunSection:Slider({ Title = "屏幕震动强度", Value = { Min = 0, Max = 50, Default = 20 }, Step = 1, Callback = function(value) Cfg.RailgunShakeIntensity = value end })

local TeleportTab = Window:Tab({ Title = "传送", Icon = "send" })
local TPSection = TeleportTab:Section({ Title = "传送玩家", Icon = "user" })
local function GetPlayerList() local list = {} for _, p in ipairs(Players:GetPlayers()) do if p ~= player then table.insert(list, p.Name) end end return list end
local TPStatus = TPSection:Paragraph({ Title = "传送状态", Desc = "待机中..." })
local TPDropdown = TPSection:Dropdown({ Title = "选择在线玩家", Values = GetPlayerList(), Value = "", Multi = false, Callback = function(selected) if type(selected) == "table" then selected = selected[1] end TP.Target = selected or "" end })
TPSection:Button({ Title = "刷新玩家列表", Callback = function() local list = GetPlayerList() pcall(function() TPDropdown:Refresh(list) end) TPStatus:SetDesc("已刷新，共 " .. #list .. " 名玩家") end })
TPSection:Slider({ Title = "传送高度偏移 (Y)", Value = { Min = 0, Max = 20, Default = 3 }, Step = 1, Callback = function(value) TP.OffsetY = value end })
TPSection:Button({ Title = "传送到目标玩家", Callback = function() if TP.Target == "" then TPStatus:SetDesc("请先选择玩家") return end local ok = TP:ToTarget() if ok then TPStatus:SetDesc("已传送到 " .. TP.Target) else TPStatus:SetDesc("传送失败") end end })
TPSection:Toggle({ Title = "循环锁定传送", Value = false, Callback = function(state) if state then if TP.Target == "" then TPStatus:SetDesc("请先选择玩家") return end TP:StartLoop() TPStatus:SetDesc("循环传送中 -> " .. TP.Target) else TP:StopLoop() TPStatus:SetDesc("已停止") end end })

local ProtectTab = Window:Tab({ Title = "防护", Icon = "shield" })
local AntiSection = ProtectTab:Section({ Title = "反挂机 / 防踢", Icon = "shield-check" })
AntiSection:Toggle({ Title = "反挂机踢出", Value = true, Callback = function(state) if state then applyAntiIdleKick() end end })
AntiSection:Toggle({ Title = "防客户端踢出", Value = false, Callback = function(state) if state then applyAntiClientKick() end end })
local GroupSection = ProtectTab:Section({ Title = "群组验证", Icon = "users" })
GroupSection:Toggle({ Title = "绕过群组验证", Value = false, Callback = function(state) if state then applyBypassGroup() end end })

local SG = Instance.new("ScreenGui") SG.Name = "PowerCrownUI" SG.ResetOnSpawn = false SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling SG.IgnoreGuiInset = true
pcall(function() SG.Parent = game:GetService("CoreGui") end) if not SG.Parent then SG.Parent = player.PlayerGui end
local DataHUD = Instance.new("Frame") DataHUD.Size = UDim2.new(0, 210, 0, 105) DataHUD.Position = UDim2.new(0, 20, 0.3, 0) DataHUD.BackgroundColor3 = Color3.fromRGB(20, 24, 34) DataHUD.BackgroundTransparency = 0.1 DataHUD.BorderSizePixel = 0 DataHUD.ZIndex = 500 DataHUD.Parent = SG
corner(DataHUD, 10) stroke(DataHUD, C.accent, 1.5, 0.2)
local HUDTitle = Instance.new("TextLabel") HUDTitle.Size = UDim2.new(1, 0, 0, 24) HUDTitle.BackgroundTransparency = 1 HUDTitle.Text = "📊 力量之冠封存全能版 9.1 · 累计总数据" HUDTitle.TextColor3 = C.accent HUDTitle.Font = Enum.Font.GothamBold HUDTitle.TextSize = 12 HUDTitle.ZIndex = 501 HUDTitle.Parent = DataHUD
local LabelReps = Instance.new("TextLabel") LabelReps.Size = UDim2.new(0.5, -10, 0, 18) LabelReps.Position = UDim2.new(0, 10, 0, 30) LabelReps.BackgroundTransparency = 1 LabelReps.Text = "总训练: 0" LabelReps.TextColor3 = Color3.fromRGB(230, 230, 235) LabelReps.Font = Enum.Font.Gotham LabelReps.TextSize = 11 LabelReps.TextXAlignment = Enum.TextXAlignment.Left LabelReps.ZIndex = 501 LabelReps.Parent = DataHUD
local LabelRebirth = Instance.new("TextLabel") LabelRebirth.Size = UDim2.new(0.5, -10, 0, 18) LabelRebirth.Position = UDim2.new(0, 10, 0, 50) LabelRebirth.BackgroundTransparency = 1 LabelRebirth.Text = "总转生: 0" LabelRebirth.TextColor3 = Color3.fromRGB(230, 230, 235) LabelRebirth.Font = Enum.Font.Gotham LabelRebirth.TextSize = 11 LabelRebirth.TextXAlignment = Enum.TextXAlignment.Left LabelRebirth.ZIndex = 501 LabelRebirth.Parent = DataHUD
local LabelTime = Instance.new("TextLabel") LabelTime.Size = UDim2.new(1, -20, 0, 18) LabelTime.Position = UDim2.new(0, 10, 0, 70) LabelTime.BackgroundTransparency = 1 LabelTime.Text = "总时长: 00:00:00" LabelTime.TextColor3 = Color3.fromRGB(230, 230, 235) LabelTime.Font = Enum.Font.Gotham LabelTime.TextSize = 11 LabelTime.TextXAlignment = Enum.TextXAlignment.Left LabelTime.ZIndex = 501 LabelTime.Parent = DataHUD

local HUDDrag, HUDStart, HUDOrigin = false, nil, nil
DataHUD.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then HUDDrag = true HUDStart = input.Position HUDOrigin = DataHUD.Position input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then HUDDrag = false end end) end end)
UserInputService.InputChanged:Connect(function(input) if HUDDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - HUDStart DataHUD.Position = UDim2.new(HUDOrigin.X.Scale, HUDOrigin.X.Offset + delta.X, HUDOrigin.Y.Scale, HUDOrigin.Y.Offset + delta.Y) end end)

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
    if dir.Magnitude > 0 then dir = dir.Unit * Cfg.FlySpeed end
    flyBV.Velocity = dir flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
end)

player.CharacterAdded:Connect(function(char) task.wait(0.5) local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed = Cfg.WalkSpeed end if flying then stopFly() end end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if isTargeting then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if targetMarker then targetMarker:Destroy() end
            local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
            local raycastParams = RaycastParams.new() raycastParams.FilterType = Enum.RaycastFilterType.Exclude raycastParams.FilterDescendantsInstances = {player.Character}
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if result then
                targetPosition = result.Position
                targetMarker = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 0, 0), 0.3)
                targetMarker.Size = Vector3.new(14, 14, 14) targetMarker.Position = targetPosition + Vector3.new(0, 5, 0) targetMarker.Parent = workspace
                RailgunStatus:SetDesc("目标已选定！") isTargeting = false
            end
        end
        return
    end
    if input.KeyCode == Enum.KeyCode.F and Cfg.RailgunKeyBind then if targetPosition then executeRailgunStrike(targetPosition) end end
end)

task.spawn(function()
    local storeEvent pcall(function() storeEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("StoreEvent") end)
    while true do
        task.wait(Cfg.EggInterval)
        if Cfg.AutoPetEgg and storeEvent then pcall(function() storeEvent:FireServer("Egg", Cfg.PetEggQty, Cfg.EggCurrency, Cfg.PetEggName) PetStatus:SetDesc("抽: " .. Cfg.PetEggName) end) end
        if Cfg.AutoHaloEgg and storeEvent then pcall(function() storeEvent:FireServer("Egg", Cfg.HaloEggQty, Cfg.EggCurrency, Cfg.HaloEggName) HaloStatus:SetDesc("抽: " .. Cfg.HaloEggName) end) end
    end
end)

task.spawn(function()
    local trainEvent pcall(function() trainEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TrainEvent") end)
    while true do
        task.wait(Cfg.TrainInterval)
        if Cfg.AutoTrain and trainEvent then pcall(function() trainEvent:FireServer(Cfg.TrainAction) Cfg.TotalReps = Cfg.TotalReps + 1 TrainStatus:SetDesc("锻炼: " .. Cfg.TrainActionCN) end) end
    end
end)

task.spawn(function()
    local fastTrainEvent pcall(function() fastTrainEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TrainEvent") end)
    local beatCount, windowStart = 0, tick()
    RunService.Heartbeat:Connect(function()
        if not Cfg.FastTrain or not fastTrainEvent then beatCount = 0 windowStart = tick() return end
        if tick() - windowStart >= 1 then windowStart = tick() beatCount = 0 end
        for _ = 1, Cfg.FastPerBeat do
            if Cfg.FastMaxPerSecond > 0 and beatCount >= Cfg.FastMaxPerSecond then break end
            local ok = pcall(function() fastTrainEvent:FireServer(Cfg.FastTrainAction) end)
            if ok then Cfg.FastTotalReps = Cfg.FastTotalReps + 1 Cfg.TotalReps = Cfg.TotalReps + 1 beatCount = beatCount + 1 else break end
        end
    end)
end)

task.spawn(function()
    local lastReps, lastTime = 0, tick()
    while SG.Parent do
        task.wait(0.5)
        if Cfg.FastTrain then
            local now = tick() local dt = now - lastTime local rate = 0
            if dt >= 0.5 then rate = math.floor((Cfg.FastTotalReps - lastReps) / dt) lastReps = Cfg.FastTotalReps lastTime = now end
            FastTrainStatus:SetDesc(string.format("极速: %s | 速率 %d/s | 累计 %d", Cfg.FastTrainActionCN, rate, Cfg.FastTotalReps))
        else FastTrainStatus:SetDesc("待机中...") end
    end
end)

task.spawn(function()
    local rebirthEvent pcall(function() rebirthEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RebirthEvent") end)
    while true do
        task.wait(0.1)
        if Cfg.AutoRebirth and rebirthEvent and not Cfg.InfiniteRebirth then
            pcall(function()
                local gameRebirths = getCurrentRebirths()
                if gameRebirths >= Cfg.TargetRebirthCount then Cfg.AutoRebirth = false RebirthStatus:SetDesc("已完成") return end
                local currentStr = getCurrentStrength()
                if currentStr >= Cfg.TargetStrength then
                    rebirthEvent:FireServer("Update") Cfg.TargetStrength = Cfg.TargetStrength + Cfg.RebirthInc
                    RebirthStatus:SetDesc("进度: " .. gameRebirths .. "/" .. Cfg.TargetRebirthCount) task.wait(0.1)
                else RebirthStatus:SetDesc("力量: " .. math.floor(currentStr) .. "/" .. Cfg.TargetStrength) end
            end)
        end
        if Cfg.InfiniteRebirth and rebirthEvent then
            pcall(function()
                local currentStr = getCurrentStrength() local gameRebirths = getCurrentRebirths()
                if currentStr >= Cfg.BaseStrength then
                    rebirthEvent:FireServer("Update") InfiniteStatus:SetDesc("已重生 " .. gameRebirths .. " 次") task.wait(0.1)
                else InfiniteStatus:SetDesc("力量: " .. math.floor(currentStr) .. "/" .. Cfg.BaseStrength) end
            end)
        end
    end
end)

task.spawn(function()
    while SG.Parent do
        task.wait(60)
        if Cfg.AntiAfk then
            pcall(function()
                local VIM = game:GetService("VirtualInputManager")
                VIM:SendKeyEvent(Enum.KeyCode.Space, true, false, game) task.wait(0.05)
                VIM:SendKeyEvent(Enum.KeyCode.Space, false, false, game)
            end)
        end
    end
end)

task.spawn(function()
    while SG.Parent do
        local et = tick() - Cfg.ScriptStartTime
        LabelReps.Text = "总训练: " .. fmt(Cfg.TotalReps)
        LabelRebirth.Text = "总转生: " .. fmt(getCurrentRebirths())
        LabelTime.Text = "总时长: " .. string.format("%02d:%02d:%02d", math.floor(et / 3600), math.floor((et % 3600) / 60), math.floor(et % 60))
        task.wait(0.5)
    end
end)

player.Idled:Connect(function()
    if Cfg.AntiAfk then
        pcall(function()
            local VIM = game:GetService("VirtualInputManager")
            VIM:SendKeyEvent(Enum.KeyCode.Space, true, false, game) task.wait(0.05)
            VIM:SendKeyEvent(Enum.KeyCode.Space, false, false, game)
        end)
    end
end)

local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
if hum then hum.WalkSpeed = Cfg.WalkSpeed end
if Cfg.AntiIdleKick then applyAntiIdleKick() end

print("[力量之冠封存全能版 9.1 · 影院模式已就绪]")