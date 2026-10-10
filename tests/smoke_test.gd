extends SceneTree
## Teste automático: joga o jogo sozinho e confere os sistemas principais.
## Uso: godot --path . --script tests/smoke_test.gd
## (com janela; adicione --headless para rodar sem janela, mais rápido)
## Termina com código 0 se tudo passar e 1 se algo falhar.

const TITLE_SCENE := "res://game/ui/title.tscn"
const MAIN_SCENE := "res://game/world/main.tscn"

var main
var p
var passed := 0
var failed := []


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


## Fecha falas abertas (elas pausam o jogo; o teste não quer esperar cada uma).
func skip_dialogs() -> void:
	var main = current_scene
	while main.is_dialog_open():
		main.hud.dialog.close()
	await wait(2)


func enemies() -> Array:
	return get_nodes_in_group("enemies").filter(func(e): return not e.is_in_group("harmful"))


func game_state():
	return root.get_node_or_null("GameState")


func geo() -> int:
	return game_state().geo if game_state() else main.geo


func defeated(id: String) -> bool:
	return game_state().defeated_bosses.has(id) if game_state() else main.defeated_bosses.has(id)


func music_path() -> String:
	return root.get_node("Audio").music_path


func music_stream_ok() -> bool:
	var m: AudioStreamPlayer = root.get_node("Audio").music
	return m.stream != null and m.stream.get_length() > 30.0


func _run() -> void:
	print("== TESTE AUTOMÁTICO ==")
	# Usa um save só do teste, para não apagar o save de verdade.
	if game_state():
		game_state().save_path = "user://test_save.json"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state().save_path))

	# --- Título ---
	change_scene_to_file(TITLE_SCENE if ResourceLoader.exists(TITLE_SCENE) else "res://game/ui/title.tscn")
	await wait(30)
	check("tela de título abre", current_scene != null and current_scene.name == "Title")

	# --- Jogo ---
	change_scene_to_file(MAIN_SCENE if ResourceLoader.exists(MAIN_SCENE) else "res://game/world/main.tscn")
	await wait(20)
	main = current_scene
	p = main.player
	check("jogo abre na vila", main.room_name == "town" and p != null)
	check("Noct comenta ao chegar na vila", main.is_dialog_open() and main.hud.dialog.lines[0].begins_with("@"))
	check("30 rostos carregados", main.hud.dialog.portraits.size() == 30 and main.hud.dialog.portrait("ultimate") != null)
	var dlg = main.hud.dialog
	check("30 rostos da Forma Demoníaca carregados", dlg.crimson_portraits.size() == 30)
	check("personagens que falam têm rosto", dlg.npc_portraits.size() == dlg.NPC_PORTRAITS.size() and dlg.npc_portrait("Mira") != null)
	p.crimson_level = p.DEMON_FORM
	check("transformado, o diálogo usa o rosto da Forma Demoníaca", dlg.portrait("serio") == dlg.crimson_portraits["%d:serio" % p.DEMON_FORM])
	p.crimson_level = 0
	check("sem a forma, volta o rosto normal", dlg.portrait("serio") == dlg.portraits["serio"])
	check("comentário de chegada em balão sobre o Noct", main.hud.dialog.anchor.distance_to(p.global_position) < 40)
	await wait(4 * 60)
	check("comentário de chegada espera o botão", main.is_dialog_open())
	for i in main.hud.dialog.lines.size():
		await tap("up")
	check("comentário de chegada passa com o botão", not main.is_dialog_open(), "%s %d/%d %s" % [main.hud.dialog.speaker, main.hud.dialog.index, main.hud.dialog.lines.size(), main.hud.dialog.lines])

	# --- Diálogo ---
	var zeno = get_nodes_in_group("interactables").filter(func(n): return "npc_name" in n and n.npc_name == "Velho Zeno")[0]
	p.global_position.x = zeno.global_position.x
	await wait(5)
	await tap("up")
	check("conversa com NPC abre", main.is_dialog_open())
	var first_talk: Array = main.hud.dialog.lines.duplicate()
	for i in 10:
		await tap("up")
		if not main.is_dialog_open():
			break
	check("conversa fecha ao terminar", not main.is_dialog_open(), "%s %d/%d" % [main.hud.dialog.speaker, main.hud.dialog.index, main.hud.dialog.lines.size()])
	await tap("up")
	check("NPC tem conversa nova na segunda vez", main.is_dialog_open() and main.hud.dialog.lines != first_talk)
	for i in 10:
		await tap("up")
		if not main.is_dialog_open():
			break

	# --- Loja ---
	main.geo = 500
	var brom = get_nodes_in_group("interactables").filter(func(n): return "shop" in n and n.shop)[0]
	p.global_position.x = brom.global_position.x
	await wait(5)
	await tap("up")
	check("loja abre", main.is_shop_open())
	var hp_before: int = p.max_hp
	await tap("attack")
	check("compra na loja (máscara)", p.max_hp == hp_before + 1 and geo() == 420, "max_hp=%d geo=%d" % [p.max_hp, geo()])
	await tap("dash")
	await wait(4)
	check("loja fecha", not main.is_shop_open() and not p.frozen)

	# --- Banco ---
	p.global_position.x = main.entries["B"].x
	p.hp = 1
	await wait(5)
	await tap("up")
	check("banco cura", p.hp == p.max_hp)
	check("banco mostra um momento de Noct", main.is_dialog_open() and main.hud.dialog.lines.size() >= 3)
	if game_state():
		check("banco salva o jogo", game_state().has_save())
	for i in 3:
		await tap("up")

	# --- Agachar ---
	await skip_dialogs()
	var x_crouch: float = p.global_position.x
	Input.action_press("down")
	Input.action_press("move_right")
	await wait(20)
	check("baixo agacha e não anda", p.crouching and p.sprite.animation == "crouch" and absf(p.global_position.x - x_crouch) < 2,
		"%s %s dx=%.0f" % [p.crouching, p.sprite.animation, p.global_position.x - x_crouch])
	check("agachado encolhe a área de dano", p.get_hurtbox().size.y < p.SIZE.y)
	Input.action_release("down")
	Input.action_release("move_right")
	await wait(5)
	check("soltar baixo levanta", not p.crouching)

	# --- Olhar para cima ---
	# Rua livre de moradores, memórias e placas: cima deve controlar a câmera.
	p.enter_room(Vector2(720, 256))
	await wait(5)
	Input.action_press("move_right")
	for i in 120:
		if main.interactable == null and p.is_on_floor():
			break
		await wait(1)
	Input.action_release("move_right")
	await wait(10)
	var cam_y: float = p.cam.offset.y
	Input.action_press("up")
	await wait(4)
	check("toque rápido em cima não olha para cima", not p.looking_up)
	await wait(60)
	check("segurar cima parado olha para cima", p.looking_up and String(p.sprite.animation).begins_with("look_up"), p.sprite.animation)
	check("olhar para cima sobe a câmera", p.cam.offset.y < cam_y - 30, "offset %.0f" % p.cam.offset.y)
	Input.action_release("up")
	await wait(40)
	check("soltar cima volta a câmera", not p.looking_up and absf(p.look_offset.y) < 1)

	# --- Arranque, corrida e freada ---
	await wait(30)
	Input.action_press("move_left")
	await wait(3)
	check("correr a partir do Idle começa com o arranque", p.sprite.animation in ["run_start", "run"], p.sprite.animation)
	await wait(12)
	check("depois do arranque, corre", p.sprite.animation == "run", p.sprite.animation)
	Input.action_release("move_left")
	await wait(2)
	check("parar de correr freia (run_stop)", p.sprite.animation == "run_stop", p.sprite.animation)
	await wait(30)
	check("depois da freada, volta ao Idle", String(p.sprite.animation).begins_with("idle"), p.sprite.animation)

	# --- Todas as salas ---
	for r in ["swamp", "cemetery", "lair", "cathedral", "sanctum", "inferno", "demon_lair", "town"]:
		main.load_room(r, "L" if r != "town" else "B")
		await wait(5)
		var n := enemies().size()
		check("sala %s carrega" % r, main.room_name == r and (n > 0 or r == "town"), "inimigos=%d" % n)
		var th: Dictionary = main.theme
		check("música da sala %s" % r, music_path() in [th["music"], th.get("combat", "")] and music_stream_ok(), music_path())

	# --- Combate, Geo e XP ---
	main.load_room("swamp", "L")
	await wait(10)
	var target = null
	for e in enemies():
		if e.get("kind") == "spider":
			target = e
			break
	var geo0 := geo()
	var xp0: int = p.xp
	p.invuln_timer = 999.0
	for i in 12:
		if not is_instance_valid(target):
			break
		p.global_position = target.global_position + Vector2(-30, -12)
		p.facing = 1
		await tap("attack")
		await wait(12)
	check("golpe mata inimigo", not is_instance_valid(target))
	check("luta troca para a música de combate", music_path() == main.theme["combat"], music_path())
	check("inimigo dá Geo e XP", geo() > geo0 and p.xp > xp0, "geo %d->%d xp %d->%d" % [geo0, geo(), xp0, p.xp])

	# --- Socos diagonais (nível 1) ---
	main.load_room("cathedral", "L")
	await wait(5)
	for e in enemies(): e.queue_free()
	await wait(2)
	p.lvl = 1
	p.unlocked = {}
	Input.action_press("up")
	await tap("attack")
	Input.action_release("up")
	check("cima + ataque = soco diagonal para cima", p.move == "up_punch", p.move)
	await wait(40)
	Input.action_press("down")
	await tap("attack")
	Input.action_release("down")
	check("baixo + ataque no chão = soco até o chão", p.move == "low_punch", p.move)
	await wait(40)

	# --- Níveis ---
	p.gain_xp(5000)
	await wait(2)
	check("sobe até o nível 10", p.lvl == 10 and p.unlocked.size() == 6, "nv=%d skills=%d" % [p.lvl, p.unlocked.size()])
	check("fala de nível pausa o jogo", main.is_dialog_open() and paused)
	await skip_dialogs()
	await tap("debug_crimson")
	await wait(3)
	var form := "c%d_" % p.DEMON_FORM
	check("F3 liga a Forma Demoníaca (a única)", p.crimson_level == p.DEMON_FORM and String(p.sprite.animation).begins_with(form), p.sprite.animation)
	check("transformar toca a transição", p.sprite.animation == form + "transform", p.sprite.animation)
	# Abaixado: depois de abaixar, a energia carmesim continua animando.
	Input.action_press("down")
	await wait(110)   # a transição da forma toca antes de abaixar
	var f0: int = p.sprite.frame
	await wait(12)
	check("Forma Demoníaca abaixada continua animando", p.sprite.animation == form + "crouch_loop" 		and p.sprite.is_playing() and p.sprite.frame != f0, "%s quadro %d" % [p.sprite.animation, p.sprite.frame])
	Input.action_release("down")
	await wait(5)
	await tap("debug_crimson")   # forma -> normal
	await wait(3)
	check("forma carmesim volta ao normal", p.crimson_level == 0 and not String(p.sprite.animation).begins_with("c"), p.sprite.animation)

	# --- Magias ---
	p.soul = 99
	await tap("spell")
	await wait(20)   # a bola sai quando a pose da magia chega no soco
	check("magia gasta alma", p.soul == 66, "alma=%d" % p.soul)
	await wait(25)
	p.soul = 99
	p.hp = 2
	Input.action_press("spell")
	await wait(80)
	Input.action_release("spell")
	await wait(3)
	check("cura recupera vida", p.hp >= 3, "hp=%d" % p.hp)

	# --- Ultimate ---
	main.load_room("swamp", "L")
	await wait(5)
	p.global_position.x = 300
	var before := enemies().size()
	p.soul = 99
	await tap("ultimate")
	await wait(170)
	check("Ultimate acerta inimigos na tela", enemies().size() < before, "%d -> %d" % [before, enemies().size()])

	# --- Troca de sala ---
	main.load_room("swamp", "L")
	await wait(5)
	p.global_position.x = 10
	Input.action_press("move_left")
	await wait(60)
	Input.action_release("move_left")
	await wait(10)
	check("sair pela esquerda do pântano leva à vila", main.room_name == "town", main.room_name)

	# --- Chefe 1: Gato Infernal ---
	main.load_room("lair", "L")
	await wait(5)
	Input.action_press("move_right")
	await wait(30)
	Input.action_release("move_right")
	check("Gato acorda e fecha o portão", main.boss != null and main.boss.is_awake() and main.solid.has(Vector2i(0, 12)))
	check("Noct fala quando o chefe acorda", main.is_dialog_open())
	check("chefe tem música própria", music_path() == main.Rooms.BOSS_MUSIC["gato"], music_path())
	check("fala do chefe pausa a luta", paused)
	await skip_dialogs()
	main.boss.hp = 1
	main.boss.take_hit(Vector2.RIGHT, 1)
	await wait(10)
	check("Gato derrotado reabre o portão", defeated("gato") and not main.solid.has(Vector2i(0, 12)))
	for i in 4:
		await tap("up")

	# --- Chefe 2: Bringer of Death ---
	main.load_room("sanctum", "L")
	await wait(5)
	Input.action_press("move_right")
	await wait(30)
	Input.action_release("move_right")
	check("Bringer acorda", main.boss != null and main.boss.is_awake())
	await skip_dialogs()
	# Metade da vida: a luta vai para dentro da cabeça de Noct, com o mesmo Bringer.
	main.boss.hp = main.boss.MAX_HP / 2 + 1
	main.boss.take_hit(Vector2.RIGHT, 1)
	for i in 180:
		if main.room_name == "mind" and not main.transitioning:
			break
		await wait(1)
	check("Bringer leva a luta para a Mente do Noct e volta com a vida cheia", main.room_name == "mind" and main.boss != null and main.boss.in_mind
		and main.boss.hp == main.boss.MAX_HP, "sala=%s" % main.room_name)
	check("Mente do Noct fica fora do mapa", not game_state().visited.has("mind"))
	main.player.hp = main.player.max_hp
	await wait(300)
	check("Bringer provoca Noct sem pausar a luta", main.boss.taunt_index > 0 and not main.get_tree().paused)
	main.boss.hp = 1
	main.boss.take_hit(Vector2.RIGHT, 1)
	for i in 600:
		if defeated("bringer") and main.room_name == "sanctum" and not main.transitioning:
			break
		await wait(1)
	check("Bringer derrotado", defeated("bringer"))
	check("Vitória volta para o Santuário", main.room_name == "sanctum", "sala=%s" % main.room_name)
	for i in 5:
		await tap("up")

	# --- Inferno: inimigos novos e lava ---
	main.load_room("inferno", "L")
	await wait(5)
	var kinds := {}
	for e in enemies():
		kinds[str(e.get("kind"))] = true
	check("Inferno tem cão, caveira e olho", kinds.has("hound") and kinds.has("skull") and kinds.has("eye"), str(kinds.keys()))
	var hound = null
	for e in enemies():
		if e.get("kind") == "hound":
			hound = e
			break
	p.invuln_timer = 999.0
	var leaped := false
	for i in 90:
		if not is_instance_valid(hound):
			break
		p.global_position = hound.global_position + Vector2(-70, -10)
		await wait(1)
		if hound.leaping:
			leaped = true
			break
	check("cão infernal salta no herói", leaped)
	var shot := false
	for e in enemies():
		if e.get("kind") == "eye":
			p.global_position = e.global_position + Vector2(-100, 40)
			for i in 200:
				await wait(1)
				for h in get_nodes_in_group("harmful"):
					if h.get_script().resource_path.ends_with("enemy_projectile.gd"):
						shot = true
				if shot:
					break
			break
	check("olho demoníaco atira", shot)
	main.load_room("inferno", "L")
	await wait(5)
	for e in enemies(): e.queue_free()
	await wait(2)
	p.invuln_timer = 0
	var hp_lava: int = p.hp
	p.global_position = Vector2(16 * 16 + 8, 25 * 16 - 4)
	await wait(10)
	# Os fragmentos carmesim levam menos de 1 s para remontar o Noct no chão seguro.
	for i in 120:
		if p.shatter == null:
			break
		await wait(1)
	check("lava machuca e devolve ao chão seguro", p.hp < hp_lava and p.global_position.y < 24 * 16, "hp %d->%d" % [hp_lava, p.hp])
	p.hp = p.max_hp

	# --- Amuletos ---
	if game_state():
		var gs = game_state()
		p.global_position = Vector2(10 * 16 + 8, 11 * 16)
		await wait(10)
		check("pega amuleto escondido (Lâmina Rubra)", gs.owned_charms.has("red_blade"))
		for i in 4:
			await tap("up")
		var bonus0: int = p._melee_bonus()
		# longe do banco: não deixa equipar
		await tap("pause")
		for i in 3:   # Continuar, Mapa, Memórias -> Amuletos
			await tap("down")
		await tap("attack")
		await tap("attack")
		check("não equipa longe do banco", not gs.equipped_charms.has("red_blade"))
		await tap("dash")
		await tap("dash")
		await wait(3)
		# no banco: equipa
		p.global_position = Vector2(5 * 16 + 8, 25 * 16 - 21)
		await wait(20)
		check("herói ao lado do banco", main.is_at_bench(), "pos=%s" % p.global_position)
		await tap("pause")
		for i in 4:   # Continuar, Mapa, Memórias, Glossário -> Amuletos
			await tap("down")
		await tap("attack")
		await tap("attack")
		check("equipa amuleto no banco", gs.equipped_charms.has("red_blade"))
		await tap("dash")
		await tap("dash")
		await wait(3)
		check("Lâmina Rubra dá +1 de dano", p._melee_bonus() == bonus0 + 1, "%d -> %d" % [bonus0, p._melee_bonus()])
		gs.owned_charms["stone_skin"] = true
		var hp_base: int = p.max_hp
		gs.equipped_charms.append("stone_skin")
		p.on_charms_changed()
		check("Pele de Pedra dá +1 máscara", p.max_hp == hp_base + 1)
		gs.equipped_charms.erase("stone_skin")
		p.on_charms_changed()

	# --- Chefe final: Demon Slime ---
	main.play_ending = false   # o final (troca de cena) é testado em tests/story_test.gd
	main.load_room("demon_lair", "L")
	await wait(5)
	Input.action_press("move_right")
	await wait(30)
	Input.action_release("move_right")
	check("Demon Slime acorda e fecha o portão", main.boss != null and main.boss.is_awake() and main.solid.has(Vector2i(0, 12)))
	await skip_dialogs()
	p.invuln_timer = 999.0
	await wait(120)   # deixa ele atacar um pouco
	main.boss.hp = 1
	main.boss.take_hit(Vector2.RIGHT, 1)
	for i in 40:   # o golpe final tem câmera lenta
		await wait(10)
		if defeated("demon_slime"):
			break
	await wait(5)
	check("Demon Slime derrotado (fim do jogo)", defeated("demon_slime") and main.is_dialog_open())
	for i in 12:
		await tap("up")
	check("falas do final passam com o botão", not main.is_dialog_open())

	# --- Pausa ---
	var x_before: float = p.global_position.x
	await tap("pause")
	await wait(2)
	check("pausa", paused)
	await tap("dash")
	await wait(3)
	check("despausa", not paused)
	await wait(15)
	check("sair da pausa com K não dá dash", absf(p.global_position.x - x_before) < 4, "andou %.0f px" % absf(p.global_position.x - x_before))

	# --- Morte e volta ao banco ---
	var respawn_room: String = game_state().bench_room
	main.load_room("swamp", "L")
	await wait(5)
	p.invuln_timer = 0
	p.hp = 1
	p._take_damage(1, false)
	await wait(150)
	check("morte volta ao banco com vida cheia", main.room_name == respawn_room and p.hp == p.max_hp, "%s hp=%d" % [main.room_name, p.hp])

	# --- Continuar um jogo salvo ---
	if game_state():
		main.load_room("cathedral", "L")
		await wait(5)
		p.global_position.x = 6 * 16 + 8
		await wait(5)
		await tap("up")   # descansa no banco da catedral (salva)
		for i in 3:
			await tap("up")
		var lvl_saved: int = p.lvl
		var max_hp_saved: int = p.max_hp
		check("salvou na catedral", game_state().bench_room == "cathedral")
		game_state().reset()
		check("save carrega", game_state().load_game())
		change_scene_to_file(MAIN_SCENE)
		await wait(20)
		main = current_scene
		p = main.player
		check("Continuar volta ao banco salvo", main.room_name == "cathedral", main.room_name)
		check("Continuar mantém nível e vida", p.lvl == lvl_saved and p.max_hp == max_hp_saved,
			"nv %d/%d hp %d/%d" % [p.lvl, lvl_saved, p.max_hp, max_hp_saved])
		check("Continuar lembra chefes derrotados", main.boss == null and defeated("bringer"))
		check("Continuar lembra amuletos", game_state().owned_charms.has("red_blade") and game_state().equipped_charms.has("red_blade"))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(game_state().save_path))

	print("== RESULTADO: %d OK, %d FALHOU ==" % [passed, failed.size()])
	if not failed.is_empty():
		print("Falhas: ", failed)
	# Libera a cena e espera efeitos pendentes para encerrar sem recursos em uso.
	await create_timer(0.6, true, false, true).timeout
	main = null
	p = null
	current_scene.queue_free()
	await process_frame
	await process_frame
	root.get_node("Audio").stop_all()
	await create_timer(0.1).timeout
	quit(0 if failed.is_empty() else 1)
