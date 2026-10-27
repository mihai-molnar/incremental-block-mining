class_name ComboMeter
extends Control
## The combo under the money counter: its multiplier, and a bar that empties as the time
## to land the next hit runs out. Shows from the second hit on and fades when it drops.

const VALUE_FONT := preload("res://assets/fonts/Silkscreen-Bold.ttf")
const LABEL_FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const BAR_SIZE := Vector2(64, 3)
const BAR_TOP := 20.0
const SHADOW_COLOR := Color("0f1020")
const TRACK_COLOR := Color("333c57")
const LABEL_COLOR := Color("94b0c2")
## The multiplier warms up from yellow to orange as it nears the cap, then flickers
## between orange and white once it's there.
const WARM_COLOR := Color("ffcd75")
const HOT_COLOR := Color("ef7d57")
const MAX_FLICKER_COLOR := Color("f4f4f4")
const MAX_FLICKER_FRAME := 0.1

@export var combo: Combo

## What's drawn, kept after the combo drops so the meter can fade out showing it.
var _multiplier := 1.0
var _maxed := false
var _flicker_t := 0.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	set_process(false)
	combo.changed.connect(_on_combo_changed)


func _process(delta: float) -> void:
	_flicker_t += delta
	queue_redraw()


func _on_combo_changed() -> void:
	if combo.hits >= 2:
		_multiplier = combo.get_multiplier()
		_maxed = combo.is_maxed()
		_pop()
	elif combo.hits == 0 and modulate.a > 0.0:
		_fade_out()


func _pop() -> void:
	set_process(true)
	if _tween:
		_tween.kill()
	modulate.a = 1.0
	pivot_offset = Vector2(0, BAR_TOP / 2.0)
	scale = Vector2.ONE * (1.3 if _maxed else 1.15)
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _fade_out() -> void:
	if _tween:
		_tween.kill()
	scale = Vector2.ONE
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(set_process.bind(false))


func _get_color() -> Color:
	if _maxed:
		return HOT_COLOR if floori(_flicker_t / MAX_FLICKER_FRAME) % 2 == 0 else MAX_FLICKER_COLOR
	var cap := Game.get_combo_cap()
	var heat := (_multiplier - 1.0) / (cap - 1.0) if cap > 1.0 else 1.0
	return WARM_COLOR if heat < 0.5 else HOT_COLOR


func _draw() -> void:
	var color := _get_color()
	var value := "x" + String.num(_multiplier, 1)
	var baseline := roundf(VALUE_FONT.get_ascent(16))
	_draw_text(VALUE_FONT, Vector2(0, baseline), value, 16, color)
	var value_width := VALUE_FONT.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_draw_text(LABEL_FONT, Vector2(value_width + 4.0, baseline), "MAX" if _maxed else "COMBO", 8, LABEL_COLOR)
	var bar := Rect2(Vector2(0, BAR_TOP), BAR_SIZE)
	draw_rect(bar.grow(1), SHADOW_COLOR)
	draw_rect(bar, TRACK_COLOR)
	var fill := roundf(BAR_SIZE.x * combo.get_time_ratio())
	if fill > 0.0:
		draw_rect(Rect2(bar.position, Vector2(fill, BAR_SIZE.y)), color)


## Text with the HUD's drop shadow (1 right, 2 down).
func _draw_text(font: Font, at: Vector2, text: String, font_size: int, color: Color) -> void:
	draw_string(font, at + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, SHADOW_COLOR)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
