local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BuffService = require(script.Parent:WaitForChild("BuffService"))
local DevToolsConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DevToolsConfig"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local PlayerRunState = require(script.Parent:WaitForChild("PlayerRunState"))
local RcCarService = require(script.Parent:WaitForChild("RcCarService"))
local RewardService = require(script.Parent:WaitForChild("RewardService"))
local StageManager = require(script.Parent:WaitForChild("StageManager"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local RunManager = {}
RunManager.__index = RunManager

local RESPAWN_ENFORCE_HEARTBEATS = 8

local function now()
	return workspace:GetServerTimeNow()
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

local function applyCharacterTransform(rootPart, targetCFrame)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	rootPart.CFrame = targetCFrame
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

local function indexStagesByNumber(worldId)
	local stageByNumber = {}
	local world = WorldConfig.Worlds[worldId]
	if not world then
		return stageByNumber
	end

	for _, stage in ipairs(world.stages) do
		stageByNumber[stage.number] = stage
	end

	return stageByNumber
end

function RunManager.new(course)
	local remote = getOrCreateRemoteEvent(ObbyConfig.RemoteEventName)
	local devRemote = getOrCreateRemoteEvent(DevToolsConfig.RemoteEventName)
	local runState = PlayerRunState.new()
	local rewardService = RewardService.new(runState)
	local buffService = BuffService.new(runState)
	local stageManager = StageManager.new(runState, rewardService, buffService, remote)
	local rcCarService = RcCarService.new(course.stage4, runState, remote)

	return setmetatable({
		_course = course,
		_remote = remote,
		_devRemote = devRemote,
		_runState = runState,
		_rewardService = rewardService,
		_buffService = buffService,
		_stageManager = stageManager,
		_rcCarService = rcCarService,
		_stageByNumber = indexStagesByNumber(course.worldId),
		_bestTimes = {},
		_spawnTokens = {},
	}, RunManager)
end

function RunManager:start()
	Players.PlayerAdded:Connect(function(player)
		self:_setupPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._rcCarService:cleanupPlayer(player)
		self._runState:cleanupPlayer(player)
		self._bestTimes[player] = nil
		self._spawnTokens[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_setupPlayer(player)
	end

	self._course.startPad.Touched:Connect(function(hit)
		self:_onStartTouched(hit)
	end)

	if self._course.finishPad then
		self._course.finishPad.Touched:Connect(function(hit)
			self:_onFinishTouched(hit)
		end)
	end

	for _, checkpoint in ipairs(self._course.checkpoints) do
		checkpoint.part.Touched:Connect(function(hit)
			self:_onCheckpointTouched(checkpoint, hit)
		end)
	end

	for _, hazard in ipairs(self._course.hazards) do
		hazard.Touched:Connect(function(hit)
			self:_onHazardTouched(hit)
		end)
	end

	self._devRemote.OnServerEvent:Connect(function(player, payload)
		self:_onDevCommand(player, payload)
	end)

	self._rcCarService:start()
end

function RunManager:_setupPlayer(player)
	self._runState:setupPlayer(player)
	self._rewardService:setupPlayer(player)

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local bestTime = leaderstats:FindFirstChild("Best Time")
	if not bestTime then
		bestTime = Instance.new("NumberValue")
		bestTime.Name = "Best Time"
		bestTime.Value = 0
		bestTime.Parent = leaderstats
	end

	player.CharacterAdded:Connect(function(character)
		self:_watchCharacter(player, character)
	end)

	if player.Character then
		self:_watchCharacter(player, player.Character)
	end
end

function RunManager:_watchCharacter(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	if not humanoid then
		return
	end

	local spawnToken = (self._spawnTokens[player] or 0) + 1
	self._spawnTokens[player] = spawnToken

	if self._runState:isRunActive(player) then
		self._buffService:applyCurrentBuffs(player, character)
		task.defer(function()
			self:_teleportCharacterForActiveRun(player, character, spawnToken)
		end)
	else
		self._buffService:resetCharacter(player, character)
		task.defer(function()
			self:_teleportCharacterToStart(player, character, spawnToken)
		end)
	end

	humanoid.Died:Connect(function()
		self:_onCharacterDied(player)
	end)
end

function RunManager:_onStartTouched(hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 or self._runState:isRunActive(player) then
		return
	end

	local startTime = now()
	self._rcCarService:resetPlayer(player)
	local state = self._stageManager:startWorld(player, self._course.worldId, startTime)
	if not state then
		return
	end

	self._remote:FireClient(player, {
		type = "RunStarted",
		startTime = state.runStartTime,
		bestTime = self._bestTimes[player] or 0,
		sessionCoins = state.sessionCoins,
		coinsEarnedThisRun = state.coinsEarnedThisRun,
	})
end

function RunManager:_onCheckpointTouched(checkpoint, hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 then
		return
	end

	if checkpoint.requiresRcCompletion and not self._rcCarService:isStageComplete(player) then
		self._remote:FireClient(player, {
			type = "RcNotice",
			message = "Finish the RC maze first",
		})
		return
	end

	local result = self._stageManager:reachCheckpoint(player, checkpoint)
	if not result then
		return
	end

	self._remote:FireClient(player, {
		type = "CheckpointReached",
		checkpointIndex = result.checkpointIndex,
		coinAward = result.reward and result.reward.amount or 0,
		coinsEarnedThisRun = result.reward and result.reward.coinsEarnedThisRun or self._runState:get(player).coinsEarnedThisRun,
	})

	if checkpoint.completesStage then
		self._stageManager:completeStage(player, checkpoint.stageId or self._runState:get(player).currentStageId)
	end
end

function RunManager:_onFinishTouched(hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 then
		return
	end

	local state = self._runState:get(player)
	if not state.isRunActive then
		return
	end

	local elapsed = ObbyConfig.roundTime(now() - state.runStartTime)
	self._stageManager:completeStage(player, self._course.finishStageId or state.currentStageId, {
		advance = false,
	})
	local finalState = self._stageManager:finishRun(player)

	local currentBest = self._bestTimes[player]
	local isBest = not currentBest or elapsed < currentBest
	if isBest then
		self._bestTimes[player] = elapsed
		self:_setLeaderstatBest(player, elapsed)
	end

	self._remote:FireClient(player, {
		type = "RunFinished",
		elapsed = elapsed,
		bestTime = self._bestTimes[player] or elapsed,
		isBest = isBest,
		coinsEarnedThisRun = finalState.coinsEarnedThisRun,
		sessionCoins = finalState.sessionCoins,
	})
end

function RunManager:_onHazardTouched(hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 then
		return
	end

	humanoid.Health = 0
end

function RunManager:_onDevCommand(player, payload)
	if not self:_isDevControlsAllowed(player) or typeof(payload) ~= "table" then
		return
	end

	local action = payload.action
	if action == DevToolsConfig.Actions.JumpToStage then
		self:_jumpToStageForTesting(player, tonumber(payload.stageNumber))
	elseif action == DevToolsConfig.Actions.ResetRun then
		self:_resetRunFromDevTools(player)
	elseif action == DevToolsConfig.Actions.ReturnToStart then
		self:_returnToStartFromDevTools(player)
	end
end

function RunManager:_isDevControlsAllowed(player)
	if DevToolsConfig.EnabledInStudio and RunService:IsStudio() then
		return true
	end

	return DevToolsConfig.isUserIdAllowed(player.UserId)
end

function RunManager:_jumpToStageForTesting(player, stageNumber)
	if not stageNumber or stageNumber ~= math.floor(stageNumber) then
		return
	end

	local stageStart = self._course.stageStarts and self._course.stageStarts[stageNumber]
	local stage = self._stageByNumber[stageNumber]
	local world = WorldConfig.Worlds[self._course.worldId]
	if not stageStart or not stage or not world then
		return
	end

	self._rcCarService:resetPlayer(player)

	local activeBuffs = self:_getActiveBuffsBeforeStage(stageNumber)
	local activePassiveBuffIds = {}
	for _, buff in ipairs(activeBuffs) do
		table.insert(activePassiveBuffIds, buff.id)
	end

	local state = self._runState:configureTestRun(player, {
		worldId = self._course.worldId,
		stageId = stage.id,
		startTime = now(),
		latestCheckpoint = stageStart.latestCheckpoint,
		latestCheckpointId = stageStart.latestCheckpointId,
		completedStageIds = self:_getCompletedStageIdsBefore(stageNumber),
		rewardedCheckpointIds = self:_getCheckpointRewardIdsThrough(stageStart.latestCheckpoint or 0),
		activePassiveBuffIds = activePassiveBuffIds,
	})

	if player.Character then
		self._buffService:applyCurrentBuffs(player, player.Character)
	end

	self._remote:FireClient(player, {
		type = "WorldStarted",
		worldId = world.id,
		worldName = world.displayName,
		stageId = stage.id,
		stageNumber = stage.number,
		stageName = stage.name,
	})
	self._remote:FireClient(player, {
		type = "RunStarted",
		startTime = state.runStartTime,
		bestTime = self._bestTimes[player] or 0,
		sessionCoins = state.sessionCoins,
		coinsEarnedThisRun = state.coinsEarnedThisRun,
	})
	self._remote:FireClient(player, {
		type = "DevTeleported",
		message = string.format("Testing Stage %d", stageNumber),
		sessionCoins = state.sessionCoins,
	})

	for _, buff in ipairs(activeBuffs) do
		self._remote:FireClient(player, {
			type = "PassiveUnlocked",
			buffId = buff.id,
			displayName = buff.displayName,
			description = buff.description,
		})
	end

	self:_teleportCurrentCharacter(player, stageStart.cframe)
end

function RunManager:_resetRunFromDevTools(player)
	self._rcCarService:resetPlayer(player)
	local state = self._stageManager:resetRun(player)
	self:_teleportCurrentCharacter(player, self._course.startSpawnCFrame)
	self._remote:FireClient(player, {
		type = "RunReset",
		bestTime = self._bestTimes[player] or 0,
		sessionCoins = state.sessionCoins,
	})
end

function RunManager:_returnToStartFromDevTools(player)
	self._rcCarService:endSession(player, "Returned to start")
	local state = self._runState:get(player)
	self:_teleportCurrentCharacter(player, self._course.startSpawnCFrame)
	self._remote:FireClient(player, {
		type = "DevTeleported",
		message = "Returned to start",
		sessionCoins = state.sessionCoins,
	})
end

function RunManager:_getCompletedStageIdsBefore(stageNumber)
	local completedStageIds = {}
	for previousStageNumber = 1, stageNumber - 1 do
		local stage = self._stageByNumber[previousStageNumber]
		if stage then
			table.insert(completedStageIds, stage.id)
		end
	end

	return completedStageIds
end

function RunManager:_getCheckpointRewardIdsThrough(maxCheckpointIndex)
	local checkpointIds = {}
	for _, checkpoint in ipairs(self._course.checkpoints) do
		if checkpoint.index and checkpoint.index <= maxCheckpointIndex then
			table.insert(checkpointIds, checkpoint.id or string.format("%s_checkpoint_%d", checkpoint.stageId or "run", checkpoint.index))
		end
	end

	return checkpointIds
end

function RunManager:_getActiveBuffsBeforeStage(stageNumber)
	local activeBuffs = {}
	for previousStageNumber = 1, stageNumber - 1 do
		local buff = self._buffService:getBuffForCompletedStage(previousStageNumber)
		if buff then
			table.insert(activeBuffs, buff)
		end
	end

	return activeBuffs
end

function RunManager:_onCharacterDied(player)
	self._rcCarService:endSession(player, "Death")
	local state = self._runState:get(player)
	if not state.isRunActive then
		return
	end

	self._remote:FireClient(player, {
		type = "RunDeath",
		checkpointIndex = state.latestCheckpoint or 0,
	})
end

function RunManager:_teleportCharacterForActiveRun(player, character, spawnToken)
	task.wait()

	local state = self._runState:get(player)
	if not state.isRunActive or not self:_isCurrentCharacter(player, character, spawnToken) then
		return
	end

	self:_teleportCharacter(player, character, self:_getRespawnCFrame(state), spawnToken)
	self._remote:FireClient(player, {
		type = "RunRespawned",
		checkpointIndex = state.latestCheckpoint or 0,
	})
end

function RunManager:_teleportCharacterToStart(player, character, spawnToken)
	task.wait()

	if self._runState:isRunActive(player) or not self:_isCurrentCharacter(player, character, spawnToken) then
		return
	end

	self:_teleportCharacter(player, character, self._course.startSpawnCFrame, spawnToken)
end

function RunManager:_teleportCharacter(player, character, targetCFrame, spawnToken)
	if not targetCFrame then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	local originalAutoRotate = humanoid.AutoRotate
	local originalAnchored = rootPart.Anchored

	humanoid.AutoRotate = false
	rootPart.Anchored = true

	for _ = 1, RESPAWN_ENFORCE_HEARTBEATS do
		if not self:_isCurrentCharacter(player, character, spawnToken) or not humanoid.Parent or not rootPart.Parent or humanoid.Health <= 0 then
			break
		end

		applyCharacterTransform(rootPart, targetCFrame)
		RunService.Heartbeat:Wait()
	end

	if self:_isCurrentCharacter(player, character, spawnToken) and humanoid.Parent and rootPart.Parent and humanoid.Health > 0 then
		applyCharacterTransform(rootPart, targetCFrame)
		rootPart.Anchored = originalAnchored
	else
		if rootPart.Parent then
			rootPart.Anchored = originalAnchored
		end
	end

	task.defer(function()
		if humanoid.Parent then
			humanoid.AutoRotate = originalAutoRotate
		end
	end)
end

function RunManager:_isCurrentCharacter(player, character, spawnToken)
	return self._spawnTokens[player] == spawnToken and player.Character == character and character.Parent ~= nil
end

function RunManager:_getRespawnCFrame(state)
	local checkpointIndex = state.latestCheckpoint or 0
	if checkpointIndex > 0 then
		local checkpoint = self._course.checkpoints[checkpointIndex]
		if checkpoint then
			return checkpoint.respawnCFrame
		end
	end

	return self._course.startRespawnCFrame
end

function RunManager:_teleportCurrentCharacter(player, targetCFrame)
	if not targetCFrame then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not character or not humanoid or humanoid.Health <= 0 then
		task.spawn(function()
			player:LoadCharacter()
			local newCharacter = player.Character or player.CharacterAdded:Wait()
			task.wait()
			local newHumanoid = newCharacter and newCharacter:FindFirstChildOfClass("Humanoid")
			if newHumanoid and newHumanoid.Health > 0 then
				self:_teleportCurrentCharacter(player, targetCFrame)
			end
		end)

		return false
	end

	local spawnToken = (self._spawnTokens[player] or 0) + 1
	self._spawnTokens[player] = spawnToken
	self:_teleportCharacter(player, character, targetCFrame, spawnToken)
	return true
end

function RunManager:_setLeaderstatBest(player, elapsed)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local bestTime = leaderstats:FindFirstChild("Best Time")
	if bestTime then
		bestTime.Value = elapsed
	end
end

return RunManager
