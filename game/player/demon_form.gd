extends Node2D
## Forma Demoníaca (docs/expansao_forma_demoniaca.md, seção 5). Filho do herói (player.gd).
## Barra da Fenda: enche ao acertar e ao apanhar; cheia, a tecla da forma (R / R3) transforma.
## Nível 1, Juramento: +1 de dano, +15% de velocidade, dash carmesim que fere, corte carmesim
## no fim dos combos e +50% de alma. Sem cura enquanto ativa e uma ressaca quando acaba.
## Visual: a Forma Demoníaca oficial é a arte carmesim do Noct (cN_*, em assets/hero/crimson/, da
## remodelagem do personagem). Com ela no jogo, este script não desenha nada por cima do Noct: só a
## explosão da transformação e o brilho. A camada provisória (chamas, chifre de aura, olhos e tom) só
## aparece se a arte carmesim do nível não existir.
## O nível que existe no jogo vem da habilidade "demon1" (liberada ao derrotar o Velário).

const Fx := preload("res://game/core/fx.gd")
const SlashScript := preload("res://game/player/crimson_slash.gd")

const MAX_GAUGE := 100.0
const GAIN_HIT := 3.0          # por golpe que acerta
const GAIN_SPELL := 6.0        # por magia que acerta
const GAIN_HURT := 12.0        # por dano recebido
const DURATION := 12.0         # segundos com a barra cheia
const KILL_BONUS := 1.5        # segundos devolvidos por inimigo morto durante a forma
const DECAY_AFTER := 6.0       # sem lutar por isso, a barra começa a esvaziar
const DECAY_RATE := 2.0        # por segundo
const TRANSFORM_TIME := 0.6
const HANGOVER_TIME := 2.5
const SHOCK_RADIUS := 70.0
const SHOCK_DAMAGE := 2
const SLASH_MOVES := ["finisher", "air_finish"]
# Por nível: [dano extra, velocidade, alma]. Só o nível 1 é liberado por enquanto.
const LEVELS := {1: {"name": "Juramento", "damage": 1, "speed": 1.15, "soul": 1.5}}
# Falas ao transformar (rodízio). As primeiras são contidas; ver docs/noct_personalidade.md.
const LINES := ["@magia_olhos: Lembrando de você, então.", "@em_combate: Hm.", "@magia_aura: Fica quieto. Eu controlo.",
	"@sorrindo: Finalmente.", "@maligno: Então engole."]

const DEEP := Color("6e0d2a")
const MID := Color("d9264f")
const HOT := Color("ff6f96")
const WHITE_HOT := Color("ffd0dd")
# Chifre de aura olhando para a direita: base embaixo à direita, curva para trás e para cima.
# o = borda clara, x = corpo, d = contorno escuro.
const HORN := [
	"o.......",
	"do......",
	"dxo.....",
	".dxo....",
	".dxxo...",
	"..dxxo..",
	"..dxxxo.",
	"...dxxxo",
]

var player: CharacterBody2D
var level
var gauge := 0.0
var active := false
var transforming := 0.0
var hangover := 0.0
var calm_timer := 0.0          # segundos desde o último golpe/dano
var uses := 0
var flames := []               # [pos, vel, vida, vida_total, tamanho]
var flame_timer := 0.0
var back: Node2D               # aura atrás do sprite
var glow: Sprite2D
var head_cache := {}           # "anim:quadro" -> [topo da cabeça, olho] em px da textura
var hit_by_dash := []


func _ready() -> void:
	z_index = 1
	back = Node2D.new()
	back.z_index = -1
	back.show_behind_parent = true
	back.draw.connect(_draw_back)
	add_child(back)
	glow = Fx.glow(Color(1, 0.12, 0.3), 26, 0.0)
	glow.z_index = -1
	add_child(glow)


# --- Regras ------------------------------------------------------------

func level_number() -> int:
	return 1 if player.has("demon1") else 0


func unlocked() -> bool:
	return level_number() > 0


func full() -> bool:
	return gauge >= MAX_GAUGE


func damage_bonus() -> int:
	return LEVELS[1]["damage"] if active else 0


func speed_mult() -> float:
	if active:
		return LEVELS[1]["speed"]
	return 0.75 if hangover > 0 else 1.0


func soul_mult() -> float:
	if hangover > 0:
		return 0.0
	return LEVELS[1]["soul"] if active else 1.0


## Ativa e na ressaca o Noct não consegue se acalmar para curar.
func can_heal() -> bool:
	return not active and transforming <= 0


func _can_fill() -> bool:
	return unlocked() and not active and hangover <= 0 and transforming <= 0


func on_hit(spell := false) -> void:
	calm_timer = 0.0
	if _can_fill():
		gauge = minf(gauge + (GAIN_SPELL if spell else GAIN_HIT), MAX_GAUGE)


func on_hurt() -> void:
	calm_timer = 0.0
	if _can_fill():
		gauge = minf(gauge + GAIN_HURT, MAX_GAUGE)


func on_kill() -> void:
	if active:
		gauge = minf(gauge + KILL_BONUS * MAX_GAUGE / DURATION, MAX_GAUGE)


## Golpes que soltam a lâmina carmesim (fim do combo no chão e no ar).
func on_move_started(move_name: String) -> void:
	if not active or not (move_name in SLASH_MOVES or move_name.begins_with("finisher_")):
		return
	var s := SlashScript.new()
	s.level = level
	s.dir = player.facing
	s.position = player.global_position + Vector2(player.facing * 18, -4)
	level.add_to_world(s)


func reset() -> void:
	if active:
		player.crimson_level = 0
	active = false
	transforming = 0.0
	hangover = 0.0
	flames.clear()
	player.sprite.self_modulate = Color.WHITE


## Tecla da forma: transforma (barra cheia) ou cancela.
func try_toggle() -> bool:
	if active:
		_end(gauge >= MAX_GAUGE * 0.5)
		return true
	if not unlocked() or not full() or transforming > 0 or player.hurt_timer > 0 or player.death_timer > 0:
		if unlocked() and not full():
			Audio.play_sfx("back", 0.0, 0.8)
		return false
	_start()
	return true


func _start() -> void:
	transforming = TRANSFORM_TIME
	uses += 1
	player.invuln_timer = maxf(player.invuln_timer, TRANSFORM_TIME + 0.1)
	player.focusing = false
	player.sprite.play("crouch")
	Audio.play_sfx("charge", 0.0, 0.7)
	level.flash_screen(Color(0.6, 0.02, 0.15), 0.3)
	if uses == 1 or randf() < 0.3:
		var i := 0 if uses == 1 else randi_range(1, LINES.size() - 1 if uses > 6 else LINES.size() - 3)
		level.say(player, "", LINES[i], 2.2)


func _burst() -> void:
	active = true
	gauge = MAX_GAUGE
	player.crimson_level = level_number()
	level.shake(6.0)
	level.flash_screen(Color(0.9, 0.1, 0.25), 0.45)
	Audio.play_sfx("thunder", 0.0, 0.8)
	level.spawn_crimson("shockwave", player.global_position + Vector2(0, 20), player.facing, 0.5)
	level.spawn_crimson("impact", player.global_position + Vector2(0, 10), player.facing, 0.4)
	level.hud.show_banner("FORMA DEMONÍACA · NÍVEL 1: " + LEVELS[1]["name"].to_upper(), 1.8)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.global_position.distance_to(player.global_position) < SHOCK_RADIUS and e.has_method("take_hit"):
			var d := Vector2(signf(e.global_position.x - player.global_position.x), 0)
			e.take_hit(d if d.x != 0 else Vector2.RIGHT, SHOCK_DAMAGE)
			if "knock" in e:
				e.knock = d.x * 300
	for i in 24:
		_spawn_flame(true)


func _end(clean: bool) -> void:
	active = false
	player.crimson_level = 0
	gauge = 0.0
	hangover = 0.0 if clean else HANGOVER_TIME
	player.sprite.self_modulate = Color.WHITE
	Audio.play_sfx("unequip", 0.0, 0.7)
	Fx.sparks(level.world, player.global_position, HOT, 14, 90, -40)


## Dash carmesim: fere (1) quem o Noct atravessa, uma vez por dash.
func dash_tick(dash_started: bool) -> void:
	if dash_started:
		hit_by_dash.clear()
	if not active:
		return
	# Cristais carmesim do Coração da Fenda quebram com o dash da forma.
	var front := Rect2(player.global_position + Vector2(player.facing * 8 - 4, -18), Vector2(16, 36))
	if player.facing < 0:
		front.position.x -= 8
	for c in get_tree().get_nodes_in_group("rift_crystals"):
		if front.intersects(Rect2(c.global_position, Vector2(16, 16))):
			c.shatter()
	var box := Rect2(player.global_position - Vector2(16, 20), Vector2(32, 40))
	for e in get_tree().get_nodes_in_group("enemies"):
		if e in hit_by_dash or not box.intersects(e.get_hurtbox()):
			continue
		hit_by_dash.append(e)
		e.take_hit(Vector2(player.facing, 0), 1 + player._melee_bonus())
		Fx.sparks(level.world, e.global_position, HOT, 10, 120)
		Audio.play_sfx("impact", 0.12, 1.2)


# --- Ciclo -------------------------------------------------------------

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	calm_timer += delta
	if transforming > 0:
		transforming -= delta
		if randf() < 0.6:
			_spawn_flame(true)
		if transforming <= 0:
			_burst()
	elif active:
		gauge -= MAX_GAUGE / DURATION * delta
		if gauge <= 0:
			_end(false)
	elif hangover > 0:
		hangover -= delta
	elif calm_timer > DECAY_AFTER and gauge > 0 and gauge < MAX_GAUGE:
		gauge = maxf(gauge - DECAY_RATE * delta, 0)

	if active:
		if not _has_art():
			player.sprite.self_modulate = Color(1.0, 0.93, 0.95)
		flame_timer -= delta
		while flame_timer <= 0:
			flame_timer += 0.035
			if not _has_art():
				_spawn_flame(false)
	for f in flames:
		f[0] += f[1] * delta
		f[1].x *= 0.92
		f[2] -= delta
	flames = flames.filter(func(f): return f[2] > 0)

	var t := Time.get_ticks_msec() / 1000.0
	var energy := 0.0
	if active:
		energy = 0.22 + 0.06 * sin(t * 5.0)
	elif transforming > 0:
		energy = 0.8 * (1.0 - transforming / TRANSFORM_TIME)
	elif hangover > 0:
		energy = 0.25 if int(t * 14) % 3 == 0 else 0.0   # a aura falha como uma lâmpada morrendo
	glow.modulate.a = energy
	glow.visible = energy > 0.01
	queue_redraw()
	back.queue_redraw()


func _spawn_flame(burst: bool) -> void:
	var x := randf_range(-9, 9)
	var y := randf_range(-18, 18)
	var vel := Vector2(randf_range(-10, 10), randf_range(-45, -25))
	if burst:
		vel = Vector2(x, y).normalized() * randf_range(60, 140) + Vector2(0, -30)
	var life := randf_range(0.25, 0.5)
	flames.append([Vector2(x, y), vel, life, life, 1 if randf() < 0.7 else 2])


# --- Desenho -----------------------------------------------------------

## Chamas da aura (atrás do sprite).
func _draw_back() -> void:
	for f in flames:
		var k: float = f[2] / f[3]
		var c := WHITE_HOT if k > 0.8 else (HOT if k > 0.55 else (MID if k > 0.3 else DEEP))
		var p: Vector2 = f[0].round()
		back.draw_rect(Rect2(p, Vector2.ONE * f[4]), Color(c, 0.35 + 0.5 * k))


## Chifre de aura e olhos (na frente do sprite).
func _draw() -> void:
	if not active and transforming <= 0 and hangover <= 0:
		return
	if hangover > 0 and int(Time.get_ticks_msec() / 70) % 3 != 0:
		return
	if _has_art():
		return   # a arte carmesim do Noct é a forma oficial
	var head = _head()
	if head == null:
		return
	var top: Vector2 = head[0]
	var eye: Vector2 = head[1]
	var f: int = player.facing
	var t := Time.get_ticks_msec() / 1000.0
	var a := 0.85 if transforming <= 0 else 1.0 - transforming / TRANSFORM_TIME
	# Chifre: nasce na parte de trás do alto da cabeça.
	var base := top + Vector2(-f * 3, 3)
	for row in HORN.size():
		var line: String = HORN[row]
		for col in line.length():
			var ch := line[col]
			if ch == ".":
				continue
			var dx := col - (line.length() - 1)    # base à direita (olhando para a direita)
			var px := base + Vector2(dx * f, row - HORN.size())
			var flicker := 0.88 + 0.12 * sin(t * 9.0 - row)
			var hc: Color = {"o": HOT, "x": MID, "d": Color("3a0a1d")}[ch]
			draw_rect(Rect2(px, Vector2.ONE), Color(hc, a * flicker * (0.9 if ch == "d" else 1.0)))
	# Olho aceso.
	draw_circle(eye + Vector2(0.5, 0.5), 3.0, Color(MID, a * 0.3))
	draw_rect(Rect2(eye, Vector2.ONE), Color(WHITE_HOT, a))
	draw_rect(Rect2(eye + Vector2(-f, 0), Vector2.ONE), Color(HOT, a * 0.9))


## A arte oficial da forma (animações cN_* do herói) existe para o nível atual?
func _has_art() -> bool:
	return player.sprite.sprite_frames.has_animation("c%d_idle" % maxi(level_number(), 1))


## Topo da cabeça e olho no quadro atual, em coordenadas locais do herói.
## Calculados uma vez por quadro de animação a partir dos pixels do próprio sprite,
## então seguem a cabeça em qualquer pose sem redesenhar o Noct.
func _head():
	var sp: AnimatedSprite2D = player.sprite
	var key := "%s:%d" % [sp.animation, sp.frame]
	if not head_cache.has(key):
		head_cache[key] = _scan_head(sp.sprite_frames.get_frame_texture(sp.animation, sp.frame))
	var h = head_cache[key]
	if h == null:
		return null
	var w: float = h[2]
	var top: Vector2 = h[0]
	var eye: Vector2 = h[1]
	if sp.flip_h:
		top.x = w - 1 - top.x
		eye.x = w - 1 - eye.x
	var origin := sp.position + sp.offset
	return [origin + top, origin + eye]


## Cabeça = topo da silhueta. O olho fica ~7 px abaixo do topo, perto da frente do rosto
## (o Noct é desenhado olhando para a direita).
func _scan_head(tex: Texture2D):
	if tex == null:
		return null
	var img := tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var top := -1
	for y in h:
		var count := 0
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				count += 1
		if count >= 2:
			top = y
			break
	if top < 0:
		return null
	var sum := 0.0
	var n := 0
	for y in range(top, mini(top + 5, h)):
		for x in w:
			if img.get_pixel(x, y).a > 0.5:
				sum += x
				n += 1
	var cx := sum / maxf(n, 1)
	var eye_y := mini(top + 6, h - 1)
	var front := cx
	for x in range(w - 1, -1, -1):
		if img.get_pixel(x, eye_y).a > 0.5:
			front = x
			break
	return [Vector2(roundf(cx), top), Vector2(front - 2, eye_y), w]
