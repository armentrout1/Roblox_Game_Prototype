# Roblox Speedrun Obby Roadmap

## 1. Core playable obby

- Build a short, readable obstacle course with a start, finish, jumps, moving element, and lava hazard.
- Add a timer that starts when the player begins and stops at the finish.
- Show a win message, completion time, and current-session best time.

## 2. Checkpoints and respawn

- Add checkpoint pads throughout the course.
- Respawn players at their latest checkpoint after falling or hitting hazards.
- Show checkpoint feedback in the UI.

## 3. Better timer + leaderboard

- Improve timer presentation and run-state feedback.
- Add richer leaderboard formatting for current-server best times.
- Track attempts, resets, and personal best improvements.

## 4. Coins and simple shop

- Add coin pickups along the course route.
- Build a small shop for cosmetic or utility rewards.
- Keep coin collection clear and satisfying without distracting from the speedrun.

## 5. Multiple courses/difficulty levels

- Support multiple generated course layouts.
- Add easy, medium, and hard routes.
- Let players choose or vote on the next course.

## 6. Polish, sound, VFX, UI

- Add sound effects for start, finish, hazards, checkpoints, and best times.
- Add lightweight VFX for movement, lava, finish, and pickups.
- Refine colors, signs, animations, and screen UI.

## 7. Monetization/game passes

- Identify optional, kid-friendly game pass ideas.
- Add safe hooks for bonuses, cosmetics, or convenience features.
- Keep monetization separate from core course completion.

## 8. Persistent progression/data saving

- Persist best times, coins, and unlocks with DataStore.
- Add retry handling and basic data safety.
- Clearly separate saved progression from per-session state.

## 9. Multiplayer testing and launch checklist

- Test with multiple players in Studio.
- Check spawn flow, timing, collisions, UI, and server cleanup.
- Prepare release notes, thumbnails/icons, and launch QA checklist.
