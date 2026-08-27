local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BasketballConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasketballConfig"))

local BasketballService = {}
BasketballService.__index = BasketballService

local SHOTS = BasketballConfig.ShotOrder
local QUALITIES = BasketballConfig.ShotQualities

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

local function calculateMeterValue(elapsed, cycleDuration)
	local progress = (elapsed % cycleDuration) / cycleDuration
	return progress <= 0.5 and (progress * 2) or ((1 - progress) * 2)
end

local function calculateLaunchVelocity(startPosition, targetPosition, arcHeight)
	local gravity = workspace.Gravity
	local apexY = math.max(startPosition.Y, targetPosition.Y) + math.max(arcHeight or 18, 4)
	local verticalVelocity = math.sqrt(2 * gravity * math.max(apexY - startPosition.Y, 1))
	local timeUp = verticalVelocity / gravity
	local timeDown = math.sqrt((2 * math.max(apexY - targetPosition.Y, 1)) / gravity)
	local flightTime = math.max(timeUp + timeDown, 0.25)
	local horizontalDisplacement = Vector3.new(targetPosition.X - startPosition.X, 0, targetPosition.Z - startPosition.Z)
	local horizontalVelocity = horizontalDisplacement / flightTime

	return Vector3.new(horizontalVelocity.X, verticalVelocity, horizontalVelocity.Z), flightTime
end

local function getShotConfig(shotIndex)
	return SHOTS[shotIndex]
end

local function getCompletedShotIndices(progress)
	local completedShotIndices = {}
	for shotIndex = 1, #SHOTS do
		if progress.completedShots[shotIndex] then
			table.insert(completedShotIndices, shotIndex)
		end
	end

	return completedShotIndices
end

local function getCompletedShotCount(progress)
	local count = 0
	for shotIndex = 1, #SHOTS do
		if progress.completedShots[shotIndex] then
			count += 1
		end
	end

	return count
end

local function getShotQuality(shotConfig, releaseValue)
	if releaseValue >= shotConfig.perfectMin and releaseValue <= shotConfig.perfectMax then
		return QUALITIES.Perfect
	elseif releaseValue >= shotConfig.greenMin and releaseValue <= shotConfig.greenMax then
		return QUALITIES.Good
	elseif releaseValue >= shotConfig.yellowMin and releaseValue <= shotConfig.yellowMax then
		return QUALITIES.Close
	elseif releaseValue < shotConfig.greenMin then
		return QUALITIES.Early
	end

	return QUALITIES.Late
end

local function canQualityScore(quality)
	return quality == QUALITIES.Perfect or quality == QUALITIES.Good
end

local function getMissMessage(quality)
	if quality == QUALITIES.Close then
		return "Rim out - try again"
	elseif quality == QUALITIES.Early then
		return "Too early - short"
	elseif quality == QUALITIES.Late then
		return "Too late - long"
	end

	return "MISS - try again"
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
	self:_clearBall(player)
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

	local originalWalkSpeed = humanoid.WalkSpeed
	local originalJumpPower = humanoid.JumpPower
	local originalJumpHeight = humanoid.JumpHeight
	local originalUseJumpPower = humanoid.UseJumpPower
	local originalAutoRotate = humanoid.AutoRotate

	self:_lockShooter(rootPart, humanoid, station)

	self._nextShotId += 1
	local shotId = self._nextShotId
	local heldBall = self:_createHeldBall(player, station)
	self._activeShots[player] = {
		shotId = shotId,
		shotIndex = stationIndex,
		startedAt = now,
		chargeStartedAt = nil,
		humanoid = humanoid,
		rootPart = rootPart,
		station = station,
		heldBall = heldBall,
		originalWalkSpeed = originalWalkSpeed,
		originalJumpPower = originalJumpPower,
		originalJumpHeight = originalJumpHeight,
		originalUseJumpPower = originalUseJumpPower,
		originalAutoRotate = originalAutoRotate,
	}

	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.ShotStarted,
		shotId = shotId,
		shotIndex = requiredShot.index,
		nextShotIndex = progress.nextShotIndex,
		completedShotIndices = getCompletedShotIndices(progress),
		displayName = requiredShot.displayName,
		progressText = string.format("%d / %d", getCompletedShotCount(progress), #SHOTS),
		meterCycleDuration = requiredShot.meterCycleDuration,
		releaseTimeout = requiredShot.releaseTimeout,
		yellowMin = requiredShot.yellowMin,
		greenMin = requiredShot.greenMin,
		perfectMin = requiredShot.perfectMin,
		perfectMax = requiredShot.perfectMax,
		greenMax = requiredShot.greenMax,
		yellowMax = requiredShot.yellowMax,
		cameraCFrame = station.cameraCFrame,
	})
end

function BasketballService:_onClientCommand(player, payload)
	if typeof(payload) ~= "table" then
		return
	end

	if payload.action == BasketballConfig.Actions.BeginCharge then
		self:_beginCharge(player, payload)
	elseif payload.action == BasketballConfig.Actions.ReleaseShot then
		self:_releaseShot(player, payload)
	elseif payload.action == BasketballConfig.Actions.CancelShot then
		self:_endActiveShot(player, "Canceled")
	end
end

function BasketballService:_beginCharge(player, payload)
	local activeShot = self._activeShots[player]
	if not activeShot or activeShot.shotId ~= payload.shotId or activeShot.chargeStartedAt then
		return
	end

	if not self:_validateActiveShot(player, activeShot) then
		self:_endActiveShot(player, "Invalid")
		return
	end

	activeShot.chargeStartedAt = workspace:GetServerTimeNow()
end

function BasketballService:_releaseShot(player, payload)
	local activeShot = self._activeShots[player]
	if not activeShot or activeShot.shotId ~= payload.shotId then
		return
	end

	local shotConfig = getShotConfig(activeShot.shotIndex)
	local now = workspace:GetServerTimeNow()
	if not shotConfig or now - activeShot.startedAt > shotConfig.releaseTimeout + 1 then
		self:_missShot(player, activeShot.shotIndex, "Shot timed out")
		return
	end

	if not self:_validateActiveShot(player, activeShot) then
		self:_endActiveShot(player, "Invalid")
		return
	end

	local chargeStartedAt = activeShot.chargeStartedAt or activeShot.startedAt
	local heldDuration = math.max(now - chargeStartedAt, 0)
	local releaseValue = heldDuration < BasketballConfig.Scoring.MinHoldDuration and 0 or calculateMeterValue(heldDuration, shotConfig.meterCycleDuration)
	local quality = getShotQuality(shotConfig, releaseValue)
	local canScore = canQualityScore(quality)
	local ball, flightTime = self:_launchBall(player, activeShot, shotConfig, releaseValue, quality, canScore)

	self._activeShots[player] = nil
	activeShot.heldBall = nil
	self:_restoreShooter(activeShot)

	self._activeBalls[player] = {
		ball = ball,
		shotIndex = activeShot.shotIndex,
		shotId = activeShot.shotId,
		quality = quality,
		releaseValue = releaseValue,
		canScore = canScore,
		previousPosition = ball.Position,
		expiresAt = now + math.max(flightTime, shotConfig.flightTime or 0) + BasketballConfig.Ball.ScoreCheckDurationPadding,
	}

	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.ShotReleased,
		shotIndex = activeShot.shotIndex,
		shotId = activeShot.shotId,
		quality = quality,
		releaseValue = releaseValue,
		progressText = string.format("%d / %d", getCompletedShotCount(self:_getProgress(player)), #SHOTS),
	})
end

function BasketballService:_lockShooter(rootPart, humanoid, station)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = station.cframe

	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
end

function BasketballService:_restoreShooter(activeShot)
	local humanoid = activeShot and activeShot.humanoid
	local rootPart = activeShot and activeShot.rootPart

	if rootPart and rootPart.Parent then
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end

	if humanoid and humanoid.Parent then
		humanoid.AutoRotate = activeShot.originalAutoRotate
		humanoid.WalkSpeed = activeShot.originalWalkSpeed
		humanoid.UseJumpPower = activeShot.originalUseJumpPower
		humanoid.JumpPower = activeShot.originalJumpPower
		humanoid.JumpHeight = activeShot.originalJumpHeight
	end
end

function BasketballService:_validateActiveShot(player, activeShot)
	local rootPart, humanoid = getCharacterRootAndHumanoid(player)
	if not rootPart or not humanoid or humanoid.Health <= 0 or not self:_canUseStage6(player) then
		return false
	end

	return self:_isNearStation(rootPart.Position, activeShot.station)
end

function BasketballService:_createBasketball(player, ballName, position, anchored)
	local ball = Instance.new("Part")
	ball.Name = ballName
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(BasketballConfig.Ball.Size, BasketballConfig.Ball.Size, BasketballConfig.Ball.Size)
	ball.Color = Color3.fromRGB(226, 99, 36)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored = anchored
	ball.CanCollide = not anchored
	ball.CanTouch = false
	ball.TopSurface = Enum.SurfaceType.Smooth
	ball.BottomSurface = Enum.SurfaceType.Smooth
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.8, 0.45, 0.72, 1, 1)
	ball.Position = position
	ball.Parent = self._stage6.ballsFolder

	local attachment0 = Instance.new("Attachment")
	attachment0.Name = "TrailStart"
	attachment0.Position = Vector3.new(0, BasketballConfig.Ball.Size * 0.45, 0)
	attachment0.Parent = ball

	local attachment1 = Instance.new("Attachment")
	attachment1.Name = "TrailEnd"
	attachment1.Position = Vector3.new(0, -BasketballConfig.Ball.Size * 0.45, 0)
	attachment1.Parent = ball

	local trail = Instance.new("Trail")
	trail.Name = "ShotTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 190, 74), Color3.fromRGB(255, 91, 38))
	trail.Lifetime = 0.28
	trail.MinLength = 0.1
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Enabled = false
	trail.Parent = ball

	return ball
end

function BasketballService:_createHeldBall(player, station)
	return self:_createBasketball(player, BasketballConfig.Ball.NamePrefix .. tostring(player.UserId) .. "_Held", station.shotStartPosition, true)
end

function BasketballService:_launchBall(player, activeShot, shotConfig, releaseValue, quality, canScore)
	self:_clearBall(player)

	local rootPart = activeShot.rootPart
	local ball = activeShot.heldBall
	if not ball or not ball.Parent then
		ball = self:_createBasketball(player, BasketballConfig.Ball.NamePrefix .. tostring(player.UserId) .. "_" .. tostring(activeShot.shotId), activeShot.station.shotStartPosition, false)
	end

	if rootPart and rootPart.Parent then
		ball.Position = (rootPart.CFrame * CFrame.new(0, BasketballConfig.Ball.HoldHeight, -BasketballConfig.Ball.HoldForwardOffset)).Position
	end

	ball.Name = BasketballConfig.Ball.NamePrefix .. tostring(player.UserId) .. "_" .. tostring(activeShot.shotId)
	ball.Anchored = false
	ball.CanCollide = true
	ball.CanTouch = false

	local targetPosition = self:_getShotTarget(shotConfig, releaseValue, quality, canScore)
	local velocity, flightTime = calculateLaunchVelocity(ball.Position, targetPosition, shotConfig.arcHeight)
	ball.AssemblyLinearVelocity = velocity
	ball.AssemblyAngularVelocity = Vector3.new(-10, 3, 0)

	local trail = ball:FindFirstChild("ShotTrail")
	if trail then
		trail.Enabled = true
	end

	pcall(function()
		ball:SetNetworkOwner(nil)
	end)

	Debris:AddItem(ball, BasketballConfig.Ball.Lifetime)
	return ball, flightTime
end

function BasketballService:_getShotTarget(shotConfig, releaseValue, quality, canScore)
	local center = (shotConfig.perfectMin + shotConfig.perfectMax) / 2
	local timingDelta = releaseValue - center
	local sideOffset = timingDelta * BasketballConfig.Ball.SideErrorScale

	if quality == QUALITIES.Perfect then
		return self._stage6.shotTarget
	elseif canScore then
		return self._stage6.shotTarget + Vector3.new(sideOffset * 0.22, 0, 0)
	elseif quality == QUALITIES.Close and timingDelta < 0 then
		return self._stage6.hoopCenter + Vector3.new(sideOffset * 0.55, 0.25, 3.8)
	elseif quality == QUALITIES.Close then
		return self._stage6.hoopCenter + Vector3.new(sideOffset * 0.55, 1.2, -3.8)
	elseif timingDelta < 0 then
		local shortAmount = 7 + (math.abs(timingDelta) * BasketballConfig.Ball.EarlyShortScale)
		return self._stage6.hoopCenter + Vector3.new(sideOffset, -2.6, shortAmount)
	end

	local longAmount = 7 + (math.abs(timingDelta) * BasketballConfig.Ball.LateLongScale)
	return self._stage6.hoopCenter + Vector3.new(sideOffset, 3.2, -longAmount)
end

function BasketballService:_update()
	local now = workspace:GetServerTimeNow()
	local timedOutShots = {}
	local missedBalls = {}
	local scoredBalls = {}

	for player, activeShot in pairs(self._activeShots) do
		local shotConfig = getShotConfig(activeShot.shotIndex)
		if not shotConfig or not self:_canUseStage6(player) or now - activeShot.startedAt > shotConfig.releaseTimeout then
			table.insert(timedOutShots, {
				player = player,
				shotIndex = activeShot.shotIndex,
			})
		elseif activeShot.heldBall and activeShot.heldBall.Parent and activeShot.rootPart and activeShot.rootPart.Parent then
			activeShot.heldBall.Position = (activeShot.rootPart.CFrame * CFrame.new(0, BasketballConfig.Ball.HoldHeight, -BasketballConfig.Ball.HoldForwardOffset)).Position
		end
	end

	for player, ballState in pairs(self._activeBalls) do
		local ball = ballState.ball
		if not ball or not ball.Parent then
			table.insert(missedBalls, {
				player = player,
				shotIndex = ballState.shotIndex,
			})
		else
			local position = ball.Position
			local movingDown = ballState.previousPosition and position.Y < ballState.previousPosition.Y
			if ballState.canScore and movingDown and isInsidePart(self._stage6.scoringZone, position) then
				table.insert(scoredBalls, {
					player = player,
					shotIndex = ballState.shotIndex,
				})
			elseif now >= ballState.expiresAt then
				table.insert(missedBalls, {
					player = player,
					shotIndex = ballState.shotIndex,
				})
			else
				ballState.previousPosition = position
			end
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
	if ballState and ballState.ball and ballState.ball.Parent then
		Debris:AddItem(ballState.ball, 1.2)
	end

	local progress = self:_getProgress(player)
	progress.completedShots[shotIndex] = true
	progress.cooldownUntil = workspace:GetServerTimeNow() + BasketballConfig.Ball.ShotCooldown

	local shotConfig = getShotConfig(shotIndex)
	local nextShotIndex = shotIndex + 1
	progress.nextShotIndex = nextShotIndex
	local quality = ballState and ballState.quality
	local message = quality == QUALITIES.Perfect and ("PERFECT! SWISH! " .. shotConfig.displayName .. " Complete") or ("SWISH! " .. shotConfig.displayName .. " Complete")

	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.ShotScored,
		shotIndex = shotIndex,
		displayName = shotConfig.displayName,
		quality = quality,
		releaseValue = ballState and ballState.releaseValue,
		message = message,
		progressText = string.format("%d / %d", getCompletedShotCount(progress), #SHOTS),
		nextShotIndex = nextShotIndex,
		completedShotIndices = getCompletedShotIndices(progress),
	})

	if nextShotIndex > #SHOTS then
		progress.complete = true
		progress.nextShotIndex = #SHOTS + 1
		self._remote:FireClient(player, {
			type = BasketballConfig.Messages.Completed,
			message = "All shots made! CP 6 unlocked",
			doorVisual = self._stage6.doorVisual,
			nextShotIndex = progress.nextShotIndex,
			completedShotIndices = getCompletedShotIndices(progress),
		})
		self:_notifyPlayer(player, "CP 6 unlocked")
	else
		local nextShot = getShotConfig(nextShotIndex)
		self._remote:FireClient(player, {
			type = BasketballConfig.Messages.ProgressChanged,
			shotIndex = nextShot.index,
			nextShotIndex = nextShot.index,
			displayName = nextShot.displayName,
			progressText = string.format("%d / %d", getCompletedShotCount(progress), #SHOTS),
			completedShotIndices = getCompletedShotIndices(progress),
		})
	end
end

function BasketballService:_missShot(player, shotIndex, message)
	local activeShot = self._activeShots[player]
	if activeShot and activeShot.shotIndex == shotIndex then
		self._activeShots[player] = nil
		self:_restoreShooter(activeShot)
		self:_destroyBall(activeShot.heldBall)
	end

	local ballState = self._activeBalls[player]
	if ballState and ballState.shotIndex == shotIndex then
		self._activeBalls[player] = nil
		self:_destroyBall(ballState.ball)
	end

	local progress = self:_getProgress(player)
	progress.cooldownUntil = workspace:GetServerTimeNow() + BasketballConfig.Ball.ShotCooldown

	local shotConfig = getShotConfig(shotIndex)
	local quality = ballState and ballState.quality
	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.ShotMissed,
		shotIndex = shotIndex,
		displayName = shotConfig and shotConfig.displayName,
		quality = quality,
		releaseValue = ballState and ballState.releaseValue,
		message = message or getMissMessage(quality),
		progressText = string.format("%d / %d", getCompletedShotCount(progress), #SHOTS),
		nextShotIndex = progress.nextShotIndex,
		completedShotIndices = getCompletedShotIndices(progress),
	})
end

function BasketballService:_endActiveShot(player, reason)
	local activeShot = self._activeShots[player]
	if not activeShot then
		return
	end

	self._activeShots[player] = nil
	self:_restoreShooter(activeShot)
	self:_destroyBall(activeShot.heldBall)
	self._remote:FireClient(player, {
		type = BasketballConfig.Messages.ShotEnded,
		reason = reason or "Ended",
	})
end

function BasketballService:_clearBall(player)
	local ballState = self._activeBalls[player]
	self._activeBalls[player] = nil
	if ballState then
		self:_destroyBall(ballState.ball)
	end
end

function BasketballService:_destroyBall(ball)
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
