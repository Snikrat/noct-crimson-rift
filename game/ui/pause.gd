extends Control
## Menu de pausa (Esc / Start): continuar, amuletos, controles ou voltar à tela de título.

const InputSetup := preload("res://game/core/input_setup.gd")
const OPTIONS := ["Continuar", "Amuletos", "Controles", "Voltar ao título"]
const GOLD := Color("e8c872")

var level
var open := false
var closing := false
var index := 0
var page := "menu"


func _ready() -> void:
	# Continua rodando com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	# Só despausa quando o botão usado para sair for solto; senão ele vira pulo/ataque/dash no jogo.
	if closing:
		for action in ["jump", "attack", "dash", "spell", "pause"]:
			if Input.is_action_pressed(action):
				return
		closing = false
		open = false
		get_tree().paused = false
		Audio.play_sfx("unpause")
		queue_redraw()
		return
	if not open:
		if Input.is_action_just_pressed("pause") and not level.transitioning and level.player.death_timer <= 0:
			open = true
			index = 0
			page = "menu"
			get_tree().paused = true
			Audio.play_sfx("pause")
			queue_redraw()
		return

	if page == "charms":
		if level.hud.charms.handle_input():
			level.hud.charms.close()
			page = "menu"
			Audio.play_sfx("back")
	elif page == "controls":
		if InputSetup.back_pressed() or InputSetup.confirm_pressed():
			page = "menu"
			Audio.play_sfx("back")
	elif InputSetup.back_pressed():
		closing = true
	elif Input.is_action_just_pressed("up"):
		index = posmod(index - 1, OPTIONS.size())
		Audio.play_sfx("hover", 0.0)
	elif Input.is_action_just_pressed("down"):
		index = posmod(index + 1, OPTIONS.size())
		Audio.play_sfx("hover", 0.0)
	elif InputSetup.confirm_pressed():
		Audio.play_sfx("confirm", 0.0)
		match OPTIONS[index]:
			"Continuar":
				closing = true
			"Amuletos":
				page = "charms"
				level.hud.charms.open()
			"Controles":
				page = "controls"
			"Voltar ao título":
				get_tree().paused = false
				Engine.time_scale = 1.0
				get_tree().change_scene_to_file("res://game/ui/title.tscn")
	queue_redraw()


func _draw() -> void:
	if not open:
		return
	var font := ThemeDB.fallback_font
	var screen := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0, 0, 0, 0.6))
	if page == "charms":
		return  # a tela de amuletos (game/ui/charms.gd) se desenha por cima
	if page == "controls":
		var box := Rect2(50, 22, screen.x - 100, screen.y - 44)
		draw_rect(box, Color(0.02, 0.02, 0.06, 0.9))
		draw_rect(box, Color(1, 1, 1, 0.3), false, 1)
		draw_string(font, box.position + Vector2(0, 24), "Controles", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, GOLD)
		InputSetup.draw_controls(self, font, Rect2(box.position + Vector2(16, 40), box.size - Vector2(32, 60)))
		draw_string(font, Vector2(0, screen.y - 8), "K / Esc ou B para voltar", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 8, Color(1, 1, 1, 0.45))
		return
	draw_string(font, Vector2(0, 96), "Pausado", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 22, Color("ece6f5"))
	for i in OPTIONS.size():
		var selected := i == index
		var label: String = OPTIONS[i]
		if selected:
			label = ">  " + label + "  <"
		draw_string(font, Vector2(0, 140 + i * 20), label, HORIZONTAL_ALIGNMENT_CENTER, screen.x, 13,
			GOLD if selected else Color(1, 1, 1, 0.75))
