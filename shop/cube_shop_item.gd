class_name CubeShopItem
extends ShopItem
## Shop entry that buys a cube and drops it into the work area.

@export var cube_type: CubeType


func get_title() -> String:
	return cube_type.display_name


## Squares, clicks per square (after upgrades) and payout, one per line.
func get_description() -> String:
	var count := cube_type.get_square_count()
	var clicks := Game.get_square_hp(cube_type.square_type, cube_type)
	var each := cube_type.square_type.get_value(cube_type)
	return "%d squares\n%d click%s each\nPays %s each (%s total)" % [
		count, clicks, "" if clicks == 1 else "s", Currency.format(each), Currency.format(each * count)]


func get_price() -> int:
	return cube_type.price


func create_icon() -> Control:
	var icon := CubeIcon.new()
	icon.cube_type = cube_type
	return icon


func on_listed() -> void:
	Game.register_cube_for_sale(cube_type)


func _apply() -> void:
	Game.deliver_cube(cube_type)
