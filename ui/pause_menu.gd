class_name PauseMenu
extends CanvasLayer
## Pauses the game and shows the pause menu. Toggled with the "pause" action (Esc).
## Its process mode is Always, so it keeps working while the tree is paused.
## End run and Reset progress ask for a second click before they do anything. Closing it
## leaves the game paused while the run-end screen is up.

const END_RUN_LABEL := "End run"
const RESET_LABEL := "Reset progress"
const CONFIRM_LABEL := "Click to confirm"

var is_open := false

var _tween: Tween

@onready var _dim: ColorRect = %Dim
@onready var _panel: Control = %Panel
@onready var _end_run_button: Button = %EndRunButton
@onready var _reset_button: Button = %ResetButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	visible = false
	_panel.resized.connect(func() -> void: _panel.pivot_offset = _panel.size / 2.0)
	_end_run_button.pressed.connect(_on_end_run_pressed)
	_reset_button.pressed.connect(_on_reset_pressed)
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
	_end_run_button.visible = Game.is_run_active()
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
	get_tree().paused = Game.run_over
	visible = false
	_end_run_button.text = END_RUN_LABEL
	_reset_button.text = RESET_LABEL
	Sfx.play(&"click")


## Breaks the pickaxe, which ends the run as if its HP had run out.
func _on_end_run_pressed() -> void:
	if _end_run_button.text != CONFIRM_LABEL:
		Sfx.play(&"click")
		_end_run_button.text = CONFIRM_LABEL
		return
	close()
	Game.break_pickaxe()


func _on_reset_pressed() -> void:
	Sfx.play(&"click")
	if _reset_button.text != CONFIRM_LABEL:
		_reset_button.text = CONFIRM_LABEL
		return
	Game.reset_progress()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	Game.save_game()
	get_tree().quit()
