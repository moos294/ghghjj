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

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/download/1.6.66/main.lua"))()

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
    ScriptStartTime = tick(), RailgunKeyBind = true,
    AntiIdleKick = true, AntiClientKick = false, BypassGroup = false,
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

local COOLDOWN = 30
local DANGER_RADIUS = 480
local CRATER_RADIUS = 480
local CRATER_DEPTH = 185
local RIM_WIDTH = 190
local RIM_HEIGHT = 96
local CELL = 12
local KILL_RADIUS = 520
local BLAST_RADIUS = 1500
local ROCK_COUNT = 260
local SPIRE_COUNT = 22
local BLAST_PARTS = true
local RESTORE_AFTER = 120
local SPACE_ORIGIN = Vector3.new(0, 300000, 0)
local EARTH_RADIUS = 80
local GALAXY_RADIUS = 34000
local SUN_RADIUS = 1400
local EARTH_ORBIT_RADIUS = 3600

local T = { lockEnd = 2, ascentEnd = 6, orbitEnd = 9.5, pullEnd = 12.5, holdEnd = 13.5, swoopEnd = 17, fireT = 21.5, groundT = 23.4, imp = 25, endT = 32 }

local ASSET_ROOT = "SpaceCannon_OriginalAssets/"
local function loadLocalAsset(relativePath)
	local getter
	pcall(function() getter = getcustomasset or getsynasset or (syn and syn.getcustomasset) end)
	if type(getter) ~= "function" then return nil end
	local path = ASSET_ROOT .. relativePath
	local existsFn
	pcall(function() existsFn = isfile end)
	if type(existsFn) == "function" then
		local okExists, exists = pcall(existsFn, path)
		if okExists and not exists then return nil end
	end
	local ok, uri = pcall(getter, path)
	if ok and type(uri) == "string" and uri ~= "" then return uri end
	return nil
end

local TEXTURES = {
	earth = loadLocalAsset("textures/earth_day.jpg"), clouds = loadLocalAsset("textures/earth_clouds_alpha.png"),
	earthLights = loadLocalAsset("textures/earth_night_lights.png"), moon = loadLocalAsset("textures/moon.jpg"),
	galaxyTop = loadLocalAsset("textures/milky_way_top_alpha.png"), galaxySky = loadLocalAsset("textures/milky_way_sky.jpg"),
	skyboxBk = loadLocalAsset("textures/skybox/bk.jpg"), skyboxDn = loadLocalAsset("textures/skybox/dn.jpg"),
	skyboxFt = loadLocalAsset("textures/skybox/ft.jpg"), skyboxLf = loadLocalAsset("textures/skybox/lf.jpg"),
	skyboxRt = loadLocalAsset("textures/skybox/rt.jpg"), skyboxUp = loadLocalAsset("textures/skybox/up.jpg"),
	mercury = loadLocalAsset("textures/mercury.jpg"), venus = loadLocalAsset("textures/venus.jpg"),
	sun = loadLocalAsset("textures/sun.jpg"), mars = loadLocalAsset("textures/mars.jpg"),
	jupiter = loadLocalAsset("textures/jupiter.jpg"), saturn = loadLocalAsset("textures/saturn.jpg"),
	uranus = loadLocalAsset("textures/uranus.jpg"), neptune = loadLocalAsset("textures/neptune.jpg"),
}

local SOUNDS = {
	click = { file = "audio/staff_select.mp3", fallback = "rbxasset://sounds/switch.wav" },
	select = { file = "audio/star_press.mp3", fallback = "rbxasset://sounds/electronicpingshort.wav" },
	lock = { file = "audio/star_lock.mp3", fallback = "rbxasset://sounds/electronicpingshort.wav" },
	whoosh = { file = "audio/star_ascent.mp3", fallback = "rbxasset://sounds/Rocket whoosh 01.wav" },
	charge = { file = "audio/star_gun.mp3", fallback = "rbxasset://sounds/Rocket whoosh 01.wav" },
	fire = { file = "audio/star_fire.mp3", fallback = "rbxasset://sounds/Rocket shot.wav" },
	boom = { file = "audio/star_impact.mp3", fallback = "rbxasset://sounds/impact_explosion_03.mp3" },
	beam = { file = "audio/star_beam.mp3", fallback = "rbxasset://sounds/Rocket whoosh 01.wav" },
	ambient = { file = "audio/stars_hum.mp3", fallback = "" },
	countdown = { file = "audio/star_countdown.mp3", fallback = "" },
	arm = { file = "audio/star_arm.mp3", fallback = "" },
	after = { file = "audio/star_after.mp3", fallback = "" },
}

local NK = NumberSequenceKeypoint.new
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

local function texturedSphere(parent, pos, diameter, textureId, color, material, transparency, name)
	if not textureId then return nil end
	local baseDiameter = math.min(diameter, 2048)
	local p = vpart({ Name = name or "TexturedCelestialBody", Size = Vector3.one * baseDiameter, Position = pos, Color = color or Color3.new(1, 1, 1), Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0 }, parent)
	local ok = pcall(function() new("SpecialMesh", { MeshType = Enum.MeshType.Sphere, Scale = Vector3.one * (diameter / baseDiameter), TextureId = textureId }, p) end)
	if not ok then p:Destroy() return nil end
	return p
end

local function addTexturedGalaxyDisc(parent, center, radius)
	if not TEXTURES.galaxyTop then return nil end
	local baseSpan = 2040
	local plate = vpart({ Name = "OriginalMilkyWayCoreTexture", Size = Vector3.new(baseSpan, 0.5, baseSpan), Position = center, Transparency = 1, Material = Enum.Material.SmoothPlastic }, parent)
	local ok = pcall(function()
		new("SpecialMesh", { Name = "GalaxyDiscScale", MeshType = Enum.MeshType.Brick, Scale = Vector3.new((radius * 2) / baseSpan, 1, (radius * 2) / baseSpan) }, plate)
		new("Decal", { Name = "MilkyWaySpiralCore", Face = Enum.NormalId.Top, Texture = TEXTURES.galaxyTop, Transparency = 0.04 }, plate)
	end)
	if not ok then plate:Destroy() return nil end
	return plate
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

local fxFolder = new("Folder", { Name = "SpaceCannonFX" }, Workspace)

local function playSound(id, volume, speed, looped)
	if type(id) == "table" then
		local localId = loadLocalAsset(id.file or "")
		id = localId or id.fallback
	end
	if not id or id == "" then return nil end
	local s = new("Sound", { SoundId = id, Volume = volume or 1, PlaybackSpeed = speed or 1, Looped = looped or false }, SoundService)
	pcall(function() s:Play() end)
	if not looped then Debris:AddItem(s, 10) end
	return s
end

local state = "idle"
local lastFire = -1e9

local gui = new("ScreenGui", { Name = "SpaceCannonUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 50, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, player:WaitForChild("PlayerGui"))

local flash = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 100, Active = false }, gui)

local function setFlash(a, color)
	flash.BackgroundColor3 = color or Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1 - clamp01(a)
end

local barTop = new("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 90 }, gui)
local barBottom = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 90 }, gui)

local function showBars(on)
	local s = UDim2.new(1, 0, on and 0.1 or 0, 0)
	tween(barTop, 0.8, { Size = s })
	tween(barBottom, 0.8, { Size = s })
end

local caption = new("TextLabel", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.9, 0), Size = UDim2.new(0.9, 0, 0, 40), BackgroundTransparency = 1, Text = "", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 22, TextTransparency = 1, TextStrokeTransparency = 0.6, ZIndex = 95 }, gui)

local function setCaption(text, color)
	if text == "" then tween(caption, 0.4, { TextTransparency = 1 }); return end
	caption.Text = text
	caption.TextColor3 = color or Color3.new(1, 1, 1)
	caption.TextTransparency = 1
	tween(caption, 0.4, { TextTransparency = 0 })
end

local fx = {}
local function ensureFx()
	if fx.cc then return end
	fx.cc = new("ColorCorrectionEffect", { Name = "SC_CC" }, Lighting)
	fx.bloom = new("BloomEffect", { Name = "SC_Bloom", Intensity = 0.5, Size = 28, Threshold = 1 }, Lighting)
	fx.blur = new("BlurEffect", { Name = "SC_Blur", Size = 0 }, Lighting)
end

local function clearFx()
	for k, v in pairs(fx) do v:Destroy(); fx[k] = nil end
end

local savedLighting = nil
local function enterSpaceLighting()
	if savedLighting then return end
	savedLighting = { props = {}, removed = {} }
	for _, k in ipairs({ "ClockTime", "Ambient", "OutdoorAmbient", "Brightness", "FogStart", "FogEnd", "FogColor", "ExposureCompensation" }) do savedLighting.props[k] = Lighting[k] end
	for _, c in ipairs(Lighting:GetChildren()) do if c:IsA("Sky") or c:IsA("Atmosphere") or c:IsA("Clouds") then savedLighting.removed[#savedLighting.removed + 1] = c; c.Parent = nil end end
	Lighting.ClockTime = 0; Lighting.Ambient = Color3.fromRGB(10, 14, 32); Lighting.OutdoorAmbient = Color3.fromRGB(18, 23, 48)
	Lighting.Brightness = 1.9; Lighting.FogStart = 1e8; Lighting.FogEnd = 1e8; Lighting.FogColor = Color3.fromRGB(3, 5, 18); Lighting.ExposureCompensation = -0.12
	savedLighting.sky = new("Sky", { Name = "SC_CosmicSkybox", SkyboxBk = TEXTURES.skyboxBk or "", SkyboxDn = TEXTURES.skyboxDn or "", SkyboxFt = TEXTURES.skyboxFt or "", SkyboxLf = TEXTURES.skyboxLf or "", SkyboxRt = TEXTURES.skyboxRt or "", SkyboxUp = TEXTURES.skyboxUp or "", StarCount = 3000, CelestialBodiesShown = false, SunAngularSize = 0, MoonAngularSize = 0 }, Lighting)
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
	pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, enabled) end)
end

local impactFlash = { t = -1e9, a = 0 }
local impactShake = { t = -1e9, amp = 0 }

local function impactFlashValue()
	local e = os.clock() - impactFlash.t
	if e < 0 or e > 0.62 then return 0 end
	local rise = math.clamp(e / 0.045, 0, 1)
	local fall = math.clamp(1 - math.max(0, e - 0.045) / 0.575, 0, 1)
	return impactFlash.a * rise * fall * fall
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
		if f > 0.003 then setFlash(f) elseif flash.BackgroundTransparency < 1 and flash.BackgroundColor3 == Color3.new(1, 1, 1) then setFlash(0) end
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			local a = impactShakeAmount()
			if a > 0.01 then
				wasShaking = true
				local t = os.clock()
				hum.CameraOffset = Vector3.new(math.noise(t * 25, 1, 0), math.noise(t * 31, 2, 0), math.noise(t * 17, 3, 0)) * 2 * a
			elseif wasShaking then wasShaking = false; hum.CameraOffset = Vector3.zero end
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
	glow(0.55, 0.93); glow(0.3, 0.82); glow(0.14, 0.55); glow(0.06, 0)
	bar(1, 3, 0, 0.1); bar(1, 3, 90, 0.1); bar(0.5, 2, 45, 0.35); bar(0.5, 2, -45, 0.35)
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
	local layers = { { w = widths[1], col = Color3.fromRGB(255, 30, 30), tr = 0.55 }, { w = widths[2], col = Color3.fromRGB(255, 70, 45), tr = 0.1 }, { w = widths[3], col = Color3.fromRGB(255, 255, 255), tr = 0 } }
	local beams = {}
	for _, L in ipairs(layers) do beams[#beams + 1] = { beam = makeBeam(p0, at0, at1, 0, L.col, L.tr), w = L.w } end
	local laser = { p0 = p0, p1 = p1 }
	function laser.setEnd(pos) p1.Position = pos end
	function laser.setWidth(k) for _, b in ipairs(beams) do b.beam.Width0 = b.w * k; b.beam.Width1 = b.w * k end end
	function laser.destroy() p0:Destroy(); p1:Destroy() end
	return laser
end

local function isCarvable(inst)
	return inst:IsA("Part") and inst.Shape == Enum.PartType.Block and inst.Anchored and inst.Size.X >= 60 and inst.Size.Z >= 60 and inst.CFrame.UpVector.Y > 0.97
end

local function raycastDown(pos, ignore)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local list = { fxFolder }
	if player.Character then list[#list + 1] = player.Character end
	for _, i in ipairs(ignore) do list[#list + 1] = i end
	params.FilterDescendantsInstances = list
	local origin = Vector3.new(pos.X, math.max(pos.Y + 1200, 5000), pos.Z)
	return Workspace:Raycast(origin, Vector3.new(0, -12000, 0), params)
end

local function resolveGround(targetPos)
	local ignore = {}
	local probe = Vector3.new(targetPos.X, targetPos.Y, targetPos.Z)
	for _ = 1, 48 do
		local r = raycastDown(probe, ignore)
		if not r then break end
		local inst = r.Instance
		if inst:IsA("Terrain") or isCarvable(inst) then return r.Position, inst end
		ignore[#ignore + 1] = inst
	end
	local fallbackY = targetPos.Y
	local down = Workspace:Raycast(Vector3.new(targetPos.X, math.max(targetPos.Y + 1200, 5000), targetPos.Z), Vector3.new(0, -12000, 0))
	if down then fallbackY = down.Position.Y end
	return Vector3.new(targetPos.X, fallbackY, targetPos.Z), nil
end

local function carveGroundPart(ground, center, folder)
	local cf, size = ground.CFrame, ground.Size
	local half = size / 2
	local lc = cf:PointToObjectSpace(center)
	local R, D, rimW, rimH = CRATER_RADIUS, CRATER_DEPTH, RIM_WIDTH, RIM_HEIGHT
	local meshOuter = R + rimW + 24
	local reach = meshOuter + math.max(36, CELL * 2)
	local x0 = math.clamp(lc.X - reach, -half.X, half.X)
	local x1 = math.clamp(lc.X + reach, -half.X, half.X)
	local z0 = math.clamp(lc.Z - reach, -half.Z, half.Z)
	local z1 = math.clamp(lc.Z + reach, -half.Z, half.Z)
	local baseBottom = math.min(-half.Y, -D - 42)
	local molten = {}
	local palettes = {
		inner = { Color3.fromRGB(30, 25, 24), Enum.Material.Basalt },
		middle = { Color3.fromRGB(43, 36, 33), Enum.Material.Slate },
		rim = { Color3.fromRGB(59, 48, 42), Enum.Material.Basalt },
		outer = { Color3.fromRGB(82, 67, 57), Enum.Material.Rock },
	}

	local function box(minx, maxx, minz, maxz, ybot, ytop)
		local sx, sz, sy = maxx - minx, maxz - minz, ytop - ybot
		if sx < 0.05 or sz < 0.05 or sy < 0.05 then return nil end
		local p = ground:Clone()
		for _, c in ipairs(p:GetChildren()) do if c:IsA("LuaSourceContainer") then c:Destroy() end end
		p.Anchored = true; p.CanCollide = true; p.CanQuery = true
		p.Size = Vector3.new(sx, sy, sz)
		p.CFrame = cf * CFrame.new((minx + maxx) / 2, (ybot + ytop) / 2, (minz + maxz) / 2)
		p.Parent = folder
		return p
	end

	local function surfaceAt(r, ang)
		local n = math.noise(math.cos(ang) * 2.25, math.sin(ang) * 2.25, 5.6)
		local localR = R * (1 + n * 0.035)
		if r < localR then
			local k = math.clamp(r / localR, 0, 1)
			return -D * (math.max(0, 1 - k * k) ^ 1.35)
		elseif r < localR + rimW then
			local t = math.clamp((r - localR) / rimW, 0, 1)
			local ridge = math.sin(math.pi * t) ^ 0.86
			return rimH * ridge * (0.9 + n * 0.16)
		end
		return 0
	end

	local function surfaceColor(r)
		if r < R * 0.34 then return palettes.inner[1], palettes.inner[2] end
		if r < R * 0.78 then return palettes.middle[1], palettes.middle[2] end
		if r < R + rimW * 0.8 then return palettes.rim[1], palettes.rim[2] end
		return palettes.outer[1], palettes.outer[2]
	end

	local function makeLocalPart(className, name, partSize, localPosition, yaw, color, material, canCollide)
		local p = new(className, {
			Name = name, Size = partSize, CFrame = cf * CFrame.new(localPosition) * CFrame.Angles(0, yaw or 0, 0),
			Anchored = true, CanCollide = canCollide ~= false, CanQuery = true, CanTouch = false, CastShadow = true,
			Color = color, Material = material, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth,
		}, folder)
		return p
	end

	box(-half.X, x0, -half.Z, half.Z, -half.Y, half.Y)
	box(x1, half.X, -half.Z, half.Z, -half.Y, half.Y)
	box(x0, x1, -half.Z, z0, -half.Y, half.Y)
	box(x0, x1, z1, half.Z, -half.Y, half.Y)

	local floorR = R * 0.18
	local diskThickness = 18
	local floorTop = half.Y - D
	local floorColor = Color3.fromRGB(34, 26, 23)
	local floor = makeLocalPart("Part", "CraterImpactBasin", Vector3.new(diskThickness, floorR * 2, floorR * 2), Vector3.new(lc.X, floorTop - diskThickness * 0.5, lc.Z), 0, floorColor, Enum.Material.Basalt, true)
	floor.Shape = Enum.PartType.Cylinder
	floor.CFrame = cf * CFrame.new(lc.X, floorTop - diskThickness * 0.5, lc.Z) * FLAT

	local rings = { floorR }
	for i = 1, 8 do rings[#rings + 1] = floorR + (R - floorR) * i / 8 end
	for i = 1, 3 do rings[#rings + 1] = R + rimW * i / 3 end
	rings[#rings + 1] = meshOuter

	local segments = 44
	for ring = 1, #rings - 1 do
		local r0, r1 = rings[ring], rings[ring + 1]
		local radialWidth = r1 - r0 + 2.0
		for i = 1, segments do
			local ang = ((i - 0.5) / segments) * math.pi * 2
			local midR = (r0 + r1) * 0.5
			local innerY = surfaceAt(r0, ang)
			local outerY = surfaceAt(r1, ang)
			local lo, hi = math.min(innerY, outerY), math.max(innerY, outerY)
			local depth = half.Y + lo - baseBottom
			if depth > 0.2 then
				local tangentialWidth = math.max(7, 2 * r1 * math.sin(math.pi / segments) * 1.075)
				local radialX = lc.X + math.cos(ang) * midR
				local radialZ = lc.Z + math.sin(ang) * midR
				local color, material = surfaceColor(midR)
				makeLocalPart("Part", "CraterBowlFacet", Vector3.new(radialWidth, depth, tangentialWidth), Vector3.new(radialX, (baseBottom + half.Y + lo) * 0.5, radialZ), -ang, color, material, true)
				local rise = hi - lo
				if rise > 2.0 then
					local slopeSize = Vector3.new(tangentialWidth, rise + 0.25, radialWidth)
					local yaw = math.pi * 0.5 - ang
					if outerY < innerY then yaw += math.pi end
					makeLocalPart("WedgePart", "CraterCurvedSlope", slopeSize, Vector3.new(radialX, half.Y + (lo + hi) * 0.5, radialZ), yaw, color, material, true)
				end
			end
		end
	end

	local flatStep = 38
	local nx = math.max(1, math.ceil((x1 - x0) / flatStep))
	local nz = math.max(1, math.ceil((z1 - z0) / flatStep))
	local wx, wz = (x1 - x0) / nx, (z1 - z0) / nz
	for iz = 0, nz - 1 do
		local zmin = z0 + iz * wz
		local zmax = zmin + wz
		local lz = (zmin + zmax) * 0.5
		local runStart = nil
		for ix = 0, nx do
			local isFlat = false
			if ix < nx then
				local lx = x0 + (ix + 0.5) * wx
				local dx, dz = lx - lc.X, lz - lc.Z
				isFlat = math.sqrt(dx * dx + dz * dz) >= meshOuter + 5
			end
			if isFlat then
				runStart = runStart or (x0 + ix * wx)
			else
				if runStart then box(runStart, x0 + ix * wx, zmin, zmax, -half.Y, half.Y); runStart = nil end
			end
		end
	end

	local fissureCount = 30
	for i = 1, 64 do
		local ang = (i / 64) * math.pi * 2
		local radial = R * (0.82 + (math.noise(math.cos(ang) * 3, math.sin(ang) * 3, 9) * 0.035))
		local y = surfaceAt(radial, ang) + half.Y + 1.8
		local tangent = math.max(16, (math.pi * 2 * radial / 64) * 0.72)
		local segment = makeLocalPart("Part", "ObsidianRimSegment", Vector3.new(tangent, 3.5 + math.random() * 4, 8 + math.random() * 5), Vector3.new(lc.X + math.cos(ang) * radial, y, lc.Z + math.sin(ang) * radial), -ang, i % 4 == 0 and Color3.fromRGB(255, 84, 28) or Color3.fromRGB(24, 29, 39), i % 4 == 0 and Enum.Material.Neon or Enum.Material.Basalt, false)
		segment.Transparency = i % 4 == 0 and 0.16 or 0.04
		segment.CastShadow = false
	end

	for i = 1, 24 do
		local ang = (i / 24) * math.pi * 2
		local radial = R * (0.38 + math.random() * 0.28)
		local y = surfaceAt(radial, ang) + half.Y + 3
		local vent = makeLocalPart("WedgePart", "ImpactMagmaVent", Vector3.new(12 + math.random() * 12, 22 + math.random() * 28, 14 + math.random() * 12), Vector3.new(lc.X + math.cos(ang) * radial, y, lc.Z + math.sin(ang) * radial), -ang, Color3.fromRGB(34, 37, 47), Enum.Material.Basalt, false)
		local seam = makeLocalPart("Part", "VentCoreGlow", Vector3.new(1.4, 10 + math.random() * 8, 2.2), Vector3.new(lc.X + math.cos(ang) * radial, y + 2, lc.Z + math.sin(ang) * radial), -ang, Color3.fromRGB(255, 88 + math.random(0, 55), 24), Enum.Material.Neon, false)
		seam.CastShadow = false
	end

	for i = 1, fissureCount do
		local ang = (i / fissureCount) * math.pi * 2 + (math.random() - 0.5) * 0.12
		local r0 = R * (0.13 + math.random() * 0.35)
		local length = R * (0.055 + math.random() * 0.10)
		local r1 = math.min(R * 0.78, r0 + length)
		local rm = (r0 + r1) * 0.5
		local yy = surfaceAt(rm, ang) + half.Y + 1.0
		local width = 0.9 + math.random() * 1.8
		local crack = makeLocalPart("Part", "MoltenFractureLine", Vector3.new(math.max(4, r1 - r0), 1.2, width), Vector3.new(lc.X + math.cos(ang) * rm, yy, lc.Z + math.sin(ang) * rm), -ang, Color3.fromRGB(255, math.random(72, 126), 24), Enum.Material.Neon, false)
		crack.Transparency = 0.12 + math.random() * 0.28
		crack.CastShadow = false
	end

	local glow = makeLocalPart("Part", "MagmaCoreGlow", Vector3.new(3.5, floorR * 1.05, floorR * 1.05), Vector3.new(lc.X, floorTop + 1.2, lc.Z), 0, Color3.fromRGB(255, 86, 28), Enum.Material.Neon, false)
	glow.Shape = Enum.PartType.Cylinder
	glow.CFrame = cf * CFrame.new(lc.X, floorTop + 1.2, lc.Z) * FLAT
	glow.Transparency = 0.36
	new("PointLight", { Color = Color3.fromRGB(255, 91, 28), Range = R * 0.9, Brightness = 2.2 }, glow)
	molten[#molten + 1] = glow

	task.delay(9, function()
		for _, p in ipairs(molten) do
			if p.Parent then
				p.Material = Enum.Material.Basalt
				tween(p, 2, { Color = Color3.fromRGB(26, 20, 18), Transparency = 0.16 })
			end
		end
	end)

	return function(worldX, worldZ)
		local lp = cf:PointToObjectSpace(Vector3.new(worldX, center.Y, worldZ))
		local dx, dz = lp.X - lc.X, lp.Z - lc.Z
		local r = math.sqrt(dx * dx + dz * dz)
		local a = math.atan2(dz, dx)
		return cf:PointToWorldSpace(Vector3.new(lp.X, half.Y + surfaceAt(r, a), lp.Z)).Y
	end
end

local function carveTerrain(center)
	local terrain = Workspace.Terrain
	local R, D, rimW, rimH = CRATER_RADIUS, CRATER_DEPTH, RIM_WIDTH, RIM_HEIGHT
	local backup
	pcall(function()
		local half = Vector3.new(R + rimW + 40, D + rimH + 80, R + rimW + 40)
		local region = Region3.new(center - half, center + half):ExpandToGrid(4)
		local copy = terrain:CopyRegion(region)
		local minCorner = region.CFrame.Position - region.Size / 2
		backup = { copy = copy, corner = Vector3int16.new(math.floor(minCorner.X / 4), math.floor(minCorner.Y / 4), math.floor(minCorner.Z / 4)) }
	end)
	local sphereRadius = (R * R + D * D) / (2 * D)
	local sphereOffset = (R * R - D * D) / (2 * D)
	pcall(function()
		terrain:FillBall(center + Vector3.new(0, sphereOffset, 0), sphereRadius, Enum.Material.Air)
		terrain:FillBall(center + Vector3.new(0, -D + 18, 0), R * 0.17, Enum.Material.CrackedLava)
		for i = 1, 76 do
			local a = i / 76 * math.pi * 2
			local rn = R * (1 + (math.random() - 0.5) * 0.1)
			local rr = rn + rimW * (0.12 + math.random() * 0.48)
			local lump = 15 + math.random() * 27
			terrain:FillBall(center + Vector3.new(math.cos(a) * rr, 2 + math.random() * 15, math.sin(a) * rr), lump, i % 4 == 0 and Enum.Material.Slate or Enum.Material.Basalt)
		end
	end)
	return backup, function(worldX, worldZ)
		local dx, dz = worldX - center.X, worldZ - center.Z
		local r = math.sqrt(dx * dx + dz * dz)
		local a = math.atan2(dz, dx)
		local noise = math.noise(math.cos(a) * 2.25, math.sin(a) * 2.25, 5.6)
		local localR = R * (1 + noise * 0.035)
		if r < localR then
			local scaled = r * (R / localR)
			return center.Y + sphereOffset - math.sqrt(math.max(0, sphereRadius * sphereRadius - scaled * scaled))
		elseif r < localR + rimW then
			local t = math.clamp((r - localR) / rimW, 0, 1)
			return center.Y + rimH * (math.sin(math.pi * t) ^ 0.86) * (0.9 + noise * 0.16)
		end
		return center.Y
	end
end

local function blastHumanoids(center)
	local op = OverlapParams.new()
	op.MaxParts = 3000
	local seen = {}
	for _, part in ipairs(Workspace:GetPartBoundsInRadius(center, BLAST_RADIUS, op)) do
		local model = part:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and not seen[hum] and hum.Health > 0 then
			seen[hum] = true
			local isSelf = model == player.Character
			local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or part
			local offset = root.Position - center
			local d = offset.Magnitude
			if d <= KILL_RADIUS then
				if isSelf then
					local c = player.Character
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if h then h.Health = 0; h:ChangeState(Enum.HumanoidStateType.Dead); c:BreakJoints() end
				else
					hum.Health = 0
				end
			else
				local t = (d - KILL_RADIUS) / (BLAST_RADIUS - KILL_RADIUS)
				local dir = d > 0.01 and offset.Unit or Vector3.yAxis
				if root:IsA("BasePart") then root.AssemblyLinearVelocity = dir * (170 * (1 - t)) + Vector3.new(0, 80 * (1 - t), 0) end
				hum.Health = hum.Health - 180 * (1 - t) ^ 1.2
			end
		end
	end
end

local function savePartState(p, record)
	if not record or not p or not p.Parent then return end
	record.seen = record.seen or {}
	if record.seen[p] then return end
	record.seen[p] = true
	record.backups[#record.backups + 1] = { part = p, parent = p.Parent, cframe = p.CFrame, anchored = p.Anchored, transparency = p.Transparency, canCollide = p.CanCollide, canQuery = p.CanQuery, canTouch = p.CanTouch, material = p.Material, color = p.Color, linearVelocity = p.AssemblyLinearVelocity, angularVelocity = p.AssemblyAngularVelocity }
end

local function blastParts(center, groundInst, folder, record)
	local op = OverlapParams.new()
	op.MaxParts = 8500
	op.FilterType = Enum.RaycastFilterType.Exclude
	local excludes = { fxFolder, folder }
	if player.Character then excludes[#excludes + 1] = player.Character end
	op.FilterDescendantsInstances = excludes
	local radius = CRATER_RADIUS + RIM_WIDTH + 180
	local parts = Workspace:GetPartBoundsInRadius(center + Vector3.new(0, 80, 0), radius, op)
	local candidates = {}
	for _, p in ipairs(parts) do
		if p ~= groundInst and p:IsA("BasePart") and not p:IsDescendantOf(fxFolder) and not p:IsDescendantOf(folder) then
			local model = p:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChildOfClass("Humanoid")
			local isCharacter = humanoid ~= nil or (player.Character and p:IsDescendantOf(player.Character))
			if not isCharacter then
				local off = p.Position - center
				local horizontal = Vector3.new(off.X, 0, off.Z).Magnitude
				local vertical = math.abs(off.Y)
				local maxSide = math.max(p.Size.X, p.Size.Z)
				local trulyHugeFloor = p.Anchored and p.Size.Y < 18 and maxSide > 700 and p.CFrame.UpVector.Y > 0.96
				if not trulyHugeFloor and horizontal < radius and vertical < 620 then candidates[#candidates + 1] = { part = p, distance = horizontal, offset = off, vertical = vertical } end
			end
		end
	end
	table.sort(candidates, function(a, b) return a.distance < b.distance end)
	local count = math.min(#candidates, 1800)
	local removed = 0
	for i = 1, count do
		local item = candidates[i]
		local p, d = item.part, item.distance
		if p and p.Parent then
			local inner = d < CRATER_RADIUS * 0.80
			local mid = d < CRATER_RADIUS + RIM_WIDTH * 0.62
			local flatFloor = p.Anchored and p.Size.Y < 18 and math.max(p.Size.X, p.Size.Z) > 700 and p.CFrame.UpVector.Y > 0.96
			if not flatFloor then
				savePartState(p, record)
				if inner and item.vertical < CRATER_DEPTH + RIM_HEIGHT + 160 then
					p.Parent = nil
					removed += 1
				elseif mid then
					p.Anchored = false; p.CanTouch = false
					local off = item.offset
					local dir = Vector3.new(off.X, 0, off.Z)
					dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
					local falloff = math.clamp(1 - d / radius, 0.08, 1)
					p.AssemblyLinearVelocity = dir * ((120 + math.random() * 240) * falloff) + Vector3.new(0, (140 + math.random() * 220) * falloff, 0)
					p.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 13
				else
					p.Anchored = false; p.CanTouch = false
					local off = item.offset
					local dir = Vector3.new(off.X, 0, off.Z)
					dir = dir.Magnitude > 0.1 and dir.Unit or Vector3.new(math.random() - 0.5, 0, math.random() - 0.5).Unit
					local falloff = math.clamp(1 - d / (radius * 1.15), 0.03, 0.34)
					p.AssemblyLinearVelocity = dir * ((70 + math.random() * 140) * falloff) + Vector3.new(0, (55 + math.random() * 120) * falloff, 0)
					p.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 8
				end
			end
		end
	end
	return removed
end

local rockMats = { Enum.Material.Slate, Enum.Material.Basalt, Enum.Material.Granite }

local function spawnRocks(center, debrisFolder, surfaceY)
	for i = 1, ROCK_COUNT do
		local s = 8 + math.random() * 30
		local ang = math.random() * math.pi * 2
		local radial = math.sqrt(math.random()) * CRATER_RADIUS * 0.94
		if i % 4 == 0 then radial = CRATER_RADIUS * (0.72 + math.random() * 0.52) end
		local px = center.X + math.cos(ang) * radial
		local pz = center.Z + math.sin(ang) * radial
		local gy = surfaceY and surfaceY(px, pz) or center.Y
		local shade = math.random(34, 77)
		local sx = s * (0.72 + math.random() * 0.66)
		local sy = s * (0.55 + math.random() * 0.68)
		local sz = s * (0.72 + math.random() * 0.66)
		local rock = new("Part", { Name = "ImpactEjectaFragment", Size = Vector3.new(sx, sy, sz), Material = rockMats[math.random(1, #rockMats)], Color = Color3.fromRGB(shade + 12, shade + 5, shade - 4), Anchored = false, CanCollide = true, CanQuery = true, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth, CFrame = CFrame.new(px, gy + sy * 0.55 + 3, pz) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6) }, debrisFolder)
		local horizontal = 62 + math.random() * 155
		rock.AssemblyLinearVelocity = Vector3.new(math.cos(ang) * horizontal, 150 + math.random() * 260, math.sin(ang) * horizontal)
		rock.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 12
		if i % 4 == 0 then new("Fire", { Size = 7 + math.random() * 5, Heat = 0, Color = Color3.fromRGB(255, 120, 30), SecondaryColor = Color3.fromRGB(120, 20, 10) }, rock) end
		Debris:AddItem(rock, 18)
		task.spawn(function()
			local t0 = os.clock()
			while rock.Parent and os.clock() - t0 < 5 do
				if rock.AssemblyLinearVelocity.Magnitude > 28 then
					local ch = player.Character
					if ch and rock.Parent then
						local op = OverlapParams.new()
						op.FilterType = Enum.RaycastFilterType.Include
						op.FilterDescendantsInstances = { ch }
						if #Workspace:GetPartsInPart(rock, op) > 0 then
							local hum = ch:FindFirstChildOfClass("Humanoid")
							if hum and hum.Health > 0 then hum.Health = 0; hum:ChangeState(Enum.HumanoidStateType.Dead); ch:BreakJoints() end
						end
					end
				end
				task.wait(0.08)
			end
		end)
	end
end

local function spawnSpires(center, folder, surfaceY)
	local spireFolder = new("Folder", { Name = "CraterRimShards" }, folder)
	for i = 1, SPIRE_COUNT do
		local baseAngle = (i - 1) * (math.pi * 2 / SPIRE_COUNT)
		local ang = baseAngle + (math.random() - 0.5) * 0.58
		local radial = CRATER_RADIUS * (0.66 + math.random() * 0.52) + math.random() * RIM_WIDTH * 0.22
		local px = center.X + math.cos(ang) * radial
		local pz = center.Z + math.sin(ang) * radial
		local gy = surfaceY and surfaceY(px, pz) or center.Y
		local w = 16 + math.random() * 20
		local h = 54 + math.random() ^ 0.72 * 184
		local shade = math.random(36, 64)
		local model = Instance.new("Model")
		model.Name = "ImpactRimShard"
		local anchor = new("Part", { Name = "ShardPivot", Size = Vector3.one, Transparency = 1, Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CFrame = CFrame.new() }, model)
		local function shard(className, name, size, pos, yaw, leanX, leanZ, color, material)
			return new(className, { Name = name, Size = size, Anchored = true, CanCollide = true, CanQuery = true, CanTouch = false, Material = material, Color = color, CFrame = CFrame.new(pos) * CFrame.Angles(leanX or 0, yaw or 0, leanZ or 0), TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, model)
		end
		local baseMat = rockMats[math.random(1, #rockMats)]
		shard("WedgePart", "FacetedBasaltSpire", Vector3.new(w * 0.72, h * 0.88, w * 0.74), Vector3.new(0, h * 0.39, 0), math.random() * 6, (math.random() - 0.5) * 0.44, (math.random() - 0.5) * 0.44, Color3.fromRGB(shade + 9, shade + 2, shade - 8), baseMat)
		shard("CornerWedgePart", "BrokenSpireTip", Vector3.new(w * 0.62, h * 0.45, w * 0.60), Vector3.new((math.random() - 0.5) * w * 0.16, h * 0.76, (math.random() - 0.5) * w * 0.16), math.random() * 6, (math.random() - 0.5) * 0.18, (math.random() - 0.5) * 0.18, Color3.fromRGB(shade + 4, shade - 2, shade - 10), Enum.Material.Basalt)
		local crack = shard("Part", "CoolingMagmaSeam", Vector3.new(1.1, h * 0.36, 1.35), Vector3.new(w * 0.12, h * 0.36, w * 0.15), 0, 0, 0, Color3.fromRGB(255, 88 + math.random(0, 36), 28), Enum.Material.Neon)
		crack.CanCollide = false; crack.CanQuery = false; crack.Transparency = 0.18
		shard("WedgePart", "DetachedSpireFacet", Vector3.new(w * 0.30, h * 0.48, w * 0.34), Vector3.new(-w * 0.28, h * 0.30, w * 0.18), math.random() * 6, (math.random() - 0.5) * 0.32, (math.random() - 0.5) * 0.24, Color3.fromRGB(shade - 2, shade - 7, shade - 12), baseMat)
		model.PrimaryPart = anchor
		local final = CFrame.new(px, gy + 1.5, pz) * CFrame.Angles((math.random() - 0.5) * 0.16, ang, (math.random() - 0.5) * 0.16)
		local start = final * CFrame.new(0, -(h + 16), 0)
		model:PivotTo(start)
		model.Parent = spireFolder
		local cv = Instance.new("CFrameValue")
		cv.Value = start
		cv.Changed:Connect(function(v) if model.Parent then model:PivotTo(v) end end)
		task.delay(math.random() * 0.28, function()
			if not model.Parent then cv:Destroy() return end
			tween(cv, 0.48 + math.random() * 0.32, { Value = final }, Enum.EasingStyle.Quart)
			task.delay(1.4, function() if cv.Parent then cv:Destroy() end end)
		end)
		Debris:AddItem(model, 18)
	end
end

local function buildCosmicCraterDecor(center, folder, surfaceY)
	local decor = new("Folder", { Name = "CosmicImpactScar" }, folder)
	local function yAt(x, z)
		local ok, result = pcall(surfaceY or function() return center.Y end, x, z)
		if ok and type(result) == "number" then return result end
		return center.Y
	end
	local function part(className, name, size, pos, yaw, color, material, transparency, collide)
		return new(className, { Name = name, Size = size, CFrame = CFrame.new(pos) * CFrame.Angles(0, yaw or 0, 0), Anchored = true, CanCollide = collide == true, CanQuery = false, CanTouch = false, CastShadow = false, Color = color, Material = material, Transparency = transparency or 0, TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth }, decor)
	end
	local coreY = yAt(center.X, center.Z)
	local coreRadius = CRATER_RADIUS * 0.205
	local glass = vpart({ Name = "ObsidianImpactGlass", Shape = Enum.PartType.Cylinder, Size = Vector3.new(5, coreRadius * 2, coreRadius * 2), CFrame = CFrame.new(center.X, coreY + 2.8, center.Z) * FLAT, Color = Color3.fromRGB(35, 24, 58), Material = Enum.Material.Glass, Transparency = 0.16, Reflectance = 0.18, CanCollide = false, CanQuery = false, CanTouch = false }, decor)
	local molten = vpart({ Name = "StarCoreResidualMagma", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3.2, coreRadius * 1.35, coreRadius * 1.35), CFrame = CFrame.new(center.X, coreY + 4.8, center.Z) * FLAT, Color = Color3.fromRGB(255, 75, 36), Material = Enum.Material.Neon, Transparency = 0.34, CanCollide = false, CanQuery = false, CanTouch = false }, decor)
	new("PointLight", { Color = Color3.fromRGB(255, 77, 39), Range = 44, Brightness = 1.6 }, molten)

	local ringDefs = {
		{ radius = CRATER_RADIUS * 0.34, width = 7.5, height = 2.1, color = Color3.fromRGB(255, 83, 42), material = Enum.Material.Neon, alpha = 0.10, density = 44 },
		{ radius = CRATER_RADIUS * 0.67, width = 5.5, height = 1.8, color = Color3.fromRGB(147, 84, 255), material = Enum.Material.Neon, alpha = 0.20, density = 48 },
		{ radius = CRATER_RADIUS + RIM_WIDTH * 0.22, width = 9.0, height = 2.8, color = Color3.fromRGB(69, 205, 255), material = Enum.Material.Neon, alpha = 0.20, density = 56 },
	}
	for ri, rd in ipairs(ringDefs) do
		for i = 1, rd.density do
			local gapEvery = ri == 2 and 9 or 12
			if i % gapEvery ~= 0 and not (ri == 3 and i % 17 == 0) then
				local a = (i / rd.density) * math.pi * 2 + (math.random() - 0.5) * 0.03
				local radial = rd.radius * (0.986 + math.random() * 0.028)
				local x = center.X + math.cos(a) * radial
				local z = center.Z + math.sin(a) * radial
				local y = yAt(x, z) + rd.height * 0.42 + math.random() * 1.3
				local segLen = 2 * math.pi * radial / rd.density * (0.66 + math.random() * 0.18)
				local color = rd.color; local mat = rd.material; local alpha = rd.alpha
				if ri == 3 and i % 4 == 0 then color = Color3.fromRGB(41, 50, 72); mat = Enum.Material.Basalt; alpha = 0.02
				elseif ri == 1 and i % 6 == 0 then color = Color3.fromRGB(255, 202, 104) end
				part("Part", "ImpactContourArc", Vector3.new(segLen, rd.height, rd.width), Vector3.new(x, y, z), -a - math.pi * 0.5, color, mat, alpha, false)
			end
		end
	end
	for i = 1, 26 do
		local a = math.random() * math.pi * 2
		local r0 = CRATER_RADIUS * (0.12 + math.random() * 0.36)
		local r1 = math.min(CRATER_RADIUS * 0.92, r0 + CRATER_RADIUS * (0.08 + math.random() * 0.21))
		local rm = (r0 + r1) * 0.5
		local px = center.X + math.cos(a) * rm
		local pz = center.Z + math.sin(a) * rm
		local py = yAt(px, pz) + 1.8 + math.random() * 1.5
		local width = 1.1 + math.random() * 3.1
		local color = i % 4 == 0 and Color3.fromRGB(87, 215, 255) or (i % 3 == 0 and Color3.fromRGB(169, 100, 255) or Color3.fromRGB(255, math.random(78, 142), 34))
		local crack = part("Part", "RadialCosmicFracture", Vector3.new(r1 - r0, 1.1, width), Vector3.new(px, py, pz), -a, color, Enum.Material.Neon, 0.10 + math.random() * 0.24, false)
		if crack then crack.CastShadow = false end
		if i % 5 == 0 then
			local splitR = rm + (r1 - r0) * 0.32
			local sx = center.X + math.cos(a + 0.14) * splitR
			local sz = center.Z + math.sin(a + 0.14) * splitR
			part("Part", "FractureBranch", Vector3.new((r1 - r0) * 0.35, 0.9, width * 0.7), Vector3.new(sx, yAt(sx, sz) + 2.1, sz), -(a + 0.14), color, Enum.Material.Neon, 0.20, false)
		end
	end
	for i = 1, 54 do
		local a = math.random() * math.pi * 2
		local radial = CRATER_RADIUS * (0.24 + math.random() * 1.02)
		local px = center.X + math.cos(a) * radial
		local pz = center.Z + math.sin(a) * radial
		local w = 8 + math.random() * 31; local h = 5 + math.random() * 24; local depth = 7 + math.random() * 34
		local gy = yAt(px, pz); local yaw = math.random() * math.pi * 2
		local className = i % 3 == 0 and "WedgePart" or "Part"
		new(className, { Name = "ImpactBasaltRubble", Size = Vector3.new(w, h, depth), CFrame = CFrame.new(px, gy + h * 0.26 + 0.6, pz) * CFrame.Angles((math.random() - 0.5) * 0.36, yaw, (math.random() - 0.5) * 0.4), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = true, Material = i % 4 == 0 and Enum.Material.Slate or Enum.Material.Basalt, Color = Color3.fromRGB(25 + math.random(0, 30), 29 + math.random(0, 28), 42 + math.random(0, 36)) }, decor)
		if i % 7 == 0 then
			local seam = part("Part", "RubbleHotSeam", Vector3.new(w * 0.55, 1.2, 1.4), Vector3.new(px, gy + h * 0.52 + 1, pz), yaw, Color3.fromRGB(255, 92, 43), Enum.Material.Neon, 0.16, false)
			if seam then seam.CastShadow = false end
		end
	end
	for i = 1, 14 do
		local a = (i - 1) * (math.pi * 2 / 14) + (math.random() - 0.5) * 0.64
		local radial = CRATER_RADIUS * (0.64 + math.random() * 0.70)
		local px = center.X + math.cos(a) * radial
		local pz = center.Z + math.sin(a) * radial
		local gy = yAt(px, pz); local h = 64 + math.random() ^ 0.7 * 176; local w = 13 + math.random() * 24
		local tilt = (math.random() - 0.5) * 0.32
		local shard = new("WedgePart", { Name = "CosmicCraterShard", Size = Vector3.new(w, h, w * (0.64 + math.random() * 0.5)), CFrame = CFrame.new(px, gy + h * 0.34, pz) * CFrame.Angles(math.cos(a) * 0.26 + tilt, a, math.sin(a) * 0.26 - tilt), Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false, Material = Enum.Material.Basalt, Color = Color3.fromRGB(32 + math.random(0, 24), 36 + math.random(0, 26), 48 + math.random(0, 30)) }, decor)
		if i % 3 == 0 then
			local seam = vpart({ Name = "ShardPlasmaSeam", Size = Vector3.new(1.8, h * 0.32, 1.4), CFrame = shard.CFrame * CFrame.new(w * 0.08, h * 0.1, w * 0.34), Color = i % 2 == 0 and Color3.fromRGB(255, 103, 48) or Color3.fromRGB(94, 209, 255), Material = Enum.Material.Neon, Transparency = 0.20, CanCollide = false, CanQuery = false, CanTouch = false }, decor)
			seam.CastShadow = false
		end
	end
	for i = 1, 42 do
		local a = math.random() * math.pi * 2
		local r0 = CRATER_RADIUS * (0.18 + math.random() * 0.58)
		local r1 = math.min(CRATER_RADIUS * 1.16, r0 + CRATER_RADIUS * (0.06 + math.random() * 0.16))
		local mid = (r0 + r1) * 0.5
		local px = center.X + math.cos(a) * mid
		local pz = center.Z + math.sin(a) * mid
		local gy = yAt(px, pz); local length = r1 - r0; local width = 2.2 + math.random() * 6.8
		local hot = part("Part", "MoltenLavaVein", Vector3.new(length, 1.25, width), Vector3.new(px, gy + 2.4, pz), -a, i % 5 == 0 and Color3.fromRGB(255, 214, 105) or Color3.fromRGB(255, 64 + math.random(0, 40), 18), Enum.Material.Neon, 0.06 + math.random() * 0.22, false)
		if hot then
			local glow = new("PointLight", {Color = Color3.fromRGB(255, 63, 24), Range = 18 + math.random(0, 18), Brightness = 0.35}, hot)
			task.delay(18 + math.random() * 12, function()
				if hot.Parent then
					tween(hot, 4, {Transparency = 0.78}, Enum.EasingStyle.Quad)
					if glow.Parent then tween(glow, 4, {Brightness = 0}) end
				end
			end)
		end
		if i % 4 == 0 then
			local bx = center.X + math.cos(a + 0.24) * (mid + length * 0.18)
			local bz = center.Z + math.sin(a + 0.24) * (mid + length * 0.18)
			part("Part", "ForkedMagmaCrack", Vector3.new(length * 0.32, 0.9, width * 0.62), Vector3.new(bx, yAt(bx, bz) + 2.1, bz), -(a + 0.24), Color3.fromRGB(255, 119, 35), Enum.Material.Neon, 0.18, false)
		end
	end
	for i = 1, 5 do
		local a = i * 2.399963
		local radial = CRATER_RADIUS * (0.20 + (i % 3) * 0.11)
		local px = center.X + math.cos(a) * radial
		local pz = center.Z + math.sin(a) * radial
		local gy = yAt(px, pz); local size = 18 + i * 4
		local prism = part("Part", "ResidualCosmicCrystal", Vector3.new(size, size * 1.7, size), Vector3.new(px, gy + size * 0.9, pz), -a, i % 2 == 0 and Color3.fromRGB(114, 82, 255) or Color3.fromRGB(51, 206, 255), Enum.Material.Neon, 0.24, false)
		if prism then
			prism.Shape = Enum.PartType.Block
			prism.CFrame = CFrame.new(px, gy + size * 0.9, pz) * CFrame.Angles(0.32, -a, 0.24)
		end
	end
end

local craters = {}
local function restoreAll()
	for i = #craters, 1, -1 do
		local c = craters[i]
		if c.folder then c.folder:Destroy() end
		for _, b in ipairs(c.backups) do
			pcall(function()
				if b.anchored == true then b.part.Anchored = true end
				b.part.Parent = b.parent or Workspace
				if b.cframe then b.part.CFrame = b.cframe end
				if b.transparency ~= nil then b.part.Transparency = b.transparency end
				if b.canCollide ~= nil then b.part.CanCollide = b.canCollide end
				if b.canQuery ~= nil then b.part.CanQuery = b.canQuery end
				if b.canTouch ~= nil then b.part.CanTouch = b.canTouch end
				if b.material then b.part.Material = b.material end
				if b.color then b.part.Color = b.color end
				if b.anchored == false then
					b.part.Anchored = false
					if b.linearVelocity then b.part.AssemblyLinearVelocity = b.linearVelocity end
					if b.angularVelocity then b.part.AssemblyAngularVelocity = b.angularVelocity end
				end
			end)
		end
		if c.terrain then pcall(function() Workspace.Terrain:PasteRegion(c.terrain.copy, c.terrain.corner, true) end) end
		craters[i] = nil
	end
end

local function doImpact(targetPos, isShooter)
	local center, groundInst = resolveGround(targetPos)
	enterSpaceLighting()
	local origin = center + Vector3.new(0, 20, 0)
	local core = vpart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 246, 220), Size = Vector3.one * 18, Position = origin, Transparency = 0.03 }, fxFolder)
	local coreLight = new("PointLight", { Color = Color3.fromRGB(255, 146, 80), Range = 60, Brightness = 8 }, core)
	tween(core, 0.32, { Size = Vector3.one * 220, Transparency = 1 }, Enum.EasingStyle.Quart)
	tween(coreLight, 0.28, { Brightness = 0, Range = 0 })
	Debris:AddItem(core, 0.42)
	local shell = vpart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 105, 52), Size = Vector3.one * 46, Position = origin, Transparency = 0.82 }, fxFolder)
	tween(shell, 0.85, { Size = Vector3.one * 980, Transparency = 1 }, Enum.EasingStyle.Quart)
	Debris:AddItem(shell, 0.95)
	local rift = vpart({ Shape = Enum.PartType.Ball, Material = Enum.Material.Neon, Color = Color3.fromRGB(100, 68, 255), Size = Vector3.one * 70, Position = center + Vector3.new(0, 28, 0), Transparency = 0.93 }, fxFolder)
	tween(rift, 1.35, { Size = Vector3.one * 1460, Transparency = 1 }, Enum.EasingStyle.Quart)
	Debris:AddItem(rift, 1.45)
	for i = 1, 4 do
		local colors = { Color3.fromRGB(255, 183, 94), Color3.fromRGB(255, 80, 46), Color3.fromRGB(143, 87, 255), Color3.fromRGB(80, 220, 255) }
		local radius = 46 + (i - 1) * 28
		local ring = vpart({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.5, radius * 2, radius * 2), Material = Enum.Material.Neon, Color = colors[i], Transparency = 0.28 + i * 0.08, CFrame = CFrame.new(center + Vector3.new(0, 4 + i * 1.2, 0)) * FLAT }, fxFolder)
		task.delay((i - 1) * 0.09, function() if ring.Parent then tween(ring, 1.5 + i * 0.12, { Size = Vector3.new(2.5, 1500 + i * 170, 1500 + i * 170), Transparency = 1 }, Enum.EasingStyle.Quart) end end)
		Debris:AddItem(ring, 2.0 + i * 0.1)
	end
	for i = 1, 3 do
		local angle = (i - 1) * math.pi * 2 / 3 + math.rad(math.random(-18, 18))
		local start = center + Vector3.new(math.cos(angle) * 95, 10 + math.random(0, 40), math.sin(angle) * 95)
		local finish = start + Vector3.new(math.cos(angle) * (460 + math.random(0, 250)), 320 + math.random(0, 420), math.sin(angle) * (460 + math.random(0, 250)))
		local delta = finish - start
		local bolt = vpart({ Name = "CosmicImpactArc", Size = Vector3.new(3 + i, delta.Magnitude, 3 + i), CFrame = CFrame.lookAt((start + finish) * 0.5, finish) * CFrame.Angles(math.pi * 0.5, 0, 0), Material = Enum.Material.Neon, Color = i == 1 and Color3.fromRGB(255, 107, 54) or (i == 2 and Color3.fromRGB(141, 86, 255) or Color3.fromRGB(72, 221, 255)), Transparency = 0.12 }, fxFolder)
		tween(bolt, 0.8, { Size = Vector3.new(0.4, delta.Magnitude * 1.2, 0.4), Transparency = 1 }, Enum.EasingStyle.Quart)
		Debris:AddItem(bolt, 0.9)
	end
	local apocalypsePalette = { Color3.fromRGB(255, 42, 18), Color3.fromRGB(255, 104, 30), Color3.fromRGB(255, 190, 74), Color3.fromRGB(113, 20, 12) }
	for i = 1, 7 do
		local angle = (i - 1) * math.pi * 2 / 7 + math.random() * 0.22
		local radius = 130 + math.random(0, 110)
		local startPos = center + Vector3.new(math.cos(angle) * radius, 2, math.sin(angle) * radius)
		local length = 330 + math.random(120, 340)
		local endPos = startPos + Vector3.new(math.cos(angle) * length, math.random(-8, 14), math.sin(angle) * length)
		local delta = endPos - startPos
		local crack = vpart({ Name = "ApocalypseMagmaFault", Size = Vector3.new(math.random(5, 10), 1.8, delta.Magnitude), CFrame = CFrame.lookAt((startPos + endPos) * 0.5, endPos) * CFrame.Angles(math.pi * 0.5, 0, 0), Material = Enum.Material.Neon, Color = apocalypsePalette[math.random(1, 3)], Transparency = 0.08 }, fxFolder)
		tween(crack, 4.2, {Transparency = 0.52, Size = Vector3.new(1.2, 0.5, delta.Magnitude * 1.04)}, Enum.EasingStyle.Quad)
		Debris:AddItem(crack, 4.5)
		for branch = 1, 2 do
			local t = math.random(25, 78) / 100
			local originB = startPos:Lerp(endPos, t)
			local side = (math.random(0, 1) == 0 and -1 or 1) * math.rad(math.random(24, 58))
			local branchAngle = angle + side
			local branchLen = length * (0.16 + math.random() * 0.17)
			local branchEnd = originB + Vector3.new(math.cos(branchAngle) * branchLen, 0, math.sin(branchAngle) * branchLen)
			local branchDelta = branchEnd - originB
			local branchPart = vpart({ Name = "BranchingLavaFault", Size = Vector3.new(math.random(2, 5), 1.1, branchDelta.Magnitude), CFrame = CFrame.lookAt((originB + branchEnd) * 0.5, branchEnd) * CFrame.Angles(math.pi * 0.5, 0, 0), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, math.random(45, 115), 20), Transparency = 0.14 }, fxFolder)
			tween(branchPart, 3.6, {Transparency = 0.68, Size = Vector3.new(0.5, 0.4, branchDelta.Magnitude)}, Enum.EasingStyle.Quad)
			Debris:AddItem(branchPart, 3.9)
		end
	end
	for i = 1, 9 do
		local a = math.random() * math.pi * 2
		local r = 110 + math.random() * 270
		local base = center + Vector3.new(math.cos(a) * r, -8, math.sin(a) * r)
		local height = 90 + math.random() * 210
		local pillar = vpart({ Name = "MagmaEruptionPillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(18 + math.random() * 20, 12 + math.random() * 20, 12 + math.random() * 20), CFrame = CFrame.new(base + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = i % 3 == 0 and Color3.fromRGB(255, 205, 89) or Color3.fromRGB(255, 54, 20), Transparency = 0.12 }, fxFolder)
		tween(pillar, 1.35, {Position = base + Vector3.new(0, height, 0), Transparency = 1, Size = Vector3.new(2, 4, 4)}, Enum.EasingStyle.Quart)
		Debris:AddItem(pillar, 1.5)
	end
	for i = 1, 18 do
		local a = math.random() * math.pi * 2
		local r = 180 + math.random() * 620
		local startPos = center + Vector3.new(math.cos(a) * r, 420 + math.random() * 600, math.sin(a) * r)
		local endPos = center + Vector3.new(math.cos(a) * (r + math.random(-130, 130)), 8 + math.random(0, 35), math.sin(a) * (r + math.random(-130, 130)))
		local meteor = vpart({ Name = "FallingStarDebris", Shape = Enum.PartType.Ball, Size = Vector3.one * math.random(7, 17), Position = startPos, Material = Enum.Material.Neon, Color = i % 3 == 0 and Color3.fromRGB(255, 218, 132) or Color3.fromRGB(255, 75, 28), Transparency = 0.04 }, fxFolder)
		local trail = new("Trail", { Lifetime = 0.28, MinLength = 0.1, LightEmission = 1, Color = ColorSequence.new(Color3.fromRGB(255, 240, 188), Color3.fromRGB(255, 54, 20)), Transparency = NumberSequence.new({NK(0, 0.05), NK(1, 1)}) }, meteor)
		local at0 = new("Attachment", {Position = Vector3.new(0, 0, -3)}, meteor)
		local at1 = new("Attachment", {Position = Vector3.new(0, 0, 3)}, meteor)
		trail.Attachment0 = at0; trail.Attachment1 = at1
		tween(meteor, 1.1 + math.random() * 0.7, {Position = endPos, Transparency = 1, Size = Vector3.one * 1.5}, Enum.EasingStyle.Quad)
		Debris:AddItem(meteor, 2)
	end
	local doomPulse = vpart({ Name = "DoomHorizonPulse", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 160, 160), CFrame = CFrame.new(center + Vector3.new(0, 1.5, 0)) * FLAT, Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 42, 16), Transparency = 0.12 }, fxFolder)
	tween(doomPulse, 2.6, {Size = Vector3.new(3, 2200, 2200), Transparency = 1}, Enum.EasingStyle.Quart)
	Debris:AddItem(doomPulse, 2.8)
	local anchor = vpart({ Transparency = 1, Size = Vector3.one, Position = center + Vector3.new(0, 8, 0) }, fxFolder)
	local att = new("Attachment", {}, anchor)
	local smoke = new("ParticleEmitter", { Enabled = false, Rate = 0, Texture = "rbxasset://textures/particles/smoke_main.dds", Lifetime = NumberRange.new(5, 9), Speed = NumberRange.new(70, 210), SpreadAngle = Vector2.new(72, 72), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-24, 24), Size = NumberSequence.new({ NK(0, 26), NK(0.45, 150), NK(1, 310) }), Transparency = NumberSequence.new({ NK(0, 0.30), NK(0.65, 0.6), NK(1, 1) }), Color = ColorSequence.new(Color3.fromRGB(47, 39, 70), Color3.fromRGB(74, 49, 54)), Drag = 2.8, Acceleration = Vector3.new(0, 18, 0) }, att)
	smoke:Emit(95)
	local sparks = new("ParticleEmitter", { Enabled = false, Rate = 0, Texture = "rbxasset://textures/particles/sparkles_main.dds", Lifetime = NumberRange.new(0.8, 2.1), Speed = NumberRange.new(160, 490), SpreadAngle = Vector2.new(80, 80), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120), Size = NumberSequence.new({ NK(0, 6), NK(0.2, 10), NK(1, 0) }), Transparency = NumberSequence.new({ NK(0, 0.02), NK(1, 1) }), Color = ColorSequence.new(Color3.fromRGB(255, 222, 144), Color3.fromRGB(123, 111, 255)), LightEmission = 1, Acceleration = Vector3.new(0, -120, 0) }, att)
	sparks:Emit(330)
	local embers = new("ParticleEmitter", { Rate = 20, Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(8, 38), SpreadAngle = Vector2.new(48, 48), Size = NumberSequence.new({ NK(0, 3.4), NK(1, 0) }), Transparency = NumberSequence.new({ NK(0, 0.02), NK(1, 1) }), Color = ColorSequence.new(Color3.fromRGB(255, 129, 49), Color3.fromRGB(113, 91, 255)), LightEmission = 1, Acceleration = Vector3.new(0, 10, 0) }, att)
	task.delay(24, function() if embers.Parent then embers.Enabled = false end end)
	Debris:AddItem(anchor, 29)
	impactFlash = { t = os.clock(), a = isShooter and 0.22 or math.max(0.06, 0.22 * (1 - math.clamp(1 - (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - center).Magnitude or 0) / 2600, 0, 1))) }
	impactShake = { t = os.clock(), amp = isShooter and 11 or 3 * (1 - math.clamp(1 - (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - center).Magnitude or 0) / 2600, 0, 1)) }
	blastHumanoids(center)
	local record = { backups = {}, seen = {} }
	local folder = new("Folder", { Name = "SpaceCannonCrater" }, Workspace)
	record.folder = folder
	local surfaceY = function() return center.Y end
	if groundInst and groundInst:IsA("Terrain") then
		record.terrain, surfaceY = carveTerrain(center)
	elseif groundInst then
		local parent = groundInst.Parent
		record.seen[groundInst] = true
		surfaceY = carveGroundPart(groundInst, center, folder) or surfaceY
		table.insert(record.backups, { part = groundInst, parent = parent, cframe = groundInst.CFrame, anchored = groundInst.Anchored, transparency = groundInst.Transparency, canCollide = groundInst.CanCollide, canQuery = groundInst.CanQuery, canTouch = groundInst.CanTouch, material = groundInst.Material, color = groundInst.Color })
		groundInst.Parent = nil
	end
	craters[#craters + 1] = record
	if BLAST_PARTS then blastParts(center, groundInst, folder, record) end
	buildCosmicCraterDecor(center, folder, surfaceY)
	local debrisFolder = new("Folder", { Name = "SpaceCannonDebris" }, Workspace)
	Debris:AddItem(debrisFolder, 28)
	spawnRocks(center, debrisFolder, surfaceY)
	spawnSpires(center, folder, surfaceY)
	if RESTORE_AFTER > 0 then
		task.delay(RESTORE_AFTER, function()
			if state ~= "cinematic" then restoreAll(); restoreLighting() end
		end)
	end
end

local function buildStars(folder, GC)
	local palette = { Color3.fromRGB(190, 215, 255), Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 232, 190), Color3.fromRGB(255, 190, 140), Color3.fromRGB(160, 190, 255) }
	local bn = Vector3.new(0.35, 0.85, 0.4).Unit
	local e1 = bn:Cross(Vector3.yAxis).Unit
	local e2 = bn:Cross(e1).Unit
	local coreA = 1.2
	local shell = GALAXY_RADIUS * 2.9
	local detailed = TEXTURES.galaxyTop ~= nil
	local function addStar(dir, radius, sizeScale)
		local s = (detailed and 12 or 18) + (math.random() ^ 3) * (detailed and 34 or 62)
		s *= sizeScale
		vpart({ Name = "DeepSpaceStar", Shape = Enum.PartType.Ball, Size = Vector3.one * s, Position = GC + dir * radius, Material = Enum.Material.Neon, Color = palette[math.random(1, #palette)], Transparency = math.random() * 0.18 }, folder)
	end
	local shellCount = detailed and 680 or 1100
	for i = 1, shellCount do addStar(randDir(), shell + math.random() * GALAXY_RADIUS * 0.18, 0.8); if i % 170 == 0 then task.wait() end end
	local armCount = detailed and 980 or 1450
	local made = 0
	while made < armCount do
		local a = math.random() * math.pi * 2
		local da = math.abs(((a - coreA + math.pi) % (math.pi * 2)) - math.pi)
		if math.random() < 0.35 + 0.65 * math.exp(-da * da / 0.9) then
			local dir = (e1 * math.cos(a) + e2 * math.sin(a) + bn * gauss() * 0.2).Unit
			addStar(dir, shell - GALAXY_RADIUS * 0.04 + math.random() * GALAXY_RADIUS * 0.14, 1 + 0.35 * math.exp(-da * da / 0.9))
			made += 1
			if made % 170 == 0 then task.wait() end
		end
	end
	local hazeCount = detailed and 22 or 38
	local hazeColors = { Color3.fromRGB(100, 120, 255), Color3.fromRGB(255, 100, 170), Color3.fromRGB(255, 170, 90), Color3.fromRGB(110, 255, 230) }
	for i = 1, hazeCount do
		local a = math.random() * math.pi * 2
		local dir = (e1 * math.cos(a) + e2 * math.sin(a) + bn * gauss() * 0.12).Unit
		bigSphere(folder, GC + dir * (GALAXY_RADIUS * 2.62), GALAXY_RADIUS * (0.045 + math.random() * 0.035), hazeColors[math.random(1, #hazeColors)], Enum.Material.Neon, 0.965 + math.random() * 0.025)
	end
end

local function buildGalaxy(folder, GC)
	local ARMS, R = 4, GALAXY_RADIUS
	local textured = addTexturedGalaxyDisc(folder, GC + Vector3.new(0, 72, 0), R * 1.48)
	local brightCount = textured and 560 or 1150
	local dustCount = textured and 680 or 1050
	for i = 1, brightCount do
		local arm = i % ARMS
		local tt = math.random() ^ 0.68
		local r = tt * R + 120 * math.random()
		local ang = arm * (2 * math.pi / ARMS) + tt * 4.6 + gauss() * 0.19 * (1.2 - tt)
		local rr = r + gauss() * R * 0.018 * (0.4 + tt)
		local pos = GC + Vector3.new(math.cos(ang) * rr, 78 + gauss() * (R * 0.008 * (1 - tt) + 18), math.sin(ang) * rr)
		local size = (18 + math.random() * 66) * (1.1 - 0.42 * tt)
		local col = Color3.fromRGB(255, 225, 170):Lerp(Color3.fromRGB(255, 140, 150), clamp01(tt * 1.6)):Lerp(Color3.fromRGB(110, 150, 255), clamp01((tt - 0.5) * 2))
		vpart({ Name = "GalacticArmStar", Shape = Enum.PartType.Ball, Size = Vector3.one * size, Position = pos, Material = Enum.Material.Neon, Color = col, Transparency = 0.18 + 0.47 * math.random() }, folder)
		if i % 130 == 0 then task.wait() end
	end
	for i = 1, dustCount do
		local arm = i % ARMS
		local tt = math.random() ^ 0.82
		local ang = arm * (2 * math.pi / ARMS) + tt * 4.6 + gauss() * (textured and 0.32 or 0.25)
		local rr = tt * R + gauss() * R * 0.026
		local pos = GC + Vector3.new(math.cos(ang) * rr, 72 + gauss() * (R * 0.006), math.sin(ang) * rr)
		vpart({ Name = "GalacticDustStar", Shape = Enum.PartType.Ball, Size = Vector3.one * (10 + math.random() * 25), Position = pos, Material = Enum.Material.Neon, Color = Color3.fromRGB(190, 210, 255), Transparency = 0.28 + 0.34 * math.random() }, folder)
		if i % 160 == 0 then task.wait() end
	end
	for i = 1, 36 do
		local v = Vector3.new(gauss(), gauss() * 0.35, gauss()) * (R * 0.045)
		bigSphere(folder, GC + v, R * (0.018 + math.random() * 0.016), Color3.fromRGB(255, 210, 145), Enum.Material.Neon, 0.945 + math.random() * 0.035)
	end
	bigSphere(folder, GC + Vector3.new(0, 88, 0), R * 0.052, Color3.fromRGB(255, 220, 150), Enum.Material.Neon, 0.56)
	bigSphere(folder, GC + Vector3.new(0, 92, 0), R * 0.13, Color3.fromRGB(255, 150, 90), Enum.Material.Neon, 0.945)
end

local function landAt(n) return math.noise(n.X * 2.1 + 3.7, n.Y * 2.1 + 1.3, n.Z * 2.1 + 8.1) + 0.45 * math.noise(n.X * 5 + 1, n.Y * 5 + 2, n.Z * 5 + 3) > 0.04 end
local function cloudAt(n) return math.noise(n.X * 3.3 + 9.1, n.Y * 3.3 + 4.2, n.Z * 3.3 + 2.7) + 0.5 * math.noise(n.X * 8 + 5, n.Y * 8 + 6, n.Z * 8 + 7) > 0.12 end

local function plateOnSphere(folder, EC, n, r, w, color, material, transparency, thick)
	local p = EC + n * r
	return vpart({ Size = Vector3.new(w, w, thick or 2), CFrame = CFrame.lookAt(p, p + n), Color = color, Material = material or Enum.Material.SmoothPlastic, Transparency = transparency or 0 }, folder)
end

local function buildEarth(folder, EC)
	local ER = EARTH_RADIUS
	if TEXTURES.earth then
		local earth = texturedSphere(folder, EC, ER * 2, TEXTURES.earth, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 0, "BlueMarbleEarth")
		if earth then
			earth.Reflectance = 0.08
			local clouds = texturedSphere(folder, EC, ER * 2.013, TEXTURES.clouds, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 0, "AnimatedEarthCloudLayer")
			local night = texturedSphere(folder, EC, ER * 2.006, TEXTURES.earthLights, Color3.new(1, 1, 1), Enum.Material.Neon, 0, "EarthCityLights")
			local atmo1 = bigSphere(folder, EC, ER * 2.055, Color3.fromRGB(86, 166, 255), Enum.Material.Neon, 0.94)
			local atmo2 = bigSphere(folder, EC, ER * 2.13, Color3.fromRGB(80, 154, 255), Enum.Material.Neon, 0.973)
			return { earth = earth, clouds = clouds, night = night, atmosphere = { atmo1, atmo2 }, center = EC }
		end
	end
	local ocean = bigSphere(folder, EC, ER * 2, Color3.fromRGB(16, 64, 148), Enum.Material.SmoothPlastic, 0)
	ocean.Reflectance = 0.12
	local landCols = { Color3.fromRGB(58, 118, 56), Color3.fromRGB(76, 132, 62), Color3.fromRGB(150, 138, 84), Color3.fromRGB(104, 92, 60), Color3.fromRGB(40, 92, 52) }
	local placed, tries = 0, 0
	while placed < 430 and tries < 4200 do
		tries += 1
		local n = randDir()
		if landAt(n) then
			placed += 1
			local polar = math.abs(n.Y) > 0.86
			local col = polar and Color3.fromRGB(238, 244, 250) or landCols[math.random(1, #landCols)]
			plateOnSphere(folder, EC, n, ER * 1.0015, ER * (0.065 + math.random() * 0.07), col, Enum.Material.SmoothPlastic, 0, 2)
			if placed % 150 == 0 then task.wait() end
		end
	end
	placed, tries = 0, 0
	while placed < 240 and tries < 3600 do
		tries += 1
		local n = randDir()
		if cloudAt(n) then
			placed += 1
			plateOnSphere(folder, EC, n, ER * 1.014, ER * (0.12 + math.random() * 0.13), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 0.40 + math.random() * 0.28, 1.4)
			if placed % 120 == 0 then task.wait() end
		end
	end
	bigSphere(folder, EC, ER * 2.06, Color3.fromRGB(110, 175, 255), Enum.Material.Neon, 0.88)
	bigSphere(folder, EC, ER * 2.13, Color3.fromRGB(110, 175, 255), Enum.Material.Neon, 0.965)
	return { earth = ocean, center = EC }
end

local function buildMoon(folder, pos)
	local MR = EARTH_RADIUS * 0.29
	if TEXTURES.moon then
		local moon = texturedSphere(folder, pos, MR * 2, TEXTURES.moon, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 0, "LROCTexturedMoon")
		if moon then
			for i = 1, 10 do
				local n = randDir()
				vpart({ Name = "MoonCraterRim", Shape = Enum.PartType.Ball, Size = Vector3.new(MR * (0.12 + math.random() * 0.12), MR * 0.025, MR * (0.12 + math.random() * 0.12)), CFrame = CFrame.lookAt(pos + n * (MR * 1.002), pos + n * (MR * 2)), Color = Color3.fromRGB(120, 120, 118), Material = Enum.Material.SmoothPlastic, Transparency = 0.58 }, folder)
			end
			return moon
		end
	end
	bigSphere(folder, pos, MR * 2, Color3.fromRGB(150, 148, 144), Enum.Material.SmoothPlastic, 0)
	for _ = 1, 26 do
		local n = randDir()
		plateOnSphere(folder, pos, n, MR * 1.006, MR * (0.13 + math.random() * 0.3), Color3.fromRGB(96, 94, 92), Enum.Material.SmoothPlastic, 0, 0.8)
	end
end

local function buildSolarSystem(folder, EC, GC)
	local radial = (EC - GC).Unit
	local tangent = Vector3.new(-radial.Z, 0, radial.X)
	if tangent.Magnitude < 0.001 then tangent = Vector3.xAxis end
	tangent = tangent.Unit
	local sunPos = EC + tangent * EARTH_ORBIT_RADIUS
	local e1 = -tangent
	local e2 = Vector3.yAxis:Cross(e1).Unit
	local normal = e1:Cross(e2).Unit
	local sun = nil
	if TEXTURES.sun then sun = texturedSphere(folder, sunPos, SUN_RADIUS * 2, TEXTURES.sun, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, 0, "OriginalAtlasSun") end
	if not sun then sun = bigSphere(folder, sunPos, SUN_RADIUS * 2, Color3.fromRGB(255, 191, 92), Enum.Material.Neon, 0) end
	bigSphere(folder, sunPos, SUN_RADIUS * 2.09, Color3.fromRGB(255, 144, 65), Enum.Material.Neon, 0.945)
	bigSphere(folder, sunPos, SUN_RADIUS * 2.22, Color3.fromRGB(255, 200, 122), Enum.Material.Neon, 0.978)
	new("PointLight", { Color = Color3.fromRGB(255, 174, 90), Range = 60, Brightness = 5 }, sun)
	starFlare(sun, 170, Color3.fromRGB(255, 196, 126))
	if not TEXTURES.sun then
		for i = 1, 52 do
			local n = randDir()
			local col = (math.random() > 0.5 and Color3.fromRGB(255, 130, 55) or Color3.fromRGB(255, 225, 145))
			plateOnSphere(folder, sunPos, n, SUN_RADIUS * 1.002, 25 + math.random() * 54, col, Enum.Material.Neon, 0.30 + math.random() * 0.37, 5)
			if i % 26 == 0 then task.wait() end
		end
	end
	local planetDefs = {
		{ name = "Mercury", orbit = 1800, radius = 18, angle = math.rad(62), color = Color3.fromRGB(156, 151, 144) },
		{ name = "Venus", orbit = 2550, radius = 35, angle = math.rad(137), color = Color3.fromRGB(219, 176, 113) },
		{ name = "Earth", orbit = EARTH_ORBIT_RADIUS, radius = EARTH_RADIUS, angle = 0, color = Color3.fromRGB(65, 145, 255) },
		{ name = "Mars", orbit = 4700, radius = 43, angle = math.rad(213), color = Color3.fromRGB(195, 90, 63) },
		{ name = "Jupiter", orbit = 6200, radius = 245, angle = math.rad(298), color = Color3.fromRGB(207, 174, 143) },
		{ name = "Saturn", orbit = 7550, radius = 205, angle = math.rad(158), color = Color3.fromRGB(222, 199, 145) },
		{ name = "Uranus", orbit = 8750, radius = 132, angle = math.rad(326), color = Color3.fromRGB(139, 215, 220) },
		{ name = "Neptune", orbit = 9950, radius = 124, angle = math.rad(238), color = Color3.fromRGB(75, 112, 232) },
	}
	local function orbitalPoint(distance, angle, center)
		center = center or sunPos
		return center + e1 * (math.cos(angle) * distance) + e2 * (math.sin(angle) * distance)
	end
	local function orbitLine(center, distance, segments, color, thickness, transparency, angleStart)
		local startAngle = angleStart or 0
		local prev = orbitalPoint(distance, startAngle, center)
		for i = 1, segments do
			local a = startAngle + (i / segments) * math.pi * 2
			local nextPoint = orbitalPoint(distance, a, center)
			local delta = nextPoint - prev
			local mid = (prev + nextPoint) * 0.5
			vpart({ Name = "EclipticOrbitLine", Size = Vector3.new(thickness, thickness, delta.Magnitude + thickness), CFrame = CFrame.lookAt(mid, nextPoint), Color = color, Material = Enum.Material.Neon, Transparency = transparency }, folder)
			prev = nextPoint
			if i % 16 == 0 then task.wait() end
		end
	end
	for i, spec in ipairs(planetDefs) do
		local col = i == 3 and Color3.fromRGB(90, 175, 255) or Color3.fromRGB(119, 145, 174)
		orbitLine(sunPos, spec.orbit, 36, col, math.max(1.1, spec.orbit * 0.00025), i == 3 and 0.40 or 0.68, 0)
	end
	for _, spec in ipairs(planetDefs) do
		if spec.name ~= "Earth" then
			local pos = orbitalPoint(spec.orbit, spec.angle)
			local texture = TEXTURES[string.lower(spec.name)]
			local material = spec.name == "Sun" and Enum.Material.Neon or Enum.Material.SmoothPlastic
			local body = texture and texturedSphere(folder, pos, spec.radius * 2, texture, Color3.new(1, 1, 1), material, 0, spec.name .. "TextureMap") or nil
			if not body then body = bigSphere(folder, pos, spec.radius * 2, spec.color, Enum.Material.SmoothPlastic, 0) end
			if spec.name == "Venus" then bigSphere(folder, pos, spec.radius * 2.09, Color3.fromRGB(255, 194, 113), Enum.Material.Neon, 0.95)
			elseif spec.name == "Mars" then bigSphere(folder, pos, spec.radius * 2.10, Color3.fromRGB(255, 103, 75), Enum.Material.Neon, 0.95)
			elseif spec.name == "Saturn" then
				for j = 1, 4 do
					local colors = { Color3.fromRGB(218, 199, 160), Color3.fromRGB(146, 125, 96), Color3.fromRGB(232, 215, 180), Color3.fromRGB(105, 93, 77) }
					orbitLine(pos, spec.radius * (1.34 + j * 0.19), 40, colors[j], 3.4 + (j % 2), 0.22 + (j % 2) * 0.10, math.rad(j * 4))
				end
			elseif spec.name == "Jupiter" and not texture then
				for j = 1, 20 do
					local n = randDir()
					local band = (j % 3 == 0) and Color3.fromRGB(153, 105, 82) or Color3.fromRGB(238, 211, 175)
					plateOnSphere(folder, pos, n, spec.radius * 1.006, spec.radius * (0.06 + math.random() * 0.1), band, Enum.Material.SmoothPlastic, 0.20 + math.random() * 0.18, 2)
				end
			end
		end
	end
	local asteroidCount = 105
	for i = 1, asteroidCount do
		local a = math.random() * math.pi * 2
		local r = 5480 + math.random() * 460
		local pos = sunPos + e1 * (math.cos(a) * r) + e2 * (math.sin(a) * r) + normal * gauss() * 160
		local size = 7 + math.random() * 23
		vpart({ Name = "AsteroidBeltRock", Size = Vector3.new(size * (0.65 + math.random() * 0.75), size * (0.5 + math.random() * 0.6), size * (0.65 + math.random() * 0.8)), CFrame = CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6), Color = Color3.fromRGB(77 + math.random(0, 35), 73 + math.random(0, 28), 70 + math.random(0, 24)), Material = Enum.Material.Slate }, folder)
		if i % 35 == 0 then task.wait() end
	end
	return { sun = sun, sunPos = sunPos, sunDir = (sunPos - EC).Unit, earthOrbit = EARTH_ORBIT_RADIUS, normal = normal }
end

local function buildCannon(folder, cf)
	local SCALE = 40
	local C = { coils = {}, coilGlow = {}, railSegments = {}, moving = {}, navLights = {}, arcBeams = {}, emitterParts = {} }
	local model = new("Model", { Name = "OriginalStyleStarDestroyer" }, folder)
	model.WorldPivot = cf
	C.model = model
	C.baseCF = cf
	local root = model
	local HULL = Color3.fromRGB(28, 31, 39)
	local HULL_LIT = Color3.fromRGB(48, 52, 62)
	local METAL = Color3.fromRGB(129, 136, 148)
	local METAL_DARK = Color3.fromRGB(68, 74, 86)
	local DARK = Color3.fromRGB(14, 17, 23)
	local GOLD = Color3.fromRGB(191, 148, 62)
	local GOLD_LIT = Color3.fromRGB(255, 205, 112)
	local RED_OFF = Color3.fromRGB(72, 12, 20)
	local RED = Color3.fromRGB(235, 28, 42)
	local HOT = Color3.fromRGB(255, 225, 218)
	local function L(x, y, z) return Vector3.new(x * SCALE, y * SCALE, z * SCALE) end
	local function cfL(x, y, z, rz, ry, rx) return CFrame.new(L(x, y, z)) * CFrame.Angles(rx or 0, ry or 0, rz or 0) end
	local function box(name, x, y, z, sx, sy, sz, col, mat, rz, ry, rx, transparency)
		return vpart({ Name = name or "CannonPanel", Size = L(sx, sy, sz), Color = col or HULL, Material = mat or Enum.Material.Metal, Transparency = transparency or 0, CFrame = cf * cfL(x, y, z, rz, ry, rx) }, root)
	end
	local function axialCylinder(name, z, radius, length, col, mat, transparency)
		return vpart({ Name = name or "AxialCylinder", Shape = Enum.PartType.Cylinder, Size = Vector3.new(length * SCALE, radius * 2 * SCALE, radius * 2 * SCALE), Color = col or HULL, Material = mat or Enum.Material.Metal, Transparency = transparency or 0, CFrame = cf * CFrame.new(0, 0, z * SCALE) * CFrame.Angles(0, math.rad(90), 0) }, root)
	end
	local function sphere(name, x, y, z, radius, col, mat, transparency)
		return vpart({ Name = name or "CannonCore", Shape = Enum.PartType.Ball, Size = Vector3.one * (radius * 2 * SCALE), Position = (cf * CFrame.new(L(x, y, z))).Position, Color = col or HULL, Material = mat or Enum.Material.Metal, Transparency = transparency or 0 }, root)
	end
	local function octRing(name, z, outer, inner, thickness, col, mat, targetList, transparency)
		local parts = {}
		for i = 0, 7 do
			local a = i * math.pi / 4
			local mid = (outer + inner) * 0.5
			local tangential = 2 * outer * math.tan(math.pi / 8) * 1.04
			parts[#parts + 1] = box(name, math.cos(a) * mid, math.sin(a) * mid, z, outer - inner, tangential, thickness, col, mat, a, 0, 0, transparency)
		end
		if targetList then targetList[#targetList + 1] = parts end
		return parts
	end
	local function octLine(name, z, radius, width, col, targetList, transparency)
		local parts = {}
		local outer = radius + width * 0.5; local inner = radius - width * 0.5
		for i = 0, 7 do
			local a = i * math.pi / 4
			local mid = (outer + inner) * 0.5
			local tangential = 2 * radius * math.tan(math.pi / 8) * 1.08
			parts[#parts + 1] = box(name, math.cos(a) * mid, math.sin(a) * mid, z, width, tangential, math.max(width * 0.75, 0.025), col, Enum.Material.Neon, a, 0, 0, transparency or 0.2)
		end
		if targetList then targetList[#targetList + 1] = parts end
		return parts
	end
	local function barBetween(name, a, b, width, depth, col, mat)
		local p0 = cf:PointToWorldSpace(L(a.X, a.Y, a.Z))
		local p1 = cf:PointToWorldSpace(L(b.X, b.Y, b.Z))
		local delta = p1 - p0
		local mid = (p0 + p1) * 0.5
		return vpart({ Name = name or "CannonStrut", Size = Vector3.new(width * SCALE, depth * SCALE, delta.Magnitude), Color = col or METAL_DARK, Material = mat or Enum.Material.Metal, CFrame = CFrame.lookAt(mid, p1) }, root)
	end
	local function ringDots(name, z, radius, count, dotRadius, col, mat, targetList)
		local list = {}
		for i = 0, count - 1 do
			local a = i * math.pi * 2 / count
			list[#list + 1] = sphere(name, math.cos(a) * radius, math.sin(a) * radius, z, dotRadius, col, mat)
		end
		if targetList then targetList[#targetList + 1] = list end
		return list
	end

	C.recoilPart = box("InternalRecoilAnchor", 0, 0, -3.1, 0.01, 0.01, 0.01, HULL, Enum.Material.SmoothPlastic, 0, 0, 0, 1)
	axialCylinder("OctagonalBarrelCore", -6.3, 0.64, 19.2, HULL, Enum.Material.Metal)
	for i = 0, 7 do
		local a = i * math.pi / 4
		box("BarrelArmorFacet", math.cos(a) * 0.55, math.sin(a) * 0.55, -6.25, 0.28, 0.44, 18.8, HULL_LIT, Enum.Material.Metal, a)
		box("BarrelPanelSeam", math.cos(a) * 0.693, math.sin(a) * 0.693, -6.2, 0.035, 0.06, 17.8, METAL_DARK, Enum.Material.Metal, a)
	end
	for k = 0, 16 do
		local z = -14.5 + k * 1.05
		local heavy = (k % 4 == 0)
		local outer = heavy and 1.62 or 1.38
		local axial = heavy and 0.24 or 0.11
		local main = octRing("InductionCoilHousing", z, outer, 1.0, axial, k % 4 == 0 and METAL or METAL_DARK, Enum.Material.Metal)
		local innerGlow = octLine("CoilInnerFluxTrack", z, 1.045, 0.045, RED_OFF, nil, 0.2)
		local grooveGlow = octLine("CoilOuterFluxGroove", z, heavy and 1.30 or 1.20, 0.035, RED_OFF, nil, 0.35)
		local clamps = {}
		if heavy then
			for i = 0, 7 do
				local a = i * math.pi / 4
				clamps[#clamps + 1] = box("CoilClamp", math.cos(a) * (outer + 0.10), math.sin(a) * (outer + 0.10), z, 0.19, 0.26, 0.40, METAL, Enum.Material.Metal, a)
			end
		end
		C.coils[#C.coils + 1] = { z = z, main = main, inner = innerGlow, groove = grooveGlow, clamps = clamps, k = k, heavy = heavy }
	end
	for _, sy in ipairs({ -1, 1 }) do
		box("UpperLowerGuideRail", 0, sy * 0.80, -6.55, 0.60, 0.32, 19.9, METAL_DARK, Enum.Material.Metal)
		box("GuideRailInset", 0, sy * 0.80 + sy * 0.13, -6.55, 0.18, 0.07, 19.4, RED_OFF, Enum.Material.Neon, 0, 0, 0, 0.28)
	end
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			local conduit = axialCylinder("PowerConduit", -5.8, 0.075, 18.4, METAL_DARK, Enum.Material.Metal)
			conduit.CFrame = cf * CFrame.new(sx * 1.5 * SCALE, sy * 0.52 * SCALE, -5.8 * SCALE) * CFrame.Angles(0, math.rad(90), 0)
			local railParts = {}
			for k = 0, 16 do
				local z = -14.6 + k * 1.05
				railParts[#railParts + 1] = box("SequentialPowerRail", sx * 1.5, sy * 0.52, z, 0.095, 0.095, 0.68, RED_OFF, Enum.Material.Neon, 0, 0, 0, 0.26)
			end
			C.railSegments[#C.railSegments + 1] = { sideX = sx, sideY = sy, parts = railParts }
		end
	end
	for i = 0, 7 do
		local a = i * math.pi / 4
		local x, y = math.cos(a), math.sin(a)
		barBetween("BarrelTrussLongitudinal", Vector3.new(x * 1.90, y * 1.90, -15.2), Vector3.new(x * 1.90, y * 1.90, 3.2), 0.075, 0.075, DARK)
		for k = 0, 16 do
			local z = -14.5 + k * 1.05
			local r = 1.84
			box("TrussCrossBrace", math.cos(a) * r, math.sin(a) * r, z, 0.07, 0.07, 0.15, METAL_DARK, Enum.Material.Metal, a)
		end
	end
	local muzzleRing = octRing("MuzzleArmorCollar", -16.1, 1.55, 0.62, 0.90, HULL_LIT, Enum.Material.Metal)
	octRing("MuzzleForwardBezel", -16.36, 1.31, 0.62, 0.20, METAL_DARK, Enum.Material.Metal)
	octLine("MuzzleRedAnnulus", -16.20, 1.24, 0.055, RED_OFF, nil, 0.12)
	axialCylinder("MuzzleLensHousing", -15.75, 0.60, 0.20, DARK, Enum.Material.Metal)
	local lens = axialCylinder("ChargingLens", -15.87, 0.49, 0.035, RED, Enum.Material.Neon, 0.06)
	C.lens = lens
	for i = 0, 15 do
		local a = i * math.pi * 2 / 16
		local r = 1.47
		box("MuzzleVent", math.cos(a) * r, math.sin(a) * r, -16.1, 0.11, 0.07, 0.34, DARK, Enum.Material.Metal, a)
	end
	for i = 0, 5 do
		local a = i * math.pi / 3 + math.pi / 6
		local function prongPiece(z, rad, width, depth, length, tone)
			return box("SixClawEmitterProng", math.cos(a) * rad, math.sin(a) * rad, z, width, depth, length, tone, Enum.Material.Metal, a)
		end
		prongPiece(-17.10, 1.00, 0.17, 0.23, 1.45, METAL_DARK)
		prongPiece(-18.40, 0.79, 0.10, 0.16, 1.30, METAL)
		local line = box("ClawEmitterRedLine", math.cos(a) * 0.91, math.sin(a) * 0.91, -18.10, 0.035, 0.04, 1.75, RED_OFF, Enum.Material.Neon, a, 0, 0, 0.15)
		C.emitterParts[#C.emitterParts + 1] = line
	end
	ringDots("MuzzleTipMicroSegments", -19.08, 0.70, 24, 0.048, METAL, Enum.Material.Metal)
	ringDots("MuzzleTipFluxSegments", -19.10, 0.62, 24, 0.026, RED_OFF, Enum.Material.Neon)
	C.muzzleCF = cf * CFrame.new(0, 0, -19.2 * SCALE)
	for i = 0, 7 do
		local a = i * math.pi / 4
		box("RearOctagonalBodyPanel", math.cos(a) * 1.46, math.sin(a) * 1.46, 5.75, 0.56, 1.12, 4.4, HULL_LIT, Enum.Material.Metal, a)
	end
	axialCylinder("RearBodyCore", 5.75, 1.82, 4.8, HULL, Enum.Material.Metal)
	octRing("RearBodyHexFlange", 3.35, 1.5, 0.50, 0.40, METAL, Enum.Material.Metal)
	octRing("RearGoldSeal", 6.92, 2.00, 1.82, 0.36, GOLD, Enum.Material.Metal)
	octRing("RearArmorPlate", 12.0, 2.2, 0.45, 0.44, HULL_LIT, Enum.Material.Metal)
	axialCylinder("ReactorCoreMount", 10.0, 1.05, 1.8, DARK, Enum.Material.Metal)
	local core = sphere("ReactorGoldCore", 0, 0, 10.0, 1.05, GOLD, Enum.Material.Metal)
	core.Reflectance = 0.22
	C.reactor = core
	ringDots("ReactorTorusGold", 10.0, 1.75, 28, 0.21, GOLD_LIT, Enum.Material.Metal)
	for i = 0, 5 do
		local a = i * math.pi / 3
		barBetween("ReactorRadialSupport", Vector3.new(math.cos(a) * 1.2, math.sin(a) * 1.2, 10.0), Vector3.new(math.cos(a) * 2.35, math.sin(a) * 2.35, 10.0), 0.11, 0.11, DARK)
	end
	box("CommandBridge", 0, 2.30, 5.10, 1.44, 0.96, 2.70, DARK, Enum.Material.Metal)
	box("CommandBridgeGlass", 0, 2.78, 5.10, 1.12, 0.055, 2.08, Color3.fromRGB(110, 190, 215), Enum.Material.Glass, 0, 0, 0, 0.32)
	for _, sx in ipairs({ -1, 1 }) do box("BridgeFrameRail", sx * 0.82, 2.35, 5.10, 0.12, 1.42, 2.55, METAL_DARK, Enum.Material.Metal) end
	for _, sx in ipairs({ -1, 1 }) do
		for _, yy in ipairs({ -0.74, 0, 0.74 }) do
			local cap = axialCylinder("BodyCoolingCanister", 5.6, 0.30, 4.05, METAL_DARK, Enum.Material.Metal)
			cap.CFrame = cf * CFrame.new(sx * 2.55 * SCALE, yy * SCALE, 5.6 * SCALE) * CFrame.Angles(0, math.rad(90), 0)
			for rib = -2, 2 do
				local band = axialCylinder("CoolingCanisterRib", 5.6 + rib * 0.62, 0.335, 0.10, METAL, Enum.Material.Metal)
				band.CFrame = cf * CFrame.new(sx * 2.55 * SCALE, yy * SCALE, (5.6 + rib * 0.62) * SCALE) * CFrame.Angles(0, math.rad(90), 0)
			end
		end
	end
	for _, z in ipairs({ 4.6, 6.9, 12.0 }) do
		for i = 0, 7 do
			local a = i * math.pi / 4
			box("ArmorSeam", math.cos(a) * 1.93, math.sin(a) * 1.93, z, 0.035, 0.05, 0.045, METAL, Enum.Material.Metal, a)
		end
	end
	for i = 0, 3 do
		local a = math.pi / 4 + i * math.pi / 2
		box("RadiatorOuterSpine", math.cos(a) * 5.15, math.sin(a) * 5.15, 8.1, 0.14, 0.14, 7.1, METAL_DARK, Enum.Material.Metal, a)
		box("RadiatorInnerSpine", math.cos(a) * 2.72, math.sin(a) * 2.72, 8.1, 0.16, 0.16, 6.8, DARK, Enum.Material.Metal, a)
		for _, side in ipairs({ -1, 1 }) do
			box("RadiatorSideFrame", math.cos(a) * 5.15 - math.sin(a) * side * 2.42, math.sin(a) * 5.15 + math.cos(a) * side * 2.42, 8.1, 4.9, 0.12, 0.14, DARK, Enum.Material.Metal, a)
		end
		for j = 0, 13 do
			local z = 4.85 + j * 0.50
			local slat = box("RadiatorThermalSlat", math.cos(a) * 5.15, math.sin(a) * 5.15, z, 4.75, 0.045, 0.34, j % 3 == 0 and METAL_DARK or Color3.fromRGB(91, 95, 102), Enum.Material.Metal, a)
			if j % 3 == 0 then
				local hotLine = box("RadiatorHeatTrace", math.cos(a) * 5.15, math.sin(a) * 5.15, z, 4.3, 0.018, 0.035, RED_OFF, Enum.Material.Neon, a, 0, 0, 0.45)
				C.emitterParts[#C.emitterParts + 1] = hotLine
			end
		end
	end
	for face = 0, 7 do
		local a = face * math.pi / 4
		local ux, uy = math.cos(a), math.sin(a)
		for k = 0, 15 do
			local z = -13.95 + k * 1.05
			box("InductionRailArmorLink", ux * 1.47, uy * 1.47, z, 0.095, 0.19, 0.44, k % 4 == 0 and METAL or HULL_LIT, Enum.Material.Metal, a)
			if k % 2 == 0 then box("InductionRailFastener", ux * 1.57, uy * 1.57, z, 0.065, 0.065, 0.09, GOLD, Enum.Material.Metal, a) end
		end
	end
	for face = 0, 5 do
		local a = face * math.pi / 3 + math.pi / 6
		local ux, uy = math.cos(a), math.sin(a)
		box("ReactorArmorShoulder", ux * 2.34, uy * 2.34, 8.55, 0.42, 1.08, 3.05, HULL_LIT, Enum.Material.Metal, a)
		box("ReactorShoulderGoldInlay", ux * 2.58, uy * 2.58, 8.55, 0.045, 0.76, 2.28, GOLD, Enum.Material.Metal, a)
		for rib = 0, 2 do box("ReactorShoulderVent", ux * 2.64, uy * 2.64, 7.82 + rib * 0.72, 0.055, 0.22, 0.10, DARK, Enum.Material.Metal, a) end
	end
	for _, sx in ipairs({ -1, 1 }) do
		local col = sx < 0 and Color3.fromRGB(255, 48, 56) or Color3.fromRGB(50, 255, 140)
		local nav = sphere("NavigationBeacon", sx * 7.68, 0, 8.1, 0.12, col, Enum.Material.Neon)
		local pl = new("PointLight", { Color = col, Range = 110, Brightness = 0.55 }, nav)
		C.navLights[#C.navLights + 1] = { part = nav, light = pl, base = col, side = sx }
	end
	for i = 0, 5 do
		local a = i * math.pi / 3
		local p = box("RearGantryArm", math.cos(a) * 2.7, math.sin(a) * 2.7, -1.3, 0.18, 0.18, 13.8, METAL_DARK, Enum.Material.Metal, a)
		C.moving[#C.moving + 1] = { part = p, localCF = cfL(math.cos(a) * 2.7, math.sin(a) * 2.7, -1.3, a), phase = a }
	end
	local chargeOrb = sphere("ChargeSingularity", 0, 0, -17.4, 0.12, RED, Enum.Material.Neon)
	C.orb = chargeOrb
	C.orbLight = new("PointLight", { Color = RED, Range = 110, Brightness = 0.2 }, chargeOrb)
	C.orbFlare = starFlare(chargeOrb, 28, Color3.fromRGB(255, 140, 132))
	local centerAtt = new("Attachment", { Name = "ChargeCoreAttachment", Position = Vector3.zero }, chargeOrb)
	for i = 0, 5 do
		local a = i * math.pi / 3
		local att = new("Attachment", { Name = "ArcOrigin", Position = Vector3.new(math.cos(a) * 0.82 * SCALE, math.sin(a) * 0.82 * SCALE, (math.sin(a * 2) * 0.16) * SCALE) }, chargeOrb)
		local beam = makeBeam(root, att, centerAtt, 0, HOT, 0.03)
		beam.Segments = 10
		beam.CurveSize0 = (math.random() - 0.5) * 24 * SCALE / 10
		beam.CurveSize1 = (math.random() - 0.5) * 20 * SCALE / 10
		beam.Enabled = false
		C.arcBeams[#C.arcBeams + 1] = beam
	end
	local chargeShell = vpart({ Name = "ChargeParticleEmitterVolume", Shape = Enum.PartType.Ball, Size = Vector3.one * (3.8 * SCALE), Transparency = 1, Position = chargeOrb.Position }, root)
	local okEmitter, emitter = pcall(function()
		return new("ParticleEmitter", { Name = "StarGunInflow", Rate = 0, Lifetime = NumberRange.new(0.25, 0.8), Speed = NumberRange.new(70, 150), Drag = 1.5, SpreadAngle = Vector2.new(180, 180), Size = NumberSequence.new({ NK(0, 4), NK(0.45, 10), NK(1, 0) }), Transparency = NumberSequence.new({ NK(0, 0.15), NK(0.7, 0.35), NK(1, 1) }), Color = ColorSequence.new(Color3.fromRGB(255, 80, 75), Color3.fromRGB(255, 238, 230)), LightEmission = 1, Shape = Enum.ParticleEmitterShape.Sphere, ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward, ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface }, chargeShell)
	end)
	C.chargeEm = okEmitter and emitter or nil
	C.reactorLight = new("PointLight", { Color = GOLD_LIT, Range = 180, Brightness = 0.6 }, core)
	local lastDetailUpdate = -1e9
	local lastX = -1
	local lastRecoil = -1e9
	function C.update(x, t)
		x = clamp01(x or 0)
		local pulse = 0.5 + 0.5 * math.sin(t * (30 + x * 42))
		local front = 3.4 - 19.8 * clamp01(x * 2)
		local recoil = t >= T.fireT and (1.4 * (1 - math.exp(-math.max(t - T.fireT, 0) * 14)) * math.exp(-math.max(t - T.fireT, 0) * 0.8)) or 0
		if math.abs(recoil - lastRecoil) > 0.002 then
			model:PivotTo(cf * CFrame.new(0, 0, recoil * SCALE))
			lastRecoil = recoil
		end
		C.muzzleCF = cf * CFrame.new(0, 0, (-19.2 + recoil) * SCALE)
		local updateDetails = (t - lastDetailUpdate) > 0.045 or math.abs(x - lastX) > 0.012
		if updateDetails then
			lastDetailUpdate = t
			lastX = x
			for _, c in ipairs(C.coils) do
				local z = c.z
				local wave = math.exp(-((z - front) / 0.7) ^ 2)
				local lit = smooth(clamp01((z - front + 0.3) / 0.9)) * clamp01(x * 2)
				local awake = 0.08 + 0.10 * (0.5 + 0.5 * math.sin(t * 2 + c.k * 0.32))
				local glow = clamp01(awake + lit * 0.72 + wave * 0.7 + (t >= T.fireT and 0.5 * math.exp(-(t - T.fireT) * 5) or 0))
				local tone = METAL_DARK:Lerp(METAL, 0.25 + glow * 0.70)
				for _, p in ipairs(c.main) do p.Color = tone end
				for _, p in ipairs(c.inner) do p.Color = RED:Lerp(HOT, clamp01(wave * 0.75 + lit * 0.4)); p.Transparency = 0.56 - 0.50 * glow end
				for _, p in ipairs(c.groove) do p.Color = RED:Lerp(HOT, clamp01(wave * 0.88 + lit * 0.26)); p.Transparency = 0.72 - 0.63 * clamp01(wave + lit * 0.6) end
				for _, p in ipairs(c.clamps) do p.Color = METAL_DARK:Lerp(GOLD_LIT, clamp01(wave * 0.24 + lit * 0.12)) end
			end
			for _, railGroup in ipairs(C.railSegments) do
				for _, p in ipairs(railGroup.parts) do
					local localZ = cf:PointToObjectSpace(p.Position).Z / SCALE
					local wave = math.exp(-((localZ - front) / 0.95) ^ 2)
					local lit = smooth(clamp01((localZ - front + 0.3) / 1.0)) * clamp01(x * 2)
					p.Color = RED:Lerp(HOT, clamp01(wave * 0.95 + lit * 0.24))
					p.Transparency = 0.76 - 0.65 * clamp01(wave + lit * 0.8)
				end
			end
			for _, p in ipairs(C.emitterParts) do p.Color = RED:Lerp(HOT, clamp01(x * 0.75 + pulse * 0.2)); p.Transparency = 0.38 - 0.30 * x end
			for _, info in ipairs(C.navLights) do
				local blink = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(t * (info.side < 0 and 4.1 or 3.2)))
				info.part.Transparency = 0.05 + (1 - blink) * 0.25
				info.light.Brightness = 0.25 + blink * 1.4
			end
		end
		local radius = 0.12 + x ^ 1.2 * 1.55 * (0.9 + 0.1 * pulse)
		C.orb.Size = Vector3.one * (radius * 2 * SCALE)
		C.orb.Color = RED:Lerp(HOT, clamp01(x * x * 0.9 + pulse * x * 0.2))
		C.orbLight.Brightness = 0.2 + x * x * 12
		C.orbLight.Range = 45 + x * 190
		C.orbFlare.Size = UDim2.fromOffset(28 + x * 112, 28 + x * 112)
		C.orbFlare.Enabled = x > 0.12 and t < T.fireT + 0.3
		if C.chargeEm then C.chargeEm.Rate = 140 * x * x end
		for i, beam in ipairs(C.arcBeams) do
			local nearCharge = clamp01((x - 0.48) / 0.52)
			beam.Enabled = nearCharge > 0.04 and t < T.fireT + 0.08
			local w = (0.55 + 2.2 * nearCharge) * (0.55 + 0.45 * math.noise(t * 17, i, 2))
			beam.Width0 = w
			beam.Width1 = 0.08 + w * 0.22
			beam.Color = ColorSequence.new(Color3.fromRGB(255, 80, 72):Lerp(HOT, clamp01(nearCharge * 0.8 + pulse * 0.2)))
			beam.CurveSize0 = math.sin(t * 21 + i * 2.4) * (4 + nearCharge * 14)
			beam.CurveSize1 = math.cos(t * 16 + i * 1.7) * (3 + nearCharge * 10)
		end
		C.lens.Color = RED:Lerp(HOT, clamp01(x * 0.95 + pulse * x * 0.15))
		C.lens.Transparency = 0.28 - 0.24 * x
		C.reactorLight.Brightness = 0.4 + 1.8 * x
	end
	return C
end

local function makeGroundStrikeMarker(parent, center, normal, radius)
	local folder = new("Folder", { Name = "StarBeamGroundLock" }, parent)
	local n = normal.Unit
	local u = n:Cross(Vector3.yAxis)
	if u.Magnitude < 0.01 then u = n:Cross(Vector3.xAxis) end
	u = u.Unit
	local v = n:Cross(u).Unit
	local cyan = Color3.fromRGB(255, 90, 83)
	local hot = Color3.fromRGB(255, 229, 220)
	local deep = Color3.fromRGB(135, 20, 30)
	local rings = {}
	local function addRing(name, r, count, width, coverage, color, baseTransparency, speed, phase)
		local entry = { radius = r, count = count, color = color, transparency = baseTransparency, speed = speed, phase = phase or 0, parts = {} }
		for i = 0, count - 1 do
			local a = i * math.pi * 2 / count
			local len = math.max(0.15, 2 * math.pi * r / count * coverage)
			local p = vpart({ Name = name, Size = Vector3.new(width, 0.85, len), Color = color, Material = Enum.Material.Neon, Transparency = baseTransparency }, folder)
			entry.parts[#entry.parts + 1] = { part = p, angle = a, length = len }
		end
		rings[#rings + 1] = entry
	end
	addRing("OuterTargetArc", radius, 56, 1.7, 0.54, cyan, 0.18, -0.10, 0)
	addRing("BearingScaleArc", radius * 0.72, 40, 1.15, 0.43, hot, 0.28, 0.18, 0.12)
	addRing("InnerScanningArc", radius * 0.43, 28, 1.35, 0.52, cyan, 0.17, -0.28, 0.31)
	addRing("NarrowLockArc", radius * 0.22, 20, 1.0, 0.35, hot, 0.10, 0.42, 0.06)
	local ticks = {}
	for i = 0, 15 do
		local a = i * math.pi * 2 / 16
		local major = i % 4 == 0
		local len = major and radius * 0.085 or radius * 0.042
		local p = vpart({ Name = major and "TargetBearingMajorTick" or "TargetBearingMinorTick", Size = Vector3.new(major and 1.55 or 0.9, 0.8, len), Color = major and hot or cyan, Material = Enum.Material.Neon, Transparency = major and 0.05 or 0.24 }, folder)
		ticks[#ticks + 1] = { part = p, angle = a, length = len, radius = radius * 0.91 }
	end
	local brackets = {}
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		for j = 1, 2 do
			local p = vpart({ Name = "TargetCornerBracket", Size = Vector3.new(1.7, 0.9, j == 1 and radius * 0.10 or radius * 0.065), Color = j == 1 and hot or cyan, Material = Enum.Material.Neon, Transparency = 0.07 + j * 0.08 }, folder)
			brackets[#brackets + 1] = { part = p, angle = a, radial = j == 1, radius = radius * 0.59 }
		end
	end
	local dot = vpart({ Name = "GroundStrikeLockPoint", Shape = Enum.PartType.Ball, Size = Vector3.one * 4.4, Color = hot, Material = Enum.Material.Neon }, folder)
	local light = new("PointLight", { Color = cyan, Range = 65, Brightness = 0.55 }, dot)
	local function putSegment(part, angle, r, len, rotation, lift)
		local tangent = -u * math.sin(angle) + v * math.cos(angle)
		local point = center + u * (math.cos(angle) * r) + v * (math.sin(angle) * r) + n * (lift or 1.0)
		local cfPart = CFrame.lookAt(point, point + tangent, n)
		if rotation and rotation ~= 0 then cfPart = cfPart * CFrame.Angles(0, 0, rotation) end
		part.CFrame = cfPart
		part.Size = Vector3.new(part.Size.X, part.Size.Y, len)
	end
	local marker = {}
	function marker.update(t)
		for _, ring in ipairs(rings) do
			local rot = ring.phase + t * ring.speed
			local scale = ring.radius == radius * 0.43 and (0.95 + 0.08 * math.sin(t * 2.8)) or 1
			for _, item in ipairs(ring.parts) do
				local angle = item.angle + rot
				local pulse = 0.5 + 0.5 * math.sin(t * 3.2 + item.angle * 3)
				putSegment(item.part, angle, ring.radius * scale, item.length, 0, 0.85 + pulse * 0.35)
				item.part.Color = ring.color:Lerp(hot, 0.24 * pulse)
				item.part.Transparency = math.clamp(ring.transparency + (1 - pulse) * 0.10, 0, 0.9)
			end
		end
		for _, item in ipairs(ticks) do putSegment(item.part, item.angle, item.radius, item.length, 0, 1.25) end
		for _, item in ipairs(brackets) do
			local angle = item.angle + (item.radial and 0 or 0.03 * math.sin(t * 1.7))
			putSegment(item.part, angle, item.radius, item.part.Size.Z, item.radial and 0 or math.pi * 0.5, 1.6)
		end
		dot.Position = center + n * 2.1
		dot.Color = deep:Lerp(hot, 0.62 + 0.38 * (0.5 + 0.5 * math.sin(t * 6)))
		light.Brightness = 0.25 + 0.7 * (0.5 + 0.5 * math.sin(t * 4.5))
	end
	function marker.destroy() folder:Destroy() end
	marker.update(0)
	return marker
end

local function buildStage(stage)
	local folder = new("Folder", { Name = "SpaceStage" }, Workspace)
	stage.folder = folder
	local GC = SPACE_ORIGIN
	local CP = GC + Vector3.new(18000, 1200, 9000)
	local fwd = Vector3.new(-0.78, -0.02, -0.2).Unit
	local cannonCF = CFrame.lookAt(CP, CP + fwd)
	local EC = CP + fwd * 5200 + cannonCF.RightVector * -500 + cannonCF.UpVector * -150
	stage.GC, stage.CP, stage.cannonCF, stage.EC = GC, CP, cannonCF, EC
	local nT = (CP - EC).Unit
	stage.nT = nT
	stage.markPt = EC + nT * EARTH_RADIUS
	stage.cannon = buildCannon(folder, cannonCF)
	buildGalaxy(folder, GC)
	buildStars(folder, GC)
	stage.earthSurface = buildEarth(folder, EC)
	stage.solarSystem = buildSolarSystem(folder, EC, GC)
	stage.sunPos, stage.sunDir = stage.solarSystem.sunPos, stage.solarSystem.sunDir
	buildMoon(folder, EC + Vector3.new(220, 160, 420))
	for _ = 1, 70 do
		local off = Vector3.new(gauss(), gauss() * 0.6, gauss()) * 1500
		if off.Magnitude > 450 then
			vpart({ Size = Vector3.new(14 + math.random() * 70, 14 + math.random() * 50, 14 + math.random() * 70), Material = Enum.Material.Slate, Color = Color3.fromRGB(70, 66, 70), CFrame = CFrame.new(CP + off) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6) }, folder)
		end
	end
	stage.markFlare = makeGroundStrikeMarker(folder, stage.markPt, nT, EARTH_RADIUS * 0.34)
	stage.markLaser = makeLaser(folder, stage.markPt + nT * 3200, { 36, 18, 7 })
	stage.markLaser.setEnd(stage.markPt)
	stage.markLaser.setWidth(0)
	stage.ready = true
end

local function finishStage(stage)
	local dir = stage.sunDir or Lighting:GetSunDirection()
	stage.sunDir = dir
	local placed, tries = 0, 0
	while placed < 300 and tries < 3600 do
		tries += 1
		local n = randDir()
		if n:Dot(dir) < -0.12 and landAt(n) then
			placed += 1
			plateOnSphere(stage.folder, stage.EC, n, EARTH_RADIUS * 1.003, 2 + math.random() * 2.5, Color3.fromRGB(255, 205, 120), Enum.Material.Neon, 0.1, 0.8)
			if placed % 100 == 0 then task.wait() end
		end
	end
end

local function finishCinematic(stage, conn)
	if conn then conn:Disconnect() end
	if stage and stage.folder then stage.folder:Destroy() end
	restoreLighting()
	clearFx()
	showBars(false)
	setCaption("")
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	setControls(true)
	setCoreGui(true)
	setFlash(0)
	state = "idle"
end

local function runSequence(target)
	state = "cinematic"
	lastFire = os.clock()
	local startCF = camera.CFrame
	local startFov = camera.FieldOfView
	local startPos = startCF.Position
	local imp = T.imp
	camera.CameraType = Enum.CameraType.Scriptable
	setControls(false)
	setCoreGui(false)
	showBars(true)
	ensureFx()
	restoreAll()
	playSound(SOUNDS.lock, 1, 0.9)
	local stage = { ready = false }
	task.spawn(function() buildStage(stage) end)
	local reticle = makeReticle(DANGER_RADIUS, target)
	local lockLaser = makeLaser(fxFolder, target + Vector3.new(0, 4500, 0), { 12, 6, 2.4 })
	lockLaser.setEnd(target)
	lockLaser.setWidth(0)
	task.delay(math.max(imp - 1.6, 0), function() groundLaser(target, 1.6) end)
	local rotStart = startCF.Rotation
	local rotEnd = CFrame.lookAt(Vector3.zero, Vector3.new(0, -1, 0), Vector3.new(0, 0, -1))
	local lv = startCF.LookVector
	local heading = math.atan2(lv.Z, lv.X)
	local groundCamBase = Vector3.new(math.cos(heading + math.pi), 0, math.sin(heading + math.pi)) * 520 + Vector3.new(0, 170, 0)
	local inSpace, fired, groundFlag, impacted, finished = false, false, false, false, false
	local laser, fireClock = nil, 0
	local chargeSnd, beamSnd, ascentSnd, ambientSnd, countdownSnd, afterSnd = nil, nil, nil, nil, nil, nil
	local armPlayed, countdownPlayed = false, false
	local t0 = os.clock()
	local conn

	local function spaceCam(t)
		local ER = EARTH_RADIUS
		local nT = stage.nT
		local EC = stage.EC
		local markPt = stage.markPt
		local dirA0 = (rotY(nT, 0.45) + Vector3.new(0, 0.35, 0)).Unit
		local dirOv = Vector3.new(0.18, 0.7, 0.69).Unit
		local OV = GALAXY_RADIUS * 1.4
		if t < T.orbitEnd then
			local u = t - T.ascentEnd
			local dirA = rotY(dirA0, u * 0.05)
			local orbitBase = EARTH_RADIUS * 3.6
			local d = orbitBase - EARTH_RADIUS * 0.11 * u
			local pos = EC + dirA * d
			return CFrame.lookAt(pos, markPt + (EC - markPt) * 0.1), 70
		elseif t < T.pullEnd then
			local u = smooth((t - T.orbitEnd) / (T.pullEnd - T.orbitEnd))
			local dirStart = rotY(dirA0, (T.orbitEnd - T.ascentEnd) * 0.05)
			local pullStart = EARTH_RADIUS * 3.6 - EARTH_RADIUS * 0.11 * (T.orbitEnd - T.ascentEnd)
			local dist = pullStart * (OV / pullStart) ^ u
			local pivot = markPt:Lerp(stage.GC, u)
			local dir = dirStart:Lerp(dirOv, u).Unit
			return CFrame.lookAt(pivot + dir * dist, pivot), 70
		elseif t < T.holdEnd then
			local dir = rotY(dirOv, (t - T.pullEnd) * 0.04)
			return CFrame.lookAt(stage.GC + dir * OV, stage.GC), 70
		else
			local e = smooth(clamp01((t - T.holdEnd) / (T.swoopEnd - T.holdEnd)))
			local dirHold = rotY(dirOv, (T.holdEnd - T.pullEnd) * 0.04)
			local orbit = (t > T.swoopEnd) and (t - T.swoopEnd) or 0
			local localOff = CFrame.Angles(0, orbit * 0.035, 0) * Vector3.new(560, 250, 330)
			local dirE = stage.cannonCF:VectorToWorldSpace(localOff).Unit
			local dist = OV * (1000 / OV) ^ e
			local pf = smooth(clamp01((e - 0.05) / 0.95))
			local push = (t > T.swoopEnd) and (1 - 0.1 * clamp01((t - T.swoopEnd) / (T.fireT - T.swoopEnd))) or 1
			local dir = dirHold:Lerp(dirE, e).Unit
			local pivot = stage.GC:Lerp(stage.CP, pf)
			local lookPoint = pivot + stage.cannonCF:VectorToWorldSpace(Vector3.new(0, 0, -330)) * pf
			return CFrame.lookAt(pivot + dir * dist * push, lookPoint), 70
		end
	end

	local function pulseWin(t, center, rise, fall)
		if t < center then return clamp01(1 - (center - t) / rise) end
		return clamp01(1 - (t - center) / fall)
	end

	local function step(t)
		if stage.earthSurface then
			if stage.earthSurface.clouds then stage.earthSurface.clouds.CFrame = CFrame.new(stage.EC) * CFrame.Angles(0, t * 0.018, 0) end
			if stage.earthSurface.night then stage.earthSurface.night.CFrame = CFrame.new(stage.EC) * CFrame.Angles(0, t * 0.018, 0) end
		end
		local cf
		local fov = 70
		local shakeAmp, rotAmp = 0, 0
		local f = 0
		if t < T.ascentEnd then
			if t < T.lockEnd then
				cf = startCF
				fov = startFov
				lockLaser.setWidth(smooth(t / 0.6))
				if t > 0.2 then setCaption("目标锁定  ·  TARGET LOCKED", Color3.fromRGB(255, 120, 120)) end
			else
				local u = clamp01((t - T.lockEnd) / (T.ascentEnd - T.lockEnd))
				local h = 40 * ((14000 / 40) ^ u - 1)
				local eo = smooth(u)
				local pos = Vector3.new(lerp(startPos.X, target.X, eo * 0.9), startPos.Y + h, lerp(startPos.Z, target.Z, eo * 0.9))
				local rot = rotStart:Lerp(rotEnd, smooth(clamp01((u - 0.1) / 0.9)))
				cf = CFrame.new(pos) * rot
				fov = lerp(startFov, 55, u)
				fx.blur.Size = lerp(0, 22, clamp01((t - (T.ascentEnd - 1.2)) / 1.2))
				fx.cc.Brightness = lerp(0, -0.05, u)
				fx.cc.Saturation = lerp(0, 0.2, u)
				setCaption("升空  ·  ASCENT", Color3.new(1, 1, 1))
				if not ascentSnd then ascentSnd = playSound(SOUNDS.whoosh, 0.9, 0.5) end
				f = math.max(f, (t > T.ascentEnd - 0.7 and 1 or 0) * (1 - math.abs(t - T.ascentEnd) / 0.7))
			end
			reticle.update(t)
		elseif t < T.groundT then
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
				ambientSnd = playSound(SOUNDS.ambient, 0.25, 1, true)
			end
			if not stage.ready then setFlash(1); return end
			if not stage.finished then stage.finished = true; task.spawn(finishStage, stage) end
			cf, fov = spaceCam(t)
			if stage.markLaser then stage.markLaser.setWidth(smooth((t - T.ascentEnd) / 1.2) * (0.85 + 0.15 * math.sin(t * 9))) end
			if stage.markFlare then stage.markFlare.update(t) end
			if t >= T.pullEnd - 0.4 then setCaption("银河系  ·  MILKY WAY", Color3.new(1, 1, 1)) end
			if t >= T.holdEnd + 0.6 then
				setCaption("歼星炮  ·  STAR-DESTROYER ONLINE", Color3.fromRGB(255, 140, 140))
				if not armPlayed then armPlayed = true; playSound(SOUNDS.arm, 0.8, 1) end
			end
			if t >= T.swoopEnd and not countdownPlayed then countdownPlayed = true; countdownSnd = playSound(SOUNDS.countdown, 0.52, 1) end
			if t < T.swoopEnd then
				stage.cannon.update(0, t)
			elseif t < T.fireT then
				local x = clamp01((t - T.swoopEnd) / (T.fireT - T.swoopEnd))
				stage.cannon.update(x, t)
				shakeAmp = 4 * x * x
				rotAmp = 0.004 * x * x
				caption.Text = string.format("充能中  ·  CHARGING  %d%%", math.floor(x * 100))
				caption.TextColor3 = Color3.fromRGB(255, 90, 90)
				caption.TextTransparency = 0
				if chargeSnd then chargeSnd.PlaybackSpeed = 0.35 + 1.2 * x; chargeSnd.Volume = 0.7 + 0.6 * x end
			else
				stage.cannon.update(1, t)
			end
			if t >= T.fireT then
				if not fired then
					fired = true
					fireClock = os.clock()
					setCaption("发射  ·  FIRE", Color3.new(1, 1, 1))
					if chargeSnd then chargeSnd:Destroy(); chargeSnd = nil end
					playSound(SOUNDS.fire, 1.35, 0.82)
					beamSnd = playSound(SOUNDS.beam, 0.8, 0.82, true)
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
				local pw = t < T.fireT and 0 or (t < T.fireT + 0.02 and (t - T.fireT) / 0.02 or math.clamp(1 - (t - T.fireT - 0.02) / 0.9, 0, 1))
				f = math.max(f, 0.9 * pw)
			end
			f = math.max(f, pulseWin(t, T.ascentEnd, 0.01, 1.1))
			f = math.max(f, pulseWin(t, T.groundT, 0.25, 0.01) * (t > T.groundT - 0.25 and 1 or 0))
		else
			if not groundFlag then
				groundFlag = true
				if chargeSnd then chargeSnd:Destroy(); chargeSnd = nil end
				if ambientSnd then ambientSnd:Destroy(); ambientSnd = nil end
				if countdownSnd then countdownSnd:Destroy(); countdownSnd = nil end
				if beamSnd then beamSnd:Destroy(); beamSnd = nil end
				if stage.folder then stage.folder:Destroy(); stage.folder = nil end
				restoreLighting()
				fx.bloom.Intensity = 0.9
				fx.bloom.Threshold = 0.95
				fx.cc.Saturation = 0
				tween(fx.cc, 1.4, { TintColor = Color3.fromRGB(233, 217, 255), Brightness = -0.035, Contrast = 0.12, Saturation = -0.08 })
				setCaption("命中  ·  IMPACT", Color3.fromRGB(255, 90, 90))
			end
			if not impacted and t >= imp then
				impacted = true
				afterSnd = playSound(SOUNDS.after, 0.75, 0.92)
				task.spawn(doImpact, target, true)
			end
			local g = t - T.groundT
			local ang = math.max(0, t - imp) * 0.06
			local offs = CFrame.Angles(0, ang, 0) * (groundCamBase * (1 - 0.08 * clamp01(g / (imp - T.groundT))))
			cf = CFrame.lookAt(target + offs, target + Vector3.new(0, 45, 0))
			fov = lerp(70, 62, clamp01(g / 6))
			f = math.max(f, (t > T.groundT - 0.01 and t < T.groundT + 0.8) and (1 - (t - T.groundT) / 0.8) or 0)
			reticle.update(t)
			if t > imp + 3 then setCaption("") end
		end
		f = math.max(f, impactFlashValue())
		local ia = impactShakeAmount()
		shakeAmp += ia
		rotAmp += ia * 0.0015
		if t > T.endT - 0.8 then setFlash(clamp01((t - (T.endT - 0.8)) / 0.8), Color3.new(0, 0, 0))
		else setFlash(f) end
		camera.FieldOfView = fov
		camera.CFrame = shakeCF(cf, shakeAmp, t, rotAmp)
	end

	conn = RunService.RenderStepped:Connect(function()
		if finished then return end
		local t = os.clock() - t0
		if t >= T.endT then
			finished = true
			reticle.destroy(); lockLaser.destroy()
			if ascentSnd then ascentSnd:Destroy() end
			if beamSnd then beamSnd:Destroy() end
			if chargeSnd then chargeSnd:Destroy() end
			if ambientSnd then ambientSnd:Destroy() end
			if countdownSnd then countdownSnd:Destroy() end
			if afterSnd then afterSnd:Destroy() end
			finishCinematic(stage, conn)
			return
		end
		local ok, err = pcall(step, t)
		if not ok then
			warn("[SpaceCannon]", err)
			finished = true
			reticle.destroy(); lockLaser.destroy()
			if beamSnd then beamSnd:Destroy() end
			if chargeSnd then chargeSnd:Destroy() end
			if ambientSnd then ambientSnd:Destroy() end
			if countdownSnd then countdownSnd:Destroy() end
			if ascentSnd then ascentSnd:Destroy() end
			if afterSnd then afterSnd:Destroy() end
			finishCinematic(stage, conn)
		end
	end)
end

local targetPosition = nil
local isTargeting = false

local Window = WindUI:CreateWindow({ Title = "力量之冠 V3.9 宇宙歼星炮", Icon = "zap", Author = "力量之冠", Folder = "PowerCrownSave", Theme = "Dark", Transparent = true, Resizable = false, Size = UDim2.fromOffset(460, 780) })

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

RailgunSection:Button({ Title = "选择发射目标", Callback = function()
    isTargeting = true
    RailgunStatus:SetDesc("请在游戏画面中点击地面选择目标...")
end })

RailgunSection:Button({ Title = "立即发射", Callback = function()
    if not targetPosition then RailgunStatus:SetDesc("请先点击「选择发射目标」选择地点！") return end
    RailgunStatus:SetDesc("歼星炮正在充能过场中...")
    runSequence(targetPosition)
end })

RailgunSection:Toggle({ Title = "启用 F 键发射", Value = true, Callback = function(state) Cfg.RailgunKeyBind = state end })

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
AntiSection:Toggle({ Title = "反挂机踢出", Value = true, Callback = function(state) Cfg.AntiIdleKick = state if state then applyAntiIdleKick() end end })
AntiSection:Toggle({ Title = "防客户端踢出", Value = false, Callback = function(state) Cfg.AntiClientKick = state if state then applyAntiClientKick() end end })
local GroupSection = ProtectTab:Section({ Title = "群组验证", Icon = "users" })
GroupSection:Toggle({ Title = "绕过群组验证", Value = false, Callback = function(state) Cfg.BypassGroup = state if state then applyBypassGroup() end end })

local SG = Instance.new("ScreenGui") SG.Name = "PowerCrownUI" SG.ResetOnSpawn = false SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling SG.IgnoreGuiInset = true
pcall(function() SG.Parent = game:GetService("CoreGui") end) if not SG.Parent then SG.Parent = player.PlayerGui end
local DataHUD = Instance.new("Frame") DataHUD.Size = UDim2.new(0, 210, 0, 105) DataHUD.Position = UDim2.new(0, 20, 0.3, 0) DataHUD.BackgroundColor3 = Color3.fromRGB(20, 24, 34) DataHUD.BackgroundTransparency = 0.1 DataHUD.BorderSizePixel = 0 DataHUD.ZIndex = 500 DataHUD.Parent = SG
corner(DataHUD, 10) stroke(DataHUD, C.accent, 1.5, 0.2)
local HUDTitle = Instance.new("TextLabel") HUDTitle.Size = UDim2.new(1, 0, 0, 24) HUDTitle.BackgroundTransparency = 1 HUDTitle.Text = "📊 力量之冠 V3.9 · 累计总数据" HUDTitle.TextColor3 = C.accent HUDTitle.Font = Enum.Font.GothamBold HUDTitle.TextSize = 12 HUDTitle.ZIndex = 501 HUDTitle.Parent = DataHUD
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
            local ray = camera:ViewportPointToRay(input.Position.X, input.Position.Y)
            local raycastParams = RaycastParams.new() raycastParams.FilterType = Enum.RaycastFilterType.Exclude raycastParams.FilterDescendantsInstances = {player.Character}
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if result then
                targetPosition = result.Position
                local targetMarker = Instance.new("Part")
                targetMarker.Shape = Enum.PartType.Ball
                targetMarker.Material = Enum.Material.Neon
                targetMarker.Color = Color3.fromRGB(255, 0, 0)
                targetMarker.Transparency = 0.3
                targetMarker.Size = Vector3.new(14, 14, 14)
                targetMarker.Position = targetPosition + Vector3.new(0, 5, 0)
                targetMarker.Anchored = true
                targetMarker.CanCollide = false
                targetMarker.Parent = workspace
                Debris:AddItem(targetMarker, 10)
                RailgunStatus:SetDesc("目标已选定！点击「立即发射」或按 F 键")
                isTargeting = false
            else
                RailgunStatus:SetDesc("未检测到地面，请重新点击「选择发射目标」")
            end
        end
        return
    end
    if input.KeyCode == Enum.KeyCode.F and Cfg.RailgunKeyBind then
        if targetPosition then
            runSequence(targetPosition)
        end
    end
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