extends SceneTree
## Forma Demoníaca Nível 1 (game/player/demon_form.gd): barra da Fenda, transformação, vantagens,
## riscos (sem cura, ressaca) e cancelamento. Usa um save só do teste.
## Uso: godot --headless --path . --script tests/demon_form_test.gd
## Com janela e -- --screenshots salva recortes ampliados do Noct transformado em docs/content-preview/.

const SLASH_PATH := "res://game/player/crimson_slash.gd"
const ORB := preload("res://game/spells/spell_orb.gd")

var main
var p
var d
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
	while main.is_dialog_open():
		main.hud.dialog.close()
	await wait(2)


func tap(action: String, hold := 2) -> void:
	Input.action_press(action)
	await wait(hold)
	Input.action_release(action)
	await wait(2)


func transform_now() -> void:
	d.gauge = d.MAX_GAUGE
	await tap("transform")
	await wait(int(d.TRANSFORM_TIME * 60) + 6)


## Recorte do Noct ampliado 4x (só com -- --screenshots e com janela).
func shot(name: String) -> void:
	if not "--screenshots" in OS.get_cmdline_user_args():
		return
	main.hud.banner_timer = 0
	await RenderingServer.frame_post_draw
	var img: Image = root.get_texture().get_image()
	var sp: Vector2 = p.get_global_transform_with_canvas().origin
	var scale_k: float = img.get_width() / float(root.get_visible_rect().size.x)
	var r := Rect2i(Vector2i((sp + Vector2(-40, -42)) * scale_k), Vector2i(Vector2(80, 70) * scale_k))
	var crop := img.get_region(r)
	crop.resize(int(r.size.x * 4 / scale_k), int(r.size.y * 4 / scale_k), Image.INTERPOLATE_NEAREST)
	var dir := "res://docs/content-preview/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	crop.save_png(dir + name + ".png")


func _run() -> void:
	print("== FORMA DEMONÍACA ==")
	for action in InputMap.get_actions():
		Input.action_release(action)
		InputMap.action_erase_events(action)
	gs().save_path = "user://test_demon_save.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	gs().reset()
	change_scene_to_file("res://game/world/main.tscn")
	await wait(20)
	main = current_scene
	p = main.player
	d = p.demon
	await skip_dialogs()
	gs().seen_intros["town"] = true
	p.invuln_timer = 0
	await wait(30)

	# --- Bloqueada antes do Velário ---
	check("forma começa bloqueada", not d.unlocked())
	d.on_hit()
	d.on_hurt()
	check("barra não enche bloqueada", d.gauge == 0.0)
	d.gauge = d.MAX_GAUGE
	await tap("transform")
	await wait(4)
	check("tecla não transforma bloqueada", not d.active and d.transforming <= 0)
	d.gauge = 0.0

	# --- Barra ---
	p.unlocked["demon1"] = true
	check("habilidade demon1 libera", d.unlocked())
	d.on_hit()
	check("golpe enche 3", is_equal_approx(d.gauge, 3.0), str(d.gauge))
	d.on_hit(true)
	check("magia enche 6", is_equal_approx(d.gauge, 9.0), str(d.gauge))
	d.on_hurt()
	check("dano recebido enche 12", is_equal_approx(d.gauge, 21.0), str(d.gauge))
	await tap("transform")
	await wait(4)
	check("não transforma sem a barra cheia", not d.active and d.transforming <= 0)
	d.calm_timer = d.DECAY_AFTER + 1
	await wait(30)
	check("barra esvazia fora de combate", d.gauge < 21.0, str(d.gauge))

	# --- Transformação ---
	var bonus_before: int = p._melee_bonus()
	d.gauge = d.MAX_GAUGE
	await shot("demon_0_idle_normal")
	await tap("transform")
	check("transformação começa", d.transforming > 0)
	check("invulnerável transformando", p.invuln_timer > 0)
	await wait(int(d.TRANSFORM_TIME * 60) + 6)
	check("forma ativa", d.active)
	check("dano +1", p._melee_bonus() == bonus_before + 1, "%d -> %d" % [bonus_before, p._melee_bonus()])
	check("alma +50%", is_equal_approx(d.soul_mult(), 1.5))
	await wait(20)
	await shot("demon_1_idle")
	check("forma usa a arte carmesim oficial", p.crimson_level == 1 and d._has_art())
	Input.action_press("move_right")
	await wait(20)
	check("velocidade +15%", is_equal_approx(p.velocity.x, p.SPEED * 1.15), str(p.velocity.x))
	await shot("demon_2_run")
	Input.action_release("move_right")
	await wait(4)

	# Sem cura com a forma ativa.
	p.hp = 1
	p.soul = p.MAX_SOUL
	Input.action_press("spell")
	await wait(30)
	check("não cura com a forma ativa", not p.focusing and p.hp == 1)
	Input.action_release("spell")
	await wait(4)
	p.hp = p.max_hp

	# Corte carmesim no finalizador.
	var before: int = main.world.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == SLASH_PATH).size()
	d.on_move_started("finisher")
	var after: int = main.world.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == SLASH_PATH).size()
	check("finalizador solta o corte carmesim", after == before + 1)
	d.on_move_started("punch")
	check("jab não solta corte", main.world.get_children().filter(func(n): return n.get_script() != null and n.get_script().resource_path == SLASH_PATH).size() == after)

	# Magia: bola de energia nas formas 1 e 2, Raposa Espectral na forma 3.
	p.soul = p.MAX_SOUL
	p._release_orb()
	var orbs: Array = main.world.get_children().filter(func(n): return n.get_script() == ORB)
	check("forma 1 solta a bola de energia", orbs.size() > 0 and not orbs[-1].fox)
	p.crimson_level = 3
	p.soul = p.MAX_SOUL
	p._release_orb()
	await wait(2)
	orbs = main.world.get_children().filter(func(n): return n.get_script() == ORB)
	var fox = orbs[-1] if orbs.size() > 0 else null
	check("forma 3 solta a Raposa Espectral", fox != null and fox.fox)
	if fox:
		var sf: SpriteFrames = fox.sprite.sprite_frames
		check("raposa: 8 quadros (surge, voa, se desfaz)",
			sf.get_frame_count("grow") + sf.get_frame_count("fly") + sf.get_frame_count("burst") == 8)
		check("raposa: quadro maior que a bola", sf.get_frame_texture("fly", 0).get_size().x > 60)
	p.crimson_level = 1
	await wait(40)

	# Pulo e golpe, para conferir o chifre em outras poses.
	await tap("jump", 6)
	await wait(8)
	await shot("demon_3_jump")
	await wait(40)
	await tap("attack")
	await wait(3)
	await shot("demon_4_jab")
	await wait(30)

	# Inimigo morto durante a forma devolve tempo.
	d.gauge = 50.0
	d.on_kill()
	check("matar devolve 1,5 s", is_equal_approx(d.gauge, 50.0 + d.KILL_BONUS * d.MAX_GAUGE / d.DURATION), str(d.gauge))

	# --- Fim natural: ressaca ---
	d.gauge = 1.0
	await wait(10)
	check("forma termina sozinha", not d.active)
	check("ressaca depois do fim", d.hangover > 0)
	check("ressaca: mais devagar", is_equal_approx(d.speed_mult(), 0.75))
	check("ressaca: sem alma", d.soul_mult() == 0.0)
	d.on_hit()
	check("barra não enche na ressaca", d.gauge == 0.0)
	await shot("demon_5_ressaca")
	await wait(int(d.HANGOVER_TIME * 60) + 6)
	check("ressaca acaba", d.hangover <= 0 and is_equal_approx(d.speed_mult(), 1.0))

	# --- Cancelar com mais da metade: sem ressaca ---
	await transform_now()
	check("transformou de novo", d.active)
	await tap("transform")
	check("cancelar desliga", not d.active)
	check("cancelar cedo não dá ressaca", d.hangover <= 0)

	# --- Troca de sala mantém a forma (inclusive durante a fala de chegada) ---
	await transform_now()
	gs().seen_intros.erase("swamp")
	main.load_room("swamp", "L")
	await wait(6)
	check("sala nova abre a fala de chegada", main.is_dialog_open())
	check("trocar de sala mantém a forma", d.active and p.crimson_level == 1)
	check("na fala de chegada o Noct segue transformado", String(p.sprite.animation).begins_with("c1_"), p.sprite.animation)
	await skip_dialogs()
	await wait(4)
	check("depois da fala segue transformado", d.active and String(p.sprite.animation).begins_with("c1_"), p.sprite.animation)
	await tap("transform")
	check("cancelar depois da troca de sala desliga", not d.active and p.crimson_level == 0)

	# --- Forma carmesim de teste (F3) também atravessa a sala ---
	p.crimson_level = 2
	await wait(4)
	main.load_room("town", "R")
	await wait(4)
	await skip_dialogs()
	check("forma carmesim 2 atravessa a sala", p.crimson_level == 2 and String(p.sprite.animation).begins_with("c2_"), p.sprite.animation)
	p.crimson_level = 0

	print("== RESULTADO: %d OK, %d FALHOU ==" % [passed, failed.size()])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(gs().save_path))
	quit(0 if failed.is_empty() else 1)
