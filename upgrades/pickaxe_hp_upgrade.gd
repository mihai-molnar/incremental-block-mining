class_name PickaxeHpUpgrade
extends Upgrade
## Each tier gives the pickaxe more HP, so every run lasts longer.

@export var hp_per_tier := 25


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "The pickaxe gets %d more HP" % hp_per_tier
	var now := "Tier %d: +%d pickaxe HP" % [level, hp_per_tier * level]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: +%d" % [now, hp_per_tier * (level + 1)]


func create_icon() -> Control:
	return create_sprite_icon(&"pickaxe")


func modify_max_pickaxe_hp(hp: int, level: int) -> int:
	return hp + hp_per_tier * level
