class_name CubeShopItem
extends ShopItem
## Shop entry that buys a cube and drops it into the work area.

@export var cube_type: CubeType


func get_title() -> String:
	return cube_type.display_name


## Squares, clicks per square (after upgrades) and payout, one per line. Cubes with rocks
## say how many, and their total leaves the rocks out.
func get_description() -> String:
	var count := cube_type.get_square_count()
	var clicks := Game.get_square_hp(cube_type.square_type, cube_type)
	var each := cube_type.square_type.get_value(cube_type)
	var squares := "%d squares" % count
	var total := Currency.format(each * count)
	var mixed := cube_type.mixed_square_type
	if mixed and cube_type.mixed_chance > 0.0:
		squares += " (%d%% %s)" % [roundi(cube_type.mixed_chance * 100.0), mixed.display_name.to_lower()]
		total = "~" + Currency.format(roundi(each * count * (1.0 - cube_type.mixed_chance)))
	return "%s\n%d click%s each\nPays %s each (%s total)" % [
		squares, clicks, "" if clicks == 1 else "s", Currency.format(each), total]


func get_price() -> int:
	return cube_type.price


func create_icon() -> Control:
	var icon := CubeIcon.new()
	icon.cube_type = cube_type
	return icon


func can_auto_buy() -> bool:
	return Game.get_auto_buy_slots() > 0


func is_auto_buying() -> bool:
	return Game.auto_buy_cube == cube_type


## Only one cube can be picked, so picking this one replaces the last pick.
func set_auto_buying(on: bool) -> void:
	if on:
		Game.set_auto_buy_cube(cube_type)
	elif is_auto_buying():
		Game.set_auto_buy_cube(null)


func on_listed() -> void:
	Game.register_cube_for_sale(cube_type)


func _apply() -> void:
	Game.deliver_cube(cube_type)
