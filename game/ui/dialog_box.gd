extends Control
## Caixa de diálogo. Enquanto está aberta, o jogo fica pausado (inimigos, chefes e o herói param).
## Toda fala espera o botão para passar; nenhuma passa sozinha.
## Com "anchor", a fala vira um balão fixo e centralizado sobre esse ponto do mundo (comentário de chegada).
## Falas do herói ("@expressão: texto") mostram o rosto dele à esquerda;
## falas do NPC mostram o desenho dele ampliado à direita.

const Paths := preload("res://data/asset_paths.gd")
const GOLD := Color("e8c872")
const HERO_NAME := "Noct"
# Expressões de Noct (assets/hero/portrait_<nome>.png, recortadas por tools/slice_portraits.gd).
const FACES := [
	"neutro", "serio", "desconfiado", "irritado", "bravo", "furioso", "surpreso", "chocado", "confuso", "pensativo",
	"determinado", "confiante", "sorrindo", "sarcastico", "cansado", "triste", "dor", "ferido", "sangrando", "olhar_lateral",
	"olhar_cima", "olhar_baixo", "fechando_olhos", "calmo", "sombrio", "maligno", "magia_olhos", "magia_aura", "em_combate", "ultimate",
]

signal finished               # a conversa acabou (fechou)
signal chosen(option: int)    # resposta de uma escolha (ask)

var level
var portraits := {}         # rostos já carregados (carregar durante o desenho deixava o rosto branco)
var speaker := ""
var lines: Array = []
var index := -1
var source: Node2D          # NPC/banco que abriu o diálogo (fecha se o herói se afastar)
var npc_tex: Texture2D      # desenho do NPC mostrado ao lado das falas dele
var anchor := Vector2.INF  # ponto do mundo onde o balão fica preso (INF = caixa normal embaixo)
var opened_frame := -1      # o botão que abriu a conversa não pode já passar a 1ª fala
var closed_frame := -10
var closed_physics := -10   # o herói lê o botão no quadro de física, que pode vir alguns quadros depois
var choices: Array = []       # opções da escolha aberta (vazio = conversa normal)
var choice_index := 0
var nav_held := true
var was_held := true          # botão de passar fala já estava apertado no quadro anterior


func _ready() -> void:
	# Roda com o jogo pausado: é a própria caixa que lê o botão para passar as falas.
	process_mode = Node.PROCESS_MODE_ALWAYS
	for face in FACES:
		portraits[face] = load(Paths.HERO + "portrait_%s.png" % face)


## Rosto pelo nome da expressão (usado também no HUD).
func portrait(face: String) -> Texture2D:
	return portraits.get(face, portraits["neutro"])


func is_open() -> bool:
	return index >= 0


func _handle_choice() -> void:
	var nav := 0
	if Input.is_action_pressed("up") or Input.is_action_pressed("ui_up"):
		nav = -1
	elif Input.is_action_pressed("down") or Input.is_action_pressed("ui_down"):
		nav = 1
	if nav != 0 and not nav_held:
		choice_index = posmod(choice_index + nav, choices.size())
		Audio.play_sfx("hover", 0.0)
	nav_held = nav != 0
	var held := Input.is_action_pressed("jump") or Input.is_action_pressed("attack") or Input.is_action_pressed("ui_accept")
	var pressed := held and not was_held
	was_held = held
	if pressed and Engine.get_process_frames() > opened_frame:
		var picked := choice_index
		choices = []
		Audio.play_sfx("confirm", 0.0)
		close()
		chosen.emit(picked)


func _advance_held() -> bool:
	for action in ["up", "jump", "attack", "ui_accept"]:
		if Input.is_action_pressed(action):
			return true
	return false


## A conversa acabou de fechar (neste quadro ou no anterior).
func just_closed() -> bool:
	return Engine.get_process_frames() - closed_frame <= 2 or Engine.get_physics_frames() - closed_physics <= 1


## Escolha: mostra uma fala e as opções; cima/baixo escolhe, pulo/ataque confirma. Emite "chosen".
func ask(who: String, line: String, options: Array) -> void:
	start(who, [line])
	choices = options
	choice_index = 0
	nav_held = true


## at: ponto do mundo para mostrar a fala em balão sobre ele (ex.: cabeça do Noct ao entrar na sala).
func start(who: String, new_lines: Array, tex: Texture2D = null, at := Vector2.INF) -> void:
	speaker = who
	lines = new_lines
	npc_tex = tex
	index = 0
	source = null
	anchor = at
	opened_frame = Engine.get_process_frames()
	was_held = true   # o botão que abriu precisa ser solto antes de passar a fala
	get_tree().paused = true
	Audio.play_sfx("switch")
	queue_redraw()


## Passa para a próxima fala (fecha depois da última).
func advance() -> void:
	index += 1
	Audio.play_sfx("switch", 0.0, 1.2)
	if index >= lines.size():
		close()
	queue_redraw()


func close() -> void:
	var was_open := index >= 0
	index = -1
	closed_frame = Engine.get_process_frames()
	closed_physics = Engine.get_physics_frames()
	if was_open:
		finished.emit()
	# Volta o jogo, a não ser que o menu de pausa esteja aberto por cima.
	if was_open and not level.hud.pause.open:
		get_tree().paused = false
	queue_redraw()


func _process(_delta: float) -> void:
	if is_open():
		queue_redraw()
		# Passar a fala.
		if not choices.is_empty():
			_handle_choice()
			return
		# Borda do botão medida aqui (não pelo "just_pressed" do Input), para não perder toques rápidos.
		var held := _advance_held()
		var pressed := held and not was_held
		was_held = held
		if pressed and Engine.get_process_frames() > opened_frame and not level.hud.pause.open:
			advance()


## Separa "@expressão: texto" em [expressão, texto]. "@:" sem expressão escolhe pela vida:
## sangrando com 1, ferido com pouca, neutro no resto.
func _hero_face(line: String) -> Array:
	var sep := line.find(":")
	var face := line.substr(1, sep - 1).strip_edges()
	var text := line.substr(sep + 1).strip_edges()
	if face == "" or not portraits.has(face):
		var player = level.player
		if player.hp <= 1:
			face = "sangrando"
		elif player.hp <= maxi(1, player.max_hp / 3):
			face = "ferido"
		else:
			face = "neutro"
	return [face, text]


## Balão preso a um ponto do mundo, centralizado nele (fica parado mesmo se a câmera andar).
func _draw_balloon() -> void:
	var font := ThemeDB.fallback_font
	var line: String = lines[index]
	var face := ""
	var who := speaker
	if line.begins_with("* "):
		line = line.substr(2)
		who = ""
	elif line.begins_with("@"):
		var parsed := _hero_face(line)
		face = parsed[0]
		line = parsed[1]
		who = HERO_NAME
	var face_w := 34.0 if face != "" else 0.0
	var text_w := 170.0
	var text_h := font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, text_w, 10).y
	var w := face_w + text_w + 14
	var h := maxf(face_w + 6, 20 + text_h + 8)
	var head := get_viewport().get_canvas_transform() * anchor
	var x := clampf(head.x - w / 2, 4, size.x - w - 4)
	var y := clampf(head.y - 10 - h, 4, size.y - h - 4)
	var box := Rect2(x, y, w, h)
	# Ponta do balão apontando para o ponto de chegada.
	var tip_x := clampf(head.x, box.position.x + 8, box.end.x - 8)
	var tail := PackedVector2Array([Vector2(tip_x - 5, box.end.y), Vector2(tip_x + 5, box.end.y), Vector2(tip_x, box.end.y + 6)])
	draw_colored_polygon(tail, Color(0, 0, 0, 0.85))
	draw_rect(box, Color(0, 0, 0, 0.85))
	draw_rect(box, Color(1, 1, 1, 0.35), false, 1)
	var text_x := box.position.x + 7
	if face != "":
		var frame := Rect2(box.position + Vector2(3, 3), Vector2(32, 32))
		draw_rect(frame, Color(0.15, 0.05, 0.1))
		draw_texture_rect(portraits[face], frame, false)
		draw_rect(frame, Color(1, 0.3, 0.6, 0.7), false, 1)
		text_x = frame.end.x + 6
	var name_color := Color(1, 0.55, 0.75) if who == HERO_NAME else GOLD
	draw_string(font, Vector2(text_x, box.position.y + 13), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, name_color)
	draw_multiline_string(font, Vector2(text_x, box.position.y + 27), line, HORIZONTAL_ALIGNMENT_LEFT, text_w, 10)
	draw_string(font, Vector2(text_x, box.position.y + 13), "%s >" % Controls.key_label("up"), HORIZONTAL_ALIGNMENT_RIGHT, text_w, 8, Color(1, 1, 1, 0.5))


func _draw() -> void:
	if not is_open():
		return
	if anchor != Vector2.INF and choices.is_empty():
		_draw_balloon()
		return
	var font := ThemeDB.fallback_font
	var box := Rect2(24, size.y - 92, size.x - 48, 80)
	draw_rect(box, Color(0, 0, 0, 0.85))
	draw_rect(box, Color(1, 1, 1, 0.35), false, 1)

	var line: String = lines[index]
	var who := speaker
	var text_x := box.position.x + 10
	var text_w := box.size.x - 20
	var name_color := GOLD

	if line.begins_with("* "):
		# Narração: sem nome e sem desenho do personagem.
		line = line.substr(2)
		who = ""
	elif line.begins_with("@"):
		# Fala do herói, com o rosto dele.
		var parsed := _hero_face(line)
		var face: String = parsed[0]
		line = parsed[1]
		var frame := Rect2(box.position + Vector2(4, 4), Vector2(72, 72))
		draw_rect(frame, Color(0.15, 0.05, 0.1))
		draw_texture_rect(portraits[face], frame, false)
		draw_rect(frame, Color(1, 0.3, 0.6, 0.7), false, 1)
		who = HERO_NAME
		name_color = Color(1, 0.55, 0.75)
		text_x = frame.end.x + 8
		text_w = box.end.x - text_x - 10
	elif npc_tex:
		var tex_size := npc_tex.get_size()
		var k := minf(1.5, 70.0 / tex_size.y)
		var dest := Rect2(Vector2(box.end.x - tex_size.x * k - 8, box.end.y - tex_size.y * k - 3), tex_size * k)
		draw_texture_rect(npc_tex, dest, false)
		text_w = dest.position.x - text_x - 8

	draw_string(font, Vector2(text_x, box.position.y + 16), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, name_color)
	draw_multiline_string(font, Vector2(text_x, box.position.y + 32), line, HORIZONTAL_ALIGNMENT_LEFT, text_w, 10)
	if not choices.is_empty():
		for i in choices.size():
			var sel := i == choice_index
			draw_string(font, Vector2(text_x + 10, box.position.y + 50 + i * 13), ("> " if sel else "  ") + String(choices[i]),
				HORIZONTAL_ALIGNMENT_LEFT, text_w, 10, GOLD if sel else Color(1, 1, 1, 0.7))
		return
	draw_string(font, Vector2(text_x, box.end.y - 6), "%s >" % Controls.key_label("up"), HORIZONTAL_ALIGNMENT_RIGHT, text_w, 8, Color(1, 1, 1, 0.5))
