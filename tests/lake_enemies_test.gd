extends SceneTree
## Inimigos da Margem do Lago Velado: Lamento (espectro fraco), Miragem (cópias falsas, só a verdadeira
## machuca e tem reflexo) e Sanguessuga de alma (cai do teto, gruda, drena alma, dash solta).
## Usa um save só do teste. Uso: godot --headless --path . --script tests/lake_enemies_test.gd

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
	await wait(2)


func of_script(name: String) -> Array:
	return get_nodes_in_group("enemies").filter(func(e): return e.get_script().resource_path.ends_with(name))


func _run() -> void:
	print("== INIMIGOS DO LAGO ==")
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.action_erase_events(action)
	gs().save_path = "user://test_lake_enemies_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	gs().reset()
	change_scene_to_file("res://game/world/main.tscn")
	await wait(20)
	main = current_scene
	p = main.player
	await skip_dialogs()
	gs().seen_intros["lake_shore"] = true
	main.load_room("lake_shore", "SANCTUM")
	await wait(6)
	await skip_dialogs()

	var laments := get_nodes_in_group("enemies").filter(func(e): return "kind" in e and e.kind == "lament")
	var mirages := of_script("enemy_mirage.gd")
	var leeches := of_script("enemy_leech.gd")
	check("dois Lamentos na Margem", laments.size() == 2)
	check("uma Miragem na Margem", mirages.size() == 1)
	check("duas Sanguessugas na Margem", leeches.size() == 2)

	# --- Lamento: espectro fraco (3 de vida) ---
	var l = laments[0]
	l.take_hit(Vector2.RIGHT, 2)
	check("Lamento aguenta 2", is_instance_valid(l) and not l.is_queued_for_deletion())
	l.take_hit(Vector2.RIGHT, 1)
	await wait(2)
	check("Lamento morre com 3", not is_instance_valid(l))

	# --- Sanguessuga ---
	var s = leeches[0]
	check("sanguessuga presa no teto", s.state == "hang" and main.is_solid(s.global_position + Vector2(0, -16)))
	p.soul = p.MAX_SOUL
	p.invuln_timer = 9999.0
	await place(Vector2(s.global_position.x, 13 * 16 + 16))
	var guard := 0
	while s.state != "latched" and guard < 120:
		await wait(1)
		guard += 1
	check("cai e gruda no Noct", s.state == "latched", s.state)
	var hp_before: int = p.hp
	var soul_before: int = p.soul
	await wait(60)
	check("drena alma (~11/s)", p.soul <= soul_before - 9 and p.soul >= soul_before - 14, "%d -> %d" % [soul_before, p.soul])
	check("não tira vida", p.hp == hp_before)
	p.dash_timer = 0.16
	await wait(2)
	check("dash solta", s.state != "latched")
	p.dash_timer = 0
	var soul_low: int = p.soul
	s.take_hit(Vector2.RIGHT, 99)
	await wait(2)
	check("morta, devolve a alma roubada", p.soul > soul_low, "%d -> %d" % [soul_low, p.soul])

	# --- Miragem ---
	var m = mirages[0]
	p.invuln_timer = 0
	p.hp = p.max_hp
	await place(m.global_position + Vector2(-120, 18))
	var m_start: float = m.global_position.x
	m.state = "idle"
	m.timer = 0.0
	guard = 0
	while m.state != "gone" and guard < 60:
		await wait(1)
		guard += 1
	check("Miragem some", m.state == "gone")
	guard = 0
	while m.state != "windup" and guard < 240:
		await wait(1)
		guard += 1
	check("Miragem some e reaparece perto", m.state == "windup" and m.global_position.x != m_start and absf(m.global_position.x - p.global_position.x) <= 100, "%s %.0f -> %.0f, Noct %.0f" % [m.state, m_start, m.global_position.x, p.global_position.x])
	var copies := of_script("enemy_mirage.gd").filter(func(e): return e.fake)
	check("duas cópias falsas", copies.size() == 2)
	check("cópia não machuca", copies.all(func(c): return c.get_damagebox().size == Vector2.ZERO))
	copies[0].take_hit(Vector2.RIGHT, 1)
	await wait(2)
	check("cópia some com um golpe", not is_instance_valid(copies[0]))
	m.take_hit(Vector2.RIGHT, 99)
	await wait(3)
	check("matar a verdadeira some com as cópias", of_script("enemy_mirage.gd").is_empty())

	print("== RESULTADO: %d OK, %d FALHOU ==" % [passed, failed.size()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	quit(0 if failed.is_empty() else 1)
