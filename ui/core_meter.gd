class_name CoreMeter
extends Control
## At the top of the field while a Star Core is out: the clicks it still needs, over a
## bar that empties as it comes down, so the player can judge whether the run will last.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
## Seconds between checks of the core's hits.
const REFRESH := 0.1
const BASELINE := 8.0
const BAR := Rect2i(0, 12, 0, 7)
const TEXT_COLOR := Color("f4f4f4")
const SHADOW_COLOR := Color("0f1020")
const TRACK_COLOR := Color("333c57")
## The fill: its color, the highlight along its top row and the shade along its bottom.
const FILL_COLORS: Array[Color] = [Color("ffcd75"), Color("f4f4f4"), Color("ef7d57")]

@export var work_area: WorkArea

var _left := 0
var _total := 0
var _wait := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update()


func _process(delta: float) -> void:
	_wait -= delta
	if _wait <= 0.0:
		_wait = REFRESH
		_update()


func _update() -> void:
	var core := work_area.get_star_core()
	visible = core != null
	if core == null:
		return
	var left := core.get_hits_left()
	var total := core.get_total_hits()
	if left != _left or total != _total:
		_left = left
		_total = total
		queue_redraw()


func _draw() -> void:
	var text := "Star Core: %s clicks left" % Currency.format(_left)
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	var at := Vector2(floorf((size.x - width) / 2.0), BASELINE)
	draw_string(FONT, at + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, SHADOW_COLOR)
	draw_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXT_COLOR)
	var bar := Rect2i(0, BAR.position.y, floori(size.x), BAR.size.y)
	draw_rect(bar, SHADOW_COLOR)
	var inner := bar.grow(-1)
	draw_rect(inner, TRACK_COLOR)
	if _total <= 0 or _left <= 0:
		return
	var fill := Rect2i(inner.position, Vector2i(maxi(roundi(inner.size.x * float(_left) / _total), 1), inner.size.y))
	draw_rect(fill, FILL_COLORS[0])
	draw_rect(Rect2i(fill.position, Vector2i(fill.size.x, 1)), FILL_COLORS[1])
	draw_rect(Rect2i(fill.position.x, fill.end.y - 1, fill.size.x, 1), FILL_COLORS[2])
