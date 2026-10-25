class_name PauseMenu
extends CanvasLayer
## Pauses the game and shows the pause menu. Toggled with the "pause" action (Esc).
## Its process mode is Always, so it keeps working while the tree is paused.

var is_open := false

var _tween: Tween

@onready var _dim: ColorRect = %Dim
@onready var _panel: Control = %Panel
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	_panel.resized.connect(func() -> void: _panel.pivot_offset = _panel.size / 2.0)
	_quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if is_open:
		close()
	else:
		open()


func open() -> void:
	is_open = true
	get_tree().paused = true
	visible = true
	Sfx.play(&"click")
	if _tween:
		_tween.kill()
	_dim.modulate.a = 0.0
	_panel.scale = Vector2.ONE * 0.85
	_tween = create_tween().set_parallel().set_ignore_time_scale()
	_tween.tween_property(_dim, "modulate:a", 1.0, 0.12)
	_tween.tween_property(_panel, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	is_open = false
	get_tree().paused = false
	visible = false
	Sfx.play(&"click")


func _on_quit_pressed() -> void:
	get_tree().quit()
