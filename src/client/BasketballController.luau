local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BasketballConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasketballConfig"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local BasketballController = {}

local player = Players.LocalPlayer

local started = false
local remote = nil
local hud = nil
local renderConnection = nil
local activeShot = nil
local currentMeterValue = 0
local feedbackToken = 0
local doorVisual = nil
local doorOriginalCFrame = nil
local doorOriginalTransparency = nil

local function createButton(parent, name, text, position, size, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Position = position
	button.Size = size
	button.Text = text
	button.TextColor3 = ObbyConfig.Colors.White
	button.TextSize = 14
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local function createText(parent, name, text, position, size, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Position = position
	label.Size = size
	label.Text = text
	label.TextColor3 = color or ObbyConfig.Colors.White
	label.TextScaled = true
	label.TextStrokeColor3 = ObbyConfig.Colors.Dark
	label.TextStrokeTransparency = 0.45
	label.Parent = parent

	return label
end

local function createHud()
	local playerGui = player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("BasketballHud")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BasketballHud"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.BackgroundColor3 = Color3.fromRGB(23, 24, 31)
	panel.BackgroundTransparency = 0.06
	panel.BorderSizePixel = 0
	panel.Position = UDim2.new(0.5, 0, 1, -28)
	panel.Size = UDim2.fromOffset(520, 150)
	panel.Visible = false
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 147, 64)
	stroke.Thickness = 2
	stroke.Transparency = 0.1
	stroke.Parent = panel

	local title = createText(panel, "Title", "BASKETBALL CHALLENGE", UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 28), Color3.fromRGB(255, 219, 74))
	local shotLabel = createText(panel, "ShotLabel", "Free Throw", UDim2.fromOffset(16, 40), UDim2.new(0.5, -20, 0, 24), ObbyConfig.Colors.White)
	local progressLabel = createText(panel, "ProgressLabel", "1 / 3", UDim2.new(0.5, 4, 0, 40), UDim2.new(0.5, -20, 0, 24), Color3.fromRGB(80, 255, 148))

	local track = Instance.new("Frame")
	track.Name = "MeterTrack"
	track.BackgroundColor3 = Color3.fromRGB(52, 57, 70)
	track.BorderSizePixel = 0
	track.Position = UDim2.fromOffset(28, 74)
	track.Size = UDim2.new(1, -56, 0, 24)
	track.Parent = panel

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 10)
	trackCorner.Parent = track

	local greenZone = Instance.new("Frame")
	greenZone.Name = "GreenZone"
	greenZone.BackgroundColor3 = Color3.fromRGB(80, 255, 148)
	greenZone.BorderSizePixel = 0
	greenZone.Position = UDim2.fromScale(0.42, 0)
	greenZone.Size = UDim2.fromScale(0.26, 1)
	greenZone.Parent = track

	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.BackgroundColor3 = ObbyConfig.Colors.White
	marker.BorderSizePixel = 0
	marker.Position = UDim2.new(0, -4, 0, -5)
	marker.Size = UDim2.new(0, 8, 1, 10)
	marker.Parent = track

	local markerCorner = Instance.new("UICorner")
	markerCorner.CornerRadius = UDim.new(0, 4)
	markerCorner.Parent = marker

	local feedbackLabel = createText(panel, "FeedbackLabel", "Space or click to release", UDim2.fromOffset(16, 104), UDim2.new(1, -172, 0, 28), Color3.fromRGB(200, 244, 255))
	local releaseButton = createButton(panel, "ReleaseButton", "RELEASE", UDim2.new(1, -142, 0, 106), UDim2.fromOffset(118, 30), Color3.fromRGB(255, 108, 38))

	return {
		panel = panel,
		title = title,
		shotLabel = shotLabel,
		progressLabel = progressLabel,
		track = track,
		greenZone = greenZone,
		marker = marker,
		feedbackLabel = feedbackLabel,
		releaseButton = releaseButton,
	}
end

local function setGreenZone(greenMin, greenMax)
	local width = math.clamp((greenMax or 0.62) - (greenMin or 0.42), 0.05, 0.6)
	hud.greenZone.Position = UDim2.fromScale(greenMin or 0.42, 0)
	hud.greenZone.Size = UDim2.fromScale(width, 1)
end

local function setMarker(value)
	currentMeterValue = math.clamp(value, 0, 1)
	hud.marker.Position = UDim2.new(currentMeterValue, -4, 0, -5)
end

local function stopMeter()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end

local function hideHud()
	feedbackToken += 1
	stopMeter()
	activeShot = nil
	if hud then
		hud.panel.Visible = false
	end
end

local function updateMeter()
	if not activeShot then
		return
	end

	local elapsed = os.clock() - activeShot.localStartedAt
	local progress = (elapsed % activeShot.meterCycleDuration) / activeShot.meterCycleDuration
	local value = progress <= 0.5 and (progress * 2) or ((1 - progress) * 2)
	setMarker(value)
end

local function beginShot(payload)
	feedbackToken += 1
	stopMeter()

	activeShot = {
		shotId = payload.shotId,
		displayName = payload.displayName,
		meterCycleDuration = payload.meterCycleDuration,
		localStartedAt = os.clock(),
	}

	hud.shotLabel.Text = payload.displayName or "Shot"
	hud.progressLabel.Text = payload.progressText or "1 / 3"
	hud.feedbackLabel.Text = BasketballConfig.Ui.ReleaseKeys .. " to release"
	hud.panel.Visible = true
	setGreenZone(payload.greenMin, payload.greenMax)
	setMarker(0)

	renderConnection = RunService.RenderStepped:Connect(updateMeter)
end

local function releaseShot()
	if not activeShot then
		return
	end

	local shotId = activeShot.shotId
	stopMeter()
	hud.feedbackLabel.Text = "Ball away..."
	remote:FireServer({
		action = BasketballConfig.Actions.ReleaseShot,
		shotId = shotId,
		releaseValue = currentMeterValue,
	})
	activeShot = nil
end

local function showFeedback(message, color, duration)
	feedbackToken += 1
	local token = feedbackToken

	stopMeter()
	activeShot = nil
	hud.panel.Visible = true
	hud.feedbackLabel.Text = message
	hud.feedbackLabel.TextColor3 = color

	task.delay(duration or BasketballConfig.Ui.FeedbackDuration, function()
		if feedbackToken == token and not activeShot then
			hud.feedbackLabel.TextColor3 = Color3.fromRGB(200, 244, 255)
			hud.panel.Visible = false
		end
	end)
end

local function openDoorLocally(targetDoor)
	if not targetDoor then
		return
	end

	doorVisual = targetDoor
	doorOriginalCFrame = doorOriginalCFrame or targetDoor.CFrame
	doorOriginalTransparency = doorOriginalTransparency or targetDoor.Transparency

	TweenService:Create(targetDoor, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = doorOriginalCFrame * CFrame.new(0, 8, 0),
		Transparency = 0.75,
	}):Play()
end

local function closeDoorLocally(targetDoor)
	local door = targetDoor or doorVisual
	if not door or not doorOriginalCFrame then
		return
	end

	door.CFrame = doorOriginalCFrame
	door.Transparency = doorOriginalTransparency or 0.12
end

function BasketballController.start()
	if started then
		return
	end

	started = true
	remote = ReplicatedStorage:WaitForChild(BasketballConfig.RemoteEventName)
	hud = createHud()

	hud.releaseButton.Activated:Connect(releaseShot)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not activeShot then
			return
		end

		if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
			releaseShot()
		end
	end)

	player.CharacterAdded:Connect(hideHud)

	ReplicatedStorage:WaitForChild(ObbyConfig.RemoteEventName).OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		if payload.type == "RunReset" or payload.type == "RunRespawned" or payload.type == "RunFinished" then
			hideHud()
			if payload.type == "RunReset" then
				closeDoorLocally()
			end
		elseif payload.type == "DevTeleported" then
			hideHud()
			closeDoorLocally()
		elseif payload.type == "StageStarted" and payload.stageNumber ~= 6 then
			hideHud()
		end
	end)

	remote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		if payload.type == BasketballConfig.Messages.ShotStarted then
			beginShot(payload)
		elseif payload.type == BasketballConfig.Messages.ShotScored then
			hud.progressLabel.Text = payload.progressText or hud.progressLabel.Text
			showFeedback(payload.message or "SWISH!", Color3.fromRGB(80, 255, 148), BasketballConfig.Ui.FeedbackDuration)
		elseif payload.type == BasketballConfig.Messages.ShotMissed then
			hud.progressLabel.Text = payload.progressText or hud.progressLabel.Text
			showFeedback(payload.message or "MISS - try again", ObbyConfig.Colors.Lava, BasketballConfig.Ui.FeedbackDuration)
		elseif payload.type == BasketballConfig.Messages.ProgressChanged then
			hud.shotLabel.Text = payload.displayName or hud.shotLabel.Text
			hud.progressLabel.Text = payload.progressText or hud.progressLabel.Text
		elseif payload.type == BasketballConfig.Messages.Completed then
			openDoorLocally(payload.doorVisual)
			showFeedback(payload.message or "CP 6 unlocked!", ObbyConfig.Colors.Finish, 2)
		elseif payload.type == BasketballConfig.Messages.ShotEnded then
			hideHud()
		elseif payload.type == BasketballConfig.Messages.DoorLocked then
			closeDoorLocally(payload.doorVisual)
		end
	end)
end

return BasketballController
