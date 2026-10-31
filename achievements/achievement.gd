class_name Achievement
extends Resource
## A milestone that, once its goal is met, adds `bonus` to all earnings for good. Game
## keeps track of which are earned; the achievements page lists them.

@export var title := "Achievement"
@export var goal: Goal
## Added to the payout multiplier once earned, next to the Shard boost (0.02 = +2%).
@export var bonus := 0.02
## PixelSprites sprite shown on its row. Goals about one cube type show that cube instead.
@export var icon: StringName = &"trophy"


func is_earned() -> bool:
	return Game.has_achievement(self)


## "+2%": what it adds to all earnings.
func get_bonus_text() -> String:
	return "+%s%%" % Upgrade.format_number(bonus * 100.0)


func create_icon() -> Control:
	if goal.cube_type:
		var cube_icon := CubeIcon.new()
		cube_icon.cube_type = goal.cube_type
		return cube_icon
	return Upgrade.create_sprite_icon(icon)
