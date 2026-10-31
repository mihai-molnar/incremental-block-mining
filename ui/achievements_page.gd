class_name AchievementsPage
extends SidebarPage
## Sidebar page listing every achievement in the order given, earned or not, under a line
## with how many are earned and what they add to all earnings. Its tab is badged while
## achievements earned since it was last on screen haven't been seen.

@export var achievements: Array[Achievement] = []

var _summary: Label
var _rows: Array[AchievementRow] = []


func _ready() -> void:
	_summary = Label.new()
	_summary.theme_type_variation = &"MutedLabel"
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_summary)
	for achievement in achievements:
		Game.register_achievement(achievement)
		var row := AchievementRow.new()
		row.achievement = achievement
		add_child(row)
		_rows.append(row)
	# Anything that moves a goal along. Rows only refresh while they're on screen.
	Game.stats_changed.connect(_refresh_if_visible)
	Game.mastery_changed.connect(func(_cube_type: CubeType) -> void: _refresh_if_visible())
	Game.pickaxe_changed.connect(func(_hp: int) -> void: _refresh_if_visible())
	Game.shards_changed.connect(func(_shards: int) -> void: _refresh_if_visible())
	Game.achievements_earned.connect(func(_earned: Array[Achievement]) -> void: _refresh_if_visible())
	_refresh()


func on_shown() -> void:
	_refresh()


func has_news() -> bool:
	return Game.has_unseen_achievements()


func mark_seen() -> void:
	Game.mark_achievements_seen()


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		_refresh()


func _refresh() -> void:
	_summary.text = "%d of %d earned. Each one adds to all earnings for good: +%s%% so far." % [
		Game.get_achievement_count(), achievements.size(),
		Upgrade.format_number(Game.get_achievement_bonus() * 100.0)]
	for row in _rows:
		row.refresh()
