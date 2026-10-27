class_name RunMeter
extends Control
## Under the money counter: the pickaxe's HP bar, with an Unbreakable shield's bar on top
## of it while there is one, then the Shards bar filling toward the run's next Shard. The
## Shard count includes what the run has earned so far, so it ticks up each time the bar
## fills. The HP bar flashes once it's low.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
## The bars, outline included. The shield bar shares the HP bar's top outline.
const SHIELD_BAR := Rect2i(12, 0, 84, 5)
const HP_BAR := Rect2i(12, 4, 84, 9)
const SHARD_BAR := Rect2i(12, 16, 84, 7)
## Where the numbers start, right of the bars.
const TEXT_X := 100.0
## Height of Silkscreen's digits at size 8, to center them on a bar.
const DIGIT_HEIGHT := 5
## Share of its max HP under which the pickaxe's bar flashes.
const LOW_HP := 0.2
const FLASH_FRAME := 0.15
const OUTLINE_COLOR := Color("0f1020")
const TRACK_COLOR := Color("333c57")
const TEXT_COLOR := Color("f4f4f4")
## Each fill: its color, the highlight along its top row and the shade along its bottom.
const HP_COLORS: Array[Color] = [Color("38b764"), Color("a7f070"), Color("257179")]
const LOW_HP_COLORS: Array[Color] = [Color("b13e53"), Color("ef7d57"), Color("5d275d")]
const FLASH_COLORS: Array[Color] = [Color("f4f4f4"), Color("f4f4f4"), Color("94b0c2")]
const SHIELD_COLORS: Array[Color] = [Color("73eff7"), Color("f4f4f4"), Color("41a6f6")]
const SHARD_COLORS: Array[Color] = [Color("41a6f6"), Color("73eff7"), Color("3b5dc9")]

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
	var hp_colors := HP_COLORS
	if _is_low():
		hp_colors = LOW_HP_COLORS if floori(_flash_t / FLASH_FRAME) % 2 == 0 else FLASH_COLORS
	_draw_bar(HP_BAR, float(Game.pickaxe_hp) / Game.get_max_pickaxe_hp(), hp_colors)
	if Game.pickaxe_shield > 0:
		_draw_bar(SHIELD_BAR, float(Game.pickaxe_shield) / Game.pickaxe_shield_max, SHIELD_COLORS)
	_draw_icon(&"pickaxe_small", HP_BAR)
	_draw_number(HP_BAR, Game.pickaxe_hp)

	_draw_bar(SHARD_BAR, Game.get_shard_progress(), SHARD_COLORS)
	_draw_icon(&"shard_small", SHARD_BAR)
	_draw_number(SHARD_BAR, Game.shards + Game.get_run_shards())


func _draw_bar(bar: Rect2i, ratio: float, colors: Array[Color]) -> void:
	draw_rect(bar, OUTLINE_COLOR)
	var inner := bar.grow(-1)
	draw_rect(inner, TRACK_COLOR)
	if ratio <= 0.0:
		return
	var fill := Rect2i(inner.position, Vector2i(maxi(roundi(inner.size.x * minf(ratio, 1.0)), 1), inner.size.y))
	draw_rect(fill, colors[0])
	draw_rect(Rect2i(fill.position, Vector2i(fill.size.x, 1)), colors[1])
	draw_rect(Rect2i(fill.position.x, fill.end.y - 1, fill.size.x, 1), colors[2])


## The sprite centered in the space left of the bar.
func _draw_icon(sprite: StringName, bar: Rect2i) -> void:
	var texture := PixelSprites.get_texture(sprite)
	var sprite_size := Vector2i(texture.get_size())
	draw_texture(texture, Vector2(floori((bar.position.x - sprite_size.x) / 2.0), bar.position.y + floori((bar.size.y - sprite_size.y) / 2.0)))


## The number right of the bar, its digits centered on the bar's rows.
func _draw_number(bar: Rect2i, value: int) -> void:
	var baseline := Vector2(TEXT_X, bar.position.y + floori((bar.size.y + DIGIT_HEIGHT) / 2.0))
	draw_string(FONT, baseline + Vector2(1, 1), str(value), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, OUTLINE_COLOR)
	draw_string(FONT, baseline, str(value), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, TEXT_COLOR)
