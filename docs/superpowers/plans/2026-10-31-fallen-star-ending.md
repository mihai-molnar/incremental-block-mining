# The Fallen Star Ending Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the game a light "Fallen Star" story and a real ending: rename the color cubes to materials, extend the cube ladder to T prices, and add the Star Core (~1Qa), a very tough cube whose breaking in one run frees the star.

**Architecture:** Everything stays data-driven: new `CubeType`/`SquareType`/`CubeShopItem`/`Achievement` `.tres` files, a few new exports (`CubeType.is_goal`, `CubeType.story_line`, `SquareType.blast_damage`, `SquareType.crit_multiplier`), one new `Upgrade` hook (`modify_hit_damage`) folded by `Game.get_hit_damage`. `Game` owns the new state (star freed, run won, story seen); `WorkArea` applies the core's hit rules; new UI nodes (`CoreMeter`, `VictoryScreen`, `StoryCard`, `StoryToast`) follow the existing HUD/run-end patterns.

**Tech Stack:** Godot 4.5.1, GDScript, GL Compatibility. No test framework: tests are throwaway `extends SceneTree` harness scripts outside the repo (CLAUDE.md, "Commands").

**Spec:** `docs/superpowers/specs/2026-10-31-fallen-star-ending-design.md`

## Global Constraints

- Renamed cubes keep their ids and file paths (`blue_cube.tres`, `id = &"blue"`, `cleared:blue`, `broken:blue`); only `display_name` changes. Achievement files keep their paths (earned ones are saved by path), e.g. `master_15.tres` keeps its name when its goal becomes 18.
- Toughness is the main gate, money the lesser one. Keep the Star Core's price near 1Qa even if late runs reach the money cap (`Game.MAX_AMOUNT`). Don't retune the Shard economy or change the money type.
- No square type over 3x clicks or 5x value of its cube's default square (diamonds stay toughest and richest).
- Copy must say exactly what the code does. Tiers read "Tier N", never "N/M". Money shows through `Currency.format`.
- Story text never interrupts play for more than one click and never shows twice.
- Nothing rewards waiting.
- Palettes from Sweetie 16; fonts Silkscreen 8 (regular) and 16 (bold) only.
- Scripts stay warning-free (`/ 2.0` or `floori`, no shadowed built-ins like `show`/`open`/`_set`, typed array literals annotated). A static `Game` function is never called through the autoload instance.
- Every harness run passes `-- --save=<scratch path>`; nothing touches `user://save.json`.
- Don't commit: the user asks for commits. The last task ends by asking.

**Shell setup used by every task:**

```sh
G="/Users/mihai/Godot games/Godot.app/Contents/MacOS/Godot"
S=<a scratch directory outside the repo>          # harnesses, saves, screenshots
mkdir -p "$S/tests"
run() { perl -e 'alarm 300; exec @ARGV' "$G" --headless --path . -s "$S/tests/$1.gd" -- --save="$S/$1.json" 2>&1 | grep -E "^(PASS|FAIL|SCRIPT ERROR|ERROR)"; rm -f "$S/$1.json"; }
```

**Harness pattern** (every test file): `extends SceneTree`; `_initialize()` calls `_run.call_deferred()`; `_run` does `change_scene_to_file("res://main.tscn")`, awaits 5 `process_frame`s, gets `Game` with `root.get_node("Game")`, keeps every variable untyped (typed game classes break compilation in `-s` scripts), prints `PASS <name>` or `FAIL <name>: <detail>` per check, then `quit()`. Tests that need a save write one to `$S/<name>.json` first (see CLAUDE.md).

**Checkpoint** (end of every task): `"$G" --headless --import --path .` once if a `class_name` was added; smoke test `"$G" --headless --path . --quit-after 30 -- --save="$S/smoke.json"` prints nothing; warnings check on a copy (CLAUDE.md "Headless runs don't print GDScript warnings": copy the project, append a `[debug]` section setting `gdscript/warnings/<name>=2` for unused_variable, unused_local_constant, unused_parameter, unused_private_class_variable, shadowed_variable, shadowed_variable_base_class, shadowed_global_identifier, integer_division, narrowing_conversion, unreachable_code, standalone_expression, incompatible_ternary, confusable_local_declaration, confusable_local_usage, static_called_on_instance, redundant_await; run the smoke test there) prints nothing.

## Review Focus

1. **Quitting during the victory sequence or on the ending screen, then relaunching:** the ending screen comes back (or the run-end screen, if Keep mining was already pressed); never a run that's neither active nor over, and never the pickaxe-broken flow. Test in Task 5.
2. **The click that breaks the core uses the pickaxe's last HP:** victory wins; `pickaxe_broken` never fires, only one screen shows. Test in Task 5.
3. **Saving with a damaged Star Core on the field, then loading:** the core comes back with its squares' hits, `CoreMeter` shows it, the shop still refuses a second core. Test in Task 3.
4. **One click or chain reaching the core and other cubes at once** (Big Pickaxe overlap, an explosive or lightning next to it): other cubes' squares break and pay as before; core squares only take their chip. Test in Task 3.
5. **Reset progress after freeing the star:** opening card shows again, the core row is locked and for sale again, Starlight is gone. Test in Task 6.

---

### Task 1: Rename the color cubes to materials

**Files:**
- Modify: `cubes/types/blue_cube.tres`, `yellow_cube.tres`, `grey_cube.tres`, `red_cube.tres` (`display_name`)
- Modify: `cubes/squares/blue_square.tres`, `yellow_square.tres`, `grey_square.tres`, `red_square.tres` (`display_name`)
- Modify: `README.md`, `CLAUDE.md`, `ROADMAP.md`, and comments in `shop/goal.gd`, `ui/goal_meter.gd`, `cubes/square_type.gd`, `ui/currency.gd` (anything naming "Blue/Yellow/Grey/Red" cubes)
- Test: `$S/tests/t1_renames.gd`

**Interfaces:**
- Produces: display names `"Lapis Cube"`, `"Sandstone Cube"`, `"Slate Cube"`, `"Jasper Cube"`; squares `"Lapis"`, `"Sandstone"`, `"Slate"`, `"Jasper"`.

- [ ] **Step 1: Write the failing test** `t1_renames.gd`: load the four cube types by their unchanged paths and check `display_name` equals the names above, their `square_type.display_name` equals the square names, ids are still `blue`, `yellow`, `grey`, `red`, and `load("res://shop/items/yellow_cube_item.tres").unlock.get_description() == "Clear 2 Lapis Cubes"`.
- [ ] **Step 2: Run** `run t1_renames`. Expected: FAIL lines for the names.
- [ ] **Step 3: Change the eight `display_name`s.** Palettes stay.
- [ ] **Step 4: Run** `run t1_renames`. Expected: only PASS lines.
- [ ] **Step 5: Update docs.** README: unlock table, cube table, mastery/achievement examples, "first Blue cube" etc. CLAUDE.md and ROADMAP: example names. `grep -rn "Blue Cube\|Yellow Cube\|Grey Cube\|Red Cube\|Blue squares\|Grey squares" --include="*.md" --include="*.gd" .` prints nothing (the `docs/superpowers/` files excepted).
- [ ] **Step 6: Checkpoint.**

### Task 2: Extend the ladder to T prices

**Files:**
- Create: `cubes/squares/tektite_square.tres`, `iridium_square.tres`, `opal_square.tres`; `cubes/types/tektite_cube.tres`, `iridium_bar.tres`, `opal_cube.tres`; `shop/items/tektite_cube_item.tres`, `iridium_bar_item.tres`, `opal_cube_item.tres`
- Modify: `cubes/types/void_cube.tres`, `cubes/squares/void_square.tres`, `shop/items/void_cube_item.tres` (unlock goal), `achievements/items/master_15.tres` (amount), `main.tscn` (ShopPage `items`), `README.md`
- Test: `$S/tests/t2_ladder.gd`

**Interfaces:**
- Produces: cube ids `tektite_cube`, `iridium_bar`, `opal_cube`; Void at `price = 1000000000000`.

Starting numbers (Task 7 tunes them; keep the payback in range):

| Cube | id | price | grid | square hp | square value | mixed rock chance | palette (shadow, base, light, shine; outline `0f1020`) | shimmer |
|---|---|---|---|---|---|---|---|---|
| Tektite Cube | tektite_cube | 1,000,000,000 | 9x9 | 110 | 52,000,000 | 0.08 | `1a1c2c`, `333c57`, `257179`, `a7f070` | no |
| Iridium Bar | iridium_bar | 10,000,000,000 | 8x3 | 105 | 1,700,000,000 | 0 | `3b5dc9`, `94b0c2`, `f4f4f4`, `73eff7` | yes |
| Opal Cube | opal_cube | 100,000,000,000 | 8x8 | 125 | 6,800,000,000 | 0.08 | `94b0c2`, `f4f4f4`, `73eff7`, `a7f070` | yes |
| Void Cube (changed) | void_cube | 1,000,000,000,000 | 8x8 | 150 | 68,000,000,000 | 0.08 | unchanged | unchanged |

Unlock chain (`Goal` CUBES_CLEARED with `cube_type`): Tektite: 3 Magma. Iridium Bar: 2 Tektite. Opal: 3 Iridium Bar. Void: 3 Opal (was 3 Magma). Rocks use `cubes/squares/rock_square.tres` like the other deep cubes.

- [ ] **Step 1: Write the failing test** `t2_ladder.gd`, reading the ShopPage `items` from the scene:
  - prices strictly increase in this order: ... Rose Quartz, Magma, Tektite, Iridium Bar, Opal, Void;
  - for Tektite, Iridium Bar, Opal, Void: `value * squares * (1 - mixed_chance) / price` is between 3.5 and 4.6, and square hp is above the previous cube's;
  - each new item's `unlock` is CUBES_CLEARED of the cube before it with the amounts above, and Void's is 3 Opal;
  - `load("res://achievements/items/master_15.tres").goal.amount == 18` and the ShopPage lists 18 cube items not counting the Star Core (count items whose `cube_type.get("is_goal") != true`, so the test still holds after Task 3).
- [ ] **Step 2: Run** `run t2_ladder`. Expected: FAIL lines.
- [ ] **Step 3: Create the nine `.tres` files and change Void,** copying the structure of `magma_cube.tres`, `magma_square.tres`, `magma_cube_item.tres` (and `ruby_bar*.tres` for the bar). Add the three items to the ShopPage `items` in `main.tscn` before Void.
- [ ] **Step 4: Run** `run t2_ladder`. Expected: only PASS lines.
- [ ] **Step 5: README:** cube table rows, the unlock table ("Magma Cubes" 3rd → Tektite Cube; new rows Tektite 2nd → Iridium Bar, Iridium Bars 3rd → Opal Cube, Opal Cubes 3rd → Void Cube), the payback paragraph, and the Grandmaster row ("Master 18 cubes").
- [ ] **Step 6: Checkpoint.**

### Task 3: The Star Core cube and its rules

**Files:**
- Modify: `cubes/cube_type.gd` (add `is_goal`), `cubes/square_type.gd` (add `blast_damage`, `crit_multiplier`), `cubes/cube.gd` (add hit totals), `shop/shop_item.gd` (add `is_always_shown`), `shop/cube_shop_item.gd`, `ui/shop_item_row.gd`, `world/work_area.gd`, `autoload/game.gd`, `fx/fx.gd` (`squares_broken`), `main.tscn`, `README.md`, `CLAUDE.md`
- Create: `cubes/squares/star_core_square.tres`, `cubes/types/star_core.tres`, `shop/items/star_core_item.tres`, `ui/core_meter.gd`
- Test: `$S/tests/t3_core.gd`

**Interfaces:**
- Consumes: Task 2's Void cube (the core's unlock: 3 Void Cubes).
- Produces:
  - `CubeType.is_goal: bool` (export, default false): the Star Core. Its squares never convert on landing, earn no mastery, don't count as cubes cleared, it can't be auto-bought, one at a time, and breaking it wins (Task 5).
  - `SquareType.blast_damage: int` (default 0 = blasts break it outright; above 0 = a blast takes this many clicks off it).
  - `SquareType.crit_multiplier: float` (default 0.0 = a crit breaks it outright; above 0 = a crit deals this multiple of the hit's damage).
  - `Cube.get_hits_left() -> int` (sum of `hp` over unbroken required squares) and `Cube.get_total_hits() -> int` (sum of `max_hp` over required squares).
  - `WorkArea.get_star_core() -> Cube` (the goal cube on the field, or null).
  - `Game.star_core_out: bool`, kept current by `WorkArea` (`Game.set_star_core_out(out: bool)`).
  - `Game.get_hit_damage(cube_type: CubeType) -> int`: returns 1 in this task (Task 4 adds the fold).
  - `ShopItem.is_always_shown() -> bool` (default false).
- Star Core data: `star_core.tres` id `star_core`, display name "Star Core", price `1000000000000000`, grid 12x12, `is_goal = true`, no mixed squares. `star_core_square.tres` id `star_core`, display name "Star", hp 2000, value 0, `blast_damage = 1`, `crit_multiplier = 10.0`, `shimmer = true`, palette shadow `ef7d57`, base `ffcd75`, light `f4f4f4`, shine `73eff7`. `star_core_item.tres` unlock: CUBES_CLEARED 3 of Void. Listed last in ShopPage `items`.

- [ ] **Step 1: Write the failing test** `t3_core.gd` (give the save `money` near `Game.MAX_AMOUNT` and the core unlocked through `"unlocked"`):
  - `core_listed_while_locked`: on a fresh save the core's row is visible with its lock and goal, untinted.
  - `core_rules`: spawn the core with `WorkArea.spawn_cube`; after it lands no square changed type even with Diamond Squares owned at level 1; `_hit_squares` on one core square deals 1; with crit chance forced to 1.0 (a `CritChanceUpgrade` made in the harness with `chance_per_tier = 1.0`, added with `Game.add_timed_effect(upgrade, 60.0)`) a hit deals 10; a blast via `_detonate` deals 1; `Game.get_stat("broken:star_core") == 0` after breaking a square; no money is earned.
  - `mixed_click` (Review Focus 4): a Lapis cube placed overlapping the core's reach and a 6x6 Big Pickaxe click hits both; Lapis squares break and pay as before (money rises by their value), core squares lose 1 each.
  - `explosive_next_to_core`: an explosive square on a Lapis cube touching the core goes off; neighboring core squares lose `blast_damage`, Lapis squares break.
  - `one_at_a_time`: with the core out, the core item's `can_purchase()` is false and `get_block_reason()` says it's already out; `can_auto_buy()` is always false; `create_meter()` returns null.
  - `core_meter`: `CoreMeter` is visible only while the core is on the field and draws `get_hits_left()` / `get_total_hits()`.
  - `save_reload` (Review Focus 3): damage the core, `Game.save_game()`, reload the scene with that save: the core is back with the same `get_hits_left()`, `Game.star_core_out` is true and `CoreMeter` is visible.
- [ ] **Step 2: Run** `run t3_core`. Expected: FAIL lines.
- [ ] **Step 3: Data and exports.** Add the three exports with doc comments, the two `Cube` totals, and the three `.tres` files; list the item in `main.tscn`.
- [ ] **Step 4: Shop rules.** `CubeShopItem`: `can_auto_buy()` false for the goal; `can_purchase()` also needs `not Game.star_core_out` for the goal; `get_block_reason()` returns "The Star Core is already out" when that's why; `create_meter()` null for the goal; `get_description()` for the goal: "144 squares\n2000 clicks each\nBreak it to free the star" built from its data, no "Pays" line; `is_always_shown()` true for the goal. `ShopItemRow._is_locked_teaser()` is `(_teaser or item.is_always_shown()) and not item.is_available()`, and the icon isn't tinted when `is_always_shown()`.
- [ ] **Step 5: Hit rules in `WorkArea`.** `_on_cube_landed` skips conversions for goal cubes. `_hit_squares`: base damage is 1 for soft hits, else `Game.get_hit_damage(square.cube_type)`; a crit rolls only when `square.hp > base`, and deals `roundi(base * crit_multiplier)` when that's above 0, else `square.hp`. `_detonate` deals `blast_damage` when above 0, else `square.hp`. `_add_mastery` skips goal cube types. `get_star_core()`; call `Game.set_star_core_out(get_star_core() != null)` wherever `_update_field_value()` runs. `Game.get_mastered_count()` skips goal types. `Fx.squares_broken` skips the popup and coins when `payout` is 0.
- [ ] **Step 6: `CoreMeter`** (`ui/core_meter.gd`, `class_name CoreMeter`, `extends Control`, export `work_area: WorkArea`), under `Hud/Root` at top center: `offset_left 156, offset_top 4, offset_right 286, offset_bottom 30` (clear of the income readout at max money and of the sidebar tabs). Draws, with the HUD's drop shadow, a line "Star Core: <Currency.format(hits_left)> clicks left" (8px) over a bar in the core's palette (`RunMeter._draw_bar` style). Hidden when there's no core; polls every 0.1s.
- [ ] **Step 7: Run** `run t3_core`. Expected: only PASS lines.
- [ ] **Step 8: Docs.** README: a "The Star Core" section (price, unlock, size, the rules above, the HP bar, that it collapses with the run). CLAUDE.md: `is_goal`, `blast_damage`, `crit_multiplier`, `star_core_out`, `CoreMeter`.
- [ ] **Step 9: Checkpoint.**

### Task 4: Starsteel Edge, the pickaxe-strength perk

**Files:**
- Modify: `upgrades/upgrade.gd` (hook), `autoload/game.gd` (fold), `main.tscn` (RunEnd `perks`), `README.md` (perk table), `CLAUDE.md` (hook lists)
- Create: `upgrades/core_damage_upgrade.gd`, `upgrades/perks/starsteel_edge.tres`
- Test: `$S/tests/t4_perk.gd`

**Interfaces:**
- Consumes: `CubeType.is_goal` (Task 3), `Game.get_hit_damage` call site (Task 3).
- Produces: hook `Upgrade.modify_hit_damage(cube_type: CubeType, damage: int, level: int) -> int`; `Game.get_hit_damage(cube_type: CubeType) -> int` folds it from 1, at least 1; `CoreDamageUpgrade` (`class_name`, `extends Upgrade`, `@export var damage_per_tier := 1`) adds `damage_per_tier * level` only when `cube_type.is_goal`. `starsteel_edge.tres`: title "Starsteel Edge", price 20, `price_growth` 1.5, `max_level` 0, `costs_shards` true, unlock CUBES_CLEARED 3 of Void (same as the core). Description per CLAUDE.md tier rules, e.g. "Tier 2: your hits take 3 clicks off Star Core squares".

- [ ] **Step 1: Write the failing test** `t4_perk.gd`: with the perk at level 2, `Game.get_hit_damage(star_core) == 3` and `Game.get_hit_damage(lapis) == 1`; a core square hit by a player click loses 3, by `drone_hit` loses 1; with crit forced, a core hit loses 30; the perk is listed on the run-end perk page only once 3 Void Cubes are cleared (`is_available()` false before, true after); its price at bought level 0 is 20 and costs Shards.
- [ ] **Step 2: Run** `run t4_perk`. Expected: FAIL lines.
- [ ] **Step 3: Implement** the hook, the fold, the class and the `.tres`; add it to RunEnd `perks` in `main.tscn`. Icon: `create_sprite_icon(&"star")`.
- [ ] **Step 4: Run** `run t4_perk`. Expected: only PASS lines.
- [ ] **Step 5: Docs:** README perk table row; CLAUDE.md hook and getter lists.
- [ ] **Step 6: Checkpoint.**

### Task 5: Freeing the star (victory)

**Files:**
- Modify: `autoload/game.gd`, `world/work_area.gd` (`_on_cube_completed`), `ui/run_end_screen.gd`, `shop/cube_shop_item.gd`, `shop/goal.gd` (Stat), `fx/fx.gd`, `ui/pixel_sprites.gd`, `main.tscn`, `README.md`, `CLAUDE.md`
- Create: `ui/victory_screen.gd`, `achievements/items/starlight.tres`
- Test: `$S/tests/t5_victory.gd`

**Interfaces:**
- Consumes: `WorkArea.get_star_core()`, `CubeType.is_goal` (Task 3).
- Produces:
  - `Game` state, all saved: `star_free: bool`, `star_freed_in_run: int` (the run number, `get_stat(STAT_RUNS) + 1` at the time), `run_won: bool` (from freeing until `end_run`). Signal `star_freed`.
  - `Game.free_star() -> void`: no-op unless the run is active; sets the three fields, checks achievements, emits `star_freed`, saves.
  - `Game.is_run_active()` also requires `not run_won`. `end_run()` clears `run_won`. `reset_progress()` clears all three.
  - `RunEndScreen.present(animated: bool)` (renamed from `_show`), and its `_ready` resume guard skips the pickaxe-broken flow while `Game.run_won`.
  - `VictoryScreen` (`class_name`, `extends CanvasLayer`, layer 41, `PROCESS_MODE_ALWAYS`, exports `fx`, `work_area`, `drones`, `run_end`, `sidebar`), built in code like `RunEndScreen`.
  - `Fx.star_freed(at: Vector2)`: awaitable, ~3s: hitstop, white flash, light burst, then a big star sprite (new `PixelSprites` `&"fallen_star"`, about 21x21) rising from `at` off the top of the screen, with sound.
  - `Goal.Stat.STAR_FREED` appended (value 1 when `Game.star_free`), description "Free the star". `starlight.tres`: title "Starlight", that goal, bonus 0.05, icon `&"star"`, last in the AchievementsPage list.
  - `CubeShopItem` for the goal: `is_owned()` is `Game.star_free`, `get_owned_label()` "Freed".

- [ ] **Step 1: Write the failing test** `t5_victory.gd`:
  - `victory`: a core with every square at 1 hp (set `hp` on its squares); a player click breaks the last square: `star_freed` fires once, `Game.run_won` and `star_free` are true, `is_run_active()` false, `record_cube_cleared` didn't count it (`cubes_cleared` unchanged), Starlight is earned.
  - `last_hp_click` (Review Focus 2): same, with `pickaxe_hp = 1`: `pickaxe_broken` never fires, `pickaxe_hp` stays 1.
  - `keep_mining`: after the fx, `VictoryScreen` is visible with the tree paused; pressing Keep mining calls `end_run` (Shards paid, `run_won` false, `run_over` true) and the run-end screen shows; the core row says "Freed" and can't be bought.
  - `quit_mid_victory` (Review Focus 1): save while `run_won` (before Keep mining), reload with that save: `VictoryScreen` is showing (no fx), `RunEndScreen` isn't running its pickaxe-broken flow; Keep mining leads to the run-end screen.
- [ ] **Step 2: Run** `run t5_victory`. Expected: FAIL lines.
- [ ] **Step 3: `Game` state, `free_star`, save/load keys `star_free`, `star_freed_in_run`, `run_won`, reset.**
- [ ] **Step 4: `WorkArea._on_cube_completed`** for a goal cube: erase its strike entry, skip the clear bonus, `record_cube_cleared` and one-click record, flash it white, call `Game.free_star()`.
- [ ] **Step 5: `VictoryScreen`.** On `Game.star_freed`: close the sidebar, `await fx.star_freed(core position)`, `work_area.clear_field()`, `drones.clear()`, then show and pause. Content: title "The star is free" (TitleLabel), the ending text (exact copy below), a summary (Time mining, Runs, Clicks, Cubes cleared, Shards earned, from `Game`'s getters), a "Keep mining" button that hides it, calls `Game.end_run()` and `run_end.present(true)`. On `_ready`, if `Game.run_won`: show at once (no fx).
  Ending text: "The last layer gives way. Light pours out of the stone, and the star rises up through every tunnel you dug, back into the sky."
- [ ] **Step 6: `RunEndScreen`:** rename `_show` to `present`, and the resume guard in `_ready`.
- [ ] **Step 7: Run** `run t5_victory`. Expected: only PASS lines.
- [ ] **Step 8: Docs:** README "Freeing the star" section and the Starlight achievement row (27 achievements, total bonus updated); CLAUDE.md victory flow and save keys.
- [ ] **Step 9: Checkpoint.**

### Task 6: The story

**Files:**
- Modify: `cubes/cube_type.gd` (add `story_line`), the seven cube types below, `autoload/game.gd`, `ui/toast.gd` (if needed for two-line bodies), `ui/run_end_screen.gd` (copy), `main.tscn`, `README.md`, `CLAUDE.md`
- Create: `ui/story_card.gd`, `ui/story_toast.gd`
- Test: `$S/tests/t6_story.gd`

**Interfaces:**
- Produces:
  - `CubeType.story_line: String` (`@export_multiline`, default empty).
  - `Game.opening_seen: bool`, `Game.mark_opening_seen()`; `Game._story_seen` (cube ids, saved as an Array under `story_seen`); signal `story_reached(cube_type: CubeType)`, emitted from `deliver_cube` the first time a cube type with a non-empty `story_line` is bought (the auto-buyer counts too).
  - Save keys `opening_seen`, `story_seen`. Loading a save without `opening_seen` sets it true when `stats` is non-empty, else false. No save file: false. `reset_progress()`: false, story seen cleared.
  - `StoryCard` (`extends CanvasLayer`, layer 42, `PROCESS_MODE_ALWAYS`): when `not Game.opening_seen`, covers the screen with the opening text and a "Begin" button, pauses the tree; Begin marks it seen, unpauses and hides.
  - `StoryToast extends Toast`, first child of `Hud/Root/Toasts`: title the cube's `display_name`, body the line wrapped to at most two 8px lines at the toast's width; shows 6s.

Exact copy:
- Opening: "Long ago, a star fell here and sank beneath every layer of stone. It's still down there, glowing. Buy cubes, break them and buy bigger ones to dig deeper. When your pickaxe breaks, the tunnel caves in and you start a new dig, a little stronger. The Star Core waits at the bottom of the shop."
- Meteorite: "The rock is scorched here, as if something burned its way down."
- Magma: "The deeper you dig, the warmer it gets. Something below still glows."
- Tektite Cube: "Glass, melted by a fall long ago. The star came down hard."
- Iridium Bar: "Iridium. Stars leave it behind where they land."
- Opal Cube: "Faint colors dance in the stone. Starlight, seeping up."
- Void Cube: "Nothing reflects down here. You must be close."
- Star Core: "There it is, the star, asleep in the stone. Break it free."
- Run-end subtitle: "Your pickaxe broke and the tunnel caved in. The dig went like this:"
- Run-end boost line: "All earnings +X%: Y% for each of the N Shards of starlight you've dug up" (same numbers as now).

- [ ] **Step 1: Write the failing test** `t6_story.gd`:
  - `new_game_opening`: no save file → `StoryCard` showing, tree paused; Begin → hidden, unpaused, `opening_seen` true and saved.
  - `old_save_skips_opening`: a save with stats and no `opening_seen` → no card.
  - `story_once`: `Game.deliver_cube(meteorite)` twice → `story_reached` once, `StoryToast` showing the Meteorite line; a reload with the saved file and another purchase → no toast; a Lapis purchase → none (no line).
  - `reset_after_victory` (Review Focus 5): a save with `star_free`, Starlight earned and story seen; `Game.reset_progress()` then reload → opening card shows, core row locked and shown, `star_free` false, Starlight not earned.
- [ ] **Step 2: Run** `run t6_story`. Expected: FAIL lines.
- [ ] **Step 3: Implement** the export and lines, `Game` state/keys/signal, `StoryCard`, `StoryToast`, the run-end copy; add the two nodes to `main.tscn`.
- [ ] **Step 4: Run** `run t6_story`. Expected: only PASS lines.
- [ ] **Step 5: Docs:** README story section near the top of "How to play" (the opening's gist, layer lines, the goal); CLAUDE.md story notes and save keys.
- [ ] **Step 6: Checkpoint.**

### Task 7: Tune with the run-playing bot

**Files:**
- Create: `$S/tests/bot.gd` (not in the repo)
- Modify (numbers only): the Task 2 cube and square `.tres` files, `star_core_square.tres` (hp), `star_core.tres` (grid), `starsteel_edge.tres` (price, growth), `core_damage_upgrade.gd` default only if needed; `README.md`, `ROADMAP.md`

**Interfaces:**
- Consumes: everything above.

Bot behavior (CLAUDE.md memory of the earlier bot): runs headless with `--fixed-fps 60`; clicks 4 times a second on the spot that hits the most unbroken squares; buys the most expensive cube it can afford whose clicks per square it can clear in the HP left, keeping one on the field (two with Auto-Buyer off); buys the cheapest affordable upgrades; buys a Whetstone when HP is under 20%; catches 70% of Lucky Cubes; at each run end buys perks cheapest first; buys the Star Core as soon as it's unlocked and affordable, then clicks only the core. Logs per run: run number, clicks, top cube reached, earned, Shards, Starsteel tier, whether the core was bought, core hits left at run end, victory.

Targets (from the spec):
- each new cube is a stop of 2-4 clears in a run that reaches it;
- the core is affordable a few runs before it's breakable;
- the core breaks around run 20-25;
- a build that buys the core weakly fails.

- [ ] **Step 1: Write `bot.gd`** with the behavior above, stopping at victory or run 40, printing one `RUN ...` line per run.
- [ ] **Step 2: Run it** in the background with a long alarm (e.g. `alarm 7200`) and a fresh save; record the log.
- [ ] **Step 3: Adjust numbers** toward the targets: the core's square hp first, then Starsteel's price growth, then the new cubes' hp/values (paybacks stay 3.5-4.6x). Rerun until the targets hold or two reruns don't move them, then stop and report.
- [ ] **Step 4: Rerun** `run t2_ladder`, `run t3_core`, `run t4_perk`. Expected: only PASS lines (update their pinned numbers only where Task 7 changed them).
- [ ] **Step 5: Docs:** README tables with the final numbers; ROADMAP: mark "The Fallen Star" done with the bot's results (run of first core purchase, run of victory, where late runs land against `MAX_AMOUNT`).
- [ ] **Step 6: Checkpoint.**

### Task 8: Final pass

**Files:**
- Modify: `ROADMAP.md`, `CLAUDE.md`, `README.md` (consistency only)

- [ ] **Step 1: Rerun every test:** `for t in t1_renames t2_ladder t3_core t4_perk t5_victory t6_story; do run $t; done`. Expected: only PASS lines.
- [ ] **Step 2: Screenshots** (non-headless, CLAUDE.md): the opening card, the shop with the core row, the core on the field with `CoreMeter`, a story toast, the victory screen. Look at each for overlap with the HUD and the 8px/16px font rule.
- [ ] **Step 3: Checkpoint.**
- [ ] **Step 4: Report to the user** with the bot's results and the screenshots' paths, and ask whether to commit and push.
