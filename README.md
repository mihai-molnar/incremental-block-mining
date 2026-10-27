# Incremental Block Mining

A small incremental game made in Godot 4.5. You buy cubes, which are grids of squares, and
break the squares with a pickaxe to earn money. Then you spend that money on bigger cubes and
better tools.

## Running it

1. Install [Godot 4.5](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot` in the editor and press **F5**, or run from a terminal:

   ```sh
   godot --path .
   ```

## How to play

You start with 20 money, enough for your first Blue cube. Open the shop, buy it, and click
its squares until they break. Every broken square pays out right away. Broken squares stay
behind as faint outlines until the whole cube is gone.

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

You start with only the Blue Cube. Every other cube and most upgrades unlock by reaching a
goal: clearing cubes (of one kind or any), breaking squares, or earning money in total. Each
list shows its cheapest locked item dimmed, with its goal and your progress ("Clear 2 Blue
Cubes (1/2)"). When a goal is met, an "UNLOCKED!" toast names what's new and its tab gets a
red dot. Both lists are sorted by the price of the next tier, cheapest first, with maxed
upgrades at the bottom; they re-sort when you open them, so rows don't move while you buy.

| Cube        | Unlocks after               | Upgrade            | Unlocks after          |
|-------------|-----------------------------|--------------------|------------------------|
| Yellow      | Clear 2 Blue Cubes          | Diamond Squares    | Clear 2 cubes          |
| Grey        | Clear 3 Yellow Cubes        | Explosive Squares  | Clear 1 Grey Cube      |
| Red         | Clear 4 Grey Cubes          | Sharp Pickaxe      | Clear 1 Yellow Cube    |
| Jade        | Earn 1,500 in total         | Lucky Strike       | Break 250 squares      |
| Obsidian    | Clear 5 Jade Cubes          | Mining Drone       | Earn 500 in total      |
| Gold Bar    | Clear 3 Obsidian Cubes      | Big Pickaxe        | Clear 1 Red Cube       |
| Silver      | Earn 20K in total           | Clean Sweep        | Clear 10 cubes         |
| Amethyst    | Clear 3 Silver Cubes        | Steady Hands       | Break 500 squares      |
| Emerald     | Break 3,000 squares         | Coin Pouches       | Earn 2,000 in total    |
| Ruby Bar    | Clear 5 Emerald Cubes       | Hot Streak         | Break 1,000 squares    |
| Meteorite   | Earn 10M in total           | Lucky Charm        | Earn 3,000 in total    |
| Rose Quartz | Clear 5 Meteorites          | Gold Fever         | Earn 6,000 in total    |
| Magma       | Break 15K squares           | Lightning Squares  | Clear 1 Obsidian Cube  |
| Void        | Earn 1B in total            | Multiplier Squares | Clear 1 Gold Bar       |
|             |                             | Auto-Buyer         | Clear 25 cubes (and own a Mining Drone) |
|             |                             | Prospector         | Clear 1 Silver Cube    |

Blast Radius and Drone Overclock need no goal: they show up once you own Explosive Squares
and a Mining Drone. Upgrades you already own always stay listed.

### Combos, crits and clearing cubes

- **Combo:** each click that hits something adds x0.1 to what your clicks pay, up to x2. It
  drops back to x1 when a second passes without a hit. The meter under the money counter
  shows the multiplier and the time left. Drone hits don't count toward it and don't get it.
- **Crits:** 2% of your hits break the square outright, whatever clicks it had left, with a
  gold flash and "CRIT!". Only squares more than one click from breaking can crit, and
  drones never do.
- **Clear bonus:** finishing a cube pays a quarter of its squares' value on top (x1.25),
  shown as a "CLEAR!" banner. Cubes the drones finish get it too.

### Lucky Cubes and frenzies

Every 2 to 5 minutes a golden Lucky Cube drifts across the field with a chime, taking about
14 seconds to cross. Click it before it leaves to start a 30-second frenzy, picked at random:

| Frenzy          | Effect                                                     |
|-----------------|------------------------------------------------------------|
| Money x7        | Every square pays 7x, drones' hits and the clear bonus too |
| Diamond Rush    | Every cube that lands is solid diamond (explosives stay)   |
| Drone Overdrive | Drones hit 3x as fast (only picked once you own a drone)   |

The running frenzy and its time left show under the combo meter. No Lucky Cube comes while
a frenzy is running, and frenzies aren't saved: quitting ends one.

### Saving

Progress saves on its own every 30 seconds, when the window loses focus and when you quit:
money, upgrades, the auto-buyer's pick and every cube on the field, down to the clicks left
on each square. The pause menu has **Reset progress** (click it twice) to start over.

Nothing is mined while the game is closed: you pick up exactly where you left off.

Amounts of 10,000 or more are shortened to one decimal, rounded down: 10.3K, 2.5M.

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

From Silver on, about 8% of each cube's squares are rock, except in the two Bars. Rocks
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
| Diamond Squares | 60                        | 15% of squares on any cube turn into diamonds, which pay 5x and take 3x the clicks |
| Sharp Pickaxe   | 100, ×1.5 per tier        | Each tier makes squares take 1 click less (never below 1); no tier limit |
| Lucky Strike    | 150, ×1.8 per tier        | Each tier adds 2% crit chance, up to 20% (9 tiers)             |
| Big Pickaxe     | 250 / 500 / 1,000         | One click hits 2x2, then 4x4, then 6x6 squares (3 tiers)       |
| Explosive Squares | 75, ×1.6 per tier       | Each tier turns 1% more squares into explosives, up to 10% (10 tiers) |
| Blast Radius    | 300 / 900 / 2,700         | Explosions reach 1 more square per tier (3 tiers); listed once you own Explosive Squares |
| Coin Pouches    | 500, ×1.7 per tier        | Each tier turns 2% more squares into coin pouches, up to 10% (5 tiers) |
| Lightning Squares | 2,000, ×2 per tier      | Each tier turns 1% more squares into lightning, up to 5% (5 tiers) |
| Multiplier Squares | 3,000, ×2.5 per tier   | Each tier turns 1% more squares into multipliers, up to 3% (3 tiers) |
| Prospector      | 20,000                    | Rocks in new cubes turn into ore, worth 3x a square            |
| Clean Sweep     | 300, ×3 per tier          | Each tier adds x0.25 to the clear bonus, up to x3.25 (8 tiers) |
| Steady Hands    | 350, ×2.5 per tier        | Each tier gives combos 0.25s more between hits, up to 2s (4 tiers) |
| Hot Streak      | 600, ×3 per tier          | Each tier raises the combo cap by x0.5, up to x4 (4 tiers)     |
| Lucky Charm     | 1,200, ×3 per tier        | Lucky Cubes come 15% sooner per tier, up to 60% (4 tiers)      |
| Gold Fever      | 1,500, ×3 per tier        | Frenzies last 5s longer per tier, up to 50s (4 tiers)          |
| Mining Drone    | 150, ×3.5 per tier        | Each tier adds a drone that flies to squares and hits them 1.5 times a second (10 tiers) |
| Drone Overclock | 2,000, ×3 per tier        | Drones hit 25% faster per tier (10 tiers); listed once you own a Mining Drone |
| Auto-Buyer      | 5,000 / 25,000 / 130,000  | Keeps 1, then 2, then 3 cubes of your pick on the field; listed once you own a Mining Drone |

A diamond always takes 3x the clicks of the cube's other squares, counted after Sharp
Pickaxe: when Grey squares drop from 5 clicks to 1, Grey diamonds drop from 15 to 3.

Drones pick the nearest square no other drone is working on and drill it until it breaks.
Their hits pay out like your clicks, and they set off explosives too. They leave alone the
cube you're dragging.

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
