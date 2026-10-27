class_name UnlockToast
extends Control
## "UNLOCKED!" with the names of the shop items whose goals were just met (or Prestige).
## Pops in at the bottom of the field and fades after a few seconds; unlocks close
## together share one.

const TITLE_FONT := preload("res://assets/fonts/Silkscreen-Bold.ttf")
const NAME_FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const TITLE_COLOR := Color("ffcd75")
const NAME_COLOR := Color("f4f4f4")
const HINT_COLOR := Color("94b0c2")
const SHADOW_COLOR := Color("0f1020")
const SHOW_TIME := 3.5
const MAX_NAMES := 3

var _names: Array[String] = []
## Which sidebar tabs the unlocked items are on.
var _in_shop := false
var _in_upgrades := false
var _in_prestige := false
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	Game.items_unlocked.connect(_on_items_unlocked)
	Game.prestige_unlocked.connect(_on_prestige_unlocked)


func _on_items_unlocked(items: Array[ShopItem]) -> void:
	_start()
	for item in items:
		_names.append(item.get_title())
		if item is Upgrade:
			_in_upgrades = true
		else:
			_in_shop = true
	_pop()


func _on_prestige_unlocked() -> void:
	_start()
	_names.append("Prestige")
	_in_prestige = true
	_pop()


## Starts a fresh list unless the last toast is still up.
func _start() -> void:
	if modulate.a <= 0.0:
		_names.clear()
		_in_shop = false
		_in_upgrades = false
		_in_prestige = false


func _pop() -> void:
	queue_redraw()
	Sfx.play(&"unlock", 0.0)
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
	_draw_centered(TITLE_FONT, title_baseline, "UNLOCKED!", 16, TITLE_COLOR)
	_draw_centered(NAME_FONT, title_baseline + 13.0, _get_names_text(), 8, NAME_COLOR)
	_draw_centered(NAME_FONT, title_baseline + 24.0, _get_hint(), 8, HINT_COLOR)


## Up to MAX_NAMES names, then how many more, so a big jump in earnings stays on screen.
func _get_names_text() -> String:
	if _names.size() <= MAX_NAMES:
		return ", ".join(_names)
	return "%s and %d more" % [", ".join(_names.slice(0, MAX_NAMES)), _names.size() - MAX_NAMES]


func _get_hint() -> String:
	var tabs: Array[String] = []
	if _in_shop:
		tabs.append("the Shop [S]")
	if _in_upgrades:
		tabs.append("Upgrades [U]")
	if _in_prestige:
		tabs.append("Prestige [P]")
	return "in " + " and ".join(tabs)


## Text centered across the toast, with a drop shadow.
func _draw_centered(font: Font, baseline: float, text: String, font_size: int, color: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at := Vector2(roundf((size.x - width) / 2.0), baseline)
	var shadow := Vector2(1, 2) if font_size > 8 else Vector2(1, 1)
	draw_string(font, at + shadow, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, SHADOW_COLOR)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
