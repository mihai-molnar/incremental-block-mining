class_name AchievementToast
extends Toast
## "ACHIEVEMENT!" with the achievements just earned and what they add to earnings.
## Achievements earned close together share one.

const TITLE_COLOR := Color("73eff7")
## The chime, pitched down so it doesn't sound like an unlock.
const PITCH := 0.8

var _achievements: Array[Achievement] = []


func _ready() -> void:
	super()
	Game.achievements_earned.connect(_on_achievements_earned)


func _on_achievements_earned(achievements: Array[Achievement]) -> void:
	if not is_showing():
		_achievements.clear()
		_names.clear()
	for achievement in achievements:
		_achievements.append(achievement)
		_names.append(achievement.title)
	_pop(PITCH)


func _get_title() -> String:
	return "ACHIEVEMENT!"


func _get_title_color() -> Color:
	return TITLE_COLOR


func _get_hint() -> String:
	var bonus := 0.0
	for achievement in _achievements:
		bonus += achievement.bonus
	return "All earnings +%s%% for good [A]" % Upgrade.format_number(bonus * 100.0)
