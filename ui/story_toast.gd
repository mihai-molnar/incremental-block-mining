class_name StoryToast
extends Toast
## A line of the Fallen Star story, the first time each deep cube is bought: the cube's
## name over its line, wrapped to two lines. Stays up longer than the other toasts.

const TITLE_COLOR := Color("ef7d57")
const STORY_SHOW_TIME := 6.0
## The chime, pitched down: the story is quieter news than an unlock.
const PITCH := 0.7

var _title := ""
var _text := ""


func _ready() -> void:
	super()
	Game.story_reached.connect(_on_story_reached)


func _on_story_reached(cube_type: CubeType) -> void:
	_title = cube_type.display_name
	_text = cube_type.story_line
	_pop(PITCH)


func _get_show_time() -> float:
	return STORY_SHOW_TIME


func _draw() -> void:
	var title_baseline := roundf(TITLE_FONT.get_ascent(16))
	_draw_centered(TITLE_FONT, title_baseline, _title, 16, TITLE_COLOR)
	var lines := _wrap(_text)
	for i in mini(lines.size(), 2):
		_draw_centered(NAME_FONT, title_baseline + 13.0 + 11.0 * i, lines[i], 8, NAME_COLOR)


## The text split into lines that fit the toast's width, word by word.
func _wrap(text: String) -> Array[String]:
	var lines: Array[String] = []
	var line := ""
	for word in text.split(" "):
		var longer := word if line.is_empty() else line + " " + word
		if line.is_empty() or NAME_FONT.get_string_size(longer, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x <= size.x:
			line = longer
		else:
			lines.append(line)
			line = word
	if not line.is_empty():
		lines.append(line)
	return lines
