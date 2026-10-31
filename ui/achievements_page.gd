class_name AchievementsPage
extends SidebarPage
## Sidebar page listing every achievement under a line with how many are earned and what
## they add to all earnings: the earned ones first, newest on top, then the rest in the
## order given. Its tab is badged, and their rows marked NEW, while achievements earned
## since it was last on screen haven't been seen. Rows re-sort only when the page is shown.

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
	Game.achievements_earned.connect(_on_achievements_earned)
	_refresh()


func on_shown() -> void:
	for row in _rows:
		row.is_new = Game.is_achievement_unseen(row.achievement)
	_sort_rows()
	_refresh()


func has_news() -> bool:
	return Game.has_unseen_achievements()


func mark_seen() -> void:
	Game.mark_achievements_seen()


## Earned while the page is on screen: marked NEW where they are, sorted next time.
func _on_achievements_earned(earned: Array[Achievement]) -> void:
	if not is_visible_in_tree():
		return
	for row in _rows:
		if row.achievement in earned:
			row.is_new = true
	_refresh()


func _sort_rows() -> void:
	var earned := Game.get_earned_achievements()
	var sorted := _rows.duplicate()
	sorted.sort_custom(func(a: AchievementRow, b: AchievementRow) -> bool:
		var a_at := earned.find(a.achievement)
		var b_at := earned.find(b.achievement)
		if (a_at >= 0) != (b_at >= 0):
			return a_at >= 0
		if a_at >= 0:
			return a_at > b_at
		return _rows.find(a) < _rows.find(b))
	var first := _summary.get_index() + 1
	for i in sorted.size():
		move_child(sorted[i], first + i)


func _refresh_if_visible() -> void:
	if is_visible_in_tree():
		_refresh()


func _refresh() -> void:
	_summary.text = "%d of %d earned. Each one adds to all earnings for good: +%s%% so far." % [
		Game.get_achievement_count(), achievements.size(),
		Upgrade.format_number(Game.get_achievement_bonus() * 100.0)]
	for row in _rows:
		row.refresh()
