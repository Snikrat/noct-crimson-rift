extends Node2D
## Inscrições e passagens: leitura acessível, segredos e atalhos persistentes.
var level
var title := "Inscrição"
var lines: Array = []
var target := ""
var entry := "L"
var discovery := ""
var requires := ""
var reward := 0
var portal := false
var phase := 0.0
var textures: Array[Texture2D] = []

func _ready() -> void:
	add_to_group("interactables")
	if portal:
		for name in ["portal1", "portal2"]:
			textures.append(load("res://assets/hero/vfx/" + name + ".png"))

func place_feet_at(feet: Vector2) -> void:
	position = feet

func can_interact(p: Node2D) -> bool:
	return absf(p.position.x - position.x) < 28 and absf(p.position.y + 20 - position.y) < 28

func prompt() -> String:
	return Controls.key_label("up") + ("  Atravessar" if target != "" else "  Examinar")

func interact() -> void:
	if requires != "" and not GameState.discoveries.has(requires):
		var clue := "O arquivo está preso ao selo. Derrote o Custódio para lê-lo." if requires == "evil_wizard" else "A fenda está adormecida. Uma marca na pedra aponta para o outro lado da serra."
		level.start_dialog(title, [clue, "@desconfiado: Abre por dentro. Claro."])
		return
	if discovery != "" and not GameState.discoveries.has(discovery):
		GameState.discoveries[discovery] = true
		if reward > 0:
			level.geo += reward
			level.player.gain_xp(preload("res://data/progression.gd").xp_for_geo(reward))
			Audio.play_sfx("absorb")
			level.hud.show_banner("Memória encontrada · +%d Geo" % reward)
	if target != "":
		level.use_passage(target, entry)
	else:
		level.start_dialog(title, lines)

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	var active := requires == "" or GameState.discoveries.has(requires)
	if portal:
		var tex := textures[int(phase * 5) % textures.size()]
		draw_texture_rect(tex, Rect2(-24, -52, 48, 48), false, Color(1, 0.75, 1, 0.95 if active else 0.25))
	else:
		var alpha := 0.35 + 0.25 * sin(phase * 3)
		draw_circle(Vector2(0, -34), 2, Color(1, 0.35, 0.6, alpha))
