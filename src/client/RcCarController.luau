local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local RcCarConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RcCarConfig"))

local RcCarController = {}

local player = Players.LocalPlayer

local started = false
local active = false
local carRoot = nil
local remote = nil
local hud = nil
local doorVisual = nil
local doorOriginalCFrame = nil
local doorOriginalTransparency = nil
local renderConnection = nil
local originalCameraType = nil
local originalCameraSubject = nil
local originalWalkSpeed = nil
local originalJumpPower = nil
local originalAutoRotate = nil
local cameraMode = RcCarConfig.Camera.DefaultMode
local cameraCFrame = nil
local cameraBindToken = 0
local activeSessionId = nil

local keysDown = {
	forward = false,
	reverse = false,
	left = false,
	right = false,
}
local lastThrottle = 0
local lastSteer = 0

local function getCameraButtonText()
	return "CAMERA: " .. string.upper(cameraMode)
end

local function createButton(parent, name, text, position, color, size)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Position = position
	button.Size = size or UDim2.fromOffset(118, 34)
	button.Text = text
	button.TextColor3 = ObbyConfig.Colors.White
	button.TextSize = 14
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local function createHud()
	local playerGui = player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("RcCarHud")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RcCarHud"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Position = UDim2.new(0.5, 0, 1, -28)
	panel.Size = UDim2.fromOffset(500, 128)
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 255, 148)
	stroke.Thickness = 2
	stroke.Transparency = 0.15
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Position = UDim2.fromOffset(16, 10)
	title.Size = UDim2.new(1, -32, 0, 28)
	title.Text = "RC CAR MAZE"
	title.TextColor3 = ObbyConfig.Colors.Finish
	title.TextSize = 24
	title.Parent = panel

	local instructions = Instance.new("TextLabel")
	instructions.Name = "Instructions"
	instructions.BackgroundTransparency = 1
	instructions.Font = Enum.Font.GothamBold
	instructions.Position = UDim2.fromOffset(16, 40)
	instructions.Size = UDim2.new(1, -32, 0, 24)
	instructions.Text = "WASD or Arrow Keys to drive. Reach the glowing goal."
	instructions.TextColor3 = ObbyConfig.Colors.White
	instructions.TextSize = 15
	instructions.Parent = panel

	local cameraModeLabel = Instance.new("TextLabel")
	cameraModeLabel.Name = "CameraModeLabel"
	cameraModeLabel.BackgroundTransparency = 1
	cameraModeLabel.Font = Enum.Font.GothamBold
	cameraModeLabel.Position = UDim2.fromOffset(16, 64)
	cameraModeLabel.Size = UDim2.new(1, -32, 0, 18)
	cameraModeLabel.Text = "Camera: Chase  |  C toggles camera"
	cameraModeLabel.TextColor3 = Color3.fromRGB(171, 230, 255)
	cameraModeLabel.TextSize = 13
	cameraModeLabel.Parent = panel

	local cameraButton = createButton(panel, "CameraButton", getCameraButtonText(), UDim2.fromOffset(22, 88), Color3.fromRGB(39, 117, 155), UDim2.fromOffset(138, 32))
	local resetButton = createButton(panel, "ResetButton", "RESET RC CAR", UDim2.fromOffset(190, 88), Color3.fromRGB(75, 93, 128), UDim2.fromOffset(118, 32))
	local exitButton = createButton(panel, "ExitButton", "EXIT RC", UDim2.fromOffset(338, 88), Color3.fromRGB(118, 54, 62), UDim2.fromOffset(118, 32))

	return {
		screenGui = screenGui,
		cameraButton = cameraButton,
		cameraModeLabel = cameraModeLabel,
		resetButton = resetButton,
		exitButton = exitButton,
	}
end

local function getCharacterHumanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function restoreCharacterControls()
	local humanoid = getCharacterHumanoid()
	if not humanoid then
		originalWalkSpeed = nil
		originalJumpPower = nil
		originalAutoRotate = nil
		return
	end

	if originalWalkSpeed ~= nil then
		humanoid.WalkSpeed = originalWalkSpeed
	end
	if originalJumpPower ~= nil then
		humanoid.JumpPower = originalJumpPower
	end
	if originalAutoRotate ~= nil then
		humanoid.AutoRotate = originalAutoRotate
	end

	originalWalkSpeed = nil
	originalJumpPower = nil
	originalAutoRotate = nil
end

local function restrictCharacterControls(payload)
	local humanoid = getCharacterHumanoid()
	if not humanoid then
		return
	end

	originalWalkSpeed = payload.originalWalkSpeed or humanoid.WalkSpeed
	originalJumpPower = payload.originalJumpPower or humanoid.JumpPower
	originalAutoRotate = payload.originalAutoRotate
	if originalAutoRotate == nil then
		originalAutoRotate = humanoid.AutoRotate
	end
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
end

local function updateCameraHud()
	if not hud then
		return
	end

	hud.cameraButton.Text = getCameraButtonText()
	hud.cameraModeLabel.Text = "Camera: " .. cameraMode .. "  |  C toggles camera"
end

local function saveOriginalCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	if originalCameraType ~= nil then
		return
	end

	originalCameraType = camera.CameraType
	originalCameraSubject = camera.CameraSubject
end

local function restoreCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		originalCameraType = nil
		originalCameraSubject = nil
		cameraCFrame = nil
		return
	end

	camera.CameraType = originalCameraType or Enum.CameraType.Custom
	camera.CameraSubject = originalCameraSubject or getCharacterHumanoid()
	originalCameraType = nil
	originalCameraSubject = nil
	cameraCFrame = nil
end

local function getFlatUnit(vector, fallback)
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.01 then
		return fallback
	end

	return flat.Unit
end

local function getTargetCameraCFrame()
	local cameraConfig = RcCarConfig.Camera
	local rootCFrame = carRoot.CFrame
	local forward = getFlatUnit(rootCFrame.LookVector, Vector3.new(0, 0, 1))
	local focusPosition = carRoot.Position + Vector3.new(0, 1.2, 0)

	if cameraMode == cameraConfig.AerialMode then
		local cameraPosition = carRoot.Position + Vector3.new(0, cameraConfig.AerialHeight, -cameraConfig.AerialBackOffset)
		return CFrame.lookAt(cameraPosition, focusPosition + Vector3.new(0, 0, cameraConfig.AerialLookAhead))
	end

	local cameraPosition = carRoot.Position - (forward * cameraConfig.ChaseDistance) + Vector3.new(0, cameraConfig.ChaseHeight, 0)
	return CFrame.lookAt(cameraPosition, focusPosition + (forward * cameraConfig.ChaseLookAhead))
end

local function updateCamera(deltaTime)
	if not active or not carRoot or not carRoot.Parent then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local targetCFrame = getTargetCameraCFrame()
	local responsiveness = cameraMode == RcCarConfig.Camera.AerialMode and RcCarConfig.Camera.AerialSmoothingResponsiveness or RcCarConfig.Camera.ChaseSmoothingResponsiveness
	local alpha = math.clamp(1 - math.exp(-(deltaTime or 0.016) * responsiveness), 0, 1)

	camera.CameraType = Enum.CameraType.Scriptable
	cameraCFrame = cameraCFrame and cameraCFrame:Lerp(targetCFrame, alpha) or targetCFrame
	camera.CFrame = cameraCFrame
end

local function setCameraToRc()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	saveOriginalCamera()
	camera.CameraType = Enum.CameraType.Scriptable
	updateCamera(1 / 60)
end

local function waitForNamedChild(parent, childName, timeout)
	if not parent or not childName or childName == "" then
		return nil
	end

	local child = parent:FindFirstChild(childName)
	if child then
		return child
	end

	return parent:WaitForChild(childName, timeout)
end

local function resolveCarRoot(payload)
	if typeof(payload.carRoot) == "Instance" and payload.carRoot.Parent then
		return payload.carRoot
	end

	local timeout = RcCarConfig.Camera.CarResolveTimeout
	local rootName = payload.carRootName or RcCarConfig.CarRootName
	local carModel = nil
	if typeof(payload.carModel) == "Instance" and payload.carModel.Parent then
		carModel = payload.carModel
	else
		local courseFolder = waitForNamedChild(workspace, ObbyConfig.CourseFolderName, timeout)
		local carsFolder = waitForNamedChild(courseFolder, RcCarConfig.CarFolderName, timeout)
		carModel = waitForNamedChild(carsFolder, payload.carModelName, timeout)
	end

	local root = waitForNamedChild(carModel, rootName, timeout)
	if typeof(root) == "Instance" and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function bindCameraToPayload(payload, token)
	local resolvedRoot = resolveCarRoot(payload)
	if token ~= cameraBindToken or not active or (payload.sessionId and payload.sessionId ~= activeSessionId) then
		return
	end

	if not resolvedRoot then
		if hud then
			hud.cameraModeLabel.Text = "RC car is still loading. Reset or exit if it gets stuck."
		end
		return
	end

	carRoot = resolvedRoot
	cameraCFrame = nil
	setCameraToRc()
end

local function toggleCameraMode()
	if cameraMode == RcCarConfig.Camera.AerialMode then
		cameraMode = RcCarConfig.Camera.ChaseMode
	else
		cameraMode = RcCarConfig.Camera.AerialMode
	end

	cameraCFrame = nil
	updateCameraHud()
	updateCamera(1 / 60)
end

local function resetInputState()
	for key in pairs(keysDown) do
		keysDown[key] = false
	end

	lastThrottle = 0
	lastSteer = 0
end

local function getThrottle()
	if keysDown.forward == keysDown.reverse then
		return 0
	end

	return keysDown.forward and RcCarConfig.Input.ThrottleForward or RcCarConfig.Input.ThrottleReverse
end

local function getSteer()
	if keysDown.left == keysDown.right then
		return 0
	end

	return keysDown.left and RcCarConfig.Input.SteerLeft or RcCarConfig.Input.SteerRight
end

local function sendInputIfChanged()
	if not active then
		return
	end

	local throttle = getThrottle()
	local steer = getSteer()
	if throttle == lastThrottle and steer == lastSteer then
		return
	end

	lastThrottle = throttle
	lastSteer = steer
	remote:FireServer({
		action = RcCarConfig.Actions.Input,
		throttle = throttle,
		steer = steer,
	})
end

local function setKey(input, isDown)
	if input.KeyCode == Enum.KeyCode.W or input.KeyCode == Enum.KeyCode.Up then
		keysDown.forward = isDown
	elseif input.KeyCode == Enum.KeyCode.S or input.KeyCode == Enum.KeyCode.Down then
		keysDown.reverse = isDown
	elseif input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.Left then
		keysDown.left = isDown
	elseif input.KeyCode == Enum.KeyCode.D or input.KeyCode == Enum.KeyCode.Right then
		keysDown.right = isDown
	else
		return
	end

	sendInputIfChanged()
end

local function openDoorLocally(targetDoor)
	if not targetDoor then
		return
	end

	doorVisual = targetDoor
	doorOriginalCFrame = doorOriginalCFrame or targetDoor.CFrame
	doorOriginalTransparency = doorOriginalTransparency or targetDoor.Transparency

	local openCFrame = doorOriginalCFrame * CFrame.new(0, 8, 0)
	TweenService:Create(targetDoor, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = openCFrame,
		Transparency = 0.75,
	}):Play()
end

local function closeDoorLocally(targetDoor)
	local door = targetDoor or doorVisual
	if not door or not doorOriginalCFrame then
		return
	end

	door.CFrame = doorOriginalCFrame
	door.Transparency = doorOriginalTransparency or 0.08
end

local function stopRcMode()
	cameraBindToken += 1
	active = false

	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if hud then
		hud.screenGui.Enabled = false
	end

	carRoot = nil
	activeSessionId = nil
	resetInputState()
	restoreCharacterControls()
	restoreCamera()
end

local function startRcMode(payload)
	stopRcMode()

	cameraBindToken += 1
	local token = cameraBindToken
	active = true
	activeSessionId = payload.sessionId
	cameraMode = RcCarConfig.Camera.DefaultMode
	cameraCFrame = nil
	carRoot = nil
	doorVisual = payload.doorVisual or doorVisual
	if doorVisual then
		doorOriginalCFrame = doorOriginalCFrame or doorVisual.CFrame
		doorOriginalTransparency = doorOriginalTransparency or doorVisual.Transparency
	end

	restrictCharacterControls(payload)
	setCameraToRc()

	if hud then
		updateCameraHud()
		hud.screenGui.Enabled = true
	end

	renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
		updateCamera(deltaTime)
	end)

	task.spawn(function()
		bindCameraToPayload(payload, token)
	end)
end

function RcCarController.start()
	if started then
		return
	end

	started = true
	remote = ReplicatedStorage:WaitForChild(RcCarConfig.RemoteEventName)
	hud = createHud()

	hud.resetButton.Activated:Connect(function()
		if active then
			remote:FireServer({
				action = RcCarConfig.Actions.ResetCar,
			})
		end
	end)

	hud.cameraButton.Activated:Connect(function()
		if active then
			toggleCameraMode()
		end
	end)

	hud.exitButton.Activated:Connect(function()
		if active then
			remote:FireServer({
				action = RcCarConfig.Actions.Exit,
			})
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not active then
			return
		end

		if input.KeyCode == Enum.KeyCode.C then
			toggleCameraMode()
			return
		end

		setKey(input, true)
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not active then
			return
		end

		setKey(input, false)
	end)

	player.CharacterAdded:Connect(function()
		stopRcMode()
	end)

	ReplicatedStorage:WaitForChild(ObbyConfig.RemoteEventName).OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		if payload.type == "RunReset" or payload.type == "DevTeleported" or payload.type == "RunRespawned" or payload.type == "RunFinished" then
			stopRcMode()
			if payload.type == "RunReset" or payload.type == "DevTeleported" then
				closeDoorLocally()
			end
		end
	end)

	remote.OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		if payload.type == RcCarConfig.Messages.Started then
			startRcMode(payload)
		elseif payload.type == RcCarConfig.Messages.Completed then
			openDoorLocally(payload.doorVisual)
		elseif payload.type == RcCarConfig.Messages.Ended then
			stopRcMode()
		elseif payload.type == RcCarConfig.Messages.Reset then
			resetInputState()
			local token = cameraBindToken
			task.spawn(function()
				bindCameraToPayload(payload, token)
			end)
		elseif payload.type == RcCarConfig.Messages.DoorLocked then
			closeDoorLocally(payload.doorVisual)
		end
	end)
end

return RcCarController
