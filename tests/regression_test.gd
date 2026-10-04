extends SceneTree
## Casos de regressão com save próprio; nunca lê ou escreve o save do jogador.

const ShopItems := preload("res://data/shop_items.gd")
const EnemyScripts := [
	"res://game/enemies/enemy_crawler.gd",
	"res://game/enemies/enemy_flyer.gd",
	"res://game/enemies/enemy_caster.gd",
]
var passed := 0
var failed := 0
var main
var p


func _initialize() -> void:
	_run.call_deferred()


func check(label: String, success: bool) -> void:
	print("  OK      " if success else "  FALHOU  ", label)
	if success:
		passed += 1
	else:
		failed += 1


## Termina na hora o voo dos fragmentos dos espinhos (o efeito dura menos de 1 s).
func finish_shatter() -> void:
	if p.shatter != null:
		p.shatter._process(p.ShardScript.TOTAL)
		p._process_shatter()


func write_json(path: String, data: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()


func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.save_path = "user://regression_%d.json" % Time.get_ticks_usec()
	change_scene_to_file("res://game/world/main.tscn")
	await process_frame
	await process_frame
	main = current_scene
	p = main.player
	p.frozen = true
	main.hud.dialog.close()
	for rising in [false, true]:
		if rising:
			p.unlocked["uppercut"] = true
		else:
			p.unlocked.erase("uppercut")
		p.velocity.y = 0
		Input.action_press("up")
		Input.action_press("attack")
		p._handle_attack_input(0.01)
		check("soco para cima não lança Noct: " + ("uppercut" if rising else "up_punch"), p.move == ("uppercut" if rising else "up_punch") and p.velocity.y == 0)
		Input.action_release("attack")
		Input.action_release("up")
		p._cancel_move()
		await process_frame
	p.unlocked.erase("uppercut")
	# Apertar o lado oposto durante o combo vira o Noct no próximo golpe, sem cortar o atual.
	p.facing = 1
	p.combo_timer = 0
	p._start_combo_hit()
	var first_move: String = p.move
	Input.action_press("move_left")
	p._move(-1.0, 0.01)
	check("golpe atual não vira no meio", p.facing == 1 and p.move == first_move)
	p.attack_queued = true
	p._on_anim_finished()
	check("próximo golpe do combo sai para o lado apertado", p.facing == -1 and p.sprite.flip_h and p.move != "")
	check("área do golpe virado fica à esquerda", p._move_rect(p.move).end.x <= p.global_position.x + 1)
	Input.action_release("move_left")
	p._cancel_move()
	p.combo_timer = 0
	p.facing = 1
	# Combo no chão de 5 golpes (com o combo liberado).
	if not p.has("combo"):
		p.unlocked["combo"] = true
	var ground_chain := []
	for i in 20:   # assenta no chão
		p.velocity = Vector2(0, 400)
		p.move_and_slide()
	p.velocity = Vector2.ZERO
	p._start_combo_hit()
	ground_chain.append(p.move)
	for i in 4:
		p.attack_queued = true
		p._on_anim_finished()
		ground_chain.append(p.move)
	check("combo no chão tem 5 golpes até o finalizador: " + str(ground_chain), ground_chain == ["punch", "combo", "kick", "combo4", "finisher"])
	# Cada forma carmesim tem o seu combo no chão.
	for lv in [1, 2, 3]:
		p._cancel_move()
		p.combo_timer = 0
		p.crimson_level = lv
		var form_chain := []
		p._start_combo_hit()
		form_chain.append(p.move)
		for i in p.FORM_COMBOS[lv]["ground"].size() - 1:
			p.attack_queued = true
			p._on_anim_finished()
			form_chain.append(p.move)
		check("forma %d tem o próprio combo no chão: %s" % [lv, str(form_chain)], form_chain == p.FORM_COMBOS[lv]["ground"])
		check("forma %d toca a arte da forma no golpe" % lv, String(p.sprite.animation).begins_with("c%d_" % lv))
	# A partir do nível 2 os golpes são inéditos: animação que o Noct base não tem, com arte da forma.
	for lv in [2, 3]:
		for kind in ["ground", "air"]:
			for mv in p.FORM_COMBOS[lv][kind]:
				var anim: String = p.MOVES[mv]["anim"]
				check("golpe %s da forma %d é inédito" % [mv, lv], not p.Sprites.HERO_ANIMS.has(anim) \
					and p.sprite.sprite_frames.has_animation("c%d_%s" % [lv, anim]))
	p.crimson_level = 0
	p._cancel_move()
	p.combo_timer = 0
	var before_air: Vector2 = p.position
	p.position.y -= 120
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	p.combo_timer = 0
	p._start_combo_hit()
	check("ataque no ar inicia combo aéreo", p.move == "air_punch")
	p.attack_queued = true
	p._on_anim_finished()
	check("ataque emendado no ar passa ao chute", p.move == "air_kick")
	p.attack_queued = true
	p._on_anim_finished()
	check("terceiro ataque no ar é o corte giratório", p.move == "air_spin")
	p.attack_queued = true
	p._on_anim_finished()
	check("quarto ataque usa finalização aérea", p.move == "air_finish")
	check("combo aéreo não acrescenta impulso ou levitação", p.velocity.y == 0)
	var air_duration := 0.0
	for animation in ["air_punch", "air_kick", "air_spin", "air_finish"]:
		air_duration += p.sprite.sprite_frames.get_frame_count(animation) / p.sprite.sprite_frames.get_animation_speed(animation)
	check("combo inteiro cabe no salto normal", air_duration < 2.0 * absf(p.JUMP_VELOCITY) / p.GRAVITY)
	p.soul = 0
	p.spell_cooldown = 1
	Input.action_press("down")
	Input.action_press("attack")
	p._handle_attack_input(0.01)
	check("baixo e ataque finalizam combo com mergulho sem alma", p.slamming and p.soul == 0 and p.move == "" and p.velocity.y == p.SLAM_SPEED)
	check("finalização não usa recarga de magia", p.spell_cooldown == 1)
	Input.action_release("attack")
	Input.action_release("down")
	p.slamming = false
	p.invuln_timer = 0
	p.spell_cooldown = 0
	p.velocity = Vector2.ZERO
	p._cancel_move()
	p.combo_timer = 0
	p.position = before_air
	gs.geo = 1000
	main.hud.shop._buy(ShopItems.ITEMS[1])
	p.gain_xp(400)
	check("compra antes do nível 6 mantém 19 de alma por golpe", p.soul_per_hit == 19)
	gs.bought.erase("soul")
	p.soul_per_hit = 14
	main.hud.shop._buy(ShopItems.ITEMS[1])
	check("compra depois do nível 6 mantém 19 de alma por golpe", p.soul_per_hit == 19)
	check("grava save novo", gs.save_game(p))
	gs.geo = 321
	check("substitui save existente", gs.save_game(p))
	var original := FileAccess.get_file_as_string(gs.save_path)
	var good: Dictionary = JSON.parse_string(original)
	check("carrega save válido", gs.load_game() and gs.geo == 321)
	var legacy := good.duplicate(true)
	legacy["hero"]["soul_per_hit"] = 16
	write_json(gs.save_path, legacy)
	check("recupera bônus de alma de save antigo", gs.load_game() and gs.hero["soul_per_hit"] == 19)

	var corruptions := [
		{"label": "versão desconhecida", "key": "version", "value": 2},
		{"label": "sala inexistente", "key": "bench_room", "value": "missing"},
		{"label": "sala sem banco", "key": "bench_room", "value": "lair"},
		{"label": "herói incompleto", "key": "hero", "value": {"lvl": 6}},
		{"label": "lista de chefes inválida", "key": "defeated_bosses", "value": "gato"},
		{"label": "amuleto desconhecido", "key": "owned_charms", "value": ["missing"]},
		{"label": "amuleto não adquirido", "key": "equipped_charms", "value": ["red_blade"]},
		{"label": "quantidade de compra inválida", "key": "bought", "value": {"soul": 2}},
		{"label": "Geo fracionado", "key": "geo", "value": 1.5},
	]
	for corruption in corruptions:
		var bad := good.duplicate(true)
		bad[corruption["key"]] = corruption["value"]
		write_json(gs.save_path, bad)
		gs.geo = 777
		check("rejeita " + corruption["label"] + " sem alterar partida", not gs.load_game() and gs.geo == 777)
	var bad_equipment := good.duplicate(true)
	bad_equipment["owned_charms"] = ["red_blade", "stone_skin", "sharp_spell"]
	bad_equipment["equipped_charms"] = bad_equipment["owned_charms"]
	write_json(gs.save_path, bad_equipment)
	check("rejeita excesso de encaixes", not gs.load_game())
	bad_equipment["equipped_charms"] = ["red_blade", "red_blade"]
	write_json(gs.save_path, bad_equipment)
	check("rejeita amuleto duplicado", not gs.load_game())

	write_json(gs.save_path, good)
	var before_failure := FileAccess.get_file_as_string(gs.save_path)
	# Um diretório no caminho temporário provoca falha de abertura determinística.
	var temporary_absolute := ProjectSettings.globalize_path(gs.save_path + ".tmp")
	DirAccess.make_dir_absolute(temporary_absolute)
	check("falha de escrita preserva o save anterior", not gs.save_game(p) and FileAccess.get_file_as_string(gs.save_path) == before_failure)
	main.rest_at_bench()
	check("banco informa falha de gravação", main.hud.dialog.lines[0].contains("Não foi possível salvar"))
	DirAccess.remove_absolute(temporary_absolute)
	check("grava novamente após falha", gs.save_game(p))
	gs.load_game()
	main.hud.charms._toggle("red_blade") # indisponível: sem alteração
	gs.owned_charms["red_blade"] = true
	p.global_position = main.entries["B"] - Vector2(0, p.SIZE.y / 2)
	main.interactable = get_nodes_in_group("interactables").filter(func(node): return node.has_method("rest_here"))[0]
	main.hud.charms._toggle("red_blade")
	check("equipar no banco grava imediatamente", gs.load_game() and gs.equipped_charms.has("red_blade"))

	for script_path in EnemyScripts:
		var script = load(script_path)
		var enemy = script.new()
		enemy.level = main
		main.add_to_world(enemy)
		var geo_before: int = gs.geo
		var xp_before: int = p.xp
		enemy.take_hit(Vector2.RIGHT, 999)
		var reward_geo: int = gs.geo
		var reward_xp: int = p.xp
		enemy.take_hit(Vector2.RIGHT, 999)
		check("dano simultâneo premia uma vez: " + script.resource_path.get_file(), reward_geo > geo_before and reward_xp > xp_before and gs.geo == reward_geo and p.xp == reward_xp)
	main.load_room("lair", "L")
	var cat = main.boss
	cat.take_hit(Vector2.RIGHT, 999)
	var cat_geo: int = gs.geo
	var cat_hp: int = p.base_max_hp
	cat.take_hit(Vector2.RIGHT, 999)
	check("Gato entrega recompensa uma vez", gs.geo == cat_geo and p.base_max_hp == cat_hp)

	p.move = "cast"
	p.orb_pending = true
	p.attack_queued = true
	p.charging = true
	p.vertical_timer = 1
	p.recoil_x = 100
	p.focusing = true
	p.focus_progress = 0.8
	p.ultimate_timer = 2
	p.slamming = true
	main.load_room("town", "B")
	check("transição cancela ataques, magia e Ultimate", p.move == "" and not p.orb_pending and not p.attack_queued and not p.charging and p.vertical_timer == 0 and p.ultimate_timer == 0)
	check("transição limpa recuo, cura e mergulho", p.velocity == Vector2.ZERO and p.recoil_x == 0 and not p.focusing and p.focus_progress == 0 and not p.slamming)
	main.load_room("inferno", "L")
	p.invuln_timer = 0
	p.hurt_timer = 0
	p.hp = p.max_hp
	var before_lava: int = p.hp
	p.global_position = Vector2(16 * 16 + 8, 25 * 16 - 4)
	p.soul = 20
	p.slamming = true
	p._process_slam()
	check("lava desfaz o Noct em fragmentos e custa 1/3 de uma magia em alma", p.hp == before_lava - 1 and not p.slamming and p.shatter != null and not p.sprite.visible and p.soul == 20 - p.SPELL_COST / 3)
	finish_shatter()
	check("fragmentos remontam o Noct no chão seguro", p.shatter == null and p.sprite.visible and p.global_position == p.safe_pos)
	var lava: Rect2 = main.hazards[0]
	var walker = main._spawn(load("res://game/enemies/enemy_crawler.gd"), lava.get_center(), {"kind": "skeleton"})
	var walker_hp: int = walker.hp
	main._hurt_enemies_on_hazards(0.016)
	main._hurt_enemies_on_hazards(0.016)
	check("inimigo comum na armadilha leva 1 de dano e pisca", walker.hp == walker_hp - 1 and walker.flash > 0)
	main._hurt_enemies_on_hazards(main.HAZARD_ENEMY_COOLDOWN)
	check("armadilha volta a ferir o inimigo após o intervalo", walker.hp == walker_hp - 2)
	walker.queue_free()
	var captain = main._spawn(load("res://game/enemies/enemy_humanoid.gd"), lava.get_center(), {"kind": "captain"})
	var captain_hp: int = captain.hp
	main._hurt_enemies_on_hazards(0.016)
	check("chefe é imune a armadilhas", captain.hp == captain_hp)
	captain.queue_free()
	var cautious = main._spawn(load("res://game/enemies/enemy_crawler.gd"), Vector2(lava.position.x - 12, lava.end.y), {"kind": "skeleton"})
	check("inimigo enxerga a armadilha à frente e não o chão livre atrás", cautious._hazard_ahead(1) and not cautious._hazard_ahead(-1))
	cautious.queue_free()
	p.hurt_timer = 0
	p.global_position.y = p.world_size.y + p.SIZE.y * 2
	p.slamming = true
	var before_fall: int = p.hp
	p.invuln_timer = 0
	p.soul = 5
	p._process_slam()
	finish_shatter()
	check("mergulho sem chão retorna à posição segura", p.hp == before_fall - 1 and not p.slamming and p.global_position == p.safe_pos)
	check("alma não fica negativa ao cair", p.soul == 0)

	# Menu de hacks (F1): só em debug, não grava save sozinho.
	var hacks = main.debug_menu
	check("menu de hacks existe na build de debug", hacks != null)
	var save_before := FileAccess.file_exists(gs.save_path)
	hacks.god_mode = true
	p.invuln_timer = 0
	var god_hp: int = p.hp
	p.hit_by_boss(1.0)
	check("invencível ignora dano", p.hp == god_hp)
	hacks.god_mode = false
	hacks.infinite_soul = true
	hacks.infinite_geo = true
	p.soul = 0
	hacks._process(0.016)
	check("alma e Geo infinitos", p.soul == p.MAX_SOUL and gs.geo == hacks.INFINITE_GEO)
	hacks.infinite_soul = false
	hacks.infinite_geo = false
	hacks._choose(7)
	check("liberar habilidades dá garras, fenda e golpes", main.has_wall_grip() and main.has_rift_step() and p.has("ultimate"))
	hacks._choose(2)
	check("nível máximo pelo menu", p.lvl == hacks.Progression.MAX_LEVEL)
	hacks.room_index = hacks.rooms.find("tower")
	main.hud.dialog.close()
	paused = true
	hacks._choose(0)
	for i in 120:
		if main.room_name == "tower" and not main.transitioning:
			break
		await create_timer(0.05, true, false, true).timeout
	check("menu leva para a sala escolhida", main.room_name == "tower")
	check("menu de hacks não grava o save", FileAccess.file_exists(gs.save_path) == save_before)
	main.hud.dialog.close()
	# Espera hitstops/efeitos pendentes antes de liberar a cena do teste.
	await create_timer(0.6, true, false, true).timeout
	change_scene_to_file("res://game/ui/title.tscn")
	await process_frame
	await process_frame
	write_json(gs.save_path, {"version": 99})
	var title = current_scene
	gs.geo = 777
	title._start_game(true)
	check("Continuar inválido permanece no título e preserva partida", current_scene == title and not title.starting and title.save_error != "" and gs.geo == 777)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
	print("== REGRESSÃO: %d OK, %d FALHOU ==" % [passed, failed])
	main = null
	p = null
	current_scene.queue_free()
	await process_frame
	await process_frame
	root.get_node("Audio").stop_all()
	await create_timer(0.1).timeout
	quit(0 if failed == 0 else 1)
