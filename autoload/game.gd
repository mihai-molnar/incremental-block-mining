extends Node
## Global game state: the player's wallet, owned upgrades, timed effects (frenzies),
## lifetime stats, unlocks, prestige Shards and game-wide events. Also keeps the save
## file: progress loads on start-up and saves every so often, when the window loses focus
## and on quit.

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
## Shop items whose unlock goals were just met.
signal items_unlocked(items: Array[ShopItem])
signal shards_changed(shards: int)
## Enough has been earned in total to open the Prestige page.
signal prestige_unlocked
## Emitted while saving, so nodes that keep their own state (the work area's cubes) can
## add it to `data`. They get it back through take_saved().
signal saving(data: Dictionary)

const STARTING_MONEY := 20
## Lifetime stats that unlock goals count. Cubes cleared of one type are kept under
## get_cleared_stat(cube_type).
const STAT_SQUARES_BROKEN := &"squares_broken"
const STAT_CUBES_CLEARED := &"cubes_cleared"
const STAT_MONEY_EARNED := &"money_earned"
const STAT_COLLAPSES := &"collapses"
## Collapsing the mine pays floor(sqrt(money earned this run / SHARD_EARNINGS)) Shards.
## Every Shard ever earned adds SHARD_BONUS to all earnings, spent or not. The Prestige
## page opens once PRESTIGE_UNLOCK has been earned in total.
const SHARD_EARNINGS := 1_000_000_000.0
const SHARD_BONUS := 0.1
const PRESTIGE_UNLOCK := 100_000_000
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
## A Lucky Cube drifts by every LUCKY_INTERVAL_MIN to LUCKY_INTERVAL_MAX seconds; catching
## it starts a frenzy that lasts FRENZY_DURATION seconds.
const LUCKY_INTERVAL_MIN := 120.0
const LUCKY_INTERVAL_MAX := 300.0
const FRENZY_DURATION := 30.0

var money: int = STARTING_MONEY
## Shards to spend on perks, and every Shard ever earned (which sets the earnings boost).
var shards := 0
var total_shards := 0
## Money earned since the last collapse; it sets the Shards the next one pays.
var run_earned := 0
## Money still sitting in unbroken squares on the field. Kept current by the work area.
var field_value := 0
## Cube the auto-buyer keeps on the field, picked with Auto in the shop. Null when none is.
var auto_buy_cube: CubeType
## Where progress is saved. Start the game with `-- --save=<path>` to use another file;
## harness runs do, so they never touch the real save.
var save_path := SAVE_PATH

## Cubes the shop sells; the cheapest one is the floor that spending must not drop below.
var _cubes_for_sale: Array[CubeType] = []
## Owned upgrades and their level (Upgrade -> int).
var _upgrade_levels := {}
## Running timed effects and their seconds left (Upgrade -> float). Not saved.
var _timed_effects := {}
## What the rules fold over: owned upgrades, then running timed effects at level 1.
var _modifiers := {}
## Lifetime stats (StringName -> int).
var _stats := {}
## Shards the last collapse paid, until the new run's banner takes them.
var _collapse_reward := 0
## Shop items with an unlock goal, and the resource paths of those unlocked so far.
## Saves from before goals start counting from zero; owned upgrades stay listed anyway.
var _unlockables: Array[ShopItem] = []
var _unlocked := {}
## The save file as loaded. Nodes take their own part of it with take_saved().
var _loaded_save := {}


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--save="):
			save_path = arg.trim_prefix("--save=")
	set_process(false)
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
	set_process(not _timed_effects.is_empty())


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
	var was_unlocked := is_prestige_unlocked()
	_set_money(money + amount)
	run_earned += amount
	add_stat(STAT_MONEY_EARNED, amount)
	if not was_unlocked and is_prestige_unlocked():
		prestige_unlocked.emit()


func try_spend_shards(cost: int) -> bool:
	if shards < cost:
		return false
	shards -= cost
	shards_changed.emit(shards)
	return true


func is_prestige_unlocked() -> bool:
	return total_shards > 0 or get_stat(STAT_MONEY_EARNED) >= PRESTIGE_UNLOCK


## Shards collapsing the mine now would pay.
func get_collapse_shards() -> int:
	return floori(sqrt(run_earned / SHARD_EARNINGS))


## Money this run needs to have earned for a collapse to pay one more Shard.
func get_next_shard_earnings() -> int:
	return roundi(pow(get_collapse_shards() + 1, 2) * SHARD_EARNINGS)


## Collapses the mine: pays the run's Shards, then starts a new run. Money, upgrades
## (but not perks), timed effects and the auto-buyer's pick reset; Shards, perks, unlocks
## and stats stay. Reload the main scene afterwards, as after reset_progress.
func collapse() -> int:
	var gained := get_collapse_shards()
	shards += gained
	total_shards += gained
	_collapse_reward += gained
	for upgrade: Upgrade in _upgrade_levels.keys():
		if not upgrade.costs_shards:
			_upgrade_levels.erase(upgrade)
	_timed_effects.clear()
	set_process(false)
	_refresh_modifiers()
	run_earned = 0
	field_value = 0
	auto_buy_cube = null
	_loaded_save = {}
	_stats[STAT_COLLAPSES] = get_stat(STAT_COLLAPSES) + 1
	_set_money(get_starting_money())
	shards_changed.emit(shards)
	save_game()
	return gained


## The Shards the last collapse paid, once, for the new run's banner.
func take_collapse_reward() -> int:
	var reward := _collapse_reward
	_collapse_reward = 0
	return reward


func get_stat(key: StringName) -> int:
	return _stats.get(key, 0)


func add_stat(key: StringName, amount: int) -> void:
	if amount <= 0:
		return
	_stats[key] = get_stat(key) + amount
	stats_changed.emit()
	_check_unlocks()


## Counts a finished cube, in total and for its type.
func record_cube_cleared(cube_type: CubeType) -> void:
	_stats[get_cleared_stat(cube_type)] = get_stat(get_cleared_stat(cube_type)) + 1
	add_stat(STAT_CUBES_CLEARED, 1)


## Stat key for cubes cleared of one type, or of every type when null.
func get_cleared_stat(cube_type: CubeType) -> StringName:
	return StringName("cleared:" + cube_type.id) if cube_type else STAT_CUBES_CLEARED


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


## Called by the shop when a cube is bought; the work area listens and spawns it.
func deliver_cube(cube_type: CubeType) -> void:
	cube_purchased.emit(cube_type)


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


func get_upgrade_level(upgrade: Upgrade) -> int:
	return _upgrade_levels.get(upgrade, 0)


func has_upgrade(upgrade: Upgrade) -> bool:
	return get_upgrade_level(upgrade) > 0


func add_upgrade_level(upgrade: Upgrade) -> void:
	_upgrade_levels[upgrade] = get_upgrade_level(upgrade) + 1
	_refresh_modifiers()
	upgrade_purchased.emit(upgrade)


## Folds `effect` into the rules, like an owned upgrade at level 1, for `seconds`.
## Starting one that's already running gives it the longer of the two times.
func add_timed_effect(effect: Upgrade, seconds: float) -> void:
	_timed_effects[effect] = maxf(seconds, _timed_effects.get(effect, 0.0))
	_refresh_modifiers()
	set_process(true)
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


## How many mining drones fly around the field.
func get_drone_count() -> int:
	var count := 0
	for modifier: Upgrade in _modifiers:
		count = modifier.modify_drone_count(count, _modifiers[modifier])
	return maxi(count, 0)


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


## The money a finished cube pays on top of its squares, which were worth `cube_value`.
func get_clear_payout(cube_value: int) -> int:
	return roundi(cube_value * (get_clear_bonus() - 1.0) * get_payout_multiplier())


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


## What every payout from squares is multiplied by: the Shard boost, then a money frenzy's
## x7 and the like.
func get_payout_multiplier() -> float:
	var multiplier := 1.0 + get_shard_boost()
	for modifier: Upgrade in _modifiers:
		multiplier = modifier.modify_payout_multiplier(multiplier, _modifiers[modifier])
	return maxf(multiplier, 0.0)


## Seconds until the next Lucky Cube, rolled anew for each one.
func roll_lucky_interval() -> float:
	var seconds := randf_range(LUCKY_INTERVAL_MIN, LUCKY_INTERVAL_MAX)
	for modifier: Upgrade in _modifiers:
		seconds = modifier.modify_lucky_interval(seconds, _modifiers[modifier])
	return maxf(seconds, 5.0)


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
	_modifiers = _upgrade_levels.duplicate()
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
	data["run_earned"] = run_earned
	data["unlocked"] = _unlocked.keys()
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
	run_earned = 0
	_collapse_reward = 0
	field_value = 0
	auto_buy_cube = null
	_upgrade_levels.clear()
	_stats.clear()
	_unlocked.clear()
	_timed_effects.clear()
	_refresh_modifiers()
	set_process(false)
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
	run_earned = int(data.get("run_earned", 0))
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
	_loaded_save = data


func _set_money(value: int) -> void:
	var delta := value - money
	money = value
	money_changed.emit(money, delta)
