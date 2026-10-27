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

The first seven cubes pay back between 1.6x and 2.7x their price in squares, or 2x to 3.3x
with the clear bonus. From Silver on, each cube costs 4 to 7 times the one before and pays
back a little more, up to 4.1x (5.1x with the bonus) for the Void Cube, so money keeps
multiplying into the billions. Combos pay more on top of that. Jade fits a maxed Big Pickaxe in one hit,
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
| Clean Sweep     | 300, ×3 per tier          | Each tier adds x0.25 to the clear bonus, up to x3.25 (8 tiers) |
| Steady Hands    | 350, ×2.5 per tier        | Each tier gives combos 0.25s more between hits, up to 2s (4 tiers) |
| Hot Streak      | 600, ×3 per tier          | Each tier raises the combo cap by x0.5, up to x4 (4 tiers)     |
| Lucky Charm     | 1,200, ×3 per tier        | Lucky Cubes come 15% sooner per tier, up to 60% (4 tiers)      |
| Gold Fever      | 1,500, ×3 per tier        | Frenzies last 5s longer per tier, up to 50s (4 tiers)          |
| Mining Drone    | 400, ×1.8 per tier        | Each tier adds a drone that flies to squares and hits them 1.5 times a second (10 tiers) |
| Drone Overclock | 1,000, ×2.2 per tier      | Drones hit 25% faster per tier (10 tiers); listed once you own a Mining Drone |
| Auto-Buyer      | 1,500 / 6,000 / 24,000    | Keeps 1, then 2, then 3 cubes of your pick on the field; listed once you own a Mining Drone |

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
