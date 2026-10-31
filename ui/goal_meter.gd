class_name GoalMeter
extends Control
## At the bottom of the field: the next goal, so there's always one in sight. That's the
## locked shop item closest to unlocking (Game.get_next_unlock), or once everything is
## unlocked, the achievement closest to earned. Shows the goal, a bar with its progress
## and what it gives, and pops when the goal changes.

const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
## Seconds between checks for progress. Goals move with clicks, drones, mastery and runs,
## so it looks every so often instead of listening for all of them.
const REFRESH := 0.25
const LINE_1 := 8.0
const BAR := Rect2i(0, 12, 0, 5)
const LINE_3 := 27.0
const GAP := 4
const TEXT_COLOR := Color("f4f4f4")
const MUTED_COLOR := Color("94b0c2")
const SHADOW_COLOR := Color("0f1020")
const TRACK_COLOR := Color("333c57")
## Each fill: its color, the highlight along its top row and the shade along its bottom.
const UNLOCK_COLORS: Array[Color] = [Color("ffcd75"), Color("f4f4f4"), Color("ef7d57")]
const ACHIEVEMENT_COLORS: Array[Color] = [Color("73eff7"), Color("f4f4f4"), Color("41a6f6")]

## The shop item or achievement shown, or null.
var _target: Resource
var _wait := 0.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update()


func _process(delta: float) -> void:
	_wait -= delta
	if _wait <= 0.0:
		_wait = REFRESH
		_update()


func _update() -> void:
	var target: Resource = Game.get_next_unlock()
	if target == null:
		target = Game.get_next_achievement()
	if target != _target and _target != null and target != null:
		_pop()
	_target = target
	queue_redraw()


func _pop() -> void:
	if _tween:
		_tween.kill()
	pivot_offset = size / 2.0
	scale = Vector2.ONE * 1.2
	_tween = create_tween()
	_tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var goal := _get_goal()
	if goal == null:
		return
	_draw_centered(LINE_1, goal.get_description(), TEXT_COLOR)
	var progress := goal.get_progress_text()
	var progress_width := _text_width(progress)
	var bar_width := mini(roundi(size.x) - progress_width - GAP, 96)
	var left := floori((size.x - bar_width - GAP - progress_width) / 2.0)
	var bar := Rect2i(left, BAR.position.y, bar_width, BAR.size.y)
	var ratio := clampf(float(goal.get_value()) / maxi(goal.amount, 1), 0.0, 1.0)
	_draw_bar(bar, ratio, UNLOCK_COLORS if _target is ShopItem else ACHIEVEMENT_COLORS)
	_draw_text(Vector2(bar.end.x + GAP, bar.position.y + BAR.size.y), progress, TEXT_COLOR)
	_draw_centered(LINE_3, _get_reward_text(), MUTED_COLOR)


func _get_goal() -> Goal:
	if _target is ShopItem:
		return (_target as ShopItem).unlock
	if _target is Achievement:
		return (_target as Achievement).goal
	return null


## "Unlocks Grey Cube", "Achievement: Rubble, +2%".
func _get_reward_text() -> String:
	if _target is ShopItem:
		return "Unlocks " + (_target as ShopItem).get_title()
	var achievement := _target as Achievement
	return "Achievement: %s, %s" % [achievement.title, achievement.get_bonus_text()]


func _draw_bar(bar: Rect2i, ratio: float, colors: Array[Color]) -> void:
	draw_rect(bar, SHADOW_COLOR)
	var inner := bar.grow(-1)
	draw_rect(inner, TRACK_COLOR)
	if ratio <= 0.0:
		return
	var fill := Rect2i(inner.position, Vector2i(maxi(roundi(inner.size.x * ratio), 1), inner.size.y))
	draw_rect(fill, colors[0])
	draw_rect(Rect2i(fill.position, Vector2i(fill.size.x, 1)), colors[1])
	draw_rect(Rect2i(fill.position.x, fill.end.y - 1, fill.size.x, 1), colors[2])


## A line centered across the meter, cut short with "..." if it doesn't fit.
func _draw_centered(baseline: float, text: String, color: Color) -> void:
	var fitted := _fit(text, floori(size.x))
	_draw_text(Vector2(floorf((size.x - _text_width(fitted)) / 2.0), baseline), fitted, color)


func _fit(text: String, width: int) -> String:
	if _text_width(text) <= width:
		return text
	var cut := text
	while not cut.is_empty() and _text_width(cut + "...") > width:
		cut = cut.left(-1)
	return cut.strip_edges() + "..."


func _text_width(text: String) -> int:
	return ceili(FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x)


## Text with a drop shadow, as on the rest of the HUD at this size (1 right, 1 down).
func _draw_text(at: Vector2, text: String, color: Color) -> void:
	draw_string(FONT, at + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, SHADOW_COLOR)
	draw_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, color)
