extends SceneTree
## Coração da Fenda (docs/expansao_forma_demoniaca.md, 1.6): entrada pelo fundo do Lago Velado, Faminto da Fenda
## (acorda com a Forma Demoníaca, morde e rouba barra, foge sem ela), rachaduras que explodem, parede de cristal
## que só o dash da forma quebra e o atalho para o Inferno. Também confere os sprites novos dos inimigos.
## Usa um save só do teste. Uso: godot --headless --path . --script tests/rift_heart_test.gd
## Com janela e -- --screenshots salva prévias em docs/content-preview/.

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


func gs():
	return root.get_node("GameState")


func skip_dialogs() -> void:
	var guard := 0
	while main.is_dialog_open() and guard < 50:
		main.hud.dialog.close()
		guard += 1
		await wait(2)
	await wait(2)


func place(feet: Vector2) -> void:
	p.global_position = feet - Vector2(0, p.SIZE.y / 2)
	p.velocity = Vector2.ZERO
	await wait(3)


func marker(title: String):
	for m in get_nodes_in_group("interactables"):
		if "title" in m and m.title == title:
			return m
	return null


func of_script(name: String) -> Array:
	return get_nodes_in_group("enemies").filter(func(e): return e.get_script().resource_path.ends_with(name))


func shot(name: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	main.hud.banner_timer = 0
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	var dir := "res://docs/content-preview/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	root.get_texture().get_image().save_png(dir + name + ".png")


func _run() -> void:
	print("== CORAÇÃO DA FENDA ==")
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.action_erase_events(action)
	gs().save_path = "user://test_rift_heart_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	gs().reset()
	change_scene_to_file("res://game/world/main.tscn")
	await wait(20)
	main = current_scene
	p = main.player
	await skip_dialogs()
	var d = p.demon

	check("sala registrada", Rooms.ROOMS.has("rift_heart"))
	var rows: Array = Rooms.ROOMS["rift_heart"]["map"]
	check("mapa retangular", rows.all(func(r): return r.length() == rows[0].length()))

	# --- Sprites novos ---
	var es = load("res://game/enemies/expansion_sprites.gd")
	for spec in [["lamento", Vector2(32, 40), {"fly": [8, true]}],
			["miragem", Vector2(32, 48), {"idle": [4, true], "windup": [8, false], "lunge": [10, false]}],
			["sanguessuga", Vector2(24, 24), {"hang": [6, true], "fall": [10, true], "crawl": [8, true], "latched": [10, true]}],
			["faminto", Vector2(64, 40), {"sleep": [3, true], "wake": [8, false], "idle": [6, true], "run": [14, true], "bite": [14, false]}]]:
		var f: SpriteFrames = es.frames(spec[0], spec[1], spec[2])
		check("sprites: " + spec[0], spec[2].keys().all(func(a): return f.has_animation(a) and f.get_frame_count(a) > 0))

	# --- Entrada pelo Lago ---
	gs().seen_intros["lake"] = true
	main.load_room("lake", "L")
	await wait(6)
	await skip_dialogs()
	if main.boss:
		main.boss.queue_free()
		main.boss = null
	var rift = marker("Fenda do fundo do lago")
	check("fenda do lago existe", rift != null)
	check("fenda do lago fechada antes do Velário", not main.requirement_met(rift.requires))
	gs().defeated_bosses["velario"] = true
	p.unlocked["demon1"] = true
	await place(Vector2(616, 224))
	rift.interact()
	await wait(40)
	await skip_dialogs()
	check("fenda leva ao Coração da Fenda", main.room_name == "rift_heart", main.room_name)
	p.invuln_timer = 9999.0
	await shot("rift_heart")

	# --- Faminto da Fenda ---
	var hounds := of_script("enemy_starved.gd")
	check("dois Famintos", hounds.size() == 2)
	var h = hounds[0]
	await place(Vector2(h.global_position.x - 90, 224))
	await wait(30)
	check("Faminto dorme sem a forma", h.state == "sleep")
	d.gauge = d.MAX_GAUGE
	d.try_toggle()
	await wait(int(d.TRANSFORM_TIME * 60) + 10)
	check("Faminto acorda com a forma", h.state in ["wake", "chase", "bite"], h.state)
	await wait(30)
	check("Faminto persegue", h.state in ["chase", "bite"], h.state)
	await shot("faminto_caca")
	# Mordida: machuca e rouba barra.
	p.invuln_timer = 0
	p.hp = p.max_hp
	var gauge_before: float = d.gauge
	var guard := 0
	while p.hp == p.max_hp and guard < 240:
		await wait(1)
		guard += 1
	check("mordida machuca", p.hp < p.max_hp)
	check("mordida rouba barra da Fenda", d.gauge < gauge_before - 10, "%.0f -> %.0f" % [gauge_before, d.gauge])
	p.invuln_timer = 9999.0
	# Sem a forma, foge para a toca.
	d.try_toggle()
	await wait(40)   # termina a mordida em andamento
	check("sem a forma, o Faminto foge ou dorme", h.state in ["flee", "sleep"], h.state)
	guard = 0
	while h.state != "sleep" and guard < 400:
		await wait(1)
		guard += 1
	check("volta a dormir", h.state == "sleep")

	# --- Rachaduras ---
	var cracks: Array = main.world.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("rift_crack.gd"))
	check("seis rachaduras", cracks.size() == 6)
	var c = cracks[0]
	var erupted := false
	for i in 200:
		await wait(1)
		if c.get_hurtbox().size != Vector2.ZERO:
			erupted = true
			break
	check("rachadura explode de tempos em tempos", erupted)

	# --- Parede de cristal ---
	var crystals := get_nodes_in_group("rift_crystals")
	check("parede de cristal (12 blocos)", crystals.size() == 12)
	check("cristal é sólido", main.is_solid(crystals[0].global_position + Vector2(8, 8)))
	await place(Vector2(41 * 16 - 10, 224))
	p.facing = 1
	d.gauge = 0.0
	p.dash_timer = 0
	p.dash_cooldown = 0
	Input.action_press("dash")
	await wait(2)
	Input.action_release("dash")
	await wait(20)
	check("dash sem a forma não quebra cristal", get_nodes_in_group("rift_crystals").size() == 12)
	p.dash_cooldown = 0
	d.gauge = d.MAX_GAUGE
	d.try_toggle()
	await wait(int(d.TRANSFORM_TIME * 60) + 10)
	await place(Vector2(41 * 16 - 10, 224))
	p.facing = 1
	Input.action_press("dash")
	await wait(2)
	Input.action_release("dash")
	await wait(20)
	check("dash da forma quebra o cristal", get_nodes_in_group("rift_crystals").size() < 12)
	check("o lugar do cristal fica livre", not main.is_solid(Vector2(41 * 16 + 8, 13 * 16 + 8)) or not main.is_solid(Vector2(41 * 16 + 8, 12 * 16 + 8)))

	# --- Atalho ---
	var exit = marker("Atalho para o Inferno")
	check("atalho para o Inferno existe", exit != null and exit.target == "inferno")
	exit.interact()
	await wait(40)
	await skip_dialogs()
	check("atalho leva ao Inferno", main.room_name == "inferno", main.room_name)

	print("== RESULTADO: %d OK, %d FALHOU ==" % [passed, failed.size()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	quit(0 if failed.is_empty() else 1)
