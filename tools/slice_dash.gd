extends SceneTree
## Dash carmesim: escala pelo corpo, com espaço para os rastros à esquerda.
const SOURCE := "res://Sequência de Dash em Pixel Art.png"
const BOUNDS := [0, 210, 440, 690, 1000, 1390, 1680, 1930, 2172]
const ANCHORS := [125, 360, 580, 865, 1210, 1530, 1845, 2080]
const FACTOR := 0.19
const CELL := Vector2i(104, 64)
const PIVOT := Vector2i(80, 52)

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	source.convert(Image.FORMAT_RGBA8)
	var strip := Image.create(CELL.x * ANCHORS.size(), CELL.y, false, Image.FORMAT_RGBA8)
	for i in ANCHORS.size():
		var rect := Rect2i(BOUNDS[i], 290, BOUNDS[i + 1] - BOUNDS[i], 230)
		var frame := source.get_region(rect)
		frame.resize(roundi(rect.size.x * FACTOR), roundi(rect.size.y * FACTOR), Image.INTERPOLATE_LANCZOS)
		var anchor := Vector2i(ANCHORS[i], 505)
		var offset := PIVOT - Vector2i(Vector2(anchor - rect.position) * FACTOR)
		strip.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(i * CELL.x, 0) + offset)
	strip.save_png(ProjectSettings.globalize_path("res://assets/hero/dash.png"))
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/hero.json"))
	meta["dash"] = {"frames": ANCHORS.size(), "w": CELL.x, "h": CELL.y, "ax": PIVOT.x, "ay": PIVOT.y - 1}
	var file := FileAccess.open("res://assets/hero/hero.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(meta, "\t"))
	print("Dash carmesim: 8 quadros na escala do corpo de Noct.")
	quit()
