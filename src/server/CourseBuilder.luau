local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local CourseBuilder = {}

local COLORS = ObbyConfig.Colors
local WORLD_ID = WorldConfig.CurrentWorldId
local STAGE_1_ID = WorldConfig.Worlds[WORLD_ID].stages[1].id
local START_CHARACTER_POSITION = Vector3.new(0, 5.8, -5)
local START_SPAWN_LOCATION_POSITION = Vector3.new(0, 3, -5)
local START_PAD_POSITION = Vector3.new(0, 3.05, 8)
local STAGE_1_CHECKPOINT_RESPAWN_POSITION = Vector3.new(0, 10.2, 172)
local STAGE_2_GATE_TARGET_POSITION = Vector3.new(0, 10.2, 203)

local LAVA_FIELD = {
	size = Vector3.new(92, 0.6, 205),
	position = Vector3.new(0, 0.85, 96),
}

local STAGE_1_BOULDERS = {
	{ position = Vector3.new(-2, 2.65, 24), size = Vector3.new(11, 1.7, 9), rotation = Vector3.new(0, 11, -4) },
	{ position = Vector3.new(5, 3.0, 37), size = Vector3.new(10, 1.9, 8), rotation = Vector3.new(2, -13, 6) },
	{ position = Vector3.new(-5, 3.2, 50), size = Vector3.new(9.5, 2, 8.2), rotation = Vector3.new(-3, 18, -5) },
	{ position = Vector3.new(6, 3.4, 63), size = Vector3.new(9, 2, 7.8), rotation = Vector3.new(4, -17, 3) },
	{ position = Vector3.new(-6, 3.8, 76), size = Vector3.new(8.6, 2.2, 7.4), rotation = Vector3.new(-2, 25, 7) },
	{ position = Vector3.new(5, 4.0, 89), size = Vector3.new(8.2, 2.2, 7), rotation = Vector3.new(3, -23, -4) },
	{ position = Vector3.new(-3, 4.3, 101), size = Vector3.new(8, 2.3, 6.8), rotation = Vector3.new(-5, 14, 5) },
	{ position = Vector3.new(7, 4.5, 113), size = Vector3.new(7.6, 2.3, 6.4), rotation = Vector3.new(5, -30, -6) },
	{ position = Vector3.new(-7, 4.8, 125), size = Vector3.new(7.4, 2.4, 6.2), rotation = Vector3.new(-3, 27, 4) },
	{ position = Vector3.new(4, 5.0, 137), size = Vector3.new(7.2, 2.4, 6), rotation = Vector3.new(4, -18, -7) },
	{ position = Vector3.new(-4, 5.2, 149), size = Vector3.new(6.8, 2.4, 5.8), rotation = Vector3.new(-4, 34, 5) },
	{ position = Vector3.new(3, 5.5, 160), size = Vector3.new(7, 2.4, 5.8), rotation = Vector3.new(6, -22, -4) },
}

local BOULDER_COLORS = {
	Color3.fromRGB(54, 49, 48),
	Color3.fromRGB(71, 63, 58),
	Color3.fromRGB(46, 45, 48),
}

local BOULDER_TUNING = {
	visualHorizontalScale = 1.45,
	visualHeightScale = 1.75,
	earlyLandingRatio = 0.84,
	midLandingRatio = 0.78,
	lateLandingRatio = 0.72,
}

local function createFacingCFrame(position, lookAtPosition)
	local flatLookAt = Vector3.new(lookAtPosition.X, position.Y, lookAtPosition.Z)
	if (flatLookAt - position).Magnitude < 0.01 then
		flatLookAt = position + Vector3.new(0, 0, 1)
	end

	return CFrame.lookAt(position, flatLookAt)
end

local function getBoulderVisualSize(config)
	return Vector3.new(
		config.size.X * BOULDER_TUNING.visualHorizontalScale,
		config.size.Y * BOULDER_TUNING.visualHeightScale,
		config.size.Z * BOULDER_TUNING.visualHorizontalScale
	)
end

local function getLandingRatio(index)
	if index <= 4 then
		return BOULDER_TUNING.earlyLandingRatio
	elseif index <= 8 then
		return BOULDER_TUNING.midLandingRatio
	end

	return BOULDER_TUNING.lateLandingRatio
end

local function createPart(parent, name, size, positionOrCFrame, color, material, properties)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size

	if typeof(positionOrCFrame) == "CFrame" then
		part.CFrame = positionOrCFrame
	else
		part.Position = positionOrCFrame
	end

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

local function createSurfaceLabel(parent, text, textColor, face)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "SurfaceLabel"
	surfaceGui.Face = face or Enum.NormalId.Top
	surfaceGui.LightInfluence = 0
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 40
	surfaceGui.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = textColor or COLORS.Dark
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = surfaceGui
end

local function createPathArrow(parent, position, color)
	createPart(parent, "ArrowStem", Vector3.new(1, 0.14, 4.8), position, color, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})

	createPart(parent, "ArrowLeftWing", Vector3.new(0.8, 0.14, 3.1), CFrame.new(position + Vector3.new(-1, 0, 2.2)) * CFrame.Angles(0, math.rad(-35), 0), color, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})

	createPart(parent, "ArrowRightWing", Vector3.new(0.8, 0.14, 3.1), CFrame.new(position + Vector3.new(1, 0, 2.2)) * CFrame.Angles(0, math.rad(35), 0), color, Enum.Material.Neon, {
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
	fire.Size = 9
	fire.Parent = lava

	local smoke = Instance.new("Smoke")
	smoke.Name = "LavaSmoke"
	smoke.Color = Color3.fromRGB(70, 57, 54)
	smoke.Opacity = 0.13
	smoke.RiseVelocity = 3
	smoke.Size = 12
	smoke.Parent = lava

	local light = Instance.new("PointLight")
	light.Name = "LavaLight"
	light.Brightness = 2
	light.Color = COLORS.Lava
	light.Range = 28
	light.Parent = lava
end

local function createStartArea(parent)
	local platform = createPart(parent, "World1Stage1StartPlatform", Vector3.new(30, 1, 22), Vector3.new(0, 2, 0), COLORS.Spawn, Enum.Material.Grass)
	createSurfaceLabel(platform, "START")

	createPart(parent, "StartLeftRail", Vector3.new(1, 1.5, 20), Vector3.new(-14.5, 3, 0), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "StartRightRail", Vector3.new(1, 1.5, 20), Vector3.new(14.5, 3, 0), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPathArrow(parent, Vector3.new(0, 2.65, 4), COLORS.Start)

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "PlayerSpawn"
	spawnLocation.Anchored = true
	spawnLocation.AllowTeamChangeOnTouch = false
	spawnLocation.Duration = 0
	spawnLocation.Neutral = true
	spawnLocation.Size = Vector3.new(8, 1, 8)
	spawnLocation.CFrame = createFacingCFrame(START_SPAWN_LOCATION_POSITION, START_PAD_POSITION)
	spawnLocation.Color = COLORS.Spawn
	spawnLocation.Material = Enum.Material.ForceField
	spawnLocation.TopSurface = Enum.SurfaceType.Smooth
	spawnLocation.BottomSurface = Enum.SurfaceType.Smooth
	spawnLocation.Parent = parent

	local startPad = createPart(parent, "StartPad", Vector3.new(18, 0.3, 2.5), Vector3.new(0, 3.05, 8), COLORS.Start, Enum.Material.Neon, {
		CanCollide = false,
	})
	createSurfaceLabel(startPad, "GO")

	return startPad
end

local function createLava(parent)
	local hazards = {}

	local lava = createPart(parent, "World1LavaField", LAVA_FIELD.size, LAVA_FIELD.position, COLORS.Lava, Enum.Material.Neon, {
		CanCollide = false,
	})
	addHazardEffects(lava)
	table.insert(hazards, lava)

	for index, stream in ipairs({
		{ x = -24, z = 55, width = 7, length = 76 },
		{ x = 26, z = 113, width = 6, length = 86 },
		{ x = 0, z = 151, width = 8, length = 48 },
	}) do
		createPart(parent, string.format("LavaGlowStream%02d", index), Vector3.new(stream.width, 0.08, stream.length), Vector3.new(stream.x, 1.2, stream.z), Color3.fromRGB(255, 143, 34), Enum.Material.Neon, {
			CanCollide = false,
			CanTouch = false,
			Transparency = 0.25,
		})
	end

	local voidKill = createPart(parent, "FallReset", Vector3.new(120, 0.5, 240), Vector3.new(0, -6, 96), COLORS.Lava, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 1,
	})
	table.insert(hazards, voidKill)

	return hazards
end

local function createBoulder(parent, index, config)
	local rotation = config.rotation or Vector3.zero
	local visualSize = getBoulderVisualSize(config)
	local boulderCFrame = CFrame.new(config.position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))

	local boulder = createPart(parent, string.format("Stage1Boulder%02d", index), visualSize, boulderCFrame, BOULDER_COLORS[((index - 1) % #BOULDER_COLORS) + 1], Enum.Material.Slate, {
		CanCollide = false,
		CanTouch = false,
		Shape = Enum.PartType.Ball,
	})

	local landingRatio = getLandingRatio(index)
	local topY = config.position.Y + (visualSize.Y / 2)
	-- Invisible flat landings keep the volcanic rocks playful instead of slippery.
	createPart(parent, string.format("Stage1Boulder%02dLanding", index), Vector3.new(visualSize.X * landingRatio, 0.2, visualSize.Z * landingRatio), Vector3.new(config.position.X, topY + 0.08, config.position.Z), COLORS.White, Enum.Material.SmoothPlastic, {
		CanTouch = false,
		Transparency = 1,
	})

	if index == 1 or index == 5 or index == 9 then
		createPathArrow(parent, Vector3.new(config.position.X, topY + 0.24, config.position.Z + 0.2), COLORS.Start)
	end

	return boulder
end

local function createBoulderRun(parent)
	for index, boulderConfig in ipairs(STAGE_1_BOULDERS) do
		createBoulder(parent, index, boulderConfig)
	end
end

local function createCheckpoint(parent)
	local platform = createPart(parent, "Stage1CheckpointPlatform", Vector3.new(26, 1, 18), Vector3.new(0, 6.4, 174), COLORS.CheckpointAccent, Enum.Material.SmoothPlastic)

	local base = createPart(parent, "Stage1CheckpointBase", Vector3.new(18, 0.16, 10), Vector3.new(0, 7.02, 172), COLORS.CheckpointAccent, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.28,
	})

	local pad = createPart(parent, "Stage1Checkpoint", Vector3.new(15, 0.35, 7), Vector3.new(0, 7.22, 172), COLORS.Checkpoint, Enum.Material.Neon, {
		CanCollide = false,
	})
	pad:SetAttribute("CheckpointIndex", 1)
	pad:SetAttribute("StageId", STAGE_1_ID)
	pad:SetAttribute("CompletesStage", true)

	return {
		{
			id = "world_1_stage_1_checkpoint",
			index = 1,
			order = 1,
			stageId = STAGE_1_ID,
			completesStage = true,
			part = pad,
			base = base,
			platform = platform,
			respawnPosition = STAGE_1_CHECKPOINT_RESPAWN_POSITION,
			respawnLookAt = STAGE_2_GATE_TARGET_POSITION,
			respawnCFrame = createFacingCFrame(STAGE_1_CHECKPOINT_RESPAWN_POSITION, STAGE_2_GATE_TARGET_POSITION),
		},
	}
end

local function createStageTwoPlaceholder(parent)
	local platform = createPart(parent, "Stage2PlaceholderPlatform", Vector3.new(30, 1, 22), Vector3.new(0, 6.4, 195), COLORS.Finish, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 2", COLORS.Dark)

	createPart(parent, "Stage2GateLeftPost", Vector3.new(2, 11, 2), Vector3.new(-10, 12, 202), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage2GateRightPost", Vector3.new(2, 11, 2), Vector3.new(10, 12, 202), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage2GateTop", Vector3.new(22, 2, 2), Vector3.new(0, 18, 202), COLORS.Dark, Enum.Material.SmoothPlastic)

	local closedDoor = createPart(parent, "Stage2ComingNextDoor", Vector3.new(17, 8, 1), Vector3.new(0, 11, 203), COLORS.Start, Enum.Material.ForceField, {
		Transparency = 0.2,
	})
	createSurfaceLabel(closedDoor, "STAGE 2\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Front)
	createSurfaceLabel(closedDoor, "STAGE 2\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Back)
end

local function createScenery(parent)
	for index, rock in ipairs({
		{ position = Vector3.new(-34, 4.2, 36), size = Vector3.new(5, 7, 5) },
		{ position = Vector3.new(33, 5.5, 66), size = Vector3.new(6, 9, 6) },
		{ position = Vector3.new(-31, 5.1, 106), size = Vector3.new(7, 8, 7) },
		{ position = Vector3.new(35, 4.7, 138), size = Vector3.new(5, 8, 5) },
	}) do
		createPart(parent, string.format("VolcanicSideRock%02d", index), rock.size, rock.position, Color3.fromRGB(43, 39, 40), Enum.Material.Slate, {
			CanTouch = false,
			Shape = Enum.PartType.Ball,
		})
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

	local startPad = createStartArea(courseFolder)
	local hazards = createLava(courseFolder)
	createBoulderRun(courseFolder)
	createScenery(courseFolder)
	local checkpoints = createCheckpoint(courseFolder)
	createStageTwoPlaceholder(courseFolder)

	return {
		folder = courseFolder,
		worldId = WORLD_ID,
		startStageId = STAGE_1_ID,
		finishStageId = nil,
		startPad = startPad,
		startSpawnCFrame = createFacingCFrame(START_CHARACTER_POSITION, START_PAD_POSITION),
		startRespawnCFrame = createFacingCFrame(START_CHARACTER_POSITION, START_PAD_POSITION),
		finishPad = nil,
		checkpoints = checkpoints,
		hazards = hazards,
	}
end

return CourseBuilder
