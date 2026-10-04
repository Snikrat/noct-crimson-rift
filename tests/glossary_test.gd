extends SceneTree
## Glossário de personagens na pausa (data/glossary.gd, game/ui/glossary_view.gd).
## Usa um save só do teste. Com -- --screenshots salva glossario_inicio e glossario_fim em docs/content-preview/.
## Uso: godot --headless --path . --script tests/glossary_test.gd

const Rooms := preload("res://data/rooms.gd")
const Memories := preload("res://data/memories.gd")

var main
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


func screenshot(name: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	main.hud.pause.queue_redraw()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	var dir := "res://docs/content-preview/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	root.get_texture().get_image().save_png(dir + name + ".png")


## Toda condição aponta para algo que existe no jogo.
func valid_condition(req: String) -> bool:
	if req == "":
		return true
	var kind := req.get_slice(":", 0)
	var id := req.get_slice(":", 1)
	match kind:
		"room": return Rooms.ROOMS.has(id)
		"boss": return id in gs().BOSSES
		"memory": return id in Memories.ORDER
		"memories": return int(id) >= 1 and int(id) <= Memories.ORDER.size()
		"flag": return id in gs().FLAGS
		"disc": return id in gs().DISCOVERIES
	return false


func _run() -> void:
	print("== GLOSSÁRIO ==")
	var Glossary = load("res://data/glossary.gd")   # depois dos autoloads
	var View = load("res://game/ui/glossary_view.gd")
	gs().save_path = "user://test_glossary_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	gs().reset()

	var bad := []
	for id in Glossary.ORDER:
		if not Glossary.ENTRIES.has(id):
			bad.append(id)
			continue
		if not valid_condition(Glossary.ENTRIES[id]["requires"]):
			bad.append(id + " requires")
		for part in Glossary.ENTRIES[id]["parts"]:
			if not valid_condition(part[0]):
				bad.append(id + " " + part[0])
	check("verbetes e condições apontam para coisas do jogo", bad.is_empty(), str(bad))
	check("nenhum verbete fora da ordem", Glossary.ENTRIES.size() == Glossary.ORDER.size())

	change_scene_to_file("res://game/world/main.tscn")
	await wait(20)
	main = current_scene
	while main.is_dialog_open():
		main.hud.dialog.close()
	await wait(2)

	# Começo do jogo: Noct, a Fenda e a gente da vila; Mira e os chefes ainda não.
	check("começo: Noct conhecido", View.is_known("noct"))
	check("começo: Zeno conhecido (vila)", View.is_known("zeno"))
	check("começo: Mira ainda não", not View.is_known("mira"))
	check("começo: Bringer ainda não", not View.is_known("bringer"))
	check("começo: Forma Demoníaca ainda não", not View.is_known("forma"))
	check("começo: Noct sem spoiler do Bringer", Glossary.text_of("noct").size() == 3)

	# Abre pela pausa: Continuar, Mapa, Memórias, Glossário.
	await tap("pause")
	for i in 3:
		await tap("down")
	await tap("attack")
	check("pausa abre o glossário", main.hud.pause.page == "glossary")
	await tap("down")
	check("cima/baixo troca de verbete", main.hud.pause.glossary_view.index == 1, str(main.hud.pause.glossary_view.index))
	await screenshot("glossario_inicio")

	# A história avança: verbetes e parágrafos novos aparecem.
	gs().memories["first_sarcasm"] = true
	gs().memories["the_seat"] = true
	gs().defeated_bosses["bringer"] = true
	gs().defeated_bosses["velario"] = true
	gs().visited["sanctum"] = true
	check("memória libera Mira", View.is_known("mira"))
	check("Mira ganha o parágrafo das raposas com a memória do banco",
		Glossary.text_of("mira").any(func(t): return "raposinha" in t))
	check("Mira sem a revelação antes do Demon Slime",
		not Glossary.text_of("mira").any(func(t): return "próprio corpo" in t))
	check("Velário libera a Forma Demoníaca", View.is_known("forma"))
	check("Bringer derrotado libera o parágrafo da mentira", Glossary.text_of("bringer").size() == 2)
	await wait(4)
	await screenshot("glossario_fim")

	# Texto longo vira páginas e esquerda/direita troca.
	gs().memories.clear()
	for id in Memories.ORDER:
		gs().memories[id] = true
	gs().defeated_bosses["demon_slime"] = true
	main.hud.pause.glossary_view.index = 1
	main.hud.pause.glossary_view.page = 0
	main.hud.pause.queue_redraw()
	await wait(4)
	var view = main.hud.pause.glossary_view
	check("Mira completa ocupa mais de uma página", view.pages > 1, str(view.pages))
	await tap("move_right")
	await wait(4)
	check("direita passa a página", view.page == 1)
	await tap("move_left")
	check("esquerda volta a página", view.page == 0)

	await tap("dash")
	check("voltar sai do glossário", main.hud.pause.page == "menu")
	await tap("dash")
	await wait(4)
	check("pausa fecha", not paused)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	print("== GLOSSÁRIO: %d OK, %d FALHOU ==" % [passed, failed.size()])
	quit(0 if failed.is_empty() else 1)
