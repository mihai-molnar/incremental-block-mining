class_name StartingMoneyUpgrade
extends Upgrade
## Each tier makes every new run, after the mine collapses, start with more money.

## Money tier 1 starts runs with; each tier after multiplies it by `step`.
@export var amount := 500
@export var step := 10


func get_amount(level: int) -> int:
	return amount * roundi(pow(step, level - 1)) if level > 0 else Game.STARTING_MONEY


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "New runs start with %s money" % Currency.format(get_amount(1))
	var now := "Tier %d: runs start with %s" % [level, Currency.format(get_amount(level))]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, Currency.format(get_amount(level + 1))]


func create_icon() -> Control:
	return create_sprite_icon(&"coin_big")


func modify_starting_money(money: int, level: int) -> int:
	return maxi(money, get_amount(level))
