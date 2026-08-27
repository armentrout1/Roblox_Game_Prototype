local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local WallRunConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WallRunConfig"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local Stage3WallRunBuilder = {}

local COLORS = ObbyConfig.Colors
local WORLD_ID = WorldConfig.CurrentWorldId
local STAGE_3_ID = WorldConfig.Worlds[WORLD_ID].stages[3].id

local STAGE_3_CHECKPOINT_RESPAWN_POSITION = Vector3.new(0, 13.4, 614)
local STAGE_4_GATE_TARGET_POSITION = Vector3.new(0, 13.4, 644)

local WALL_COLOR = Color3.fromRGB(24, 27, 34)
local WALL_ACCENT = Color3.fromRGB(255, 55, 68)
local SHADOW_PURPLE = Color3.fromRGB(96, 70, 150)

local WALL_SECTIONS = {
	{ name = "Stage3IntroLeftWall", side = -1, z = 408, length = 28, height = 22, y = 17.4 },
	{ name = "Stage3LongRightWall", side = 1, z = 441, length = 30, height = 23, y = 17.8 },
	{ name = "Stage3TransferLeftWall", side = -1, z = 475, length = 31, height = 24, y = 18.2 },
	{ name = "Stage3HighRightWall", side = 1, z = 510, length = 32, height = 25, y = 18.8 },
	{ name = "Stage3FastLeftWall", side = -1, z = 546, length = 34, height = 26, y = 19.2 },
	{ name = "Stage3FinalRightWall", side = 1, z = 583, length = 34, height = 26, y = 19.4 },
}

local REST_PLATFORMS = {
	{ name = "Stage3TransferPad01", position = Vector3.new(0, 9.8, 427), size = Vector3.new(12, 1, 6) },
	{ name = "Stage3TransferPad02", position = Vector3.new(0, 10.3, 496), size = Vector3.new(11, 1, 6) },
	{ name = "Stage3TransferPad03", position = Vector3.new(0, 10.8, 564), size = Vector3.new(10, 1, 6) },
}

local function createFacingCFrame(position, lookAtPosition)
	local flatLookAt = Vector3.new(lookAtPosition.X, position.Y, lookAtPosition.Z)
	if (flatLookAt - position).Magnitude < 0.01 then
		flatLookAt = position + WallRunConfig.StageForward
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
	surfaceGui.PixelsPerStud = 38
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

local function markWallRunSurface(part)
	part:SetAttribute(WallRunConfig.SurfaceAttribute, true)
	part:SetAttribute(WallRunConfig.SurfaceStageAttribute, STAGE_3_ID)
end

local function createWallArrow(parent, wall)
	local x = wall.side * 7.35
	local z = wall.z - (wall.length * 0.18)
	local y = wall.y + 0.5

	createPart(parent, wall.name .. "ArrowStem", Vector3.new(0.18, 0.9, 7), Vector3.new(x, y, z), WALL_ACCENT, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, wall.name .. "ArrowHeadLeft", Vector3.new(0.18, 0.9, 3.5), CFrame.new(x, y, z + 4) * CFrame.Angles(0, math.rad(30), 0), WALL_ACCENT, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, wall.name .. "ArrowHeadRight", Vector3.new(0.18, 0.9, 3.5), CFrame.new(x, y, z + 4) * CFrame.Angles(0, math.rad(-30), 0), WALL_ACCENT, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
end

local function createEntrance(parent)
	local platform = createPart(parent, "Stage3EntrancePlatform", Vector3.new(32, 1, 24), Vector3.new(0, 8.8, 378), SHADOW_PURPLE, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 3\nNINJA WALL RUN", COLORS.White)

	createPart(parent, "Stage3StartArrow", Vector3.new(3, 0.15, 10), Vector3.new(0, 9.4, 389), WALL_ACCENT, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, "Stage3NoRunDecoration", Vector3.new(3, 9, 14), Vector3.new(15, 14, 397), Color3.fromRGB(42, 43, 52), Enum.Material.SmoothPlastic, {
		CanTouch = false,
	})
end

local function createWallSection(parent, wall)
	local x = wall.side * 8.5
	local wallPart = createPart(parent, wall.name, Vector3.new(2, wall.height, wall.length), Vector3.new(x, wall.y, wall.z), WALL_COLOR, Enum.Material.SmoothPlastic)
	markWallRunSurface(wallPart)

	local accentX = wall.side * 7.42
	createPart(parent, wall.name .. "BottomGlow", Vector3.new(0.25, 0.35, wall.length - 2), Vector3.new(accentX, wall.y - (wall.height / 2) + 2, wall.z), WALL_ACCENT, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createPart(parent, wall.name .. "TopGlow", Vector3.new(0.25, 0.35, wall.length - 2), Vector3.new(accentX, wall.y + (wall.height / 2) - 2, wall.z), WALL_ACCENT, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
	})
	createWallArrow(parent, wall)
end

local function createRestPlatforms(parent)
	for _, platformConfig in ipairs(REST_PLATFORMS) do
		local platform = createPart(parent, platformConfig.name, platformConfig.size, platformConfig.position, COLORS.Beam, Enum.Material.SmoothPlastic)
		createPart(parent, platformConfig.name .. "Glow", platformConfig.size + Vector3.new(1, -0.65, 1), platformConfig.position + Vector3.new(0, 0.2, 0), WALL_ACCENT, Enum.Material.Neon, {
			CanCollide = false,
			CanTouch = false,
			Transparency = 0.4,
		})
	end
end

local function createWalls(parent)
	for _, wall in ipairs(WALL_SECTIONS) do
		createWallSection(parent, wall)
	end
end

local function createCheckpoint(parent)
	local platform = createPart(parent, "Stage3CheckpointPlatform", Vector3.new(30, 1, 20), Vector3.new(0, 10.2, 614), COLORS.CheckpointAccent, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "CP 3", COLORS.Dark)

	local base = createPart(parent, "Stage3CheckpointBase", Vector3.new(21, 0.16, 10), Vector3.new(0, 10.82, 614), COLORS.CheckpointAccent, Enum.Material.Neon, {
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.28,
	})

	local pad = createPart(parent, "Stage3Checkpoint", Vector3.new(17, 0.35, 7), Vector3.new(0, 11.02, 614), COLORS.Checkpoint, Enum.Material.Neon, {
		CanCollide = false,
	})
	pad:SetAttribute("CheckpointIndex", 3)
	pad:SetAttribute("StageId", STAGE_3_ID)
	pad:SetAttribute("CompletesStage", true)

	return {
		id = "world_1_stage_3_checkpoint",
		index = 3,
		order = 3,
		stageId = STAGE_3_ID,
		completesStage = true,
		part = pad,
		base = base,
		platform = platform,
		respawnPosition = STAGE_3_CHECKPOINT_RESPAWN_POSITION,
		respawnLookAt = STAGE_4_GATE_TARGET_POSITION,
		respawnCFrame = createFacingCFrame(STAGE_3_CHECKPOINT_RESPAWN_POSITION, STAGE_4_GATE_TARGET_POSITION),
	}
end

local function createStageFourPlaceholder(parent)
	local platform = createPart(parent, "Stage4PlaceholderPlatform", Vector3.new(34, 1, 24), Vector3.new(0, 10.2, 642), COLORS.Moving, Enum.Material.SmoothPlastic)
	createSurfaceLabel(platform, "STAGE 4", COLORS.Dark)

	createPart(parent, "Stage4GateLeftPost", Vector3.new(2, 12, 2), Vector3.new(-12, 16.5, 650), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage4GateRightPost", Vector3.new(2, 12, 2), Vector3.new(12, 16.5, 650), COLORS.Dark, Enum.Material.SmoothPlastic)
	createPart(parent, "Stage4GateTop", Vector3.new(26, 2, 2), Vector3.new(0, 22.5, 650), COLORS.Dark, Enum.Material.SmoothPlastic)

	local door = createPart(parent, "Stage4ComingNextDoor", Vector3.new(21, 8, 1), Vector3.new(0, 15.5, 651), COLORS.Start, Enum.Material.ForceField, {
		Transparency = 0.2,
	})
	createSurfaceLabel(door, "STAGE 4\nRC CAR MAZE\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Front)
	createSurfaceLabel(door, "STAGE 4\nRC CAR MAZE\nCOMING NEXT", COLORS.Dark, Enum.NormalId.Back)
end

function Stage3WallRunBuilder.build(parent)
	createEntrance(parent)
	createRestPlatforms(parent)
	createWalls(parent)
	local checkpoint = createCheckpoint(parent)
	createStageFourPlaceholder(parent)

	return checkpoint
end

return Stage3WallRunBuilder
