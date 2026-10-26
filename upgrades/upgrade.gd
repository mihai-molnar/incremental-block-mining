class_name Upgrade
extends ShopItem
## A purchase that changes the rules, optionally over several levels (tiers). Once owned,
## Game asks it through the hook methods below; subclasses override the hooks they need.

@export var title := "Upgrade"
## Leave empty to let the subclass describe itself.
@export_multiline var description := ""
## Price of level 1. Level N costs price × N (100, 200, 300...).
@export var price := 0
## How many times it can be bought. 0 means no limit.
@export_range(0, 99) var max_level := 1
## Stays out of the shop until this upgrade is owned.
@export var requires: Upgrade


func get_level() -> int:
	return Game.get_upgrade_level(self)


func is_maxed() -> bool:
	return max_level > 0 and get_level() >= max_level


## Whether it can be bought more than once.
func is_tiered() -> bool:
	return max_level != 1


func get_title() -> String:
	return title


func get_description() -> String:
	return description


## Price of the next level (or of the last one, once maxed).
func get_price() -> int:
	return price * (get_level() if is_maxed() else get_level() + 1)


func is_available() -> bool:
	return requires == null or Game.has_upgrade(requires)


func is_owned() -> bool:
	return is_maxed()


func get_owned_label() -> String:
	return "Maxed" if is_tiered() else "Owned"


func can_purchase() -> bool:
	return not is_maxed() and not Game.would_soft_lock(get_price()) and super()


## Upgrades don't make money themselves, so they can't eat the money needed for a cube.
func get_block_reason() -> String:
	if is_maxed() or not Game.can_afford(get_price()) or not Game.would_soft_lock(get_price()):
		return ""
	return "Keep %s for a cube" % Currency.format(Game.get_cheapest_cube_price())


func _apply() -> void:
	Game.add_upgrade_level(self)


# --- Hooks (level is this upgrade's owned level, at least 1) ----------------------

## Called for every square of a newly landed cube. Returns the type the square should be.
func modify_square_type(_cube_type: CubeType, current: SquareType, _level: int) -> SquareType:
	return current


## Clicks needed to break a square. Game clamps the final result to at least 1.
func modify_square_hp(_square_type: SquareType, hp: int, _level: int) -> int:
	return hp


## Side, in squares, of the area one click hits.
func modify_pickaxe_size(size: int, _level: int) -> int:
	return size


## How many squares out an explosive square's blast reaches.
func modify_blast_radius(radius: int, _level: int) -> int:
	return radius
