class_name WelcomeBack
extends CanvasLayer
## Shown on start-up when the drones made money while the game was closed. It pauses the
## game until the player collects, which pays out with a shower of coins.
## Its process mode is Always, so it works while the tree is paused.

@export var fx: Fx

@onready var _panel: Control = %Panel
@onready var _summary: Label = %Summary
@onready var _coin_icon: TextureRect = %CoinIcon
@onready var _amount: Label = %Amount
@onready var _hint: Label = %Hint
@onready var _collect_button: Button = %CollectButton


func _ready() -> void:
	visible = false
	if Game.offline_earnings <= 0:
		return
	var cubes := Game.offline_cubes
	_summary.text = "Your drones mined %d %s%s\nin %s" % [
		cubes, Game.offline_cube_type.display_name, "" if cubes == 1 else "s",
		_format_duration(Game.offline_seconds)]
	_coin_icon.texture = PixelSprites.get_texture(&"coin_big")
	_amount.text = "+" + Currency.format(Game.offline_earnings)
	_hint.text = "Away, drones work at %d%% speed\nfor up to %s" % [
		roundi(Game.OFFLINE_EFFICIENCY * 100.0), _format_duration(Game.OFFLINE_CAP)]
	_collect_button.pressed.connect(_collect)
	_panel.resized.connect(func() -> void: _panel.pivot_offset = _panel.size / 2.0)
	visible = true
	get_tree().paused = true
	_panel.scale = Vector2.ONE * 0.85
	_panel.create_tween().set_ignore_time_scale().tween_property(_panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	# Esc collects too, rather than opening the pause menu on top.
	if visible and event.is_action_pressed("pause"):
		_collect()
		get_viewport().set_input_as_handled()


func _collect() -> void:
	if not visible:
		return
	var from := _amount.get_global_rect().get_center()
	visible = false
	get_tree().paused = false
	var amount := Game.collect_offline_earnings()
	Sfx.play(&"buy")
	if fx:
		fx.coins(fx.get_viewport().get_canvas_transform().affine_inverse() * from, amount, 16)


## "1h 12m", "45m", "2h".
static func _format_duration(seconds: int) -> String:
	var hours := floori(seconds / 3600.0)
	var minutes := floori((seconds % 3600) / 60.0)
	if hours == 0:
		return "%dm" % maxi(minutes, 1)
	if minutes == 0:
		return "%dh" % hours
	return "%dh %dm" % [hours, minutes]
