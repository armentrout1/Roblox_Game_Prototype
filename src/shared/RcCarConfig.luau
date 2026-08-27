local RcCarConfig = {}

RcCarConfig.RemoteEventName = "RcCarEvent"

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

return RcCarConfig
