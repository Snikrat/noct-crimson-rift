extends Node2D
## Espinhos: Noct se desfaz em fragmentos carmesim que explodem, voam em arco até o último
## chão seguro e se remontam ali no formato do corpo. Só visual: o player_body segue center()
## enquanto voa e reaparece quando done fica true.
const Fx := preload("res://game/core/fx.gd")
# Feito no Aseprite (art_source/vfx/shards.aseprite): 4 rotações do fragmento + 2 brilhos, 8x8.
const SHEET := preload("res://assets/hero/vfx/shard_sheet.png")
const FRAME := 8
const COUNT := 18
const BURST_TIME := 0.22
const FLY_TIME := 0.5
const GATHER_TIME := 0.18
const TOTAL := BURST_TIME + FLY_TIME + GATHER_TIME
const TAIL := 0.25            # o brilho ainda some depois que o Noct reaparece
const MAX_DELAY := 0.12       # fragmentos saem em leva, não todos juntos

var from := Vector2.ZERO      # centro do Noct ao tocar os espinhos (coordenadas da sala)
var to := Vector2.ZERO        # centro dele no último chão seguro
var t := 0.0
var done := false
var shards: Array[Dictionary] = []
var glow: Sprite2D


func _ready() -> void:
	z_index = 3
	for i in COUNT:
		var dir := Vector2.from_angle(randf() * TAU)
		var body := Vector2(randf_range(-6, 6), randf_range(-18, 18))
		var start := from + body
		var burst := start + dir * randf_range(14, 30) + Vector2(0, -8)
		var land := to + body + dir * 14
		var mid := (burst + land) / 2 + Vector2(0, -randf_range(30, 60))
		mid.y = maxf(mid.y, 16.0)   # o arco não sai pelo teto da sala
		shards.append({
			"start": start, "burst": burst, "mid": mid, "land": land, "end": to + body,
			"delay": randf() * MAX_DELAY, "spin": randf_range(10, 18), "phase": randf() * 4,
			"small": i % 4 == 0,
		})
	glow = Fx.glow(Color(1, 0.15, 0.35), 26, 0.5)
	glow.position = from
	add_child(glow)
	Fx.sparks(self, from, Color(1, 0.25, 0.4), 14, 120, 60)


func _process(delta: float) -> void:
	t += delta
	if t >= TOTAL and not done:
		done = true
		Fx.sparks(self, to, Color(1, 0.45, 0.6), 16, 90, 0)
	if t >= TOTAL + TAIL:
		queue_free()
		return
	glow.position = center()
	glow.modulate.a = 0.5 if not done else 0.5 * (1.0 - (t - TOTAL) / TAIL)
	queue_redraw()


func _shard_pos(s: Dictionary, time: float) -> Vector2:
	if time < BURST_TIME:
		return s.start.lerp(s.burst, ease(time / BURST_TIME, 0.4))
	if time < BURST_TIME + FLY_TIME:
		var k := clampf((time - BURST_TIME - s.delay) / (FLY_TIME - MAX_DELAY), 0.0, 1.0)
		k = ease(k, -2.0)
		var a: Vector2 = s.burst.lerp(s.mid, k)
		var b: Vector2 = s.mid.lerp(s.land, k)
		return a.lerp(b, k)
	var g := clampf((time - BURST_TIME - FLY_TIME) / GATHER_TIME, 0.0, 1.0)
	return s.land.lerp(s.end, ease(g, 0.5))


## Ponto médio dos fragmentos: a câmera (presa ao Noct) acompanha o voo.
func center() -> Vector2:
	if done:
		return to
	var sum := Vector2.ZERO
	for s in shards:
		sum += _shard_pos(s, t)
	return sum / shards.size()


func _draw() -> void:
	if done:
		return
	var flying := t > BURST_TIME and t < BURST_TIME + FLY_TIME
	for s in shards:
		var frame := 4 + int(t * 8) % 2 if s.small else int(s.phase + t * s.spin) % 4
		var src := Rect2(frame * FRAME, 0, FRAME, FRAME)
		var half := Vector2(FRAME, FRAME) / 2
		if flying:
			var trail := _shard_pos(s, t - 0.04)
			draw_texture_rect_region(SHEET, Rect2(trail - half, half * 2), src, Color(1, 1, 1, 0.35))
		draw_texture_rect_region(SHEET, Rect2(_shard_pos(s, t) - half, half * 2), src)
