extends Node2D
## Rachadura do Coração da Fenda ("j" no mapa): o chão brilha cada vez mais forte e explode numa coluna
## de energia carmesim. Rachaduras vizinhas explodem em sequência (o atraso vem da coluna no mapa).
## Machuca pelo grupo "harmful" só durante a explosão.
const Fx := preload("res://game/core/fx.gd")

const PERIOD := 2.6
const WARN := 0.7
const BURST := 0.35

var level
var t := 0.0


func _ready() -> void:
	add_to_group("harmful")
	t = fmod(position.x / 16.0 * 0.22, PERIOD)


func place_feet_at(feet: Vector2) -> void:
	position = feet
	t = fmod(feet.x / 16.0 * 0.22, PERIOD)


func _phase() -> float:
	return fmod(t, PERIOD)


func get_hurtbox() -> Rect2:
	var ph := _phase()
	if ph > PERIOD - BURST:
		return Rect2(global_position + Vector2(-7, -40), Vector2(14, 40))
	return Rect2(-99999, -99999, 0, 0)


func _process(delta: float) -> void:
	var before := _phase()
	t += delta
	if before < PERIOD - BURST and _phase() >= PERIOD - BURST:
		Fx.sparks(level.world, global_position + Vector2(0, -6), Color("ff6f96"), 8, 120, 60)
		Audio.play_sfx("rise", 0.15, 1.2)
	queue_redraw()


func _draw() -> void:
	var ph := _phase()
	var warn_from := PERIOD - BURST - WARN
	# Fenda no chão (sempre), acesa no aviso.
	var glow := clampf((ph - warn_from) / WARN, 0, 1) if ph < PERIOD - BURST else 1.0
	var line := [Vector2(-6, -1), Vector2(-3, -2), Vector2(-1, -1), Vector2(2, -2), Vector2(5, -1)]
	for i in line.size() - 1:
		draw_line(line[i], line[i + 1], Color(0.85, 0.15, 0.3, 0.35 + glow * 0.65), 1)
	if ph >= PERIOD - BURST:
		var k := (ph - (PERIOD - BURST)) / BURST
		var h := 40.0 * (1.0 - k * 0.4)
		draw_rect(Rect2(-5, -h, 10, h), Color(0.85, 0.15, 0.3, 0.55 * (1 - k)))
		draw_rect(Rect2(-2, -h, 4, h), Color(1, 0.82, 0.88, 0.9 * (1 - k)))
