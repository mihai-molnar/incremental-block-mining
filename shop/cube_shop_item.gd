class_name CubeShopItem
extends ShopItem
## Shop entry that buys a cube and drops it into the work area.

@export var cube_type: CubeType


func get_title() -> String:
	return cube_type.display_name


## Squares, clicks per square (after upgrades) and payout, one per line. Cubes with rocks
## say how many, and their total leaves the rocks out. The Star Core pays nothing: its
## last line says what breaking it does instead.
func get_description() -> String:
	var count := cube_type.get_square_count()
	var clicks := Game.get_square_hp(cube_type.square_type, cube_type)
	if cube_type.is_goal:
		return "%d squares\n%d click%s each\nBreak it to free the star" % [count, clicks, "" if clicks == 1 else "s"]
	var each := cube_type.square_type.get_value(cube_type)
	var squares := "%d squares" % count
	var total := Currency.format(each * count)
	var mixed := cube_type.mixed_square_type
	if mixed and cube_type.mixed_chance > 0.0:
		# Each square rolls on its own, so the share is only roughly this.
		squares += " (~%d%% %s)" % [roundi(cube_type.mixed_chance * 100.0), mixed.display_name.to_lower()]
		total = "~" + Currency.format(roundi(each * count * (1.0 - cube_type.mixed_chance)))
	return "%s\n%d click%s each\nPays %s each (%s total)" % [
		squares, clicks, "" if clicks == 1 else "s", Currency.format(each), total]


func get_price() -> int:
	return cube_type.price


func create_icon() -> Control:
	var icon := CubeIcon.new()
	icon.cube_type = cube_type
	return icon


## Cubes show their mastery; the Star Core has none.
func create_meter() -> Control:
	if cube_type.is_goal:
		return null
	var meter := MasteryMeter.new()
	meter.cube_type = cube_type
	return meter


func can_auto_buy() -> bool:
	return not cube_type.is_goal and Game.get_auto_buy_slots() > 0


## Only one Star Core can be out at a time, and once the star is free it isn't sold again.
func can_purchase() -> bool:
	if cube_type.is_goal and (Game.star_core_out or Game.star_free):
		return false
	return super()


func is_owned() -> bool:
	return cube_type.is_goal and Game.star_free


func get_owned_label() -> String:
	return "Freed"


func get_block_reason() -> String:
	if cube_type.is_goal and Game.star_core_out and is_available():
		return "The Star Core is already out"
	return ""


func is_always_shown() -> bool:
	return cube_type.is_goal


func is_auto_buying() -> bool:
	return Game.auto_buy_cube == cube_type


## Only one cube can be picked, so picking this one replaces the last pick.
func set_auto_buying(on: bool) -> void:
	if on:
		Game.set_auto_buy_cube(cube_type)
	elif is_auto_buying():
		Game.set_auto_buy_cube(null)


func on_listed() -> void:
	super()
	Game.register_cube_for_sale(cube_type)


func _apply() -> void:
	Game.deliver_cube(cube_type)
