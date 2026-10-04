extends RefCounted
## Aba "Glossário" da pausa: os personagens do jogo (data/glossary.gd). Cima/baixo escolhe o verbete,
## esquerda/direita troca a página do texto quando ele não cabe. Verbetes ainda não conhecidos
## aparecem como "???"; os parágrafos entram conforme a história avança.

const InputSetup := preload("res://game/core/input_setup.gd")
const Glossary := preload("res://data/glossary.gd")
const GOLD := Color("e8c872")
const RIBBON := Color(0.9, 0.15, 0.3)
const ROW := 14          # altura de cada nome na lista
const TEXT_SIZE := 10
const LINE := 13         # altura de cada linha do texto

var index := 0
var page := 0
var pages := 1           # calculado ao desenhar (depende da fonte)
var scroll := 0          # primeiro nome visível da lista


## Retorna true quando o jogador sai da aba.
func handle_input() -> bool:
	if InputSetup.back_pressed() or Input.is_action_just_pressed("ui_cancel"):
		Audio.play_sfx("back", 0.0)
		return true
	if Input.is_action_just_pressed("up") or Input.is_action_just_pressed("ui_up"):
		index = posmod(index - 1, Glossary.ORDER.size())
		page = 0
		Audio.play_sfx("hover", 0.0)
	elif Input.is_action_just_pressed("down") or Input.is_action_just_pressed("ui_down"):
		index = posmod(index + 1, Glossary.ORDER.size())
		page = 0
		Audio.play_sfx("hover", 0.0)
	elif (Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right")) and page < pages - 1:
		page += 1
		Audio.play_sfx("hover", 0.0)
	elif (Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left")) and page > 0:
		page -= 1
		Audio.play_sfx("hover", 0.0)
	return false


static func is_known(id: String) -> bool:
	return Glossary.unlocked(Glossary.ENTRIES[id]["requires"])


func draw(ci: CanvasItem, font: Font, screen: Vector2) -> void:
	var box := Rect2(16, 18, screen.x - 32, screen.y - 36)
	ci.draw_rect(box, Color(0.02, 0.02, 0.06, 0.92))
	ci.draw_rect(box, Color(1, 1, 1, 0.3), false, 1)
	var known := 0
	for id in Glossary.ORDER:
		if is_known(id):
			known += 1
	ci.draw_string(font, box.position + Vector2(0, 20), "Glossário  %d/%d" % [known, Glossary.ORDER.size()],
		HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 14, GOLD)

	# Lista de nomes (rola para manter o selecionado visível).
	var list_x := box.position.x + 14
	var list_top := box.position.y + 44
	var visible := int((box.size.y - 66) / ROW)
	scroll = clampi(scroll, index - visible + 1, index)
	scroll = clampi(scroll, 0, maxi(0, Glossary.ORDER.size() - visible))
	for row in visible:
		var i := scroll + row
		if i >= Glossary.ORDER.size():
			break
		var id: String = Glossary.ORDER[i]
		var has := is_known(id)
		var y := list_top + row * ROW
		var r := Rect2(list_x, y - 7, 5, 7)
		if has:
			ci.draw_rect(r, RIBBON)
		else:
			ci.draw_rect(r, Color(RIBBON, 0.5), false, 1)
		ci.draw_string(font, Vector2(list_x + 10, y), Glossary.ENTRIES[id]["name"] if has else "???",
			HORIZONTAL_ALIGNMENT_LEFT, 150, 10, GOLD if i == index else Color(1, 1, 1, 0.8 if has else 0.4))
	if scroll > 0:
		ci.draw_string(font, Vector2(list_x + 60, list_top - 13), "^", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.5))
	if scroll + visible < Glossary.ORDER.size():
		ci.draw_string(font, Vector2(list_x + 60, list_top + visible * ROW - 4), "v", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.5))

	# Texto do verbete escolhido.
	var text_box := Rect2(box.position.x + 182, box.position.y + 34, box.size.x - 196, box.size.y - 56)
	ci.draw_rect(text_box, Color(0.12, 0.02, 0.05, 0.6))
	ci.draw_rect(text_box, Color(RIBBON, 0.4), false, 1)
	var sel: String = Glossary.ORDER[index]
	if not is_known(sel):
		pages = 1
		ci.draw_string(font, text_box.get_center() + Vector2(-text_box.size.x / 2, 0), "Ainda não conhecido.",
			HORIZONTAL_ALIGNMENT_CENTER, text_box.size.x, 10, Color(1, 1, 1, 0.4))
	else:
		var entry: Dictionary = Glossary.ENTRIES[sel]
		var x := text_box.position.x + 10
		ci.draw_string(font, Vector2(x, text_box.position.y + 16), entry["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
		ci.draw_string(font, Vector2(x, text_box.position.y + 28), entry["role"], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.5))
		# Quebra os parágrafos em linhas e divide em páginas.
		var width := text_box.size.x - 20
		var lines := []
		for paragraph in Glossary.text_of(sel):
			if not lines.is_empty():
				lines.append("")
			lines.append_array(wrap_text(font, paragraph, width, TEXT_SIZE))
		var per_page := int((text_box.size.y - 52) / LINE)
		pages = maxi(1, ceili(float(lines.size()) / per_page))
		page = clampi(page, 0, pages - 1)
		var y := text_box.position.y + 46
		for i in range(page * per_page, mini(lines.size(), (page + 1) * per_page)):
			ci.draw_string(font, Vector2(x, y), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, TEXT_SIZE, Color(1, 0.92, 0.95))
			y += LINE
		if pages > 1:
			ci.draw_string(font, Vector2(text_box.position.x, text_box.end.y - 6), "<  %d/%d  >" % [page + 1, pages],
				HORIZONTAL_ALIGNMENT_CENTER, text_box.size.x, 8, Color(1, 1, 1, 0.55))
	ci.draw_string(font, Vector2(box.position.x, box.end.y - 8), "K / Esc volta   ", HORIZONTAL_ALIGNMENT_RIGHT, box.size.x, 8, Color(1, 1, 1, 0.45))


## Quebra um texto em linhas que cabem na largura.
static func wrap_text(font: Font, text: String, width: float, size: int) -> Array:
	var out := []
	var line := ""
	for word in text.split(" ", false):
		var attempt := word if line == "" else line + " " + word
		if line != "" and font.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			out.append(line)
			line = word
		else:
			line = attempt
	if line != "":
		out.append(line)
	return out
