extends Node2D
## Ataques soltos do Velário (game/bosses/velario/velario.gd). Um script, vários tipos (kind):
##   "chain": corrente que corre pelo chão (Tranca). Pule por cima.
##   "cage":  gaiola que cai do alto num ponto marcado por uma sombra (Chuva de gaiolas).
##   "tide":  onda carmesim baixa que corre pelo chão até a parede (Maré carmesim). Pule por cima.
##   "shock": onda de choque curta dos dois lados ao cair do salto.
##   "dark":  escuridão do "Esquecer"/"Não olha": só visual, some sozinha.
## A origem do nó fica no chão. Machuca pelo grupo "harmful" (o herói confere get_hurtbox).

const Fx := preload("res://game/core/fx.gd")
const IRON := Color("4a4f5a")
const IRON_HI := Color("9aa0aa")
const CRIM := Color("d9264f")
const HOT := Color("ff6f96")

var level
var kind := "chain"
var dir := 1
var speed := 170.0
var life := 2.4
var warn := 0.7          # cage: tempo da sombra antes de cair
var t := 0.0
var fall_y := 0.0        # cage: altura acima do chão
var dark_time := 1.6     # dark: duração
var glow: Sprite2D


func _ready() -> void:
	if kind != "dark":
		add_to_group("harmful")
	match kind:
		"cage":
			fall_y = -220.0
		"tide":
			glow = Fx.glow(CRIM, 22, 0.55)
			glow.position = Vector2(0, -8)
			add_child(glow)
		"dark":
			z_index = 50
			life = dark_time
	if kind == "chain":
		Audio.play_sfx("rise", 0.1, 0.5)


func get_hurtbox() -> Rect2:
	match kind:
		"chain":
			return Rect2(global_position + Vector2(-10, -9), Vector2(20, 9))
		"tide":
			return Rect2(global_position + Vector2(-9, -18), Vector2(18, 18))
		"cage":
			if t >= warn and fall_y > -30:
				return Rect2(global_position + Vector2(-9, fall_y - 20), Vector2(18, 22))
		"shock":
			if t < 0.25:
				return Rect2(global_position + Vector2(-70, -14), Vector2(140, 14))
	return Rect2(-99999, -99999, 0, 0)


func _process(delta: float) -> void:
	t += delta
	match kind:
		"chain", "tide":
			position.x += dir * speed * delta
			var ahead := global_position + Vector2(dir * 8, -6)
			if level.is_solid(ahead) or t > life:
				if kind == "tide":
					Fx.sparks(level.world, global_position + Vector2(0, -8), HOT, 10, 90)
				queue_free()
				return
			if kind == "tide" and int(t * 30) % 3 == 0:
				Fx.sparks(level.world, global_position + Vector2(-dir * 6, -6), CRIM, 2, 50, 60, 1.2)
		"cage":
			if t >= warn:
				fall_y = minf(fall_y + 520.0 * delta, 0.0)
				if fall_y >= 0.0 and t < warn + 10:
					t = warn + 10   # caiu: fica um instante no chão e some
					level.shake(3.0)
					Audio.play_sfx("earth", 0.1, 1.3)
					Fx.sparks(level.world, global_position, IRON_HI, 8, 80)
			if t > warn + 10.5:
				queue_free()
				return
		"shock":
			if t > 0.4:
				queue_free()
				return
		"dark":
			if t > life:
				queue_free()
				return
	queue_redraw()


func _draw() -> void:
	match kind:
		"chain":
			# Elos de ferro deitados, puxados pelo chão, com fagulha na ponta.
			for i in 5:
				var x := -dir * i * 6.0
				draw_rect(Rect2(x - 3, -6 + (i % 2) * 1, 6, 3), IRON)
				draw_rect(Rect2(x - 3, -6 + (i % 2) * 1, 6, 1), IRON_HI)
			draw_rect(Rect2(dir * 4 - 1, -8, 3, 3), HOT)
		"tide":
			# Onda carmesim em pixels, mais alta na frente.
			for i in 8:
				var h := 16.0 - i * 1.6 + sin(t * 18.0 + i) * 1.5
				var x := -dir * i * 2.0
				draw_rect(Rect2(x - 1, -h, 2, h), Color(CRIM if i > 1 else HOT, 0.9 - i * 0.08))
		"cage":
			if t < warn:
				var k := t / warn
				draw_rect(Rect2(-8 * k - 2, -2, 16 * k + 4, 2), Color(0, 0, 0, 0.5 + 0.3 * k))
				draw_arc(Vector2(0, -1), 4 + 6 * k, PI, TAU, 10, Color(CRIM, 0.6 * k), 1)
			var y := fall_y
			if t >= warn - 0.25:
				draw_line(Vector2(0, y - 22), Vector2(0, y - 60), Color(IRON, 0.8), 1)
				draw_rect(Rect2(-8, y - 20, 16, 20), Color(0.04, 0.02, 0.05, 0.85))
				for bx in [-8, -4, 0, 4, 7]:
					draw_rect(Rect2(bx, y - 20, 1, 20), IRON)
				draw_rect(Rect2(-9, y - 21, 18, 2), IRON_HI)
				draw_rect(Rect2(-9, y - 1, 18, 2), IRON)
				draw_rect(Rect2(-1, y - 14, 2, 8), Color(HOT, 0.8))
		"shock":
			var k := t / 0.4
			for s in [-1, 1]:
				var x: float = s * (10 + k * 60)
				draw_rect(Rect2(x - 3, -10 * (1 - k), 6, 10 * (1 - k)), Color(HOT, 1 - k))
				draw_rect(Rect2(x - 1, -14 * (1 - k), 2, 14 * (1 - k)), Color(1, 0.85, 0.9, 1 - k))
		"dark":
			# Tela quase preta, enorme em volta do herói (desenhada no mundo, acima de tudo).
			var a: float = clampf(minf(t / 0.25, (life - t) / 0.35), 0, 1) * 0.86
			var p: Vector2 = level.player.global_position - global_position
			draw_rect(Rect2(p - Vector2(900, 600), Vector2(1800, 1200)), Color(0.01, 0.0, 0.02, a))
