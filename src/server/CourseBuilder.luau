local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local CourseBuilder = {}

local COLORS = ObbyConfig.Colors

local function createPart(parent, name, size, position, color, material, properties)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	for propertyName, value in pairs(properties or {}) do
		part[propertyName] = value
	end

	part.Parent = parent
	return part
end

local function createLabel(parent, text, offsetY)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(220, 64)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, offsetY or 4, 0)
	billboard.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = COLORS.White
	label.TextScaled = true
	label.TextStrokeColor3 = COLORS.Dark
	label.TextStrokeTransparency = 0.2
	label.Parent = billboard

	return billboard
end

local function createSurfaceLabel(parent, text)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "SurfaceLabel"
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.LightInfluence = 0
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 40
	surfaceGui.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = COLORS.Dark
	label.TextScaled = true
	label.Parent = surfaceGui
end

local function createArrow(parent, position, color)
	createPart(parent, "ArrowStem", Vector3.new(1.2, 0.14, 4.5), position, color, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})

	createPart(parent, "ArrowHead", Vector3.new(4.4, 0.14, 1.2), position + Vector3.new(0, 0, 2.5), color, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
end

local function addHazardEffects(lava)
	local fire = Instance.new("Fire")
	fire.Name = "LavaGlow"
	fire.Color = COLORS.Lava
	fire.SecondaryColor = Color3.fromRGB(255, 174, 59)
	fire.Heat = 4
	fire.Size = 8
	fire.Parent = lava

	local light = Instance.new("PointLight")
	light.Name = "LavaLight"
	light.Brightness = 1.8
	light.Color = COLORS.Lava
	light.Range = 22
	light.Parent = lava
end

local function createSpawn(parent)
	local platform = createPart(parent, "StartPlatform", Vector3.new(22, 1, 18), Vector3.new(0, 2, 0), COLORS.Spawn, Enum.Material.Grass)
	createLabel(platform, "START", 5)
	createSurfaceLabel(platform, "START")
	createArrow(parent, Vector3.new(0, 2.6, 3), COLORS.Start)

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "PlayerSpawn"
	spawnLocation.Anchored = true
	spawnLocation.AllowTeamChangeOnTouch = false
	spawnLocation.Duration = 0
	spawnLocation.Neutral = true
	spawnLocation.Size = Vector3.new(8, 1, 8)
	spawnLocation.Position = Vector3.new(0, 3, -4)
	spawnLocation.Color = COLORS.Spawn
	spawnLocation.Material = Enum.Material.ForceField
	spawnLocation.TopSurface = Enum.SurfaceType.Smooth
	spawnLocation.BottomSurface = Enum.SurfaceType.Smooth
	spawnLocation.Parent = parent

	local startPad = createPart(parent, "StartPad", Vector3.new(18, 0.3, 2), Vector3.new(0, 3.05, 8), COLORS.Start, Enum.Material.Neon, {
		CanCollide = false,
	})
	createLabel(startPad, "GO!", 4)

	return platform, startPad
end

local function createFinish(parent)
	local platform = createPart(parent, "FinishPlatform", Vector3.new(22, 1, 18), Vector3.new(0, 5.5, 174), COLORS.Finish, Enum.Material.SmoothPlastic)
	createLabel(platform, "FINISH", 5)
	createSurfaceLabel(platform, "FINISH")

	local finishPad = createPart(parent, "FinishPad", Vector3.new(16, 0.35, 9), Vector3.new(0, 6.15, 174), COLORS.Finish, Enum.Material.Neon, {
		CanCollide = false,
	})

	return platform, finishPad
end

local function createMovingPlatform(parent)
	local platform = createPart(parent, "MovingPlatform", Vector3.new(9, 1, 8), Vector3.new(-9, 5.2, 132), COLORS.Moving, Enum.Material.Neon)
	createLabel(platform, "MOVING PLATFORM", 5)

	local tweenInfo = TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local tween = TweenService:Create(platform, tweenInfo, {
		Position = Vector3.new(9, 5.2, 132),
	})
	tween:Play()

	return platform
end

local function createHazards(parent)
	local hazards = {}

	local lava = createPart(parent, "LavaPit", Vector3.new(30, 0.5, 24), Vector3.new(0, 2.3, 96), COLORS.Lava, Enum.Material.Neon, {
		CanCollide = false,
	})
	createLabel(lava, "LAVA", 6)
	addHazardEffects(lava)
	table.insert(hazards, lava)

	local voidKill = createPart(parent, "FallReset", Vector3.new(80, 1, 220), Vector3.new(0, 0.8, 88), COLORS.Lava, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 1,
	})
	table.insert(hazards, voidKill)

	return hazards
end

local function createStaticCourse(parent)
	local platforms = {
		{ "JumpPad01", Vector3.new(11, 1, 8), Vector3.new(0, 3, 22), COLORS.PathA },
		{ "JumpPad02", Vector3.new(9, 1, 7), Vector3.new(0, 4, 35), COLORS.PathB },
		{ "JumpPad03", Vector3.new(8, 1, 7), Vector3.new(0, 5, 48), COLORS.PathC },
		{ "LeftZig", Vector3.new(8, 1, 8), Vector3.new(-8, 5, 61), COLORS.PathA },
		{ "RightZig", Vector3.new(8, 1, 8), Vector3.new(8, 5, 74), COLORS.PathB },
		{ "LavaLaunch", Vector3.new(12, 1, 8), Vector3.new(0, 5, 86), COLORS.PathC },
		{ "Stone01", Vector3.new(5, 1, 5), Vector3.new(-7, 5.2, 95), COLORS.PathA },
		{ "Stone02", Vector3.new(5, 1, 5), Vector3.new(0, 5.5, 102), COLORS.PathB },
		{ "Stone03", Vector3.new(5, 1, 5), Vector3.new(7, 5.2, 109), COLORS.PathC },
		{ "PostLava", Vector3.new(12, 1, 8), Vector3.new(0, 5, 119), COLORS.PathA },
		{ "MovingLanding", Vector3.new(12, 1, 8), Vector3.new(0, 5, 145), COLORS.PathB },
		{ "BalanceBeam", Vector3.new(4, 1, 18), Vector3.new(0, 5.3, 158), COLORS.Beam },
	}

	for index, platformData in ipairs(platforms) do
		local platform = createPart(parent, platformData[1], platformData[2], platformData[3], platformData[4], Enum.Material.SmoothPlastic)

		if index == 1 or index == 6 or index == 10 then
			createArrow(parent, platform.Position + Vector3.new(0, 0.62, 0.4), COLORS.Start)
		end
	end
end

function CourseBuilder.build()
	local oldCourse = workspace:FindFirstChild(ObbyConfig.CourseFolderName)
	if oldCourse then
		oldCourse:Destroy()
	end

	local courseFolder = Instance.new("Folder")
	courseFolder.Name = ObbyConfig.CourseFolderName
	courseFolder.Parent = workspace

	local _, startPad = createSpawn(courseFolder)
	createStaticCourse(courseFolder)
	local hazards = createHazards(courseFolder)
	createMovingPlatform(courseFolder)
	local _, finishPad = createFinish(courseFolder)

	return {
		folder = courseFolder,
		startPad = startPad,
		finishPad = finishPad,
		hazards = hazards,
	}
end

return CourseBuilder
