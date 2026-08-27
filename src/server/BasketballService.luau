local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BasketballConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasketballConfig"))

local BasketballService = {}
BasketballService.__index = BasketballService

local SHOTS = BasketballConfig.ShotOrder

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
		return nil, nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	return rootPart, humanoid
end

local function isInsidePart(part, position)
	local localPosition = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size / 2
	return math.abs(localPosition.X) <= halfSize.X
		and math.abs(localPosition.Y) <= halfSize.Y
		and math.abs(localPosition.Z) <= halfSize.Z
end

local function calculateLaunchVelocity(startPosition, targetPosition, flightTime)
	local gravity = Vector3.new(0, -workspace.Gravity, 0)
	local displacement = targetPosition - startPosition
	return (displacement - (0.5 * gravity * flightTime * flightTime)) / flightTime
end

local function getShotConfig(shotIndex)
	return SHOTS[shotIndex]
end

function BasketballService.new(stage6Data, runState, obbyRemote)
	return setmetatable({
		_stage6 = stage6Data,
		_runState = runState,
		_obbyRemote = obbyRemote,
		_remote = getOrCreateRemoteEvent(BasketballConfig.RemoteEventName),
		_stationByIndex = {},
		_progress = {},
		_activeShots = {},
		_activeBalls = {},
		_nextShotId = 0,
	}, BasketballService):_indexStations()
end

function BasketballService:_indexStations()
	if not self._stage6 then
		return self
	end

	for _, station in ipairs(self._stage6.stations or {}) do
		self._stationByIndex[station.index] = station
	end

	return self
end

function BasketballService:start()
	if not self._stage6 then
		return
	end

	for _, station in ipairs(self._stage6.stations or {}) do
		station.prompt.Triggered:Connect(function(player)
			self:_tryStartShot(player, station.index)
		end)
	end

	self._stage6.gateBlocker.Touched:Connect(function(hit)
		self:_onGateTouched(hit)
	end)

	self._remote.OnServerEvent:Connect(function(player, payload)
		self:_onClientCommand(player, payload)
	end)

	RunService.Heartbeat:Connect(function()
		self:_update()
	end)
end

function BasketballService:resetPlayer(player)
	self:_endActiveShot(player, "Reset")
	self:_clearBall(player)
	self._progress[player] = nil
	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.DoorLocked,
		doorVisual = self._stage6.doorVisual,
	})
end

function BasketballService:cleanupPlayer(player)
	self:_endActiveShot(player, "Cleanup")
	self:_clearBall(player)
	self._progress[player] = nil
end

function BasketballService:endShot(player, reason)
	self:_endActiveShot(player, reason or "Ended")
end

function BasketballService:isStageComplete(player)
	local progress = self._progress[player]
	return progress and progress.complete == true
end

function BasketballService:_tryStartShot(player, stationIndex)
	if not self:_canUseStage6(player) then
		self:_notifyPlayer(player, "Reach Stage 6 first")
		return
	end

	local progress = self:_getProgress(player)
	if progress.complete then
		self:_notifyPlayer(player, "CP 6 is unlocked")
		return
	end

	local requiredShot = getShotConfig(progress.nextShotIndex)
	if not requiredShot then
		return
	end

	if stationIndex ~= requiredShot.index then
		self:_notifyPlayer(player, requiredShot.displayName .. " is next")
		return
	end

	if self._activeShots[player] or self._activeBalls[player] then
		self:_notifyPlayer(player, "Finish this shot first")
		return
	end

	local now = workspace:GetServerTimeNow()
	if progress.cooldownUntil and now < progress.cooldownUntil then
		return
	end

	local rootPart, humanoid = getCharacterRootAndHumanoid(player)
	local station = self._stationByIndex[stationIndex]
	if not rootPart or not humanoid or humanoid.Health <= 0 or not station or not self:_isNearStation(rootPart.Position, station) then
		return
	end

	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = station.cframe

	self._nextShotId += 1
	local shotId = self._nextShotId
	self._activeShots[player] = {
		shotId = shotId,
		shotIndex = stationIndex,
		startedAt = now,
	}

	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.ShotStarted,
		shotId = shotId,
		shotIndex = requiredShot.index,
		displayName = requiredShot.displayName,
		progressText = string.format("%d / 3", requiredShot.index, #SHOTS),
		meterCycleDuration = requiredShot.meterCycleDuration,
		releaseTimeout = requiredShot.releaseTimeout,
		greenMin = requiredShot.greenMin,
		greenMax = requiredShot.greenMax,
	})
end

function BasketballService:_onClientCommand(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.action == BasketballConfig.Actions.ReleaseShot then
		self:_releaseShot(player, payload)
	elseif payload.action == BasketballConfig.Actions.CancelShot then
		self:_endActiveShot(player, "Canceled")
	end
end

function BasketballService:_releaseShot(player, payload)
	local activeShot = self._activeShots[player]
	if not activeShot or activeShot.shotId ~= payload.shotId then
		return
	end

	local shotConfig = getShotConfig(activeShot.shotIndex)
	local releaseValue = math.clamp(tonumber(payload.releaseValue) or -1, 0, 1)
	local elapsed = workspace:GetServerTimeNow() - activeShot.startedAt
	if elapsed < BasketballConfig.Scoring.MinReleaseElapsed or elapsed > shotConfig.releaseTimeout + 1 then
		return
	end

	local rootPart, humanoid = getCharacterRootAndHumanoid(player)
	local station = self._stationByIndex[activeShot.shotIndex]
	if not rootPart or not humanoid or humanoid.Health <= 0 or not self:_canUseStage6(player) or not self:_isNearStation(rootPart.Position, station) then
		self:_endActiveShot(player, "Invalid")
		return
	end

	self._activeShots[player] = nil
	local willScore = releaseValue >= shotConfig.greenMin and releaseValue <= shotConfig.greenMax
	local ball = self:_launchBall(player, station, shotConfig, releaseValue, willScore)
	self._activeBalls[player] = {
		ball = ball,
		shotIndex = activeShot.shotIndex,
		shotId = activeShot.shotId,
		willScore = willScore,
		expiresAt = workspace:GetServerTimeNow() + shotConfig.flightTime + BasketballConfig.Ball.ScoreCheckDurationPadding,
		missed = false,
	}
end

function BasketballService:_launchBall(player, station, shotConfig, releaseValue, willScore)
	self:_clearBall(player)

	local ball = Instance.new("Part")
	ball.Name = BasketballConfig.Ball.NamePrefix .. tostring(player.UserId)
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(BasketballConfig.Ball.Size, BasketballConfig.Ball.Size, BasketballConfig.Ball.Size)
	ball.Color = Color3.fromRGB(226, 99, 36)
	ball.Material = Enum.Material.SmoothPlastic
	ball.CanCollide = false
	ball.CanTouch = false
	ball.TopSurface = Enum.SurfaceType.Smooth
	ball.BottomSurface = Enum.SurfaceType.Smooth
	ball.Position = station.shotStartPosition
	ball.Parent = self._stage6.ballsFolder

	local center = (shotConfig.greenMin + shotConfig.greenMax) / 2
	local missDirection = releaseValue < center and -1 or 1
	local timingError = math.abs(releaseValue - center)
	local targetPosition = self._stage6.shotTarget
	if not willScore then
		local missOffset = math.max(7, timingError * BasketballConfig.Ball.MissOffsetScale)
		targetPosition += Vector3.new(missDirection * missOffset, timingError * 5, 0)
	end

	ball.AssemblyLinearVelocity = calculateLaunchVelocity(ball.Position, targetPosition, shotConfig.flightTime)

	pcall(function()
		ball:SetNetworkOwner(nil)
	end)

	Debris:AddItem(ball, BasketballConfig.Ball.Lifetime)
	return ball
end

function BasketballService:_update()
	local now = workspace:GetServerTimeNow()
	local timedOutShots = {}
	local missedBalls = {}
	local scoredBalls = {}

	for player, activeShot in pairs(self._activeShots) do
		local shotConfig = getShotConfig(activeShot.shotIndex)
		if not self:_canUseStage6(player) or now - activeShot.startedAt > shotConfig.releaseTimeout then
			table.insert(timedOutShots, {
				player = player,
				shotIndex = activeShot.shotIndex,
			})
		end
	end

	for player, ballState in pairs(self._activeBalls) do
		local ball = ballState.ball
		if not ball or not ball.Parent then
			table.insert(missedBalls, {
				player = player,
				shotIndex = ballState.shotIndex,
			})
		elseif ballState.willScore and isInsidePart(self._stage6.scoringZone, ball.Position) then
			table.insert(scoredBalls, {
				player = player,
				shotIndex = ballState.shotIndex,
			})
		elseif now >= ballState.expiresAt then
			table.insert(missedBalls, {
				player = player,
				shotIndex = ballState.shotIndex,
			})
		end
	end

	for _, shot in ipairs(timedOutShots) do
		self:_missShot(shot.player, shot.shotIndex, "Shot timed out")
	end

	for _, shot in ipairs(scoredBalls) do
		self:_scoreShot(shot.player, shot.shotIndex)
	end

	for _, shot in ipairs(missedBalls) do
		self:_missShot(shot.player, shot.shotIndex)
	end
end

function BasketballService:_scoreShot(player, shotIndex)
	local ballState = self._activeBalls[player]
	self._activeBalls[player] = nil
	self:_destroyBallState(ballState)

	local progress = self:_getProgress(player)
	progress.completedShots[shotIndex] = true
	progress.cooldownUntil = workspace:GetServerTimeNow() + BasketballConfig.Ball.ShotCooldown

	local shotConfig = getShotConfig(shotIndex)
	local nextShotIndex = shotIndex + 1
	progress.nextShotIndex = nextShotIndex

	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.ShotScored,
		shotIndex = shotIndex,
		displayName = shotConfig.displayName,
		message = "SWISH! " .. shotConfig.displayName .. " Complete",
		progressText = string.format("%d / 3", math.min(shotIndex, #SHOTS), #SHOTS),
	})

	if nextShotIndex > #SHOTS then
		progress.complete = true
		progress.nextShotIndex = #SHOTS + 1
		self._remote:FireClient(player, {
			type = BasketballConfig.Messages.Completed,
			message = "All shots made! CP 6 unlocked",
			doorVisual = self._stage6.doorVisual,
		})
		self:_notifyPlayer(player, "CP 6 unlocked")
	else
		local nextShot = getShotConfig(nextShotIndex)
		self._remote:FireClient(player, {
			type = BasketballConfig.Messages.ProgressChanged,
			shotIndex = nextShot.index,
			displayName = nextShot.displayName,
			progressText = string.format("%d / 3", nextShot.index, #SHOTS),
		})
	end
end

function BasketballService:_missShot(player, shotIndex, message)
	local activeShot = self._activeShots[player]
	if activeShot and activeShot.shotIndex == shotIndex then
		self._activeShots[player] = nil
	end

	local ballState = self._activeBalls[player]
	if ballState and ballState.shotIndex == shotIndex then
		self._activeBalls[player] = nil
		self:_destroyBallState(ballState)
	end

	local progress = self:_getProgress(player)
	progress.cooldownUntil = workspace:GetServerTimeNow() + BasketballConfig.Ball.ShotCooldown

	local shotConfig = getShotConfig(shotIndex)
	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.ShotMissed,
		shotIndex = shotIndex,
		displayName = shotConfig and shotConfig.displayName,
		message = message or "MISS - try again",
		progressText = string.format("%d / 3", math.min(progress.nextShotIndex, #SHOTS), #SHOTS),
	})
end

function BasketballService:_endActiveShot(player, reason)
	local activeShot = self._activeShots[player]
	if not activeShot then
		return
	end

	self._activeShots[player] = nil
	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.ShotEnded,
		reason = reason or "Ended",
	})
end

function BasketballService:_clearBall(player)
	local ballState = self._activeBalls[player]
	self._activeBalls[player] = nil
	self:_destroyBallState(ballState)
end

function BasketballService:_destroyBallState(ballState)
	local ball = ballState and ballState.ball
	if ball and ball.Parent then
		ball:Destroy()
	end
end

function BasketballService:_getProgress(player)
	local progress = self._progress[player]
	if not progress then
		progress = {
			nextShotIndex = 1,
			completedShots = {},
			complete = false,
			cooldownUntil = 0,
		}
		self._progress[player] = progress
	end

	return progress
end

function BasketballService:_canUseStage6(player)
	local state = self._runState:get(player)
	return state.isRunActive and state.currentStageId == self._stage6.stageId
end

function BasketballService:_isNearStation(position, station)
	if not station then
		return false
	end

	return (position - station.cframe.Position).Magnitude <= 16
end

function BasketballService:_onGateTouched(hit)
	local character = hit:FindFirstAncestorWhichIsA("Model")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local player = character and Players:GetPlayerFromCharacter(character)
	if not player or not humanoid or humanoid.Health <= 0 or self:isStageComplete(player) or not self:_canUseStage6(player) then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.CFrame = self._stage6.deniedCFrame
	end

	local progress = self:_getProgress(player)
	local nextShot = getShotConfig(progress.nextShotIndex)
	self:_notifyPlayer(player, nextShot and ("Make the " .. nextShot.displayName .. " first") or "Make all 3 shots first")
end

function BasketballService:_notifyPlayer(player, message)
	if self._obbyRemote then
		self._obbyRemote:FireClient(player, {
			type = BasketballConfig.Messages.Notice,
			message = message,
		})
	end
end

return BasketballService
