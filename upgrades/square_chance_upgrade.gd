class_name SquareChanceUpgrade
extends Upgrade
## Gives each default square of a cube a chance to become a different square type.

## Leave empty to affect every cube.
@export var cube_type: CubeType
@export var square_type: SquareType
@export_range(0.0, 1.0, 0.01) var chance := 0.15
## Cube drawn in the shop icon when `cube_type` is empty.
@export var preview_cube: CubeType


func get_description() -> String:
	if not description.is_empty():
		return description
	var where := cube_type.display_name if cube_type else "any cube"
	var pays := "pays %d" % square_type.value
	if square_type.value_multiplier > 0.0:
		pays = "%sx value" % _format_multiplier(square_type.value_multiplier)
	var clicks := "%d clicks" % square_type.hp
	if square_type.hp_multiplier > 0.0:
		clicks = "%sx clicks" % _format_multiplier(square_type.hp_multiplier)
	return "%d%% of squares on %s turn %s (%s, %s)" % [
		roundi(chance * 100.0), where, square_type.display_name, pays, clicks]


static func _format_multiplier(multiplier: float) -> String:
	if is_equal_approx(multiplier, roundf(multiplier)):
		return str(roundi(multiplier))
	return str(multiplier)


func create_icon() -> Control:
	var icon := CubeIcon.new()
	icon.cube_type = cube_type if cube_type else preview_cube
	icon.accent_type = square_type
	return icon


func modify_square_type(for_cube: CubeType, current: SquareType, _level: int) -> SquareType:
	if cube_type and for_cube != cube_type:
		return current
	if current == for_cube.square_type and randf() < chance:
		return square_type
	return current
