local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BasketballConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BasketballConfig"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local BasketballController = {}

local player = Players.LocalPlayer
local QUALITIES = BasketballConfig.ShotQualities

local started = false
local remote = nil
local hud = nil
local renderConnection = nil
local activeShot = nil
local currentMeterValue = 0
local feedbackToken = 0
local cameraToken = 0
local cameraState = nil
local doorVisual = nil
local doorOriginalCFrame = nil
local doorOriginalTransparency = nil

local STATION_LABELS = {
	[1] = "FREE\nTHROW",
	[2] = "THREE\nPOINTER",
	[3] = "HALF\nCOURT",
}

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
	label.TextWrapped = true
	label.Parent = parent

	return label
end

local function createZone(parent, name, color, transparency)
	local zone = Instance.new("Frame")
	zone.Name = name
	zone.BackgroundColor3 = color
	zone.BackgroundTransparency = transparency or 0
	zone.BorderSizePixel = 0
	zone.Position = UDim2.fromScale(0, 0)
	zone.Size = UDim2.fromScale(0, 1)
	zone.Parent = parent

	return zone
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
	panel.BackgroundColor3 = Color3.fromRGB(21, 23, 29)
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Position = UDim2.new(0.5, 0, 1, -26)
	panel.Size = UDim2.fromOffset(560, 176)
	panel.Visible = false
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 147, 64)
	stroke.Thickness = 2
	stroke.Transparency = 0.08
	stroke.Parent = panel

	local title = createText(panel, "Title", "BASKETBALL CHALLENGE", UDim2.fromOffset(18, 10), UDim2.new(1, -36, 0, 28), Color3.fromRGB(255, 219, 74))
	local shotLabel = createText(panel, "ShotLabel", "Current shot: Free Throw", UDim2.fromOffset(18, 42), UDim2.new(0.56, -24, 0, 24), ObbyConfig.Colors.White)
	local progressLabel = createText(panel, "ProgressLabel", "Progress: 0 / 3", UDim2.new(0.56, 0, 0, 42), UDim2.new(0.44, -18, 0, 24), Color3.fromRGB(80, 255, 148))
	local instructionLabel = createText(panel, "InstructionLabel", "Hold SPACE to shoot. Release in the GREEN.", UDim2.fromOffset(18, 68), UDim2.new(1, -36, 0, 24), Color3.fromRGB(206, 244, 255))

	local track = Instance.new("Frame")
	track.Name = "MeterTrack"
	track.BackgroundColor3 = Color3.fromRGB(195, 48, 48)
	track.BorderSizePixel = 0
	track.Position = UDim2.fromOffset(30, 102)
	track.Size = UDim2.new(1, -60, 0, 26)
	track.Parent = panel

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 10)
	trackCorner.Parent = track

	local closeLeft = createZone(track, "CloseLeftZone", Color3.fromRGB(255, 211, 70), 0)
	local greenZone = createZone(track, "GreenZone", Color3.fromRGB(68, 234, 122), 0)
	local perfectZone = createZone(track, "PerfectZone", Color3.fromRGB(218, 255, 234), 0.05)
	local closeRight = createZone(track, "CloseRightZone", Color3.fromRGB(255, 211, 70), 0)

	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.BackgroundColor3 = ObbyConfig.Colors.White
	marker.BorderSizePixel = 0
	marker.Position = UDim2.new(0, -4, 0, -6)
	marker.Size = UDim2.new(0, 8, 1, 12)
	marker.ZIndex = 5
	marker.Parent = track

	local markerCorner = Instance.new("UICorner")
	markerCorner.CornerRadius = UDim.new(0, 4)
	markerCorner.Parent = marker

	local feedbackLabel = createText(panel, "FeedbackLabel", "Step onto the glowing spot and hold to charge.", UDim2.fromOffset(18, 138), UDim2.new(1, -166, 0, 26), Color3.fromRGB(206, 244, 255))
	local releaseButton = createButton(panel, "ReleaseButton", "HOLD", UDim2.new(1, -134, 0, 136), UDim2.fromOffset(108, 30), Color3.fromRGB(255, 108, 38))

	return {
		panel = panel,
		stroke = stroke,
		title = title,
		shotLabel = shotLabel,
		progressLabel = progressLabel,
		instructionLabel = instructionLabel,
		track = track,
		closeLeft = closeLeft,
		closeRight = closeRight,
		greenZone = greenZone,
		perfectZone = perfectZone,
		marker = marker,
		feedbackLabel = feedbackLabel,
		releaseButton = releaseButton,
	}
end

local function calculateMeterValue(elapsed, cycleDuration)
	local progress = (elapsed % cycleDuration) / cycleDuration
	return progress <= 0.5 and (progress * 2) or ((1 - progress) * 2)
end

local function setZone(zone, startValue, endValue)
	local startScale = math.clamp(startValue or 0, 0, 1)
	local width = math.clamp((endValue or startScale) - startScale, 0, 1)
	zone.Position = UDim2.fromScale(startScale, 0)
	zone.Size = UDim2.fromScale(width, 1)
	zone.Visible = width > 0.01
end

local function setMeterZones(payload)
	setZone(hud.closeLeft, payload.yellowMin, payload.greenMin)
	setZone(hud.greenZone, payload.greenMin, payload.greenMax)
	setZone(hud.perfectZone, payload.perfectMin, payload.perfectMax)
	setZone(hud.closeRight, payload.greenMax, payload.yellowMax)
end

local function setMarker(value)
	currentMeterValue = math.clamp(value, 0, 1)
	hud.marker.Position = UDim2.new(currentMeterValue, -4, 0, -6)
end

local function setProgressText(progressText)
	if progressText then
		hud.progressLabel.Text = "Progress: " .. progressText
	end
end

local function stopMeter()
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
end

local function getStationPart(shotConfig)
	local course = workspace:FindFirstChild(ObbyConfig.CourseFolderName)
	return course and course:FindFirstChild(shotConfig.stationName, true)
end

local function setStationLabel(part, text)
	local surfaceGui = part and part:FindFirstChild("SurfaceLabel")
	local label = surfaceGui and surfaceGui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = text
	end
end

local function updateStationVisuals(nextShotIndex, completedShotIndices)
	local completed = {}
	for _, shotIndex in ipairs(completedShotIndices or {}) do
		completed[shotIndex] = true
	end

	for _, shotConfig in ipairs(BasketballConfig.ShotOrder) do
		local part = getStationPart(shotConfig)
		if part then
			local baseLabel = STATION_LABELS[shotConfig.index] or shotConfig.displayName:upper()
			if completed[shotConfig.index] then
				part.Color = Color3.fromRGB(76, 255, 145)
				part.Transparency = 0
				setStationLabel(part, baseLabel .. "\nDONE")
			elseif shotConfig.index == nextShotIndex then
				part.Color = Color3.fromRGB(255, 219, 74)
				part.Transparency = 0
				setStationLabel(part, baseLabel .. "\nNEXT")
			else
				part.Color = Color3.fromRGB(61, 70, 84)
				part.Transparency = 0.18
				setStationLabel(part, baseLabel)
			end
		end
	end
end

local function restoreCamera()
	cameraToken += 1
	if not cameraState then
		return
	end

	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = cameraState.cameraType
		camera.CameraSubject = cameraState.cameraSubject
		camera.FieldOfView = cameraState.fieldOfView
		if cameraState.cameraType == Enum.CameraType.Scriptable then
			camera.CFrame = cameraState.cframe
		end
	end

	cameraState = nil
end

local function scheduleCameraRestore(delaySeconds)
	cameraToken += 1
	local token = cameraToken
	task.delay(delaySeconds or BasketballConfig.Camera.RestoreDelay, function()
		if cameraToken == token then
			restoreCamera()
		end
	end)
end

local function beginShotCamera(cameraCFrame)
	if not BasketballConfig.Camera.Enabled or not cameraCFrame then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	cameraToken += 1
	if not cameraState then
		cameraState = {
			cameraType = camera.CameraType,
			cameraSubject = camera.CameraSubject,
			fieldOfView = camera.FieldOfView,
			cframe = camera.CFrame,
		}
	end

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = BasketballConfig.Camera.FieldOfView
	camera.CFrame = cameraCFrame
end

local function playEffectSound(soundName)
	local soundId = BasketballConfig.Effects.SoundIds[soundName]
	if not soundId or soundId == "" then
		return
	end

	local sound = Instance.new("Sound")
	sound.Name = "Stage6" .. soundName
	sound.SoundId = soundId
	sound.Volume = 0.45
	sound.Parent = workspace.CurrentCamera or player:WaitForChild("PlayerGui")
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local function hideHud()
	feedbackToken += 1
	stopMeter()
	activeShot = nil
	restoreCamera()
	if hud then
		hud.panel.Visible = false
		hud.releaseButton.Text = "HOLD"
		hud.feedbackLabel.TextColor3 = Color3.fromRGB(206, 244, 255)
		hud.stroke.Color = Color3.fromRGB(255, 147, 64)
	end
end

local function updateMeter()
	if not activeShot or not activeShot.isCharging then
		return
	end

	local elapsed = os.clock() - activeShot.localChargeStartedAt
	setMarker(calculateMeterValue(elapsed, activeShot.meterCycleDuration))
end

local function beginShot(payload)
	feedbackToken += 1
	stopMeter()

	activeShot = {
		shotId = payload.shotId,
		displayName = payload.displayName,
		meterCycleDuration = payload.meterCycleDuration,
		isCharging = false,
		released = false,
		localChargeStartedAt = 0,
	}

	hud.shotLabel.Text = "Current shot: " .. (payload.displayName or "Shot")
	setProgressText(payload.progressText or "0 / 3")
	hud.instructionLabel.Text = "Hold " .. BasketballConfig.Ui.ReleaseKeys .. ". Release in the GREEN."
	hud.feedbackLabel.Text = "Hold to charge."
	hud.feedbackLabel.TextColor3 = Color3.fromRGB(206, 244, 255)
	hud.releaseButton.Text = "HOLD"
	hud.stroke.Color = Color3.fromRGB(255, 147, 64)
	hud.panel.Visible = true
	setMeterZones(payload)
	setMarker(0)
	updateStationVisuals(payload.nextShotIndex, payload.completedShotIndices)
	beginShotCamera(payload.cameraCFrame)
end

local function startCharge()
	if not activeShot or activeShot.isCharging or activeShot.released then
		return
	end

	activeShot.isCharging = true
	activeShot.localChargeStartedAt = os.clock()
	hud.feedbackLabel.Text = "Release in the GREEN."
	hud.feedbackLabel.TextColor3 = Color3.fromRGB(206, 244, 255)
	hud.releaseButton.Text = "RELEASE"
	remote:FireServer({
		action = BasketballConfig.Actions.BeginCharge,
		shotId = activeShot.shotId,
	})

	stopMeter()
	renderConnection = RunService.RenderStepped:Connect(updateMeter)
end

local function releaseShot()
	if not activeShot or activeShot.released then
		return
	end

	if not activeShot.isCharging then
		hud.feedbackLabel.Text = "Hold first, then release."
		hud.feedbackLabel.TextColor3 = Color3.fromRGB(255, 219, 74)
		return
	end

	local shotId = activeShot.shotId
	activeShot.released = true
	stopMeter()
	hud.releaseButton.Text = "WAIT"
	hud.feedbackLabel.Text = "Ball away..."
	hud.feedbackLabel.TextColor3 = Color3.fromRGB(206, 244, 255)
	remote:FireServer({
		action = BasketballConfig.Actions.ReleaseShot,
		shotId = shotId,
		releaseValue = currentMeterValue,
	})
	activeShot = nil
end

local function flashMeter(color)
	hud.stroke.Color = color
	TweenService:Create(hud.marker, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundColor3 = color,
	}):Play()

	task.delay(0.3, function()
		if hud then
			hud.marker.BackgroundColor3 = ObbyConfig.Colors.White
		end
	end)
end

local function showFeedback(message, color, duration, restoreCameraAfter)
	feedbackToken += 1
	local token = feedbackToken

	stopMeter()
	activeShot = nil
	hud.panel.Visible = true
	hud.releaseButton.Text = "HOLD"
	hud.feedbackLabel.Text = message
	hud.feedbackLabel.TextColor3 = color

	task.delay(duration or BasketballConfig.Ui.FeedbackDuration, function()
		if feedbackToken == token and not activeShot then
			hud.feedbackLabel.TextColor3 = Color3.fromRGB(206, 244, 255)
			hud.panel.Visible = false
			hud.stroke.Color = Color3.fromRGB(255, 147, 64)
			if restoreCameraAfter then
				scheduleCameraRestore(BasketballConfig.Camera.RestoreDelay)
			end
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

local function handleShotReleased(payload)
	setMarker(payload.releaseValue or currentMeterValue)

	if payload.quality == QUALITIES.Perfect then
		flashMeter(Color3.fromRGB(80, 255, 148))
		hud.feedbackLabel.Text = "PERFECT!"
		hud.feedbackLabel.TextColor3 = Color3.fromRGB(80, 255, 148)
		playEffectSound("Perfect")
	elseif payload.quality == QUALITIES.Good then
		flashMeter(Color3.fromRGB(80, 255, 148))
		hud.feedbackLabel.Text = "GREEN!"
		hud.feedbackLabel.TextColor3 = Color3.fromRGB(80, 255, 148)
	elseif payload.quality == QUALITIES.Close then
		flashMeter(Color3.fromRGB(255, 219, 74))
		hud.feedbackLabel.Text = "CLOSE!"
		hud.feedbackLabel.TextColor3 = Color3.fromRGB(255, 219, 74)
	else
		flashMeter(Color3.fromRGB(255, 95, 72))
		hud.feedbackLabel.Text = "Ball away..."
		hud.feedbackLabel.TextColor3 = Color3.fromRGB(206, 244, 255)
	end
end

function BasketballController.start()
	if started then
		return
	end

	started = true
	remote = ReplicatedStorage:WaitForChild(BasketballConfig.RemoteEventName)
	hud = createHud()

	hud.releaseButton.MouseButton1Down:Connect(startCharge)
	hud.releaseButton.MouseButton1Up:Connect(releaseShot)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not activeShot then
			return
		end

		if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
			startCharge()
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not activeShot then
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
				updateStationVisuals(1, {})
			end
		elseif payload.type == "DevTeleported" then
			hideHud()
			closeDoorLocally()
			updateStationVisuals(1, {})
		elseif payload.type == "StageStarted" then
			if payload.stageNumber == 6 then
				updateStationVisuals(1, {})
			else
				hideHud()
			end
		end
	end)

	remote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		if payload.type == BasketballConfig.Messages.ShotStarted then
			beginShot(payload)
		elseif payload.type == BasketballConfig.Messages.ShotReleased then
			handleShotReleased(payload)
		elseif payload.type == BasketballConfig.Messages.ShotScored then
			setProgressText(payload.progressText)
			updateStationVisuals(payload.nextShotIndex, payload.completedShotIndices)
			playEffectSound(payload.quality == QUALITIES.Perfect and "Perfect" or "Swish")
			showFeedback(payload.message or "SWISH!", Color3.fromRGB(80, 255, 148), BasketballConfig.Ui.FeedbackDuration, true)
		elseif payload.type == BasketballConfig.Messages.ShotMissed then
			setProgressText(payload.progressText)
			updateStationVisuals(payload.nextShotIndex, payload.completedShotIndices)
			showFeedback(payload.message or "MISS - try again", ObbyConfig.Colors.Lava, BasketballConfig.Ui.FeedbackDuration, true)
		elseif payload.type == BasketballConfig.Messages.ProgressChanged then
			hud.shotLabel.Text = "Current shot: " .. (payload.displayName or hud.shotLabel.Text)
			setProgressText(payload.progressText)
			updateStationVisuals(payload.nextShotIndex, payload.completedShotIndices)
		elseif payload.type == BasketballConfig.Messages.Completed then
			openDoorLocally(payload.doorVisual)
			updateStationVisuals(payload.nextShotIndex, payload.completedShotIndices)
			showFeedback(payload.message or "CP 6 unlocked!", ObbyConfig.Colors.Finish, 2, true)
		elseif payload.type == BasketballConfig.Messages.ShotEnded then
			hideHud()
		elseif payload.type == BasketballConfig.Messages.DoorLocked then
			closeDoorLocally(payload.doorVisual)
		end
	end)
end

return BasketballController
