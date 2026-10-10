extends Control
## Tela de amuletos (aberta pela pausa): mostra os encaixes, os amuletos que você tem
## e permite equipar/remover quando o herói está ao lado de um banco.

const Charms := preload("res://data/charms.gd")
const GOLD := Color("e8c872")
const PINK := Color(1, 0.35, 0.6)
const COLS := 5

var level
var opened := false
var index := 0
var msg := ""
var icons := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in Charms.ORDER:
		icons[id] = Charms.icon(id)


func is_open() -> bool:
	return opened


func open() -> void:
	opened = true
	msg = ""
	queue_redraw()


func close() -> void:
	opened = false
	queue_redraw()


## Encaixes ocupados pelos amuletos equipados.
static func used_notches() -> int:
	var n := 0
	for id in GameState.equipped_charms:
		n += Charms.CHARMS[id]["cost"]
	return n


## Trata o input enquanto aberta. Retorna true quando o jogador pede para voltar.
func handle_input() -> bool:
	var count: int = Charms.ORDER.size()
	if Input.is_action_just_pressed("move_left"):
		index = posmod(index - 1, count)
	elif Input.is_action_just_pressed("move_right"):
		index = posmod(index + 1, count)
	elif Input.is_action_just_pressed("up"):
		index = posmod(index - COLS, count)
	elif Input.is_action_just_pressed("down"):
		index = posmod(index + COLS, count)
	elif Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("jump") \
			or Input.is_action_just_pressed("ui_accept"):
		_toggle(Charms.ORDER[index])
	elif Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("spell") \
			or Input.is_action_just_pressed("pause"):
		return true
	else:
		return false
	queue_redraw()
	return false


func _toggle(id: String) -> void:
	if not GameState.owned_charms.has(id):
		msg = "Você ainda não tem este amuleto."
		return
	if not level.is_at_bench():
		msg = "Troque amuletos sentado num banco."
		Audio.play_sfx("denied")
		return
	var equipped: Array = GameState.equipped_charms
	if equipped.has(id):
		equipped.erase(id)
		msg = "Removido."
		Audio.play_sfx("unequip")
	elif used_notches() + Charms.CHARMS[id]["cost"] > Charms.NOTCHES:
		msg = "Encaixes insuficientes."
		Audio.play_sfx("denied")
		return
	else:
		equipped.append(id)
		msg = "Equipado!"
		Audio.play_sfx("equip")
	level.player.on_charms_changed()
	GameState.bench_room = level.room_name
	if not GameState.save_game(level.player):
		msg = "Alterado, mas não salvo. Descanse novamente para salvar."


func _draw() -> void:
	if not opened:
		return
	var font := ThemeDB.fallback_font
	var screen := get_viewport_rect().size
	var box := Rect2(40, 16, screen.x - 80, screen.y - 32)
	draw_rect(box, Color(0.02, 0.02, 0.06, 0.94))
	draw_rect(box, Color(1, 1, 1, 0.3), false, 1)
	draw_string(font, box.position + Vector2(14, 22), "Amuletos", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, GOLD)

	# Encaixes: bolinhas cheias = ocupadas.
	var used := used_notches()
	draw_string(font, Vector2(box.end.x - 150, box.position.y + 21), "Encaixes", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.7))
	for i in Charms.NOTCHES:
		var c := Vector2(box.end.x - 98 + i * 14, box.position.y + 18)
		if i < used:
			draw_circle(c, 5, PINK)
		draw_arc(c, 5, 0, TAU, 16, Color(1, 1, 1, 0.8), 1)

	# Grade de amuletos.
	var cell := 46.0
	var grid_x := box.position.x + (box.size.x - cell * COLS) / 2
	for i in Charms.ORDER.size():
		var id: String = Charms.ORDER[i]
		var pos := Vector2(grid_x + (i % COLS) * cell, box.position.y + 36 + (i / COLS) * cell)
		var r := Rect2(pos, Vector2(40, 40))
		var owned: bool = GameState.owned_charms.has(id)
		var equipped: bool = GameState.equipped_charms.has(id)
		draw_rect(r, Color(1, 1, 1, 0.06))
		if owned:
			draw_texture_rect(icons[id], r.grow(-4), false)
		else:
			draw_string(font, r.position + Vector2(0, 26), "?", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, Color(1, 1, 1, 0.25))
		if equipped:
			draw_rect(r, PINK, false, 2)
		if i == index:
			draw_rect(r.grow(2), GOLD, false, 1)

	# Descrição do selecionado.
	var sel: String = Charms.ORDER[index]
	var info: Dictionary = Charms.CHARMS[sel]
	var rows := ceili(Charms.ORDER.size() / float(COLS))
	var y := box.position.y + 36 + rows * cell + 14  # logo abaixo da grade
	if GameState.owned_charms.has(sel):
		draw_string(font, Vector2(box.position.x + 16, y), "%s   (custo %d)" % [info["name"], info["cost"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GOLD)
		draw_multiline_string(font, Vector2(box.position.x + 16, y + 16), info["desc"], HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 32, 10, -1, Color(1, 1, 1, 0.85))
	else:
		draw_string(font, Vector2(box.position.x + 16, y), "???", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.4))
		draw_string(font, Vector2(box.position.x + 16, y + 16), "Ainda não encontrado.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.4))
	if msg != "":
		draw_string(font, Vector2(box.position.x, box.end.y - 30), msg, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 10, GOLD)
	var bench_note := "" if level.is_at_bench() else "   (troca só no banco)"
	draw_string(font, Vector2(box.position.x, box.end.y - 10),
		"Setas escolher   %s equipar/remover   %s voltar%s" % [Controls.key_label("attack"), Controls.key_label("dash"), bench_note],
		HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 8, Color(1, 1, 1, 0.5))
