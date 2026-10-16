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
    EggCurrency = "Gem", EggInterval = 0.1, AutoTrain = false, TrainAction = "Dumbbell",
    TrainActionCN = "哑铃", TrainInterval = 0.2, FastTrain = false, FastTrainAction = "Dumbbell",
    FastTrainActionCN = "哑铃", FastPerBeat = 1, FastMaxPerSecond = 0, FastTotalReps = 0,
    AutoRebirth = false, TargetStrength = 10000, RebirthInc = 10000, TargetRebirthCount = 5,
    RebirthCheckInterval = 0.1, RebirthCooldown = 0.1, InfiniteRebirth = false, BaseStrength = 10000,
    Fly = false, FlySpeed = 50, WalkSpeed = 16, AntiAfk = true, TotalReps = 0,
    AutoRebirthDone = 0, ScriptStartTime = tick(), TeleportTarget = "", TeleportLoop = false,
    TeleportOffsetY = 3, AntiIdleKick = true, AntiClientKick = false, BypassGroup = false,
    RailgunKeyBind = true, RailgunCooldown = 1.2, RailgunCraterRadius = 120,
    RailgunCraterDepth = 80, RailgunDebrisCount = 200, RailgunShakeIntensity = 20, RailgunShakeDuration = 4,
}

local C = { accent = Color3.fromRGB(60, 150, 230), text = Color3.fromRGB(230, 230, 235), textDim = Color3.fromRGB(150, 150, 160), green = Color3.fromRGB(0, 200, 140), red = Color3.fromRGB(220, 70, 80), stroke = Color3.fromRGB(48, 48, 56) }

local function corner(p, r) local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, r or 8) c.Parent = p return c end
local function stroke(p, c, t, tr) local s = Instance.new("UIStroke") s.Color = c or C.stroke s.Thickness = t or 1 s.Transparency = tr or 0 s.Parent = p return s end
local function fmt(n) n = math.floor(tonumber(n) or 0) local s = tostring(n) local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse() if out:sub(1, 1) == "," then out = out:sub(2) end return out end

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
                if ls:FindFirstChild(n) and (ls[n]:IsA("IntValue") or ls[n]:IsA("NumberValue")) then count = ls[n].Value return end
            end
        end
        local names = {"Rebirths", "Rebirth", "RebirthCount"}
        for _, n in ipairs(names) do
            if player:FindFirstChild(n) and (player[n]:IsA("IntValue") or player[n]:IsA("NumberValue")) then count = player[n].Value return end
        end
    end)
    return count
end

local function applyAntiIdleKick() if not getconnections then return end pcall(function() for _, conn in next, getconnections(player.Idled) do pcall(function() conn:Disable() end) pcall(function() conn:Disconnect() end) end end) end
local function applyAntiClientKick() if not getgc then return end pcall(function() for _, Value in next, getgc(true) do if typeof(Value) == "table" then if rawget(Value, "indexInstance") or rawget(Value, "newindexInstance") or rawget(Value, "newIndexInstance") then Value.tvk = {"kick", function() return task.wait(9e9) end} end end end end) end
local function applyBypassGroup()
    if not hookmetamethod or not hookfunction then return end
    pcall(function()
        local clonerefFunc = cloneref or function(o) return o end
        local getnamecallmethod = getnamecallmethod
        local Speaker = clonerefFunc(Players).LocalPlayer
        local OldNameCall
        OldNameCall = hookmetamethod(game, "__namecall", function(self, ...)
            if self ~= Speaker or getnamecallmethod() ~= "IsInGroup" then return OldNameCall(self, ...) end
            return true
        end)
        hookfunction(Speaker.IsInGroup, function(self, ...) return true end)
    end)
end

local function applyGrayBuildings()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local isCharacter = false
            for _, plr in ipairs(Players:GetPlayers()) do if plr.Character and obj:IsDescendantOf(plr.Character) then isCharacter = true break end end
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
                for _, child in ipairs(obj:GetChildren()) do if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance") then child:Destroy() end end
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
                    for _, part in ipairs(obj:GetDescendants()) do if part:IsA("BasePart") then part.Transparency = 1 end end
                end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("pet") or obj.Name:lower():find("宠物")) then
            for _, part in ipairs(obj:GetDescendants()) do if part:IsA("BasePart") then part.Transparency = 1 end end
        end
    end
end

local function boostPerformance()
    pcall(function()
        Lighting.GlobalShadows = false Lighting.FogEnd = 100000 Lighting.Brightness = 1
        Lighting.EnvironmentDiffuseScale = 0 Lighting.EnvironmentSpecularScale = 0
        Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0) Lighting.ClockTime = 12
    end)
    for _, v in ipairs(Lighting:GetChildren()) do if v:IsA("PostEffect") then v:Destroy() end end
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
function TP:GetPlayerList(includeLocal) local list = {} for _, p in ipairs(Players:GetPlayers()) do if includeLocal or p ~= player then table.insert(list, p.Name) end end return list end
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
function TP:StartLoop() if self.Loop then return end self.Loop = true self.Thread = task.spawn(function() while self.Loop do self:ToTarget() task.wait() end end) end
function TP:StopLoop() self.Loop = false self.Thread = nil end
_G.TP = TP

local function newEffectPart(shape, material, color, transparency)
    local p = Instance.new("Part")
    p.Shape = shape p.Material = material p.Color = color p.Transparency = transparency or 0
    p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
    return p
end

local function addGlow(part, color, range, brightness)
    local light = Instance.new("PointLight")
    light.Color = color
    light.Range = range
    light.Brightness = brightness
    light.Parent = part
    return light
end

local targetPosition = nil
local isTargeting = false
local targetMarker = nil
local originalLighting = { Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart }
local savedSky = nil
local spaceModeActive = false

local function enterSpaceMode()
    spaceModeActive = true
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then
        savedSky = sky
        sky.Parent = nil
    end
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") then v.Parent = nil end
    end
    Lighting.FogColor = Color3.new(0, 0, 0)
    Lighting.FogEnd = 200000
    Lighting.FogStart = 0
    Lighting.Ambient = Color3.new(0, 0, 0)
    Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
    Lighting.Brightness = 0
    Lighting.ClockTime = 0
    Lighting.EnvironmentDiffuseScale = 0
    Lighting.EnvironmentSpecularScale = 0
    Lighting.GlobalShadows = false
end

local function exitSpaceMode()
    spaceModeActive = false
    if savedSky then savedSky.Parent = Lighting savedSky = nil end
    Lighting.FogColor = originalLighting.FogColor
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.FogStart = originalLighting.FogStart
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.GlobalShadows = true
end

local function setDoomsdaySky(active)
    pcall(function()
        if active then
            local cc = Lighting:FindFirstChild("DoomsdayCC") or Instance.new("ColorCorrectionEffect")
            cc.Name = "DoomsdayCC" cc.TintColor = Color3.fromRGB(255, 60, 60) cc.Contrast = 0.4 cc.Saturation = -0.1 cc.Parent = Lighting
            local atm = Lighting:FindFirstChild("DoomsdayAtm") or Instance.new("Atmosphere")
            atm.Name = "DoomsdayAtm" atm.Density = 0.5 atm.Color = Color3.fromRGB(180, 20, 20)
            atm.Decay = Color3.fromRGB(120, 0, 0) atm.Glare = 0.2 atm.Haze = 1.5 atm.Parent = Lighting
            TweenService:Create(Lighting, TweenInfo.new(1.5), { Ambient = Color3.fromRGB(100, 10, 10), OutdoorAmbient = Color3.fromRGB(120, 20, 20), Brightness = 0.8, ClockTime = 0, FogColor = Color3.fromRGB(150, 0, 0), FogEnd = 600 }):Play()
        else
            local cc = Lighting:FindFirstChild("DoomsdayCC") if cc then cc:Destroy() end
            local atm = Lighting:FindFirstChild("DoomsdayAtm") if atm then atm:Destroy() end
            TweenService:Create(Lighting, TweenInfo.new(2), { Ambient = originalLighting.Ambient, OutdoorAmbient = originalLighting.OutdoorAmbient, Brightness = originalLighting.Brightness, ClockTime = originalLighting.ClockTime, FogColor = originalLighting.FogColor, FogEnd = originalLighting.FogEnd }):Play()
        end
    end)
end

local function createChargingOrb(position)
    local orb = newEffectPart(Enum.PartType.Ball, Enum.Material.Glass, Color3.fromRGB(0, 0, 0), 0.1)
    orb.Size = Vector3.new(1, 1, 1) orb.Position = position + Vector3.new(0, 2, 0) orb.Reflectance = 0.9 orb.Parent = workspace
    local light = Instance.new("PointLight") light.Color = Color3.fromRGB(255, 0, 0) light.Range = 30 light.Brightness = 10 light.Parent = orb
    TweenService:Create(orb, TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(45, 45, 45), Transparency = 0.3, Color = Color3.fromRGB(20, 0, 0) }):Play()
    return orb
end

local function createBeamSegment(startPos, endPos, width, color, transparency)
    local dist = (endPos - startPos).Magnitude
    if dist < 0.1 then return nil end
    local beam = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, color, transparency)
    beam.Size = Vector3.new(dist, width, width)
    beam.CFrame = CFrame.new(startPos + (endPos - startPos) * 0.5, endPos) * CFrame.Angles(0, math.rad(90), 0)
    beam.Parent = workspace
    return beam
end

local function createLaserFromSky(targetPos)
    local skyY = 400
    local segments = {}
    local prevPos = targetPos + Vector3.new(0, skyY, 0)
    for i = 1, 25 do
        task.spawn(function()
            task.wait((i - 1) * 0.04)
            local currentY = skyY - (skyY / 25) * i
            local curPos = targetPos + Vector3.new(0, currentY, 0)
            local seg = createBeamSegment(curPos, prevPos, 45, Color3.fromRGB(255, 220, 120), 0.15)
            if seg then
                table.insert(segments, seg)
                local light = Instance.new("PointLight") light.Color = Color3.fromRGB(255, 150, 50) light.Range = 150 light.Brightness = 20 light.Parent = seg
            end
            prevPos = curPos
        end)
    end
    for i = 1, 60 do
        task.spawn(function()
            task.wait(math.random(0, 15) / 10)
            local angle = math.random() * math.pi * 2 local dist = math.random(0, 120)
            local drop = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 60, 0), 0)
            drop.Size = Vector3.new(math.random(15, 35), math.random(15, 35), math.random(15, 35))
            drop.Position = targetPos + Vector3.new(math.cos(angle) * dist, 350, math.sin(angle) * dist)
            drop.Parent = workspace
            TweenService:Create(drop, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = targetPos + Vector3.new(math.cos(angle) * dist * 0.3, 0, math.sin(angle) * dist * 0.3),
                Size = Vector3.new(6, 6, 6), Transparency = 0.6
            }):Play()
            Debris:AddItem(drop, 1.5)
        end)
    end
    task.delay(3, function()
        for _, seg in ipairs(segments) do
            if seg and seg.Parent then
                TweenService:Create(seg, TweenInfo.new(1.5), { Transparency = 1 }):Play()
                Debris:AddItem(seg, 2)
            end
        end
    end)
end

local function spawnGiantCrater(hitPosition)
    local craterRadius = Cfg.RailgunCraterRadius
    local craterDepth = Cfg.RailgunCraterDepth
    pcall(function()
        local terrain = workspace.Terrain
        terrain:FillBall(hitPosition, craterRadius, Enum.Material.Air)
        terrain:FillBall(hitPosition - Vector3.new(0, craterDepth * 0.4, 0), craterRadius * 0.85, Enum.Material.Air)
        terrain:FillBall(hitPosition - Vector3.new(0, craterDepth * 0.8, 0), craterRadius * 0.6, Enum.Material.Air)
        terrain:FillBall(hitPosition - Vector3.new(0, craterDepth * 0.9, 0), craterRadius * 0.7, Enum.Material.CrackedLava)
        for i = 1, 50 do
            local a = (i / 50) * math.pi * 2
            local dist = craterRadius * (0.9 + math.random() * 0.4)
            terrain:FillBall(hitPosition + Vector3.new(math.cos(a) * dist, math.random(-3, 0), math.sin(a) * dist), math.random(8, 18), Enum.Material.Basalt)
        end
    end)
    local lavaCenter = hitPosition - Vector3.new(0, craterDepth * 0.8, 0)
    local lavaBase = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 70, 0), 0)
    lavaBase.Size = Vector3.new(craterRadius * 1.7, 8, craterRadius * 1.7)
    lavaBase.Position = lavaCenter
    lavaBase.Parent = workspace
    addGlow(lavaBase, Color3.fromRGB(255, 60, 0), craterRadius * 4, 15)
    Debris:AddItem(lavaBase, 300)
    for i = 1, 100 do
        local angle = math.random() * math.pi * 2
        local r = math.random() * craterRadius * 0.9
        local crack = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 30, 0), 0)
        crack.Size = Vector3.new(math.random(6, 14), 10, math.random(20, 45))
        crack.CFrame = CFrame.new(lavaCenter + Vector3.new(math.cos(angle) * r, 4, math.sin(angle) * r)) * CFrame.Angles(0, angle + math.random(-0.9, 0.9), 0)
        crack.Parent = workspace
        Debris:AddItem(crack, 300)
    end
    for i = 1, 150 do
        task.spawn(function()
            task.wait(math.random(0, 20) / 10)
            local splash = Instance.new("Part")
            splash.Shape = Enum.PartType.Ball
            splash.Material = Enum.Material.Neon
            splash.Color = Color3.fromRGB(255, 80, 0)
            splash.Size = Vector3.new(math.random(8, 25), math.random(8, 25), math.random(8, 25))
            splash.Anchored = false splash.CanCollide = true splash.CanQuery = false
            splash.Position = hitPosition + Vector3.new(math.random(-30, 30), math.random(5, 35), math.random(-30, 30))
            splash.Parent = workspace
            splash.AssemblyLinearVelocity = Vector3.new(math.random(-150, 150), math.random(80, 200), math.random(-150, 150))
            splash.AssemblyAngularVelocity = Vector3.new(math.random(-60, 60), math.random(-60, 60), math.random(-60, 60))
            Debris:AddItem(splash, 15)
        end)
    end
    for i = 1, Cfg.RailgunDebrisCount do
        task.spawn(function()
            task.wait(math.random(0, 15) / 10)
            local w = math.random(20, 70) / 10
            local h = math.random(20, 70) / 10
            local d = math.random(20, 70) / 10
            local rock = Instance.new("Part")
            rock.Shape = Enum.PartType.Block
            rock.Material = Enum.Material.Neon
            rock.Color = Color3.fromRGB(math.random(70, 110), math.random(70, 110), math.random(70, 110))
            rock.Size = Vector3.new(w, h, d)
            rock.Anchored = false rock.CanCollide = true rock.CanQuery = false
            local angle = math.random() * math.pi * 2
            local dist = craterRadius * (0.6 + math.random() * 0.6)
            rock.Position = hitPosition + Vector3.new(math.cos(angle) * dist, math.random(5, 30), math.sin(angle) * dist)
            rock.CFrame = CFrame.new(rock.Position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
            rock.Parent = workspace
            rock.AssemblyLinearVelocity = Vector3.new(math.random(-40, 40), math.random(20, 50), math.random(-40, 40))
            rock.AssemblyAngularVelocity = Vector3.new(math.random(-30, 30), math.random(-30, 30), math.random(-30, 30))
            task.spawn(function()
                for _ = 1, 400 do
                    if not rock or not rock.Parent then break end
                    local toCenter = Vector3.new(hitPosition.X - rock.Position.X, 0, hitPosition.Z - rock.Position.Z)
                    local mag = toCenter.Magnitude
                    if mag > 1 then
                        local dir = toCenter.Unit
                        rock.AssemblyLinearVelocity = Vector3.new(dir.X * 20, rock.AssemblyLinearVelocity.Y, dir.Z * 20)
                    else
                        rock.AssemblyLinearVelocity = Vector3.new(0, rock.AssemblyLinearVelocity.Y, 0)
                    end
                    task.wait(0.05)
                end
            end)
            Debris:AddItem(rock, 60)
        end)
    end
    task.spawn(function()
        for _ = 1, 300 do
            task.wait(0.15)
            local angle = math.random() * math.pi * 2
            local r = math.random() * craterRadius * 0.85
            local glow = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 100, 20), 0)
            glow.Size = Vector3.new(math.random(6, 16), math.random(6, 16), math.random(6, 16))
            glow.Position = lavaCenter + Vector3.new(math.cos(angle) * r, math.random(0, 8), math.sin(angle) * r)
            glow.Anchored = false glow.CanCollide = false glow.Parent = workspace
            glow.AssemblyLinearVelocity = Vector3.new(math.random(-40, 40), math.random(30, 80), math.random(-40, 40))
            Debris:AddItem(glow, 4)
        end
    end)
    local smokeHolder = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.new(1,1,1), 1)
    smokeHolder.Size = Vector3.new(2, 2, 2) smokeHolder.Position = hitPosition + Vector3.new(0, 50, 0) smokeHolder.Parent = workspace
    local smoke = Instance.new("Smoke") smoke.Color = Color3.fromRGB(40, 40, 40) smoke.Opacity = 0.85 smoke.RiseVelocity = 45 smoke.Size = 60 smoke.Parent = smokeHolder
    local smokeCap = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.new(1,1,1), 1)
    smokeCap.Size = Vector3.new(2, 2, 2) smokeCap.Position = hitPosition + Vector3.new(0, 250, 0) smokeCap.Parent = workspace
    local smoke2 = Instance.new("Smoke") smoke2.Color = Color3.fromRGB(30, 30, 30) smoke2.Opacity = 0.95 smoke2.RiseVelocity = 25 smoke2.Size = 150 smoke2.Parent = smokeCap
    task.delay(60, function() if smoke then smoke.Enabled = false end if smoke2 then smoke2.Enabled = false end end)
    Debris:AddItem(smokeHolder, 70) Debris:AddItem(smokeCap, 70)
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
    local chargeOrb = createChargingOrb(targetPos)
    task.spawn(function()
        task.wait(3)
        if chargeOrb and chargeOrb.Parent then chargeOrb:Destroy() end
        setDoomsdaySky(true)
        createLaserFromSky(targetPos)
        screenShake(Cfg.RailgunShakeIntensity, Cfg.RailgunShakeDuration)
        task.wait(2)
        spawnGiantCrater(targetPos)
        task.wait(40)
        setDoomsdaySky(false)
    end)
end

local spaceAnim = {}
local spaceFolderRef = nil
local function addAnim(data) table.insert(spaceAnim, data) end

local function makeDetailedMeteor(pos, size)
    local model = Instance.new("Model") model.Name = "Meteor" model.Parent = spaceFolderRef
    local r = math.random(160, 220)
    local g = math.random(160, 220)
    local b = math.random(160, 220)
    local core = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(r, g, b), 0)
    core.Size = Vector3.new(size, size * 0.95, size * 0.9)
    core.Position = pos
    core.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
    core.Parent = model
    addGlow(core, Color3.fromRGB(r, g, b), size * 4, 3)
    for i = 1, math.random(8, 16) do
        local crater = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(math.max(r - 60, 40), math.max(g - 60, 40), math.max(b - 60, 40)), 0)
        local s = size * math.random(12, 28) / 100
        crater.Size = Vector3.new(s, s, s)
        local angle = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = size * 0.45
        crater.Position = pos + Vector3.new(d * math.sin(phi) * math.cos(angle), d * math.cos(phi), d * math.sin(phi) * math.sin(angle))
        crater.Parent = model
    end
    for i = 1, math.random(4, 8) do
        local bump = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(math.min(r + 30, 255), math.min(g + 30, 255), math.min(b + 30, 255)), 0)
        local s = size * math.random(20, 35) / 100
        bump.Size = Vector3.new(s, s * 0.7, s)
        local angle = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = size * 0.4
        bump.Position = pos + Vector3.new(d * math.sin(phi) * math.cos(angle), d * math.cos(phi), d * math.sin(phi) * math.sin(angle))
        bump.Parent = model
    end
    for i = 1, math.random(2, 4) do
        local vein = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(math.max(r - 80, 30), math.max(g - 80, 30), math.max(b - 80, 30)), 0)
        vein.Size = Vector3.new(size * 0.6, size * 0.08, size * 0.05)
        vein.CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
        vein.Parent = model
    end
    addAnim({model = model, basePos = pos, rotSpeed = Vector3.new(math.random(-10, 10) / 200, math.random(-10, 10) / 200, math.random(-10, 10) / 200), floatSpeed = math.random(15, 45) / 100, floatAmp = math.random(5, 15), startTime = tick(), rot = math.random() * 6})
    return model
end

local function createSpaceEnvironment(origin)
    local folder = Instance.new("Folder") folder.Name = "CinematicSpace" folder.Parent = workspace
    spaceFolderRef = folder

    local void = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.new(0, 0, 0), 0)
    void.Size = Vector3.new(120000, 120000, 120000)
    void.Position = origin
    void.Parent = folder

    for i = 1, 2000 do
        local angle = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local dist = 40000 + math.random() * 20000
        local starPos = origin + Vector3.new(dist * math.sin(phi) * math.cos(angle), dist * math.cos(phi), dist * math.sin(phi) * math.sin(angle))
        local starColor = Color3.fromRGB(255, 255, 255)
        local starRoll = math.random()
        if starRoll > 0.9 then starColor = Color3.fromRGB(180, 200, 255)
        elseif starRoll > 0.8 then starColor = Color3.fromRGB(255, 220, 180)
        elseif starRoll > 0.7 then starColor = Color3.fromRGB(255, 180, 180)
        end
        local star = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, starColor, 0)
        local s = math.random(80, 250)
        star.Size = Vector3.new(s, s, s)
        star.Position = starPos
        star.Parent = folder
    end

    local sunPos = origin
    local sun = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 235, 110), 0)
    sun.Size = Vector3.new(2400, 2400, 2400) sun.Position = sunPos sun.Parent = folder
    addGlow(sun, Color3.fromRGB(255, 220, 100), 80000, 30)
    for i = 1, 6 do
        local corona = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, math.max(200 - i * 30, 60), math.max(80 - i * 10, 20)), 0.75 + i * 0.02)
        corona.Size = Vector3.new(2500 + i * 280, 2500 + i * 280, 2500 + i * 280)
        corona.Position = sunPos
        corona.Parent = folder
    end
    for i = 1, 20 do
        local flare = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 140, 40), 0.35)
        flare.Size = Vector3.new(4500 + i * 80, 80, 250)
        flare.CFrame = CFrame.new(sunPos) * CFrame.Angles(math.random() * math.pi, math.random() * math.pi, math.random() * math.pi)
        flare.Parent = folder
    end
    for i = 1, 80 do
        local plasma = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 220, 90), 0)
        local s = math.random(200, 500)
        plasma.Size = Vector3.new(s, s, s)
        local angle = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 1250
        plasma.Position = sunPos + Vector3.new(d * math.sin(phi) * math.cos(angle), d * math.cos(phi), d * math.sin(phi) * math.sin(angle))
        plasma.Parent = folder
    end
    addAnim({model = sun, basePos = sunPos, rotSpeed = Vector3.new(0, 0.02, 0), floatSpeed = 0, floatAmp = 0, startTime = tick(), rot = 0, isPlanet = true, core = sun})

    local mercuryPos = origin + Vector3.new(7000, 0, 3000)
    local mercuryModel = Instance.new("Model") mercuryModel.Name = "Mercury" mercuryModel.Parent = folder
    local mercuryCore = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(200, 190, 180), 0)
    mercuryCore.Size = Vector3.new(600, 600, 600) mercuryCore.Position = mercuryPos mercuryCore.Parent = mercuryModel
    addGlow(mercuryCore, Color3.fromRGB(200, 190, 180), 6000, 10)
    for i = 1, 40 do
        local crater = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(140, 130, 120), 0)
        crater.Size = Vector3.new(math.random(40, 100), math.random(40, 100), math.random(40, 100))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 290
        crater.Position = mercuryPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        crater.Parent = mercuryModel
    end
    for i = 1, 15 do
        local ridge = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(170, 160, 150), 0)
        ridge.Size = Vector3.new(math.random(100, 250), math.random(15, 30), math.random(20, 40))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 295
        ridge.Position = mercuryPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        ridge.CFrame = CFrame.new(ridge.Position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
        ridge.Parent = mercuryModel
    end
    addAnim({model = mercuryModel, basePos = mercuryPos, rotSpeed = Vector3.new(0, math.random(5, 15) / 100, 0), floatSpeed = math.random(10, 25) / 100, floatAmp = math.random(15, 40), startTime = tick(), rot = 0, isPlanet = true, core = mercuryCore})

    local venusPos = origin + Vector3.new(-9000, 1200, -4500)
    local venusModel = Instance.new("Model") venusModel.Name = "Venus" venusModel.Parent = folder
    local venusCore = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(245, 215, 145), 0)
    venusCore.Size = Vector3.new(900, 900, 900) venusCore.Position = venusPos venusCore.Parent = venusModel
    addGlow(venusCore, Color3.fromRGB(245, 215, 145), 9000, 12)
    for i = 1, 12 do
        local band = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(220, 180, 120), 0.15)
        band.Size = Vector3.new(18, 900, 900)
        band.CFrame = CFrame.new(venusPos + Vector3.new(0, (i - 6.5) * 70, 0)) * CFrame.Angles(0, 0, math.rad(90))
        band.Parent = venusModel
    end
    for i = 1, 20 do
        local cloud = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 235, 180), 0.4)
        cloud.Size = Vector3.new(math.random(150, 350), math.random(80, 150), math.random(150, 350))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 460
        cloud.Position = venusPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        cloud.CFrame = CFrame.new(cloud.Position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
        cloud.Parent = venusModel
    end
    local venusAtm = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 220, 150), 0.9)
    venusAtm.Size = Vector3.new(980, 980, 980) venusAtm.Position = venusPos venusAtm.Parent = venusModel
    addAnim({model = venusModel, basePos = venusPos, rotSpeed = Vector3.new(0, math.random(5, 15) / 100, 0), floatSpeed = math.random(10, 25) / 100, floatAmp = math.random(15, 40), startTime = tick(), rot = 0, isPlanet = true, core = venusCore})

    local earthPos = origin + Vector3.new(15000, 0, 8000)
    local earthModel = Instance.new("Model") earthModel.Name = "Earth" earthModel.Parent = folder
    local earthCore = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(30, 110, 200), 0)
    earthCore.Size = Vector3.new(1100, 1100, 1100) earthCore.Position = earthPos earthCore.Parent = earthModel
    addGlow(earthCore, Color3.fromRGB(60, 150, 230), 12000, 15)
    local earthAtm = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(100, 190, 255), 0.85)
    earthAtm.Size = Vector3.new(1200, 1200, 1200) earthAtm.Position = earthPos earthAtm.Parent = earthModel
    local earthClouds = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.new(1, 1, 1), 0.8)
    earthClouds.Size = Vector3.new(1160, 1160, 1160) earthClouds.Position = earthPos earthClouds.Parent = earthModel
    local continentColors = {
        Color3.fromRGB(55, 130, 55), Color3.fromRGB(70, 150, 70),
        Color3.fromRGB(90, 110, 60), Color3.fromRGB(120, 100, 60),
        Color3.fromRGB(80, 120, 50), Color3.fromRGB(60, 90, 50),
    }
    for i = 1, 50 do
        local land = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, continentColors[math.random(1, #continentColors)], 0)
        land.Size = Vector3.new(math.random(150, 380), math.random(80, 180), math.random(150, 380))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 520
        land.Position = earthPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        land.CFrame = CFrame.new(land.Position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
        land.Parent = earthModel
    end
    local northPolar = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.new(1, 1, 1), 0)
    northPolar.Size = Vector3.new(400, 250, 400)
    northPolar.Position = earthPos + Vector3.new(0, 540, 0)
    northPolar.Parent = earthModel
    local southPolar = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.new(1, 1, 1), 0)
    southPolar.Size = Vector3.new(450, 280, 450)
    southPolar.Position = earthPos + Vector3.new(0, -540, 0)
    southPolar.Parent = earthModel
    for i = 1, 25 do
        local cloudBlock = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.new(1, 1, 1), 0.4)
        cloudBlock.Size = Vector3.new(math.random(200, 400), math.random(60, 120), math.random(200, 400))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 580
        cloudBlock.Position = earthPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        cloudBlock.CFrame = CFrame.new(cloudBlock.Position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
        cloudBlock.Parent = earthModel
    end
    addAnim({model = earthModel, basePos = earthPos, rotSpeed = Vector3.new(0, 0.08, 0), floatSpeed = math.random(10, 25) / 100, floatAmp = math.random(15, 40), startTime = tick(), rot = 0, isPlanet = true, core = earthCore})

    local moonOrbitRadius = 2200
    local moonModel = Instance.new("Model") moonModel.Name = "Moon" moonModel.Parent = folder
    local moonPos = earthPos + Vector3.new(moonOrbitRadius, 0, 0)
    local moonCore = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(220, 220, 220), 0)
    moonCore.Size = Vector3.new(320, 320, 320) moonCore.Position = moonPos moonCore.Parent = moonModel
    addGlow(moonCore, Color3.fromRGB(220, 220, 220), 4000, 6)
    for i = 1, 30 do
        local crater = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(150, 150, 150), 0)
        crater.Size = Vector3.new(math.random(30, 80), math.random(30, 80), math.random(30, 80))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 155
        crater.Position = moonPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        crater.Parent = moonModel
    end
    for i = 1, 10 do
        local maria = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(160, 160, 160), 0)
        maria.Size = Vector3.new(math.random(60, 130), math.random(20, 40), math.random(60, 130))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 158
        maria.Position = moonPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        maria.CFrame = CFrame.new(maria.Position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
        maria.Parent = moonModel
    end
    addAnim({model = moonModel, basePos = moonPos, orbitCenter = earthPos, orbitRadius = moonOrbitRadius, orbitSpeed = 0.12, rotSpeed = Vector3.new(0, 0.05, 0), startTime = tick(), rot = 0, isOrbit = true})

    for i = 1, 80 do
        local orbitRing = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(100, 140, 200), 0.85)
        orbitRing.Size = Vector3.new(1, 4200 + i * 8, 4200 + i * 8)
        orbitRing.CFrame = CFrame.new(earthPos) * CFrame.Angles(math.rad(90) + (i / 80) * math.rad(25), 0, math.rad(20))
        orbitRing.Parent = folder
    end

    local marsPos = origin + Vector3.new(28000, -1800, 16000)
    local marsModel = Instance.new("Model") marsModel.Name = "Mars" marsModel.Parent = folder
    local marsCore = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(220, 110, 70), 0)
    marsCore.Size = Vector3.new(800, 800, 800) marsCore.Position = marsPos marsCore.Parent = marsModel
    addGlow(marsCore, Color3.fromRGB(255, 130, 80), 9000, 12)
    local marsAtm = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 150, 100), 0.9)
    marsAtm.Size = Vector3.new(880, 880, 880) marsAtm.Position = marsPos marsAtm.Parent = marsModel
    local marsNorthPolar = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.new(1, 1, 1), 0.1)
    marsNorthPolar.Size = Vector3.new(350, 180, 350)
    marsNorthPolar.Position = marsPos + Vector3.new(0, 395, 0)
    marsNorthPolar.Parent = marsModel
    local marsSouthPolar = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.new(1, 1, 1), 0.1)
    marsSouthPolar.Size = Vector3.new(320, 160, 320)
    marsSouthPolar.Position = marsPos + Vector3.new(0, -395, 0)
    marsSouthPolar.Parent = marsModel
    for i = 1, 35 do
        local crater = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(160, 65, 30), 0)
        crater.Size = Vector3.new(math.random(50, 140), math.random(50, 140), math.random(50, 140))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 385
        crater.Position = marsPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        crater.Parent = marsModel
    end
    for i = 1, 15 do
        local canyon = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(140, 55, 25), 0)
        canyon.Size = Vector3.new(math.random(200, 400), math.random(15, 30), math.random(30, 60))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 388
        canyon.Position = marsPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        canyon.CFrame = CFrame.new(canyon.Position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
        canyon.Parent = marsModel
    end
    addAnim({model = marsModel, basePos = marsPos, rotSpeed = Vector3.new(0, math.random(5, 15) / 100, 0), floatSpeed = math.random(10, 25) / 100, floatAmp = math.random(15, 40), startTime = tick(), rot = 0, isPlanet = true, core = marsCore})

    local jupiterPos = origin + Vector3.new(-22000, 2500, 18000)
    local jupiterModel = Instance.new("Model") jupiterModel.Name = "Jupiter" jupiterModel.Parent = folder
    local jupiterCore = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(235, 195, 155), 0)
    jupiterCore.Size = Vector3.new(1900, 1900, 1900) jupiterCore.Position = jupiterPos jupiterCore.Parent = jupiterModel
    addGlow(jupiterCore, Color3.fromRGB(245, 210, 170), 22000, 18)
    local jupiterColors = {
        Color3.fromRGB(185, 130, 85), Color3.fromRGB(245, 215, 175),
        Color3.fromRGB(205, 150, 105), Color3.fromRGB(235, 195, 150),
        Color3.fromRGB(170, 115, 75), Color3.fromRGB(250, 225, 185),
        Color3.fromRGB(195, 140, 95), Color3.fromRGB(230, 190, 145),
        Color3.fromRGB(200, 145, 100), Color3.fromRGB(240, 205, 160),
        Color3.fromRGB(180, 125, 80), Color3.fromRGB(248, 220, 180),
    }
    for i = 1, 16 do
        local band = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, jupiterColors[i % #jupiterColors + 1], 0.1)
        band.Size = Vector3.new(35, 1880, 1880)
        band.CFrame = CFrame.new(jupiterPos + Vector3.new(0, (i - 8.5) * 105, 0)) * CFrame.Angles(0, 0, math.rad(90))
        band.Parent = jupiterModel
    end
    local redSpot = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(225, 95, 75), 0)
    redSpot.Size = Vector3.new(650, 380, 420)
    redSpot.Position = jupiterPos + Vector3.new(1100, -280, 800)
    redSpot.CFrame = CFrame.new(redSpot.Position) * CFrame.Angles(0, math.rad(45), math.rad(-15))
    redSpot.Parent = jupiterModel
    local redSpotRing = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(190, 75, 60), 0.3)
    redSpotRing.Size = Vector3.new(800, 500, 540)
    redSpotRing.Position = redSpot.Position
    redSpotRing.CFrame = redSpot.CFrame
    redSpotRing.Parent = jupiterModel
    for i = 1, 20 do
        local swirl = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, jupiterColors[math.random(1, #jupiterColors)], 0.15)
        swirl.Size = Vector3.new(math.random(150, 350), math.random(80, 180), math.random(150, 350))
        local a = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local d = 950
        swirl.Position = jupiterPos + Vector3.new(d * math.sin(phi) * math.cos(a), d * math.cos(phi), d * math.sin(phi) * math.sin(a))
        swirl.CFrame = CFrame.new(swirl.Position) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
        swirl.Parent = jupiterModel
    end
    addAnim({model = jupiterModel, basePos = jupiterPos, rotSpeed = Vector3.new(0, math.random(5, 15) / 100, 0), floatSpeed = math.random(8, 20) / 100, floatAmp = math.random(20, 50), startTime = tick(), rot = 0, isPlanet = true, core = jupiterCore})

    local saturnPos = origin + Vector3.new(-40000, -2500, -30000)
    local saturnModel = Instance.new("Model") saturnModel.Name = "Saturn" saturnModel.Parent = folder
    local saturnCore = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(245, 225, 175), 0)
    saturnCore.Size = Vector3.new(1600, 1600, 1600) saturnCore.Position = saturnPos saturnCore.Parent = saturnModel
    addGlow(saturnCore, Color3.fromRGB(250, 230, 180), 18000, 16)
    for i = 1, 8 do
        local band = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(215, 190, 140), 0.15)
        band.Size = Vector3.new(30, 1580, 1580)
        band.CFrame = CFrame.new(saturnPos + Vector3.new(0, (i - 4.5) * 100, 0)) * CFrame.Angles(0, 0, math.rad(90))
        band.Parent = saturnModel
    end
    local ringColors = {
        Color3.fromRGB(230, 210, 170), Color3.fromRGB(190, 170, 130),
        Color3.fromRGB(255, 235, 195), Color3.fromRGB(210, 190, 150),
        Color3.fromRGB(250, 230, 190), Color3.fromRGB(180, 160, 125),
        Color3.fromRGB(235, 215, 175), Color3.fromRGB(200, 180, 140),
        Color3.fromRGB(245, 225, 185), Color3.fromRGB(195, 175, 135),
        Color3.fromRGB(255, 240, 200),
    }
    for i = 1, 12 do
        local ringRadius = 2000 + i * 160
        local ring = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, ringColors[i], 0.15)
        ring.Size = Vector3.new(25, ringRadius, ringRadius)
        ring.CFrame = CFrame.new(saturnPos) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(25), 0, math.rad(10))
        ring.Parent = saturnModel
        local ringInner = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.new(0, 0, 0), 0.4)
        ringInner.Size = Vector3.new(28, ringRadius - 90, ringRadius - 90)
        ringInner.CFrame = ring.CFrame
        ringInner.Parent = saturnModel
    end
    addAnim({model = saturnModel, basePos = saturnPos, rotSpeed = Vector3.new(0, math.random(5, 15) / 100, 0), floatSpeed = math.random(8, 20) / 100, floatAmp = math.random(20, 50), startTime = tick(), rot = 0, isPlanet = true, core = saturnCore})

    for i = 1, 150 do
        local angle = math.random() * math.pi * 2
        local dist = 4000 + math.random() * 35000
        local height = math.random(-10000, 10000)
        local size = math.random(200, 800)
        local pos = origin + Vector3.new(math.cos(angle) * dist, height, math.sin(angle) * dist)
        makeDetailedMeteor(pos, size)
    end

    return folder, earthPos, sunPos, mercuryPos, venusPos, marsPos, jupiterPos, saturnPos
end

local function startSpaceAnimation()
    local connection = RunService.Heartbeat:Connect(function()
        if not spaceModeActive then return end
        local now = tick()
        for _, data in ipairs(spaceAnim) do
            if data.model and data.model.Parent then
                local elapsed = now - data.startTime
                if data.isOrbit and data.orbitCenter then
                    local angle = elapsed * data.orbitSpeed * math.pi * 2
                    local offset = Vector3.new(math.cos(angle) * data.orbitRadius, 0, math.sin(angle) * data.orbitRadius)
                    local targetPos = data.orbitCenter + offset
                    local rot = data.rot + elapsed * data.rotSpeed.Y
                    data.model:PivotTo(CFrame.new(targetPos) * CFrame.Angles(0, rot, 0))
                else
                    local rot = data.rot + elapsed * data.rotSpeed.Y
                    local floatY = math.sin(elapsed * data.floatSpeed * math.pi * 2) * data.floatAmp
                    local newPos = data.basePos + Vector3.new(0, floatY, 0)
                    if data.isPlanet and data.core then
                        data.core.CFrame = CFrame.new(newPos) * CFrame.Angles(0, rot, 0)
                    else
                        data.model:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, rot, 0))
                    end
                end
            end
        end
    end)
    return connection
end

local function createSpaceStationRailgun(earthPos)
    local folder = Instance.new("Folder") folder.Name = "SpaceStationRailgun" folder.Parent = workspace
    local gunBase = earthPos + Vector3.new(0, 6500, 0)
    local core = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(110, 115, 125), 0)
    core.Size = Vector3.new(900, 175, 175) core.CFrame = CFrame.new(gunBase) * CFrame.Angles(0, 0, math.rad(90)) core.Parent = folder
    addGlow(core, Color3.fromRGB(120, 160, 220), 1500, 8)
    local ring1 = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(80, 85, 95), 0)
    ring1.Size = Vector3.new(60, 275, 275) ring1.CFrame = CFrame.new(gunBase + Vector3.new(450, 0, 0)) * CFrame.Angles(0, 0, math.rad(90)) ring1.Parent = folder
    local ring2 = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(80, 85, 95), 0)
    ring2.Size = Vector3.new(45, 240, 240) ring2.CFrame = CFrame.new(gunBase + Vector3.new(375, 0, 0)) * CFrame.Angles(0, 0, math.rad(90)) ring2.Parent = folder
    for i = 1, 8 do
        local detailRing = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(120, 130, 145), 0)
        detailRing.Size = Vector3.new(10, 200, 200)
        detailRing.CFrame = CFrame.new(gunBase + Vector3.new(150 + i * 70, 0, 0)) * CFrame.Angles(0, 0, math.rad(90))
        detailRing.Parent = folder
    end
    local mount = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(70, 75, 85), 0)
    mount.Size = Vector3.new(200, 500, 200) mount.Position = gunBase + Vector3.new(0, -300, 0) mount.Parent = folder
    addGlow(mount, Color3.fromRGB(120, 160, 220), 800, 5)
    for i = 1, 4 do
        local mountRib = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(90, 95, 105), 0)
        mountRib.Size = Vector3.new(220, 40, 220)
        mountRib.Position = gunBase + Vector3.new(0, -100 - i * 100, 0)
        mountRib.Parent = folder
    end
    local barrel = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(60, 65, 75), 0)
    barrel.Size = Vector3.new(1300, 130, 130) barrel.CFrame = CFrame.new(gunBase + Vector3.new(0, -800, 0)) * CFrame.Angles(0, 0, math.rad(90)) barrel.Parent = folder
    addGlow(barrel, Color3.fromRGB(100, 150, 220), 1200, 6)
    for i = 1, 6 do
        local ringSeg = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(100, 105, 115), 0)
        ringSeg.Size = Vector3.new(20, 140, 140) ringSeg.CFrame = CFrame.new(gunBase + Vector3.new(0, -350 - i * 190, 0)) * CFrame.Angles(0, 0, math.rad(90)) ringSeg.Parent = folder
    end
    local muzzle = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(80, 160, 255), 0.3)
    muzzle.Size = Vector3.new(250, 250, 250) muzzle.Position = gunBase + Vector3.new(0, -1450, 0) muzzle.Parent = folder
    addGlow(muzzle, Color3.fromRGB(100, 200, 255), 2500, 15)
    for _, side in ipairs({-1, 1}) do
        local panelHolder = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(80, 80, 80), 0)
        panelHolder.Size = Vector3.new(35, 125, 600) panelHolder.Position = gunBase + Vector3.new(0, 0, side * 600) panelHolder.Parent = folder
        for i = 1, 8 do
            local panel = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(30, 100, 180), 0.05)
            panel.Size = Vector3.new(30, 250, 200) panel.Position = gunBase + Vector3.new(0, 0, side * (500 + i * 150)) panel.Parent = folder
            addGlow(panel, Color3.fromRGB(100, 180, 255), 400, 4)
            local panelLine = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(150, 220, 255), 0.1)
            panelLine.Size = Vector3.new(32, 250, 7) panelLine.Position = panel.Position + Vector3.new(0, 0, -side * 100) panelLine.Parent = folder
        end
    end
    local charge = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(150, 220, 255), 0)
    charge.Size = Vector3.new(80, 80, 80) charge.Position = muzzle.Position charge.Parent = folder
    addGlow(charge, Color3.fromRGB(150, 220, 255), 3000, 20)
    return folder, charge, muzzle.Position
end

local function createLetterbox()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CinematicLetterbox"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 998
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = player.PlayerGui end
    local topBar = Instance.new("Frame")
    topBar.AnchorPoint = Vector2.new(0, 0)
    topBar.Size = UDim2.new(1, 0, 0, 0)
    topBar.Position = UDim2.new(0, 0, 0, 0)
    topBar.BackgroundColor3 = Color3.new(0, 0, 0)
    topBar.BorderSizePixel = 0
    topBar.Parent = gui
    local bottomBar = Instance.new("Frame")
    bottomBar.AnchorPoint = Vector2.new(0, 1)
    bottomBar.Size = UDim2.new(1, 0, 0, 0)
    bottomBar.Position = UDim2.new(0, 0, 1, 0)
    bottomBar.BackgroundColor3 = Color3.new(0, 0, 0)
    bottomBar.BorderSizePixel = 0
    bottomBar.Parent = gui
    return gui, topBar, bottomBar
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
    local letterboxGui, topBar, bottomBar = createLetterbox()
    TweenService:Create(topBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 60) }):Play()
    TweenService:Create(bottomBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 60) }):Play()
    camera.CameraType = Enum.CameraType.Scriptable
    local startCF = camera.CFrame
    task.spawn(function()
        local dur = 1.2 local startT = tick()
        while tick() - startT < dur do
            local a = (tick() - startT) / dur
            camera.CFrame = startCF:Lerp(CFrame.new(startCF.Position + Vector3.new(0, 300 * a, 0), startCF.Position + startCF.LookVector * 100 + Vector3.new(0, 300 * a, 0)), a)
            RunService.RenderStepped:Wait()
        end
    end)
    task.wait(1.2)
    TweenService:Create(blackFrame, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
    task.wait(0.5)
    enterSpaceMode()
    local origin = Vector3.new(0, 500000, 0)
    local spaceFolder, earthPos, sunPos, mercuryPos, venusPos, marsPos, jupiterPos, saturnPos = createSpaceEnvironment(origin)
    local stationFolder, chargeOrb, muzzlePos = createSpaceStationRailgun(earthPos)
    local animConn = startSpaceAnimation()
    camera.CFrame = CFrame.new(sunPos + Vector3.new(6000, 2000, 6000), sunPos)
    task.wait(0.3)
    TweenService:Create(blackFrame, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
    local function cameraMoveTo(startCF, endCF, dur)
        local startT = tick()
        while tick() - startT < dur do
            local a = (tick() - startT) / dur
            camera.CFrame = startCF:Lerp(endCF, a)
            RunService.RenderStepped:Wait()
        end
    end
    cameraMoveTo(camera.CFrame, CFrame.new(sunPos + Vector3.new(-3500, 1200, 7000), sunPos), 2.5) task.wait(2.5)
    cameraMoveTo(camera.CFrame, CFrame.new(saturnPos + Vector3.new(3000, 1500, 3500), saturnPos), 2.5) task.wait(2.5)
    cameraMoveTo(camera.CFrame, CFrame.new(marsPos + Vector3.new(-2500, 800, 3000), marsPos), 2.5) task.wait(2.5)
    cameraMoveTo(camera.CFrame, CFrame.new(jupiterPos + Vector3.new(3500, 2000, 5000), jupiterPos), 2.5) task.wait(2.5)
    cameraMoveTo(camera.CFrame, CFrame.new(earthPos + Vector3.new(3500, 2500, 5000), earthPos), 2.5) task.wait(2.5)
    cameraMoveTo(camera.CFrame, CFrame.new(earthPos + Vector3.new(1500, 1000, 3000), earthPos), 1.5) task.wait(1.5)
    local closeUpCF = CFrame.new(muzzlePos + Vector3.new(0, 300, 1000), muzzlePos)
    cameraMoveTo(camera.CFrame, closeUpCF, 2.5) task.wait(2.5)
    task.spawn(function()
        local dur = 4 local startT = tick()
        while tick() - startT < dur do
            local a = (tick() - startT) / dur
            local s = 80 + a * 500
            chargeOrb.Size = Vector3.new(s, s, s)
            chargeOrb.Color = Color3.fromRGB(150 + 100 * a, 220 + 30 * a, 255)
            RunService.RenderStepped:Wait()
        end
    end)
    task.wait(4)
    local flash = Instance.new("Frame")
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = Color3.new(1, 1, 1)
    flash.BackgroundTransparency = 0
    flash.BorderSizePixel = 0
    flash.Parent = blackoutGui
    TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
    Debris:AddItem(flash, 0.6)
    local beamFromGun = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(150, 220, 255), 0.05)
    local dir = (earthPos - muzzlePos).Unit
    local dist = (earthPos - muzzlePos).Magnitude
    beamFromGun.Size = Vector3.new(dist, 500, 500)
    beamFromGun.CFrame = CFrame.new(muzzlePos + dir * dist / 2, earthPos) * CFrame.Angles(0, math.rad(90), 0)
    beamFromGun.Parent = workspace
    addGlow(beamFromGun, Color3.fromRGB(150, 220, 255), 5000, 20)
    Debris:AddItem(beamFromGun, 1.5)
    task.wait(0.5)
    TweenService:Create(blackFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
    task.wait(0.25)
    animConn:Disconnect()
    spaceAnim = {}
    stationFolder:Destroy()
    spaceFolder:Destroy()
    spaceFolderRef = nil
    exitSpaceMode()
    camera.CameraType = oldCameraType
    if oldSubject then camera.CameraSubject = oldSubject end
    TweenService:Create(blackFrame, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
    task.wait(0.4)
    createLaserFromSky(targetPos)
    setDoomsdaySky(true)
    screenShake(Cfg.RailgunShakeIntensity * 2, 2)
    task.wait(3)
    spawnGiantCrater(targetPos)
    task.wait(30)
    setDoomsdaySky(false)
    TweenService:Create(topBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 0) }):Play()
    TweenService:Create(bottomBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 0) }):Play()
    task.wait(0.6)
    blackFrame:Destroy()
    blackoutGui:Destroy()
    letterboxGui:Destroy()
end

local Window = WindUI:CreateWindow({ Title = "力量之冠封存全能版 4.2", Icon = "zap", Author = "力量之冠", Folder = "PowerCrownSave", Theme = "Dark", Transparent = true, Resizable = false, Size = UDim2.fromOffset(460, 780) })

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
RailgunSection:Button({ Title = "选择发射目标", Callback = function() isTargeting = true RailgunStatus:SetDesc("请在游戏画面中点击地面选择目标...") end })
RailgunSection:Button({ Title = "立即发射", Callback = function() if not targetPosition then RailgunStatus:SetDesc("请先点击「选择发射目标」选择地点！") return end executeRailgunStrike(targetPosition) RailgunStatus:SetDesc("末日轨道炮已发射！") end })
RailgunSection:Button({ Title = "🎬 影院模式发射 4.2", Callback = function() if not targetPosition then RailgunStatus:SetDesc("请先点击「选择发射目标」选择地点！") return end RailgunStatus:SetDesc("影院模式播放中...") task.spawn(function() playCinematic(targetPosition) RailgunStatus:SetDesc("影院模式完成！") end) end })
RailgunSection:Toggle({ Title = "启用 F 键发射", Value = true, Callback = function(state) Cfg.RailgunKeyBind = state end })
RailgunSection:Slider({ Title = "发射冷却 (秒)", Value = { Min = 0.1, Max = 10, Default = 1.2 }, Step = 0.1, Callback = function(value) Cfg.RailgunCooldown = value end })
RailgunSection:Slider({ Title = "坑洞半径", Value = { Min = 30, Max = 300, Default = 120 }, Step = 10, Callback = function(value) Cfg.RailgunCraterRadius = value end })
RailgunSection:Slider({ Title = "坑洞深度", Value = { Min = 20, Max = 200, Default = 80 }, Step = 10, Callback = function(value) Cfg.RailgunCraterDepth = value end })
RailgunSection:Slider({ Title = "碎石数量", Value = { Min = 0, Max = 400, Default = 200 }, Step = 20, Callback = function(value) Cfg.RailgunDebrisCount = value end })
RailgunSection:Slider({ Title = "屏幕震动强度", Value = { Min = 0, Max = 50, Default = 20 }, Step = 1, Callback = function(value) Cfg.RailgunShakeIntensity = value end })

local TeleportTab = Window:Tab({ Title = "传送", Icon = "send" })
local TPSection = TeleportTab:Section({ Title = "传送玩家", Icon = "user" })
local function GetPlayerList() local list = {} for _, p in ipairs(Players:GetPlayers()) do if p ~= player then table.insert(list, p.Name) end end return list end
local TPStatus = TPSection:Paragraph({ Title = "传送状态", Desc = "待机中..." })
local TPDropdown = TPSection:Dropdown({ Title = "选择在线玩家", Values = GetPlayerList(), Value = "", Multi = false, Callback = function(selected) if type(selected) == "table" then selected = selected[1] end TP.Target = selected or "" Cfg.TeleportTarget = TP.Target end })
TPSection:Button({ Title = "刷新玩家列表", Callback = function() local list = GetPlayerList() pcall(function() TPDropdown:Refresh(list) end) TPStatus:SetDesc("已刷新，共 " .. #list .. " 名玩家") end })
TPSection:Slider({ Title = "传送高度偏移 (Y)", Value = { Min = 0, Max = 20, Default = 3 }, Step = 1, Callback = function(value) Cfg.TeleportOffsetY = value TP.OffsetY = value end })
TPSection:Button({ Title = "传送到目标玩家", Callback = function() if TP.Target == "" then TPStatus:SetDesc("请先选择玩家") return end local ok = TP:ToTarget() if ok then TPStatus:SetDesc("已传送到 " .. TP.Target) else TPStatus:SetDesc("传送失败：找不到目标或角色") end end })
TPSection:Toggle({ Title = "循环锁定传送", Value = false, Callback = function(state) if state then if TP.Target == "" then TPStatus:SetDesc("请先选择玩家") return end TP:StartLoop() TPStatus:SetDesc("循环传送中 -> " .. TP.Target) else TP:StopLoop() TPStatus:SetDesc("已停止循环传送") end end })

local ProtectTab = Window:Tab({ Title = "防护", Icon = "shield" })
local AntiSection = ProtectTab:Section({ Title = "反挂机 / 防踢", Icon = "shield-check" })
AntiSection:Toggle({ Title = "反挂机踢出 (getconnections)", Value = true, Callback = function(state) Cfg.AntiIdleKick = state if state then applyAntiIdleKick() end end })
AntiSection:Toggle({ Title = "防客户端踢出", Value = false, Callback = function(state) Cfg.AntiClientKick = state if state then applyAntiClientKick() end end })
local GroupSection = ProtectTab:Section({ Title = "群组验证", Icon = "users" })
GroupSection:Toggle({ Title = "绕过群组验证", Value = false, Callback = function(state) Cfg.BypassGroup = state if state then applyBypassGroup() end end })

local SG = Instance.new("ScreenGui") SG.Name = "PowerCrownUI" SG.ResetOnSpawn = false SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling SG.IgnoreGuiInset = true
pcall(function() SG.Parent = game:GetService("CoreGui") end) if not SG.Parent then SG.Parent = player.PlayerGui end
local DataHUD = Instance.new("Frame") DataHUD.Size = UDim2.new(0, 210, 0, 105) DataHUD.Position = UDim2.new(0, 20, 0.3, 0) DataHUD.BackgroundColor3 = Color3.fromRGB(20, 24, 34) DataHUD.BackgroundTransparency = 0.1 DataHUD.BorderSizePixel = 0 DataHUD.ZIndex = 500 DataHUD.Parent = SG
corner(DataHUD, 10) stroke(DataHUD, C.accent, 1.5, 0.2)
local HUDTitle = Instance.new("TextLabel") HUDTitle.Size = UDim2.new(1, 0, 0, 24) HUDTitle.BackgroundTransparency = 1 HUDTitle.Text = "📊 力量之冠封存全能版 4.2 · 累计总数据" HUDTitle.TextColor3 = C.accent HUDTitle.Font = Enum.Font.GothamBold HUDTitle.TextSize = 12 HUDTitle.ZIndex = 501 HUDTitle.Parent = DataHUD
local LabelReps = Instance.new("TextLabel") LabelReps.Size = UDim2.new(0.5, -10, 0, 18) LabelReps.Position = UDim2.new(0, 10, 0, 30) LabelReps.BackgroundTransparency = 1 LabelReps.Text = "总训练: 0" LabelReps.TextColor3 = Color3.fromRGB(230, 230, 235) LabelReps.Font = Enum.Font.Gotham LabelReps.TextSize = 11 LabelReps.TextXAlignment = Enum.TextXAlignment.Left LabelReps.ZIndex = 501 LabelReps.Parent = DataHUD
local LabelRebirth = Instance.new("TextLabel") LabelRebirth.Size = UDim2.new(0.5, -10, 0, 18) LabelRebirth.Position = UDim2.new(0, 10, 0, 50) LabelRebirth.BackgroundTransparency = 1 LabelRebirth.Text = "总转生: 0" LabelRebirth.TextColor3 = Color3.fromRGB(230, 230, 235) LabelRebirth.Font = Enum.Font.Gotham LabelRebirth.TextSize = 11 LabelRebirth.TextXAlignment = Enum.TextXAlignment.Left LabelRebirth.ZIndex = 501 LabelRebirth.Parent = DataHUD
local LabelTime = Instance.new("TextLabel") LabelTime.Size = UDim2.new(1, -20, 0, 18) LabelTime.Position = UDim2.new(0, 10, 0, 70) LabelTime.BackgroundTransparency = 1 LabelTime.Text = "总时长: 00:00:00" LabelTime.TextColor3 = Color3.fromRGB(230, 230, 235) LabelTime.Font = Enum.Font.Gotham LabelTime.TextSize = 11 LabelTime.TextXAlignment = Enum.TextXAlignment.Left LabelTime.ZIndex = 501 LabelTime.Parent = DataHUD

local HUDDrag, HUDStart, HUDOrigin = false, nil, nil
DataHUD.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then HUDDrag = true HUDStart = input.Position HUDOrigin = DataHUD.Position input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then HUDDrag = false end end) end end)
UserInputService.InputChanged:Connect(function(input) if HUDDrag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - HUDStart DataHUD.Position = UDim2.new(HUDOrigin.X.Scale, HUDOrigin.X.Offset + delta.X, HUDOrigin.Y.Scale, HUDOrigin.Y.Offset + delta.Y) end end)

local MobileInput = { Forward = false, Back = false, Left = false, Right = false, Up = false, Down = false }
local FlyControls = Instance.new("Frame") FlyControls.Size = UDim2.new(0, 170, 0, 104) FlyControls.Position = UDim2.new(0.5, -85, 1, -120) FlyControls.BackgroundColor3 = Color3.fromRGB(16, 18, 26) FlyControls.BackgroundTransparency = 0.2 FlyControls.Visible = false FlyControls.ZIndex = 30 FlyControls.Parent = SG
corner(FlyControls, 8) stroke(FlyControls, C.accent, 1.2, 0.3)
local function flyButton(text, x, y, color) local b = Instance.new("TextButton") b.Size = UDim2.new(0, 34, 0, 34) b.Position = UDim2.new(0, x, 0, y) b.BackgroundColor3 = Color3.fromRGB(32, 32, 38) b.Text = text b.TextColor3 = color or C.accent b.Font = Enum.Font.GothamBold b.TextSize = 14 b.AutoButtonColor = false b.BorderSizePixel = 0 b.ZIndex = 31 b.Parent = FlyControls corner(b, 6) return b end
local BtnUp = flyButton("▲", 42, 4, C.accent) local BtnDown = flyButton("▼", 42, 66, Color3.fromRGB(180, 120, 255)) local BtnLeft = flyButton("◀", 4, 35, C.accent) local BtnRight = flyButton("▶", 80, 35, C.accent) local BtnRise = flyButton("＋", 118, 4, C.green) local BtnFall = flyButton("－", 118, 66, C.red)
local function bindHold(btn, key) local function set(v) MobileInput[key] = v TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = v and 0.6 or 0}):Play() end btn.MouseButton1Down:Connect(function() set(true) end) btn.MouseButton1Up:Connect(function() set(false) end) btn.MouseLeave:Connect(function() set(false) end) end
bindHold(BtnUp, "Forward") bindHold(BtnDown, "Back") bindHold(BtnLeft, "Left") bindHold(BtnRight, "Right") bindHold(BtnRise, "Up") bindHold(BtnFall, "Down")

local flying, flyBV, flyBG = false, nil, nil
local startFly, stopFly, applyWalkSpeed
applyWalkSpeed = function() local char = player.Character if not char then return end local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.WalkSpeed = Cfg.WalkSpeed end end
startFly = function()
    if flying then return end
    local char = player.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp then return end
    local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.PlatformStand = true end
    flyBV = Instance.new("BodyVelocity") flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5) flyBV.Velocity = Vector3.zero flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro") flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5) flyBG.P = 3000 flyBG.D = 500 flyBG.Parent = hrp
    flying = true
end
stopFly = function()
    if not flying then return end
    flying = false
    for k in pairs(MobileInput) do MobileInput[k] = false end
    local char = player.Character
    if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.PlatformStand = false end end
    if flyBV then flyBV:Destroy(); flyBV = nil end if flyBG then flyBG:Destroy(); flyBG = nil end
    applyWalkSpeed()
end

RunService.RenderStepped:Connect(function()
    if not Cfg.Fly then if flying then stopFly() end FlyControls.Visible = false return end
    FlyControls.Visible = true
    if not flying then startFly() return end
    local char = player.Character if not char then stopFly() return end
    local hrp = char:FindFirstChild("HumanoidRootPart") if not hrp or not flyBV or not flyBG then return end
    local cam = workspace.CurrentCamera local dir = Vector3.zero
    local fwd = UserInputService:IsKeyDown(Enum.KeyCode.W) or MobileInput.Forward
    local bck = UserInputService:IsKeyDown(Enum.KeyCode.S) or MobileInput.Back
    local lft = UserInputService:IsKeyDown(Enum.KeyCode.A) or MobileInput.Left
    local rgt = UserInputService:IsKeyDown(Enum.KeyCode.D) or MobileInput.Right
    local up = UserInputService:IsKeyDown(Enum.KeyCode.Space) or MobileInput.Up
    local dn = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or MobileInput.Down
    if fwd then dir = dir + cam.CFrame.LookVector end if bck then dir = dir - cam.CFrame.LookVector end
    if lft then dir = dir - cam.CFrame.RightVector end if rgt then dir = dir + cam.CFrame.RightVector end
    if up then dir = dir + Vector3.new(0, 1, 0) end if dn then dir = dir - Vector3.new(0, 1, 0) end
    if dir.Magnitude > 0 then dir = dir.Unit * Cfg.FlySpeed end
    flyBV.Velocity = dir flyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cam.CFrame.LookVector)
end)

player.CharacterAdded:Connect(function(char) task.wait(0.5) applyWalkSpeed() if flying then stopFly() end end)

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
                RailgunStatus:SetDesc("目标已选定！点击「立即发射」或按 F 键") isTargeting = false
            else RailgunStatus:SetDesc("未检测到地面，请重新点击「选择发射目标」") end
        end
        return
    end
    if input.KeyCode == Enum.KeyCode.F and Cfg.RailgunKeyBind then if targetPosition then executeRailgunStrike(targetPosition) end end
end)

task.spawn(function()
    local storeEvent
    pcall(function() storeEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("StoreEvent") end)
    while true do
        task.wait(Cfg.EggInterval)
        if Cfg.AutoPetEgg and storeEvent then pcall(function() storeEvent:FireServer("Egg", Cfg.PetEggQty, Cfg.EggCurrency, Cfg.PetEggName) PetStatus:SetDesc("正在抽: " .. Cfg.PetEggName .. " x" .. Cfg.PetEggQty) end) else PetStatus:SetDesc("待机中") end
        if Cfg.AutoHaloEgg and storeEvent then pcall(function() storeEvent:FireServer("Egg", Cfg.HaloEggQty, Cfg.EggCurrency, Cfg.HaloEggName) HaloStatus:SetDesc("正在抽: " .. Cfg.HaloEggName .. " x" .. Cfg.HaloEggQty) end) else HaloStatus:SetDesc("待机中") end
    end
end)

task.spawn(function()
    local trainEvent
    pcall(function() trainEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TrainEvent") end)
    while true do
        task.wait(Cfg.TrainInterval)
        if Cfg.AutoTrain and trainEvent then pcall(function() trainEvent:FireServer(Cfg.TrainAction) Cfg.TotalReps = Cfg.TotalReps + 1 TrainStatus:SetDesc("正在锻炼: " .. Cfg.TrainActionCN) end) else TrainStatus:SetDesc("待机中") end
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
    local rebirthEvent
    pcall(function() rebirthEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RebirthEvent") end)
    while true do
        task.wait(Cfg.RebirthCheckInterval)
        if Cfg.AutoRebirth and rebirthEvent and not Cfg.InfiniteRebirth then
            pcall(function()
                local gameRebirths = getCurrentRebirths()
                if gameRebirths >= Cfg.TargetRebirthCount then Cfg.AutoRebirth = false RebirthStatus:SetDesc("已完成 " .. gameRebirths .. " 次重生，已停止") return end
                local currentStr = getCurrentStrength()
                if currentStr >= Cfg.TargetStrength then
                    rebirthEvent:FireServer("Update") Cfg.TargetStrength = Cfg.TargetStrength + Cfg.RebirthInc
                    RebirthStatus:SetDesc("进度: " .. gameRebirths .. "/" .. Cfg.TargetRebirthCount .. " | 目标力量: " .. Cfg.TargetStrength) task.wait(Cfg.RebirthCooldown)
                else RebirthStatus:SetDesc("力量: " .. math.floor(currentStr) .. "/" .. Cfg.TargetStrength .. " | 重生: " .. gameRebirths .. "/" .. Cfg.TargetRebirthCount) end
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
                local currentStr = getCurrentStrength() local gameRebirths = getCurrentRebirths()
                if currentStr >= Cfg.BaseStrength then
                    rebirthEvent:FireServer("Update") InfiniteStatus:SetDesc("正在重生... 已重生 " .. gameRebirths .. " 次") task.wait(Cfg.RebirthCooldown)
                else InfiniteStatus:SetDesc("力量: " .. math.floor(currentStr) .. "/" .. Cfg.BaseStrength .. " | 已重生: " .. gameRebirths .. " 次") end
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
                VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, true, false, game) task.wait(0.05)
                VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, false, false, game)
            end)
        end
    end
end)

task.spawn(function()
    while SG.Parent do
        local elapsedTime = tick() - Cfg.ScriptStartTime
        local hours = math.floor(elapsedTime / 3600) local mins = math.floor((elapsedTime % 3600) / 60) local secs = math.floor(elapsedTime % 60)
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
            VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, true, false, game) task.wait(0.05)
            VirtualInputManager:SendKeyEvent(Enum.KeyCode.Space, false, false, game)
        end)
    end
end)

applyWalkSpeed()
if Cfg.AntiIdleKick then applyAntiIdleKick() end

print("[力量之冠封存全能版 4.2 · 影院模式轨道炮已就绪]")