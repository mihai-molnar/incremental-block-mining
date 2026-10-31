class_name AchievementRow
extends PanelContainer
## One achievement on the achievements page: icon, title, goal and what it adds to all
## earnings. Until it's earned, the icon is dimmed and the goal shows its progress.

const EARNED_COLOR := Color("ffcd75")

var achievement: Achievement

var _icon: Control
var _title_label: Label
var _description_label: Label
var _bonus_label: Label


func _ready() -> void:
	theme_type_variation = &"ShopRow"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	_icon = achievement.create_icon()
	row.add_child(_icon)

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

	_bonus_label = Label.new()
	_bonus_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_bonus_label)
	refresh()


func refresh() -> void:
	var earned := achievement.is_earned()
	_icon.modulate = Color.WHITE if earned else ShopItemRow.LOCKED_TINT
	_title_label.text = achievement.title
	var goal := achievement.goal
	_description_label.text = goal.get_description() if earned else "%s (%s)" % [goal.get_description(), goal.get_progress_text()]
	_bonus_label.text = achievement.get_bonus_text()
	_bonus_label.theme_type_variation = &"" if earned else &"MutedLabel"
	if earned:
		_title_label.add_theme_color_override("font_color", EARNED_COLOR)
		_bonus_label.add_theme_color_override("font_color", EARNED_COLOR)
	else:
		_title_label.remove_theme_color_override("font_color")
		_bonus_label.remove_theme_color_override("font_color")
