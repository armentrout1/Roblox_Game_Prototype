local ObbyConfig = {}

ObbyConfig.RemoteEventName = "ObbyTimerEvent"
ObbyConfig.CourseFolderName = "SpeedrunObby"

ObbyConfig.Colors = {
	Spawn = Color3.fromRGB(68, 196, 125),
	Start = Color3.fromRGB(38, 179, 255),
	PathA = Color3.fromRGB(255, 209, 102),
	PathB = Color3.fromRGB(126, 217, 87),
	PathC = Color3.fromRGB(117, 155, 255),
	Moving = Color3.fromRGB(255, 144, 31),
	Beam = Color3.fromRGB(186, 139, 255),
	Lava = Color3.fromRGB(255, 62, 48),
	Finish = Color3.fromRGB(255, 219, 74),
	Dark = Color3.fromRGB(28, 31, 40),
	White = Color3.fromRGB(255, 255, 255),
}

function ObbyConfig.roundTime(seconds)
	return math.floor((seconds * 100) + 0.5) / 100
end

function ObbyConfig.formatTime(seconds)
	local safeSeconds = math.max(0, seconds or 0)
	local minutes = math.floor(safeSeconds / 60)
	local remaining = safeSeconds - (minutes * 60)

	if minutes > 0 then
		return string.format("%d:%05.2f", minutes, remaining)
	end

	return string.format("%.2fs", remaining)
end

function ObbyConfig.formatBestTime(seconds)
	if not seconds or seconds <= 0 then
		return "--"
	end

	return ObbyConfig.formatTime(seconds)
end

return ObbyConfig
