local WorldConfig = {}

WorldConfig.CurrentWorldId = "world_1"

WorldConfig.Rewards = {
	CheckpointCoins = 150,
	WorldCompletionCoins = 400,
}

WorldConfig.ProgressiveBuffs = {
	{
		id = "stage_2_jump_boost",
		afterStage = 2,
		displayName = "Jump Boost",
		description = "Slightly higher jumping for the rest of the run.",
		effects = {
			jumpPowerMultiplier = 1.08,
		},
	},
	{
		id = "stage_4_speed_boost",
		afterStage = 4,
		displayName = "Quick Feet",
		description = "Slightly faster movement for the rest of the run.",
		effects = {
			walkSpeedMultiplier = 1.08,
		},
	},
	{
		id = "stage_6_air_control",
		afterStage = 6,
		displayName = "Air Control",
		description = "A modest movement boost for later precision stages.",
		effects = {
			walkSpeedMultiplier = 1.04,
			jumpPowerMultiplier = 1.04,
		},
	},
	{
		id = "stage_8_final_push",
		afterStage = 8,
		displayName = "Final Push",
		description = "A small final-stage movement boost.",
		effects = {
			walkSpeedMultiplier = 1.05,
		},
	},
}

WorldConfig.Worlds = {
	world_1 = {
		id = "world_1",
		displayName = "World 1",
		theme = "Lava speedrun obby",
		stageCount = 10,
		stages = {
			{
				number = 1,
				id = "world_1_stage_1",
				name = "Lava Boulders",
				controllerType = "obby",
				summary = "Jump back and forth across boulders suspended in lava.",
			},
			{
				number = 2,
				id = "world_1_stage_2",
				name = "Sea of Noobs",
				controllerType = "obby",
				summary = "Cross safe elevated noobs while avoiding the hazardous low Sea of Noobs.",
			},
			{
				number = 3,
				id = "world_1_stage_3",
				name = "Ninja Wall Run",
				controllerType = "movement_challenge",
				summary = "Use an achievable wall-run approximation for a fast ninja-inspired sequence.",
			},
			{
				number = 4,
				id = "world_1_stage_4",
				name = "RC Car Maze",
				controllerType = "vehicle_maze",
				summary = "Control an RC car through a maze to unlock the next-stage door.",
			},
			{
				number = 5,
				id = "world_1_stage_5",
				name = "Tsunami Run",
				controllerType = "chase",
				summary = "Race through the course while avoiding an incoming tsunami.",
			},
			{
				number = 6,
				id = "world_1_stage_6",
				name = "Basketball Challenge",
				controllerType = "timing_minigame",
				summary = "Complete a free throw, three-pointer, and half-court shot with a shot meter.",
			},
			{
				number = 7,
				id = "world_1_stage_7",
				name = "Cat and Mouse",
				controllerType = "ai_chase",
				summary = "Reach the escape hole before the cat catches the player.",
			},
			{
				number = 8,
				id = "world_1_stage_8",
				name = "Roller Coaster Lean",
				controllerType = "vehicle_balance",
				summary = "Ride a cart and lean left or right to stay balanced.",
			},
			{
				number = 9,
				id = "world_1_stage_9",
				name = "Hacky Sack Timing Game",
				controllerType = "rhythm_timing",
				summary = "Hit prompts correctly 15 times in a row.",
			},
			{
				number = 10,
				id = "world_1_stage_10",
				name = "Final Speed Race",
				controllerType = "race_cutscene",
				rivalName = "Lightning Legend",
				summary = "Race with a speed coil, then finish with a comedic rival cutscene.",
			},
		},
	},
}

WorldConfig.PlannedGamepasses = {
	demonicDragon = {
		id = "demonic_dragon",
		displayName = "Demonic Dragon",
		targetRobuxPrice = 50,
		status = "planned_not_implemented",
		benefits = {
			extraLives = 1,
			walkSpeedMultiplier = 1.05,
			deathRecoveryEffect = "heart_shatter_reassemble",
		},
	},
}

return WorldConfig
