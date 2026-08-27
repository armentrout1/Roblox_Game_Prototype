local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CatMouseConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CatMouseConfig"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local Stage7CatMouseBuilder = {}

local COLORS = ObbyConfig.Colors
local WORLD_ID = WorldConfig.CurrentWorldId
local STAGE_7_ID = WorldConfig.Worlds[WORLD_ID].stages[7].id
local STAGE = CatMouseConfig.Stage
local FLOOR_TOP_Y = STAGE.FloorCenter.Y + (STAGE.FloorSize.Y / 2)

local STAGE_COLORS = {
	Floor = Color3.fromRGB(111, 77, 63),
	FloorAccent = Color3.fromRGB(154, 118, 82),
	Wall = Color3.fromRGB(62, 52, 54),
	Cheese = Color3.fromRGB(255, 213, 71),
	CheeseDark = Color3.fromRGB(217, 156, 42),
	Crumb = Color3.fromRGB(255, 235, 148),
	BoxRed = Color3.fromRGB(211, 68, 67),
	BoxBlue = Color3.fromRGB(66, 123, 210),
	BoxGreen = Color3.fromRGB(65, 157, 95),
	Pipe = Color3.fromRGB(86, 92, 102),
	Hole = Color3.fromRGB(10, 10, 14),
	Mouse = Color3.fromRGB(174, 187, 199),
	CatFur = Color3.fromRGB(248, 167, 65),
	CatStripe = Color3.fromRGB(107, 70, 42),
	CatBelly = Color3.fromRGB(255, 228, 178),
	CatEye = Color3.fromRGB(82, 255, 134),
}

local ROUTE_ARROWS = {
	{ position = Vector3.new(0, FLOOR_TOP_Y + 0.1, 1546), yaw = 0 },
	{ position = Vector3.new(-17, FLOOR_TOP_Y + 0.1, 1588), yaw = -28 },
	{ position = Vector3.new(18, FLOOR_TOP_Y + 0.1, 1646), yaw = 28 },
	{ position = Vector3.new(-18, FLOOR_TOP_Y + 0.1, 1708), yaw = -28 },
	{ position = Vector3.new(16, FLOOR_TOP_Y + 0.1, 1762), yaw = 28 },
	{ position = Vector3.new(0, FLOOR_TOP_Y + 0.1, 1804), yaw = 0 },
}

local CHEESE_BLOCKS = {
	{ name = "Stage7CheeseRampA", position = Vector3.new(-15, FLOOR_TOP_Y + 0.95, 1574), size = Vector3.new(18, 1.8, 16), yaw = -12 },
	{ name = "Stage7CheeseHopA", position = Vector3.new(10, FLOOR_TOP_Y + 1.2, 1606), size = Vector3.new(14, 2.3, 14), yaw = 18 },
	{ name = "Stage7CheeseRampB", position = Vector3.new(18, FLOOR_TOP_Y + 0.9, 1664), size = Vector3.new(18, 1.6, 15), yaw = 13 },
	{ name = "Stage7CheeseHopB", position = Vector3.new(-12, FLOOR_TOP_Y + 1.15, 1716), size = Vector3.new(16, 2.2, 13), yaw = -17 },
	{ name = "Stage7CheeseBridge", position = Vector3.new(0, FLOOR_TOP_Y + 1.05, 1772), size = Vector3.new(24, 2, 12), yaw = 0 },
}

local GIANT_BOXES = {
	{ name = "Stage7CerealBoxA", position = Vector3.new(26, FLOOR_TOP_Y + 10, 1578), size = Vector3.new(12, 20, 22), color = STAGE_COLORS.BoxRed, yaw = -5 },
	{ name = "Stage7SnackBoxA", position = Vector3.new(-27, FLOOR_TOP_Y + 9, 1636), size = Vector3.new(12, 18, 26), color = STAGE_COLORS.BoxBlue, yaw = 8 },
	{ name = "Stage7CerealBoxB", position = Vector3.new(27, FLOOR_TOP_Y + 10, 1730), size = Vector3.new(13, 20, 24), color = STAGE_COLORS.BoxGreen, yaw = -9 },
}

local TABLE_LEGS = {
	Vector3.new(-28, FLOOR_TOP_Y + 12, 1660),
	Vector3.new(28, FLOOR_TOP_Y + 12, 1660),
	Vector3.new(-28, FLOOR_TOP_Y + 12, 1750),
	Vector3.new(28, FLOOR_TOP_Y + 12, 1750),
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

local function markHazard(part, hazardType)
	part:SetAttribute("Hazard", true)
	part:SetAttribute("HazardType", hazardType)
	return part
end

local function createSurfaceLabel(parent, text, textColor, face, pixelsPerStud)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "SurfaceLabel"
	surfaceGui.Face = face or Enum.NormalId.Top
	surfaceGui.LightInfluence = 0
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = pixelsPerStud or 34
	surfaceGui.Parent = parent

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Size = UDim2.fromScale(1, 1)
	label.Text = text
	label.TextColor3 = textColor or COLORS.Dark
	label.TextScaled = true
	label.TextStrokeColor3 = COLORS.Dark
	label.TextStrokeTransparency = 0.45
	label.TextWrapped = true
	label.Parent = surfaceGui
end

local function createRouteArrow(parent, position, yawDegrees)
	local cframe = CFrame.new(position) * CFrame.Angles(0, math.rad(yawDegrees), 0)
	createPart(parent, "Stage7RouteArrowStem", Vector3.new(1.2, 0.14, 8), cframe, COLORS.Finish, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.05,
	})
	createPart(parent, "Stage7RouteArrowLeft", Vector3.new(0.9, 0.14, 3.5), cframe * CFrame.new(-1.25, 0, 3.1) * CFrame.Angles(0, math.rad(-35), 0), COLORS.Finish, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.05,
	})
	createPart(parent, "Stage7RouteArrowRight", Vector3.new(0.9, 0.14, 3.5), cframe * CFrame.new(1.25, 0, 3.1) * CFrame.Angles(0, math.rad(35), 0), COLORS.Finish, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.05,
	})
end

local function createCheeseBlock(parent, config)
	local cframe = CFrame.new(config.position) * CFrame.Angles(0, math.rad(config.yaw or 0), 0)
	local block = createPart(parent, config.name, config.size, cframe, STAGE_COLORS.Cheese, Enum.Material.SmoothPlastic)

	for index = 1, 4 do
		local x = ((index % 2 == 0) and 0.25 or -0.25) * config.size.X
		local z = (((index - 1) % 2 == 0) and 0.22 or -0.22) * config.size.Z
		createPart(parent, config.name .. "Hole" .. tostring(index), Vector3.new(1.8, 0.12, 1.8), cframe * CFrame.new(x, (config.size.Y / 2) + 0.08, z), STAGE_COLORS.CheeseDark, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
			Shape = Enum.PartType.Ball,
		})
	end

	return block
end

local function createOversizedBox(parent, config)
	local cframe = CFrame.new(config.position) * CFrame.Angles(0, math.rad(config.yaw or 0), 0)
	local box = createPart(parent, config.name, config.size, cframe, config.color, Enum.Material.SmoothPlastic)
	createPart(parent, config.name .. "Stripe", Vector3.new(config.size.X + 0.12, 1.5, 0.22), cframe * CFrame.new(0, config.size.Y * 0.22, -(config.size.Z / 2) - 0.08), COLORS.White, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, config.name .. "TopFlap", Vector3.new(config.size.X + 1, 0.8, config.size.Z + 1), cframe * CFrame.new(0, (config.size.Y / 2) + 0.35, 0), STAGE_COLORS.FloorAccent, Enum.Material.SmoothPlastic, {
		CanTouch = false,
	})
	return box
end

local function createStageEntrance(parent)
	createPart(parent, "Stage7ConnectorFromCp6", Vector3.new(18, 1, 30), Vector3.new(0, FLOOR_TOP_Y - 0.5, 1494), STAGE_COLORS.FloorAccent, Enum.Material.Concrete)

	local entrance = createPart(parent, "Stage7EntrancePlatform", Vector3.new(40, 1, 26), Vector3.new(0, FLOOR_TOP_Y - 0.5, 1516), STAGE_COLORS.Mouse, Enum.Material.SmoothPlastic)
	createSurfaceLabel(entrance, "STAGE 7\nCAT AND MOUSE", COLORS.Dark, Enum.NormalId.Top, 30)

	local attemptStart = createPart(parent, "Stage7AttemptStart", Vector3.new(20, 0.34, 8), Vector3.new(0, FLOOR_TOP_Y + 0.18, 1530), COLORS.Start, Enum.Material.Neon, {
		CanCollide = false,
	})
	createSurfaceLabel(attemptStart, "RUN", COLORS.Dark, Enum.NormalId.Top, 30)

	for _, side in ipairs({ -1, 1 }) do
		createPart(parent, "Stage7EntranceRail" .. tostring(side), Vector3.new(1.2, 3, 28), Vector3.new(side * 20.5, FLOOR_TOP_Y + 1.5, 1516), STAGE_COLORS.Wall, Enum.Material.SmoothPlastic, {
			CanTouch = false,
		})
	end

	return attemptStart
end

local function createArena(parent)
	createPart(parent, "Stage7KitchenFloor", STAGE.FloorSize, STAGE.FloorCenter, STAGE_COLORS.Floor, Enum.Material.WoodPlanks)

	for _, x in ipairs({ -35.5, 35.5 }) do
		createPart(parent, "Stage7SideWall", Vector3.new(2, 9, STAGE.FloorSize.Z), Vector3.new(x, FLOOR_TOP_Y + 4.5, STAGE.FloorCenter.Z), STAGE_COLORS.Wall, Enum.Material.Wood)
	end

	for _, arrow in ipairs(ROUTE_ARROWS) do
		createRouteArrow(parent, arrow.position, arrow.yaw)
	end

	for _, box in ipairs(GIANT_BOXES) do
		createOversizedBox(parent, box)
	end

	for index, position in ipairs(TABLE_LEGS) do
		createPart(parent, "Stage7TableLeg" .. tostring(index), Vector3.new(7, 24, 7), position, Color3.fromRGB(94, 62, 39), Enum.Material.Wood, {
			CanTouch = false,
			Shape = Enum.PartType.Cylinder,
		})
	end

	createPart(parent, "Stage7TableTop", Vector3.new(70, 2.5, 112), Vector3.new(0, FLOOR_TOP_Y + 25.5, 1705), Color3.fromRGB(112, 73, 45), Enum.Material.Wood, {
		CanTouch = false,
	})

	for _, cheese in ipairs(CHEESE_BLOCKS) do
		createCheeseBlock(parent, cheese)
	end

	createPart(parent, "Stage7PaperTube", Vector3.new(20, 5, 28), CFrame.new(0, FLOOR_TOP_Y + 2.6, 1688) * CFrame.Angles(0, math.rad(90), math.rad(90)), STAGE_COLORS.Pipe, Enum.Material.Metal, {
		CanTouch = false,
		Shape = Enum.PartType.Cylinder,
	})
	createPart(parent, "Stage7TubeLanding", Vector3.new(15, 0.2, 24), Vector3.new(0, FLOOR_TOP_Y + 5.18, 1688), COLORS.White, Enum.Material.SmoothPlastic, {
		CanTouch = false,
		Transparency = 1,
	})

	for index, crumb in ipairs({
		Vector3.new(-8, FLOOR_TOP_Y + 0.35, 1558),
		Vector3.new(8, FLOOR_TOP_Y + 0.35, 1594),
		Vector3.new(-6, FLOOR_TOP_Y + 0.35, 1652),
		Vector3.new(12, FLOOR_TOP_Y + 0.35, 1728),
		Vector3.new(-7, FLOOR_TOP_Y + 0.35, 1790),
	}) do
		createPart(parent, "Stage7CheeseCrumb" .. tostring(index), Vector3.new(2.8, 0.45, 2.8), crumb, STAGE_COLORS.Crumb, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
			Shape = Enum.PartType.Ball,
		})
	end
end

local function createEscape(parent)
	local wallZ = 1820
	createPart(parent, "Stage7MouseHoleWallLeft", Vector3.new(25, 18, 2), Vector3.new(-22.5, FLOOR_TOP_Y + 9, wallZ), STAGE_COLORS.Wall, Enum.Material.Wood)
	createPart(parent, "Stage7MouseHoleWallRight", Vector3.new(25, 18, 2), Vector3.new(22.5, FLOOR_TOP_Y + 9, wallZ), STAGE_COLORS.Wall, Enum.Material.Wood)
	createPart(parent, "Stage7MouseHoleWallTop", Vector3.new(22, 9, 2), Vector3.new(0, FLOOR_TOP_Y + 13.5, wallZ), STAGE_COLORS.Wall, Enum.Material.Wood)
	createPart(parent, "Stage7MouseHoleBack", Vector3.new(21, 9, 1), Vector3.new(0, FLOOR_TOP_Y + 4.5, wallZ + 1.2), STAGE_COLORS.Hole, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})

	local tunnel = createPart(parent, "Stage7MouseTunnel", Vector3.new(18, 8, 24), Vector3.new(0, FLOOR_TOP_Y + 4, 1832), STAGE_COLORS.Hole, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.16,
	})
	createSurfaceLabel(tunnel, "ESCAPE", COLORS.White, Enum.NormalId.Front, 24)

	local escapeZone = createPart(parent, "Stage7EscapeZone", Vector3.new(18, 10, 16), Vector3.new(0, FLOOR_TOP_Y + 5, 1827), COLORS.Finish, Enum.Material.ForceField, {
		CanCollide = false,
		Transparency = 1,
	})

	return escapeZone
end

local function createCheckpoint(parent)
	local platform = createPart(parent, "Stage7CheckpointPlatform", Vector3.new(34, 1, 22), Vector3.new(0, FLOOR_TOP_Y - 0.5, 1846), STAGE_COLORS.Mouse, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "CP 7", COLORS.Dark, Enum.NormalId.Top, 30)

	local base = createPart(parent, "Stage7CheckpointBase", Vector3.new(23, 0.16, 11), Vector3.new(0, FLOOR_TOP_Y + 0.12, 1846), COLORS.CheckpointAccent, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.28,
	})

	local pad = createPart(parent, "Stage7Checkpoint", Vector3.new(19, 0.35, 8), Vector3.new(0, FLOOR_TOP_Y + 0.32, 1846), COLORS.Checkpoint, Enum.Material.Neon, {
		CanCollide = false,
	})
	pad:SetAttribute("CheckpointIndex", 7)
	pad:SetAttribute("StageId", STAGE_7_ID)
	pad:SetAttribute("CompletesStage", true)
	pad:SetAttribute("RequiresCatMouseCompletion", true)

	return {
		id = "world_1_stage_7_checkpoint",
		index = 7,
		order = 7,
		stageId = STAGE_7_ID,
		completesStage = true,
		requiresCatMouseCompletion = true,
		part = pad,
		base = base,
		platform = platform,
		respawnPosition = STAGE.Cp7Position,
		respawnLookAt = STAGE.Stage8LookAt,
		respawnCFrame = createFacingCFrame(STAGE.Cp7Position, STAGE.Stage8LookAt),
	}
end

local function createStageEightPlaceholder(parent)
	createPart(parent, "Stage7ToStage8Connector", Vector3.new(18, 1, 24), Vector3.new(0, FLOOR_TOP_Y - 0.5, 1868), STAGE_COLORS.FloorAccent, Enum.Material.Concrete)

	local platform = createPart(parent, "Stage8PlaceholderPlatform", Vector3.new(40, 1, 26), Vector3.new(0, FLOOR_TOP_Y - 0.5, 1888), COLORS.Moving, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 8\nROLLER COASTER LEAN", COLORS.Dark, Enum.NormalId.Top, 26)

	local gate = createPart(parent, "Stage8ComingNextSign", Vector3.new(28, 8, 1), Vector3.new(0, FLOOR_TOP_Y + 5, 1902), COLORS.Finish, Enum.Material.ForceField, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.15,
	})
	createSurfaceLabel(gate, "STAGE 8\nROLLER COASTER LEAN\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Front, 24)
	createSurfaceLabel(gate, "STAGE 8\nROLLER COASTER LEAN\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Back, 24)
end

local function setTemplateTransparency(part, visibleTransparency)
	part.Transparency = 1
	part:SetAttribute("VisibleTransparency", visibleTransparency or 0)
	part.CanCollide = false
	part.CanTouch = false
end

local function createCatPart(model, name, size, cframe, color, material, properties, visibleTransparency)
	local part = createPart(model, name, size, cframe, color, material, properties)
	setTemplateTransparency(part, visibleTransparency)
	return part
end

local function createCatTemplate(parent)
	local model = Instance.new("Model")
	model.Name = CatMouseConfig.Cat.TemplateName
	model.Parent = parent

	local root = createCatPart(model, "CatRoot", Vector3.new(1, 1, 1), CFrame.new(0, -80, 0), STAGE_COLORS.CatFur, Enum.Material.SmoothPlastic, {
		CanQuery = false,
	}, 1)
	root:SetAttribute("IsCatRoot", true)
	model.PrimaryPart = root

	createCatPart(model, "CatBody", Vector3.new(17, 7.5, 23), root.CFrame * CFrame.new(0, 4.8, 0), STAGE_COLORS.CatFur, Enum.Material.SmoothPlastic, nil, 0)
	createCatPart(model, "CatBelly", Vector3.new(11, 5.5, 0.55), root.CFrame * CFrame.new(0, 4.4, -11.7), STAGE_COLORS.CatBelly, Enum.Material.SmoothPlastic, {
		CanQuery = false,
	}, 0)
	createCatPart(model, "CatHead", Vector3.new(13, 10, 10), root.CFrame * CFrame.new(0, 7.4, -14.6), STAGE_COLORS.CatFur, Enum.Material.SmoothPlastic, nil, 0)
	createCatPart(model, "CatLeftEar", Vector3.new(4, 5, 3), root.CFrame * CFrame.new(-4.3, 14, -16), STAGE_COLORS.CatFur, Enum.Material.SmoothPlastic, nil, 0)
	createCatPart(model, "CatRightEar", Vector3.new(4, 5, 3), root.CFrame * CFrame.new(4.3, 14, -16), STAGE_COLORS.CatFur, Enum.Material.SmoothPlastic, nil, 0)

	for _, x in ipairs({ -5.6, 5.6 }) do
		createCatPart(model, "CatFrontLeg", Vector3.new(3.4, 6, 3.4), root.CFrame * CFrame.new(x, 1.5, -7.2), STAGE_COLORS.CatFur, Enum.Material.SmoothPlastic, nil, 0)
		createCatPart(model, "CatBackLeg", Vector3.new(3.6, 6, 3.6), root.CFrame * CFrame.new(x, 1.5, 7.3), STAGE_COLORS.CatFur, Enum.Material.SmoothPlastic, nil, 0)
	end

	createCatPart(model, "CatTailBase", Vector3.new(3.2, 3.2, 16), root.CFrame * CFrame.new(0, 7.4, 14.8) * CFrame.Angles(math.rad(-20), 0, 0), STAGE_COLORS.CatFur, Enum.Material.SmoothPlastic, nil, 0)

	for _, stripeZ in ipairs({ -4, 1.6, 7 }) do
		createCatPart(model, "CatBodyStripe", Vector3.new(17.3, 0.45, 1.2), root.CFrame * CFrame.new(0, 8.75, stripeZ), STAGE_COLORS.CatStripe, Enum.Material.SmoothPlastic, {
			CanQuery = false,
		}, 0)
	end

	for _, x in ipairs({ -3.2, 3.2 }) do
		createCatPart(model, "CatEye", Vector3.new(2, 2, 0.35), root.CFrame * CFrame.new(x, 8.5, -19.75), STAGE_COLORS.CatEye, Enum.Material.Neon, {
			CanQuery = false,
		}, 0)
	end

	createCatPart(model, "CatNose", Vector3.new(1.7, 1.1, 0.35), root.CFrame * CFrame.new(0, 6.7, -19.9), Color3.fromRGB(255, 110, 146), Enum.Material.Neon, {
		CanQuery = false,
	}, 0)

	for _, y in ipairs({ 6.4, 7.1 }) do
		createCatPart(model, "CatLeftWhisker", Vector3.new(5.5, 0.22, 0.22), root.CFrame * CFrame.new(-5.8, y, -20.1) * CFrame.Angles(0, 0, math.rad(-10)), COLORS.White, Enum.Material.SmoothPlastic, {
			CanQuery = false,
		}, 0)
		createCatPart(model, "CatRightWhisker", Vector3.new(5.5, 0.22, 0.22), root.CFrame * CFrame.new(5.8, y, -20.1) * CFrame.Angles(0, 0, math.rad(10)), COLORS.White, Enum.Material.SmoothPlastic, {
			CanQuery = false,
		}, 0)
	end

	return model
end

local function createHazards(parent)
	local fallReset = createPart(parent, "Stage7FallReset", Vector3.new(98, 1, 374), Vector3.new(0, FLOOR_TOP_Y - 18, 1674), COLORS.Lava, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 1,
	})

	return { markHazard(fallReset, "Stage7Fall") }
end

function Stage7CatMouseBuilder.build(parent)
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "Stage7CatAndMouse"
	stageFolder.Parent = parent

	local attemptStart = createStageEntrance(stageFolder)
	createArena(stageFolder)
	local escapeZone = createEscape(stageFolder)
	local checkpoint = createCheckpoint(stageFolder)
	createStageEightPlaceholder(stageFolder)
	local hazards = createHazards(stageFolder)

	local catTemplate = createCatTemplate(stageFolder)

	local activeCatsFolder = Instance.new("Folder")
	activeCatsFolder.Name = CatMouseConfig.Cat.FolderName
	activeCatsFolder.Parent = stageFolder

	local effectsFolder = Instance.new("Folder")
	effectsFolder.Name = "Stage7CatMouseEffects"
	effectsFolder.Parent = stageFolder

	return {
		stageId = STAGE_7_ID,
		stageStart = {
			stageNumber = 7,
			stageId = STAGE_7_ID,
			cframe = createFacingCFrame(STAGE.StartPosition, STAGE.StartLookAt),
		},
		checkpoint = checkpoint,
		attemptStart = attemptStart,
		escapeZone = escapeZone,
		catTemplate = catTemplate,
		activeCatsFolder = activeCatsFolder,
		effectsFolder = effectsFolder,
		catSpawnCFrame = createFacingCFrame(CatMouseConfig.Cat.SpawnPosition, STAGE.StartPosition),
		retryCFrame = createFacingCFrame(STAGE.RetryPosition, STAGE.RetryLookAt),
		captureHoldCFrame = CFrame.new(STAGE.CaptureHoldPosition),
		bounds = CatMouseConfig.Bounds,
		hazards = hazards,
	}
end

return Stage7CatMouseBuilder
