extends SceneTree
## Analisa uma prancha: acha faixas horizontais com conteúdo e, em cada uma, os blocos separados por colunas vazias.
## Uso: godot --headless --script tools/analyze_sheet.gd -- <png> <alfa_min> <gap_min>

func _initialize():
	var args := OS.get_cmdline_user_args()
	var img := Image.load_from_file(args[0])
	var amin := int(args[1])
	var gap := int(args[2])
	if args.size() > 3:
		var r := args[3].split(",")
		img = img.get_region(Rect2i(int(r[0]), int(r[1]), int(r[2]) - int(r[0]), int(r[3]) - int(r[1])))
		print("(regiao relativa a ", r[0], ",", r[1], ")")
	var w := img.get_width()
	var h := img.get_height()
	var row_has := PackedInt32Array()
	row_has.resize(h)
	for y in h:
		var n := 0
		for x in range(0, w, 2):
			if img.get_pixel(x, y).a8 >= amin:
				n += 1
		row_has[y] = n
	# faixas
	var bands := []
	var y := 0
	while y < h:
		if row_has[y] > 0:
			var s := y
			var empty := 0
			while y < h and empty < gap:
				empty = empty + 1 if row_has[y] == 0 else 0
				y += 1
			bands.append([s, y - empty])
		else:
			y += 1
	for b in bands:
		var cols := []
		var x := 0
		var col_has := func(cx):
			for yy in range(b[0], b[1]):
				if img.get_pixel(cx, yy).a8 >= amin:
					return true
			return false
		while x < w:
			if col_has.call(x):
				var s := x
				var empty := 0
				while x < w and empty < gap:
					empty = empty + 1 if not col_has.call(x) else 0
					x += 1
				cols.append("%d-%d" % [s, x - empty])
			else:
				x += 1
		print("faixa y%d-%d (%d px): %d blocos  %s" % [b[0], b[1], b[1] - b[0], cols.size(), " ".join(cols)])
	quit()
