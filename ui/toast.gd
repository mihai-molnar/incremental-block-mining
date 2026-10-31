class_name Toast
extends Control
## A title over a line of names and a hint, popping in over the field and fading after a
## few seconds. Subclasses fill in `_names` and the text; news arriving while one is up
## joins it.

const TITLE_FONT := preload("res://assets/fonts/Silkscreen-Bold.ttf")
const NAME_FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const NAME_COLOR := Color("f4f4f4")
const HINT_COLOR := Color("94b0c2")
const SHADOW_COLOR := Color("0f1020")
const SHOW_TIME := 3.5
const MAX_NAMES := 3

var _names: Array[String] = []
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0


## Whether it's on screen, fading included. News that comes after it's gone starts afresh.
func is_showing() -> bool:
	return modulate.a > 0.0


func _get_title() -> String:
	return ""


func _get_title_color() -> Color:
	return Color.WHITE


func _get_hint() -> String:
	return ""


## Pops it in (again) with the unlock chime, at `pitch`, and restarts the time it stays up.
func _pop(pitch := 1.0) -> void:
	queue_redraw()
	Sfx.play(&"unlock", 0.0, 0.0, pitch)
	if _tween:
		_tween.kill()
	modulate.a = 1.0
	pivot_offset = size / 2.0
	scale = Vector2.ONE * 1.3
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(SHOW_TIME)
	_tween.tween_property(self, "modulate:a", 0.0, 0.4)


func _draw() -> void:
	var title_baseline := roundf(TITLE_FONT.get_ascent(16))
	_draw_centered(TITLE_FONT, title_baseline, _get_title(), 16, _get_title_color())
	_draw_centered(NAME_FONT, title_baseline + 13.0, _get_names_text(), 8, NAME_COLOR)
	_draw_centered(NAME_FONT, title_baseline + 24.0, _get_hint(), 8, HINT_COLOR)


## Up to MAX_NAMES names, then how many more, so a burst of news stays on screen.
func _get_names_text() -> String:
	if _names.size() <= MAX_NAMES:
		return ", ".join(_names)
	return "%s and %d more" % [", ".join(_names.slice(0, MAX_NAMES)), _names.size() - MAX_NAMES]


## Text centered across the toast, with a drop shadow.
func _draw_centered(font: Font, baseline: float, text: String, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2(roundf((size.x - width) / 2.0), baseline)
	var shadow := Vector2(1, 2) if font_size > 8 else Vector2(1, 1)
	draw_string(font, at + shadow, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, SHADOW_COLOR)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
