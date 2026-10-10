extends SceneTree
## Lago Velado e Velário (docs/expansao_forma_demoniaca.md, seções 3-4): salas, fenda do Santuário,
## as duas fases, os ataques, a morte, a lembrança "Continua andando" e a Forma Demoníaca liberada.
## Usa um save só do teste. Uso: godot --headless --path . --script tests/velario_test.gd
## Com janela e -- --screenshots salva prévias em docs/content-preview/.

const Rooms := preload("res://data/rooms.gd")
const Memories := preload("res://data/memories.gd")

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
	var guard := 0
	while main.is_dialog_open() and guard < 50:
		main.hud.dialog.close()
		guard += 1
		await wait(2)
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


func shot(name: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	main.hud.banner_timer = 0
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var dir := "res://docs/content-preview/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	root.get_texture().get_image().save_png(dir + name + ".png")


func marker(title: String):
	for m in get_nodes_in_group("interactables"):
		if "title" in m and m.title == title:
			return m
	return null


func hazards(kind: String) -> Array:
	return main.world.get_children().filter(func(n): return "kind" in n and n.kind == kind and n.get_script().resource_path.ends_with("velario_hazard.gd"))


func _run() -> void:
	print("== LAGO VELADO / VELÁRIO ==")
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.action_erase_events(action)
	gs().save_path = "user://test_velario_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	gs().reset()
	change_scene_to_file("res://game/world/main.tscn")
	await wait(20)
	main = current_scene
	p = main.player
	main.play_ending = false
	await skip_dialogs()

	# --- Salas ---
	for r in ["lake_shore", "lake"]:
		check("sala registrada: " + r, Rooms.ROOMS.has(r))
		var rows: Array = Rooms.ROOMS[r]["map"]
		check("mapa retangular: " + r, rows.all(func(row): return row.length() == rows[0].length()))
	check("memória the_promise existe", Memories.MEMORIES.has("the_promise") and Memories.ORDER.has("the_promise"))
	check("velario é um chefe do save", gs().BOSSES.has("velario"))

	# --- Fenda do Santuário: fechada antes do Bringer ---
	await go("sanctum", "L")
	var rift = marker("Fenda sob o altar")
	check("fenda sob o altar existe", rift != null)
	check("fenda fechada antes do Bringer", rift != null and not main.requirement_met(rift.requires))
	gs().defeated_bosses["bringer"] = true
	check("fenda abre depois do Bringer", main.requirement_met(rift.requires))
	await place(Vector2(288, 224))
	rift.interact()
	await wait(40)
	await skip_dialogs()
	check("fenda leva à Margem", main.room_name == "lake_shore", main.room_name)
	await shot("lake_shore")

	# --- Arena ---
	p.invuln_timer = 9999.0
	# Margem -> Capela da Vigília -> Penhasco da Chuva Eterna -> Lago Velado (área Águas Veladas).
	for expected in ["vigil_chapel", "rain_cliff", "lake"]:
		gs().seen_intros[expected] = true
		main.request_exit("right")
		await wait(40)
		await skip_dialogs()
		check("saída direita leva a " + expected, main.room_name == expected, main.room_name)
	var b = main.boss
	check("Velário aparece", b != null and b.BOSS_ID == "velario")
	check("Velário dorme até o Noct chegar", b.state == "sleep")
	await place(Vector2(300, 224))
	await wait(10)
	await skip_dialogs()
	check("Velário acorda", b.is_awake())
	check("portão fecha", main.solid.has(Vector2i(0, 12)))
	await wait(30)
	await shot("velario_fase1")

	# Ataques da fase 1 (chamados direto para não depender do sorteio).
	b._spawn_chains()
	await wait(2)
	check("Tranca solta duas correntes", hazards("chain").size() == 2)
	b._forget()
	await wait(2)
	check("Esquecer escurece a tela", hazards("dark").size() == 1)
	await wait(40)
	await shot("velario_esquecer")
	await wait(80)

	# Golpe: área machuca o Noct.
	p.invuln_timer = 0
	var hp_before: int = p.hp
	await place(Vector2(b.global_position.x + 40, 224))
	b._face(p)
	b._start_attack()
	await wait(50)
	check("golpe da chave acerta de perto", p.hp < hp_before, "%d -> %d" % [hp_before, p.hp])
	p.hp = p.max_hp
	p.invuln_timer = 9999.0

	# --- Transição ---
	b.take_hit(Vector2.RIGHT, b.MAX_HP / 2)
	check("metade da vida começa a transição", b.state == "transform")
	var hp_mid: int = b.hp
	b.take_hit(Vector2.RIGHT, 5)
	check("invulnerável na transição", b.hp == hp_mid)
	await wait(120)
	check("fase 2", b.phase == 2 and b.state != "transform", "fase %d estado %s" % [b.phase, b.state])
	await wait(20)
	await shot("velario_fase2")
	b._rain_cages()
	b._tide()
	b._land_shock()
	await wait(2)
	check("chuva de gaiolas (5)", hazards("cage").size() == 5)
	check("maré carmesim (2)", hazards("tide").size() == 2)
	check("onda de choque", hazards("shock").size() == 1)
	await wait(30)
	await shot("velario_ataques")
	b.hp = b.MAX_HP / 5 + 1
	b.take_hit(Vector2.RIGHT, 2)
	check("desespero abaixo de 20%", b.desperate)
	await wait(200)

	# --- Morte e lembrança ---
	b.take_hit(Vector2.RIGHT, 999)
	check("Velário morre", b.dying)
	var guard := 0
	while not gs().defeated_bosses.has("velario") and guard < 600:
		await wait(5)
		guard += 5
	check("Velário derrotado", gs().defeated_bosses.has("velario"))
	check("portão abre", not main.solid.has(Vector2i(0, 12)))
	check("vitória mostra fala", main.is_dialog_open())
	# Vitória -> lembrança -> depois.
	for i in 3:
		await wait(10)
		await skip_dialogs()
		await wait(30)
	await skip_dialogs()
	await wait(20)
	check("lembrança Continua andando liberada", gs().memories.has("the_promise"))
	check("Forma Demoníaca Nível 1 liberada", p.has("demon1") and p.demon.unlocked())
	check("barra da Fenda cheia ao liberar", p.demon.full())

	# --- Save ---
	gs().bench_room = "lake_shore"
	check("salva com Velário e demon1", gs().save_game(p))
	check("carrega o save", gs().load_game())
	check("save lembra o Velário", gs().defeated_bosses.has("velario"))
	check("save lembra a forma", gs().hero["unlocked"].has("demon1"))
	check("save lembra a memória", gs().memories.has("the_promise"))

	# Voltando: o Velário não reaparece.
	await go("lake", "L")
	check("Velário não volta", main.boss == null)

	print("== RESULTADO: %d OK, %d FALHOU ==" % [passed, failed.size()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	quit(0 if failed.is_empty() else 1)
