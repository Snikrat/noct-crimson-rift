extends Control
## Menu de hacks para testar o jogo (F1 / Select). Fica ativo também no jogo exportado (DEBUG_KEYS em main.gd),
## inclusive no .exe de release. Não grava o save sozinho: ele só é salvo ao descansar num banco.

const InputSetup := preload("res://game/core/input_setup.gd")
const Rooms := preload("res://data/rooms.gd")
const Progression := preload("res://data/progression.gd")
const GOLD := Color("e8c872")
const INFINITE_GEO := 99999
const SKILLS := ["combo", "wave", "charged", "uppercut", "slam", "ultimate", "demon1"]

var level
var open := false
var closing := false
var index := 0
var room_index := 0
var rooms: Array = Rooms.ROOMS.keys()

# Hacks ligados (continuam valendo com o menu fechado).
var infinite_soul := false
var infinite_geo := false
var god_mode := false        # lido por player_body.gd (_take_damage)
var all_powers := false      # lido por main.gd (Garras do Gato e Passo da Fenda sem os chefes)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _options() -> Array:
	return [
		"Ir para: < %s >" % Rooms.ROOMS[rooms[room_index]]["title"],
		"Subir um nível",
		"Nível máximo",
		"Encher vida e alma",
		"Alma infinita: %s" % _on_off(infinite_soul),
		"Geo infinito: %s" % _on_off(infinite_geo),
		"Invencível: %s" % _on_off(god_mode),
		"Liberar habilidades: %s" % _on_off(all_powers),
		"Forma carmesim: %d" % level.player.crimson_level,
		"Forma Demoníaca: liberar e encher a barra",
		"Fechar",
	]


func _on_off(value: bool) -> String:
	return "LIGADO" if value else "desligado"


func _process(_delta: float) -> void:
	_apply_hacks()
	# Igual à pausa: só devolve o jogo quando o botão usado para fechar for solto.
	if closing:
		for action in ["jump", "attack", "dash", "spell", "pause", "debug_menu"]:
			if Input.is_action_pressed(action):
				return
		closing = false
		open = false
		get_tree().paused = level.is_dialog_open()
		queue_redraw()
		return
	if not open:
		if Input.is_action_just_pressed("debug_menu") and not get_tree().paused \
				and not level.transitioning and level.player.death_timer <= 0:
			open = true
			room_index = maxi(rooms.find(level.room_name), 0)
			get_tree().paused = true
			Audio.play_sfx("pause")
			queue_redraw()
		return

	var count := _options().size()
	if InputSetup.back_pressed() or Input.is_action_just_pressed("debug_menu"):
		closing = true
		Audio.play_sfx("back")
	elif Input.is_action_just_pressed("up"):
		index = posmod(index - 1, count)
		Audio.play_sfx("hover", 0.0)
	elif Input.is_action_just_pressed("down"):
		index = posmod(index + 1, count)
		Audio.play_sfx("hover", 0.0)
	elif index == 0 and (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("move_right")):
		room_index = posmod(room_index + (1 if Input.is_action_just_pressed("move_right") else -1), rooms.size())
		Audio.play_sfx("hover", 0.0)
	elif InputSetup.confirm_pressed():
		Audio.play_sfx("confirm", 0.0)
		_choose(index)
	queue_redraw()


func _choose(option: int) -> void:
	var p = level.player
	match option:
		0:
			closing = true
			level.use_passage(rooms[room_index], "B")
		1:
			level_up()
		2:
			while p.lvl < Progression.MAX_LEVEL:
				level_up()
		3:
			p.hp = p.max_hp
			p.soul = p.MAX_SOUL
		4:
			infinite_soul = not infinite_soul
		5:
			infinite_geo = not infinite_geo
		6:
			god_mode = not god_mode
		7:
			all_powers = not all_powers
			if all_powers:
				for skill in SKILLS:
					p.unlocked[skill] = true
		8:
			level.cycle_crimson()
		9:
			p.unlocked["demon1"] = true
			p.demon.gauge = p.demon.MAX_GAUGE
			level.hud.show_banner("Barra da Fenda cheia: aperte %s" % Controls.key_label("transform"), 1.8)
		10:
			closing = true
	level.refresh_hud()


## Sobe um nível pelo caminho normal (recompensas e aviso de nível).
func level_up() -> void:
	var p = level.player
	if p.lvl < Progression.MAX_LEVEL:
		p.gain_xp(Progression.XP_FOR_LEVEL[p.lvl + 1] - p.xp)
	else:
		level.hud.show_banner("Nível máximo", 1.5)


func _apply_hacks() -> void:
	var p = level.player
	if infinite_soul and p.soul < p.MAX_SOUL:
		p.soul = p.MAX_SOUL
		level.refresh_hud()
	if infinite_geo and GameState.geo < INFINITE_GEO:
		GameState.geo = INFINITE_GEO
		level.refresh_hud()


func _draw() -> void:
	if not open:
		return
	var font := ThemeDB.fallback_font
	var screen := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0, 0, 0, 0.6))
	var box := Rect2(60, 22, screen.x - 120, screen.y - 44)
	draw_rect(box, Color(0.02, 0.02, 0.06, 0.92))
	draw_rect(box, Color(1, 1, 1, 0.3), false, 1)
	draw_string(font, box.position + Vector2(0, 22), "Hacks de teste", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, GOLD)
	var options := _options()
	for i in options.size():
		var selected := i == index
		var label: String = ("> " if selected else "  ") + options[i]
		draw_string(font, box.position + Vector2(18, 44 + i * 17), label, HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 36, 11,
			GOLD if selected else Color(1, 1, 1, 0.75))
	var hint := "Esq./dir. troca a sala · Pulo confirma · F1 ou K fecha"
	draw_string(font, Vector2(0, box.end.y - 8), hint, HORIZONTAL_ALIGNMENT_CENTER, screen.x, 8, Color(1, 1, 1, 0.45))
