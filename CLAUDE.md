# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Incremental cube-mining game: Godot 4.5.1, GDScript, GL Compatibility renderer. The README has the
player-facing rules and current economy numbers.

## Commands

The Godot binary is not on PATH:

```sh
G="/Users/mihai/Godot games/Godot.app/Contents/MacOS/Godot"
"$G" --path .                                    # run the game
"$G" --headless --import --path .                # refresh the class cache (needed after adding a class_name)
"$G" --headless --path . --quit-after 30         # smoke test: loads main.tscn, prints script errors
```

There's no test suite, lint config or CI. Behavior was checked with throwaway harness scripts
(`extends SceneTree`) kept outside the repo, run with `-s`:

```sh
perl -e 'alarm 60; exec @ARGV' "$G" --headless --path . -s /path/to/check.gd
```

- macOS has no `timeout`, so `perl alarm` stops a hung harness.
- A harness calls `change_scene_to_file("res://main.tscn")`, waits a few `process_frame`s, drives
  the scene through `Game`, `WorkArea.spawn_cube` or `Cube.hit_at`, prints results, then calls `quit()`.
- Inject keys with `Input.parse_input_event`. Mouse events need `root.get_final_transform() * pos`.
- For screenshots, drop `--headless`, `await RenderingServer.frame_post_draw`, and save `root.get_texture().get_image()`.
- ObjectDB leak warnings on a forced harness quit come from the harness's pending coroutines or audio, not from game code.
- Autoloads aren't global identifiers in a `-s` script: fetch `root.get_node("Game")`, and keep the harness untyped. A member typed as a game class compiles game scripts before `Game` exists and floods the output with "Identifier not found: Game".
- Headless runs don't print GDScript warnings. To check for them, copy the project to a temp folder, set `debug/gdscript/warnings/<name>=2` there to make them errors, and run the smoke test on the copy.

## Architecture

**Content is data.** These are `Resource` classes with `.tres` instances:

| Class | Instances | Defines |
|---|---|---|
| `CubeType` | `cubes/types/` | price, grid size, default `SquareType` |
| `SquareType` | `cubes/squares/` | hp, value, palette, shimmer |
| `ShopItem` subclasses | `shop/items/`, `upgrades/items/` | what can be bought |

- A `SquareType` can set `hp_multiplier` or `value_multiplier` above 0. It then scales off the containing cube's default square, which is how diamonds give 5x value and 3x clicks on any cube.
- A `SquareType` with `blast_radius` above 0 is explosive, and its `emblem` names a `PixelSprites` sprite drawn on the tile.
- Shop contents live in `main.tscn`, in the `items` arrays of the `ItemListPage` nodes under `Hud/Root/Sidebar/Panel/VBox/PageScroll/Pages`. A new cube or upgrade needs a `.tres` file plus an entry there.

**`Game` autoload (`autoload/game.gd`) is the rules engine.**
- It holds money, owned upgrade levels and `field_value`, the money still left in unbroken squares.
- Gameplay never hardcodes upgrade effects. It asks `Game.get_square_hp`, `Game.roll_square_type`, `Game.get_pickaxe_size` or `Game.get_blast_radius`.
- Each of those folds over every owned `Upgrade`, calling its hook: `modify_square_hp`, `modify_square_type`, `modify_pickaxe_size` or `modify_blast_radius`.
- To add a new kind of upgrade, subclass `Upgrade` and override a hook. If no existing hook fits, add one to `Upgrade` plus a matching fold in `Game`.

**Upgrade tiers.** `max_level` 0 means unlimited. The price of the next tier is `price × (level + 1)`. Tiered upgrades show the tier in the description ("Tier 2: ..."), never an "x/y" counter. `SquareChanceUpgrade.chance_per_tier` makes the chance grow per tier. An upgrade with `requires` set stays out of the shop until that upgrade is owned.

**Soft-lock guard.** `Game.would_soft_lock(cost)` returns true when `money - cost + field_value` would be below the cheapest cube's price. `Upgrade.can_purchase` refuses those purchases, and the shop row shows "Keep N for a cube". Cubes register themselves for this check via `CubeShopItem.on_listed`.

**Purchase to payout flow:**
1. `ShopItem.purchase()` spends the money.
2. `CubeShopItem` calls `Game.deliver_cube`, which emits `cube_purchased`.
3. `WorkArea.spawn_cube` spawns the cube.
4. When `Cube.landed` fires, `WorkArea` converts squares through `Game.roll_square_type`, staggered so each conversion pops.
5. In break mode, `WorkArea._break_at` hits every square that `get_squares_in_reach` returns, while `_resolving_click` is set.
6. Explosives the click broke go off in the same click (`WorkArea._detonate`), breaking every square `get_squares_in_blast` returns, across cubes. Explosives caught in a blast are the next link of the chain, set off `CHAIN_DELAY` later and resolved like a click of their own.
7. Hits and breaks are collected and resolved once per click: one `Game.earn`, one `Fx.squares_hit`/`squares_broken`, one sound. A Big Pickaxe click that breaks 36 squares produces one payout popup, not 36.
8. The last square emits `Cube.completed`, which triggers the explosion fx, a short hitstop, and `queue_free`.

**Fx (`fx/fx.gd`).** All "juice" goes through this node as named recipes (`squares_broken`, `cube_exploded`, `explosion`, ...): particles, debris chunks, shockwave, camera trauma shake, hitstop via `Engine.time_scale`, and flying coins. The HUD money counter only catches up as coins arrive, through `Hud.on_coin_arrived`.

**Sidebar UI.** `Sidebar` holds `SidebarPage` children. Each page names its `tab_button` and `toggle_action`.
- `ItemListPage` builds a `ShopItemRow` for each item.
- With `notify_when_affordable`, a page reports `has_news()` when an item becomes buyable at a price the player hasn't seen while the page was open. The seen key is the item id plus its price, so a new tier counts as news again. The sidebar shows a badge on that page's tab.
- Rows refresh on `money_changed`, `field_value_changed` and `upgrade_purchased`. `money_changed` fires before the upgrade level increments, so a refresh on money alone shows a stale tier.

## Conventions and gotchas

**Pixel art:**
- The game renders at 640x360 (viewport stretch, fractional scale), with nearest filtering and 2D pixel snapping.
- UI fonts are Silkscreen on an 8px grid: regular at 8, bold at 16. Other sizes blur.
- Sprites (cursor, coins, badge) are ASCII grids in `ui/pixel_sprites.gd`.
- Tiles, icons and effects are drawn in `_draw()`. There are no image assets.
- Colors come from the Sweetie 16 palette.

**Input:**
- Read the mouse position from input events (`WorkArea._mouse_screen`, `get_mouse_world_position`), not from `get_global_mouse_position()`. That function reads the OS mouse, so it misses injected events.
- World clicks go in `_unhandled_input`, so the GUI can block them. Drag release is caught in `_input`, so it still fires over UI.
- The OS cursor is hidden. `ui/pixel_cursor.gd` draws a software cursor that changes with the mode.

**Pause.** The pause menu uses `get_tree().paused`. `PauseMenu` and `CursorLayer` run with `PROCESS_MODE_ALWAYS`. `WorkArea` drops any held cube on `NOTIFICATION_PAUSED`.

**Processing.** Godot enables `_process` on any node that defines it. Nodes that don't always need it, like non-shimmering squares, call `set_process(...)` in `_ready`.

**Warnings.** Keep scripts warning-free:
- Use `/ 2.0` or `floori`/`ceili`, never bare integer division.
- Don't shadow built-ins like `show` or `open`.
- Annotate the element type on typed array literals.

**Working with the user.** They playtest builds themselves. Make the change, check it with a headless harness, and skip rounds of clarifying questions.
