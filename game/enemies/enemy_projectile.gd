extends Node2D
## Bola de fogo em linha reta (dos magos). Some ao bater numa parede ou depois de um tempo.
## Também pode ser rebatida com um golpe.
const Fx := preload("res://game/core/fx.gd")

const Sprites := preload("res://game/core/sprites.gd")
const SIZE := Vector2(12, 12)

var level
var velocity := Vector2.ZERO
var life := 3.0
var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("harmful")
	add_to_group("enemies")  # para os golpes poderem destruí-la
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = Sprites.church_fireball()
	sprite.flip_h = velocity.x > 0
	add_child(sprite)
	add_child(Fx.glow(Color(1, 0.5, 0.2), 18, 0.6))
	sprite.play("fly")


func get_hurtbox() -> Rect2:
	return Rect2(global_position - SIZE / 2, SIZE)


func _physics_process(delta: float) -> void:
	life -= delta
	position += velocity * delta
	if life <= 0 or level.is_solid(global_position + velocity.normalized() * 6):
		queue_free()


## Um golpe apaga a bola de fogo.
func take_hit(_from_dir: Vector2, _damage: int) -> void:
	level.spawn_explosion(global_position, false)
	queue_free()
