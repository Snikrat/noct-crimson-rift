extends SceneTree
## Recortes do combo aéreo; escala baseada no corpo, sem contar a energia.
const SOURCE := "res://art_source/personagem principal/animacoes/combo_aereo.png"
const BOUNDS := [0, 220, 525, 790, 1100, 1450, 1730, 1935, 2172]
const ANCHORS := [150, 355, 655, 935, 1200, 1600, 1840, 2100]
const FACTOR := 0.16
const CELL := Vector2i(72, 64)
const PIVOT := Vector2i(30, 50)

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	source.convert(Image.FORMAT_RGBA8)
	var frames := []
	for i in ANCHORS.size():
		var rect := Rect2i(BOUNDS[i], 225, BOUNDS[i + 1] - BOUNDS[i], 325)
		var region := source.get_region(rect)
		region.resize(roundi(rect.size.x * FACTOR), roundi(rect.size.y * FACTOR), Image.INTERPOLATE_LANCZOS)
		var canvas := Image.create(CELL.x, CELL.y, false, Image.FORMAT_RGBA8)
		var offset := PIVOT - Vector2i(Vector2(Vector2i(ANCHORS[i], 510) - rect.position) * FACTOR)
		canvas.blit_rect(region, Rect2i(Vector2i.ZERO, region.get_size()), offset)
		frames.append(canvas)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/hero.json"))
	for spec in [["air_punch", 0, 3], ["air_kick", 3, 2], ["air_finish", 5, 3]]:
		var strip := Image.create(CELL.x * spec[2], CELL.y, false, Image.FORMAT_RGBA8)
		for j in spec[2]:
			strip.blit_rect(frames[spec[1] + j], Rect2i(Vector2i.ZERO, CELL), Vector2i(j * CELL.x, 0))
		strip.save_png(ProjectSettings.globalize_path("res://assets/hero/" + spec[0] + ".png"))
		meta[spec[0]] = {"frames": spec[2], "w": CELL.x, "h": CELL.y, "ax": PIVOT.x, "ay": PIVOT.y - 1}
	var file := FileAccess.open("res://assets/hero/hero.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(meta, "\t"))
	print("Combo aéreo: três golpes, oito quadros.")
	quit()
