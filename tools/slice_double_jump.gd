extends SceneTree
## Recorta somente o salto novo, sem regenerar as outras animações.
const SOURCE := "res://art_source/personagem principal/animacoes/pulo_duplo.png"
const BOUNDS := [0, 210, 365, 565, 745, 945, 1110, 1275, 1450, 1672]
# Referências do corpo: a aura não determina a escala nem o ponto dos pés.
const ANCHORS := [Vector2i(144, 565), Vector2i(298, 556), Vector2i(496, 558),
	Vector2i(683, 550), Vector2i(866, 516), Vector2i(1052, 553),
	Vector2i(1205, 578), Vector2i(1379, 598), Vector2i(1580, 606)]
const FACTOR := 0.22
const CELL := Vector2i(64, 64)
const PIVOT := Vector2i(32, 54)

func _initialize() -> void:
	var source := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	source.convert(Image.FORMAT_RGBA8)
	var strip := Image.create(CELL.x * ANCHORS.size(), CELL.y, false, Image.FORMAT_RGBA8)
	for i in ANCHORS.size():
		var rect := Rect2i(BOUNDS[i], 340, BOUNDS[i + 1] - BOUNDS[i], 280)
		var frame := source.get_region(rect)
		frame.resize(roundi(rect.size.x * FACTOR), roundi(rect.size.y * FACTOR), Image.INTERPOLATE_LANCZOS)
		var offset := PIVOT - Vector2i(Vector2(ANCHORS[i] - rect.position) * FACTOR)
		strip.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i(i * CELL.x, 0) + offset)
	strip.save_png(ProjectSettings.globalize_path("res://assets/hero/double_jump.png"))
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hero/hero.json"))
	meta["double_jump"] = {"frames": ANCHORS.size(), "w": CELL.x, "h": CELL.y, "ax": PIVOT.x, "ay": PIVOT.y - 1}
	var file := FileAccess.open("res://assets/hero/hero.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(meta, "\t"))
	print("Salto duplo: 9 quadros, corpo na escala de Noct, aura preservada.")
	quit()
