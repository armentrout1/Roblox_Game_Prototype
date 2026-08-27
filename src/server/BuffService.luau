local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local BuffService = {}
BuffService.__index = BuffService

local BASE_WALK_SPEED = 16
local BASE_JUMP_POWER = 50

function BuffService.new(runState)
	return setmetatable({
		_runState = runState,
		_buffByStage = {},
		_buffById = {},
	}, BuffService):_indexBuffs()
end

function BuffService:_indexBuffs()
	for _, buff in ipairs(WorldConfig.ProgressiveBuffs) do
		self._buffByStage[buff.afterStage] = buff
		self._buffById[buff.id] = buff
	end

	return self
end

function BuffService:resetCharacter(player, character)
	self:_applyStats(character, 1, 1)
end

function BuffService:applyCurrentBuffs(player, character)
	local walkMultiplier = 1
	local jumpMultiplier = 1

	for _, buffId in ipairs(self._runState:getActiveBuffIds(player)) do
		local buff = self._buffById[buffId]
		local effects = buff and buff.effects
		if effects then
			walkMultiplier *= effects.walkSpeedMultiplier or 1
			jumpMultiplier *= effects.jumpPowerMultiplier or 1
		end
	end

	self:_applyStats(character, walkMultiplier, jumpMultiplier)
end

function BuffService:getBuffForCompletedStage(stageNumber)
	return self._buffByStage[stageNumber]
end

function BuffService:unlockForCompletedStage(player, stageNumber)
	local buff = self._buffByStage[stageNumber]
	if not buff then
		return nil
	end

	if not self._runState:addPassiveBuff(player, buff.id) then
		return nil
	end

	if player.Character then
		self:applyCurrentBuffs(player, player.Character)
	end

	return buff
end

function BuffService:_applyStats(character, walkMultiplier, jumpMultiplier)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	humanoid.WalkSpeed = BASE_WALK_SPEED * walkMultiplier
	humanoid.UseJumpPower = true
	humanoid.JumpPower = BASE_JUMP_POWER * jumpMultiplier
end

return BuffService
