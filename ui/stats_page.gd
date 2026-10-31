class_name StatsPage
extends SidebarPage
## Sidebar page with lifetime stats, records and bonuses (the boosts add to all earnings),
## built in code. Refreshes every so often while it's on screen.

const REFRESH := 0.5
const HEADING_COLOR := Color("ffcd75")

## Value labels by stat name, filled by _build.
var _values := {}
var _wait := 0.0


func _ready() -> void:
	_build()
	on_shown()


func on_shown() -> void:
	_refresh()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_wait -= delta
	if _wait <= 0.0:
		_wait = REFRESH
		_refresh()


func _build() -> void:
	_add_heading("Lifetime")
	for stat: String in ["Time mining", "Runs finished", "Clicks", "Squares broken", "Cubes cleared",
			"Money earned", "Shards earned", "Lucky Cubes caught"]:
		_add_row(stat)
	_add_heading("Records")
	for stat: String in ["Longest run", "Longest run time", "Most cubes in a run", "Most money in a run",
			"Biggest click", "Longest chain", "Cubes cleared in one click"]:
		_add_row(stat)
	_add_heading("Bonuses")
	for stat: String in ["Shard boost", "Achievement boost", "Achievements earned", "Cubes mastered"]:
		_add_row(stat)


func _refresh() -> void:
	_show("Time mining", _format_time(Game.get_time_mining()))
	_show("Runs finished", str(Game.get_stat(Game.STAT_RUNS)))
	_show("Clicks", Currency.format(Game.get_lifetime_clicks()))
	_show("Squares broken", Currency.format(Game.get_stat(Game.STAT_SQUARES_BROKEN)))
	_show("Cubes cleared", Currency.format(Game.get_stat(Game.STAT_CUBES_CLEARED)))
	_show("Money earned", Currency.format(Game.get_stat(Game.STAT_MONEY_EARNED)))
	_show("Shards earned", Currency.format(Game.total_shards))
	_show("Lucky Cubes caught", str(Game.get_stat(Game.STAT_LUCKY_CAUGHT)))
	_show("Longest run", "%s clicks" % Currency.format(Game.get_best_run_value("clicks")))
	_show("Longest run time", _format_time(Game.get_best_run_value("seconds")))
	_show("Most cubes in a run", Currency.format(Game.get_best_run_value("cubes")))
	_show("Most money in a run", Currency.format(Game.get_best_run_value("earned")))
	_show("Biggest click", "%s squares" % Currency.format(Game.get_stat(Game.STAT_BIGGEST_CLICK)))
	_show("Longest chain", "%d set off" % Game.get_stat(Game.STAT_LONGEST_CHAIN))
	_show("Cubes cleared in one click", str(Game.get_stat(Game.STAT_ONE_CLICK_CLEARS)))
	_show("Shard boost", _format_percent(Game.get_shard_boost()))
	_show("Achievement boost", _format_percent(Game.get_achievement_bonus()))
	_show("Achievements earned", str(Game.get_achievement_count()))
	_show("Cubes mastered", str(Game.get_mastered_count()))


func _add_heading(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", HEADING_COLOR)
	add_child(label)


func _add_row(stat: String) -> void:
	var row := HBoxContainer.new()
	add_child(row)
	var name_label := Label.new()
	name_label.text = stat
	name_label.theme_type_variation = &"MutedLabel"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var value := Label.new()
	row.add_child(value)
	_values[stat] = value


func _show(stat: String, text: String) -> void:
	(_values[stat] as Label).text = text


## "1:02:03", or "2:03" under an hour.
func _format_time(seconds: int) -> String:
	var hours := floori(seconds / 3600.0)
	var minutes := floori(seconds / 60.0) % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, seconds % 60]
	return "%d:%02d" % [minutes, seconds % 60]


func _format_percent(boost: float) -> String:
	return "+%s%%" % Upgrade.format_number(boost * 100.0)
