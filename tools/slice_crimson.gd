extends SceneTree
## Recorta as formas carmesim de Noct (art_source/personagem principal/carmesim/niveis_carmesim.png):
## 3 níveis (Despertar, Corrupção avançada, Consumido) x 6 animações (parado, andando, pulo, pulo duplo,
## dash, abaixado). Por enquanto é só visual: troca as animações básicas, sem mudar golpes nem atributos.
##
## A prancha não tem grade fixa (ver _frames);
## o recorte vai até a metade do caminho para o vizinho e o boneco é alinhado pelos pés.
## Escala: o corpo do 1º quadro parado do nível 1 fica com a mesma altura do Noct normal.
## Saída: assets/hero/crimson/c<nível>_<animação>.png + crimson.json (quadros, w, h, ax, ay).
## Uso: godot --headless --path . --script tools/slice_crimson.gd

const SRC := "res://art_source/personagem principal/carmesim/niveis_carmesim.png"
const OUT := "res://assets/hero/crimson/"
const HERO_IDLE_HEIGHT := 44.0     # altura do quadro parado do Noct normal (hero.json)
const SOLID := 0.6                 # alfa a partir do qual o pixel é "corpo" (o resto é aura)
const BY_BODY := ["double_jump", "crouch"]
# Dash: os rastros encostam um boneco no outro; divisões medidas na prancha (iguais nos 3 níveis).
const FIXED := {"dash": [982, 1080, 1192, 1282]}   # animações separadas pelos bonecos, não pelos números

# Faixas x de cada animação na prancha (o nome é o da animação do herói que ela substitui).
const COLUMNS := {
	"idle": [20, 322], "run": [326, 676], "jump": [690, 982], "double_jump": [690, 982],
	"dash": [982, 1282], "crouch": [1284, 1536],
}
# Por nível: faixa y dos bonecos e faixa y dos números embaixo deles.
# "ground" vale para parado, andando, dash e abaixado.
const LEVELS := [
	{"ground": [160, 297, 298, 318], "jump": [52, 154, 155, 172], "double_jump": [206, 304, 305, 324],
	 "dash": [160, 300, 300, 324], "crouch": [160, 300, 300, 324]},
	{"ground": [476, 628, 629, 648], "jump": [374, 481, 481, 498], "double_jump": [530, 632, 633, 654],
	 "dash": [476, 632, 633, 654], "crouch": [476, 632, 633, 654]},
	{"ground": [800, 972, 973, 992], "jump": [706, 814, 815, 832], "double_jump": [860, 980, 981, 1000],
	 "dash": [800, 980, 981, 1000], "crouch": [800, 980, 981, 1000]},
]

var img: Image


func _initialize() -> void:
	img = Image.load_from_file(ProjectSettings.globalize_path(SRC))
	img.convert(Image.FORMAT_RGBA8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	# Escala pelo corpo do 1º quadro parado do nível 1.
	var first: Rect2i = _frames(0, "idle")[0]
	var body := _body(first)
	var factor := HERO_IDLE_HEIGHT / body.size.y
	print("escala %.3f (corpo parado com %d px)" % [factor, body.size.y])

	var meta := {}
	for lv in LEVELS.size():
		for anim in COLUMNS:
			var rects := _frames(lv, anim)
			meta["c%d_%s" % [lv + 1, anim]] = _strip(rects, factor, OUT + "c%d_%s.png" % [lv + 1, anim])
			print("nível %d %s: %d quadros" % [lv + 1, anim, rects.size()])
	var file := FileAccess.open(OUT + "crimson.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(meta, "\t"))
	quit()


## Retângulos dos quadros de uma animação.
## Parado, andando e pulo: um quadro por número ("01", "02"...) embaixo dos bonecos.
## Pulo duplo, dash e abaixado têm 3 bonecos sobre 4 números (o dash usa cortes fixos): aí cada boneco é separado pelas
## colunas sem corpo (a aura vermelha não conta, senão os bonecos do nível 3 se juntam).
func _frames(lv: int, anim: String) -> Array:
	var band: Array = LEVELS[lv].get(anim, LEVELS[lv]["ground"])
	var cols: Array = COLUMNS[anim]
	if FIXED.has(anim):
		var cuts: Array = FIXED[anim]
		var fixed := []
		for i in cuts.size() - 1:
			fixed.append(Rect2i(cuts[i], band[0], cuts[i + 1] - cuts[i], band[1] - band[0]))
		return fixed
	var by_body: bool = anim in BY_BODY
	var y0: int = band[0] if by_body else band[2]
	var y1: int = band[1] if by_body else band[3]
	var groups := []        # [x0, x1] de cada boneco (ou número)
	var start := -1
	var last := -100
	for x in range(cols[0], cols[1]):
		var hit := false
		for y in range(y0, y1):
			var c := img.get_pixel(x, y)
			if (by_body and _is_body(c)) or (not by_body and c.a > 0.9):
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
		groups = groups.filter(func(g): return g[1] - g[0] >= 18)   # fiapos soltos não são bonecos
	var rects := []
	for i in groups.size():
		var x0: int = cols[0] if i == 0 else (groups[i - 1][1] + groups[i][0]) / 2
		var x1: int = cols[1] if i == groups.size() - 1 else (groups[i][1] + groups[i + 1][0]) / 2
		rects.append(Rect2i(x0, band[0], x1 - x0, band[1] - band[0]))
	return rects


## Pixel do corpo (pele, roupa, cabelo), não da aura: opaco e sem o vermelho-rosa forte da energia.
func _is_body(c: Color) -> bool:
	return c.a > 0.95 and (c.r < 0.55 or c.g > 0.35)


## Caixa dos pixels sólidos (corpo, sem a aura) dentro do retângulo.
func _body(r: Rect2i) -> Rect2i:
	var x0 := r.end.x
	var y0 := r.end.y
	var x1 := r.position.x
	var y1 := r.position.y
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if img.get_pixel(x, y).a > SOLID:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


## Ponto dos pés: centro do corpo (média das colunas sólidas) e a linha mais baixa do corpo.
func _anchor(r: Rect2i) -> Vector2:
	var sum := 0.0
	var n := 0
	var bottom := r.position.y
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if img.get_pixel(x, y).a > SOLID:
				sum += x
				n += 1
				bottom = maxi(bottom, y)
	return Vector2(sum / maxi(n, 1), bottom)


## Monta a tira com todos os quadros alinhados pelos pés e devolve as medidas.
func _strip(rects: Array, factor: float, path: String) -> Dictionary:
	var anchors := []
	var left := 0.0
	var right := 0.0
	var up := 0.0
	var down := 0.0
	for r in rects:
		var a := _anchor(r)
		anchors.append(a)
		left = maxf(left, (a.x - r.position.x) * factor)
		right = maxf(right, (r.end.x - a.x) * factor)
		up = maxf(up, (a.y - r.position.y) * factor)
		down = maxf(down, (r.end.y - a.y) * factor)
	var cell := Vector2i(ceili(left + right) + 2, ceili(up + down) + 2)
	var pivot := Vector2i(ceili(left) + 1, ceili(up) + 1)
	var strip := Image.create(cell.x * rects.size(), cell.y, false, Image.FORMAT_RGBA8)
	for i in rects.size():
		var r: Rect2i = rects[i]
		var part := img.get_region(r)
		part.resize(maxi(1, roundi(r.size.x * factor)), maxi(1, roundi(r.size.y * factor)), Image.INTERPOLATE_LANCZOS)
		var a: Vector2 = anchors[i]
		var pos := Vector2i(i * cell.x, 0) + pivot - Vector2i(((a - Vector2(r.position)) * factor).round())
		strip.blend_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), pos)
	strip.save_png(ProjectSettings.globalize_path(path))
	return {"frames": rects.size(), "w": cell.x, "h": cell.y, "ax": pivot.x, "ay": pivot.y}
