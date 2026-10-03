extends Control
## Caixa de diálogo. Enquanto está aberta, o jogo fica pausado (inimigos, chefes e o herói param).
## Falas do herói ("@expressão: texto") mostram o rosto dele à esquerda;
## falas do NPC mostram o desenho dele ampliado à direita.

const Paths := preload("res://data/asset_paths.gd")
const InputSetup := preload("res://game/core/input_setup.gd")
const GOLD := Color("e8c872")
const HERO_NAME := "Noct"
# Expressões de Noct (assets/hero/portrait_<nome>.png, recortadas por tools/slice_portraits.gd).
const FACES := [
	"neutro", "serio", "desconfiado", "irritado", "bravo", "furioso", "surpreso", "chocado", "confuso", "pensativo",
	"determinado", "confiante", "sorrindo", "sarcastico", "cansado", "triste", "dor", "ferido", "sangrando", "olhar_lateral",
	"olhar_cima", "olhar_baixo", "fechando_olhos", "calmo", "sombrio", "maligno", "magia_olhos", "magia_aura", "em_combate", "ultimate",
]

var level
var portraits := {}         # rostos já carregados (carregar durante o desenho deixava o rosto branco)
var speaker := ""
var lines: Array = []
var index := -1
var source: Node2D          # NPC/banco que abriu o diálogo (fecha se o herói se afastar)
var npc_tex: Texture2D      # desenho do NPC mostrado ao lado das falas dele


var auto_advance := 0.0     # > 0: cada fala passa sozinha depois desse tempo (comentários de Noct)
var auto_timer := 0.0
var opened_frame := -1      # o botão que abriu a conversa não pode já passar a 1ª fala
var closed_frame := -10


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


## A conversa acabou de fechar (neste quadro ou no anterior).
func just_closed() -> bool:
	return Engine.get_process_frames() - closed_frame <= 2


## auto > 0 faz as falas passarem sozinhas (comentários curtos que não exigem apertar nada).
func start(who: String, new_lines: Array, tex: Texture2D = null, auto := 0.0) -> void:
	speaker = who
	lines = new_lines
	npc_tex = tex
	index = 0
	source = null
	auto_advance = auto
	auto_timer = auto
	opened_frame = Engine.get_process_frames()
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
	# Volta o jogo, a não ser que o menu de pausa esteja aberto por cima.
	if was_open and not level.hud.pause.open:
		get_tree().paused = false
	queue_redraw()


func _process(delta: float) -> void:
	if is_open():
		queue_redraw()
		# Passar a fala (também adianta as que passam sozinhas).
		var pressed := Input.is_action_just_pressed("up") or InputSetup.confirm_pressed()
		if pressed and Engine.get_process_frames() > opened_frame and not level.hud.pause.open:
			auto_timer = auto_advance
			advance()
			return
		if auto_advance > 0:
			auto_timer -= delta
			if auto_timer <= 0:
				auto_timer = auto_advance
				advance()


func _draw() -> void:
	if not is_open():
		return
	var font := ThemeDB.fallback_font
	var player = level.player
	var box := Rect2(24, size.y - 92, size.x - 48, 80)
	draw_rect(box, Color(0, 0, 0, 0.85))
	draw_rect(box, Color(1, 1, 1, 0.35), false, 1)

	var line: String = lines[index]
	var who := speaker
	var text_x := box.position.x + 10
	var text_w := box.size.x - 20
	var name_color := GOLD

	if line.begins_with("@"):
		# Fala do herói. "@:" sem expressão escolhe sozinho: ferido com pouca vida.
		var sep := line.find(":")
		var face := line.substr(1, sep - 1).strip_edges()
		line = line.substr(sep + 1).strip_edges()
		if face == "" or not portraits.has(face):
			# "@:" escolhe pela vida: sangrando com 1, ferido com pouca, neutro no resto.
			if player.hp <= 1:
				face = "sangrando"
			elif player.hp <= maxi(1, player.max_hp / 3):
				face = "ferido"
			else:
				face = "neutro"
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
	draw_string(font, Vector2(text_x, box.end.y - 6), "%s >" % Controls.key_label("up"), HORIZONTAL_ALIGNMENT_RIGHT, text_w, 8, Color(1, 1, 1, 0.5))
