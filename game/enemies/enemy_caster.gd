extends CharacterBody2D
## Mago encapuzado: fica parado e lança bolas de fogo em linha reta quando vê o herói.

const Sprites := preload("res://game/core/sprites.gd")
const ProjectileScript := preload("res://game/enemies/enemy_projectile.gd")

const SIZE := Vector2(20, 40)
const GRAVITY := 900.0
const SIGHT := 240.0
const COOLDOWN := 2.0
const FIRE_FRAME := 6   # quadro da animação em que a bola de fogo sai

var level
var hp := 4
var dir := -1
var flash := 0.0
var cooldown := 1.0
var fired := false
var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	var shape := CollisionShape2D.new()
	shape.shape = rect
	add_child(shape)
	# Quadro 81x66, pés na linha 65.
	sprite = Sprites.make_sprite(Sprites.wizard(), Vector2(81, 66), 65, SIZE.y / 2)
	add_child(sprite)
	sprite.play("idle")
	sprite.animation_finished.connect(func(): sprite.play("idle"))


func place_feet_at(feet: Vector2) -> void:
	position = feet - Vector2(0, SIZE.y / 2)


func get_hurtbox() -> Rect2:
	return Rect2(global_position - SIZE / 2, SIZE)


func _physics_process(delta: float) -> void:
	flash = maxf(flash - delta, 0)
	cooldown -= delta
	velocity.y = minf(velocity.y + GRAVITY * delta, 400)
	velocity.x = 0
	move_and_slide()

	var p: Node2D = level.player
	var dx := p.global_position.x - global_position.x
	var sees := absf(dx) < SIGHT and absf(p.global_position.y - global_position.y) < 48

	if sprite.animation == "fire":
		if not fired and sprite.frame >= FIRE_FRAME:
			fired = true
			_shoot()
	elif sees:
		dir = 1 if dx > 0 else -1
		if cooldown <= 0:
			cooldown = COOLDOWN
			fired = false
			sprite.play("fire")

	sprite.flip_h = dir > 0  # o desenho olha para a esquerda
	sprite.modulate = Color(1, 0.35, 0.35) if flash > 0 else Color.WHITE


func _shoot() -> void:
	var fb = ProjectileScript.new()
	fb.level = level
	fb.velocity = Vector2(dir * 150, 0)
	fb.position = global_position + Vector2(dir * 22, -6)
	level.add_to_world(fb)
	Audio.play_sfx("rise", 0.1, 1.6)


func take_hit(_from_dir: Vector2, damage: int) -> void:
	if hp <= 0 or is_queued_for_deletion():
		return
	hp -= damage
	flash = 0.12
	if hp <= 0:
		level.on_enemy_killed(9)
		level.spawn_explosion(global_position)
		queue_free()
