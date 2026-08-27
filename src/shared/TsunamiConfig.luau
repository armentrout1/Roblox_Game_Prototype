local TsunamiConfig = {}

TsunamiConfig.Phases = {
	Idle = "Idle",
	Run = "Run",
	Warning = "Warning",
	Wave = "Wave",
	Recovery = "Recovery",
}

TsunamiConfig.RemoteTypes = {
	Phase = "TsunamiPhase",
	Countdown = "TsunamiCountdown",
	Hit = "TsunamiHit",
}

TsunamiConfig.SafeZoneAttribute = "Stage5SafeZone"
TsunamiConfig.SafeZoneIndexAttribute = "Stage5SafeZoneIndex"

TsunamiConfig.Timing = {
	Run = 9.5,
	Warning = 3,
	Wave = 3.4,
	Recovery = 1.4,
}

TsunamiConfig.Wave = {
	StartX = -58,
	EndX = 58,
	ParkX = -82,
	CenterY = 22,
	CenterZ = 1058,
	Width = 8,
	Height = 34,
	Depth = 360,
	KillWidth = 12,
}

TsunamiConfig.StageBounds = {
	MinX = -42,
	MaxX = 42,
	MinY = 6,
	MaxY = 42,
	MinZ = 884,
	MaxZ = 1232,
}

TsunamiConfig.Ui = {
	RunMessageDuration = 1.6,
	RecoveryMessageDuration = 1.2,
}

return TsunamiConfig
