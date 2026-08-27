local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DevToolsConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DevToolsConfig"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local DevStageSelector = {}

local player = Players.LocalPlayer

local function isAllowedLocally()
	if DevToolsConfig.EnabledInStudio and RunService:IsStudio() then
		return true
	end

	return DevToolsConfig.isUserIdAllowed(player.UserId)
end

local function createButton(parent, text, order, color)
	local button = Instance.new("TextButton")
	button.Name = text:gsub("%s+", "") .. "Button"
	button.AutoButtonColor = true
	button.BackgroundColor3 = color or Color3.fromRGB(45, 55, 72)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.LayoutOrder = order
	button.Size = UDim2.new(1, 0, 0, 30)
	button.Text = text
	button.TextColor3 = ObbyConfig.Colors.White
	button.TextSize = 14
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	return button
end

local function createPanel()
	local playerGui = player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("DevStageSelector")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DevStageSelector"
	screenGui.IgnoreGuiInset = false
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Position = UDim2.new(0, 14, 0.5, 0)
	panel.Size = UDim2.fromOffset(146, 232)
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = ObbyConfig.Colors.CheckpointAccent
	stroke.Thickness = 1
	stroke.Transparency = 0.25
	stroke.Parent = panel

	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 10)
	padding.Parent = panel

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 8)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.LayoutOrder = 0
	title.Size = UDim2.new(1, 0, 0, 18)
	title.Text = "DEV"
	title.TextColor3 = ObbyConfig.Colors.CheckpointAccent
	title.TextSize = 14
	title.Parent = panel

	return panel
end

function DevStageSelector.start()
	if not isAllowedLocally() then
		return
	end

	local remote = ReplicatedStorage:WaitForChild(DevToolsConfig.RemoteEventName)
	local panel = createPanel()

	for index, stageButton in ipairs(DevToolsConfig.StageButtons) do
		local button = createButton(panel, stageButton.label, index, Color3.fromRGB(38, 90, 128))
		button.Activated:Connect(function()
			remote:FireServer({
				action = DevToolsConfig.Actions.JumpToStage,
				stageNumber = stageButton.stageNumber,
			})
		end)
	end

	local resetButton = createButton(panel, "Reset Run", 10, Color3.fromRGB(118, 54, 62))
	resetButton.Activated:Connect(function()
		remote:FireServer({
			action = DevToolsConfig.Actions.ResetRun,
		})
	end)

	local returnButton = createButton(panel, "Return to Start", 11, Color3.fromRGB(58, 89, 70))
	returnButton.Activated:Connect(function()
		remote:FireServer({
			action = DevToolsConfig.Actions.ReturnToStart,
		})
	end)
end

return DevStageSelector
