local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BasketballConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasketballConfig"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local Stage6BasketballBuilder = {}

local COLORS = ObbyConfig.Colors
local WORLD_ID = WorldConfig.CurrentWorldId
local STAGE_6_ID = WorldConfig.Worlds[WORLD_ID].stages[6].id

local STAGE_6_START_POSITION = Vector3.new(0, 13.4, 1260)
local STAGE_6_START_LOOK_AT = Vector3.new(0, 13.4, 1296)
local STAGE_6_CHECKPOINT_RESPAWN_POSITION = Vector3.new(0, 13.4, 1468)
local STAGE_7_TARGET_POSITION = Vector3.new(0, 13.4, 1512)

local HOOP_CENTER = Vector3.new(0, 17.4, 1304)
local SHOT_TARGET = HOOP_CENTER + Vector3.new(0, 0.35, 0)

local COURT_COLORS = {
	Court = Color3.fromRGB(212, 116, 47),
	CourtDark = Color3.fromRGB(140, 63, 35),
	Paint = Color3.fromRGB(70, 116, 215),
	Line = Color3.fromRGB(246, 246, 238),
	Hoop = Color3.fromRGB(255, 108, 38),
	Backboard = Color3.fromRGB(235, 247, 255),
	Net = Color3.fromRGB(235, 235, 235),
	Gate = Color3.fromRGB(255, 224, 74),
}

local SHOT_STATIONS = {
	{
		index = 1,
		name = "Stage6FreeThrowStation",
		position = Vector3.new(0, 11.05, 1342),
		size = Vector3.new(18, 0.35, 8),
		label = "FREE\nTHROW",
		color = Color3.fromRGB(80, 255, 148),
	},
	{
		index = 2,
		name = "Stage6ThreePointerStation",
		position = Vector3.new(0, 11.05, 1374),
		size = Vector3.new(18, 0.35, 8),
		label = "THREE\nPOINTER",
		color = Color3.fromRGB(80, 255, 218),
	},
	{
		index = 3,
		name = "Stage6HalfCourtStation",
		position = Vector3.new(0, 11.05, 1414),
		size = Vector3.new(20, 0.35, 8),
		label = "HALF\nCOURT",
		color = Color3.fromRGB(255, 219, 74),
	},
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

local function createCourtLine(parent, name, size, positionOrCFrame)
	return createPart(parent, name, size, positionOrCFrame, COURT_COLORS.Line, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
end

local function createEntrance(parent)
	createPart(parent, "Stage6ConnectorFromCp5", Vector3.new(18, 1, 24), Vector3.new(0, 10.2, 1240), COURT_COLORS.CourtDark, Enum.Material.Concrete)

	local platform = createPart(parent, "Stage6EntrancePlatform", Vector3.new(38, 1, 26), Vector3.new(0, 10.2, 1260), COURT_COLORS.Court, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 6\nBASKETBALL CHALLENGE", COLORS.White)
end

local function createCourt(parent)
	createPart(parent, "Stage6BasketballCourt", Vector3.new(46, 1, 190), Vector3.new(0, 10.2, 1356), COURT_COLORS.Court, Enum.Material.Concrete)

	createCourtLine(parent, "Stage6LeftSideline", Vector3.new(0.4, 0.12, 180), Vector3.new(-21, 10.86, 1356))
	createCourtLine(parent, "Stage6RightSideline", Vector3.new(0.4, 0.12, 180), Vector3.new(21, 10.86, 1356))
	createCourtLine(parent, "Stage6BaselineNearHoop", Vector3.new(42, 0.12, 0.4), Vector3.new(0, 10.86, 1284))
	createCourtLine(parent, "Stage6BaselineFar", Vector3.new(42, 0.12, 0.4), Vector3.new(0, 10.86, 1448))
	createCourtLine(parent, "Stage6HalfCourtLine", Vector3.new(42, 0.12, 0.4), Vector3.new(0, 10.86, 1414))
	createCourtLine(parent, "Stage6FreeThrowLine", Vector3.new(28, 0.12, 0.4), Vector3.new(0, 10.86, 1342))
	createCourtLine(parent, "Stage6ThreePointLine", Vector3.new(36, 0.12, 0.4), Vector3.new(0, 10.86, 1374))

	createPart(parent, "Stage6PaintArea", Vector3.new(20, 0.15, 42), Vector3.new(0, 10.92, 1320), COURT_COLORS.Paint, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.15,
	})
end

local function createHoop(parent)
	createPart(parent, "Stage6BackboardPost", Vector3.new(2, 19, 2), Vector3.new(0, 18.4, 1284), COLORS.Dark, Enum.Material.Metal)
	createPart(parent, "Stage6Backboard", Vector3.new(16, 10, 1), Vector3.new(0, 21.2, 1294), COURT_COLORS.Backboard, Enum.Material.Glass, {
		Transparency = 0.18,
	})

	createPart(parent, "Stage6RimFront", Vector3.new(8, 0.35, 0.6), Vector3.new(0, HOOP_CENTER.Y, HOOP_CENTER.Z + 3), COURT_COLORS.Hoop, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage6RimBack", Vector3.new(8, 0.35, 0.6), Vector3.new(0, HOOP_CENTER.Y, HOOP_CENTER.Z - 3), COURT_COLORS.Hoop, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage6RimLeft", Vector3.new(0.6, 0.35, 6), Vector3.new(-4, HOOP_CENTER.Y, HOOP_CENTER.Z), COURT_COLORS.Hoop, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage6RimRight", Vector3.new(0.6, 0.35, 6), Vector3.new(4, HOOP_CENTER.Y, HOOP_CENTER.Z), COURT_COLORS.Hoop, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})

	for index, x in ipairs({ -3, -1.5, 0, 1.5, 3 }) do
		createPart(parent, "Stage6NetLine" .. tostring(index), Vector3.new(0.18, 3.8, 0.18), Vector3.new(x, HOOP_CENTER.Y - 2, HOOP_CENTER.Z + 2.6), COURT_COLORS.Net, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
		})
	end

	local scoringZone = createPart(parent, "Stage6ScoringZone", BasketballConfig.Scoring.ZoneSize, HOOP_CENTER, Color3.fromRGB(80, 255, 148), Enum.Material.ForceField, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 1,
	})

	return scoringZone
end

local function createStations(parent)
	local stations = {}

	for _, stationConfig in ipairs(SHOT_STATIONS) do
		local station = createPart(parent, stationConfig.name, stationConfig.size, stationConfig.position, stationConfig.color, Enum.Material.Neon, {
			CanCollide = false,
		})
		createSurfaceLabel(station, stationConfig.label, COLORS.Dark)
		station:SetAttribute("ShotIndex", stationConfig.index)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StartBasketballShotPrompt"
		prompt.ActionText = "Shoot"
		prompt.ObjectText = stationConfig.label:gsub("\n", " ")
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.15
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = station

		table.insert(stations, {
			index = stationConfig.index,
			part = station,
			prompt = prompt,
			cframe = createFacingCFrame(stationConfig.position + Vector3.new(0, 3.2, 0), SHOT_TARGET),
			shotStartPosition = stationConfig.position + Vector3.new(0, BasketballConfig.Ball.StartHeight + 1.2, -BasketballConfig.Ball.StartForwardOffset),
		})
	end

	return stations
end

local function createGate(parent)
	local frame = createPart(parent, "Stage6ChallengeGateFrame", Vector3.new(28, 10, 2), Vector3.new(0, 15.2, 1438), COLORS.Dark, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})

	local doorVisual = createPart(parent, "Stage6BasketballDoorVisual", Vector3.new(24, 7, 1), Vector3.new(0, 14.2, 1438), COURT_COLORS.Gate, Enum.Material.ForceField, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.12,
	})
	createSurfaceLabel(doorVisual, "LOCKED\nMAKE SHOTS", COLORS.Dark, Enum.NormalId.Front)
	createSurfaceLabel(doorVisual, "LOCKED\nMAKE SHOTS", COLORS.Dark, Enum.NormalId.Back)

	local gateBlocker = createPart(parent, "Stage6BasketballGateBlocker", Vector3.new(24, 8, 6), Vector3.new(0, 14.2, 1438), COLORS.Dark, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 1,
	})

	return {
		doorVisual = doorVisual,
		gateBlocker = gateBlocker,
	}
end

local function createCheckpoint(parent)
	local platform = createPart(parent, "Stage6CheckpointPlatform", Vector3.new(32, 1, 22), Vector3.new(0, 10.2, 1468), COURT_COLORS.CourtDark, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "CP 6", COLORS.Dark)

	local base = createPart(parent, "Stage6CheckpointBase", Vector3.new(22, 0.16, 11), Vector3.new(0, 10.82, 1468), COLORS.CheckpointAccent, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.28,
	})

	local pad = createPart(parent, "Stage6Checkpoint", Vector3.new(18, 0.35, 8), Vector3.new(0, 11.02, 1468), COLORS.Checkpoint, Enum.Material.Neon, {
		CanCollide = false,
	})
	pad:SetAttribute("CheckpointIndex", 6)
	pad:SetAttribute("StageId", STAGE_6_ID)
	pad:SetAttribute("CompletesStage", true)
	pad:SetAttribute("RequiresBasketballCompletion", true)

	return {
		id = "world_1_stage_6_checkpoint",
		index = 6,
		order = 6,
		stageId = STAGE_6_ID,
		completesStage = true,
		requiresBasketballCompletion = true,
		part = pad,
		base = base,
		platform = platform,
		respawnPosition = STAGE_6_CHECKPOINT_RESPAWN_POSITION,
		respawnLookAt = STAGE_7_TARGET_POSITION,
		respawnCFrame = createFacingCFrame(STAGE_6_CHECKPOINT_RESPAWN_POSITION, STAGE_7_TARGET_POSITION),
	}
end

local function createStageSevenPlaceholder(parent)
	createPart(parent, "Stage6ToStage7Connector", Vector3.new(18, 1, 22), Vector3.new(0, 10.2, 1490), COURT_COLORS.CourtDark, Enum.Material.Concrete)

	local platform = createPart(parent, "Stage7PlaceholderPlatform", Vector3.new(36, 1, 24), Vector3.new(0, 10.2, 1512), COLORS.Moving, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 7", COLORS.Dark)

	createPart(parent, "Stage7GateLeftPost", Vector3.new(2, 12, 2), Vector3.new(-13, 16.5, 1520), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage7GateRightPost", Vector3.new(2, 12, 2), Vector3.new(13, 16.5, 1520), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage7GateTop", Vector3.new(28, 2, 2), Vector3.new(0, 22.5, 1520), COLORS.Dark, Enum.Material.SmoothPlastic)

	local door = createPart(parent, "Stage7ComingNextDoor", Vector3.new(23, 8, 1), Vector3.new(0, 15.5, 1521), COLORS.Start, Enum.Material.ForceField, {
		Transparency = 0.2,
	})
	createSurfaceLabel(door, "STAGE 7\nCAT AND MOUSE\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Front)
	createSurfaceLabel(door, "STAGE 7\nCAT AND MOUSE\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Back)
end

function Stage6BasketballBuilder.build(parent)
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "Stage6BasketballChallenge"
	stageFolder.Parent = parent

	createEntrance(stageFolder)
	createCourt(stageFolder)
	local scoringZone = createHoop(stageFolder)
	local stations = createStations(stageFolder)
	local gate = createGate(stageFolder)
	local checkpoint = createCheckpoint(stageFolder)
	createStageSevenPlaceholder(stageFolder)

	local ballsFolder = Instance.new("Folder")
	ballsFolder.Name = "Stage6PlayerBasketballs"
	ballsFolder.Parent = stageFolder

	return {
		stageId = STAGE_6_ID,
		stageStart = {
			stageNumber = 6,
			stageId = STAGE_6_ID,
			cframe = createFacingCFrame(STAGE_6_START_POSITION, STAGE_6_START_LOOK_AT),
		},
		checkpoint = checkpoint,
		stations = stations,
		scoringZone = scoringZone,
		shotTarget = SHOT_TARGET,
		doorVisual = gate.doorVisual,
		gateBlocker = gate.gateBlocker,
		deniedCFrame = createFacingCFrame(Vector3.new(0, 13.4, 1420), SHOT_TARGET),
		ballsFolder = ballsFolder,
	}
end

return Stage6BasketballBuilder
