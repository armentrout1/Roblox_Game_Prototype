# Roblox Speedrun Obby Roadmap

## Current Status

- Core playable obby prototype is complete.
- Checkpoints and respawn are implemented, with Studio verification still pending.
- Foundation architecture pass is implemented: server-owned run state, stage progression, checkpoint rewards, coin session state, passive buff plumbing, and stage-module documentation.
- World 1 Stage 1 - Lava Boulders is implemented as the first real content pass.
- World 1 Stage 2 - Sea of Noobs is implemented: the low Sea of Noobs is hazardous, while elevated noobs are safe traversal platforms.
- The first progressive buff unlocks after Stage 2 through the existing `BuffService` and `WorldConfig` flow.
- World 1 Stage 3 - Ninja Wall Run is implemented with a client-side wall-run controller and server-owned checkpoint completion.
- World 1 Stage 4 - RC Car Maze is implemented as a distinct remote-control mini-game with server-owned completion and CP 4 progression.
- Stage 4 RC camera and maze tuning pass is complete: first-start camera binding is more reliable, Chase/Aerial camera modes are available, and the maze has wider turns.
- The second progressive buff, Speed Boost, unlocks after Stage 4 through the existing `BuffService` and `WorldConfig` flow.
- World 1 Stage 5 - Tsunami Run is implemented with server-owned wave timing, explicit safe shelters, and CP 5 progression.
- World 1 Stage 6 - Basketball Challenge is implemented with free throw, three-pointer, and half-court shot stations, a client shot meter, server-owned scoring, and CP 6 progression.
- Stage 6 basketball polish pass is complete: elevated court arena, clearer court markings, hold/release shooting, timing-quality feedback, improved shot arcs, rim/backboard interaction, and a subtle shooting camera.
- The third progressive buff, Agility Boost, unlocks after Stage 6 through the existing `BuffService` and `WorldConfig` flow.
- World 1 Stage 7 - Cat and Mouse is implemented with a server-owned cat chase, helper distraction validation, cartoon capture/spit-out retry flow, escape-hole objective, CP 7 progression, and a Stage 8 placeholder.
- Developer-only Studio testing UI is implemented for jumping to Stage 1 through Stage 7, resetting a run, and returning to the start without beginning Stage 8 work.
- Timer rule: during an active speedrun, death does not reset or stop the timer; respawn time counts against the run.
- Stage 7 timer rule: if the cat captures a player, the 15-second captured/spit-out retry time counts against the active run timer; the run does not pause or reset.
- Current course includes Stage 1 through Stage 7, plus a visual-only Stage 8 placeholder. Reaching CP 7 after escaping the cat marks Stage 7 complete and advances run state to Stage 8 metadata, but it does not finish World 1.

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
- Stage 6 reward: Agility Boost, a small combined movement and jump improvement.
- Stage 8 reward: another modest final-stage-appropriate buff.
- Buffs should be configurable and conservative so late stages remain meaningful.

### Stage List

1. Stage 1 - Lava Boulders: jump back and forth across boulders over lava.
2. Stage 2 - Sea of Noobs: cross elevated safe noob platforms above a hazardous low sea of noob heads and body pieces.
3. Stage 3 - Ninja Wall Run: achievable Roblox approximation of fast wall-running/ninja movement.
4. Stage 4 - RC Car Maze: control an RC car through a maze, unlock the player gate, then reach CP 4.
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
- Complete: Stage 4 RC session service keeps mini-game completion server-authoritative while the client handles input, camera, and HUD presentation.
- Complete: Stage 4 RC tuning pass added robust client car readiness binding, Chase/Aerial camera modes, and a more forgiving maze layout.
- Complete: Stage 5 tsunami service keeps wave lifecycle and safe-zone validation server-authoritative while the client handles warning UI.
- Complete: Stage 6 basketball service keeps shot order, timing validation, ball scoring, gate access, and CP 6 completion server-authoritative while the client handles meter UI and feedback.
- Complete: Stage 6 polish pass centralizes basketball tuning in `BasketballConfig` and improves court visuals, shooting presentation, shot quality, and camera cleanup without starting Stage 7.
- Complete: Stage 7 cat-and-mouse service keeps cat AI, catch checks, helper distraction validation, capture timing, escape validation, and CP 7 gating server-authoritative while the client handles temporary chase feedback UI.
- Continue to keep all gameplay authority on the server.

## World 1 - First Content Pass

- Complete: Stage 1 - Lava Boulders.
- Complete: Stage 2 - Sea of Noobs, with low hazardous noob sea visuals and elevated safe noob traversal.
- Complete: first progressive buff unlock after Stage 2.
- Complete: Stage 3 - Ninja Wall Run.
- Complete: developer tooling to jump directly into Stage 1, Stage 2, Stage 3, or Stage 4 test states without awarding skipped checkpoint coins.
- Complete: Stage 4 - RC Car Maze.
- Complete: Speed Boost unlock after Stage 4.
- Complete: Stage 5 - Tsunami Run with explicit safe shelters and CP 5 checkpoint reward.
- Complete: Stage 6 - Basketball Challenge with three required shots, visible ball arcs, CP 6 checkpoint reward, and Agility Boost unlock.
- Complete: Stage 6 basketball polish pass.
- Complete: Stage 7 - Cat and Mouse with escape-hole completion, helper distraction, capture/spit-out retry, CP 7 checkpoint reward, and Stage 8 placeholder.
- The Stage 1-7 content pass is now complete; confirm checkpoint, reward, buff, respawn, timer, and multiplayer behavior through these first seven stages before adding more content.

## World 1 - Interactive Stages

- Complete: Stage 4 - RC Car Maze with player-specific RC completion gate.
- Complete: Stage 4 tuning pass for RC camera startup, camera mode toggle, and easier maze navigation.
- Complete: Stage 5 - Tsunami Run with shared wave cycle and per-player survival checks.
- Complete: Stage 6 - Basketball Challenge with a server-validated shot meter sequence.
- Complete: Stage 6 basketball polish pass with elevated court presentation and hold/release timing.
- Complete: Stage 7 - Cat and Mouse with independent per-player cat sessions and server-validated friend distraction.
- Keep each mini-game behind a server-owned completion signal.

## World 1 - Advanced Stages

- Complete: Stage 7 - Cat and Mouse, including multiplayer distraction behavior and comedic catch/spit-out sequence.
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

Continue World 1 - Advanced Stages only after Stage 1 through Stage 7 Studio testing:

- Build Stage 8 - Roller Coaster Lean.
- Use the new `StageManager` completion API instead of awarding progress directly.
- Keep checkpoint placement and rewards server-owned.
- First recommended task: prototype the Stage 8 cart lane, cart spawn/control handoff, and lean/fall validation behind the existing Stage 8 placeholder.
