extends SceneTree
## Recorta os rostos de Noct para os diálogos a partir da cartela de expressões
## (art_source/rostos_expressoes.png: 3 linhas x 10 rostos, com o nome escrito embaixo de cada um).
## Cada rosto vira assets/hero/portrait_<expressão>.png (72x72, cabeça e ombros, centrado no rosto).
## Uso: godot --headless --path . --script tools/slice_portraits.gd

const SRC := "res://art_source/rostos_expressoes.png"
const OUT := "res://assets/hero/"
const SIZE := 72
const WIDE_OUT := "res://art_source/portraits/noct_wide/"

# Faixa vertical de cada linha de rostos (sem a faixa do nome) e as colunas [x0, x1] de cada rosto.
const ROWS := [
	{"y": [25, 246], "faces": [
		["neutro", 10, 192], ["serio", 208, 388], ["desconfiado", 404, 583], ["irritado", 598, 765],
		["bravo", 782, 966], ["furioso", 982, 1165], ["surpreso", 1178, 1358], ["chocado", 1374, 1546],
		["confuso", 1561, 1743], ["pensativo", 1757, 1952]]},
	{"y": [284, 492], "faces": [
		["determinado", 10, 190], ["confiante", 205, 388], ["sorrindo", 399, 584], ["sarcastico", 592, 770],
		["cansado", 786, 966], ["triste", 982, 1162], ["dor", 1178, 1358], ["ferido", 1374, 1552],
		["sangrando", 1568, 1749], ["olhar_lateral", 1766, 1948]]},
	{"y": [529, 744], "faces": [
		["olhar_cima", 13, 196], ["olhar_baixo", 210, 383], ["fechando_olhos", 398, 572], ["calmo", 588, 763],
		["sombrio", 778, 959], ["maligno", 974, 1155], ["magia_olhos", 1169, 1339], ["magia_aura", 1350, 1546],
		["em_combate", 1561, 1749], ["ultimate", 1763, 1966]]},
]


func _initialize() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	img.convert(Image.FORMAT_RGBA8)
	var count := 0
	for row in ROWS:
		var y0: int = row["y"][0]
		var y1: int = row["y"][1]
		for face in row["faces"]:
			var x0: int = face[1]
			var x1: int = face[2]
			# Quadrado do tamanho da largura do busto, encostado no topo do cabelo e centrado na cabeça.
			var side := mini(x1 - x0, y1 - y0)
			var cx := _head_center(img, x0, x1, y0, y0 + (y1 - y0) / 3)
			var left := clampi(cx - side / 2, x0 - 6, x1 - side + 6)
			var crop := Image.create(side, side, false, Image.FORMAT_RGBA8)
			crop.blit_rect(img, Rect2i(left, y0, side, side), Vector2i.ZERO)
			# Só o que está dentro da coluna deste rosto (nada do vizinho).
			for y in side:
				for x in side:
					var sx := left + x
					if sx < x0 or sx > x1 or crop.get_pixel(x, y).a8 < 60:
						crop.set_pixel(x, y, Color(0, 0, 0, 0))
			_save_wide(img, face[0], x0, x1, y0, y1, side, cx)
			crop.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
			crop.save_png(ProjectSettings.globalize_path(OUT + "portrait_" + face[0] + ".png"))
			count += 1
	print("%d rostos recortados" % count)
	quit()


## Coluna média dos pixels do cabelo/rosto (terço de cima), para centralizar o recorte.
func _head_center(img: Image, x0: int, x1: int, y0: int, y1: int) -> int:
	var sum := 0
	var n := 0
	for y in range(y0, y1, 2):
		for x in range(x0, x1, 2):
			if img.get_pixel(x, y).a8 > 160:
				sum += x
				n += 1
	return sum / maxi(n, 1) if n > 0 else (x0 + x1) / 2


## Base dos rostos da Forma Demoníaca: o mesmo rosto um pouco mais afastado, com espaço em cima e
## dos lados para as orelhas e as caudas de energia (art_source/portraits/noct_wide/<expressão>.png).
## tools/make_portraits.lua desenha a forma por cima, no Aseprite.
func _save_wide(img: Image, face: String, x0: int, x1: int, y0: int, y1: int, side: int, cx: int) -> void:
	var extra := int(side * 0.32)
	var big := side + extra
	var left := cx - big / 2
	var top := y0 - extra
	var crop := Image.create(big, big, false, Image.FORMAT_RGBA8)
	for y in big:
		for x in big:
			var sx := left + x
			var sy := top + y
			if sx < x0 or sx > x1 or sy < y0 or sy >= y0 + side or sx < 0 or sx >= img.get_width():
				continue
			var c := img.get_pixel(sx, sy)
			if c.a8 >= 60:
				crop.set_pixel(x, y, c)
	crop.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	var dir := ProjectSettings.globalize_path(WIDE_OUT)
	DirAccess.make_dir_recursive_absolute(dir)
	crop.save_png(dir + face + ".png")
