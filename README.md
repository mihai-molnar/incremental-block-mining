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

A red dot on the Upgrades tab means a new upgrade (or its next tier) has become affordable.

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

Every cube pays back between 1.6x and 2.7x its price. Jade fits a maxed Big Pickaxe in one
hit, Obsidian is big and tough enough that explosives pay off most there, and the shimmering
Gold Bar is the jackpot.

### Upgrades

| Upgrade         | Price           | Effect                                                         |
|-----------------|-----------------|----------------------------------------------------------------|
| Diamond Squares | 60              | 15% of squares on any cube turn into diamonds, which pay 5x and take 3x the clicks |
| Sharp Pickaxe   | 100 × tier      | Each tier makes squares take 1 click less (never below 1); no tier limit |
| Big Pickaxe     | 250 × tier      | One click hits 2x2, then 4x4, then 6x6 squares (3 tiers)       |
| Explosive Squares | 75 × tier     | Each tier turns 1% more squares into explosives; no tier limit |
| Blast Radius    | 300 × tier      | Explosions reach 1 more square per tier (3 tiers); listed once you own Explosive Squares |

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
| `world/`    | The play field (input, spawning, dragging), camera shake, background  |
| `fx/`       | Particles, debris, shockwaves, flying coins                           |
| `ui/`       | HUD, sidebar pages, shop rows, pause menu, pixel cursor, theme, ASCII sprites |

Cubes, squares and upgrades are data: to add a new one, create a `.tres` resource and add it
to a sidebar page's `items` list in `main.tscn`.

## Credits

The [Silkscreen](https://github.com/googlefonts/silkscreen) font is used under the SIL Open
Font License 1.1 (see `assets/fonts/Silkscreen-OFL.txt`). All other art and sound is generated
in code.
