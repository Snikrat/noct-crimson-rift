extends RefCounted
## Painel de opções (usado na tela de título e no menu de pausa):
## volume da música, volume dos efeitos e tela cheia. Esquerda/direita mudam o valor.

const InputSetup := preload("res://game/core/input_setup.gd")
const GOLD := Color("e8c872")
const ITEMS := ["Música", "Efeitos", "Tela cheia", "Voltar"]
const STEP := 0.1

var index := 0


## Lê os botões. Retorna true quando o jogador sai do painel (as mudanças já ficam salvas).
func handle_input() -> bool:
	if InputSetup.back_pressed() or Input.is_action_just_pressed("ui_cancel"):
		_close()
		return true
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("ui_up"):
		index = posmod(index - 1, ITEMS.size())
		Audio.play_sfx("hover", 0.0)
	elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("ui_down"):
		index = posmod(index + 1, ITEMS.size())
		Audio.play_sfx("hover", 0.0)
	var dir := 0
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		dir = -1
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		dir = 1
	var confirm := InputSetup.confirm_pressed()
	match ITEMS[index]:
		"Música":
			if dir != 0:
				Settings.music = clampf(snappedf(Settings.music + dir * STEP, STEP), 0.0, 1.0)
				Settings.apply()
				Audio.play_sfx("hover", 0.0)
		"Efeitos":
			if dir != 0:
				Settings.sfx = clampf(snappedf(Settings.sfx + dir * STEP, STEP), 0.0, 1.0)
				Settings.apply()
				Audio.play_sfx("confirm", 0.0)   # toca já no volume novo
		"Tela cheia":
			if dir != 0 or confirm:
				Settings.fullscreen = not Settings.fullscreen
				Settings.apply()
				Audio.play_sfx("confirm", 0.0)
		"Voltar":
			if confirm:
				_close()
				return true
	return false


func _close() -> void:
	Settings.save()
	Audio.play_sfx("back", 0.0)


func draw(ci: CanvasItem, font: Font, box: Rect2) -> void:
	ci.draw_rect(box, Color(0.02, 0.02, 0.06, 0.9))
	ci.draw_rect(box, Color(1, 1, 1, 0.3), false, 1)
	ci.draw_string(font, box.position + Vector2(0, 24), "Opções", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, GOLD)
	for i in ITEMS.size():
		var y := box.position.y + 62 + i * 26
		var selected := i == index
		var color := GOLD if selected else Color(1, 1, 1, 0.8)
		var label: String = ITEMS[i]
		ci.draw_string(font, Vector2(box.position.x + 40, y), ("> " if selected else "  ") + label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
		var vx := box.position.x + 170
		match label:
			"Música", "Efeitos":
				var v: float = Settings.music if label == "Música" else Settings.sfx
				var bar := Rect2(vx, y - 8, 120, 6)
				ci.draw_rect(bar, Color(0, 0, 0, 0.6))
				ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * v, bar.size.y)), Color(0.85, 0.15, 0.3))
				ci.draw_rect(bar, Color(1, 1, 1, 0.35), false, 1)
				ci.draw_string(font, Vector2(vx + 128, y), "%d%%" % roundi(v * 100), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
			"Tela cheia":
				ci.draw_string(font, Vector2(vx, y), "Sim" if Settings.fullscreen else "Não", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
	ci.draw_string(font, Vector2(box.position.x, box.end.y - 10), "Cima/baixo escolhe   Esquerda/direita muda   K / Esc volta",
		HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 8, Color(1, 1, 1, 0.45))
