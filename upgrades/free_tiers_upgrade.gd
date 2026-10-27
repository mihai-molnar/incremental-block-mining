class_name FreeTiersUpgrade
extends Upgrade
## A perk that starts every run with free tiers of a regular upgrade, one per tier of its
## own. They count toward that upgrade's tier and effect, not its price or cap.

@export var target: Upgrade


func get_description() -> String:
	if not description.is_empty():
		return description
	var level := get_level()
	var target_title := target.get_title()
	if level == 0:
		return "Runs start with a free %s tier" % target_title
	var now := "Tier %d: runs start with %d free %s tiers" % [level, level, target_title]
	if level == 1:
		now = "Tier 1: runs start with a free %s tier" % target_title
	if is_maxed():
		return now + " (max)"
	return "%s\nNext tier: %d free" % [now, level + 1]


func create_icon() -> Control:
	return target.create_icon()


func get_free_tiers_target() -> Upgrade:
	return target
