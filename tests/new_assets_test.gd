extends SceneTree
## Novos pacotes: combate com preparação, duelos, progressão opcional e checkpoint.
var main
var p
var gs
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

func actors() -> Array:
	return main.world.get_children().filter(func(n): return "attack_elapsed" in n)

func marker_to(target: String):
	return get_nodes_in_group("interactables").filter(func(n): return "target" in n and n.target == target)[0]

func load_room(name: String, entry := "L") -> void:
	main.load_room(name, entry)
	await settle()
	main.hud.dialog.close()
	p.frozen = true
	p.invuln_timer = 100
	for actor in actors():
		actor.set_physics_process(false)

func capture(name: String, feet: Vector2) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	p.enter_room(feet)
	p.frozen = true
	main.hud.dialog.close()
	p.sprite.modulate = Color.WHITE
	p.invuln_timer = 0
	p.hurt_timer = 0
	Engine.time_scale = 1
	main.hud.banner_timer = 0
	main.hud.levelup_timer = 0
	await create_timer(0.5, true, false, true).timeout
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://docs/content-preview/" + name + ".png")

func _run() -> void:
	await process_frame
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.action_erase_events(action)
	gs = root.get_node("GameState")
	gs.save_path = "user://new_assets_%d.json" % Time.get_ticks_usec()
	change_scene_to_file("res://game/world/main.tscn")
	await settle()
	main = current_scene
	p = main.player
	p.frozen = true
	main.hud.dialog.close()
	var passage = marker_to("forest")
	passage.interact()
	await create_timer(0.65).timeout
	check("vila conecta ao bosque", main.room_name == "forest")
	await load_room("forest")
	check("bosque contém quatro humanoides", actors().size() == 4)
	check("bosque tem camadas de floresta", main.backdrop.layers.size() == 4)
	check("folhas à frente preservam HUD", main.backdrop.foreground_texture != null and main.hud.layer > 1)
	for name in ["forest", "arcane_ruins", "mountain"]:
		await load_room(name)
		for actor in actors():
			check("ator em piso sólido: " + actor.kind, main.is_solid(actor.position + Vector2(0, actor.size.y / 2 + 2)))
		for marker in get_nodes_in_group("interactables"):
			if "target" in marker:
				check("marcador acessível: " + marker.title, main.is_solid(marker.position + Vector2(0, 2)))
		for prop in main.room.get("props", []):
			if prop.size() > 3:
				var tex: Texture2D = load(prop[0] if "/" in prop[0] else main.Rooms.TOWN_ENV + "props-sliced/" + prop[0] + ".png")
				check("recorte dentro da textura " + prop[0].get_file(), Rect2(Vector2.ZERO, tex.get_size()).encloses(prop[3]))
	await load_room("forest")
	var light = actors().filter(func(n): return n.kind == "light")[0]
	check("bandido mantém primeiro quadro da animação", light.sprite.sprite_frames.get_frame_texture("attack1", 0).resource_path.ends_with("_0.png"))
	check("bandido tem oito quadros de ataque", light.sprite.sprite_frames.get_frame_count("attack1") == 8)
	for bandit in actors().filter(func(n): return n.kind in ["light", "heavy"]):
		for facing in [-1, 1]:
			bandit.dir = facing
			bandit._update_animation()
			check("sprite de %s acompanha direção %d" % [bandit.kind, facing], bandit.sprite.flip_h == (facing > 0))
	check("corpo do bandido é vulnerável sem dano de contato", light.get_hurtbox().size.y > 0 and light.get_damagebox().size == Vector2.ZERO)
	p.frozen = false
	p.position = light.position + Vector2(40, 0)
	light._physics_process(0.01)
	check("bandido percebe jogador e entra em alerta", light.state == "alert")
	p.position = light.position - Vector2(40, 0)
	light._physics_process(0.01)
	check("alerta acompanha jogador à esquerda", light.dir == -1 and not light.sprite.flip_h)
	p.position = light.position + Vector2(40, 0)
	light._physics_process(0.4)
	check("alerta vira perseguição", light.state == "chase")
	light._physics_process(0.01)
	check("proximidade dispara preparação automática", light.state == "windup")
	p.position = light.position - Vector2(40, 0)
	light._physics_process(0.01)
	check("preparação acompanha troca de lado", light.dir == -1 and not light.sprite.flip_h)
	p.position = light.position + Vector2(40, 0)
	light.timer = 0.15
	light._physics_process(0.01)
	check("aviso final fixa direção para esquiva", light.dir == -1)
	light._begin_attack()
	light._physics_process(0.3)
	check("ataque à esquerda mantém sprite e dano no mesmo lado", light.dir == -1 and not light.sprite.flip_h and light.get_damagebox().end.x < light.position.x)
	light._face_player(0)
	check("sobreposição não faz orientação oscilar", light.dir == -1)
	p.frozen = true
	light.dir = 1
	light._begin_windup()
	check("aviso antecede golpe", light.state == "windup" and light.timer >= 0.5 and light.get_damagebox().size == Vector2.ZERO)
	light._begin_attack()
	check("início do golpe ainda não machuca", light.get_damagebox().size == Vector2.ZERO)
	light.attack_elapsed = 0.3
	check("espada tem alcance além do corpo", light.get_damagebox().size.x >= 48 and light.get_damagebox().position.x > light.position.x)
	p.position = light.position + Vector2(32, 0)
	p.invuln_timer = 0
	var before_hp: int = p.hp
	p._check_damage()
	check("espada ativa causa dano ao herói", p.hp == before_hp - 1)
	light.attack_elapsed = 0.55
	check("fim do golpe deixa de causar dano", light.get_damagebox().size == Vector2.ZERO)
	light.state = "recover"
	var old_hp: int = light.hp
	light.take_hit(Vector2.RIGHT, 1)
	check("recuperação pode ser punida", light.hp == old_hp - 1 and light.state == "hurt")
	var before_geo: int = gs.geo
	light.take_hit(Vector2.RIGHT, 999)
	light.take_hit(Vector2.RIGHT, 999)
	check("morte paga uma recompensa", gs.geo == before_geo + 10)
	var knight = actors().filter(func(n): return n.kind == "knight")[0]
	check("cavaleiro começa pacífico", not knight.is_in_group("enemies") and knight.get_hurtbox().size == Vector2.ZERO)
	knight.take_hit(Vector2.RIGHT, 99)
	check("golpe não inicia duelo sem interação", knight.hp == knight.MAX_HP)
	knight.interact()
	check("primeira interação abre diálogo", main.is_dialog_open() and knight.state == "friendly" and knight.challenged)
	main.hud.dialog.close()
	knight.interact()
	check("segunda interação aceita duelo", knight.is_in_group("enemies") and main.boss == knight and knight.state == "alert")
	knight._begin_windup()
	await capture("knight", Vector2(864, 192))
	before_geo = gs.geo
	knight.take_hit(Vector2.RIGHT, 999)
	knight.take_hit(Vector2.RIGHT, 999)
	check("duelo poupa cavaleiro e paga uma vez", knight.state == "spared" and not knight.is_in_group("enemies") and gs.geo == before_geo + 90)
	check("duelo registra vitória sem alterar chefes principais", gs.discoveries.has("knight_duel") and gs.defeated_bosses.is_empty())
	await load_room("forest")
	knight = actors().filter(func(n): return n.kind == "knight")[0]
	check("cavaleiro permanece pacífico ao retornar", knight.state == "spared")
	var cache = get_nodes_in_group("interactables").filter(func(n): return "discovery" in n and n.discovery == "forest_cache")[0]
	before_geo = gs.geo
	cache.interact()
	cache.interact()
	check("tesouro do acampamento não duplica", gs.geo == before_geo + 45)
	main.hud.dialog.close()
	await capture("forest_camp", Vector2(560, 320))
	marker_to("mountain").interact()
	await create_timer(0.65).timeout
	check("bosque conecta à serra", main.room_name == "mountain")
	await load_room("mountain")
	var captain = actors().filter(func(n): return n.kind == "captain")[0]
	captain.dir = -1
	captain._begin_windup()
	check("capitão orienta sprite para a esquerda", not captain.sprite.flip_h)
	check("capitão prepara golpe mais lentamente", captain.timer > 0.5)
	await capture("bandit_captain", Vector2(776, 320))
	before_geo = gs.geo
	captain.take_hit(Vector2.RIGHT, 999)
	captain.take_hit(Vector2.RIGHT, 999)
	check("capitão entrega recompensa única", gs.geo == before_geo + 80 and gs.discoveries.has("bandit_captain"))
	await load_room("mountain")
	check("capitão derrotado não reaparece", actors().filter(func(n): return n.kind == "captain").is_empty())
	await load_room("arcane_ruins")
	var wizard = actors()[0]
	var archive = get_nodes_in_group("interactables").filter(func(n): return "discovery" in n and n.discovery == "ruins_memory")[0]
	before_geo = gs.geo
	archive.interact()
	check("arquivo aguarda derrota do mago", not gs.discoveries.has("ruins_memory") and gs.geo == before_geo)
	main.hud.dialog.close()
	check("mago possui duas animações de ataque", wizard.sprite.sprite_frames.has_animation("attack2"))
	wizard.dir = -1
	wizard._begin_windup()
	main.boss = wizard
	await capture("evil_wizard", Vector2(536, 320))
	wizard._begin_attack()
	wizard.attack_elapsed = 0.3
	check("primeiro ataque do mago usa golpe de perto", wizard.get_damagebox().size.x > 0 and wizard.sprite.animation == "attack1")
	wizard._begin_windup()
	wizard._begin_attack()
	check("segundo ataque usa conjuração", wizard.get_damagebox().size == Vector2.ZERO and wizard.sprite.animation == "attack2")
	p.position = Vector2(536, 300)
	wizard._cast_seals()
	var seals: Array = main.world.get_children().filter(func(n): return "active" in n and "timer" in n and n.has_method("get_damagebox"))
	check("conjuração cria dois selos", seals.size() == 2)
	for seal in seals:
		seal.set_physics_process(false)
		check("selo avisa antes de machucar", not seal.active and seal.get_damagebox().size == Vector2.ZERO and seal.timer >= 0.7)
	var seal = seals[0]
	seal._physics_process(0.8)
	check("selo gera raio após aviso", seal.active and seal.get_damagebox().size.y == 90)
	seals[1].take_hit(Vector2.RIGHT, 1)
	check("golpe pode desfazer selo durante aviso", seals[1].is_queued_for_deletion())
	before_geo = gs.geo
	wizard.take_hit(Vector2.RIGHT, 999)
	wizard.take_hit(Vector2.RIGHT, 999)
	check("mago paga uma vez e libera arquivo", gs.geo == before_geo + 120 and gs.discoveries.has("evil_wizard"))
	archive.interact()
	archive.interact()
	check("arquivo recompensa uma vez", gs.geo == before_geo + 180 and gs.discoveries.has("ruins_memory"))
	await load_room("arcane_ruins")
	check("mago derrotado não reaparece", actors().is_empty())
	marker_to("cathedral").interact()
	await create_timer(0.65).timeout
	check("ruína permite voltar à catedral", main.room_name == "cathedral")
	await load_room("cathedral")
	marker_to("arcane_ruins").interact()
	await create_timer(0.65).timeout
	check("catedral conecta à ruína", main.room_name == "arcane_ruins")
	await load_room("forest", "B")
	gs.bench_room = "forest"
	check("banco do bosque salva novos encontros", gs.save_game(p))
	gs.discoveries.clear()
	check("save restaura vitórias e tesouros", gs.load_game() and gs.discoveries.has("knight_duel") and gs.discoveries.has("evil_wizard") and gs.discoveries.has("bandit_captain") and gs.discoveries.has("forest_cache") and gs.discoveries.has("ruins_memory"))
	gs.bench_room = "arcane_ruins"
	check("ruína é checkpoint válido", gs.save_game(p) and gs.load_game())
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(gs.save_path))
	saved.erase("discoveries")
	check("saves antigos continuam válidos", gs._valid_save(saved))
	await load_room("swamp")
	marker_to("forest").interact()
	await create_timer(0.65).timeout
	check("pântano reconecta ao bosque", main.room_name == "forest")
	await load_room("forest")
	marker_to("swamp").interact()
	await create_timer(0.65).timeout
	check("bosque permite seguir ao pântano", main.room_name == "swamp")
	await load_room("forest")
	marker_to("town").interact()
	await create_timer(0.65).timeout
	check("bosque reconecta à vila", main.room_name == "town")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
	await create_timer(0.3, true, false, true).timeout
	main = null
	p = null
	current_scene.queue_free()
	await settle()
	root.get_node("Audio").stop_all()
	await create_timer(0.1).timeout
	print("== NOVOS ASSETS: %d OK, %d FALHOU ==" % [passed, failed])
	quit(0 if failed == 0 else 1)
