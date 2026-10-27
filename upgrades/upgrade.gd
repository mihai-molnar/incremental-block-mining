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
## A perk: bought with Shards on the Prestige page instead of money, and kept when the
## mine collapses.
@export var costs_shards := false


## Owned tiers, counting free ones from perks.
func get_level() -> int:
	return Game.get_upgrade_level(self)


## Free tiers don't count toward the cap, so a perk adds tiers past it.
func is_maxed() -> bool:
	return max_level > 0 and Game.get_bought_level(self) >= max_level


## Whether it can be bought more than once.
func is_tiered() -> bool:
	return max_level != 1


func get_title() -> String:
	return title


func get_description() -> String:
	return description


## Price of the next level (or of the last one, once maxed). Free tiers don't raise it.
func get_price() -> int:
	var bought := Game.get_bought_level(self)
	if is_maxed():
		bought -= 1
	return _round_price(price * pow(price_growth, bought))


## Owned upgrades stay listed whatever happens.
func is_available() -> bool:
	return get_level() > 0 or super()


func meets_requirements() -> bool:
	return requires == null or Game.has_upgrade(requires)


func is_owned() -> bool:
	return is_maxed()


func get_owned_label() -> String:
	return "Maxed" if is_tiered() else "Owned"


func can_purchase() -> bool:
	if is_maxed() or not is_available():
		return false
	if costs_shards:
		return Game.shards >= get_price()
	return not Game.would_soft_lock(get_price()) and super()


## Upgrades don't make money themselves, so they can't eat the money needed for a cube.
func get_block_reason() -> String:
	if costs_shards or is_maxed() or not Game.can_afford(get_price()) or not Game.would_soft_lock(get_price()):
		return ""
	return "Keep %s for a cube" % Currency.format(Game.get_cheapest_cube_price())


func get_price_icon() -> StringName:
	return &"shard_small" if costs_shards else super()


func _pay(cost: int) -> bool:
	return Game.try_spend_shards(cost) if costs_shards else super(cost)


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

## The upgrade this one hands a free tier of per level, or null. Game counts those tiers
## into that upgrade's level (see FreeTiersUpgrade).
func get_free_tiers_target() -> Upgrade:
	return null


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


## The pickaxe's HP at the start of a run.
func modify_max_pickaxe_hp(hp: int, _level: int) -> int:
	return hp


## Pickaxe HP one click that hits costs.
func modify_click_cost(cost: int, _level: int) -> int:
	return cost


## Hits a new mining drone makes before it breaks.
func modify_drone_hp(hp: int, _level: int) -> int:
	return hp


## Drones a new run starts with.
func modify_starting_drones(count: int, _level: int) -> int:
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


## What every payout from squares is multiplied by.
func modify_payout_multiplier(multiplier: float, _level: int) -> float:
	return multiplier


## Squares the player breaks before the next Lucky Cube drifts by.
func modify_lucky_interval(squares: float, _level: int) -> float:
	return squares


## Seconds a frenzy lasts.
func modify_frenzy_duration(seconds: float, _level: int) -> float:
	return seconds


## Money a new run starts with.
func modify_starting_money(amount: int, _level: int) -> int:
	return amount


## How much each Shard ever earned adds to earnings.
func modify_shard_bonus(bonus: float, _level: int) -> float:
	return bonus
