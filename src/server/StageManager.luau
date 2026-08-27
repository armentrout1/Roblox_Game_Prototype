local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local StageManager = {}
StageManager.__index = StageManager

function StageManager.new(runState, rewardService, buffService, remote)
	return setmetatable({
		_runState = runState,
		_rewardService = rewardService,
		_buffService = buffService,
		_remote = remote,
		_stageById = {},
		_nextStageById = {},
	}, StageManager):_indexWorlds()
end

function StageManager:_indexWorlds()
	for _, world in pairs(WorldConfig.Worlds) do
		for stageIndex, stage in ipairs(world.stages) do
			self._stageById[stage.id] = {
				world = world,
				stage = stage,
				index = stageIndex,
			}

			local nextStage = world.stages[stageIndex + 1]
			if nextStage then
				self._nextStageById[stage.id] = nextStage.id
			end
		end
	end

	return self
end

function StageManager:startWorld(player, worldId, startTime)
	local world = WorldConfig.Worlds[worldId]
	if not world then
		return nil
	end

	local firstStage = world.stages[1]
	if not firstStage then
		return nil
	end

	local state = self._runState:startRun(player, worldId, firstStage.id, startTime)
	if player.Character then
		self._buffService:resetCharacter(player, player.Character)
	end

	self:_fireClient(player, {
		type = "WorldStarted",
		worldId = world.id,
		worldName = world.displayName,
		stageId = firstStage.id,
		stageNumber = firstStage.number,
		stageName = firstStage.name,
	})

	return state
end

function StageManager:startStage(player, stageId)
	local stageInfo = self._stageById[stageId]
	if not stageInfo or not self._runState:isRunActive(player) then
		return nil
	end

	local state = self._runState:setCurrentStage(player, stageId)
	self:_fireClient(player, {
		type = "StageStarted",
		stageId = stageId,
		stageNumber = stageInfo.stage.number,
		stageName = stageInfo.stage.name,
	})

	return state
end

function StageManager:reachCheckpoint(player, checkpoint)
	local state = self._runState:get(player)
	if not state.isRunActive then
		return nil
	end

	local checkpointOrder = checkpoint.order or checkpoint.index
	local checkpointStageId = checkpoint.stageId or state.currentStageId or state.currentWorldId or "run"
	local checkpointKey = checkpoint.id or string.format("%s_checkpoint_%d", checkpointStageId, checkpoint.index)
	if checkpointOrder <= (state.latestCheckpoint or 0) then
		return nil
	end

	if checkpoint.stageId and checkpoint.stageId ~= state.currentStageId then
		return nil
	end

	self._runState:setLatestCheckpoint(player, checkpointOrder, checkpointKey)
	local reward = self._rewardService:awardCheckpoint(player, checkpointKey)

	if reward then
		self:_fireClient(player, {
			type = "CoinAwarded",
			amount = reward.amount,
			reason = reward.reason,
			sessionCoins = reward.sessionCoins,
			coinsEarnedThisRun = reward.coinsEarnedThisRun,
		})
	end

	return {
		checkpointIndex = checkpoint.index,
		checkpointId = checkpointKey,
		reward = reward,
	}
end

function StageManager:completeStage(player, stageId, options)
	local state = self._runState:get(player)
	local targetStageId = stageId or state.currentStageId
	local stageInfo = targetStageId and self._stageById[targetStageId]
	if not state.isRunActive or not stageInfo then
		return nil
	end

	if not self._runState:markStageCompleted(player, targetStageId) then
		return {
			stageId = targetStageId,
			duplicate = true,
		}
	end

	local buff = self._buffService:unlockForCompletedStage(player, stageInfo.stage.number)
	local nextStageId = self._nextStageById[targetStageId]
	local shouldAdvance = not options or options.advance ~= false

	self:_fireClient(player, {
		type = "StageCompleted",
		stageId = targetStageId,
		stageNumber = stageInfo.stage.number,
		stageName = stageInfo.stage.name,
		nextStageId = nextStageId,
	})

	if buff then
		self:_fireClient(player, {
			type = "PassiveUnlocked",
			buffId = buff.id,
			displayName = buff.displayName,
			description = buff.description,
		})
	end

	if nextStageId and shouldAdvance then
		self:startStage(player, nextStageId)
	elseif not nextStageId then
		return self:completeWorld(player, stageInfo.world.id, {
			stageId = targetStageId,
			stageNumber = stageInfo.stage.number,
			stageName = stageInfo.stage.name,
			buff = buff,
		})
	end

	return {
		stageId = targetStageId,
		stageNumber = stageInfo.stage.number,
		stageName = stageInfo.stage.name,
		nextStageId = nextStageId,
		buff = buff,
	}
end

function StageManager:completeWorld(player, worldId, stageResult)
	local state = self._runState:get(player)
	if not state.isRunActive then
		return nil
	end

	local reward = self._rewardService:awardWorldCompletion(player, worldId)
	if reward then
		self:_fireClient(player, {
			type = "CoinAwarded",
			amount = reward.amount,
			reason = reward.reason,
			sessionCoins = reward.sessionCoins,
			coinsEarnedThisRun = reward.coinsEarnedThisRun,
		})
	end

	self:_fireClient(player, {
		type = "WorldCompleted",
		worldId = worldId,
		reward = reward,
	})

	return {
		worldId = worldId,
		worldCompleted = true,
		reward = reward,
		stageResult = stageResult,
	}
end

function StageManager:finishRun(player)
	local state = self._runState:finishRun(player)
	if player.Character then
		self._buffService:resetCharacter(player, player.Character)
	end

	return state
end

function StageManager:resetRun(player)
	local state = self._runState:resetRun(player)
	if player.Character then
		self._buffService:resetCharacter(player, player.Character)
	end

	return state
end

function StageManager:_fireClient(player, payload)
	if self._remote then
		self._remote:FireClient(player, payload)
	end
end

return StageManager
