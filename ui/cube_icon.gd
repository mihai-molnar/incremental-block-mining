class_name CubeIcon
extends Control
## Miniature preview of a cube type, used in the shop. Optionally shows a few squares
## in an accent type (e.g. for an upgrade that turns some squares into diamonds).

## Cell size in pixels, shrunk for big grids so every icon stays about the same size.
const MAX_CELL := 6
const MAX_GRID_PX := 26
const ACCENT_CELLS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(3, 2), Vector2i(0, 3)]

@export var cube_type: CubeType:
	set(v):
		cube_type = v
		_update_minimum_size()
		queue_redraw()
@export var accent_type: SquareType:
	set(v):
		accent_type = v
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_minimum_size()


func _update_minimum_size() -> void:
	if cube_type:
		custom_minimum_size = Vector2(cube_type.grid_size * _get_cell()) + Vector2(2, 2)


func _get_cell() -> int:
	var longest := maxi(cube_type.grid_size.x, cube_type.grid_size.y)
	return clampi(floori(float(MAX_GRID_PX) / longest), 3, MAX_CELL)


func _draw() -> void:
	if cube_type == null:
		return
	var cell := _get_cell()
	var grid_px := Vector2(cube_type.grid_size * cell)
	var origin := ((size - grid_px) / 2.0).floor()
	draw_rect(Rect2(origin + Vector2(1, 2), grid_px), Color(0, 0, 0, 0.35))
	for y in cube_type.grid_size.y:
		for x in cube_type.grid_size.x:
			var t := cube_type.square_type
			if accent_type and Vector2i(x, y) in ACCENT_CELLS:
				t = accent_type
			var r := Rect2(origin + Vector2(x, y) * cell, Vector2.ONE * cell)
			draw_rect(r, t.outline_color)
			draw_rect(r.grow(-1), t.base_color)
			draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(cell - 2, 1)), t.light_color)
			if cell > 4:
				draw_rect(Rect2(r.position + Vector2(1, cell - 2), Vector2(cell - 2, 1)), t.shadow_color)
