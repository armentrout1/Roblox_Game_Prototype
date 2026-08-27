local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))

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

function RunManager.new(course)
	local remote = ReplicatedStorage:FindFirstChild(ObbyConfig.RemoteEventName)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = ObbyConfig.RemoteEventName
		remote.Parent = ReplicatedStorage
	end

	return setmetatable({
		_course = course,
		_remote = remote,
		_activeRuns = {},
		_bestTimes = {},
	}, RunManager)
end

function RunManager:start()
	Players.PlayerAdded:Connect(function(player)
		self:_setupPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self._activeRuns[player] = nil
		self._bestTimes[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:_setupPlayer(player)
	end

	self._course.startPad.Touched:Connect(function(hit)
		self:_onStartTouched(hit)
	end)

	self._course.finishPad.Touched:Connect(function(hit)
		self:_onFinishTouched(hit)
	end)

	for _, hazard in ipairs(self._course.hazards) do
		hazard.Touched:Connect(function(hit)
			self:_onHazardTouched(hit)
		end)
	end
end

function RunManager:_setupPlayer(player)
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

	humanoid.Died:Connect(function()
		self:_cancelRun(player)
	end)
end

function RunManager:_onStartTouched(hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 or self._activeRuns[player] then
		return
	end

	local startTime = now()
	self._activeRuns[player] = {
		startTime = startTime,
	}

	self._remote:FireClient(player, {
		type = "RunStarted",
		startTime = startTime,
		bestTime = self._bestTimes[player] or 0,
	})
end

function RunManager:_onFinishTouched(hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 then
		return
	end

	local run = self._activeRuns[player]
	if not run then
		return
	end

	local elapsed = ObbyConfig.roundTime(now() - run.startTime)
	self._activeRuns[player] = nil

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
	})
end

function RunManager:_onHazardTouched(hit)
	local player, humanoid = findPlayerFromHit(hit)
	if not player or humanoid.Health <= 0 then
		return
	end

	humanoid.Health = 0
	self:_cancelRun(player)
end

function RunManager:_cancelRun(player)
	if not self._activeRuns[player] then
		return
	end

	self._activeRuns[player] = nil
	self._remote:FireClient(player, {
		type = "RunCancelled",
	})
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
