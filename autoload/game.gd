extends Node
## Global game state: the player's wallet, owned upgrades and game-wide events.
## Also keeps the save file: progress loads on start-up and saves every so often, when the
## window loses focus and on quit.

signal money_changed(money: int, delta: int)
signal cube_purchased(cube_type: CubeType)
signal upgrade_purchased(upgrade: Upgrade)
signal field_value_changed(value: int)
signal auto_buy_changed(cube_type: CubeType)
## Emitted while saving, so nodes that keep their own state (the work area's cubes) can
## add it to `data`. They get it back through take_saved().
signal saving(data: Dictionary)

const STARTING_MONEY := 20
const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const AUTOSAVE_INTERVAL := 30.0
## Hits per second one mining drone makes, before upgrades.
const DRONE_HITS_PER_SECOND := 1.5
## While the game is closed, drones keep mining at this fraction of their speed, for up
## to OFFLINE_CAP seconds. Absences shorter than OFFLINE_MIN don't count.
const OFFLINE_EFFICIENCY := 0.5
const OFFLINE_CAP := 2 * 3600
const OFFLINE_MIN := 60

var money: int = STARTING_MONEY
## Money still sitting in unbroken squares on the field. Kept current by the work area.
var field_value := 0
## Cube the auto-buyer keeps on the field, picked with Auto in the shop. Null when none is.
var auto_buy_cube: CubeType
## Where progress is saved. Start the game with `-- --save=<path>` to use another file;
## harness runs do, so they never touch the real save.
var save_path := SAVE_PATH

## What the drones made while the game was closed, until the welcome-back panel collects it.
var offline_earnings := 0
var offline_seconds := 0
var offline_cubes := 0
var offline_cube_type: CubeType

## Cubes the shop sells; the cheapest one is the floor that spending must not drop below.
var _cubes_for_sale: Array[CubeType] = []
## Owned upgrades and their level (Upgrade -> int).
var _upgrade_levels := {}
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
	_set_money(money + amount)


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
	upgrade_purchased.emit(upgrade)


## Picks the cube the auto-buyer keeps on the field, or null to stop it.
func set_auto_buy_cube(cube_type: CubeType) -> void:
	if cube_type == auto_buy_cube:
		return
	auto_buy_cube = cube_type
	auto_buy_changed.emit(cube_type)


## Pays out what the drones made while the game was closed. Returns the amount.
func collect_offline_earnings() -> int:
	var amount := offline_earnings
	offline_earnings = 0
	earn(amount)
	return amount


# --- Rules (every owned upgrade gets a say) ---------------------------------------

## Picks the type for one square of a newly landed cube.
func roll_square_type(cube_type: CubeType) -> SquareType:
	var result := cube_type.square_type
	for upgrade: Upgrade in _upgrade_levels:
		result = upgrade.modify_square_type(cube_type, result, _upgrade_levels[upgrade])
	return result


## Side, in squares, of the area one pickaxe click hits (1 = a single square).
func get_pickaxe_size() -> int:
	var size := 1
	for upgrade: Upgrade in _upgrade_levels:
		size = upgrade.modify_pickaxe_size(size, _upgrade_levels[upgrade])
	return maxi(size, 1)


## How many squares out a square of this type blows up when it breaks (0 = it doesn't).
func get_blast_radius(square_type: SquareType) -> int:
	if not square_type.is_explosive():
		return 0
	var radius := square_type.blast_radius
	for upgrade: Upgrade in _upgrade_levels:
		radius = upgrade.modify_blast_radius(radius, _upgrade_levels[upgrade])
	return maxi(radius, 1)


## Clicks needed to break a square of this type inside a cube of that type. Never less than 1.
func get_square_hp(square_type: SquareType, cube_type: CubeType) -> int:
	var hp := square_type.get_hp(cube_type)
	for upgrade: Upgrade in _upgrade_levels:
		hp = upgrade.modify_square_hp(square_type, hp, _upgrade_levels[upgrade])
	return maxi(hp, 1)


## How many mining drones fly around the field.
func get_drone_count() -> int:
	var count := 0
	for upgrade: Upgrade in _upgrade_levels:
		count = upgrade.modify_drone_count(count, _upgrade_levels[upgrade])
	return maxi(count, 0)


## Hits per second each drone makes.
func get_drone_hit_rate() -> float:
	var rate := DRONE_HITS_PER_SECOND
	for upgrade: Upgrade in _upgrade_levels:
		rate = upgrade.modify_drone_hit_rate(rate, _upgrade_levels[upgrade])
	return maxf(rate, 0.1)


## How many cubes the auto-buyer keeps on the field (0 = there's no auto-buyer).
func get_auto_buy_slots() -> int:
	var slots := 0
	for upgrade: Upgrade in _upgrade_levels:
		slots = upgrade.modify_auto_buy_slots(slots, _upgrade_levels[upgrade])
	return maxi(slots, 0)


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
	# Offline earnings the player hasn't collected yet aren't lost.
	data["money"] = money + offline_earnings
	data["upgrades"] = levels
	data["auto_buy"] = auto_buy_cube.resource_path if auto_buy_cube else ""
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
	field_value = 0
	auto_buy_cube = null
	_upgrade_levels.clear()
	_loaded_save = {}
	offline_earnings = 0


func _load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not parsed is Dictionary:
		push_warning("Ignoring unreadable save file: %s" % save_path)
		return
	var data: Dictionary = parsed
	money = int(data.get("money", STARTING_MONEY))
	if data.get("upgrades") is Dictionary:
		var levels: Dictionary = data.upgrades
		for path: Variant in levels:
			var upgrade := load_saved_resource(path) as Upgrade
			if upgrade:
				_upgrade_levels[upgrade] = int(levels[path])
	auto_buy_cube = load_saved_resource(data.get("auto_buy")) as CubeType
	_loaded_save = data
	_estimate_offline_earnings(int(Time.get_unix_time_from_system()) - int(data.get("saved_at", 0)))


## While the game was closed, the drones kept clearing the auto-buyer's cube at a discount.
## Works out how many cubes they'd have finished in that time and what that made.
func _estimate_offline_earnings(seconds_away: int) -> void:
	offline_earnings = 0
	var cube_type := auto_buy_cube
	if seconds_away < OFFLINE_MIN or cube_type == null or get_auto_buy_slots() == 0:
		return
	var away := mini(seconds_away, OFFLINE_CAP)
	var hits := get_drone_count() * get_drone_hit_rate() * away * OFFLINE_EFFICIENCY
	var square_type := cube_type.square_type
	var hits_per_cube := cube_type.get_square_count() * get_square_hp(square_type, cube_type)
	var profit := cube_type.get_square_count() * square_type.get_value(cube_type) - cube_type.price
	var cubes := floori(hits / hits_per_cube)
	if cubes <= 0 or profit <= 0:
		return
	offline_seconds = away
	offline_cubes = cubes
	offline_cube_type = cube_type
	offline_earnings = cubes * profit


func _set_money(value: int) -> void:
	var delta := value - money
	money = value
	money_changed.emit(money, delta)
