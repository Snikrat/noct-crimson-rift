extends Control
## Menu de pausa (Esc / Start): continuar, mapa, memórias de Mira, glossário de personagens, amuletos, opções, controles ou voltar ao título.
## O botão de mapa (M / Tab / LB) abre o mapa direto; sair do mapa nesse caso já volta ao jogo.

const InputSetup := preload("res://game/core/input_setup.gd")
const OptionsPanel := preload("res://game/ui/options_panel.gd")
const WorldMapView := preload("res://game/ui/world_map_view.gd")
const MemoriesView := preload("res://game/ui/memories_view.gd")
const GlossaryView := preload("res://game/ui/glossary_view.gd")
const OPTIONS := ["Continuar", "Mapa", "Memórias", "Glossário", "Amuletos", "Opções", "Controles", "Voltar ao título"]
const GOLD := Color("e8c872")

var level
var open := false
var closing := false
var index := 0
var page := "menu"
var map_direct := false   # mapa aberto pelo botão de mapa: sair dele fecha a pausa
var options_panel := OptionsPanel.new()
var memories_view := MemoriesView.new()
var glossary_view := GlossaryView.new()


func _ready() -> void:
	# Continua rodando com o jogo pausado.
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	# Só despausa quando o botão usado para sair for solto; senão ele vira pulo/ataque/dash no jogo.
	if closing:
		for action in ["jump", "attack", "dash", "spell", "pause", "map"]:
			if Input.is_action_pressed(action):
				return
		closing = false
		open = false
		get_tree().paused = level.is_dialog_open()   # um diálogo aberto continua segurando o jogo
		Audio.play_sfx("unpause")
		queue_redraw()
		return
	if not open:
		var to_map := Input.is_action_just_pressed("map")
		var debug_busy: bool = level.debug_menu != null and (level.debug_menu.open or level.debug_menu.closing)
		if (to_map or Input.is_action_just_pressed("pause")) and not level.transitioning and level.player.death_timer <= 0 and not debug_busy:
			open = true
			index = 1 if to_map else 0
			page = "map" if to_map else "menu"
			map_direct = to_map
			get_tree().paused = true
			Audio.play_sfx("pause")
			queue_redraw()
		return

	if page == "charms":
		if level.hud.charms.handle_input():
			level.hud.charms.close()
			page = "menu"
			Audio.play_sfx("back")
	elif page == "map":
		if InputSetup.back_pressed() or InputSetup.confirm_pressed() or Input.is_action_just_pressed("map"):
			if map_direct:
				closing = true
			else:
				page = "menu"
				Audio.play_sfx("back")
	elif page == "memories":
		if memories_view.handle_input():
			page = "menu"
	elif page == "glossary":
		if glossary_view.handle_input():
			page = "menu"
	elif page == "options":
		if options_panel.handle_input():
			page = "menu"
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
			"Mapa":
				page = "map"
				map_direct = false
			"Memórias":
				page = "memories"
			"Glossário":
				page = "glossary"
			"Opções":
				page = "options"
				options_panel.index = 0
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
	if page == "map":
		WorldMapView.draw(self, font, screen, level, Time.get_ticks_msec() / 1000.0)
		return
	if page == "memories":
		memories_view.draw(self, font, screen)
		return
	if page == "glossary":
		glossary_view.draw(self, font, screen)
		return
	if page == "options":
		options_panel.draw(self, font, Rect2(70, 30, screen.x - 140, screen.y - 60))
		return
	if page == "controls":
		var box := Rect2(50, 22, screen.x - 100, screen.y - 44)
		draw_rect(box, Color(0.02, 0.02, 0.06, 0.9))
		draw_rect(box, Color(1, 1, 1, 0.3), false, 1)
		draw_string(font, box.position + Vector2(0, 24), "Controles", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, GOLD)
		InputSetup.draw_controls(self, font, Rect2(box.position + Vector2(16, 40), box.size - Vector2(32, 60)))
		draw_string(font, Vector2(0, screen.y - 8), "K / Esc ou B para voltar", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 8, Color(1, 1, 1, 0.45))
		return
	draw_string(font, Vector2(0, 90), "Pausado", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 22, Color("ece6f5"))
	for i in OPTIONS.size():
		var selected := i == index
		var label: String = OPTIONS[i]
		if selected:
			label = ">  " + label + "  <"
		draw_string(font, Vector2(0, 122 + i * 18), label, HORIZONTAL_ALIGNMENT_CENTER, screen.x, 13,
			GOLD if selected else Color(1, 1, 1, 0.75))
