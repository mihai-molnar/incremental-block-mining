class_name PrestigePage
extends ItemListPage
## Sidebar page for prestige: the Shards you have and the boost they give, what collapsing
## the mine now would pay, the Collapse button (click twice), then the perks Shards buy.
## Its tab shows up once Game.is_prestige_unlocked().

## Seconds the Collapse button waits for the confirming second click.
const CONFIRM_TIME := 3.0
## Seconds the collapse effects play before the new run starts.
const COLLAPSE_TIME := 1.2

@export var fx: Fx
@export var work_area: WorkArea

var _shards_label: Label
var _boost_label: Label
var _run_label: Label
var _collapse_button: Button
var _confirm_left := 0.0
var _collapsing := false


func _ready() -> void:
	_build_header()
	super()
	set_process(false)
	Game.stats_changed.connect(_refresh_header)
	Game.shards_changed.connect(func(_shards: int) -> void: _refresh_header())
	Game.prestige_unlocked.connect(_on_prestige_unlocked)
	tab_button.visible = Game.is_prestige_unlocked()
	_refresh_header()
	var reward := Game.take_collapse_reward()
	if reward > 0:
		fx.shards_gained.call_deferred(reward, Game.get_shard_boost())


func _process(delta: float) -> void:
	_confirm_left -= delta
	if _confirm_left <= 0.0:
		set_process(false)
		_refresh_header()


func _build_header() -> void:
	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", 4)
	add_child(header)
	var shard_row := HBoxContainer.new()
	shard_row.add_theme_constant_override("separation", 5)
	header.add_child(shard_row)
	var icon := TextureRect.new()
	icon.texture = PixelSprites.get_texture(&"shard")
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	shard_row.add_child(icon)
	_shards_label = Label.new()
	_shards_label.theme_type_variation = &"TitleLabel"
	shard_row.add_child(_shards_label)
	_boost_label = _add_label(header, &"MutedLabel")
	_run_label = _add_label(header, &"")
	_collapse_button = Button.new()
	_collapse_button.focus_mode = Control.FOCUS_NONE
	_collapse_button.pressed.connect(_on_collapse_pressed)
	header.add_child(_collapse_button)
	var note := _add_label(header, &"MutedLabel")
	note.text = "Collapsing resets money, upgrades and cubes. You keep Shards, perks, unlocks and stats."
	header.add_child(HSeparator.new())
	var perks := _add_label(header, &"")
	perks.text = "Perks, kept forever:"


func _add_label(parent: Control, variation: StringName) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label


func _refresh_header() -> void:
	_shards_label.text = "%d Shard%s" % [Game.shards, "" if Game.shards == 1 else "s"]
	_boost_label.text = "+%d%% to all earnings: %d%% for each of the %d Shard%s you've earned" % [
		roundi(Game.get_shard_boost() * 100.0), roundi(Game.get_shard_bonus() * 100.0),
		Game.total_shards, "" if Game.total_shards == 1 else "s"]
	var gain := Game.get_collapse_shards()
	var next := Currency.format(Game.get_next_shard_earnings())
	if gain > 0:
		_run_label.text = "Earned this run: %s\nCollapse now for %d Shard%s\nNext Shard at %s" % [
			Currency.format(Game.run_earned), gain, "" if gain == 1 else "s", next]
	else:
		_run_label.text = "Earned this run: %s\nThe first Shard comes at %s" % [Currency.format(Game.run_earned), next]
	_collapse_button.disabled = gain <= 0 or _collapsing
	_collapse_button.text = "Click again to collapse" if _confirm_left > 0.0 else "Collapse the mine"


func _on_collapse_pressed() -> void:
	Sfx.play(&"click")
	if _confirm_left <= 0.0:
		_confirm_left = CONFIRM_TIME
		set_process(true)
		_refresh_header()
		return
	_collapse()


## Shatters the field, then collapses and starts the new run on a fresh scene.
func _collapse() -> void:
	_collapsing = true
	_confirm_left = 0.0
	set_process(false)
	_refresh_header()
	Game.set_auto_buy_cube(null)
	var sidebar := find_parent("Sidebar") as Sidebar
	if sidebar:
		sidebar.close()
	fx.mine_collapsed(work_area.get_cubes())
	work_area.clear_field()
	await get_tree().create_timer(COLLAPSE_TIME).timeout
	Game.collapse()
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


func _on_prestige_unlocked() -> void:
	tab_button.visible = true
	_new_items.append_array(items)
