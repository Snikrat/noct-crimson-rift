extends CanvasLayer
## Fagulhas carmesim subindo pela tela (temas com "motes": true, como a Mente do Noct). Só visual.
## Quanto menos vida o chefe da sala tem, mais rápidas e acesas ficam: Noct perdendo a cabeça.
## Fica dentro do "world" da sala e some com ela.

const MOTES := 70
const COLORS := [Color("9c1238"), Color("e52d5e"), Color("ff7ea3"), Color("ffd9e4")]

var level
var canvas: Control
var motes: Array[Vector4] = []   # x, y, velocidade, fase do balanço
var t := 0.0


func _ready() -> void:
	layer = -5   # na frente do fundo, atrás da sala
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_motes)
	add_child(canvas)
	var size := get_viewport().get_visible_rect().size
	for i in MOTES:
		motes.append(Vector4(randf() * size.x, randf() * size.y, randf_range(10, 34), randf() * TAU))


## 0 = calmo, 1 = o chefe quase caindo.
func intensity() -> float:
	var b = level.boss if level else null
	if b and is_instance_valid(b) and "hp" in b and "MAX_HP" in b:
		return clampf(1.0 - float(b.hp) / b.MAX_HP, 0.0, 1.0)
	return 0.0


func _process(delta: float) -> void:
	t += delta
	var size := get_viewport().get_visible_rect().size
	var speed := 1.0 + intensity() * 1.6
	for i in motes.size():
		var m := motes[i]
		m.y -= m.z * speed * delta
		m.x += sin(t * 1.5 + m.w) * 6.0 * delta
		if m.y < -4:
			m = Vector4(randf() * size.x, size.y + 4, randf_range(10, 34), randf() * TAU)
		motes[i] = m
	canvas.queue_redraw()


func _draw_motes() -> void:
	var k := intensity()
	for m in motes:
		var c: Color = COLORS[int(m.z) % COLORS.size()]
		c.a = 0.35 + 0.35 * sin(t * 3.0 + m.w) * 0.5 + 0.3 * k
		var s := 2.0 if m.z > 28 else 1.0
		canvas.draw_rect(Rect2(Vector2(m.x, m.y).floor(), Vector2(s, s)), c)
