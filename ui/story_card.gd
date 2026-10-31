class_name StoryCard
extends CanvasLayer
## The opening of the Fallen Star story, covering a new game before play starts: why
## you're digging, and that the Star Core waits at the bottom of the shop. One click to
## begin. Shown once (Game.opening_seen), and again after Reset progress.

const BACKGROUND_COLOR := Color("1a1c2c")
const OPENING := "Long ago, a star fell here and sank beneath every layer of stone. It's still down there, glowing. Buy cubes, break them and buy bigger ones to dig deeper. When your pickaxe breaks, the tunnel caves in and you start a new dig, a little stronger. The Star Core waits at the bottom of the shop."


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if Game.opening_seen:
		return
	_build()
	visible = true
	get_tree().paused = true


func _build() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 340
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	var title := Label.new()
	title.theme_type_variation = &"TitleLabel"
	title.text = "The Fallen Star"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var text := Label.new()
	text.text = OPENING
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(text)
	var begin := Button.new()
	begin.text = "Begin"
	begin.focus_mode = Control.FOCUS_NONE
	begin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	begin.pressed.connect(_on_begin_pressed)
	box.add_child(begin)


func _on_begin_pressed() -> void:
	Sfx.play(&"click")
	Game.mark_opening_seen()
	visible = false
	get_tree().paused = false
