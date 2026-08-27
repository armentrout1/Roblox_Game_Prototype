local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local WallRunConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WallRunConfig"))

local WallRunController = {}

local player = Players.LocalPlayer
local UP = Vector3.new(0, 1, 0)

local started = false
local character = nil
local humanoid = nil
local rootPart = nil
local raycastParams = RaycastParams.new()

local active = false
local activeNormal = nil
local activeDirection = nil
local startedAt = 0
local lostWallAt = nil
local cooldownUntil = 0
local originalAutoRotate = true
local attachment = nil
local linearVelocity = nil
local alignOrientation = nil

local function refreshRaycastFilter()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = character and { character } or {}
	raycastParams.IgnoreWater = true
end

local function isValidWall(result)
	local instance = result and result.Instance
	if not instance then
		return false
	end

	return instance:GetAttribute(WallRunConfig.SurfaceAttribute) == true
		and instance:GetAttribute(WallRunConfig.SurfaceStageAttribute) == WallRunConfig.StageId
		and math.abs(result.Normal.Y) < 0.25
end

local function getRunDirection(normal)
	local direction = normal:Cross(UP)
	if direction.Magnitude < 0.01 then
		return WallRunConfig.StageForward
	end

	direction = direction.Unit
	if direction:Dot(WallRunConfig.StageForward) < 0 then
		direction = -direction
	end

	return direction
end

local function castWall(direction)
	if not rootPart then
		return nil
	end

	local result = workspace:Raycast(rootPart.Position, direction.Unit * WallRunConfig.DetectionDistance, raycastParams)
	if isValidWall(result) then
		return result
	end

	return nil
end

local function findNearbyWall()
	if not rootPart then
		return nil
	end

	local directions = {
		-rootPart.CFrame.RightVector,
		rootPart.CFrame.RightVector,
		Vector3.new(-1, 0, 0),
		Vector3.new(1, 0, 0),
	}

	for _, direction in ipairs(directions) do
		local result = castWall(direction)
		if result then
			return result
		end
	end

	return nil
end

local function destroyMovementForces()
	if linearVelocity then
		linearVelocity:Destroy()
		linearVelocity = nil
	end

	if alignOrientation then
		alignOrientation:Destroy()
		alignOrientation = nil
	end

	if attachment then
		attachment:Destroy()
		attachment = nil
	end
end

local function stopWallRun()
	if not active then
		return
	end

	active = false
	activeNormal = nil
	activeDirection = nil
	lostWallAt = nil
	cooldownUntil = os.clock() + WallRunConfig.Cooldown
	destroyMovementForces()

	if humanoid then
		humanoid.AutoRotate = originalAutoRotate
	end
end

local function createMovementForces()
	if not rootPart then
		return
	end

	attachment = Instance.new("Attachment")
	attachment.Name = "Stage3WallRunAttachment"
	attachment.Parent = rootPart

	linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "Stage3WallRunVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = WallRunConfig.MaxForce
	linearVelocity.Parent = rootPart

	alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "Stage3WallRunOrientation"
	alignOrientation.Attachment0 = attachment
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.MaxTorque = WallRunConfig.MaxTorque
	alignOrientation.Responsiveness = WallRunConfig.OrientationResponsiveness
	alignOrientation.Parent = rootPart
end

local function applyWallRunVelocity()
	if not active or not rootPart or not linearVelocity or not alignOrientation or not activeNormal or not activeDirection then
		return
	end

	linearVelocity.VectorVelocity = (activeDirection * WallRunConfig.WallRunSpeed)
		+ (UP * WallRunConfig.VerticalVelocity)
		+ (-activeNormal * WallRunConfig.WallStickVelocity)
	alignOrientation.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + activeDirection, UP)
end

local function startWallRun(result)
	if active or not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	active = true
	activeNormal = result.Normal
	activeDirection = getRunDirection(activeNormal)
	startedAt = os.clock()
	lostWallAt = nil
	originalAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

	createMovementForces()
	applyWallRunVelocity()
end

local function isAirborne()
	if not humanoid then
		return false
	end

	local humanoidState = humanoid:GetState()
	return humanoid.FloorMaterial == Enum.Material.Air
		or humanoidState == Enum.HumanoidStateType.Jumping
		or humanoidState == Enum.HumanoidStateType.Freefall
end

local function tryStartWallRun()
	if active or os.clock() < cooldownUntil or not isAirborne() or not humanoid or humanoid.Health <= 0 then
		return
	end

	local wallResult = findNearbyWall()
	if wallResult then
		startWallRun(wallResult)
	end
end

local function updateActiveWallRun()
	if not active or not humanoid or not rootPart or humanoid.Health <= 0 then
		stopWallRun()
		return
	end

	local now = os.clock()
	if now - startedAt >= WallRunConfig.MaxDuration then
		stopWallRun()
		return
	end

	local wallResult = activeNormal and castWall(-activeNormal) or nil
	if not wallResult then
		wallResult = findNearbyWall()
	end

	if wallResult then
		activeNormal = wallResult.Normal
		activeDirection = getRunDirection(activeNormal)
		lostWallAt = nil
	else
		lostWallAt = lostWallAt or now
		if now - lostWallAt > WallRunConfig.LostWallGraceTime then
			stopWallRun()
			return
		end
	end

	applyWallRunVelocity()
end

local function jumpAwayFromWall()
	if not active or not rootPart or not humanoid or not activeNormal or not activeDirection then
		return
	end

	local jumpVelocity = (activeNormal * WallRunConfig.JumpAwayVelocity)
		+ (activeDirection * WallRunConfig.JumpForwardVelocity)
		+ (UP * WallRunConfig.JumpUpVelocity)

	stopWallRun()
	rootPart.AssemblyLinearVelocity = jumpVelocity
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

local function bindCharacter(newCharacter)
	stopWallRun()
	character = newCharacter
	humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	refreshRaycastFilter()

	if humanoid then
		humanoid.Died:Connect(function()
			stopWallRun()
		end)
	end
end

function WallRunController.start()
	if started then
		return
	end

	started = true
	refreshRaycastFilter()

	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		task.defer(bindCharacter, player.Character)
	end

	UserInputService.JumpRequest:Connect(function()
		jumpAwayFromWall()
	end)

	RunService.Heartbeat:Connect(function()
		if active then
			updateActiveWallRun()
		else
			tryStartWallRun()
		end
	end)
end

return WallRunController
