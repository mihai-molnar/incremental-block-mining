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
"$G" --headless --path . --quit-after 30 -- --save=user://smoke.json   # smoke test: loads main.tscn, prints script errors
```

The game saves to `user://save.json` (`~/Library/Application Support/Godot/app_userdata/Incremental Miner/`),
which holds the user's playtest progress. Every run that isn't the user's own passes
`-- --save=<path>` so it reads and writes another file instead.

There's no test suite, lint config or CI. Behavior was checked with throwaway harness scripts
(`extends SceneTree`) kept outside the repo, run with `-s`:

```sh
perl -e 'alarm 60; exec @ARGV' "$G" --headless --path . -s /path/to/check.gd -- --save=/path/to/test_save.json
```

- macOS has no `timeout`, so `perl alarm` stops a hung harness.
- In debug builds the `=` key (`dev_add_money`, handled in `Hud`) adds 100K money, for playtesting expensive content, and the `-` key (`dev_lucky_cube`, handled in `LuckyEvent`) sends a Lucky Cube across right away.
- A harness calls `change_scene_to_file("res://main.tscn")`, waits a few `process_frame`s, drives
  the scene through `Game`, `WorkArea.spawn_cube` or `Cube.hit_at`, prints results, then calls `quit()`.
- To test loading, write a save file first, then run the harness with `--save` pointing at it. `Game` loads it in `_ready`, before the scene.
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

- A `SquareType` can set `hp_multiplier` or `value_multiplier` above 0. It then scales off the containing cube's default square, which is how diamonds give 5x value and 3x clicks on any cube. `Game.get_square_hp` multiplies the default square's hp *after* upgrades, so Sharp Pickaxe shrinks diamonds in proportion.
- A `SquareType` with `blast_radius` above 0 is explosive, and its `emblem` names a `PixelSprites` sprite drawn on the tile.
- Other `SquareType` flags: `strikes_lines` (lightning: breaks its row and column across lined-up cubes), `cube_value_bonus` (multiplier: its cube pays that much more while it's unbroken), `coin_shower` (coin pouch fx) and `required` (false for rocks: `Cube.is_complete` ignores them and drones skip them).
- A `CubeType` can set `mixed_square_type`/`mixed_chance`, so some squares start as another type (rocks in the deep cubes). `Game.roll_square_type(cube_type, current)` starts from that type, and `SquareChanceUpgrade.from_square_type` converts from it (Prospector: rock to ore).
- Keep diamonds the toughest and richest square: other square types stay below 3x clicks and 5x value.
- Shop contents live in `main.tscn`, in the `items` arrays of the `ItemListPage` nodes under `Hud/Root/Sidebar/Panel/VBox/PageScroll/Pages`. A new cube or upgrade needs a `.tres` file plus an entry there.

**`Game` autoload (`autoload/game.gd`) is the rules engine.**
- It holds money, the pickaxe's HP and the current run's numbers, owned upgrade levels and `field_value`, the money still left in unbroken squares.
- Gameplay never hardcodes upgrade effects. It asks `Game.get_square_hp`, `Game.roll_square_type`, `Game.get_pickaxe_size`, `Game.get_blast_radius`, `Game.get_max_pickaxe_hp`, `Game.get_drone_hp`, `Game.get_starting_drones`, `Game.get_drone_hit_rate`, `Game.get_auto_buy_slots`, `Game.get_clear_bonus`, `Game.get_combo_cap`, `Game.get_combo_window`, `Game.get_crit_chance`, `Game.get_payout_multiplier`, `Game.roll_lucky_interval`, `Game.get_frenzy_duration`, `Game.get_starting_money` or `Game.get_shard_bonus`.
- Each of those folds over `Game._modifiers`, calling each one's hook: `modify_square_hp`, `modify_square_type`, `modify_pickaxe_size`, `modify_blast_radius`, `modify_max_pickaxe_hp`, `modify_drone_hp`, `modify_starting_drones`, `modify_drone_hit_rate`, `modify_auto_buy_slots`, `modify_clear_bonus`, `modify_combo_cap`, `modify_combo_window`, `modify_crit_chance`, `modify_payout_multiplier`, `modify_lucky_interval`, `modify_frenzy_duration`, `modify_starting_money` or `modify_shard_bonus`. The base values (`PICKAXE_HP`, `DRONE_HP`, `CLEAR_BONUS`, `COMBO_*`, `CRIT_CHANCE`, `LUCKY_INTERVAL_*`, `FRENZY_DURATION`, `SHARD_*`) are constants at the top of `Game`.
- `_modifiers` is the owned upgrades plus running timed effects (at level 1), rebuilt by `_refresh_modifiers` whenever either changes. Code that edits `_upgrade_levels` directly must call it.
- Timed effects: `Game.add_timed_effect(effect, seconds)` folds any `Upgrade` into the rules for a while. `Game._process` counts them down (pausing with the tree) and emits `timed_effect_started`/`timed_effect_ended`. They aren't saved.
- To add a new kind of upgrade, subclass `Upgrade` and override a hook. If no existing hook fits, add one to `Upgrade` plus a matching fold in `Game`.

**Unlock goals.** Pacing rule: every goal is "clear N of one cube type", staggered so each clear unlocks at most one thing, and an upgrade's first tier costs about one or two of the cube that unlocks it. Money and squares goals cross in bursts once income takes off, so they're kept for achievements, not unlocks.
A `ShopItem` with `unlock` set (a `Goal`, `shop/goal.gd`, stored inline in the item's `.tres`) stays unlisted until its goal is met: `Goal.Stat` is `SQUARES_BROKEN`, `CUBES_CLEARED` (optionally of one `cube_type`) or `MONEY_EARNED`.
- `Game` keeps lifetime stats (`add_stat`, `record_cube_cleared`, `get_stat`; `earn` counts money) and saves them with the resource paths of unlocked items. `WorkArea` counts squares broken in `_resolve_click` and cubes cleared in `_on_cube_completed`.
- Pages call `on_listed`, which registers the item with `Game.register_unlockable`. Goals already met (and upgrades already owned) unlock quietly; later ones emit `items_unlocked`, which `UnlockToast` shows.
- `ShopItem.is_available()` is `is_unlocked() and meets_requirements()` (`Upgrade.requires` is a requirement). Owned upgrades are always available.
- `ItemListPage` sorts rows by `get_price()` (owned items last) in `on_shown`, which the `Sidebar` calls on switching pages, never while a page is open. It shows the cheapest locked item that meets its requirements as a teaser row (`ShopItemRow.set_teaser`). Newly unlocked items badge the page's tab.

**Runs and prestige.** A run lasts as long as the pickaxe: every click that hits a square calls `Game.use_pickaxe`, which takes 1 from `pickaxe_shield` while there's a shield (an Unbreakable frenzy), otherwise from `pickaxe_hp`, however many squares the click hit. Misses, drones and chain reactions are free. `Game.is_run_active()` is false once it's at 0 (or the run is over): clicks, drones, the auto-buyer and Lucky Cubes stop.
- At 0 HP `Game` emits `pickaxe_broken`. `RunEndScreen` (`ui/run_end_screen.gd`, the `RunEnd` CanvasLayer in `main.tscn`) plays `Fx.pickaxe_broken`, waits for chain reactions, then `Fx.mine_collapsed`, `WorkArea.clear_field` and `DroneSwarm.clear`, and calls `Game.end_run()`.
- `end_run` pays `get_run_shards()` (the cube root of `run_earned` ÷ `SHARD_EARNINGS`, rounded down), keeps the run's summary in `last_run` (its keys that beat `best_run` under `records`), removes every upgrade that isn't a perk, clears timed effects and the auto-buyer's pick, sets `run_over` and saves.
- While `run_over` is set, `RunEndScreen` covers the screen and keeps the tree paused (the pause menu leaves it paused too). It shows the summary, the Shards and the perks list (an `ItemListPage` built in code from its `perks` export). A save with `run_over` reopens it. Start next run calls `Game.start_run()` (pickaxe at `get_max_pickaxe_hp()`, money at `get_starting_money()`, Drone Bay's drones handed to the swarm through `_loaded_save`) and reloads the scene.
- The pause menu's End run calls `Game.break_pickaxe()`, which ends the run the same way.
- Perks are `Upgrade`s with `costs_shards`: `_pay` spends `Game.shards`, they skip the soft-lock guard, they show a shard next to the price, and `end_run` keeps their levels.
- A perk that boosts a regular upgrade is a `FreeTiersUpgrade` (hook `get_free_tiers_target`): each of its levels is a free tier of `target`. `Game.get_upgrade_level` counts free tiers (so the target's row, description and effect show them), while `get_bought_level`, which prices, caps (`is_maxed`) and saving use, doesn't. Don't make a perk a second copy of the upgrade it boosts: the shop row would ignore it.
- `get_payout_multiplier` starts from `1 + get_shard_boost()` (every Shard ever earned times `get_shard_bonus()`), so the boost reaches clicks, drones and the clear bonus.
- `RunMeter` (under `Hud/Root`) draws the HP bar, the shield's bar on top of it while `pickaxe_shield` > 0, and the Shard bar (`get_shard_progress()` toward the next) with the Shards owned plus what the run pays so far. The cursor's pickaxe cracks under half HP.

**Upgrade tiers.** `max_level` 0 means unlimited. The price of the next tier is `price × price_growth^bought` (free tiers from perks don't count), rounded to two significant digits from 100 up (`Upgrade._round_price`). Each `.tres` sets its own `price_growth` (default 1.5). Tiered upgrades show the tier in the description ("Tier 2: ..."), never an "x/y" counter. `SquareChanceUpgrade.chance_per_tier` makes the chance grow per tier. An upgrade with `requires` set stays out of the shop until that upgrade is owned.
Mining Drone (`DroneUpgrade`) and Whetstone (`RepairUpgrade`) are bought again and again, with `max_level` 0: their level counts this run's purchases, so each costs more than the last, and `_apply` launches a drone or repairs the pickaxe.

**Soft-lock guard.** `Game.would_soft_lock(cost)` returns true when `money - cost + field_value` would be below the cheapest cube's price. `Upgrade.can_purchase` refuses those purchases, and the shop row shows "Keep N for a cube". Cubes register themselves for this check via `CubeShopItem.on_listed`.

**Saving (`Game.save_game`, `user://save.json`).**
- JSON with money, upgrade levels, the auto-buyer's cube, Shards, the pickaxe's HP and shield, `run_over`, the run so far, `last_run`, `best_run`, `saved_at`, the field's cubes and the drones' HP. Resources are stored by `resource_path`, so renaming a `.tres` drops it from old saves (loading skips paths that no longer exist).
- Saves on a 30s timer, on `NOTIFICATION_WM_CLOSE_REQUEST` and `NOTIFICATION_APPLICATION_FOCUS_OUT`, and from the pause menu's Quit.
- `Game` saves its own state, then emits `saving(data)` so other nodes add theirs. `WorkArea` adds the cubes (`Cube.get_save_data`: each square's clicks left and its type when it isn't the cube's default), and `DroneSwarm` the drones.
- On load, a node takes its part back once with `Game.take_saved(key)`. `WorkArea._restore_cubes` rebuilds cubes with `Cube.load_save_data`, which marks them landed so their squares don't convert again.
- There are no offline earnings, on purpose: nothing is mined while the game is closed. `saved_at` is only a record.
- `Game.reset_progress` deletes the file and clears state; the pause menu then reloads the scene.

**Drones and the auto-buyer.**
- Buying a Mining Drone calls `Game.launch_drone`; `DroneSwarm` (under `Main`, drawn above `WorkArea`) adds a `Drone` with `Game.get_drone_hp()` hits, up to `Game.MAX_DRONES`, and keeps `Game.drones_out` current. Each hit costs the drone 1 HP (the bar above it); at 0 it breaks (`Fx.drone_broken`) and the rest close ranks.
- Each drone takes the nearest unbroken square no other drone has (`find_target`), skipping the held cube, rocks, and multiplier squares while their cube has other squares left.
- A drone hit goes through `WorkArea.drone_hit`, which resolves it like a click with `soft` effects: no shake, quieter sound, fewer coins. The cursor doesn't swing for it.
- `AutoBuyer` checks every 0.5s and buys `Game.auto_buy_cube` (spend plus `deliver_cube`) while fewer unfinished cubes than `Game.get_auto_buy_slots()` are on the field.
- The shop row shows an Auto toggle when `ShopItem.can_auto_buy()` is true; `CubeShopItem` sets `Game.auto_buy_cube`, which allows only one pick.

**Purchase to payout flow:**
1. `ShopItem.purchase()` spends the money (the `AutoBuyer` spends directly).
2. `CubeShopItem` calls `Game.deliver_cube`, which emits `cube_purchased`.
3. `WorkArea.spawn_cube` spawns the cube.
4. When `Cube.landed` fires, `WorkArea` converts squares through `Game.roll_square_type`, staggered so each conversion pops.
5. In break mode, `WorkArea._break_at` adds a hit to the `Combo` node (if it hit anything), then hits every square that `get_squares_in_reach` returns, while `_resolving_click` is set, and charges the pickaxe (`Game.use_pickaxe`) if it hit anything. Each square rolls `Game.get_crit_chance()`; a crit deals the square's remaining hp and plays `Fx.critical_hits`. Drone (`soft`) hits never crit.
6. Explosives the click broke go off in the same click (`WorkArea._detonate`), breaking every square `get_squares_in_blast` returns, across cubes. Lightning squares are blasts too, breaking what `get_squares_in_lines` returns. Explosives and lightning caught in a blast are the next link of the chain, set off `CHAIN_DELAY` later and resolved like a click of their own.
   Every hit inside a resolution goes through `WorkArea._hit`, which notes each cube's `_get_cube_bonus` (multiplier squares times mastery) on first contact. Breaks pay `square.value` times that snapshot, so a click that breaks a multiplier square still pays it on everything it broke.
7. Hits and breaks are collected and resolved once per click: one `Game.earn`, one `Fx.squares_hit`/`squares_broken`, one sound. A Big Pickaxe click that breaks 36 squares produces one payout popup, not 36. Payouts are the squares' value times `Game.get_payout_multiplier()` (Shard boost, frenzies) and, for non-soft clicks, the combo multiplier; `WorkArea._payout_carry` carries rounding leftovers to the next payout. Chain links keep the `soft` flag of the click that started them.
8. The last square emits `Cube.completed`. `WorkArea` pays the clear bonus (`Game.get_clear_payout` of `Cube.get_total_value` times the cube type's mastery) right away, then plays a short hitstop, the explosion fx, the `cube_cleared` banner, and `queue_free`.

**Lucky Cubes (`world/lucky_event.gd`).** `LuckyEvent` (under `Main`, after `WorkArea` so it sees clicks first) counts down `Game.roll_lucky_interval()` squares as `WorkArea.squares_broken` reports them: the player's clicks and their chain reactions count, drones' (`soft`) squares don't, so it can't be waited out. The count pauses while a cube is out, `Game.has_timed_effects()`, the pickaxe is shielded or the run isn't active. It sends a `LuckyCube` drifting across. Clicking it starts a random useful `Frenzy` from its `frenzies` array (`Frenzy.start`): a timed effect for `Game.get_frenzy_duration()`, or a shield. A `Frenzy` (`upgrades/frenzy.gd`, instances in `upgrades/frenzies/`) is an `Upgrade` that's never sold: its exports set a payout multiplier, a square type for landing cubes, a drone rate multiplier, or `shield_clicks` (Unbreakable). `Frenzy.start` adds a timed effect, or for a shield frenzy calls `Game.add_pickaxe_shield` (clicks scaled like durations by Gold Fever) instead. Payouts apply `Game.get_payout_multiplier()` in `WorkArea._resolve_click` and `Game.get_clear_payout`. `FrenzyMeter` (under `Hud/Root`) shows running frenzies.

**Cube mastery.** `Game.add_mastery(cube_type, squares)` counts squares broken on a cube type in the lifetime stat `broken:<id>` (`get_mastery_stat`), so it's saved and kept across runs. `WorkArea._resolve_click` reports every break, drones' and chains' included.
- `get_mastery_level` reads the level off `get_mastery_threshold` (N(N+1)/2 cubes' worth of squares for level N, up to `MASTERY_MAX_LEVEL`). `get_mastery_multiplier` (+`MASTERY_BONUS` a level) multiplies the cube's value in `WorkArea._get_cube_bonus` and its clear payout. Square values themselves (`CubeSquare.value`, `field_value`, the shop's "Pays N each") stay unmastered.
- A click's `_clicked_value` adds up unrounded, so +5% still counts on 2-coin squares.
- `MasteryMeter` (built by `ShopItem.create_meter`) draws it on cube rows. `MasteryToast` sits above `UnlockToast` (both extend `Toast`) and announces `mastery_leveled_up`.

**Combo (`world/combo.gd`).** A node under `Main` holding the hit count and time left; it emits `changed` on each hit and when it drops. `ComboMeter` (under `Hud/Root`) draws it below the money counter.

**Fx (`fx/fx.gd`).** All "juice" goes through this node as named recipes (`squares_broken`, `critical_hits`, `cube_cleared`, `lucky_caught`, `cube_exploded`, `explosion`, ...): particles, debris chunks, shockwave, camera trauma shake, hitstop via `Engine.time_scale`, and flying coins. The HUD money counter only catches up as coins arrive, through `Hud.on_coin_arrived`.

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

**Money text.** Show every money amount through `Currency.format` (`ui/currency.gd`). It shortens 10,000 and up to one decimal (10.3K, 2.5M), rounded down.

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
