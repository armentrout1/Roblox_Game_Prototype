local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CatMouseConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CatMouseConfig"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local CatMouseUiController = {}

local player = Players.LocalPlayer

local started = false
local hud = nil
local visibleToken = 0
local onStageSeven = false

local function createHud()
	local playerGui = player:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("CatMouseHud")
	if existing then
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CatMouseHud"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.BackgroundColor3 = Color3.fromRGB(42, 31, 34)
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel = 0
	panel.Position = UDim2.fromScale(0.5, 0.17)
	panel.Size = UDim2.fromOffset(448, 88)
	panel.Visible = false
	panel.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 202, 86)
	stroke.Thickness = 3
	stroke.Transparency = 0.12
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.Position = UDim2.fromOffset(16, 10)
	title.Size = UDim2.new(1, -32, 0, 34)
	title.Text = "CAT AND MOUSE"
	title.TextColor3 = ObbyConfig.Colors.White
	title.TextScaled = true
	title.TextStrokeColor3 = ObbyConfig.Colors.Dark
	title.TextStrokeTransparency = 0.35
	title.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.BackgroundTransparency = 1
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Position = UDim2.fromOffset(16, 49)
	subtitle.Size = UDim2.new(1, -32, 0, 25)
	subtitle.Text = "Reach the mouse hole."
	subtitle.TextColor3 = Color3.fromRGB(255, 235, 183)
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

local function show(title, subtitle, color, duration)
	visibleToken += 1
	local token = visibleToken

	hud.title.Text = title
	hud.subtitle.Text = subtitle or ""
	hud.stroke.Color = color or Color3.fromRGB(255, 202, 86)
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

local function showIntro()
	show("CAT AND MOUSE", "Reach the mouse hole. Friends distract from behind.", Color3.fromRGB(255, 202, 86), CatMouseConfig.Ui.IntroDuration)
end

local function handleCatEvent(payload)
	if payload.type == CatMouseConfig.Messages.AttemptStarted then
		onStageSeven = true
		show("RUN!", "The cat is awake.", ObbyConfig.Colors.Start, 1.4)
	elseif payload.type == CatMouseConfig.Messages.CatClose then
		show("CAT IS CLOSE!", "Keep moving!", ObbyConfig.Colors.Lava, 1)
	elseif payload.type == CatMouseConfig.Messages.CatDistracted then
		show("CAT DISTRACTED!", "Go now!", ObbyConfig.Colors.CheckpointAccent, payload.duration or 1.5)
	elseif payload.type == CatMouseConfig.Messages.Captured then
		show("THE CAT GOT YOU!", "Spit out in: " .. tostring(payload.duration or CatMouseConfig.Cat.CaptureDuration), ObbyConfig.Colors.Lava)
	elseif payload.type == CatMouseConfig.Messages.CaptureCountdown then
		show("THE CAT GOT YOU!", string.format("Spit out in: %ds", payload.seconds or 0), ObbyConfig.Colors.Lava)
	elseif payload.type == CatMouseConfig.Messages.SpitOut then
		show("HAIRBALL!", "Try again. The timer kept running.", ObbyConfig.Colors.Finish, payload.duration or CatMouseConfig.Ui.NoticeDuration)
	elseif payload.type == CatMouseConfig.Messages.Escaped then
		show("ESCAPED!", "CP 7 unlocked.", ObbyConfig.Colors.Finish, payload.duration or CatMouseConfig.Ui.EscapeDuration)
	elseif payload.type == CatMouseConfig.Messages.Ended then
		hide()
	elseif payload.type == CatMouseConfig.Messages.Notice then
		show(payload.message or "Cat and Mouse", "Keep moving.", ObbyConfig.Colors.Finish, CatMouseConfig.Ui.NoticeDuration)
	end
end

function CatMouseUiController.start()
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
			onStageSeven = payload.stageNumber == 7
			if onStageSeven then
				showIntro()
			else
				hide()
			end
		elseif payload.type == "RunReset" or payload.type == "RunFinished" then
			onStageSeven = false
			hide()
		elseif payload.type == "DevTeleported" then
			onStageSeven = payload.message == "Testing Stage 7"
			if onStageSeven then
				showIntro()
			else
				hide()
			end
		elseif payload.type == CatMouseConfig.Messages.Notice and onStageSeven then
			show(payload.message or "Cat and Mouse", "Keep moving.", ObbyConfig.Colors.Finish, CatMouseConfig.Ui.NoticeDuration)
		end
	end)

	ReplicatedStorage:WaitForChild(CatMouseConfig.RemoteEventName).OnClientEvent:Connect(function(payload)
		if typeof(payload) ~= "table" then
			return
		end

		handleCatEvent(payload)
	end)
end

return CatMouseUiController
