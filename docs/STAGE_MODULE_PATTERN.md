# Stage Module Pattern

Future World 1 stages should plug into the server-owned progression systems instead of awarding progress directly.

## Server Authority

- Stage modules run their authoritative completion checks on the server.
- Clients may show UI, play effects, send input, or request an action, but the server decides whether the action is valid.
- Clients must never directly award coins, unlock passives, complete stages, or grant lives.

## Recommended Shape

Each stage controller should expose a small API such as:

```luau
local StageController = {}

function StageController.start(player, context)
	-- Spawn or enable stage-specific objects for this player.
end

function StageController.stop(player, context)
	-- Clean up temporary state, connections, vehicles, prompts, or effects.
end

return StageController
```

The `context` table should provide references to shared systems such as:

- `stageManager`
- `runState`
- `rewardService`
- `buffService`
- remote feedback APIs
- stage/world metadata from `WorldConfig`

## Completion Flow

When a stage has been completed, the stage controller should call the progression layer:

```luau
stageManager:completeStage(player, "world_1_stage_4")
```

The progression layer handles:

- duplicate completion protection
- next-stage progression
- passive unlock checks
- world completion detection
- reward APIs where appropriate
- client feedback events

## Mini-Game Notes

- RC car, basketball, cat-and-mouse, roller coaster, timing prompts, and final race logic should each live in their own focused controller/module.
- Any input-sensitive mini-game should validate timing, location, and current stage on the server.
- Visual-only effects can be client-side, but server state remains the source of truth.
