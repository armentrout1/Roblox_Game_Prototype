local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local Stage6BasketballBuilder = require(script.Parent:WaitForChild("Stage6BasketballBuilder"))
local Stage7CatMouseBuilder = require(script.Parent:WaitForChild("Stage7CatMouseBuilder"))
local Stage3WallRunBuilder = require(script.Parent:WaitForChild("Stage3WallRunBuilder"))
local Stage4RcMazeBuilder = require(script.Parent:WaitForChild("Stage4RcMazeBuilder"))
local Stage5TsunamiBuilder = require(script.Parent:WaitForChild("Stage5TsunamiBuilder"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local CourseBuilder = {}

local COLORS = ObbyConfig.Colors
local WORLD_ID = WorldConfig.CurrentWorldId
local STAGE_1_ID = WorldConfig.Worlds[WORLD_ID].stages[1].id
local STAGE_2_ID = WorldConfig.Worlds[WORLD_ID].stages[2].id
local START_CHARACTER_POSITION = Vector3.new(0, 5.8, -5)
local START_SPAWN_LOCATION_POSITION = Vector3.new(0, 3, -5)
local START_PAD_POSITION = Vector3.new(0, 3.05, 8)
local STAGE_1_CHECKPOINT_RESPAWN_POSITION = Vector3.new(0, 10.2, 172)
local STAGE_2_START_POSITION = Vector3.new(0, 10.2, 195)
local STAGE_2_FIRST_TARGET_POSITION = Vector3.new(0, 10.2, 214)
local STAGE_2_CHECKPOINT_RESPAWN_POSITION = Vector3.new(0, 12, 352)
local STAGE_3_FIRST_TARGET_POSITION = Vector3.new(0, 12, 382)

local LAVA_FIELD = {
	size = Vector3.new(124, 0.6, 735),
	position = Vector3.new(0, 0.85, 292),
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

local BOULDER_TUNING = {
	visualHorizontalScale = 1.45,
	visualHeightScale = 1.75,
	earlyVisualHorizontalBonus = 1.12,
	midVisualHorizontalBonus = 1.06,
	lateVisualHorizontalBonus = 1,
	earlyLandingRatio = 0.84,
	midLandingRatio = 0.78,
	lateLandingRatio = 0.72,
}

local STAGE_1_ROCK_TEMPLATE_NAMES = {
	"Stage1RockTemplate",
	"stage1rocktemplate",
}

local STAGE_2_NOOB_TEMPLATE_NAMES = {
	"Stage2NoobTemplate",
	"stage2noobtemplate",
}

local NOOB_COLORS = {
	Yellow = Color3.fromRGB(255, 220, 64),
	SeaYellow = Color3.fromRGB(255, 207, 48),
	Blue = Color3.fromRGB(43, 104, 255),
	Green = Color3.fromRGB(75, 195, 72),
	Black = Color3.fromRGB(22, 22, 24),
	SkinShadow = Color3.fromRGB(224, 176, 45),
}

local STAGE_2_NOOB_SEA = {
	visualSize = Vector3.new(88, 0.35, 168),
	visualPosition = Vector3.new(0, 1.42, 279),
	hazardSize = Vector3.new(90, 2.1, 168),
	hazardPosition = Vector3.new(0, 2.8, 279),
	columns = 7,
	rows = 10,
	startZ = 205,
	zSpacing = 15,
	xSpacing = 11,
}

local STAGE_2_SAFE_NOOBS = {
	{ kind = "head", name = "SeaSafeGiantHead01", position = Vector3.new(0, 6.1, 214), size = Vector3.new(18, 7.8, 18), landingRatio = 0.82, face = true },
	{ kind = "limb", name = "SeaSafeArmBridge01", position = Vector3.new(6, 10.1, 228), size = Vector3.new(22, 1.2, 7), color = NOOB_COLORS.Yellow, yaw = -16 },
	{ kind = "stack", name = "SeaSafeStack01", position = Vector3.new(-7, 7.8, 242), size = Vector3.new(12, 7.6, 10), yaw = 8 },
	{ kind = "head", name = "SeaSafeHeadHop01", position = Vector3.new(5, 7.5, 255), size = Vector3.new(11.5, 4.5, 11.5), landingRatio = 0.86 },
	{ kind = "limb", name = "SeaSafeArmBridge02", position = Vector3.new(-4, 10.3, 269), size = Vector3.new(23, 1.1, 5.6), color = NOOB_COLORS.Yellow, yaw = 18 },
	{ kind = "torso", name = "SeaSafeTorso01", position = Vector3.new(8, 10.0, 282), size = Vector3.new(15, 2.4, 11), yaw = -10 },
	{ kind = "head", name = "SeaSafeHeadHop02", position = Vector3.new(0, 8.4, 296), size = Vector3.new(10.5, 4.2, 10.5), landingRatio = 0.8 },
	{ kind = "hand", name = "SeaSafeHand01", position = Vector3.new(-9, 10.1, 309), size = Vector3.new(10, 2.2, 8.5), landingRatio = 0.9 },
	{ kind = "limb", name = "SeaSafeLegBeam01", position = Vector3.new(-1, 10.7, 322), size = Vector3.new(5.5, 1.1, 24), color = NOOB_COLORS.Green, yaw = 10 },
	{ kind = "head", name = "SeaSafeHeadHop03", position = Vector3.new(8, 9.2, 334), size = Vector3.new(9.4, 3.8, 9.4), landingRatio = 0.78 },
	{ kind = "stack", name = "SeaSafeStack02", position = Vector3.new(0, 8.8, 345), size = Vector3.new(13.5, 7.2, 9.5), yaw = -8 },
}

local function createFacingCFrame(position, lookAtPosition)
	local flatLookAt = Vector3.new(lookAtPosition.X, position.Y, lookAtPosition.Z)
	if (flatLookAt - position).Magnitude < 0.01 then
		flatLookAt = position + Vector3.new(0, 0, 1)
	end

	return CFrame.lookAt(position, flatLookAt)
end

local function getBoulderHorizontalBonus(index)
	if index <= 4 then
		return BOULDER_TUNING.earlyVisualHorizontalBonus
	elseif index <= 8 then
		return BOULDER_TUNING.midVisualHorizontalBonus
	end

	return BOULDER_TUNING.lateVisualHorizontalBonus
end

local function getBoulderVisualSize(config, index)
	local horizontalBonus = getBoulderHorizontalBonus(index)
	return Vector3.new(
		config.size.X * BOULDER_TUNING.visualHorizontalScale * horizontalBonus,
		config.size.Y * BOULDER_TUNING.visualHeightScale,
		config.size.Z * BOULDER_TUNING.visualHorizontalScale * horizontalBonus
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

local function markHazard(part, hazardType)
	part:SetAttribute("Hazard", true)
	part:SetAttribute("HazardType", hazardType)
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

local function createInvisibleLanding(parent, name, position, visualSize, landingRatio)
	local topY = position.Y + (visualSize.Y / 2)
	return createPart(parent, name, Vector3.new(visualSize.X * landingRatio, 0.22, visualSize.Z * landingRatio), Vector3.new(position.X, topY + 0.08, position.Z), COLORS.White, Enum.Material.SmoothPlastic, {
		CanTouch = false,
		Transparency = 1,
	})
end

local function createNoobFace(parent, name, position, size)
	local faceZ = position.Z - (size.Z / 2) - 0.08
	local eyeY = position.Y + (size.Y * 0.18)
	local mouthY = position.Y - (size.Y * 0.14)

	for _, eyeX in ipairs({ -size.X * 0.18, size.X * 0.18 }) do
		createPart(parent, name .. "Eye", Vector3.new(size.X * 0.09, size.Y * 0.12, 0.14), Vector3.new(position.X + eyeX, eyeY, faceZ), NOOB_COLORS.Black, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
		})
	end

	createPart(parent, name .. "Smile", Vector3.new(size.X * 0.32, size.Y * 0.08, 0.14), Vector3.new(position.X, mouthY, faceZ), NOOB_COLORS.Black, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
end

local createTemplateNoob

local function createNoobHeadObstacle(parent, index, obstacle)
	local head = createPart(parent, obstacle.name, obstacle.size, obstacle.position, NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Shape = Enum.PartType.Ball,
	})

	createInvisibleLanding(parent, obstacle.name .. "Landing", obstacle.position, obstacle.size, obstacle.landingRatio or 0.78)

	if obstacle.face then
		createNoobFace(parent, obstacle.name, obstacle.position, obstacle.size)
	end

	if index == 1 or index == 6 or index == 10 then
		local topY = obstacle.position.Y + (obstacle.size.Y / 2)
		createPathArrow(parent, Vector3.new(obstacle.position.X, topY + 0.24, obstacle.position.Z + 0.2), COLORS.Start)
	end

	return head
end

local function createNoobHandPlatform(parent, index, obstacle)
	local hand = createPart(parent, obstacle.name, obstacle.size, obstacle.position, NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Shape = Enum.PartType.Ball,
	})

	createInvisibleLanding(parent, obstacle.name .. "Landing", obstacle.position, obstacle.size, obstacle.landingRatio or 0.86)

	local topY = obstacle.position.Y + (obstacle.size.Y / 2)
	if index == 8 then
		createPathArrow(parent, Vector3.new(obstacle.position.X, topY + 0.24, obstacle.position.Z + 0.2), COLORS.Start)
	end

	return hand
end

local function createNoobLimbObstacle(parent, obstacle)
	local yaw = math.rad(obstacle.yaw or 0)
	return createPart(parent, obstacle.name, obstacle.size, CFrame.new(obstacle.position) * CFrame.Angles(0, yaw, 0), obstacle.color or NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic)
end

local function createNoobTorsoObstacle(parent, obstacle)
	local yaw = math.rad(obstacle.yaw or 0)
	local torso = createPart(parent, obstacle.name, obstacle.size, CFrame.new(obstacle.position) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Blue, Enum.Material.SmoothPlastic)

	local armOffset = (obstacle.size.X / 2) + 1.1
	createPart(parent, obstacle.name .. "LeftArm", Vector3.new(1.4, 1.2, obstacle.size.Z + 1.5), CFrame.new(obstacle.position + Vector3.new(-armOffset, 0, 0)) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, obstacle.name .. "RightArm", Vector3.new(1.4, 1.2, obstacle.size.Z + 1.5), CFrame.new(obstacle.position + Vector3.new(armOffset, 0, 0)) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})

	return torso
end

local function createNoobStackObstacle(parent, index, obstacle)
	local yaw = math.rad(obstacle.yaw or 0)
	local torsoPosition = obstacle.position + Vector3.new(0, -0.4, 0)
	local torsoSize = Vector3.new(obstacle.size.X, obstacle.size.Y * 0.44, obstacle.size.Z)
	local headSize = Vector3.new(obstacle.size.X * 0.72, obstacle.size.Y * 0.34, obstacle.size.Z * 0.72)
	local headPosition = obstacle.position + Vector3.new(0, obstacle.size.Y * 0.28, 0)

	createPart(parent, obstacle.name .. "TallTorso", torsoSize, CFrame.new(torsoPosition) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Blue, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, obstacle.name .. "Head", headSize, headPosition, NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Shape = Enum.PartType.Ball,
	})

	local armOffset = (torsoSize.X / 2) + 0.8
	createPart(parent, obstacle.name .. "LeftArm", Vector3.new(1.5, 1.2, torsoSize.Z + 1.5), CFrame.new(torsoPosition + Vector3.new(-armOffset, 0.2, 0)) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, obstacle.name .. "RightArm", Vector3.new(1.5, 1.2, torsoSize.Z + 1.5), CFrame.new(torsoPosition + Vector3.new(armOffset, 0.2, 0)) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
	})

	createInvisibleLanding(parent, obstacle.name .. "Landing", headPosition, headSize, 1.05)

	if index == 3 or index == 11 then
		local topY = headPosition.Y + (headSize.Y / 2)
		createPathArrow(parent, Vector3.new(obstacle.position.X, topY + 0.24, obstacle.position.Z + 0.2), COLORS.Start)
	end
end

local function createTemplateSafeNoob(parent, template, index, obstacle)
	local yaw = math.rad(obstacle.yaw or (((index * 23) % 50) - 25))
	local roll = math.rad(obstacle.kind == "limb" and 86 or 0)
	local pitch = math.rad(obstacle.kind == "hand" and -8 or 0)
	local noobCFrame = CFrame.new(obstacle.position) * CFrame.Angles(pitch, yaw, roll)

	createTemplateNoob(parent, template, obstacle.name, obstacle.size, noobCFrame)
	createInvisibleLanding(parent, obstacle.name .. "Landing", obstacle.position, obstacle.size, obstacle.landingRatio or 0.82)

	if index == 1 or index == 3 or index == 6 or index == 8 or index == 10 or index == 11 then
		local topY = obstacle.position.Y + (obstacle.size.Y / 2)
		createPathArrow(parent, Vector3.new(obstacle.position.X, topY + 0.24, obstacle.position.Z + 0.2), COLORS.Start)
	end
end

local function createNoobSeaVisualPiece(parent, row, column, template)
	local centerColumn = (STAGE_2_NOOB_SEA.columns + 1) / 2
	local x = (column - centerColumn) * STAGE_2_NOOB_SEA.xSpacing
	local z = STAGE_2_NOOB_SEA.startZ + ((row - 1) * STAGE_2_NOOB_SEA.zSpacing)
	local offset = ((row + column) % 2 == 0) and 3.2 or -3.2
	local variant = (row * 5 + column * 3) % 5
	local yaw = math.rad(((row * 17 + column * 29) % 50) - 25)
	local position = Vector3.new(x + offset, 2.25 + ((row + column) % 3) * 0.12, z)

	if template then
		local roll = math.rad(((row + column) % 2 == 0) and 88 or -88)
		local pitch = math.rad(((row * 7 + column * 11) % 28) - 14)
		local targetSize = Vector3.new(7.2 + variant * 0.35, 5.8, 7.2 + variant * 0.35)
		createTemplateNoob(parent, template, string.format("NoobSeaTemplate%02d%02d", row, column), targetSize, CFrame.new(position) * CFrame.Angles(pitch, yaw, roll))
		return
	end

	if variant == 0 then
		createPart(parent, string.format("NoobSeaHead%02d%02d", row, column), Vector3.new(7.5, 2.9, 7.5), position, NOOB_COLORS.SeaYellow, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
			Shape = Enum.PartType.Ball,
		})
	elseif variant == 1 then
		createPart(parent, string.format("NoobSeaTorso%02d%02d", row, column), Vector3.new(8.5, 2.2, 5.5), CFrame.new(position) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Blue, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
		})
	elseif variant == 2 then
		createPart(parent, string.format("NoobSeaArm%02d%02d", row, column), Vector3.new(10, 1.1, 3.2), CFrame.new(position) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
		})
	elseif variant == 3 then
		createPart(parent, string.format("NoobSeaLeg%02d%02d", row, column), Vector3.new(4.2, 1.1, 9), CFrame.new(position) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Green, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
		})
	else
		createPart(parent, string.format("NoobSeaMiniBody%02d%02d", row, column), Vector3.new(5.5, 1.6, 4.4), CFrame.new(position + Vector3.new(0, -0.2, 0)) * CFrame.Angles(0, yaw, 0), NOOB_COLORS.Blue, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
		})
		createPart(parent, string.format("NoobSeaMiniHead%02d%02d", row, column), Vector3.new(3.8, 1.6, 3.8), position + Vector3.new(0, 1.1, 0), NOOB_COLORS.SeaYellow, Enum.Material.SmoothPlastic, {
			CanCollide = false,
			CanTouch = false,
			Shape = Enum.PartType.Ball,
		})
	end
end

local function createStageTwoNoobSea(parent, template)
	local seaFolder = Instance.new("Folder")
	seaFolder.Name = "Stage2NoobSeaVisuals"
	seaFolder.Parent = parent

	createPart(seaFolder, "Stage2NoobSeaSurface", STAGE_2_NOOB_SEA.visualSize, STAGE_2_NOOB_SEA.visualPosition, NOOB_COLORS.SkinShadow, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.08,
	})

	for row = 1, STAGE_2_NOOB_SEA.rows do
		for column = 1, STAGE_2_NOOB_SEA.columns do
			createNoobSeaVisualPiece(seaFolder, row, column, template)
		end
	end

	local hazard = createPart(parent, "Stage2NoobSeaHazard", STAGE_2_NOOB_SEA.hazardSize, STAGE_2_NOOB_SEA.hazardPosition, NOOB_COLORS.SeaYellow, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 1,
	})

	return markHazard(hazard, "NoobSea")
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
	table.insert(hazards, markHazard(lava, "Lava"))

	for index, stream in ipairs({
		{ x = -24, z = 55, width = 7, length = 76 },
		{ x = 26, z = 113, width = 6, length = 86 },
		{ x = 0, z = 151, width = 8, length = 48 },
		{ x = -30, z = 245, width = 7, length = 82 },
		{ x = 28, z = 322, width = 8, length = 92 },
		{ x = -33, z = 454, width = 7, length = 110 },
		{ x = 31, z = 557, width = 8, length = 118 },
	}) do
		createPart(parent, string.format("LavaGlowStream%02d", index), Vector3.new(stream.width, 0.08, stream.length), Vector3.new(stream.x, 1.2, stream.z), Color3.fromRGB(255, 143, 34), Enum.Material.Neon, {
			CanCollide = false,
			CanTouch = false,
			Transparency = 0.25,
		})
	end

	local voidKill = createPart(parent, "FallReset", Vector3.new(150, 0.5, 790), Vector3.new(0, -6, 292), COLORS.Lava, Enum.Material.SmoothPlastic, {
		CanCollide = false,
		Transparency = 1,
	})
	table.insert(hazards, markHazard(voidKill, "Fall"))

	return hazards
end

local function findStageOneRockTemplate()
	for _, name in ipairs(STAGE_1_ROCK_TEMPLATE_NAMES) do
		local template = workspace:FindFirstChild(name)
		if template and template:IsA("Model") then
			return template
		end
	end

	return nil
end

local function prepareRockClone(clone)
	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
end

local function getModelSize(model)
	local _, size = model:GetBoundingBox()
	return size
end

local function scaleRockClone(clone, targetSize)
	local sourceSize = getModelSize(clone)
	local maxSourceAxis = math.max(sourceSize.X, sourceSize.Z, 0.01)
	local maxTargetAxis = math.max(targetSize.X, targetSize.Z)
	local scale = math.max(maxTargetAxis / maxSourceAxis, 0.01)

	clone:ScaleTo(scale)
end

local function hideRockTemplate(template)
	for _, descendant in ipairs(template:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
end

local function findStageTwoNoobTemplate()
	for _, name in ipairs(STAGE_2_NOOB_TEMPLATE_NAMES) do
		local template = workspace:FindFirstChild(name)
		if template and template:IsA("Model") then
			return template
		end
	end

	return nil
end

local function prepareNoobClone(clone)
	for _, descendant in ipairs(clone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
end

local function scaleNoobClone(clone, targetSize)
	local sourceSize = getModelSize(clone)
	local sourceAxis = math.max(sourceSize.X, sourceSize.Y, sourceSize.Z, 0.01)
	local targetAxis = math.max(targetSize.X, targetSize.Y, targetSize.Z)
	local scale = math.max(targetAxis / sourceAxis, 0.01)

	clone:ScaleTo(scale)
end

local function hideNoobTemplate(template)
	for _, descendant in ipairs(template:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Transparency = 1
			descendant.CanCollide = false
			descendant.CanTouch = false
		end
	end
end

createTemplateNoob = function(parent, template, name, targetSize, targetCFrame)
	local clone = template:Clone()
	clone.Name = name
	clone.Parent = parent
	prepareNoobClone(clone)
	scaleNoobClone(clone, targetSize)
	clone:PivotTo(targetCFrame)

	return clone
end

local function createTemplateBoulder(parent, template, index, visualSize, boulderCFrame)
	local clone = template:Clone()
	clone.Name = string.format("Stage1Boulder%02d", index)
	clone.Parent = parent
	prepareRockClone(clone)
	scaleRockClone(clone, visualSize)
	clone:PivotTo(boulderCFrame)

	return clone
end

local function createFallbackBoulder(parent, index, visualSize, boulderCFrame)
	return createPart(parent, string.format("Stage1Boulder%02d", index), visualSize, boulderCFrame, Color3.fromRGB(60, 64, 68), Enum.Material.Slate, {
		CanCollide = false,
		CanTouch = false,
		Shape = Enum.PartType.Ball,
	})
end

local function createBoulder(parent, index, config, template)
	local rotation = config.rotation or Vector3.zero
	local visualSize = getBoulderVisualSize(config, index)
	local boulderCFrame = CFrame.new(config.position) * CFrame.Angles(math.rad(rotation.X), math.rad(rotation.Y), math.rad(rotation.Z))

	local boulder = if template then createTemplateBoulder(parent, template, index, visualSize, boulderCFrame) else createFallbackBoulder(parent, index, visualSize, boulderCFrame)

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
	local template = findStageOneRockTemplate()
	if template then
		hideRockTemplate(template)
	end

	for index, boulderConfig in ipairs(STAGE_1_BOULDERS) do
		createBoulder(parent, index, boulderConfig, template)
	end
end

local function createStageOneCheckpoint(parent)
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
			respawnLookAt = STAGE_2_FIRST_TARGET_POSITION,
			respawnCFrame = createFacingCFrame(STAGE_1_CHECKPOINT_RESPAWN_POSITION, STAGE_2_FIRST_TARGET_POSITION),
		},
	}
end

local function createStageTwoEntrance(parent)
	local platform = createPart(parent, "Stage2EntrancePlatform", Vector3.new(30, 1, 22), Vector3.new(0, 6.4, 195), NOOB_COLORS.Blue, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 2", COLORS.Dark)

	createPart(parent, "Stage2EntranceLeftHand", Vector3.new(5, 1.2, 8), Vector3.new(-16, 7.4, 199), NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
		CanTouch = false,
	})
	createPart(parent, "Stage2EntranceRightHand", Vector3.new(5, 1.2, 8), Vector3.new(16, 7.4, 199), NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic, {
		CanTouch = false,
	})

	return platform
end

local function createStageTwoObstacles(parent, template)
	for index, obstacle in ipairs(STAGE_2_SAFE_NOOBS) do
		if template then
			createTemplateSafeNoob(parent, template, index, obstacle)
		elseif obstacle.kind == "head" then
			createNoobHeadObstacle(parent, index, obstacle)
		elseif obstacle.kind == "torso" then
			createNoobTorsoObstacle(parent, obstacle)
		elseif obstacle.kind == "limb" then
			createNoobLimbObstacle(parent, obstacle)
		elseif obstacle.kind == "stack" then
			createNoobStackObstacle(parent, index, obstacle)
		elseif obstacle.kind == "hand" then
			createNoobHandPlatform(parent, index, obstacle)
		end
	end
end

local function createStageTwoCheckpoint(parent)
	local platform = createPart(parent, "Stage2CheckpointPlatform", Vector3.new(28, 1, 18), Vector3.new(0, 8.8, 352), NOOB_COLORS.Yellow, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "CP 2", COLORS.Dark)

	local base = createPart(parent, "Stage2CheckpointBase", Vector3.new(20, 0.16, 10), Vector3.new(0, 9.42, 352), COLORS.CheckpointAccent, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.28,
	})

	local pad = createPart(parent, "Stage2Checkpoint", Vector3.new(16, 0.35, 7), Vector3.new(0, 9.62, 352), COLORS.Checkpoint, Enum.Material.Neon, {
		CanCollide = false,
	})
	pad:SetAttribute("CheckpointIndex", 2)
	pad:SetAttribute("StageId", STAGE_2_ID)
	pad:SetAttribute("CompletesStage", true)

	return {
		id = "world_1_stage_2_checkpoint",
		index = 2,
		order = 2,
		stageId = STAGE_2_ID,
		completesStage = true,
		part = pad,
		base = base,
		platform = platform,
		respawnPosition = STAGE_2_CHECKPOINT_RESPAWN_POSITION,
		respawnLookAt = STAGE_3_FIRST_TARGET_POSITION,
		respawnCFrame = createFacingCFrame(STAGE_2_CHECKPOINT_RESPAWN_POSITION, STAGE_3_FIRST_TARGET_POSITION),
	}
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
	local checkpoints = createStageOneCheckpoint(courseFolder)
	createStageTwoEntrance(courseFolder)
	local stageTwoNoobTemplate = findStageTwoNoobTemplate()
	if stageTwoNoobTemplate then
		hideNoobTemplate(stageTwoNoobTemplate)
	end
	table.insert(hazards, createStageTwoNoobSea(courseFolder, stageTwoNoobTemplate))
	createStageTwoObstacles(courseFolder, stageTwoNoobTemplate)
	table.insert(checkpoints, createStageTwoCheckpoint(courseFolder))
	local stage3Data = Stage3WallRunBuilder.build(courseFolder)
	table.insert(checkpoints, stage3Data.checkpoint)
	local stage4Data = Stage4RcMazeBuilder.build(courseFolder)
	table.insert(checkpoints, stage4Data.checkpoint)
	local stage5Data = Stage5TsunamiBuilder.build(courseFolder)
	table.insert(checkpoints, stage5Data.checkpoint)
	for _, hazard in ipairs(stage5Data.hazards or {}) do
		table.insert(hazards, hazard)
	end
	local stage6Data = Stage6BasketballBuilder.build(courseFolder)
	table.insert(checkpoints, stage6Data.checkpoint)
	local stage7Data = Stage7CatMouseBuilder.build(courseFolder)
	table.insert(checkpoints, stage7Data.checkpoint)
	for _, hazard in ipairs(stage7Data.hazards or {}) do
		table.insert(hazards, hazard)
	end

	local startCFrame = createFacingCFrame(START_CHARACTER_POSITION, START_PAD_POSITION)
	local stageStarts = {
		[1] = {
			stageNumber = 1,
			stageId = STAGE_1_ID,
			cframe = startCFrame,
			latestCheckpoint = 0,
			latestCheckpointId = nil,
		},
		[2] = {
			stageNumber = 2,
			stageId = STAGE_2_ID,
			cframe = createFacingCFrame(STAGE_2_START_POSITION, STAGE_2_FIRST_TARGET_POSITION),
			latestCheckpoint = checkpoints[1].index,
			latestCheckpointId = checkpoints[1].id,
		},
		[3] = {
			stageNumber = 3,
			stageId = stage3Data.stageStart.stageId,
			cframe = stage3Data.stageStart.cframe,
			latestCheckpoint = checkpoints[2].index,
			latestCheckpointId = checkpoints[2].id,
		},
		[4] = {
			stageNumber = 4,
			stageId = stage4Data.stageStart.stageId,
			cframe = stage4Data.stageStart.cframe,
			latestCheckpoint = checkpoints[3].index,
			latestCheckpointId = checkpoints[3].id,
		},
		[5] = {
			stageNumber = 5,
			stageId = stage5Data.stageStart.stageId,
			cframe = stage5Data.stageStart.cframe,
			latestCheckpoint = checkpoints[4].index,
			latestCheckpointId = checkpoints[4].id,
		},
		[6] = {
			stageNumber = 6,
			stageId = stage6Data.stageStart.stageId,
			cframe = stage6Data.stageStart.cframe,
			latestCheckpoint = checkpoints[5].index,
			latestCheckpointId = checkpoints[5].id,
		},
		[7] = {
			stageNumber = 7,
			stageId = stage7Data.stageStart.stageId,
			cframe = stage7Data.stageStart.cframe,
			latestCheckpoint = checkpoints[6].index,
			latestCheckpointId = checkpoints[6].id,
		},
	}

	return {
		folder = courseFolder,
		worldId = WORLD_ID,
		startStageId = STAGE_1_ID,
		finishStageId = nil,
		startPad = startPad,
		startSpawnCFrame = startCFrame,
		startRespawnCFrame = startCFrame,
		finishPad = nil,
		checkpoints = checkpoints,
		stageStarts = stageStarts,
		stage4 = stage4Data,
		stage5 = stage5Data,
		stage6 = stage6Data,
		stage7 = stage7Data,
		hazards = hazards,
	}
end

return CourseBuilder
