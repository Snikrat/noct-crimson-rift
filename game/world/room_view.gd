extends Node2D
## Desenha o chão, as paredes e os espinhos da sala atual usando o tileset do tema.

const TILE := 16
# Feitos no Aseprite (art_source/vfx/): espinhos em 2 variações de 16x16; parede carmesim em
# 3 variações (colunas) x 4 níveis de brilho da rachadura (linhas).
const SPIKES_TEX := preload("res://assets/props/spikes.png")
const RIFT_TEX := preload("res://assets/props/rift_wall.png")
const RIFT_VARIANTS := 3
const RIFT_LEVELS := 4
# Fundo dos poços de espinhos: distância máxima até a parede e quanto a terra de trás escurece.
const PIT_REACH := 6
const PIT_SHADE := Color(0.42, 0.42, 0.48)

var level
var lava_tex: Texture2D


func _process(_delta: float) -> void:
	# A lava ondula: redesenha a sala quando há lava.
	if not level.lava.is_empty() or not level.rift.is_empty() or not level.water.is_empty():
		queue_redraw()


## Paredes carmesim (X): pedra rachada com a energia da fenda pulsando nas frestas.
func _draw_rift() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for cell: Vector2i in level.rift:
		var dest := Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)
		var pulse := 0.55 + 0.45 * sin(t * 3.0 + cell.y * 0.7)
		var variant := (cell.x * 7 + cell.y * 13) % RIFT_VARIANTS
		var glow := clampi(int(roundf(pulse * RIFT_LEVELS)) - 1, 0, RIFT_LEVELS - 1)
		draw_texture_rect_region(RIFT_TEX, dest, Rect2(variant * TILE, glow * TILE, TILE, TILE))
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


## Água parada (w no mapa): faixa escura translúcida com um brilho na superfície que oscila.
func _draw_water(theme: Dictionary) -> void:
	if level.water.is_empty():
		return
	var color: Color = theme.get("water", Color(0.1, 0.18, 0.3, 0.75))
	var t := Time.get_ticks_msec() / 1000.0
	for cell: Vector2i in level.water:
		var dest := Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)
		draw_rect(dest, color)
		if not level.water.has(cell + Vector2i.UP):
			var shine := 0.25 + 0.2 * sin(t * 2.0 + cell.x * 0.9)
			draw_rect(Rect2(dest.position + Vector2(0, 1), Vector2(TILE, 1)), Color(0.6, 0.8, 1.0, shine))


func _draw() -> void:
	var theme: Dictionary = level.theme
	var tileset: Texture2D = level.tileset
	var solid: Dictionary = level.solid
	var pits := _pit_cells(solid)
	_draw_pit_walls(theme, tileset, solid, pits)
	if theme.get("wang_platform", false):
		_draw_wang_platform(tileset, solid)
	elif theme.get("autotile", false):
		_draw_autotile(theme, tileset, solid, pits)
	else:
		_draw_blocks(theme, tileset, solid, pits)

	_draw_lava(theme)
	_draw_water(theme)
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
		var cell_x := int(h.position.x) / TILE
		draw_texture_rect_region(SPIKES_TEX, Rect2(cell_x * TILE, h.end.y - TILE, TILE, TILE), Rect2((cell_x % 2) * TILE, 0, TILE, TILE))


## Tileset de Pedravelha gerado no PixelLab; bordas preservam a grade de colisão de 16 px.
func _draw_wang_platform(tileset: Texture2D, solid: Dictionary) -> void:
	# PixelLab: peças Wang 4x4. Índice: NW, NE, SW, SE (1 = pedra).
	const PIECES := [Vector2i(0, 3), Vector2i(3, 3), Vector2i(0, 2), Vector2i(1, 2),
		Vector2i(0, 0), Vector2i(3, 2), Vector2i(2, 3), Vector2i(2, 2),
		Vector2i(1, 3), Vector2i(0, 1), Vector2i(1, 0), Vector2i(3, 1),
		Vector2i(3, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(2, 1)]
	for cell: Vector2i in solid:
		var up := solid.has(cell + Vector2i.UP)
		var down := solid.has(cell + Vector2i.DOWN)
		var left := solid.has(cell + Vector2i.LEFT)
		var right := solid.has(cell + Vector2i.RIGHT)
		var mask := int(up and left) + 2 * int(up and right) + 4 * int(down and left) + 8 * int(down and right)
		var dest := Rect2(Vector2(cell * TILE), Vector2(TILE, TILE))
		if not up:
			# O Wang de topo tem 8 px de ar: alinhar a pedra à linha de colisão.
			draw_texture_rect_region(tileset, dest, Rect2(32, 16, TILE, TILE))
			dest.position.y -= 8
			draw_texture_rect_region(tileset, dest, Rect2(48, 0, TILE, TILE))
		else:
			draw_texture_rect_region(tileset, dest, Rect2(Vector2(PIECES[mask] * TILE), Vector2(TILE, TILE)))


## Tilesets dos pacotes: blocos de chão em colunas e cor sólida abaixo de "rows" tiles.
func _draw_blocks(theme: Dictionary, tileset: Texture2D, solid: Dictionary, pits: Dictionary) -> void:
	var blocks: Array = theme["blocks"]
	var block_w: int = theme["block_w"]
	var rows: int = theme["rows"]
	var top: int = theme["top"]
	for cell: Vector2i in solid:
		var dest := Rect2(cell.x * TILE, cell.y * TILE, TILE, TILE)
		# Profundidade = quantos blocos sólidos existem acima até chegar no ar. O fundo de um poço
		# de espinhos já começa como terra (sem uma faixa de grama solta embaixo das pontas).
		var depth := 0
		if pits.has(cell + Vector2i.UP):
			depth = 1
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
func _draw_autotile(theme: Dictionary, tileset: Texture2D, solid: Dictionary, pits: Dictionary) -> void:
	var top_variants: Array = theme.get("top_variants", [])
	var fill_variants: Array = theme.get("fill_variants", [])
	for cell: Vector2i in solid:
		var up := not solid.has(cell + Vector2i.UP) and not pits.has(cell + Vector2i.UP)
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


## Espinhos e lava no fundo de poços (com chão dos dois lados). Espinhos em cima de plataformas ficam de fora.
func _pit_cells(solid: Dictionary) -> Dictionary:
	var cells := {}
	for h: Rect2 in level.hazards:
		var cell := Vector2i(int(h.position.x) / TILE, int(h.position.y) / TILE)
		if _walled(solid, cell):
			cells[cell] = true
	return cells


## Fundo dos poços de espinhos: a terra do chão continua atrás do buraco, mais escura (recuada),
## em vez de o fundo da sala aparecer como um retângulo liso embaixo das árvores e do mato.
## Sobe de cada espinho enquanto houver chão dos dois lados (até PIT_REACH tiles de distância).
func _draw_pit_walls(theme: Dictionary, tileset: Texture2D, solid: Dictionary, pits: Dictionary) -> void:
	var tint: Color = theme.get("tint", Color.WHITE) * PIT_SHADE
	for pit: Vector2i in pits:
		var cell := pit
		while not solid.has(cell) and _walled(solid, cell):
			var dest := Rect2(Vector2(cell * TILE), Vector2(TILE, TILE))
			if theme.get("autotile", false):
				draw_texture_rect_region(tileset, dest, Rect2(TILE, TILE, TILE, TILE), PIT_SHADE)
			else:
				var wall := _wall_beside(solid, cell)
				var depth := 0
				while depth < theme["rows"] and solid.has(wall + Vector2i(0, -(depth + 1))):
					depth += 1
				depth = maxi(depth, 1)   # sem grama na parede do fundo
				if depth < theme["rows"]:
					var blocks: Array = theme["blocks"]
					var block_w: int = theme["block_w"]
					var block: int = blocks[(cell.x / block_w) % blocks.size()]
					var src := Rect2(block + (cell.x % block_w) * TILE, theme["top"] + depth * TILE, TILE, TILE)
					draw_texture_rect_region(tileset, dest, src, tint)
				else:
					draw_rect(dest, Color(theme["rock"]) * PIT_SHADE)
			cell += Vector2i.UP


## A célula está entre chão dos dois lados (parede do poço) na mesma linha?
func _walled(solid: Dictionary, cell: Vector2i) -> bool:
	return _wall_beside(solid, cell) != cell and _wall_beside(solid, cell, 1) != cell


## Primeiro bloco sólido à esquerda (side = -1) ou à direita (side = 1); a própria célula se não houver.
func _wall_beside(solid: Dictionary, cell: Vector2i, side := -1) -> Vector2i:
	for i in range(1, PIT_REACH + 1):
		var c := cell + Vector2i(side * i, 0)
		if solid.has(c):
			return c
	return cell
