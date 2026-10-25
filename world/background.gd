extends Node2D
## Work area backdrop: flat color with a faint dot grid. Drawn slightly larger than the
## screen so screen shake never reveals an edge.

@export var size := Vector2(640, 360)
@export var color := Color("1a1c2c")
@export var dot_color := Color("262b44")
@export var dot_spacing := 16
@export var margin := 16.0


func _draw() -> void:
	draw_rect(Rect2(-Vector2.ONE * margin, size + Vector2.ONE * margin * 2.0), color)
	for x in range(0, int(size.x) + 1, dot_spacing):
		for y in range(0, int(size.y) + 1, dot_spacing):
			draw_rect(Rect2(x, y, 1, 1), dot_color)
