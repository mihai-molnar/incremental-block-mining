class_name ShardBonusUpgrade
extends Upgrade
## Each tier makes every Shard ever earned add more to earnings.

## Extra boost per Shard per tier (0.01 takes 5% per Shard to 6%, then 7%...).
@export_range(0.0, 0.1, 0.005) var bonus_per_tier := 0.01


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Each Shard adds %s to earnings instead of %s" % [_format_bonus(1), _format_bonus(0)]
	var now := "Tier %d: each Shard adds %s" % [level, _format_bonus(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, _format_bonus(level + 1)]


func _format_bonus(level: int) -> String:
	return "%d%%" % roundi((Game.SHARD_BONUS + bonus_per_tier * level) * 100.0)


func create_icon() -> Control:
	return create_sprite_icon(&"shard")


func modify_shard_bonus(bonus: float, level: int) -> float:
	return bonus + bonus_per_tier * level
