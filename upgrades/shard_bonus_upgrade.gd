class_name ShardBonusUpgrade
extends Upgrade
## Each tier makes every doubling of the Shards ever earned add more to earnings.

## Extra boost per doubling per tier (0.05 takes 25% per doubling to 30%, then 35%...).
@export_range(0.0, 0.5, 0.01) var bonus_per_tier := 0.05


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	if level == 0:
		return "Shards add %s per doubling instead of %s" % [_format_bonus(1), _format_bonus(0)]
	var now := "Tier %d: Shards add %s per doubling" % [level, _format_bonus(level)]
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %s" % [now, _format_bonus(level + 1)]


func _format_bonus(level: int) -> String:
	return format_number((Game.SHARD_BONUS + bonus_per_tier * level) * 100.0) + "%"


func create_icon() -> Control:
	return create_sprite_icon(&"shard")


func modify_shard_bonus(bonus: float, level: int) -> float:
	return bonus + bonus_per_tier * level
