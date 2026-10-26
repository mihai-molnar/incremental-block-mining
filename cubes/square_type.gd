class_name SquareType
extends Resource
## Defines a kind of square: how many clicks it takes, what it pays and how it looks.
## Cubes are filled with their default square type; upgrades can swap in others.

@export var id: StringName = &"square"
@export var display_name := "Square"
## Clicks needed to break the square.
@export var hp := 2
## When above 0, the square takes this multiple of its cube's default square's clicks
## instead of `hp` (e.g. 3 makes a diamond take 3 clicks in a blue cube, 24 in a red one).
@export var hp_multiplier := 0.0
## Money earned when the square breaks.
@export var value := 2
## When above 0, the square pays this multiple of its cube's default square instead of
## `value` (e.g. 5 makes a diamond worth 10 in a blue cube and 15 in a yellow one).
@export var value_multiplier := 0.0
## Precious squares (diamonds...) glint every few seconds with a light sweep and a twinkle.
@export var shimmer := false
## When above 0, breaking the square sets off an explosion that breaks every square within
## this many squares of it (1 = the 8 around it). Upgrades can widen it.
@export var blast_radius := 0
## PixelSprites sprite drawn in the middle of the tile (e.g. a bomb on explosive squares).
@export var emblem: StringName = &""

@export_group("Palette")
@export var outline_color := Color("0f1020")
@export var shadow_color := Color("29366f")
@export var base_color := Color("3b5dc9")
@export var light_color := Color("41a6f6")
@export var shine_color := Color("73eff7")


## Clicks this square takes inside a cube of the given type, before upgrades.
func get_hp(cube_type: CubeType) -> int:
	if hp_multiplier > 0.0 and cube_type:
		return roundi(cube_type.square_type.hp * hp_multiplier)
	return hp


## Money this square pays inside a cube of the given type.
func get_value(cube_type: CubeType) -> int:
	if value_multiplier > 0.0 and cube_type:
		return roundi(cube_type.square_type.value * value_multiplier)
	return value


func is_explosive() -> bool:
	return blast_radius > 0


## Colors used for debris particles.
func get_debris_colors() -> Array[Color]:
	return [shadow_color, base_color, base_color, light_color, shine_color]
