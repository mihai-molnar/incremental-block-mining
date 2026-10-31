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

You start with 20 money, enough for your first Blue cube, and a pickaxe with 100 HP. Open the
shop, buy it, and click its squares until they break. Every broken square pays out right
away. Broken squares stay behind as faint outlines until the whole cube is gone.

| Key   | Action                                          |
|-------|-------------------------------------------------|
| B     | Break mode: click squares to hit them           |
| M     | Move mode: drag cubes around the field          |
| S     | Open or close the shop                          |
| U     | Open or close upgrades                          |
| Esc   | Pause menu                                      |
| =     | Dev cheat: +100K money (debug builds only)      |
| -     | Dev cheat: send a Lucky Cube now (debug builds only) |

A red dot on the Upgrades tab means a new upgrade (or its next tier) has become affordable.

### Unlocking cubes and upgrades

You start with only the Blue Cube. Every other cube and most upgrades unlock as you clear
cubes, one step at a time down the ladder, so new things arrive one or two at once instead of
in a flood. Each list shows its cheapest locked item dimmed, with its goal and your progress
("Clear 2 Blue Cubes (1/2)"). When a goal is met, an "UNLOCKED!" toast names what's new and
its tab gets a red dot. Both lists are sorted by the price of the next tier, cheapest first,
with maxed upgrades at the bottom; they re-sort when you open them, so rows don't move while
you buy.

| Clearing your... | 1st                | 2nd                | 3rd              |
|------------------|--------------------|--------------------|------------------|
| Blue Cubes       |                    | Yellow Cube        | Diamond Squares  |
| Yellow Cubes     | Sharp Pickaxe      |                    | Grey Cube        |
| Grey Cubes       | Explosive Squares  | Mining Drone       | Red Cube         |
| Red Cubes        | Big Pickaxe        | Lucky Strike       | Jade Cube        |
| Jade Cubes       | Steady Hands       | Clean Sweep        | Obsidian Cube    |
| Obsidian Cubes   | Lightning Squares  | Gold Bar           |                  |
| Gold Bars        | Coin Pouches       | Silver Cube        |                  |
| Silver Cubes     | Prospector         | Hot Streak         | Amethyst Cube    |
| Amethyst Cubes   | Multiplier Squares | Lucky Charm        | Emerald Cube     |
| Emerald Cubes    | Gold Fever         | Auto-Buyer         | Ruby Bar         |
| Ruby Bars        |                    | Meteorite          |                  |
| Meteorites       |                    |                    | Rose Quartz Cube |
| Rose Quartz Cubes |                   |                    | Magma Cube       |
| Magma Cubes      |                    |                    | Void Cube        |

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
- Shards, perks, unlocked cubes and upgrades, cube mastery and lifetime stats stay.
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

### Saving

Progress saves on its own every 30 seconds, when the window loses focus and when you quit:
money, the pickaxe's HP, upgrades, the auto-buyer's pick, the drones and every cube on the
field, down to the clicks left on each square. Quitting on the run-end screen brings you
back to it. The pause menu has **Reset progress** (click it twice) to start over.

Nothing is mined while the game is closed: you pick up exactly where you left off.

Amounts of 10,000 or more are shortened to one decimal, rounded down: 10.3K, 2.5M, then B, T,
Qa (quadrillions) and Qi (quintillions).

### Cubes

| Cube     | Price | Squares | Clicks per square | Pays per square |
|----------|------:|--------:|------------------:|----------------:|
| Blue     |    20 |     4x4 |                 1 |               2 |
| Yellow   |    30 |     4x4 |                 2 |               3 |
| Grey     |    50 |     4x4 |                 5 |               5 |
| Red      |   150 |     6x6 |                 8 |              10 |
| Jade     |   400 |     6x6 |                12 |              25 |
| Obsidian |  1200 |     8x8 |                24 |              50 |
| Gold Bar |  3000 |     8x3 |                20 |             300 |
| Silver   |   12K |     6x6 |                30 |             900 |
| Amethyst |   50K |     7x7 |                36 |           3,000 |
| Emerald  |  200K |     8x8 |                44 |           9,500 |
| Ruby Bar |    1M |     8x3 |                40 |            140K |
| Meteorite |   5M |     9x9 |                60 |            220K |
| Rose Quartz | 25M |    8x8 |                70 |           1.45M |
| Magma    |  150M |    10x6 |                85 |            9.6M |
| Void     |    1B |     8x8 |               100 |             64M |

From Silver on, each square has an 8% chance to be rock, except in the two Bars. Rocks
take twice the clicks and pay nothing, but the cube is done without them: they crumble when
its last other square breaks, and drones leave them alone. Prospector turns them into ore
worth 3x a square.

The first seven cubes pay back between 1.6x and 2.7x their price in squares, or 2x to 3.3x
with the clear bonus. From Silver on, each cube costs 4 to 7 times the one before and pays
back a little more, up to 3.8x (4.7x with the bonus) for the Void Cube counting its rocks as
worthless, so money keeps multiplying into the billions. Combos pay more on top of that. Jade fits a maxed Big Pickaxe in one hit,
Obsidian is big and tough enough that explosives pay off most there, and the shimmering
Gold Bar and Ruby Bar are the jackpots.

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
Pickaxe: when Grey squares drop from 5 clicks to 1, Grey diamonds drop from 15 to 3.

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
