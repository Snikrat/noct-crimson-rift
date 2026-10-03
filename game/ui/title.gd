extends Node2D
## Tela de título: céu noturno em camadas, vagalumes, música e menu (Jogar, Controles, Créditos, Sair).

const InputSetup := preload("res://game/core/input_setup.gd")

const Paths := preload("res://data/asset_paths.gd")
const FINAL := Paths.TITLE_BG
const MUSIC := Paths.MUSIC_TITLE
const LOGO := Paths.LOGO   # quadros em pixel art feitos no Aseprite por tools/make_logo.lua

# Logo animado: abertura (a fenda se abre e as letras se formam), loop pulsando e saída ao começar.
const LOGO_INTRO := [0, 1, 2, 3, 4, 5, 6, 7]
const LOGO_LOOP := [8, 9, 10, 11, 12, 13]
const LOGO_OUTRO := 14
const LOGO_COUNT := 15
const LOGO_INTRO_FPS := 11.0
const LOGO_LOOP_FRAME := 0.24          # segundos por quadro do loop
const LOGO_DELAY := 0.5                # espera o fade da tela antes de abrir a fenda
const LOGO_POS := Vector2(90, 4)       # o logo é desenhado 1:1 (300x112 pixels de jogo)

const GAME_SCENE := "res://game/world/main.tscn"

const SCREEN := Vector2(480, 270)
const LAYER_SCALE := 270.0 / 416.0   # as camadas têm 416px de altura
const GOLD := Color("e8c872")
# "Continuar" só aparece quando existe um jogo salvo.
const OptionsPanel := preload("res://game/ui/options_panel.gd")
const OPTIONS_NEW := ["Novo jogo", "Opções", "Controles", "Créditos", "Sair"]
const OPTIONS_SAVE := ["Continuar", "Novo jogo", "Opções", "Controles", "Créditos", "Sair"]

const CREDITS := [
	["Noct e logo", "Arte criada para o jogo"],
	["Arte", "Luis Zuno (ansimuz) - Gothicvania, Legacy Collection, Magic Pack (CC0)"],
	["Tela de título", "Anokolisa - pacote Final"],
	["Bringer of Death", "Clembod (clembod.itch.io)"],
	["Inferno", "Demon Slime (itch.io) e Legacy Collection (ansimuz)"],
	["Música", "Music by YannZ - https://yannz41.itch.io"],
	["Música", "Tom Feldmann e David J. Barrios (CC BY 4.0), vitalezzz, MintoDog, Pascal Belisle"],
	["Sons", "RPG Essentials SFX (Leohpaz) e Gothicvania (ansimuz)"],
	["Motor", "Godot Engine 4"],
]

var layers := []
var fireflies := []
var t := 0.0
var index := 0
var page := "menu"
var fade := 1.0
var starting := false
var save_error := ""
var options: Array = OPTIONS_NEW
var options_panel := OptionsPanel.new()
var font: Font
var logo_frames: Array[Texture2D] = []
var logo_t := -LOGO_DELAY      # tempo da animação do logo
var outro_t := -1.0             # >= 0: o logo está se desfazendo
var logo_boom := false
var logo_layer := Node2D.new()   # o logo fica num nó próprio com filtro nítido (pixel art)


func _ready() -> void:
	InputSetup.setup()
	Engine.time_scale = 1.0
	get_tree().paused = false
	RenderingServer.set_default_clear_color(Color("0b0d1a"))
	# As camadas são reduzidas para caber na tela, então usam filtro suave.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	font = ThemeDB.fallback_font

	# [textura, velocidade em px/s] do fundo para a frente.
	for l in [["Background_0", 3.0], ["Background_1", 8.0], ["Grass_background_2", 16.0], ["Grass_background_1", 26.0]]:
		layers.append({"tex": load(FINAL + l[0] + ".png"), "speed": l[1]})

	logo_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo_layer.draw.connect(_draw_logo)
	add_child(logo_layer)
	for i in LOGO_COUNT:
		logo_frames.append(load(LOGO + "logo_%02d.png" % i))

	for i in 28:
		fireflies.append({
			"pos": Vector2(randf() * SCREEN.x, randf_range(120, 260)),
			"phase": randf() * TAU,
			"speed": randf_range(0.4, 1.0),
		})

	options = OPTIONS_SAVE if GameState.has_save() else OPTIONS_NEW
	Audio.play_music(MUSIC, 1.0, 2.0)


func _process(delta: float) -> void:
	t += delta
	logo_t += delta
	if outro_t >= 0:
		outro_t += delta
	# Quando as letras se formam: trovão e clarão.
	if not logo_boom and logo_t >= 6.0 / LOGO_INTRO_FPS:
		logo_boom = true
		Audio.play_sfx("thunder", 0.0, 0.8)
	if starting:
		fade = minf(fade + delta * 1.5, 1.0)
	else:
		fade = maxf(fade - delta * 1.2, 0.0)
		_handle_input()
	queue_redraw()
	logo_layer.queue_redraw()


func _handle_input() -> void:
	if fade > 0.6:
		return
	if page == "options":
		if options_panel.handle_input():
			page = "menu"
		return
	if page != "menu":
		if InputSetup.back_pressed() or InputSetup.confirm_pressed() or Input.is_action_just_pressed("ui_cancel"):
			page = "menu"
			Audio.play_sfx("back", 0.0)
		return
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("ui_up"):
		index = posmod(index - 1, options.size())
		Audio.play_sfx("hover", 0.0)
	elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("ui_down"):
		index = posmod(index + 1, options.size())
		Audio.play_sfx("hover", 0.0)
	elif InputSetup.confirm_pressed():
		Audio.play_sfx("confirm", 0.0)
		match options[index]:
			"Continuar":
				_start_game(true)
			"Novo jogo":
				_start_game(false)
			"Opções":
				page = "options"
				options_panel.index = 0
			"Controles":
				page = "controls"
			"Créditos":
				page = "credits"
			"Sair":
				get_tree().quit()


## Começa o jogo: "Continuar" carrega o save; "Novo jogo" começa do zero.
func _start_game(continue_save: bool) -> void:
	if continue_save and not GameState.load_game():
		save_error = "Não foi possível carregar o save."
		Audio.play_sfx("denied")
		return
	save_error = ""
	starting = true
	outro_t = 0.0
	Audio.play_sfx("explosion", 0.0, 0.7)
	if not continue_save:
		GameState.reset()
	await Audio.fade_out_music(0.7)
	get_tree().change_scene_to_file(GAME_SCENE)


func _draw() -> void:
	# Camadas com rolagem lenta e infinita.
	for l in layers:
		var tex: Texture2D = l["tex"]
		var w := tex.get_width() * LAYER_SCALE
		var x := -fposmod(t * l["speed"], w)
		while x < SCREEN.x:
			draw_texture_rect(tex, Rect2(x, 0, w + 1, SCREEN.y), false)
			x += w

	# Vagalumes piscando e flutuando.
	for f in fireflies:
		var p: Vector2 = f["pos"] + Vector2(sin(t * f["speed"] + f["phase"]) * 14, cos(t * f["speed"] * 0.7 + f["phase"]) * 9)
		p.x = fposmod(p.x + t * 6, SCREEN.x)
		var a := 0.35 + 0.65 * absf(sin(t * 1.7 * f["speed"] + f["phase"]))
		draw_circle(p, 3.0, Color(1, 0.8, 0.35, a * 0.15))
		draw_circle(p, 1.1, Color(1, 0.9, 0.5, a))

	# Escurece o centro para o texto se destacar.
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.02, 0.02, 0.08, 0.25))

	match page:
		"menu":
			_draw_menu()
		"options":
			options_panel.draw(self, font, Rect2(70, 30, SCREEN.x - 140, SCREEN.y - 60))
		"controls":
			var box := _panel("Controles")
			InputSetup.draw_controls(self, font, Rect2(box.position + Vector2(16, 40), box.size - Vector2(32, 60)))
			_footer()
		"credits":
			_draw_credits()

	if fade > 0:
		draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0, 0, 0, fade))


func _draw_menu() -> void:
	if save_error != "":
		draw_string(font, Vector2(0, 252), save_error, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 9, GOLD)


	for i in options.size():
		var y := 146.0 + i * 18
		var selected := i == index
		var color := GOLD if selected else Color(1, 1, 1, 0.75)
		var label: String = options[i]
		if selected:
			label = ">  " + label + "  <"
		draw_string_outline(font, Vector2(0, y), label, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 13, 4, Color(0, 0, 0, 0.85))
		draw_string(font, Vector2(0, y), label, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 13, color)

	draw_string(font, Vector2(0, SCREEN.y - 8), "W/S ou direcional para escolher   Espaço/J ou A para confirmar",
		HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 8, Color(1, 1, 1, 0.45))


## Logo animado (desenhado no nó logo_layer, por cima do fundo): abertura quadro a quadro,
## loop do fogo e da fenda pulsando, e a saída quando o jogo começa. Some fora do menu.
func _draw_logo() -> void:
	if logo_t < 0 or page != "menu":
		return
	var intro_len := LOGO_INTRO.size() / LOGO_INTRO_FPS
	if outro_t >= 0:
		var k := minf(outro_t / 0.5, 1.0)
		_logo_frame(LOGO_LOOP[0], 1.0 - k)
		_logo_frame(LOGO_OUTRO, 1.0 - maxf(outro_t - 0.5, 0.0) * 2.0)
	elif logo_t < intro_len:
		_logo_frame(LOGO_INTRO[int(logo_t * LOGO_INTRO_FPS)], 1.0)
	else:
		var i := int((logo_t - intro_len) / LOGO_LOOP_FRAME)
		_logo_frame(LOGO_LOOP[i % LOGO_LOOP.size()], 1.0)


func _logo_frame(i: int, alpha: float) -> void:
	# O escurecimento da tela é desenhado embaixo deste nó, então o logo também apaga com ele.
	alpha *= 1.0 - fade
	if alpha > 0:
		logo_layer.draw_texture(logo_frames[i], LOGO_POS, Color(1, 1, 1, alpha))


func _draw_credits() -> void:
	var box := _panel("Créditos")
	var y := box.position.y + 44
	for c in CREDITS:
		draw_string(font, Vector2(box.position.x + 16, y), c[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, GOLD)
		draw_string(font, Vector2(box.position.x + 16, y + 12), c[1], HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 32, 9, Color(1, 1, 1, 0.85))
		y += 20
	_footer()


func _panel(title: String) -> Rect2:
	var box := Rect2(50, 22, SCREEN.x - 100, SCREEN.y - 44)
	draw_rect(box, Color(0.02, 0.02, 0.06, 0.88))
	draw_rect(box, Color(1, 1, 1, 0.3), false, 1)
	draw_string(font, box.position + Vector2(0, 24), title, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, GOLD)
	return box


func _footer() -> void:
	draw_string(font, Vector2(0, SCREEN.y - 8), "K / Esc ou B para voltar", HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 8, Color(1, 1, 1, 0.45))
