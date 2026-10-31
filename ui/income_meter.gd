class_name IncomeMeter
extends Control
## Next to the money counter: money earned per minute, "+1.2K/min". It's what came in
## over the last WINDOW seconds, or since the run started when that's sooner (over
## MIN_SPAN at the least, so the first payouts don't read as a huge rate). Spending
## doesn't count. Hidden while nothing's coming in.

const MONEY_FONT := preload("res://assets/fonts/Silkscreen-Bold.ttf")
const FONT := preload("res://assets/fonts/Silkscreen-Regular.ttf")
## Seconds of earnings it averages over, one bucket per second.
const WINDOW := 60
const MIN_SPAN := 10.0
const REFRESH := 0.5
const COLOR := Color("94b0c2")
const SHADOW_COLOR := Color("0f1020")

## Seconds of play this run, paused with the game.
var _clock := 0.0
## Money earned in each of the last WINDOW seconds, as a ring. Floats, since it's only
## shown rounded, and late-game amounts would overflow an int when added up.
var _buckets := PackedFloat64Array()
## The second the newest bucket is for.
var _second := 0
var _text := ""
var _wait := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_buckets.resize(WINDOW)
	Game.money_changed.connect(_on_money_changed)


func _process(delta: float) -> void:
	_clock += delta
	_wait -= delta
	if _wait <= 0.0:
		_wait = REFRESH
		_refresh()


## Money per minute, at the current rate.
func get_per_minute() -> int:
	_advance()
	var total := 0.0
	for amount in _buckets:
		total += amount
	var span := clampf(_clock, MIN_SPAN, WINDOW)
	return floori(minf(total * 60.0 / span, Game.MAX_AMOUNT))


func _on_money_changed(_money: int, delta: int) -> void:
	if delta <= 0:
		return
	_advance()
	_buckets[_second % WINDOW] += delta


## Moves the ring up to the current second, emptying the buckets it passes.
func _advance() -> void:
	var now := floori(_clock)
	while _second < now:
		_second += 1
		_buckets[_second % WINDOW] = 0.0
		if now - _second > WINDOW:
			_second = now - WINDOW


func _refresh() -> void:
	var per_minute := get_per_minute()
	var text := "+%s/min" % Currency.format(per_minute) if per_minute > 0 else ""
	if text == _text:
		return
	_text = text
	custom_minimum_size.x = FONT.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x + 1
	queue_redraw()


func _draw() -> void:
	# On the money counter's baseline.
	var at := Vector2(0, roundf(MONEY_FONT.get_ascent(16)))
	draw_string(FONT, at + Vector2(1, 1), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, SHADOW_COLOR)
	draw_string(FONT, at, _text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COLOR)
