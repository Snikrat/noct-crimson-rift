extends SceneTree
## Diagnóstico: desenha os retângulos de recorte sobre as pranchas e salva imagens para conferência.
const Slicer := preload("res://tools/slice_hero.gd")
func _initialize():
	var out: String = OS.get_cmdline_user_args()[0]
	var colors := [Color.YELLOW, Color.CYAN, Color.LIME, Color.ORANGE, Color.MAGENTA, Color.WHITE]
	for key in Slicer.SOURCES:
		var img := Image.load_from_file(ProjectSettings.globalize_path(Slicer.SRC + Slicer.SOURCES[key]["file"]))
		img.convert(Image.FORMAT_RGBA8)
		# fundo cinza para ver a transparência
		var bg := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
		bg.fill(Color(0.25, 0.25, 0.3))
		bg.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i.ZERO)
		var ci := 0
		for anim in Slicer.ANIMS:
			if Slicer.ANIMS[anim]["src"] != key:
				continue
			var col: Color = colors[ci % colors.size()]
			ci += 1
			for r in Slicer.ANIMS[anim]["rects"]:
				for x in range(r[0], r[2]):
					for t in 2:
						bg.set_pixel(clampi(x, 0, bg.get_width() - 1), clampi(r[1] + t, 0, bg.get_height() - 1), col)
						bg.set_pixel(clampi(x, 0, bg.get_width() - 1), clampi(r[3] - 1 - t, 0, bg.get_height() - 1), col)
				for y in range(r[1], r[3]):
					for t in 2:
						bg.set_pixel(clampi(r[0] + t, 0, bg.get_width() - 1), clampi(y, 0, bg.get_height() - 1), col)
						bg.set_pixel(clampi(r[2] - 1 - t, 0, bg.get_width() - 1), clampi(y, 0, bg.get_height() - 1), col)
		bg.save_png(out + "/diag_" + key + ".png")
	quit()
