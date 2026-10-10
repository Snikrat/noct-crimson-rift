extends SceneTree
## Áreas do mundo (data/areas.gd): toda sala numa área só, chefe na última sala de cada área,
## mapa da pausa marcando o chefe e nome da área no aviso de entrada. Usa um save só do teste.
## Uso: godot --headless --path . --script tests/world_areas_test.gd

const Rooms := preload("res://data/rooms.gd")
const Areas := preload("res://data/areas.gd")
const WorldMap := preload("res://data/world_map.gd")
# Caractere do chefe no mapa da sala, ou o tipo do minichefe humano em "actors".
const BOSS_MARK := {"boss:gato": "G", "boss:bringer": "D", "boss:demon_slime": "M", "boss:velario": "Y"}

var passed := 0
var failed: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		print("  OK      ", name)
	else:
		failed.append(name)
		print("  FALHOU  ", name, "  ", detail)


func _run() -> void:
	# Cada sala do jogo pertence a exatamente uma área (menos a Mente do Noct).
	for r in Rooms.ROOMS:
		var count := 0
		for a in Areas.AREAS:
			count += int(r in a["rooms"]) + int(r in a.get("extras", []))
		check("sala %s numa área só" % r, count == (0 if r == "mind" else 1), "está em %d" % count)
	for a in Areas.AREAS:
		for r in a["rooms"] + a.get("extras", []):
			check("sala %s da área %s existe" % [r, a["id"]], Rooms.ROOMS.has(r))
		if a["boss_room"] == "":
			continue
		check("chefe de %s na última sala" % a["id"], a["rooms"].back() == a["boss_room"])
		var room: Dictionary = Rooms.ROOMS[a["boss_room"]]
		var req: String = a["defeated"]
		if BOSS_MARK.has(req):
			check("sala %s tem o chefe %s" % [a["boss_room"], req], "".join(room["map"]).contains(BOSS_MARK[req]))
		else:
			var actor: Array = room.get("actors", []).filter(func(x): return x.get("discovery", "") == req)
			check("sala %s tem o minichefe %s" % [a["boss_room"], req], actor.size() == 1)
	# Nenhuma sala de chefe fica fora do lugar: todo G/D/M/Y está na sala de chefe de uma área.
	for r in Rooms.ROOMS:
		var map := "".join(Rooms.ROOMS[r]["map"])
		for req in BOSS_MARK:
			if map.contains(BOSS_MARK[req]):
				check("%s é a sala de chefe da sua área" % r, Areas.area_of(r).get("boss_room", "") == r)
	var names := Areas.AREAS.map(func(a): return a["name"])
	for r in Rooms.ROOMS:
		check("nome da sala %s diferente do nome de área" % r, not Rooms.ROOMS[r]["title"] in names)
	check("toda sala do mapa da pausa tem área", (WorldMap.MAIN_ROW + WorldMap.SIDE.keys()).all(func(r): return Areas.area_of(r) != {}))

	# No jogo: aviso de área ao trocar de área, sem repetir dentro da mesma área nem ao voltar da Mente.
	var gs = root.get_node("GameState")
	gs.save_path = "user://world_areas_%d.json" % Time.get_ticks_usec()
	change_scene_to_file("res://game/world/main.tscn")
	await process_frame
	await process_frame
	var main = current_scene
	for r in ["town", "swamp", "cemetery", "lair", "cathedral"]:
		gs.seen_intros[r] = true
	main.load_room("swamp", "L")
	check("entrar no Pântano mostra a área", main.hud.banner_area == "Terras Esquecidas", main.hud.banner_area)
	main.load_room("cemetery", "L")
	check("dentro da mesma área não repete o nome", main.hud.banner_area == "")
	main.load_room("cathedral", "L")
	check("Catedral mostra a área nova", main.hud.banner_area == "Domínio do Ceifador", main.hud.banner_area)

	print("== RESULTADO: %d OK, %d FALHOU ==" % [passed, failed.size()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
	quit(1 if failed.size() > 0 else 0)
