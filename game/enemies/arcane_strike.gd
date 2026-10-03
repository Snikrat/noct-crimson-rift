extends Node2D
## Selo do mago: aviso fixo no chão antes do raio; golpes podem apagá-lo.
const Sprites := preload("res://game/core/sprites.gd")
var level
var timer := 0.75
var active := false
var sprite: AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("harmful")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.lightning()
	sprite.position = Vector2(0, -48)
	sprite.scale = Vector2(0.65, 0.75)
	sprite.modulate = Color(0.75, 0.45, 1)
	sprite.visible = false
	add_child(sprite)

func _physics_process(delta: float) -> void:
	timer -= delta
	if not active and timer <= 0:
		active = true
		timer = 0.4
		sprite.visible = true
		sprite.play("strike")
		Audio.play_sfx("thunder", 0.05, 1.25)
	elif active and timer <= 0:
		queue_free()
	queue_redraw()

func get_hurtbox() -> Rect2:
	return Rect2(global_position + Vector2(-16, -20), Vector2(32, 20)) if not active else Rect2()

func get_damagebox() -> Rect2:
	return Rect2(global_position + Vector2(-16, -90), Vector2(32, 90)) if active else Rect2()

func take_hit(_direction: Vector2, _damage: int) -> void:
	if not active:
		queue_free()

func _draw() -> void:
	if not active:
		var alpha := 0.6 + sin(timer * 28) * 0.25
		draw_arc(Vector2(0, -3), 16, 0, TAU, 24, Color(0.7, 0.35, 1, alpha), 2)
		draw_line(Vector2(-16, -2), Vector2(16, -2), Color(0.85, 0.6, 1, alpha), 2)
