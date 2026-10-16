local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"))()
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Cfg = {
    RailgunKeyBind = true, RailgunCooldown = 1.2, RailgunCraterRadius = 60,
    RailgunCraterDepth = 40, RailgunDebrisCount = 100, RailgunShakeIntensity = 12, RailgunShakeDuration = 3,
}

local function newEffectPart(shape, material, color, transparency)
    local p = Instance.new("Part")
    p.Shape = shape p.Material = material p.Color = color p.Transparency = transparency or 0
    p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false p.CastShadow = false
    p.TopSurface = Enum.SurfaceType.Smooth p.BottomSurface = Enum.SurfaceType.Smooth
    return p
end

local targetPosition = nil
local isTargeting = false
local targetMarker = nil
local originalLighting = { Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogColor = Lighting.FogColor, FogEnd = Lighting.FogEnd, FogStart = Lighting.FogStart }
local savedSky = nil

local function enterSpaceMode()
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if sky then savedSky = sky sky.Parent = nil end
    Lighting.FogColor = Color3.new(0, 0, 0)
    Lighting.FogEnd = 100000
    Lighting.FogStart = 100000
    Lighting.Ambient = Color3.new(0, 0, 0)
    Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
    Lighting.Brightness = 0
    Lighting.ClockTime = 0
end

local function exitSpaceMode()
    if savedSky then savedSky.Parent = Lighting savedSky = nil end
    Lighting.FogColor = originalLighting.FogColor
    Lighting.FogEnd = originalLighting.FogEnd
    Lighting.FogStart = originalLighting.FogStart
    Lighting.Ambient = originalLighting.Ambient
    Lighting.OutdoorAmbient = originalLighting.OutdoorAmbient
    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
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

local function createLaserFromSky(targetPos)
    local beamHeight = 220 local beamWidth = 35
    local beam = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(255, 180, 50), 0.05)
    beam.Size = Vector3.new(beamHeight, beamWidth, beamWidth)
    beam.CFrame = CFrame.new(targetPos + Vector3.new(0, beamHeight / 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
    beam.Parent = workspace
    local beamLight = Instance.new("PointLight") beamLight.Color = Color3.fromRGB(255, 100, 20) beamLight.Range = 120 beamLight.Brightness = 25 beamLight.Parent = beam
    for i = 0, 35 do
        local orb = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 150, 50), 0.1)
        orb.Size = Vector3.new(55, 55, 55)
        orb.Position = targetPos + Vector3.new(math.random(-3, 3), i * 6, math.random(-3, 3))
        orb.Parent = workspace
        Debris:AddItem(orb, 3)
    end
    for i = 1, 25 do
        task.spawn(function()
            task.wait(math.random(0, 10) / 10)
            local angle = math.random() * math.pi * 2 local dist = math.random(0, 60)
            local drop = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 60, 0), 0)
            drop.Size = Vector3.new(math.random(8, 15), math.random(8, 15), math.random(8, 15))
            drop.Position = targetPos + Vector3.new(math.cos(angle) * dist, 150, math.sin(angle) * dist)
            drop.Parent = workspace
            TweenService:Create(drop, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = targetPos + Vector3.new(math.cos(angle) * dist * 0.5, 0, math.sin(angle) * dist * 0.5), Size = Vector3.new(4, 4, 4), Transparency = 0.5 }):Play()
            Debris:AddItem(drop, 1)
        end)
    end
    task.delay(1.5, function() if beam and beam.Parent then TweenService:Create(beam, TweenInfo.new(0.6), { Transparency = 1, Size = Vector3.new(beamHeight, beamWidth * 2, beamWidth * 2) }):Play() Debris:AddItem(beam, 0.7) end end)
end

local function spawnNuclearCrater(hitPosition)
    local craterRadius = Cfg.RailgunCraterRadius local craterDepth = Cfg.RailgunCraterDepth
    pcall(function()
        local terrain = workspace.Terrain
        terrain:FillBall(hitPosition, craterRadius, Enum.Material.Air)
        terrain:FillBall(hitPosition - Vector3.new(0, craterDepth * 0.4, 0), craterRadius * 0.8, Enum.Material.Air)
        terrain:FillBall(hitPosition - Vector3.new(0, craterDepth * 0.8, 0), craterRadius * 0.5, Enum.Material.Air)
        terrain:FillBall(hitPosition - Vector3.new(0, craterDepth * 0.85, 0), craterRadius * 0.6, Enum.Material.CrackedLava)
        for i = 1, 30 do
            local a = (i / 30) * math.pi * 2
            local dist = craterRadius * (0.9 + math.random() * 0.3)
            terrain:FillBall(hitPosition + Vector3.new(math.cos(a) * dist, math.random(-2, 0), math.sin(a) * dist), math.random(6, 12), Enum.Material.Basalt)
        end
    end)
    local lavaCenter = hitPosition - Vector3.new(0, craterDepth * 0.75, 0)
    local lavaBase = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 60, 0), 0)
    lavaBase.Size = Vector3.new(craterRadius * 1.6, 6, craterRadius * 1.6) lavaBase.Position = lavaCenter lavaBase.Parent = workspace
    local lavaLight = Instance.new("PointLight") lavaLight.Color = Color3.fromRGB(255, 60, 0) lavaLight.Range = craterRadius * 3 lavaLight.Brightness = 10 lavaLight.Parent = lavaBase
    Debris:AddItem(lavaBase, 180)
    for i = 1, 60 do
        local angle = math.random() * math.pi * 2 local r = math.random() * craterRadius * 0.85
        local crack = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(255, 30, 0), 0)
        crack.Size = Vector3.new(math.random(4, 10), 8, math.random(15, 30))
        crack.CFrame = CFrame.new(lavaCenter + Vector3.new(math.cos(angle) * r, 3, math.sin(angle) * r)) * CFrame.Angles(0, angle + math.random(-0.8, 0.8), 0)
        crack.Parent = workspace
        Debris:AddItem(crack, 180)
    end
    for i = 1, 80 do
        task.spawn(function()
            task.wait(math.random(0, 15) / 10)
            local splash = Instance.new("Part")
            splash.Shape = Enum.PartType.Ball
            splash.Material = Enum.Material.Neon
            splash.Color = Color3.fromRGB(255, 80, 0)
            splash.Size = Vector3.new(math.random(5, 15), math.random(5, 15), math.random(5, 15))
            splash.Anchored = false splash.CanCollide = true splash.CanQuery = false
            splash.Position = hitPosition + Vector3.new(math.random(-20, 20), math.random(5, 25), math.random(-20, 20))
            splash.Parent = workspace
            splash.AssemblyLinearVelocity = Vector3.new(math.random(-100, 100), math.random(60, 150), math.random(-100, 100))
            splash.AssemblyAngularVelocity = Vector3.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
            Debris:AddItem(splash, 10)
        end)
    end
    for i = 1, 30 do
        task.spawn(function()
            task.wait(math.random(0, 4) / 10)
            local angle = (i / 30) * math.pi * 2 + math.random(-0.2, 0.2)
            local dist = craterRadius * (0.9 + math.random(-0.1, 0.15))
            local x = math.cos(angle) * dist local z = math.sin(angle) * dist
            local height = math.random(60, 150) local width = math.random(15, 30)
            local outwardDir = Vector3.new(x, 0, z).Unit
            local tiltRad = math.rad(5 + math.random() * 20)
            local upVector = (Vector3.new(0, 1, 0) + outwardDir * math.tan(tiltRad)).Unit
            local model = Instance.new("Model") model.Name = "RockSpike"
            local mat = Enum.Material.Slate local col = Color3.fromRGB(40, 40, 40) local parts = {}
            local bottom = newEffectPart(Enum.PartType.Block, mat, col, 0)
            bottom.Size = Vector3.new(width, height * 0.6, width)
            bottom.CFrame = CFrame.lookAt(hitPosition + Vector3.new(x, -height * 1.5, z) + upVector * (height * 0.3), hitPosition + Vector3.new(x, -height * 1.5, z) + upVector * (height * 0.3) + upVector)
            bottom.Parent = model table.insert(parts, bottom)
            local mid = newEffectPart(Enum.PartType.Block, mat, col, 0)
            mid.Size = Vector3.new(width * 0.8, height * 0.5, width * 0.8)
            mid.CFrame = CFrame.lookAt(hitPosition + Vector3.new(x, -height * 1.5, z) + upVector * (height * 0.8), hitPosition + Vector3.new(x, -height * 1.5, z) + upVector * (height * 0.8) + upVector)
            mid.Parent = model table.insert(parts, mid)
            local tip = newEffectPart(Enum.PartType.Block, mat, col, 0)
            tip.Size = Vector3.new(width * 0.4, height * 0.4, width * 0.4)
            tip.CFrame = CFrame.lookAt(hitPosition + Vector3.new(x, -height * 1.5, z) + upVector * (height * 1.2), hitPosition + Vector3.new(x, -height * 1.5, z) + upVector * (height * 1.2) + upVector)
            tip.Parent = model table.insert(parts, tip)
            model.PrimaryPart = bottom model.Parent = workspace
            local targetPos = hitPosition + Vector3.new(x, height * 0.15, z)
            for _, part in ipairs(parts) do
                local offset = targetPos - (hitPosition + Vector3.new(x, -height * 1.5, z))
                TweenService:Create(part, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = part.CFrame + offset }):Play()
            end
            Debris:AddItem(model, 180)
        end)
    end
    for i = 1, Cfg.RailgunDebrisCount do
        task.spawn(function()
            task.wait(math.random(0, 10) / 10)
            local size = math.random(20, 60) / 10
            local rock = Instance.new("Part")
            rock.Shape = Enum.PartType.Block
            rock.Material = Enum.Material.Slate
            rock.Color = Color3.fromRGB(50, 50, 50)
            rock.Size = Vector3.new(size, size, size)
            rock.Anchored = false rock.CanCollide = true rock.CanQuery = false
            local angle = math.random() * math.pi * 2 local dist = craterRadius * (0.8 + math.random() * 0.4)
            rock.Position = hitPosition + Vector3.new(math.cos(angle) * dist, math.random(5, 20), math.sin(angle) * dist)
            rock.CFrame = CFrame.new(rock.Position) * CFrame.Angles(math.random() * math.pi * 2, math.random() * math.pi * 2, math.random() * math.pi * 2)
            rock.Parent = workspace
            local dirToCenter = (Vector3.new(hitPosition.X, rock.Position.Y, hitPosition.Z) - rock.Position).Unit
            rock.AssemblyLinearVelocity = dirToCenter * math.random(3, 8) + Vector3.new(0, math.random(5, 15), 0)
            rock.AssemblyAngularVelocity = Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
            task.spawn(function()
                for _ = 1, 100 do
                    if not rock or not rock.Parent then break end
                    local currentDir = (Vector3.new(hitPosition.X, rock.Position.Y, hitPosition.Z) - rock.Position).Unit
                    rock.AssemblyLinearVelocity = Vector3.new(currentDir.X * 5, rock.AssemblyLinearVelocity.Y, currentDir.Z * 5)
                    task.wait(0.1)
                end
            end)
            Debris:AddItem(rock, 30)
        end)
    end
    task.spawn(function()
        for _ = 1, 100 do
            task.wait(0.2)
            local angle = math.random() * math.pi * 2 local r = math.random() * craterRadius * 0.8
            local glow = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 100, 20), 0)
            glow.Size = Vector3.new(math.random(4, 12), math.random(4, 12), math.random(4, 12))
            glow.Position = lavaCenter + Vector3.new(math.cos(angle) * r, math.random(0, 5), math.sin(angle) * r)
            glow.Anchored = false glow.CanCollide = false glow.Parent = workspace
            glow.AssemblyLinearVelocity = Vector3.new(math.random(-30, 30), math.random(20, 60), math.random(-30, 30))
            Debris:AddItem(glow, 3)
        end
    end)
    local smokeHolder = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.new(1,1,1), 1)
    smokeHolder.Size = Vector3.new(2, 2, 2) smokeHolder.Position = hitPosition + Vector3.new(0, 30, 0) smokeHolder.Parent = workspace
    local smoke = Instance.new("Smoke") smoke.Color = Color3.fromRGB(40, 40, 40) smoke.Opacity = 0.8 smoke.RiseVelocity = 35 smoke.Size = 40 smoke.Parent = smokeHolder
    local smokeCap = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.new(1,1,1), 1)
    smokeCap.Size = Vector3.new(2, 2, 2) smokeCap.Position = hitPosition + Vector3.new(0, 150, 0) smokeCap.Parent = workspace
    local smoke2 = Instance.new("Smoke") smoke2.Color = Color3.fromRGB(30, 30, 30) smoke2.Opacity = 0.9 smoke2.RiseVelocity = 20 smoke2.Size = 100 smoke2.Parent = smokeCap
    task.delay(40, function() if smoke then smoke.Enabled = false end if smoke2 then smoke2.Enabled = false end end)
    Debris:AddItem(smokeHolder, 45) Debris:AddItem(smokeCap, 45)
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
        setDoomsdaySky(true) createLaserFromSky(targetPos)
        screenShake(Cfg.RailgunShakeIntensity, Cfg.RailgunShakeDuration) task.wait(1.2)
        spawnNuclearCrater(targetPos) task.wait(30) setDoomsdaySky(false)
    end)
end

local function createSpaceEnvironment(origin)
    local folder = Instance.new("Folder") folder.Name = "CinematicSpace" folder.Parent = workspace
    
    local sunPos = origin
    local sun = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 220, 80), 0)
    sun.Size = Vector3.new(1200, 1200, 1200) sun.Position = sunPos sun.Parent = folder
    local sunGlow = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 120, 0), 0.5)
    sunGlow.Size = Vector3.new(1600, 1600, 1600) sunGlow.Position = sunPos sunGlow.Parent = folder
    local sunLight = Instance.new("PointLight") sunLight.Color = Color3.fromRGB(255, 220, 100) sunLight.Range = 30000 sunLight.Brightness = 20 sunLight.Parent = sun

    local mercury = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(170, 160, 150), 0)
    mercury.Size = Vector3.new(180, 180, 180) mercury.Position = origin + Vector3.new(2500, 0, 1000) mercury.Parent = folder
    local venus = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(240, 200, 130), 0)
    venus.Size = Vector3.new(280, 280, 280) venus.Position = origin + Vector3.new(-3500, 500, -1800) venus.Parent = folder

    local earthPos = origin + Vector3.new(5000, 0, 2500)
    local ocean = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(30, 100, 180), 0)
    ocean.Size = Vector3.new(600, 600, 600) ocean.Position = earthPos ocean.Parent = folder
    local atmosphere = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(100, 180, 255), 0.85)
    atmosphere.Size = Vector3.new(650, 650, 650) atmosphere.Position = earthPos atmosphere.Parent = folder
    for i = 1, 25 do
        local land = newEffectPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, Color3.fromRGB(60, 140, 60), 0)
        land.Size = Vector3.new(math.random(80, 180), math.random(50, 100), math.random(80, 180))
        local a = math.random() * math.pi * 2 local d = 250
        land.Position = earthPos + Vector3.new(math.cos(a) * d, math.random(-180, 180), math.sin(a) * d)
        land.CFrame = CFrame.new(land.Position) * CFrame.Angles(math.random() * math.pi, math.random() * math.pi, math.random() * math.pi)
        land.Parent = folder
    end
    for i = 1, 15 do
        local cloud = newEffectPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, Color3.new(1,1,1), 0.4)
        cloud.Size = Vector3.new(math.random(80, 160), math.random(40, 80), math.random(80, 160))
        local a = math.random() * math.pi * 2 local d = 280
        cloud.Position = earthPos + Vector3.new(math.cos(a) * d, math.random(-150, 150), math.sin(a) * d)
        cloud.Parent = folder
    end
    local moon = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(180, 180, 180), 0)
    moon.Size = Vector3.new(120, 120, 120) moon.Position = earthPos + Vector3.new(900, 200, 400) moon.Parent = folder

    local marsPos = origin + Vector3.new(9000, -500, 5000)
    local mars = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(200, 90, 50), 0)
    mars.Size = Vector3.new(400, 400, 400) mars.Position = marsPos mars.Parent = folder
    for i = 1, 12 do
        local crater = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(140, 50, 20), 0)
        crater.Size = Vector3.new(math.random(40, 90), math.random(40, 90), math.random(40, 90))
        local a = math.random() * math.pi * 2 local d = 170
        crater.Position = marsPos + Vector3.new(math.cos(a) * d, math.random(-140, 140), math.sin(a) * d)
        crater.Parent = folder
    end

    local jupiterPos = origin + Vector3.new(-8000, 800, 7000)
    local jupiter = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(220, 180, 140), 0)
    jupiter.Size = Vector3.new(900, 900, 900) jupiter.Position = jupiterPos jupiter.Parent = folder
    for i = 1, 8 do
        local band = newEffectPart(Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Color3.fromRGB(170, 120, 80), 0.2)
        band.Size = Vector3.new(20, 900, 900)
        band.CFrame = CFrame.new(jupiterPos + Vector3.new(0, (i - 4.5) * 100, 0)) * CFrame.Angles(0, 0, math.rad(90))
        band.Parent = folder
    end
    local redSpot = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(220, 80, 60), 0)
    redSpot.Size = Vector3.new(220, 150, 120) redSpot.Position = jupiterPos + Vector3.new(450, -80, 300) redSpot.Parent = folder

    local saturnPos = origin + Vector3.new(-15000, -1000, -12000)
    local saturn = newEffectPart(Enum.PartType.Ball, Enum.Material.SmoothPlastic, Color3.fromRGB(230, 210, 160), 0)
    saturn.Size = Vector3.new(700, 700, 700) saturn.Position = saturnPos saturn.Parent = folder
    for i = 1, 6 do
        local ring = newEffectPart(Enum.PartType.Cylinder, Enum.Material.SmoothPlastic, Color3.fromRGB(210 + i * 5, 190 + i * 5, 140 + i * 5), 0.15)
        ring.Size = Vector3.new(15, 1000 + i * 150, 1000 + i * 150)
        ring.CFrame = CFrame.new(saturnPos) * CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(25), 0, 0)
        ring.Parent = folder
    end

    for i = 1, 1500 do
        local angle = math.random() * math.pi * 2
        local phi = math.acos(2 * math.random() - 1)
        local dist = 15000 + math.random() * 40000
        local starPos = origin + Vector3.new(dist * math.sin(phi) * math.cos(angle), dist * math.cos(phi), dist * math.sin(phi) * math.sin(angle))
        local star = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(255, 255, 255), 0)
        local starSize = math.random(15, 40)
        star.Size = Vector3.new(starSize, starSize, starSize)
        star.Position = starPos
        star.Parent = folder
    end

    for i = 1, 100 do
        local angle = math.random() * math.pi * 2
        local dist = 3000 + math.random() * 15000
        local height = math.random(-5000, 5000)
        local rock = newEffectPart(Enum.PartType.Block, Enum.Material.Slate, Color3.fromRGB(math.random(50, 100), math.random(50, 100), math.random(50, 100)), 0)
        local s = math.random(80, 400)
        rock.Size = Vector3.new(s, s * (0.5 + math.random()), s * (0.5 + math.random()))
        rock.Position = origin + Vector3.new(math.cos(angle) * dist, height, math.sin(angle) * dist)
        rock.CFrame = CFrame.new(rock.Position) * CFrame.Angles(math.random() * math.pi, math.random() * math.pi, math.random() * math.pi)
        rock.Parent = folder
    end
    return folder, earthPos, sunPos, mercury.Position, venus.Position, marsPos, jupiterPos, saturnPos
end

local function createSpaceStationRailgun(earthPos)
    local folder = Instance.new("Folder") folder.Name = "SpaceStationRailgun" folder.Parent = workspace
    local gunBase = earthPos + Vector3.new(0, 1500, 0)
    local core = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(90, 95, 105), 0)
    core.Size = Vector3.new(1200, 250, 250) core.CFrame = CFrame.new(gunBase) * CFrame.Angles(0, 0, math.rad(90)) core.Parent = folder
    local ring1 = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(60, 65, 75), 0)
    ring1.Size = Vector3.new(80, 400, 400) ring1.CFrame = CFrame.new(gunBase + Vector3.new(600, 0, 0)) * CFrame.Angles(0, 0, math.rad(90)) ring1.Parent = folder
    local ring2 = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(60, 65, 75), 0)
    ring2.Size = Vector3.new(60, 350, 350) ring2.CFrame = CFrame.new(gunBase + Vector3.new(500, 0, 0)) * CFrame.Angles(0, 0, math.rad(90)) ring2.Parent = folder
    local mount = newEffectPart(Enum.PartType.Block, Enum.Material.Metal, Color3.fromRGB(50, 55, 65), 0)
    mount.Size = Vector3.new(250, 700, 250) mount.Position = gunBase + Vector3.new(0, -450, 0) mount.Parent = folder
    local barrel = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Metal, Color3.fromRGB(40, 45, 55), 0)
    barrel.Size = Vector3.new(1800, 180, 180) barrel.CFrame = CFrame.new(gunBase + Vector3.new(0, -1100, 0)) * CFrame.Angles(0, 0, math.rad(90)) barrel.Parent = folder
    local muzzle = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(80, 160, 255), 0.3)
    muzzle.Size = Vector3.new(350, 350, 350) muzzle.Position = gunBase + Vector3.new(0, -2000, 0) muzzle.Parent = folder
    for _, side in ipairs({-1, 1}) do
        local panelHolder = newEffectPart(Enum.PartType.Block, Enum.Material.Metal, Color3.fromRGB(60, 60, 60), 0)
        panelHolder.Size = Vector3.new(40, 150, 800) panelHolder.Position = gunBase + Vector3.new(0, 0, side * 800) panelHolder.Parent = folder
        for i = 1, 5 do
            local panel = newEffectPart(Enum.PartType.Block, Enum.Material.SmoothPlastic, Color3.fromRGB(20, 80, 160), 0.1)
            panel.Size = Vector3.new(30, 350, 280) panel.Position = gunBase + Vector3.new(0, 0, side * (700 + i * 220)) panel.Parent = folder
            local panelLine = newEffectPart(Enum.PartType.Block, Enum.Material.Neon, Color3.fromRGB(100, 200, 255), 0.2)
            panelLine.Size = Vector3.new(35, 350, 8) panelLine.Position = panel.Position + Vector3.new(0, 0, -side * 140) panelLine.Parent = folder
        end
    end
    local charge = newEffectPart(Enum.PartType.Ball, Enum.Material.Neon, Color3.fromRGB(150, 220, 255), 0)
    charge.Size = Vector3.new(80, 80, 80) charge.Position = muzzle.Position charge.Parent = folder
    local chargeLight = Instance.new("PointLight") chargeLight.Color = Color3.fromRGB(150, 220, 255) chargeLight.Range = 3000 chargeLight.Brightness = 15 chargeLight.Parent = charge
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
    
    camera.CFrame = CFrame.new(sunPos + Vector3.new(3000, 1000, 3000), sunPos)
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
    
    cameraMoveTo(camera.CFrame, CFrame.new(sunPos + Vector3.new(-2000, 500, 4000), sunPos), 2) task.wait(2)
    cameraMoveTo(camera.CFrame, CFrame.new(saturnPos + Vector3.new(1500, 800, 2000), saturnPos), 2) task.wait(2)
    cameraMoveTo(camera.CFrame, CFrame.new(marsPos + Vector3.new(-1500, 500, 1800), marsPos), 2) task.wait(2)
    cameraMoveTo(camera.CFrame, CFrame.new(jupiterPos + Vector3.new(2000, 1200, 3000), jupiterPos), 2) task.wait(2)
    cameraMoveTo(camera.CFrame, CFrame.new(earthPos + Vector3.new(2000, 1500, 3000), earthPos), 2) task.wait(2)
    
    local closeUpCF = CFrame.new(muzzlePos + Vector3.new(0, 400, 1200), muzzlePos)
    cameraMoveTo(camera.CFrame, closeUpCF, 2)
    task.wait(2)
    
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
    beamFromGun.Size = Vector3.new(dist, 300, 300)
    beamFromGun.CFrame = CFrame.new(muzzlePos + dir * dist / 2, earthPos) * CFrame.Angles(0, math.rad(90), 0)
    beamFromGun.Parent = workspace
    Debris:AddItem(beamFromGun, 1.5)
    task.wait(0.5)
    
    TweenService:Create(blackFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
    task.wait(0.25)
    
    stationFolder:Destroy()
    spaceFolder:Destroy()
    
    exitSpaceMode()
    
    camera.CameraType = oldCameraType
    if oldSubject then camera.CameraSubject = oldSubject end
    
    local skyBeamStart = targetPos + Vector3.new(2500, 1500, 2500)
    local skyBeamDir = (targetPos - skyBeamStart).Unit
    local skyBeamDist = (targetPos - skyBeamStart).Magnitude
    local skyBeam = newEffectPart(Enum.PartType.Cylinder, Enum.Material.Neon, Color3.fromRGB(255, 200, 100), 0.1)
    skyBeam.Size = Vector3.new(skyBeamDist, 150, 150)
    skyBeam.CFrame = CFrame.new(skyBeamStart + skyBeamDir * skyBeamDist / 2, targetPos) * CFrame.Angles(0, math.rad(90), 0)
    skyBeam.Parent = workspace
    
    TweenService:Create(blackFrame, TweenInfo.new(0.7), { BackgroundTransparency = 1 }):Play()
    task.wait(0.35)
    
    TweenService:Create(skyBeam, TweenInfo.new(0.6), { Size = Vector3.new(skyBeamDist, 300, 300) }):Play()
    task.wait(0.6)
    
    setDoomsdaySky(true)
    screenShake(Cfg.RailgunShakeIntensity * 2, 2)
    spawnNuclearCrater(targetPos)
    
    TweenService:Create(skyBeam, TweenInfo.new(1.5), { Transparency = 1 }):Play()
    Debris:AddItem(skyBeam, 2)
    
    task.wait(15)
    setDoomsdaySky(false)
    
    TweenService:Create(topBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 0) }):Play()
    TweenService:Create(bottomBar, TweenInfo.new(0.6), { Size = UDim2.new(1, 0, 0, 0) }):Play()
    task.wait(0.6)
    blackFrame:Destroy()
    blackoutGui:Destroy()
    letterboxGui:Destroy()
end

local Window = WindUI:CreateWindow({ Title = "力量之冠封存全能版 3.1", Icon = "zap", Author = "力量之冠", Folder = "PowerCrownSave", Theme = "Dark", Transparent = true, Resizable = false, Size = UDim2.fromOffset(460, 780) })
local FunTab = Window:Tab({ Title = "娱乐区", Icon = "sparkles" })
local RailgunSection = FunTab:Section({ Title = "末日轨道炮", Icon = "zap" })
local RailgunStatus = RailgunSection:Paragraph({ Title = "轨道炮状态", Desc = "请先点击「选择发射目标」选择地点" })
RailgunSection:Button({ Title = "选择发射目标", Callback = function() isTargeting = true RailgunStatus:SetDesc("请在游戏画面中点击地面选择目标...") end })
RailgunSection:Button({ Title = "立即发射", Callback = function() if not targetPosition then RailgunStatus:SetDesc("请先点击「选择发射目标」选择地点！") return end executeRailgunStrike(targetPosition) RailgunStatus:SetDesc("末日轨道炮已发射！") end })
RailgunSection:Button({ Title = "🎬 影院模式发射 3.1", Callback = function() if not targetPosition then RailgunStatus:SetDesc("请先点击「选择发射目标」选择地点！") return end RailgunStatus:SetDesc("影院模式播放中...") task.spawn(function() playCinematic(targetPosition) RailgunStatus:SetDesc("影院模式完成！") end) end })
RailgunSection:Slider({ Title = "坑洞半径", Value = { Min = 20, Max = 150, Default = 60 }, Step = 5, Callback = function(value) Cfg.RailgunCraterRadius = value end })
RailgunSection:Slider({ Title = "坑洞深度", Value = { Min = 10, Max = 100, Default = 40 }, Step = 5, Callback = function(value) Cfg.RailgunCraterDepth = value end })
RailgunSection:Slider({ Title = "碎石数量", Value = { Min = 0, Max = 200, Default = 100 }, Step = 10, Callback = function(value) Cfg.RailgunDebrisCount = value end })
RailgunSection:Slider({ Title = "屏幕震动强度", Value = { Min = 0, Max = 40, Default = 12 }, Step = 1, Callback = function(value) Cfg.RailgunShakeIntensity = value end })

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if isTargeting then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if targetMarker then targetMarker:Destroy() end
            local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = { player.Character }
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

print("[力量之冠封存全能版 3.1 · 影院模式轨道炮已就绪]")