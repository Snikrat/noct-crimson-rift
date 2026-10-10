extends Node2D
## Clipe PixelLab com recortes JSON; cada efeito mantém seu próprio canvas e ritmo.
const DIRECTORY := "res://assets/areas/pedravelha/vfx/"
var sheet: Texture2D
var frames: Array = []
var elapsed := 0.0
var duration := 0.0
var looping := true
var offset := Vector2.ZERO
var cycle_gap := 0.0
var level
var requires_rift := false

func setup(clip: String, anchor := Vector2.ZERO, repeats := true) -> void:
	sheet = load(DIRECTORY + clip + ".png")
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIRECTORY + clip + ".json"))
	frames = metadata["frames"]
	for frame: Dictionary in frames:
		duration += float(frame["duration"]) / 1000.0
	offset = -anchor
	looping = repeats
	z_index = -1
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if requires_rift and level.rift.is_empty():
		queue_free()
		return
	elapsed += delta
	if not looping and elapsed >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if frames.is_empty():
		return
	var time := fmod(elapsed, duration + cycle_gap)
	if time >= duration:
		return
	for frame: Dictionary in frames:
		var seconds := float(frame["duration"]) / 1000.0
		if time < seconds:
			var rect: Dictionary = frame["frame"]
			var source := Rect2(rect["x"], rect["y"], rect["w"], rect["h"])
			draw_texture_rect_region(sheet, Rect2(offset, source.size), source)
			return
		time -= seconds
