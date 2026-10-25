class_name Hud
extends CanvasLayer
## Screen-space UI: money counter, tool mode buttons and the shop sidebar.

@export var work_area: WorkArea

var _shown_money := 0
var _catch_up_timer := 0.0
var _bump_tween: Tween

@onready var _money_box: Control = %MoneyBox
@onready var _coin_icon: TextureRect = %CoinIcon
@onready var _money_label: Label = %MoneyLabel
@onready var _break_button: Button = %BreakButton
@onready var _move_button: Button = %MoveButton


func _ready() -> void:
	_coin_icon.texture = PixelSprites.get_texture(&"coin_big")
	_break_button.icon = PixelSprites.get_texture(&"pickaxe")
	_move_button.icon = PixelSprites.get_texture(&"hand_open")
	var group := ButtonGroup.new()
	_break_button.button_group = group
	_move_button.button_group = group
	_break_button.pressed.connect(_on_mode_button_pressed.bind(WorkArea.Mode.BREAK))
	_move_button.pressed.connect(_on_mode_button_pressed.bind(WorkArea.Mode.MOVE))
	work_area.mode_changed.connect(_on_mode_changed)
	_on_mode_changed(work_area.mode)
	Game.money_changed.connect(_on_money_changed)
	_shown_money = Game.money
	_refresh_money()


## Screen position flying coins should head to.
func get_coin_target() -> Vector2:
	return _coin_icon.get_global_rect().get_center()


func on_coin_arrived(value: int) -> void:
	_shown_money = mini(_shown_money + value, Game.money)
	_refresh_money()
	_bump(1.35)


func _process(delta: float) -> void:
	# Safety net: if coins never arrive, the counter still catches up.
	if _shown_money != Game.money:
		_catch_up_timer -= delta
		if _catch_up_timer <= 0.0:
			_shown_money = Game.money
			_refresh_money()


func _on_money_changed(money: int, delta: int) -> void:
	if delta < 0:
		_shown_money = money
		_refresh_money()
		_bump(0.75)
	else:
		_catch_up_timer = 1.5


func _refresh_money() -> void:
	_money_label.text = str(_shown_money)


func _bump(from_scale: float) -> void:
	if _bump_tween:
		_bump_tween.kill()
	_money_box.pivot_offset = Vector2(0, _money_box.size.y / 2.0)
	_money_box.scale = Vector2.ONE * from_scale
	_bump_tween = create_tween()
	_bump_tween.tween_property(_money_box, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_mode_button_pressed(mode: WorkArea.Mode) -> void:
	Sfx.play(&"click")
	work_area.set_mode(mode)


func _on_mode_changed(mode: WorkArea.Mode) -> void:
	_break_button.set_pressed_no_signal(mode == WorkArea.Mode.BREAK)
	_move_button.set_pressed_no_signal(mode == WorkArea.Mode.MOVE)
