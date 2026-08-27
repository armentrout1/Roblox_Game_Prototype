local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RcCarConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RcCarConfig"))

local RcCarService = {}
RcCarService.__index = RcCarService

local UP = Vector3.new(0, 1, 0)
local RC_CAR_COLLISION_GROUP = "Stage4RcCars"

local function ensureRcCollisionGroup()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(RC_CAR_COLLISION_GROUP)
	end)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(RC_CAR_COLLISION_GROUP, RC_CAR_COLLISION_GROUP, false)
	end)
end

local function findPlayerFromHit(hit)
	local character = hit:FindFirstAncestorWhichIsA("Model")
	if not character then
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil, nil
	end

	return Players:GetPlayerFromCharacter(character), humanoid
end

local function getOrCreateRemoteEvent(name)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end

	return remote
end

local function getFlatUnit(vector, fallback)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.01 then
		return fallback
	end

	return flat.Unit
end

local function normalizeAxis(value)
	local numberValue = math.clamp(tonumber(value) or 0, -1, 1)
	if numberValue > 0.2 then
		return 1
	elseif numberValue < -0.2 then
		return -1
	end

	return 0
end

local function moveToward(value, target, maxDelta)
	if value < target then
		return math.min(value + maxDelta, target)
	elseif value > target then
		return math.max(value - maxDelta, target)
	end

	return value
end

function RcCarService.new(stage4Data, runState, obbyRemote)
	ensureRcCollisionGroup()

	return setmetatable({
		_stage4 = stage4Data,
		_runState = runState,
		_obbyRemote = obbyRemote,
		_remote = getOrCreateRemoteEvent(RcCarConfig.RemoteEventName),
		_sessions = {},
		_completedPlayers = {},
		_nextSessionId = 0,
	}, RcCarService)
end

function RcCarService:start()
	if not self._stage4 then
		return
	end

	self._stage4.controlPrompt.Triggered:Connect(function(player)
		self:_tryStartSession(player)
	end)

	self._stage4.gateBlocker.Touched:Connect(function(hit)
		self:_onGateTouched(hit)
	end)

	self._remote.OnServerEvent:Connect(function(player, payload)
		self:_onClientCommand(player, payload)
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		self:_update(deltaTime)
	end)
end

function RcCarService:resetPlayer(player)
	self:endSession(player, "Reset")
	self._completedPlayers[player] = nil
	self._remote:FireClient(player, {
		type = RcCarConfig.Messages.DoorLocked,
		doorVisual = self._stage4.doorVisual,
	})
end

function RcCarService:cleanupPlayer(player)
	self:endSession(player, "Cleanup")
	self._completedPlayers[player] = nil
end

function RcCarService:endSession(player, reason)
	local session = self._sessions[player]
	if not session then
		return
	end

	self._sessions[player] = nil
	self:_restoreCharacter(session)

	if session.carModel then
		session.carModel:Destroy()
	end

	self._remote:FireClient(player, {
		type = RcCarConfig.Messages.Ended,
		reason = reason or "Ended",
		doorVisual = self._stage4.doorVisual,
	})
end

function RcCarService:isStageComplete(player)
	return self._completedPlayers[player] == true
end

function RcCarService:_tryStartSession(player)
	if self._sessions[player] then
		self:_resetCar(player, "Already driving")
		return
	end

	if self._completedPlayers[player] then
		self:_notifyPlayer(player, "RC gate is already unlocked")
		return
	end

	if not self:_canUseStage4(player) then
		self:_notifyPlayer(player, "Reach Stage 4 first")
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	self._nextSessionId += 1
	local sessionId = self._nextSessionId
	local car = self:_createCar(player, sessionId)
	local session = {
		sessionId = sessionId,
		player = player,
		character = character,
		humanoid = humanoid,
		rootPart = rootPart,
		originalRootAnchored = rootPart.Anchored,
		originalWalkSpeed = humanoid.WalkSpeed,
		originalJumpPower = humanoid.JumpPower,
		originalAutoRotate = humanoid.AutoRotate,
		carModel = car.model,
		carRoot = car.root,
		linearVelocity = car.linearVelocity,
		alignOrientation = car.alignOrientation,
		heading = getFlatUnit(self._stage4.rcStartCFrame.LookVector, Vector3.new(0, 0, 1)),
		speed = 0,
		input = {
			throttle = 0,
			steer = 0,
		},
		lastReset = -math.huge,
	}
	self._sessions[player] = session

	self:_freezeCharacter(session)
	self:_resetSessionCar(session)

	self._remote:FireClient(player, {
		type = RcCarConfig.Messages.Started,
		sessionId = session.sessionId,
		carModel = session.carModel,
		carRoot = session.carRoot,
		carModelName = session.carModel.Name,
		carRootName = session.carRoot.Name,
		doorVisual = self._stage4.doorVisual,
		originalWalkSpeed = session.originalWalkSpeed,
		originalJumpPower = session.originalJumpPower,
		originalAutoRotate = session.originalAutoRotate,
	})
end

function RcCarService:_onClientCommand(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	local action = payload.action
	if action == RcCarConfig.Actions.Input then
		self:_setInput(player, payload)
	elseif action == RcCarConfig.Actions.ResetCar then
		self:_resetCar(player, "Manual reset")
	elseif action == RcCarConfig.Actions.Exit then
		self:endSession(player, "Exited")
	end
end

function RcCarService:_setInput(player, payload)
	local session = self._sessions[player]
	if not session then
		return
	end

	session.input.throttle = normalizeAxis(payload.throttle)
	session.input.steer = normalizeAxis(payload.steer)
end

function RcCarService:_resetCar(player, reason)
	local session = self._sessions[player]
	if not session then
		return
	end

	local now = os.clock()
	if now - session.lastReset < RcCarConfig.Vehicle.ResetCooldown then
		return
	end

	session.lastReset = now
	self:_resetSessionCar(session)
	self._remote:FireClient(player, {
		type = RcCarConfig.Messages.Reset,
		reason = reason or "Reset",
		sessionId = session.sessionId,
		carRoot = session.carRoot,
		carModelName = session.carModel.Name,
		carRootName = session.carRoot.Name,
	})
end

function RcCarService:_update(deltaTime)
	for player, session in pairs(self._sessions) do
		if not self:_isSessionValid(player, session) then
			self:endSession(player, "Interrupted")
			continue
		end

		local position = session.carRoot.Position
		if not self:_isInBounds(position) then
			self:_resetCar(player, "Recovered")
			continue
		end

		self:_applyDriving(session, deltaTime)

		if self:_isAtGoal(session.carRoot.Position) then
			self:_completeMaze(player)
		end
	end
end

function RcCarService:_applyDriving(session, deltaTime)
	local tuning = RcCarConfig.Vehicle
	local throttle = session.input.throttle
	local steer = session.input.steer

	if throttle ~= 0 then
		session.speed += throttle * tuning.Acceleration * deltaTime
	else
		session.speed = moveToward(session.speed, 0, tuning.Deceleration * deltaTime)
	end

	session.speed = math.clamp(session.speed, -tuning.ReverseMaxSpeed, tuning.MaxSpeed)

	if steer ~= 0 and math.abs(session.speed) > 0.5 then
		local reverseSign = session.speed >= 0 and 1 or -1
		local yawDelta = steer * tuning.SteeringSpeed * deltaTime * reverseSign
		session.heading = getFlatUnit(CFrame.Angles(0, yawDelta, 0):VectorToWorldSpace(session.heading), Vector3.new(0, 0, 1))
	end

	session.linearVelocity.VectorVelocity = session.heading * session.speed
	session.alignOrientation.CFrame = CFrame.lookAt(session.carRoot.Position, session.carRoot.Position + session.heading, UP)
end

function RcCarService:_completeMaze(player)
	local session = self._sessions[player]
	if not session then
		return
	end

	self._completedPlayers[player] = true
	self._remote:FireClient(player, {
		type = RcCarConfig.Messages.Completed,
		doorVisual = self._stage4.doorVisual,
	})
	self:_notifyPlayer(player, "RC complete! Gate unlocked")
	self:endSession(player, "Completed")
end

function RcCarService:_createCar(player, sessionId)
	local model = Instance.new("Model")
	model.Name = string.format("%s%d_%d", RcCarConfig.CarModelPrefix, player.UserId, sessionId)
	model.Parent = self._stage4.rcCarsFolder

	local root = Instance.new("Part")
	root.Name = RcCarConfig.CarRootName
	root.Anchored = false
	root.CanCollide = true
	root.CanTouch = false
	root.Size = Vector3.new(4, 1, 6)
	root.CFrame = self._stage4.rcStartCFrame
	root.Color = Color3.fromRGB(255, 68, 72)
	root.Material = Enum.Material.SmoothPlastic
	root.CustomPhysicalProperties = PhysicalProperties.new(1.5, 0.55, 0.05)
	root.CollisionGroup = RC_CAR_COLLISION_GROUP
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.Parent = model
	model.PrimaryPart = root

	local attachment = Instance.new("Attachment")
	attachment.Name = "RcCarDriveAttachment"
	attachment.Parent = root

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "RcCarLinearVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = RcCarConfig.Vehicle.LinearMaxForce
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.Parent = root

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "RcCarAlignOrientation"
	alignOrientation.Attachment0 = attachment
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.MaxTorque = RcCarConfig.Vehicle.OrientationMaxTorque
	alignOrientation.Responsiveness = RcCarConfig.Vehicle.OrientationResponsiveness
	alignOrientation.RigidityEnabled = false
	alignOrientation.CFrame = root.CFrame
	alignOrientation.Parent = root

	self:_addCarVisual(root, model, "RcCarCab", Vector3.new(3.4, 1.2, 2.8), CFrame.new(0, 0.85, -0.65), Color3.fromRGB(45, 116, 255), Enum.Material.SmoothPlastic)
	self:_addCarVisual(root, model, "RcCarSpoiler", Vector3.new(4.4, 0.35, 0.8), CFrame.new(0, 0.92, 2.7), Color3.fromRGB(26, 28, 36), Enum.Material.SmoothPlastic)
	self:_addCarVisual(root, model, "RcCarAntenna", Vector3.new(0.18, 2.2, 0.18), CFrame.new(1.1, 1.85, 1.4), Color3.fromRGB(255, 224, 74), Enum.Material.Neon)

	for index, offset in ipairs({
		Vector3.new(-2.25, -0.35, -2),
		Vector3.new(2.25, -0.35, -2),
		Vector3.new(-2.25, -0.35, 2),
		Vector3.new(2.25, -0.35, 2),
	}) do
		self:_addCarVisual(root, model, "RcCarWheel" .. tostring(index), Vector3.new(0.7, 1.35, 1.35), CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(20, 22, 27), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
	end

	pcall(function()
		root:SetNetworkOwner(player)
	end)

	return {
		model = model,
		root = root,
		linearVelocity = linearVelocity,
		alignOrientation = alignOrientation,
	}
end

function RcCarService:_addCarVisual(root, model, name, size, localCFrame, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.Massless = true
	part.Size = size
	part.CFrame = root.CFrame * localCFrame
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
end

function RcCarService:_resetSessionCar(session)
	session.speed = 0
	session.input.throttle = 0
	session.input.steer = 0
	session.heading = getFlatUnit(self._stage4.rcStartCFrame.LookVector, Vector3.new(0, 0, 1))
	session.carRoot.AssemblyLinearVelocity = Vector3.zero
	session.carRoot.AssemblyAngularVelocity = Vector3.zero
	session.carRoot.CFrame = self._stage4.rcStartCFrame
	session.linearVelocity.VectorVelocity = Vector3.zero
	session.alignOrientation.CFrame = self._stage4.rcStartCFrame
end

function RcCarService:_freezeCharacter(session)
	session.rootPart.AssemblyLinearVelocity = Vector3.zero
	session.rootPart.AssemblyAngularVelocity = Vector3.zero
	session.rootPart.CFrame = self._stage4.controlCharacterCFrame
	session.rootPart.Anchored = true
	session.humanoid.WalkSpeed = 0
	session.humanoid.JumpPower = 0
	session.humanoid.AutoRotate = false
end

function RcCarService:_restoreCharacter(session)
	if session.rootPart and session.rootPart.Parent then
		session.rootPart.Anchored = session.originalRootAnchored
	end

	if session.humanoid and session.humanoid.Parent and session.humanoid.Health > 0 then
		session.humanoid.WalkSpeed = session.originalWalkSpeed
		session.humanoid.JumpPower = session.originalJumpPower
		session.humanoid.AutoRotate = session.originalAutoRotate
	end
end

function RcCarService:_isSessionValid(player, session)
	if not player.Parent or not session.carRoot or not session.carRoot.Parent then
		return false
	end

	if not session.character or player.Character ~= session.character then
		return false
	end

	return session.humanoid and session.humanoid.Parent and session.humanoid.Health > 0
end

function RcCarService:_canUseStage4(player)
	local state = self._runState:get(player)
	return state.isRunActive and state.currentStageId == self._stage4.stageId
end

function RcCarService:_isInBounds(position)
	local bounds = self._stage4.bounds
	return position.X >= bounds.minX
		and position.X <= bounds.maxX
		and position.Z >= bounds.minZ
		and position.Z <= bounds.maxZ
		and position.Y >= bounds.minY
		and position.Y <= bounds.maxY
end

function RcCarService:_isAtGoal(position)
	local goal = self._stage4.rcGoal
	local localPosition = goal.CFrame:PointToObjectSpace(position)
	return math.abs(localPosition.X) <= (goal.Size.X / 2) + 2
		and math.abs(localPosition.Z) <= (goal.Size.Z / 2) + 2
end

function RcCarService:_onGateTouched(hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 or self._completedPlayers[player] then
		return
	end

	if not self:_canUseStage4(player) then
		return
	end

	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.CFrame = self._stage4.deniedCFrame
	end

	self:_notifyPlayer(player, "Finish the RC maze first")
end

function RcCarService:_notifyPlayer(player, message)
	if self._obbyRemote then
		self._obbyRemote:FireClient(player, {
			type = RcCarConfig.Messages.Notice,
			message = message,
		})
	end
end

return RcCarService
