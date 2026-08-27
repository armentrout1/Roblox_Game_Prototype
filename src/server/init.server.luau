local CourseBuilder = require(script:WaitForChild("CourseBuilder"))
local RunManager = require(script:WaitForChild("RunManager"))

local course = CourseBuilder.build()
local runManager = RunManager.new(course)

runManager:start()
