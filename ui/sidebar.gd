class_name Sidebar
extends Control
## Panel that slides in from the right edge and shows one SidebarPage at a time.
## Each page's tab button (sticking out of the panel's left edge) and toggle action
## open the sidebar on that page, switch to it, or close the sidebar if it's showing.

@export var panel_width := 240.0
@export var slide_duration := 0.25

var is_open := false
var current_page: SidebarPage

var _pages: Array[SidebarPage] = []
## Notification dot on each page's tab button (SidebarPage -> TextureRect).
var _badges := {}
var _slide := 0.0
var _tween: Tween

@onready var _title: Label = %Title
@onready var _close_button: Button = %CloseButton
@onready var _page_container: Control = %Pages
@onready var _page_scroll: ScrollContainer = %PageScroll


func _ready() -> void:
	for child in _page_container.get_children():
		var page := child as SidebarPage
		if page:
			_pages.append(page)
			page.tab_button.pressed.connect(show_page.bind(page))
			_badges[page] = _create_badge(page.tab_button)
	_close_button.pressed.connect(close)
	Game.money_changed.connect(func(_money: int, _delta: int) -> void: _update_badges())
	Game.field_value_changed.connect(func(_value: int) -> void: _update_badges())
	Game.upgrade_purchased.connect(func(_upgrade: Upgrade) -> void: _update_badges())
	Game.items_unlocked.connect(func(_items: Array[ShopItem]) -> void: _update_badges())
	if not _pages.is_empty():
		_set_page(_pages[0])
	_apply_slide(0.0)
	_update_badges.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	for page in _pages:
		if event.is_action_pressed(page.toggle_action):
			show_page(page)
			get_viewport().set_input_as_handled()
			return


func show_page(page: SidebarPage) -> void:
	if is_open and page == current_page:
		close()
		return
	_set_page(page)
	if is_open:
		Sfx.play(&"click")
	else:
		_slide_to(true)


func close() -> void:
	if is_open:
		_slide_to(false)


func _set_page(page: SidebarPage) -> void:
	if page != current_page:
		_page_scroll.scroll_vertical = 0
	current_page = page
	page.on_shown()
	_title.text = page.title
	for p in _pages:
		p.visible = p == page
	_update_tabs()
	_update_badges()


## Marks the page on screen as seen, then shows a dot on every tab with news.
func _update_badges() -> void:
	for page in _pages:
		if is_open and page == current_page:
			page.mark_seen()
		var badge: TextureRect = _badges[page]
		var wanted := page.has_news()
		if wanted and not badge.visible:
			badge.scale = Vector2.ZERO
			badge.create_tween().tween_property(badge, "scale", Vector2.ONE, 0.3) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		badge.visible = wanted


func _create_badge(tab: Button) -> TextureRect:
	var badge := TextureRect.new()
	badge.texture = PixelSprites.get_texture(&"badge")
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 1.0
	badge.anchor_right = 1.0
	badge.offset_left = -5.0
	badge.offset_top = -3.0
	badge.offset_right = 3.0
	badge.offset_bottom = 5.0
	badge.pivot_offset = Vector2(4, 4)
	badge.visible = false
	tab.add_child(badge)
	return badge


func _update_tabs() -> void:
	for p in _pages:
		p.tab_button.set_pressed_no_signal(is_open and p == current_page)


func _slide_to(opening: bool) -> void:
	is_open = opening
	_update_tabs()
	_update_badges()
	Sfx.play(&"click")
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_apply_slide, _slide, 1.0 if opening else 0.0, slide_duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _apply_slide(amount: float) -> void:
	_slide = amount
	offset_left = roundf(-panel_width * amount)
	offset_right = offset_left + panel_width
