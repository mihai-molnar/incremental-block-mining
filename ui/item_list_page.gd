class_name ItemListPage
extends SidebarPage
## Sidebar page that lists ShopItems (cubes, upgrades...) with buy buttons.

@export var items: Array[ShopItem] = []
## Badge this page's tab when an item (or its next tier) becomes buyable and you
## haven't looked at the page since.
@export var notify_when_affordable := false

## Item + price combinations the player has already seen as buyable.
var _seen := {}


func _ready() -> void:
	for item in items:
		item.on_listed()
		var row := ShopItemRow.new()
		row.item = item
		add_child(row)


func has_news() -> bool:
	if not notify_when_affordable:
		return false
	for item in items:
		if _is_buyable(item) and not _seen.has(_seen_key(item)):
			return true
	return false


func mark_seen() -> void:
	for item in items:
		if _is_buyable(item):
			_seen[_seen_key(item)] = true


func _is_buyable(item: ShopItem) -> bool:
	return item.is_available() and item.can_purchase()


## A new tier has a new price, so it counts as news again.
func _seen_key(item: ShopItem) -> String:
	return "%d:%d" % [item.get_instance_id(), item.get_price()]
