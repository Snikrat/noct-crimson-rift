extends CanvasLayer
## Fundo da sala em camadas com parallax (cada camada anda numa velocidade com a câmera).

var layers := []   # [{tex: [Texture2D], scroll: float, align: "center"|"bottom", tint: Color}]
var canvas: Control
var foreground_canvas: Control
var foreground_texture: Texture2D


func _ready() -> void:
	layer = -10
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_layers)
	add_child(canvas)
	var foreground_layer := CanvasLayer.new()
	foreground_layer.layer = 1
	add_child(foreground_layer)
	foreground_canvas = Control.new()
	foreground_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	foreground_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foreground_canvas.draw.connect(_draw_foreground)
	foreground_layer.add_child(foreground_canvas)


## Carrega as camadas do tema da sala.
func set_theme_layers(theme: Dictionary) -> void:
	layers.clear()
	foreground_texture = load(theme["foreground"]) if theme.has("foreground") else null
	for l in theme["layers"]:
		var texs := []
		for path in l["tex"]:
			texs.append(load(path))
		layers.append({"tex": texs, "scroll": l["scroll"], "align": l["align"], "gap": l.get("gap", 0), "cover": l.get("cover", false),
			"tint": l.get("tint", Color.WHITE)})


func _process(_delta: float) -> void:
	canvas.queue_redraw()
	foreground_canvas.queue_redraw()


func _draw_foreground() -> void:
	if foreground_texture == null:
		return
	var cam := canvas.get_viewport().get_camera_2d()
	var cam_x := cam.get_screen_center_position().x if cam else 0.0
	var width := foreground_texture.get_width()
	var x := -fposmod(cam_x * 0.55, width)
	while x < foreground_canvas.size.x:
		foreground_canvas.draw_texture(foreground_texture, Vector2(roundf(x), -24), Color(1, 1, 1, 0.85))
		x += width


func _draw_layers() -> void:
	var cam := canvas.get_viewport().get_camera_2d()
	var cam_x := cam.get_screen_center_position().x if cam else 0.0
	var screen := canvas.size
	for l in layers:
		if l["cover"]:
			var tex: Texture2D = l["tex"][0]
			var scale_factor := maxf(screen.x / tex.get_width(), screen.y / tex.get_height())
			var size := tex.get_size() * scale_factor
			canvas.draw_texture_rect(tex, Rect2((screen - size) / 2, size), false, l["tint"])
			continue
		var h: float = l["tex"][0].get_height()
		var y := screen.y - h if l["align"] == "bottom" else (screen.y - h) / 2.0
		_draw_strip(l["tex"], cam_x * l["scroll"], roundf(y), screen.x, l["gap"], l["tint"])


## Repete as texturas lado a lado (com "gap" pixels de espaço entre elas), deslocadas pelo parallax.
## "tint" escurece ou colore a camada (reaproveitar o fundo de uma área em outra).
func _draw_strip(textures: Array, scroll: float, y: float, screen_w: float, gap := 0, tint := Color.WHITE) -> void:
	var tile_w := 0.0
	for t: Texture2D in textures:
		tile_w += t.get_width() + gap
	var x := -fposmod(scroll, tile_w)
	while x < screen_w:
		for t: Texture2D in textures:
			canvas.draw_texture(t, Vector2(roundf(x), y), tint)
			x += t.get_width() + gap
