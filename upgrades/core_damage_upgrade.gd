class_name CoreDamageUpgrade
extends Upgrade
## A perk: each tier makes the player's hits on the Star Core take more clicks off its
## squares. Other cubes aren't touched, so the rest of the economy stays as it was tuned.

@export var damage_per_tier := 1


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Your hits take %d clicks off Star Core squares instead of 1" % _get_damage(1)
	var now := "Tier %d: your hits take %d clicks off Star Core squares" % [level, _get_damage(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %d" % [now, _get_damage(level + 1)]


## Once the star is free there's no Star Core left to hit, so no more tiers are sold.
func can_purchase() -> bool:
	return not Game.star_free and super()


func get_block_reason() -> String:
	return "The star is free" if Game.star_free and is_available() else super()


func _get_damage(level: int) -> int:
	return 1 + damage_per_tier * level


func create_icon() -> Control:
	return create_sprite_icon(&"star")


func modify_hit_damage(cube_type: CubeType, damage: int, level: int) -> int:
	return damage + damage_per_tier * level if cube_type.is_goal else damage
