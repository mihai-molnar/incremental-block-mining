class_name VictoryScreen
extends CanvasLayer
## Takes over when the Star Core breaks: the star rises out of the stone (Fx.star_freed),
## the field clears, and this screen tells the end of the story with a summary of the
## whole dig. Keep mining ends the run as usual, paying its Shards, and opens the run-end
## screen; play goes on from there. A save made before Keep mining brings this screen back.

const BACKGROUND_COLOR := Color("1a1c2c")
const ENDING := "The last layer gives way. Light pours out of the stone, and the star rises up through every tunnel you dug, back into the sky."
const SUMMARY_ROWS: Array[String] = ["Time mining", "Runs", "Clicks", "Cubes cleared", "Shards earned"]

@export var fx: Fx
@export var work_area: WorkArea
@export var drones: DroneSwarm
@export var run_end: RunEndScreen
@export var sidebar: Sidebar

var _background: ColorRect
## Summary row label -> value label.
var _values := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	Game.star_freed.connect(_on_star_freed)
	if Game.run_won:
		# The game closed before Keep mining: back to the ending, without the show.
		work_area.clear_field()
		drones.clear()
		_present.call_deferred(false)


func _build() -> void:
	_background = ColorRect.new()
	_background.color = BACKGROUND_COLOR
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 320
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	var title := Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.text = "The star is free"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var ending := Label.new()
	ending.text = ENDING
	ending.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ending)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(grid)
	for row in SUMMARY_ROWS:
		var name_label := Label.new()
		name_label.theme_type_variation = &"MutedLabel"
		name_label.text = row
		grid.add_child(name_label)
		var value := Label.new()
		grid.add_child(value)
		_values[row] = value
	var keep := Button.new()
	keep.text = "Keep mining"
	keep.focus_mode = Control.FOCUS_NONE
	keep.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	keep.pressed.connect(_on_keep_mining_pressed)
	box.add_child(keep)


func _on_star_freed() -> void:
	sidebar.close()
	var core: Cube = null
	for cube in work_area.get_cubes():
		if cube.cube_type.is_goal:
			core = cube
	await fx.star_freed(core)
	work_area.clear_field()
	drones.clear()
	Engine.time_scale = 1.0
	_present(true)


func _present(animated: bool) -> void:
	_refresh()
	visible = true
	get_tree().paused = true
	if animated:
		_background.modulate.a = 0.0
		create_tween().tween_property(_background, "modulate:a", 1.0, 0.6)


## The whole dig so far, this run included (its Shards are paid on Keep mining).
func _refresh() -> void:
	(_values["Time mining"] as Label).text = StatsPage.format_time(Game.get_time_mining())
	(_values["Runs"] as Label).text = str(Game.star_freed_in_run)
	(_values["Clicks"] as Label).text = Currency.format(Game.get_lifetime_clicks())
	(_values["Cubes cleared"] as Label).text = Currency.format(Game.get_stat(Game.STAT_CUBES_CLEARED))
	(_values["Shards earned"] as Label).text = Currency.format(Game.total_shards + Game.get_run_shards())


func _on_keep_mining_pressed() -> void:
	Sfx.play(&"click")
	visible = false
	Game.end_run()
	run_end.present(true)
