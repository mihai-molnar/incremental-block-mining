class_name UnlockToast
extends Toast
## "UNLOCKED!" with the names of the shop items whose goals were just met.
## Pops in at the bottom of the field and fades after a few seconds; unlocks close
## together share one.

const TITLE_COLOR := Color("ffcd75")

## Which sidebar tabs the unlocked items are on.
var _in_shop := false
var _in_upgrades := false


func _ready() -> void:
	super()
	Game.items_unlocked.connect(_on_items_unlocked)


func _on_items_unlocked(items: Array[ShopItem]) -> void:
	if not is_showing():
		_names.clear()
		_in_shop = false
		_in_upgrades = false
	for item in items:
		_names.append(item.get_title())
		if item is Upgrade:
			_in_upgrades = true
		else:
			_in_shop = true
	_pop()


func _get_title() -> String:
	return "UNLOCKED!"


func _get_title_color() -> Color:
	return TITLE_COLOR


func _get_hint() -> String:
	var tabs: Array[String] = []
	if _in_shop:
		tabs.append("the Shop [S]")
	if _in_upgrades:
		tabs.append("Upgrades [U]")
	return "in " + " and ".join(tabs)
