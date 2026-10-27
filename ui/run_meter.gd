class_name RunMeter
extends Control
## Under the money counter: the pickaxe's HP, then the Shards you have and what this run
## adds, over a bar filling toward the run's next Shard. The HP bar flashes once it's low.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const BAR_X := 11.0
const BAR_WIDTH := 60.0
const TEXT_X := 75.0
## Share of its max HP under which the pickaxe's bar flashes.
const LOW_HP := 0.2
const FLASH_FRAME := 0.15
const SHADOW_COLOR := Color("0f1020")
const TRACK_COLOR := Color("333c57")
const HP_COLOR := Color("a7f070")
const LOW_HP_COLOR := Color("e43b44")
const SHARD_COLOR := Color("73eff7")
const TEXT_COLOR := Color("f4f4f4")

var _flash_t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Game.pickaxe_changed.connect(func(_hp: int) -> void: _update())
	# Earnings move the Shard bar.
	Game.money_changed.connect(func(_money: int, _delta: int) -> void: queue_redraw())
	Game.shards_changed.connect(func(_shards: int) -> void: queue_redraw())
	_update()


func _process(delta: float) -> void:
	_flash_t += delta
	queue_redraw()


func _update() -> void:
	set_process(_is_low())
	queue_redraw()


func _is_low() -> bool:
	return Game.pickaxe_hp <= Game.get_max_pickaxe_hp() * LOW_HP


func _draw() -> void:
	draw_texture(PixelSprites.get_texture(&"pickaxe_small"), Vector2.ZERO)
	var hp_color := HP_COLOR
	if _is_low():
		hp_color = LOW_HP_COLOR if floori(_flash_t / FLASH_FRAME) % 2 == 0 else TEXT_COLOR
	_draw_bar(Rect2(BAR_X, 2, BAR_WIDTH, 4), float(Game.pickaxe_hp) / Game.get_max_pickaxe_hp(), hp_color)
	_draw_text(Vector2(TEXT_X, 7), str(Game.pickaxe_hp), TEXT_COLOR)

	draw_texture(PixelSprites.get_texture(&"shard_small"), Vector2(1, 12))
	_draw_bar(Rect2(BAR_X, 14, BAR_WIDTH, 2), Game.get_shard_progress(), SHARD_COLOR)
	var owned := str(Game.shards)
	_draw_text(Vector2(TEXT_X, 18), owned, TEXT_COLOR)
	var run_shards := Game.get_run_shards()
	if run_shards > 0:
		var x := TEXT_X + FONT.get_string_size(owned, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 3.0
		_draw_text(Vector2(x, 18), "+%d" % run_shards, SHARD_COLOR)


func _draw_bar(rect: Rect2, ratio: float, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(1, 1), rect.size), SHADOW_COLOR)
	draw_rect(rect, TRACK_COLOR)
	if ratio > 0.0:
		draw_rect(Rect2(rect.position, Vector2(maxf(roundf(rect.size.x * ratio), 1.0), rect.size.y)), color)


func _draw_text(baseline: Vector2, text: String, color: Color) -> void:
	draw_string(FONT, baseline + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, SHADOW_COLOR)
	draw_string(FONT, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
