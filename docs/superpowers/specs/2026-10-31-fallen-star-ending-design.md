# The Fallen Star: a story and an ending

Date: 2026-10-31. Status: design, awaiting the user's approval.

## Intent

The game has no end goal yet: runs get longer, Shards and perks pile up, and the cube
ladder tops out at the Void Cube (1B), which late runs earn many times over. This adds a
light story with a real ending. A star fell long ago and lies buried under every layer of
stone; the player digs down to it. The last item in the shop, the **Star Core**, is the
star itself: a very tough cube that one strong run, where money, upgrades, HP and drones
all come together, can break. Breaking it is the victory moment.

The player should know from the first minute that the Star Core is where the dig leads.

## Decided with the user

- Story: "The Fallen Star". Light: an opening, a short line the first time each deeper
  layer is reached, and the ending. Not walls of text.
- The game ends with a victory moment when the Star Core breaks.
- The Star Core is broken in **one final run**. Damage does not carry across runs.
- The player may be able to afford it before they can break it. The blockers are both
  money and upgrades (pickaxe strength, HP, drones...).
- Cube names are materials, not colors. Rename the four color cubes everywhere the
  player sees them (shop, achievements, notifications, goal meter, stats, docs).
- The money ladder should reach T and Qa: roughly a cube at 1B, one at 1T (Void), and the
  Star Core at 1Qa. Void stays the last cube before the core. Exact numbers may move.
- **Toughness is the main gate, money the lesser one.** Late runs may reach the money cap
  (`Game.MAX_AMOUNT`, ~9.2Qi), which makes the core's price easy by then; that's
  accepted. Don't retune the Shard economy or switch money to a bigger number type to
  keep the price meaningful.
- The user accepted these proposals (they are decided, not open):
  - Renames: Blue → **Lapis**, Yellow → **Sandstone**, Grey → **Slate**, Red → **Jasper**
    (cube and square display names), keeping the existing palettes.
  - Three new cubes between Magma and Void: **Tektite Cube** (~1B), **Iridium Bar**
    (~10B, a jackpot bar like Gold and Ruby), **Opal Cube** (~100B). Void moves to ~1T,
    the Star Core is ~1Qa.
  - The Star Core is always visible in the shop as its last row, locked and glowing,
    from the first run.
  - The core's squares resist cheese: blasts (explosives, lightning) only chip them and a
    crit deals heavy damage instead of breaking a square outright. No special squares
    spawn on it.
  - "Pickaxe strength" is new: damage per hit, as a perk.
  - A big HP bar for the core while it's on the field.
  - Shards stay Shards; their copy calls them splinters of the star's light. A run is a
    dig; the pickaxe breaking is the tunnel caving in.
  - Grandmaster becomes "Master 18 cubes". The Star Core has no mastery.
  - After the ending the player can keep playing.

## Goals

1. A player always knows the end goal: the opening says it, the Star Core row shows it.
2. The ending is earned by a strong build: enough HP, damage, pickaxe size and drones to
   break the core before the pickaxe does. Affording it in the run is a smaller hurdle.
3. The ladder reaches T and Qa prices, so the shop stays relevant in late runs.
4. Renames and new content follow the existing data-driven patterns (CLAUDE.md).

## Non-goals

- Cutscenes, dialogue, characters, voice. The story is a few lines of text.
- Several endings, New Game+ mechanics, or a prestige layer above Shards.
- An art overhaul. New cubes use Sweetie 16 palettes and the existing tile drawing.
- Renaming the Lucky Cube or other systems beyond copy. (The earlier "Lucky Cube as a
  wisp of starlight" idea was a maybe; leave it out.)

## Anti-goals (would make this a failure even if it works)

- The core falls to a lucky chain reaction, a crit streak or an idle swarm of drones.
- Story text that interrupts play for more than a click, or shows more than once.
- Losing the user's playtest progress: saves must keep working (see Saving).
- The ending reachable by waiting: per the existing rule, nothing rewards waiting.
- Copy that doesn't say exactly what the code does (a standing user rule).

## The story

Exact wording is the builder's, within these beats and in this tone (wonder, a little
cosmic, plain words):

- **Opening** (new game: no save, and after Reset progress): a full-screen card over the
  field before play. Gist: "Long ago a star fell here. It lies buried under every layer
  of stone. Dig down to it." Mentions that the Star Core waits at the bottom of the shop.
  One click to begin.
- **Layer lines**: a short line the first time the player *buys* each of these cubes
  (once ever, saved): Meteorite, Magma, Tektite, Iridium Bar, Opal, Void and Star Core.
  Example: Meteorite "The rock is scorched, as if something burned through it." Void
  "Nothing reflects. You must be close." Shown as a toast-style banner that doesn't
  pause or block clicks. The builder may add lines for earlier cubes if they read well.
- **Ending**: see Victory.
- **Copy reframing**: Shards are described as splinters of the star's light (run-end
  screen, README). The pickaxe breaking reads as the tunnel caving in where the run-end
  screen says the run is over. No mechanics change.

## Renames

Change `display_name` only, on the cube types and their default square types:
Blue → Lapis (Cube), Yellow → Sandstone, Grey → Slate, Red → Jasper.

**Keep ids and file paths** (`blue_cube.tres`, `id = &"blue"`, `cleared:blue`,
`broken:blue`): saves store progress under them, so renaming them would wipe unlocks and
mastery for those cubes. All UI reads `display_name`, so shop rows, teasers, toasts,
goals, the goal meter and stats follow. Update README tables, ROADMAP and CLAUDE.md, and
code comments that name the old colors.

## Ladder extension

| Cube | Price (start) | Notes |
|---|---|---|
| Magma | 150M | unchanged |
| Tektite Cube | ~1B | new; glass melted by the star's impact |
| Iridium Bar | ~10B | new; 8x3 jackpot bar like Gold Bar and Ruby Bar |
| Opal Cube | ~100B | new; shimmering, first hint of starlight |
| Void Cube | ~1T | repriced from 1B; square values scaled to match |
| Star Core | ~1Qa | new; the goal (see below) |

- Each new cube is a `CubeType` + default `SquareType` + `CubeShopItem` `.tres`, added
  to the shop page's `items` in `main.tscn`, like the existing ones.
- Each unlocks with "clear N of the cube before it" (N = 2 or 3, following the existing
  one-unlock-per-clear pacing rule); Void's goal moves to Opal.
- Each pays back about 4x its price in squares (like the later existing cubes) and takes
  more clicks per square than the one before. Deep non-bar cubes get 8% rocks like the
  others from Silver on.
- Squares stay below diamonds: no square type over 3x clicks or 5x value (CLAUDE.md).
- Palettes from Sweetie 16, distinct from neighbors: Tektite a dark bottle green/teal
  glass, Iridium a cold silver-white metal bar, Opal pale with a shimmer (`shimmer =
  true`). Builder picks the exact colors.
- Mastery works on them like any cube. Grandmaster's goal becomes 18 (every cube type
  except the Star Core).
- "Into the Void" (Clear 1 Void Cube) stays; it's now much later.

## The Star Core

- **In the shop**: last row of the Shop page, always shown (not only when it's the
  cheapest locked teaser), glowing, with its lock and goal while locked. Unlock: clear
  3 Void Cubes. Price ~1Qa. Not auto-buyable. One on the field at a time.
- **Shape and toughness** (starting points, tuned): about 12x12 squares, each taking
  hundreds of hits. A distinct look: a bright star palette with shimmer.
- **Rules on its squares**:
  - They take damage per hit from the new pickaxe-strength perk (below), times 1 for a
    normal hit.
  - A crit deals a heavy fixed multiple of a hit (say 10x), not the square's remaining HP.
  - Explosions and lightning that reach them deal a chip (say one hit's damage each)
    instead of breaking them. Chains still pass through other cubes as usual.
  - No square conversions on landing (no diamonds, explosives, multipliers, rocks).
  - Drones can hit it (one hit = 1 damage, or the perk's damage; builder's call), so they
    help, but drones break after their HP and can't keep a run going (existing rule).
  - Its squares pay nothing. The reward is the ending. (Avoids an absurd payout.)
  - No mastery, not counted toward mastery or "cubes cleared" achievements.
- **Pickaxe strength perk** (Shards, on the run-end screen): each tier adds damage to
  the player's hits **on the Star Core only**, unlimited tiers like Sturdy Handle, so it
  is a second long-term Shard sink. Core-only so it doesn't speed up the tuned economy
  of other cubes or duplicate Sharp Pickaxe. It's listed once the Star Core is unlocked
  (the same goal, as its `unlock`), so nobody spends Shards on it while it can't matter
  and the bot's early perk buying isn't skewed. Name is the builder's (e.g. "Starsteel
  Edge"). Needs a new `Upgrade` hook and `Game` fold per CLAUDE.md.
- **HP bar**: while a Star Core is on the field, a large bar (HUD, top or bottom center,
  wherever it doesn't collide with existing HUD) shows the core's total remaining hits
  across its squares, so the player can watch it come down and judge whether the run
  will make it.
- **If the run ends first**: the core collapses with the field like any cube. The money
  is gone. Mid-run saves keep it on the field like other cubes.

## Victory

- When the last Star Core square breaks: the run stops (no more clicks), a long build-up
  (hitstop, white flash, light pouring out), then the star rising off the top of the
  screen. Fx recipes in `Fx`, sounds via `Sfx`.
- Then an **ending screen**, full screen like the run-end screen: the ending text ("The
  star rises..."), and a summary: time mining, runs, clicks, cubes cleared, Shards earned
  (from the Stats data). A button to keep mining.
- The run that freed the star ends normally: it pays its Shards, the run-end screen
  follows "Keep mining", and the next run starts as usual.
- The save records that the star is freed (and when, in runs). After that:
  - The Star Core row shows as freed (not for sale again).
  - Everything else keeps working: records, achievements, mastery.
  - A new achievement for freeing the star (bonus like the hard ones).
- Reset progress clears it and shows the opening again.

## Saving

- New save keys: story lines seen, the opening seen, star freed (+ run number).
- Old saves load: the four renamed cubes keep their ids, so progress stays. Saves without
  the new keys treat the opening as **seen** if they have any progress (stats), so an
  existing player isn't shown the intro mid-game; the builder may instead show it once on
  next launch if that reads better.
- Void's reprice applies to existing saves; a Void cube already on the field keeps its
  squares' saved hits.

## Numbers and tuning

- Every number here is a starting guess; the user tunes by playtesting.
- Tune with a bot that plays runs (the earlier one was a throwaway in a session
  scratchpad; rewrite it: clicks at ~4/s on the best spot, buys the best cube it can
  clear, cheapest upgrades, Whetstones when low, catches 70% of Lucky Cubes, buys perks
  cheapest first, `--fixed-fps`).
- Targets:
  - Each new cube is a stop of 2-4 clears in a run that reaches it.
  - The core becomes **affordable** a few runs before it becomes **breakable**, and is
    breakable around run 20-25 of the bot's play.
  - Breaking it takes most of a strong run's HP and drones: a weak build that buys it
    must fail.
- The main lever is the core's toughness (square HP, size) against HP, the perk, pickaxe
  size and drones. Keep the price near 1Qa even if late runs earn far more or reach the
  money cap (the user's call). Report where late runs land against the cap.

## Docs

README (story section, cube table, perks, achievements, Star Core), ROADMAP (mark done,
move leftovers), CLAUDE.md (Star Core rules, story, new hook, save keys).

## Calls made without the user (for them to check)

- The pickaxe-strength perk affects the Star Core only, and is listed once the core
  unlocks.
- Story lines trigger on the first purchase of each deep cube, once ever.
- Existing saves with progress skip the opening.
- The core's squares pay nothing; the core isn't auto-buyable; one at a time.
- Drones can hit the core.
- Freeing the star ends that run normally (Shards paid), then play continues; the core
  row shows as freed and isn't sold again; a new achievement marks it.
- Renamed cubes keep their ids and file names so saves keep their progress.

## Left to the builder

Exact wording of the story lines; palettes; grid sizes, prices, values and HP within the
targets; the perk's name and per-tier damage and price growth; the core's crit and blast
damage; where the core HP bar sits; the victory effects; whether drones deal perk damage.
