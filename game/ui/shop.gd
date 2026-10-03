extends Control
## Loja: lista os itens de data/shop_items.gd, compra com Geo e aplica o efeito no herói.

const ShopItems := preload("res://data/shop_items.gd")
const GOLD := Color("e8c872")

var level
var opened := false
var shop_name := ""
var index := 0
var ready_for_input := false
var closing := 0
var msg := ""


func is_open() -> bool:
	return opened


func open(npc_name: String) -> void:
	opened = true
	shop_name = npc_name
	index = 0
	ready_for_input = false
	msg = ""
	level.player.frozen = true
	Audio.play_sfx("switch")


func _process(_delta: float) -> void:
	queue_redraw()
	if closing > 0:
		closing -= 1
		if closing == 0:
			level.player.frozen = false
		return
	if not opened:
		return
	# Ignora o botão que abriu a loja.
	if not ready_for_input:
		ready_for_input = true
		return
	var items: Array = ShopItems.ITEMS
	if Input.is_action_just_pressed("up"):
		index = posmod(index - 1, items.size())
		msg = ""
		Audio.play_sfx("switch", 0.0, 1.2)
	elif Input.is_action_just_pressed("down"):
		index = posmod(index + 1, items.size())
		msg = ""
		Audio.play_sfx("switch", 0.0, 1.2)
	elif Input.is_action_just_pressed("attack"):
		_buy(items[index])
	elif Input.is_action_just_pressed("dash") or Input.is_action_just_pressed("jump"):
		opened = false
		# Espera dois quadros antes de soltar o herói, para a tecla de sair não virar pulo/dash.
		closing = 2


func _buy(item: Dictionary) -> void:
	var count: int = GameState.bought.get(item["id"], 0)
	if count >= item["max"]:
		msg = "Esgotado."
		return
	if GameState.geo < item["price"]:
		msg = "Geo insuficiente."
		Audio.play_sfx("denied")
		return
	GameState.geo -= item["price"]
	GameState.bought[item["id"]] = count + 1
	var player = level.player
	if item.has("charm"):
		GameState.owned_charms[item["charm"]] = true
	match item["id"]:
		"mask":
			player.max_hp += 1
			player.hp = player.max_hp
		"soul":
			player.soul_per_hit += 5
		"blade":
			player.nail_damage = 2
	msg = "Comprado!"
	Audio.play_sfx("buy")


func _draw() -> void:
	if not opened:
		return
	var font := ThemeDB.fallback_font
	var items: Array = ShopItems.ITEMS
	var box := Rect2(60, 20, size.x - 120, 230)
	draw_rect(box, Color(0, 0, 0, 0.88))
	draw_rect(box, Color(1, 1, 1, 0.35), false, 1)
	draw_string(font, box.position + Vector2(12, 18), shop_name + " - Loja", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GOLD)
	draw_string(font, box.position + Vector2(0, 18), "Geo %d" % GameState.geo, HORIZONTAL_ALIGNMENT_RIGHT, box.size.x - 12, 10)
	for i in items.size():
		var item: Dictionary = items[i]
		var y := box.position.y + 40 + i * 19
		var count: int = GameState.bought.get(item["id"], 0)
		var sold_out: bool = count >= item["max"]
		var color := GOLD if i == index else Color(1, 1, 1, 0.4 if sold_out else 0.85)
		if i == index:
			draw_rect(Rect2(box.position.x + 6, y - 12, box.size.x - 12, 17), Color(1, 1, 1, 0.07))
			draw_string(font, Vector2(box.position.x + 10, y), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, GOLD)
		var label: String = item["name"] + ("  (%d/%d)" % [count, item["max"]] if item["max"] > 1 else "")
		draw_string(font, Vector2(box.position.x + 22, y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, color)
		var price := "esgotado" if sold_out else "%d Geo" % item["price"]
		draw_string(font, Vector2(box.position.x, y), price, HORIZONTAL_ALIGNMENT_RIGHT, box.size.x - 14, 10, color)
	var sel: Dictionary = items[index]
	draw_multiline_string(font, Vector2(box.position.x + 12, box.end.y - 42), sel["desc"],
		HORIZONTAL_ALIGNMENT_LEFT, box.size.x - 24, 9, -1, Color(1, 1, 1, 0.75))
	if msg != "":
		draw_string(font, Vector2(box.position.x, box.end.y - 22), msg, HORIZONTAL_ALIGNMENT_RIGHT, box.size.x - 12, 9, GOLD)
	draw_string(font, Vector2(box.position.x + 12, box.end.y - 8), "%s/%s escolher   %s comprar   %s sair" % [
		Controls.key_label("up"), Controls.key_label("down"), Controls.key_label("attack"), Controls.key_label("dash")],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.5))
