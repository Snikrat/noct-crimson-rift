extends Node2D
## Inscrições e passagens: leitura acessível, segredos e atalhos persistentes.
var level
var title := "Inscrição"
var lines: Array = []
var target := ""
var entry := "L"
var discovery := ""
var requires := ""            # descoberta, "memory:<id>" ou "boss:<id>" (main.requirement_met)
var locked_lines: Array = []  # falas enquanto o requisito não foi cumprido (opcional)
var reveals := false          # luneta da torre: marca a região no mapa da pausa
var reward := 0
var portal := false            # fenda carmesim: só nas passagens ligadas à Fenda
var style := ""               # passagem natural: "door", "trail", "mine", "rope" ou "well" (sem desenho, usa o cenário)
var facing := 1               # placa de trilha: 1 aponta para a direita, -1 para a esquerda
var phase := 0.0
const PORTAL_SHEET := preload("res://assets/hero/vfx/portal_sheet.png")
const PORTAL_FRAMES := 6
const PORTAL_SIZE := Vector2(40, 56)
const PASSAGE_TEXTURES := {
	"door": preload("res://assets/world/passages/door.png"),
	"trail": preload("res://assets/world/passages/trail_sign.png"),
	"mine": preload("res://assets/world/passages/mine.png"),
	"rope": preload("res://assets/world/passages/rope.png"),
}
const Fx := preload("res://game/core/fx.gd")
var glow: Sprite2D

func _ready() -> void:
	add_to_group("interactables")
	if style != "":
		z_index = -1   # porta, placa e mina fazem parte do cenário, atrás do herói
	if portal:
		# Halo radial (redondo) atrás da fenda; a textura do portal tem bordas transparentes.
		glow = Fx.glow(Color(1, 0.12, 0.35), 34, 0.45)
		glow.position = Vector2(0, -30)
		glow.z_index = 0
		glow.show_behind_parent = true
		add_child(glow)

func place_feet_at(feet: Vector2) -> void:
	position = feet

func can_interact(p: Node2D) -> bool:
	return absf(p.position.x - position.x) < 28 and absf(p.position.y + 20 - position.y) < 28

func prompt() -> String:
	return Controls.key_label("up") + ("  Atravessar" if target != "" else "  Examinar")

func interact() -> void:
	if requires != "" and not level.requirement_met(requires):
		if not locked_lines.is_empty():
			level.start_dialog(title, locked_lines)
			return
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
	if reveals:
		level.reveal_region()
	if target != "":
		level.use_passage(target, entry)
	else:
		level.start_dialog(title, lines)

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _draw() -> void:
	var active: bool = requires == "" or level.requirement_met(requires)
	if portal:
		var frame := int(phase * 8) % PORTAL_FRAMES
		var src := Rect2(Vector2(frame * PORTAL_SIZE.x, 0), PORTAL_SIZE)
		draw_texture_rect_region(PORTAL_SHEET, Rect2(Vector2(-20, -58), PORTAL_SIZE), src, Color(1, 1, 1, 1.0 if active else 0.3))
		if glow:
			glow.visible = active
	elif style != "":
		if PASSAGE_TEXTURES.has(style):
			var tex: Texture2D = PASSAGE_TEXTURES[style]
			var size := tex.get_size()
			var tint := Color.WHITE if active else Color(0.6, 0.6, 0.65)
			draw_texture_rect(tex, Rect2(Vector2(-size.x / 2.0 * facing, -size.y), Vector2(size.x * facing, size.y)), false, tint)
	else:
		var alpha := 0.35 + 0.25 * sin(phase * 3)
		draw_circle(Vector2(0, -34), 2, Color(1, 0.35, 0.6, alpha))
