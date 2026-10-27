class_name Currency
## Turns money amounts into display text. Amounts below 10,000 show in full; bigger ones
## are shortened to one decimal (10.3K, 2.5M...), with a whole number shown without
## the ".0" (10K). Always rounded down, so the HUD never shows more than you have.

const SHORTEN_FROM := 10_000
## Up to quintillions, as far as a 64-bit int goes (9.2Qi).
const SUFFIXES: Array[String] = ["K", "M", "B", "T", "Qa", "Qi"]


static func format(amount: int) -> String:
	var size := absi(amount)
	if size < SHORTEN_FROM:
		return str(amount)
	var divisor := 1.0
	var suffix := ""
	for next in SUFFIXES:
		if size < divisor * 1000.0:
			break
		divisor *= 1000.0
		suffix = next
	var tenths := floori(size * 10.0 / divisor)
	var whole := floori(tenths / 10.0)
	var decimal := tenths % 10
	var text := str(whole) if decimal == 0 else "%d.%d" % [whole, decimal]
	return ("-" if amount < 0 else "") + text + suffix
