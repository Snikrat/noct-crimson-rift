extends SceneTree
## Prepara as barras do HUD e a fonte pixel do jogo a partir da arte feita no Aseprite (art_source/ui/hud/).
## Barras: separa a moldura (com o interior vazio) do preenchimento, que o HUD recorta conforme o valor.
## Fonte: copia a folha de glifos e escreve o .fnt (BMFont) com a largura de cada letra.
## Uso: godot --headless --path . --script tools/make_hud_ui.gd

const SRC := "res://art_source/ui/hud/"
const OUT_BARS := "res://assets/ui/hud/"
const OUT_FONT := "res://assets/ui/fonts/"
const BARS := ["vida", "magia", "xp"]
const EMPTY := Color("130000")           # interior vazio da barra
const FILL_ROWS := Vector2i(5, 9)        # linhas do preenchimento (de cima para baixo, inclusive)
const FILL_FROM_X := 13                  # à esquerda disso fica o losango

# Folha de glifos: células 8x12, uma linha por grupo.
const CELL := Vector2i(8, 12)
const FONT_SIZE := 8                     # tamanho "natural": textos de 8 a 15 saem em 1x, de 16 a 23 em 2x
const GLYPH_ROWS := [
	"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	"abcdefghijklmnopqrstuvwxyz",
	"0123456789.,!?:-%/",
	"áàâãéêíóôõúç",
	"ÁÀÂÃÉÊÍÓÔÕÚÇ",
]
const RAISED := "ÁÀÂÃÉÊÍÓÔÕÚ"         # maiúsculas acentuadas: desenhadas 2 px abaixo na folha para caber o acento
const RAISE := 2
const BASELINE := 8                      # da linha de cima da célula até a base das maiúsculas
const SPACE_ADVANCE := 4


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_BARS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_FONT))
	for bar in BARS:
		_split_bar(bar)
	_make_font()
	quit()


func _load(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.convert(Image.FORMAT_RGBA8)
	return img


## Pixel do preenchimento: dentro da faixa e com uma das cores da barra (não o contorno escuro).
func _is_fill(img: Image, x: int, y: int) -> bool:
	if x < FILL_FROM_X or y < FILL_ROWS.x or y > FILL_ROWS.y:
		return false
	var c := img.get_pixel(x, y)
	return c.a > 0 and c.to_html(false) not in ["0d020e", "291926", "4a3a44", "8a7a84", "c9bcc4"]


func _split_bar(bar: String) -> void:
	var img := _load(SRC + "barra_%s.png" % bar)
	var frame := img.duplicate() as Image
	var x0 := img.get_width()
	var x1 := 0
	for y in range(FILL_ROWS.x, FILL_ROWS.y + 1):
		for x in img.get_width():
			if _is_fill(img, x, y):
				frame.set_pixel(x, y, EMPTY)
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
	var fill := Image.create(x1 - x0 + 1, FILL_ROWS.y - FILL_ROWS.x + 1, false, Image.FORMAT_RGBA8)
	for y in fill.get_height():
		for x in fill.get_width():
			if _is_fill(img, x0 + x, FILL_ROWS.x + y):
				fill.set_pixel(x, y, img.get_pixel(x0 + x, FILL_ROWS.x + y))
	frame.save_png(ProjectSettings.globalize_path(OUT_BARS + "barra_%s_moldura.png" % bar))
	fill.save_png(ProjectSettings.globalize_path(OUT_BARS + "barra_%s_preenchimento.png" % bar))
	print("barra %s: preenchimento em x=%d, %dx%d" % [bar, x0, fill.get_width(), fill.get_height()])


func _make_font() -> void:
	var img := _load(SRC + "fonte_glifos.png")
	img.save_png(ProjectSettings.globalize_path(OUT_FONT + "noct_pixel.png"))
	var chars := PackedStringArray()
	for row in GLYPH_ROWS.size():
		var line: String = GLYPH_ROWS[row]
		for col in line.length():
			# Largura real do glifo (com a sombra), para a fonte ficar proporcional.
			var cell := Rect2i(Vector2i(col, row) * CELL, CELL)
			var left := CELL.x
			var right := -1
			for y in CELL.y:
				for x in CELL.x:
					if img.get_pixel(cell.position.x + x, cell.position.y + y).a > 0:
						left = mini(left, x)
						right = maxi(right, x)
			if right < 0:
				continue
			var w := right - left + 1
			var y_off := -RAISE if RAISED.contains(line[col]) else 0
			chars.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=%d xadvance=%d page=0 chnl=15" % [
				line.unicode_at(col), cell.position.x + left, cell.position.y, w, CELL.y, y_off, w])
	chars.append("char id=32 x=0 y=0 width=0 height=0 xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15" % SPACE_ADVANCE)
	var fnt := PackedStringArray([
		'info face="Noct Pixel" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=0,0' % FONT_SIZE,
		"common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0" % [CELL.y, BASELINE, img.get_width(), img.get_height()],
		'page id=0 file="noct_pixel.png"',
		"chars count=%d" % chars.size(),
	])
	fnt.append_array(chars)
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT_FONT + "noct_pixel.fnt"), FileAccess.WRITE)
	f.store_string("\n".join(fnt) + "\n")
	print("fonte: %d glifos" % chars.size())
