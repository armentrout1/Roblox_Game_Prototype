local Debris = game:GetService("Debris")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CatMouseConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CatMouseConfig"))

local CatMouseService = {}
CatMouseService.__index = CatMouseService

local MESSAGES = CatMouseConfig.Messages
local STATES = CatMouseConfig.States

local function getOrCreateRemoteEvent(name)
	local remote = ReplicatedStorage:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = ReplicatedStorage
	end

	return remote
end

local function getCharacterRootAndHumanoid(player)
	local character = player.Character
	if not character then
		return nil, nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	return character, rootPart, humanoid
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

local function flatten(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end

local function clampPositionToBounds(position, bounds)
	return Vector3.new(
		math.clamp(position.X, bounds.MinX, bounds.MaxX),
		math.clamp(position.Y, bounds.MinY, bounds.MaxY),
		math.clamp(position.Z, bounds.MinZ, bounds.MaxZ)
	)
end

local function createFacingCFrame(position, lookAtPosition)
	local flatLookAt = Vector3.new(lookAtPosition.X, position.Y, lookAtPosition.Z)
	if (flatLookAt - position).Magnitude < 0.01 then
		flatLookAt = position + Vector3.new(0, 0, 1)
	end

	return CFrame.lookAt(position, flatLookAt)
end

function CatMouseService.new(stage7Data, runState, obbyRemote)
	return setmetatable({
		_stage7 = stage7Data,
		_runState = runState,
		_obbyRemote = obbyRemote,
		_remote = getOrCreateRemoteEvent(CatMouseConfig.RemoteEventName),
		_sessions = {},
		_completedPlayers = {},
	}, CatMouseService)
end

function CatMouseService:start()
	if not self._stage7 then
		return
	end

	self._stage7.attemptStart.Touched:Connect(function(hit)
		self:_onAttemptStartTouched(hit)
	end)

	self._stage7.escapeZone.Touched:Connect(function(hit)
		self:_onEscapeTouched(hit)
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		self:_update(deltaTime)
	end)
end

function CatMouseService:resetPlayer(player)
	self:endSession(player, "Reset")
	self._completedPlayers[player] = nil
end

function CatMouseService:cleanupPlayer(player)
	self:endSession(player, "Cleanup")
	self._completedPlayers[player] = nil
end

function CatMouseService:endSession(player, reason)
	local session = self._sessions[player]
	if not session then
		return
	end

	self._sessions[player] = nil
	self:_restoreCapturedPlayer(player, session)
	self:_destroyCat(session)

	self._remote:FireClient(player, {
		type = MESSAGES.Ended,
		reason = reason or "Ended",
	})
end

function CatMouseService:isStageComplete(player)
	return self._completedPlayers[player] == true
end

function CatMouseService:_onAttemptStartTouched(hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 then
		return
	end

	if not self:_canUseStage7(player) then
		self:_notifyPlayer(player, "Reach Stage 7 first")
		return
	end

	if self._completedPlayers[player] then
		self:_notifyPlayer(player, "CP 7 is unlocked")
		return
	end

	if self._sessions[player] then
		self:_notifyPlayer(player, "Keep running")
		return
	end

	self:_startAttempt(player)
end

function CatMouseService:_startAttempt(player)
	local catModel, catRoot = self:_createCatForPlayer(player)
	if not catModel or not catRoot then
		self:_notifyPlayer(player, "Cat chase could not start")
		return
	end

	local now = workspace:GetServerTimeNow()
	self._sessions[player] = {
		player = player,
		state = STATES.Chasing,
		catModel = catModel,
		catRoot = catRoot,
		catPosition = self._stage7.catSpawnCFrame.Position,
		lastLookAt = self._stage7.stageStart.cframe.Position,
		lastPathAt = -math.huge,
		lastCloseNoticeAt = -math.huge,
		stunUntil = 0,
		stunCooldownUntil = 0,
		captureToken = 0,
		waypoints = {},
		waypointIndex = 1,
		startedAt = now,
	}

	self._remote:FireClient(player, {
		type = MESSAGES.AttemptStarted,
		stageId = self._stage7.stageId,
	})
end

function CatMouseService:_createCatForPlayer(targetPlayer)
	local template = self._stage7.catTemplate
	if not template then
		return nil, nil
	end

	local catModel = template:Clone()
	catModel.Name = CatMouseConfig.Cat.ModelPrefix .. tostring(targetPlayer.UserId)
	catModel.Parent = self._stage7.activeCatsFolder

	local catRoot = catModel:FindFirstChild("CatRoot", true)
	if not catRoot or not catRoot:IsA("BasePart") then
		catModel:Destroy()
		return nil, nil
	end

	catModel.PrimaryPart = catRoot
	self:_makeCatVisible(catModel)
	catModel:PivotTo(self._stage7.catSpawnCFrame)

	local promptParent = catModel:FindFirstChild("CatBody", true) or catRoot
	if promptParent:IsA("BasePart") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DistractCatPrompt"
		prompt.ActionText = "Distract"
		prompt.ObjectText = "Giant Cat"
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0.12
		prompt.MaxActivationDistance = CatMouseConfig.Distract.InteractRange
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptParent
		prompt.Triggered:Connect(function(helperPlayer)
			self:_tryDistract(helperPlayer, targetPlayer)
		end)
	end

	return catModel, catRoot
end

function CatMouseService:_makeCatVisible(catModel)
	for _, descendant in ipairs(catModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			if descendant:GetAttribute("IsCatRoot") then
				descendant.Transparency = 1
			else
				descendant.Transparency = descendant:GetAttribute("VisibleTransparency") or 0
			end
		end
	end
end

function CatMouseService:_update(deltaTime)
	local serverNow = workspace:GetServerTimeNow()
	local playersToEnd = {}

	for player, session in pairs(self._sessions) do
		if not self:_canUseStage7(player) then
			table.insert(playersToEnd, player)
		elseif session.state == STATES.Chasing then
			self:_updateChase(session, deltaTime, serverNow)
		elseif session.state == STATES.Stunned then
			self:_updateStunned(session, serverNow)
		elseif session.state == STATES.Captured then
			self:_updateCaptured(session)
		end
	end

	for _, player in ipairs(playersToEnd) do
		self:endSession(player, "Stage changed")
	end
end

function CatMouseService:_updateChase(session, deltaTime, serverNow)
	local player = session.player
	local _, rootPart, humanoid = getCharacterRootAndHumanoid(player)
	if not rootPart or not humanoid or humanoid.Health <= 0 then
		self:endSession(player, "Character unavailable")
		return
	end

	if rootPart.Position.Y < self._stage7.bounds.MinY then
		humanoid.Health = 0
		self:endSession(player, "Fell")
		return
	end

	self:_refreshPath(session, rootPart.Position, serverNow)
	self:_moveCatTowardTarget(session, rootPart.Position, deltaTime, serverNow)

	local distance = (rootPart.Position - session.catPosition).Magnitude
	if distance <= CatMouseConfig.Cat.CatchRadius then
		self:_capturePlayer(player, session)
	elseif distance <= CatMouseConfig.Cat.CloseRadius and serverNow - session.lastCloseNoticeAt >= CatMouseConfig.Cat.CloseNoticeCooldown then
		session.lastCloseNoticeAt = serverNow
		self._remote:FireClient(player, {
			type = MESSAGES.CatClose,
			distance = distance,
		})
	end
end

function CatMouseService:_updateStunned(session, serverNow)
	if serverNow >= session.stunUntil then
		session.state = STATES.Chasing
		self:_setCatStunnedVisual(session, false)
	end

	self:_pivotCat(session, session.lastLookAt, serverNow)
end

function CatMouseService:_updateCaptured(session)
	local lockState = session.lockState
	if not lockState or not lockState.rootPart or not lockState.rootPart.Parent then
		return
	end

	lockState.rootPart.AssemblyLinearVelocity = Vector3.zero
	lockState.rootPart.AssemblyAngularVelocity = Vector3.zero
	lockState.rootPart.CFrame = self._stage7.captureHoldCFrame
end

function CatMouseService:_refreshPath(session, targetPosition, serverNow)
	if serverNow - session.lastPathAt < CatMouseConfig.Cat.PathRefreshInterval then
		return
	end

	session.lastPathAt = serverNow
	local path = PathfindingService:CreatePath({
		AgentRadius = 4,
		AgentHeight = 8,
		AgentCanJump = false,
		WaypointSpacing = 10,
	})

	local ok = pcall(function()
		path:ComputeAsync(session.catPosition, targetPosition)
	end)

	if ok and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		if #waypoints >= 2 then
			session.waypoints = waypoints
			session.waypointIndex = 2
			return
		end
	end

	session.waypoints = {}
	session.waypointIndex = 1
end

function CatMouseService:_getMoveTarget(session, targetPosition)
	local waypoints = session.waypoints
	while waypoints[session.waypointIndex] do
		local waypointPosition = waypoints[session.waypointIndex].Position
		local flatDelta = flatten(waypointPosition - session.catPosition)
		if flatDelta.Magnitude > CatMouseConfig.Cat.PathWaypointRadius then
			return waypointPosition
		end

		session.waypointIndex += 1
	end

	return targetPosition
end

function CatMouseService:_moveCatTowardTarget(session, targetPosition, deltaTime, serverNow)
	local moveTarget = self:_getMoveTarget(session, targetPosition)
	local flatTarget = Vector3.new(moveTarget.X, session.catPosition.Y, moveTarget.Z)
	local delta = flatTarget - session.catPosition

	if delta.Magnitude > 0.05 then
		local stepDistance = math.min(delta.Magnitude, CatMouseConfig.Cat.ChaseSpeed * deltaTime)
		local direction = delta.Unit
		session.catPosition = clampPositionToBounds(session.catPosition + (direction * stepDistance), self._stage7.bounds)
		session.lastLookAt = session.catPosition + direction
	end

	self:_pivotCat(session, targetPosition, serverNow)
end

function CatMouseService:_pivotCat(session, lookAtPosition, serverNow)
	if not session.catModel or not session.catModel.Parent then
		return
	end

	local target = Vector3.new(lookAtPosition.X, session.catPosition.Y, lookAtPosition.Z)
	if (target - session.catPosition).Magnitude < 0.05 then
		target = session.lastLookAt or (session.catPosition + Vector3.new(0, 0, 1))
	end

	local cframe = CFrame.lookAt(session.catPosition, target)
	if session.state == STATES.Stunned then
		local wobble = math.sin(serverNow * 10) * 0.12
		cframe *= CFrame.Angles(0, 0, wobble)
	end

	session.catModel:PivotTo(cframe)
end

function CatMouseService:_tryDistract(helperPlayer, targetPlayer)
	local session = self._sessions[targetPlayer]
	if not session or session.state ~= STATES.Chasing then
		self:_notifyPlayer(helperPlayer, "No cat to distract")
		return
	end

	if helperPlayer == targetPlayer then
		self:_notifyPlayer(helperPlayer, "A friend has to distract the cat")
		return
	end

	if not self:_canUseStage7(helperPlayer) then
		self:_notifyPlayer(helperPlayer, "Reach Stage 7 to help")
		return
	end

	local _, helperRoot, helperHumanoid = getCharacterRootAndHumanoid(helperPlayer)
	if not helperRoot or not helperHumanoid or helperHumanoid.Health <= 0 then
		return
	end

	local now = workspace:GetServerTimeNow()
	if now < session.stunCooldownUntil then
		self:_notifyPlayer(helperPlayer, "Wait for another opening")
		return
	end

	if (helperRoot.Position - session.catPosition).Magnitude > CatMouseConfig.Distract.InteractRange then
		return
	end

	local toHelper = flatten(helperRoot.Position - session.catPosition)
	local catForward = flatten(session.catRoot.CFrame.LookVector)
	if toHelper.Magnitude < 0.1 or catForward.Magnitude < 0.1 or toHelper.Unit:Dot(catForward.Unit) > -CatMouseConfig.Distract.BehindDotThreshold then
		self:_notifyPlayer(helperPlayer, "Distract from behind")
		return
	end

	session.state = STATES.Stunned
	session.stunUntil = now + CatMouseConfig.Cat.StunDuration
	session.stunCooldownUntil = now + CatMouseConfig.Cat.StunCooldown
	session.waypoints = {}
	session.waypointIndex = 1
	self:_setCatStunnedVisual(session, true)

	local payload = {
		type = MESSAGES.CatDistracted,
		duration = CatMouseConfig.Cat.StunDuration,
		helperName = helperPlayer.DisplayName,
	}
	self._remote:FireClient(targetPlayer, payload)
	self._remote:FireClient(helperPlayer, payload)
end

function CatMouseService:_setCatStunnedVisual(session, isStunned)
	if not session.catModel or not session.catModel.Parent then
		return
	end

	for _, descendant in ipairs(session.catModel:GetDescendants()) do
		if descendant:IsA("BasePart") and not descendant:GetAttribute("IsCatRoot") then
			if isStunned then
				if descendant:GetAttribute("PreStunColor") == nil then
					descendant:SetAttribute("PreStunColor", descendant.Color)
				end
				descendant.Color = descendant.Color:Lerp(Color3.fromRGB(96, 219, 255), 0.28)
			else
				local preStunColor = descendant:GetAttribute("PreStunColor")
				if preStunColor then
					descendant.Color = preStunColor
					descendant:SetAttribute("PreStunColor", nil)
				end
			end
		end
	end
end

function CatMouseService:_capturePlayer(player, session)
	local character, rootPart, humanoid = getCharacterRootAndHumanoid(player)
	if not character or not rootPart or not humanoid or humanoid.Health <= 0 then
		self:endSession(player, "Capture invalid")
		return
	end

	session.state = STATES.Captured
	session.captureToken += 1
	session.waypoints = {}
	session.waypointIndex = 1
	session.lockState = self:_lockCapturedCharacter(character, rootPart, humanoid)

	self._remote:FireClient(player, {
		type = MESSAGES.Captured,
		duration = CatMouseConfig.Cat.CaptureDuration,
	})

	local token = session.captureToken
	task.spawn(function()
		for remaining = CatMouseConfig.Cat.CaptureDuration, 1, -1 do
			if self._sessions[player] ~= session or session.captureToken ~= token or session.state ~= STATES.Captured then
				return
			end

			self._remote:FireClient(player, {
				type = MESSAGES.CaptureCountdown,
				seconds = remaining,
			})
			task.wait(1)
		end

		if self._sessions[player] == session and session.captureToken == token and session.state == STATES.Captured then
			self:_spitOutPlayer(player, session)
		end
	end)
end

function CatMouseService:_lockCapturedCharacter(character, rootPart, humanoid)
	local lockState = {
		character = character,
		rootPart = rootPart,
		humanoid = humanoid,
		originalWalkSpeed = humanoid.WalkSpeed,
		originalJumpPower = humanoid.JumpPower,
		originalJumpHeight = humanoid.JumpHeight,
		originalUseJumpPower = humanoid.UseJumpPower,
		originalAutoRotate = humanoid.AutoRotate,
		originalPlatformStand = humanoid.PlatformStand,
		originalAnchored = rootPart.Anchored,
		visuals = {},
	}

	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			table.insert(lockState.visuals, {
				instance = descendant,
				transparency = descendant.Transparency,
			})
			descendant.Transparency = 1
		end
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = self._stage7.captureHoldCFrame
	rootPart.Anchored = true

	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	humanoid.WalkSpeed = 0
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0

	return lockState
end

function CatMouseService:_restoreCapturedPlayer(player, session, targetCFrame)
	local lockState = session.lockState
	if not lockState then
		return
	end

	session.lockState = nil
	if lockState.character ~= player.Character then
		return
	end

	for _, visual in ipairs(lockState.visuals) do
		local instance = visual.instance
		if instance and instance.Parent then
			instance.Transparency = visual.transparency
		end
	end

	local rootPart = lockState.rootPart
	if rootPart and rootPart.Parent then
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		if targetCFrame then
			rootPart.CFrame = targetCFrame
		end
		rootPart.Anchored = lockState.originalAnchored
	end

	local humanoid = lockState.humanoid
	if humanoid and humanoid.Parent and humanoid.Health > 0 then
		humanoid.AutoRotate = lockState.originalAutoRotate
		humanoid.PlatformStand = lockState.originalPlatformStand
		humanoid.WalkSpeed = lockState.originalWalkSpeed
		humanoid.UseJumpPower = lockState.originalUseJumpPower
		humanoid.JumpPower = lockState.originalJumpPower
		humanoid.JumpHeight = lockState.originalJumpHeight
	end
end

function CatMouseService:_spitOutPlayer(player, session)
	self:_createHairball(session)
	self:_restoreCapturedPlayer(player, session, self._stage7.retryCFrame)
	self:_destroyCat(session)
	self._sessions[player] = nil

	self._remote:FireClient(player, {
		type = MESSAGES.SpitOut,
		duration = CatMouseConfig.Ui.NoticeDuration,
	})
end

function CatMouseService:_createHairball(session)
	if not self._stage7.effectsFolder then
		return
	end

	local sourceCFrame = session.catRoot and session.catRoot.CFrame or createFacingCFrame(session.catPosition, self._stage7.retryCFrame.Position)
	local startPosition = (sourceCFrame * CFrame.new(0, 5.5, -9)).Position
	local targetPosition = self._stage7.retryCFrame.Position

	local hairball = Instance.new("Part")
	hairball.Name = "Stage7HairballSpit"
	hairball.Shape = Enum.PartType.Ball
	hairball.Size = Vector3.new(3.6, 3.6, 3.6)
	hairball.Color = Color3.fromRGB(125, 103, 88)
	hairball.Material = Enum.Material.SmoothPlastic
	hairball.Anchored = false
	hairball.CanCollide = true
	hairball.CanTouch = false
	hairball.Position = startPosition
	hairball.TopSurface = Enum.SurfaceType.Smooth
	hairball.BottomSurface = Enum.SurfaceType.Smooth
	hairball.Parent = self._stage7.effectsFolder

	local smoke = Instance.new("Smoke")
	smoke.Name = "HairballPuff"
	smoke.Color = Color3.fromRGB(148, 139, 126)
	smoke.Opacity = 0.22
	smoke.RiseVelocity = 2
	smoke.Size = 8
	smoke.Parent = hairball

	local displacement = targetPosition - startPosition
	hairball.AssemblyLinearVelocity = Vector3.new(displacement.X, 22, displacement.Z) * 0.75
	hairball.AssemblyAngularVelocity = Vector3.new(3, 7, 2)

	pcall(function()
		hairball:SetNetworkOwner(nil)
	end)

	Debris:AddItem(hairball, 3.5)
end

function CatMouseService:_onEscapeTouched(hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 or not self:_canUseStage7(player) then
		return
	end

	local session = self._sessions[player]
	if not session then
		if not self._completedPlayers[player] then
			self:_notifyPlayer(player, "Touch RUN to start the chase")
		end
		return
	end

	if session.state == STATES.Captured then
		return
	end

	self._completedPlayers[player] = true
	self._sessions[player] = nil
	self:_destroyCat(session)

	self._remote:FireClient(player, {
		type = MESSAGES.Escaped,
		duration = CatMouseConfig.Ui.EscapeDuration,
	})
	self:_notifyPlayer(player, "CP 7 unlocked")
end

function CatMouseService:_destroyCat(session)
	if session and session.catModel and session.catModel.Parent then
		session.catModel:Destroy()
	end
end

function CatMouseService:_canUseStage7(player)
	if not self._stage7 then
		return false
	end

	local state = self._runState:get(player)
	return state.isRunActive and state.currentStageId == self._stage7.stageId
end

function CatMouseService:_notifyPlayer(player, message)
	if self._obbyRemote then
		self._obbyRemote:FireClient(player, {
			type = MESSAGES.Notice,
			message = message,
		})
	end
end

return CatMouseService
