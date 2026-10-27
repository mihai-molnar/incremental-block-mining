class_name RepairUpgrade
extends Upgrade
## Puts HP back on the pickaxe, so the run goes on longer. It's bought again and again: its
## level counts the repairs this run, so each costs more than the last.

## HP one repair puts back.
@export var amount := 25


func get_description() -> String:
	if not description.is_empty():
		return description
	return "Repairs %d of the pickaxe's HP" % amount


func create_icon() -> Control:
	return create_sprite_icon(&"whetstone")


func can_purchase() -> bool:
	return Game.pickaxe_hp < Game.get_max_pickaxe_hp() and super()


func get_block_reason() -> String:
	if Game.pickaxe_hp >= Game.get_max_pickaxe_hp():
		return "The pickaxe is at full HP"
	return super()


func _apply() -> void:
	super()
	Game.repair_pickaxe(amount)
