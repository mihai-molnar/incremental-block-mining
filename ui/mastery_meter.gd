class_name MasteryMeter
extends Control
## A cube's mastery on its shop row: the level, a bar filling toward the next one, and
## what the level adds to its squares' pay. Mastery carries over from run to run.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
## Height of the bar, outline included, and of one line of 8px text. The line drops TOP
## below the description so it keeps the description's line spacing.
const BAR_HEIGHT := 5
const LINE_HEIGHT := 7
const TOP := 3
const GAP := 4
const OUTLINE_COLOR := Color("0f1020")
const TRACK_COLOR := Color("333c57")
const LABEL_COLOR := Color("94b0c2")
const BONUS_COLOR := Color("ffcd75")
## Each fill: its color, the highlight along its top row and the shade along its bottom.
const FILL_COLORS: Array[Color] = [Color("ffcd75"), Color("f4f4f4"), Color("ef7d57")]
const MAXED_COLORS: Array[Color] = [Color("38b764"), Color("a7f070"), Color("257179")]

var cube_type: CubeType


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, TOP + LINE_HEIGHT)
	Game.mastery_changed.connect(_on_mastery_changed)


func _on_mastery_changed(changed: CubeType) -> void:
	if changed == cube_type:
		queue_redraw()


func _draw() -> void:
	var level := Game.get_mastery_level(cube_type)
	var maxed := level >= Game.MASTERY_MAX_LEVEL
	var label := "Mastered" if maxed else "Mastery %d" % level
	var bonus := _format_bonus(level)
	# The bar's ends stay put whatever the level, so bars line up from row to row.
	var left := _text_width("Mastery %d" % Game.MASTERY_MAX_LEVEL) + GAP
	var right := _text_width(_format_bonus(Game.MASTERY_MAX_LEVEL)) + GAP
	var baseline := float(TOP + LINE_HEIGHT - 1)
	draw_string(FONT, Vector2(0, baseline), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, LABEL_COLOR)
	draw_string(FONT, Vector2(size.x - _text_width(bonus), baseline), bonus, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		BONUS_COLOR if level > 0 else LABEL_COLOR)
	var bar := Rect2i(left, TOP + 1, maxi(roundi(size.x) - left - right, 0), BAR_HEIGHT)
	if bar.size.x > 2:
		_draw_bar(bar, Game.get_mastery_progress(cube_type), MAXED_COLORS if maxed else FILL_COLORS)


## "+15%": what `level` adds to the cube's squares' pay.
func _format_bonus(level: int) -> String:
	return "+%d%%" % roundi(level * Game.MASTERY_BONUS * 100.0)


func _text_width(text: String) -> int:
	return ceili(FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)


func _draw_bar(bar: Rect2i, ratio: float, colors: Array[Color]) -> void:
	draw_rect(bar, OUTLINE_COLOR)
	var inner := bar.grow(-1)
	draw_rect(inner, TRACK_COLOR)
	if ratio <= 0.0:
		return
	var fill := Rect2i(inner.position, Vector2i(maxi(roundi(inner.size.x * minf(ratio, 1.0)), 1), inner.size.y))
	draw_rect(fill, colors[0])
	draw_rect(Rect2i(fill.position, Vector2i(fill.size.x, 1)), colors[1])
	draw_rect(Rect2i(fill.position.x, fill.end.y - 1, fill.size.x, 1), colors[2])
