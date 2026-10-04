extends RefCounted
## Cria as ações de teclado e controle usadas no jogo inteiro (título, jogo e pausa).


static func setup() -> void:
	# Já configurado (ex.: voltando do jogo para o título).
	if InputMap.has_action("map"):
		return

	var keys := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"up": [KEY_W, KEY_UP],
		"down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE, KEY_Z],
		"attack": [KEY_J, KEY_X],
		"dash": [KEY_K, KEY_SHIFT, KEY_C],
		"spell": [KEY_L, KEY_V],
		"pause": [KEY_ESCAPE, KEY_P],
		"map": [KEY_M, KEY_TAB],
		"ultimate": [KEY_U],
		"transform": [KEY_R],      # Forma Demoníaca (barra da Fenda cheia)
		"debug_menu": [KEY_F1],    # atalho de teste: menu de hacks (também no jogo exportado)
		"debug_soul": [KEY_F2],    # atalho de teste: enche alma e vida
		"debug_crimson": [KEY_F3], # atalho de teste: troca a forma carmesim (0 -> 1 -> 2 -> 3 -> 0)
	}
	for action in keys:
		InputMap.add_action(action, 0.4)
		for key in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

	# Controle (layout Xbox, igual ao Hollow Knight): A pula, X ataca, B magia/cura,
	# RT ou RB dash, LB mapa, Start pausa, analógico esquerdo ou direcional para andar e mirar.
	var pad_buttons := {
		"move_left": [JOY_BUTTON_DPAD_LEFT],
		"move_right": [JOY_BUTTON_DPAD_RIGHT],
		"up": [JOY_BUTTON_DPAD_UP],
		"down": [JOY_BUTTON_DPAD_DOWN],
		"jump": [JOY_BUTTON_A],
		"attack": [JOY_BUTTON_X],
		"spell": [JOY_BUTTON_B],
		"dash": [JOY_BUTTON_RIGHT_SHOULDER],
		"pause": [JOY_BUTTON_START],
		"map": [JOY_BUTTON_LEFT_SHOULDER],
		"ultimate": [JOY_BUTTON_Y],
		"transform": [JOY_BUTTON_RIGHT_STICK],
		"debug_menu": [JOY_BUTTON_BACK],
		"debug_crimson": [JOY_BUTTON_LEFT_STICK],
	}
	for action in pad_buttons:
		for button in pad_buttons[action]:
			var ev := InputEventJoypadButton.new()
			ev.button_index = button
			InputMap.action_add_event(action, ev)
	var pad_axes := {
		"move_left": [JOY_AXIS_LEFT_X, -1.0],
		"move_right": [JOY_AXIS_LEFT_X, 1.0],
		"up": [JOY_AXIS_LEFT_Y, -1.0],
		"down": [JOY_AXIS_LEFT_Y, 1.0],
		"dash": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	}
	for action in pad_axes:
		var ev := InputEventJoypadMotion.new()
		ev.axis = pad_axes[action][0]
		ev.axis_value = pad_axes[action][1]
		InputMap.action_add_event(action, ev)
	# Cima/baixo no analógico exigem mais inclinação, para não falar com NPC ou
	# atacar para cima sem querer enquanto anda.
	InputMap.action_set_deadzone("up", 0.6)
	InputMap.action_set_deadzone("down", 0.6)


## Menus: confirmar com pulo/ataque/Enter, voltar com dash/magia/Esc.
static func confirm_pressed() -> bool:
	return Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack") \
		or Input.is_action_just_pressed("ui_accept")


static func back_pressed() -> bool:
	return Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("spell") \
		or Input.is_action_just_pressed("pause")


const CONTROLS := [
	["Andar", "A / D", "Analógico / Direcional"],
	["Pular (2x no ar)", "Espaço", "A"],
	["Atacar (+ cima/baixo) / segurar: carregar", "J", "X"],
	["Dash", "K", "RT / RB"],
	["Magia (toque) / Curar (segurar)", "L", "B"],
	["Trovão", "W + L", "Cima + B"],
	["Falar / Descansar / Loja", "W", "Cima"],
	["Ultimate (alma cheia, nível 10)", "U", "Y"],
	["Forma Demoníaca (barra da Fenda cheia)", "R", "Analógico dir."],
	["Mapa", "M / Tab", "LB"],
	["Pausa", "Esc", "Start"],
	["Teste: menu de hacks / encher alma", "F1 / F2", "Select"],
	["Teste: forma carmesim", "F3", "Analógico esq."],
]


## Desenha a tabela de controles (usada no título e na pausa).
static func draw_controls(ci: CanvasItem, font: Font, rect: Rect2) -> void:
	var gold := Color("e8c872")
	var cols := [rect.position.x, rect.position.x + rect.size.x * 0.52, rect.position.x + rect.size.x * 0.7]
	var heads := ["Ação", "Teclado", "Controle"]
	for c in 3:
		ci.draw_string(font, Vector2(cols[c], rect.position.y), heads[c], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, gold)
	ci.draw_line(Vector2(rect.position.x, rect.position.y + 5), Vector2(rect.end.x, rect.position.y + 5), Color(1, 1, 1, 0.2))
	var y := rect.position.y + 20
	for row in CONTROLS:
		for c in 3:
			ci.draw_string(font, Vector2(cols[c], y), row[c], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.85))
		y += 15