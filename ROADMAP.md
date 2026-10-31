# Roadmap

The plan to make the game hold attention the way good incremental games do. Each phase
builds on the one before. All numbers are starting guesses to tune by playtesting.

## Phase 1: the idle core (done)

- Saving: autosave and Reset progress in the pause menu. Offline earnings were built, then removed: the game shouldn't mine while it's closed.
- Mining Drone, Drone Overclock and Auto-Buyer upgrades.
- Upgrade prices that multiply per tier (`price_growth`).
- Eight more cubes after the Gold Bar, from Silver (12K) to Void (1B).

## Phase 2: make clicks feel lucky (done)

Unpredictable rewards are the strongest hook in the genre.

- **Clear bonus:** finishing a cube pays x1.25 of its value, with a "CLEAR!" banner. Clean Sweep adds x0.25 per tier.
- **Combo meter:** +x0.1 per player hit up to x2, dropping after 1s without a hit. Hot Streak raises the cap, Steady Hands the window. Drone hits don't count.
- **Critical hits:** 2% of player hits break a square outright. Lucky Strike adds 2% per tier.
- **Diamonds scale after upgrades:** they take 3x the clicks of their cube's squares as Sharp Pickaxe lowers them, instead of a fixed 3x of the base.
- **Golden events:** a Lucky Cube drifts by every 2-5 minutes at first, now after every 60-120 squares the player breaks (drones' don't count), so a player can't sit on 1 HP waiting for one. Catching it starts a 30s frenzy: Money x7, Diamond Rush or Drone Overdrive. Lucky Charm brings them sooner, Gold Fever makes frenzies longer. Frenzies are `Frenzy` resources folded in through `Game.add_timed_effect`.
- **Special squares:** Lightning (row and column), Coin Pouch (4x), Multiplier (2x its cube while unbroken) from chance upgrades. Rocks (2x clicks, worthless, not needed to clear) make up 8% of the deep cubes; Prospector turns them into 3x ore.

## Phase 3: long-term goals

### Runs and prestige (done)
- The goal is longer and longer runs. The pickaxe has HP (100 to start), and every click that hits costs 1, however many squares it breaks. At 0 the run ends: the field collapses and a full-screen run-end screen shows the run's time, clicks, cubes and money (with records), the Shards it paid (∛(run earnings ÷ 50), rounded down) and the perk shop. Start next run resets money, upgrades and cubes; Shards, perks, unlocks and stats stay.
- During a run: the Whetstone repairs 25 HP (each repair costs 4x the last), Mining Drones are bought one at a time and break after 60 hits (10 at once, each 1.3x the last), and the Unbreakable frenzy makes clicks free.
- Every Shard ever earned adds 2% to all earnings. Shards buy perks kept forever: Sturdy Handle (+25 max HP per tier, no limit) as the long-term sink, Head Start, Diamond Tips, Drone Bay, Drone Plating, Four-Leaf Clover, Standing Order and Shard Resonance.
- History: prestige started as a Collapse button that unlocked at 100M earned and paid √(run earnings ÷ 1B). Runs had no end, so they ran into the trillions.
- Tuned with a bot that plays runs (scratch harness): square-root Shards and a Whetstone at 1.5x per repair fed each other into runs of quadrillions by run 4. With cube-root Shards, x4 repairs, a 2% boost and a smaller Head Start, runs grow from 150 to about 850 clicks over 13 runs. Earnings still jump once runs reach the Bars (each cube tier pays ~5x the last), but HP caps how much that lengthens a run. With Lucky Cubes counted in squares, the bot reaches the Void Cube at run 14 and ~2,000-click runs by run 18; late runs earn ~10^17, so money and stats stop at `Game.MAX_AMOUNT` instead of overflowing.
- Ideas for more perks: keep a Big Pickaxe tier, a permanent combo cap bonus, a cheaper first Whetstone.

### Achievements (done)
- 26 milestones on their own sidebar page ([A]), each adding +2% (or +5% for hard ones) to all earnings for good, +88% in all: squares broken, cubes cleared, the Void Cube, one-click clears (any cube, a Gold Bar), squares and blasts in one click, run length in clicks, money, Lucky Cubes, mastered cubes, runs and Shards.
- New records in `Game`: longest chain and biggest click (the player's clicks, chains included), one-click clears per cube, Lucky Cubes caught.
- Ideas: achievements for combos, crits or drones; varied rewards (pickaxe HP, a crit chance) instead of earnings only; showing the ones a run earned on the run-end screen.

### Cube mastery (done)
- Each cube type levels up from squares broken on it, drones' included: +5% pay per level on its squares and clear bonus, up to level 10 (+50%). Level N takes N(N+1)/2 cubes' worth of its squares (1 cube for level 1, 55 for level 10). Its shop row shows the level and a bar; a "MASTERY UP!" toast announces each level.
- Kept across runs, so each run climbs the early ladder a little faster, and cheap cubes level fastest per HP spent.
- The count is a lifetime stat per cube (`broken:<id>`), ready for achievements ("Master 5 cubes").
- Ideas: a perk that speeds mastery, a run-end line showing the levels gained in the run.

## Phase 4: always show the next goal

- **Locked silhouettes (done as unlock goals):** cubes and upgrades unlock through goals (clear cubes, break squares, earn money), and each list teases its cheapest locked item with the goal and progress.
- **Progress bar:** under the money counter, filling toward the next unlock.
- **Income per minute:** shown in the HUD, averaged over the last minute of `money_changed` deltas.
- **Stats page:** a sidebar page with squares broken, longest chain, lifetime earnings and time played.

## Tuning notes and smaller ideas

- **Sharp Pickaxe fades:** -1 click per tier matters less as cube clicks grow (Void squares take 100). Options: make it a percentage, or add a "Heavy Pickaxe" that adds damage per hit.
- **Drone pacing:** drones hit 1.5 times a second for 1 damage each, so big cubes take them a while. Watch whether they feel useful in the mid game. Possible levers: base rate, a Drone Drill upgrade (+1 damage per tier), a smarter-targeting upgrade (explosives first).
- **Endless cubes:** past the Void Cube, generate cube tiers on the fly (price `1B × 6^N`, a palette rotated from the existing ones) so the ladder never runs out.
- **Several auto-buy picks:** let each Auto-Buyer tier pick its own cube instead of one cube for every slot.
- **Art:** the clean pixel look is still a placeholder. Late cubes (Meteorite, Magma, Void) are dark and could use emblems or custom tiles to stand out.
