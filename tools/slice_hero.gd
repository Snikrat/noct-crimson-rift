extends SceneTree
## Recorta a esfera da magia (spell_ball) e o dragão da Ultimate.
## As animações do corpo do Noct saem de tools/remaster_hero.gd (os recortes abaixo ficam só como referência).
## Para cada quadro: limpa o fundo, alinha pelos pés e pela cabeça, reduz para o tamanho do jogo
## e salva cada animação como uma tira horizontal em assets/hero/<anim>.png.
## Também grava assets/hero/hero.json com o tamanho dos quadros e o ponto dos pés.
##
## Uso: godot --headless --path . --script tools/slice_hero.gd

const SRC := "res://art_source/personagem principal/"
const OUT := "res://assets/hero/"
const TARGET_HEIGHT := 44.0   # altura do personagem parado no jogo, em pixels

# Cada fonte: arquivo e altura do personagem parado nela (para todas ficarem na mesma escala).
const SOURCES := {
	"n1": {"file": "nivel 1.png", "idle_height": 266.0},
	"pr": {"file": "Prancha de Movimentos do Lutador Arcano.png", "idle_height": 118.0},
	"ul": {"file": "Ultimate Pixel Art_ Dragão de Energia Magenta.png", "idle_height": 198.0},
	# Animações novas, uma por imagem (geradas com o prompt_sprites.md).
	"corrida": {"file": "animacoes/corrida.png", "idle_height": 310.0},
	"idle": {"file": "animacoes/idle.png", "idle_height": 428.0},
	"agachado": {"file": "animacoes/agachado.png", "idle_height": 420.0},
	# 3 linhas: em pé acumulando poder, agachado carregando energia, e morte.
	# A linha da morte foi desenhada menor (193 px em pé) que as de cima (243 px): escala própria.
	"morte": {"file": "animacoes/morte_e_poder.png", "idle_height": 193.0},
	# Linhas de cima da mesma imagem (personagem em pé com 243 px).
	"poder": {"file": "animacoes/morte_e_poder.png", "idle_height": 243.0},
	"pulo": {"file": "animacoes/pulo.png", "idle_height": 370.0},
	"retos": {"file": "animacoes/socos_retos.png", "idle_height": 248.0},
	"diag": {"file": "animacoes/socos_diagonais.png", "idle_height": 188.0},
	"magia": {"file": "animacoes/magia_pose.png", "idle_height": 248.0},
	"projetil": {"file": "animacoes/magia_projetil.png", "idle_height": 248.0},
}

# anim: fonte, retângulos [x0, y0, x1, y1] de cada quadro, e como alinhar na horizontal
# ("head" = pela cabeça, "legs" = pelas pernas, "bbox" = pelo centro do recorte).
# Por padrão cada quadro é recortado pela silhueta; com "retangulo" no fim, pelo retângulo exato.
const ANIMS := {
	"idle": {"src": "idle", "anchor": "head", "rects": [
		[30, 150, 330, 615], [380, 150, 700, 615], [740, 150, 1060, 615],
		[1100, 150, 1440, 615], [1470, 150, 1800, 615], [1840, 150, 2160, 615]]},
	"run": {"src": "corrida", "anchor": "head", "rects": [
		[20, 225, 270, 545], [270, 225, 535, 545], [535, 225, 810, 545], [810, 225, 1066, 545],
		[1066, 225, 1350, 545], [1350, 225, 1600, 545], [1600, 225, 1872, 545], [1872, 225, 2160, 545]]},
	# Pulo: impulso (quadro 1, guardado), subida e topo (2-3), início da queda e queda (4-5).
	"jump": {"src": "pulo", "anchor": "head", "rects": [[285, 60, 565, 600], [570, 10, 830, 600]]},
	"fall": {"src": "pulo", "anchor": "head", "rects": [[830, 60, 1100, 600], [1100, 100, 1360, 600]]},
	# Aterrissagem: 1º quadro do pulo (agachado, com o estouro de energia sob os pés).
	"land": {"src": "pulo", "anchor": "legs", "rects": [[10, 150, 285, 600]]},
	# Socos retos: jab (quadros 1-4) e direto forte (5-8).
	"jab": {"src": "retos", "anchor": "legs", "rects": [
		[20, 200, 205, 560], [205, 200, 490, 560], [480, 200, 815, 560], [805, 200, 1050, 560]]},
	"cross": {"src": "retos", "anchor": "legs", "rects": [
		[1045, 200, 1330, 560], [1310, 200, 1625, 560], [1575, 200, 1965, 560], [1965, 200, 2165, 560]]},
	# Socos diagonais: linha 1 sobe na diagonal, linha 3 desce até o chão.
	"up_punch": {"src": "diag", "scale": 0.20, "anchor": "legs", "rects": [
		[20, 5, 195, 318], [200, 5, 425, 318], [425, 5, 700, 318], [680, 5, 1000, 318],
		[965, 5, 1262, 318], [1235, 5, 1530, 318], [1500, 5, 1725, 318], [1715, 5, 1900, 318]]},
	"low_punch": {"src": "diag", "anchor": "legs", "rects": [
		[15, 600, 190, 821], [200, 600, 448, 821], [448, 600, 712, 821],
		[712, 600, 995, 821, "retangulo"], [995, 600, 1268, 821, "retangulo"],
		[1468, 600, 1712, 821], [1708, 600, 1900, 821]]},
	# Pose da magia: concentra a esfera e solta.
	"cast": {"src": "magia", "anchor": "legs", "rects": [
		[15, 200, 210, 560], [212, 200, 475, 560], [485, 200, 755, 560], [765, 200, 1048, 560],
		[1045, 200, 1352, 560], [1348, 200, 1578, 560], [1572, 200, 1918, 560], [1935, 200, 2165, 560]]},
	# Projétil da magia: surge (1-3), voa (4-6), se desfaz (7-8). Alinhado pelo centro.
	"spell_ball": {"src": "projetil", "anchor": "bbox", "pivot": "center", "scale": 0.12, "rects": [
		[30, 240, 185, 510], [210, 240, 430, 510], [440, 240, 730, 510], [740, 240, 1065, 510],
		[1070, 240, 1455, 510], [1452, 240, 1795, 510], [1788, 240, 1958, 510], [1980, 240, 2150, 510]]},
	# --- Prancha de Movimentos ---
	"crouch": {"src": "agachado", "anchor": "legs", "rects": [
		[20, 240, 280, 585], [282, 240, 545, 585], [545, 240, 812, 585], [812, 240, 1110, 585]]},
	"hurt": {"src": "pr", "anchor": "head", "rects": [
		[345, 207, 420, 312], [433, 207, 510, 312], [511, 207, 588, 312]]},
	"death": {"src": "morte", "anchor": "legs", "rects": [
		[20, 520, 200, 730], [205, 520, 440, 730], [445, 520, 690, 730], [700, 520, 950, 730],
		[955, 520, 1210, 730], [1215, 520, 1510, 730], [1515, 520, 1815, 730], [1820, 520, 2150, 730]]},
	"dash": {"src": "pr", "anchor": "head", "rects": [[30, 662, 125, 745], [158, 662, 257, 745]]},
	"double_jump": {"src": "pr", "anchor": "head", "rects": [
		[772, 656, 822, 746], [824, 656, 885, 746], [893, 650, 970, 746], [979, 636, 1046, 746]]},
	"kick": {"src": "pr", "anchor": "head", "rects": [
		[1120, 352, 1225, 470], [1225, 352, 1312, 470], [1314, 352, 1416, 470], [1414, 352, 1524, 470]]},
	# O último quadro junta o soco e a explosão (na prancha eles estão separados).
	"charged": {"src": "pr", "anchor": "legs", "rects": [
		[10, 522, 82, 615], [82, 522, 154, 615], [155, 522, 237, 615], [237, 522, 430, 615]]},
	"uppercut": {"src": "diag", "scale": 0.20, "anchor": "legs", "rects": [
		[20, 300, 195, 610], [200, 300, 445, 610], [460, 300, 722, 610], [722, 300, 985, 610],
		[1000, 300, 1235, 610], [1260, 300, 1495, 610], [1478, 300, 1718, 610], [1700, 300, 1900, 610]]},
	"slam": {"src": "pr", "anchor": "legs", "rects": [[640, 822, 742, 900], [822, 822, 908, 968, "retangulo"]]},
	# --- Ultimate ---
	# Ultimate em 3 partes: 1) em pé acumulando poder, 2) agachado carregando a esfera até a
	# explosão de aura, 3) a pose original da Ultimate, que solta o dragão.
	"ultimate_charge": {"src": "poder", "anchor": "legs", "rects": [
		[120, 5, 338, 295], [342, 5, 565, 295], [570, 5, 795, 295], [798, 5, 1030, 295],
		[1032, 5, 1268, 295], [1270, 5, 1508, 295], [1510, 5, 1750, 295], [1755, 5, 1995, 295]]},
	"ultimate_burst": {"src": "poder", "anchor": "legs", "rects": [
		[10, 285, 232, 522], [234, 285, 506, 522], [508, 285, 788, 522], [790, 285, 1046, 522],
		[1048, 285, 1312, 522], [1314, 285, 1602, 522], [1604, 285, 1892, 522], [1894, 285, 2150, 522]]},
	"ultimate_pose": {"src": "ul", "anchor": "head", "rects": [
		[20, 70, 115, 280], [110, 70, 205, 280], [200, 70, 290, 280], [285, 70, 385, 280]]},
	"dragon": {"src": "ul", "anchor": "bbox", "scale": 0.32, "key_dark": 0.32, "rects": [[420, 515, 1250, 755]]},
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var images := {}
	for key in SOURCES:
		images[key] = Image.load_from_file(ProjectSettings.globalize_path(SRC + SOURCES[key]["file"]))
		images[key].convert(Image.FORMAT_RGBA8)
	# O corpo do Noct (todas as animações) é gerado por tools/remaster_hero.gd.
	# Aqui só saem a esfera da magia e o dragão da Ultimate, que não são o personagem.
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "hero.json"))
	for anim in ["spell_ball", "dragon"]:
		var spec: Dictionary = ANIMS[anim]
		var src: Image = images[spec["src"]]
		var scale: float = spec.get("scale", TARGET_HEIGHT / SOURCES[spec["src"]]["idle_height"])
		meta[anim] = _slice(anim, src, spec, scale)
		print("%s: %d quadros %dx%d pés em (%d, %d)" % [anim, meta[anim]["frames"], meta[anim]["w"], meta[anim]["h"], meta[anim]["ax"], meta[anim]["ay"]])
	var f := FileAccess.open(OUT + "hero.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "\t"))
	f.close()
	quit()


func _slice(anim: String, src: Image, spec: Dictionary, scale: float) -> Dictionary:
	var frames := []
	var left := 0
	var right := 0
	var top := 0
	var bottom := 0
	var center_pivot: bool = spec.get("pivot", "feet") == "center"
	for r in spec["rects"]:
		var region: Image
		# "retangulo" no fim do quadro = recorte simples (quando a silhueta não separa bem).
		if spec.has("key_dark") or r.size() > 4:
			region = src.get_region(Rect2i(r[0], r[1], r[2] - r[0], r[3] - r[1]))
			_clean_alpha(region)
			if spec.has("key_dark"):
				_key_dark(region, spec["key_dark"])
		else:
			region = _extract(src, Rect2i(r[0], r[1], r[2] - r[0], r[3] - r[1]))
		var used := region.get_used_rect()
		if used.size.x == 0:
			continue
		# Ponto de apoio vertical: os pés (base do desenho) ou o centro (projéteis).
		var feet_y := used.position.y + used.size.y / 2 if center_pivot else used.end.y
		var ax := _anchor_x(region, used, spec["anchor"])
		left = maxi(left, ax - used.position.x)
		right = maxi(right, used.end.x - ax)
		top = maxi(top, feet_y - used.position.y)
		bottom = maxi(bottom, used.end.y - feet_y)
		frames.append({"img": region, "used": used, "ax": ax, "feet": feet_y})

	# Monta todos os quadros numa tela comum, alinhados pelos pés/âncora, ainda no tamanho original.
	var cw := left + right
	var ch := top + bottom
	var fw := maxi(1, int(round(cw * scale)))
	var fh := maxi(1, int(round(ch * scale)))
	var strip := Image.create(fw * frames.size(), fh, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		var fr: Dictionary = frames[i]
		var canvas := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
		var used: Rect2i = fr["used"]
		var dst := Vector2i(left - (fr["ax"] - used.position.x), top - (fr["feet"] - used.position.y))
		canvas.blit_rect(fr["img"], used, dst)
		canvas.resize(fw, fh, Image.INTERPOLATE_LANCZOS)
		_clean_alpha(canvas, 50)
		strip.blit_rect(canvas, Rect2i(0, 0, fw, fh), Vector2i(i * fw, 0))
	strip.save_png(ProjectSettings.globalize_path(OUT + anim + ".png"))
	return {"frames": frames.size(), "w": fw, "h": fh, "ax": int(round(left * scale)), "ay": int(round(top * scale)) - 1}


## Recorta um quadro pela silhueta, não pelo retângulo.
## Olha uma área um pouco maior que o retângulo, separa os pedaços de pixels conectados
## e fica só com os pedaços cujo centro está dentro do retângulo: assim o pé do quadro
## vizinho que invade a área fica de fora, e o braço deste quadro que sai da área entra.
func _extract(src: Image, rect: Rect2i) -> Image:
	var margin := Vector2i(int(rect.size.x * 0.35), int(rect.size.y * 0.12))
	var search := rect.grow_individual(margin.x, margin.y, margin.x, margin.y).intersection(Rect2i(Vector2i.ZERO, src.get_size()))
	var img := src.get_region(search)
	var w := img.get_width()
	var h := img.get_height()
	var inner := Rect2i(rect.position - search.position, rect.size)

	# 1) Rotula os pedaços de pixels "fortes" (8 vizinhos).
	var label := PackedInt32Array()
	label.resize(w * h)
	label.fill(-1)
	var keep := {}
	var next_id := 0
	for y in h:
		for x in w:
			if label[y * w + x] != -1 or img.get_pixel(x, y).a8 < STRONG:
				continue
			var stack := [Vector2i(x, y)]
			label[y * w + x] = next_id
			var sum := Vector2.ZERO
			var n := 0
			while not stack.is_empty():
				var p: Vector2i = stack.pop_back()
				sum += Vector2(p)
				n += 1
				for dy in [-1, 0, 1]:
					for dx in [-1, 0, 1]:
						var q := p + Vector2i(dx, dy)
						if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or label[q.y * w + q.x] != -1:
							continue
						if img.get_pixel(q.x, q.y).a8 >= STRONG:
							label[q.y * w + q.x] = next_id
							stack.append(q)
			var c := sum / n
			if inner.has_point(Vector2i(c)):
				keep[next_id] = true
			next_id += 1

	# 2) Monta o resultado: pixels fortes dos pedaços mantidos + bordas suaves coladas neles.
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var col := img.get_pixel(x, y)
			if col.a8 < 40:
				continue
			var id := label[y * w + x]
			if id != -1:
				if keep.has(id):
					out.set_pixel(x, y, col)
			elif _near_kept(label, keep, w, h, x, y, 2):
				out.set_pixel(x, y, col)
	return out


const STRONG := 150


func _near_kept(label: PackedInt32Array, keep: Dictionary, w: int, h: int, x: int, y: int, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var qx := x + dx
			var qy := y + dy
			if qx >= 0 and qy >= 0 and qx < w and qy < h and keep.has(label[qy * w + qx]):
				return true
	return false


## Zera o alfa dos pixels quase transparentes (o "fundo" das pranchas).
func _clean_alpha(img: Image, threshold := 40) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a8 < threshold:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


## Apaga o fundo escuro (pixels pouco brilhantes) - usado no dragão, que vem com o fundo do painel.
## O brilho vira transparência suave para a energia não ficar com borda dura.
func _key_dark(img: Image, limit: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			var v := maxf(c.r, maxf(c.g, c.b))
			if v < limit:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif v < limit + 0.25:
				c.a *= (v - limit) / 0.25
				img.set_pixel(x, y, c)


## Coluna de referência horizontal do quadro (mediana dos pixels da cabeça ou das pernas).
func _anchor_x(img: Image, used: Rect2i, mode: String) -> int:
	if mode == "bbox":
		return used.position.x + used.size.x / 2
	var y0: int
	var y1: int
	if mode == "head":
		y0 = used.position.y
		y1 = used.position.y + int(used.size.y * 0.22)
	else:
		y0 = used.position.y + int(used.size.y * 0.7)
		y1 = used.end.y
	var xs := []
	for y in range(y0, y1):
		for x in range(used.position.x, used.end.x):
			if img.get_pixel(x, y).a8 >= 160:
				xs.append(x)
	if xs.is_empty():
		return used.position.x + used.size.x / 2
	xs.sort()
	return xs[xs.size() / 2]
