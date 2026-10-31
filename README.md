# Incremental Block Mining

A small incremental game made in Godot 4.5. You buy cubes, which are grids of squares, and
break the squares with a pickaxe to earn money. Then you spend that money on bigger cubes and
better tools. The pickaxe wears down with every click: when it breaks, the run ends, and the
Shards it paid buy perks that make the next run last longer.

## Running it

1. Install [Godot 4.5](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot` in the editor and press **F5**, or run from a terminal:

   ```sh
   godot --path .
   ```

## How to play

**The story.** Long ago a star fell here and sank beneath every layer of stone. You're digging
down to it. A new game opens on a card that tells you so (one click to begin). Each dig is a
run: when your pickaxe breaks, the tunnel caves in and you start again a little stronger,
thanks to the Shards, splinters of the star's light. The Star Core, the star itself, waits at
the bottom of the shop; breaking it is the ending. The first time you buy each of the deep
cubes (Meteorite, Magma, Tektite, Iridium Bar, Opal, Void and the Star Core), a line of the
story shows above the field, once ever.

You start with 20 money, enough for your first Lapis Cube, and a pickaxe with 100 HP. Open the
shop, buy it, and click its squares until they break. Every broken square pays out right
away. Broken squares stay behind as faint outlines until the whole cube is gone.

| Key   | Action                                          |
|-------|-------------------------------------------------|
| B     | Break mode: click squares to hit them           |
| M     | Move mode: drag cubes around the field          |
| S     | Open or close the shop                          |
| U     | Open or close upgrades                          |
| A     | Open or close achievements                      |
| T     | Open or close stats                             |
| Esc   | Pause menu                                      |
| =     | Dev cheat: +100K money (debug builds only)      |
| -     | Dev cheat: send a Lucky Cube now (debug builds only) |

A red dot on the Upgrades tab means a new upgrade (or its next tier) has become affordable.

Each sidebar page remembers how far you scrolled it, so switching pages and back, or
closing the sidebar, keeps your place. At the bottom of the field, the next goal shows with a progress bar: the locked cube or upgrade closest to unlocking, or once
everything is unlocked, the achievement closest to earned.

The Stats page ([T]) lists lifetime totals (time mining, runs, clicks, squares, cubes,
money, Shards, Lucky Cubes), records (the best run's clicks, time, cubes and money, the
biggest click, the longest chain, one-click clears) and bonuses (the Shard and achievement
boosts, achievements earned, cubes mastered). Time mining counts only time in runs, not
pauses or the run-end screen. Lifetime clicks and time count from the version that added
the page.

### Unlocking cubes and upgrades

You start with only the Lapis Cube. Every other cube and most upgrades unlock as you clear
cubes, one step at a time down the ladder, so new things arrive one or two at once instead of
in a flood. Each list shows its cheapest locked item dimmed, with its goal and your progress
("Clear 2 Lapis Cubes (1/2)"). When a goal is met, an "UNLOCKED!" toast names what's new and
its tab gets a red dot. Both lists are sorted by the price of the next tier, cheapest first,
with maxed upgrades at the bottom; they re-sort when you open them, so rows don't move while
you buy.

| Clearing your... | 1st                | 2nd                | 3rd              |
|------------------|--------------------|--------------------|------------------|
| Lapis Cubes      |                    | Sandstone Cube     | Diamond Squares  |
| Sandstone Cubes  | Sharp Pickaxe      |                    | Slate Cube       |
| Slate Cubes      | Explosive Squares  | Mining Drone       | Jasper Cube      |
| Jasper Cubes     | Big Pickaxe        | Lucky Strike       | Jade Cube        |
| Jade Cubes       | Steady Hands       | Clean Sweep        | Obsidian Cube    |
| Obsidian Cubes   | Lightning Squares  | Gold Bar           |                  |
| Gold Bars        | Coin Pouches       | Platinum Cube      |                  |
| Platinum Cubes   | Prospector         | Hot Streak         | Amethyst Cube    |
| Amethyst Cubes   | Multiplier Squares | Lucky Charm        | Emerald Cube     |
| Emerald Cubes    | Gold Fever         | Auto-Buyer         | Ruby Bar         |
| Ruby Bars        |                    | Meteorite          |                  |
| Meteorites       |                    |                    | Rose Quartz Cube |
| Rose Quartz Cubes |                   |                    | Magma Cube       |
| Magma Cubes      |                    |                    | Tektite Cube     |
| Tektite Cubes    |                    | Iridium Bar        |                  |
| Iridium Bars     |                    |                    | Opal Cube        |
| Opal Cubes       |                    |                    | Void Cube        |

The Whetstone is there from the start. Blast Radius and Drone Overclock need no goal: they
show up once you own Explosive Squares, and once you've bought a Mining Drone in the run. Upgrades you already own always stay
listed. Each upgrade's first tier costs about one or two of the cubes that unlock it, and
later tiers climb steeply, so upgrades stay worth saving for all the way down the ladder.

### Combos, crits and clearing cubes

- **Combo:** each click that hits something adds x0.1 to what your clicks pay, up to x2. It
  drops back to x1 when a second passes without a hit. The meter under the money counter
  shows the multiplier and the time left. Drone hits don't count toward it and don't get it.
- **Crits:** each of your hits has a 2% chance to break the square outright, whatever clicks
  it had left, with a gold flash and "CRIT!". Only squares more than one click from breaking can crit, and
  drones never do.
- **Clear bonus:** finishing a cube pays a quarter of its squares' value on top (x1.25),
  shown as a "CLEAR!" banner. Cubes the drones finish get it too.

### Cube mastery

Every square you break on a cube counts toward that cube type's mastery, whether your
clicks, explosions or drones broke it. Each mastery level makes that cube type's squares,
and its clear bonus, pay 5% more, up to level 10 (+50%, "Mastered"). Level N takes N(N+1)/2
cubes' worth of its squares: the first cube you clear of a type gets it to level 1, then 3
cubes for level 2, 6 for level 3 and 55 for level 10. Mastery is kept from run to run.

Each cube's shop row shows its mastery level, a bar filling toward the next level and its
bonus. A "MASTERY UP!" toast announces each new level.

### Achievements

The Achievements page ([A]) lists 27 milestones, each with its progress. Each one you reach
adds to all earnings for good, on top of the Shard boost: +2%, or +5% for the hard ones,
+93% for all of them. An "ACHIEVEMENT!" toast announces it and badges the tab. The ones
you've earned are listed first, newest on top, and new ones are tagged NEW until you've seen
the page. They're kept from run to run, and goals you'd already met before achievements
existed count right away.

"With one click" counts the chain reaction the click sets off, but not drones' hits. A cube
cleared with one click has to be untouched when the click lands. Run goals count your best
run so far, the one you're in included.

| Achievement | Goal | Earnings |
|-------------|------|---------:|
| Rubble | Break 1000 squares | +2% |
| Landslide | Break 10K squares | +2% |
| Strip Mine | Break 100K squares | +5% |
| Demolition Crew | Clear 100 cubes | +2% |
| Wrecking Ball | Clear 1000 cubes | +5% |
| Into the Void | Clear 1 Void Cube | +5% |
| One and Done | Clear 1 cube with one click | +2% |
| Midas Touch | Clear 1 Gold Bar with one click | +5% |
| Wide Swing | Break 100 squares with one click | +2% |
| Chain Reaction | Set off 10 explosive or lightning squares with one click | +2% |
| Fireworks | Set off 25 explosive or lightning squares with one click | +5% |
| Second Wind | Make a run last 300 clicks | +2% |
| Iron Grip | Make a run last 1000 clicks | +2% |
| Marathon | Make a run last 2500 clicks | +5% |
| Millionaire | Earn 1M in total | +2% |
| Motherlode | Earn 1B in one run | +2% |
| Tycoon | Earn 1T in total | +5% |
| Lucky Streak | Catch 10 Lucky Cubes | +2% |
| Charmed Life | Catch 100 Lucky Cubes | +5% |
| Specialist | Master 1 cube (mastery 10) | +2% |
| Connoisseur | Master 5 cubes (mastery 10) | +5% |
| Grandmaster | Master 18 cubes (mastery 10) | +5% |
| Seasoned Miner | Finish 10 runs | +2% |
| Lifer | Finish 50 runs | +5% |
| Shard Collector | Earn 100 Shards | +2% |
| Crystal Hoard | Earn 10K Shards | +5% |
| Starlight | Free the star | +5% |

### Lucky Cubes and frenzies

After every 60 to 120 squares you break (a random number each time), a golden Lucky Cube
drifts across the field with a chime, taking about 14 seconds to cross. Squares your clicks
break count, explosions and lightning included; drones' don't, so you can't wait one out.
Click it before it leaves to start a frenzy, picked at random. Most last 30 seconds;
Unbreakable is counted in clicks instead:

| Frenzy          | Effect                                                     |
|-----------------|------------------------------------------------------------|
| Money x7        | Every square pays 7x, drones' hits and the clear bonus too |
| Diamond Rush    | Every cube that lands is solid diamond (explosives stay)   |
| Drone Overdrive | Drones hit 3x as fast (only picked while drones are out)   |
| Unbreakable     | A shield on the pickaxe: your next 60 clicks on squares cost no HP |

A running frenzy and its time left show under the combo meter; Unbreakable's shield shows as
a bar on top of the HP bar, shrinking with each click. Squares broken while a frenzy runs or
the shield is up don't count toward the next Lucky Cube. Timed frenzies aren't saved
(quitting ends one), but the shield is.

### Runs: the pickaxe's HP

Every click that hits a square costs the pickaxe 1 HP, however many squares it breaks.
Missing costs nothing, and neither do drones or the explosions and lightning a click sets
off. The HP bar under the money counter flashes once it's low, and the cursor's pickaxe
cracks. During a run, the **Whetstone** repairs 25 HP, each repair costing 4x the last.

When the HP runs out, the pickaxe breaks and the run is over: the field collapses and the
run-end screen takes over. (The pause menu's **End run** breaks it early.) It shows the run's
time, clicks, cubes cleared and money earned, marking new records, and pays **Shards**: the
cube root of (money earned in the run ÷ 50), rounded down, so 50 pays 1, 400 pays 2, 50K
pays 10 and 50M pays 100. The bar under the HP bar fills toward the run's next Shard, and
the number next to it, your Shards plus the run's so far, goes up each time it fills.

- Money, upgrades, the cubes on the field, drones and the Auto-Buyer's pick reset.
- Shards, perks, unlocked cubes and upgrades, cube mastery, achievements and lifetime stats stay.
- Every Shard you've ever earned adds 2% to all earnings, spent or not.

Shards buy perks on the run-end screen, which are kept forever:

| Perk             | Price (Shards)     | Effect                                                    |
|------------------|--------------------|-----------------------------------------------------------|
| Sturdy Handle    | 1, ×1.5 per tier   | The pickaxe gets 25 more HP per tier (no tier limit)      |
| Head Start       | 2, ×4 per tier     | Runs start with 200, then 2K, 20K, 200K money (4 tiers)  |
| Diamond Tips     | 2, ×2 per tier     | Runs start with a free Sharp Pickaxe tier per tier (5 tiers) |
| Drone Bay        | 3, ×2.5 per tier   | Runs start with a drone out per tier (3 tiers)            |
| Drone Plating    | 3, ×2 per tier     | Drones last 20 more hits per tier (5 tiers)               |
| Four-Leaf Clover | 4, ×3 per tier     | Lucky Cubes come 10% sooner per tier, on top of Lucky Charm (3 tiers) |
| Standing Order   | 8                  | Runs start with a free Auto-Buyer tier                    |
| Shard Resonance  | 5, ×2.2 per tier   | Each Shard adds 0.5% more, up to 7% per Shard (10 tiers, the last costs 6,000) |
| Starsteel Edge   | 50K, every tier    | Your hits take 1 more click off Star Core squares per tier (no tier limit); listed once the Star Core unlocks, no longer sold once the star is free |

### Saving

Progress saves on its own every 30 seconds, when the window loses focus and when you quit:
money, the pickaxe's HP, upgrades, the auto-buyer's pick, the drones and every cube on the
field, down to the clicks left on each square, plus the story you've seen. Quitting on the
run-end screen or the ending screen brings you back to it. The pause menu has **Reset
progress** (click it twice) to start over, story and all.

Nothing is mined while the game is closed: you pick up exactly where you left off.

Amounts of 10,000 or more are shortened to one decimal, rounded down: 10.3K, 2.5M, then B, T,
Qa (quadrillions) and Qi (quintillions).

### Cubes

| Cube     | Price | Squares | Clicks per square | Pays per square |
|----------|------:|--------:|------------------:|----------------:|
| Lapis    |    20 |     4x4 |                 1 |               2 |
| Sandstone |   30 |     4x4 |                 2 |               3 |
| Slate    |    50 |     4x4 |                 5 |               5 |
| Jasper   |   150 |     6x6 |                 8 |              10 |
| Jade     |   400 |     6x6 |                12 |              25 |
| Obsidian |  1200 |     8x8 |                24 |              50 |
| Gold Bar |  3000 |     8x3 |                27 |             300 |
| Platinum |   12K |     6x6 |                30 |             900 |
| Amethyst |   50K |     7x7 |                36 |           3,000 |
| Emerald  |  200K |     8x8 |                44 |           9,500 |
| Ruby Bar |    1M |     8x3 |                52 |            140K |
| Meteorite |   5M |     9x9 |                60 |            220K |
| Rose Quartz | 25M |    8x8 |                70 |           1.45M |
| Magma    |  150M |    10x6 |                85 |            9.6M |
| Tektite  |    1B |     9x9 |               110 |             52M |
| Iridium Bar | 10B |    8x3 |               118 |            1.7B |
| Opal     |  100B |     8x8 |               125 |            6.8B |
| Void     |    1T |     8x8 |               150 |             68B |

Clicks per square rise with every step up the ladder, so a pricier cube never breaks
faster: a Bar is small and rich, not easy. From Platinum on, each square has an 8% chance
to be rock, except in the three Bars. Rocks take twice the clicks and pay nothing, but the
cube is done without them: they crumble when its last other square breaks, and drones leave
them alone. Prospector turns them into ore worth 3x a square.

The first seven cubes pay back between 1.6x and 2.7x their price in squares, or 2x to 3.3x
with the clear bonus. From Platinum to Magma, each cube costs 4 to 7 times the one before and
pays back a little more; past Magma, each costs 10 times the one before (Tektite 1B, Iridium
Bar 10B, Opal 100B, Void 1T) and pays back about 4x, counting rocks as worthless, so money
keeps multiplying into the trillions. Combos pay more on top of that. Jade fits a maxed Big
Pickaxe in one hit, Obsidian is big and tough enough that explosives pay off most there, and
the shimmering Gold Bar, Ruby Bar and Iridium Bar are the jackpots.

### The Star Core

The shop's last row, shown from your first run, is the Star Core: where the dig ends. It
unlocks after you clear 3 Void Cubes and costs 1Qa. It's a 12x12 cube whose squares take
25000 clicks each (3.6M in all), and it doesn't fall to shortcuts:

- Explosions and lightning that reach it take 1 click off its squares instead of breaking them.
- A crit on it deals 10 hits' worth instead of breaking a square outright.
- No special squares turn up on it: no diamonds, explosives, multipliers or rocks.
- Drones can hit it, 1 click a hit. Your own hits take more with the Starsteel Edge perk.
- Its squares pay nothing and earn no mastery, and it doesn't count as a cube cleared.

Only one can be out at a time, and the Auto-Buyer can't buy it. While it's out, a bar at the
top of the field shows the clicks it still needs. If your pickaxe breaks first, it collapses
with the rest of the mine, and the money is gone.

The price is the easy part: by the time the core unlocks, a run earns far more than 1Qa. What
breaks it is a build. Each Starsteel Edge tier costs the same 50K Shards, so every run's
Shards turn into more damage, and each try gets further than the last. In tuning, a bot that
plays well reached the core around run 10-13 and freed the star around run 20-25.

### Freeing the star

Break the Star Core's last square and the star is free: the mine goes white, the star swells
out of the stone and rises off the top of the screen. (A chain reaction your last click set off
counts, even if that click used your pickaxe's last HP.) The ending screen follows, with a
summary of the whole dig: time mining, runs, clicks, cubes cleared and Shards. **Keep mining**
ends that run as usual, paying its Shards, and play goes on: the Star Core's row says Freed
and isn't sold again, and the Starlight achievement is yours. Quitting on the ending screen
brings you back to it.

### Upgrades

Each tier of an upgrade costs a fixed multiple of the tier before it, rounded to two
significant digits.

| Upgrade         | Price                     | Effect                                                         |
|-----------------|---------------------------|----------------------------------------------------------------|
| Diamond Squares | 60                        | Each square has a 15% chance to turn into a diamond, which pays 5x and takes 3x the clicks |
| Sharp Pickaxe   | 100, ×1.6 per tier        | Each tier makes squares take 1 click less (never below 1); no tier limit |
| Lucky Strike    | 300, ×2.5 per tier        | Each tier adds 2% crit chance, up to 20% (9 tiers)             |
| Big Pickaxe     | 250 / 2,500 / 25,000      | One click hits 2x2, then 4x4, then 6x6 squares (3 tiers)       |
| Explosive Squares | 75, ×2.5 per tier       | Each square has a 1% chance per tier to turn explosive, up to 10% (10 tiers) |
| Blast Radius    | 500 / 3,000 / 18,000      | Explosions reach 1 more square per tier (3 tiers); listed once you own Explosive Squares |
| Coin Pouches    | 5,000, ×3.5 per tier      | Each square has a 2% chance per tier to turn into a coin pouch, up to 10% (5 tiers) |
| Lightning Squares | 3,000, ×4 per tier      | Each square has a 1% chance per tier to turn into lightning, up to 5% (5 tiers) |
| Multiplier Squares | 80,000, ×6 per tier    | Each square has a 1% chance per tier to turn into a multiplier, up to 3% (3 tiers) |
| Prospector      | 25,000                    | Rocks in new cubes turn into ore, worth 3x a square            |
| Clean Sweep     | 1,000, ×3.5 per tier      | Each tier adds x0.25 to the clear bonus, up to x3.25 (8 tiers) |
| Steady Hands    | 1,500, ×5 per tier        | Each tier gives combos 0.25s more between hits, up to 2s (4 tiers) |
| Hot Streak      | 20,000, ×6 per tier       | Each tier raises the combo cap by x0.5, up to x4 (4 tiers)     |
| Lucky Charm     | 100,000, ×5 per tier      | Lucky Cubes come 15% sooner (fewer squares) per tier, up to 60% (4 tiers) |
| Gold Fever      | 300,000, ×6 per tier      | Frenzies last 5s longer per tier, up to 50s, and Unbreakable holds 10 more clicks, up to 100 (4 tiers) |
| Whetstone       | 40, ×4 per repair         | Repairs 25 of the pickaxe's HP; the price resets each run      |
| Mining Drone    | 150, ×1.3 per drone       | A drone that flies to squares and hits them 1.5 times a second, then breaks after 60 hits. Up to 10 at once; the price resets each run |
| Drone Overclock | 2,000, ×3 per tier        | Drones hit 25% faster per tier (10 tiers); listed once you've bought a Mining Drone |
| Auto-Buyer      | 400K / 2M / 10M           | Keeps 1, then 2, then 3 cubes of your pick on the field        |

A diamond always takes 3x the clicks of the cube's other squares, counted after Sharp
Pickaxe: when Slate squares drop from 5 clicks to 1, Slate diamonds drop from 15 to 3.

Drones pick the nearest square no other drone is working on and drill it until it breaks.
Their hits pay out like your clicks and cost the pickaxe nothing, and they set off
explosives too. Each drone's HP shows on a bar above it. They leave alone the cube you're
dragging.

Once you own the Auto-Buyer, every cube in the shop gets an **Auto** toggle. Turn it on for
one cube and the auto-buyer buys that cube whenever the field has fewer unfinished cubes than
its tier keeps there.

An explosive square breaks in one click and blows up every square around it, paying for all
of them, however many clicks they had left. Explosives caught in a blast go off a moment
later, so they chain. Blasts also reach squares on other cubes that touch, so drag cubes
together before you set one off.

The other special squares:

| Square     | Clicks | Pays | What it does |
|------------|-------:|-----:|--------------|
| Lightning  | 1      | 1x   | Breaks every square in its row and column, on its cube and on any cube lined up with it. Explosives and lightning it hits go off next, like a chain |
| Coin Pouch | 1x     | 4x   | Bursts in a fountain of coins |
| Multiplier | 1x     | 1x   | While it's unbroken, every square on its cube pays 2x (a green frame marks the cube). Break it last; drones do |
| Ore        | 1x     | 3x   | What Prospector turns rocks into |

Diamonds stay the toughest and richest: 3x the clicks and 5x the value.

The shop won't sell you an upgrade if paying for it would leave you unable to afford the
cheapest cube. Money still sitting in unbroken squares counts toward that.

## Project layout

| Folder      | Contents                                                              |
|-------------|-----------------------------------------------------------------------|
| `autoload/` | `Game` (money, upgrades, rules) and `Sfx` (sound effects generated in code) |
| `cubes/`    | Cube and square scripts, plus `.tres` resources for each cube and square type |
| `shop/`     | Base class for things that can be bought, and the cube listings       |
| `upgrades/` | The upgrade base class, one script per kind of upgrade, and their resources |
| `world/`    | The play field (input, spawning, dragging), drones, the auto-buyer, camera shake, background |
| `fx/`       | Particles, debris, shockwaves, flying coins                           |
| `ui/`       | HUD, sidebar pages, shop rows, pause menu, pixel cursor, theme, ASCII sprites |

Cubes, squares and upgrades are data: to add a new one, create a `.tres` resource and add it
to a sidebar page's `items` list in `main.tscn`.

What's planned next is in [ROADMAP.md](ROADMAP.md).

## Credits

The [Silkscreen](https://github.com/googlefonts/silkscreen) font is used under the SIL Open
Font License 1.1 (see `assets/fonts/Silkscreen-OFL.txt`). All other art and sound is generated
in code.
