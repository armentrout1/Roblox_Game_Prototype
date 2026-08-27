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

local keysDown = {
	forward = false,
	reverse = false,
	left = false,
	right = false,
}
local lastThrottle = 0
local lastSteer = 0

local function createButton(parent, name, text, position, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = true
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Position = position
	button.Size = UDim2.fromOffset(118, 34)
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
	panel.Size = UDim2.fromOffset(430, 118)
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

	local resetButton = createButton(panel, "ResetButton", "RESET RC CAR", UDim2.fromOffset(82, 72), Color3.fromRGB(75, 93, 128))
	local exitButton = createButton(panel, "ExitButton", "EXIT RC", UDim2.fromOffset(230, 72), Color3.fromRGB(118, 54, 62))

	return {
		screenGui = screenGui,
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
		return
	end

	if originalWalkSpeed then
		humanoid.WalkSpeed = originalWalkSpeed
	end
	if originalJumpPower then
		humanoid.JumpPower = originalJumpPower
	end
	if originalAutoRotate ~= nil then
		humanoid.AutoRotate = originalAutoRotate
	end
end

local function restrictCharacterControls()
	local humanoid = getCharacterHumanoid()
	if not humanoid then
		return
	end

	originalWalkSpeed = humanoid.WalkSpeed
	originalJumpPower = humanoid.JumpPower
	originalAutoRotate = humanoid.AutoRotate
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
end

local function restoreCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	camera.CameraType = originalCameraType or Enum.CameraType.Custom
	camera.CameraSubject = originalCameraSubject or getCharacterHumanoid()
	originalCameraType = nil
	originalCameraSubject = nil
end

local function updateCamera()
	if not active or not carRoot or not carRoot.Parent then
		return
	end

	local camera = workspace.CurrentCamera
	if not camera then
		return
	end

	local rootCFrame = carRoot.CFrame
	local focusPosition = carRoot.Position + (rootCFrame.LookVector * 6)
	local cameraPosition = carRoot.Position - (rootCFrame.LookVector * 18) + Vector3.new(0, 10, 0)
	camera.CFrame = CFrame.lookAt(cameraPosition, focusPosition)
end

local function setCameraToRc()
	local camera = workspace.CurrentCamera
	if not camera or not carRoot then
		return
	end

	originalCameraType = camera.CameraType
	originalCameraSubject = camera.CameraSubject
	camera.CameraType = Enum.CameraType.Scriptable
	updateCamera()
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
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end

	if hud then
		hud.screenGui.Enabled = false
	end

	active = false
	carRoot = nil
	resetInputState()
	restoreCharacterControls()
	restoreCamera()
end

local function startRcMode(payload)
	stopRcMode()

	active = true
	carRoot = payload.carRoot
	doorVisual = payload.doorVisual or doorVisual
	if doorVisual then
		doorOriginalCFrame = doorOriginalCFrame or doorVisual.CFrame
		doorOriginalTransparency = doorOriginalTransparency or doorVisual.Transparency
	end

	restrictCharacterControls()
	setCameraToRc()

	if hud then
		hud.screenGui.Enabled = true
	end

	renderConnection = RunService.RenderStepped:Connect(updateCamera)
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
			carRoot = payload.carRoot or carRoot
			resetInputState()
		elseif payload.type == RcCarConfig.Messages.DoorLocked then
			closeDoorLocally(payload.doorVisual)
		end
	end)
end

return RcCarController
