extends Node2D
## Desenha o chão, as paredes e os espinhos da sala atual usando o tileset do tema.

const TILE := 16
const COLOR_SPIKE := Color("a39e7e")
const COLOR_SPIKE_DARK := Color("5c5843")

var level
var lava_tex: Texture2D


func _process(_delta: float) -> void:
	# A lava ondula: redesenha a sala quando há lava.
	if not level.lava.is_empty() or not level.rift.is_empty():
		queue_redraw()


## Paredes carmesim (X): pedra rachada com a energia da fenda pulsando nas frestas.
func _draw_rift() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for cell: Vector2i in level.rift:
		var dest := Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)
		var pulse := 0.55 + 0.45 * sin(t * 3.0 + cell.y * 0.7)
		draw_rect(dest, Color(0.16, 0.02, 0.06))
		draw_rect(dest, Color(0.9, 0.1, 0.28, 0.18 * pulse))
		# Rachaduras: zigue-zague que muda com a célula.
		var seed := (cell.x * 7 + cell.y * 13) % 5
		var a := dest.position + Vector2(3 + seed, 0)
		var b := dest.position + Vector2(TILE - 4 - seed, TILE * 0.45)
		var c := dest.position + Vector2(5 + seed * 0.5, TILE)
		draw_polyline(PackedVector2Array([a, b, c]), Color(1, 0.3, 0.45, 0.5 + 0.5 * pulse), 1.2)
		if not level.rift.has(cell + Vector2i.LEFT) and not level.solid.has(cell + Vector2i.LEFT):
			draw_rect(Rect2(dest.position, Vector2(1, TILE)), Color(1, 0.35, 0.5, 0.7 * pulse))
		if not level.rift.has(cell + Vector2i.RIGHT) and not level.solid.has(cell + Vector2i.RIGHT):
			draw_rect(Rect2(dest.position + Vector2(TILE - 1, 0), Vector2(1, TILE)), Color(1, 0.35, 0.5, 0.7 * pulse))


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
	if theme.get("autotile", false):
		_draw_autotile(theme, tileset, solid)
	else:
		_draw_blocks(theme, tileset, solid)

	_draw_lava(theme)
	_draw_rift()

	for h: Rect2 in level.hazards:
		# Poços de lava já foram desenhados em _draw_lava.
		if level.lava.has(Vector2i(int(h.position.x) / TILE, int(h.position.y) / TILE)):
			continue
		if theme.has("spike_src"):
			var src: Rect2 = theme["spike_src"]
			var tile_x := int(h.position.x) / TILE
			if theme.get("spike_pair", true):
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


## Tilesets dos pacotes: blocos de chão em colunas (blocks/block_w) e cor sólida abaixo de "rows" tiles.
func _draw_blocks(theme: Dictionary, tileset: Texture2D, solid: Dictionary) -> void:
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


## Tilesets próprios (assets/areas/): bloco 3x3 nas colunas 0-2 (cantos, bordas e meio) e o bloco
## isolado em (3,2). Cada célula escolhe a peça pelos lados expostos ao ar.
## "top_variants"/"fill_variants": peças (coluna, linha) que às vezes trocam o topo e o meio.
func _draw_autotile(theme: Dictionary, tileset: Texture2D, solid: Dictionary) -> void:
	var top_variants: Array = theme.get("top_variants", [])
	var fill_variants: Array = theme.get("fill_variants", [])
	for cell: Vector2i in solid:
		var up := not solid.has(cell + Vector2i.UP)
		var down := not solid.has(cell + Vector2i.DOWN)
		var left := not solid.has(cell + Vector2i.LEFT)
		var right := not solid.has(cell + Vector2i.RIGHT)
		var piece := Vector2i(1, 1)
		if up and down and left and right:
			piece = Vector2i(3, 2)
		else:
			piece.x = 0 if left and not right else (2 if right and not left else 1)
			piece.y = 0 if up else (2 if down else 1)
		# Variação fixa por célula (não pisca ao redesenhar).
		var roll := absi(cell.x * 73 + cell.y * 37) % 7
		if piece == Vector2i(1, 0) and not top_variants.is_empty() and roll == 0:
			piece = top_variants[cell.x % top_variants.size()]
		elif piece == Vector2i(1, 1) and not fill_variants.is_empty() and roll < 2:
			piece = fill_variants[(cell.x + cell.y) % fill_variants.size()]
		var src := Rect2(Vector2(piece * TILE), Vector2(TILE, TILE))
		draw_texture_rect_region(tileset, Rect2(Vector2(cell * TILE), Vector2(TILE, TILE)), src)
