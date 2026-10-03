extends Node2D
## Bola de fogo cuspida pelo Gato Infernal: voa em arco e explode ao tocar o chão ou a parede.
const Fx := preload("res://game/core/fx.gd")

const Sprites := preload("res://game/core/sprites.gd")
const GRAVITY := 600.0
const SIZE := Vector2(14, 14)

var level
var velocity := Vector2.ZERO
var exploded := false
var life := 4.0
var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("harmful")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.fireball()
	sprite.animation_finished.connect(queue_free)
	add_child(sprite)
	add_child(Fx.glow(Color(1, 0.55, 0.2), 20, 0.7))
	sprite.play("fly")


func get_hurtbox() -> Rect2:
	# Depois de explodir não machuca mais (o raio fica para trás, uma rect vazia longe do herói).
	if exploded:
		return Rect2(-99999, -99999, 0, 0)
	return Rect2(global_position - SIZE / 2, SIZE)


func _physics_process(delta: float) -> void:
	if exploded:
		return
	life -= delta
	velocity.y += GRAVITY * delta
	position += velocity * delta
	sprite.rotation += delta * 8
	if life <= 0 or level.is_solid(global_position + velocity.normalized() * 6):
		exploded = true
		sprite.rotation = 0
		sprite.position.y = -16
		sprite.play("boom")
		Audio.play_sfx("explosion", 0.2, 1.3)
