extends CanvasLayer
## Chuva na tela (temas com "rain": true, como a Estação). Só visual: riscos inclinados caindo
## na frente do cenário e atrás da interface. Fica dentro do "world" da sala e some com ela.

const DROPS := 90
const SPEED := 420.0
const SLANT := Vector2(-0.22, 1.0)
const COLOR := Color(0.7, 0.78, 0.95, 0.35)

var canvas: Control
var drops: Array[Vector3] = []   # x, y, comprimento


func _ready() -> void:
	layer = 1
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_rain)
	add_child(canvas)
	var size := get_viewport().get_visible_rect().size
	for i in DROPS:
		drops.append(Vector3(randf() * size.x, randf() * size.y, randf_range(5, 10)))


func _process(delta: float) -> void:
	var size := get_viewport().get_visible_rect().size
	for i in drops.size():
		var d := drops[i]
		d.x += SLANT.x * SPEED * delta
		d.y += SLANT.y * SPEED * delta * (0.8 + d.z / 25.0)
		if d.y > size.y:
			d = Vector3(randf() * (size.x + 60), -10, randf_range(5, 10))
		drops[i] = d
	canvas.queue_redraw()


func _draw_rain() -> void:
	for d in drops:
		var top := Vector2(d.x, d.y)
		canvas.draw_line(top, top + SLANT * d.z, COLOR, 1.0)
