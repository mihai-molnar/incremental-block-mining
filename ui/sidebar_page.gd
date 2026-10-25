class_name SidebarPage
extends VBoxContainer
## One page of the Sidebar. Its tab button and toggle action open the sidebar on it.

@export var title := ""
@export var toggle_action: StringName
@export var tab_button: Button


## Whether the page has something new to show; the sidebar badges its tab when true.
func has_news() -> bool:
	return false


## Called while the page is on screen, so what's on it no longer counts as news.
func mark_seen() -> void:
	pass
