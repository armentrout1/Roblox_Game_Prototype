local BasketballConfig = {}

BasketballConfig.RemoteEventName = "BasketballEvent"

BasketballConfig.Actions = {
	BeginCharge = "BeginCharge",
	ReleaseShot = "ReleaseShot",
	CancelShot = "CancelShot",
}

BasketballConfig.Messages = {
	ShotStarted = "BasketballShotStarted",
	ShotReleased = "BasketballShotReleased",
	ShotEnded = "BasketballShotEnded",
	ShotScored = "BasketballShotScored",
	ShotMissed = "BasketballShotMissed",
	ProgressChanged = "BasketballProgressChanged",
	Completed = "BasketballCompleted",
	Notice = "BasketballNotice",
	DoorLocked = "BasketballDoorLocked",
}

BasketballConfig.ShotStates = {
	FreeThrow = "FREE_THROW",
	ThreePointer = "THREE_POINTER",
	HalfCourt = "HALF_COURT",
	Complete = "COMPLETE",
}

BasketballConfig.ShotQualities = {
	Perfect = "PERFECT",
	Good = "GOOD",
	Close = "CLOSE",
	Early = "EARLY",
	Late = "LATE",
}

BasketballConfig.Court = {
	PlatformCenter = Vector3.new(0, 22.1, 1360),
	PlatformSize = Vector3.new(70, 1.2, 222),
	FloorCenter = Vector3.new(0, 22.82, 1360),
	FloorSize = Vector3.new(52, 0.28, 182),
	EntrancePosition = Vector3.new(0, 25.95, 1260),
	EntranceLookAt = Vector3.new(0, 25.95, 1304),
	CheckpointPosition = Vector3.new(0, 25.95, 1468),
	Stage7LookAt = Vector3.new(0, 25.95, 1512),
	HoopCenter = Vector3.new(0, 29.65, 1304),
	ShotTargetOffset = Vector3.new(0, -1.05, 0),
}

BasketballConfig.ShotOrder = {
	{
		index = 1,
		id = BasketballConfig.ShotStates.FreeThrow,
		displayName = "Free Throw",
		stationName = "Stage6FreeThrowStation",
		meterCycleDuration = 1.6,
		releaseTimeout = 7,
		yellowMin = 0.31,
		greenMin = 0.4,
		perfectMin = 0.48,
		perfectMax = 0.6,
		greenMax = 0.7,
		yellowMax = 0.8,
		arcHeight = 18,
		flightTime = 1.25,
	},
	{
		index = 2,
		id = BasketballConfig.ShotStates.ThreePointer,
		displayName = "Three-Pointer",
		stationName = "Stage6ThreePointerStation",
		meterCycleDuration = 1.42,
		releaseTimeout = 7,
		yellowMin = 0.36,
		greenMin = 0.44,
		perfectMin = 0.5,
		perfectMax = 0.58,
		greenMax = 0.66,
		yellowMax = 0.74,
		arcHeight = 23,
		flightTime = 1.45,
	},
	{
		index = 3,
		id = BasketballConfig.ShotStates.HalfCourt,
		displayName = "Half-Court Shot",
		stationName = "Stage6HalfCourtStation",
		meterCycleDuration = 1.28,
		releaseTimeout = 7.5,
		yellowMin = 0.39,
		greenMin = 0.46,
		perfectMin = 0.51,
		perfectMax = 0.57,
		greenMax = 0.64,
		yellowMax = 0.71,
		arcHeight = 31,
		flightTime = 1.75,
	},
}

BasketballConfig.Ball = {
	NamePrefix = "Stage6Basketball_",
	Size = 2.1,
	Lifetime = 4.5,
	ShotCooldown = 0.85,
	HoldHeight = 1.65,
	HoldForwardOffset = 1.65,
	ScoreCheckDurationPadding = 1.1,
	EarlyShortScale = 15,
	LateLongScale = 13,
	SideErrorScale = 8,
}

BasketballConfig.Scoring = {
	ZoneSize = Vector3.new(5.8, 3.4, 5.8),
	ZoneOffset = Vector3.new(0, -1.2, 0),
	MinHoldDuration = 0.16,
}

BasketballConfig.Camera = {
	Enabled = true,
	FieldOfView = 66,
	RestoreDelay = 0.25,
}

BasketballConfig.Ui = {
	ReleaseKeys = "SPACE or mouse",
	FeedbackDuration = 1.35,
	PerfectFeedbackDuration = 1.75,
}

BasketballConfig.Effects = {
	SoundIds = {
		Bounce = "",
		Rim = "",
		Backboard = "",
		Swish = "",
		Perfect = "",
	},
}

return BasketballConfig
