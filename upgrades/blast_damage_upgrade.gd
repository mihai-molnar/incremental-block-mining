class_name BlastDamageUpgrade
extends Upgrade
## A perk: each tier makes every blast (explosions and lightning) take more clicks off the
## squares it reaches, so deep cubes fall to chain reactions later in the game.

@export var damage_per_tier := 1


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Blasts take %s off each square" % _more_clicks(damage_per_tier)
	var now := "Tier %d: blasts take %s off each square" % [level, _more_clicks(damage_per_tier * level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %d more" % [now, damage_per_tier * (level + 1)]


static func _more_clicks(count: int) -> String:
	return "%d more click%s" % [count, "" if count == 1 else "s"]


func create_icon() -> Control:
	return create_sprite_icon(&"blast")


func modify_blast_damage(damage: int, level: int) -> int:
	return damage + damage_per_tier * level
