extends SceneTree
## Integração da vila: colisão da rua, banco, moradores e ida/volta das passagens.
var main
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(label: String, ok: bool) -> void:
	print("OK " if ok else "FALHOU ", label)
	if not ok:
		failures += 1

func settle() -> void:
	for i in 5:
		await process_frame

func _run() -> void:
	await process_frame
	var gs = root.get_node("GameState")
	gs.save_path = "user://pedravelha_test.json"
	gs.reset()
	change_scene_to_file("res://game/world/main.tscn")
	await settle()
	main = current_scene
	main.hud.dialog.close()
	check("vila abre sem perder o jogador", main.room_name == "town" and main.player != null)
	for x in range(6, main.map_size.x):
		check("rua contínua %d" % x, main.solid.has(Vector2i(x, 16)))
	var benches := get_nodes_in_group("interactables").filter(func(n): return n.has_method("rest_here"))
	check("um único banco funcional na praça", benches.size() == 1)
	if benches.size() == 1:
		main.player.enter_room(benches[0].position)
		await settle()
		check("banco acessível na rua", benches[0].can_interact(main.player))
		benches[0].interact()
		check("descanso salva retorno em Pedravelha", gs.bench_room == "town")
		main.hud.dialog.close()
	for destination in ["tower", "well", "forest", "mountain", "mines"]:
		main.load_room("town", "B")
		await settle()
		main.hud.dialog.close()
		var passages := get_nodes_in_group("interactables").filter(func(n): return "target" in n and n.target == destination)
		check("passagem %s existe" % destination, passages.size() == 1)
		if passages.size() == 1:
			passages[0].interact()
			await create_timer(0.7).timeout
			main.hud.dialog.close()
			check("passagem leva a %s" % destination, main.room_name == destination)
		main.load_room("town", destination.to_upper())
		await settle()
		check("retorno %s em chão livre" % destination, not main.is_solid(main.player.position))
	if "--screenshots" in OS.get_cmdline_user_args():
		main.load_room("town", "B")
		await settle()
		main.hud.dialog.close()
		main.hud.banner_timer = 0
		for section in [["praca", 488], ["capela", 928], ["ferraria", 1176], ["torre", 232], ["escala", 728]]:
			main.player.enter_room(Vector2(section[1], 256))
			await create_timer(0.3).timeout
			await RenderingServer.frame_post_draw
			get_root().get_texture().get_image().save_png("res://docs/content-preview/pedravelha_" + section[0] + ".png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs.save_path))
	print("Pedravelha: %d falhas" % failures)
	main = null
	current_scene.queue_free()
	await settle()
	root.get_node("Audio").stop_all()
	await create_timer(0.1).timeout
	quit(1 if failures else 0)
