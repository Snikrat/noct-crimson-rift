extends SceneTree
## Áreas novas: Torre de Pedravelha (Garras do Gato), Poço da vila (água e amuleto) e Estação
## (chuva, banco à direita). Usa um save só do teste; -- --screenshots salva prévias em docs/content-preview/.
## Uso: godot --headless --path . --script tests/areas_test.gd

const Rooms := preload("res://data/rooms.gd")
const Charms := preload("res://data/charms.gd")
const NEW_ROOMS := ["tower", "well", "station"]

var main
var p
var passed := 0
var failed: Array[String] = []


func _initialize() -> void:
	_run()


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passed += 1
		print("  OK      ", name)
	else:
		failed.append(name)
		print("  FALHOU  ", name, "  ", detail)


func wait(frames: int) -> void:
	for i in frames:
		await physics_frame


func gs():
	return root.get_node("GameState")


func skip_dialogs() -> void:
	while main.is_dialog_open():
		main.hud.dialog.close()
	await wait(2)


func go(room: String, entry: String) -> void:
	gs().seen_intros[room] = true
	main.load_room(room, entry)
	await wait(4)
	await skip_dialogs()


func place(feet: Vector2) -> void:
	p.global_position = feet - Vector2(0, p.SIZE.y / 2)
	p.velocity = Vector2.ZERO
	await wait(4)


func markers() -> Array:
	return get_nodes_in_group("interactables").filter(func(n): return "discovery" in n)


func marker(title: String):
	for m in markers():
		if m.title == title:
			return m
	return null


func screenshot(name: String, feet: Vector2) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	await place(feet)
	main.hud.dialog.close()
	main.hud.banner_timer = 0
	main.hud.levelup_timer = 0
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var dir := "res://docs/content-preview/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	root.get_texture().get_image().save_png(dir + name + ".png")


## Encosta na parede da esquerda e aperta pulo várias vezes; retorna o ponto mais alto (pés).
func climb_left(frames: int) -> float:
	var best: float = p.global_position.y + p.SIZE.y / 2
	Input.action_press("move_left")
	for i in frames:
		if i % 14 == 0:
			Input.action_press("jump")
		elif i % 14 == 10:
			Input.action_release("jump")
		await physics_frame
		best = minf(best, p.global_position.y + p.SIZE.y / 2)
	Input.action_release("jump")
	Input.action_release("move_left")
	await wait(2)
	return best


func _run() -> void:
	print("== ÁREAS NOVAS ==")
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.action_erase_events(action)
	gs().save_path = "user://test_areas_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	gs().reset()
	change_scene_to_file("res://game/world/main.tscn")
	await wait(20)
	main = current_scene
	p = main.player
	p.invuln_timer = 9999.0
	await skip_dialogs()

	# --- Registro das salas ---
	for r in NEW_ROOMS:
		check("sala registrada: " + r, Rooms.ROOMS.has(r))
		var rows: Array = Rooms.ROOMS[r]["map"]
		var width: int = rows[0].length()
		check("mapa retangular: " + r, rows.all(func(row): return row.length() == width))
		check("sala tem banco ou saída: " + r, rows.any(func(row): return "B" in row) or not Rooms.ROOMS[r].get("markers", []).is_empty())

	# --- Vila: portas novas ---
	await go("town", "B")
	var tower_door = marker("Porta da torre")
	var well_mouth = marker("Poço")
	check("vila tem a porta da torre", tower_door != null and tower_door.target == "tower")
	check("vila tem a entrada do poço", well_mouth != null and well_mouth.target == "well")
	check("vila tem só uma fenda (o resto são saídas naturais)", markers().filter(func(m): return m.portal).size() == 1)
	for m in [tower_door, well_mouth]:
		if m:
			check("porta da vila tem chão: " + m.title, main.is_solid(m.position + Vector2(0, 2)))

	# --- Torre: sem as Garras, o térreo é um beco ---
	await go("tower", "TOWN")
	check("torre carrega pela porta", main.room_name == "tower")
	check("torre é checkpoint", main.entries.has("B"))
	for m in markers():
		check("marcador da torre tem chão: " + m.title, main.is_solid(m.position + Vector2(0, 2)))
	check("sem o Gato, sem Garras", not main.has_wall_grip())
	await place(Vector2(24, 512))
	var top_without := await climb_left(150)
	check("sem Garras não sobe ao piso do meio", top_without > 336, "pés em %.0f" % top_without)
	await screenshot("tower_bottom", Vector2(296, 512))

	# --- Torre: com as Garras, sobe pela parede ---
	gs().defeated_bosses["gato"] = true
	check("Gato derrotado libera as Garras", main.has_wall_grip())
	await place(Vector2(24, 512))
	var top_with := await climb_left(150)
	check("com Garras sobe acima do piso do meio", top_with < 320, "pés em %.0f" % top_with)
	await place(Vector2(40, 400))
	Input.action_press("move_left")
	await wait(10)
	check("desliza devagar encostado na parede", p.wall_dir == -1 and p.velocity.y <= p.WALL_SLIDE_SPEED + 0.1)
	Input.action_release("move_left")
	await wait(2)
	gs().defeated_bosses.erase("gato")

	var view = marker("Luneta do sineiro")
	gs().visited.erase("well")
	view.interact()
	await skip_dialogs()
	check("luneta marca a região no mapa", gs().visited.has("well") and gs().visited.has("cemetery") and not gs().visited.has("inferno"))
	check("luneta vira descoberta", gs().discoveries.has("tower_view"))
	var geo_before: int = gs().geo
	var bell = marker("Sino rachado")
	bell.interact()
	await skip_dialogs()
	bell.interact()
	await skip_dialogs()
	check("sino entrega 40 Geo uma vez", gs().geo == geo_before + 40)
	await screenshot("tower_top", Vector2(200, 128))

	# --- Poço ---
	await go("well", "TOWN")
	check("poço carrega pela boca", main.room_name == "well")
	check("poço tem água", main.water.size() == 36)
	check("água não machuca", main.hazards.size() == 6)
	check("nicho do amuleto atrás da parede carmesim", main.rift.size() == 3)
	var charm: Array = main.world.get_children().filter(func(n): return n.get("charm_id") == "one_day")
	check("amuleto Um Dia de Cada Vez está no poço", not charm.is_empty())
	for m in markers():
		check("marcador do poço tem chão: " + m.title, main.is_solid(m.position + Vector2(0, 2)))
	await screenshot("well", Vector2(200, 320))
	var back = marker("Subir para a vila")
	back.interact()
	await wait(40)
	await skip_dialogs()
	check("poço volta para a vila", main.room_name == "town")

	# --- Amuleto Um Dia de Cada Vez ---
	check("amuleto registrado", Charms.ORDER.has("one_day") and Charms.CHARMS["one_day"]["cost"] == 1)
	gs().owned_charms["one_day"] = true
	gs().equipped_charms.append("one_day")
	await place(Vector2(600, 256))
	p.soul = 0
	await wait(60)
	check("parado menos de 3 s não recupera alma", p.soul == 0)
	await wait(180)
	check("parado depois de 3 s recupera alma", p.soul > 0, "alma %d" % p.soul)
	gs().equipped_charms.erase("one_day")

	# --- Serra → Estação ---
	await go("mountain", "STATION")
	var tracks = marker("Trilhos velhos")
	check("serra tem os trilhos velhos", tracks != null and tracks.target == "station")
	check("trilhos fechados sem a memória Volto logo", not main.requirement_met(tracks.requires))
	tracks.interact()
	await wait(30)
	check("trilhos fechados não levam à estação", main.room_name == "mountain")
	await skip_dialogs()
	gs().memories["last_night"] = true
	check("memória Volto logo abre os trilhos", main.requirement_met(tracks.requires))
	tracks.interact()
	await wait(40)
	await skip_dialogs()
	check("trilhos levam à estação", main.room_name == "station")
	check("estação tem chuva", main.world.get_children().any(func(n): return n is CanvasLayer))
	check("estação sem inimigos", get_nodes_in_group("enemies").is_empty())
	for m in markers():
		check("marcador da estação tem chão: " + m.title, main.is_solid(m.position + Vector2(0, 2)))
	gs().memories["the_seat"] = true
	main.rest_at_bench()
	var lines: Array = main.hud.dialog.lines
	check("no banco da estação ele senta à direita", lines.any(func(l): return "direita" in l))
	check("eco da memória do banco", lines.has("* Não estava frio."))
	check("banco da estação vira checkpoint", gs().bench_room == "station")
	await skip_dialogs()
	await screenshot("station", Vector2(200, 224))

	# --- Save com tudo isso ---
	gs().owned_charms["one_day"] = true
	check("salva com as descobertas novas", gs().save_game(p))
	check("carrega com as descobertas novas", gs().load_game() and gs().discoveries.has("tower_bell") and gs().owned_charms.has("one_day"))

	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	print("== ÁREAS NOVAS: %d OK, %d FALHOU ==" % [passed, failed.size()])
	quit(0 if failed.is_empty() else 1)
