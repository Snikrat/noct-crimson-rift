extends SceneTree
## Novidades da história e do mundo: opções, mapa, memórias de Mira, Passo da Fenda, Tessa,
## luz/impacto e o final (escolha + cena final + créditos). Usa um save só do teste.
## Uso: godot --headless --path . --script tests/story_test.gd

const Memories := preload("res://data/memories.gd")
const Rooms := preload("res://data/rooms.gd")

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


func tap(action: String, hold := 2) -> void:
	Input.action_press(action)
	await wait(hold)
	Input.action_release(action)
	await wait(2)


func gs():
	return root.get_node("GameState")


func skip_dialogs() -> void:
	while main.is_dialog_open():
		main.hud.dialog.close()
	await wait(2)


func go(room: String, feet: Vector2) -> void:
	gs().seen_intros[room] = true
	main.load_room(room, "L")
	await wait(4)
	await skip_dialogs()
	p.global_position = feet - Vector2(0, p.SIZE.y / 2)
	p.velocity = Vector2.ZERO
	await wait(6)


func _run() -> void:
	print("== HISTÓRIA E MUNDO ==")
	gs().save_path = "user://test_story_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	gs().reset()
	change_scene_to_file("res://game/world/main.tscn")
	await wait(20)
	main = current_scene
	p = main.player
	p.invuln_timer = 9999.0
	await skip_dialogs()

	# --- Opções (sem salvar o arquivo de verdade) ---
	var settings = root.get_node("Settings")
	var music_before: float = settings.music
	settings.music = 0.5
	settings.apply()
	var bus := AudioServer.get_bus_index("Music")
	check("opções: canal de música existe e muda de volume", bus != -1 and absf(AudioServer.get_bus_volume_db(bus) - linear_to_db(0.5)) < 0.1)
	settings.music = music_before
	settings.apply()
	check("música e efeitos tocam nos canais certos", root.get_node("Audio").music.bus == "Music" and root.get_node("Audio").sfx_players[0].bus == "SFX")

	# --- Mapa ---
	check("mapa: vila marcada como visitada", gs().visited.has("town"))
	var world_map_view = load("res://game/ui/world_map_view.gd")   # carregado depois dos autoloads
	var rects: Dictionary = world_map_view.layout(Vector2(240, 135))
	var on_map := Rooms.ROOMS.keys().filter(func(r): return not Rooms.ROOMS[r].get("hidden", false))
	check("mapa: todas as salas têm lugar", rects.size() == on_map.size(), "%d/%d" % [rects.size(), on_map.size()])
	var inside := true
	for r in rects:
		if not Rect2(16, 18, 448, 234).encloses(rects[r]):
			inside = false
	check("mapa: cabe na tela", inside)
	await tap("pause")
	await tap("down")
	await tap("attack")
	check("pausa abre o mapa", main.hud.pause.page == "map")
	await tap("dash")
	await tap("down")
	await tap("attack")
	check("pausa abre as memórias", main.hud.pause.page == "memories")
	await tap("dash")
	await tap("dash")
	await wait(4)
	check("pausa fecha", not paused)
	await tap("map")
	check("botão de mapa abre o mapa direto", paused and main.hud.pause.page == "map")
	await tap("map")
	await wait(4)
	check("botão de mapa fecha e volta ao jogo", not paused)

	# --- Memória de Mira ---
	await go("town", Vector2(376, 192))
	check("memória: pega a da vila", gs().memories.has("first_sarcasm"))
	check("memória: mostra o texto", main.is_dialog_open() and main.hud.dialog.lines.size() >= 4)
	await skip_dialogs()
	# "the_promise" não fica numa sala: o Velário a libera (main.gd, _promise_memory).
	check("memórias: as 8 de sala têm lugar em alguma sala", _placed_memories() == Memories.ORDER.size() - 1, str(_placed_memories()))

	# --- Passo da Fenda ---
	await go("town", Vector2(104, 256))
	p.facing = -1
	Input.action_press("move_left")
	await wait(2)
	await tap("dash")
	Input.action_release("move_left")
	await wait(6)
	check("parede carmesim bloqueia antes do Bringer", p.global_position.x > 90, "x=%.0f" % p.global_position.x)
	gs().defeated_bosses["bringer"] = true
	await go("town", Vector2(104, 256))
	p.dash_cooldown = 0
	Input.action_press("move_left")
	await wait(2)
	await tap("dash")
	Input.action_release("move_left")
	await wait(10)
	check("Passo da Fenda atravessa a parede", p.global_position.x < 80, "x=%.0f" % p.global_position.x)
	Input.action_press("move_left")   # anda até o fundo do nicho
	await wait(20)
	Input.action_release("move_left")
	await wait(3)
	check("memória atrás da parede", gs().memories.has("afraid"))
	await skip_dialogs()
	p.dash_cooldown = 0
	Input.action_press("move_right")
	await wait(2)
	await tap("dash")
	Input.action_release("move_right")
	await wait(10)
	check("Passo da Fenda volta para fora", p.global_position.x > 96, "x=%.0f" % p.global_position.x)

	# --- Tessa ---
	await go("forest", Vector2(640, 320))
	var tessa = _find_tessa()
	check("Tessa presa no Bosque", tessa != null and tessa.stage == "captive")
	if tessa:
		tessa.interact()
		await wait(2)
		check("não solta com saqueadores por perto", not gs().flags.has("tessa_saved"))
		for e in get_nodes_in_group("enemies"):
			if not e.is_in_group("harmful"):
				e.queue_free()
		await wait(3)
		tessa.interact()
		await wait(2)
		check("solta Tessa", gs().flags.has("tessa_saved") and main.is_dialog_open())
		await skip_dialogs()
	await go("town", Vector2(200, 256))
	tessa = _find_tessa()
	check("Tessa aparece na vila", tessa != null and tessa.stage == "town")
	main.rest_at_bench()
	check("banco da vila: a manta", gs().flags.has("tessa_jacket") and "manta" in str(main.hud.dialog.lines))
	await skip_dialogs()
	if tessa:
		tessa.interact()
		check("Tessa agradece a manta", gs().flags.has("tessa_thanked") and "Era." in str(main.hud.dialog.lines))
		await skip_dialogs()
	await go("cathedral", Vector2(220, 400))
	tessa = _find_tessa()
	check("Tessa aparece na catedral", tessa != null and tessa.stage == "cathedral")
	if tessa:
		tessa.interact()
		await skip_dialogs()
		await wait(70)
		check("Tessa vai embora da catedral", gs().flags.has("tessa_cathedral") and not is_instance_valid(tessa))

	# --- Luz e impacto ---
	check("aura do herói existe e acende na forma carmesim", p.aura != null)
	p.crimson_level = 3
	await wait(3)
	check("aura visível no carmesim 3", p.aura.visible and p.aura.modulate.a > 0.2)
	p.crimson_level = 0

	# --- Final ---
	gs().defeated_bosses.erase("demon_slime")
	await go("demon_lair", Vector2(300, 224))
	await skip_dialogs()
	var boss = main.boss
	check("Demon Slime pronto", boss != null)
	if boss:
		boss.take_hit(Vector2.RIGHT, 1)
		await skip_dialogs()
		boss.hp = 1
		boss.take_hit(Vector2.RIGHT, 1)
		await wait(4)
		check("golpe final: câmera lenta", Engine.time_scale < 0.5)
		for i in 60:
			await wait(10)
			if main.is_dialog_open() and main.hud.dialog.speaker == "Vitória":
				break
		check("vitória abre a fala", main.is_dialog_open())
		main.hud.dialog.close()
		await wait(3)
		check("a fenda fala (revelação)", main.is_dialog_open() and main.hud.dialog.speaker == "A Fenda")
		main.hud.dialog.close()
		await wait(3)
		check("escolha final aparece", main.hud.dialog.choices.size() == 2)
		await tap("down")
		await tap("attack")
		check("escolha 'Ir embora'", gs().ending_choice == "leave" and gs().flags.has("ending_seen"))
		for i in 60:
			await wait(5)
			if current_scene and current_scene.name == "Ending":
				break
		check("cena final abre", current_scene != null and current_scene.name == "Ending")
		if current_scene and current_scene.name == "Ending":
			var ending = current_scene
			check("final com Tessa no banco", "Tessa|Eu percebi." in ending.lines)
			for i in 120:
				await tap("attack")
				await wait(26)
				if ending.phase != "story":
					break
			check("nome do final aparece", ending.phase in ["title", "credits"], ending.phase)
			await wait(int(4.5 * 60))
			check("créditos rolam", ending.phase == "credits")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	print("== HISTÓRIA: %d OK, %d FALHOU ==" % [passed, failed.size()])
	quit(0 if failed.is_empty() else 1)


func _find_tessa():
	for n in get_nodes_in_group("interactables"):
		if n.get("npc_name") == "Tessa":
			return n
	return null


func _placed_memories() -> int:
	var ids := {}
	for r in Rooms.ROOMS:
		for m in Rooms.ROOMS[r].get("memories", []):
			ids[m["id"]] = true
	return ids.size()
