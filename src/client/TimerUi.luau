local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local TimerUi = {}

local player = Players.LocalPlayer

local function createText(parent, name, text, size, position, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font or Enum.Font.GothamBold
	label.Position = position
	label.Size = size
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextScaled = true
	label.TextStrokeColor3 = ObbyConfig.Colors.Dark
	label.TextStrokeTransparency = 0.45
	label.Parent = parent

	return label
end

local function createHud()
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ObbyHud"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "TimerPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.BackgroundColor3 = ObbyConfig.Colors.Dark
	panel.BackgroundTransparency = 0.14
	panel.BorderSizePixel = 0
	panel.Position = UDim2.fromScale(0.5, 0.035)
	panel.Size = UDim2.fromOffset(430, 118)
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = ObbyConfig.Colors.Start
	stroke.Thickness = 2
	stroke.Transparency = 0.15
	stroke.Parent = panel

	local timerLabel = createText(panel, "TimerLabel", "Time 0.00s", UDim2.new(1, -24, 0, 42), UDim2.fromOffset(12, 8), ObbyConfig.Colors.White)
	local bestLabel = createText(panel, "BestLabel", "Best --", UDim2.new(0.5, -20, 0, 26), UDim2.fromOffset(16, 54), ObbyConfig.Colors.Finish)
	local coinsLabel = createText(panel, "CoinsLabel", "Coins 0", UDim2.new(0.5, -20, 0, 26), UDim2.new(0.5, 4, 0, 54), ObbyConfig.Colors.CheckpointAccent)
	local statusLabel = createText(panel, "StatusLabel", "Touch GO to start", UDim2.new(1, -32, 0, 26), UDim2.fromOffset(16, 82), ObbyConfig.Colors.Start)

	local winPanel = Instance.new("Frame")
	winPanel.Name = "WinPanel"
	winPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	winPanel.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	winPanel.BackgroundTransparency = 0.08
	winPanel.BorderSizePixel = 0
	winPanel.Position = UDim2.fromScale(0.5, 0.45)
	winPanel.Size = UDim2.fromOffset(430, 210)
	winPanel.Visible = false
	winPanel.Parent = screenGui

	local winCorner = Instance.new("UICorner")
	winCorner.CornerRadius = UDim.new(0, 14)
	winCorner.Parent = winPanel

	local winStroke = Instance.new("UIStroke")
	winStroke.Color = ObbyConfig.Colors.Finish
	winStroke.Thickness = 3
	winStroke.Parent = winPanel

	createText(winPanel, "WinTitle", "You Win!", UDim2.new(1, -32, 0, 64), UDim2.fromOffset(16, 18), ObbyConfig.Colors.Finish)
	local winTime = createText(winPanel, "WinTime", "Time 0.00s", UDim2.new(1, -32, 0, 46), UDim2.fromOffset(16, 88), ObbyConfig.Colors.White)
	local winBest = createText(winPanel, "WinBest", "Best --", UDim2.new(1, -32, 0, 38), UDim2.fromOffset(16, 140), ObbyConfig.Colors.Start)
	local winCoins = createText(winPanel, "WinCoins", "Run coins 0", UDim2.new(1, -32, 0, 26), UDim2.fromOffset(16, 176), ObbyConfig.Colors.CheckpointAccent)

	return {
		timerLabel = timerLabel,
		bestLabel = bestLabel,
		coinsLabel = coinsLabel,
		statusLabel = statusLabel,
		winPanel = winPanel,
		winTime = winTime,
		winBest = winBest,
		winCoins = winCoins,
	}
end

function TimerUi.start()
	local remote = ReplicatedStorage:WaitForChild(ObbyConfig.RemoteEventName)
	local hud = createHud()

	local running = false
	local startTime = 0
	local bestTime = 0
	local sessionCoins = 0
	local statusToken = 0

	local function setBest(value)
		bestTime = value or bestTime
		hud.bestLabel.Text = "Best " .. ObbyConfig.formatBestTime(bestTime)
	end

	local function setCoins(value)
		sessionCoins = value or sessionCoins
		hud.coinsLabel.Text = "Coins " .. tostring(sessionCoins)
	end

	local function setStatus(text, color)
		statusToken = statusToken + 1
		hud.statusLabel.Text = text
		hud.statusLabel.TextColor3 = color or ObbyConfig.Colors.Start
	end

	local function flashStatus(text, color, duration)
		statusToken = statusToken + 1
		local token = statusToken
		hud.statusLabel.Text = text
		hud.statusLabel.TextColor3 = color

		task.delay(duration, function()
			if running and statusToken == token then
				hud.statusLabel.Text = "Run!"
				hud.statusLabel.TextColor3 = ObbyConfig.Colors.Start
			end
		end)
	end

	RunService.RenderStepped:Connect(function()
		if running then
			local elapsed = workspace:GetServerTimeNow() - startTime
			hud.timerLabel.Text = "Time " .. ObbyConfig.formatTime(elapsed)
		end
	end)

	remote.OnClientEvent:Connect(function(payload)
		if payload.type == "RunStarted" then
			running = true
			startTime = payload.startTime
			hud.timerLabel.Text = "Time 0.00s"
			setStatus("Run!", ObbyConfig.Colors.Start)
			hud.winPanel.Visible = false
			setBest(payload.bestTime)
			setCoins(payload.sessionCoins)
		elseif payload.type == "CoinAwarded" then
			setCoins(payload.sessionCoins)
			if running then
				flashStatus(string.format("+%d coins", payload.amount), ObbyConfig.Colors.CheckpointAccent, 1)
			end
		elseif payload.type == "CheckpointReached" then
			if running then
				local text = string.format("Checkpoint %d!", payload.checkpointIndex)
				if payload.coinAward and payload.coinAward > 0 then
					text = text .. string.format(" +%d coins", payload.coinAward)
				end
				flashStatus(text, ObbyConfig.Colors.Checkpoint, 1.25)
			end
		elseif payload.type == "RunDeath" then
			if running then
				flashStatus("Respawning...", ObbyConfig.Colors.Lava, 1.5)
			end
		elseif payload.type == "RunRespawned" then
			if running then
				local message = payload.checkpointIndex > 0 and string.format("Back to checkpoint %d", payload.checkpointIndex) or "Back to start"
				flashStatus(message, ObbyConfig.Colors.CheckpointAccent, 1.25)
			end
		elseif payload.type == "StageCompleted" then
			if running then
				flashStatus(string.format("Stage %d complete!", payload.stageNumber), ObbyConfig.Colors.Finish, 1.25)
			end
		elseif payload.type == "StageStarted" then
			if running then
				flashStatus(string.format("Stage %d next", payload.stageNumber), ObbyConfig.Colors.Start, 1.5)
			end
		elseif payload.type == "PassiveUnlocked" then
			if running then
				flashStatus(payload.displayName .. " unlocked!", ObbyConfig.Colors.CheckpointAccent, 1.5)
			end
		elseif payload.type == "WorldCompleted" then
			if running then
				flashStatus("World complete!", ObbyConfig.Colors.Finish, 1.5)
			end
		elseif payload.type == "RunFinished" then
			running = false
			setBest(payload.bestTime)
			setCoins(payload.sessionCoins)

			local elapsedText = ObbyConfig.formatTime(payload.elapsed)
			hud.timerLabel.Text = "Time " .. elapsedText
			setStatus(payload.isBest and "New best!" or "Finished", payload.isBest and ObbyConfig.Colors.Finish or ObbyConfig.Colors.Start)
			hud.winTime.Text = "Time " .. elapsedText
			hud.winBest.Text = "Best " .. ObbyConfig.formatBestTime(bestTime)
			hud.winCoins.Text = "Run coins " .. tostring(payload.coinsEarnedThisRun or 0)
			hud.winPanel.Visible = true
		end
	end)
end

return TimerUi
