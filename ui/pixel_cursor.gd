class_name PixelCursor
extends Node2D
## Software cursor drawn at the game's pixel resolution, so it matches the art.
## Shows a pickaxe in break mode, a hand in move mode and an arrow over UI. With a
## bigger pickaxe, corner brackets around the pickaxe mark the area a click hits.

## Point of each sprite that lines up with the mouse position.
const HOTSPOTS := {
	&"pickaxe": Vector2(1, 5),
	&"hand_open": Vector2(8, 8),
	&"hand_closed": Vector2(8, 9),
	&"pointer": Vector2(0, 0),
}
## Pivot the pickaxe swings around (its grip).
const PICKAXE_GRIP := Vector2(1, 12)
const REACH_BRACKET := 4
const REACH_COLOR := Color(1, 1, 1, 0.55)

@export var work_area: WorkArea

var _current := &""
var _pivot: Node2D
var _sprite: Sprite2D
var _swing_tween: Tween


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_pivot = Node2D.new()
	add_child(_pivot)
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_pivot.add_child(_sprite)
	work_area.tool_used.connect(_on_tool_used)
	Game.upgrade_purchased.connect(func(_upgrade: Upgrade) -> void: queue_redraw())


func _process(_delta: float) -> void:
	position = get_viewport().get_mouse_position().floor()
	_set_shape(_pick_shape())


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_MOUSE_EXIT:
			visible = false
		NOTIFICATION_WM_MOUSE_ENTER:
			visible = true


func _pick_shape() -> StringName:
	if work_area.is_dragging():
		return &"hand_closed"
	if get_viewport().gui_get_hovered_control() != null:
		return &"pointer"
	if work_area.mode == WorkArea.Mode.MOVE:
		return &"hand_open"
	return &"pickaxe"


func _set_shape(shape: StringName) -> void:
	if shape == _current:
		return
	_current = shape
	_sprite.texture = PixelSprites.get_texture(shape)
	var hotspot: Vector2 = HOTSPOTS[shape]
	if shape == &"pickaxe":
		_pivot.position = PICKAXE_GRIP - hotspot
		_sprite.position = -PICKAXE_GRIP
	else:
		_pivot.position = Vector2.ZERO
		_sprite.position = -hotspot
	_pivot.rotation = 0.0
	queue_redraw()


func _draw() -> void:
	var size := Game.get_pickaxe_size()
	if _current != &"pickaxe" or size <= 1:
		return
	var half := size * CubeSquare.SIZE / 2.0
	var box := Rect2(-Vector2.ONE * half, Vector2.ONE * half * 2.0)
	var b := REACH_BRACKET
	var left := box.position.x
	var top := box.position.y
	var right := box.end.x
	var bottom := box.end.y
	for bar in [
		Rect2(left, top, b, 1), Rect2(left, top, 1, b),
		Rect2(right - b, top, b, 1), Rect2(right - 1, top, 1, b),
		Rect2(left, bottom - 1, b, 1), Rect2(left, bottom - b, 1, b),
		Rect2(right - b, bottom - 1, b, 1), Rect2(right - 1, bottom - b, 1, b),
	]:
		draw_rect(bar, REACH_COLOR)


func _on_tool_used(hit: bool) -> void:
	if _current != &"pickaxe":
		return
	if _swing_tween:
		_swing_tween.kill()
	_pivot.rotation = -0.55 if hit else -0.3
	_swing_tween = create_tween()
	_swing_tween.tween_property(_pivot, "rotation", 0.0, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
