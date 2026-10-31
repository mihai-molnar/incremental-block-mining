class_name TierCapUpgrade
extends Upgrade
## A perk: each tier lets a regular upgrade be bought `tiers_per_level` more times in
## every run (Tempered Steel: Sharp Pickaxe past 20).

@export var target: Upgrade
@export var tiers_per_level := 10


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	var target_title := target.get_title()
	if level == 0:
		return "%s goes up to %d tiers instead of %d" % [target_title, _get_cap(1), target.max_level]
	var now := "Tier %d: %s goes up to %d tiers" % [level, target_title, _get_cap(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: up to %d" % [now, _get_cap(level + 1)]


func _get_cap(level: int) -> int:
	return target.max_level + tiers_per_level * level


func create_icon() -> Control:
	return create_sprite_icon(&"anvil")


func modify_max_level(upgrade: Upgrade, max_tiers: int, level: int) -> int:
	return max_tiers + tiers_per_level * level if upgrade == target else max_tiers
