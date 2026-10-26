class_name ShopItemRow
extends PanelContainer
## One entry in the shop: icon, name, description and a buy button showing the price.
## Items the auto-buyer can buy get an Auto toggle under the buy button.

var item: ShopItem

var _title_label: Label
var _description_label: Label
var _buy_button: Button
var _auto_button: Button
var _reason_label: Label
var _punch_tween: Tween


func _ready() -> void:
	theme_type_variation = &"ShopRow"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	row.add_child(item.create_icon())

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 3)
	row.add_child(text_box)
	_title_label = Label.new()
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(_title_label)
	_description_label = Label.new()
	_description_label.theme_type_variation = &"MutedLabel"
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(_description_label)
	_reason_label = Label.new()
	_reason_label.theme_type_variation = &"WarningLabel"
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(_reason_label)

	var buttons := VBoxContainer.new()
	buttons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	buttons.add_theme_constant_override("separation", 3)
	row.add_child(buttons)
	_buy_button = Button.new()
	_buy_button.theme_type_variation = &"BuyButton"
	_buy_button.focus_mode = Control.FOCUS_NONE
	_buy_button.pressed.connect(_on_buy_pressed)
	buttons.add_child(_buy_button)
	_auto_button = Button.new()
	_auto_button.text = "Auto"
	_auto_button.toggle_mode = true
	_auto_button.focus_mode = Control.FOCUS_NONE
	_auto_button.toggled.connect(_on_auto_toggled)
	buttons.add_child(_auto_button)

	Game.money_changed.connect(_on_money_changed)
	Game.field_value_changed.connect(_on_field_value_changed)
	Game.upgrade_purchased.connect(_on_upgrade_purchased)
	Game.auto_buy_changed.connect(_on_auto_buy_changed)
	_refresh()


func _refresh() -> void:
	visible = item.is_available()
	_title_label.text = item.get_title()
	_description_label.text = item.get_description()
	if item.is_owned():
		_buy_button.text = item.get_owned_label()
		_buy_button.icon = null
	else:
		_buy_button.text = Currency.format(item.get_price())
		_buy_button.icon = PixelSprites.get_texture(&"coin_small")
	_buy_button.disabled = not item.can_purchase()
	_reason_label.text = item.get_block_reason()
	_reason_label.visible = not _reason_label.text.is_empty()
	_auto_button.visible = item.can_auto_buy()
	_auto_button.set_pressed_no_signal(item.is_auto_buying())


func _on_money_changed(_money: int, _delta: int) -> void:
	_refresh()


func _on_field_value_changed(_value: int) -> void:
	_refresh()


func _on_upgrade_purchased(_upgrade: Upgrade) -> void:
	_refresh()


func _on_auto_buy_changed(_cube_type: CubeType) -> void:
	_refresh()


func _on_auto_toggled(on: bool) -> void:
	Sfx.play(&"click")
	item.set_auto_buying(on)
	_refresh()


func _on_buy_pressed() -> void:
	if item.purchase():
		Sfx.play(&"buy", 0.02)
		_punch()
	_refresh()


func _punch() -> void:
	if _punch_tween:
		_punch_tween.kill()
	_buy_button.pivot_offset = _buy_button.size / 2.0
	_buy_button.scale = Vector2.ONE * 1.25
	_punch_tween = create_tween()
	_punch_tween.tween_property(_buy_button, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
