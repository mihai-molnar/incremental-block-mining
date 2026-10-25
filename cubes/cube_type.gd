class_name CubeType
extends Resource
## Defines a kind of cube: what it costs, its size and the squares it's made of.
## Add new cube kinds by saving new CubeType resources.

@export var id: StringName = &"cube"
@export var display_name := "Cube"
@export var price := 20
@export var grid_size := Vector2i(4, 4)
## What every square of this cube starts as (before upgrades change some of them).
@export var square_type: SquareType


func get_square_count() -> int:
	return grid_size.x * grid_size.y
