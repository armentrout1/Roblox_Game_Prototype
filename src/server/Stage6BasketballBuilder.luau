local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BasketballConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasketballConfig"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local Stage6BasketballBuilder = {}

local COLORS = ObbyConfig.Colors
local WORLD_ID = WorldConfig.CurrentWorldId
local STAGE_6_ID = WorldConfig.Worlds[WORLD_ID].stages[6].id
local COURT = BasketballConfig.Court
local FLOOR_TOP_Y = COURT.FloorCenter.Y + (COURT.FloorSize.Y / 2)
local PLATFORM_TOP_Y = COURT.PlatformCenter.Y + (COURT.PlatformSize.Y / 2)
local HOOP_CENTER = COURT.HoopCenter
local SHOT_TARGET = HOOP_CENTER + COURT.ShotTargetOffset

local COURT_COLORS = {
	Basalt = Color3.fromRGB(30, 32, 38),
	BasaltLight = Color3.fromRGB(55, 59, 70),
	Floor = Color3.fromRGB(204, 125, 54),
	FloorDark = Color3.fromRGB(129, 70, 37),
	Paint = Color3.fromRGB(44, 116, 197),
	Line = Color3.fromRGB(248, 244, 226),
	Glow = Color3.fromRGB(255, 128, 47),
	Hoop = Color3.fromRGB(255, 93, 30),
	Backboard = Color3.fromRGB(226, 246, 255),
	Net = Color3.fromRGB(238, 238, 230),
	Gate = Color3.fromRGB(255, 224, 74),
	Next = Color3.fromRGB(255, 219, 74),
}

local SHOT_STATIONS = {
	{
		index = 1,
		name = "Stage6FreeThrowStation",
		position = Vector3.new(0, FLOOR_TOP_Y + 0.13, 1342),
		size = Vector3.new(17, 0.26, 7),
		label = "FREE\nTHROW",
		color = Color3.fromRGB(82, 255, 151),
	},
	{
		index = 2,
		name = "Stage6ThreePointerStation",
		position = Vector3.new(0, FLOOR_TOP_Y + 0.13, 1374),
		size = Vector3.new(17, 0.26, 7),
		label = "THREE\nPOINTER",
		color = Color3.fromRGB(80, 215, 255),
	},
	{
		index = 3,
		name = "Stage6HalfCourtStation",
		position = Vector3.new(0, FLOOR_TOP_Y + 0.13, 1414),
		size = Vector3.new(19, 0.26, 7),
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

local function createSurfaceLabel(parent, text, textColor, face, pixelsPerStud)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "SurfaceLabel"
	surfaceGui.Face = face or Enum.NormalId.Top
	surfaceGui.LightInfluence = 0
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = pixelsPerStud or 32
	surfaceGui.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = textColor or COLORS.Dark
	label.TextScaled = true
	label.TextStrokeColor3 = COLORS.Dark
	label.TextStrokeTransparency = 0.55
	label.TextWrapped = true
	label.Parent = surfaceGui
end

local function createCourtLine(parent, name, size, positionOrCFrame)
	return createPart(parent, name, size, positionOrCFrame, COURT_COLORS.Line, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
end

local function createArcLine(parent, name, center, radius, startDegrees, endDegrees, segments, thickness)
	local floorY = FLOOR_TOP_Y + 0.065
	for segment = 1, segments do
		local alphaA = (segment - 1) / segments
		local alphaB = segment / segments
		local angleA = math.rad(startDegrees + ((endDegrees - startDegrees) * alphaA))
		local angleB = math.rad(startDegrees + ((endDegrees - startDegrees) * alphaB))
		local pointA = Vector3.new(center.X + (math.sin(angleA) * radius), floorY, center.Z + (math.cos(angleA) * radius))
		local pointB = Vector3.new(center.X + (math.sin(angleB) * radius), floorY, center.Z + (math.cos(angleB) * radius))
		local midpoint = (pointA + pointB) / 2
		local delta = pointB - pointA
		local yaw = math.atan2(delta.X, delta.Z)

		createCourtLine(parent, string.format("%s%02d", name, segment), Vector3.new(thickness, 0.12, delta.Magnitude), CFrame.new(midpoint) * CFrame.Angles(0, yaw, 0))
	end
end

local function createRail(parent, name, position, size)
	return createPart(parent, name, size, position, COURT_COLORS.Basalt, Enum.Material.Metal, {
		CanTouch = false,
	})
end

local function createRails(parent)
	local railY = PLATFORM_TOP_Y + 2.2
	createRail(parent, "Stage6LeftCourtRail", Vector3.new(-34.5, railY, 1364), Vector3.new(1, 3.2, 172))
	createRail(parent, "Stage6RightCourtRail", Vector3.new(34.5, railY, 1364), Vector3.new(1, 3.2, 172))
	createRail(parent, "Stage6BackRail", Vector3.new(0, railY, 1456), Vector3.new(68, 3.2, 1))
	createRail(parent, "Stage6HoopEndRailLeft", Vector3.new(-22, railY, 1276), Vector3.new(24, 3.2, 1))
	createRail(parent, "Stage6HoopEndRailRight", Vector3.new(22, railY, 1276), Vector3.new(24, 3.2, 1))

	for index, z in ipairs({ 1288, 1316, 1344, 1372, 1400, 1428 }) do
		createRail(parent, "Stage6LeftFencePost" .. tostring(index), Vector3.new(-34.5, PLATFORM_TOP_Y + 2.6, z), Vector3.new(1.4, 4.8, 1.4))
		createRail(parent, "Stage6RightFencePost" .. tostring(index), Vector3.new(34.5, PLATFORM_TOP_Y + 2.6, z), Vector3.new(1.4, 4.8, 1.4))
	end
end

local function createRamp(parent)
	createPart(parent, "Stage6GroundConnectorFromCp5", Vector3.new(22, 1, 16), Vector3.new(0, 10.2, 1229), COURT_COLORS.BasaltLight, Enum.Material.Concrete)

	local startTop = Vector3.new(0, 10.85, 1236)
	local endTop = Vector3.new(0, PLATFORM_TOP_Y + 0.15, 1266)
	local delta = endTop - startTop
	local length = math.sqrt((delta.Y * delta.Y) + (delta.Z * delta.Z))
	local angle = -math.atan2(delta.Y, delta.Z)
	local midpoint = (startTop + endTop) / 2

	createPart(parent, "Stage6ElevatedCourtRamp", Vector3.new(24, 1.05, length), CFrame.new(midpoint) * CFrame.Angles(angle, 0, 0), COURT_COLORS.BasaltLight, Enum.Material.Concrete)
	createRail(parent, "Stage6RampLeftRail", Vector3.new(-12.5, 16.2, 1252), Vector3.new(1, 3, 42))
	createRail(parent, "Stage6RampRightRail", Vector3.new(12.5, 16.2, 1252), Vector3.new(1, 3, 42))
end

local function createElevatedPlatform(parent)
	createRamp(parent)

	createPart(parent, "Stage6ElevatedBasaltPlatform", COURT.PlatformSize, COURT.PlatformCenter, COURT_COLORS.Basalt, Enum.Material.Slate)

	for index, x in ipairs({ -28, 28 }) do
		createPart(parent, "Stage6UndercourtLavaGlow" .. tostring(index), Vector3.new(8, 0.16, 188), Vector3.new(x, COURT.PlatformCenter.Y - 0.74, COURT.PlatformCenter.Z), COURT_COLORS.Glow, Enum.Material.Neon, {
			CanCollide = false,
			CanTouch = false,
			Transparency = 0.22,
		})
	end

	createPart(parent, "Stage6HardwoodCourtFloor", COURT.FloorSize, COURT.FloorCenter, COURT_COLORS.Floor, Enum.Material.WoodPlanks)
	createPart(parent, "Stage6CourtBorderLeft", Vector3.new(2, 0.14, 188), Vector3.new(-28, FLOOR_TOP_Y + 0.02, COURT.FloorCenter.Z), COURT_COLORS.FloorDark, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.12,
	})
	createPart(parent, "Stage6CourtBorderRight", Vector3.new(2, 0.14, 188), Vector3.new(28, FLOOR_TOP_Y + 0.02, COURT.FloorCenter.Z), COURT_COLORS.FloorDark, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.12,
	})
	createPart(parent, "Stage6CourtBorderNear", Vector3.new(58, 0.14, 2), Vector3.new(0, FLOOR_TOP_Y + 0.02, 1268), COURT_COLORS.FloorDark, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.12,
	})
	createPart(parent, "Stage6CourtBorderFar", Vector3.new(58, 0.14, 2), Vector3.new(0, FLOOR_TOP_Y + 0.02, 1452), COURT_COLORS.FloorDark, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.12,
	})

	createRails(parent)
end

local function createEntrance(parent)
	local pad = createPart(parent, "Stage6EntrancePlatform", Vector3.new(36, 0.32, 18), Vector3.new(0, FLOOR_TOP_Y + 0.18, 1262), COURT_COLORS.Next, Enum.Material.Neon, {
		CanCollide = false,
		Transparency = 0.08,
	})
	createSurfaceLabel(pad, "STAGE 6\nBASKETBALL", COLORS.Dark, Enum.NormalId.Top, 28)

	createPart(parent, "Stage6EntranceLeftBeacon", Vector3.new(1.5, 6, 1.5), Vector3.new(-19, PLATFORM_TOP_Y + 3, 1262), COURT_COLORS.Glow, Enum.Material.Neon, {
		CanTouch = false,
	})
	createPart(parent, "Stage6EntranceRightBeacon", Vector3.new(1.5, 6, 1.5), Vector3.new(19, PLATFORM_TOP_Y + 3, 1262), COURT_COLORS.Glow, Enum.Material.Neon, {
		CanTouch = false,
	})
end

local function createCourt(parent)
	local floorY = FLOOR_TOP_Y + 0.065

	createCourtLine(parent, "Stage6LeftSideline", Vector3.new(0.42, 0.12, 176), Vector3.new(-24, floorY, 1360))
	createCourtLine(parent, "Stage6RightSideline", Vector3.new(0.42, 0.12, 176), Vector3.new(24, floorY, 1360))
	createCourtLine(parent, "Stage6BaselineNearHoop", Vector3.new(48, 0.12, 0.42), Vector3.new(0, floorY, 1276))
	createCourtLine(parent, "Stage6BaselineFar", Vector3.new(48, 0.12, 0.42), Vector3.new(0, floorY, 1448))
	createCourtLine(parent, "Stage6HalfCourtLine", Vector3.new(48, 0.12, 0.42), Vector3.new(0, floorY, 1414))
	createCourtLine(parent, "Stage6FreeThrowLine", Vector3.new(19, 0.12, 0.42), Vector3.new(0, floorY, 1342))

	createPart(parent, "Stage6PaintedLane", Vector3.new(18, 0.13, 66), Vector3.new(0, floorY + 0.01, 1309), COURT_COLORS.Paint, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.08,
	})
	createCourtLine(parent, "Stage6LaneLeftLine", Vector3.new(0.34, 0.14, 66), Vector3.new(-9, floorY + 0.04, 1309))
	createCourtLine(parent, "Stage6LaneRightLine", Vector3.new(0.34, 0.14, 66), Vector3.new(9, floorY + 0.04, 1309))
	createCourtLine(parent, "Stage6LaneTopLine", Vector3.new(18, 0.14, 0.34), Vector3.new(0, floorY + 0.04, 1342))

	createArcLine(parent, "Stage6CenterCircle", Vector3.new(0, floorY, 1414), 7.8, 0, 360, 36, 0.38)
	createArcLine(parent, "Stage6FreeThrowCircle", Vector3.new(0, floorY, 1342), 9, -90, 90, 18, 0.34)
	createArcLine(parent, "Stage6ThreePointArc", Vector3.new(HOOP_CENTER.X, floorY, HOOP_CENTER.Z), 70, -20, 20, 22, 0.38)

	for index, x in ipairs({ -18, 18 }) do
		createPart(parent, "Stage6VolcanicCornerAccent" .. tostring(index), Vector3.new(8, 0.16, 8), CFrame.new(x, floorY + 0.02, 1441) * CFrame.Angles(0, math.rad(45), 0), COURT_COLORS.Glow, Enum.Material.Neon, {
			CanCollide = false,
			CanTouch = false,
			Transparency = 0.28,
		})
	end
end

local function createHoop(parent)
	createPart(parent, "Stage6HoopPost", Vector3.new(2.2, 19, 2.2), Vector3.new(0, PLATFORM_TOP_Y + 9.5, 1288), COURT_COLORS.Basalt, Enum.Material.Metal)
	createPart(parent, "Stage6HoopArm", Vector3.new(2, 1.5, 11), Vector3.new(0, HOOP_CENTER.Y + 3.8, 1294), COURT_COLORS.Basalt, Enum.Material.Metal)
	createPart(parent, "Stage6Backboard", Vector3.new(17, 10, 1), Vector3.new(0, HOOP_CENTER.Y + 4.4, 1296), COURT_COLORS.Backboard, Enum.Material.Glass, {
		Transparency = 0.16,
	})
	createPart(parent, "Stage6BackboardTargetTop", Vector3.new(7, 0.18, 0.12), Vector3.new(0, HOOP_CENTER.Y + 5.4, 1296.56), COURT_COLORS.Line, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage6BackboardTargetBottom", Vector3.new(7, 0.18, 0.12), Vector3.new(0, HOOP_CENTER.Y + 2.8, 1296.56), COURT_COLORS.Line, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage6BackboardTargetLeft", Vector3.new(0.18, 2.6, 0.12), Vector3.new(-3.5, HOOP_CENTER.Y + 4.1, 1296.56), COURT_COLORS.Line, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage6BackboardTargetRight", Vector3.new(0.18, 2.6, 0.12), Vector3.new(3.5, HOOP_CENTER.Y + 4.1, 1296.56), COURT_COLORS.Line, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})

	createPart(parent, "Stage6RimFront", Vector3.new(7.6, 0.34, 0.55), Vector3.new(0, HOOP_CENTER.Y, HOOP_CENTER.Z + 3.2), COURT_COLORS.Hoop, Enum.Material.Neon)
	createPart(parent, "Stage6RimBack", Vector3.new(7.6, 0.34, 0.55), Vector3.new(0, HOOP_CENTER.Y, HOOP_CENTER.Z - 3.2), COURT_COLORS.Hoop, Enum.Material.Neon)
	createPart(parent, "Stage6RimLeft", Vector3.new(0.55, 0.34, 6.4), Vector3.new(-3.8, HOOP_CENTER.Y, HOOP_CENTER.Z), COURT_COLORS.Hoop, Enum.Material.Neon)
	createPart(parent, "Stage6RimRight", Vector3.new(0.55, 0.34, 6.4), Vector3.new(3.8, HOOP_CENTER.Y, HOOP_CENTER.Z), COURT_COLORS.Hoop, Enum.Material.Neon)

	for index, x in ipairs({ -3, -1.5, 0, 1.5, 3 }) do
		createPart(parent, "Stage6NetLine" .. tostring(index), Vector3.new(0.18, 3.8, 0.18), Vector3.new(x, HOOP_CENTER.Y - 2, HOOP_CENTER.Z + 2.6), COURT_COLORS.Net, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
		})
	end
	for index, z in ipairs({ -2, 0, 2 }) do
		createPart(parent, "Stage6NetCrossLine" .. tostring(index), Vector3.new(6.4, 0.16, 0.16), Vector3.new(0, HOOP_CENTER.Y - 2.6, HOOP_CENTER.Z + z), COURT_COLORS.Net, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
		})
	end

	local scoringZone = createPart(parent, "Stage6ScoringZone", BasketballConfig.Scoring.ZoneSize, HOOP_CENTER + BasketballConfig.Scoring.ZoneOffset, Color3.fromRGB(80, 255, 148), Enum.Material.ForceField, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 1,
	})

	return scoringZone
end

local function createStationBeacon(parent, stationConfig)
	createPart(parent, stationConfig.name .. "Halo", Vector3.new(stationConfig.size.X + 2, 0.12, stationConfig.size.Z + 2), stationConfig.position - Vector3.new(0, 0.09, 0), stationConfig.color, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.45,
	})
	createPart(parent, stationConfig.name .. "BackMarker", Vector3.new(stationConfig.size.X + 4, 0.2, 0.55), stationConfig.position + Vector3.new(0, 0.15, stationConfig.size.Z / 2), COURT_COLORS.Line, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
end

local function createStations(parent)
	local stations = {}

	for _, stationConfig in ipairs(SHOT_STATIONS) do
		local station = createPart(parent, stationConfig.name, stationConfig.size, stationConfig.position, stationConfig.color, Enum.Material.Neon, {
			CanCollide = false,
		})
		createSurfaceLabel(station, stationConfig.label, COLORS.Dark, Enum.NormalId.Top, 30)
		station:SetAttribute("ShotIndex", stationConfig.index)
		createStationBeacon(parent, stationConfig)

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "StartBasketballShotPrompt"
		prompt.ActionText = "Shoot"
		prompt.ObjectText = stationConfig.label:gsub("\n", " ")
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.12
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = station

		local shooterCFrame = createFacingCFrame(stationConfig.position + Vector3.new(0, 3.15, 0), SHOT_TARGET)
		local cameraPosition = stationConfig.position + Vector3.new(20, 9.8, 19)
		local cameraFocus = (stationConfig.position + HOOP_CENTER) / 2 + Vector3.new(0, 3.2, 0)

		table.insert(stations, {
			index = stationConfig.index,
			part = station,
			prompt = prompt,
			cframe = shooterCFrame,
			cameraCFrame = CFrame.lookAt(cameraPosition, cameraFocus),
			shotStartPosition = (shooterCFrame * CFrame.new(0, BasketballConfig.Ball.HoldHeight, -BasketballConfig.Ball.HoldForwardOffset)).Position,
		})
	end

	return stations
end

local function createGate(parent)
	createPart(parent, "Stage6ChallengeGateFrame", Vector3.new(30, 10, 2), Vector3.new(0, PLATFORM_TOP_Y + 5, 1438), COURT_COLORS.Basalt, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})

	local doorVisual = createPart(parent, "Stage6BasketballDoorVisual", Vector3.new(24, 7, 1), Vector3.new(0, PLATFORM_TOP_Y + 4.2, 1438), COURT_COLORS.Gate, Enum.Material.ForceField, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.12,
	})
	createSurfaceLabel(doorVisual, "LOCKED\nMAKE SHOTS", COLORS.Dark, Enum.NormalId.Front, 28)
	createSurfaceLabel(doorVisual, "LOCKED\nMAKE SHOTS", COLORS.Dark, Enum.NormalId.Back, 28)

	local gateBlocker = createPart(parent, "Stage6BasketballGateBlocker", Vector3.new(24, 8, 6), Vector3.new(0, PLATFORM_TOP_Y + 4.2, 1438), COLORS.Dark, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 1,
	})

	return {
		doorVisual = doorVisual,
		gateBlocker = gateBlocker,
	}
end

local function createCheckpoint(parent)
	local platform = createPart(parent, "Stage6CheckpointPlatform", Vector3.new(32, 1, 22), Vector3.new(0, PLATFORM_TOP_Y - 0.5, 1468), COURT_COLORS.BasaltLight, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "CP 6", COLORS.Dark, Enum.NormalId.Top, 30)

	local base = createPart(parent, "Stage6CheckpointBase", Vector3.new(22, 0.16, 11), Vector3.new(0, PLATFORM_TOP_Y + 0.12, 1468), COLORS.CheckpointAccent, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.28,
	})

	local pad = createPart(parent, "Stage6Checkpoint", Vector3.new(18, 0.35, 8), Vector3.new(0, PLATFORM_TOP_Y + 0.32, 1468), COLORS.Checkpoint, Enum.Material.Neon, {
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
		respawnPosition = COURT.CheckpointPosition,
		respawnLookAt = COURT.Stage7LookAt,
		respawnCFrame = createFacingCFrame(COURT.CheckpointPosition, COURT.Stage7LookAt),
	}
end

local function createStageSevenPlaceholder(parent)
	createPart(parent, "Stage6ToStage7Connector", Vector3.new(18, 1, 24), Vector3.new(0, PLATFORM_TOP_Y - 0.5, 1490), COURT_COLORS.BasaltLight, Enum.Material.Concrete)

	local platform = createPart(parent, "Stage7PlaceholderPlatform", Vector3.new(36, 1, 24), Vector3.new(0, PLATFORM_TOP_Y - 0.5, 1512), COLORS.Moving, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 7", COLORS.Dark, Enum.NormalId.Top, 30)

	createPart(parent, "Stage7GateLeftPost", Vector3.new(2, 12, 2), Vector3.new(-13, PLATFORM_TOP_Y + 5.8, 1520), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage7GateRightPost", Vector3.new(2, 12, 2), Vector3.new(13, PLATFORM_TOP_Y + 5.8, 1520), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage7GateTop", Vector3.new(28, 2, 2), Vector3.new(0, PLATFORM_TOP_Y + 11.8, 1520), COLORS.Dark, Enum.Material.SmoothPlastic)

	local door = createPart(parent, "Stage7ComingNextDoor", Vector3.new(23, 8, 1), Vector3.new(0, PLATFORM_TOP_Y + 4.8, 1521), COLORS.Start, Enum.Material.ForceField, {
		Transparency = 0.2,
	})
	createSurfaceLabel(door, "STAGE 7\nCAT AND MOUSE\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Front, 26)
	createSurfaceLabel(door, "STAGE 7\nCAT AND MOUSE\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Back, 26)
end

function Stage6BasketballBuilder.build(parent)
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "Stage6BasketballChallenge"
	stageFolder.Parent = parent

	createElevatedPlatform(stageFolder)
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
			cframe = createFacingCFrame(COURT.EntrancePosition, COURT.EntranceLookAt),
		},
		checkpoint = checkpoint,
		stations = stations,
		scoringZone = scoringZone,
		hoopCenter = HOOP_CENTER,
		shotTarget = SHOT_TARGET,
		doorVisual = gate.doorVisual,
		gateBlocker = gate.gateBlocker,
		deniedCFrame = createFacingCFrame(Vector3.new(0, COURT.EntrancePosition.Y, 1420), SHOT_TARGET),
		ballsFolder = ballsFolder,
	}
end

return Stage6BasketballBuilder
