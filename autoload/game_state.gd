extends Node
## Estado do jogo que sobrevive às trocas de sala e de cena, e que vai para o save.
## Registrado como autoload "GameState" (sempre disponível em qualquer script).

const SAVE_PATH := "user://save.json"
const Rooms := preload("res://data/rooms.gd")
const Charms := preload("res://data/charms.gd")
const ShopItems := preload("res://data/shop_items.gd")
const Progression := preload("res://data/progression.gd")
const Memories := preload("res://data/memories.gd")
# "demon1": Forma Demoníaca Nível 1 (derrotar o Velário; game/player/demon_form.gd).
const SKILLS := ["combo", "wave", "charged", "uppercut", "slam", "ultimate", "demon1"]
const BOSSES := ["gato", "bringer", "demon_slime", "velario"]
const DISCOVERIES := ["mountain_pass", "nameless_grave", "watcher_note", "mountain_memory", "bandit_captain", "evil_wizard", "knight_duel", "forest_cache", "ruins_memory", "tower_marks", "tower_view", "tower_bell", "well_note", "station_board", "station_tracks", "mines_journal", "archive_page", "cliff_cabin"]
# Marcos da história (Tessa, final).
const FLAGS := ["tessa_saved", "tessa_jacket", "tessa_thanked", "tessa_cathedral", "ending_seen", "ending_stay", "ending_leave"]
var save_path := SAVE_PATH      # o teste automático usa outro arquivo para não mexer no seu save

var geo := 0
var bench_room := "town"        # onde o herói volta ao morrer (último banco usado)
var defeated_bosses := {}       # BOSS_ID -> true
var bought := {}                # id do item da loja -> quantidade comprada
var hero := {}                  # atributos do herói (nível, XP, habilidades...)
var owned_charms := {}          # amuletos que o herói tem (id -> true)
var equipped_charms: Array = [] # amuletos equipados (ids)
var seen_intros := {}           # áreas em que Noct já fez o comentário de chegada
var discoveries := {}          # inscrições e atalhos encontrados (salvos ao descansar)
var visited := {}              # salas por onde o herói já passou (mapa da pausa)
var memories := {}             # memórias de Mira encontradas (data/memories.gd)
var flags := {}                # marcos da história (FLAGS)
var ending_choice := ""        # "stay" ou "leave": escolha final (lida pela cena do final)
var continuing := false         # true quando o jogo foi aberto pelo "Continuar"


## Começa um jogo novo, do zero.
func reset() -> void:
	geo = 0
	bench_room = "town"
	defeated_bosses = {}
	bought = {}
	hero = {}
	owned_charms = {}
	equipped_charms = []
	seen_intros = {}
	discoveries = {}
	visited = {}
	memories = {}
	flags = {}
	continuing = false


# --- Herói ---------------------------------------------------------------

## Copia os atributos permanentes do herói (o que não se perde ao morrer).
func capture_hero(p: Node) -> void:
	hero = {
		"lvl": p.lvl, "xp": p.xp, "unlocked": p.unlocked.keys(),
		"max_hp": p.base_max_hp, "nail_damage": p.nail_damage,
		"soul_per_hit": p.soul_per_hit, "spell_bonus": p.spell_bonus,
	}


## Devolve ao herói os atributos guardados (ao continuar um jogo salvo).
func apply_hero(p: Node) -> void:
	if hero.is_empty():
		return
	p.lvl = int(hero["lvl"])
	p.xp = int(hero["xp"])
	p.unlocked = {}
	for skill in hero["unlocked"]:
		p.unlocked[skill] = true
	p.base_max_hp = int(hero["max_hp"])
	p.hp = p.max_hp
	p.nail_damage = int(hero["nail_damage"])
	p.soul_per_hit = int(hero["soul_per_hit"])
	p.spell_bonus = int(hero["spell_bonus"])


# --- Save ----------------------------------------------------------------

## O amuleto está equipado?
func has_charm(id: String) -> bool:
	return equipped_charms.has(id)


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


func save_game(p: Node) -> bool:
	capture_hero(p)
	var data := {
		"version": 1,
		"geo": geo, "bench_room": bench_room,
		"defeated_bosses": defeated_bosses.keys(), "bought": bought, "hero": hero,
		"owned_charms": owned_charms.keys(), "equipped_charms": equipped_charms,
		"seen_intros": seen_intros.keys(),
		"discoveries": discoveries.keys(),
		"visited": visited.keys(), "memories": memories.keys(), "flags": flags.keys(),
	}
	# Só substitui o save anterior depois que a escrita terminou sem erro.
	var temporary := save_path + ".tmp"
	var f := FileAccess.open(temporary, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.flush()
	var write_error := f.get_error()
	f.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return false
	var result := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(save_path))
	if result != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
	return result == OK


## Carrega o save. Retorna false se não existir ou estiver corrompido.
func load_game() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not _valid_save(data):
		return false
	reset()
	for id in data.get("discoveries", []):
		discoveries[id] = true
	geo = int(data.get("geo", 0))
	bench_room = data.get("bench_room", "town")
	for id in data.get("defeated_bosses", []):
		defeated_bosses[id] = true
	for id in data.get("bought", {}):
		bought[id] = int(data["bought"][id])
	hero = data.get("hero", {})
	# Corrige também saves antigos afetados pela ordem da compra e do nível 6.
	hero["soul_per_hit"] = 11 + (5 if bought.get("soul", 0) > 0 else 0) + (3 if int(hero["lvl"]) >= 6 else 0)
	for id in data.get("owned_charms", []):
		owned_charms[id] = true
	equipped_charms = Array(data.get("equipped_charms", []))
	for room_id in data.get("seen_intros", []):
		seen_intros[room_id] = true
	for room_id in data.get("visited", []):
		visited[room_id] = true
	for id in data.get("memories", []):
		memories[id] = true
	for id in data.get("flags", []):
		flags[id] = true
	continuing = true
	return true


## Valida tudo antes de alterar o estado da partida atual.
func _valid_save(data: Variant) -> bool:
	if not data is Dictionary or not _integer_between(data.get("version"), 1, 1):
		return false
	if not _valid_ids(data.get("discoveries", []), DISCOVERIES):
		return false
	if not _integer_between(data.get("geo", 0), 0, 2147483647):
		return false
	var saved_room = data.get("bench_room", "town")
	if not saved_room is String or not Rooms.ROOMS.has(saved_room):
		return false
	var has_bench := false
	for row in Rooms.ROOMS[saved_room]["map"]:
		if "B" in row:
			has_bench = true
	if not has_bench:
		return false
	var saved_hero = data.get("hero")
	if not saved_hero is Dictionary:
		return false
	for key in ["lvl", "xp", "max_hp", "nail_damage", "soul_per_hit", "spell_bonus"]:
		var minimum := 0 if key in ["xp", "spell_bonus"] else 1
		var bounds := {"lvl": Progression.MAX_LEVEL, "xp": 2147483647, "max_hp": 11, "nail_damage": 2, "soul_per_hit": 19, "spell_bonus": 1}
		var maximum: int = bounds[key]
		if not _integer_between(saved_hero.get(key), minimum, maximum):
			return false
	var saved_level := int(saved_hero["lvl"])
	if int(saved_hero["xp"]) < Progression.XP_FOR_LEVEL[saved_level]:
		return false
	if saved_level < Progression.MAX_LEVEL and int(saved_hero["xp"]) >= Progression.XP_FOR_LEVEL[saved_level + 1]:
		return false
	if not _valid_ids(saved_hero.get("unlocked"), SKILLS):
		return false
	for level_number in Progression.REWARDS:
		var reward: Dictionary = Progression.REWARDS[level_number]
		if reward.has("unlock") and saved_hero["unlocked"].has(reward["unlock"]) != (saved_level >= level_number):
			return false
	if not _valid_ids(data.get("defeated_bosses", []), BOSSES):
		return false
	if not _valid_ids(data.get("seen_intros", []), Rooms.ROOMS.keys()):
		return false
	if not _valid_ids(data.get("visited", []), Rooms.ROOMS.keys()):
		return false
	if not _valid_ids(data.get("memories", []), Memories.ORDER):
		return false
	if not _valid_ids(data.get("flags", []), FLAGS):
		return false
	var owned = data.get("owned_charms", [])
	var equipped = data.get("equipped_charms", [])
	if not _valid_ids(owned, Charms.ORDER) or not _valid_ids(equipped, owned):
		return false
	var used := 0
	for id in equipped:
		used += Charms.CHARMS[id]["cost"]
	if used > Charms.NOTCHES:
		return false
	var purchases = data.get("bought", {})
	if not purchases is Dictionary:
		return false
	var limits := {}
	for item in ShopItems.ITEMS:
		limits[item["id"]] = item["max"]
	for id in purchases:
		if not limits.has(id) or not _integer_between(purchases[id], 0, limits[id]):
			return false
	return true


func _integer_between(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	return is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum


func _valid_ids(value: Variant, allowed: Array) -> bool:
	if not value is Array:
		return false
	var seen := {}
	for id in value:
		if not id is String or not allowed.has(id) or seen.has(id):
			return false
		seen[id] = true
	return true
