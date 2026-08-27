local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local RcCarConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RcCarConfig"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local Stage4RcMazeBuilder = {}

local COLORS = ObbyConfig.Colors
local WORLD_ID = WorldConfig.CurrentWorldId
local STAGE_4_ID = WorldConfig.Worlds[WORLD_ID].stages[4].id

local STAGE_4_START_POSITION = Vector3.new(0, 13.4, 642)
local STAGE_4_CONTROL_POSITION = Vector3.new(0, 13.4, 652)
local STAGE_4_CONTROL_LOOK_AT = Vector3.new(0, 13.4, 660)
local STAGE_4_CHECKPOINT_RESPAWN_POSITION = Vector3.new(0, 13.4, 858)
local STAGE_5_TARGET_POSITION = Vector3.new(0, 13.4, 894)

local MAZE_TUNING = RcCarConfig.Maze
local MAZE_CENTER = Vector3.new(58, 10.2, 752)
local MAZE_SIZE = Vector3.new(MAZE_TUNING.Width, 1, MAZE_TUNING.Length)
local MAZE_MIN_X = MAZE_CENTER.X - (MAZE_TUNING.Width / 2)
local MAZE_MAX_X = MAZE_CENTER.X + (MAZE_TUNING.Width / 2)
local MAZE_MIN_Z = MAZE_CENTER.Z - (MAZE_TUNING.Length / 2)
local MAZE_MAX_Z = MAZE_CENTER.Z + (MAZE_TUNING.Length / 2)
local STANDARD_OPENING_WIDTH = MAZE_TUNING.CorridorWidth + MAZE_TUNING.BevelSize
local FIRST_TURN_OPENING_WIDTH = MAZE_TUNING.CorridorWidth + MAZE_TUNING.TurnPocketWidth
local RC_START_POSITION = Vector3.new(24, 12.2, 676)
local RC_GOAL_POSITION = Vector3.new(92, 10.95, 828)

local STAGE_COLORS = {
	Concrete = Color3.fromRGB(84, 89, 104),
	Road = Color3.fromRGB(46, 48, 55),
	Rail = Color3.fromRGB(20, 23, 31),
	RcRed = Color3.fromRGB(255, 68, 72),
	RcBlue = Color3.fromRGB(45, 116, 255),
	Goal = Color3.fromRGB(80, 255, 148),
	Arrow = Color3.fromRGB(255, 224, 74),
}

local function horizontalWall(name, startX, endX, z)
	return {
		name = name,
		position = Vector3.new((startX + endX) / 2, 13.2, z),
		size = Vector3.new(math.abs(endX - startX), 5, MAZE_TUNING.WallThickness),
	}
end

local function verticalWall(name, x, startZ, endZ)
	return {
		name = name,
		position = Vector3.new(x, 13.2, (startZ + endZ) / 2),
		size = Vector3.new(MAZE_TUNING.WallThickness, 5, math.abs(endZ - startZ)),
	}
end

local MAZE_WALLS = {
	verticalWall("OuterLeft", MAZE_MIN_X, MAZE_MIN_Z, MAZE_MAX_Z),
	verticalWall("OuterRight", MAZE_MAX_X, MAZE_MIN_Z, MAZE_MAX_Z),
	horizontalWall("OuterBack", MAZE_MIN_X, MAZE_MAX_X, MAZE_MIN_Z),
	horizontalWall("OuterFront", MAZE_MIN_X, MAZE_MAX_X, MAZE_MAX_Z),
	horizontalWall("TeachTurnNorth", MAZE_MIN_X, MAZE_MAX_X - FIRST_TURN_OPENING_WIDTH, 704),
	horizontalWall("TeachTurnSouth", MAZE_MIN_X + STANDARD_OPENING_WIDTH + 8, MAZE_MAX_X, 734),
	horizontalWall("MiddleNorth", MAZE_MIN_X, MAZE_MAX_X - STANDARD_OPENING_WIDTH, 764),
	horizontalWall("MiddleSouth", MAZE_MIN_X + STANDARD_OPENING_WIDTH, MAZE_MAX_X, 794),
	horizontalWall("FinalNorth", MAZE_MIN_X, MAZE_MAX_X - STANDARD_OPENING_WIDTH - 4, 820),
	verticalWall("StartGuideLeft", 12, 670, 694),
	verticalWall("StartGuideRight", 42, 670, 694),
	verticalWall("BridgeGuideLeft", 76, 800, 826),
	verticalWall("BridgeGuideRight", 108, 800, 826),
}

local CORNER_POCKETS = {
	{ position = Vector3.new(88, 10.94, 704), size = Vector3.new(36, 0.12, 18) },
	{ position = Vector3.new(25, 10.94, 734), size = Vector3.new(34, 0.12, 18) },
	{ position = Vector3.new(90, 10.94, 764), size = Vector3.new(34, 0.12, 18) },
	{ position = Vector3.new(24, 10.94, 794), size = Vector3.new(34, 0.12, 18) },
	{ position = Vector3.new(89, 10.94, 820), size = Vector3.new(36, 0.12, 18) },
}

local BUMPS = {
	{ position = Vector3.new(82, 11.08, 722), size = Vector3.new(4.5, 0.65, 1.8) },
	{ position = Vector3.new(30, 11.08, 751), size = Vector3.new(1.8, 0.65, 4.5) },
	{ position = Vector3.new(91, 11.08, 812), size = Vector3.new(4.5, 0.65, 1.8) },
}

local ARROWS = {
	{ position = Vector3.new(24, 10.95, 688), yaw = 0 },
	{ position = Vector3.new(75, 10.95, 704), yaw = 90 },
	{ position = Vector3.new(86, 10.95, 724), yaw = 0 },
	{ position = Vector3.new(34, 10.95, 735), yaw = -90 },
	{ position = Vector3.new(24, 10.95, 754), yaw = 0 },
	{ position = Vector3.new(82, 10.95, 765), yaw = 90 },
	{ position = Vector3.new(94, 10.95, 808), yaw = 0 },
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
	createPart(parent, "Stage4RcArrowStem", Vector3.new(1, 0.16, 6), cframe, STAGE_COLORS.Arrow, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage4RcArrowLeft", Vector3.new(0.8, 0.16, 3.1), cframe * CFrame.new(-1, 0, 2.2) * CFrame.Angles(0, math.rad(-35), 0), STAGE_COLORS.Arrow, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage4RcArrowRight", Vector3.new(0.8, 0.16, 3.1), cframe * CFrame.new(1, 0, 2.2) * CFrame.Angles(0, math.rad(35), 0), STAGE_COLORS.Arrow, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
end

local function createEntrance(parent)
	local platform = createPart(parent, "Stage4EntrancePlatform", Vector3.new(36, 1, 26), Vector3.new(0, 10.2, 642), STAGE_COLORS.Concrete, Enum.Material.Concrete)
	createSurfaceLabel(platform, "STAGE 4\nRC CAR MAZE", COLORS.White)

	local station = createPart(parent, "Stage4RcControlStation", Vector3.new(10, 3.4, 6), Vector3.new(0, 12.4, 660), STAGE_COLORS.RcBlue, Enum.Material.SmoothPlastic)
	createSurfaceLabel(station, "RC\nCONTROL", COLORS.White, Enum.NormalId.Front)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StartRcMazePrompt"
	prompt.ActionText = "Drive RC Car"
	prompt.ObjectText = "RC Control Station"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Parent = station

	createPart(parent, "Stage4Antenna", Vector3.new(0.35, 8, 0.35), Vector3.new(0, 18, 660), STAGE_COLORS.Arrow, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage4ExitWalkway", Vector3.new(18, 1, 166), Vector3.new(0, 10.2, 766), STAGE_COLORS.Road, Enum.Material.Concrete)

	return {
		platform = platform,
		station = station,
		prompt = prompt,
	}
end

local function createGate(parent)
	local gateFrame = createPart(parent, "Stage4RcGateFrame", Vector3.new(26, 10, 2), Vector3.new(0, 15.2, 681), STAGE_COLORS.Rail, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
	createSurfaceLabel(gateFrame, "RC GATE", COLORS.White, Enum.NormalId.Front)
	createSurfaceLabel(gateFrame, "RC GATE", COLORS.White, Enum.NormalId.Back)

	local doorVisual = createPart(parent, "Stage4RcDoorVisual", Vector3.new(22, 7, 1), Vector3.new(0, 14.2, 681), STAGE_COLORS.RcRed, Enum.Material.ForceField, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.08,
	})
	createSurfaceLabel(doorVisual, "LOCKED\nFINISH RC", COLORS.White, Enum.NormalId.Front)
	createSurfaceLabel(doorVisual, "LOCKED\nFINISH RC", COLORS.White, Enum.NormalId.Back)

	local gateBlocker = createPart(parent, "Stage4RcGateBlocker", Vector3.new(24, 8, 6), Vector3.new(0, 14.2, 681), COLORS.Dark, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 1,
	})

	return {
		frame = gateFrame,
		doorVisual = doorVisual,
		gateBlocker = gateBlocker,
	}
end

local function createMaze(parent)
	local mazeFolder = Instance.new("Folder")
	mazeFolder.Name = "Stage4RcMaze"
	mazeFolder.Parent = parent

	local base = createPart(mazeFolder, "Stage4RcMazeBase", MAZE_SIZE, MAZE_CENTER, STAGE_COLORS.Road, Enum.Material.Concrete)
	createSurfaceLabel(base, "RC MAZE", COLORS.White)

	for _, wall in ipairs(MAZE_WALLS) do
		createPart(mazeFolder, "Stage4MazeWall" .. wall.name, wall.size, wall.position, STAGE_COLORS.Rail, Enum.Material.Concrete)
	end

	for _, pocket in ipairs(CORNER_POCKETS) do
		createPart(mazeFolder, "Stage4RcCornerPocket", pocket.size, pocket.position, Color3.fromRGB(64, 72, 88), Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
			Transparency = 0.16,
		})
	end

	for _, bump in ipairs(BUMPS) do
		createPart(mazeFolder, "Stage4RcBump", bump.size, bump.position, STAGE_COLORS.Concrete, Enum.Material.SmoothPlastic)
	end

	createPart(mazeFolder, "Stage4RcBridge", Vector3.new(24, 0.7, 16), Vector3.new(92, 11.05, 812), Color3.fromRGB(76, 81, 96), Enum.Material.Metal)
	createPart(mazeFolder, "Stage4RcBridgeRampA", Vector3.new(24, 0.45, 8), CFrame.new(92, 10.9, 801) * CFrame.Angles(math.rad(-5), 0, 0), Color3.fromRGB(92, 96, 110), Enum.Material.Metal)
	createPart(mazeFolder, "Stage4RcBridgeRampB", Vector3.new(24, 0.45, 8), CFrame.new(92, 10.9, 825) * CFrame.Angles(math.rad(5), 0, 0), Color3.fromRGB(92, 96, 110), Enum.Material.Metal)

	for _, arrow in ipairs(ARROWS) do
		createArrow(mazeFolder, arrow.position, arrow.yaw)
	end

	local goal = createPart(mazeFolder, "Stage4RcGoalZone", Vector3.new(14, 0.35, 14), RC_GOAL_POSITION, STAGE_COLORS.Goal, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createSurfaceLabel(goal, "GOAL", COLORS.Dark)

	local light = Instance.new("PointLight")
	light.Name = "GoalGlow"
	light.Brightness = 2.2
	light.Color = STAGE_COLORS.Goal
	light.Range = 28
	light.Parent = goal

	local rcCarsFolder = Instance.new("Folder")
	rcCarsFolder.Name = RcCarConfig.CarFolderName
	rcCarsFolder.Parent = parent

	return {
		folder = mazeFolder,
		base = base,
		goal = goal,
		rcCarsFolder = rcCarsFolder,
		bounds = {
			minX = MAZE_MIN_X - 4,
			maxX = MAZE_MAX_X + 4,
			minZ = MAZE_MIN_Z,
			maxZ = MAZE_MAX_Z,
			minY = 7,
			maxY = 35,
		},
		rcStartCFrame = createFacingCFrame(RC_START_POSITION, RC_START_POSITION + Vector3.new(0, 0, 12)),
	}
end

local function createCheckpoint(parent)
	local platform = createPart(parent, "Stage4CheckpointPlatform", Vector3.new(30, 1, 20), Vector3.new(0, 10.2, 858), STAGE_COLORS.Concrete, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "CP 4", COLORS.Dark)

	local base = createPart(parent, "Stage4CheckpointBase", Vector3.new(21, 0.16, 10), Vector3.new(0, 10.82, 858), COLORS.CheckpointAccent, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.28,
	})

	local pad = createPart(parent, "Stage4Checkpoint", Vector3.new(17, 0.35, 7), Vector3.new(0, 11.02, 858), COLORS.Checkpoint, Enum.Material.Neon, {
		CanCollide = false,
	})
	pad:SetAttribute("CheckpointIndex", 4)
	pad:SetAttribute("StageId", STAGE_4_ID)
	pad:SetAttribute("CompletesStage", true)
	pad:SetAttribute("RequiresRcCompletion", true)

	return {
		id = "world_1_stage_4_checkpoint",
		index = 4,
		order = 4,
		stageId = STAGE_4_ID,
		completesStage = true,
		requiresRcCompletion = true,
		part = pad,
		base = base,
		platform = platform,
		respawnPosition = STAGE_4_CHECKPOINT_RESPAWN_POSITION,
		respawnLookAt = STAGE_5_TARGET_POSITION,
		respawnCFrame = createFacingCFrame(STAGE_4_CHECKPOINT_RESPAWN_POSITION, STAGE_5_TARGET_POSITION),
	}
end

local function createStageFivePlaceholder(parent)
	createPart(parent, "Stage4ToStage5Connector", Vector3.new(18, 1, 22), Vector3.new(0, 10.2, 875), STAGE_COLORS.Road, Enum.Material.Concrete)

	local platform = createPart(parent, "Stage5PlaceholderPlatform", Vector3.new(34, 1, 24), Vector3.new(0, 10.2, 894), COLORS.Moving, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 5", COLORS.Dark)

	createPart(parent, "Stage5GateLeftPost", Vector3.new(2, 12, 2), Vector3.new(-12, 16.5, 902), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage5GateRightPost", Vector3.new(2, 12, 2), Vector3.new(12, 16.5, 902), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage5GateTop", Vector3.new(26, 2, 2), Vector3.new(0, 22.5, 902), COLORS.Dark, Enum.Material.SmoothPlastic)

	local door = createPart(parent, "Stage5ComingNextDoor", Vector3.new(21, 8, 1), Vector3.new(0, 15.5, 903), COLORS.Start, Enum.Material.ForceField, {
		Transparency = 0.2,
	})
	createSurfaceLabel(door, "STAGE 5\nTSUNAMI RUN\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Front)
	createSurfaceLabel(door, "STAGE 5\nTSUNAMI RUN\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Back)
end

function Stage4RcMazeBuilder.build(parent)
	local entrance = createEntrance(parent)
	local gate = createGate(parent)
	local maze = createMaze(parent)
	local checkpoint = createCheckpoint(parent)
	createStageFivePlaceholder(parent)

	return {
		stageId = STAGE_4_ID,
		stageStart = {
			stageNumber = 4,
			stageId = STAGE_4_ID,
			cframe = createFacingCFrame(STAGE_4_START_POSITION, Vector3.new(0, STAGE_4_START_POSITION.Y, 660)),
		},
		controlPrompt = entrance.prompt,
		controlStation = entrance.station,
		controlCharacterCFrame = createFacingCFrame(STAGE_4_CONTROL_POSITION, STAGE_4_CONTROL_LOOK_AT),
		deniedCFrame = createFacingCFrame(Vector3.new(0, 13.4, 666), STAGE_4_CONTROL_LOOK_AT),
		doorVisual = gate.doorVisual,
		gateBlocker = gate.gateBlocker,
		rcCarsFolder = maze.rcCarsFolder,
		rcStartCFrame = maze.rcStartCFrame,
		rcGoal = maze.goal,
		bounds = maze.bounds,
		checkpoint = checkpoint,
	}
end

return Stage4RcMazeBuilder
