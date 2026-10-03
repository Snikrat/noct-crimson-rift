extends SceneTree
## Reduz o emblema carmesim (art_source/ui/emblema.png) para o HUD: ícone de jogo salvo.
## Uso: godot --headless --path . --script tools/make_emblem.gd

const SRC := "res://art_source/ui/emblema.png"
const OUT := "res://assets/ui/emblem.png"
const SIZE := 160


func _initialize() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(SRC))
	img.convert(Image.FORMAT_RGBA8)
	img.resize(SIZE, SIZE, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(OUT))
	print("emblema %dx%d" % [SIZE, SIZE])
	quit()
