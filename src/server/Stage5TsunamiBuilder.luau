local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local TsunamiConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TsunamiConfig"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local Stage5TsunamiBuilder = {}

local COLORS = ObbyConfig.Colors
local WORLD_ID = WorldConfig.CurrentWorldId
local STAGE_5_ID = WorldConfig.Worlds[WORLD_ID].stages[5].id

local STAGE_5_START_POSITION = Vector3.new(0, 13.4, 894)
local STAGE_5_START_LOOK_AT = Vector3.new(0, 13.4, 928)
local STAGE_5_CHECKPOINT_RESPAWN_POSITION = Vector3.new(0, 13.4, 1218)
local STAGE_6_TARGET_POSITION = Vector3.new(0, 13.4, 1260)

local STAGE_COLORS = {
	Road = Color3.fromRGB(58, 63, 76),
	Deck = Color3.fromRGB(82, 91, 112),
	Water = Color3.fromRGB(38, 157, 224),
	Wave = Color3.fromRGB(72, 202, 255),
	Foam = Color3.fromRGB(230, 250, 255),
	Shelter = Color3.fromRGB(52, 214, 126),
	ShelterDark = Color3.fromRGB(24, 102, 71),
	Warning = Color3.fromRGB(255, 224, 74),
}

local SAFE_SLOTS = {
	{ index = 1, side = -1, z = 940, width = 24, depth = 22, label = "SAFE 1" },
	{ index = 2, side = 1, z = 995, width = 22, depth = 21, label = "SAFE 2" },
	{ index = 3, side = -1, z = 1052, width = 21, depth = 20, label = "SAFE 3" },
	{ index = 4, side = 1, z = 1110, width = 19, depth = 19, label = "SAFE 4" },
	{ index = 5, side = -1, z = 1167, width = 20, depth = 19, label = "FINAL SAFE" },
}

local OBSTACLES = {
	{ name = "FoamLog01", position = Vector3.new(6, 11.15, 964), size = Vector3.new(8, 0.9, 2.4), yaw = 10 },
	{ name = "FoamLog02", position = Vector3.new(-6, 11.15, 1018), size = Vector3.new(8, 0.9, 2.4), yaw = -12 },
	{ name = "FoamLog03", position = Vector3.new(7, 11.15, 1084), size = Vector3.new(7, 0.9, 2.2), yaw = 13 },
	{ name = "FoamLog04", position = Vector3.new(-6, 11.15, 1141), size = Vector3.new(7, 0.9, 2.2), yaw = -13 },
}

local ARROWS = {
	{ position = Vector3.new(0, 10.86, 916), yaw = 0 },
	{ position = Vector3.new(-8, 10.86, 954), yaw = -35 },
	{ position = Vector3.new(8, 10.86, 981), yaw = 35 },
	{ position = Vector3.new(-8, 10.86, 1037), yaw = -35 },
	{ position = Vector3.new(8, 10.86, 1097), yaw = 35 },
	{ position = Vector3.new(0, 10.86, 1194), yaw = 0 },
}

local function createFacingCFrame(position, lookAtPosition)
	local flatLookAt = Vector3.new(lookAtPosition.X, position.Y, lookAtPosition.Z)
	if (flatLookAt - position).Magnitude < 0.01 then
		flatLookAt = position + Vector3.new(0, 0, 1)
	end

	return CFrame.lookAt(position, flatLookAt)
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
	surfaceGui.PixelsPerStud = 36
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

local function createArrow(parent, position, yawDegrees)
	local cframe = CFrame.new(position) * CFrame.Angles(0, math.rad(yawDegrees), 0)
	createPart(parent, "Stage5ArrowStem", Vector3.new(1.2, 0.16, 7), cframe, STAGE_COLORS.Warning, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage5ArrowLeft", Vector3.new(0.9, 0.16, 3.4), cframe * CFrame.new(-1.2, 0, 2.6) * CFrame.Angles(0, math.rad(-35), 0), STAGE_COLORS.Warning, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage5ArrowRight", Vector3.new(0.9, 0.16, 3.4), cframe * CFrame.new(1.2, 0, 2.6) * CFrame.Angles(0, math.rad(35), 0), STAGE_COLORS.Warning, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
end

local function createEntrance(parent)
	createPart(parent, "Stage5ConnectorFromCp4", Vector3.new(18, 1, 24), Vector3.new(0, 10.2, 876), STAGE_COLORS.Road, Enum.Material.Concrete)

	local platform = createPart(parent, "Stage5EntrancePlatform", Vector3.new(36, 1, 24), Vector3.new(0, 10.2, 894), STAGE_COLORS.Deck, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 5\nTSUNAMI RUN", COLORS.White)

	local sign = createPart(parent, "Stage5StartWarningSign", Vector3.new(26, 5, 1), Vector3.new(0, 15.2, 908), STAGE_COLORS.Warning, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
	createSurfaceLabel(sign, "RUN TO GREEN SAFE SLOTS", COLORS.Dark, Enum.NormalId.Front)
end

local function createLane(parent)
	createPart(parent, "Stage5RunLane", Vector3.new(32, 1, 300), Vector3.new(0, 10.2, 1056), STAGE_COLORS.Road, Enum.Material.Concrete)
	createPart(parent, "Stage5LeftFloodWater", Vector3.new(36, 0.35, 318), Vector3.new(-34, 9.84, 1056), STAGE_COLORS.Water, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.08,
	})
	createPart(parent, "Stage5RightFloodWater", Vector3.new(36, 0.35, 318), Vector3.new(34, 9.84, 1056), STAGE_COLORS.Water, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.08,
	})

	for index, z in ipairs({ 930, 984, 1040, 1098, 1155 }) do
		createPart(parent, string.format("Stage5WarningBeacon%02d", index), Vector3.new(1.3, 5, 1.3), Vector3.new(-14, 13.2, z), STAGE_COLORS.Warning, Enum.Material.Neon, {
			CanCollide = false,
			CanTouch = false,
		})
		createPart(parent, string.format("Stage5WarningBeaconRight%02d", index), Vector3.new(1.3, 5, 1.3), Vector3.new(14, 13.2, z), STAGE_COLORS.Warning, Enum.Material.Neon, {
			CanCollide = false,
			CanTouch = false,
		})
	end

	for _, arrow in ipairs(ARROWS) do
		createArrow(parent, arrow.position, arrow.yaw)
	end

	for _, obstacle in ipairs(OBSTACLES) do
		createPart(parent, "Stage5" .. obstacle.name, obstacle.size, CFrame.new(obstacle.position) * CFrame.Angles(0, math.rad(obstacle.yaw or 0), 0), STAGE_COLORS.Foam, Enum.Material.SmoothPlastic)
	end
end

local function createShelter(parent, slot)
	local safeZones = {}
	local centerX = slot.side * 26
	local openEdgeX = slot.side * 16
	local wallBackX = slot.side * (16 + slot.width + 1)
	local labelColor = slot.index >= 4 and COLORS.White or COLORS.Dark

	local floor = createPart(parent, "Stage5ShelterFloor" .. tostring(slot.index), Vector3.new(slot.width, 1, slot.depth), Vector3.new(centerX, 10.35, slot.z), STAGE_COLORS.Shelter, Enum.Material.SmoothPlastic)
	createSurfaceLabel(floor, slot.label, labelColor)

	createPart(parent, "Stage5ShelterBackWall" .. tostring(slot.index), Vector3.new(2, 8, slot.depth), Vector3.new(wallBackX, 14.5, slot.z), STAGE_COLORS.ShelterDark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage5ShelterFrontLip" .. tostring(slot.index), Vector3.new(1.5, 4, slot.depth), Vector3.new(openEdgeX, 13, slot.z), STAGE_COLORS.ShelterDark, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.35,
	})
	createPart(parent, "Stage5ShelterSideA" .. tostring(slot.index), Vector3.new(slot.width + 3, 7, 1.5), Vector3.new(centerX, 14.1, slot.z - (slot.depth / 2)), STAGE_COLORS.ShelterDark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage5ShelterSideB" .. tostring(slot.index), Vector3.new(slot.width + 3, 7, 1.5), Vector3.new(centerX, 14.1, slot.z + (slot.depth / 2)), STAGE_COLORS.ShelterDark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage5ShelterRoof" .. tostring(slot.index), Vector3.new(slot.width + 2, 1.2, slot.depth + 2), Vector3.new(centerX, 18.5, slot.z), STAGE_COLORS.ShelterDark, Enum.Material.SmoothPlastic)

	local volume = createPart(parent, "Stage5SafeZone" .. tostring(slot.index), Vector3.new(slot.width - 2, 11, slot.depth - 2), Vector3.new(centerX, 15.2, slot.z), STAGE_COLORS.Shelter, Enum.Material.ForceField, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.7,
	})
	volume:SetAttribute(TsunamiConfig.SafeZoneAttribute, true)
	volume:SetAttribute(TsunamiConfig.SafeZoneIndexAttribute, slot.index)

	table.insert(safeZones, volume)
	return safeZones
end

local function createShelters(parent)
	local safeZones = {}
	for _, slot in ipairs(SAFE_SLOTS) do
		for _, zone in ipairs(createShelter(parent, slot)) do
			table.insert(safeZones, zone)
		end
	end

	return safeZones
end

local function createWave(parent)
	local waveConfig = TsunamiConfig.Wave
	local waveModel = Instance.new("Model")
	waveModel.Name = "Stage5TsunamiWave"
	waveModel.Parent = parent

	local parkedCFrame = CFrame.new(waveConfig.ParkX, waveConfig.CenterY, waveConfig.CenterZ)
	local body = createPart(waveModel, "Stage5TsunamiWall", Vector3.new(waveConfig.Width, waveConfig.Height, waveConfig.Depth), parkedCFrame, STAGE_COLORS.Wave, Enum.Material.ForceField, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.26,
	})
	waveModel.PrimaryPart = body

	createPart(waveModel, "Stage5TsunamiFoamTop", Vector3.new(waveConfig.Width + 1.2, 3, waveConfig.Depth), parkedCFrame * CFrame.new(0, waveConfig.Height / 2, 0), STAGE_COLORS.Foam, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.22,
	})
	createPart(waveModel, "Stage5TsunamiFoamBase", Vector3.new(waveConfig.Width + 1.4, 2.2, waveConfig.Depth), parkedCFrame * CFrame.new(0, -(waveConfig.Height / 2) + 2, 0), STAGE_COLORS.Foam, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.32,
	})

	local light = Instance.new("PointLight")
	light.Name = "WaveGlow"
	light.Brightness = 2
	light.Color = STAGE_COLORS.Wave
	light.Range = 34
	light.Parent = body

	return {
		model = waveModel,
		root = body,
	}
end

local function createCheckpoint(parent)
	local platform = createPart(parent, "Stage5CheckpointPlatform", Vector3.new(32, 1, 22), Vector3.new(0, 10.2, 1218), STAGE_COLORS.Deck, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "CP 5", COLORS.Dark)

	local base = createPart(parent, "Stage5CheckpointBase", Vector3.new(22, 0.16, 11), Vector3.new(0, 10.82, 1218), COLORS.CheckpointAccent, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.28,
	})

	local pad = createPart(parent, "Stage5Checkpoint", Vector3.new(18, 0.35, 8), Vector3.new(0, 11.02, 1218), COLORS.Checkpoint, Enum.Material.Neon, {
		CanCollide = false,
	})
	pad:SetAttribute("CheckpointIndex", 5)
	pad:SetAttribute("StageId", STAGE_5_ID)
	pad:SetAttribute("CompletesStage", true)

	return {
		id = "world_1_stage_5_checkpoint",
		index = 5,
		order = 5,
		stageId = STAGE_5_ID,
		completesStage = true,
		part = pad,
		base = base,
		platform = platform,
		respawnPosition = STAGE_5_CHECKPOINT_RESPAWN_POSITION,
		respawnLookAt = STAGE_6_TARGET_POSITION,
		respawnCFrame = createFacingCFrame(STAGE_5_CHECKPOINT_RESPAWN_POSITION, STAGE_6_TARGET_POSITION),
	}
end

local function createStageSixPlaceholder(parent)
	createPart(parent, "Stage5ToStage6Connector", Vector3.new(18, 1, 22), Vector3.new(0, 10.2, 1238), STAGE_COLORS.Road, Enum.Material.Concrete)

	local platform = createPart(parent, "Stage6PlaceholderPlatform", Vector3.new(36, 1, 24), Vector3.new(0, 10.2, 1260), COLORS.Moving, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 6", COLORS.Dark)

	createPart(parent, "Stage6GateLeftPost", Vector3.new(2, 12, 2), Vector3.new(-13, 16.5, 1268), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage6GateRightPost", Vector3.new(2, 12, 2), Vector3.new(13, 16.5, 1268), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage6GateTop", Vector3.new(28, 2, 2), Vector3.new(0, 22.5, 1268), COLORS.Dark, Enum.Material.SmoothPlastic)

	local door = createPart(parent, "Stage6ComingNextDoor", Vector3.new(23, 8, 1), Vector3.new(0, 15.5, 1269), COLORS.Start, Enum.Material.ForceField, {
		Transparency = 0.2,
	})
	createSurfaceLabel(door, "STAGE 6\nBASKETBALL CHALLENGE\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Front)
	createSurfaceLabel(door, "STAGE 6\nBASKETBALL CHALLENGE\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Back)
end

local function createHazards(parent)
	local flood = createPart(parent, "Stage5FloodWaterHazard", Vector3.new(120, 1, 360), Vector3.new(0, 5.8, 1058), STAGE_COLORS.Water, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 1,
	})

	return { flood }
end

function Stage5TsunamiBuilder.build(parent)
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "Stage5TsunamiRun"
	stageFolder.Parent = parent

	createEntrance(stageFolder)
	createLane(stageFolder)
	local safeZones = createShelters(stageFolder)
	local wave = createWave(stageFolder)
	local checkpoint = createCheckpoint(stageFolder)
	createStageSixPlaceholder(stageFolder)
	local hazards = createHazards(stageFolder)

	return {
		stageId = STAGE_5_ID,
		stageStart = {
			stageNumber = 5,
			stageId = STAGE_5_ID,
			cframe = createFacingCFrame(STAGE_5_START_POSITION, STAGE_5_START_LOOK_AT),
		},
		checkpoint = checkpoint,
		safeZones = safeZones,
		waveModel = wave.model,
		waveRoot = wave.root,
		bounds = TsunamiConfig.StageBounds,
		hazards = hazards,
	}
end

return Stage5TsunamiBuilder
