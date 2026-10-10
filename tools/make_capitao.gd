extends SceneTree
## Monta as tiras do Capitão dos Desgarrados a partir dos quadros do PixelLab
## (art_source/inimigos/capitao_pixellab/<animação>/<i>.png, olhando para a direita).
## O personagem foi gerado num quadro de 56 px (pés na linha 54). Cada animação vem num quadro
## maior e centrado nesse; aqui tudo vai para o mesmo quadro CELL com os pés na linha FEET.
## Uso: godot --headless --path . --script tools/make_capitao.gd

const SRC := "res://art_source/inimigos/capitao_pixellab/"
const OUT := "res://assets/enemies/capitao/"
const BASE := 56          # quadro original do personagem
const BASE_FEET := 54     # linha dos pés no quadro original
const BASE_X := 28        # centro do corpo no quadro original
const CELL := Vector2i(112, 80)
const FEET := 72
const ANIMS := ["idle", "run", "slash", "lunge", "throw_net", "hurt", "death", "taunt", "rage", "spin"]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for anim in ANIMS:
		var frames := []
		var i := 0
		while FileAccess.file_exists(SRC + anim + "/%d.png" % i):
			frames.append(Image.load_from_file(ProjectSettings.globalize_path(SRC + anim + "/%d.png" % i)))
			i += 1
		if frames.is_empty():
			print("sem quadros: ", anim)
			continue
		var strip := Image.create(CELL.x * frames.size(), CELL.y, false, Image.FORMAT_RGBA8)
		for f in frames.size():
			var img: Image = frames[f]
			img.convert(Image.FORMAT_RGBA8)
			var pad := (img.get_size() - Vector2i(BASE, BASE)) / 2
			var dest := Vector2i(CELL.x / 2 - BASE_X, FEET - BASE_FEET) - pad + Vector2i(f * CELL.x, 0)
			var src_rect := Rect2i(Vector2i.ZERO, img.get_size())
			# Recorta o que sairia do quadro (para não vazar para o quadro vizinho).
			var cell_rect := Rect2i(Vector2i(f * CELL.x, 0), CELL)
			var placed := Rect2i(dest, img.get_size()).intersection(cell_rect)
			src_rect = Rect2i(placed.position - dest, placed.size)
			strip.blend_rect(img, src_rect, placed.position)
		strip.save_png(ProjectSettings.globalize_path(OUT + anim + ".png"))
		var used := frames[0].get_used_rect() as Rect2i
		print(anim, ": ", frames.size(), " quadros, canvas ", frames[0].get_size(), ", pés no quadro 0 = ", used.end.y - (frames[0].get_height() - BASE) / 2)
	quit()
