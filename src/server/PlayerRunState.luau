local PlayerRunState = {}
PlayerRunState.__index = PlayerRunState

local DEFAULT_BONUS_LIVES = 0

local function createState(player)
	return {
		player = player,
		isRunActive = false,
		currentWorldId = nil,
		currentStageId = nil,
		latestCheckpoint = 0,
		latestCheckpointId = nil,
		checkpointsRewardedThisRun = {},
		stagesCompletedThisRun = {},
		worldCompletionRewarded = false,
		runStartTime = 0,
		coinsEarnedThisRun = 0,
		sessionCoins = 0,
		activePassiveBuffs = {},
		remainingLives = DEFAULT_BONUS_LIVES,
		bonusLives = DEFAULT_BONUS_LIVES,
	}
end

function PlayerRunState.new()
	return setmetatable({
		_states = {},
	}, PlayerRunState)
end

function PlayerRunState:setupPlayer(player)
	local state = self._states[player]
	if not state then
		state = createState(player)
		self._states[player] = state
	end

	return state
end

function PlayerRunState:cleanupPlayer(player)
	self._states[player] = nil
end

function PlayerRunState:get(player)
	return self._states[player] or self:setupPlayer(player)
end

function PlayerRunState:isRunActive(player)
	return self:get(player).isRunActive
end

function PlayerRunState:startRun(player, worldId, stageId, startTime)
	local state = self:get(player)
	state.isRunActive = true
	state.currentWorldId = worldId
	state.currentStageId = stageId
	state.latestCheckpoint = 0
	state.latestCheckpointId = nil
	state.checkpointsRewardedThisRun = {}
	state.stagesCompletedThisRun = {}
	state.worldCompletionRewarded = false
	state.runStartTime = startTime
	state.coinsEarnedThisRun = 0
	state.activePassiveBuffs = {}
	state.remainingLives = state.bonusLives or DEFAULT_BONUS_LIVES

	return state
end

function PlayerRunState:configureTestRun(player, options)
	local state = self:get(player)
	state.isRunActive = true
	state.currentWorldId = options.worldId
	state.currentStageId = options.stageId
	state.latestCheckpoint = options.latestCheckpoint or 0
	state.latestCheckpointId = options.latestCheckpointId
	state.checkpointsRewardedThisRun = {}
	state.stagesCompletedThisRun = {}
	state.worldCompletionRewarded = false
	state.runStartTime = options.startTime or 0
	state.coinsEarnedThisRun = 0
	state.activePassiveBuffs = {}
	state.remainingLives = state.bonusLives or DEFAULT_BONUS_LIVES

	for _, checkpointId in ipairs(options.rewardedCheckpointIds or {}) do
		state.checkpointsRewardedThisRun[checkpointId] = true
	end

	for _, stageId in ipairs(options.completedStageIds or {}) do
		state.stagesCompletedThisRun[stageId] = true
	end

	for _, buffId in ipairs(options.activePassiveBuffIds or {}) do
		state.activePassiveBuffs[buffId] = true
	end

	return state
end

function PlayerRunState:finishRun(player)
	local state = self:get(player)
	state.isRunActive = false
	state.currentStageId = nil
	state.latestCheckpoint = 0
	state.latestCheckpointId = nil
	state.checkpointsRewardedThisRun = {}
	state.stagesCompletedThisRun = {}
	state.worldCompletionRewarded = false
	state.activePassiveBuffs = {}
	state.remainingLives = state.bonusLives or DEFAULT_BONUS_LIVES

	return state
end

function PlayerRunState:resetRun(player)
	local state = self:finishRun(player)
	state.currentWorldId = nil
	state.runStartTime = 0
	state.coinsEarnedThisRun = 0

	return state
end

function PlayerRunState:setCurrentStage(player, stageId)
	local state = self:get(player)
	state.currentStageId = stageId
	return state
end

function PlayerRunState:setLatestCheckpoint(player, checkpointIndex, checkpointId)
	local state = self:get(player)
	state.latestCheckpoint = checkpointIndex or 0
	state.latestCheckpointId = checkpointId
	return state
end

function PlayerRunState:markCheckpointRewarded(player, checkpointKey)
	local state = self:get(player)
	if state.checkpointsRewardedThisRun[checkpointKey] then
		return false
	end

	state.checkpointsRewardedThisRun[checkpointKey] = true
	return true
end

function PlayerRunState:markStageCompleted(player, stageId)
	local state = self:get(player)
	if state.stagesCompletedThisRun[stageId] then
		return false
	end

	state.stagesCompletedThisRun[stageId] = true
	return true
end

function PlayerRunState:isStageCompleted(player, stageId)
	return self:get(player).stagesCompletedThisRun[stageId] == true
end

function PlayerRunState:markWorldCompletionRewarded(player)
	local state = self:get(player)
	if state.worldCompletionRewarded then
		return false
	end

	state.worldCompletionRewarded = true
	return true
end

function PlayerRunState:addCoins(player, amount)
	local state = self:get(player)
	state.coinsEarnedThisRun += amount
	state.sessionCoins += amount
	return state
end

function PlayerRunState:addPassiveBuff(player, buffId)
	local state = self:get(player)
	if state.activePassiveBuffs[buffId] then
		return false
	end

	state.activePassiveBuffs[buffId] = true
	return true
end

function PlayerRunState:getActiveBuffIds(player)
	local buffIds = {}
	for buffId in pairs(self:get(player).activePassiveBuffs) do
		table.insert(buffIds, buffId)
	end

	return buffIds
end

return PlayerRunState
