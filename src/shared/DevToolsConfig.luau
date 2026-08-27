local DevToolsConfig = {}

DevToolsConfig.RemoteEventName = "DevStageSelectorEvent"
DevToolsConfig.EnabledInStudio = true

-- Add trusted developer user ids here if this tool ever needs to run outside Studio.
DevToolsConfig.AllowedUserIds = {
	-- [123456789] = true,
}

DevToolsConfig.Actions = {
	JumpToStage = "JumpToStage",
	ResetRun = "ResetRun",
	ReturnToStart = "ReturnToStart",
}

DevToolsConfig.StageButtons = {
	{
		stageNumber = 1,
		label = "Stage 1",
	},
	{
		stageNumber = 2,
		label = "Stage 2",
	},
	{
		stageNumber = 3,
		label = "Stage 3",
	},
	{
		stageNumber = 4,
		label = "Stage 4",
	},
	{
		stageNumber = 5,
		label = "Stage 5",
	},
	{
		stageNumber = 6,
		label = "Stage 6",
	},
	{
		stageNumber = 7,
		label = "Stage 7",
	},
}

function DevToolsConfig.isUserIdAllowed(userId)
	return DevToolsConfig.AllowedUserIds[userId] == true
end

return DevToolsConfig
