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
- The Star Core (1Qa, 12x12, 25,000 clicks a square, 12,000 since the balance pass) unlocks after 3 Void Cubes. Blasts only chip it, a crit deals 10 hits, nothing converts on it, it pays nothing. Starsteel Edge (a perk, 50K Shards every tier, 10K since the balance pass) adds a click per tier to hits on it.
- Toughness is the gate, money the lesser one (the user's call). Tuned with a bot that plays runs (rewrite it from the plan in `docs/superpowers/plans/2026-10-31-fallen-star-ending.md`, Task 7):
  - With the core at 2000 clicks a square the bot won at run 11. A 1.5x-per-tier Starsteel price made late damage grow only with the log of Shards, so no toughness gave a steady finish (at 24,000 it never won in 40 runs). A flat price fixed that: every run's Shards add damage, and each try gets further.
  - Final numbers, four campaigns (superseded by the balance pass below, whose bot plays much better): core reached at runs 10-13, star freed at runs 20-25. In the run that first reaches them the bot clears about 3 Tektite, 4 Iridium Bars, 4 Opal and 3-4 Void. Late runs reach the money cap (`Game.MAX_AMOUNT`), as accepted.
- Ideas: a perk or upgrade that helps drones on the core; showing the best core attempt on the run-end screen; a New Game+.

## Balance pass (done)

The user's save after 6 runs (51 minutes of mining in all): run 6 lasted 25 minutes, 721
clicks, 477 cubes cleared, 6.7Qa earned (past the Star Core's 1Qa) and 51,212 Shards against
43 from the five runs before it, and it ended out of boredom with the pickaxe nowhere near
breaking. 89 one-click clears (22 Opal, 17 Void), a 694-square click and an 85-blast chain.
The user wants the feeling of obliterating cubes in one click, but near the end of the game.

- **A stronger tuning bot reproduced it.** It aims at explosives and lightning first, leaves a new cube alone until its special squares have popped up, catches 90% of Lucky Cubes, clicks 4 times a second and ends a run past 30 game-minutes. With the old numbers it sat on Slate for runs 1-7, then reached 1.5e16 in run 8 and the Star Core by run 9-11. The Fallen Star's bot never aimed at explosives, so its pacing was too optimistic.
- **What drove it**, from switching one part of play off at a time and from variants:
  - **The Shard boost**, 2% per Shard: 4,700 Shards made earnings x95 and 100K made them x2,000, so each big run paid for a bigger one.
  - **Sharp Pickaxe**, unlimited at x1.6 a tier: 47 tiers by run 5 and about 70 later, taking 70 clicks off every square, so Meteorite and everything below it broke in one click.
  - **Payout multipliers** (combo up to x4, the clear bonus up to x3.25, Money x7, the Shard boost, diamonds): one cleared cube paid for a cube two tiers up, so money never held a run back. Weakening Clean Sweep, Hot Streak and Money x7, or spreading upgrade prices across the ladder, barely changed reach. Neither did capping Whetstones, or blast damage alone.
  - **Toughness** did: once the deep cubes took more clicks, reach followed HP and damage, about a tier per run.
- **Changes:**
  - Blasts take 5 clicks off each square they reach (overlaps add up) instead of breaking it. The new Blasting Powder perk adds 1 per tier (5 Shards, x1.35), so chains wear down deep cubes early and obliterate them late.
  - The Shard boost is +25% per doubling of the Shards ever earned; Shard Resonance adds 2.5% per doubling per tier.
  - Sharp Pickaxe stops at 20 tiers (Diamond Tips still adds 5 free ones). The Tempered Steel perk raises the limit to 30, then 40 (500 and 5,000 Shards, listed once a Meteorite is cleared), so the pickaxe keeps growing across runs instead of within one.
  - Deep cubes take more clicks: Amethyst 38, Emerald 47, Ruby Bar 56, Meteorite 68, Rose Quartz 82, Magma 100, Tektite 130, Iridium Bar 140, Opal 155, Void 185 (was 36 to 150).
  - The Star Core takes 12,000 clicks a square (was 25,000) and Starsteel Edge costs 10K Shards a tier (was 50K): core runs now pay about 30K Shards, not 100-250K.
- **Results**, six 28-run bot campaigns: about a tier a run from run 3-4 (Gold or Amethyst by run 4-5, Ruby 5-6, Magma 7-9, Opal 10-12), Void at run 10-14, the core bought a run later, the star freed at runs 21-23 with the core at 12,000 (22-25 at 15,000). One-click clears of mid cubes come back around run 10 as Blasting Powder grows (46 in one Tektite run). Runs end: about 5-6 game-minutes and 1,200-1,400 clicks for the bot in the late game.
- **With Tempered Steel**, seven more campaigns (four buying perks cheapest first, three buying it as soon as it's listed): tier 1 at runs 7-11, tier 2 at runs 10-15, Void at runs 12-15 and the star freed at runs 19-23, about the same as without it. At 40 tiers (+5 from Diamond Tips) Meteorite squares take 23 clicks instead of 43, but Void squares still take 140 instead of 160: one click per tier matters little against the deepest cubes.
- **Still open:**
  - Runs 1-3 stay on Sandstone and Slate before the climb starts.
  - Every campaign sits on Magma for 2-5 runs before Tektite (3 Magma clears unlock it, and its squares take 130 clicks). Part of that is the bot, which only buys a cube it can clear with 80% of the HP it has left.
  - Frenzies are unchanged: they make money, and money isn't what holds a run back any more.
  - The bot clicks 4 times a second; a person is slower, so runs take them longer in time, though not in clicks.
- **The tuning bot** (throwaway, in a session scratchpad; rewrite it from this): a `SceneTree` script run headless with `--fixed-fps 60` and `--save=<scratch>`. Every 15 frames it clicks where `get_squares_in_reach` scores best (an explosive or lightning square it breaks 1000, a square it breaks 10, a hit 1), skipping cubes seen less than 80 frames ago. Every 30 frames it buys the Star Core if it can, a Whetstone under 20% HP, cubes up to 2 unfinished (the priciest it can afford and clear with 80% of its HP), then the cheapest upgrade that leaves money for that cube. It catches 90% of Lucky Cubes after 45 frames. Between runs it buys perks cheapest first; once Starsteel Edge is listed, small perks first, then Starsteel Edge or Sturdy Handle, whichever adds more core damage per Shard. A copy of the project per variant, with `.tres` values edited, runs several campaigns at once.

## Tuning notes and smaller ideas

- **Sharp Pickaxe:** it stops at 20 tiers, 30 or 40 with Tempered Steel (see the balance pass). If the deepest cubes should fall faster late, add Tempered Steel tiers (`max_level` in its `.tres`), or add a late-game upgrade with a percentage cut or a "Heavy Pickaxe" that adds damage per hit.
- **Drone pacing:** drones hit 1.5 times a second for 1 damage each, so big cubes take them a while. Watch whether they feel useful in the mid game. Possible levers: base rate, a Drone Drill upgrade (+1 damage per tier), a smarter-targeting upgrade (explosives first).
- **Endless cubes:** past the Void Cube, generate cube tiers on the fly (price `1B × 6^N`, a palette rotated from the existing ones) so the ladder never runs out.
- **Several auto-buy picks:** let each Auto-Buyer tier pick its own cube instead of one cube for every slot.
- **Art:** the clean pixel look is still a placeholder. Late cubes (Meteorite, Magma, Void) are dark and could use emblems or custom tiles to stand out.
