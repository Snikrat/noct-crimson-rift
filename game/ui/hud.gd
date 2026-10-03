extends CanvasLayer
## Interface por cima do jogo: alma, vida, Geo, nível, avisos (área, nível, interação),
## barra do chefe, clarão e escurecimento de transição. Também contém o diálogo, a loja e a pausa.

const DialogScript := preload("res://game/ui/dialog_box.gd")
const ShopScript := preload("res://game/ui/shop.gd")
const PauseScript := preload("res://game/ui/pause.gd")
const CharmsScript := preload("res://game/ui/charms.gd")
const GOLD := Color("e8c872")
const Paths := preload("res://data/asset_paths.gd")
const EMBLEM_SIZE := 46.0           # emblema carmesim em volta do vaso de alma
const EMBLEM_CORE := 0.18           # raio do centro escuro do emblema (fração do tamanho)
const SAVE_ICON_TIME := 2.2

var level
var canvas: Control           # onde o HUD é desenhado
var dialog: Control
var shop: Control
var pause: Control
var charms: Control
var fade: ColorRect
var flash: ColorRect

var banner_text := ""
var banner_timer := 0.0
var levelup_timer := 0.0
var levelup_level := 0
var levelup_reward := {}
var cutin_face := ""          # rosto grande que cruza a tela (Ultimate, morte)
var cutin_timer := 0.0
var cutin_total := 1.0
var cutin_color := Color.WHITE
var emblem: Texture2D
var saved_timer := 0.0        # ícone "jogo salvo" girando no canto
var t := 0.0


func _ready() -> void:
	layer = 5
	emblem = load(Paths.EMBLEM)
	canvas = _full_rect(Control.new())
	# O emblema é arte reduzida: filtro suave para não serrilhar.
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	canvas.draw.connect(_draw_hud)
	dialog = _full_rect(DialogScript.new())
	dialog.level = level
	shop = _full_rect(ShopScript.new())
	shop.level = level
	fade = _full_rect(ColorRect.new())
	fade.color = Color(0, 0, 0, 0)
	flash = _full_rect(ColorRect.new())
	flash.color = Color(1, 1, 1, 0)
	pause = PauseScript.new()
	pause.level = level
	add_child(pause)
	charms = _full_rect(CharmsScript.new())
	charms.level = level


func _full_rect(c: Control) -> Control:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


func _process(delta: float) -> void:
	banner_timer = maxf(banner_timer - delta, 0)
	levelup_timer = maxf(levelup_timer - delta, 0)
	cutin_timer = maxf(cutin_timer - delta, 0)
	saved_timer = maxf(saved_timer - delta, 0)
	t += delta
	canvas.queue_redraw()


func refresh() -> void:
	canvas.queue_redraw()


## Nome da área (ou outro aviso curto) no alto da tela.
func show_banner(text: String, duration := 2.5) -> void:
	banner_text = text
	banner_timer = duration


func show_level_up(new_level: int, reward: Dictionary) -> void:
	levelup_level = new_level
	levelup_reward = reward
	levelup_timer = 4.5


## Cut-in: o rosto de Noct entra pela lateral numa faixa colorida (estilo jogo de luta).
func show_cutin(face: String, duration := 1.2, color := Color(1, 0.2, 0.45)) -> void:
	cutin_face = face
	cutin_total = duration
	cutin_timer = duration
	cutin_color = color


## Emblema girando no canto com "Jogo salvo" (ao descansar no banco).
func show_saved() -> void:
	saved_timer = SAVE_ICON_TIME


## Clarão colorido na tela inteira que some aos poucos.
func flash_screen(color: Color, duration: float) -> void:
	flash.color = Color(color, 0.55)
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(flash, "color:a", 0.0, duration)


## Escurece (alpha 1) ou clareia (alpha 0) a tela; usado nas trocas de sala.
func fade_to(alpha: float, duration: float) -> Tween:
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)   # continua se um diálogo pausar o jogo no meio da troca de sala
	tw.tween_property(fade, "color:a", alpha, duration)
	return tw


func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	var player = level.player
	var c := canvas

	# Vaso de alma: o emblema carmesim acende conforme a alma; o centro da fenda enche de baixo para cima.
	var vc := Vector2(26, 25)
	var fill: float = clampf(player.soul / float(player.MAX_SOUL), 0, 1)
	var full: bool = player.soul >= player.SPELL_COST
	var glow := lerpf(0.4, 1.0, fill) + (0.15 * sin(t * 6.0) if full else 0.0)
	c.draw_texture_rect(emblem, Rect2(vc - Vector2.ONE * EMBLEM_SIZE / 2, Vector2.ONE * EMBLEM_SIZE), false,
		Color(glow, glow * 0.9, glow * 0.95))
	var r := EMBLEM_SIZE * EMBLEM_CORE
	c.draw_circle(vc, r, Color(0.05, 0, 0.02, 0.75))
	if fill > 0:
		var line_y := vc.y + r - fill * r * 2
		var pts := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			var p := vc + Vector2(cos(a), sin(a)) * (r - 0.5)
			pts.append(Vector2(p.x, maxf(p.y, line_y + sin(t * 4.0 + p.x) * 0.6)))
		c.draw_colored_polygon(pts, Color(0.78, 0.05, 0.18, 0.95))
		# Superfície da alma: linha clara que ondula.
		var half := sqrt(maxf(r * r - pow(line_y - vc.y, 2), 0.0))
		if half > 1:
			c.draw_line(Vector2(vc.x - half + 0.5, line_y), Vector2(vc.x + half - 0.5, line_y), Color(1, 0.55, 0.65, 0.9), 1.0)
	if full:
		# Alma suficiente para magia: a fenda no centro brilha.
		var k := 0.6 + 0.4 * sin(t * 6.0)
		c.draw_line(vc + Vector2(0, -r + 1), vc + Vector2(0, r - 1), Color(1, 0.9, 0.95, k), 1.2)
		c.draw_circle(vc, 1.6, Color(1, 1, 1, k))
	# Máscaras de vida.
	for i in player.max_hp:
		var m := Vector2(54 + i * 13, 15)
		if i < player.hp:
			c.draw_circle(m, 5, Color.WHITE)
			c.draw_circle(m + Vector2(-1.5, 0), 1, Color.BLACK)
			c.draw_circle(m + Vector2(1.5, 0), 1, Color.BLACK)
		else:
			c.draw_arc(m, 5, 0, TAU, 16, Color(1, 1, 1, 0.3), 1.0)
	c.draw_string(font, Vector2(50, 34), "Geo %d" % GameState.geo, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)

	# Nível e barra de XP.
	c.draw_string(font, Vector2(8, 60), "Nv %d" % player.lvl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, GOLD)
	var bar := Rect2(34, 54, 60, 4)
	c.draw_rect(bar.grow(1), Color(0, 0, 0, 0.6))
	c.draw_rect(Rect2(bar.position, Vector2(bar.size.x * player.xp_progress(), bar.size.y)), Color(1, 0.3, 0.6))

	_draw_level_up(font)
	_draw_cutin()
	_draw_saved(font)

	# Nome da área ao entrar.
	if banner_timer > 0:
		var a := clampf(banner_timer, 0, 1)
		c.draw_string(font, Vector2(0, 60), banner_text, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 16, Color(1, 1, 1, a))
		c.draw_line(Vector2(c.size.x / 2 - 60, 66), Vector2(c.size.x / 2 + 60, 66), Color(1, 1, 1, a * 0.5))

	# Aviso de interação acima do herói.
	if level.interactable and not dialog.is_open() and not level.transitioning:
		var sp: Vector2 = player.get_global_transform_with_canvas().origin
		c.draw_string(font, sp + Vector2(-40, -34), level.interactable.prompt(), HORIZONTAL_ALIGNMENT_CENTER, 80, 9, GOLD)

	var boss = level.boss
	var boss_fight: bool = is_instance_valid(boss) and boss.is_awake()
	if boss_fight:
		_draw_boss_bar(font, boss)
	elif not shop.is_open() and not dialog.is_open():
		c.draw_string(font, Vector2(8, c.size.y - 6),
			"%s atacar   %s dash   %s magia (segure: curar)   %s falar/descansar" % [
				Controls.key_label("attack"), Controls.key_label("dash"),
				Controls.key_label("spell"), Controls.key_label("up")],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.4))


func _draw_saved(font: Font) -> void:
	if saved_timer <= 0:
		return
	var c := canvas
	var a := clampf(minf(saved_timer, SAVE_ICON_TIME - saved_timer) * 4.0, 0, 1)
	var center := Vector2(c.size.x - 22, 22)
	var s := 28.0
	c.draw_set_transform(center, t * 2.5, Vector2.ONE)
	c.draw_texture_rect(emblem, Rect2(-Vector2.ONE * s / 2, Vector2.ONE * s), false, Color(1, 1, 1, a))
	c.draw_set_transform(Vector2.ZERO)
	c.draw_string_outline(font, Vector2(0, 26), "Jogo salvo", HORIZONTAL_ALIGNMENT_RIGHT, c.size.x - 40, 9, 3, Color(0, 0, 0, a * 0.8))
	c.draw_string(font, Vector2(0, 26), "Jogo salvo", HORIZONTAL_ALIGNMENT_RIGHT, c.size.x - 40, 9, Color(1, 0.6, 0.7, a))


## Aviso de subida de nível.
func _draw_level_up(font: Font) -> void:
	if levelup_timer <= 0:
		return
	var c := canvas
	var a := clampf(levelup_timer, 0, 1)
	var title := "NÍVEL %d!" % levelup_level
	c.draw_string_outline(font, Vector2(0, 96), title, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 20, 5, Color(0, 0, 0, a * 0.8))
	c.draw_string(font, Vector2(0, 96), title, HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 20, Color(1, 0.55, 0.75, a))
	# Rosto de Noct com aura ao lado do aviso.
	var face: Texture2D = dialog.portrait("magia_aura")
	c.draw_texture_rect(face, Rect2(c.size.x / 2 - 118, 66, 40, 40), false, Color(1, 1, 1, a))
	if levelup_reward.has("title"):
		c.draw_string_outline(font, Vector2(0, 114), levelup_reward["title"], HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 11, 4, Color(0, 0, 0, a * 0.8))
		c.draw_string(font, Vector2(0, 114), levelup_reward["title"], HORIZONTAL_ALIGNMENT_CENTER, c.size.x, 11, Color(GOLD, a))
		c.draw_string_outline(font, Vector2(60, 128), levelup_reward["text"], HORIZONTAL_ALIGNMENT_CENTER, c.size.x - 120, 9, 3, Color(0, 0, 0, a * 0.8))
		c.draw_string(font, Vector2(60, 128), levelup_reward["text"], HORIZONTAL_ALIGNMENT_CENTER, c.size.x - 120, 9, Color(1, 1, 1, a))


## Faixa diagonal com o rosto grande entrando pela esquerda, parando e saindo.
func _draw_cutin() -> void:
	if cutin_timer <= 0:
		return
	var c := canvas
	var k := 1.0 - cutin_timer / cutin_total     # 0 -> 1 ao longo do cut-in
	var a := clampf(minf(k, 1.0 - k) * 6.0, 0, 1)   # entra e sai suave
	var slide := clampf(k * 5.0, 0, 1)
	var band_y := 72.0
	var band_h := 112.0
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(0, band_y + 10), Vector2(c.size.x, band_y - 10),
		Vector2(c.size.x, band_y + band_h - 10), Vector2(0, band_y + band_h + 10),
	]), Color(cutin_color.r * 0.25, cutin_color.g * 0.1, cutin_color.b * 0.2, 0.75 * a))
	c.draw_line(Vector2(0, band_y + 10), Vector2(c.size.x, band_y - 10), Color(cutin_color, a), 2)
	c.draw_line(Vector2(0, band_y + band_h + 10), Vector2(c.size.x, band_y + band_h - 10), Color(cutin_color, a), 2)
	var size := 128.0
	var x := lerpf(-size, 70.0, slide) + k * 20.0
	c.draw_texture_rect(dialog.portrait(cutin_face), Rect2(x, band_y - 8, size, size), false, Color(1, 1, 1, a))


func _draw_boss_bar(font: Font, boss: Node) -> void:
	var c := canvas
	var w := 240.0
	var bar := Rect2((c.size.x - w) / 2, c.size.y - 20, w, 6)
	c.draw_string(font, bar.position + Vector2(0, -4), boss.BOSS_NAME, HORIZONTAL_ALIGNMENT_CENTER, w, 9, Color(1, 1, 1, 0.85))
	c.draw_rect(bar.grow(1), Color(0, 0, 0, 0.7))
	var k := clampf(boss.hp / float(boss.MAX_HP), 0, 1)
	c.draw_rect(Rect2(bar.position, Vector2(w * k, bar.size.y)), Color("c0303a"))
	c.draw_rect(bar.grow(1), Color(1, 1, 1, 0.4), false, 1)
