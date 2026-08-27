local BasketballConfig = {}

BasketballConfig.RemoteEventName = "BasketballEvent"

BasketballConfig.Actions = {
	ReleaseShot = "ReleaseShot",
	CancelShot = "CancelShot",
}

BasketballConfig.Messages = {
	ShotStarted = "BasketballShotStarted",
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

BasketballConfig.ShotOrder = {
	{
		index = 1,
		id = BasketballConfig.ShotStates.FreeThrow,
		displayName = "Free Throw",
		stationName = "Stage6FreeThrowStation",
		meterCycleDuration = 1.45,
		releaseTimeout = 5.5,
		greenMin = 0.42,
		greenMax = 0.68,
		flightTime = 1.15,
	},
	{
		index = 2,
		id = BasketballConfig.ShotStates.ThreePointer,
		displayName = "Three-Pointer",
		stationName = "Stage6ThreePointerStation",
		meterCycleDuration = 1.25,
		releaseTimeout = 5.5,
		greenMin = 0.45,
		greenMax = 0.63,
		flightTime = 1.35,
	},
	{
		index = 3,
		id = BasketballConfig.ShotStates.HalfCourt,
		displayName = "Half-Court Shot",
		stationName = "Stage6HalfCourtStation",
		meterCycleDuration = 1.05,
		releaseTimeout = 6,
		greenMin = 0.48,
		greenMax = 0.6,
		flightTime = 1.65,
	},
}

BasketballConfig.Ball = {
	NamePrefix = "Stage6Basketball_",
	Size = 2.1,
	Lifetime = 4,
	ShotCooldown = 1.1,
	StartHeight = 3.1,
	StartForwardOffset = 1.4,
	ScoreCheckDurationPadding = 0.7,
	MissOffsetScale = 18,
}

BasketballConfig.Scoring = {
	ZoneSize = Vector3.new(8, 4.5, 8),
	MinReleaseElapsed = 0.12,
}

BasketballConfig.Ui = {
	ReleaseKeys = "Space or click",
	FeedbackDuration = 1.4,
}

return BasketballConfig
