class_name MasteryToast
extends Toast
## "MASTERY UP!" with the cube types whose mastery just reached a new level, and what
## their squares pay now. Shows above the unlock toast, since a cube's first clear often
## brings both; level-ups close together share one.

const TITLE_COLOR := Color("a7f070")
## The chime, pitched up so it doesn't sound like an unlock.
const PITCH := 1.25

var _cube_types: Array[CubeType] = []


func _ready() -> void:
	super()
	Game.mastery_leveled_up.connect(_on_mastery_leveled_up)


func _on_mastery_leveled_up(cube_type: CubeType, _level: int) -> void:
	if not is_showing():
		_cube_types.clear()
	if cube_type not in _cube_types:
		_cube_types.append(cube_type)
	_names.clear()
	for type in _cube_types:
		_names.append("%s Lv %d" % [type.display_name, Game.get_mastery_level(type)])
	_pop(PITCH)


func _get_title() -> String:
	return "MASTERY UP!"


func _get_title_color() -> Color:
	return TITLE_COLOR


func _get_hint() -> String:
	if _cube_types.size() != 1:
		return "Each level pays %d%% more on that cube" % roundi(Game.MASTERY_BONUS * 100.0)
	var level := Game.get_mastery_level(_cube_types[0])
	var hint := "Its squares pay %d%% more" % roundi(level * Game.MASTERY_BONUS * 100.0)
	return "Mastered! " + hint if level >= Game.MASTERY_MAX_LEVEL else hint
