# Roblox Speedrun Obby Roadmap

## Current Status

- Core playable obby prototype is complete.
- Checkpoints and respawn are implemented, with Studio verification still pending.
- Foundation architecture pass is implemented: server-owned run state, stage progression, checkpoint rewards, coin session state, passive buff plumbing, and stage-module documentation.
- World 1 Stage 1 - Lava Boulders is implemented as the first real content pass.
- World 1 Stage 2 - Sea of Noobs is implemented: the low Sea of Noobs is hazardous, while elevated noobs are safe traversal platforms.
- The first progressive buff unlocks after Stage 2 through the existing `BuffService` and `WorldConfig` flow.
- World 1 Stage 3 - Ninja Wall Run is implemented with a client-side wall-run controller and server-owned checkpoint completion.
- World 1 Stage 4 - RC Car Maze has not been started; the current course ends at a safe Stage 4 placeholder gate.
- Developer-only Studio testing UI is implemented for jumping to Stage 1, Stage 2, Stage 3, resetting a run, and returning to the start without beginning Stage 4 work.
- Timer rule: during an active speedrun, death does not reset or stop the timer; respawn time counts against the run.
- Current course includes Stage 1, Stage 2, and Stage 3. Reaching the Stage 3 checkpoint marks Stage 3 complete and advances run state to Stage 4 metadata, but it does not finish World 1.

## World 1 Design Brief

World 1 is a 10-stage speedrun/obby world built primarily over lava.

### Rewards

- Each checkpoint reached awards 150 coins.
- Completing World 1 awards 400 coins.
- Checkpoint rewards are awarded once per checkpoint per run.
- Completion rewards are awarded once per completed run.
- Reward logic must be server-authoritative and resist obvious coin farming.

### Progressive Buffs

- Every 2 completed stages grants a modest passive buff for the remainder of the current run.
- Stage 2 reward: slightly higher jumping.
- Stage 4 reward: slightly faster movement.
- Stage 6 reward: another modest movement or jump-related improvement.
- Stage 8 reward: another modest final-stage-appropriate buff.
- Buffs should be configurable and conservative so late stages remain meaningful.

### Stage List

1. Stage 1 - Lava Boulders: jump back and forth across boulders over lava.
2. Stage 2 - Sea of Noobs: cross elevated safe noob platforms above a hazardous low sea of noob heads and body pieces.
3. Stage 3 - Ninja Wall Run: achievable Roblox approximation of fast wall-running/ninja movement.
4. Stage 4 - RC Car Maze: control an RC car through a maze, then unlock the next-stage door.
5. Stage 5 - Tsunami Run: outrun an incoming tsunami while reaching safe slots/areas.
6. Stage 6 - Basketball Challenge: complete a free throw, three-pointer, and half-court shot using a shot meter/timing mechanic.
7. Stage 7 - Cat and Mouse: mouse escapes before the cat catches them; friends can distract/interfere with the cat server-authoritatively.
8. Stage 8 - Roller Coaster Lean: ride a cart and lean/control balance to reach the end.
9. Stage 9 - Hacky Sack Timing Game: hit the correct prompt 15 times in a row, with future PC/mobile/controller support.
10. Stage 10 - Final Speed Race: use a speed coil and race a fictional rival such as "Lightning Legend"; finish with the slip-and-slide lava boulder cutscene and "I'M FINE" sign.

### Planned Gamepass

Demonic Dragon is planned for a future pass, not implemented yet.

- Target price: 50 Robux, to be finalized later.
- Benefits: one additional life, modest movement speed increase, and special death/recovery effect.
- Server owns lives and gameplay benefits.
- Client may run visual effects such as heart shatter/reassemble.

## Architecture Direction

The game should evolve from a single generated prototype into reusable systems:

- World configuration: world metadata, stage list, reward values, buff thresholds, and future pass metadata.
- Stage lifecycle: stage start, active, complete, failed, and reset state.
- Player run state: per-player run id, active world/stage, checkpoints, claimed checkpoint rewards, completion reward claim, lives, buffs, and timer start.
- Checkpoint/respawn system: reusable checkpoint definitions with server-authoritative activation and respawn CFrames.
- Reward/economy system: server-side coin awards with once-per-run guards.
- Buff/passive system: configurable buff unlocks that apply through a controlled server API.
- Stage modules/controllers: one module per stage or mini-game, with clear server authority and client-only presentation hooks.
- Multiplayer safety: server validates progress, rewards, lives, and mini-game completion.
- Persistence boundary: current-run state stays in memory; long-term coins/progression move to DataStore later.

## Foundation

- Complete: existing playable obby prototype.
- Complete: checkpoints and respawn implementation.
- Complete: World/Stage progression architecture around the current prototype.
- Complete: `PlayerRunState` as the server-owned source of active run data.
- Complete: checkpoint reward framework awarding 150 session coins once per checkpoint per run.
- Complete: world completion reward API for future Stage 10 completion.
- Complete: configurable passive buff framework for Stage 2/4/6/8 unlocks.
- Complete: stage module/controller pattern documentation.
- Complete: developer-only stage selector for Studio testing of currently implemented stages.
- Continue to keep all gameplay authority on the server.

## World 1 - First Content Pass

- Complete: Stage 1 - Lava Boulders.
- Complete: Stage 2 - Sea of Noobs, with low hazardous noob sea visuals and elevated safe noob traversal.
- Complete: first progressive buff unlock after Stage 2.
- Complete: Stage 3 - Ninja Wall Run.
- Complete: developer tooling to jump directly into Stage 1, Stage 2, or Stage 3 test states without awarding skipped checkpoint coins.
- Confirm checkpoint, reward, buff, respawn, and timer behavior through these first stages before adding more content.

## World 1 - Interactive Stages

- Not started: Stage 4 - RC Car Maze.
- Build Stage 4 - RC Car Maze with door unlock.
- Build Stage 5 - Tsunami Run with safe areas.
- Build Stage 6 - Basketball Challenge with shot meter and three required shots.
- Keep each mini-game behind a server-owned completion signal.

## World 1 - Advanced Stages

- Build Stage 7 - Cat and Mouse, including multiplayer distraction behavior and comedic catch/spit-out sequence.
- Build Stage 8 - Roller Coaster Lean with cart balance controls.
- Build Stage 9 - Hacky Sack Timing Game with 15-success streak.
- Build Stage 10 - Final Speed Race with fictional rival, speed coil, finish sequence, and completion reward.

## Progression and Monetization

- Add persistent coins.
- Add saved progression.
- Add a simple shop.
- Implement Demonic Dragon gamepass later, with server-owned lives and benefits.
- Plan other future passes only after the base loop is fun.

## Polish

- Improve UI for stage progress, coins, buffs, checkpoints, and run results.
- Complete: player-facing Timer ON/OFF visibility toggle; this hides the timer readout only and never pauses the authoritative run timer.
- Add sounds, music, animation, and VFX.
- Add mobile and controller support.
- Test multiplayer behavior.
- Balance difficulty, rewards, and buffs.
- Add anti-exploit checks.
- Prepare launch checklist.

## Recommended Next Milestone

Begin World 1 - Interactive Stages only after Stage 1, Stage 2, and Stage 3 Studio testing:

- Build Stage 4 - RC Car Maze.
- Use the new `StageManager` completion API instead of awarding progress directly.
- Keep checkpoint placement and rewards server-owned.
- Verify the Stage 3 wall-run mechanic, checkpoint, coin reward, respawn orientation, and Stage 4 placeholder before adding Stage 4 content.
