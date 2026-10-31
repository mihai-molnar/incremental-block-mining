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
- 27 milestones on their own sidebar page ([A]), each adding +2% (or +5% for hard ones) to all earnings for good, +93% in all (Starlight, for freeing the star, came with the ending): squares broken, cubes cleared, the Void Cube, one-click clears (any cube, a Gold Bar), squares and blasts in one click, run length in clicks, money, Lucky Cubes, mastered cubes, runs and Shards.
- New records in `Game`: longest chain and biggest click (the player's clicks, chains included), one-click clears per cube, Lucky Cubes caught.
- Ideas: achievements for combos, crits or drones; varied rewards (pickaxe HP, a crit chance) instead of earnings only; showing the ones a run earned on the run-end screen.

### Cube mastery (done)
- Each cube type levels up from squares broken on it, drones' included: +5% pay per level on its squares and clear bonus, up to level 10 (+50%). Level N takes N(N+1)/2 cubes' worth of its squares (1 cube for level 1, 55 for level 10). Its shop row shows the level and a bar; a "MASTERY UP!" toast announces each level.
- Kept across runs, so each run climbs the early ladder a little faster, and cheap cubes level fastest per HP spent.
- The count is a lifetime stat per cube (`broken:<id>`), ready for achievements ("Master 5 cubes").
- Ideas: a perk that speeds mastery, a run-end line showing the levels gained in the run.

## Phase 4: always show the next goal (done)

- **Locked silhouettes (done as unlock goals):** cubes and upgrades unlock through goals (clear cubes, break squares, earn money), and each list teases its cheapest locked item with the goal and progress.
- **Next goal:** at the bottom of the field (the top-left column was full, and the income readout needs the room next to the money): the locked item whose goal is furthest along, its goal, a bar and what it unlocks. Unlocks are kept across runs, so once they're all done it shows the achievement closest to earned instead.
- **Income per minute:** "+1.2K/min" next to the money counter, from earnings over the last minute. Removed after playtesting: not wanted.
- **Stats page ([T]):** lifetime totals, records and bonuses. Lifetime clicks and time mining are new stats, added up as runs end.

## The Fallen Star (done)

- A light story: a star fell and lies under every layer of stone. A new game opens on a story card; the first purchase of each deep cube shows a line; breaking the Star Core frees the star (victory effects, an ending screen, the Starlight achievement), then play goes on.
- The color cubes became materials (Lapis, Sandstone, Slate, Jasper; ids unchanged). Tektite (1B), Iridium Bar (10B) and Opal (100B) went in between Magma and Void, which moved to 1T.
- The Star Core (1Qa, 12x12, 25,000 clicks a square) unlocks after 3 Void Cubes. Blasts only chip it, a crit deals 10 hits, nothing converts on it, it pays nothing. Starsteel Edge (a perk, 50K Shards every tier) adds a click per tier to hits on it.
- Toughness is the gate, money the lesser one (the user's call). Tuned with a bot that plays runs (rewrite it from the plan in `docs/superpowers/plans/2026-10-31-fallen-star-ending.md`, Task 7):
  - With the core at 2000 clicks a square the bot won at run 11. A 1.5x-per-tier Starsteel price made late damage grow only with the log of Shards, so no toughness gave a steady finish (at 24,000 it never won in 40 runs). A flat price fixed that: every run's Shards add damage, and each try gets further.
  - Final numbers, four campaigns: core reached at runs 10-13, star freed at runs 20-25. In the run that first reaches them the bot clears about 3 Tektite, 4 Iridium Bars, 4 Opal and 3-4 Void. Late runs reach the money cap (`Game.MAX_AMOUNT`), as accepted.
- Ideas: a perk or upgrade that helps drones on the core; showing the best core attempt on the run-end screen; a New Game+.

## Balance notes from playtesting (to fix next)

From the user's save after 6 runs (51 minutes of mining in all). Run 6 lasted 25 minutes:
721 clicks, 477 cubes cleared, 6.7Qa earned (past the Star Core's 1Qa) and 51,212 Shards,
against 43 Shards from the five runs before it. It ended out of boredom: the pickaxe wasn't
going to break. The records show how: 89 one-click clears (22 Opal, 17 Void, 8 Iridium Bars,
8 Magma, 7 Tektite), a biggest click of 694 squares and a chain of 85 blasts. Explosives and
lightning chains plus frenzies (Money x7 above all) did it. The feeling of obliterating
cubes in one click is wanted, but near the end of the game, not by run 5 or 6.

- **Chains clear deep cubes too early.** A blast breaks any square outright, however deep the cube, so a few percent of explosives and lightning wipe out Void Cubes in one click. Options: blasts deal clicks off instead of breaking (like the Star Core's `blast_damage`), growing with Blast Radius tiers or a late perk; a cap on chain links per click; lower or later Explosive and Lightning chances.
- **Runs stop ending.** Income climbs 4 to 10 times with each cube step and chains make clicks nearly free, so the Whetstone (25 HP, 4x the price each time) and Unbreakable keep the pickaxe going. Options: Whetstone prices that follow the run's earnings, a limit per run, or charging some HP for blast breaks.
- **One run pays for every perk.** Shards are ∛(earnings ÷ 50), so one huge run pays far more than every run before it. All the perks but Starsteel Edge cost about 11K Shards together (Shard Resonance's 10 tiers are most of it), so one 6.7Qa run covers all of them, or Starsteel Edge's first tier with change to spare. Options: a steeper root or a log, perk prices that climb faster, more Shard sinks before Starsteel.
- **Frenzies multiply the problem.** Money x7 on top of chains, made longer by Gold Fever. Options: a smaller multiplier, or one that grows with Lucky Charm tiers instead.
- **The tuning bot is too timid.** It clicks the spot with the most squares and buys the cheapest upgrades, so it neither aims at explosives nor plans around frenzies. It reached the core around runs 10-13; the player was past 1Qa in run 6. Retune with a bot that plays chains, or from playtest saves.
- **Sharp Pickaxe takes clicks off flat.** Cheap cubes fall to 1 click, and at high tiers a pricier cube can pay less a click than the one below (at Sharp 26 a Gold Bar takes 1 click for 300, Platinum 4 clicks for 900). Clicks now rise with every step up the ladder, so a pricier cube never takes fewer clicks a square, but a percentage cut would keep the ladder's ratios at every tier (see "Sharp Pickaxe fades" below).

## Tuning notes and smaller ideas

- **Sharp Pickaxe fades:** -1 click per tier matters less as cube clicks grow (Void squares take 100). Options: make it a percentage, or add a "Heavy Pickaxe" that adds damage per hit.
- **Drone pacing:** drones hit 1.5 times a second for 1 damage each, so big cubes take them a while. Watch whether they feel useful in the mid game. Possible levers: base rate, a Drone Drill upgrade (+1 damage per tier), a smarter-targeting upgrade (explosives first).
- **Endless cubes:** past the Void Cube, generate cube tiers on the fly (price `1B × 6^N`, a palette rotated from the existing ones) so the ladder never runs out.
- **Several auto-buy picks:** let each Auto-Buyer tier pick its own cube instead of one cube for every slot.
- **Art:** the clean pixel look is still a placeholder. Late cubes (Meteorite, Magma, Void) are dark and could use emblems or custom tiles to stand out.
