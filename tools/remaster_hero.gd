extends SceneTree
## Remasterização técnica de TODAS as animações do Noct (base e formas carmesim).
## Não redesenha nada: recorta de novo as pranchas originais em alta resolução e só padroniza.
##
## 1. Escala: cada prancha tem um fator próprio (px do jogo por px da prancha) medido para o corpo
##    ficar do mesmo tamanho do Idle (44 px em pé) em todas as animações.
## 2. Recorte pela silhueta (pedaços conectados), com folga: nada é cortado na borda e nada do
##    quadro vizinho entra.
## 3. Redução por média de área (sem Lanczos/blur), alfa binário (sem semitransparência) e uma
##    paleta única para todas as animações.
## 4. Todas as animações usam o MESMO tamanho de quadro e o MESMO ponto de origem (centro do corpo
##    na horizontal, pés na vertical), com margem transparente em volta.
##
## Saída: assets/hero/<anim>.png, assets/hero/crimson/c<n>_<anim>.png, hero.json, crimson.json
## e assets/hero/noct_atlas.png (uma linha por animação) + noct_atlas.json.
## Uso: godot --headless --path . --script tools/remaster_hero.gd

const SRC := "res://art_source/personagem principal/"
const OUT := "res://assets/hero/"
const CRIMSON_OUT := "res://assets/hero/crimson/"
const MARGIN := 3            # pixels transparentes em volta do maior desenho
const PALETTE_SIZE := 64
const HITBOX_CENTER := 20    # o centro do corpo no ar fica 20 px acima dos pés (hitbox de 40 px)

# Fonte -> arquivo e escala.
# "h" = altura em px de fonte que corresponde aos 44 px do Idle (escala = 44 / h).
const SOURCES := {
	"idle": {"file": "animacoes/idle.png", "h": 423.0},
	"corrida": {"file": "animacoes/corrida.png", "h": 310.0},
	"agachado": {"file": "animacoes/agachado.png", "h": 420.0},
	"morte": {"file": "animacoes/morte_e_poder.png", "h": 193.0},
	"poder": {"file": "animacoes/morte_e_poder.png", "h": 243.0},
	"pulo": {"file": "animacoes/pulo.png", "h": 370.0},
	"retos": {"file": "animacoes/socos_retos.png", "h": 264.0},
	"diag": {"file": "animacoes/socos_diagonais.png", "h": 211.0},
	"magia": {"file": "animacoes/magia_pose.png", "h": 264.0},
	# A prancha de movimentos tem um brilho de fundo semitransparente que liga os bonecos:
	# só pixels quase opacos contam ("weak").
	"pr": {"file": "Prancha de Movimentos do Lutador Arcano.png", "h": 110.0, "weak": 160},
	"ul": {"file": "Ultimate Pixel Art_ Dragão de Energia Magenta.png", "h": 158.0},
	"aereo": {"file": "animacoes/combo_aereo.png", "h": 275.0},
	"dash": {"file": "animacoes/dash.png", "h": 231.6},
	"pulo_duplo": {"file": "animacoes/pulo_duplo.png", "h": 200.0},
	"carmesim": {"file": "carmesim/niveis_carmesim.png", "h": 0.0, "weak": 160},   # escala medida por nível (ver _crimson)
}

# anim: fonte, quadros [x0, y0, x1, y1] (+ opcional âncora manual x, y em px da fonte),
# e alinhamento: "legs"/"head" = pés no chão, coluna pela mediana das pernas/cabeça;
# "center" = pés no chão, coluna pelo centro de massa do corpo;
# "air" = no ar, alinhado pelo centro do corpo.
const ANIMS := {
	"idle": {"src": "idle", "anchor": "head", "rects": [
		[30, 150, 330, 615], [380, 150, 700, 615], [740, 150, 1060, 615],
		[1100, 150, 1440, 615], [1470, 150, 1800, 615], [1840, 150, 2160, 615]]},
	"run": {"src": "corrida", "anchor": "head", "rects": [
		[20, 225, 270, 545], [270, 225, 535, 545], [535, 225, 810, 545], [810, 225, 1066, 545],
		[1066, 225, 1350, 545], [1350, 225, 1600, 545], [1600, 225, 1872, 545], [1872, 225, 2160, 545]]},
	"jump": {"src": "pulo", "anchor": "air", "rects": [[285, 60, 565, 600], [570, 10, 830, 600]]},
	"fall": {"src": "pulo", "anchor": "air", "rects": [[830, 60, 1100, 600], [1100, 100, 1360, 600]]},
	"land": {"src": "pulo", "anchor": "legs", "rects": [[10, 150, 285, 600]]},
	"jab": {"src": "retos", "anchor": "legs", "rects": [
		[20, 200, 205, 560], [205, 200, 490, 560], [480, 200, 815, 560], [805, 200, 1050, 560]]},
	"cross": {"src": "retos", "anchor": "legs", "rects": [
		[1045, 200, 1330, 560], [1310, 200, 1625, 560], [1575, 200, 1965, 560], [1965, 200, 2165, 560]]},
	"up_punch": {"src": "diag", "anchor": "legs", "rects": [
		[20, 5, 195, 318], [200, 5, 425, 318], [425, 5, 700, 318], [680, 5, 1000, 318],
		[965, 5, 1262, 318], [1235, 5, 1530, 318], [1500, 5, 1725, 318], [1715, 5, 1900, 318]]},
	"uppercut": {"src": "diag", "anchor": "legs", "rects": [
		[20, 300, 195, 610], [200, 300, 445, 610], [460, 300, 722, 610], [722, 300, 985, 610],
		[1000, 300, 1235, 610], [1260, 300, 1495, 610], [1478, 300, 1718, 610], [1700, 300, 1900, 610]]},
	"low_punch": {"src": "diag", "anchor": "legs", "rects": [
		[15, 600, 190, 821], [200, 600, 448, 821], [448, 600, 712, 821],
		[712, 600, 995, 821, "clip"], [995, 600, 1440, 821, "clip"],
		[1468, 600, 1712, 821], [1708, 600, 1900, 821]]},
	"cast": {"src": "magia", "anchor": "legs", "rects": [
		[15, 200, 210, 560], [212, 200, 475, 560], [485, 200, 755, 560], [765, 200, 1048, 560],
		[1045, 200, 1352, 560], [1348, 200, 1578, 560], [1572, 200, 1918, 560], [1935, 200, 2165, 560]]},
	"crouch": {"src": "agachado", "anchor": "legs", "rects": [
		[20, 240, 280, 585], [282, 240, 545, 585], [545, 240, 812, 585], [812, 240, 1110, 585]]},
	"hurt": {"src": "pr", "anchor": "legs", "rects": [
		[345, 207, 420, 312], [433, 207, 510, 312], [511, 207, 588, 312]]},
	"death": {"src": "morte", "anchor": "legs", "rects": [
		[20, 520, 200, 730], [205, 520, 440, 730], [445, 520, 690, 730], [700, 520, 950, 730],
		[955, 520, 1210, 730], [1215, 520, 1510, 730], [1515, 520, 1815, 730], [1820, 520, 2150, 730]]},
	"kick": {"src": "pr", "anchor": "legs", "rects": [
		[1120, 352, 1225, 470], [1225, 352, 1312, 470], [1314, 352, 1416, 470], [1414, 352, 1524, 470]]},
	"charged": {"src": "pr", "anchor": "legs", "rects": [
		[10, 522, 82, 615], [82, 522, 154, 615], [155, 522, 237, 615], [237, 522, 430, 615]]},
	"slam": {"src": "pr", "anchor": "legs", "rects": [[640, 822, 742, 900], [822, 822, 908, 968]]},
	"ultimate_charge": {"src": "poder", "anchor": "legs", "rects": [
		[120, 5, 338, 295], [342, 5, 565, 295], [570, 5, 795, 295], [798, 5, 1030, 295],
		[1032, 5, 1268, 295], [1270, 5, 1508, 295], [1510, 5, 1750, 295], [1755, 5, 1995, 295]]},
	"ultimate_burst": {"src": "poder", "anchor": "legs", "rects": [
		[10, 285, 232, 522], [234, 285, 506, 522], [508, 285, 788, 522], [790, 285, 1046, 522],
		[1048, 285, 1312, 522], [1314, 285, 1602, 522], [1604, 285, 1892, 522], [1894, 285, 2150, 522]]},
	"ultimate_pose": {"src": "ul", "anchor": "legs", "rects": [
		[20, 70, 115, 280], [110, 70, 205, 280], [200, 70, 290, 280], [285, 70, 385, 280]]},
	# Combo aéreo: âncoras do corpo medidas na prancha (tools/slice_air_combo.gd).
	"air_punch": {"src": "aereo", "anchor": "air", "rects": [
		[0, 225, 220, 550, 150, 510], [220, 225, 525, 550, 355, 510], [525, 225, 790, 550, 655, 510]]},
	"air_kick": {"src": "aereo", "anchor": "air", "rects": [
		[790, 225, 1100, 550, 935, 510], [1100, 225, 1450, 550, 1200, 510]]},
	"air_finish": {"src": "aereo", "anchor": "air", "rects": [
		[1450, 225, 1730, 550, 1600, 510], [1730, 225, 1935, 550, 1840, 510], [1935, 225, 2172, 550, 2100, 510]]},
	# Dash: pés no chão; o rastro fica atrás (tools/slice_dash.gd).
	"dash": {"src": "dash", "anchor": "center", "rects": [
		[0, 290, 210, 520], [210, 290, 440, 520], [440, 290, 690, 520], [690, 290, 1000, 520],
		[1000, 290, 1390, 520], [1390, 290, 1680, 520], [1680, 290, 1930, 520], [1930, 290, 2172, 520]]},
	"double_jump": {"src": "pulo_duplo", "anchor": "air", "rects": [
		[0, 340, 210, 620], [210, 340, 365, 620], [365, 340, 565, 620], [565, 340, 745, 620],
		[745, 340, 945, 620], [945, 340, 1110, 620], [1110, 340, 1275, 620], [1275, 340, 1450, 620],
		[1450, 340, 1672, 620]]},
}

# Formas carmesim: mesma divisão da prancha usada em tools/slice_crimson.gd.
const CRIMSON_COLUMNS := {
	"idle": [20, 322], "run": [326, 676], "jump": [690, 982], "double_jump": [690, 982],
	"dash": [982, 1282], "crouch": [1284, 1536],
}
const CRIMSON_ANCHOR := {"idle": "head", "run": "head", "jump": "air", "double_jump": "air", "dash": "center", "crouch": "legs"}
const CRIMSON_BY_BODY := ["double_jump", "crouch"]
# Dash: os rastros encostam um boneco no outro. Faixas x de cada boneco medidas na prancha
# (uma lista por nível); as faixas se sobrepõem um pouco e os pedaços do vizinho que encostam
# na borda saem (ver _clip).
const CRIMSON_CUTS := {"dash": [
	[[982, 1096], [1088, 1190], [1180, 1290]],
	[[982, 1114], [1100, 1214], [1200, 1295]],
	[[982, 1134], [1118, 1218], [1212, 1310]]]}
const CRIMSON_LEVELS := [
	{"ground": [160, 297, 298, 318], "jump": [52, 154, 155, 172], "double_jump": [206, 304, 305, 324],
	 "dash": [160, 300, 300, 324], "crouch": [160, 300, 300, 324]},
	{"ground": [476, 628, 629, 648], "jump": [374, 481, 481, 498], "double_jump": [530, 632, 633, 654],
	 "dash": [476, 632, 633, 654], "crouch": [476, 632, 633, 654]},
	{"ground": [800, 972, 973, 992], "jump": [706, 814, 815, 832], "double_jump": [860, 980, 981, 1000],
	 "dash": [800, 980, 981, 1000], "crouch": [800, 980, 981, 1000]},
]

var images := {}
# Cada quadro reduzido: {"img": Image (RGBA, alfa ainda suave), "pivot": Vector2 (ponto de origem no img)}
var anims := {}            # nome -> Array de quadros
var order := []            # ordem das linhas no atlas


func _initialize() -> void:
	var t0 := Time.get_ticks_msec()
	for key in SOURCES:
		var img := Image.load_from_file(ProjectSettings.globalize_path(SRC + SOURCES[key]["file"]))
		img.convert(Image.FORMAT_RGBA8)
		images[key] = img
	for anim in ANIMS:
		var spec: Dictionary = ANIMS[anim]
		var scale: float = 44.0 / SOURCES[spec["src"]]["h"] * float(spec.get("fix", 1.0))
		var frames := []
		var weak: int = SOURCES[spec["src"]].get("weak", WEAK)
		for r in spec["rects"]:
			var rect := Rect2i(r[0], r[1], r[2] - r[0], r[3] - r[1])
			var manual = Vector2(r[4], r[5]) if r.size() > 5 else null
			var clip: bool = r.size() == 5 and r[4] == "clip"
			frames.append(_frame(images[spec["src"]], rect, spec["anchor"], scale, manual, clip, weak))
		anims[anim] = frames
		order.append(anim)
		print("%s: %d quadros (escala %.4f)" % [anim, frames.size(), scale])
	_crimson()
	_finish()
	print("pronto em %.1f s" % ((Time.get_ticks_msec() - t0) / 1000.0))
	quit()


# --- Recorte de um quadro ------------------------------------------------

## Recorta, reduz e calcula o ponto de origem (pés ou centro do corpo) de um quadro.
func _frame(src: Image, rect: Rect2i, anchor: String, scale: float, manual, clip := false, weak := WEAK, limit_y := -1) -> Dictionary:
	var region := _clip(src, rect, weak) if clip else _extract(src, rect, weak)
	var img: Image = region["img"]
	if limit_y >= 0:
		var cut: int = limit_y - region["origin"].y
		if cut < img.get_height():
			img.fill_rect(Rect2i(0, maxi(0, cut), img.get_width(), img.get_height()), Color(0, 0, 0, 0))
	var used := img.get_used_rect()
	var info := _body_info(img)
	var body: Rect2i = info["rect"]
	var pivot: Vector2
	if manual != null:
		pivot = Vector2(manual) - Vector2(region["origin"])
		pivot.y = info["center"].y if anchor == "air" else float(body.end.y)
	elif anchor == "air":
		pivot = info["center"]
	elif anchor == "center":
		pivot = Vector2(info["center"].x, body.end.y)   # corpo inclinado (dash): centro de massa
	else:
		pivot = Vector2(_anchor_x(info, anchor), body.end.y)
	# Recorta só a área usada (com 1 px de folga) antes de reduzir.
	var crop := img.get_region(used.grow(1).intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	var crop_pos := Vector2(used.grow(1).intersection(Rect2i(Vector2i.ZERO, img.get_size())).position)
	var small := _downscale(crop, crop_pos, scale)
	var p: Vector2 = (pivot - crop_pos) * scale + small["shift"]
	if anchor == "air":
		p.y += HITBOX_CENTER   # o centro do corpo fica 20 px acima da linha dos pés
	return {"img": small["img"], "pivot": p}


## Recorta um quadro pela silhueta: a prancha inteira é separada em pedaços conectados
## (uma vez por prancha) e o quadro fica com os pedaços cujo centro está dentro do retângulo.
## Assim um braço ou efeito que sai do retângulo entra inteiro, e o pé do quadro vizinho,
## os números e os títulos da prancha ficam de fora.
## Os pedaços são separados numa grade de blocos de 3x3 px (rápido e sem perder detalhe).
func _extract(src: Image, rect: Rect2i, weak := WEAK) -> Dictionary:
	var lab := _labels(src, weak)
	var bw: int = lab["bw"]
	var comps: Array = lab["comps"]
	var label: PackedInt32Array = lab["label"]
	# Pedaço normal: entra inteiro se o centro está no retângulo.
	# Pedaço "ponte" (mais largo que o quadro, ligando bonecos vizinhos pela energia ou pelo chão):
	# entra só a parte dentro do retângulo (keep = 2).
	var keep := {}
	var area := Rect2i()
	var rectf := Rect2(rect)
	for id in comps.size():
		var c: Dictionary = comps[id]
		if not c["strong"]:
			continue
		var box: Rect2i = c["box"]
		var part := Rect2i()
		if box.size.x > rect.size.x * 1.3 or box.size.y > rect.size.y * 1.3:
			part = box.intersection(rect)
			if part.size.x <= 0:
				continue
			keep[id] = 2
		elif rectf.has_point(c["center"]):
			part = box
			keep[id] = 1
		else:
			continue
		area = part if area.size == Vector2i.ZERO else area.merge(part)
	if keep.is_empty():
		return {"img": Image.create(1, 1, false, Image.FORMAT_RGBA8), "origin": rect.position}
	area = area.intersection(Rect2i(Vector2i.ZERO, src.get_size()))
	var data := src.get_data()
	var sw := src.get_width()
	var out := PackedByteArray()
	out.resize(area.size.x * area.size.y * 4)
	for y in area.size.y:
		var gy := area.position.y + y
		var row := (gy / BLOCK) * bw
		for x in area.size.x:
			var gx := area.position.x + x
			var id := label[row + gx / BLOCK]
			if id != -1 and keep.has(id) and (keep[id] == 1 or rect.has_point(Vector2i(gx, gy))):
				var i := (gy * sw + gx) * 4
				if data[i + 3] >= weak:
					var o := (y * area.size.x + x) * 4
					out[o] = data[i]
					out[o + 1] = data[i + 1]
					out[o + 2] = data[i + 2]
					out[o + 3] = data[i + 3]
	return {"img": Image.create_from_data(area.size.x, area.size.y, false, Image.FORMAT_RGBA8, out), "origin": area.position}


var _label_cache := {}


## Pedaços conectados de uma prancha inteira (blocos de 3x3 px com alfa >= weak).
func _labels(src: Image, weak: int) -> Dictionary:
	var key := "%d_%d" % [src.get_instance_id(), weak]
	if _label_cache.has(key):
		return _label_cache[key]
	var w := src.get_width()
	var h := src.get_height()
	var data := src.get_data()
	var bw := ceili(w / float(BLOCK))
	var bh := ceili(h / float(BLOCK))
	var amax := PackedByteArray()
	amax.resize(bw * bh)
	for y in h:
		var row := (y / BLOCK) * bw
		for x in w:
			var al := data[(y * w + x) * 4 + 3]
			var bi := row + x / BLOCK
			if al > amax[bi]:
				amax[bi] = al
	var label := PackedInt32Array()
	label.resize(bw * bh)
	label.fill(-1)
	var comps := []
	var stack := PackedInt32Array()
	for start in bw * bh:
		if label[start] != -1 or amax[start] < weak:
			continue
		var id := comps.size()
		label[start] = id
		stack.append(start)
		var sx := 0.0
		var sy := 0.0
		var n := 0
		var strong := false
		var sat := 0.0
		var x0 := bw
		var y0 := bh
		var x1 := 0
		var y1 := 0
		while stack.size() > 0:
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			var x := i % bw
			var y := i / bw
			sx += x
			sy += y
			n += 1
			x0 = mini(x0, x)
			y0 = mini(y0, y)
			x1 = maxi(x1, x)
			y1 = maxi(y1, y)
			if amax[i] >= STRONG:
				strong = true
			var pi := (mini(h - 1, y * BLOCK + 1) * w + mini(w - 1, x * BLOCK + 1)) * 4
			var hi := maxi(data[pi], maxi(data[pi + 1], data[pi + 2]))
			var lo := mini(data[pi], mini(data[pi + 1], data[pi + 2]))
			if hi > 70 and (hi - lo) > hi * 0.3:
				sat += 1.0   # bloco colorido (pele, energia, botas)
			for qy in range(maxi(0, y - 1), mini(bh, y + 2)):
				for qx in range(maxi(0, x - 1), mini(bw, x + 2)):
					var q := qy * bw + qx
					if label[q] == -1 and amax[q] >= weak:
						label[q] = id
						stack.append(q)
		# Etiquetas das pranchas (números "01", "02"... em caixinhas pretas): pequenas e sem cor.
		var badge := n >= 12 and n <= 120 and sat / n < 0.1 and (x1 - x0) <= 14 and (y1 - y0) <= 9
		comps.append({"strong": strong and not badge, "center": Vector2(sx / n + 0.5, sy / n + 0.5) * BLOCK,
			"box": Rect2i(x0 * BLOCK, y0 * BLOCK, (x1 - x0 + 1) * BLOCK, (y1 - y0 + 1) * BLOCK)})
	var result := {"bw": bw, "label": label, "comps": comps}
	_label_cache[key] = result
	return result


## Recorte pelo retângulo, para quadros que encostam no vizinho pela energia ou pelo chão.
## Pedaços de corpo pequenos encostados na borda esquerda/direita são do quadro vizinho e saem.
func _clip(src: Image, rect: Rect2i, weak := WEAK) -> Dictionary:
	var img := src.get_region(rect)
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	for i in w * h:
		if data[i * 4 + 3] < weak:
			data[i * 4 + 3] = 0
	# Pedaços de corpo (sem a energia), em blocos.
	var bw := ceili(w / float(BLOCK))
	var bh := ceili(h / float(BLOCK))
	var body := PackedByteArray()
	body.resize(bw * bh)
	for y in h:
		for x in w:
			var i := (y * w + x) * 4
			if _is_body_rgba(data[i], data[i + 1], data[i + 2], data[i + 3]):
				body[(y / BLOCK) * bw + x / BLOCK] = 1
	var label := PackedInt32Array()
	label.resize(bw * bh)
	label.fill(-1)
	var sizes := []
	var edge := []
	var stack := PackedInt32Array()
	for start in bw * bh:
		if label[start] != -1 or body[start] == 0:
			continue
		var id := sizes.size()
		label[start] = id
		stack.append(start)
		var n := 0
		var touches := false
		while stack.size() > 0:
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			var x := i % bw
			var y := i / bw
			n += 1
			if x == 0 or x == bw - 1:
				touches = true
			for qy in range(maxi(0, y - 1), mini(bh, y + 2)):
				for qx in range(maxi(0, x - 1), mini(bw, x + 2)):
					var q := qy * bw + qx
					if label[q] == -1 and body[q] == 1:
						label[q] = id
						stack.append(q)
		sizes.append(n)
		edge.append(touches)
	var total := 0
	for n in sizes:
		total += n
	# Apaga os pedaços do vizinho e tudo num raio de 4 blocos em volta deles (a energia deles).
	var drop := PackedByteArray()
	drop.resize(bw * bh)
	for i in bw * bh:
		var id := label[i]
		if id != -1 and edge[id] and sizes[id] < total * 0.3:
			var x := i % bw
			var y := i / bw
			for qy in range(maxi(0, y - 4), mini(bh, y + 5)):
				for qx in range(maxi(0, x - 4), mini(bw, x + 5)):
					var q := qy * bw + qx
					if label[q] == -1 or label[q] == id:
						drop[q] = 1
	for y in h:
		for x in w:
			if drop[(y / BLOCK) * bw + x / BLOCK] == 1:
				data[(y * w + x) * 4 + 3] = 0
	return {"img": Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, data), "origin": rect.position}


const BLOCK := 3
const WEAK := 24      # alfa mínimo para o pixel contar (o fundo das pranchas fica abaixo disso)
const STRONG := 150   # um pedaço só conta se tiver pixels fortes (fiapos de fundo não)


## Pixel do corpo (pele, roupa, cabelo, botas), não da energia rosa/vermelha.
static func _is_body_rgba(r: int, g: int, b: int, a: int) -> bool:
	if a < 230:
		return false
	return not (r > 140 and g < 90 and b > 46 and r > b * 1.2)


static func _is_body(c: Color) -> bool:
	return _is_body_rgba(c.r8, c.g8, c.b8, c.a8)


## Medidas do corpo (sem a energia): caixa, centro de massa e lista de colunas por linha.
func _body_info(img: Image) -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	var s := Vector2.ZERO
	var n := 0
	var rows := []
	rows.resize(h)
	for y in h:
		var xs := PackedInt32Array()
		for x in w:
			var i := (y * w + x) * 4
			if _is_body_rgba(data[i], data[i + 1], data[i + 2], data[i + 3]):
				xs.append(x)
		rows[y] = xs
		if xs.size() > 0:
			x0 = mini(x0, xs[0])
			x1 = maxi(x1, xs[xs.size() - 1])
			y0 = mini(y0, y)
			y1 = y
			for x in xs:
				s.x += x
			s.y += y * xs.size()
			n += xs.size()
	if n == 0:
		var used := img.get_used_rect()
		return {"rect": used, "center": Vector2(used.get_center()), "rows": rows}
	return {"rect": Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1), "center": s / n, "rows": rows}


## Coluna de referência: mediana dos pixels do corpo na faixa da cabeça ou das pernas.
func _anchor_x(info: Dictionary, mode: String) -> float:
	var body: Rect2i = info["rect"]
	var y0: int
	var y1: int
	if mode == "head":
		y0 = body.position.y
		y1 = body.position.y + int(body.size.y * 0.22)
	else:
		y0 = body.position.y + int(body.size.y * 0.7)
		y1 = body.end.y
	var xs := []
	for y in range(y0, y1):
		xs.append_array(Array(info["rows"][y]))
	if xs.is_empty():
		return body.get_center().x
	xs.sort()
	return xs[xs.size() / 2]


## Reduz pela média da área de cada pixel do jogo (com alfa pré-multiplicado). Sem filtros de
## suavização: cada pixel final é a média exata dos pixels da prancha que ele cobre.
## A grade é presa à origem da prancha (crop_pos), e "shift" diz quanto o desenho andou.
func _downscale(img: Image, crop_pos: Vector2, scale: float) -> Dictionary:
	var gx0 := floori(crop_pos.x * scale)
	var gy0 := floori(crop_pos.y * scale)
	var gx1 := ceili((crop_pos.x + img.get_width()) * scale)
	var gy1 := ceili((crop_pos.y + img.get_height()) * scale)
	var w := gx1 - gx0
	var h := gy1 - gy0
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var data := img.get_data()
	var iw := img.get_width()
	var ih := img.get_height()
	var inv := 1.0 / scale
	for oy in h:
		var sy0 := (gy0 + oy) * inv - crop_pos.y
		var sy1 := sy0 + inv
		for ox in w:
			var sx0 := (gx0 + ox) * inv - crop_pos.x
			var sx1 := sx0 + inv
			var r := 0.0
			var g := 0.0
			var b := 0.0
			var a := 0.0
			var area := 0.0
			for sy in range(maxi(0, floori(sy0)), mini(ih, ceili(sy1))):
				var wy := minf(sy + 1, sy1) - maxf(sy, sy0)
				for sx in range(maxi(0, floori(sx0)), mini(iw, ceili(sx1))):
					var wgt := wy * (minf(sx + 1, sx1) - maxf(sx, sx0))
					var i := (sy * iw + sx) * 4
					var al := data[i + 3] / 255.0 * wgt
					r += data[i] * al
					g += data[i + 1] * al
					b += data[i + 2] * al
					a += al
					area += wgt
			if a <= 0.0:
				continue
			out.set_pixel(ox, oy, Color(r / a / 255.0, g / a / 255.0, b / a / 255.0, a / (inv * inv)))
	# Posição do pixel (0,0) reduzido em relação ao recorte, em px do jogo.
	var shift := Vector2(gx0, gy0) - crop_pos * scale
	return {"img": out, "shift": -shift}


# --- Formas carmesim -------------------------------------------------------

func _crimson() -> void:
	var img: Image = images["carmesim"]
	for lv in CRIMSON_LEVELS.size():
		# Cada nível foi desenhado maior na prancha: a escala é medida no 1º quadro parado DESTE nível.
		var first: Rect2i = _crimson_rects(img, lv, "idle")[0]
		var weak: int = SOURCES["carmesim"]["weak"]
		var region := _extract(img, first, weak)
		var body: Rect2i = _body_info(region["img"])["rect"]
		var scale := 44.0 / body.size.y
		for anim in CRIMSON_COLUMNS:
			var frames := []
			for r in _crimson_rects(img, lv, anim):
				frames.append(_frame(img, r, CRIMSON_ANCHOR[anim], scale, null, CRIMSON_CUTS.has(anim), weak, _numbers_y(lv, anim)))
			var key := "c%d_%s" % [lv + 1, anim]
			anims[key] = frames
			order.append(key)
			print("%s: %d quadros (escala %.4f)" % [key, frames.size(), scale])


## Quadros de uma animação carmesim (mesma lógica de tools/slice_crimson.gd: números embaixo
## dos bonecos, ou colunas vazias entre os corpos).
## Linha onde começam os números ("01", "02"...) embaixo dos bonecos: nada abaixo dela entra.
func _numbers_y(lv: int, anim: String) -> int:
	return CRIMSON_LEVELS[lv].get(anim, CRIMSON_LEVELS[lv]["ground"])[2]


func _crimson_rects(img: Image, lv: int, anim: String) -> Array:
	var band: Array = CRIMSON_LEVELS[lv].get(anim, CRIMSON_LEVELS[lv]["ground"])
	var cols: Array = CRIMSON_COLUMNS[anim]
	if CRIMSON_CUTS.has(anim):
		var fixed := []
		for c in CRIMSON_CUTS[anim][lv]:
			fixed.append(Rect2i(c[0], band[0], c[1] - c[0], band[1] - band[0]))
		return fixed
	var by_body: bool = anim in CRIMSON_BY_BODY
	var y0: int = band[0] if by_body else band[2]
	var y1: int = band[1] if by_body else band[3]
	var groups := []
	var start := -1
	var last := -100
	for x in range(cols[0], cols[1]):
		var hit := false
		for y in range(y0, y1):
			var c := img.get_pixel(x, y)
			if (by_body and c.a > 0.95 and (c.r < 0.55 or c.g > 0.35)) or (not by_body and c.a > 0.9):
				hit = true
				break
		if hit:
			if x - last > (3 if by_body else 10):
				if start >= 0:
					groups.append([start, last])
				start = x
			last = x
	if start >= 0:
		groups.append([start, last])
	if by_body:
		groups = groups.filter(func(g): return g[1] - g[0] >= 18)
	var rects := []
	for i in groups.size():
		var x0: int = cols[0] if i == 0 else (groups[i - 1][1] + groups[i][0]) / 2
		var x1: int = cols[1] if i == groups.size() - 1 else (groups[i][1] + groups[i + 1][0]) / 2
		rects.append(Rect2i(x0, band[0], x1 - x0, band[1] - band[0]))
	return rects


# --- Paleta, quadro único e gravação ---------------------------------------

func _finish() -> void:
	# 1) Alfa binário: o pixel é do desenho se cobre pelo menos metade da área.
	var all_colors := PackedColorArray()
	for anim in order:
		for fr in anims[anim]:
			var img: Image = fr["img"]
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a >= 0.5:
						c.a = 1.0
						img.set_pixel(x, y, c)
						all_colors.append(c)
					elif c.a > 0.0:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
	# 2) Paleta única (corte pela mediana) e troca de cada cor pela mais próxima.
	var palette := _median_cut(all_colors, PALETTE_SIZE)
	var cache := {}
	for anim in order:
		for fr in anims[anim]:
			var img: Image = fr["img"]
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					if c.a == 0.0:
						continue
					var key := c.to_rgba32()
					if not cache.has(key):
						cache[key] = _nearest(palette, c)
					img.set_pixel(x, y, cache[key])
	_save_palette(palette)
	# 3) Mesmo quadro e mesma origem para todas as animações.
	var left := 0
	var right := 0
	var up := 0
	var down := 0
	for anim in order:
		for fr in anims[anim]:
			var img: Image = fr["img"]
			var used := img.get_used_rect()
			var p: Vector2i = Vector2i(Vector2(fr["pivot"]).round())
			fr["p"] = p
			left = maxi(left, p.x - used.position.x)
			right = maxi(right, used.end.x - p.x)
			up = maxi(up, p.y - used.position.y)
			down = maxi(down, used.end.y - p.y)
	var cell := Vector2i(left + right + MARGIN * 2, up + down + MARGIN * 2)
	var origin := Vector2i(left + MARGIN, up + MARGIN)
	# Linha dos pés = última linha do corpo; o jogo desenha com offset (-ax, -ay - 1).
	var hero_meta := {}
	var crimson_meta := {}
	var max_frames := 0
	for anim in order:
		max_frames = maxi(max_frames, anims[anim].size())
	var atlas := Image.create(cell.x * max_frames, cell.y * order.size(), false, Image.FORMAT_RGBA8)
	var atlas_meta := {"cell": [cell.x, cell.y], "origin": [origin.x, origin.y - 1], "rows": []}
	for row in order.size():
		var anim: String = order[row]
		var frames: Array = anims[anim]
		var strip := Image.create(cell.x * frames.size(), cell.y, false, Image.FORMAT_RGBA8)
		for i in frames.size():
			var fr: Dictionary = frames[i]
			var img: Image = fr["img"]
			var pos: Vector2i = Vector2i(i * cell.x, 0) + origin - fr["p"]
			strip.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), pos)
		var crimson := anim.begins_with("c") and anim[1].is_valid_int()
		var path := (CRIMSON_OUT if crimson else OUT) + anim + ".png"
		strip.save_png(ProjectSettings.globalize_path(path))
		atlas.blit_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(0, row * cell.y))
		var m := {"frames": frames.size(), "w": cell.x, "h": cell.y, "ax": origin.x, "ay": origin.y - 1}
		if crimson:
			crimson_meta[anim] = m
		else:
			hero_meta[anim] = m
		atlas_meta["rows"].append({"anim": anim, "row": row, "frames": frames.size()})
	# Projétil e dragão não são o corpo do Noct: mantêm as medidas atuais.
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUT + "hero.json"))
	for keep in ["spell_ball", "dragon"]:
		if previous.has(keep):
			hero_meta[keep] = previous[keep]
	_write_json(OUT + "hero.json", hero_meta)
	_write_json(CRIMSON_OUT + "crimson.json", crimson_meta)
	atlas.save_png(ProjectSettings.globalize_path(OUT + "noct_atlas.png"))
	_write_json(OUT + "noct_atlas.json", atlas_meta)
	print("quadro único %dx%d, origem (%d, %d), %d animações" % [cell.x, cell.y, origin.x, origin.y, order.size()])


func _write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()


func _save_palette(palette: PackedColorArray) -> void:
	var img := Image.create(palette.size(), 1, false, Image.FORMAT_RGBA8)
	for i in palette.size():
		img.set_pixel(i, 0, palette[i])
	img.save_png(ProjectSettings.globalize_path("res://art_source/personagem principal/paleta_noct.png"))


## Corte pela mediana: divide as cores na caixa de maior variação até ter n caixas.
func _median_cut(colors: PackedColorArray, n: int) -> PackedColorArray:
	var boxes := [Array(colors)]
	while boxes.size() < n:
		var best := -1
		var best_range := -1.0
		var best_axis := 0
		for bi in boxes.size():
			var box: Array = boxes[bi]
			if box.size() < 2:
				continue
			for axis in 3:
				var lo := 1.0
				var hi := 0.0
				for c in box:
					var v: float = c[axis]
					lo = minf(lo, v)
					hi = maxf(hi, v)
				var rng := (hi - lo) * sqrt(box.size())
				if rng > best_range:
					best_range = rng
					best = bi
					best_axis = axis
		if best < 0:
			break
		var box: Array = boxes[best]
		var axis := best_axis
		box.sort_custom(func(a, b): return a[axis] < b[axis])
		var mid := box.size() / 2
		boxes[best] = box.slice(0, mid)
		boxes.append(box.slice(mid))
	var out := PackedColorArray()
	for box in boxes:
		var s := Color(0, 0, 0, 0)
		for c in box:
			s += c
		out.append(Color(s.r / box.size(), s.g / box.size(), s.b / box.size(), 1.0))
	return out


func _nearest(palette: PackedColorArray, c: Color) -> Color:
	var best := palette[0]
	var bd := INF
	for p in palette:
		var dr := (p.r - c.r) * 0.30
		var dg := (p.g - c.g) * 0.59
		var db := (p.b - c.b) * 0.11
		var d := dr * dr + dg * dg + db * db
		if d < bd:
			bd = d
			best = p
	return best
