# Roadmap

The plan to make the game hold attention the way good incremental games do. Each phase
builds on the one before. All numbers are starting guesses to tune by playtesting.

## Phase 1: the idle core (done)

- Saving and offline earnings: autosave, a welcome-back panel, and Reset progress in the pause menu.
- Mining Drone, Drone Overclock and Auto-Buyer upgrades.
- Upgrade prices that multiply per tier (`price_growth`).
- Eight more cubes after the Gold Bar, from Silver (12K) to Void (1B).

## Phase 2: make clicks feel lucky

Unpredictable rewards are the strongest hook in the genre.

### Done
- **Clear bonus:** finishing a cube pays x1.25 of its value, with a "CLEAR!" banner. Clean Sweep adds x0.25 per tier.
- **Combo meter:** +x0.1 per player hit up to x2, dropping after 1s without a hit. Hot Streak raises the cap, Steady Hands the window. Drone hits don't count.
- **Critical hits:** 2% of player hits break a square outright. Lucky Strike adds 2% per tier.
- **Diamonds scale after upgrades:** they take 3x the clicks of their cube's squares as Sharp Pickaxe lowers them, instead of a fixed 3x of the base.

### Golden events
- Every 2-5 minutes a meteor or "Lucky Cube" drifts across the field. Clicking it starts a 30s frenzy, picked at random from:
  - x7 money
  - every new square is a diamond
  - drones at triple speed
- New node `world/lucky_event.gd`. It reads its spawn interval and frenzy length from hooks, so upgrades can tune them.
- The frenzy is a timed modifier that `Game` folds in alongside upgrades. A good shape is `Game.add_timed_effect(effect, seconds)`, with effects being `Upgrade`-like objects that use the same hooks.

### More special squares
These are `SquareType` resources. Each needs a `SquareChanceUpgrade` to unlock it, plus a little code where noted.
- **Lightning:** breaking it clears its whole row and column. It's like a blast with a cross shape, so add a `blast_shape` to `SquareType` and a matching query to `WorkArea`.
- **Multiplier:** while unbroken, doubles the value of every square on its cube. Breaking it last is the trick.
- **Coin pouch:** pays a lump sum worth several squares.
- **Rock:** tough and worthless, so the player has to choose where to click. Comes with an upgrade that turns rocks into ore.

## Phase 3: long-term goals

### Prestige ("Collapse the mine")
- Resets money, upgrades and cubes in exchange for Shards.
- Shards earned = `floor(sqrt(lifetime_earned / 1M))`.
- Each Shard gives +X% to all earnings.
- Shards also buy permanent perks, kept across resets: start with more money, keep your drones, start with the Auto-Buyer, a longer offline cap.
- Needs `lifetime_earned` in `Game` (and in the save).
- Shard perks can be `Upgrade`s on a third sidebar page that `reset_progress` doesn't clear. Split `_upgrade_levels` into run levels and permanent levels.

### Achievements
- Milestones that each give a small permanent bonus:
  - Break 1,000 squares: +2% value
  - Set off a 10-explosive chain
  - Clear a Gold Bar in one click
- Needs stat counters in `Game` (squares broken, longest chain, cubes cleared, lifetime earned). Save them too.

### Cube mastery
- Each cube type levels up from squares broken on it (Blue Lv 7: +35% value), with a progress bar on its shop row.
- Gives a reason to keep buying cheap cubes.
- Store the levels by cube id in `Game`. A `modify_square_value` hook would let both mastery and future upgrades scale payouts.

## Phase 4: always show the next goal

- **Locked silhouettes:** list only the next unaffordable cube or upgrade, as "??? - 8K". This needs an `is_revealed()` on `ShopItem`, based on lifetime earnings.
- **Progress bar:** under the money counter, filling toward the next unlock.
- **Income per minute:** shown in the HUD, averaged over the last minute of `money_changed` deltas.
- **Stats page:** a sidebar page with squares broken, longest chain, lifetime earnings and time played.

## Tuning notes and smaller ideas

- **Sharp Pickaxe fades:** -1 click per tier matters less as cube clicks grow (Void squares take 100). Options: make it a percentage, or add a "Heavy Pickaxe" that adds damage per hit.
- **Drone pacing:** drones hit 1.5 times a second for 1 damage each, so big cubes take them a while. Watch whether they feel useful in the mid game. Possible levers: base rate, a Drone Drill upgrade (+1 damage per tier), a smarter-targeting upgrade (explosives first).
- **Offline upgrades:** raise the 2h cap and the 50% efficiency (good prestige perks).
- **Endless cubes:** past the Void Cube, generate cube tiers on the fly (price `1B × 6^N`, a palette rotated from the existing ones) so the ladder never runs out.
- **Several auto-buy picks:** let each Auto-Buyer tier pick its own cube instead of one cube for every slot.
- **Art:** the clean pixel look is still a placeholder. Late cubes (Meteorite, Magma, Void) are dark and could use emblems or custom tiles to stand out.
