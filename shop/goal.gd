class_name Goal
extends Resource
## A milestone that unlocks a shop item or earns an achievement: break so many squares,
## clear so many cubes (of one kind, or any), earn so much money, make a run last so
## long... Progress comes from Game's stats and records.

## New kinds go at the end: resources store the number.
enum Stat {
	SQUARES_BROKEN, CUBES_CLEARED, MONEY_EARNED, RUNS_FINISHED, RUN_CLICKS, RUN_EARNED,
	LONGEST_CHAIN, BIGGEST_CLICK, ONE_CLICK_CLEARS, CUBES_MASTERED, LUCKY_CUBES, SHARDS_EARNED,
}

@export var stat := Stat.CUBES_CLEARED
@export var amount := 1
## For CUBES_CLEARED and ONE_CLICK_CLEARS: count only cubes of this type. Empty counts
## every cube.
@export var cube_type: CubeType


## How far along it is: the stat, or for the run goals the best run so far, this one
## included.
func get_value() -> int:
	match stat:
		Stat.SQUARES_BROKEN:
			return Game.get_stat(Game.STAT_SQUARES_BROKEN)
		Stat.MONEY_EARNED:
			return Game.get_stat(Game.STAT_MONEY_EARNED)
		Stat.RUNS_FINISHED:
			return Game.get_stat(Game.STAT_RUNS)
		Stat.RUN_CLICKS:
			return Game.get_best_run_value("clicks")
		Stat.RUN_EARNED:
			return Game.get_best_run_value("earned")
		Stat.LONGEST_CHAIN:
			return Game.get_stat(Game.STAT_LONGEST_CHAIN)
		Stat.BIGGEST_CLICK:
			return Game.get_stat(Game.STAT_BIGGEST_CLICK)
		Stat.ONE_CLICK_CLEARS:
			return Game.get_stat(Game.get_one_click_stat(cube_type))
		Stat.CUBES_MASTERED:
			return Game.get_mastered_count()
		Stat.LUCKY_CUBES:
			return Game.get_stat(Game.STAT_LUCKY_CAUGHT)
		Stat.SHARDS_EARNED:
			return Game.total_shards
	return Game.get_stat(Game.get_cleared_stat(cube_type))


func is_met() -> bool:
	return get_value() >= amount


## "Clear 3 Yellow Cubes", "Break 600 squares", "Make a run last 300 clicks".
func get_description() -> String:
	var count := Currency.format(amount)
	match stat:
		Stat.SQUARES_BROKEN:
			return "Break %s %s" % [count, _plural("square")]
		Stat.MONEY_EARNED:
			return "Earn %s in total" % count
		Stat.RUNS_FINISHED:
			return "Finish %s %s" % [count, _plural("run")]
		Stat.RUN_CLICKS:
			return "Make a run last %s %s" % [count, _plural("click")]
		Stat.RUN_EARNED:
			return "Earn %s in one run" % count
		Stat.LONGEST_CHAIN:
			return "Set off %s explosive or lightning %s with one click" % [count, _plural("square")]
		Stat.BIGGEST_CLICK:
			return "Break %s %s with one click" % [count, _plural("square")]
		Stat.ONE_CLICK_CLEARS:
			return "Clear %s %s with one click" % [count, _plural(cube_type.display_name if cube_type else "cube")]
		Stat.CUBES_MASTERED:
			return "Master %s %s (mastery %d)" % [count, _plural("cube"), Game.MASTERY_MAX_LEVEL]
		Stat.LUCKY_CUBES:
			return "Catch %s %s" % [count, _plural("Lucky Cube")]
		Stat.SHARDS_EARNED:
			return "Earn %s %s" % [count, _plural("Shard")]
	return "Clear %s %s" % [count, _plural(cube_type.display_name if cube_type else "cube")]


## "1/3": how far along it is, capped at the amount.
func get_progress_text() -> String:
	return "%s/%s" % [Currency.format(mini(get_value(), amount)), Currency.format(amount)]


func _plural(noun: String) -> String:
	return noun if amount == 1 else noun + "s"
