extends CanvasLayer
## Interface por cima do jogo: barras de vida/magia (alma)/XP, Geo, nível, avisos (área, nível, interação),
## barra do chefe, clarão e escurecimento de transição. Também contém o diálogo, a loja e a pausa.

const DialogScript := preload("res://game/ui/dialog_box.gd")
const ShopScript := preload("res://game/ui/shop.gd")
const PauseScript := preload("res://game/ui/pause.gd")
const CharmsScript := preload("res://game/ui/charms.gd")
const GOLD := Color("e8c872")
const Paths := preload("res://data/asset_paths.gd")
const SAVE_ICON_TIME := 2.2
const BARS_POS := Vector2(6, 3)       # canto da primeira barra (vida); magia e XP vêm embaixo
const BAR_STEP := 12.0                # distância entre as barras
const FILL_OFFSET := Vector2(13, 5)   # onde o preenchimento começa dentro da moldura (tools/make_hud_ui.gd)

var level
var canvas: Control           # onde o HUD é desenhado (pixel art nítida)
var soft: Control             # embaixo do canvas, com filtro suave: o emblema de "jogo salvo"
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
var bars := {}                # "vida"/"magia"/"xp" -> [moldura, preenchimento]
var fill_width := 0.0         # largura do preenchimento das barras
var saved_timer := 0.0        # ícone "jogo salvo" girando no canto
var t := 0.0


func _ready() -> void:
	layer = 5
	emblem = load(Paths.EMBLEM)
	for kind in ["vida", "magia", "xp"]:
		bars[kind] = [load(Paths.HUD_BARS + "barra_%s_moldura.png" % kind), load(Paths.HUD_BARS + "barra_%s_preenchimento.png" % kind)]
	fill_width = bars["vida"][1].get_width()
	# O emblema de "jogo salvo" é arte reduzida: filtro suave para não serrilhar. O resto (barras, texto) fica nítido.
	soft = _full_rect(Control.new())
	soft.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	soft.draw.connect(_draw_soft)
	canvas = _full_rect(Control.new())
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
	soft.queue_redraw()
	canvas.queue_redraw()


func refresh() -> void:
	soft.queue_redraw()
	canvas.queue_redraw()


## Nome da área (ou outro aviso curto) no alto da tela.
func show_banner(text: String, duration := 2.5) -> void:
	banner_text = text
	banner_timer = duration
	refresh()   # a sala pode abrir com uma fala (jogo pausado): mostra o nome novo mesmo assim


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


## Camada suave: o emblema girando de "jogo salvo" (arte reduzida, filtro suave).
func _draw_soft() -> void:
	var c := soft
	if saved_timer > 0:
		var a := clampf(minf(saved_timer, SAVE_ICON_TIME - saved_timer) * 4.0, 0, 1)
		var s := 28.0
		c.draw_set_transform(Vector2(c.size.x - 22, 22), t * 2.5, Vector2.ONE)
		c.draw_texture_rect(emblem, Rect2(-Vector2.ONE * s / 2, Vector2.ONE * s), false, Color(1, 1, 1, a))
		c.draw_set_transform(Vector2.ZERO)


func _draw_hud() -> void:
	var font := ThemeDB.fallback_font
	var player = level.player
	var c := canvas

	var fill: float = clampf(player.soul / float(player.MAX_SOUL), 0, 1)
	# Barras de vida, magia (alma) e nível (XP).
	var x := BARS_POS.x
	_draw_bar("vida", Vector2(x, BARS_POS.y), player.hp / float(player.max_hp))
	_draw_bar("magia", Vector2(x, BARS_POS.y + BAR_STEP), fill)
	# Marcas de cada magia que a alma já paga.
	for i in range(1, ceili(player.MAX_SOUL / float(player.SPELL_COST))):
		var mx: float = x + FILL_OFFSET.x + roundf(fill_width * player.SPELL_COST * i / float(player.MAX_SOUL))
		c.draw_line(Vector2(mx, BARS_POS.y + BAR_STEP + FILL_OFFSET.y), Vector2(mx, BARS_POS.y + BAR_STEP + FILL_OFFSET.y + 5),
			Color("0d020e", 0.7), 1.0)
	_draw_bar("xp", Vector2(x, BARS_POS.y + BAR_STEP * 2), player.xp_progress())
	var text_x: float = x + bars["xp"][0].get_width() + 3
	c.draw_string(font, Vector2(text_x, BARS_POS.y + BAR_STEP * 2 + 10), "Nv %d" % player.lvl, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, GOLD)
	c.draw_string(font, Vector2(text_x, BARS_POS.y + 10), "%d/%d" % [player.hp, player.max_hp], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.75))
	c.draw_string(font, Vector2(x + 2, BARS_POS.y + BAR_STEP * 3 + 10), "Geo %d" % GameState.geo, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)

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


## Barra do HUD: moldura com o interior vazio e, por cima, o preenchimento recortado até "k" (0..1).
func _draw_bar(kind: String, pos: Vector2, k: float) -> void:
	var frame: Texture2D = bars[kind][0]
	var fill_tex: Texture2D = bars[kind][1]
	canvas.draw_texture(frame, pos)
	var w := roundf(fill_tex.get_width() * clampf(k, 0, 1))
	if w > 0:
		canvas.draw_texture_rect_region(fill_tex, Rect2(pos + FILL_OFFSET, Vector2(w, fill_tex.get_height())),
			Rect2(0, 0, w, fill_tex.get_height()))


func _draw_saved(font: Font) -> void:
	if saved_timer <= 0:
		return
	var c := canvas
	var a := clampf(minf(saved_timer, SAVE_ICON_TIME - saved_timer) * 4.0, 0, 1)
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
