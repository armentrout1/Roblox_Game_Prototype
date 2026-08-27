local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BuffService = require(script.Parent:WaitForChild("BuffService"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local PlayerRunState = require(script.Parent:WaitForChild("PlayerRunState"))
local RewardService = require(script.Parent:WaitForChild("RewardService"))
local StageManager = require(script.Parent:WaitForChild("StageManager"))

local RunManager = {}
RunManager.__index = RunManager

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

local function applyCharacterTransform(character, rootPart, targetCFrame)
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
	character:PivotTo(targetCFrame)
end

function RunManager.new(course)
	local remote = ReplicatedStorage:FindFirstChild(ObbyConfig.RemoteEventName)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = ObbyConfig.RemoteEventName
		remote.Parent = ReplicatedStorage
	end

	local runState = PlayerRunState.new()
	local rewardService = RewardService.new(runState)
	local buffService = BuffService.new(runState)
	local stageManager = StageManager.new(runState, rewardService, buffService, remote)

	return setmetatable({
		_course = course,
		_remote = remote,
		_runState = runState,
		_rewardService = rewardService,
		_buffService = buffService,
		_stageManager = stageManager,
		_bestTimes = {},
	}, RunManager)
end

function RunManager:start()
	Players.PlayerAdded:Connect(function(player)
		self:_setupPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._runState:cleanupPlayer(player)
		self._bestTimes[player] = nil
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

	if self._runState:isRunActive(player) then
		self._buffService:applyCurrentBuffs(player, character)
		task.defer(function()
			self:_teleportCharacterForActiveRun(player, character)
		end)
	else
		self._buffService:resetCharacter(player, character)
		task.defer(function()
			self:_teleportCharacterToStart(player, character)
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

function RunManager:_onCharacterDied(player)
	local state = self._runState:get(player)
	if not state.isRunActive then
		return
	end

	self._remote:FireClient(player, {
		type = "RunDeath",
		checkpointIndex = state.latestCheckpoint or 0,
	})
end

function RunManager:_teleportCharacterForActiveRun(player, character)
	task.wait()

	local state = self._runState:get(player)
	if not state.isRunActive then
		return
	end

	self:_teleportCharacter(character, self:_getRespawnCFrame(state))
	self._remote:FireClient(player, {
		type = "RunRespawned",
		checkpointIndex = state.latestCheckpoint or 0,
	})
end

function RunManager:_teleportCharacterToStart(player, character)
	task.wait()

	if self._runState:isRunActive(player) then
		return
	end

	self:_teleportCharacter(character, self._course.startSpawnCFrame)
end

function RunManager:_teleportCharacter(character, targetCFrame)
	if not targetCFrame then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not rootPart or humanoid.Health <= 0 then
		return
	end

	local originalAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false
	applyCharacterTransform(character, rootPart, targetCFrame)

	RunService.Heartbeat:Wait()
	if not character.Parent or not humanoid.Parent or not rootPart.Parent or humanoid.Health <= 0 then
		return
	end

	-- Apply once more after Roblox's spawn placement settles so the intended facing wins deterministically.
	applyCharacterTransform(character, rootPart, targetCFrame)
	task.defer(function()
		if humanoid.Parent then
			humanoid.AutoRotate = originalAutoRotate
		end
	end)
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
