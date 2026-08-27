local CatMouseConfig = {}

CatMouseConfig.RemoteEventName = "CatMouseEvent"

CatMouseConfig.Messages = {
	AttemptStarted = "CatMouseAttemptStarted",
	CatClose = "CatMouseCatClose",
	CatDistracted = "CatMouseCatDistracted",
	Captured = "CatMouseCaptured",
	CaptureCountdown = "CatMouseCaptureCountdown",
	SpitOut = "CatMouseSpitOut",
	Escaped = "CatMouseEscaped",
	Ended = "CatMouseEnded",
	Notice = "CatMouseNotice",
}

CatMouseConfig.States = {
	Chasing = "Chasing",
	Stunned = "Stunned",
	Captured = "Captured",
	Escaped = "Escaped",
}

CatMouseConfig.Stage = {
	FloorCenter = Vector3.new(0, 22.15, 1670),
	FloorSize = Vector3.new(70, 1, 330),
	StartPosition = Vector3.new(0, 25.95, 1526),
	StartLookAt = Vector3.new(0, 25.95, 1570),
	RetryPosition = Vector3.new(0, 25.95, 1526),
	RetryLookAt = Vector3.new(0, 25.95, 1570),
	Cp7Position = Vector3.new(0, 25.95, 1846),
	Stage8LookAt = Vector3.new(0, 25.95, 1888),
	CaptureHoldPosition = Vector3.new(0, 42, 1512),
}

CatMouseConfig.Bounds = {
	MinX = -42,
	MaxX = 42,
	MinY = 18,
	MaxY = 58,
	MinZ = 1490,
	MaxZ = 1838,
}

CatMouseConfig.Cat = {
	ModelPrefix = "Stage7Cat_",
	TemplateName = "Stage7CatTemplate",
	FolderName = "Stage7ActiveCats",
	SpawnPosition = Vector3.new(0, 23.25, 1490),
	ChaseSpeed = 17.8,
	CatchRadius = 5.8,
	CloseRadius = 24,
	CloseNoticeCooldown = 2,
	PathRefreshInterval = 0.85,
	PathWaypointRadius = 4.5,
	StunDuration = 2.6,
	StunCooldown = 6,
	CaptureDuration = 15,
}

CatMouseConfig.Distract = {
	InteractRange = 16,
	BehindDotThreshold = 0.35,
}

CatMouseConfig.Ui = {
	NoticeDuration = 1.5,
	IntroDuration = 2.4,
	EscapeDuration = 2,
}

CatMouseConfig.Effects = {
	SoundIds = {
		Chase = "",
		Cat = "",
		Distract = "",
		Capture = "",
		Hairball = "",
		Escape = "",
	},
}

return CatMouseConfig
