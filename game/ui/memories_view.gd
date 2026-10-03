extends RefCounted
## Aba "Memórias" da pausa: lista as memórias de Mira (as não encontradas aparecem como "???")
## e mostra o texto da selecionada.

const InputSetup := preload("res://game/core/input_setup.gd")
const Memories := preload("res://data/memories.gd")
const GOLD := Color("e8c872")
const RIBBON := Color(0.9, 0.15, 0.3)

var index := 0


## Retorna true quando o jogador sai da aba.
func handle_input() -> bool:
	if InputSetup.back_pressed() or Input.is_action_just_pressed("ui_cancel"):
		Audio.play_sfx("back", 0.0)
		return true
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("ui_up"):
		index = posmod(index - 1, Memories.ORDER.size())
		Audio.play_sfx("hover", 0.0)
	elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("ui_down"):
		index = posmod(index + 1, Memories.ORDER.size())
		Audio.play_sfx("hover", 0.0)
	return false


func draw(ci: CanvasItem, font: Font, screen: Vector2) -> void:
	var box := Rect2(16, 18, screen.x - 32, screen.y - 36)
	ci.draw_rect(box, Color(0.02, 0.02, 0.06, 0.92))
	ci.draw_rect(box, Color(1, 1, 1, 0.3), false, 1)
	var found: int = GameState.memories.size()
	ci.draw_string(font, box.position + Vector2(0, 20), "Memórias  %d/%d" % [found, Memories.ORDER.size()],
		HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, GOLD)
	var list_x := box.position.x + 14
	for i in Memories.ORDER.size():
		var id: String = Memories.ORDER[i]
		var has: bool = GameState.memories.has(id)
		var y := box.position.y + 46 + i * 20
		var selected := i == index
		# Fita: cheia quando encontrada, só o contorno quando não.
		var r := Rect2(list_x, y - 8, 6, 9)
		if has:
			ci.draw_rect(r, RIBBON)
		else:
			ci.draw_rect(r, Color(RIBBON, 0.5), false, 1)
		var label: String = Memories.MEMORIES[id]["title"] if has else "???"
		ci.draw_string(font, Vector2(list_x + 12, y), label, HORIZONTAL_ALIGNMENT_LEFT, 150, 10,
			GOLD if selected else Color(1, 1, 1, 0.8 if has else 0.4))
	# Texto da memória escolhida.
	var text_box := Rect2(box.position.x + 182, box.position.y + 36, box.size.x - 196, box.size.y - 60)
	ci.draw_rect(text_box, Color(0.12, 0.02, 0.05, 0.6))
	ci.draw_rect(text_box, Color(RIBBON, 0.4), false, 1)
	var sel: String = Memories.ORDER[index]
	if GameState.memories.has(sel):
		var y := text_box.position.y + 18
		for line in Memories.MEMORIES[sel]["lines"]:
			var l: String = line
			ci.draw_multiline_string(font, Vector2(text_box.position.x + 10, y), l, HORIZONTAL_ALIGNMENT_LEFT,
				text_box.size.x - 20, 10, -1, Color(1, 0.92, 0.95) if l.begins_with("\"") else Color(1, 1, 1, 0.65))
			y += 14 * ceili(font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x / (text_box.size.x - 20)) + 6
	else:
		ci.draw_string(font, text_box.get_center() + Vector2(-text_box.size.x / 2, 0), "Ainda não encontrada.",
			HORIZONTAL_ALIGNMENT_CENTER, text_box.size.x, 10, Color(1, 1, 1, 0.4))
	ci.draw_string(font, Vector2(box.position.x, box.end.y - 8), "K / Esc volta   ", HORIZONTAL_ALIGNMENT_RIGHT, box.size.x, 8, Color(1, 1, 1, 0.45))
