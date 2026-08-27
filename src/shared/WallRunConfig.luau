local WorldConfig = require(script.Parent:WaitForChild("WorldConfig"))

local WallRunConfig = {}

local worldId = WorldConfig.CurrentWorldId

WallRunConfig.StageId = WorldConfig.Worlds[worldId].stages[3].id
WallRunConfig.SurfaceAttribute = "WallRunEnabled"
WallRunConfig.SurfaceStageAttribute = "WallRunStageId"

WallRunConfig.StageForward = Vector3.new(0, 0, 1)
WallRunConfig.DetectionDistance = 6.75
WallRunConfig.MaxDuration = 1.55
WallRunConfig.Cooldown = 0.22
WallRunConfig.LostWallGraceTime = 0.12

WallRunConfig.WallRunSpeed = 38
WallRunConfig.VerticalVelocity = 4.5
WallRunConfig.WallStickVelocity = 4
WallRunConfig.JumpAwayVelocity = 34
WallRunConfig.JumpForwardVelocity = 31
WallRunConfig.JumpUpVelocity = 52

WallRunConfig.MaxForce = 70000
WallRunConfig.MaxTorque = 70000
WallRunConfig.OrientationResponsiveness = 18

return WallRunConfig
