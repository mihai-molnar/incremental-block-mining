extends Node
## Global game state: the player's wallet, owned upgrades and game-wide events.

signal money_changed(money: int, delta: int)
signal cube_purchased(cube_type: CubeType)
signal upgrade_purchased(upgrade: Upgrade)
signal field_value_changed(value: int)

const STARTING_MONEY := 20

var money: int = STARTING_MONEY
## Money still sitting in unbroken squares on the field. Kept current by the work area.
var field_value := 0

## Cubes the shop sells; the cheapest one is the floor that spending must not drop below.
var _cubes_for_sale: Array[CubeType] = []
## Owned upgrades and their level (Upgrade -> int).
var _upgrade_levels := {}


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


## Clicks needed to break a square of this type inside a cube of that type. Never less than 1.
func get_square_hp(square_type: SquareType, cube_type: CubeType) -> int:
	var hp := square_type.get_hp(cube_type)
	for upgrade: Upgrade in _upgrade_levels:
		hp = upgrade.modify_square_hp(square_type, hp, _upgrade_levels[upgrade])
	return maxi(hp, 1)


func _set_money(value: int) -> void:
	var delta := value - money
	money = value
	money_changed.emit(money, delta)
