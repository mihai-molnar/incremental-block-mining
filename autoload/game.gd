extends Node
## Global game state: the player's wallet, the pickaxe's HP and the run it limits, owned
## upgrades, timed effects (frenzies), lifetime stats, unlocks, Shards and game-wide
## events. Also keeps the save file: progress loads on start-up and saves every so often,
## when the window loses focus and on quit.

signal money_changed(money: int, delta: int)
signal cube_purchased(cube_type: CubeType)
signal upgrade_purchased(upgrade: Upgrade)
signal field_value_changed(value: int)
signal auto_buy_changed(cube_type: CubeType)
## A timed effect (a frenzy) started or ran out.
signal timed_effect_started(effect: Upgrade)
signal timed_effect_ended(effect: Upgrade)
## A lifetime stat went up.
signal stats_changed
## Squares broken on a cube type counted toward its mastery, and its mastery reaching a
## new level.
signal mastery_changed(cube_type: CubeType)
signal mastery_leveled_up(cube_type: CubeType, level: int)
## Shop items whose unlock goals were just met.
signal items_unlocked(items: Array[ShopItem])
## Achievements whose goals were just met.
signal achievements_earned(achievements: Array[Achievement])
signal shards_changed(shards: int)
## The pickaxe's HP or its shield changed.
signal pickaxe_changed(hp: int)
## The pickaxe ran out of HP. The run ends (end_run) once the field has collapsed.
signal pickaxe_broken
## The run ended and paid its Shards; last_run holds its summary.
signal run_ended
## The Star Core broke: the star is free and the run is won. The victory screen takes over.
signal star_freed
## A cube with a story line was bought for the first time ever; the story toast shows it.
signal story_reached(cube_type: CubeType)
## A mining drone was bought; the drone swarm launches it.
signal drone_launched
## How many drones are out changed.
signal drones_changed(count: int)
## Emitted while saving, so nodes that keep their own state (the work area's cubes) can
## add it to `data`. They get it back through take_saved().
signal saving(data: Dictionary)

const STARTING_MONEY := 20
## Money amounts top out here, a little under the largest int, instead of wrapping around
## to negative. Late runs with a big Shard boost earn ~10^17 each.
const MAX_AMOUNT := 9_000_000_000_000_000_000
## Lifetime stats that unlock goals count. Cubes cleared of one type are kept under
## get_cleared_stat(cube_type).
const STAT_SQUARES_BROKEN := &"squares_broken"
const STAT_CUBES_CLEARED := &"cubes_cleared"
const STAT_MONEY_EARNED := &"money_earned"
const STAT_RUNS := &"runs"
## Clicks and whole seconds of finished runs. Add the current run's for lifetime totals
## (get_lifetime_clicks, get_time_mining).
const STAT_CLICKS := &"clicks"
const STAT_SECONDS := &"seconds"
## Records of the player's clicks (drones' don't count): the most explosive and lightning
## squares one click set off, chain included, and the most squares it broke. Cubes cleared
## by one click are kept under get_one_click_stat(cube_type).
const STAT_LONGEST_CHAIN := &"longest_chain"
const STAT_BIGGEST_CLICK := &"biggest_click"
const STAT_ONE_CLICK_CLEARS := &"one_click_clears"
const STAT_LUCKY_CAUGHT := &"lucky_caught"
## The pickaxe's HP before perks. Every click that hits a square costs 1 of it (or of its
## shield, while it has one), and the run ends when it's gone.
const PICKAXE_HP := 100
## Hits a mining drone makes before it breaks, before perks, and how many fly at once.
const DRONE_HP := 60
const MAX_DRONES := 10
## A run pays the cube root of (money earned in it / SHARD_EARNINGS) Shards, rounded down,
## when it ends: 50 pays 1, 400 pays 2, 50K pays 10. Every Shard ever earned adds
## SHARD_BONUS to all earnings, spent or not.
const SHARD_EARNINGS := 50.0
const SHARD_BONUS := 0.02
## What a run's summary keeps, and what counts as a record (all but the Shards).
const RUN_SUMMARY: Array[String] = ["seconds", "clicks", "cubes", "earned", "shards"]
const RUN_RECORDS: Array[String] = ["seconds", "clicks", "cubes", "earned"]
const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const AUTOSAVE_INTERVAL := 30.0
## Hits per second one mining drone makes, before upgrades.
const DRONE_HITS_PER_SECOND := 1.5
## Finishing a cube pays this multiple of its squares' value: 1.25 adds a quarter on top.
const CLEAR_BONUS := 1.25
## Each of the player's hits in a row adds COMBO_STEP to the payout multiplier, up to
## COMBO_CAP. The combo drops when COMBO_WINDOW seconds pass without a hit.
const COMBO_STEP := 0.1
const COMBO_CAP := 2.0
const COMBO_WINDOW := 1.0
## Chance that one of the player's hits breaks a square outright.
const CRIT_CHANCE := 0.02
## A Lucky Cube drifts by after the player breaks LUCKY_INTERVAL_MIN to LUCKY_INTERVAL_MAX
## squares (a random number each time, so it can't be timed or waited out); catching it
## starts a frenzy that lasts FRENZY_DURATION seconds.
const LUCKY_INTERVAL_MIN := 60
const LUCKY_INTERVAL_MAX := 120
const FRENZY_DURATION := 30.0
## Each mastery level of a cube type makes its squares pay MASTERY_BONUS more, up to
## MASTERY_MAX_LEVEL. Level N takes N(N+1)/2 cubes' worth of its squares broken, over
## every run: 1 cube for level 1, 3 for 2, 6 for 3, 55 for 10.
const MASTERY_BONUS := 0.05
const MASTERY_MAX_LEVEL := 10

var money: int = STARTING_MONEY
## Shards to spend on perks, and every Shard ever earned (which sets the earnings boost).
var shards := 0
var total_shards := 0
## The pickaxe's HP left this run.
var pickaxe_hp := PICKAXE_HP
## Clicks on squares the pickaxe takes for free before its HP (an Unbreakable frenzy), and
## what the shield started at, for its bar.
var pickaxe_shield := 0
var pickaxe_shield_max := 0
## True from a run ending until the next one starts, while the run-end screen is up.
var run_over := false
## Whether the star has ever been freed, and in which run (its number).
var star_free := false
var star_freed_in_run := 0
## True from the star being freed until end_run, while the victory plays and the ending
## screen is up. Nothing can be mined meanwhile.
var run_won := false
## Whether the story's opening card has been seen. A new game shows it.
var opening_seen := false
## This run so far: money earned (which sets the Shards it pays), clicks that hit,
## seconds played and cubes cleared.
var run_earned := 0
var run_clicks := 0
var run_time := 0.0
var run_cubes := 0
## The last finished run's summary (RUN_SUMMARY keys, its number under "run" and the
## keys it set records for under "records"), and the best of every run.
var last_run := {}
var best_run := {}
## Drones out right now, kept current by the drone swarm.
var drones_out := 0
## Whether a Star Core is on the field, kept current by the work area. Only one at a time.
var star_core_out := false
## Money still sitting in unbroken squares on the field. Kept current by the work area.
var field_value := 0
## Cube the auto-buyer keeps on the field, picked with Auto in the shop. Null when none is.
var auto_buy_cube: CubeType
## Where progress is saved. Start the game with `-- --save=<path>` to use another file;
## harness runs do, so they never touch the real save.
var save_path := SAVE_PATH

## Cubes the shop sells; the cheapest one is the floor that spending must not drop below.
var _cubes_for_sale: Array[CubeType] = []
## Owned upgrades and their bought level (Upgrade -> int).
var _upgrade_levels := {}
## Tiers perks hand out for free (Upgrade -> int), rebuilt with `_modifiers`.
var _free_tiers := {}
## Running timed effects and their seconds left (Upgrade -> float). Not saved.
var _timed_effects := {}
## What the rules fold over: owned upgrades (free tiers included), then running timed
## effects at level 1.
var _modifiers := {}
## Lifetime stats (StringName -> int).
var _stats := {}
## Shop items with an unlock goal, and the resource paths of those unlocked so far.
## Saves from before goals start counting from zero; owned upgrades stay listed anyway.
var _unlockables: Array[ShopItem] = []
var _unlocked := {}
## Achievements the achievements page listed, and the earned ones by resource path
## (String -> Achievement). Ones earned since the page was last on screen aren't saved.
var _achievements: Array[Achievement] = []
var _earned := {}
var _unseen_achievements: Array[Achievement] = []
## Cube types whose story lines have been shown (id -> true), so each shows once ever.
var _story_seen := {}
## The save file as loaded. Nodes take their own part of it with take_saved().
var _loaded_save := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save="):
			save_path = arg.trim_prefix("--save=")
	_load_game()
	var autosave := Timer.new()
	autosave.wait_time = AUTOSAVE_INTERVAL
	autosave.autostart = true
	autosave.timeout.connect(save_game)
	add_child(autosave)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()


func _process(delta: float) -> void:
	if is_run_active():
		run_time += delta
	if _timed_effects.is_empty():
		return
	var ended: Array[Upgrade] = []
	for effect: Upgrade in _timed_effects:
		_timed_effects[effect] -= delta
		if _timed_effects[effect] <= 0.0:
			ended.append(effect)
	for effect in ended:
		_timed_effects.erase(effect)
	if not ended.is_empty():
		_refresh_modifiers()
		for effect in ended:
			timed_effect_ended.emit(effect)


func can_afford(cost: int) -> bool:
	return money >= cost


func try_spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	_set_money(money - cost)
	return true


func earn(amount: int) -> void:
	if amount <= 0:
		return
	_set_money(add_capped(money, amount))
	run_earned = add_capped(run_earned, amount)
	add_stat(STAT_MONEY_EARNED, amount)


func try_spend_shards(cost: int) -> bool:
	if shards < cost:
		return false
	shards -= cost
	shards_changed.emit(shards)
	return true


## Whether the player can still mine: the pickaxe holds and the run hasn't ended or been won.
func is_run_active() -> bool:
	return not run_over and not run_won and pickaxe_hp > 0


## Called when the Star Core's last square breaks. Wins the run, even when the click that
## set off the chain reaction finishing it used the pickaxe's last HP.
func free_star() -> void:
	if run_over or run_won:
		return
	run_won = true
	star_free = true
	star_freed_in_run = get_stat(STAT_RUNS) + 1
	_check_achievements()
	star_freed.emit()
	save_game()


## Called for every click that hits a square: takes 1 off the shield if there is one,
## otherwise off the HP, and breaks the pickaxe at 0.
func use_pickaxe() -> void:
	if not is_run_active():
		return
	run_clicks += 1
	_check_achievements()
	if pickaxe_shield > 0:
		pickaxe_shield -= 1
		pickaxe_changed.emit(pickaxe_hp)
		return
	pickaxe_hp -= 1
	pickaxe_changed.emit(pickaxe_hp)
	if pickaxe_hp == 0:
		pickaxe_broken.emit()


## Puts `amount` HP back on the pickaxe, up to its max.
func repair_pickaxe(amount: int) -> void:
	pickaxe_hp = mini(pickaxe_hp + amount, get_max_pickaxe_hp())
	pickaxe_changed.emit(pickaxe_hp)


## Shields the pickaxe for `clicks` more clicks on squares. A new shield on top of one
## that's left adds up, and its bar starts full again.
func add_pickaxe_shield(clicks: int) -> void:
	pickaxe_shield += clicks
	pickaxe_shield_max = pickaxe_shield
	pickaxe_changed.emit(pickaxe_hp)


## Breaks the pickaxe on the spot, ending the run early (the pause menu's End run).
func break_pickaxe() -> void:
	if not is_run_active():
		return
	pickaxe_hp = 0
	pickaxe_shield = 0
	pickaxe_changed.emit(pickaxe_hp)
	pickaxe_broken.emit()


## Shards ending the run now would pay.
func get_run_shards() -> int:
	# The nudge keeps exact cubes (800 for 2) from rounding down a Shard.
	return floori(pow(run_earned / SHARD_EARNINGS, 1.0 / 3.0) + 1e-9)


## Money a run needs to have earned to pay `count` Shards.
func get_shard_earnings(count: int) -> int:
	return ceili(pow(count, 3) * SHARD_EARNINGS)


## How far (0..1) this run's earnings are from its last Shard to the next one.
func get_shard_progress() -> float:
	var from := get_shard_earnings(get_run_shards())
	var to := get_shard_earnings(get_run_shards() + 1)
	return clampf(float(run_earned - from) / (to - from), 0.0, 1.0)


## Ends the run, once the pickaxe has broken and the field has collapsed: pays its Shards
## and keeps its summary in last_run. Money, upgrades (but not perks), timed effects and
## the auto-buyer's pick reset; Shards, perks, unlocks and stats stay. The run-end screen
## shows until start_run().
func end_run() -> int:
	var gained := get_run_shards()
	shards += gained
	total_shards += gained
	_stats[STAT_RUNS] = get_stat(STAT_RUNS) + 1
	_stats[STAT_CLICKS] = get_stat(STAT_CLICKS) + run_clicks
	_stats[STAT_SECONDS] = get_stat(STAT_SECONDS) + floori(run_time)
	var summary := {
		"seconds": floori(run_time), "clicks": run_clicks, "cubes": run_cubes,
		"earned": run_earned, "shards": gained,
	}
	var records: Array[String] = []
	for key in RUN_RECORDS:
		if best_run.has(key) and summary[key] > best_run[key]:
			records.append(key)
		best_run[key] = maxi(best_run.get(key, 0), summary[key])
	summary["run"] = get_stat(STAT_RUNS)
	summary["records"] = records
	last_run = summary
	for upgrade: Upgrade in _upgrade_levels.keys():
		if not upgrade.costs_shards:
			_upgrade_levels.erase(upgrade)
	_timed_effects.clear()
	_refresh_modifiers()
	run_over = true
	run_won = false
	run_earned = 0
	run_clicks = 0
	run_time = 0.0
	run_cubes = 0
	field_value = 0
	auto_buy_cube = null
	_loaded_save = {}
	_check_achievements()
	shards_changed.emit(shards)
	run_ended.emit()
	save_game()
	return gained


## Starts the next run from the run-end screen: money and the pickaxe start fresh, with
## perks, and the drone swarm gets Drone Bay's drones. Reload the main scene afterwards.
func start_run() -> void:
	# Keeps the perks just bought, should the game close before the next save.
	save_game()
	run_over = false
	pickaxe_hp = get_max_pickaxe_hp()
	pickaxe_shield = 0
	pickaxe_shield_max = 0
	_set_money(get_starting_money())
	var drones: Array[int] = []
	for i in get_starting_drones():
		drones.append(get_drone_hp())
	_loaded_save = {"drones": drones}


func get_stat(key: StringName) -> int:
	return _stats.get(key, 0)


func add_stat(key: StringName, amount: int) -> void:
	if amount <= 0:
		return
	_stats[key] = add_capped(get_stat(key), amount)
	stats_changed.emit()
	_check_unlocks()
	_check_achievements()


## Raises a record stat (the longest chain...) to `value`, if that beats it.
func record_max(key: StringName, value: int) -> void:
	if value <= get_stat(key):
		return
	_stats[key] = value
	stats_changed.emit()
	_check_unlocks()
	_check_achievements()


## Counts a finished cube, in total and for its type.
func record_cube_cleared(cube_type: CubeType) -> void:
	_stats[get_cleared_stat(cube_type)] = get_stat(get_cleared_stat(cube_type)) + 1
	run_cubes += 1
	add_stat(STAT_CUBES_CLEARED, 1)


## Records one of the player's clicks so far, chain reaction included: the squares it
## broke and the explosive and lightning squares it set off.
func record_click(squares: int, blasts: int) -> void:
	record_max(STAT_BIGGEST_CLICK, squares)
	record_max(STAT_LONGEST_CHAIN, blasts)


## Counts a cube one of the player's clicks cleared from untouched, chain included.
func record_one_click_clear(cube_type: CubeType) -> void:
	_stats[get_one_click_stat(cube_type)] = get_stat(get_one_click_stat(cube_type)) + 1
	add_stat(STAT_ONE_CLICK_CLEARS, 1)


## Stat key for cubes of one type cleared with one click, or of every type when null.
func get_one_click_stat(cube_type: CubeType) -> StringName:
	return StringName("one_click:" + cube_type.id) if cube_type else STAT_ONE_CLICK_CLEARS


## Clicks that hit a square, over every run, this one included.
func get_lifetime_clicks() -> int:
	return get_stat(STAT_CLICKS) + run_clicks


## Seconds spent in runs (paused time and run-end screens don't count), this one included.
func get_time_mining() -> int:
	return get_stat(STAT_SECONDS) + floori(run_time)


## The best a run has done for a RUN_SUMMARY key ("clicks"...), the current run included.
func get_best_run_value(key: String) -> int:
	var current := 0
	match key:
		"seconds":
			current = floori(run_time)
		"clicks":
			current = run_clicks
		"cubes":
			current = run_cubes
		"earned":
			current = run_earned
	return maxi(best_run.get(key, 0), current)


## Stat key for cubes cleared of one type, or of every type when null.
func get_cleared_stat(cube_type: CubeType) -> StringName:
	return StringName("cleared:" + cube_type.id) if cube_type else STAT_CUBES_CLEARED


## Counts squares broken on cubes of this type toward its mastery. Lifetime stats keep
## the count, so mastery carries over from run to run.
func add_mastery(cube_type: CubeType, squares: int) -> void:
	if squares <= 0:
		return
	var level := get_mastery_level(cube_type)
	var key := get_mastery_stat(cube_type)
	_stats[key] = add_capped(get_stat(key), squares)
	mastery_changed.emit(cube_type)
	if get_mastery_level(cube_type) > level:
		mastery_leveled_up.emit(cube_type, get_mastery_level(cube_type))
		_check_achievements()


## Stat key for squares broken on cubes of one type.
func get_mastery_stat(cube_type: CubeType) -> StringName:
	return StringName("broken:" + cube_type.id)


func get_mastery_level(cube_type: CubeType) -> int:
	var squares := get_stat(get_mastery_stat(cube_type))
	var level := 0
	while level < MASTERY_MAX_LEVEL and squares >= get_mastery_threshold(cube_type, level + 1):
		level += 1
	return level


## Squares broken on cubes of this type that mastery `level` takes, counted from zero.
func get_mastery_threshold(cube_type: CubeType, level: int) -> int:
	return roundi(cube_type.get_square_count() * level * (level + 1) / 2.0)


## How far (0..1) this cube type's mastery is from its level to the next (1 at the max).
func get_mastery_progress(cube_type: CubeType) -> float:
	var level := get_mastery_level(cube_type)
	if level >= MASTERY_MAX_LEVEL:
		return 1.0
	var from := get_mastery_threshold(cube_type, level)
	var to := get_mastery_threshold(cube_type, level + 1)
	return clampf(float(get_stat(get_mastery_stat(cube_type)) - from) / (to - from), 0.0, 1.0)


## What squares on cubes of this type pay for its mastery: x1, plus MASTERY_BONUS a level.
func get_mastery_multiplier(cube_type: CubeType) -> float:
	return 1.0 + get_mastery_level(cube_type) * MASTERY_BONUS


## How many of the cube types the shop sells are at the top mastery level. The Star Core
## has no mastery.
func get_mastered_count() -> int:
	return _cubes_for_sale.filter(func(cube_type: CubeType) -> bool:
		return not cube_type.is_goal and get_mastery_level(cube_type) >= MASTERY_MAX_LEVEL).size()


## Called by shop pages for items with an unlock goal. Goals already met, and upgrades
## already owned, unlock quietly.
func register_unlockable(item: ShopItem) -> void:
	if item in _unlockables:
		return
	_unlockables.append(item)
	if item.unlock.is_met() or (item is Upgrade and get_upgrade_level(item) > 0):
		_unlocked[item.resource_path] = true


func is_unlocked(item: ShopItem) -> bool:
	return _unlocked.has(item.resource_path)


func _check_unlocks() -> void:
	var fresh: Array[ShopItem] = []
	for item in _unlockables:
		if not is_unlocked(item) and item.unlock.is_met():
			_unlocked[item.resource_path] = true
			fresh.append(item)
	if not fresh.is_empty():
		items_unlocked.emit(fresh)


## The locked shop item closest to unlocking: its goal furthest along (then the cheapest),
## among those whose other requirements are met. Null once there's none.
func get_next_unlock() -> ShopItem:
	var best: ShopItem = null
	for item in _unlockables:
		if is_unlocked(item) or not item.meets_requirements():
			continue
		if best == null or _goal_ratio(item.unlock) > _goal_ratio(best.unlock) \
				or (_goal_ratio(item.unlock) == _goal_ratio(best.unlock) and item.get_price() < best.get_price()):
			best = item
	return best


## The achievement not yet earned whose goal is furthest along, or null.
func get_next_achievement() -> Achievement:
	var best: Achievement = null
	for achievement in _achievements:
		if not has_achievement(achievement) and (best == null or _goal_ratio(achievement.goal) > _goal_ratio(best.goal)):
			best = achievement
	return best


## How far along a goal is, 0..1.
func _goal_ratio(goal: Goal) -> float:
	return clampf(float(goal.get_value()) / maxi(goal.amount, 1), 0.0, 1.0)


## Called by the achievements page. Goals already met earn quietly.
func register_achievement(achievement: Achievement) -> void:
	if achievement in _achievements:
		return
	_achievements.append(achievement)
	if achievement.goal.is_met():
		_earned[achievement.resource_path] = achievement


func has_achievement(achievement: Achievement) -> bool:
	return _earned.has(achievement.resource_path)


func get_achievement_count() -> int:
	return _earned.size()


## Earned achievements, in the order they were earned.
func get_earned_achievements() -> Array[Achievement]:
	var earned: Array[Achievement] = []
	earned.assign(_earned.values())
	return earned


## What earned achievements add to all earnings together (0.1 = +10%).
func get_achievement_bonus() -> float:
	var bonus := 0.0
	for achievement: Achievement in _earned.values():
		bonus += achievement.bonus
	return bonus


## Whether achievements were earned since the achievements page was last on screen.
func has_unseen_achievements() -> bool:
	return not _unseen_achievements.is_empty()


func is_achievement_unseen(achievement: Achievement) -> bool:
	return achievement in _unseen_achievements


func mark_achievements_seen() -> void:
	_unseen_achievements.clear()


func _check_achievements() -> void:
	var fresh: Array[Achievement] = []
	for achievement in _achievements:
		if not has_achievement(achievement) and achievement.goal.is_met():
			_earned[achievement.resource_path] = achievement
			fresh.append(achievement)
	if not fresh.is_empty():
		_unseen_achievements.append_array(fresh)
		achievements_earned.emit(fresh)


## Called by the shop when a cube is bought; the work area listens and spawns it. The
## first purchase of a cube with a story line tells that part of the story.
func deliver_cube(cube_type: CubeType) -> void:
	cube_purchased.emit(cube_type)
	if not cube_type.story_line.is_empty() and not _story_seen.has(cube_type.id):
		_story_seen[cube_type.id] = true
		story_reached.emit(cube_type)


## The opening card was read: it doesn't show again (until Reset progress).
func mark_opening_seen() -> void:
	opening_seen = true
	save_game()


## Called by the shop when a drone is bought; the drone swarm listens and launches it.
func launch_drone() -> void:
	drone_launched.emit()


func set_drones_out(count: int) -> void:
	if count == drones_out:
		return
	drones_out = count
	drones_changed.emit(count)


func set_star_core_out(out: bool) -> void:
	star_core_out = out


func set_field_value(value: int) -> void:
	if value == field_value:
		return
	field_value = value
	field_value_changed.emit(value)


func register_cube_for_sale(cube_type: CubeType) -> void:
	if cube_type not in _cubes_for_sale:
		_cubes_for_sale.append(cube_type)


func get_cheapest_cube_price() -> int:
	if _cubes_for_sale.is_empty():
		return 0
	var cheapest := _cubes_for_sale[0].price
	for cube_type in _cubes_for_sale:
		cheapest = mini(cheapest, cube_type.price)
	return cheapest


## True if spending `cost` would leave the player unable to ever afford another cube:
## what's left in the wallet plus what's still on the field falls short of the cheapest cube.
func would_soft_lock(cost: int) -> bool:
	return money - cost + field_value < get_cheapest_cube_price()


## Owned tiers: the bought ones plus free ones from perks.
func get_upgrade_level(upgrade: Upgrade) -> int:
	return get_bought_level(upgrade) + _free_tiers.get(upgrade, 0)


## Tiers paid for. Prices and caps follow these.
func get_bought_level(upgrade: Upgrade) -> int:
	return _upgrade_levels.get(upgrade, 0)


func has_upgrade(upgrade: Upgrade) -> bool:
	return get_upgrade_level(upgrade) > 0


func add_upgrade_level(upgrade: Upgrade) -> void:
	_upgrade_levels[upgrade] = get_bought_level(upgrade) + 1
	_refresh_modifiers()
	upgrade_purchased.emit(upgrade)


## Folds `effect` into the rules, like an owned upgrade at level 1, for `seconds`.
## Starting one that's already running gives it the longer of the two times.
func add_timed_effect(effect: Upgrade, seconds: float) -> void:
	_timed_effects[effect] = maxf(seconds, _timed_effects.get(effect, 0.0))
	_refresh_modifiers()
	timed_effect_started.emit(effect)


func has_timed_effects() -> bool:
	return not _timed_effects.is_empty()


## Seconds left on a running timed effect (0 when it isn't running).
func get_effect_time_left(effect: Upgrade) -> float:
	return _timed_effects.get(effect, 0.0)


## Picks the cube the auto-buyer keeps on the field, or null to stop it.
func set_auto_buy_cube(cube_type: CubeType) -> void:
	if cube_type == auto_buy_cube:
		return
	auto_buy_cube = cube_type
	auto_buy_changed.emit(cube_type)


# --- Rules (every owned upgrade and running timed effect gets a say) ---------------

## Picks the type for one square of a newly landed cube, which started out as `current`
## (the cube's default square, or a rock).
func roll_square_type(cube_type: CubeType, current: SquareType) -> SquareType:
	var result := current
	for modifier: Upgrade in _modifiers:
		result = modifier.modify_square_type(cube_type, result, _modifiers[modifier])
	return result


## Clicks one of the player's hits takes off a square of a cube of this type (Starsteel
## Edge adds to it on the Star Core).
func get_hit_damage(cube_type: CubeType) -> int:
	var damage := 1
	for modifier: Upgrade in _modifiers:
		damage = modifier.modify_hit_damage(cube_type, damage, _modifiers[modifier])
	return maxi(damage, 1)


## Side, in squares, of the area one pickaxe click hits (1 = a single square).
func get_pickaxe_size() -> int:
	var size := 1
	for modifier: Upgrade in _modifiers:
		size = modifier.modify_pickaxe_size(size, _modifiers[modifier])
	return maxi(size, 1)


## How many squares out a square of this type blows up when it breaks (0 = it doesn't).
func get_blast_radius(square_type: SquareType) -> int:
	if not square_type.is_explosive():
		return 0
	var radius := square_type.blast_radius
	for modifier: Upgrade in _modifiers:
		radius = modifier.modify_blast_radius(radius, _modifiers[modifier])
	return maxi(radius, 1)


## Clicks needed to break a square of this type inside a cube of that type. Never less than 1.
## Squares with an hp_multiplier (diamonds) scale off the cube's default square after
## upgrades, so they stay 3x as tough however sharp the pickaxe gets, and no tougher.
func get_square_hp(square_type: SquareType, cube_type: CubeType) -> int:
	if square_type.hp_multiplier > 0.0 and cube_type and square_type != cube_type.square_type:
		var base_hp := get_square_hp(cube_type.square_type, cube_type)
		return maxi(roundi(base_hp * square_type.hp_multiplier), 1)
	var hp := square_type.get_hp(cube_type)
	for modifier: Upgrade in _modifiers:
		hp = modifier.modify_square_hp(square_type, hp, _modifiers[modifier])
	return maxi(hp, 1)


## The pickaxe's HP at the start of a run.
func get_max_pickaxe_hp() -> int:
	var hp := PICKAXE_HP
	for modifier: Upgrade in _modifiers:
		hp = modifier.modify_max_pickaxe_hp(hp, _modifiers[modifier])
	return maxi(hp, 1)


## Hits a new mining drone makes before it breaks.
func get_drone_hp() -> int:
	var hp := DRONE_HP
	for modifier: Upgrade in _modifiers:
		hp = modifier.modify_drone_hp(hp, _modifiers[modifier])
	return maxi(hp, 1)


## Drones a new run starts with.
func get_starting_drones() -> int:
	var count := 0
	for modifier: Upgrade in _modifiers:
		count = modifier.modify_starting_drones(count, _modifiers[modifier])
	return clampi(count, 0, MAX_DRONES)


## Hits per second each drone makes.
func get_drone_hit_rate() -> float:
	var rate := DRONE_HITS_PER_SECOND
	for modifier: Upgrade in _modifiers:
		rate = modifier.modify_drone_hit_rate(rate, _modifiers[modifier])
	return maxf(rate, 0.1)


## How many cubes the auto-buyer keeps on the field (0 = there's no auto-buyer).
func get_auto_buy_slots() -> int:
	var slots := 0
	for modifier: Upgrade in _modifiers:
		slots = modifier.modify_auto_buy_slots(slots, _modifiers[modifier])
	return maxi(slots, 0)


## What finishing a cube pays, as a multiple of its squares' value (1.25 = a quarter more).
func get_clear_bonus() -> float:
	var multiplier := CLEAR_BONUS
	for modifier: Upgrade in _modifiers:
		multiplier = modifier.modify_clear_bonus(multiplier, _modifiers[modifier])
	return maxf(multiplier, 1.0)


## The money a finished cube pays on top of its squares, which were worth `cube_value`
## (with its mastery).
func get_clear_payout(cube_value: float) -> int:
	return roundi(minf(cube_value * (get_clear_bonus() - 1.0) * get_payout_multiplier(), MAX_AMOUNT))


## Highest payout multiplier the combo meter reaches.
func get_combo_cap() -> float:
	var cap := COMBO_CAP
	for modifier: Upgrade in _modifiers:
		cap = modifier.modify_combo_cap(cap, _modifiers[modifier])
	return maxf(cap, 1.0)


## Seconds the combo meter waits for the player's next hit before it drops.
func get_combo_window() -> float:
	var seconds := COMBO_WINDOW
	for modifier: Upgrade in _modifiers:
		seconds = modifier.modify_combo_window(seconds, _modifiers[modifier])
	return maxf(seconds, 0.1)


## Chance (0..1) that one of the player's hits breaks a square outright.
func get_crit_chance() -> float:
	var chance := CRIT_CHANCE
	for modifier: Upgrade in _modifiers:
		chance = modifier.modify_crit_chance(chance, _modifiers[modifier])
	return clampf(chance, 0.0, 1.0)


## What every payout from squares is multiplied by: the Shard boost and achievements'
## bonus, then a money frenzy's x7 and the like.
func get_payout_multiplier() -> float:
	var multiplier := 1.0 + get_shard_boost() + get_achievement_bonus()
	for modifier: Upgrade in _modifiers:
		multiplier = modifier.modify_payout_multiplier(multiplier, _modifiers[modifier])
	return maxf(multiplier, 0.0)


## Squares the player breaks before the next Lucky Cube, rolled anew for each one.
func roll_lucky_interval() -> int:
	var squares := float(randi_range(LUCKY_INTERVAL_MIN, LUCKY_INTERVAL_MAX))
	for modifier: Upgrade in _modifiers:
		squares = modifier.modify_lucky_interval(squares, _modifiers[modifier])
	return maxi(roundi(squares), 5)


## Seconds a frenzy lasts.
func get_frenzy_duration() -> float:
	var seconds := FRENZY_DURATION
	for modifier: Upgrade in _modifiers:
		seconds = modifier.modify_frenzy_duration(seconds, _modifiers[modifier])
	return maxf(seconds, 1.0)


## How much each Shard ever earned adds to earnings (0.05 = 5%).
func get_shard_bonus() -> float:
	var bonus := SHARD_BONUS
	for modifier: Upgrade in _modifiers:
		bonus = modifier.modify_shard_bonus(bonus, _modifiers[modifier])
	return maxf(bonus, 0.0)


## What every Shard ever earned adds to earnings together (0.5 = +50%).
func get_shard_boost() -> float:
	return total_shards * get_shard_bonus()


## Money a new run starts with.
func get_starting_money() -> int:
	var amount := STARTING_MONEY
	for modifier: Upgrade in _modifiers:
		amount = modifier.modify_starting_money(amount, _modifiers[modifier])
	return maxi(amount, 0)


func _refresh_modifiers() -> void:
	_free_tiers.clear()
	for upgrade: Upgrade in _upgrade_levels:
		var target := upgrade.get_free_tiers_target()
		if target:
			_free_tiers[target] = _free_tiers.get(target, 0) + _upgrade_levels[upgrade]
	_modifiers = _upgrade_levels.duplicate()
	for upgrade: Upgrade in _free_tiers:
		_modifiers[upgrade] = get_upgrade_level(upgrade)
	for effect: Upgrade in _timed_effects:
		_modifiers[effect] = 1


# --- Saving -----------------------------------------------------------------

func save_game() -> void:
	# Parts nobody has taken back yet (no work area loaded) are kept as they were.
	var data := _loaded_save.duplicate()
	var levels := {}
	for upgrade: Upgrade in _upgrade_levels:
		if not upgrade.resource_path.is_empty():
			levels[upgrade.resource_path] = _upgrade_levels[upgrade]
	data["version"] = SAVE_VERSION
	data["saved_at"] = int(Time.get_unix_time_from_system())
	data["money"] = money
	data["upgrades"] = levels
	data["auto_buy"] = auto_buy_cube.resource_path if auto_buy_cube else ""
	data["stats"] = _stats
	data["shards"] = shards
	data["total_shards"] = total_shards
	data["pickaxe_hp"] = pickaxe_hp
	data["pickaxe_shield"] = [pickaxe_shield, pickaxe_shield_max]
	data["run_over"] = run_over
	data["run_won"] = run_won
	data["star_free"] = star_free
	data["star_freed_in_run"] = star_freed_in_run
	data["opening_seen"] = opening_seen
	data["story_seen"] = _story_seen.keys()
	data["run"] = {"earned": run_earned, "clicks": run_clicks, "seconds": run_time, "cubes": run_cubes}
	data["last_run"] = last_run
	data["best_run"] = best_run
	data["unlocked"] = _unlocked.keys()
	data["achievements"] = _earned.keys()
	data["unseen_achievements"] = _unseen_achievements.map(func(a: Achievement) -> String: return a.resource_path)
	saving.emit(data)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't save to %s: %s" % [save_path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify(data, "\t"))


## Hands a node its part of the loaded save, once (the work area takes its cubes).
func take_saved(key: String, default: Variant = null) -> Variant:
	var value: Variant = _loaded_save.get(key, default)
	_loaded_save.erase(key)
	return value


## Loads a resource the save file names, or null if it no longer exists.
func load_saved_resource(path: Variant) -> Resource:
	if not path is String or not ResourceLoader.exists(path):
		return null
	return load(path)


## Deletes the save and starts over. Reload the main scene afterwards.
func reset_progress() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	money = STARTING_MONEY
	shards = 0
	total_shards = 0
	pickaxe_hp = PICKAXE_HP
	pickaxe_shield = 0
	pickaxe_shield_max = 0
	run_over = false
	run_won = false
	star_free = false
	star_freed_in_run = 0
	opening_seen = false
	_story_seen.clear()
	run_earned = 0
	run_clicks = 0
	run_time = 0.0
	run_cubes = 0
	last_run = {}
	best_run = {}
	field_value = 0
	auto_buy_cube = null
	_upgrade_levels.clear()
	_stats.clear()
	_unlocked.clear()
	_earned.clear()
	_unseen_achievements.clear()
	_timed_effects.clear()
	_refresh_modifiers()
	_loaded_save = {}


func _load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not parsed is Dictionary:
		push_warning("Ignoring unreadable save file: %s" % save_path)
		return
	var data: Dictionary = parsed
	money = int(data.get("money", STARTING_MONEY))
	shards = int(data.get("shards", 0))
	total_shards = int(data.get("total_shards", 0))
	run_over = bool(data.get("run_over", false))
	run_won = bool(data.get("run_won", false))
	star_free = bool(data.get("star_free", false))
	star_freed_in_run = int(data.get("star_freed_in_run", 0))
	if data.get("run") is Dictionary:
		var run: Dictionary = data.run
		run_earned = int(run.get("earned", 0))
		run_clicks = int(run.get("clicks", 0))
		run_time = float(run.get("seconds", 0.0))
		run_cubes = int(run.get("cubes", 0))
	if data.get("last_run") is Dictionary:
		last_run = _load_run_summary(data.last_run)
	if data.get("best_run") is Dictionary:
		best_run = _load_run_summary(data.best_run)
	if data.get("upgrades") is Dictionary:
		var levels: Dictionary = data.upgrades
		for path: Variant in levels:
			var upgrade := load_saved_resource(path) as Upgrade
			if upgrade:
				_upgrade_levels[upgrade] = int(levels[path])
		_refresh_modifiers()
	auto_buy_cube = load_saved_resource(data.get("auto_buy")) as CubeType
	if data.get("stats") is Dictionary:
		var stats: Dictionary = data.stats
		for key: Variant in stats:
			_stats[StringName(str(key))] = int(stats[key])
	if data.get("unlocked") is Array:
		for path: Variant in data.unlocked:
			_unlocked[str(path)] = true
	# Saves from before the story have no key: a player with progress already began.
	opening_seen = bool(data.get("opening_seen", not _stats.is_empty()))
	if data.get("story_seen") is Array:
		for id: Variant in data.story_seen:
			_story_seen[StringName(str(id))] = true
	if data.get("achievements") is Array:
		for path: Variant in data.achievements:
			var achievement := load_saved_resource(path) as Achievement
			if achievement:
				_earned[achievement.resource_path] = achievement
	if data.get("unseen_achievements") is Array:
		for path: Variant in data.unseen_achievements:
			var achievement := load_saved_resource(path) as Achievement
			if achievement and _earned.has(achievement.resource_path):
				_unseen_achievements.append(achievement)
	# Perks are in by now, so a save without the pickaxe starts it at full HP.
	pickaxe_hp = int(data.get("pickaxe_hp", get_max_pickaxe_hp()))
	if data.get("pickaxe_shield") is Array and data.pickaxe_shield.size() == 2:
		pickaxe_shield = int(data.pickaxe_shield[0])
		pickaxe_shield_max = int(data.pickaxe_shield[1])
	_loaded_save = data


## A run summary as saved, with JSON's floats turned back into whole numbers.
func _load_run_summary(saved: Dictionary) -> Dictionary:
	var summary := {}
	for key: Variant in saved:
		var value: Variant = saved[key]
		if value is float:
			summary[str(key)] = int(value)
		elif value is Array:
			var records: Array[String] = []
			for record: Variant in value:
				records.append(str(record))
			summary[str(key)] = records
	return summary


## `a + b` for non-negative amounts, kept at MAX_AMOUNT at most.
static func add_capped(a: int, b: int) -> int:
	return MAX_AMOUNT if a > MAX_AMOUNT - b else a + b


func _set_money(value: int) -> void:
	var delta := value - money
	money = value
	money_changed.emit(money, delta)
