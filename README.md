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

A red dot on the Upgrades tab means a new upgrade (or its next tier) has become affordable.

### Saving and time away

Progress saves on its own every 30 seconds, when the window loses focus and when you quit:
money, upgrades, the auto-buyer's pick and every cube on the field, down to the clicks left
on each square. The pause menu has **Reset progress** (click it twice) to start over.

While the game is closed, your drones keep mining the auto-buyer's cube at half speed, for
up to 2 hours. A "Welcome back" panel shows what they made; Collect (or Esc) pays it out.
Without a drone, the auto-buyer and a picked cube, nothing is earned while you're away.

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

The first seven cubes pay back between 1.6x and 2.7x their price. From Silver on, each cube
costs 4 to 7 times the one before and pays back a little more, up to 4.1x for the Void Cube, so
money keeps multiplying into the billions. Jade fits a maxed Big Pickaxe in one hit,
Obsidian is big and tough enough that explosives pay off most there, and the shimmering
Gold Bar and Ruby Bar are the jackpots.

### Upgrades

Each tier of an upgrade costs a fixed multiple of the tier before it, rounded to two
significant digits.

| Upgrade         | Price                     | Effect                                                         |
|-----------------|---------------------------|----------------------------------------------------------------|
| Diamond Squares | 60                        | 15% of squares on any cube turn into diamonds, which pay 5x and take 3x the clicks |
| Sharp Pickaxe   | 100, ×1.5 per tier        | Each tier makes squares take 1 click less (never below 1); no tier limit |
| Big Pickaxe     | 250 / 500 / 1,000         | One click hits 2x2, then 4x4, then 6x6 squares (3 tiers)       |
| Explosive Squares | 75, ×1.6 per tier       | Each tier turns 1% more squares into explosives, up to 10% (10 tiers) |
| Blast Radius    | 300 / 900 / 2,700         | Explosions reach 1 more square per tier (3 tiers); listed once you own Explosive Squares |
| Mining Drone    | 400, ×1.8 per tier        | Each tier adds a drone that flies to squares and hits them 1.5 times a second (10 tiers) |
| Drone Overclock | 1,000, ×2.2 per tier      | Drones hit 25% faster per tier (10 tiers); listed once you own a Mining Drone |
| Auto-Buyer      | 1,500 / 6,000 / 24,000    | Keeps 1, then 2, then 3 cubes of your pick on the field; listed once you own a Mining Drone |

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
