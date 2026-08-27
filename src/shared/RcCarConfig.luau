local RcCarConfig = {}

RcCarConfig.RemoteEventName = "RcCarEvent"
RcCarConfig.CarFolderName = "Stage4PlayerRcCars"
RcCarConfig.CarModelPrefix = "Stage4RcCar_"
RcCarConfig.CarRootName = "RcCarBody"

RcCarConfig.Actions = {
	Input = "Input",
	ResetCar = "ResetCar",
	Exit = "Exit",
}

RcCarConfig.Messages = {
	Started = "RcStarted",
	Ended = "RcEnded",
	Completed = "RcCompleted",
	Reset = "RcReset",
	Notice = "RcNotice",
	DoorLocked = "RcDoorLocked",
}

RcCarConfig.Vehicle = {
	Acceleration = 46,
	Deceleration = 38,
	MaxSpeed = 34,
	ReverseMaxSpeed = 15,
	SteeringSpeed = math.rad(112),
	LinearMaxForce = 90000,
	OrientationMaxTorque = 90000,
	OrientationResponsiveness = 28,
	OutOfBoundsY = 5,
	ResetCooldown = 0.75,
}

RcCarConfig.Input = {
	ThrottleForward = 1,
	ThrottleReverse = -1,
	SteerLeft = -1,
	SteerRight = 1,
}

RcCarConfig.Camera = {
	DefaultMode = "Chase",
	ChaseMode = "Chase",
	AerialMode = "Aerial",
	ChaseDistance = 20,
	ChaseHeight = 11,
	ChaseLookAhead = 7,
	ChaseSmoothingResponsiveness = 10,
	AerialHeight = 62,
	AerialBackOffset = 12,
	AerialLookAhead = 4,
	AerialSmoothingResponsiveness = 12,
	CarResolveTimeout = 4,
}

RcCarConfig.Maze = {
	Width = 104,
	Length = 174,
	WallThickness = 2,
	CorridorWidth = 24,
	TurnPocketWidth = 26,
	BevelSize = 8,
}

return RcCarConfig
