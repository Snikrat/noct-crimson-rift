extends SceneTree
## Recorta o logo animado da tela de título (art_source/logo/logo_sheet.png).
## A prancha não tem grade fixa: cada quadro tem seu retângulo em FRAMES.
## Os quadros com o logo pronto são encaixados no quadro de referência comparando as letras
## escuras de "NOCT" (busca de posição e escala), para o logo não tremer na animação.
## Os quadros só com a faísca da fenda são centrados no ponto mais brilhante, em cima do "O".
## Saída: assets/ui/logo/logo_NN.png (todos do mesmo tamanho, OUT_SIZE).
## Uso: godot --headless --path . --script tools/slice_logo.gd

const SRC := "res://art_source/logo/logo_sheet.png"
const OUT := "res://assets/ui/logo/"
const OUT_SIZE := Vector2i(560, 260)
const TEXT_CENTER := Vector2(280, 110)   # onde fica o centro de "NOCT" em cada quadro de saída
const O_OFFSET := Vector2(-8, -4)        # a fenda (o "O") em relação ao centro de "NOCT"
const REFERENCE := 10                    # quadro mais limpo, usado como molde
const FEATHER := 24                      # borda que some aos poucos (corta o brilho sem linha dura)

# [x0, y0, x1, y1] na prancha, em ordem de animação.
const FRAMES := [
	# Abertura: faíscas da fenda -> letras se formando -> logo.
	[60, 40, 258, 244], [258, 40, 450, 244], [450, 40, 666, 244], [666, 40, 876, 244],
	[876, 40, 978, 244], [978, 40, 1290, 244], [1290, 40, 1686, 244], [1686, 40, 2160, 244],
	# Logo pulsando (loop).
	[16, 244, 462, 462], [462, 244, 906, 462], [906, 244, 1338, 462], [1338, 244, 1764, 462], [1764, 244, 2160, 462],
	[16, 462, 456, 712], [456, 462, 906, 712], [906, 462, 1410, 712],
	# Saída: o logo se desfaz em faíscas (ao começar o jogo).
	[1410, 462, 2160, 712],
]

var ref_grid := {}   # pixels escuros do molde (em passos de 2px), relativos ao centro dele


func _initialize() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	img.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var infos := []
	for f in FRAMES:
		infos.append(_measure(img, _cell(f)))
	var ref: Dictionary = infos[REFERENCE]
	for p in ref["dark"]:
		var q: Vector2 = (p - ref["center"]) / 2.0
		# Molde engrossado 1 passo: tolera pequenas diferenças de desenho entre os quadros.
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				ref_grid[Vector2i(roundi(q.x) + dx, roundi(q.y) + dy)] = true

	for i in FRAMES.size():
		var cell := _cell(FRAMES[i])
		var info: Dictionary = infos[i]
		var k := 1.0
		var anchor_src: Vector2
		var anchor_dst := TEXT_CENTER
		if info.has("center"):
			var fit := _fit(info) if i != REFERENCE else [1.0, Vector2.ZERO]
			k = fit[0]
			anchor_src = info["center"]
			anchor_dst = TEXT_CENTER + fit[1]
			print("quadro %d: escala %.2f deslocamento %s" % [i, k, fit[1]])
		else:
			anchor_src = info["hot"]
			anchor_dst = TEXT_CENTER + O_OFFSET
		var part := img.get_region(cell)
		_feather(part)
		part.resize(maxi(1, int(cell.size.x * k)), maxi(1, int(cell.size.y * k)), Image.INTERPOLATE_LANCZOS)
		var out := Image.create(OUT_SIZE.x, OUT_SIZE.y, false, Image.FORMAT_RGBA8)
		var pos := Vector2i((anchor_dst - (anchor_src - Vector2(cell.position)) * k).round())
		out.blend_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), pos)
		_feather(out)
		out.save_png(ProjectSettings.globalize_path(OUT + "logo_%02d.png" % i))
	print("%d quadros do logo" % FRAMES.size())
	quit()


func _cell(f: Array) -> Rect2i:
	return Rect2i(f[0], f[1], f[2] - f[0], f[3] - f[1])


## Pixels escuros (letras de "NOCT"), o centro deles e o ponto mais brilhante do quadro.
func _measure(img: Image, cell: Rect2i) -> Dictionary:
	var dark := []
	var hot := Vector2.ZERO
	var hot_n := 0
	for y in range(cell.position.y, cell.end.y, 2):
		for x in range(cell.position.x, cell.end.x, 2):
			var c := img.get_pixel(x, y)
			if c.a > 0.9 and maxf(c.r, maxf(c.g, c.b)) < 0.1:
				dark.append(Vector2(x, y))
			elif c.a > 0.5 and c.r > 0.9 and c.g > 0.8 and c.b > 0.8:
				hot += Vector2(x, y)
				hot_n += 1
	var info := {"hot": hot / hot_n if hot_n > 0 else Vector2(cell.get_center()), "dark": dark}
	if dark.size() > 600:
		# Mediana: a fumaça escura solta em volta quase não puxa o centro.
		var xs := dark.map(func(p): return p.x)
		var ys := dark.map(func(p): return p.y)
		xs.sort()
		ys.sort()
		info["center"] = Vector2(xs[xs.size() / 2], ys[ys.size() / 2])
	return info


## Melhor escala e deslocamento (px) para as letras deste quadro caírem em cima das do molde.
func _fit(info: Dictionary) -> Array:
	var pts := []
	var dark: Array = info["dark"]
	for j in range(0, dark.size(), 3):
		pts.append((dark[j] - info["center"]) / 2.0)
	# Busca grossa, depois fina em volta do melhor resultado (deslocamento em passos de 2px).
	var best := _search(pts, 0.84, 1.16, 0.04, Vector2.ZERO, 16, 4)
	best = _search(pts, best[1] - 0.03, best[1] + 0.03, 0.01, best[2], 4, 1)
	return [best[1], best[2] * 2.0]


func _search(pts: Array, s0: float, s1: float, s_step: float, center: Vector2, radius: int, step: int) -> Array:
	var best := [-1, 1.0, Vector2.ZERO]
	var s := s0
	while s <= s1 + 0.0001:
		for dy in range(-radius, radius + 1, step):
			for dx in range(-radius, radius + 1, step):
				var off := center + Vector2(dx, dy)
				var hits := 0
				for p in pts:
					var q: Vector2 = p * s + off
					if ref_grid.has(Vector2i(roundi(q.x), roundi(q.y))):
						hits += 1
				if hits > best[0]:
					best = [hits, s, off]
		s += s_step
	return best


## Apaga aos poucos a borda da imagem.
func _feather(im: Image) -> void:
	var w := im.get_width()
	var h := im.get_height()
	for y in h:
		for x in w:
			var d := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			if d < FEATHER:
				var c := im.get_pixel(x, y)
				c.a *= float(d) / FEATHER
				im.set_pixel(x, y, c)
