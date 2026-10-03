extends Node2D
## Cena final: o epílogo da escolha (GameState.ending_choice), o nome do final e os créditos rolando.
## Falas: "@rosto: texto" = Noct com o rosto; "Nome|texto" = outra pessoa; "* texto" = narração.
## Um botão passa a fala (ou ela passa sozinha); nos créditos, um botão volta ao título.

const Paths := preload("res://data/asset_paths.gd")
const TitleScript := preload("res://game/ui/title.gd")
const SCREEN := Vector2(480, 270)
const GOLD := Color("e8c872")
const LINE_TIME := 5.0
const CREDITS_SPEED := 18.0

const STAY := [
	"@fechando_olhos: ...",
	"* Noct dá um passo para dentro da fenda.",
	"* Lá dentro há uma voz que se parece com a dela. E um banco com dois lugares.",
	"* Ele se senta. Pela primeira vez em muito tempo, o outro lado não está vazio.",
	"* Mas a voz nunca ri do sarcasmo dele. Nunca sabe quando ele está mentindo.",
	"* Em Pedravelha, a fenda continua respirando. Ninguém mais a fecha.",
]
const LEAVE_START := [
	"@olhar_baixo: Ela fechou essa porta pra eu poder ir embora.",
	"@calmo: Não vou desperdiçar isso.",
	"* Noct desamarra a fita do pulso. Por um segundo, parece que vai deixá-la ali.",
	"* Amarra de novo. Mais firme.",
	"* A fenda se fecha devagar, como quem desiste de chamar.",
]
const LEAVE_TESSA := [
	"* Dias depois, em Pedravelha, ele está sentado numa ponta do banco. Alguém se senta na outra.",
	"@olhar_lateral: Esse lugar estava livre.",
	"Tessa|Eu percebi.",
	"Tessa|Você quase morreu.",
	"@neutro: Acontece.",
	"Tessa|Você não precisa fazer tudo sozinho.",
	"* Ele passa o polegar pela fita carmesim.",
	"@olhar_baixo: ...Preciso.",
	"Tessa|Por quê?",
	"* Por um segundo, parece que ele vai responder.",
	"@sarcastico: Você faz perguntas demais.",
	"* Ela fica. Ele também. Nenhum dos dois diz mais nada.",
	"* E ele não pede que ela vá embora.",
]
const LEAVE_ALONE := [
	"* Dias depois, em Pedravelha, ele está sentado numa ponta do banco.",
	"* O outro lado continua vazio. Mas desta vez ele fica um pouco mais.",
]
const LEAVE_END := [
	"@calmo: Um dia de cada vez.",
	"* Pela primeira vez, a frase não soa como sobreviver até amanhã.",
	"@fechando_olhos: ...Talvez amanhã valha a pena.",
]

var lines: Array = []
var title_card := ""
var index := 0
var line_t := 0.0
var t := 0.0
var phase := "story"        # story -> title -> credits
var phase_t := 0.0
var credits: Array = []      # [texto, tamanho, cor]
var credits_y := 0.0
var faces := {}
var embers := []
var was_held := true
var font: Font
var leaving := false


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(Color("07040a"))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	font = ThemeDB.fallback_font
	var stay: bool = GameState.ending_choice == "stay"
	if stay:
		lines = STAY.duplicate()
		title_card = "FINAL · ECO"
	else:
		lines = LEAVE_START.duplicate()
		lines.append_array(LEAVE_TESSA if GameState.flags.has("tessa_saved") else LEAVE_ALONE)
		lines.append_array(LEAVE_END)
		title_card = "FINAL · UM DIA DE CADA VEZ"
	for line in lines:
		var l: String = line
		if l.begins_with("@"):
			var face := l.substr(1, l.find(":") - 1)
			if not faces.has(face):
				faces[face] = load(Paths.HERO + "portrait_%s.png" % face)
	for i in 40:
		embers.append({"pos": Vector2(randf() * SCREEN.x, randf() * SCREEN.y), "speed": randf_range(6, 18), "phase": randf() * TAU})
	_build_credits()
	Audio.play_music(Paths.MUSIC_LIVING_SCORN, 1.0, 2.0)


func _build_credits() -> void:
	credits = [["NOCT: CRIMSON RIFT", 22, Color(0.95, 0.25, 0.38)], ["Break the Rift. Become the weapon.", 10, GOLD], ["", 10, Color.WHITE]]
	for c in TitleScript.CREDITS:
		credits.append([c[0], 11, GOLD])
		credits.append([c[1], 9, Color(1, 1, 1, 0.85)])
		credits.append(["", 8, Color.WHITE])
	credits.append(["", 30, Color.WHITE])
	credits.append(["Obrigado por jogar.", 14, Color(1, 0.8, 0.85)])
	credits.append(["Um dia de cada vez.", 10, Color(1, 1, 1, 0.6)])
	credits_y = SCREEN.y + 10


func _process(delta: float) -> void:
	t += delta
	phase_t += delta
	var held := Input.is_action_pressed("jump") or Input.is_action_pressed("attack") \
		or Input.is_action_pressed("up") or Input.is_action_pressed("ui_accept") or Input.is_action_pressed("pause")
	var pressed := held and not was_held
	was_held = held
	match phase:
		"story":
			line_t += delta
			if (pressed and line_t > 0.4) or line_t > LINE_TIME:
				index += 1
				line_t = 0.0
				if index >= lines.size():
					phase = "title"
					phase_t = 0.0
					Audio.play_sfx("thunder", 0.0, 0.7)
		"title":
			if phase_t > 4.0 or (pressed and phase_t > 1.0):
				phase = "credits"
				phase_t = 0.0
		"credits":
			credits_y -= CREDITS_SPEED * delta * (3.0 if held else 1.0)
			if credits_y + credits.size() * 16 < -20 or (pressed and Input.is_action_pressed("pause")):
				_back_to_title()
	queue_redraw()


func _back_to_title() -> void:
	if leaving:
		return
	leaving = true
	await Audio.fade_out_music(1.0)
	get_tree().change_scene_to_file("res://game/ui/title.tscn")


func _draw() -> void:
	# Fundo: escuro com brasas subindo; no final "Um dia de cada vez" amanhece aos poucos.
	var dawn := 0.0
	if GameState.ending_choice != "stay" and phase == "story":
		dawn = clampf(float(index - (lines.size() - LEAVE_END.size())) / LEAVE_END.size(), 0.0, 1.0)
	elif GameState.ending_choice != "stay":
		dawn = 1.0
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.03, 0.015, 0.04).lerp(Color(0.16, 0.08, 0.12), dawn))
	for e in embers:
		var p: Vector2 = e["pos"]
		p.y = fposmod(p.y - t * e["speed"], SCREEN.y)
		p.x += sin(t + e["phase"]) * 6
		var a := 0.3 + 0.3 * sin(t * 2 + e["phase"])
		draw_circle(p, 1.2, Color(1, 0.25, 0.35, a))
	match phase:
		"story":
			_draw_line()
		"title":
			var a := clampf(phase_t, 0, 1) * clampf(4.0 - phase_t, 0, 1)
			draw_string(font, Vector2(0, SCREEN.y / 2), title_card, HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 18, Color(1, 0.8, 0.85, a))
		"credits":
			var y := credits_y
			for c in credits:
				if y > -20 and y < SCREEN.y + 20:
					draw_string(font, Vector2(20, y), c[0], HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x - 40, c[1], c[2])
				y += c[1] + 7
			draw_string(font, Vector2(0, SCREEN.y - 6), "Segure um botão para acelerar   Esc pula",
				HORIZONTAL_ALIGNMENT_CENTER, SCREEN.x, 7, Color(1, 1, 1, 0.35))


func _draw_line() -> void:
	if index >= lines.size():
		return
	var line: String = lines[index]
	var a := clampf(line_t * 2.5, 0, 1)
	var text_box := Rect2(60, 110, SCREEN.x - 120, 60)
	var color := Color(1, 1, 1, 0.75 * a)
	var who := ""
	if line.begins_with("@"):
		var sep := line.find(":")
		var face: Texture2D = faces[line.substr(1, sep - 1)]
		line = line.substr(sep + 1).strip_edges()
		draw_texture_rect(face, Rect2(text_box.position.x, text_box.position.y - 6, 56, 56), false, Color(1, 1, 1, a))
		draw_rect(Rect2(text_box.position.x, text_box.position.y - 6, 56, 56), Color(1, 0.3, 0.6, 0.6 * a), false, 1)
		text_box.position.x += 66
		text_box.size.x -= 66
		who = "Noct"
		color = Color(1, 0.92, 0.95, a)
	elif "|" in line:
		who = line.get_slice("|", 0)
		line = line.get_slice("|", 1)
		color = Color(0.85, 0.9, 1, a)
	elif line.begins_with("* "):
		line = line.substr(2)
	if who != "":
		draw_string(font, text_box.position + Vector2(0, 8), who, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(GOLD, a))
	draw_multiline_string(font, text_box.position + Vector2(0, 26), line, HORIZONTAL_ALIGNMENT_LEFT, text_box.size.x, 11, -1, color)
