extends Node2D
## Desenha o chão, as paredes e os espinhos da sala atual usando o tileset do tema.

const TILE := 16
const COLOR_SPIKE := Color("a39e7e")
const COLOR_SPIKE_DARK := Color("5c5843")

var level
var lava_tex: Texture2D


func _process(_delta: float) -> void:
	# A lava ondula: redesenha a sala quando há lava.
	if not level.lava.is_empty():
		queue_redraw()


## Poços de lava (caractere ~ no mapa): faixa de cima do bloco de lava, deslizando devagar.
func _draw_lava(theme: Dictionary) -> void:
	if level.lava.is_empty():
		return
	if lava_tex == null or lava_tex.resource_path != theme.get("lava_tile", ""):
		lava_tex = load(theme["lava_tile"])
	var shift := int(Time.get_ticks_msec() / 120.0) % 48
	for cell: Vector2i in level.lava:
		var src := Rect2(fposmod(cell.x * TILE + shift, 48 - TILE), 0, TILE, TILE)
		draw_texture_rect_region(lava_tex, Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE), src)


func _draw() -> void:
	var theme: Dictionary = level.theme
	var tileset: Texture2D = level.tileset
	var solid: Dictionary = level.solid
	var blocks: Array = theme["blocks"]
	var block_w: int = theme["block_w"]
	var rows: int = theme["rows"]
	var top: int = theme["top"]
	for cell: Vector2i in solid:
		var dest := Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)
		# Profundidade = quantos blocos sólidos existem acima até chegar no ar.
		var depth := 0
		while depth < rows and solid.has(cell + Vector2i(0, -(depth + 1))):
			depth += 1
		if depth < rows:
			var block: int = blocks[(cell.x / block_w) % blocks.size()]
			var src := Rect2(block + (cell.x % block_w) * TILE, top + depth * TILE, TILE, TILE)
			draw_texture_rect_region(tileset, dest, src, theme.get("tint", Color.WHITE))
		else:
			draw_rect(dest, theme["rock"])
		if not solid.has(cell + Vector2i.LEFT):
			draw_rect(Rect2(dest.position, Vector2(2, TILE)), theme["side"])
		if not solid.has(cell + Vector2i.RIGHT):
			draw_rect(Rect2(dest.position + Vector2(TILE - 2, 0), Vector2(2, TILE)), theme["side"])

	_draw_lava(theme)

	for h: Rect2 in level.hazards:
		# Poços de lava já foram desenhados em _draw_lava.
		if level.lava.has(Vector2i(int(h.position.x) / TILE, int(h.position.y) / TILE)):
			continue
		if theme.has("spike_src"):
			var src: Rect2 = theme["spike_src"]
			var tile_x := int(h.position.x) / TILE
			src.position.x += (tile_x % 2) * TILE
			draw_texture_rect_region(tileset, Rect2(tile_x * TILE, h.end.y - src.size.y, TILE, src.size.y), src)
			continue
		var bottom := h.end.y
		var left := h.position.x - 2
		for i in 3:
			var x0 := left + i * 5 + 0.5
			draw_colored_polygon(PackedVector2Array([
				Vector2(x0, bottom), Vector2(x0 + 2.5, bottom - 11), Vector2(x0 + 5, bottom),
			]), COLOR_SPIKE)
			draw_line(Vector2(x0 + 2.5, bottom - 11), Vector2(x0 + 5, bottom), COLOR_SPIKE_DARK)
