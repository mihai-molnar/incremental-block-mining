class_name Upgrade
extends ShopItem
## A purchase that changes the rules, optionally over several levels (tiers). Once owned,
## Game asks it through the hook methods below; subclasses override the hooks they need.

@export var title := "Upgrade"
## Leave empty to let the subclass describe itself.
@export_multiline var description := ""
## Price of level 1. Each level after it costs `price_growth` times the one before
## (100, 150, 230... with 1.5), rounded to two significant digits.
@export var price := 0
@export_range(1.0, 10.0, 0.05) var price_growth := 1.5
## How many times it can be bought. 0 means no limit.
@export_range(0, 99) var max_level := 1
## Stays out of the shop until this upgrade is owned.
@export var requires: Upgrade


func get_level() -> int:
	return Game.get_upgrade_level(self)


func is_maxed() -> bool:
	return max_level > 0 and get_level() >= max_level


## Whether it can be bought more than once.
func is_tiered() -> bool:
	return max_level != 1


func get_title() -> String:
	return title


func get_description() -> String:
	return description


## Price of the next level (or of the last one, once maxed).
func get_price() -> int:
	var bought := get_level() - 1 if is_maxed() else get_level()
	return _round_price(price * pow(price_growth, bought))


func is_available() -> bool:
	return requires == null or Game.has_upgrade(requires)


func is_owned() -> bool:
	return is_maxed()


func get_owned_label() -> String:
	return "Maxed" if is_tiered() else "Owned"


func can_purchase() -> bool:
	return not is_maxed() and not Game.would_soft_lock(get_price()) and super()


## Upgrades don't make money themselves, so they can't eat the money needed for a cube.
func get_block_reason() -> String:
	if is_maxed() or not Game.can_afford(get_price()) or not Game.would_soft_lock(get_price()):
		return ""
	return "Keep %s for a cube" % Currency.format(Game.get_cheapest_cube_price())


func _apply() -> void:
	Game.add_upgrade_level(self)


## Shop icon showing one PixelSprites sprite at its own size.
static func create_sprite_icon(sprite: StringName) -> Control:
	var icon := TextureRect.new()
	icon.texture = PixelSprites.get_texture(sprite)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(26, 26)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## Multipliers and seconds for descriptions: "2" when whole, "1.25" otherwise.
static func format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return String.num(value, 2)


## Keeps prices readable: two significant digits from 100 up (1139 -> 1100).
static func _round_price(value: float) -> int:
	if value < 100.0:
		return roundi(value)
	var step := pow(10.0, floorf(log(value) / log(10.0)) - 1.0)
	return roundi(roundf(value / step) * step)


# --- Hooks (level is this upgrade's owned level, at least 1) ----------------------

## Called for every square of a newly landed cube. Returns the type the square should be.
func modify_square_type(_cube_type: CubeType, current: SquareType, _level: int) -> SquareType:
	return current


## Clicks needed to break a square. Game clamps the final result to at least 1.
func modify_square_hp(_square_type: SquareType, hp: int, _level: int) -> int:
	return hp


## Side, in squares, of the area one click hits.
func modify_pickaxe_size(size: int, _level: int) -> int:
	return size


## How many squares out an explosive square's blast reaches.
func modify_blast_radius(radius: int, _level: int) -> int:
	return radius


## How many mining drones fly around the field.
func modify_drone_count(count: int, _level: int) -> int:
	return count


## Hits per second each drone makes.
func modify_drone_hit_rate(rate: float, _level: int) -> float:
	return rate


## How many cubes the auto-buyer keeps on the field (0 = there's no auto-buyer).
func modify_auto_buy_slots(slots: int, _level: int) -> int:
	return slots


## Payout multiplier for finishing a cube (1.25 pays a quarter of its value on top).
func modify_clear_bonus(multiplier: float, _level: int) -> float:
	return multiplier


## Highest payout multiplier the combo meter reaches.
func modify_combo_cap(cap: float, _level: int) -> float:
	return cap


## Seconds the combo meter waits for the next hit before it drops.
func modify_combo_window(seconds: float, _level: int) -> float:
	return seconds


## Chance (0..1) that one of the player's hits breaks a square outright.
func modify_crit_chance(chance: float, _level: int) -> float:
	return chance
