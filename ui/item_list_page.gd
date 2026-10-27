class_name ItemListPage
extends SidebarPage
## Sidebar page that lists ShopItems (cubes, upgrades...) with buy buttons, cheapest first.
## Items still locked behind a goal stay hidden, except the cheapest one, shown as a
## teaser with its goal. Rows re-sort only when the page is shown, so they don't move
## under the cursor while buying.

@export var items: Array[ShopItem] = []
## Badge this page's tab when an item (or its next tier) becomes buyable and you
## haven't looked at the page since.
@export var notify_when_affordable := false

var _rows: Array[ShopItemRow] = []
## Item + price combinations the player has already seen as buyable.
var _seen := {}
## Items unlocked since the page was last on screen.
var _new_items: Array[ShopItem] = []


func _ready() -> void:
	for item in items:
		item.on_listed()
		var row := ShopItemRow.new()
		row.item = item
		add_child(row)
		_rows.append(row)
	Game.items_unlocked.connect(_on_items_unlocked)
	Game.upgrade_purchased.connect(func(_upgrade: Upgrade) -> void: _update_teaser())
	on_shown()


func on_shown() -> void:
	_sort_rows()
	_update_teaser()


func has_news() -> bool:
	if not _new_items.is_empty():
		return true
	if not notify_when_affordable:
		return false
	for item in items:
		if _is_buyable(item) and not _seen.has(_seen_key(item)):
			return true
	return false


func mark_seen() -> void:
	_new_items.clear()
	for item in items:
		if _is_buyable(item):
			_seen[_seen_key(item)] = true


## Cheapest first by the price of the next tier; owned and maxed items sink to the bottom.
func _sort_rows() -> void:
	var sorted := _rows.duplicate()
	sorted.sort_custom(func(a: ShopItemRow, b: ShopItemRow) -> bool:
		if a.item.is_owned() != b.item.is_owned():
			return b.item.is_owned()
		return a.item.get_price() < b.item.get_price())
	for i in sorted.size():
		move_child(sorted[i], i)


## Shows the cheapest locked item whose other requirements are met as a teaser.
func _update_teaser() -> void:
	var teaser: ShopItemRow = null
	for row in _rows:
		var item := row.item
		if item.is_available() or item.is_unlocked() or not item.meets_requirements():
			continue
		if teaser == null or item.get_price() < teaser.item.get_price():
			teaser = row
	for row in _rows:
		row.set_teaser(row == teaser)


func _on_items_unlocked(unlocked: Array[ShopItem]) -> void:
	for item in unlocked:
		if item in items:
			_new_items.append(item)
	_update_teaser()


func _is_buyable(item: ShopItem) -> bool:
	return item.is_available() and item.can_purchase()


## A new tier has a new price, so it counts as news again.
func _seen_key(item: ShopItem) -> String:
	return "%d:%d" % [item.get_instance_id(), item.get_price()]
