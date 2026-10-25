class_name Fx
extends Node2D
## Central place for "juice" recipes: particles, popups, coins, shake and hitstop.
## Gameplay code says what happened; the feel of it is tuned here.

const POPUP_FONT := preload("res://assets/fonts/Silkscreen-Bold.ttf")
const POPUP_COLOR := Color("ffcd75")
const SPARK_COLORS: Array[Color] = [Color("f4f4f4"), Color("ffcd75")]
const DUST_COLORS: Array[Color] = [Color("566c86"), Color("94b0c2"), Color("333c57")]

@export var camera: ShakeCamera
@export var hud: Hud
## Screen-space layer for things that travel to the HUD.
@export var screen_layer: CanvasLayer
@export var screen_flash: ColorRect

var _popup_settings: LabelSettings
var _hitstop_depth := 0


func _ready() -> void:
	_popup_settings = LabelSettings.new()
	_popup_settings.font = POPUP_FONT
	_popup_settings.font_size = 16
	_popup_settings.font_color = POPUP_COLOR
	_popup_settings.shadow_color = Color("0f1020")
	_popup_settings.shadow_offset = Vector2(1, 2)
	_popup_settings.shadow_size = 0


# --- Recipes -----------------------------------------------------------------

## Squares damaged (but not broken) by one click: chips from each, one sound and shake.
func squares_hit(squares: Array[CubeSquare]) -> void:
	for square in squares:
		var chips := _burst(square.global_position, square.square_type.get_debris_colors(), 4)
		chips.speed_min = 30.0
		chips.speed_max = 80.0
		chips.lifetime_min = 0.15
		chips.lifetime_max = 0.3
		chips.size_max = 2
		chips.start()
	shake(0.12)
	Sfx.play(&"hit", 0.12)


## Squares broken by one click: each shatters, and the payout shows once, as a total
## popup with coins from the middle of the broken squares.
func squares_broken(squares: Array[CubeSquare]) -> void:
	var total := 0
	var center := Vector2.ZERO
	for square in squares:
		var at := square.global_position
		var type := square.square_type
		total += square.value
		center += at
		_chunks(at, type.outline_color, type.base_color, type.light_color).start()
		var debris := _burst(at, type.get_debris_colors(), 10 if squares.size() < 4 else 5)
		debris.speed_min = 50.0
		debris.speed_max = 140.0
		debris.size_min = 2
		debris.emit_extents = Vector2(5, 5)
		debris.start()
		var sparks := _burst(at, SPARK_COLORS, 5)
		sparks.speed_min = 90.0
		sparks.speed_max = 170.0
		sparks.gravity = 0.0
		sparks.damping = 6.0
		sparks.lifetime_min = 0.1
		sparks.lifetime_max = 0.2
		sparks.size_max = 1
		sparks.start()
	center /= squares.size()
	popup_text(center + Vector2(0, -10), "+%d" % total)
	coins(center, total)
	shake(minf(0.2 + 0.04 * (squares.size() - 1), 0.5))
	Sfx.play(&"break", 0.1, minf(squares.size() - 1, 4.0))


## The big one: call after the hitstop, right before the cube is removed.
func cube_exploded(cube: Cube) -> void:
	var center := cube.global_position
	for square in cube.get_squares():
		var type := square.square_type
		var from_center := square.global_position - center
		var chunks := _chunks(square.global_position, type.light_color, Color.WHITE, Color.WHITE)
		chunks.push = from_center * 4.0
		chunks.chunk_size = 6.0
		chunks.lifetime = 0.45
		chunks.start()
		var shards := _burst(square.global_position, type.get_debris_colors(), 5)
		shards.direction = from_center if from_center != Vector2.ZERO else Vector2.UP
		shards.spread = 0.9
		shards.speed_min = 70.0
		shards.speed_max = 200.0
		shards.gravity = 260.0
		shards.lifetime_min = 0.4
		shards.lifetime_max = 0.85
		shards.size_min = 2
		shards.size_max = 4
		shards.emit_extents = Vector2(4, 4)
		shards.start()
	var sparks := _burst(center, SPARK_COLORS, 22)
	sparks.speed_min = 120.0
	sparks.speed_max = 260.0
	sparks.gravity = 60.0
	sparks.damping = 4.0
	sparks.lifetime_min = 0.2
	sparks.lifetime_max = 0.45
	sparks.size_max = 2
	sparks.start()
	var half := cube.get_size().x / 2.0
	var wave := SquareShockwave.new()
	wave.position = center
	wave.start_half_size = half
	wave.end_half_size = half + 44.0
	wave.color = cube.cube_type.square_type.shine_color
	add_child(wave)
	flash_screen(0.12)
	shake(0.7)


## A square turning into another type (e.g. from an upgrade).
func square_converted(at: Vector2, type: SquareType) -> void:
	var sparkles := _burst(at, [type.shine_color, type.light_color, Color.WHITE], 8)
	sparkles.speed_min = 30.0
	sparkles.speed_max = 90.0
	sparkles.gravity = -40.0
	sparkles.damping = 4.0
	sparkles.lifetime_min = 0.3
	sparkles.lifetime_max = 0.55
	sparkles.size_max = 2
	sparkles.emit_extents = Vector2(6, 6)
	sparkles.start()
	var ring := SquareShockwave.new()
	ring.position = at
	ring.start_half_size = 8.0
	ring.end_half_size = 16.0
	ring.thickness = 2.0
	ring.duration = 0.25
	ring.color = type.light_color
	add_child(ring)
	Sfx.play(&"convert", 0.04)


func cube_landed(cube: Cube) -> void:
	var rect := cube.get_rect()
	for side in [-1.0, 1.0]:
		var dust := _burst(Vector2(rect.get_center().x, rect.end.y), DUST_COLORS, 7)
		dust.direction = Vector2(side, -0.35)
		dust.spread = 0.35
		dust.speed_min = 40.0
		dust.speed_max = 100.0
		dust.gravity = 40.0
		dust.damping = 5.0
		dust.lifetime_min = 0.25
		dust.lifetime_max = 0.5
		dust.size_max = 2
		dust.emit_extents = Vector2(rect.size.x / 2.0, 1)
		dust.start()
	shake(0.25)
	Sfx.play(&"land", 0.1)


func cube_dropped(cube: Cube) -> void:
	var rect := cube.get_rect()
	var dust := _burst(Vector2(rect.get_center().x, rect.end.y), DUST_COLORS, 6)
	dust.direction = Vector2.UP
	dust.spread = 1.3
	dust.speed_min = 20.0
	dust.speed_max = 60.0
	dust.gravity = 30.0
	dust.damping = 5.0
	dust.lifetime_min = 0.2
	dust.lifetime_max = 0.4
	dust.size_max = 2
	dust.emit_extents = Vector2(rect.size.x / 2.0, 1)
	dust.start()
	Sfx.play(&"drop", 0.08)


# --- Building blocks -------------------------------------------------------------

func popup_text(at: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.label_settings = _popup_settings
	add_child(label)
	label.size = label.get_minimum_size()
	label.pivot_offset = (label.size / 2.0).round()
	label.position = (at - label.size / 2.0).round()
	label.scale = Vector2.ONE * 1.6
	var tween := label.create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "position:y", label.position.y - 16.0, 0.6) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.2)
	tween.tween_callback(label.queue_free)


## Sends coins flying from a world position to the HUD money counter.
func coins(world_at: Vector2, value: int) -> void:
	if hud == null or screen_layer == null:
		return
	var count := clampi(value, 1, 8)
	var from := get_viewport().get_canvas_transform() * world_at
	var target := hud.get_coin_target()
	var remaining := value
	for i in count:
		var coin := FlyingCoin.new()
		coin.value = ceili(float(remaining) / (count - i))
		remaining -= coin.value
		screen_layer.add_child(coin)
		coin.arrived.connect(_on_coin_arrived)
		coin.launch(from, target, randf_range(0.4, 0.55), i * 0.05)


func flash_screen(alpha: float) -> void:
	if screen_flash == null:
		return
	screen_flash.color.a = alpha
	screen_flash.create_tween().tween_property(screen_flash, "color:a", 0.0, 0.18)


func shake(amount: float) -> void:
	if camera:
		camera.add_trauma(amount)


## Freezes the game for a moment of impact. Await it to continue after the freeze.
func hitstop(duration: float) -> void:
	_hitstop_depth += 1
	Engine.time_scale = 0.02
	await get_tree().create_timer(duration, true, false, true).timeout
	_hitstop_depth -= 1
	if _hitstop_depth == 0:
		Engine.time_scale = 1.0


func _burst(at: Vector2, colors: Array[Color], amount: int) -> PixelBurst:
	var burst := PixelBurst.new()
	burst.position = at
	burst.colors = colors
	burst.amount = amount
	add_child(burst)
	return burst


func _chunks(at: Vector2, outline: Color, fill: Color, highlight: Color) -> TileChunks:
	var chunks := TileChunks.new()
	chunks.position = at
	chunks.outline_color = outline
	chunks.fill_color = fill
	chunks.highlight_color = highlight
	add_child(chunks)
	return chunks


func _on_coin_arrived(coin: FlyingCoin) -> void:
	hud.on_coin_arrived(coin.value)
	Sfx.play(&"coin", 0.06, -4.0)
