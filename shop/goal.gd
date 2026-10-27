class_name Goal
extends Resource
## A milestone that unlocks a shop item: break so many squares, clear so many cubes (of
## one kind, or any), or earn so much money in total. Progress comes from Game's stats.

enum Stat { SQUARES_BROKEN, CUBES_CLEARED, MONEY_EARNED }

@export var stat := Stat.CUBES_CLEARED
@export var amount := 1
## For CUBES_CLEARED: count only cubes of this type. Empty counts every cube.
@export var cube_type: CubeType


func get_stat_key() -> StringName:
	match stat:
		Stat.SQUARES_BROKEN:
			return Game.STAT_SQUARES_BROKEN
		Stat.MONEY_EARNED:
			return Game.STAT_MONEY_EARNED
	return Game.get_cleared_stat(cube_type)


func is_met() -> bool:
	return Game.get_stat(get_stat_key()) >= amount


## "Clear 3 Yellow Cubes", "Break 600 squares", "Earn 2000 in total".
func get_description() -> String:
	match stat:
		Stat.SQUARES_BROKEN:
			return "Break %s square%s" % [Currency.format(amount), "" if amount == 1 else "s"]
		Stat.MONEY_EARNED:
			return "Earn %s in total" % Currency.format(amount)
	var what := cube_type.display_name if cube_type else "cube"
	return "Clear %s %s%s" % [Currency.format(amount), what, "" if amount == 1 else "s"]


## "1/3": how far along it is, capped at the amount.
func get_progress_text() -> String:
	var done := mini(Game.get_stat(get_stat_key()), amount)
	return "%s/%s" % [Currency.format(done), Currency.format(amount)]
