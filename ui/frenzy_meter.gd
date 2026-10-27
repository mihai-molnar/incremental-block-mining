class_name FrenzyMeter
extends Control
## Running frenzies, under the combo meter: each one's name in its color and a bar with
## the seconds left. Flickers in the last few seconds, and hides when none is running.

const TITLE_FONT := preload("res://assets/fonts/Silkscreen-Bold.ttf")
const LABEL_FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const BAR_SIZE := Vector2(96, 3)
const ROW_HEIGHT := 26.0
const SHADOW_COLOR := Color("0f1020")
const TRACK_COLOR := Color("333c57")
const LABEL_COLOR := Color("94b0c2")
const WARNING_TIME := 5.0
const FLICKER_FRAME := 0.12

## Running frenzies and how long each one was started for (Upgrade -> float).
var _durations := {}
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	Game.timed_effect_started.connect(_on_effect_started)
	Game.timed_effect_ended.connect(_on_effect_ended)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _on_effect_started(effect: Upgrade) -> void:
	_durations[effect] = Game.get_effect_time_left(effect)
	set_process(true)
	pivot_offset = Vector2(0, ROW_HEIGHT / 2.0)
	scale = Vector2.ONE * 1.3
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_effect_ended(effect: Upgrade) -> void:
	_durations.erase(effect)
	set_process(not _durations.is_empty())
	queue_redraw()


func _draw() -> void:
	var y := 0.0
	for effect: Upgrade in _durations:
		_draw_row(effect, y)
		y += ROW_HEIGHT


func _draw_row(effect: Upgrade, top: float) -> void:
	var left := Game.get_effect_time_left(effect)
	var frenzy := effect as Frenzy
	var color := frenzy.color if frenzy else Color("f4f4f4")
	if left < WARNING_TIME and floori(_t / FLICKER_FRAME) % 2 == 0:
		color = Color("f4f4f4")
	var baseline := top + roundf(TITLE_FONT.get_ascent(16))
	_draw_text(TITLE_FONT, Vector2(0, baseline), effect.get_title(), 16, color)
	var bar := Rect2(Vector2(0, top + 20.0), BAR_SIZE)
	draw_rect(bar.grow(1), SHADOW_COLOR)
	draw_rect(bar, TRACK_COLOR)
	var ratio := clampf(left / _durations[effect], 0.0, 1.0)
	var fill := roundf(BAR_SIZE.x * ratio)
	if fill > 0.0:
		draw_rect(Rect2(bar.position, Vector2(fill, BAR_SIZE.y)), color)
	_draw_text(LABEL_FONT, Vector2(BAR_SIZE.x + 5.0, bar.end.y + 1.0), "%ds" % ceili(left), 8, LABEL_COLOR)


## Text with a drop shadow, like the other HUD labels.
func _draw_text(font: Font, at: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(font, at + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, SHADOW_COLOR)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
