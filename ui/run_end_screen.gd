class_name RunEndScreen
extends CanvasLayer
## Takes over once the pickaxe breaks. The last click's chain reactions get a moment, the
## field collapses and Game.end_run pays the run's Shards. Then this screen covers
## everything: the run's summary and records, the Shards, and the perks they buy. The game
## stays paused under it until Start next run begins a fresh run on a fresh scene.

## Seconds from the pickaxe breaking to the mine collapsing, then to the screen showing.
const BREAK_TIME := 1.0
const COLLAPSE_TIME := 1.2
const BACKGROUND_COLOR := Color("1a1c2c")
const RECORD_COLOR := Color("ffcd75")
## Summary rows: the Game.last_run key, and its label.
const SUMMARY_ROWS := [
	["seconds", "Time"],
	["clicks", "Clicks"],
	["cubes", "Cubes cleared"],
	["earned", "Money earned"],
]

@export var fx: Fx
@export var work_area: WorkArea
@export var drones: DroneSwarm
@export var sidebar: Sidebar
## The perks Shards buy, listed cheapest first.
@export var perks: Array[ShopItem] = []

var _ending := false
var _background: ColorRect
var _title: Label
## Game.last_run key -> [value label, best label].
var _summary_labels := {}
## Why the run ended: the pickaxe broke, or the star is free.
var _subtitle: Label
var _gained_label: Label
var _boost_label: Label
var _shards_label: Label
var _perk_list: ItemListPage


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	Game.pickaxe_broken.connect(_on_pickaxe_broken)
	Game.shards_changed.connect(func(_shards: int) -> void: _refresh_shards())
	if Game.run_over:
		present.call_deferred(false)
	elif not Game.is_run_active() and not Game.run_won:
		# The game closed while the field was collapsing: finish ending the run.
		_on_pickaxe_broken.call_deferred()


func _build() -> void:
	_background = ColorRect.new()
	_background.color = BACKGROUND_COLOR
	_background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_background)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	_background.add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	margin.add_child(columns)
	_build_summary(columns)
	columns.add_child(VSeparator.new())
	_build_perks(columns)


func _build_summary(parent: Control) -> void:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 240
	box.add_theme_constant_override("separation", 8)
	parent.add_child(box)
	_title = _add_label(box, &"TitleLabel")
	_subtitle = _add_label(box, &"MutedLabel")
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for row: Array in SUMMARY_ROWS:
		var name_label := _add_label(grid, &"MutedLabel", false)
		name_label.text = row[1]
		var value := _add_label(grid, &"", false)
		var best := _add_label(grid, &"MutedLabel", false)
		_summary_labels[row[0]] = [value, best]
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var gained_row := _add_shard_row(box)
	_gained_label = _add_label(gained_row, &"TitleLabel", false)
	_boost_label = _add_label(box, &"MutedLabel")
	var start := Button.new()
	start.text = "Start next run"
	start.focus_mode = Control.FOCUS_NONE
	start.pressed.connect(_on_start_pressed)
	box.add_child(start)


func _build_perks(parent: Control) -> void:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	parent.add_child(box)
	var shard_row := _add_shard_row(box)
	_shards_label = _add_label(shard_row, &"TitleLabel", false)
	var note := _add_label(box, &"MutedLabel")
	note.text = "Spend them on perks, kept forever:"
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	_perk_list = ItemListPage.new()
	_perk_list.items = perks
	_perk_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_perk_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_perk_list)


## Labels that wrap need a width from their container; ones in rows and the grid don't wrap.
func _add_label(parent: Control, variation: StringName, wraps := true) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wraps else TextServer.AUTOWRAP_OFF
	parent.add_child(label)
	return label


func _add_shard_row(parent: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	parent.add_child(row)
	var icon := TextureRect.new()
	icon.texture = PixelSprites.get_texture(&"shard")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	row.add_child(icon)
	return row


## Breaks up the field, ends the run, then shows the screen.
func _on_pickaxe_broken() -> void:
	if _ending:
		return
	_ending = true
	fx.pickaxe_broken(work_area.get_mouse_world_position())
	await get_tree().create_timer(BREAK_TIME).timeout
	# The last click's chain reaction freed the star: the victory screen takes over.
	if Game.run_won:
		_ending = false
		return
	sidebar.close()
	fx.mine_collapsed(work_area.get_cubes())
	work_area.clear_field()
	drones.clear()
	await get_tree().create_timer(COLLAPSE_TIME).timeout
	Engine.time_scale = 1.0
	Game.end_run()
	present(true)


## Shows the screen over a paused game, fading in when `animated` (a run that just ended).
func present(animated: bool) -> void:
	_refresh()
	_perk_list.on_shown()
	visible = true
	get_tree().paused = true
	if animated:
		_background.modulate.a = 0.0
		create_tween().tween_property(_background, "modulate:a", 1.0, 0.4)
		if Game.last_run.get("shards", 0) > 0:
			Sfx.play(&"unlock", 0.0)


func _refresh() -> void:
	var run := Game.last_run
	_title.text = "Run %d is over" % run.get("run", 1)
	var won := Game.star_free and Game.star_freed_in_run == int(run.get("run", 0))
	_subtitle.text = "The star is free. The dig went like this:" if won \
		else "Your pickaxe broke and the tunnel caved in. The dig went like this:"
	var records: Array = run.get("records", [])
	for key: String in _summary_labels:
		var labels: Array = _summary_labels[key]
		var value: Label = labels[0]
		var best: Label = labels[1]
		value.text = _format(key, run.get(key, 0))
		if key in records:
			best.text = "New best!"
			best.add_theme_color_override("font_color", RECORD_COLOR)
		else:
			# The first run is its own best.
			best.text = "" if run.get("run", 1) == 1 else "Best: " + _format(key, Game.best_run.get(key, 0))
			best.remove_theme_color_override("font_color")
	var gained: int = run.get("shards", 0)
	_gained_label.text = "+%d Shard%s" % [gained, "" if gained == 1 else "s"]
	_refresh_shards()


func _refresh_shards() -> void:
	_shards_label.text = "%d Shard%s" % [Game.shards, "" if Game.shards == 1 else "s"]
	_boost_label.text = "All earnings +%d%%: %s%% for each of the %d Shard%s of starlight you've dug up" % [
		roundi(Game.get_shard_boost() * 100.0), Upgrade.format_number(Game.get_shard_bonus() * 100.0),
		Game.total_shards, "" if Game.total_shards == 1 else "s"]


func _format(key: String, value: int) -> String:
	match key:
		"seconds":
			return "%d:%02d" % [floori(value / 60.0), value % 60]
		"earned":
			return Currency.format(value)
	return str(value)


func _on_start_pressed() -> void:
	Sfx.play(&"click")
	Game.start_run()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
