extends SceneTree
## Conteúdo novo, com save isolado; -- --screenshots também salva prévias visuais.
var main
var p
var passed := 0
var failed := 0

func _initialize() -> void:
	_run.call_deferred()

func check(label: String, success: bool) -> void:
	print("  OK      " if success else "  FALHOU  ", label)
	if success:
		passed += 1
	else:
		failed += 1

func settle() -> void:
	await process_frame
	await process_frame

func markers() -> Array:
	return get_nodes_in_group("interactables").filter(func(n): return "discovery" in n)

func screenshot(name: String, feet: Vector2) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	p.enter_room(feet)
	main.hud.dialog.close()
	main.hud.banner_timer = 0
	main.hud.levelup_timer = 0
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var dir := "res://docs/content-preview/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	get_root().get_texture().get_image().save_png(dir + name + ".png")

func _run() -> void:
	await process_frame
	# Entrada física não interfere na execução determinística ou nas capturas.
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.action_erase_events(action)
	var gs = root.get_node("GameState")
	gs.save_path = "user://content_%d.json" % Time.get_ticks_usec()
	change_scene_to_file("res://game/world/main.tscn")
	await settle()
	main = current_scene
	p = main.player
	p.frozen = true
	main.hud.dialog.close()
	var residents := get_nodes_in_group("interactables").filter(func(n): return "npc_name" in n)
	for n in residents:
		check("idle/walk do morador " + n.npc_name, n.sprite.sprite_frames.has_animation("walk"))
		var home: Vector2 = n.home
		p.position = Vector2(20, 20)
		n.pause_timer = 0
		n._process(0.2)
		check("morador caminha em piso seguro " + n.npc_name, n.position != home and absf(n.position.x - home.x) <= n.patrol_span)
		p.position = n.position - Vector2(0, 20)
		var before: Vector2 = n.position
		n._process(0.2)
		check("morador para para conversar " + n.npc_name, n.position == before and n.can_interact(p))
	var entrance = markers().filter(func(n): return n.target == "mountain")[0]
	p.position = entrance.position - Vector2(0, 20)
	main._process(0)
	check("passagem mais próxima tem prioridade", main.interactable == entrance)
	entrance.interact()
	await create_timer(0.65).timeout
	p.frozen = true
	check("passagem da vila chega à serra", main.room_name == "mountain")
	check("montanha tem seis camadas", main.backdrop.layers.size() == 6)
	check("banco da montanha é checkpoint válido", main.entries.has("B"))
	for marker in markers():
		check("marcador tem chão: " + marker.title, main.is_solid(marker.position + Vector2(0, 2)))
	var memory = markers().filter(func(n): return n.discovery == "mountain_memory")[0]
	var before_geo: int = gs.geo
	memory.interact()
	memory.interact()
	check("segredo entrega recompensa só uma vez", gs.geo == before_geo + 40)
	main.hud.dialog.close()
	await screenshot("mountain", Vector2(640, 320))
	var passage = markers().filter(func(n): return n.discovery == "mountain_pass")[0]
	passage.interact()
	await create_timer(0.65).timeout
	p.frozen = true
	check("serra reconecta ao cemitério", main.room_name == "cemetery" and gs.discoveries.has("mountain_pass"))
	check("atalho não derrota nem pula chefe", gs.defeated_bosses.is_empty())
	var ambush = get_nodes_in_group("enemies").filter(func(n): return "emerging" in n and n.emerging)[0]
	ambush.set_physics_process(false)
	check("esqueleto enterrado não causa dano", ambush.get_hurtbox().size == Vector2.ZERO)
	p.position = ambush.position + Vector2(-80, 0)
	ambush._process_ambush(0.1)
	check("proximidade inicia aviso visível", ambush.ambush_state == "warning" and ambush.ambush_timer > 0.7)
	ambush.take_hit(Vector2.RIGHT, 999)
	check("aviso não entrega recompensa antecipada", ambush.hp == 5)
	ambush._process_ambush(0.8)
	check("surgimento ainda não causa dano", ambush.ambush_state == "rising" and ambush.sprite.animation == "rise" and ambush.get_hurtbox().size == Vector2.ZERO)
	ambush._process_ambush(0.9)
	check("ataque apenas depois de surgir", ambush.ambush_state == "active" and ambush.get_hurtbox().size.y > 0)
	var buried = get_nodes_in_group("enemies").filter(func(n): return "emerging" in n and n.emerging and n != ambush)[0]
	buried.set_physics_process(false)
	p.position = buried.position + Vector2(-60, 0)
	buried._process_ambush(0.1)
	await screenshot("ambush", buried.position + Vector2(-60, 18))
	for marker in markers():
		check("pista acessível em chão sólido: " + marker.title, main.is_solid(marker.position + Vector2(0, 2)))
	await screenshot("cemetery", Vector2(472, 400))
	main.load_room("swamp", "L")
	await settle()
	var things := get_nodes_in_group("enemies").filter(func(n): return "kind" in n and n.kind == "thing")
	check("Thing exclusivo do pântano está presente", things.size() == 2)
	var thing = things[0]
	thing.set_physics_process(false)
	p.position = thing.position + Vector2(60, 0)
	thing._physics_process(0.016)
	check("Thing persegue Noct", thing.velocity.x > thing.speed)
	await screenshot("swamp", thing.position + Vector2(-60, 17))
	main.load_room("inferno", "L")
	await settle()
	var hound = get_nodes_in_group("enemies").filter(func(n): return "kind" in n and n.kind == "hound")[0]
	hound.set_physics_process(false)
	p.position = Vector2(-1000, -1000)
	hound.patrol_timer = 0
	hound._physics_process(0.016)
	check("cão descansa com idle", hound.resting and hound.sprite.animation == "idle")
	hound.patrol_timer = 0
	hound._physics_process(0.016)
	check("cão patrulha com walk", not hound.resting and hound.sprite.animation == "walk")
	p.position = hound.position + Vector2(50, 0)
	hound.leap_cooldown = 10
	hound._physics_process(0.016)
	check("cão persegue com run", hound.sprite.animation == "run")
	main.load_room("town", "B")
	await settle()
	p.frozen = true
	for kind in ["trail", "impact", "shockwave", "circle"]:
		main.spawn_crimson(kind, p.position + Vector2(0, 20), 1, 0.15)
	await settle()
	check("efeitos carmesim carregam e aparecem", main.world.get_children().filter(func(n): return "textures" in n and "lifetime" in n).size() == 4)
	await create_timer(0.25).timeout
	check("efeitos temporários são liberados", main.world.get_children().filter(func(n): return "lifetime" in n).is_empty())
	if "--screenshots" in OS.get_cmdline_user_args():
		main.spawn_crimson("impact", Vector2(520, 256), 1, 1.2)
		main.spawn_crimson("shockwave", Vector2(520, 256), 1, 1.2)
		main.spawn_crimson("trail", Vector2(456, 236), 1, 1.2)
		main.spawn_crimson("circle", Vector2(376, 256), 1, 1.2)
		await screenshot("crimson", Vector2(456, 256))
	gs.bench_room = "mountain"
	check("salva descobertas no banco da montanha", gs.save_game(p))
	gs.discoveries.clear()
	check("restaura atalhos e segredos", gs.load_game() and gs.discoveries.has("mountain_pass") and gs.discoveries.has("mountain_memory"))
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(gs.save_path))
	data.erase("discoveries")
	check("save antigo sem descobertas continua válido", gs._valid_save(data))
	data["discoveries"] = ["missing"]
	check("rejeita descoberta desconhecida", not gs._valid_save(data))
	await screenshot("town", Vector2(376, 256))
	var shortcut = markers().filter(func(n): return n.requires == "mountain_pass")[0]
	p.position = shortcut.position - Vector2(0, 20)
	main.hud.dialog.close()
	main._process(0)
	check("atalho ao lado do NPC continua acessível", main.interactable == shortcut)
	shortcut.interact()
	await create_timer(0.65).timeout
	p.frozen = true
	check("atalho da vila leva ao cemitério", main.room_name == "cemetery")
	var return_passage = markers().filter(func(n): return n.target == "mountain")[0]
	return_passage.interact()
	await create_timer(0.65).timeout
	p.frozen = true
	check("cemitério reconecta à serra", main.room_name == "mountain")
	var home_passage = markers().filter(func(n): return n.target == "town")[0]
	home_passage.interact()
	await create_timer(0.65).timeout
	check("serra permite voltar à vila", main.room_name == "town")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
	print("== CONTEÚDO: %d OK, %d FALHOU ==" % [passed, failed])
	main = null
	p = null
	current_scene.queue_free()
	await settle()
	root.get_node("Audio").stop_all()
	await create_timer(0.1).timeout
	quit(0 if failed == 0 else 1)
