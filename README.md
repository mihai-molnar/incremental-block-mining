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

| Cube   | Price | Squares | Clicks per square | Pays per square |
|--------|------:|--------:|------------------:|----------------:|
| Blue   |    20 |     4x4 |                 2 |               2 |
| Yellow |    30 |     4x4 |                 2 |               3 |
| Grey   |    50 |     4x4 |                 5 |               5 |
| Red    |   150 |     6x6 |                 8 |              10 |

### Upgrades

| Upgrade         | Price           | Effect                                                         |
|-----------------|-----------------|----------------------------------------------------------------|
| Diamond Squares | 60              | 15% of squares on any cube turn into diamonds, which pay 5x and take 3x the clicks |
| Sharp Pickaxe   | 100 × tier      | Each tier makes squares take 1 click less (never below 1); no tier limit |
| Big Pickaxe     | 250 × tier      | One click hits 2x2, then 4x4, then 6x6 squares (3 tiers)       |

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
