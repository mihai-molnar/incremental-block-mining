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
## Squares that start as this type instead, `mixed_chance` of them (rocks in deep cubes).
@export var mixed_square_type: SquareType
@export_range(0.0, 1.0, 0.01) var mixed_chance := 0.0
## The Star Core, the end goal: its squares never convert when it lands, it earns no
## mastery and doesn't count as a cube cleared, the auto-buyer can't buy it, only one can
## be out at a time, and breaking it frees the star.
@export var is_goal := false
## A line of the Fallen Star story, shown once ever, the first time this cube is bought.
## Empty for most cubes.
@export_multiline var story_line := ""


func get_square_count() -> int:
	return grid_size.x * grid_size.y
