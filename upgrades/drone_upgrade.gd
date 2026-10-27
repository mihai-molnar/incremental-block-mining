class_name DroneUpgrade
extends Upgrade
## Launches a mining drone, which hits squares on its own until its HP
## (Game.get_drone_hp) runs out, then breaks. It's bought again and again: its level counts
## the drones bought this run, so each costs more than the last. Up to Game.MAX_DRONES fly
## at once.


func get_description() -> String:
	if not description.is_empty():
		return description
	return "A drone that mines %d hits for you, then breaks. Up to %d at once" % [
		Game.get_drone_hp(), Game.MAX_DRONES]


func create_icon() -> Control:
	return create_sprite_icon(&"drone")


func can_purchase() -> bool:
	return Game.drones_out < Game.MAX_DRONES and super()


func get_block_reason() -> String:
	if Game.drones_out >= Game.MAX_DRONES:
		return "%d drones are out already" % Game.MAX_DRONES
	return super()


func _apply() -> void:
	super()
	Game.launch_drone()
