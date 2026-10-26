class_name SquareChanceUpgrade
extends Upgrade
## Gives each default square of a cube a chance to become a different square type.

## Leave empty to affect every cube.
@export var cube_type: CubeType
@export var square_type: SquareType
@export_range(0.0, 1.0, 0.01) var chance := 0.15
## When above 0, each owned tier adds this much chance and `chance` is ignored
## (0.01 makes tier 1 1%, tier 2 2%...).
@export_range(0.0, 1.0, 0.01) var chance_per_tier := 0.0
## Cube drawn in the shop icon when `cube_type` is empty.
@export var preview_cube: CubeType


func get_chance(level: int) -> float:
	if chance_per_tier > 0.0:
		return chance_per_tier * maxi(level, 1)
	return chance


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if chance_per_tier > 0.0 and level > 0:
		var now := "Tier %d: %s of squares turn %s" % [
			level, _format_percent(get_chance(level)), square_type.display_name]
		if is_maxed():
			return now + " (max)"
		return "%s\nNext tier: %s" % [now, _format_percent(get_chance(level + 1))]
	var where := cube_type.display_name if cube_type else "any cube"
	return "%s of squares on %s turn %s (%s)" % [
		_format_percent(get_chance(level)), where, square_type.display_name, _describe_square()]


## What sets the square apart: "5x value, 3x clicks" for a diamond,
## "1 click, blows up its neighbors" for an explosive.
func _describe_square() -> String:
	var parts: Array[String] = []
	if square_type.value_multiplier <= 0.0:
		parts.append("pays %d" % square_type.value)
	elif not is_equal_approx(square_type.value_multiplier, 1.0):
		parts.append("%sx value" % _format_multiplier(square_type.value_multiplier))
	if square_type.hp_multiplier > 0.0:
		parts.append("%sx clicks" % _format_multiplier(square_type.hp_multiplier))
	else:
		parts.append("%d click%s" % [square_type.hp, "" if square_type.hp == 1 else "s"])
	if square_type.is_explosive():
		parts.append("blows up its neighbors")
	return ", ".join(parts)


static func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value * 100.0)


static func _format_multiplier(multiplier: float) -> String:
	if is_equal_approx(multiplier, roundf(multiplier)):
		return str(roundi(multiplier))
	return str(multiplier)


func create_icon() -> Control:
	var icon := CubeIcon.new()
	icon.cube_type = cube_type if cube_type else preview_cube
	icon.accent_type = square_type
	return icon


func modify_square_type(for_cube: CubeType, current: SquareType, level: int) -> SquareType:
	if cube_type and for_cube != cube_type:
		return current
	if current == for_cube.square_type and randf() < get_chance(level):
		return square_type
	return current
