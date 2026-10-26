class_name PixelSprites
## Small pixel-art sprites defined as text grids and turned into textures on first use.
## Edit the grids below to tweak the art; each character maps to a palette color.

const PALETTE := {
	"K": Color("0f1020"),
	"W": Color("f4f4f4"),
	"L": Color("94b0c2"),
	"G": Color("566c86"),
	"B": Color("c0814e"),
	"b": Color("7a4630"),
	"Y": Color("ffcd75"),
	"O": Color("ef7d57"),
	"R": Color("e43b44"),
	"r": Color("a82838"),
}

const SPRITES := {
	&"pickaxe": [
		"....KKKK........",
		"..KKWWLLKK......",
		".KWLLKKGGGK.....",
		".KLKK..KKGGK....",
		"KLK....KbKGGK...",
		"KLK...KBbK.KGK..",
		"KK...KBbK..KGK..",
		"....KBbK....KGK.",
		"...KBbK.....KGK.",
		"..KBbK......KKK.",
		".KBbK...........",
		"KBbK............",
		"KbbK............",
		".KK.............",
	],
	&"hand_open": [
		"......KK........",
		".....KWWK.......",
		"..KK.KWWK.KK....",
		".KWWKKWWKKWWK...",
		".KWWKKWWKKWWK...",
		".KWWKKWWKKWWKKK.",
		".KWWKKWWKKWWKWWK",
		".KWWWWWWWWWWKWWK",
		"KKWWWWWWWWWWWWWK",
		"KWKWWWWWWWWWWWLK",
		"KWWWWWWWWWWWWWLK",
		".KWWWWWWWWWWWLK.",
		"..KWWWWWWWWWLK..",
		"...KLWWWWWWLK...",
		"....KLLLLLLK....",
		"....KKKKKKKK....",
	],
	&"hand_closed": [
		"................",
		"................",
		"................",
		"....KK.KK.KK....",
		"...KWWKWWKWWKK..",
		"..KWKWWKWWKWWWK.",
		"..KWKWWKWWKWWWK.",
		".KKWWWWWWWWWWWK.",
		"KWKWWWWWWWWWWLK.",
		"KWWWWWWWWWWWWLK.",
		".KWWWWWWWWWWLK..",
		"..KWWWWWWWWWLK..",
		"...KLWWWWWWLK...",
		"....KLLLLLLK....",
		"....KKKKKKKK....",
		"................",
	],
	&"pointer": [
		"K.........",
		"KK........",
		"KWK.......",
		"KWWK......",
		"KWWWK.....",
		"KWWWWK....",
		"KWWWWWK...",
		"KWWWWWWK..",
		"KWWWWWWWK.",
		"KWWWWKKKKK",
		"KWWKWK....",
		"KWK.KWK...",
		"KK..KWK...",
		"K....KWK..",
		".....KWK..",
		"......K...",
	],
	&"coin": [
		"...KKKK...",
		".KKYYYYKK.",
		".KYWYYYOK.",
		"KYWYYYYYOK",
		"KYYYYYYYOK",
		"KYYYYYYOOK",
		"KYYYYYYOOK",
		".KYYYYOOK.",
		".KKOOOOKK.",
		"...KKKK...",
	],
	&"coin_big": [
		"....KKKKKK....",
		"..KKYYYYYYKK..",
		".KYYWWYYYYYOK.",
		".KYWYYYYYYYOK.",
		"KYWYYYYYYYYYOK",
		"KYWYYOOOOYYYOK",
		"KYYYYOYYWYYOOK",
		"KYYYYOYYWYYOOK",
		"KYYYYOWWWYYOOK",
		"KYYYYYYYYYOOOK",
		".KYYYYYYYYOOK.",
		".KOYYYYYYOOOK.",
		"..KKOOOOOOKK..",
		"....KKKKKK....",
	],
	&"badge": [
		"..KKKK..",
		".KRRRRK.",
		"KRWRRRRK",
		"KRRRRRRK",
		"KRRRRRRK",
		"KRRRRRrK",
		".KrRRrK.",
		"..KKKK..",
	],
	&"coin_small": [
		".KKKK.",
		"KYWYOK",
		"KYYYOK",
		"KYYOOK",
		".KOOK.",
		"..KK..",
	],
	# Explosive squares flicker a spark at the fuse tip (the Y); see CubeSquare.FUSE_TIP.
	&"bomb": [
		"........Y.",
		".......b..",
		"....GGb...",
		"...KKKK...",
		"..KKKKKK..",
		".KWLKKKKK.",
		".KLKKKKKK.",
		".KKKKKKKK.",
		".KKKKKKKK.",
		"..KKKKKK..",
		"...KKKK...",
	],
	&"blast": [
		"........K........",
		".......KRK.......",
		"...K...KOK...K...",
		"..KRKK.KOK.KKRK..",
		"...KORKRYRKROK...",
		"...KRYOOYOOYRK...",
		"....KOYYWYYOK....",
		".KKKROYWWWYORKKK.",
		"KROOYYWWWWWYYOORK",
		".KKKROYWWWYORKKK.",
		"....KOYYWYYOK....",
		"...KRYOOYOOYRK...",
		"...KORKRYRKROK...",
		"..KRKK.KOK.KKRK..",
		"...K...KOK...K...",
		".......KRK.......",
		"........K........",
	],
}

static var _cache := {}


static func get_texture(sprite: StringName) -> Texture2D:
	if not _cache.has(sprite):
		_cache[sprite] = _build(SPRITES[sprite])
	return _cache[sprite]


static func _build(rows: Array) -> ImageTexture:
	var width := 0
	for row: String in rows:
		width = maxi(width, row.length())
	var image := Image.create_empty(width, rows.size(), false, Image.FORMAT_RGBA8)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			image.set_pixel(x, y, PALETTE.get(row[x], Color.TRANSPARENT))
	return ImageTexture.create_from_image(image)
