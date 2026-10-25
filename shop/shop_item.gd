class_name ShopItem
extends Resource
## Base class for anything the shop sells. Subclasses define what it is, what it costs
## and what buying it does (cubes now; upgrades and other things later).


func get_title() -> String:
	return ""


func get_description() -> String:
	return ""


func get_price() -> int:
	return 0


## Whether the item is currently listed at all (e.g. false until something unlocks it).
func is_available() -> bool:
	return true


## Whether a one-time item has already been bought. It stays listed, marked as owned.
func is_owned() -> bool:
	return false


## Button text once a one-time item is bought.
func get_owned_label() -> String:
	return "Owned"


func can_purchase() -> bool:
	return is_available() and Game.can_afford(get_price())


## Why an affordable item can't be bought right now, shown under it in the shop.
## Empty when nothing besides the price is in the way.
func get_block_reason() -> String:
	return ""


## Called once when a shop page lists this item.
func on_listed() -> void:
	pass


## Spends the money and applies the item. Returns true if the purchase went through.
func purchase() -> bool:
	if not can_purchase() or not Game.try_spend(get_price()):
		return false
	_apply()
	return true


## Builds the small preview shown next to the item in the shop.
func create_icon() -> Control:
	return Control.new()


func _apply() -> void:
	pass
