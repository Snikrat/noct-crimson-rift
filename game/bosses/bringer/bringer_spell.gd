extends Node2D
## Mão sombria do Bringer of Death: marca o chão, espera um instante e desce do alto.
## A origem deste nó fica no chão, onde a mão vai bater.

const Sprites := preload("res://game/core/sprites.gd")
const WARN_TIME := 0.6          # tempo do aviso no chão antes da mão aparecer
const HIT_FRAMES := [5, 10]     # quadros da animação em que a mão machuca
const AREA := Rect2(-14, -56, 28, 56)

var level
var t := 0.0
var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("harmful")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.bringer_spell()
	sprite.centered = false
	# Mão: x 52-83 e pés (ponta) na linha 91 do quadro 140x93.
	sprite.offset = Vector2(-67, -92)
	sprite.visible = false
	sprite.animation_finished.connect(queue_free)
	add_child(sprite)


func get_hurtbox() -> Rect2:
	if not sprite.visible or sprite.frame < HIT_FRAMES[0] or sprite.frame > HIT_FRAMES[1]:
		return Rect2(-99999, -99999, 0, 0)
	return Rect2(global_position + AREA.position, AREA.size)


func _process(delta: float) -> void:
	t += delta
	if not sprite.visible and t >= WARN_TIME:
		sprite.visible = true
		sprite.play("spell")
		Audio.play_sfx("rise", 0.1, 0.6)
	queue_redraw()


func _draw() -> void:
	# Aviso: um círculo roxo pulsando no chão.
	if not sprite.visible:
		var k := t / WARN_TIME
		draw_arc(Vector2(0, -2), 6 + k * 10, 0, TAU, 20, Color(0.7, 0.3, 1.0, 0.4 + k * 0.5), 2)
		draw_line(Vector2(-16 * k, -1), Vector2(16 * k, -1), Color(0.8, 0.5, 1.0, 0.8), 2)
