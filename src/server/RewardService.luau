local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local RewardService = {}
RewardService.__index = RewardService

function RewardService.new(runState)
	return setmetatable({
		_runState = runState,
	}, RewardService)
end

function RewardService:setupPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = self._runState:get(player).sessionCoins
		coins.Parent = leaderstats
	end
end

function RewardService:awardCheckpoint(player, checkpointKey)
	if not self._runState:isRunActive(player) then
		return nil
	end

	if not self._runState:markCheckpointRewarded(player, checkpointKey) then
		return nil
	end

	return self:_awardCoins(player, WorldConfig.Rewards.CheckpointCoins, "checkpoint", checkpointKey)
end

function RewardService:awardWorldCompletion(player, worldId)
	if not self._runState:isRunActive(player) then
		return nil
	end

	if not self._runState:markWorldCompletionRewarded(player) then
		return nil
	end

	return self:_awardCoins(player, WorldConfig.Rewards.WorldCompletionCoins, "world_complete", worldId)
end

function RewardService:_awardCoins(player, amount, reason, sourceId)
	local state = self._runState:addCoins(player, amount)
	self:_updateCoinsLeaderstat(player, state.sessionCoins)

	return {
		amount = amount,
		reason = reason,
		sourceId = sourceId,
		sessionCoins = state.sessionCoins,
		coinsEarnedThisRun = state.coinsEarnedThisRun,
	}
end

function RewardService:_updateCoinsLeaderstat(player, value)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins then
		coins.Value = value
	end
end

return RewardService
