class_name Fx
extends Node2D
## Central place for "juice" recipes: particles, popups, coins, shake and hitstop.
## Gameplay code says what happened; the feel of it is tuned here.

const POPUP_FONT := preload("res://assets/fonts/Silkscreen-Bold.ttf")
const SMALL_FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
const POPUP_COLOR := Color("ffcd75")
const SPARK_COLORS: Array[Color] = [Color("f4f4f4"), Color("ffcd75")]
const DUST_COLORS: Array[Color] = [Color("566c86"), Color("94b0c2"), Color("333c57")]
const FIRE_COLORS: Array[Color] = [Color("f4f4f4"), Color("ffcd75"), Color("ffcd75"), Color("ef7d57"), Color("b13e53")]
const CRIT_COLOR := Color("ef7d57")
const CLEAR_COLOR := Color("73eff7")
const LUCKY_COLORS: Array[Color] = [Color("ffcd75"), Color("ffcd75"), Color("f4f4f4")]
const BOLT_COLORS: Array[Color] = [Color("f4f4f4"), Color("73eff7"), Color("ffcd75")]
const COIN_COLORS: Array[Color] = [Color("ffcd75"), Color("ffcd75"), Color("ef7d57"), Color("f4f4f4")]
const METAL_COLORS: Array[Color] = [Color("f4f4f4"), Color("94b0c2"), Color("566c86"), Color("7a4630")]

@export var camera: ShakeCamera
@export var hud: Hud
## Screen-space layer for things that travel to the HUD.
@export var screen_layer: CanvasLayer
@export var screen_flash: ColorRect

## Popup text styles by font color and size.
var _popup_settings := {}
var _hitstop_depth := 0
## Frame of the last explosion boom and lightning zap, so ones going off together
## share a single sound and flash.
var _last_boom_frame := -1
var _last_zap_frame := -1


# --- Recipes -----------------------------------------------------------------

## Squares damaged (but not broken) by one click: chips from each, one sound and shake.
## Soft hits (from drones) chip less, don't shake and tick quietly, so a swarm of them
## doesn't drown out the player's own clicks.
func squares_hit(squares: Array[CubeSquare], soft := false) -> void:
	for square in squares:
		var chips := _burst(square.global_position, square.square_type.get_debris_colors(), 2 if soft else 4)
		chips.speed_min = 30.0
		chips.speed_max = 80.0
		chips.lifetime_min = 0.15
		chips.lifetime_max = 0.3
		chips.size_max = 2
		chips.start()
	if soft:
		Sfx.play(&"hit", 0.12, -14.0, 1.5)
	else:
		shake(0.12)
		Sfx.play(&"hit", 0.12)


## Squares broken by one click: each shatters, and the payout shows once, as a total
## popup with coins from the middle of the broken squares. Soft breaks (from drones)
## don't shake, sound quieter and send fewer coins. Coin pouches burst in a fountain of
## coins with a jingle, however they broke.
func squares_broken(squares: Array[CubeSquare], payout: int, soft := false) -> void:
	var center := Vector2.ZERO
	var pouches := 0
	for square in squares:
		var at := square.global_position
		var type := square.square_type
		center += at
		if type.coin_shower:
			pouches += 1
			_coin_fountain(at)
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
	# Squares that pay nothing (the Star Core's, rocks) show no popup or coins.
	if payout <= 0:
		if not soft:
			shake(minf(0.2 + 0.04 * (squares.size() - 1), 0.5))
		Sfx.play(&"break", 0.1, -8.0 if soft else minf(squares.size() - 1, 4.0))
		return
	popup_text(center + Vector2(0, -10), "+" + Currency.format(payout))
	if pouches > 0:
		coins(center, payout, 8 + 6 * mini(pouches, 2))
		for i in 4:
			get_tree().create_timer(i * 0.07).timeout.connect(Sfx.play.bind(&"coin", 0.12, -3.0))
	if soft:
		if pouches == 0:
			coins(center, payout, 3)
		Sfx.play(&"break", 0.1, -8.0)
		return
	if pouches == 0:
		coins(center, payout)
	shake(minf(0.2 + 0.04 * (squares.size() - 1), 0.5))
	Sfx.play(&"break", 0.1, minf(squares.size() - 1, 4.0))


## Squares a click broke outright with a critical hit: a gold flash on each, and one
## "CRIT!" popup above them. Play it before the break effects of the same click.
func critical_hits(squares: Array[CubeSquare]) -> void:
	var center := Vector2.ZERO
	for square in squares:
		var at := square.global_position
		center += at
		var core := SquareShockwave.new()
		core.position = at
		core.start_half_size = 4.0
		core.end_half_size = 10.0
		core.thickness = 8.0
		core.duration = 0.16
		core.color = Color("f4f4f4")
		add_child(core)
		var ring := SquareShockwave.new()
		ring.position = at
		ring.start_half_size = 8.0
		ring.end_half_size = 22.0
		ring.thickness = 3.0
		ring.duration = 0.3
		ring.color = POPUP_COLOR
		add_child(ring)
		var sparks := _burst(at, SPARK_COLORS, 12)
		sparks.speed_min = 110.0
		sparks.speed_max = 220.0
		sparks.gravity = 0.0
		sparks.damping = 5.0
		sparks.lifetime_min = 0.15
		sparks.lifetime_max = 0.3
		sparks.size_max = 2
		sparks.start()
	center /= squares.size()
	var text := "CRIT!" if squares.size() == 1 else "CRIT x%d!" % squares.size()
	popup_text(center + Vector2(0, -28), text, CRIT_COLOR)
	shake(0.15)
	Sfx.play(&"crit", 0.05)


## A finished cube's clear bonus: a "CLEAR!" banner with the multiplier and the bonus,
## and the bonus flying to the money counter. Call it with cube_exploded.
func cube_cleared(cube: Cube, multiplier: float, bonus: int) -> void:
	_banner(cube.global_position, [
		_make_label("CLEAR! x" + Upgrade.format_number(multiplier), CLEAR_COLOR),
		_make_label("+" + Currency.format(bonus), POPUP_COLOR),
	], 1.0)
	# The coins wait for the banner to land, so they don't fly over it as it pops.
	coins(cube.global_position + Vector2(0, 8), bonus, 8, 0.35)
	Sfx.play(&"clear", 0.0)


## A Lucky Cube setting off across the field: a chime so the player looks up.
func lucky_cube_appeared() -> void:
	Sfx.play(&"lucky", 0.0)


## Sparkles a drifting Lucky Cube leaves behind.
func lucky_trail(at: Vector2) -> void:
	var sparkles := _burst(at, LUCKY_COLORS, 2)
	sparkles.speed_min = 5.0
	sparkles.speed_max = 25.0
	sparkles.gravity = 30.0
	sparkles.damping = 2.0
	sparkles.lifetime_min = 0.3
	sparkles.lifetime_max = 0.6
	sparkles.size_max = 2
	sparkles.emit_extents = Vector2(10, 10)
	sparkles.start()


## A Lucky Cube caught: it bursts in a flash of gold, and a banner names the frenzy.
func lucky_caught(at: Vector2, frenzy: Frenzy) -> void:
	var ring := SquareShockwave.new()
	ring.position = at
	ring.start_half_size = 12.0
	ring.end_half_size = 70.0
	ring.thickness = 4.0
	ring.duration = 0.45
	ring.color = frenzy.color
	add_child(ring)
	var core := SquareShockwave.new()
	core.position = at
	core.start_half_size = 6.0
	core.end_half_size = 24.0
	core.thickness = 12.0
	core.duration = 0.2
	core.color = Color("f4f4f4")
	add_child(core)
	var colors: Array[Color] = LUCKY_COLORS.duplicate()
	colors.append(frenzy.color)
	var sparks := _burst(at, colors, 40)
	sparks.speed_min = 80.0
	sparks.speed_max = 260.0
	sparks.gravity = 120.0
	sparks.damping = 3.0
	sparks.lifetime_min = 0.4
	sparks.lifetime_max = 0.9
	sparks.size_min = 1
	sparks.size_max = 3
	sparks.emit_extents = Vector2(8, 8)
	sparks.start()
	_banner(at, [
		_make_label("FRENZY!", Color("f4f4f4")),
		_make_label(frenzy.get_title(), frenzy.color),
		_make_label(frenzy.get_description(), Color("f4f4f4"), true),
	], 1.8)
	flash_screen(0.25)
	shake(0.6)
	hitstop(0.06)
	Sfx.play(&"frenzy", 0.0)


## The Star Core breaking: a freeze, a white-out as the core blows apart in a burst of
## light, then the star swelling where it was and rising off the top of the screen. Await
## it (~3.5s). `core` is null when it's already gone (the middle of the field then).
func star_freed(core: Cube) -> void:
	var at := core.global_position if core else get_viewport_rect().get_center()
	Sfx.play(&"explode", 0.0)
	shake(1.0)
	await hitstop(0.35)
	flash_screen(1.0)
	if core:
		cube_exploded(core)
		core.hide()
	Sfx.play(&"lucky", 0.0)
	var ring := SquareShockwave.new()
	ring.position = at
	ring.start_half_size = 20.0
	ring.end_half_size = 220.0
	ring.thickness = 8.0
	ring.duration = 0.8
	ring.color = Color("ffcd75")
	add_child(ring)
	var sparks := _burst(at, LUCKY_COLORS, 90)
	sparks.speed_min = 120.0
	sparks.speed_max = 340.0
	sparks.gravity = 60.0
	sparks.damping = 2.0
	sparks.lifetime_min = 0.6
	sparks.lifetime_max = 1.4
	sparks.size_min = 1
	sparks.size_max = 3
	sparks.emit_extents = Vector2(40, 40)
	sparks.start()
	var star := Sprite2D.new()
	star.texture = PixelSprites.get_texture(&"fallen_star")
	star.position = at.round()
	star.scale = Vector2.ONE * 0.25
	add_child(star)
	var tween := star.create_tween()
	tween.tween_property(star, "scale", Vector2.ONE * 2.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.7)
	tween.tween_callback(Sfx.play.bind(&"frenzy", 0.0))
	tween.tween_property(star, "position:y", -60.0, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_method(func(_t: float) -> void: lucky_trail(star.position), 0.0, 1.0, 1.8)
	await tween.finished
	star.queue_free()


## The pickaxe out of HP: it shatters at the cursor, and the run is over.
func pickaxe_broken(at: Vector2) -> void:
	var shards := _burst(at, METAL_COLORS, 18)
	shards.speed_min = 60.0
	shards.speed_max = 170.0
	shards.lifetime_max = 0.8
	shards.size_max = 4
	shards.start()
	_banner(get_viewport_rect().size / 2.0, [
		_make_label("PICKAXE BROKE!", CRIT_COLOR),
		_make_label("The run is over", Color("f4f4f4"), true),
	], 1.6)
	flash_screen(0.35)
	shake(0.7)
	hitstop(0.12)
	Sfx.play(&"crit", 0.0, 0.0, 0.7)


## A mining drone out of HP falling apart.
func drone_broken(at: Vector2) -> void:
	var bits := _burst(at, METAL_COLORS, 8)
	bits.speed_min = 30.0
	bits.speed_max = 90.0
	bits.size_max = 2
	bits.start()
	Sfx.play(&"break", 0.1, -6.0)


## The mine collapsing at the end of a run: every cube on the field shatters at once,
## under a white-out and a long rumble.
func mine_collapsed(cubes: Array[Cube]) -> void:
	for cube in cubes:
		cube_exploded(cube)
	flash_screen(0.7)
	shake(1.0)
	Sfx.play(&"collapse", 0.0)


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


## An explosive square going off, reaching `radius` squares out: a white-hot core that
## opens into a ring the size of the blast, fire, smoke and a kick of shake. Explosions
## in the same frame (one link of a chain reaction) share a single boom and flash.
func explosion(at: Vector2, radius: int) -> void:
	var reach := (radius + 0.5) * CubeSquare.SIZE
	var core := SquareShockwave.new()
	core.position = at
	core.start_half_size = 5.0
	core.end_half_size = reach * 0.6
	core.thickness = 10.0
	core.duration = 0.2
	core.color = Color("f4f4f4")
	add_child(core)
	var ring := SquareShockwave.new()
	ring.position = at
	ring.start_half_size = 8.0
	ring.end_half_size = reach + 6.0
	ring.thickness = 3.0
	ring.duration = 0.32
	ring.color = Color("ffcd75")
	add_child(ring)
	var fire := _burst(at, FIRE_COLORS, 12 + 8 * radius)
	fire.speed_min = 40.0
	fire.speed_max = reach * 6.0
	fire.gravity = -40.0
	fire.damping = 5.0
	fire.lifetime_min = 0.2
	fire.lifetime_max = 0.45
	fire.size_min = 2
	fire.size_max = 4
	fire.emit_extents = Vector2(3, 3)
	fire.start()
	var smoke := _burst(at, DUST_COLORS, 6 + 4 * radius)
	smoke.speed_min = 10.0
	smoke.speed_max = reach * 2.0
	smoke.gravity = -60.0
	smoke.damping = 3.0
	smoke.lifetime_min = 0.45
	smoke.lifetime_max = 0.9
	smoke.size_min = 2
	smoke.size_max = 4
	smoke.emit_extents = Vector2(reach, reach) * 0.4
	smoke.start()
	shake(0.3 + 0.08 * radius)
	var frame := Engine.get_process_frames()
	if frame != _last_boom_frame:
		_last_boom_frame = frame
		flash_screen(0.1)
		Sfx.play(&"blast", 0.1)


## A lightning square going off: crackling bolts along its row and column across `span`,
## sparks where they cross, and a kick of shake. Lightning in the same frame shares one
## zap and flash.
func lightning(at: Vector2, span: Rect2) -> void:
	var ends: Array[Vector2] = [
		Vector2(span.position.x, at.y), Vector2(span.end.x, at.y),
		Vector2(at.x, span.position.y), Vector2(at.x, span.end.y),
	]
	for i in range(0, ends.size(), 2):
		var bolt := LightningBolt.new()
		bolt.from = ends[i]
		bolt.to = ends[i + 1]
		add_child(bolt)
	var sparks := _burst(at, BOLT_COLORS, 16)
	sparks.speed_min = 80.0
	sparks.speed_max = 200.0
	sparks.gravity = 0.0
	sparks.damping = 5.0
	sparks.lifetime_min = 0.15
	sparks.lifetime_max = 0.35
	sparks.size_max = 2
	sparks.start()
	shake(0.35)
	var frame := Engine.get_process_frames()
	if frame != _last_zap_frame:
		_last_zap_frame = frame
		flash_screen(0.12)
		Sfx.play(&"zap", 0.08)


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

func popup_text(at: Vector2, text: String, color := POPUP_COLOR) -> void:
	var label := _make_label(text, color)
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


## A label in the popup style (bold 16, with a drop shadow), or regular 8 when `small`.
## Size it once it's in the tree.
func _make_label(text: String, color: Color, small := false) -> Label:
	var key := [color, small]
	if not _popup_settings.has(key):
		var settings := LabelSettings.new()
		settings.font = SMALL_FONT if small else POPUP_FONT
		settings.font_size = 8 if small else 16
		settings.font_color = color
		settings.shadow_color = Color("0f1020")
		settings.shadow_offset = Vector2(1, 1) if small else Vector2(1, 2)
		settings.shadow_size = 0
		_popup_settings[key] = settings
	var label := Label.new()
	label.text = text
	label.label_settings = _popup_settings[key]
	return label


## Centered lines of text that pop in at `at`, drift up for `duration` and fade, kept on
## screen and clear of the open sidebar when `at` is near an edge.
func _banner(at: Vector2, labels: Array[Label], duration: float) -> void:
	var banner := Node2D.new()
	add_child(banner)
	var size := Vector2.ZERO
	for label in labels:
		banner.add_child(label)
		label.size = label.get_minimum_size()
		size = Vector2(maxf(size.x, label.size.x), size.y + label.size.y)
	var y := -size.y / 2.0
	for label in labels:
		label.position = Vector2(-label.size.x / 2.0, y).round()
		y += label.size.y
	var half := size / 2.0 + Vector2(4, 4)
	var view := get_viewport_rect().size
	var right := view.x - (hud.get_covered_width() if hud else 0.0)
	banner.position = Vector2(clampf(at.x, half.x, right - half.x), clampf(at.y, half.y + 20.0, view.y - half.y)).round()
	banner.scale = Vector2.ONE * 2.0
	var tween := banner.create_tween()
	tween.tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(banner, "position:y", banner.position.y - 20.0, duration) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(banner, "modulate:a", 0.0, 0.25)
	tween.tween_callback(banner.queue_free)


## Sends coins flying from a world position to the HUD money counter, up to `max_count`
## of them, splitting the value between them. They set off after `delay` seconds.
func coins(world_at: Vector2, value: int, max_count := 8, delay := 0.0) -> void:
	if hud == null or screen_layer == null:
		return
	var count := clampi(value, 1, max_count)
	var from := get_viewport().get_canvas_transform() * world_at
	var target := hud.get_coin_target()
	var remaining := value
	for i in count:
		var coin := FlyingCoin.new()
		coin.value = ceili(float(remaining) / (count - i))
		remaining -= coin.value
		screen_layer.add_child(coin)
		coin.arrived.connect(_on_coin_arrived)
		coin.launch(from, target, randf_range(0.4, 0.55), delay + i * 0.05)


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


## Coins spraying up out of a broken coin pouch and raining back down.
func _coin_fountain(at: Vector2) -> void:
	var fountain := _burst(at, COIN_COLORS, 24)
	fountain.direction = Vector2.UP
	fountain.spread = 0.7
	fountain.speed_min = 90.0
	fountain.speed_max = 190.0
	fountain.gravity = 420.0
	fountain.damping = 0.5
	fountain.lifetime_min = 0.5
	fountain.lifetime_max = 0.9
	fountain.size_min = 2
	fountain.size_max = 3
	fountain.start()


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
