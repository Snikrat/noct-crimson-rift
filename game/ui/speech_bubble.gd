extends CanvasLayer
## Balão curto que NÃO pausa o jogo: provocações no meio do combate (o resto das falas espera o botão,
## ver dialog_box.gd). Segue um personagem e some sozinho. Fica dentro do "world" da sala e some com ela.
## Texto com "@expressão: " é Noct falando, com o rosto dele no balão.

const GOLD := Color("e8c872")
const HERO_COLOR := Color(1, 0.55, 0.75)
const TEXT_W := 150.0

var level
var target: Node2D
var who := ""
var text := ""
var duration := 3.0
var lift := 44.0        # altura do balão acima da origem do alvo
var face := ""
var t := 0.0
var canvas: Control


func _ready() -> void:
	layer = 4   # acima da sala, abaixo do HUD
	if text.begins_with("@"):
		var parsed: Array = level.hud.dialog._hero_face(text)
		face = parsed[0]
		text = parsed[1]
		who = "Noct"
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_bubble)
	add_child(canvas)


func _process(delta: float) -> void:
	t += delta
	if t >= duration or not is_instance_valid(target):
		queue_free()
		return
	canvas.queue_redraw()


func _draw_bubble() -> void:
	var font := ThemeDB.fallback_font
	var alpha := clampf(minf(t / 0.12, (duration - t) / 0.35), 0.0, 1.0)
	var face_w := 30.0 if face != "" else 0.0
	var text_h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, TEXT_W, 10).y
	var w := face_w + TEXT_W + 14
	var h := maxf(face_w + 6, 20 + text_h + 6)
	var head := canvas.get_viewport().get_canvas_transform() * (target.global_position - Vector2(0, lift))
	var box := Rect2(clampf(head.x - w / 2, 4, canvas.size.x - w - 4), clampf(head.y - h, 4, canvas.size.y - h - 4), w, h)
	var tip_x := clampf(head.x, box.position.x + 8, box.end.x - 8)
	var tail := PackedVector2Array([Vector2(tip_x - 5, box.end.y), Vector2(tip_x + 5, box.end.y), Vector2(tip_x, box.end.y + 6)])
	var bg := Color(0.06, 0.0, 0.03, 0.88 * alpha)
	var edge := Color(1, 0.3, 0.45, 0.6 * alpha) if who != "Noct" else Color(1, 1, 1, 0.35 * alpha)
	canvas.draw_colored_polygon(tail, bg)
	canvas.draw_rect(box, bg)
	canvas.draw_rect(box, edge, false, 1)
	var text_x := box.position.x + 7
	if face != "":
		var frame := Rect2(box.position + Vector2(3, 3), Vector2(28, 28))
		canvas.draw_texture_rect(level.hud.dialog.portrait(face), frame, false, Color(1, 1, 1, alpha))
		canvas.draw_rect(frame, Color(1, 0.3, 0.6, 0.7 * alpha), false, 1)
		text_x = frame.end.x + 6
	var name_color := HERO_COLOR if who == "Noct" else GOLD
	name_color.a = alpha
	canvas.draw_string(font, Vector2(text_x, box.position.y + 13), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, name_color)
	canvas.draw_multiline_string(font, Vector2(text_x, box.position.y + 26), text, HORIZONTAL_ALIGNMENT_LEFT, TEXT_W, 10,
		-1, Color(1, 1, 1, alpha))
