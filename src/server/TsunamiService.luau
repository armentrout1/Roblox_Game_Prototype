local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local TsunamiConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TsunamiConfig"))

local TsunamiService = {}
TsunamiService.__index = TsunamiService

local PHASES = TsunamiConfig.Phases

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

function TsunamiService.new(stage5Data, runState, remote)
	return setmetatable({
		_stage5 = stage5Data,
		_runState = runState,
		_remote = remote,
		_phase = PHASES.Idle,
		_phaseStartedAt = 0,
		_lastCountdownSecond = nil,
		_waveX = TsunamiConfig.Wave.ParkX,
	}, TsunamiService)
end

function TsunamiService:start()
	if not self._stage5 then
		return
	end

	self:_parkWave()

	RunService.Heartbeat:Connect(function()
		self:_update()
	end)
end

function TsunamiService:cleanupPlayer(_player)
	-- Stage 5 currently has no per-player tsunami state; run state owns progression.
end

function TsunamiService:_update()
	local stagePlayers = self:_getStagePlayers()
	if #stagePlayers == 0 then
		if self._phase ~= PHASES.Idle then
			self._phase = PHASES.Idle
			self:_parkWave()
		end
		return
	end

	if self._phase == PHASES.Idle then
		self:_beginPhase(PHASES.Run, stagePlayers)
		return
	end

	local elapsed = workspace:GetServerTimeNow() - self._phaseStartedAt

	if self._phase == PHASES.Run then
		if elapsed >= TsunamiConfig.Timing.Run then
			self:_beginPhase(PHASES.Warning, stagePlayers)
		end
	elseif self._phase == PHASES.Warning then
		self:_updateCountdown(elapsed, stagePlayers)
		if elapsed >= TsunamiConfig.Timing.Warning then
			self:_beginPhase(PHASES.Wave, stagePlayers)
		end
	elseif self._phase == PHASES.Wave then
		local alpha = math.clamp(elapsed / TsunamiConfig.Timing.Wave, 0, 1)
		self:_moveWave(alpha)
		self:_damageUnsafePlayers(stagePlayers)

		if elapsed >= TsunamiConfig.Timing.Wave then
			self:_beginPhase(PHASES.Recovery, stagePlayers)
		end
	elseif self._phase == PHASES.Recovery and elapsed >= TsunamiConfig.Timing.Recovery then
		self:_beginPhase(PHASES.Run, stagePlayers)
	end
end

function TsunamiService:_beginPhase(phase, players)
	self._phase = phase
	self._phaseStartedAt = workspace:GetServerTimeNow()
	self._lastCountdownSecond = nil

	if phase == PHASES.Run then
		self:_parkWave()
		self:_fireToPlayers(players, {
			type = TsunamiConfig.RemoteTypes.Phase,
			stageId = self._stage5.stageId,
			phase = phase,
			message = "Run to the next safe slot!",
			duration = TsunamiConfig.Ui.RunMessageDuration,
		})
	elseif phase == PHASES.Warning then
		self:_moveWave(0)
		self:_fireToPlayers(players, {
			type = TsunamiConfig.RemoteTypes.Phase,
			stageId = self._stage5.stageId,
			phase = phase,
			message = "GET TO SAFETY!",
			duration = TsunamiConfig.Timing.Warning,
		})
		self:_updateCountdown(0, players)
	elseif phase == PHASES.Wave then
		self:_moveWave(0)
		self:_fireToPlayers(players, {
			type = TsunamiConfig.RemoteTypes.Phase,
			stageId = self._stage5.stageId,
			phase = phase,
			message = "TSUNAMI!",
			duration = TsunamiConfig.Timing.Wave,
		})
	elseif phase == PHASES.Recovery then
		self:_parkWave()
		self:_fireToPlayers(players, {
			type = TsunamiConfig.RemoteTypes.Phase,
			stageId = self._stage5.stageId,
			phase = phase,
			message = "Wave passed!",
			duration = TsunamiConfig.Ui.RecoveryMessageDuration,
		})
	end
end

function TsunamiService:_updateCountdown(elapsed, players)
	local remaining = math.max(1, math.ceil(TsunamiConfig.Timing.Warning - elapsed))
	if remaining == self._lastCountdownSecond then
		return
	end

	self._lastCountdownSecond = remaining
	self:_fireToPlayers(players, {
		type = TsunamiConfig.RemoteTypes.Countdown,
		stageId = self._stage5.stageId,
		seconds = remaining,
		message = string.format("TSUNAMI IN %d...", remaining),
	})
end

function TsunamiService:_moveWave(alpha)
	local waveConfig = TsunamiConfig.Wave
	local x = waveConfig.StartX + ((waveConfig.EndX - waveConfig.StartX) * alpha)
	self._waveX = x
	self:_setWaveCFrame(CFrame.new(x, waveConfig.CenterY, waveConfig.CenterZ))
end

function TsunamiService:_parkWave()
	local waveConfig = TsunamiConfig.Wave
	self._waveX = waveConfig.ParkX
	self:_setWaveCFrame(CFrame.new(waveConfig.ParkX, waveConfig.CenterY, waveConfig.CenterZ))
end

function TsunamiService:_setWaveCFrame(cframe)
	if self._stage5.waveModel and self._stage5.waveModel.Parent then
		self._stage5.waveModel:PivotTo(cframe)
	end
end

function TsunamiService:_damageUnsafePlayers(players)
	for _, player in ipairs(players) do
		local rootPart, humanoid = getCharacterRootAndHumanoid(player)
		if rootPart and humanoid and humanoid.Health > 0 and self:_isInsideStageBounds(rootPart.Position) then
			if not self:_isPlayerSafe(rootPart.Position) and self:_isWaveTouching(rootPart.Position) then
				self:_fireToPlayers({ player }, {
					type = TsunamiConfig.RemoteTypes.Hit,
					stageId = self._stage5.stageId,
					message = "Caught by the tsunami!",
				})
				humanoid.Health = 0
			end
		end
	end
end

function TsunamiService:_isPlayerSafe(position)
	for _, safeZone in ipairs(self._stage5.safeZones or {}) do
		if safeZone.Parent and isInsidePart(safeZone, position) then
			return true
		end
	end

	return false
end

function TsunamiService:_isWaveTouching(position)
	return math.abs(position.X - self._waveX) <= (TsunamiConfig.Wave.KillWidth / 2)
end

function TsunamiService:_isInsideStageBounds(position)
	local bounds = self._stage5.bounds
	return position.X >= bounds.MinX
		and position.X <= bounds.MaxX
		and position.Y >= bounds.MinY
		and position.Y <= bounds.MaxY
		and position.Z >= bounds.MinZ
		and position.Z <= bounds.MaxZ
end

function TsunamiService:_getStagePlayers()
	local players = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if self:_isPlayerInStage(player) then
			table.insert(players, player)
		end
	end

	return players
end

function TsunamiService:_isPlayerInStage(player)
	local state = self._runState:get(player)
	if not state.isRunActive or state.currentStageId ~= self._stage5.stageId then
		return false
	end

	local rootPart, humanoid = getCharacterRootAndHumanoid(player)
	return rootPart ~= nil and humanoid ~= nil and humanoid.Health > 0 and self:_isInsideStageBounds(rootPart.Position)
end

function TsunamiService:_fireToPlayers(players, payload)
	if not self._remote then
		return
	end

	for _, player in ipairs(players or {}) do
		self._remote:FireClient(player, payload)
	end
end

return TsunamiService
