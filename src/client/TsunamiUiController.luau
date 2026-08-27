local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local TsunamiConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TsunamiConfig"))

local TsunamiUiController = {}

local player = Players.LocalPlayer

local started = false
local hud = nil
local visibleToken = 0
local onStageFive = false

local function createHud()
	local playerGui = player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("TsunamiHud")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TsunamiHud"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.BackgroundColor3 = Color3.fromRGB(18, 35, 48)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Position = UDim2.fromScale(0.5, 0.17)
	panel.Size = UDim2.fromOffset(430, 82)
	panel.Visible = false
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(72, 202, 255)
	stroke.Thickness = 3
	stroke.Transparency = 0.12
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Position = UDim2.fromOffset(16, 10)
	title.Size = UDim2.new(1, -32, 0, 32)
	title.Text = "TSUNAMI RUN"
	title.TextColor3 = ObbyConfig.Colors.White
	title.TextScaled = true
	title.TextStrokeColor3 = ObbyConfig.Colors.Dark
	title.TextStrokeTransparency = 0.35
	title.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Position = UDim2.fromOffset(16, 46)
	subtitle.Size = UDim2.new(1, -32, 0, 24)
	subtitle.Text = "Run to the green safe slot!"
	subtitle.TextColor3 = Color3.fromRGB(200, 244, 255)
	subtitle.TextScaled = true
	subtitle.TextStrokeColor3 = ObbyConfig.Colors.Dark
	subtitle.TextStrokeTransparency = 0.5
	subtitle.Parent = panel

	return {
		panel = panel,
		stroke = stroke,
		title = title,
		subtitle = subtitle,
	}
end

local function hide()
	visibleToken += 1
	if hud then
		hud.panel.Visible = false
	end
end

local function show(message, subtitle, color, duration)
	visibleToken += 1
	local token = visibleToken

	hud.title.Text = message
	hud.subtitle.Text = subtitle or "Run to the green safe slot!"
	hud.stroke.Color = color or Color3.fromRGB(72, 202, 255)
	hud.panel.BackgroundTransparency = 0.08
	hud.panel.Visible = true

	TweenService:Create(hud.panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()

	if duration and duration > 0 then
		task.delay(duration, function()
			if visibleToken == token then
				hide()
			end
		end)
	end
end

local function handlePhase(payload)
	if not onStageFive then
		return
	end

	local phase = payload.phase
	if phase == TsunamiConfig.Phases.Run then
		show(payload.message or "RUN!", "Next wave is resetting.", ObbyConfig.Colors.Start, payload.duration or TsunamiConfig.Ui.RunMessageDuration)
	elseif phase == TsunamiConfig.Phases.Warning then
		show(payload.message or "GET TO SAFETY!", "Find a green shelter before the wave hits.", ObbyConfig.Colors.Lava, payload.duration or TsunamiConfig.Timing.Warning)
	elseif phase == TsunamiConfig.Phases.Wave then
		show(payload.message or "TSUNAMI!", "Stay inside the safe slot.", Color3.fromRGB(72, 202, 255), payload.duration or TsunamiConfig.Timing.Wave)
	elseif phase == TsunamiConfig.Phases.Recovery then
		show(payload.message or "WAVE PASSED!", "Run to the next safe slot.", ObbyConfig.Colors.CheckpointAccent, payload.duration or TsunamiConfig.Ui.RecoveryMessageDuration)
	end
end

local function handleCountdown(payload)
	if not onStageFive then
		return
	end

	show(payload.message or "TSUNAMI SOON!", "GET TO SAFETY!", ObbyConfig.Colors.Lava, 1.05)
end

function TsunamiUiController.start()
	if started then
		return
	end

	started = true
	hud = createHud()

	ReplicatedStorage:WaitForChild(ObbyConfig.RemoteEventName).OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		if payload.type == "WorldStarted" or payload.type == "StageStarted" then
			onStageFive = payload.stageNumber == 5
			if not onStageFive then
				hide()
			end
		elseif payload.type == "RunReset" or payload.type == "RunFinished" then
			onStageFive = false
			hide()
		elseif payload.type == "DevTeleported" then
			if payload.message == "Testing Stage 5" then
				onStageFive = true
			else
				onStageFive = false
				hide()
			end
		elseif payload.type == TsunamiConfig.RemoteTypes.Phase then
			handlePhase(payload)
		elseif payload.type == TsunamiConfig.RemoteTypes.Countdown then
			handleCountdown(payload)
		elseif payload.type == TsunamiConfig.RemoteTypes.Hit then
			show(payload.message or "CAUGHT BY THE TSUNAMI!", "Respawning...", ObbyConfig.Colors.Lava, 1.4)
		end
	end)
end

return TsunamiUiController
